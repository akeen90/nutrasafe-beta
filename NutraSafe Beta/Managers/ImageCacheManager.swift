//
//  ImageCacheManager.swift
//  NutraSafe Beta
//
//  Persistent local image cache for UseBy items and Weight entries
//  Caches images locally to avoid repeated downloads from Firebase
//

import Foundation
import UIKit
import SwiftUI

/// Manages persistent local image caching for UseBy items and Weight entries
@MainActor
class ImageCacheManager {
    static let shared = ImageCacheManager()

    // In-memory cache for quick access (auto-manages memory)
    private let memoryCache = NSCache<NSString, UIImage>()

    // File manager for disk operations
    private let fileManager = FileManager.default

    // Cache directory paths
    private let useByImagesDirectory: URL
    private let weightImagesDirectory: URL

    private init() {
        // Get the app's caches directory
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory

        // Create subdirectories for different image types
        useByImagesDirectory = cachesDirectory.appendingPathComponent("UseByImages", isDirectory: true)
        weightImagesDirectory = cachesDirectory.appendingPathComponent("WeightImages", isDirectory: true)

        // Configure memory cache limits
        // Reduced limits to prevent memory pressure on devices with < 2GB RAM
        // 100 images at 2000x2000 pixels would be ~400MB - too aggressive
        memoryCache.countLimit = 30 // Max 30 images in memory (realistic visible count)
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50 MB max

        // Create cache directories if they don't exist
        createCacheDirectoriesIfNeeded()

        #if DEBUG
        print("📦 ImageCacheManager initialized")
        print("   UseBy cache: \(useByImagesDirectory.path)")
        print("   Weight cache: \(weightImagesDirectory.path)")
        #endif
    }

    // MARK: - Directory Management

    private func createCacheDirectoriesIfNeeded() {
        do {
            try fileManager.createDirectory(at: useByImagesDirectory, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: weightImagesDirectory, withIntermediateDirectories: true)
            #if DEBUG
            print("✅ Cache directories created/verified")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to create cache directories: \(error)")
            #endif
        }
    }

    // MARK: - UseBy Item Images

    /// Save an image for a UseBy item to local cache
    func saveUseByImage(_ image: UIImage, for itemId: String) throws {
        let fileURL = useByImageURL(for: itemId)
        try saveImage(image, to: fileURL, itemId: itemId)
        #if DEBUG
        print("✅ Saved UseBy image for item: \(itemId)")
        #endif
    }

    func saveUseByImageAsync(_ image: UIImage, for itemId: String) async throws {
        let fileURL = useByImageURL(for: itemId)
        try await saveImageAsync(image, to: fileURL, itemId: itemId)
        #if DEBUG
        print("✅ Saved UseBy image for item: \(itemId)")
        #endif
    }

    /// Load a UseBy item image from cache
    func loadUseByImage(for itemId: String) -> UIImage? {
        let fileURL = useByImageURL(for: itemId)
        return loadImage(from: fileURL, itemId: itemId)
    }

    func loadUseByImageAsync(for itemId: String) async -> UIImage? {
        let fileURL = useByImageURL(for: itemId)
        return await loadImageAsync(from: fileURL, itemId: itemId)
    }

    /// Check if a UseBy item has a cached image
    func hasUseByImage(for itemId: String) -> Bool {
        let fileURL = useByImageURL(for: itemId)
        return fileManager.fileExists(atPath: fileURL.path)
    }

    /// Delete a UseBy item's cached image
    func deleteUseByImage(for itemId: String) {
        let fileURL = useByImageURL(for: itemId)
        deleteImage(at: fileURL, itemId: itemId)
        #if DEBUG
        print("🗑️ Deleted UseBy image for item: \(itemId)")
        #endif
    }

    private func useByImageURL(for itemId: String) -> URL {
        return useByImagesDirectory.appendingPathComponent("\(itemId).jpg")
    }

    // MARK: - Weight Entry Images

    /// Save an image for a Weight entry to local cache
    func saveWeightImage(_ image: UIImage, for entryId: String) throws {
        let fileURL = weightImageURL(for: entryId)
        try saveImage(image, to: fileURL, itemId: entryId)
        #if DEBUG
        print("✅ Saved Weight image for entry: \(entryId)")
        #endif
    }

    func saveWeightImageAsync(_ image: UIImage, for entryId: String) async throws {
        let fileURL = weightImageURL(for: entryId)
        try await saveImageAsync(image, to: fileURL, itemId: entryId)
        #if DEBUG
        print("✅ Saved Weight image for entry: \(entryId)")
        #endif
    }

    /// Load a Weight entry image from cache
    func loadWeightImage(for entryId: String) -> UIImage? {
        let fileURL = weightImageURL(for: entryId)
        return loadImage(from: fileURL, itemId: entryId)
    }

    func loadWeightImageAsync(for entryId: String) async -> UIImage? {
        let fileURL = weightImageURL(for: entryId)
        return await loadImageAsync(from: fileURL, itemId: entryId)
    }

    /// Check if a Weight entry has a cached image
    func hasWeightImage(for entryId: String) -> Bool {
        let fileURL = weightImageURL(for: entryId)
        return fileManager.fileExists(atPath: fileURL.path)
    }

    /// Delete a Weight entry's cached image
    func deleteWeightImage(for entryId: String) {
        let fileURL = weightImageURL(for: entryId)
        deleteImage(at: fileURL, itemId: entryId)
        #if DEBUG
        print("🗑️ Deleted Weight image for entry: \(entryId)")
        #endif
    }

    /// Save multiple images for a Weight entry (for photoURLs array)
    func saveWeightImages(_ images: [UIImage], for entryId: String) throws {
        for (index, image) in images.enumerated() {
            let imageId = "\(entryId)_\(index)"
            let fileURL = weightImageURL(for: imageId)
            try saveImage(image, to: fileURL, itemId: imageId)
        }
        #if DEBUG
        print("✅ Saved \(images.count) Weight images for entry: \(entryId)")
        #endif
    }

    /// Load multiple images for a Weight entry
    func loadWeightImages(for entryId: String, count: Int) -> [UIImage] {
        var images: [UIImage] = []
        for index in 0..<count {
            let imageId = "\(entryId)_\(index)"
            if let image = loadWeightImage(for: imageId) {
                images.append(image)
            }
        }
        return images
    }

    func loadWeightImagesAsync(for entryId: String, count: Int) async -> [UIImage] {
        var images: [UIImage] = []
        for index in 0..<count {
            let imageId = "\(entryId)_\(index)"
            if let image = await loadWeightImageAsync(for: imageId) {
                images.append(image)
            }
        }
        return images
    }

    /// Delete all images for a Weight entry (when entry is deleted)
    func deleteAllWeightImages(for entryId: String) {
        // Delete main image
        deleteWeightImage(for: entryId)

        // Delete any indexed images (photoURLs array)
        for index in 0..<10 { // Reasonable upper limit
            let imageId = "\(entryId)_\(index)"
            let fileURL = weightImageURL(for: imageId)
            if fileManager.fileExists(atPath: fileURL.path) {
                deleteImage(at: fileURL, itemId: imageId)
            } else {
                break // No more images
            }
        }
        #if DEBUG
        print("🗑️ Deleted all Weight images for entry: \(entryId)")
        #endif
    }

    private func weightImageURL(for entryId: String) -> URL {
        return weightImagesDirectory.appendingPathComponent("\(entryId).jpg")
    }

    // MARK: - Core Image Operations

    private func saveImage(_ image: UIImage, to fileURL: URL, itemId: String) throws {
        // Check memory cache first
        let cacheKey = NSString(string: fileURL.path)

        // Optimize image for storage (compress to 70% quality JPEG)
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            #if DEBUG
            print("❌ Failed to convert image to JPEG for \(itemId)")
            #endif
            throw NSError(domain: "ImageCache", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG"])
        }

        // Write to disk
        do {
            try imageData.write(to: fileURL, options: .atomic)
        } catch {
            #if DEBUG
            print("❌ Failed to write image to disk for \(itemId): \(error.localizedDescription)")
            print("   Path: \(fileURL.path)")
            #endif
            throw error
        }

        // Store in memory cache for quick access
        memoryCache.setObject(image, forKey: cacheKey, cost: imageData.count)

        #if DEBUG
        print("💾 Cached image to disk: \(fileURL.lastPathComponent) (\(imageData.count / 1024)KB)")
        #endif
    }

    private func saveImageAsync(_ image: UIImage, to fileURL: URL, itemId: String) async throws {
        let cacheKey = NSString(string: fileURL.path)

        // PERFORMANCE: Move compression and disk write to background thread
        let result = await Task.detached { () -> Result<Data, Error> in
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                return .failure(NSError(domain: "ImageCache", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to convert image to JPEG data"
                ]))
            }
            do {
                try imageData.write(to: fileURL, options: .atomic)
                return .success(imageData)
            } catch {
                return .failure(error)
            }
        }.value

        switch result {
        case .success(let imageData):
            memoryCache.setObject(image, forKey: cacheKey, cost: imageData.count)
            #if DEBUG
            print("💾 Cached image to disk: \(fileURL.lastPathComponent) (\(imageData.count / 1024)KB)")
            #endif
        case .failure(let error):
            throw error
        }
    }

    private func loadImage(from fileURL: URL, itemId: String) -> UIImage? {
        let cacheKey = NSString(string: fileURL.path)

        // Check memory cache first (fastest)
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            #if DEBUG
            print("⚡️ Memory cache HIT for: \(fileURL.lastPathComponent)")
            #endif
            return cachedImage
        }

        // Load from disk
        guard let imageData = try? Data(contentsOf: fileURL),
              let image = UIImage(data: imageData) else {
            #if DEBUG
            print("⚠️ No cached image found for \(itemId)")
            print("   This is normal if the image hasn't been cached yet")
            #endif
            return nil
        }

        // Store in memory cache for next time
        memoryCache.setObject(image, forKey: cacheKey, cost: imageData.count)
        #if DEBUG
        print("📀 Disk cache HIT for: \(fileURL.lastPathComponent) (\(imageData.count / 1024)KB)")
        #endif

        return image
    }

    private func loadImageAsync(from fileURL: URL, itemId: String) async -> UIImage? {
        let cacheKey = NSString(string: fileURL.path)
        if let cachedImage = memoryCache.object(forKey: cacheKey) { return cachedImage }
        let dataResult: Data? = await Task.detached { () -> Data? in
            return try? Data(contentsOf: fileURL)
        }.value
        guard let imageData = dataResult, let image = UIImage(data: imageData) else {
            #if DEBUG
            print("⚠️ No cached image found at: \(fileURL.lastPathComponent)")
            #endif
            return nil
        }
        memoryCache.setObject(image, forKey: cacheKey, cost: imageData.count)
        #if DEBUG
        print("📀 Disk cache HIT for: \(fileURL.lastPathComponent) (\(imageData.count / 1024)KB)")
        #endif
        return image
    }

    private func deleteImage(at fileURL: URL, itemId: String) {
        let cacheKey = NSString(string: fileURL.path)

        // Remove from memory cache
        memoryCache.removeObject(forKey: cacheKey)

        // Remove from disk
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
                #if DEBUG
                print("🗑️ Deleted cached image: \(fileURL.lastPathComponent)")
                #endif
            }
        } catch {
            #if DEBUG
            print("❌ Failed to delete cached image for \(itemId): \(error.localizedDescription)")
            print("   Path: \(fileURL.path)")
            print("   Note: This won't affect app functionality")
            #endif
        }
    }

    // MARK: - Cache Management

    /// Clear all cached images (useful for testing or freeing up space)
    func clearAllCache() {
        do {
            // Clear memory cache
            memoryCache.removeAllObjects()

            // Clear UseBy images
            if fileManager.fileExists(atPath: useByImagesDirectory.path) {
                let files = try fileManager.contentsOfDirectory(at: useByImagesDirectory, includingPropertiesForKeys: nil)
                for file in files {
                    try fileManager.removeItem(at: file)
                }
            }

            // Clear Weight images
            if fileManager.fileExists(atPath: weightImagesDirectory.path) {
                let files = try fileManager.contentsOfDirectory(at: weightImagesDirectory, includingPropertiesForKeys: nil)
                for file in files {
                    try fileManager.removeItem(at: file)
                }
            }

            #if DEBUG
            print("🧹 Cleared all cached images")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to clear cache: \(error)")
            #endif
        }
    }

    /// Get cache statistics
    func getCacheStats() -> (useByCount: Int, weightCount: Int, totalSizeMB: Double) {
        var useByCount = 0
        var weightCount = 0
        var totalSize: Int64 = 0

        do {
            // Count UseBy images
            if fileManager.fileExists(atPath: useByImagesDirectory.path) {
                let useByFiles = try fileManager.contentsOfDirectory(at: useByImagesDirectory, includingPropertiesForKeys: [.fileSizeKey])
                useByCount = useByFiles.count
                for file in useByFiles {
                    if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
                       let size = attributes[.size] as? Int64 {
                        totalSize += size
                    }
                }
            }

            // Count Weight images
            if fileManager.fileExists(atPath: weightImagesDirectory.path) {
                let weightFiles = try fileManager.contentsOfDirectory(at: weightImagesDirectory, includingPropertiesForKeys: [.fileSizeKey])
                weightCount = weightFiles.count
                for file in weightFiles {
                    if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
                       let size = attributes[.size] as? Int64 {
                        totalSize += size
                    }
                }
            }
        } catch {
            #if DEBUG
            print("❌ Failed to get cache stats: \(error)")
            #endif
        }

        let totalSizeMB = Double(totalSize) / (1024 * 1024)
        return (useByCount, weightCount, totalSizeMB)
    }

    /// Print cache statistics (for debugging)
    func printCacheStats() {
        let stats = getCacheStats()
        #if DEBUG
        print("📊 Image Cache Statistics:")
        print("   UseBy images: \(stats.useByCount)")
        print("   Weight images: \(stats.weightCount)")
        print("   Total size: \(String(format: "%.2f", stats.totalSizeMB)) MB")
        #endif
    }
}
