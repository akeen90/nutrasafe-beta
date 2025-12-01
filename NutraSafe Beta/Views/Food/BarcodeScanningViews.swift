//
//  BarcodeScanningViews.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-09-12.
//  Advanced Barcode Scanning System with Camera Integration
//

import SwiftUI
import AVFoundation
import UIKit
import AudioToolbox
import Foundation

// MARK: - Barcode Scanning View (DIARY-ONLY)
struct AddFoodBarcodeView: View {
    @Binding var selectedTab: TabItem
    var onSwitchToManual: ((String) -> Void)? = nil // Callback with barcode
    @State private var scannedProduct: FoodSearchResult?
    @State private var pendingContribution: PendingFoodContribution?
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var showingContributionForm = false
    @State private var scanFailed = false
    @State private var scannerKey = UUID() // Force scanner reset

    var body: some View {
        VStack(spacing: 0) {
            if let product = scannedProduct {
                // Result state
                VStack(spacing: 16) {
                    Text("Product Found!")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.green)
                        .padding(.top, 20)

                    FoodSearchResultRowEnhanced(
                        food: product,
                        sourceType: .barcode,
                        selectedTab: $selectedTab,
                        onComplete: { tab in
                            // Switch to the selected tab after adding food
                            selectedTab = tab
                        }
                    )
                    .padding(.horizontal, 16)

                    Button("Scan Another") {
                        scannedProduct = nil
                        errorMessage = nil
                    }
                    .foregroundColor(.blue)
                    .padding(.bottom, 20)
                }

            } else if let contribution = pendingContribution {
                // Product not found - navigate to manual add
                VStack(spacing: 20) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                        .padding(.top, 20)

                    Text("Product Not Found")
                        .font(.system(size: 20, weight: .semibold))

                    Text("Add it manually with AI search")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Barcode: \(contribution.barcode)")
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)

                    Button("Add Manually") {
                        onSwitchToManual?(contribution.barcode)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)

                    Button("Scan Another") {
                        pendingContribution = nil
                        errorMessage = nil
                    }
                    .foregroundColor(.blue)
                    .padding(.bottom, 20)
                }
                .padding()

            } else if scanFailed {
                // Scan failed state - show error and retry button
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                        .padding(.top, 40)

                    Text("Product Not Found")
                        .font(.system(size: 20, weight: .semibold))

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    Button(action: {
                        resetScanner()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: 200)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .padding(.top, 20)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemBackground))

            } else {
                // Camera scanning view
                ZStack {
                    ModernBarcodeScanner(onBarcodeScanned: { barcode in
                        handleBarcodeScanned(barcode)
                    }, isSearching: $isSearching)
                        .id(scannerKey) // Force recreate scanner when key changes

                    // Overlay UI
                    VStack {
                        HStack {
                            Spacer()
                        }
                        .frame(height: 100)
                        .background(Color.black.opacity(0.7))

                        Spacer()

                        // Bottom instruction text (only when not searching)
                        if !isSearching {
                            VStack(spacing: 16) {
                                Text("Position barcode within the frame")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .frame(height: 120)
                            .frame(maxWidth: .infinity)
                            .background(Color.black.opacity(0.7))
                        }
                    }

                    // Center searching indicator (appears when searching)
                    if isSearching {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Looking up product...")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(Color.black.opacity(0.75))
                        .cornerRadius(16)
                    }
                }
            }
        }
        .navigationTitle("Scan Barcode")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingContributionForm, onDismiss: {
            // Clean up state when sheet is dismissed
            pendingContribution = nil
            errorMessage = nil
        }) {
            if let contribution = pendingContribution {
                NavigationView {
                    ManualFoodDetailEntryView(
                        selectedTab: $selectedTab,
                        prefilledBarcode: contribution.barcode
                    )
                    .navigationBarItems(leading: Button("Cancel") {
                        showingContributionForm = false
                        pendingContribution = nil
                    })
                }
            }
        }
    }
    
    // MARK: - Scanner Reset
    private func resetScanner() {
        // Reset all state
        scanFailed = false
        errorMessage = nil
        isSearching = false

        // Generate new key to force scanner recreation (clears debounce)
        scannerKey = UUID()
    }

    // MARK: - Barcode Normalization
    /// Normalizes a barcode to handle format variations (EAN-13 ↔ UPC-A)
    /// Returns an array of barcode variations to search
    private func normalizeBarcode(_ barcode: String) -> [String] {
        var variations = [barcode] // Always include original

        // EAN-13 to UPC-A: Remove leading zero if length is 13 and starts with 0
        if barcode.count == 13 && barcode.hasPrefix("0") {
            let upcVariation = String(barcode.dropFirst())
            variations.append(upcVariation)
        }

        // UPC-A to EAN-13: Add leading zero if length is 12
        if barcode.count == 12 {
            let eanVariation = "0" + barcode
            variations.append(eanVariation)
        }

        return variations
    }

    // MARK: - Barcode Handling
    private func handleBarcodeScanned(_ barcode: String) {
        guard !isSearching else { return }

        isSearching = true
        errorMessage = nil

        Task {
            // Step 1: Normalize barcode to handle format variations
            let barcodeVariations = normalizeBarcode(barcode)
            #if DEBUG
            print("🔍 Searching for barcode variations: \(barcodeVariations)")
            #endif

            // Step 2: Try Algolia exact barcode lookup across indices (fast path)
            var foundInAlgolia: FoodSearchResult? = nil
            for variation in barcodeVariations {
                do {
                    if let hit = try await AlgoliaSearchManager.shared.searchByBarcode(variation) {
                        foundInAlgolia = hit
                        #if DEBUG
                        print("✅ Found in Algolia with barcode: \(variation)")
                        #endif
                        break
                    }
                } catch {
                    // Continue to next variation/fallback
                }
            }

            // If found in Algolia, show immediately (fast path)
            if let product = foundInAlgolia {
                await MainActor.run {
                    self.scannedProduct = product
                    self.isSearching = false
                }
                return
            }

            #if DEBUG
            print("⚠️ Not found in Algolia, falling back to Firebase Cloud Function...")
            #endif

            // Step 3: Fallback to Firebase Cloud Function (which falls back to OpenFoodFacts)
            searchProductByBarcode(barcode) { result in
                Task { @MainActor in
                    self.isSearching = false

                    switch result {
                    case .success(let response):
                        if response.success, let product = response.toFoodSearchResult() {
                            #if DEBUG
                            print("✅ Found via Firebase Cloud Function")
                            #endif
                            self.scannedProduct = product
                        } else if response.action == "user_contribution_needed",
                                  let placeholderId = response.placeholder_id {
                            // Product not found anywhere - show manual add option
                            #if DEBUG
                            print("📱 Product not found anywhere. Showing manual add option.")
                            #endif
                            self.pendingContribution = PendingFoodContribution(
                                placeholderId: placeholderId,
                                barcode: barcode
                            )
                        } else {
                            // Network error or unexpected response
                            self.errorMessage = response.message ?? "Product not found in our database."
                            self.pendingContribution = PendingFoodContribution(
                                placeholderId: "", // Empty placeholder for manual add
                                barcode: barcode
                            )
                        }
                    case .failure(let error):
                        // Network failure - show user-friendly error and manual add option
                        #if DEBUG
                        print("❌ Network error: \(error)")
                        #endif

                        // Determine error type and show appropriate message
                        if let urlError = error as? URLError {
                            switch urlError.code {
                            case .notConnectedToInternet, .networkConnectionLost:
                                self.errorMessage = "No internet connection. You can add this product manually."
                            case .timedOut:
                                self.errorMessage = "Request timed out. You can add this product manually."
                            default:
                                self.errorMessage = "Unable to search. You can add this product manually."
                            }
                        } else {
                            self.errorMessage = "Unable to search. You can add this product manually."
                        }
                        self.pendingContribution = PendingFoodContribution(
                            placeholderId: "",
                            barcode: barcode
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Barcode API Search
    private func searchProductByBarcode(_ barcode: String, completion: @escaping (Result<BarcodeSearchResponse, Error>) -> Void) {
        // Hardcoded API endpoint for barcode lookup
        guard let url = URL(string: "https://us-central1-nutrasafe-705c7.cloudfunctions.net/searchFoodByBarcode") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["barcode": barcode]
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(BarcodeSearchResponse.self, from: data)
                completion(.success(response))
            } catch {
                // Fallback to manual parsing for compatibility
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let response = BarcodeSearchResponse(
                            success: json["success"] as? Bool ?? false,
                            food: nil,
                            error: json["error"] as? String,
                            message: json["message"] as? String,
                            action: json["action"] as? String,
                            placeholder_id: json["placeholder_id"] as? String,
                            barcode: json["barcode"] as? String
                        )
                        completion(.success(response))
                    } else {
                        completion(.failure(error))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}

// MARK: - Modern Barcode Scanner Bridge
struct ModernBarcodeScanner: UIViewControllerRepresentable {
    let onBarcodeScanned: (String) -> Void
    @Binding var isSearching: Bool

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let scanner = BarcodeScannerViewController()
        scanner.onBarcodeScanned = onBarcodeScanned
        return scanner
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {
        // Stop/start camera based on search state
        if isSearching {
            uiViewController.pauseScanning()
        } else {
            uiViewController.resumeScanning()
        }
    }
}

// MARK: - Camera-Based Barcode Scanner
class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onBarcodeScanned: ((String) -> Void)?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var lastScannedBarcode: String?
    private var lastScanTime: Date?
    private var isScanningPaused = false
    private var videoCaptureDevice: AVCaptureDevice?

    // Multi-frame verification for barcode accuracy
    private var candidateBarcode: String?
    private var consecutiveDetections: Int = 0
    private let requiredConsecutiveDetections: Int = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCamera()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCamera()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
    
    // MARK: - Camera Setup
    private func setupCamera() {
        // Check camera authorization status first
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Permission already granted, proceed with setup
            configureCamera()

        case .notDetermined:
            // First time - request permission
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.configureCamera()
                    } else {
                        self?.showCameraError("Camera permission denied")
                    }
                }
            }

        case .denied, .restricted:
            // Permission was denied or restricted - show settings message
            showCameraError("Camera permission denied. Please enable in Settings")

        @unknown default:
            showCameraError("Camera permission unknown")
        }
    }

    private func configureCamera() {
        // Use the best rear camera with autofocus capabilities
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTripleCamera],
            mediaType: .video,
            position: .back
        )

        guard let videoCaptureDevice = discoverySession.devices.first else {
            showCameraError("Camera not available")
            return
        }

        self.videoCaptureDevice = videoCaptureDevice

        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high

        do {
            // Configure autofocus for optimal barcode scanning
            try videoCaptureDevice.lockForConfiguration()
            if videoCaptureDevice.isFocusModeSupported(.continuousAutoFocus) {
                videoCaptureDevice.focusMode = .continuousAutoFocus
            }
            if videoCaptureDevice.isAutoFocusRangeRestrictionSupported {
                videoCaptureDevice.autoFocusRangeRestriction = .near
            }
            videoCaptureDevice.unlockForConfiguration()

            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                showCameraError("Cannot add camera input")
                return
            }
            
            let metadataOutput = AVCaptureMetadataOutput()
            
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                // Restrict to food product barcode formats only (EAN-8, EAN-13, UPC-E)
                // Excludes QR codes, Code39, Code128, etc. to prevent scanning non-food items
                metadataOutput.metadataObjectTypes = [.ean8, .ean13, .upce]

                // Set a much larger scanning area instead of the tiny default slit
                // This covers most of the screen for easier barcode scanning
                metadataOutput.rectOfInterest = CGRect(x: 0.1, y: 0.2, width: 0.8, height: 0.6)
            } else {
                showCameraError("Cannot add metadata output")
                return
            }
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            
            self.captureSession = captureSession
            self.previewLayer = previewLayer
            
            #if DEBUG
            print("Camera setup completed successfully")
            #endif
            
        } catch {
            showCameraError("Camera setup failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Camera Controls
    private func startCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.startRunning()
        }
    }

    private func stopCamera() {
        captureSession?.stopRunning()
    }

    func pauseScanning() {
        isScanningPaused = true
    }

    func resumeScanning() {
        isScanningPaused = false
        // Reset debounce to allow new scans
        lastScannedBarcode = nil
        lastScanTime = nil
        // Reset multi-frame verification
        candidateBarcode = nil
        consecutiveDetections = 0
    }
    
    private func showCameraError(_ message: String) {
        // Create user-friendly error message
        let userMessage: String
        if message.contains("not available") {
            userMessage = "Camera is not available on this device"
        } else if message.contains("setup failed") || message.contains("Cannot add") {
            userMessage = "Unable to access camera. Please check permissions in Settings"
        } else {
            userMessage = "Camera error: Please restart the app"
        }

        let label = UILabel()
        label.text = userMessage
        label.textAlignment = .center
        label.textColor = .white
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])

        #if DEBUG
        print("📷 Camera Error: \(message)")
        #endif
    }
    
    // MARK: - Barcode Detection Delegate
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Don't process barcodes if scanning is paused
        guard !isScanningPaused else { return }

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }

            // Debounce repeated scans - prevent duplicate scans within 2 seconds of last ACCEPTED scan
            let now = Date()
            if let lastBarcode = lastScannedBarcode,
               let lastTime = lastScanTime,
               lastBarcode == stringValue && now.timeIntervalSince(lastTime) < 2.0 {
                return
            }

            // Multi-frame verification: require 3 consecutive identical reads
            if candidateBarcode == stringValue {
                // Same barcode detected again - increment counter
                consecutiveDetections += 1
                #if DEBUG
                print("📸 Barcode verification: \(consecutiveDetections)/\(requiredConsecutiveDetections) - \(stringValue)")
                #endif

                if consecutiveDetections >= requiredConsecutiveDetections {
                    // Success! We have 3 consecutive identical reads
                    #if DEBUG
                    print("✅ Barcode verified after \(requiredConsecutiveDetections) consecutive detections: \(stringValue)")
                    #endif

                    lastScannedBarcode = stringValue
                    lastScanTime = now

                    // Reset verification state
                    candidateBarcode = nil
                    consecutiveDetections = 0

                    // Provide haptic feedback for successful scan
                    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                    onBarcodeScanned?(stringValue)
                }
            } else {
                // Different barcode detected - reset and start new verification
                candidateBarcode = stringValue
                consecutiveDetections = 1
                #if DEBUG
                print("🔄 New barcode candidate: \(stringValue) (1/\(requiredConsecutiveDetections))")
                #endif
            }
        } else {
            // No barcode detected in this frame - reset verification
            if candidateBarcode != nil {
                #if DEBUG
                print("❌ Lost barcode lock - resetting verification")
                #endif
                candidateBarcode = nil
                consecutiveDetections = 0
            }
        }
    }
}
