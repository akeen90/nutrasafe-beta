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
    // Use Dictionary for O(1) access time tracking instead of O(n) array operations
    private var lastAccessTime: [String: Date] = [:]

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

        // Update access time for LRU - O(1) operation
        lastAccessTime[dateKey] = Date()

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

        // Update access time - O(1) operation
        lastAccessTime[dateKey] = Date()

            }

    /// Invalidate (remove) cache for a specific date
    /// Called when diary data changes for that date
    func invalidate(date: Date) {
        let dateKey = formatDateKey(date)
        if dayCache.removeValue(forKey: dateKey) != nil {
            lastAccessTime.removeValue(forKey: dateKey)
                    }
    }

    /// Invalidate cache for a date range
    /// Useful when bulk changes occur
    func invalidate(dateRange: ClosedRange<Date>) {
        var invalidatedCount = 0
        for date in stride(from: dateRange.lowerBound, through: dateRange.upperBound, by: 86400) {
            let dateKey = formatDateKey(date)
            if dayCache.removeValue(forKey: dateKey) != nil {
                lastAccessTime.removeValue(forKey: dateKey)
                invalidatedCount += 1
            }
        }
        if invalidatedCount > 0 {
                    }
    }

    /// Clear all cached diary data
    func clear() {
        dayCache.removeAll()
        lastAccessTime.removeAll()
        hits = 0
        misses = 0
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
        guard !lastAccessTime.isEmpty else { return }

        // Find least recently used entry - O(n) but only runs on eviction, not every access
        if let oldestKey = lastAccessTime.min(by: { $0.value < $1.value })?.key {
            dayCache.removeValue(forKey: oldestKey)
            lastAccessTime.removeValue(forKey: oldestKey)
                    }
    }

    // PERFORMANCE: Static DateFormatter to avoid recreation on every call
    // DateFormatter creation is expensive (~10ms per instance)
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = Calendar.current.timeZone
        return formatter
    }()

    private func formatDateKey(_ date: Date) -> String {
        return Self.dateFormatter.string(from: date)
    }
}
