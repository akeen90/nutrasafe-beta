//
//  DiaryCacheActor.swift
//  NutraSafe Beta
//
//  Thread-safe caching for diary food data
//  Prevents redundant Firebase fetches when navigating between dates
//

import Foundation

/// Cached diary data for a single day
struct DayDiaryData: Codable {
    let breakfast: [DiaryFoodItem]
    let lunch: [DiaryFoodItem]
    let dinner: [DiaryFoodItem]
    let snacks: [DiaryFoodItem]
    let cachedAt: Date

    var totalItems: Int {
        breakfast.count + lunch.count + dinner.count + snacks.count
    }
}

/// Thread-safe cache for diary food data per day
/// Uses Actor isolation to prevent concurrent access crashes
actor DiaryCacheActor {

    // MARK: - Cache Storage

    private var dayCache: [String: DayDiaryData] = [:]
    private let maxCacheSize: Int
    private var accessOrder: [String] = [] // For LRU eviction

    // MARK: - Statistics

    private var hits: Int = 0
    private var misses: Int = 0

    // MARK: - Initialization

    init(maxDays: Int = 30) {
        self.maxCacheSize = maxDays
    }

    // MARK: - Cache Operations

    /// Retrieve cached diary data for a specific date
    /// - Parameter date: The date to fetch
    /// - Returns: Tuple of (breakfast, lunch, dinner, snacks) arrays if cached, nil otherwise
    func getData(for date: Date) -> DayDiaryData? {
        let dateKey = formatDateKey(date)

        // Update access order for LRU
        if let index = accessOrder.firstIndex(of: dateKey) {
            accessOrder.remove(at: index)
        }
        accessOrder.append(dateKey)

        let cachedData = dayCache[dateKey]
        if cachedData != nil {
            hits += 1
        } else {
            misses += 1
        }

        return cachedData
    }

    /// Store diary data for a specific date
    /// - Parameters:
    ///   - breakfast: Breakfast items
    ///   - lunch: Lunch items
    ///   - dinner: Dinner items
    ///   - snacks: Snacks items
    ///   - date: The date for this data
    func setData(breakfast: [DiaryFoodItem], lunch: [DiaryFoodItem], dinner: [DiaryFoodItem], snacks: [DiaryFoodItem], for date: Date) {
        let dateKey = formatDateKey(date)

        // Evict oldest entry if cache is full
        if dayCache.count >= maxCacheSize, dayCache[dateKey] == nil {
            evictOldestEntry()
        }

        let data = DayDiaryData(
            breakfast: breakfast,
            lunch: lunch,
            dinner: dinner,
            snacks: snacks,
            cachedAt: Date()
        )

        dayCache[dateKey] = data

        // Update access order
        if let index = accessOrder.firstIndex(of: dateKey) {
            accessOrder.remove(at: index)
        }
        accessOrder.append(dateKey)

        print("📦 [DiaryCache] Cached data for \(dateKey): \(data.totalItems) items")
    }

    /// Invalidate (remove) cache for a specific date
    /// Called when diary data changes for that date
    func invalidate(date: Date) {
        let dateKey = formatDateKey(date)
        if dayCache.removeValue(forKey: dateKey) != nil {
            if let index = accessOrder.firstIndex(of: dateKey) {
                accessOrder.remove(at: index)
            }
            print("🗑️ [DiaryCache] Invalidated cache for \(dateKey)")
        }
    }

    /// Invalidate cache for a date range
    /// Useful when bulk changes occur
    func invalidate(dateRange: ClosedRange<Date>) {
        var invalidatedCount = 0
        for date in stride(from: dateRange.lowerBound, through: dateRange.upperBound, by: 86400) {
            let dateKey = formatDateKey(date)
            if dayCache.removeValue(forKey: dateKey) != nil {
                if let index = accessOrder.firstIndex(of: dateKey) {
                    accessOrder.remove(at: index)
                }
                invalidatedCount += 1
            }
        }
        if invalidatedCount > 0 {
            print("🗑️ [DiaryCache] Invalidated \(invalidatedCount) days in range")
        }
    }

    /// Clear all cached diary data
    func clear() {
        let previousSize = dayCache.count
        dayCache.removeAll()
        accessOrder.removeAll()
        hits = 0
        misses = 0
        print("🗑️ [DiaryCache] Cleared \(previousSize) cached days")
    }

    /// Get current cache size
    func size() -> Int {
        return dayCache.count
    }

    /// Get cache statistics
    func getStats() -> (size: Int, hits: Int, misses: Int, hitRate: Double) {
        let total = hits + misses
        let hitRate = total > 0 ? Double(hits) / Double(total) : 0.0
        return (size: dayCache.count, hits: hits, misses: misses, hitRate: hitRate)
    }

    /// Check if date is cached
    func isCached(date: Date) -> Bool {
        let dateKey = formatDateKey(date)
        return dayCache[dateKey] != nil
    }

    // MARK: - Private Helpers

    private func evictOldestEntry() {
        guard !accessOrder.isEmpty else { return }

        // Remove least recently used entry
        let oldestKey = accessOrder.removeFirst()
        dayCache.removeValue(forKey: oldestKey)
        print("♻️ [DiaryCache] Evicted oldest entry: \(oldestKey)")
    }

    private func formatDateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
