//
//  AIScanQueueManager.swift
//  NutraSafe Beta
//
//  P2-1: Manages offline AI scan queue processing
//  Processes pending scans when network becomes available
//

import Foundation
import UIKit
import Network

/// Manages the queue of AI scans waiting for network connectivity
final class AIScanQueueManager: @unchecked Sendable {

    // MARK: - Singleton

    static let shared = AIScanQueueManager()

    // MARK: - Properties

    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.nutrasafe.aiscanqueue.monitor")
    private var isProcessing = false
    private var wasOffline = false

    // MARK: - Initialization

    private init() {
        setupNetworkMonitoring()
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            if path.status == .satisfied {
                // Network is available
                if self.wasOffline {
                    // We just came back online - process pending scans
                    self.wasOffline = false
                    Task {
                        await self.processPendingScans()
                    }
                }
            } else {
                // Network is unavailable
                self.wasOffline = true
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }

    // MARK: - Public Methods

    /// Manually trigger processing of pending scans
    func processQueueIfNeeded() {
        Task {
            await processPendingScans()
        }
    }

    /// Get count of pending scans
    func getPendingCount() -> Int {
        return OfflineDataManager.shared.getPendingAIScansCount()
    }

    // MARK: - Processing

    private func processPendingScans() async {
        // Prevent concurrent processing
        guard !isProcessing else { return }
        isProcessing = true

        defer { isProcessing = false }

        let pendingScans = OfflineDataManager.shared.getPendingAIScans()

        guard !pendingScans.isEmpty else { return }

        print("[AIScanQueueManager] Processing \(pendingScans.count) pending AI scans")

        for scan in pendingScans {
            // Skip if too many retries (max 5)
            guard scan.retryCount < 5 else {
                print("[AIScanQueueManager] Scan \(scan.id) exceeded max retries, removing")
                OfflineDataManager.shared.removePendingAIScan(id: scan.id)
                continue
            }

            do {
                // Convert image data back to UIImage
                guard let image = UIImage(data: scan.imageData) else {
                    print("[AIScanQueueManager] Failed to decode image for scan \(scan.id)")
                    OfflineDataManager.shared.removePendingAIScan(id: scan.id)
                    continue
                }

                // Process the scan
                let results = try await recognizeFood(from: image)

                if !results.isEmpty {
                    // Success! Remove from queue and notify
                    OfflineDataManager.shared.removePendingAIScan(id: scan.id)

                    await MainActor.run {
                        // Post notification with results
                        NotificationCenter.default.post(
                            name: .pendingAIScanCompleted,
                            object: nil,
                            userInfo: [
                                "scanId": scan.id,
                                "results": results,
                                "mealType": scan.mealType as Any,
                                "targetDate": scan.targetDate as Any
                            ]
                        )
                    }

                    print("[AIScanQueueManager] Successfully processed scan \(scan.id) with \(results.count) results")
                } else {
                    // No results - update retry count
                    OfflineDataManager.shared.updatePendingAIScan(
                        id: scan.id,
                        retryCount: scan.retryCount + 1,
                        lastError: "No food items detected"
                    )
                }

            } catch let error as NSError {
                // Check if it's a network error - if so, stop processing
                if error.domain == NSURLErrorDomain {
                    print("[AIScanQueueManager] Network error, stopping queue processing")
                    wasOffline = true
                    break
                }

                // Other error - update retry count
                OfflineDataManager.shared.updatePendingAIScan(
                    id: scan.id,
                    retryCount: scan.retryCount + 1,
                    lastError: error.localizedDescription
                )
                print("[AIScanQueueManager] Error processing scan \(scan.id): \(error.localizedDescription)")
            }

            // Small delay between scans to avoid overwhelming the server
            try? await Task.sleep(nanoseconds: 500_000_000)
        }

        // Notify that processing is complete
        let remainingCount = OfflineDataManager.shared.getPendingAIScansCount()
        await MainActor.run {
            NotificationCenter.default.post(
                name: .pendingAIScansProcessed,
                object: nil,
                userInfo: ["remainingCount": remainingCount]
            )
        }
    }

    // MARK: - AI Recognition (copied from AddFoodAIView for reuse)

    private func recognizeFood(from image: UIImage) async throws -> [FoodSearchResult] {
        // Resize image if too large
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

        guard let imageData = processedImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "AIScanQueueManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to process image"])
        }

        let base64Image = imageData.base64EncodedString()

        let urlString = "https://us-central1-nutrasafe-705c7.cloudfunctions.net/recognizeFood"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "AIScanQueueManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90

        let body = ["image": base64Image]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "AIScanQueueManager", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }

        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let foodsArray = json["foods"] as? [[String: Any]] else {
            return []
        }

        var results: [FoodSearchResult] = []
        for foodDict in foodsArray {
            if let foodData = try? JSONSerialization.data(withJSONObject: foodDict),
               let food = try? JSONDecoder().decode(FoodSearchResult.self, from: foodData) {
                results.append(food)
            }
        }

        return results
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let pendingAIScanCompleted = Notification.Name("pendingAIScanCompleted")
}
