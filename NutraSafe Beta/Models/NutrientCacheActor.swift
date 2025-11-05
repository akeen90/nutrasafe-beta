//
//  NutrientCacheActor.swift
//  NutraSafe Beta
//
//  Thread-safe caching for micronutrient profiles
//  Prevents race conditions during concurrent nutrient calculations
//

import Foundation

/// Thread-safe cache for micronutrient profiles
/// Uses Actor isolation to prevent concurrent access crashes
actor NutrientCacheActor {

    // MARK: - Cache Storage

    private var profileCache: [String: MicronutrientProfile] = [:]
    private let maxCacheSize: Int
    private var accessOrder: [String] = [] // For LRU eviction

    // MARK: - Initialization

    init(maxSize: Int = 1000) {
        self.maxCacheSize = maxSize
    }

    // MARK: - Cache Operations

    /// Retrieve a cached profile for a food
    func getProfile(forFoodId foodId: String) -> MicronutrientProfile? {
        // Update access order for LRU
        if let index = accessOrder.firstIndex(of: foodId) {
            accessOrder.remove(at: index)
        }
        accessOrder.append(foodId)

        return profileCache[foodId]
    }

    /// Store a profile in the cache
    func setProfile(_ profile: MicronutrientProfile, forFoodId foodId: String) {
        // Evict oldest entry if cache is full
        if profileCache.count >= maxCacheSize, profileCache[foodId] == nil {
            evictOldestEntry()
        }

        profileCache[foodId] = profile

        // Update access order
        if let index = accessOrder.firstIndex(of: foodId) {
            accessOrder.remove(at: index)
        }
        accessOrder.append(foodId)
    }

    /// Get multiple profiles at once (batch operation)
    func getProfiles(forFoodIds foodIds: [String]) -> [String: MicronutrientProfile] {
        var result: [String: MicronutrientProfile] = [:]
        for foodId in foodIds {
            if let profile = profileCache[foodId] {
                result[foodId] = profile

                // Update access order
                if let index = accessOrder.firstIndex(of: foodId) {
                    accessOrder.remove(at: index)
                }
                accessOrder.append(foodId)
            }
        }
        return result
    }

    /// Store multiple profiles at once (batch operation)
    func setProfiles(_ profiles: [String: MicronutrientProfile]) {
        for (foodId, profile) in profiles {
            // Evict oldest entry if cache is full
            if profileCache.count >= maxCacheSize, profileCache[foodId] == nil {
                evictOldestEntry()
            }

            profileCache[foodId] = profile

            // Update access order
            if let index = accessOrder.firstIndex(of: foodId) {
                accessOrder.remove(at: index)
            }
            accessOrder.append(foodId)
        }
    }

    /// Clear all cached profiles
    func clear() {
        profileCache.removeAll()
        accessOrder.removeAll()
    }

    /// Get current cache size
    func size() -> Int {
        return profileCache.count
    }

    // MARK: - Private Helpers

    private func evictOldestEntry() {
        guard !accessOrder.isEmpty else { return }

        // Remove least recently used entry
        let oldestKey = accessOrder.removeFirst()
        profileCache.removeValue(forKey: oldestKey)
    }
}
