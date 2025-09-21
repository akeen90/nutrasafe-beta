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
    
    // MARK: - Private Properties
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var textDetectionRequest: VNRecognizeTextRequest?
    private let firebaseManager = FirebaseManager.shared
    private var scanTimer: Timer?
    
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
        isScanning = true
        sessionId = UUID().uuidString
        accumulatedText.removeAll()
        textBlocks.removeAll()
        detectedText = ""
        confidence = 0.0
        
        setupCameraSession()
        
        // Start periodic text detection
        scanTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.processCurrentFrame()
            }
        }
    }
    
    func stopScanning() {
        isScanning = false
        scanTimer?.invalidate()
        scanTimer = nil
        
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
        guard captureSession == nil else { return }
        
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            print("Failed to setup camera")
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frame.processing.queue"))
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        // Configure preview layer
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        previewLayer = preview
        
        captureSession = session
        
        DispatchQueue.global(qos: .background).async {
            session.startRunning()
        }
    }
    
    private func handleTextDetectionResults(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRecognizedTextObservation],
              error == nil else {
            print("Text detection error: \(error?.localizedDescription ?? "Unknown error")")
            return
        }
        
        var newTextBlocks: [TextBlock] = []
        var newText = ""
        var totalConfidence: Float = 0
        var validObservations = 0
        
        for observation in observations {
            guard let candidate = observation.topCandidates(1).first,
                  candidate.confidence > 0.3 else { continue }
            
            let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }
            
            let textBlock = TextBlock(
                text: text,
                boundingBox: observation.boundingBox,
                confidence: candidate.confidence,
                timestamp: Date()
            )
            
            newTextBlocks.append(textBlock)
            newText += text + " "
            totalConfidence += candidate.confidence
            validObservations += 1
            
            // Add to accumulated text (using Set to avoid duplicates)
            accumulatedText.insert(text)
        }
        
        // Update UI
        textBlocks = newTextBlocks
        detectedText = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        confidence = validObservations > 0 ? Double(totalConfidence / Float(validObservations)) : 0.0
    }
    
    private func processCurrentFrame() async {
        // This will be called by the camera delegate
        // Frame processing is handled in the AVCaptureVideoDataOutputSampleBufferDelegate
    }
    
    private func processTextWithGemini(textChunks: [String], finalProcess: Bool) async -> ProcessedTextResult {
        // For now, return basic processing while we fix the build issues
        // TODO: Implement Gemini integration once Firebase build is working
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