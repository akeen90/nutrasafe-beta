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
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var diaryDataManager: DiaryDataManager
    @EnvironmentObject var firebaseManager: FirebaseManager
    @EnvironmentObject var fastingViewModelWrapper: FastingViewModelWrapper
    @State private var isScanning = false
    @State private var recognizedFoods: [FoodSearchResult] = []
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingCombinedMealView = false
    @State private var combinedMealFoods: [FoodSearchResult] = []
    @State private var selectedFoodForDetail: FoodSearchResult?
    @State private var hasLaunchedCamera = false  // Prevents re-launching camera on state changes
    @State private var errorMessage: String?  // Shows errors to user
    @State private var showingGalleryPicker = false  // For photo library selection
    // Pro feature gate for non-subscribers
    @State private var showingProFeatureGate = false
    @State private var capturedImageForGate: UIImage?
    @State private var showingPaywall = false
    
    // Check if user has Pro access
    private var hasProAccess: Bool {
        subscriptionManager.isSubscribed || subscriptionManager.isInTrial || subscriptionManager.isPremiumOverride
    }

    var body: some View {
        VStack(spacing: 20) {
            if showingProFeatureGate {
                // Pro Feature Gate - shown after photo taken for non-subscribers
                proFeatureGateView

            } else if !isScanning && recognizedFoods.isEmpty {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.adaptiveCard)
        // Removed auto-launch - user chooses camera or gallery from the initial screen
        .fullScreenCover(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera) { [self] image in
                showingImagePicker = false
                if let image = image {
                    // Check subscription status directly from the manager
                    let isSubscribed = subscriptionManager.isSubscribed
                    let isInTrial = subscriptionManager.isInTrial
                    let isPremiumOverride = subscriptionManager.isPremiumOverride
                    let hasPro = isSubscribed || isInTrial || isPremiumOverride

                    
                    if hasPro {
                        // Pro user - proceed with analysis
                        isScanning = true
                        errorMessage = nil
                                                analyzeImage(image)
                    } else {
                        // Non-subscriber - show Pro feature gate
                        capturedImageForGate = image
                        showingProFeatureGate = true
                                            }
                } else {
                    // User cancelled OR image extraction failed
                    hasLaunchedCamera = false
                    // Check if this was a failure vs cancellation
                    if selectedImage == nil {
                        errorMessage = "Failed to capture image. Please try again."
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingCombinedMealView) {
            CombinedMealView(
                foods: combinedMealFoods,
                onDismiss: {
                    showingCombinedMealView = false
                    combinedMealFoods = []
                },
                onSaveComplete: {
                    // Dismiss CombinedMealView and AddFoodAIView, go back to diary
                    showingCombinedMealView = false
                    combinedMealFoods = []
                    selectedTab = .diary
                    dismiss()
                }
            )
        }
        .sheet(item: $selectedFoodForDetail) { food in
            NavigationView {
                // Use constant binding to prevent Details view from changing main tab while in AI scanner
                FoodDetailViewFromSearch(food: food, selectedTab: .constant(.diary), fastingViewModel: fastingViewModelWrapper.viewModel)
            }
            .environmentObject(diaryDataManager)
            .environmentObject(subscriptionManager)
            .environmentObject(firebaseManager)
        }
        .sheet(isPresented: $showingGalleryPicker) {
            MultiImagePicker(maxSelection: 1) { [self] images in
                // First dismiss the picker
                showingGalleryPicker = false

                // Then process the result after a brief delay to ensure clean dismissal
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
                    if let image = images.first {
                        // Check subscription status directly from the manager
                        let isSubscribed = subscriptionManager.isSubscribed
                        let isInTrial = subscriptionManager.isInTrial
                        let isPremiumOverride = subscriptionManager.isPremiumOverride
                        let hasPro = isSubscribed || isInTrial || isPremiumOverride

                        
                        if hasPro {
                            // Pro user - proceed with analysis
                            isScanning = true
                            errorMessage = nil
                                                        analyzeImage(image)
                        } else {
                            // Non-subscriber - show Pro feature gate
                            capturedImageForGate = image
                            showingProFeatureGate = true
                                                    }
                    } else {
                        // User cancelled or image loading failed
                        hasLaunchedCamera = false
                        // Only show error if this wasn't an explicit cancel (images array was expected)
                                            }
                }
            }
        }
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView()
                .environmentObject(subscriptionManager)
        }
        .onChange(of: subscriptionManager.isSubscribed) { _, isSubscribed in
            // If user subscribed via paywall, dismiss gate and analyze the image
            if isSubscribed && showingProFeatureGate {
                showingPaywall = false
                showingProFeatureGate = false
                if let image = capturedImageForGate {
                    isScanning = true
                    errorMessage = nil
                    analyzeImage(image)
                    capturedImageForGate = nil
                }
            }
        }
    }

    // MARK: - Pro Feature Gate View
    private var proFeatureGateView: some View {
        VStack(spacing: 24) {
            // Image preview (thumbnail of captured photo)
            if let image = capturedImageForGate {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }

            // Pro badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                Image(systemName: "star.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }

            VStack(spacing: 8) {
                Text("AI Meal Scan is a Pro Feature")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text("Upgrade to unlock AI-powered food recognition and automatic nutrition logging")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 12) {
                Button(action: {
                    showingPaywall = true
                }) {
                    HStack {
                        Image(systemName: "lock.open.fill")
                        Text("Unlock Pro")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }

                Button(action: {
                    // Reset and go back to initial state
                    showingProFeatureGate = false
                    capturedImageForGate = nil
                    hasLaunchedCamera = false
                }) {
                    Text("Maybe Later")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 32)
        }
        .padding(.horizontal, 24)
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
                    }
                    // If not granted, user can try again later
                }
            }
        case .denied, .restricted:
            // Show settings alert to enable camera - handled by UI
            break
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

        
        Task {
            do {
                let recognizedItems = try await recognizeFoodWithRetry(from: image, maxRetries: 2)
                await MainActor.run {
                    self.isScanning = false
                    if recognizedItems.isEmpty {
                        self.errorMessage = "No food items detected. Try taking another photo with better lighting."
                        self.hasLaunchedCamera = false
                                            } else {
                        self.recognizedFoods = recognizedItems
                                            }
                }
            } catch let error as NSError {
                await MainActor.run {
                    self.isScanning = false
                    self.hasLaunchedCamera = false

                    // Build diagnostic info for error message
                    let diagInfo = "[\(error.domain):\(error.code)]"

                    // Provide user-friendly error messages based on domain and code
                    if error.domain == NSURLErrorDomain {
                        switch error.code {
                        case NSURLErrorTimedOut:
                            self.errorMessage = "Request timed out \(diagInfo). Check connection."
                        case NSURLErrorNotConnectedToInternet:
                            self.errorMessage = "No internet connection \(diagInfo)."
                        case NSURLErrorCannotConnectToHost:
                            self.errorMessage = "Cannot reach server \(diagInfo)."
                        case NSURLErrorNetworkConnectionLost:
                            self.errorMessage = "Connection lost during upload \(diagInfo)."
                        case NSURLErrorSecureConnectionFailed:
                            self.errorMessage = "Secure connection failed \(diagInfo)."
                        default:
                            self.errorMessage = "Network error \(diagInfo). Check connection."
                        }
                    } else if error.domain == "AddFoodAIView" {
                        // Custom errors from our code - show detailed message
                        let detail = error.userInfo[NSLocalizedDescriptionKey] as? String ?? ""
                        switch error.code {
                        case -2:
                            // Show the detailed parse error
                            self.errorMessage = detail.isEmpty ? "Failed to parse response \(diagInfo)." : detail
                        case -1:
                            self.errorMessage = "Invalid response \(diagInfo)."
                        case 400...499:
                            self.errorMessage = "Request error \(diagInfo). Try different photo."
                        case 500...599:
                            self.errorMessage = "Server error \(diagInfo). Try again."
                        default:
                            self.errorMessage = "Analysis failed \(diagInfo)."
                        }
                    } else if error.domain == "ImageError" {
                        self.errorMessage = "Image processing failed \(diagInfo)."
                    } else if error.code >= 500 {
                        self.errorMessage = "Server error \(diagInfo). Try again."
                    } else if error.code >= 400 {
                        self.errorMessage = "Request error \(diagInfo). Try different photo."
                    } else {
                        self.errorMessage = "Analysis failed \(diagInfo)."
                    }

                    }
            }
        }
    }

    private func recognizeFoodWithRetry(from image: UIImage, maxRetries: Int) async throws -> [FoodSearchResult] {
        var lastError: Error?

        for attempt in 0...maxRetries {
            do {
                return try await recognizeFood(from: image)
            } catch {
                lastError = error
                
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
                    }

        // Compress image for upload (0.8 for better quality)
        guard let imageData = processedImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to process image"])
        }

        let base64Image = imageData.base64EncodedString()

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
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = bodyData

        
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check HTTP status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "AddFoodAIView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
        }

        
        if httpResponse.statusCode != 200 {
            throw NSError(domain: "AddFoodAIView", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])
        }

        // Decode response
        do {
            let decodedResponse = try JSONDecoder().decode(FoodRecognitionResponse.self, from: data)

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
        } catch let decodeError {
            // Extract helpful error info for debugging
            var errorDetail = "parse error"
            if let decodingError = decodeError as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, _):
                    errorDetail = "missing '\(key.stringValue)'"
                case .typeMismatch(let type, let context):
                    errorDetail = "type mismatch at \(context.codingPath.map { $0.stringValue }.joined(separator: ".")): expected \(type)"
                case .valueNotFound(let type, let context):
                    errorDetail = "null value at \(context.codingPath.map { $0.stringValue }.joined(separator: ".")): expected \(type)"
                case .dataCorrupted(let context):
                    errorDetail = "corrupted at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
                @unknown default:
                    errorDetail = "unknown decode error"
                }
            }

            throw NSError(domain: "AddFoodAIView", code: -2, userInfo: [NSLocalizedDescriptionKey: "Parse failed: \(errorDetail)"])
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
            // Extract image first before dismissing
            let selectedImage = info[.originalImage] as? UIImage

            // Dismiss picker and call callback in completion handler
            // This prevents double-dismissal issues when presented in a sheet
            picker.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                if let image = selectedImage {
                    self.parent.selectedImage?.wrappedValue = image
                    self.parent.onImageSelected(image)
                } else {
                    // Failed to extract image - still call callback with nil to trigger error handling
                    self.parent.onImageSelected(nil)
                }
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            // Dismiss picker and call callback in completion handler
            // This prevents double-dismissal issues when presented in a sheet
            picker.dismiss(animated: true) { [weak self] in
                self?.parent.onImageSelected(nil)
            }
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
            // NOTE: Do NOT call picker.dismiss() here - let SwiftUI handle dismissal via the binding
            // Calling both picker.dismiss() and setting the binding to false causes parent view dismissal issues

            guard !results.isEmpty else {
                DispatchQueue.main.async {
                    self.parent.onImagesSelected([])
                }
                return
            }

            // Thread-safe image collection
            let imageQueue = DispatchQueue(label: "multiImagePicker.images")
            var images: [UIImage] = []
            let group = DispatchGroup()

            for result in results {
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    defer { group.leave() }
                    if let image = object as? UIImage {
                        imageQueue.sync {
                            images.append(image)
                        }
                    }
                }
            }

            group.notify(queue: .main) {
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
    @EnvironmentObject var diaryDataManager: DiaryDataManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var firebaseManager: FirebaseManager
    @EnvironmentObject var fastingViewModelWrapper: FastingViewModelWrapper

    @State private var selectedFoods: Set<String> = []
    @State private var selectedFood: FoodSearchResult?
    @State private var hasInitializedSelection = false

    // Sort foods by confidence (highest first)
    private var sortedFoods: [FoodSearchResult] {
        recognizedFoods.sorted { ($0.confidence ?? 0) > ($1.confidence ?? 0) }
    }

    // Calculate total calories for selected foods
    // Note: calories from AI scanner are already scaled to portion size, no need to re-scale
    private var totalSelectedCalories: Double {
        sortedFoods
            .filter { selectedFoods.contains($0.id) }
            .reduce(0) { $0 + $1.calories }
    }

    var body: some View {
        VStack(spacing: 16) {
            // AI Estimate Disclaimer
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
                Text("AI estimates may vary. Use as a guide only.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal, 16)

            // Total calories summary (updates as foods are selected)
            if !selectedFoods.isEmpty {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Estimated")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("\(Int(totalSelectedCalories)) kcal")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Text("\(selectedFoods.count) item\(selectedFoods.count == 1 ? "" : "s")")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 16)
            }

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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.adaptiveCard)
        .sheet(item: $selectedFood) { food in
            NavigationView {
                // Use constant binding to prevent Details view from changing main tab while in AI scanner
                FoodDetailViewFromSearch(food: food, selectedTab: .constant(.diary), fastingViewModel: fastingViewModelWrapper.viewModel)
            }
            .environmentObject(diaryDataManager)
            .environmentObject(subscriptionManager)
            .environmentObject(firebaseManager)
        }
        .onAppear {
            // Auto-select all detected foods by default
            if !hasInitializedSelection {
                hasInitializedSelection = true
                selectedFoods = Set(recognizedFoods.map { $0.id })
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
    
    // Calories are already scaled to portion size from the AI scanner
    // No need to re-scale - just use the value directly
    private var perServingCalories: Double {
        food.calories
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

                    // Confidence indicator - only show if 70% or higher
                    if let confidence = food.confidence, confidence >= 0.7 {
                        Text("\(Int(confidence * 100))%")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(confidence >= 0.85 ? .green : .secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(confidence >= 0.85 ? Color.green.opacity(0.15) : Color.gray.opacity(0.2))
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
        .background(Color.adaptiveCard)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Combined Meal Management

struct CombinedMealView: View {
    let foods: [FoodSearchResult]
    let onDismiss: () -> Void
    var onSaveComplete: (() -> Void)? = nil  // Called after successful save to dismiss all the way to diary

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
                // Post notification to refresh diary data
                NotificationCenter.default.post(name: NSNotification.Name("RefreshDiaryData"), object: nil)
                // Dismiss all the way back to diary if callback provided, otherwise just dismiss this view
                if let onSaveComplete = onSaveComplete {
                    onSaveComplete()
                } else {
                    onDismiss()
                }
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
            } catch is FirebaseManager.DiaryLimitError {
                await MainActor.run {
                    showingLimitError = true
                }
            } catch {
                // Silently handle other save errors
            }
        }
    }
}

struct CombinedMealFoodRow: View {
    let food: FoodSearchResult
    let servingSize: Double
    let onServingSizeChange: (Double) -> Void
    
    // Extract gram weight from serving description
    private var gramWeight: Int? {
        if let desc = food.servingDescription {
            // Parse "150g (verified)" or "120g (AI estimate)"
            let pattern = #"(\d+)g"#
            if let range = desc.range(of: pattern, options: .regularExpression),
               let grams = Int(desc[range].dropLast()) {
                return grams
            }
        }
        return nil
    }

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

                    // Gram weight and confidence
                    HStack(spacing: 8) {
                        if let grams = gramWeight {
                            Text("\(Int(Double(grams) * servingSize))g")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        // Only show confidence if 70% or higher
                        if let confidence = food.confidence, confidence >= 0.7 {
                            Text("\(Int(confidence * 100))% match")
                                .font(.caption)
                                .foregroundColor(confidence >= 0.85 ? .green : .blue)
                        }
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
        .background(Color.adaptiveCard)
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