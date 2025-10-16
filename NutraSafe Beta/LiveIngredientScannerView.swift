import SwiftUI
import AVFoundation
import Vision

struct LiveIngredientScannerView: View {
    @StateObject private var scannerService = LiveTextScannerService()
    @Environment(\.dismiss) private var dismiss
    @State private var showingResults = false
    @State private var finalResult: LiveTextScannerService.ProcessedTextResult?
    @State private var isProcessing = false
    @State private var processingMessage = "Processing text..."
    
    var onScanComplete: ((String, [String: Any]?) -> Void)?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        scannerService.stopScanning()
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                    
                    Spacer()
                    
                    Text("Live Scanner")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))
                    
                    Spacer()
                    
                    Button("Done") {
                        finalizeScan()
                    }
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .semibold))
                    .disabled(scannerService.accumulatedText.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .background(Color.black.opacity(0.7))
                
                // Scan Type Picker
                HStack(spacing: 16) {
                    ForEach(LiveTextScannerService.ScanType.allCases, id: \.rawValue) { type in
                        Button(action: {
                            scannerService.switchScanType(type)
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: iconForScanType(type))
                                    .font(.system(size: 20))
                                Text(type.displayName)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(scannerService.scanType == type ? .blue : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .foregroundColor(scannerService.scanType == type ? Color.blue.opacity(0.2) : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(scannerService.scanType == type ? Color.blue : Color.gray, lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.7))
                
                // Camera Preview
                ZStack {
                    CameraPreviewView(previewLayer: scannerService.getPreviewLayer())
                        .onAppear {
                            scannerService.startScanning()
                        }
                        .onDisappear {
                            scannerService.stopScanning()
                        }
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    // Convert tap location to normalized camera coordinates
                                    let locationInView = value.location
                                    if let preview = scannerService.getPreviewLayer() {
                                        let viewSize = preview.bounds.size
                                        let normalizedPoint = CGPoint(
                                            x: locationInView.x / viewSize.width,
                                            y: locationInView.y / viewSize.height
                                        )
                                        scannerService.focusAt(point: normalizedPoint)
                                    }
                                }
                        )
                    
                    // Show all detected text in gray (non-highlighted)
                    if !scannerService.textBlocks.isEmpty {
                        TextDetectionOverlay(
                            textBlocks: scannerService.textBlocks.filter { block in
                                !scannerService.highlightedRegions.contains(where: { $0.id == block.id })
                            },
                            isHighlighted: false,
                            scanningStep: scannerService.scanningStep
                        )
                    }

                    // Text Detection Overlay - Show highlighted regions in color
                    if !scannerService.highlightedRegions.isEmpty {
                        TextDetectionOverlay(
                            textBlocks: scannerService.highlightedRegions,
                            isHighlighted: true,
                            scanningStep: scannerService.scanningStep
                        )
                    }

                    // Processing Overlay
                    if isProcessing {
                        ProcessingOverlay(message: processingMessage)
                    }

                    // Completion Checkmark Overlay - Only show when actually advancing to next step
                    if scannerService.showCompletionCheckmark && scannerService.scanningStep == .complete {
                        ZStack {
                            Color.clear
                            VStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.green)
                                    .shadow(color: .black.opacity(0.5), radius: 10)
                                    .scaleEffect(scannerService.showCompletionCheckmark ? 1.0 : 0.5)
                                    .opacity(scannerService.showCompletionCheckmark ? 1.0 : 0.0)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: scannerService.showCompletionCheckmark)
                                Spacer()
                            }
                        }
                    }
                }
                
                // Bottom Info Panel
                VStack(spacing: 12) {
                    // Current Step Indicator
                    VStack(spacing: 8) {
                        HStack {
                            Circle()
                                .fill(scannerService.scanningStep == .ingredients ? Color.blue : Color.green)
                                .frame(width: 12, height: 12)
                            Text(scannerService.scanningStep.rawValue.capitalized)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            if scannerService.isReadyToComplete {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Ready")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.green)
                                }
                            }
                        }

                        Text(scannerService.scanningStep.instructions)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.bottom, 8)

                    // Stats and Actions
                    VStack(spacing: 12) {
                        // Stats Row
                        HStack(spacing: 20) {
                            VStack(spacing: 4) {
                                Text("Quality")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                                HStack(spacing: 4) {
                                    Image(systemName: qualityIcon(for: scannerService.confidence))
                                        .font(.system(size: 14))
                                        .foregroundColor(qualityColor(for: scannerService.confidence))
                                    Text(qualityText(for: scannerService.confidence))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(qualityColor(for: scannerService.confidence))
                                }
                            }

                            VStack(spacing: 4) {
                                Text("Items Found")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                                Text("\(scannerService.accumulatedText.count)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            Spacer()
                        }

                        // Action Buttons Row
                        if scannerService.scanningStep != .complete {
                            HStack(spacing: 12) {
                                Button(action: {
                                    scannerService.forceComplete()
                                }) {
                                    HStack {
                                        Text("Skip")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .foregroundColor(Color.orange.opacity(0.8))
                                    )
                                }

                                if scannerService.isReadyToComplete, let nextStep = scannerService.scanningStep.nextStep {
                                    Button(action: {
                                        scannerService.advanceToNextStep()
                                    }) {
                                        HStack(spacing: 6) {
                                            Text(nextStep == .complete ? "Finish" : "Next")
                                                .font(.system(size: 16, weight: .semibold))
                                            Image(systemName: "arrow.right")
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .foregroundColor(Color.green)
                                        )
                                    }
                                }
                            }
                        }
                    }

                    // Live Text Preview
                    if !scannerService.detectedText.isEmpty {
                        ScrollView {
                            Text(scannerService.detectedText)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.1))
                                )
                        }
                        .frame(maxHeight: 100)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "text.viewfinder")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                            Text("Point camera at ingredients list")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.9))
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingResults) {
            ScanResultsView(result: finalResult) {
                dismiss()
            }
        }
    }
    
    private func iconForScanType(_ type: LiveTextScannerService.ScanType) -> String {
        switch type {
        case .ingredients:
            return "list.bullet.rectangle"
        case .nutrition:
            return "chart.bar.doc.horizontal"
        case .barcode:
            return "barcode"
        }
    }

    private func qualityIcon(for confidence: Double) -> String {
        if confidence >= 0.8 {
            return "checkmark.circle.fill"
        } else if confidence >= 0.5 {
            return "exclamationmark.circle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }

    private func qualityColor(for confidence: Double) -> Color {
        if confidence >= 0.8 {
            return .green
        } else if confidence >= 0.5 {
            return .yellow
        } else {
            return .red
        }
    }

    private func qualityText(for confidence: Double) -> String {
        if confidence >= 0.8 {
            return "Excellent"
        } else if confidence >= 0.6 {
            return "Good"
        } else if confidence >= 0.4 {
            return "Fair"
        } else {
            return "Poor"
        }
    }

    private func finalizeScan() {
        guard !scannerService.accumulatedText.isEmpty else { return }
        
        isProcessing = true
        processingMessage = "Processing with AI..."
        
        Task {
            let result = await scannerService.finalizeScanning()
            
            await MainActor.run {
                isProcessing = false
                finalResult = result
                
                if let result = result {
                    onScanComplete?(result.cleanedText, result.structuredData)
                }
                
                showingResults = true
            }
        }
    }
}

// MARK: - Supporting Views

struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer?

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black

        // Add the preview layer immediately if available
        if let previewLayer = previewLayer {
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            view.previewLayer = previewLayer
        }

        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Always update the frame
        DispatchQueue.main.async {
            if let previewLayer = previewLayer {
                if uiView.previewLayer == nil {
                    // Layer doesn't exist yet, add it
                    previewLayer.videoGravity = .resizeAspectFill
                    uiView.layer.addSublayer(previewLayer)
                    uiView.previewLayer = previewLayer
                }

                // Update the frame
                previewLayer.frame = uiView.bounds
            }
        }
    }

    class PreviewView: UIView {
        var previewLayer: AVCaptureVideoPreviewLayer?

        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer?.frame = bounds
        }
    }
}

struct TextDetectionOverlay: View {
    let textBlocks: [LiveTextScannerService.TextBlock]
    let isHighlighted: Bool
    let scanningStep: LiveTextScannerService.ScanningStep

    private var highlightColor: Color {
        if !isHighlighted {
            return .white.opacity(0.2)
        }

        switch scanningStep {
        case .ingredients:
            return .green  // Green for ingredients
        case .nutrition:
            return .blue   // Blue for nutrition
        case .complete:
            return .green
        }
    }

    private var strokeWidth: CGFloat {
        isHighlighted ? 2 : 1
    }

    var body: some View {
        GeometryReader { geometry in
            ForEach(textBlocks) { block in
                let rect = convertBoundingBox(block.boundingBox, to: geometry.size)

                Rectangle()
                    .stroke(highlightColor, lineWidth: strokeWidth)
                    .background(isHighlighted ? highlightColor.opacity(0.15) : Color.clear)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            }
        }
    }

    private func convertBoundingBox(_ boundingBox: CGRect, to size: CGSize) -> CGRect {
        let rect = VNImageRectForNormalizedRect(boundingBox, Int(size.width), Int(size.height))
        return CGRect(
            x: rect.minX,
            y: size.height - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }
}

struct ProcessingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.2)
                
                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.8))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

struct ScanResultsView: View {
    let result: LiveTextScannerService.ProcessedTextResult?
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let result = result {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Scan Results")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Processed Text")
                                    .font(.headline)
                                
                                Text(result.cleanedText)
                                    .font(.body)
                                    .padding(12)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            if let structuredData = result.structuredData {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Structured Data")
                                        .font(.headline)
                                    
                                    ForEach(Array(structuredData.keys.sorted()), id: \.self) { key in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(key.capitalized)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                            
                                            Text("\(structuredData[key] ?? "N/A")")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(8)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(6)
                                    }
                                }
                            }
                            
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                Text("Scan Quality: \(result.confidence >= 0.8 ? "Excellent" : result.confidence >= 0.5 ? "Good" : "Fair")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                    } else {
                        Text("No results available")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Scan Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LiveIngredientScannerView { text, data in
        print("Scanned text: \\(text)")
        if let data = data {
            print("Structured data: \\(data)")
        }
    }
}