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
    @State private var showingFoodDetail = false
    @EnvironmentObject var diaryDataManager: DiaryDataManager
    @EnvironmentObject var fastingViewModelWrapper: FastingViewModelWrapper

    var body: some View {
        VStack(spacing: 0) {
            if let contribution = pendingContribution {
                // Product not found - navigate to manual add
                VStack(spacing: 20) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 50))
                        .foregroundColor(AppPalette.standard.accent)
                        .padding(.top, 20)

                    Text("Product Not Found")
                        .font(.system(size: 20, weight: .semibold))

                    Text("Add it manually")
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
                    .background(AppPalette.standard.accent)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)

                    Button("Scan Another") {
                        pendingContribution = nil
                        errorMessage = nil
                    }
                    .foregroundColor(AppPalette.standard.accent)
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
                        .background(AppPalette.standard.accent)
                        .cornerRadius(10)
                    }
                    .padding(.top, 20)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.adaptiveCard)

            } else {
                // Camera scanning view
                ZStack {
                    ModernBarcodeScanner(onBarcodeScanned: { barcode in
                        handleBarcodeScanned(barcode)
                    }, isSearching: $isSearching, isPaused: showingFoodDetail)
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
        .fullScreenCover(isPresented: $showingContributionForm, onDismiss: {
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
        .fullScreenCover(isPresented: Binding(
            get: { showingFoodDetail },
            set: { newValue in
                if !newValue {
                    // Disable animation when dismissing
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        showingFoodDetail = false
                    }
                    // Reset for another scan
                    scannedProduct = nil
                    errorMessage = nil
                } else {
                    showingFoodDetail = newValue
                }
            }
        )) {
            if let product = scannedProduct {
                FoodDetailViewFromSearch(food: product, sourceType: .barcode, selectedTab: $selectedTab, fastingViewModel: fastingViewModelWrapper.viewModel) { tab in
                    selectedTab = tab
                }
                .environmentObject(diaryDataManager)
                .interactiveDismissDisabled(false)
            }
        }
        .onChange(of: scannedProduct) { _, newProduct in
            // Automatically show food detail when product is found
            if newProduct != nil {
                showingFoodDetail = true
            }
        }
        .trackScreen("Barcode Scanner")
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

    // MARK: - Nutrition Data Validation

    /// Validates that a product has usable nutrition data
    /// Rejects products with all zeros and no ingredients, or where macros don't add up
    private func hasValidNutritionData(_ product: FoodSearchResult) -> Bool {
        let calories = product.calories
        let protein = product.protein
        let carbs = product.carbs
        let fat = product.fat
        let hasIngredients = (product.ingredients?.count ?? 0) > 0

        // Check if ALL main values are zero
        let allZero = calories == 0 && protein == 0 && carbs == 0 && fat == 0

        // If all nutrition is zero AND no ingredients, reject
        if allZero && !hasIngredients {
                        return false
        }

        // If we have macros but zero calories, that's suspicious
        // (Exception: very small amounts can round to 0)
        let totalMacros = protein + carbs + fat
        if totalMacros > 5 && calories == 0 {
                        return false
        }

        // Calculate expected calories from macros (protein=4, carbs=4, fat=9 kcal/g)
        let expectedCalories = (protein * 4) + (carbs * 4) + (fat * 9)

        // If we have significant macros, calories should roughly match
        // Allow generous tolerance (50%) because fiber, alcohol, rounding etc
        if expectedCalories > 50 && calories > 0 {
            let ratio = calories / expectedCalories
            // Reject if calories are way off (less than 30% or more than 200% of expected)
            if ratio < 0.3 || ratio > 2.0 {
                                return false
            }
        }

        // If we have calories but zero macros, that's also suspicious
        // (Exception: diet drinks can have 1-5 kcal with essentially 0 macros)
        if calories > 10 && totalMacros == 0 && !hasIngredients {
                        return false
        }

                return true
    }

    // MARK: - Barcode Handling
    private func handleBarcodeScanned(_ barcode: String) {
        guard !isSearching else { return }

        isSearching = true
        errorMessage = nil

        Task {
            // Step 1: Normalize barcode to handle format variations
            let barcodeVariations = normalizeBarcode(barcode)
            
            // Step 2: Try Algolia exact barcode lookup across indices (fast path)
            var foundInAlgolia: FoodSearchResult? = nil
            for variation in barcodeVariations {
                do {
                    if let hit = try await AlgoliaSearchManager.shared.searchByBarcode(variation) {
                        foundInAlgolia = hit
                                                break
                    }
                } catch {
                    // Continue to next variation/fallback
                }
            }

            // If found in Algolia, validate and show
            if let product = foundInAlgolia {
                // Validate nutrition data even from Algolia (some imported data may be incomplete)
                if self.hasValidNutritionData(product) {
                    await MainActor.run {
                        self.scannedProduct = product
                        self.isSearching = false
                    }
                    return
                } else {
                                        // Continue to Cloud Function fallback
                }
            }

            
            // Step 3: Fallback to Firebase Cloud Function (which falls back to OpenFoodFacts)
            searchProductByBarcode(barcode) { result in
                Task { @MainActor in
                    self.isSearching = false

                    switch result {
                    case .success(let response):
                        if response.success, let product = response.toFoodSearchResult() {
                            
                            // Validate nutrition data from external sources (OpenFoodFacts)
                            // Reject products with missing/invalid data
                            if self.hasValidNutritionData(product) {
                                self.scannedProduct = product
                            } else {
                                                                self.errorMessage = "This product has incomplete nutrition data."
                                self.pendingContribution = PendingFoodContribution(
                                    placeholderId: "",
                                    barcode: barcode
                                )
                            }
                        } else if response.action == "user_contribution_needed",
                                  let placeholderId = response.placeholder_id {
                            // Product not found anywhere - show manual add option
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
    var isPaused: Bool = false  // Additional pause control (e.g., when food detail is showing)

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let scanner = BarcodeScannerViewController()
        scanner.onBarcodeScanned = onBarcodeScanned
        return scanner
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {
        // Stop/start camera based on search state OR external pause (e.g., food detail showing)
        if isSearching || isPaused {
            uiViewController.pauseScanning()
        } else {
            uiViewController.resumeScanning()
        }
    }
}

// MARK: - Barcode Overlay View (Yuka-style visual feedback)
class BarcodeOverlayView: UIView {

    // MARK: - Visual Layers
    private let outlineLayer = CAShapeLayer()
    private let glowLayer = CAShapeLayer()

    // MARK: - Smoothing State
    private var smoothedCorners: [CGPoint] = []
    private let smoothingFactor: CGFloat = 0.55  // Higher = smoother tracking (Yuka-style)

    // Velocity-based adaptive smoothing
    private var previousCorners: [CGPoint] = []
    private var cornerVelocities: [CGPoint] = []

    // MARK: - Animation State
    private var isVisible = false
    private var hideWorkItem: DispatchWorkItem?

    // MARK: - Configuration (Yuka-style refined design)
    private let strokeColor: UIColor = .white
    private let strokeWidth: CGFloat = 2.5  // Thinner for cleaner look
    private let cornerLength: CGFloat = 18.0  // Length of corner brackets
    private let cornerRadius: CGFloat = 4.0  // Subtle corner rounding
    private let glowColor: UIColor = UIColor.white.withAlphaComponent(0.2)
    private let glowRadius: CGFloat = 4.0  // Subtler glow
    private let verifyingColor: UIColor = UIColor(red: 0, green: 0.6, blue: 0.55, alpha: 1) // App accent teal
    private let animationDuration: TimeInterval = 0.1
    private let hideDelay: TimeInterval = 0.06

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    private func setupLayers() {
        // Glow layer (subtle blur effect behind outline)
        glowLayer.fillColor = UIColor.clear.cgColor
        glowLayer.strokeColor = glowColor.cgColor
        glowLayer.lineWidth = strokeWidth + glowRadius
        glowLayer.lineCap = .round
        glowLayer.lineJoin = .round
        glowLayer.opacity = 0
        glowLayer.shadowColor = UIColor.white.cgColor
        glowLayer.shadowRadius = 3.0
        glowLayer.shadowOpacity = 0.3
        glowLayer.shadowOffset = .zero
        layer.addSublayer(glowLayer)

        // Main outline layer (crisp white brackets)
        outlineLayer.fillColor = UIColor.clear.cgColor
        outlineLayer.strokeColor = strokeColor.cgColor
        outlineLayer.lineWidth = strokeWidth
        outlineLayer.lineCap = .round
        outlineLayer.lineJoin = .round
        outlineLayer.opacity = 0
        layer.addSublayer(outlineLayer)

        // Disable implicit animations for smooth manual updates
        outlineLayer.actions = ["path": NSNull(), "opacity": NSNull(), "strokeColor": NSNull()]
        glowLayer.actions = ["path": NSNull(), "opacity": NSNull(), "strokeColor": NSNull(),
                            "shadowColor": NSNull(), "shadowOpacity": NSNull()]

        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    // MARK: - Corner Processing

    /// Transform AVMetadataObject corners to view coordinates
    func transformCorners(from metadataObject: AVMetadataMachineReadableCodeObject,
                          using previewLayer: AVCaptureVideoPreviewLayer) -> [CGPoint]? {
        // Transform to video preview coordinates
        guard let transformedObject = previewLayer.transformedMetadataObject(for: metadataObject)
                as? AVMetadataMachineReadableCodeObject else {
            return nil
        }

        // Extract corner points
        let corners = transformedObject.corners
        guard corners.count == 4 else { return nil }

        // Validate corners are within reasonable bounds
        guard isValidCorners(corners) else { return nil }

        return corners
    }

    /// Validate corners are within view bounds and form a reasonable shape
    private func isValidCorners(_ corners: [CGPoint]) -> Bool {
        guard corners.count == 4 else { return false }

        let viewBounds = bounds.insetBy(dx: -30, dy: -30) // Small tolerance

        for corner in corners {
            if !viewBounds.contains(corner) {
                return false
            }
        }

        // Check for reasonable quadrilateral (not degenerate)
        // Calculate approximate area using shoelace formula
        var area: CGFloat = 0
        for i in 0..<4 {
            let j = (i + 1) % 4
            area += corners[i].x * corners[j].y
            area -= corners[j].x * corners[i].y
        }
        area = abs(area) / 2.0

        return area > 200 // Minimum area threshold (pixels squared)
    }

    /// Apply adaptive velocity-based smoothing for Yuka-style smooth tracking
    private func smoothCorners(_ newCorners: [CGPoint]) -> [CGPoint] {
        guard smoothedCorners.count == 4 else {
            // First detection - initialize all state
            smoothedCorners = newCorners
            previousCorners = newCorners
            cornerVelocities = Array(repeating: .zero, count: 4)
            return newCorners
        }

        var result: [CGPoint] = []
        var newVelocities: [CGPoint] = []

        for i in 0..<4 {
            // Calculate velocity (change since last frame)
            let dx = newCorners[i].x - previousCorners[i].x
            let dy = newCorners[i].y - previousCorners[i].y
            let velocity = CGPoint(x: dx, y: dy)

            // Adaptive smoothing: use less smoothing when moving fast (responsive)
            // and more smoothing when slow or stationary (stable)
            let speed = sqrt(dx * dx + dy * dy)
            let adaptiveFactor: CGFloat
            if speed < 2 {
                // Slow movement - heavy smoothing for stability
                adaptiveFactor = 0.25
            } else if speed < 10 {
                // Normal movement - standard smoothing
                adaptiveFactor = smoothingFactor
            } else {
                // Fast movement - less smoothing for responsiveness
                adaptiveFactor = min(0.75, smoothingFactor + 0.2)
            }

            // Smooth the velocity too for even smoother motion
            let smoothedVelocityX = cornerVelocities[i].x * 0.6 + velocity.x * 0.4
            let smoothedVelocityY = cornerVelocities[i].y * 0.6 + velocity.y * 0.4
            newVelocities.append(CGPoint(x: smoothedVelocityX, y: smoothedVelocityY))

            // Apply smoothed position with velocity prediction
            let targetX = newCorners[i].x + smoothedVelocityX * 0.1
            let targetY = newCorners[i].y + smoothedVelocityY * 0.1

            let smoothedX = smoothedCorners[i].x + adaptiveFactor * (targetX - smoothedCorners[i].x)
            let smoothedY = smoothedCorners[i].y + adaptiveFactor * (targetY - smoothedCorners[i].y)
            result.append(CGPoint(x: smoothedX, y: smoothedY))
        }

        previousCorners = newCorners
        cornerVelocities = newVelocities
        smoothedCorners = result
        return result
    }

    /// Reset smoothing state (call when barcode is lost)
    func resetSmoothing() {
        smoothedCorners = []
        previousCorners = []
        cornerVelocities = []
    }

    // MARK: - Path Creation

    /// Create Yuka-style corner brackets from 4 corner points
    /// Only draws L-shaped brackets at each corner instead of a full box
    private func createPath(from corners: [CGPoint]) -> UIBezierPath {
        guard corners.count == 4 else { return UIBezierPath() }

        let path = UIBezierPath()

        // Draw corner brackets at each of the 4 corners
        for i in 0..<4 {
            let current = corners[i]
            let next = corners[(i + 1) % 4]
            let prev = corners[(i + 3) % 4]

            // Vectors from current corner to adjacent corners
            let toNext = CGPoint(x: next.x - current.x, y: next.y - current.y)
            let toPrev = CGPoint(x: prev.x - current.x, y: prev.y - current.y)

            // Normalize vectors
            let nextLen = sqrt(toNext.x * toNext.x + toNext.y * toNext.y)
            let prevLen = sqrt(toPrev.x * toPrev.x + toPrev.y * toPrev.y)

            guard nextLen > 0 && prevLen > 0 else { continue }

            // Calculate bracket length (limited by edge length)
            let bracketLength = min(cornerLength, nextLen * 0.35, prevLen * 0.35)

            // Direction unit vectors
            let nextDir = CGPoint(x: toNext.x / nextLen, y: toNext.y / nextLen)
            let prevDir = CGPoint(x: toPrev.x / prevLen, y: toPrev.y / prevLen)

            // End points of the bracket arms
            let armEndNext = CGPoint(
                x: current.x + nextDir.x * bracketLength,
                y: current.y + nextDir.y * bracketLength
            )
            let armEndPrev = CGPoint(
                x: current.x + prevDir.x * bracketLength,
                y: current.y + prevDir.y * bracketLength
            )

            // Draw the L-shaped bracket with tiny rounded corner
            // Start from one arm end, go to corner, then to other arm end
            path.move(to: armEndPrev)

            // Add subtle curve at the corner vertex
            let curveOffset = min(cornerRadius, bracketLength * 0.2)
            let curveStart = CGPoint(
                x: current.x + prevDir.x * curveOffset,
                y: current.y + prevDir.y * curveOffset
            )
            let curveEnd = CGPoint(
                x: current.x + nextDir.x * curveOffset,
                y: current.y + nextDir.y * curveOffset
            )

            path.addLine(to: curveStart)
            path.addQuadCurve(to: curveEnd, controlPoint: current)
            path.addLine(to: armEndNext)
        }

        return path
    }

    // MARK: - Update Overlay

    /// Update the overlay with new corner positions
    func updateOverlay(with corners: [CGPoint], verificationProgress: Float = 0) {
        // Apply smoothing
        let smoothed = smoothCorners(corners)

        // Create path
        let path = createPath(from: smoothed)

        // Update layers without animation
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        outlineLayer.path = path.cgPath
        glowLayer.path = path.cgPath

        // Adjust color based on verification progress (0 to 1)
        if verificationProgress > 0.3 {
            let progressColor = interpolateColor(
                from: strokeColor,
                to: verifyingColor,
                progress: CGFloat(verificationProgress)
            )
            outlineLayer.strokeColor = progressColor.cgColor
            glowLayer.strokeColor = progressColor.withAlphaComponent(0.3).cgColor
        } else {
            outlineLayer.strokeColor = strokeColor.cgColor
            glowLayer.strokeColor = glowColor.cgColor
        }

        CATransaction.commit()

        // Show if hidden
        showOverlay()
    }

    private func interpolateColor(from: UIColor, to: UIColor, progress: CGFloat) -> UIColor {
        var fromR: CGFloat = 0, fromG: CGFloat = 0, fromB: CGFloat = 0, fromA: CGFloat = 0
        var toR: CGFloat = 0, toG: CGFloat = 0, toB: CGFloat = 0, toA: CGFloat = 0

        from.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)
        to.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)

        let r = fromR + (toR - fromR) * progress
        let g = fromG + (toG - fromG) * progress
        let b = fromB + (toB - fromB) * progress
        let a = fromA + (toA - fromA) * progress

        return UIColor(red: r, green: g, blue: b, alpha: a)
    }

    // MARK: - Visibility Animations

    private func showOverlay() {
        // Cancel pending hide
        hideWorkItem?.cancel()
        hideWorkItem = nil

        guard !isVisible else { return }
        isVisible = true

        // Animate in
        CATransaction.begin()
        CATransaction.setAnimationDuration(animationDuration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))

        outlineLayer.opacity = 1.0
        glowLayer.opacity = 1.0

        CATransaction.commit()
    }

    func hideOverlay(animated: Bool = true) {
        // Cancel any pending hide and schedule new one
        hideWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.performHide(animated: animated)
        }
        hideWorkItem = workItem

        DispatchQueue.main.asyncAfter(deadline: .now() + hideDelay, execute: workItem)
    }

    private func performHide(animated: Bool) {
        guard isVisible else { return }
        isVisible = false

        if animated {
            CATransaction.begin()
            CATransaction.setAnimationDuration(animationDuration * 1.5)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeIn))

            outlineLayer.opacity = 0
            glowLayer.opacity = 0

            CATransaction.commit()
        } else {
            outlineLayer.opacity = 0
            glowLayer.opacity = 0
        }

        // Reset smoothing when hidden
        resetSmoothing()
    }

    func hideImmediately() {
        hideWorkItem?.cancel()
        performHide(animated: false)
    }

    // MARK: - Success Animation

    func flashSuccess() {
        // Change to success color immediately
        outlineLayer.strokeColor = verifyingColor.cgColor
        glowLayer.strokeColor = verifyingColor.withAlphaComponent(0.4).cgColor

        // Bright flash effect
        let flashAnimation = CABasicAnimation(keyPath: "opacity")
        flashAnimation.fromValue = 1.0
        flashAnimation.toValue = 0.4
        flashAnimation.duration = 0.08
        flashAnimation.autoreverses = true
        flashAnimation.repeatCount = 2

        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 1.03
        scaleAnimation.duration = 0.08
        scaleAnimation.autoreverses = true
        scaleAnimation.repeatCount = 2

        let group = CAAnimationGroup()
        group.animations = [flashAnimation, scaleAnimation]
        group.duration = 0.32

        outlineLayer.add(group, forKey: "successFlash")
        glowLayer.add(group, forKey: "successFlash")

        // Hide after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.hideImmediately()
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

    // Barcode overlay for visual feedback
    private var barcodeOverlay: BarcodeOverlayView?

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
        barcodeOverlay?.frame = view.bounds
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
        // Use a virtual device that supports automatic macro switching
        // Virtual devices (Triple/Dual camera) automatically switch to ultra-wide
        // when focusing on close objects, giving us macro capability while normally
        // using the standard wide-angle camera
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInTripleCamera,     // iPhone 12 Pro+ (wide, ultra-wide, telephoto)
                .builtInDualWideCamera,   // iPhone 13+ (wide + ultra-wide with macro)
                .builtInDualCamera,       // Older Pro models (wide + telephoto)
                .builtInWideAngleCamera   // Fallback for non-Pro models
            ],
            mediaType: .video,
            position: .back
        )

        // Use the most capable device available (virtual devices listed first)
        guard let videoCaptureDevice = discoverySession.devices.first else {
            showCameraError("Camera not available")
            return
        }

        self.videoCaptureDevice = videoCaptureDevice

        let captureSession = AVCaptureSession()
        // Use highest resolution available for maximum distance detection
        // 4K allows detecting smaller barcodes from further away (Yuka-style)
        // Falls back gracefully to lower resolutions on older devices
        if captureSession.canSetSessionPreset(.hd4K3840x2160) {
            captureSession.sessionPreset = .hd4K3840x2160
        } else if captureSession.canSetSessionPreset(.hd1920x1080) {
            captureSession.sessionPreset = .hd1920x1080
        } else if captureSession.canSetSessionPreset(.hd1280x720) {
            captureSession.sessionPreset = .hd1280x720
        } else {
            captureSession.sessionPreset = .high
        }

        do {
            // Configure camera for optimal close-up barcode scanning
            try videoCaptureDevice.lockForConfiguration()

            // For virtual devices, enable automatic camera switching for macro mode
            // This allows the system to switch to ultra-wide when focusing close
            if videoCaptureDevice.isVirtualDevice {
                videoCaptureDevice.setPrimaryConstituentDeviceSwitchingBehavior(
                    .auto,
                    restrictedSwitchingBehaviorConditions: []
                )
                            }

            // Enable continuous autofocus
            if videoCaptureDevice.isFocusModeSupported(.continuousAutoFocus) {
                videoCaptureDevice.focusMode = .continuousAutoFocus
            }

            // Allow autofocus at ANY distance (near and far) for Yuka-style scanning
            // Previously restricted to .near which prevented distance scanning
            if videoCaptureDevice.isAutoFocusRangeRestrictionSupported {
                videoCaptureDevice.autoFocusRangeRestriction = .none
            }

            // Enable smooth autofocus for better transitions between distances
            if videoCaptureDevice.isSmoothAutoFocusSupported {
                videoCaptureDevice.isSmoothAutoFocusEnabled = true
            }

            // Set focus point to center of screen where barcode typically is
            if videoCaptureDevice.isFocusPointOfInterestSupported {
                videoCaptureDevice.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
            }

            // Enable continuous auto-exposure for varying lighting
            if videoCaptureDevice.isExposureModeSupported(.continuousAutoExposure) {
                videoCaptureDevice.exposureMode = .continuousAutoExposure
            }

            // Use 1.5x zoom for balance between close-up and distance scanning
            // Lower zoom = better distance scanning, but still helps with small barcodes
            if !videoCaptureDevice.isVirtualDevice {
                let desiredZoom: CGFloat = 1.5
                let maxZoom = min(videoCaptureDevice.activeFormat.videoMaxZoomFactor, 4.0)
                let actualZoom = min(desiredZoom, maxZoom)
                videoCaptureDevice.videoZoomFactor = actualZoom
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

            // Setup barcode overlay for visual feedback
            setupBarcodeOverlay()

        } catch {
            showCameraError("Camera setup failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Barcode Overlay Setup
    private func setupBarcodeOverlay() {
        let overlay = BarcodeOverlayView(frame: view.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlay)
        barcodeOverlay = overlay
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
        barcodeOverlay?.hideImmediately()
    }

    func resumeScanning() {
        isScanningPaused = false
        // Reset debounce to allow new scans
        lastScannedBarcode = nil
        lastScanTime = nil
        // Reset multi-frame verification
        candidateBarcode = nil
        consecutiveDetections = 0
        // Reset overlay smoothing
        barcodeOverlay?.resetSmoothing()
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

            }
    
    // MARK: - Barcode Detection Delegate
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Don't process barcodes if scanning is paused
        guard !isScanningPaused else { return }

        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue,
           let previewLayer = previewLayer {

            // Update visual overlay with barcode corners
            if let corners = barcodeOverlay?.transformCorners(from: readableObject, using: previewLayer) {
                let progress = Float(consecutiveDetections) / Float(requiredConsecutiveDetections)
                barcodeOverlay?.updateOverlay(with: corners, verificationProgress: progress)
            }

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

                // Update overlay with verification progress
                if let corners = barcodeOverlay?.transformCorners(from: readableObject, using: previewLayer) {
                    let progress = Float(consecutiveDetections) / Float(requiredConsecutiveDetections)
                    barcodeOverlay?.updateOverlay(with: corners, verificationProgress: progress)
                }

                if consecutiveDetections >= requiredConsecutiveDetections {
                    // Success! We have 3 consecutive identical reads

                    // Flash success animation on overlay
                    barcodeOverlay?.flashSuccess()

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
            }
        } else {
            // No barcode detected in this frame - hide overlay and reset verification
            barcodeOverlay?.hideOverlay()

            if candidateBarcode != nil {
                candidateBarcode = nil
                consecutiveDetections = 0
            }
        }
    }
}
