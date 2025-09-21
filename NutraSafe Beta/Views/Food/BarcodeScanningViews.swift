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

// MARK: - Barcode Scanning View
struct AddFoodBarcodeView: View {
    @Binding var selectedTab: TabItem
    @State private var scannedProduct: FoodSearchResult?
    @State private var isSearching = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            if let product = scannedProduct {
                // Result state
                VStack(spacing: 16) {
                    Text("Product Found!")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.green)
                        .padding(.top, 20)
                    
                    FoodSearchResultRowEnhanced(food: product, sourceType: .barcode, selectedTab: $selectedTab)
                    .padding(.horizontal, 16)
                    
                    Button("Scan Another") {
                        scannedProduct = nil
                        errorMessage = nil
                    }
                    .foregroundColor(.blue)
                    .padding(.bottom, 20)
                }
                
            } else {
                // Camera scanning view
                ZStack {
                    ModernBarcodeScanner { barcode in
                        handleBarcodeScanned(barcode)
                    }
                    
                    // Overlay UI
                    VStack {
                        HStack {
                            Spacer()
                        }
                        .frame(height: 100)
                        .background(Color.black.opacity(0.7))
                        
                        Spacer()
                        
                        // Scanning indicator
                        VStack(spacing: 16) {
                            if isSearching {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Looking up product...")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            } else {
                                Text("Position barcode within the frame")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            
                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                        }
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .background(Color.black.opacity(0.7))
                    }
                }
            }
        }
        .navigationTitle("Scan Barcode")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Barcode Handling
    private func handleBarcodeScanned(_ barcode: String) {
        guard !isSearching else { return }
        
        isSearching = true
        errorMessage = nil
        
        searchProductByBarcode(barcode) { result in
            DispatchQueue.main.async {
                isSearching = false
                
                switch result {
                case .success(let product):
                    scannedProduct = product
                case .failure(let error):
                    errorMessage = "Product not found. Try scanning again or search manually."
                    print("Barcode search error: \(error)")
                }
            }
        }
    }
    
    // MARK: - Barcode API Search
    private func searchProductByBarcode(_ barcode: String, completion: @escaping (Result<FoodSearchResult, Error>) -> Void) {
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
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool,
                   success,
                   let foodData = json["food"] as? [String: Any] {
                    
                    let food = FoodSearchResult(
                        id: foodData["food_id"] as? String ?? UUID().uuidString,
                        name: foodData["food_name"] as? String ?? "Unknown Product",
                        brand: foodData["brand_name"] as? String,
                        calories: foodData["calories"] as? Double ?? 0,
                        protein: foodData["protein"] as? Double ?? 0,
                        carbs: foodData["carbohydrates"] as? Double ?? 0,
                        fat: foodData["fat"] as? Double ?? 0,
                        fiber: foodData["fiber"] as? Double ?? 0,
                        sugar: foodData["sugar"] as? Double ?? 0,
                        sodium: foodData["sodium"] as? Double ?? 0,
                        servingDescription: foodData["serving_description"] as? String ?? "per 100g",
                        ingredients: (foodData["ingredients"] as? String)?.components(separatedBy: ", ")
                    )
                    
                    completion(.success(food))
                } else {
                    completion(.failure(NSError(domain: "Product not found", code: 404)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - Modern Barcode Scanner Bridge
struct ModernBarcodeScanner: UIViewControllerRepresentable {
    let onBarcodeScanned: (String) -> Void
    
    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let scanner = BarcodeScannerViewController()
        scanner.onBarcodeScanned = onBarcodeScanned
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Camera-Based Barcode Scanner
class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onBarcodeScanned: ((String) -> Void)?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var lastScannedBarcode: String?
    private var lastScanTime: Date?
    
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
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            showCameraError("Camera not available")
            return
        }
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        do {
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
                metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417, .upce, .code128, .code39, .code93, .qr]
                
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
            
            print("Camera setup completed successfully")
            
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
    
    private func showCameraError(_ message: String) {
        let label = UILabel()
        label.text = message
        label.textAlignment = .center
        label.textColor = .white
        label.numberOfLines = 0
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
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            // Debounce repeated scans - prevent duplicate scans within 2 seconds
            let now = Date()
            if let lastBarcode = lastScannedBarcode, 
               let lastTime = lastScanTime,
               lastBarcode == stringValue && now.timeIntervalSince(lastTime) < 2.0 {
                return
            }
            
            lastScannedBarcode = stringValue
            lastScanTime = now
            
            print("Barcode scanned: \(stringValue)")
            // Provide haptic feedback for successful scan
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            onBarcodeScanned?(stringValue)
        }
    }
}