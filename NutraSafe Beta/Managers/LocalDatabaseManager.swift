//
//  LocalDatabaseManager.swift
//  NutraSafe Beta
//
//  SQLite-based local food database for offline functionality
//  Copies bundled database to Documents directory for writable delta sync support
//

import Foundation
import SQLite3

// MARK: - SQLite Constants

/// SQLITE_TRANSIENT constant for Swift - tells SQLite to make its own copy of the string
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

// MARK: - Local Database Manager

/// Manages the local SQLite database for offline food search
/// Thread-safe singleton that provides fast FTS5-powered search
/// Supports delta sync by maintaining a writable copy in Documents
final class LocalDatabaseManager {

    // MARK: - Singleton

    static let shared = LocalDatabaseManager()

    // MARK: - Properties

    private var db: OpaquePointer?
    private let dbQueue = DispatchQueue(label: "com.nutrasafe.localdb", qos: .userInitiated)
    private var isInitialized = false

    /// Path to the writable database in the app's Documents directory
    /// Falls back to temp directory if Documents is unavailable (should never happen on iOS)
    private var writableDatabasePath: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return documentsPath.appendingPathComponent("nutrasafe_foods_writable.sqlite")
    }

    /// Path to the bundled database in the app bundle (read-only source)
    private var bundledDatabasePath: URL? {
        Bundle.main.url(forResource: "nutrasafe_foods", withExtension: "sqlite")
    }

    // MARK: - Initialization

    private init() {
        setupDatabase()
    }

    deinit {
        closeDatabase()
    }

    /// Current bundled database version - increment when bundling a new database
    private static let bundledDatabaseVersion = 2  // v2: Fixed Tesco barcodes (EAN-13 format)

    /// Sets up the database, copying from bundle to Documents on first launch
    /// Also replaces database if bundle version is newer
    private func setupDatabase() {
        dbQueue.sync {
            let fileManager = FileManager.default
            let dbPath = writableDatabasePath.path

            // Check if writable database exists in Documents
            var needsCopy = !fileManager.fileExists(atPath: dbPath)

            // If database exists, check if bundle has a newer version
            if !needsCopy {
                let storedVersion = UserDefaults.standard.integer(forKey: "localDatabaseVersion")
                if storedVersion < Self.bundledDatabaseVersion {
                    print("🔄 LocalDB: Bundle has newer database (v\(Self.bundledDatabaseVersion) > v\(storedVersion)), replacing...")
                    do {
                        try fileManager.removeItem(atPath: dbPath)
                        needsCopy = true
                    } catch {
                        print("⚠️ LocalDB: Failed to remove old database, continuing with existing: \(error)")
                    }
                }
            }

            if needsCopy {
                // First launch or update: copy bundled database to Documents for writable access
                guard let bundledPath = bundledDatabasePath else {
                    print("❌ LocalDB: No bundled database found")
                    return
                }

                do {
                    print("📂 LocalDB: Copying bundled database to Documents...")
                    try fileManager.copyItem(at: bundledPath, to: writableDatabasePath)
                    UserDefaults.standard.set(Self.bundledDatabaseVersion, forKey: "localDatabaseVersion")
                    print("✅ LocalDB: Database v\(Self.bundledDatabaseVersion) copied to \(dbPath)")
                } catch {
                    print("❌ LocalDB: Failed to copy database: \(error)")
                    // Fallback: try to open bundled database directly (read-only)
                    openBundledDatabaseReadOnly()
                    return
                }
            }

            // CRIT-3 FIX: Use SQLITE_OPEN_FULLMUTEX for thread-safe concurrent access
            // NOMUTEX disables threading protection, which can cause corruption with concurrent access
            let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
            let result = sqlite3_open_v2(dbPath, &db, flags, nil)

            if result == SQLITE_OK {
                isInitialized = true
                print("✅ LocalDB: Writable database opened successfully")

                // Set WAL mode for better concurrent access and crash recovery
                if sqlite3_exec(db, "PRAGMA journal_mode=WAL", nil, nil, nil) != SQLITE_OK {
                    print("⚠️ LocalDB: Failed to set WAL mode, continuing with default")
                }

                // Ensure sync-related tables exist
                createSyncTables()

                // Log stats (use internal method to avoid deadlock)
                if let count = _getFoodCountUnsafe() {
                    print("📊 LocalDB: \(count) foods available offline")
                }

                // Log database version
                if let version = _getDatabaseVersionUnsafe() {
                    print("📋 LocalDB: Database version = \(version)")
                }
            } else {
                let errorMsg = String(cString: sqlite3_errmsg(db))
                print("❌ LocalDB: Failed to open writable database: \(errorMsg) (code: \(result))")

                // Fallback: try to open bundled database directly
                openBundledDatabaseReadOnly()
            }
        }
    }

    /// Fallback: Open bundled database in read-only mode (no delta sync support)
    private func openBundledDatabaseReadOnly() {
        guard let bundledPath = bundledDatabasePath else { return }

        // CRIT-3 FIX: Use SQLITE_OPEN_FULLMUTEX for thread-safe concurrent access
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX
        let result = sqlite3_open_v2(bundledPath.path, &db, flags, nil)

        if result == SQLITE_OK {
            isInitialized = true
            print("⚠️ LocalDB: Opened bundled database (read-only fallback, no sync support)")
        }
    }

    /// Create tables needed for sync and usage tracking (for LRU eviction)
    private func createSyncTables() {
        // Usage tracking for LRU eviction
        let createUsageTable = """
            CREATE TABLE IF NOT EXISTS food_usage (
                food_id TEXT PRIMARY KEY,
                access_count INTEGER DEFAULT 1,
                last_accessed INTEGER NOT NULL,
                first_accessed INTEGER NOT NULL
            )
        """

        // Track evicted foods (can be re-fetched on demand)
        let createEvictedTable = """
            CREATE TABLE IF NOT EXISTS evicted_foods (
                food_id TEXT PRIMARY KEY,
                evicted_at INTEGER NOT NULL,
                original_source TEXT
            )
        """

        if sqlite3_exec(db, createUsageTable, nil, nil, nil) != SQLITE_OK {
            print("⚠️ LocalDB: Failed to create food_usage table")
        }
        if sqlite3_exec(db, createEvictedTable, nil, nil, nil) != SQLITE_OK {
            print("⚠️ LocalDB: Failed to create evicted_foods table")
        }

        // Ensure sync_state table exists (should be in bundled DB, but be safe)
        let createSyncStateTable = """
            CREATE TABLE IF NOT EXISTS sync_state (
                key TEXT PRIMARY KEY,
                value TEXT,
                updated_at INTEGER
            )
        """
        if sqlite3_exec(db, createSyncStateTable, nil, nil, nil) != SQLITE_OK {
            print("⚠️ LocalDB: Failed to create sync_state table")
        }
    }

    /// Reset database to fresh bundled version
    /// Call this on app version change to get latest food data
    func resetToFreshBundle() {
        dbQueue.sync {
            // Close current connection
            if db != nil {
                sqlite3_close(db)
                db = nil
                isInitialized = false
            }

            let fileManager = FileManager.default
            let dbPath = writableDatabasePath.path

            // Delete existing writable database
            if fileManager.fileExists(atPath: dbPath) {
                do {
                    try fileManager.removeItem(atPath: dbPath)
                    print("🗑️ LocalDB: Deleted old database")

                    // Also delete WAL and SHM files if they exist
                    try? fileManager.removeItem(atPath: dbPath + "-wal")
                    try? fileManager.removeItem(atPath: dbPath + "-shm")
                } catch {
                    print("❌ LocalDB: Failed to delete database: \(error)")
                    return
                }
            }
        }

        // Re-setup will copy fresh bundle
        setupDatabase()
        print("✅ LocalDB: Reset to fresh bundled database")
    }

    /// Internal database version - MUST be called from within dbQueue.sync
    private func _getDatabaseVersionUnsafe() -> String? {
        guard db != nil else { return nil }

        let sql = "SELECT value FROM sync_state WHERE key = 'db_version'"
        var stmt: OpaquePointer?
        var version: String?

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                if let cString = sqlite3_column_text(stmt, 0) {
                    version = String(cString: cString)
                }
            }
        }
        sqlite3_finalize(stmt)
        return version
    }

    /// Internal food count - MUST be called from within dbQueue.sync
    private func _getFoodCountUnsafe() -> Int? {
        guard db != nil else { return nil }

        let sql = "SELECT COUNT(*) FROM foods"
        var stmt: OpaquePointer?
        var count: Int?

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                count = Int(sqlite3_column_int64(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        return count
    }

    /// Closes the database connection
    private func closeDatabase() {
        dbQueue.sync {
            if db != nil {
                sqlite3_close(db)
                db = nil
                isInitialized = false
            }
        }
    }

    // MARK: - Public API

    /// Whether the local database is available for queries
    var isAvailable: Bool {
        return isInitialized && db != nil
    }

    /// Force refresh the database from the bundled copy
    /// Use this after app updates that include a new database
    func refreshFromBundle() {
        dbQueue.sync {
            // Close existing connection
            if db != nil {
                sqlite3_close(db)
                db = nil
                isInitialized = false
            }

            let fileManager = FileManager.default
            let dbPath = writableDatabasePath.path

            // Delete existing writable database
            if fileManager.fileExists(atPath: dbPath) {
                do {
                    try fileManager.removeItem(atPath: dbPath)
                    print("🗑️ LocalDB: Removed old database")
                } catch {
                    print("❌ LocalDB: Failed to remove old database: \(error)")
                    return
                }
            }
        }

        // Re-setup the database (will copy from bundle)
        setupDatabase()
        print("✅ LocalDB: Database refreshed from bundle")
    }

    /// Total number of foods in the database
    func getFoodCount() -> Int? {
        guard isAvailable else { return nil }

        var count: Int?
        dbQueue.sync {
            let sql = "SELECT COUNT(*) FROM foods"
            var stmt: OpaquePointer?

            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                if sqlite3_step(stmt) == SQLITE_ROW {
                    count = Int(sqlite3_column_int64(stmt, 0))
                }
            }
            sqlite3_finalize(stmt)
        }
        return count
    }

    /// Database version from sync_state table
    func getDatabaseVersion() -> String? {
        guard isAvailable else { return nil }

        var version: String?
        dbQueue.sync {
            let sql = "SELECT value FROM sync_state WHERE key = 'db_version'"
            var stmt: OpaquePointer?

            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                if sqlite3_step(stmt) == SQLITE_ROW {
                    if let cString = sqlite3_column_text(stmt, 0) {
                        version = String(cString: cString)
                    }
                }
            }
            sqlite3_finalize(stmt)
        }
        return version
    }

    /// Last sync timestamp
    func getLastSyncDate() -> Date? {
        guard isAvailable else { return nil }

        var timestamp: Int64?
        dbQueue.sync {
            let sql = "SELECT value FROM sync_state WHERE key = 'last_full_sync'"
            var stmt: OpaquePointer?

            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                if sqlite3_step(stmt) == SQLITE_ROW {
                    if let cString = sqlite3_column_text(stmt, 0) {
                        timestamp = Int64(String(cString: cString))
                    }
                }
            }
            sqlite3_finalize(stmt)
        }

        guard let ts = timestamp else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(ts) / 1000.0)
    }

    // MARK: - Search

    /// Search foods using FTS5 full-text search
    /// - Parameters:
    ///   - query: Search query string
    ///   - limit: Maximum results to return (default 20)
    /// - Returns: Array of FoodSearchResult matching the query
    func search(query: String, limit: Int = 20) -> [FoodSearchResult] {
        guard isAvailable else {
            print("⚠️ LocalDB: Database not available for search")
            return []
        }

        // Use same normalization as Algolia search for consistent results
        let normalized = SearchQueryNormalizer.normalize(query)
        var allResults: [FoodSearchResult] = []
        var seenIds = Set<String>()

        dbQueue.sync {
            // Build comprehensive query variants including:
            // 1. Primary normalized query
            // 2. All normalized variants (compound words, UK spellings, hyphen variants)
            // 3. Fuzzy/misspelling variants
            var queriesToSearch = [normalized.primary] + Array(normalized.variants.prefix(5))

            // Add fuzzy variants for typo tolerance (like "hellmans" -> "hellmann's")
            let fuzzyVariants = FuzzyMatcher.generateMisspellingVariants(normalized.primary)
            queriesToSearch.append(contentsOf: fuzzyVariants.prefix(3))

            // Remove duplicates
            queriesToSearch = Array(Set(queriesToSearch))

            for searchQuery in queriesToSearch {
                let sanitized = sanitizeFTSQuery(searchQuery)
                guard !sanitized.isEmpty else { continue }

                // FTS5 search with prefix matching
                let sql = """
                    SELECT f.id, f.name, f.brand, f.barcode,
                           f.calories, f.protein, f.carbs, f.fat,
                           f.saturated_fat, f.fiber, f.sugar, f.sodium,
                           f.serving_size_g, f.serving_description, f.is_per_unit,
                           f.ingredients_text, f.is_verified, f.image_url, f.source,
                           f.category
                    FROM foods f
                    JOIN foods_fts fts ON f.rowid = fts.rowid
                    WHERE foods_fts MATCH ?
                    ORDER BY rank
                    LIMIT ?
                """

                var stmt: OpaquePointer?

                if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                    // FTS5 prefix matching - each word gets a wildcard
                    let words = sanitized.split(separator: " ").map(String.init)
                    let ftsQuery = words.map { "\($0)*" }.joined(separator: " ")
                    sqlite3_bind_text(stmt, 1, ftsQuery, -1, SQLITE_TRANSIENT)
                    sqlite3_bind_int(stmt, 2, Int32(limit * 3)) // Fetch more for ranking

                    while sqlite3_step(stmt) == SQLITE_ROW {
                        if let food = parseFoodRow(stmt), !seenIds.contains(food.id) {
                            seenIds.insert(food.id)
                            allResults.append(food)
                        }
                    }
                } else {
                    let errorMessage = String(cString: sqlite3_errmsg(db))
                    print("❌ LocalDB: Search query failed for '\(sanitized)': \(errorMessage)")
                }

                sqlite3_finalize(stmt)

                // Stop early if we have enough results
                if allResults.count >= limit * 2 {
                    break
                }
            }

            // === FALLBACK: OR-based search if AND-based returned few results ===
            // FTS5 default is AND for multi-word queries, but sometimes OR is better
            // e.g., "chicken breast" should find "chicken" AND "breast" but also "grilled chicken breast"
            if allResults.count < limit / 2 {
                let sanitized = sanitizeFTSQuery(normalized.primary)
                let words = sanitized.split(separator: " ").map(String.init)

                if words.count > 1 {
                    // Search for each word separately and combine
                    for word in words {
                        let sql = """
                            SELECT f.id, f.name, f.brand, f.barcode,
                                   f.calories, f.protein, f.carbs, f.fat,
                                   f.saturated_fat, f.fiber, f.sugar, f.sodium,
                                   f.serving_size_g, f.serving_description, f.is_per_unit,
                                   f.ingredients_text, f.is_verified, f.image_url, f.source,
                                   f.category
                            FROM foods f
                            JOIN foods_fts fts ON f.rowid = fts.rowid
                            WHERE foods_fts MATCH ?
                            ORDER BY rank
                            LIMIT ?
                        """

                        var stmt: OpaquePointer?

                        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                            let ftsQuery = "\(word)*"
                            sqlite3_bind_text(stmt, 1, ftsQuery, -1, SQLITE_TRANSIENT)
                            sqlite3_bind_int(stmt, 2, Int32(limit))

                            while sqlite3_step(stmt) == SQLITE_ROW {
                                if let food = parseFoodRow(stmt), !seenIds.contains(food.id) {
                                    seenIds.insert(food.id)
                                    allResults.append(food)
                                }
                            }
                        }

                        sqlite3_finalize(stmt)
                    }
                }
            }
        }

        // Apply intelligent ranking (same logic as Algolia)
        let rankedResults = rankResults(allResults, query: query, normalized: normalized)

        return Array(rankedResults.prefix(limit))
    }

    /// Rank search results using same logic as Algolia search
    private func rankResults(_ results: [FoodSearchResult], query: String, normalized: NormalizedQuery) -> [FoodSearchResult] {
        let queryLower = query.lowercased()
        let queryWords = Set(queryLower.split(separator: " ").map { String($0) })

        // Single-serve indicators (boost these)
        let singleServeIndicators: Set<String> = [
            "330ml", "250ml", "500ml", "can", "bottle", "carton",
            "bar", "single", "standard", "regular",
            "portion", "serving", "individual", "1x", "each",
            "25g", "30g", "32g", "35g", "40g", "45g", "50g", "51g", "52g", "58g"
        ]

        // Multipack indicators (demote these)
        let bulkIndicators: Set<String> = [
            "multipack", "multi-pack", "multi pack", "case", "tray", "box of",
            "24 pack", "24pk", "24x", "x24", "18 pack", "18pk", "18x", "x18",
            "12 pack", "12pk", "12x", "x12", "10 pack", "10pk", "10x", "x10",
            "8 pack", "8pk", "8x", "x8", "6 pack", "6pk", "6x", "x6",
            "4 pack", "4pk", "4x", "x4", "3 pack", "3pk", "3x", "x3",
            "2 pack", "2pk", "2x", "x2", "bulk", "wholesale", "catering",
            "family pack", "sharing", "value pack", "bundle", "selection"
        ]

        let scored = results.map { result -> (result: FoodSearchResult, score: Int) in
            let nameLower = result.name.lowercased()
            let nameWords = Set(nameLower.split(separator: " ").map { String($0) })
            let brandLower = result.brand?.lowercased() ?? ""

            var score = 0

            // === TIER 0: EXACT NAME MATCH (highest priority) ===
            if nameLower == queryLower {
                score += 20000
            }

            // === TIER 1: NAME STARTS WITH QUERY ===
            if nameLower.hasPrefix(queryLower) {
                score += 15000
            }

            // === TIER 2: WORD MATCH SCORING ===
            let matchingWords = queryWords.intersection(nameWords)
            score += matchingWords.count * 3000

            // Bonus for matching in order at start
            if nameLower.hasPrefix(queryWords.first ?? "") {
                score += 2000
            }

            // === TIER 3: BRAND MATCHING ===
            if !brandLower.isEmpty {
                if queryWords.contains(brandLower) || brandLower.contains(queryLower) {
                    score += 2500
                }
            }

            // === TIER 4: SINGLE-SERVE vs MULTIPACK ===
            // Boost single-serve items (users typically log individual portions)
            for indicator in singleServeIndicators {
                if nameLower.contains(indicator) {
                    score += 500
                    break
                }
            }

            // Demote multipacks (users rarely want 24-pack when logging)
            for indicator in bulkIndicators {
                if nameLower.contains(indicator) {
                    score -= 3000
                    break
                }
            }

            // === TIER 5: IMAGE BOOST ===
            // Products with images are slightly preferred (tiebreaker)
            if let imageUrl = result.imageUrl, !imageUrl.isEmpty {
                score += 200
            }

            // === TIER 6: VERIFIED BOOST ===
            if result.isVerified == true {
                score += 300
            }

            // === TIER 7: CONSUMER FOODS BOOST (for generic searches) ===
            // When searching for generic foods like "apple", "banana", etc., heavily boost
            // items from consumer_foods index since users want raw ingredients, not branded products
            if let source = result.source, source == "consumer_foods" {
                // Always give consumer foods a moderate boost
                score += 3000
            }

            // === INTENT-SPECIFIC SCORING ===
            switch normalized.intent {
            case .genericFood(let food):
                // For generic queries like "banana", prefer raw/base foods

                // MAJOR BOOST: Consumer foods get significant priority for generic searches
                // This ensures "Apple" from consumer_foods ranks above "Apple Juice" from Tesco
                if let source = result.source, source == "consumer_foods" {
                    score += 8000
                }

                // Demote prepared foods
                if PreparedFoodDetector.isPreparedFood(result.name) {
                    score -= 2000
                }
                // Boost if name is short (likely raw ingredient)
                if nameWords.count <= 3 {
                    score += 1000
                }
                // Exact match for generic food
                if nameLower == food || nameLower.hasPrefix(food + " ") || nameLower.hasPrefix(food + ",") {
                    score += 5000
                }

            case .brandOnly(let brand):
                // Pure brand search - boost brand matches
                if brandLower == brand || brandLower.hasPrefix(brand) {
                    score += 4000
                }

            case .brandAndProduct(let brand, let product):
                // Brand + product - boost both matches
                if brandLower.contains(brand) {
                    score += 2000
                }
                if nameLower.contains(product) {
                    score += 2000
                }

            case .productSearch:
                // General product search - no special adjustments
                break

            case .barcode:
                // Barcode handled separately
                break
            }

            return (result, score)
        }

        // Sort by score descending, then by name for consistency
        return scored
            .sorted { $0.score > $1.score || ($0.score == $1.score && $0.result.name < $1.result.name) }
            .map { $0.result }
    }

    /// Search by barcode (exact match)
    /// - Parameter barcode: The barcode to search for
    /// - Returns: FoodSearchResult if found
    /// Note: Handles GTIN-14 ↔ EAN-13 conversion for Tesco products
    func searchByBarcode(_ barcode: String) -> FoodSearchResult? {
        guard isAvailable else { return nil }

        var result: FoodSearchResult?

        dbQueue.sync {
            // Search barcode column with both original and converted formats
            // Tesco uses GTIN-14 (14 digits with leading 0), scanners provide EAN-13 (13 digits)
            // Also search barcodes JSON array for alternative barcodes
            let sql = """
                SELECT id, name, brand, barcode,
                       calories, protein, carbs, fat,
                       saturated_fat, fiber, sugar, sodium,
                       serving_size_g, serving_description, is_per_unit,
                       ingredients_text, is_verified, image_url, source,
                       category
                FROM foods
                WHERE barcode = ?1
                   OR barcode = ?2
                   OR barcodes LIKE ?3
                   OR barcodes LIKE ?4
                ORDER BY source_priority ASC
                LIMIT 1
            """

            var stmt: OpaquePointer?

            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                // ?1 = original barcode
                sqlite3_bind_text(stmt, 1, barcode, -1, SQLITE_TRANSIENT)

                // ?2 = converted barcode (EAN-13 ↔ GTIN-14)
                // If 13 digits not starting with 0, add leading 0 for GTIN-14
                // If 14 digits starting with 0, remove leading 0 for EAN-13
                let convertedBarcode: String
                if barcode.count == 13 && !barcode.hasPrefix("0") {
                    convertedBarcode = "0" + barcode  // EAN-13 → GTIN-14
                } else if barcode.count == 14 && barcode.hasPrefix("0") {
                    convertedBarcode = String(barcode.dropFirst())  // GTIN-14 → EAN-13
                } else {
                    convertedBarcode = barcode  // No conversion needed
                }
                sqlite3_bind_text(stmt, 2, convertedBarcode, -1, SQLITE_TRANSIENT)

                // ?3 = LIKE pattern for original barcode in barcodes JSON array
                let likePattern = "%\(barcode)%"
                sqlite3_bind_text(stmt, 3, likePattern, -1, SQLITE_TRANSIENT)

                // ?4 = LIKE pattern for converted barcode in barcodes JSON array
                let convertedLikePattern = "%\(convertedBarcode)%"
                sqlite3_bind_text(stmt, 4, convertedLikePattern, -1, SQLITE_TRANSIENT)

                if sqlite3_step(stmt) == SQLITE_ROW {
                    result = parseFoodRow(stmt)
                }
            }

            sqlite3_finalize(stmt)
        }

        return result
    }

    /// Get food by ID
    /// - Parameter id: The food ID
    /// - Returns: FoodSearchResult if found
    func getFood(byId id: String) -> FoodSearchResult? {
        guard isAvailable else { return nil }

        var result: FoodSearchResult?

        dbQueue.sync {
            let sql = """
                SELECT id, name, brand, barcode,
                       calories, protein, carbs, fat,
                       saturated_fat, fiber, sugar, sodium,
                       serving_size_g, serving_description, is_per_unit,
                       ingredients_text, is_verified, image_url, source,
                       category
                FROM foods
                WHERE id = ?
                LIMIT 1
            """

            var stmt: OpaquePointer?

            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, id, -1, SQLITE_TRANSIENT)

                if sqlite3_step(stmt) == SQLITE_ROW {
                    result = parseFoodRow(stmt)
                }
            }

            sqlite3_finalize(stmt)
        }

        return result
    }

    // MARK: - Delete Operations

    /// Delete a food by its ID
    /// Used to sync deletions from Firebase to local database
    /// - Parameter foodId: The food's objectID
    /// - Returns: true if deleted, false if not found or error
    func deleteFood(byId foodId: String) -> Bool {
        guard isAvailable else { return false }

        var success = false
        dbQueue.sync {
            success = applyDelete(foodId: foodId)
            if success {
                print("🗑️ LocalDB: Deleted food \(foodId)")
            }
        }
        return success
    }

    /// Delete multiple foods by their IDs
    /// Used for bulk deletion sync from Firebase
    /// - Parameter foodIds: Array of food objectIDs to delete
    /// - Returns: Number of successfully deleted foods
    func deleteFoods(byIds foodIds: [String]) -> Int {
        guard isAvailable, !foodIds.isEmpty else { return 0 }

        var deletedCount = 0
        dbQueue.sync {
            for foodId in foodIds {
                if applyDelete(foodId: foodId) {
                    deletedCount += 1
                }
            }
            if deletedCount > 0 {
                print("🗑️ LocalDB: Deleted \(deletedCount) foods")
            }
        }
        return deletedCount
    }

    /// Delete a food by its barcode (handles both EAN-13 and GTIN-14 formats)
    /// - Parameter barcode: The barcode to delete
    /// - Returns: true if deleted, false if not found or error
    func deleteFood(byBarcode barcode: String) -> Bool {
        guard isAvailable else { return false }

        var success = false
        dbQueue.sync {
            // Delete both original and converted barcode formats
            var sql = "DELETE FROM foods WHERE barcode = ?"
            var stmt: OpaquePointer?

            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, barcode, -1, SQLITE_TRANSIENT)
                sqlite3_step(stmt)
                let changes1 = sqlite3_changes(db)
                sqlite3_finalize(stmt)

                // Also try converted barcode (EAN-13 ↔ GTIN-14)
                let convertedBarcode: String
                if barcode.count == 13 && !barcode.hasPrefix("0") {
                    convertedBarcode = "0" + barcode
                } else if barcode.count == 14 && barcode.hasPrefix("0") {
                    convertedBarcode = String(barcode.dropFirst())
                } else {
                    convertedBarcode = barcode
                }

                if convertedBarcode != barcode {
                    if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                        sqlite3_bind_text(stmt, 1, convertedBarcode, -1, SQLITE_TRANSIENT)
                        sqlite3_step(stmt)
                        let changes2 = sqlite3_changes(db)
                        sqlite3_finalize(stmt)
                        success = (changes1 + changes2) > 0
                    }
                } else {
                    success = changes1 > 0
                }

                if success {
                    print("🗑️ LocalDB: Deleted food with barcode \(barcode)")
                }
            }
        }
        return success
    }

    // MARK: - Private Helpers

    /// Sanitize search query for FTS5
    /// Removes special characters that could cause FTS5 syntax errors
    private func sanitizeFTSQuery(_ query: String) -> String {
        // Remove FTS5 special characters that could cause syntax errors
        let sanitized = query
            .lowercased()
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "'", with: "")  // Apostrophes cause FTS issues
            .replacingOccurrences(of: "'", with: "")  // Curly apostrophe
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "^", with: "")
            .replacingOccurrences(of: "-", with: " ") // Convert hyphens to spaces for word matching
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return sanitized
    }

    /// Parse a SQLite row into FoodSearchResult
    private func parseFoodRow(_ stmt: OpaquePointer?) -> FoodSearchResult? {
        guard let stmt = stmt else { return nil }

        // Helper to get optional string
        func getString(_ col: Int32) -> String? {
            guard let cString = sqlite3_column_text(stmt, col) else { return nil }
            return String(cString: cString)
        }

        // Helper to get double with default
        func getDouble(_ col: Int32) -> Double {
            return sqlite3_column_double(stmt, col)
        }

        // Helper to get optional double
        func getOptionalDouble(_ col: Int32) -> Double? {
            if sqlite3_column_type(stmt, col) == SQLITE_NULL {
                return nil
            }
            return sqlite3_column_double(stmt, col)
        }

        // Helper to get bool from int
        func getBool(_ col: Int32) -> Bool {
            return sqlite3_column_int(stmt, col) != 0
        }

        // Parse ID - strip source prefix for cleaner display
        guard let rawId = getString(0) else { return nil }
        // IDs are stored as "source:originalId" - we can keep or strip
        let id = rawId

        guard let name = getString(1) else { return nil }

        // Parse ingredients from text to array
        var ingredients: [String]? = nil
        if let ingredientsText = getString(15) {
            ingredients = ingredientsText
                .components(separatedBy: CharacterSet(charactersIn: ",;"))
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }

        return FoodSearchResult(
            id: id,
            name: name,
            brand: getString(2),
            calories: getDouble(4),
            protein: getDouble(5),
            carbs: getDouble(6),
            fat: getDouble(7),
            saturatedFat: getOptionalDouble(8),
            fiber: getOptionalDouble(9) ?? 0,
            sugar: getOptionalDouble(10) ?? 0,
            sodium: getOptionalDouble(11) ?? 0,
            servingDescription: getString(13),
            servingSizeG: getOptionalDouble(12),
            isPerUnit: getBool(14),
            ingredients: ingredients,
            confidence: nil,
            isVerified: getBool(16),
            additives: nil,
            additivesDatabaseVersion: nil,
            processingScore: nil,
            processingGrade: nil,
            processingLabel: nil,
            barcode: getString(3),
            gtin: nil,
            micronutrientProfile: nil,
            portions: nil,
            source: getString(18),
            imageUrl: getString(17),
            foodCategory: getString(19),
            suggestedServingSize: nil,
            suggestedServingUnit: nil,
            suggestedServingDescription: nil,
            unitOverrideLocked: nil
        )
    }

    // MARK: - Delta Sync Application

    /// Apply delta updates from server to local database
    /// - Parameter updates: Array of update records from getFoodDatabaseDelta
    /// - Returns: Number of updates successfully applied
    func applyDeltaUpdates(_ updates: [[String: Any]]) -> Int {
        guard isAvailable else { return 0 }

        var appliedCount = 0

        dbQueue.sync {
            // Begin transaction for atomicity
            if sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil) != SQLITE_OK {
                print("❌ LocalDB: Failed to begin transaction for delta updates")
                return
            }

            var transactionFailed = false

            for update in updates {
                guard let action = update["action"] as? String,
                      let foodId = update["foodId"] as? String else { continue }

                switch action {
                case "add", "update":
                    if let food = update["food"] as? [String: Any] {
                        if applyUpsert(foodId: foodId, food: food) {
                            appliedCount += 1
                        } else {
                            transactionFailed = true
                            print("❌ LocalDB: Failed to upsert food \(foodId)")
                            break
                        }
                    }

                case "delete":
                    if applyDelete(foodId: foodId) {
                        appliedCount += 1
                    }
                    // Note: Delete failures are non-critical (food may already be gone)

                default:
                    // Handle batch operations by marking for full resync
                    if action.hasPrefix("batch_") {
                        if let indexName = update["indexName"] as? String {
                            markIndexForResync(indexName)
                        }
                    }
                }

                if transactionFailed { break }
            }

            // Rollback on failure, commit on success
            if transactionFailed {
                if sqlite3_exec(db, "ROLLBACK", nil, nil, nil) != SQLITE_OK {
                    print("❌ LocalDB: Failed to rollback transaction")
                }
                appliedCount = 0  // Reset count since we rolled back
            } else {
                if sqlite3_exec(db, "COMMIT", nil, nil, nil) != SQLITE_OK {
                    print("❌ LocalDB: Failed to commit transaction")
                    appliedCount = 0
                }
            }
        }

        // Rebuild FTS index after batch changes
        if appliedCount > 0 {
            rebuildFTSIndex()

            // DATA CONSISTENCY FIX: Notify to invalidate search cache
            // This ensures stale nutrition data isn't shown after database updates
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .localDatabaseUpdated, object: nil, userInfo: ["updatedCount": appliedCount])
            }
        }

        return appliedCount
    }

    /// Upsert a single food record
    private func applyUpsert(foodId: String, food: [String: Any]) -> Bool {
        let sql = """
            INSERT OR REPLACE INTO foods (
                id, source, source_priority, name, brand, barcode, barcodes,
                calories, protein, carbs, fat, saturated_fat, fiber, sugar, sodium,
                serving_size_g, serving_description, is_per_unit,
                ingredients_text, category, image_url, is_verified,
                search_tokens, last_synced
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            print("❌ Delta: Failed to prepare upsert statement")
            return false
        }
        defer { sqlite3_finalize(stmt) }

        // Determine source from foodId prefix or food data
        let source = (food["source"] as? String) ?? extractSource(from: foodId)
        let sourcePriority = getSourcePriority(source)
        let name = food["name"] as? String ?? "Unknown"

        // Handle barcodes - convert array to JSON string for storage
        // The barcodes array includes both GTIN-14 and EAN-13 for better search coverage
        var barcodesJson: String? = nil
        if let barcodesArray = food["barcodes"] as? [String], !barcodesArray.isEmpty {
            if let data = try? JSONSerialization.data(withJSONObject: barcodesArray),
               let json = String(data: data, encoding: .utf8) {
                barcodesJson = json
            }
        }

        // Bind parameters
        sqlite3_bind_text(stmt, 1, foodId, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, source, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(stmt, 3, Int32(sourcePriority))
        sqlite3_bind_text(stmt, 4, name, -1, SQLITE_TRANSIENT)
        bindOptionalText(stmt, 5, food["brand"] as? String)
        bindOptionalText(stmt, 6, food["barcode"] as? String)
        bindOptionalText(stmt, 7, barcodesJson)
        sqlite3_bind_double(stmt, 8, food["calories"] as? Double ?? 0)
        sqlite3_bind_double(stmt, 9, food["protein"] as? Double ?? 0)
        sqlite3_bind_double(stmt, 10, food["carbs"] as? Double ?? 0)
        sqlite3_bind_double(stmt, 11, food["fat"] as? Double ?? 0)
        bindOptionalDouble(stmt, 12, food["saturatedFat"] as? Double)
        bindOptionalDouble(stmt, 13, food["fiber"] as? Double)
        bindOptionalDouble(stmt, 14, food["sugar"] as? Double)
        bindOptionalDouble(stmt, 15, food["sodium"] as? Double)
        bindOptionalDouble(stmt, 16, food["servingSizeG"] as? Double)
        bindOptionalText(stmt, 17, food["servingDescription"] as? String)
        sqlite3_bind_int(stmt, 18, (food["isPerUnit"] as? Bool ?? false) ? 1 : 0)
        bindOptionalText(stmt, 19, food["ingredients"] as? String)
        bindOptionalText(stmt, 20, food["category"] as? String)
        bindOptionalText(stmt, 21, food["imageUrl"] as? String)
        sqlite3_bind_int(stmt, 22, (food["isVerified"] as? Bool ?? false) ? 1 : 0)
        sqlite3_bind_text(stmt, 23, generateSearchTokens(name: name, brand: food["brand"] as? String, barcode: food["barcode"] as? String), -1, SQLITE_TRANSIENT)
        sqlite3_bind_int64(stmt, 24, Int64(Date().timeIntervalSince1970 * 1000))

        return sqlite3_step(stmt) == SQLITE_DONE
    }

    /// Delete a food record
    private func applyDelete(foodId: String) -> Bool {
        let sql = "DELETE FROM foods WHERE id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, foodId, -1, SQLITE_TRANSIENT)
        return sqlite3_step(stmt) == SQLITE_DONE
    }

    /// Update database version in sync_state
    func updateDatabaseVersion(_ version: String) {
        guard isAvailable else { return }

        dbQueue.sync {
            let sql = "INSERT OR REPLACE INTO sync_state (key, value, updated_at) VALUES (?, ?, ?)"
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
            defer { sqlite3_finalize(stmt) }

            sqlite3_bind_text(stmt, 1, "db_version", -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 2, version, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int64(stmt, 3, Int64(Date().timeIntervalSince1970 * 1000))
            sqlite3_step(stmt)
        }
    }

    /// Mark an index for full resync (for batch operations)
    private func markIndexForResync(_ indexName: String) {
        let sql = "INSERT OR REPLACE INTO sync_state (key, value, updated_at) VALUES (?, ?, ?)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, "resync_index_\(indexName)", -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, "pending", -1, SQLITE_TRANSIENT)
        sqlite3_bind_int64(stmt, 3, Int64(Date().timeIntervalSince1970 * 1000))
        sqlite3_step(stmt)
    }

    /// Rebuild FTS index after delta changes
    /// RACE CONDITION FIX: Use sync instead of async to prevent stale db pointer
    /// The db pointer can become nil if closeDatabase() is called while async block is waiting
    private func rebuildFTSIndex() {
        // FIX: Use sync instead of async to ensure db pointer is valid throughout operation
        // This prevents use-after-free crash when database closes during async operation
        dbQueue.sync { [weak self] in
            guard let self = self else { return }
            // Double-check db and isInitialized under lock to prevent race
            guard self.isInitialized, let db = self.db else {
                print("⚠️ Delta: Cannot rebuild FTS - database not initialized or closed")
                return
            }
            // Rebuild FTS content
            if sqlite3_exec(db, "INSERT INTO foods_fts(foods_fts) VALUES('rebuild')", nil, nil, nil) != SQLITE_OK {
                let errorMsg = String(cString: sqlite3_errmsg(db))
                print("⚠️ Delta: Failed to rebuild FTS index: \(errorMsg)")
            } else {
                print("📝 Delta: Rebuilt FTS index")
            }
        }
    }

    // MARK: - Usage Tracking (for LRU eviction)

    /// Record that a food was accessed (for LRU tracking)
    /// Note: Uses async for performance since this is non-critical tracking data
    /// The db check inside the block prevents crashes if database closes
    func recordFoodAccess(_ foodId: String) {
        guard isAvailable else { return }

        dbQueue.async { [weak self] in
            // FIX: Check isInitialized AND db in one guard to prevent race
            guard let self = self, self.isInitialized, let db = self.db else { return }

            let now = Int64(Date().timeIntervalSince1970 * 1000)
            let sql = """
                INSERT INTO food_usage (food_id, access_count, last_accessed, first_accessed)
                VALUES (?, 1, ?, ?)
                ON CONFLICT(food_id) DO UPDATE SET
                    access_count = access_count + 1,
                    last_accessed = excluded.last_accessed
            """

            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
            defer { sqlite3_finalize(stmt) }

            sqlite3_bind_text(stmt, 1, foodId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int64(stmt, 2, now)
            sqlite3_bind_int64(stmt, 3, now)
            sqlite3_step(stmt)
        }
    }

    /// Get least recently used foods for potential eviction
    func getLeastUsedFoods(limit: Int = 1000) -> [String] {
        guard isAvailable else { return [] }

        var foodIds: [String] = []

        dbQueue.sync {
            // Get foods ordered by: access_count (ascending), last_accessed (ascending)
            // This prioritizes evicting rarely-used, old items
            let sql = """
                SELECT f.id FROM foods f
                LEFT JOIN food_usage u ON f.id = u.food_id
                ORDER BY COALESCE(u.access_count, 0) ASC,
                         COALESCE(u.last_accessed, 0) ASC
                LIMIT ?
            """

            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
            defer { sqlite3_finalize(stmt) }

            sqlite3_bind_int(stmt, 1, Int32(limit))

            while sqlite3_step(stmt) == SQLITE_ROW {
                if let cString = sqlite3_column_text(stmt, 0) {
                    foodIds.append(String(cString: cString))
                }
            }
        }

        return foodIds
    }

    // MARK: - LRU Eviction

    /// Target database size in bytes (50MB)
    private static let targetDatabaseSize: Int64 = 50 * 1024 * 1024

    /// Eviction threshold - trigger when 20% over target
    private static let evictionThreshold: Double = 1.2

    /// Check if eviction is needed and perform if necessary
    func checkAndEvictIfNeeded() {
        guard isAvailable else { return }

        let currentSize = getDatabaseSize()
        let threshold = Int64(Double(Self.targetDatabaseSize) * Self.evictionThreshold)

        if currentSize > threshold {
            print("📊 LocalDB: Size \(currentSize / 1024 / 1024)MB exceeds threshold, starting eviction...")
            performEviction(targetSize: Self.targetDatabaseSize)
        }
    }

    /// Get current database file size
    /// Note: File size is accessed from filesystem, not database, so it's safe to call outside dbQueue
    /// However, for accurate size after WAL mode writes, we should checkpoint first
    private func getDatabaseSize() -> Int64 {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: writableDatabasePath.path),
              let size = attrs[.size] as? Int64 else {
            return 0
        }
        // Also add WAL file size if it exists (WAL mode writes there first)
        let walPath = writableDatabasePath.path + "-wal"
        let walSize: Int64
        if let walAttrs = try? FileManager.default.attributesOfItem(atPath: walPath),
           let ws = walAttrs[.size] as? Int64 {
            walSize = ws
        } else {
            walSize = 0
        }
        return size + walSize
    }

    /// Evict least-used foods until database is under target size
    private func performEviction(targetSize: Int64) {
        let batchSize = 500
        var evictedCount = 0
        var iterationCount = 0
        let maxIterations = 20  // Safety limit: max eviction rounds

        while getDatabaseSize() > targetSize && iterationCount < maxIterations {
            iterationCount += 1
            let previousSize = getDatabaseSize()

            let toEvict = getLeastUsedFoods(limit: batchSize)

            if toEvict.isEmpty {
                print("⚠️ LocalDB: No more foods to evict")
                break
            }

            dbQueue.sync {
                if sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil) != SQLITE_OK {
                    print("❌ LocalDB: Failed to begin eviction transaction")
                    return
                }

                for foodId in toEvict {
                    // Move to evicted_foods table before deleting
                    let moveSQL = """
                        INSERT OR REPLACE INTO evicted_foods (food_id, evicted_at, original_source)
                        SELECT id, ?, source FROM foods WHERE id = ?
                    """
                    var moveStmt: OpaquePointer?
                    if sqlite3_prepare_v2(db, moveSQL, -1, &moveStmt, nil) == SQLITE_OK {
                        sqlite3_bind_int64(moveStmt, 1, Int64(Date().timeIntervalSince1970 * 1000))
                        sqlite3_bind_text(moveStmt, 2, foodId, -1, SQLITE_TRANSIENT)
                        sqlite3_step(moveStmt)
                        sqlite3_finalize(moveStmt)
                    }

                    // Delete from main table
                    let deleteSQL = "DELETE FROM foods WHERE id = ?"
                    var deleteStmt: OpaquePointer?
                    if sqlite3_prepare_v2(db, deleteSQL, -1, &deleteStmt, nil) == SQLITE_OK {
                        sqlite3_bind_text(deleteStmt, 1, foodId, -1, SQLITE_TRANSIENT)
                        sqlite3_step(deleteStmt)
                        sqlite3_finalize(deleteStmt)
                    }

                    // Delete from usage tracking
                    let usageSQL = "DELETE FROM food_usage WHERE food_id = ?"
                    var usageStmt: OpaquePointer?
                    if sqlite3_prepare_v2(db, usageSQL, -1, &usageStmt, nil) == SQLITE_OK {
                        sqlite3_bind_text(usageStmt, 1, foodId, -1, SQLITE_TRANSIENT)
                        sqlite3_step(usageStmt)
                        sqlite3_finalize(usageStmt)
                    }

                    evictedCount += 1
                }

                if sqlite3_exec(db, "COMMIT", nil, nil, nil) != SQLITE_OK {
                    print("❌ LocalDB: Failed to commit eviction transaction")
                }
            }

            // Safety limit on total evicted items
            if evictedCount >= 5000 {
                print("⚠️ LocalDB: Hit eviction safety limit (5000 items)")
                break
            }

            // Check if size actually decreased - if not, VACUUM and check again
            let currentSize = getDatabaseSize()
            if currentSize >= previousSize {
                print("⚠️ LocalDB: Size didn't decrease after eviction batch, running VACUUM...")
                dbQueue.sync {
                    if sqlite3_exec(db, "VACUUM", nil, nil, nil) != SQLITE_OK {
                        print("❌ LocalDB: VACUUM failed")
                    }
                }
                // Check again after VACUUM
                let sizeAfterVacuum = getDatabaseSize()
                if sizeAfterVacuum >= previousSize {
                    print("⚠️ LocalDB: Size still didn't decrease after VACUUM, stopping eviction")
                    break
                }
            }
        }

        if iterationCount >= maxIterations {
            print("⚠️ LocalDB: Hit eviction iteration limit (\(maxIterations))")
        }

        // Final VACUUM to reclaim space
        // FIX: Use sync to ensure db pointer is valid and operation completes before method returns
        dbQueue.sync { [weak self] in
            guard let self = self, self.isInitialized, let db = self.db else {
                print("⚠️ LocalDB: Cannot VACUUM - database not initialized or closed")
                return
            }
            if sqlite3_exec(db, "VACUUM", nil, nil, nil) != SQLITE_OK {
                let errorMsg = String(cString: sqlite3_errmsg(db))
                print("⚠️ LocalDB: Final VACUUM failed: \(errorMsg)")
            }
        }
        print("✅ LocalDB: Evicted \(evictedCount) foods, new size: \(getDatabaseSize() / 1024 / 1024)MB")
    }

    /// Check if a food was evicted (for on-demand re-fetch)
    func isEvicted(_ foodId: String) -> Bool {
        guard isAvailable else { return false }

        var evicted = false

        dbQueue.sync {
            let sql = "SELECT 1 FROM evicted_foods WHERE food_id = ?"
            var stmt: OpaquePointer?

            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, foodId, -1, SQLITE_TRANSIENT)
                evicted = sqlite3_step(stmt) == SQLITE_ROW
            }
            sqlite3_finalize(stmt)
        }

        return evicted
    }

    // MARK: - Helper Methods

    private func bindOptionalText(_ stmt: OpaquePointer?, _ index: Int32, _ value: String?) {
        if let v = value {
            sqlite3_bind_text(stmt, index, v, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(stmt, index)
        }
    }

    private func bindOptionalDouble(_ stmt: OpaquePointer?, _ index: Int32, _ value: Double?) {
        if let v = value {
            sqlite3_bind_double(stmt, index, v)
        } else {
            sqlite3_bind_null(stmt, index)
        }
    }

    private func extractSource(from foodId: String) -> String {
        // Format: "source:id" e.g., "consumer_foods:consumer_0202"
        if let colonIndex = foodId.firstIndex(of: ":") {
            return String(foodId[..<colonIndex])
        }
        return "unknown"
    }

    private func getSourcePriority(_ source: String) -> Int {
        let priorities = [
            "consumer_foods": 0,
            "tesco_products": 1,
            "uk_foods_cleaned": 2,
            "verified_foods": 3,
            "ai_enhanced": 4,
            "ai_manually_added": 5,
            "user_added": 6,
            "foods": 7,
            "fast_foods_database": 8,
            "generic_database": 9,
            "manual_foods": 10,
        ]
        return priorities[source] ?? 99
    }

    private func generateSearchTokens(name: String, brand: String?, barcode: String?) -> String {
        var tokens: [String] = [name.lowercased()]
        if let b = brand { tokens.append(b.lowercased()) }
        if let bc = barcode { tokens.append(bc) }
        return tokens.joined(separator: " ")
    }
}

// MARK: - Database Sync Manager

/// Handles background sync of the local food database with the server
class DatabaseSyncManager {
    static let shared = DatabaseSyncManager()

    private let syncQueue = DispatchQueue(label: "com.nutrasafe.sync", qos: .utility)
    private let functionsBaseURL = "https://us-central1-nutrasafe-705c7.cloudfunctions.net"

    /// Minimum time between sync attempts (5 minutes - more responsive than 1 hour)
    private let minSyncInterval: TimeInterval = 300

    /// Key for storing last sync time
    private let lastSyncKey = "lastDatabaseSyncTimestamp"

    /// Key for storing last synced version
    private let lastVersionKey = "lastSyncedDatabaseVersion"

    /// Thread-safe storage for sync state
    private let syncStateLock = NSLock()
    private var _isSyncing = false

    /// Thread-safe access to sync status - can be called from any context
    private var isSyncing: Bool {
        get {
            syncStateLock.lock()
            defer { syncStateLock.unlock() }
            return _isSyncing
        }
        set {
            syncStateLock.lock()
            defer { syncStateLock.unlock() }
            _isSyncing = newValue
        }
    }

    private init() {
        setupNetworkObserver()
    }

    /// Listen for network reconnection to trigger immediate sync
    private func setupNetworkObserver() {
        NotificationCenter.default.addObserver(
            forName: .networkReconnected,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🔄 Sync: Network reconnected - triggering immediate sync")
            Task {
                await self?.forceSync()
            }
        }
    }

    /// Check if sync is needed and perform if necessary
    /// Called on app launch and when network becomes available
    func syncIfNeeded() {
        guard NetworkMonitor.shared.isConnected else {
            print("📴 Sync: Offline, skipping sync check")
            return
        }

        guard LocalDatabaseManager.shared.isAvailable else {
            print("⚠️ Sync: Local database not available")
            return
        }

        guard !isSyncing else {
            print("⏳ Sync: Already in progress")
            return
        }

        // Check if enough time has passed since last sync
        let lastSync = UserDefaults.standard.double(forKey: lastSyncKey)
        let timeSinceLastSync = Date().timeIntervalSince1970 - lastSync

        if timeSinceLastSync < minSyncInterval {
            print("⏳ Sync: Last sync was \(Int(timeSinceLastSync/60)) minutes ago, skipping")
            return
        }

        // Perform sync in background
        syncQueue.async {
            Task {
                await self.performDeltaSync()
            }
        }
    }

    /// Force sync regardless of timing
    func forceSync() async {
        guard NetworkMonitor.shared.isConnected else {
            print("📴 Sync: Cannot force sync while offline")
            return
        }

        guard !isSyncing else {
            print("⏳ Sync: Already in progress")
            return
        }

        await performDeltaSync()
    }

    /// Perform delta sync with the server
    @discardableResult
    private func performDeltaSync() async -> Bool {
        isSyncing = true
        defer { isSyncing = false }

        print("🔄 Sync: Starting delta sync...")

        // Get current local database version
        let localVersion = LocalDatabaseManager.shared.getDatabaseVersion() ?? "0"
        print("📊 Sync: Local version: \(localVersion)")

        // Check server for updates
        do {
            let serverVersion = try await checkServerVersion()
            print("📊 Sync: Server version: \(serverVersion)")

            if serverVersion == localVersion {
                print("✅ Sync: Database is up to date")
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastSyncKey)
                return false
            }

            // Fetch delta updates with pagination
            var allUpdates: [[String: Any]] = []
            var currentVersion = localVersion
            var hasMore = true
            var iterations = 0
            let maxIterations = 20 // Safety limit: max pagination rounds
            let maxTotalTime: TimeInterval = 20 // Safety limit: 20 second timeout (iOS background ~30s)
            let syncStartTime = Date()

            while hasMore && iterations < maxIterations {
                // Check total timeout to prevent infinite sync loops
                let elapsed = Date().timeIntervalSince(syncStartTime)
                if elapsed > maxTotalTime {
                    print("⚠️ Sync: Total timeout exceeded (\(Int(elapsed))s), stopping")
                    break
                }

                let result = try await fetchDelta(sinceVersion: currentVersion)

                if result.updates.isEmpty {
                    hasMore = false
                } else {
                    allUpdates.append(contentsOf: result.updates)
                    currentVersion = result.currentVersion
                    hasMore = result.hasMore
                }

                iterations += 1

                // Safety: if too many updates, something is wrong
                if allUpdates.count > 10000 {
                    print("⚠️ Sync: Too many updates (\(allUpdates.count)), may need full resync")
                    break
                }
            }

            if allUpdates.isEmpty {
                print("✅ Sync: No updates available")
            } else {
                print("📥 Sync: Applying \(allUpdates.count) updates...")

                // Apply delta updates to local database
                let appliedCount = LocalDatabaseManager.shared.applyDeltaUpdates(allUpdates)
                print("✅ Sync: Applied \(appliedCount) updates")

                // Update local version to match server
                LocalDatabaseManager.shared.updateDatabaseVersion(serverVersion)

                // Check if eviction is needed after adding data
                LocalDatabaseManager.shared.checkAndEvictIfNeeded()
            }

            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastSyncKey)
            UserDefaults.standard.set(serverVersion, forKey: lastVersionKey)

            print("✅ Sync: Complete")
            return !allUpdates.isEmpty

        } catch {
            print("❌ Sync: Failed - \(error.localizedDescription)")
            return false
        }
    }

    /// Check current server database version
    private func checkServerVersion() async throws -> String {
        guard let url = URL(string: "\(functionsBaseURL)/getCurrentDatabaseVersion") else {
            throw SyncError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SyncError.serverError
        }

        struct VersionResponse: Decodable {
            let version: String
        }

        let versionResponse = try JSONDecoder().decode(VersionResponse.self, from: data)
        return versionResponse.version
    }

    /// Fetch delta updates from server
    private func fetchDelta(sinceVersion: String) async throws -> DeltaResult {
        guard let url = URL(string: "\(functionsBaseURL)/getFoodDatabaseDelta") else {
            throw SyncError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["since": sinceVersion])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SyncError.serverError
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SyncError.parseError
        }

        return DeltaResult(
            updates: json["updates"] as? [[String: Any]] ?? [],
            currentVersion: json["currentVersion"] as? String ?? sinceVersion,
            hasMore: json["hasMore"] as? Bool ?? false
        )
    }

    struct DeltaResult {
        let updates: [[String: Any]]
        let currentVersion: String
        let hasMore: Bool
    }

    enum SyncError: Error {
        case invalidURL
        case serverError
        case parseError
    }
}

// MARK: - Network Monitor

import Network

/// Notification posted when network reconnects (was offline, now online)
extension Notification.Name {
    static let networkReconnected = Notification.Name("networkReconnected")
    /// UX TRUTH: Posted on any network status change with userInfo["isConnected": Bool]
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
    /// DATA CONSISTENCY: Posted when local database updates from delta sync (invalidate caches)
    static let localDatabaseUpdated = Notification.Name("localDatabaseUpdated")
}

/// Network reachability monitor using NWPathMonitor
/// Posts .networkReconnected notification when connection is restored
/// Thread-safe: isConnected can be accessed from any thread/actor context
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    /// Thread-safe storage for connection state (accessed via lock)
    private let connectionLock = NSLock()
    private var _isConnected: Bool = true
    private var _connectionType: ConnectionType = .unknown

    /// Thread-safe access to connection status - can be called from any context
    var isConnected: Bool {
        connectionLock.lock()
        defer { connectionLock.unlock() }
        return _isConnected
    }

    /// Thread-safe access to connection type
    var connectionType: ConnectionType {
        connectionLock.lock()
        defer { connectionLock.unlock() }
        return _connectionType
    }

    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.nutrasafe.networkmonitor")

    /// Track if we were previously disconnected (to detect reconnection)
    private var wasDisconnected = false

    private init() {
        startMonitoring()
    }

    deinit {
        monitor.cancel()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            // Thread-safe read of previous state
            self.connectionLock.lock()
            let wasConnected = self._isConnected
            self.connectionLock.unlock()

            let isNowConnected = path.status == .satisfied
            let newType = self.getConnectionType(path)

            // Thread-safe write of new state
            self.connectionLock.lock()
            self._isConnected = isNowConnected
            self._connectionType = newType
            self.connectionLock.unlock()

            // Notify SwiftUI observers on main thread (for ObservableObject conformance)
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }

            // Detect reconnection: was offline, now online
            if !wasConnected && isNowConnected {
                print("🌐 Network: Reconnected (\(newType))")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .networkReconnected, object: nil)
                    // UX TRUTH: Also post generic status change for UI updates
                    NotificationCenter.default.post(
                        name: .networkStatusChanged,
                        object: nil,
                        userInfo: ["isConnected": true, "connectionType": "\(newType)"]
                    )
                }
            } else if wasConnected && !isNowConnected {
                print("📴 Network: Disconnected")
                DispatchQueue.main.async {
                    // UX TRUTH: Notify UI of offline status
                    NotificationCenter.default.post(
                        name: .networkStatusChanged,
                        object: nil,
                        userInfo: ["isConnected": false]
                    )
                }
            }
        }

        monitor.start(queue: monitorQueue)
    }

    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) { return .wifi }
        if path.usesInterfaceType(.cellular) { return .cellular }
        if path.usesInterfaceType(.wiredEthernet) { return .ethernet }
        return .unknown
    }

    /// Manual connectivity check (legacy support)
    func checkConnectivity() {
        // NWPathMonitor handles this automatically now
        // This method is kept for compatibility but doesn't need to do anything
    }
}

// MARK: - Local Food Image Manager

/// Manages local food images bundled with the app
/// Provides fast offline access to food product images
class LocalFoodImageManager {
    static let shared = LocalFoodImageManager()

    /// Cached folder URL - computed once and stored
    private var _imagesFolderURL: URL?
    private var _folderURLLoaded = false

    /// Path to bundled FoodImages folder
    /// Note: For folder references, we need to use resourceURL, not url(forResource:)
    private var imagesFolderURL: URL? {
        // Return cached value if already computed AND found
        if _folderURLLoaded && _imagesFolderURL != nil {
            return _imagesFolderURL
        }

        // If we haven't loaded, or if previous attempt failed, try (again)
        print("🔍 LocalImages: Searching for FoodImages folder...")
        print("   Bundle path: \(Bundle.main.bundlePath)")

        // 1. Direct path from bundle resource URL (works for folder references)
        if let resourceURL = Bundle.main.resourceURL {
            print("   Resource URL: \(resourceURL.path)")
            let folderURL = resourceURL.appendingPathComponent("FoodImages")
            if FileManager.default.fileExists(atPath: folderURL.path) {
                print("   ✅ Found via resourceURL: \(folderURL.path)")
                _imagesFolderURL = folderURL
                _folderURLLoaded = true
                return folderURL
            } else {
                print("   ❌ Not found at resourceURL path")
            }
        }

        // 2. Try url(forResource:) as fallback (works for some bundle configurations)
        if let url = Bundle.main.url(forResource: "FoodImages", withExtension: nil) {
            print("   ✅ Found via url(forResource:): \(url.path)")
            _imagesFolderURL = url
            _folderURLLoaded = true
            return url
        } else {
            print("   ❌ Not found via url(forResource:)")
        }

        // 3. Check if it's at the bundle path directly
        let bundlePath = Bundle.main.bundlePath
        let directPath = (bundlePath as NSString).appendingPathComponent("FoodImages")
        if FileManager.default.fileExists(atPath: directPath) {
            print("   ✅ Found at direct bundle path: \(directPath)")
            let url = URL(fileURLWithPath: directPath)
            _imagesFolderURL = url
            _folderURLLoaded = true
            return url
        } else {
            print("   ❌ Not found at direct bundle path")
        }

        // 4. List all items in resource URL to help debug
        if let resourceURL = Bundle.main.resourceURL {
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: resourceURL.path) {
                let relevant = contents.filter { $0.lowercased().contains("food") || $0.lowercased().contains("image") }
                print("   📂 Items containing 'food' or 'image': \(relevant)")
                print("   📂 Total items in bundle: \(contents.count)")
            }
        }

        print("   ⚠️ FoodImages folder NOT FOUND in bundle")
        _folderURLLoaded = true  // Mark as loaded even if failed, to avoid repeated logging
        return nil
    }

    /// Image mapping from food IDs to filenames
    private var imageMapping: [String: String] = [:]
    private var isLoaded = false

    private init() {
        loadImageMapping()
    }

    /// Load the image mapping JSON file
    private func loadImageMapping() {
        guard let folderURL = imagesFolderURL else {
            print("⚠️ LocalImages: Cannot load mapping - folder not found")
            return
        }

        print("📂 LocalImages: Loading mapping from \(folderURL.path)")
        let mappingURL = folderURL.appendingPathComponent("image_mapping.json")

        // Check if mapping file exists
        if !FileManager.default.fileExists(atPath: mappingURL.path) {
            print("⚠️ LocalImages: image_mapping.json not found at \(mappingURL.path)")
            // List folder contents to debug
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: folderURL.path) {
                print("   📂 Folder contains \(contents.count) items")
                let jsonFiles = contents.filter { $0.hasSuffix(".json") }
                print("   📂 JSON files: \(jsonFiles)")
            }
            return
        }

        guard let data = try? Data(contentsOf: mappingURL) else {
            print("⚠️ LocalImages: Failed to read image_mapping.json data")
            return
        }

        guard let mapping = try? JSONDecoder().decode([String: String].self, from: data) else {
            print("⚠️ LocalImages: Failed to decode image_mapping.json")
            return
        }

        imageMapping = mapping
        isLoaded = true
        print("✅ LocalImages: Loaded \(imageMapping.count) image mappings")

        // Verify a sample image exists
        if let firstEntry = mapping.first {
            let sampleImageURL = folderURL.appendingPathComponent(firstEntry.value)
            let exists = FileManager.default.fileExists(atPath: sampleImageURL.path)
            print("   🔍 Sample image '\(firstEntry.value)' exists: \(exists)")
        }
    }

    /// Check if we have a local image for a food ID
    func hasLocalImage(for foodId: String) -> Bool {
        let has = imageMapping[foodId] != nil
        // Debug: uncomment to trace lookups
        // print("🔍 LocalImages: hasLocalImage(\(foodId)) = \(has)")
        return has
    }

    /// Get the local file URL for a food's image
    /// - Parameter foodId: The food ID (e.g., "consumer_foods:consumer_0202")
    /// - Returns: Local file URL if available, nil otherwise
    func localImageURL(for foodId: String) -> URL? {
        guard let filename = imageMapping[foodId] else {
            // Only log for first few failures to avoid spam
            if !isLoaded {
                print("⚠️ LocalImages: Mapping not loaded, cannot find image for \(foodId)")
            }
            return nil
        }

        guard let folderURL = imagesFolderURL else {
            print("⚠️ LocalImages: Folder URL is nil, cannot find image for \(foodId)")
            return nil
        }

        let imageURL = folderURL.appendingPathComponent(filename)

        // Verify file actually exists (debug check - can remove for performance later)
        if !FileManager.default.fileExists(atPath: imageURL.path) {
            print("⚠️ LocalImages: Image file not found at \(imageURL.path)")
            return nil
        }

        return imageURL
    }

    /// Get the image URL to use - prefers local, falls back to remote
    /// - Parameters:
    ///   - foodId: The food ID
    ///   - remoteURL: The remote URL from the database
    /// - Returns: Local file URL if available, otherwise the remote URL
    func imageURL(for foodId: String, remoteURL: String?) -> URL? {
        // Prefer local image if available
        if let localURL = localImageURL(for: foodId) {
            return localURL
        }

        // Fall back to remote URL
        if let remote = remoteURL, !remote.isEmpty {
            return URL(string: remote)
        }

        return nil
    }

    /// Number of local images available
    var localImageCount: Int {
        return imageMapping.count
    }

    /// Debug: Print current state of image manager
    func debugPrintState() {
        print("=== LocalFoodImageManager Debug State ===")
        print("   isLoaded: \(isLoaded)")
        print("   imageMapping count: \(imageMapping.count)")
        print("   imagesFolderURL: \(imagesFolderURL?.path ?? "nil")")
        if let folderURL = imagesFolderURL {
            let mappingExists = FileManager.default.fileExists(atPath: folderURL.appendingPathComponent("image_mapping.json").path)
            print("   image_mapping.json exists: \(mappingExists)")
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: folderURL.path) {
                let jpgCount = contents.filter { $0.hasSuffix(".jpg") }.count
                print("   JPG files in folder: \(jpgCount)")
            }
        }
        print("=========================================")
    }
}
