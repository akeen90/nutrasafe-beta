//
//  AddFoodAIView.swift
//  NutraSafe Beta
//
//  AI Food Scanning System - Extracted from ContentView.swift
//  This file contains all AI food recognition and scanning functionality
//

import SwiftUI
import Vision
import AVFoundation
import AudioToolbox

// MARK: - AI Food Scanner Main View (DIARY-ONLY)

struct AddFoodAIView: View {
    @Binding var selectedTab: TabItem
    @State private var isScanning = false
    @State private var recognizedFoods: [FoodSearchResult] = []
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingCombinedMealView = false
    @State private var combinedMealFoods: [FoodSearchResult] = []
    @State private var showingFoodDetail = false
    @State private var selectedFoodForDetail: FoodSearchResult?
    @State private var hasLaunchedCamera = false  // Prevents re-launching camera on state changes
    @State private var errorMessage: String?  // Shows errors to user
    @State private var showingGalleryPicker = false  // For photo library selection
    
    var body: some View {
        VStack(spacing: 20) {
            if !isScanning && recognizedFoods.isEmpty {
                // Initial state - shown when user cancelled or error occurred
                VStack(spacing: 24) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(Color.blue)

                    VStack(spacing: 8) {
                        Text("AI Food Scanner")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Take a photo of your food and we'll identify items")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Show error message if there was a problem
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    VStack(spacing: 12) {
                        Button(action: {
                            hasLaunchedCamera = true
                            errorMessage = nil
                            startAIScanning()
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Take Photo")
                            }
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }

                        Button(action: {
                            hasLaunchedCamera = true
                            errorMessage = nil
                            selectFromGallery()
                        }) {
                            HStack {
                                Image(systemName: "photo.fill")
                                Text("Choose from Gallery")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 32)
                
            } else if isScanning {
                // Scanning state
                VStack(spacing: 20) {
                    Text("Analysing Image")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.primary)

                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()

                    Text("AI is analysing your food...")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
            } else if !recognizedFoods.isEmpty {
                // Results state
                VStack(spacing: 16) {
                    Text("Foods Detected")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    AIFoodSelectionView(
                        recognizedFoods: recognizedFoods,
                        onSelectionComplete: { selectedFoods in
                            // Handle selected foods - either show combined view or individual detail
                            handleAIFoodSelection(selectedFoods)
                        },
                        onScanAnother: {
                            recognizedFoods = []
                        },
                        selectedTab: $selectedTab
                    )
                }
            }
            
            Spacer()
        }
        .padding(.top, 20)
        // Removed auto-launch - user chooses camera or gallery from the initial screen
        .fullScreenCover(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera) { image in
                showingImagePicker = false
                if let image = image {
                    // NOW start showing the scanning state (after photo is taken)
                    isScanning = true
                    errorMessage = nil
                    analyzeImage(image)
                } else {
                    // User cancelled - allow them to try again
                    hasLaunchedCamera = false
                }
            }
        }
        .fullScreenCover(isPresented: $showingCombinedMealView) {
            CombinedMealView(foods: combinedMealFoods) {
                showingCombinedMealView = false
                combinedMealFoods = []
            }
        }
        .fullScreenCover(isPresented: $showingFoodDetail) {
            if let food = selectedFoodForDetail {
                NavigationView {
                    FoodDetailViewFromSearch(food: food, selectedTab: $selectedTab)
                }
            }
        }
        .sheet(isPresented: $showingGalleryPicker) {
            MultiImagePicker(maxSelection: 1) { images in
                showingGalleryPicker = false
                if let image = images.first {
                    isScanning = true
                    errorMessage = nil
                    analyzeImage(image)
                } else {
                    // User cancelled
                    hasLaunchedCamera = false
                }
            }
        }
    }
    
    private func startAIScanning() {
        // Request camera permission first
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            presentImagePicker()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.presentImagePicker()
                    } else {
                        // Show permission denied message
                        #if DEBUG
                        print("Camera permission denied")
                        #endif
                    }
                }
            }
        case .denied, .restricted:
            // Show settings alert to enable camera
            #if DEBUG
            print("Camera permission denied - redirect to settings")
            #endif
        @unknown default:
            break
        }
    }
    
    private func presentImagePicker() {
        // Only show the camera - don't set isScanning yet
        // isScanning will be set AFTER user takes a photo
        showingImagePicker = true
    }
    
    private func handleAIFoodSelection(_ selectedFoods: [FoodSearchResult]) {
        if selectedFoods.count == 1 {
            let food = selectedFoods[0]
            // Check if it's likely a branded product (high confidence)
            if let confidence = food.confidence, confidence > 0.8 {
                // High confidence single item - likely branded product, go to detail page
                selectedFoodForDetail = food
                showingFoodDetail = true
            } else {
                // Lower confidence single item - might be generic food, show combined meal view
                combinedMealFoods = selectedFoods
                showingCombinedMealView = true
            }
            recognizedFoods = [] // Clear AI scanner results
        } else if selectedFoods.count > 1 {
            // Multiple foods - show combined meal view for plate of food
            combinedMealFoods = selectedFoods
            showingCombinedMealView = true
            recognizedFoods = [] // Clear AI scanner results
        }
    }
    
    private func analyzeImage(_ image: UIImage) {
        // isScanning should already be true (set before this is called)
        recognizedFoods = []
        errorMessage = nil

        #if DEBUG
        print("📸 Starting food recognition...")
        print("   Image size: \(Int(image.size.width))x\(Int(image.size.height))")
        #endif

        Task {
            do {
                let recognizedItems = try await recognizeFoodWithRetry(from: image, maxRetries: 2)
                await MainActor.run {
                    self.isScanning = false
                    if recognizedItems.isEmpty {
                        self.errorMessage = "No food items detected. Try taking another photo with better lighting."
                        self.hasLaunchedCamera = false
                        #if DEBUG
                        print("⚠️ No foods detected in image")
                        #endif
                    } else {
                        self.recognizedFoods = recognizedItems
                        #if DEBUG
                        print("✅ Detected \(recognizedItems.count) food items")
                        #endif
                    }
                }
            } catch let error as NSError {
                await MainActor.run {
                    self.isScanning = false
                    self.hasLaunchedCamera = false

                    // Provide user-friendly error messages
                    if error.domain == NSURLErrorDomain {
                        switch error.code {
                        case NSURLErrorTimedOut:
                            self.errorMessage = "Request timed out. Please check your connection and try again."
                        case NSURLErrorNotConnectedToInternet:
                            self.errorMessage = "No internet connection. Please connect and try again."
                        case NSURLErrorCannotConnectToHost:
                            self.errorMessage = "Cannot reach server. Please try again later."
                        default:
                            self.errorMessage = "Network error. Please check your connection."
                        }
                    } else if error.code >= 500 {
                        self.errorMessage = "Server error. Please try again in a moment."
                    } else if error.code >= 400 {
                        self.errorMessage = "Invalid request. Please try a different photo."
                    } else {
                        self.errorMessage = "Failed to analyse image. Please try again."
                    }

                    #if DEBUG
                    print("❌ Food recognition failed: \(error.localizedDescription)")
                    print("   Domain: \(error.domain), Code: \(error.code)")
                    #endif
                }
            }
        }
    }

    private func recognizeFoodWithRetry(from image: UIImage, maxRetries: Int) async throws -> [FoodSearchResult] {
        var lastError: Error?

        for attempt in 0...maxRetries {
            do {
                #if DEBUG
                if attempt > 0 {
                    print("🔄 Retry attempt \(attempt) of \(maxRetries)")
                }
                #endif
                return try await recognizeFood(from: image)
            } catch {
                lastError = error
                #if DEBUG
                print("⚠️ Attempt \(attempt + 1) failed: \(error.localizedDescription)")
                #endif

                // Only retry on network errors, not server errors
                if let nsError = error as NSError?,
                   nsError.domain == NSURLErrorDomain,
                   attempt < maxRetries {
                    // Wait before retry (exponential backoff)
                    try await Task.sleep(nanoseconds: UInt64(500_000_000 * (attempt + 1)))
                    continue
                }
                throw error
            }
        }

        throw lastError ?? NSError(domain: "AddFoodAIView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])
    }
    
    private func recognizeFood(from image: UIImage) async throws -> [FoodSearchResult] {
        // Resize image if too large (max 1920px on longest side for faster upload)
        let maxDimension: CGFloat = 1920
        var processedImage = image
        if max(image.size.width, image.size.height) > maxDimension {
            let scale = maxDimension / max(image.size.width, image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            processedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
            #if DEBUG
            print("   Resized image to \(Int(newSize.width))x\(Int(newSize.height))")
            #endif
        }

        // Compress image for upload (0.8 for better quality)
        guard let imageData = processedImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to process image"])
        }

        let base64Image = imageData.base64EncodedString()
        let imageSizeKB = imageData.count / 1024

        #if DEBUG
        print("   Compressed image size: \(imageSizeKB) KB")
        print("   Calling Firebase recognizeFood function...")
        #endif

        // Call Firebase function for AI food recognition
        let urlString = "https://us-central1-nutrasafe-705c7.cloudfunctions.net/recognizeFood"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "AddFoodAIView", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid recognition URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90  // 90 second timeout (match Firebase function)

        let body = ["image": base64Image]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        #if DEBUG
        let startTime = Date()
        #endif

        let (data, response) = try await URLSession.shared.data(for: request)

        #if DEBUG
        let elapsed = Date().timeIntervalSince(startTime)
        print("   Response received in \(String(format: "%.1f", elapsed))s")
        #endif

        // Check HTTP status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "AddFoodAIView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
        }

        #if DEBUG
        print("   HTTP status: \(httpResponse.statusCode)")
        #endif

        if httpResponse.statusCode != 200 {
            #if DEBUG
            if let errorText = String(data: data, encoding: .utf8) {
                print("   Error response: \(errorText.prefix(500))")
            }
            #endif
            throw NSError(domain: "AddFoodAIView", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])
        }

        // Decode response
        do {
            let decodedResponse = try JSONDecoder().decode(FoodRecognitionResponse.self, from: data)

            #if DEBUG
            print("   Decoded \(decodedResponse.foods.count) food items")
            for food in decodedResponse.foods {
                let source = (food.isFromDatabase ?? false) ? "DB" : "AI"
                print("   - \(food.name) [\(source)] \(Int(food.calories)) kcal")
            }
            #endif

            return decodedResponse.foods.map { foodItem in
                let portionGrams = foodItem.portionGrams ?? 100
                let isVerified = foodItem.isFromDatabase ?? false
                let servingDesc = isVerified
                    ? "\(Int(portionGrams))g (verified)"
                    : "\(Int(portionGrams))g (AI estimate)"

                return FoodSearchResult(
                    id: foodItem.databaseId ?? UUID().uuidString,
                    name: foodItem.name,
                    brand: foodItem.brand,
                    calories: foodItem.calories,
                    protein: foodItem.protein,
                    carbs: foodItem.carbs,
                    fat: foodItem.fat,
                    fiber: foodItem.fiber ?? 0,
                    sugar: foodItem.sugar ?? 0,
                    sodium: foodItem.sodium ?? 0,
                    servingDescription: servingDesc,
                    ingredients: foodItem.ingredients.map { [$0] },
                    confidence: foodItem.confidence,
                    isVerified: isVerified
                )
            }
        } catch {
            #if DEBUG
            print("   JSON decode error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("   Raw response: \(jsonString.prefix(500))")
            }
            #endif
            throw NSError(domain: "AddFoodAIView", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse server response"])
        }
    }
    
    private func selectFromGallery() {
        showingGalleryPicker = true
    }
}

// MARK: - Supporting Input Components

struct NutritionInputRow: View {
    let label: String
    @Binding var value: String
    let unit: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)
            
            TextField("0", text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
            
            Text(unit)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)
        }
    }
}

// MARK: - Image Picker for AI Scanner

struct ImagePicker: UIViewControllerRepresentable {
    var selectedImage: Binding<UIImage?>?
    var sourceType: UIImagePickerController.SourceType = .camera
    let onImageSelected: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        #if DEBUG
        print("📸 ImagePicker makeUIViewController - sourceType: \(sourceType == .camera ? "CAMERA" : "PHOTO LIBRARY")")
        #endif
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = false

        // Disable rotation - lock to portrait only
        picker.navigationBar.isHidden = false

        // Override supported orientations for camera
        picker.modalPresentationStyle = .fullScreen

        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        // Lock camera to portrait orientation
        func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
            return .portrait
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage?.wrappedValue = image
                parent.onImageSelected(image)
            }
            // Don't dismiss here - let parent view control dismissal via sheet binding
            // This allows async operations (like photo upload) to complete before dismissal
            // picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onImageSelected(nil)
            // Don't dismiss here - let parent view control dismissal via sheet binding
            // picker.dismiss(animated: true)
        }
    }
}

// MARK: - Multi Image Picker (for Photo Library)
import PhotosUI

struct MultiImagePicker: UIViewControllerRepresentable {
    let maxSelection: Int
    let onImagesSelected: ([UIImage]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        // Always allow multiple selection to prevent auto-dismiss on single tap
        // We'll limit the number added in the callback instead
        config.selectionLimit = 0 // 0 means unlimited
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MultiImagePicker

        init(_ parent: MultiImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            #if DEBUG
            print("📸 MultiImagePicker: User finished picking \(results.count) photos")
            #endif
            picker.dismiss(animated: true)

            guard !results.isEmpty else {
                #if DEBUG
                print("⚠️ MultiImagePicker: User cancelled - no photos selected")
                #endif
                parent.onImagesSelected([])
                return
            }

            var images: [UIImage] = []
            let group = DispatchGroup()

            for result in results {
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    defer { group.leave() }
                    if let image = object as? UIImage {
                        images.append(image)
                        #if DEBUG
                        print("✅ MultiImagePicker: Successfully loaded image")
                        #endif
                    } else {
                        #if DEBUG
                        print("❌ MultiImagePicker: Failed to load image: \(error?.localizedDescription ?? "unknown error")")
                        #endif
                    }
                }
            }

            group.notify(queue: .main) {
                #if DEBUG
                print("📦 MultiImagePicker: Returning \(images.count) images to callback")
                #endif
                self.parent.onImagesSelected(images)
            }
        }
    }
}

// MARK: - AI Food Selection Views

struct AIFoodSelectionView: View {
    let recognizedFoods: [FoodSearchResult]
    let onSelectionComplete: ([FoodSearchResult]) -> Void
    let onScanAnother: () -> Void
    @Binding var selectedTab: TabItem

    @State private var selectedFoods: Set<String> = []
    @State private var showingFoodDetail = false
    @State private var selectedFood: FoodSearchResult?
    
    // Sort foods by confidence (highest first)
    private var sortedFoods: [FoodSearchResult] {
        recognizedFoods.sorted { ($0.confidence ?? 0) > ($1.confidence ?? 0) }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(sortedFoods, id: \.id) { food in
                        AIFoodSelectionRow(
                            food: food,
                            isSelected: selectedFoods.contains(food.id),
                            onToggleSelection: {
                                toggleFoodSelection(food)
                            },
                            onViewDetails: {
                                selectedFood = food
                                showingFoodDetail = true
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // Action buttons
            VStack(spacing: 12) {
                if selectedFoods.count > 0 {
                    Button(action: {
                        let selected = sortedFoods.filter { selectedFoods.contains($0.id) }
                        onSelectionComplete(selected)
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Add Selected (\(selectedFoods.count))")
                                .font(.headline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 16)
                }
                
                Button("Scan Another") {
                    onScanAnother()
                }
                .foregroundColor(Color.blue)
                .padding(.bottom, 16)
            }
        }
        .fullScreenCover(isPresented: $showingFoodDetail) {
            if let food = selectedFood {
                NavigationView {
                    FoodDetailViewFromSearch(food: food, selectedTab: $selectedTab)
                }
            }
        }
    }

    private func toggleFoodSelection(_ food: FoodSearchResult) {
        if selectedFoods.contains(food.id) {
            selectedFoods.remove(food.id)
        } else {
            selectedFoods.insert(food.id)
        }
    }
}

struct AIFoodSelectionRow: View {
    let food: FoodSearchResult
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onViewDetails: () -> Void
    
    private func getNutraSafeColor(_ grade: String) -> Color {
        switch grade.uppercased() {
        case "A", "A+":
            return .green
        case "B":
            return .mint
        case "C":
            return .orange
        case "D", "E", "F":
            return .red
        default:
            return .gray
        }
    }
    
    // Calculate per-serving calories from per-100g values
    private var perServingCalories: Double {
        let servingSize = extractServingSize(from: food.servingDescription)
        return food.calories * (servingSize / 100.0)
    }
    
    // Extract serving size in grams from serving description
    private func extractServingSize(from servingDesc: String?) -> Double {
        guard let servingDesc = servingDesc else { return 100.0 }
        
        // Try to extract numbers from serving description like "39.4g", "1 container (150g)" or "1/2 cup (98g)"
        let patterns = [
            #"(\d+(?:\.\d+)?)\s*g"#,  // Match "39.4g" or "39.4 g"
            #"\((\d+(?:\.\d+)?)\s*g\)"#  // Match "(150g)" in parentheses
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: servingDesc, options: [], range: NSRange(location: 0, length: servingDesc.count)),
               let range = Range(match.range(at: 1), in: servingDesc) {
                return Double(String(servingDesc[range])) ?? 100.0
            }
        }
        
        // If just a number is found, assume it's grams
        if let number = Double(servingDesc.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return number
        }
        
        // Fallback to 100g if no weight found
        return 100.0
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox
            Button(action: onToggleSelection) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            
            // Food info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(food.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Confidence indicator
                    if let confidence = food.confidence {
                        Text("\(Int(confidence * 100))%")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                if let brand = food.brand, !brand.isEmpty {
                    Text(brand)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 16) {
                    // Verified indicator (green tick)
                    if food.isVerified {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color.blue)
                    }
                    
                    // NutraSafe grade
                    let ns = ProcessingScorer.shared.computeNutraSafeProcessingGrade(for: food)
                    Text(ns.grade)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(getNutraSafeColor(ns.grade))
                        .clipShape(Circle())
                    
                    // Calories
                    VStack(spacing: 2) {
                        Text("\(Int(perServingCalories))")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        Text("kcal")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Details button
                    Button(action: onViewDetails) {
                        Text("Details")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Combined Meal Management

struct CombinedMealView: View {
    let foods: [FoodSearchResult]
    let onDismiss: () -> Void

    @State private var servingSizes: [String: Double] = [:]
    @State private var selectedMealType: MealType = .lunch
    @State private var showingSuccessAlert = false
    @State private var showingPaywall = false
    @State private var showingLimitError = false

    // PERFORMANCE: Cache nutrition totals to prevent redundant calculations on every render
    // Pattern from Clay's production app: move expensive operations to cached state
    @State private var cachedTotalCalories: Double = 0
    @State private var cachedTotalProtein: Double = 0
    @State private var cachedTotalCarbs: Double = 0
    @State private var cachedTotalFat: Double = 0

    @EnvironmentObject var firebaseManager: FirebaseManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    // Update cached nutrition totals when data changes
    private func updateCachedNutritionTotals() {
        cachedTotalCalories = foods.reduce(0) { total, food in
            let multiplier = servingSizes[food.id] ?? 1.0
            return total + (food.calories * multiplier)
        }
        cachedTotalProtein = foods.reduce(0) { total, food in
            let multiplier = servingSizes[food.id] ?? 1.0
            return total + (food.protein * multiplier)
        }
        cachedTotalCarbs = foods.reduce(0) { total, food in
            let multiplier = servingSizes[food.id] ?? 1.0
            return total + (food.carbs * multiplier)
        }
        cachedTotalFat = foods.reduce(0) { total, food in
            let multiplier = servingSizes[food.id] ?? 1.0
            return total + (food.fat * multiplier)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Your Meal")
                        .font(.title2.bold())
                    Text("Adjust quantities below")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Meal Type Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meal Type")
                        .font(.headline)
                    
                    Picker("Meal Type", selection: $selectedMealType) {
                        ForEach(MealType.allCases, id: \.self) { mealType in
                            Text(mealType.rawValue.capitalized).tag(mealType)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)
                
                // Food List
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(foods, id: \.id) { food in
                            CombinedMealFoodRow(
                                food: food,
                                servingSize: servingSizes[food.id] ?? 1.0
                            ) { newServingSize in
                                servingSizes[food.id] = newServingSize
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Totals Summary
                VStack(spacing: 8) {
                    Divider()
                    
                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(totalCalories)) cal")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        NutrientSummaryMacros(label: "Protein", value: totalProtein, unit: "g", color: .blue)
                        Spacer()
                        NutrientSummaryMacros(label: "Carbs", value: totalCarbs, unit: "g", color: .orange)
                        Spacer()
                        NutrientSummaryMacros(label: "Fat", value: totalFat, unit: "g", color: Color.blue)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Save Button
                Button(action: saveCombinedMeal) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Add All Foods to Diary")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Combined Meal")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    onDismiss()
                }
            )
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK") {
                onDismiss()
            }
        } message: {
            Text("All \(foods.count) foods have been added to your diary.")
        }
        .diaryLimitAlert(
            isPresented: $showingLimitError,
            showingPaywall: $showingPaywall
        )
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView()
        }
        .onAppear {
            // Initialize serving sizes
            for food in foods {
                if servingSizes[food.id] == nil {
                    servingSizes[food.id] = 1.0
                }
            }
            // PERFORMANCE: Initialize cached nutrition totals on first appearance
            updateCachedNutritionTotals()
        }
        // PERFORMANCE: Update cached totals only when serving sizes change
        .onChange(of: servingSizes) { updateCachedNutritionTotals() }
    }
    
    private var totalCalories: Double { cachedTotalCalories }
    private var totalProtein: Double { cachedTotalProtein }
    private var totalCarbs: Double { cachedTotalCarbs }
    private var totalFat: Double { cachedTotalFat }
    
    private func saveCombinedMeal() {
        Task {
            do {
                let currentDate = Date()
                let hasAccess = subscriptionManager.hasAccess

                for food in foods {
                    let multiplier = servingSizes[food.id] ?? 1.0

                    let entry = FoodEntry(
                        userId: firebaseManager.currentUser?.uid ?? "anonymous",
                        foodName: food.name,
                        brandName: food.brand,
                        servingSize: multiplier,
                        servingUnit: "portion",
                        calories: food.calories * multiplier,
                        protein: food.protein * multiplier,
                        carbohydrates: food.carbs * multiplier,
                        fat: food.fat * multiplier,
                        fiber: food.fiber * multiplier,
                        sugar: food.sugar * multiplier,
                        sodium: food.sodium * multiplier,
                        mealType: selectedMealType,
                        date: currentDate
                    )

                    try await firebaseManager.saveFoodEntry(entry, hasProAccess: hasAccess)
                }

                await MainActor.run {
                    showingSuccessAlert = true
                }
            } catch let error as FirebaseManager.DiaryLimitError {
                #if DEBUG
                print("Diary limit reached: \(error.localizedDescription)")
                #endif
                await MainActor.run {
                    showingLimitError = true
                }
            } catch {
                #if DEBUG
                print("Error saving combined meal: \(error)")
                #endif
            }
        }
    }
}

struct CombinedMealFoodRow: View {
    let food: FoodSearchResult
    let servingSize: Double
    let onServingSizeChange: (Double) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Food Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.headline)
                        .lineLimit(2)
                    
                    if let brand = food.brand, !brand.isEmpty {
                        Text(brand)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Confidence if available
                    if let confidence = food.confidence {
                        Text("\(Int(confidence * 100))% confidence")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                // Calories
                Text("\(Int(food.calories * servingSize)) cal")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            // Quantity Controls
            HStack {
                Text("Quantity")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: {
                        let newSize = max(0.5, servingSize - 0.5)
                        onServingSizeChange(newSize)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                    
                    Text(formatQuantity(servingSize))
                        .font(.headline)
                        .frame(minWidth: 80)
                    
                    Button(action: {
                        let newSize = servingSize + 0.5
                        onServingSizeChange(newSize)
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color.blue)
                    }
                }
            }
            
            // Nutrition Summary
            HStack {
                NutrientPill(label: "P", value: food.protein * servingSize, unit: "g", color: .blue)
                NutrientPill(label: "C", value: food.carbs * servingSize, unit: "g", color: .orange)
                NutrientPill(label: "F", value: food.fat * servingSize, unit: "g", color: Color.blue)
                Spacer()
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func formatQuantity(_ quantity: Double) -> String {
        if quantity == 1.0 {
            return "1 portion"
        } else if quantity == 0.5 {
            return "½ portion"
        } else if quantity == 1.5 {
            return "1½ portions"
        } else if quantity == 2.0 {
            return "2 portions"
        } else if quantity == 2.5 {
            return "2½ portions"
        } else if quantity == 3.0 {
            return "3 portions"
        } else if quantity < 1.0 {
            return "Small"
        } else if quantity >= 4.0 {
            return "Large"
        } else {
            return "\(String(format: "%.1f", quantity)) portions"
        }
    }
}

// MARK: - Supporting Nutrient Display Components

struct NutrientSummaryMacros: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(String(format: "%.1f", value))\(unit)")
                .font(.subheadline.bold())
                .foregroundColor(color)
        }
    }
}

struct NutrientPill: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.caption.bold())
                .foregroundColor(.white)
            Text(String(format: "%.1f", value))
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color)
        .cornerRadius(10)
    }
}

// MARK: - String Constants (Local)

private struct LocalStringConstants {
    static let aiTitle = "AI Food Recognition"
    static let aiDescription = "Take a photo of your meal and our AI will identify the foods and estimate portions"
    static let takePhoto = "Take Photo"
    static let chooseFromGallery = "Choose from Gallery"
    static let analysingImage = "Analysing Image..."
    static let aiAnalysing = "AI is identifying foods in your image"
    static let foodsDetected = "Foods Detected"
    static let scanAnother = "Scan Another"
    static let details = "Details"
    static let yourMeal = "Your Meal"
    static let adjustQuantities = "Adjust quantities for each food item"
    static let mealType = "Meal Type"
    static let total = "Total:"
    static let quantity = "Quantity:"
    static let addAllFoodsToDiary = "Add All Foods to Diary"
    static let combinedMeal = "Combined Meal"
    static let cancel = "Cancel"
    static let success = "Success!"
}

// MARK: - Atomic Constants (Local)

private struct LocalAtomicConstants {
    static let iconSizeLarge: CGFloat = 80
    static let fontSizeLarge: CGFloat = 24
    static let fontSizeMediumLarge: CGFloat = 18
    static let fontSizeExtraSmall: CGFloat = 10
    static let spacing24: CGFloat = 24
    static let labelWidth80: CGFloat = 80
    static let unitWidth40: CGFloat = 40
    static let circleSize24: CGFloat = 24
    static let cornerRadius4: CGFloat = 4
    static let cornerRadius6: CGFloat = 6
    static let cornerRadius10: CGFloat = 10
    static let padding2: CGFloat = 2
    static let padding4: CGFloat = 4
    static let padding6: CGFloat = 6
    static let padding14: CGFloat = 14
    static let padding32: CGFloat = 32
    static let minQuantityWidth80: CGFloat = 80
}