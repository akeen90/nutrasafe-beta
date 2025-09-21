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
                    
                    // Text Detection Overlay
                    if !scannerService.textBlocks.isEmpty {
                        TextDetectionOverlay(textBlocks: scannerService.textBlocks)
                    }
                    
                    // Scanning Frame
                    ScanningFrameView()
                    
                    // Processing Overlay
                    if isProcessing {
                        ProcessingOverlay(message: processingMessage)
                    }
                }
                
                // Bottom Info Panel
                VStack(spacing: 12) {
                    // Stats
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("Confidence")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                            Text("\\(Int(scannerService.confidence * 100))%")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text("Text Blocks")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                            Text("\\(scannerService.accumulatedText.count)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            scannerService.accumulatedText.removeAll()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "trash")
                                Text("Clear")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .foregroundColor(Color.red.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .disabled(scannerService.accumulatedText.isEmpty)
                    }
                    
                    // Live Text Preview
                    if !scannerService.detectedText.isEmpty {
                        ScrollView {
                            Text(scannerService.detectedText)
                                .font(.system(size: 13, weight: .regular, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.1))
                                )
                        }
                        .frame(maxHeight: 120)
                    } else {
                        Text("Point camera at text to start scanning")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
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
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        if let previewLayer = previewLayer {
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = previewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}

struct TextDetectionOverlay: View {
    let textBlocks: [LiveTextScannerService.TextBlock]
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(textBlocks) { block in
                let rect = convertBoundingBox(block.boundingBox, to: geometry.size)
                
                Rectangle()
                    .stroke(Color.green, lineWidth: 2)
                    .background(Color.green.opacity(0.1))
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
                    .overlay(
                        Text(block.text)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.7))
                            .position(x: rect.midX, y: rect.maxY + 10),
                        alignment: .topLeading
                    )
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

struct ScanningFrameView: View {
    var body: some View {
        GeometryReader { geometry in
            let frameSize = CGSize(
                width: min(geometry.size.width * 0.8, 300),
                height: min(geometry.size.height * 0.4, 200)
            )
            
            Rectangle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: frameSize.width, height: frameSize.height)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .overlay(
                    VStack {
                        HStack {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.blue)
                                .frame(width: 20, height: 3)
                            Spacer()
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.blue)
                                .frame(width: 20, height: 3)
                        }
                        Spacer()
                        HStack {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.blue)
                                .frame(width: 20, height: 3)
                            Spacer()
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.blue)
                                .frame(width: 20, height: 3)
                        }
                    }
                    .frame(width: frameSize.width - 4, height: frameSize.height - 4)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                )
        }
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
                                Text("Confidence: \\(Int(result.confidence * 100))%")
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