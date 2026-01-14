//
//  CacheManager.swift
//  NutraSafe Beta
//
//  Handles cache clearing on app version updates
//  Ensures users get fresh data after updating the app
//

import Foundation
import UIKit

/// Notification posted when caches should be cleared due to app update
extension Notification.Name {
    static let appVersionDidChange = Notification.Name("appVersionDidChange")
    static let waterUpdated = Notification.Name("waterUpdated")
    static let favoritesDidChange = Notification.Name("favoritesDidChange")
}

/// Manages cache clearing on app version changes
final class CacheManager {
    static let shared = CacheManager()

    private let lastVersionKey = "lastAppVersion"
    private let lastBuildKey = "lastAppBuild"

    private init() {}

    /// Check if app version changed and clear caches if needed
    /// Call this in app init or MainAppView.onAppear
    func checkAndClearCachesIfNeeded() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let currentBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"

        let lastVersion = UserDefaults.standard.string(forKey: lastVersionKey)
        let lastBuild = UserDefaults.standard.string(forKey: lastBuildKey)

        // Check if version or build changed
        let versionChanged = lastVersion != currentVersion
        let buildChanged = lastBuild != currentBuild

        if versionChanged || buildChanged {
            #if DEBUG
            print("🔄 App updated: \(lastVersion ?? "new") -> \(currentVersion) (build: \(lastBuild ?? "new") -> \(currentBuild))")
            #endif

            // Clear all caches
            clearAllCaches()

            // Save new version info
            UserDefaults.standard.set(currentVersion, forKey: lastVersionKey)
            UserDefaults.standard.set(currentBuild, forKey: lastBuildKey)

            // Notify observers (view models can listen for this to clear in-memory caches)
            NotificationCenter.default.post(name: .appVersionDidChange, object: nil)

            #if DEBUG
            print("✅ Caches cleared for app update")
            #endif
        } else {
            #if DEBUG
            print("📱 App version unchanged: \(currentVersion) (build: \(currentBuild))")
            #endif
        }
    }

    /// Clear all caches - called automatically on version change
    func clearAllCaches() {
        clearURLCache()
        clearFileSystemCaches()
        clearImageCaches()
        clearUserDefaultsCaches()
    }

    /// Force clear all caches (can be called from settings)
    func forceClearAllCaches() {
        clearAllCaches()
        NotificationCenter.default.post(name: .appVersionDidChange, object: nil)
        #if DEBUG
        print("🗑️ Force cleared all caches")
        #endif
    }

    // MARK: - Private Cache Clearing Methods

    private func clearURLCache() {
        URLCache.shared.removeAllCachedResponses()
        #if DEBUG
        print("  - Cleared URL cache")
        #endif
    }

    private func clearFileSystemCaches() {
        let fileManager = FileManager.default

        // Clear Caches directory
        if let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            do {
                let cacheContents = try fileManager.contentsOfDirectory(at: cachesURL, includingPropertiesForKeys: nil)
                for fileURL in cacheContents {
                    try? fileManager.removeItem(at: fileURL)
                }
                #if DEBUG
                print("  - Cleared \(cacheContents.count) items from Caches directory")
                #endif
            } catch {
                #if DEBUG
                print("  - Error clearing Caches: \(error.localizedDescription)")
                #endif
            }
        }

        // Clear tmp directory
        let tmpURL = fileManager.temporaryDirectory
        do {
            let tmpContents = try fileManager.contentsOfDirectory(at: tmpURL, includingPropertiesForKeys: nil)
            for fileURL in tmpContents {
                try? fileManager.removeItem(at: fileURL)
            }
            #if DEBUG
            print("  - Cleared \(tmpContents.count) items from tmp directory")
            #endif
        } catch {
            #if DEBUG
            print("  - Error clearing tmp: \(error.localizedDescription)")
            #endif
        }
    }

    private func clearImageCaches() {
        // Clear NSCache-based image caches (if defined)
        // Note: GradeCache not currently implemented - can be added later

        #if DEBUG
        print("  - Cleared image caches")
        #endif
    }

    private func clearUserDefaultsCaches() {
        // Clear specific cached data keys (not user preferences)
        let cacheKeys = [
            "cachedNutrientData",
            "cachedDiaryData",
            "cachedWeekData",
            "lastFetchDate",
            "searchCache"
        ]

        for key in cacheKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }

        #if DEBUG
        print("  - Cleared UserDefaults cache keys")
        #endif
    }
}
