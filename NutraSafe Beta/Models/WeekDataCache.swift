//
//  WeekDataCache.swift
//  NutraSafe Beta
//
//  Thread-safe caching for processed week-level nutrient data
//  Stores RhythmDays and CoverageRows to avoid recomputation
//

import Foundation

/// Codable version of SourceLevel for caching
enum CachedSourceLevel: String, Codable {
    case none = "None"
    case trace = "Low"
    case moderate = "Moderate"
    case strong = "Strong"
}

/// Codable version of Segment for caching
struct CachedSegment: Codable {
    let date: Date
    let level: CachedSourceLevel?
    let foods: [String]?
}

/// Codable version of CoverageRow for caching
struct CachedCoverageRow: Codable {
    let id: String
    let name: String
    let status: String  // CoverageStatus as string
    let segments: [CachedSegment]
}

/// Codable version of RhythmDay for caching
struct CachedRhythmDay: Codable {
    let date: Date
    let level: CachedSourceLevel
}

/// Cached week data
struct WeekData: Codable {
    let weekStart: Date
    let rhythmDays: [CachedRhythmDay]
    let coverageRows: [CachedCoverageRow]
    let cachedAt: Date
}

/// Thread-safe cache for processed week-level nutrient data
/// Uses Actor isolation to prevent concurrent access crashes
actor WeekDataCache {

    // MARK: - Cache Storage

    private var weekCache: [String: WeekData] = [:]
    private let maxCacheSize: Int
    private var accessOrder: [String] = [] // For LRU eviction

    // MARK: - Statistics

    private var hits: Int = 0
    private var misses: Int = 0

    // MARK: - Initialization

    init(maxWeeks: Int = 8) {
        self.maxCacheSize = maxWeeks
    }

    // MARK: - Cache Operations

    /// Retrieve cached week data
    /// - Parameter weekStart: The Monday date of the week
    /// - Returns: Cached week data if available, nil otherwise
    func getData(for weekStart: Date) -> WeekData? {
        let weekKey = formatWeekKey(weekStart)

        // Update access order for LRU
        if let index = accessOrder.firstIndex(of: weekKey) {
            accessOrder.remove(at: index)
        }
        accessOrder.append(weekKey)

        let cachedData = weekCache[weekKey]
        if cachedData != nil {
            hits += 1
        } else {
            misses += 1
        }

        return cachedData
    }

    /// Store processed week data
    /// - Parameters:
    ///   - rhythmDays: Array of 7 RhythmDay objects
    ///   - coverageRows: Array of nutrient coverage rows
    ///   - weekStart: The Monday date of the week
    func setData(rhythmDays: [CachedRhythmDay], coverageRows: [CachedCoverageRow], for weekStart: Date) {
        let weekKey = formatWeekKey(weekStart)

        // Evict oldest entry if cache is full
        if weekCache.count >= maxCacheSize, weekCache[weekKey] == nil {
            evictOldestEntry()
        }

        let data = WeekData(
            weekStart: weekStart,
            rhythmDays: rhythmDays,
            coverageRows: coverageRows,
            cachedAt: Date()
        )

        weekCache[weekKey] = data

        // Update access order
        if let index = accessOrder.firstIndex(of: weekKey) {
            accessOrder.remove(at: index)
        }
        accessOrder.append(weekKey)

        #if DEBUG
        print("📦 [WeekCache] Cached week data for \(weekKey): \(coverageRows.count) nutrients, \(rhythmDays.count) days")
        #endif
    }

    /// Invalidate (remove) cache for a specific week
    /// Called when any day in the week changes
    func invalidate(weekStart: Date) {
        let weekKey = formatWeekKey(weekStart)
        if weekCache.removeValue(forKey: weekKey) != nil {
            if let index = accessOrder.firstIndex(of: weekKey) {
                accessOrder.remove(at: index)
            }
            #if DEBUG
            print("🗑️ [WeekCache] Invalidated cache for week \(weekKey)")
            #endif
        }
    }

    /// Invalidate cache for a date (finds and invalidates the week containing that date)
    func invalidate(containingDate date: Date) {
        let calendar = Calendar.current
        guard let weekStart = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: date).date else {
            return
        }
        invalidate(weekStart: weekStart)
    }

    /// Clear all cached week data
    func clear() {
        let previousSize = weekCache.count
        weekCache.removeAll()
        accessOrder.removeAll()
        hits = 0
        misses = 0
        #if DEBUG
        print("🗑️ [WeekCache] Cleared \(previousSize) cached weeks")
        #endif
    }

    /// Get current cache size
    func size() -> Int {
        return weekCache.count
    }

    /// Get cache statistics
    func getStats() -> (size: Int, hits: Int, misses: Int, hitRate: Double) {
        let total = hits + misses
        let hitRate = total > 0 ? Double(hits) / Double(total) : 0.0
        return (size: weekCache.count, hits: hits, misses: misses, hitRate: hitRate)
    }

    /// Check if week is cached
    func isCached(weekStart: Date) -> Bool {
        let weekKey = formatWeekKey(weekStart)
        return weekCache[weekKey] != nil
    }

    // MARK: - Private Helpers

    private func evictOldestEntry() {
        guard !accessOrder.isEmpty else { return }

        // Remove least recently used entry
        let oldestKey = accessOrder.removeFirst()
        weekCache.removeValue(forKey: oldestKey)
        #if DEBUG
        print("♻️ [WeekCache] Evicted oldest week: \(oldestKey)")
        #endif
    }

    private func formatWeekKey(_ weekStart: Date) -> String {
        // PERFORMANCE: Use cached static formatter
        DateHelper.weekKeyFormatter.string(from: weekStart)
    }
}
