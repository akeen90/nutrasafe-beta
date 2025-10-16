import Foundation
import UIKit
@preconcurrency import AVFoundation
import Vision

// MARK: - LiveTextScannerService
@MainActor
class LiveTextScannerService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isScanning = false
    @Published var detectedText = ""
    @Published var textBlocks: [TextBlock] = []
    @Published var sessionId = UUID().uuidString
    @Published var scanType: ScanType = .ingredients
    @Published var accumulatedText: Set<String> = []
    @Published var confidence: Double = 0.0
    @Published var scanningStep: ScanningStep = .ingredients
    @Published var ingredientsData: String?
    @Published var nutritionData: [String: Any]?
    @Published var isReadyToComplete = false
    @Published var highlightedRegions: [TextBlock] = []
    @Published var showCompletionCheckmark = false

    // MARK: - Private Properties
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var textDetectionRequest: VNRecognizeTextRequest?
    private let firebaseManager = FirebaseManager.shared
    private var scanTimer: Timer?
    private var autoAdvanceTimer: Timer?
    private var currentCamera: AVCaptureDevice?
    
    // MARK: - Enums
    enum ScanType: String, CaseIterable {
        case ingredients = "ingredients"
        case nutrition = "nutrition"
        case barcode = "barcode"

        var displayName: String {
            switch self {
            case .ingredients: return "Ingredients"
            case .nutrition: return "Nutrition Facts"
            case .barcode: return "Barcode"
            }
        }
    }

    enum ScanningStep: String {
        case ingredients = "ingredients"
        case nutrition = "nutrition"
        case complete = "complete"

        var instructions: String {
            switch self {
            case .ingredients:
                return "Point at ingredients list - detected items will be outlined"
            case .nutrition:
                return "Point at nutrition facts - values will be highlighted"
            case .complete:
                return "Scan complete! Review your data"
            }
        }

        var nextStep: ScanningStep? {
            switch self {
            case .ingredients:
                return .nutrition
            case .nutrition:
                return .complete
            case .complete:
                return nil
            }
        }
    }
    
    // MARK: - Data Structures
    struct TextBlock: Identifiable, Equatable {
        let id = UUID()
        let text: String
        let boundingBox: CGRect
        let confidence: Float
        let timestamp: Date
        
        static func == (lhs: TextBlock, rhs: TextBlock) -> Bool {
            return lhs.text == rhs.text && lhs.boundingBox == rhs.boundingBox
        }
    }
    
    struct ProcessedTextResult {
        let cleanedText: String
        let structuredData: [String: Any]?
        let confidence: Double
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupTextDetection()
    }
    
    deinit {
        // stopScanning() will be called automatically when the object is deallocated
        // since AVCaptureSession is a strong reference that will be released
    }
    
    // MARK: - Public Methods
    func startScanning() {
        print("🎯 startScanning() called")
        sessionId = UUID().uuidString
        accumulatedText.removeAll()
        textBlocks.removeAll()
        detectedText = ""
        confidence = 0.0

        // Request camera permission first
        Task {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            print("📹 Camera authorization status: \(status.rawValue)")

            if status == .notDetermined {
                print("📹 Requesting camera permission...")
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                if granted {
                    print("✅ Camera permission granted")
                    self.setupCameraSession()
                } else {
                    print("❌ Camera permission denied")
                    self.isScanning = false
                }
            } else if status == .authorized {
                print("✅ Camera already authorized")
                self.setupCameraSession()
            } else {
                print("❌ Camera not authorized. Status: \(status.rawValue)")
                self.isScanning = false
            }
        }
    }
    
    func stopScanning() {
        isScanning = false
        scanTimer?.invalidate()
        scanTimer = nil
        autoAdvanceTimer?.invalidate()
        autoAdvanceTimer = nil

        captureSession?.stopRunning()
        captureSession = nil
        previewLayer = nil
    }
    
    func switchScanType(_ type: ScanType) {
        scanType = type
        // Clear previous results when switching types
        accumulatedText.removeAll()
        textBlocks.removeAll()
        detectedText = ""
    }
    
    func finalizeScanning() async -> ProcessedTextResult? {
        guard !accumulatedText.isEmpty else { return nil }
        
        let textChunks = Array(accumulatedText)
        
        do {
            let result = await processTextWithGemini(textChunks: textChunks, finalProcess: true)
            return result
        } catch {
            print("Error finalizing scan: \\(error)")
            return ProcessedTextResult(
                cleanedText: textChunks.joined(separator: " "),
                structuredData: nil,
                confidence: confidence
            )
        }
    }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        return previewLayer
    }

    /// Manually trigger focus at a specific point
    func focusAt(point: CGPoint) {
        guard let camera = currentCamera else {
            print("⚠️ No camera available for manual focus")
            return
        }

        Task.detached {
            do {
                try camera.lockForConfiguration()

                if camera.isFocusPointOfInterestSupported && camera.isFocusModeSupported(.autoFocus) {
                    camera.focusPointOfInterest = point
                    camera.focusMode = .autoFocus
                    print("📍 Focused at point: \(point)")
                }

                if camera.isExposurePointOfInterestSupported && camera.isExposureModeSupported(.autoExpose) {
                    camera.exposurePointOfInterest = point
                    camera.exposureMode = .autoExpose
                }

                camera.unlockForConfiguration()

                // After auto focus/exposure completes, return to continuous mode
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                try camera.lockForConfiguration()

                if camera.isFocusModeSupported(.continuousAutoFocus) {
                    camera.focusMode = .continuousAutoFocus
                }

                if camera.isExposureModeSupported(.continuousAutoExposure) {
                    camera.exposureMode = .continuousAutoExposure
                }

                camera.unlockForConfiguration()
            } catch {
                print("⚠️ Failed to adjust focus: \(error)")
            }
        }
    }

    // MARK: - Multi-Step Scanning Methods
    func advanceToNextStep() {
        guard let nextStep = scanningStep.nextStep else { return }

        // Save current step data
        if scanningStep == .ingredients {
            ingredientsData = Array(accumulatedText).joined(separator: ", ")
            print("✅ Saved ingredients: \(ingredientsData ?? "")")
        } else if scanningStep == .nutrition {
            // Process nutrition data from accumulated text
            let nutritionText = Array(accumulatedText).joined(separator: " ")
            nutritionData = parseNutritionFromText(nutritionText)
            print("✅ Saved nutrition data: \(nutritionData ?? [:])")
        }

        // Clear for next step
        accumulatedText.removeAll()
        textBlocks.removeAll()
        detectedText = ""
        highlightedRegions.removeAll()

        // Advance to next step
        scanningStep = nextStep
        isReadyToComplete = false

        // Show checkmark only when completing the entire scan
        if nextStep == .complete {
            showCompletionCheckmark = true
            // Hide after 1.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.showCompletionCheckmark = false
            }
        }

        print("📍 Advanced to step: \(scanningStep.rawValue)")
    }

    func forceComplete() {
        // Save current step data if any
        if scanningStep == .ingredients && !accumulatedText.isEmpty {
            ingredientsData = Array(accumulatedText).joined(separator: ", ")
        } else if scanningStep == .nutrition && !accumulatedText.isEmpty {
            let nutritionText = Array(accumulatedText).joined(separator: " ")
            nutritionData = parseNutritionFromText(nutritionText)
        }

        scanningStep = .complete
        print("🏁 Force completed scanning")
    }

    func saveToUserEnhancedDatabase(barcode: String, productName: String) async -> Bool {
        guard let ingredients = ingredientsData,
              let nutrition = nutritionData else {
            print("❌ Cannot save: missing ingredients or nutrition data")
            return false
        }

        let enhancedData: [String: Any] = [
            "barcode": barcode,
            "productName": productName,
            "ingredients": ingredients,
            "nutrition": nutrition,
            "scannedBy": firebaseManager.currentUser?.uid ?? "unknown",
            "scannedAt": Date().timeIntervalSince1970,
            "sessionId": sessionId,
            "confidence": confidence
        ]

        do {
            try await firebaseManager.saveUserEnhancedProduct(data: enhancedData)
            print("✅ Saved to userEnhancedProductData collection")
            return true
        } catch {
            print("❌ Error saving to Firebase: \(error)")
            return false
        }
    }

    // MARK: - Private Methods
    private func setupTextDetection() {
        textDetectionRequest = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.handleTextDetectionResults(request: request, error: error)
            }
        }
        
        textDetectionRequest?.recognitionLevel = .accurate
        textDetectionRequest?.usesLanguageCorrection = true
        textDetectionRequest?.recognitionLanguages = ["en-US", "en-GB"]
    }
    
    private func setupCameraSession() {
        guard captureSession == nil else {
            print("⚠️ Camera session already exists, using existing session")
            self.isScanning = true
            return
        }

        print("📷 Setting up camera session...")

        // Setup needs to happen on a background thread to avoid blocking UI
        Task.detached { [weak self] in
            guard let self = self else { return }

            let session = AVCaptureSession()
            session.sessionPreset = .high

            guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                print("❌ Failed to get back camera device")
                await MainActor.run {
                    self.isScanning = false
                }
                return
            }

            // Store camera reference for later use
            await MainActor.run {
                self.currentCamera = backCamera
            }

            // Configure camera for optimal text scanning
            do {
                try backCamera.lockForConfiguration()

                // Enable continuous autofocus with center weighting
                if backCamera.isFocusModeSupported(.continuousAutoFocus) {
                    backCamera.focusMode = .continuousAutoFocus
                    print("✅ Enabled continuous autofocus")
                }

                // Set focus point of interest to center for document scanning
                if backCamera.isFocusPointOfInterestSupported {
                    backCamera.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
                    print("✅ Set focus point to center")
                }

                // Enable auto exposure with center weighting
                if backCamera.isExposureModeSupported(.continuousAutoExposure) {
                    backCamera.exposureMode = .continuousAutoExposure
                }

                // Set exposure point to center
                if backCamera.isExposurePointOfInterestSupported {
                    backCamera.exposurePointOfInterest = CGPoint(x: 0.5, y: 0.5)
                }

                // Enable smooth autofocus for better document scanning
                if backCamera.isSmoothAutoFocusSupported {
                    backCamera.isSmoothAutoFocusEnabled = true
                    print("✅ Enabled smooth autofocus")
                }

                // Enable auto white balance for better text recognition
                if backCamera.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                    backCamera.whiteBalanceMode = .continuousAutoWhiteBalance
                }

                // Disable low light boost if supported (for sharper text)
                if backCamera.isLowLightBoostSupported {
                    backCamera.automaticallyEnablesLowLightBoostWhenAvailable = false
                }

                backCamera.unlockForConfiguration()
                print("✅ Camera configured for optimal text scanning")
            } catch {
                print("⚠️ Failed to configure camera: \(error)")
            }

            guard let input = try? AVCaptureDeviceInput(device: backCamera) else {
                print("❌ Failed to create camera input")
                await MainActor.run {
                    self.isScanning = false
                }
                return
            }

            if session.canAddInput(input) {
                session.addInput(input)
                print("✅ Added camera input")
            } else {
                print("❌ Cannot add camera input to session")
                await MainActor.run {
                    self.isScanning = false
                }
                return
            }

            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]

            if session.canAddOutput(output) {
                session.addOutput(output)
                print("✅ Added video output")
            } else {
                print("❌ Cannot add video output to session")
                await MainActor.run {
                    self.isScanning = false
                }
                return
            }

            // Set delegate on main actor
            await MainActor.run {
                output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frame.processing.queue"))
            }

            // Configure preview layer on main actor
            let preview = AVCaptureVideoPreviewLayer(session: session)
            preview.videoGravity = .resizeAspectFill

            await MainActor.run {
                self.previewLayer = preview
                self.captureSession = session
            }

            // Start session on background thread
            print("🎬 Starting camera session...")
            session.startRunning()

            await MainActor.run {
                print("✅ Camera session running: \(session.isRunning)")
                self.isScanning = session.isRunning
            }
        }
    }
    
    private func handleTextDetectionResults(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRecognizedTextObservation],
              error == nil else {
            print("Text detection error: \(error?.localizedDescription ?? "Unknown error")")
            return
        }

        var newTextBlocks: [TextBlock] = []
        var newHighlightedRegions: [TextBlock] = []
        var newText = ""
        var totalConfidence: Float = 0
        var validObservations = 0

        // Track detected content types
        var hasIngredients = false
        var hasNutrition = false

        for observation in observations {
            guard let candidate = observation.topCandidates(1).first,
                  candidate.confidence > 0.5 else { continue }  // Increased from 0.3 to 0.5 for better quality

            let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty, text.count >= 3 else { continue }  // Minimum 3 characters

            let textBlock = TextBlock(
                text: text,
                boundingBox: observation.boundingBox,
                confidence: candidate.confidence,
                timestamp: Date()
            )

            newTextBlocks.append(textBlock)
            totalConfidence += candidate.confidence
            validObservations += 1

            // Intelligent content detection - only process in ingredients mode
            if scanningStep == .ingredients {
                // Only highlight actual ingredients, not headers or noise
                if isActualIngredient(text) && !isHeaderOrNoise(text) {
                    newHighlightedRegions.append(textBlock)
                    accumulatedText.insert(text)
                    newText += text + " "
                    hasIngredients = true
                }
            } else if scanningStep == .nutrition {
                // Only highlight nutrition values
                if isNutritionValue(text) {
                    newHighlightedRegions.append(textBlock)
                    accumulatedText.insert(text)
                    newText += text + " "
                    hasNutrition = true
                }
            }
        }

        // Auto-switch scan mode based on detected content
        if hasIngredients && scanningStep == .ingredients {
            // Already on ingredients, good
        } else if hasNutrition && scanningStep == .nutrition {
            // Already on nutrition, good
        } else if hasIngredients && scanningStep != .ingredients {
            print("🔄 Auto-detected ingredients, staying in current mode")
        } else if hasNutrition && scanningStep != .nutrition {
            print("🔄 Auto-detected nutrition facts, staying in current mode")
        }

        // Update UI
        textBlocks = newTextBlocks
        highlightedRegions = newHighlightedRegions
        detectedText = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        confidence = validObservations > 0 ? Double(totalConfidence / Float(validObservations)) : 0.0

        // Check if ready to advance to next step
        checkIfReadyToComplete()
    }

    private enum ContentType {
        case ingredients
        case nutrition
        case header
        case unknown
    }

    private func detectContentType(_ text: String) -> ContentType {
        let lowerText = text.lowercased()

        // Check for ingredient headers
        let ingredientHeaders = ["ingredients", "contains", "allergens", "may contain"]
        for header in ingredientHeaders {
            if lowerText.contains(header) {
                return .header
            }
        }

        // Check for nutrition headers
        let nutritionHeaders = ["nutrition", "nutritional information", "typical values", "energy", "per 100g", "per serving"]
        for header in nutritionHeaders {
            if lowerText.contains(header) {
                return .header
            }
        }

        // Check for actual ingredients (food items)
        let commonIngredients = ["water", "flour", "sugar", "salt", "milk", "egg", "wheat", "oil", "butter",
                                  "yeast", "cornstarch", "modified", "emulsifier", "preservative", "acid",
                                  "colour", "flavor", "flavour", "citric", "sodium", "calcium", "extract",
                                  "powder", "syrup", "starch", "protein", "vitamin", "mineral"]
        for ingredient in commonIngredients {
            if lowerText.contains(ingredient) {
                return .ingredients
            }
        }

        // Check for nutrition values (numbers with units)
        let nutritionPatterns = [
            "\\d+\\.?\\d*\\s*g",           // grams: 10g, 10.5g
            "\\d+\\.?\\d*\\s*mg",          // milligrams: 100mg
            "\\d+\\.?\\d*\\s*kcal",        // calories: 250kcal
            "\\d+\\.?\\d*\\s*kj",          // kilojoules: 1000kj
            "\\d+\\.?\\d*\\s*%",           // percentage: 15%
            "protein\\s*:?\\s*\\d+",       // protein: 10
            "carb",                         // carbohydrate
            "fat\\s*:?\\s*\\d+",           // fat: 5
            "sugar",                        // sugar
            "fibre",                        // fiber/fibre
            "saturates"                     // saturated fat
        ]

        for pattern in nutritionPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(lowerText.startIndex..., in: lowerText)
                if regex.firstMatch(in: lowerText, range: range) != nil {
                    return .nutrition
                }
            }
        }

        return .unknown
    }

    private func isActualIngredient(_ text: String) -> Bool {
        let lowerText = text.lowercased()

        // Must have at least 3 characters and not be all numbers
        if text.count < 3 || text.allSatisfy({ $0.isNumber }) {
            return false
        }

        // Exclude if it's mostly numbers (like "41%" or "100g")
        let digitCount = text.filter({ $0.isNumber }).count
        if Double(digitCount) / Double(text.count) > 0.5 {
            return false
        }

        // Check if it looks like an ingredient with strong indicators
        let strongIngredientIndicators = [
            "water", "flour", "sugar", "salt", "milk", "egg", "wheat", "oil",
            "butter", "yeast", "starch", "acid", "extract", "powder", "syrup",
            "apple", "bramley", "rapeseed", "cornflour", "demerara", "palm",
            "calcium", "iron", "niacin", "thiamin"  // Common fortification ingredients
        ]

        for indicator in strongIngredientIndicators {
            if lowerText.contains(indicator) {
                return true
            }
        }

        // If it contains ingredient-like structure (word with comma or parentheses)
        // But must be at least 4 characters long
        if text.count >= 4 && (text.contains(",") || (text.contains("(") && text.contains(")"))) {
            return true
        }

        return false
    }

    private func isHeaderOrNoise(_ text: String) -> Bool {
        let lowerText = text.lowercased()

        // Exclude common headers and noise
        let noisePhrases = [
            "ingredients", "contains", "may contain", "allergens", "nutrition",
            "typical", "per 100g", "per serving", "dietary", "preparation",
            "safety", "country", "origin", "size", "quality", "items found",
            "fair", "medium", "good", "excellent", "energy", "fat", "saturates",
            "carbohydrate", "fibre", "protein", "reference intake", "typical values",
            "nutritional information", "file", "edit", "view", "history", "window",
            "coursera", "online", "barcodes", "search", "products", "sainsburys",
            "stamford", "street", "gol-ui", "product"
        ]

        for phrase in noisePhrases {
            if lowerText.contains(phrase) {
                return true
            }
        }

        // Exclude URLs and web content
        if lowerText.contains("http") || lowerText.contains("www") || lowerText.contains(".com") || lowerText.contains(".co.uk") {
            return true
        }

        // Exclude standalone single words that are too short
        if !text.contains(" ") && text.count < 4 {
            return true
        }

        return false
    }

    private func isNutritionValue(_ text: String) -> Bool {
        let lowerText = text.lowercased()

        // Check for nutrition-related patterns
        let patterns = [
            "\\d+\\.?\\d*\\s*g",
            "\\d+\\.?\\d*\\s*mg",
            "\\d+\\.?\\d*\\s*kcal",
            "\\d+\\.?\\d*\\s*kj",
            "\\d+\\.?\\d*\\s*%",
            "protein",
            "carb",
            "fat",
            "sugar",
            "fibre",
            "energy",
            "saturates"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(lowerText.startIndex..., in: lowerText)
                if regex.firstMatch(in: lowerText, range: range) != nil {
                    return true
                }
            }
        }

        return false
    }
    
    private func processCurrentFrame() async {
        // This will be called by the camera delegate
        // Frame processing is handled in the AVCaptureVideoDataOutputSampleBufferDelegate
    }

    private func parseNutritionFromText(_ text: String) -> [String: Any] {
        var nutrition: [String: Any] = [:]

        // Simple pattern matching for common nutrition values
        let patterns: [String: String] = [
            "calories": "(?:energy|calories?)\\s*:?\\s*(\\d+\\.?\\d*)",
            "protein": "protein\\s*:?\\s*(\\d+\\.?\\d*)\\s*g",
            "carbs": "(?:carbohydrate|carbs?)\\s*:?\\s*(\\d+\\.?\\d*)\\s*g",
            "fat": "(?:total\\s*)?fat\\s*:?\\s*(\\d+\\.?\\d*)\\s*g",
            "sugar": "sugars?\\s*:?\\s*(\\d+\\.?\\d*)\\s*g",
            "fiber": "(?:fibre|fiber)\\s*:?\\s*(\\d+\\.?\\d*)\\s*g",
            "sodium": "sodium\\s*:?\\s*(\\d+\\.?\\d*)\\s*(?:mg|g)"
        ]

        let lowerText = text.lowercased()

        for (key, pattern) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(lowerText.startIndex..., in: lowerText)
                if let match = regex.firstMatch(in: lowerText, range: range),
                   match.numberOfRanges > 1,
                   let valueRange = Range(match.range(at: 1), in: lowerText) {
                    let valueStr = String(lowerText[valueRange])
                    if let value = Double(valueStr) {
                        nutrition[key] = value
                    }
                }
            }
        }

        return nutrition
    }

    private func isRelevantForCurrentStep(_ text: String) -> Bool {
        let lowerText = text.lowercased()

        switch scanningStep {
        case .ingredients:
            // Look for ingredient markers
            let ingredientKeywords = ["ingredients", "contains", "wheat", "milk", "water", "flour", "sugar", "salt"]
            return ingredientKeywords.contains(where: { lowerText.contains($0) })

        case .nutrition:
            // Look for nutrition markers
            let nutritionKeywords = ["energy", "calories", "protein", "carbohydrate", "fat", "sugar", "fiber", "sodium", "per 100g", "per serving"]
            return nutritionKeywords.contains(where: { lowerText.contains($0) })

        case .complete:
            return false
        }
    }

    private func checkIfReadyToComplete() {
        let wasReady = isReadyToComplete

        switch scanningStep {
        case .ingredients:
            // Check if we have at least 3 ingredients detected
            let relevantText = textBlocks.filter { isRelevantForCurrentStep($0.text) }
            isReadyToComplete = accumulatedText.count >= 3 && relevantText.count >= 2

        case .nutrition:
            // Check if we have detected key nutrition values
            let detectedText = Array(accumulatedText).joined(separator: " ")
            let nutritionData = parseNutritionFromText(detectedText)
            isReadyToComplete = nutritionData.count >= 3

        case .complete:
            isReadyToComplete = true
        }

        // Update highlighted regions for visual feedback
        highlightedRegions = textBlocks.filter { isRelevantForCurrentStep($0.text) }

        // Don't auto-advance or show checkmark - user must manually click Next
        // Just update the UI to show "Ready" indicator in the bottom panel
        if !isReadyToComplete && wasReady {
            // Cancel any pending timers if we're no longer ready
            autoAdvanceTimer?.invalidate()
            autoAdvanceTimer = nil
        }
    }

    private func processTextWithGemini(textChunks: [String], finalProcess: Bool) async -> ProcessedTextResult {
        guard let apiKey = AppConfig.APIKeys.geminiKey, !apiKey.isEmpty else {
            print("⚠️ Gemini API key not configured, falling back to basic processing")
            let processedText = textChunks.joined(separator: " ")
            return ProcessedTextResult(
                cleanedText: processedText,
                structuredData: [
                    "ingredients": textChunks,
                    "confidence": confidence
                ],
                confidence: confidence
            )
        }

        let rawText = textChunks.joined(separator: " ")

        // Build prompt based on scan type
        let prompt: String
        switch scanType {
        case .ingredients:
            prompt = """
            Extract and clean the ingredients list from this OCR text. Remove any noise, correct OCR errors, and format as a clean comma-separated list.

            OCR Text: \(rawText)

            Return ONLY the cleaned ingredients list, nothing else.
            """
        case .nutrition:
            prompt = """
            Extract nutrition facts from this OCR text. Parse values for calories, protein, carbs, fat, sugar, fiber, and sodium per 100g.

            OCR Text: \(rawText)

            Return as JSON with keys: calories, protein, carbs, fat, sugar, fiber, sodium. All values should be numbers per 100g.
            """
        case .barcode:
            prompt = """
            Extract any barcode or product code from this OCR text. Look for EAN, UPC, or other numeric codes.

            OCR Text: \(rawText)

            Return ONLY the barcode number, nothing else.
            """
        }

        do {
            let result = try await callGeminiAPI(prompt: prompt, apiKey: apiKey)

            // Parse structured data if it's JSON
            var structuredData: [String: Any]?
            if scanType == .nutrition,
               let data = result.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                structuredData = json
            } else {
                structuredData = [
                    "rawResult": result,
                    "scanType": scanType.rawValue
                ]
            }

            return ProcessedTextResult(
                cleanedText: result,
                structuredData: structuredData,
                confidence: confidence
            )
        } catch {
            print("❌ Gemini API error: \(error)")
            // Fallback to basic processing
            let processedText = textChunks.joined(separator: " ")
            return ProcessedTextResult(
                cleanedText: processedText,
                structuredData: [
                    "ingredients": textChunks,
                    "confidence": confidence,
                    "error": error.localizedDescription
                ],
                confidence: confidence
            )
        }
    }

    private func callGeminiAPI(prompt: String, apiKey: String) async throws -> String {
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=\(apiKey)"

        guard let url = URL(string: endpoint) else {
            throw NSError(domain: "GeminiAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid API endpoint"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "maxOutputTokens": 2048
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "GeminiAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Gemini API error (\(httpResponse.statusCode)): \(errorMessage)")
            throw NSError(domain: "GeminiAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API returned status \(httpResponse.statusCode)"])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw NSError(domain: "GeminiAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse API response"])
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension LiveTextScannerService: @preconcurrency AVCaptureVideoDataOutputSampleBufferDelegate {
    
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        Task { @MainActor in
            guard let textDetectionRequest = self.textDetectionRequest else { return }
            
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
            
            do {
                try imageRequestHandler.perform([textDetectionRequest])
            } catch {
                print("Failed to perform text detection: \(error)")
            }
        }
    }
}