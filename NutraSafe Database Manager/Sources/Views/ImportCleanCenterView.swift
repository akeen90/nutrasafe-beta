//
//  ImportCleanCenterView.swift
//  NutraSafe Database Manager
//
//  Full-screen Import & Clean Center for importing, cleaning, and reviewing food data
//  Handles MASSIVE files (100k+ rows) using streaming + SQLite staging database
//  Data persists across sessions - come back anytime to continue cleaning
//

import SwiftUI
import UniformTypeIdentifiers
import SQLite3

// MARK: - SQLite Staging Database Manager

class StagingDatabase: @unchecked Sendable {
    static let shared = StagingDatabase()

    private var db: OpaquePointer?
    private let dbPath: String
    private let queue = DispatchQueue(label: "com.nutrasafe.stagingdb", qos: .userInitiated)
    private var isInitialized = false

    init() {
        // Just set up the path - don't open DB yet
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("NutraSafeDatabaseManager", isDirectory: true)
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        dbPath = appFolder.appendingPathComponent("import_staging.sqlite").path
    }

    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }

    /// Ensure database is open - call this before any DB operation
    private func ensureOpen() {
        if db != nil { return }

        // Open with FULLMUTEX for thread-safe access
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        if sqlite3_open_v2(dbPath, &db, flags, nil) != SQLITE_OK {
            print("[StagingDB] Error opening database at \(dbPath)")
            return
        }

        // Performance optimizations - balanced for memory efficiency
        sqlite3_exec(db, "PRAGMA journal_mode=WAL", nil, nil, nil)
        sqlite3_exec(db, "PRAGMA synchronous=NORMAL", nil, nil, nil)
        sqlite3_exec(db, "PRAGMA cache_size=-8000", nil, nil, nil)  // 8MB cache (memory efficient)
        sqlite3_exec(db, "PRAGMA temp_store=MEMORY", nil, nil, nil)
        sqlite3_exec(db, "PRAGMA mmap_size=0", nil, nil, nil)  // Disable mmap - reduces RAM

        // Create table if needed (fast - just checks if exists)
        let sql = """
        CREATE TABLE IF NOT EXISTS staging_foods (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL DEFAULT '',
            brand TEXT DEFAULT '',
            barcode TEXT DEFAULT '',
            calories REAL DEFAULT 0,
            protein REAL DEFAULT 0,
            carbs REAL DEFAULT 0,
            fat REAL DEFAULT 0,
            saturated_fat REAL DEFAULT 0,
            fiber REAL DEFAULT 0,
            sugar REAL DEFAULT 0,
            sodium REAL DEFAULT 0,
            serving_description TEXT DEFAULT '',
            serving_size_g REAL DEFAULT 0,
            is_per_unit INTEGER DEFAULT 0,
            ingredients TEXT DEFAULT '',
            cleaning_status TEXT DEFAULT 'pending',
            queue TEXT DEFAULT 'staging',
            imported_at TEXT DEFAULT CURRENT_TIMESTAMP,
            extra_data TEXT DEFAULT '{}'
        )
        """
        sqlite3_exec(db, sql, nil, nil, nil)

        // Essential indexes only - these are fast (IF NOT EXISTS)
        sqlite3_exec(db, "CREATE INDEX IF NOT EXISTS idx_queue ON staging_foods(queue)", nil, nil, nil)
        sqlite3_exec(db, "CREATE INDEX IF NOT EXISTS idx_queue_id ON staging_foods(queue, id DESC)", nil, nil, nil)

        print("[StagingDB] Database opened: \(dbPath)")
    }

    /// Run slow index creation in background (call once after app starts)
    func createOptionalIndexesAsync() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            self.ensureOpen()

            // These can be slow on large tables but IF NOT EXISTS makes them fast if already created
            sqlite3_exec(self.db, "CREATE INDEX IF NOT EXISTS idx_status ON staging_foods(cleaning_status)", nil, nil, nil)
            sqlite3_exec(self.db, "CREATE INDEX IF NOT EXISTS idx_barcode ON staging_foods(barcode)", nil, nil, nil)
            sqlite3_exec(self.db, "CREATE INDEX IF NOT EXISTS idx_name_brand ON staging_foods(name, brand)", nil, nil, nil)
            sqlite3_exec(self.db, "CREATE INDEX IF NOT EXISTS idx_queue_status ON staging_foods(queue, cleaning_status)", nil, nil, nil)

            // Migrations
            sqlite3_exec(self.db, "ALTER TABLE staging_foods ADD COLUMN queue TEXT DEFAULT 'staging'", nil, nil, nil)
            sqlite3_exec(self.db, "ALTER TABLE staging_foods ADD COLUMN extra_data TEXT DEFAULT '{}'", nil, nil, nil)

            print("[StagingDB] Optional indexes created")
        }
    }

    // Helper to safely extract strings from SQLite
    private func getString(_ stmt: OpaquePointer?, _ col: Int32, default defaultValue: String = "") -> String {
        if let ptr = sqlite3_column_text(stmt, col) {
            return String(cString: ptr)
        }
        return defaultValue
    }

    // Helper to parse extra_data JSON into dictionary
    private func parseExtraData(_ jsonString: String) -> [String: String] {
        guard !jsonString.isEmpty,
              let data = jsonString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        // Convert all values to strings
        var result: [String: String] = [:]
        for (key, value) in dict {
            if let str = value as? String {
                result[key] = str
            } else {
                result[key] = "\(value)"
            }
        }
        return result
    }

    func clearAll() {
        ensureOpen()
        sqlite3_exec(db, "DELETE FROM staging_foods", nil, nil, nil)
        sqlite3_exec(db, "VACUUM", nil, nil, nil)
    }

    // SQLITE_TRANSIENT tells SQLite to make its own copy of the string immediately
    private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    func insertRow(name: String, brand: String, barcode: String,
                   calories: Double, protein: Double, carbs: Double, fat: Double,
                   saturatedFat: Double, fiber: Double, sugar: Double, sodium: Double,
                   servingDescription: String, servingSizeG: Double, isPerUnit: Bool,
                   ingredients: String, extraData: [String: String] = [:]) {
        ensureOpen()
        let sql = """
        INSERT INTO staging_foods (name, brand, barcode, calories, protein, carbs, fat,
            saturated_fat, fiber, sugar, sodium, serving_description, serving_size_g, is_per_unit, ingredients, extra_data)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }

        // Use NSString for reliable C string conversion
        let nsName = name as NSString
        let nsBrand = brand as NSString
        let nsBarcode = barcode as NSString
        let nsServingDesc = servingDescription as NSString
        let nsIngredients = ingredients as NSString

        // Serialize extra data to JSON
        let extraJson: String
        if let jsonData = try? JSONSerialization.data(withJSONObject: extraData, options: []),
           let jsonStr = String(data: jsonData, encoding: .utf8) {
            extraJson = jsonStr
        } else {
            extraJson = "{}"
        }
        let nsExtraJson = extraJson as NSString

        sqlite3_bind_text(stmt, 1, nsName.utf8String, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, nsBrand.utf8String, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 3, nsBarcode.utf8String, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(stmt, 4, calories)
        sqlite3_bind_double(stmt, 5, protein)
        sqlite3_bind_double(stmt, 6, carbs)
        sqlite3_bind_double(stmt, 7, fat)
        sqlite3_bind_double(stmt, 8, saturatedFat)
        sqlite3_bind_double(stmt, 9, fiber)
        sqlite3_bind_double(stmt, 10, sugar)
        sqlite3_bind_double(stmt, 11, sodium)
        sqlite3_bind_text(stmt, 12, nsServingDesc.utf8String, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(stmt, 13, servingSizeG)
        sqlite3_bind_int(stmt, 14, isPerUnit ? 1 : 0)
        sqlite3_bind_text(stmt, 15, nsIngredients.utf8String, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 16, nsExtraJson.utf8String, -1, SQLITE_TRANSIENT)

        sqlite3_step(stmt)
        sqlite3_finalize(stmt)
    }

    func beginTransaction() {
        ensureOpen()
        sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil)
    }

    func commitTransaction() {
        ensureOpen()
        sqlite3_exec(db, "COMMIT", nil, nil, nil)
    }

    func getTotalCount() -> Int {
        ensureOpen()
        let sql = "SELECT COUNT(*) FROM staging_foods"
        var stmt: OpaquePointer?
        var count = 0
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                count = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        return count
    }

    func getRows(offset: Int, limit: Int) -> [StagingFoodRow] {
        ensureOpen()
        let sql = """
        SELECT id, name, brand, barcode, calories, protein, carbs, fat,
               saturated_fat, fiber, sugar, sodium, serving_description,
               serving_size_g, is_per_unit, ingredients, cleaning_status, queue, extra_data
        FROM staging_foods
        ORDER BY id DESC LIMIT ? OFFSET ?
        """
        var stmt: OpaquePointer?
        var rows: [StagingFoodRow] = []

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(limit))
            sqlite3_bind_int(stmt, 2, Int32(offset))

            while sqlite3_step(stmt) == SQLITE_ROW {
                let row = StagingFoodRow(
                    id: Int(sqlite3_column_int(stmt, 0)),
                    name: getString(stmt, 1),
                    brand: getString(stmt, 2),
                    barcode: getString(stmt, 3),
                    calories: sqlite3_column_double(stmt, 4),
                    protein: sqlite3_column_double(stmt, 5),
                    carbs: sqlite3_column_double(stmt, 6),
                    fat: sqlite3_column_double(stmt, 7),
                    saturatedFat: sqlite3_column_double(stmt, 8),
                    fiber: sqlite3_column_double(stmt, 9),
                    sugar: sqlite3_column_double(stmt, 10),
                    sodium: sqlite3_column_double(stmt, 11),
                    servingDescription: getString(stmt, 12),
                    servingSizeG: sqlite3_column_double(stmt, 13),
                    isPerUnit: sqlite3_column_int(stmt, 14) == 1,
                    ingredients: getString(stmt, 15),
                    cleaningStatus: getString(stmt, 16, default: "pending"),
                    queue: getString(stmt, 17, default: "staging"),
                    extraData: parseExtraData(getString(stmt, 18, default: "{}"))
                )
                rows.append(row)
            }
        }
        sqlite3_finalize(stmt)
        return rows
    }

    func getRowsSorted(offset: Int, limit: Int, sortColumn: SortColumn, ascending: Bool,
                       queue: String, barcodeFilter: BarcodeFilter, dataFilter: DataFilterPreset) -> [StagingFoodRow] {
        ensureOpen()
        let order = ascending ? "ASC" : "DESC"
        let col = sortColumn.rawValue

        // Build WHERE clause
        var conditions: [String] = []

        // Queue filter - use simple equality for index usage
        // Migration ensures queue is never NULL or empty
        conditions.append("queue = '\(queue)'")

        // Barcode filter - comprehensive UK detection including supermarket own-brands
        switch barcodeFilter {
        case .all: break
        case .ukOnly:
            // UK GS1 prefix: 50, plus supermarket own-brand prefixes
            conditions.append("""
                (barcode LIKE '50%' OR barcode LIKE '00%' OR barcode LIKE '01%' OR barcode LIKE '02%' OR
                 barcode LIKE '20%' OR barcode LIKE '21%' OR barcode LIKE '22%' OR barcode LIKE '23%' OR
                 barcode LIKE '24%' OR barcode LIKE '25%' OR barcode LIKE '26%' OR barcode LIKE '27%' OR
                 barcode LIKE '28%' OR barcode LIKE '29%' OR
                 barcode LIKE '4088600%' OR barcode LIKE '4088660%' OR barcode LIKE '4056489%')
                """)
        case .nonUK:
            conditions.append("""
                barcode != '' AND barcode NOT LIKE '50%' AND barcode NOT LIKE '00%' AND barcode NOT LIKE '01%' AND
                barcode NOT LIKE '02%' AND barcode NOT LIKE '20%' AND barcode NOT LIKE '21%' AND
                barcode NOT LIKE '22%' AND barcode NOT LIKE '23%' AND barcode NOT LIKE '24%' AND
                barcode NOT LIKE '25%' AND barcode NOT LIKE '26%' AND barcode NOT LIKE '27%' AND
                barcode NOT LIKE '28%' AND barcode NOT LIKE '29%' AND
                barcode NOT LIKE '4088600%' AND barcode NOT LIKE '4088660%' AND barcode NOT LIKE '4056489%'
                """)
        case .noBarcode:
            conditions.append("(barcode IS NULL OR barcode = '')")
        }

        // Data filter preset
        if dataFilter != .all {
            conditions.append(dataFilter.sqlCondition)
        }

        let whereClause = conditions.isEmpty ? "" : "WHERE " + conditions.joined(separator: " AND ")

        let sql = """
        SELECT id, name, brand, barcode, calories, protein, carbs, fat,
               saturated_fat, fiber, sugar, sodium, serving_description,
               serving_size_g, is_per_unit, ingredients, cleaning_status, queue, extra_data
        FROM staging_foods
        \(whereClause)
        ORDER BY \(col) \(order) LIMIT ? OFFSET ?
        """

        var stmt: OpaquePointer?
        var rows: [StagingFoodRow] = []

        let result = sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        if result == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(limit))
            sqlite3_bind_int(stmt, 2, Int32(offset))

            while sqlite3_step(stmt) == SQLITE_ROW {
                let row = StagingFoodRow(
                    id: Int(sqlite3_column_int(stmt, 0)),
                    name: getString(stmt, 1),
                    brand: getString(stmt, 2),
                    barcode: getString(stmt, 3),
                    calories: sqlite3_column_double(stmt, 4),
                    protein: sqlite3_column_double(stmt, 5),
                    carbs: sqlite3_column_double(stmt, 6),
                    fat: sqlite3_column_double(stmt, 7),
                    saturatedFat: sqlite3_column_double(stmt, 8),
                    fiber: sqlite3_column_double(stmt, 9),
                    sugar: sqlite3_column_double(stmt, 10),
                    sodium: sqlite3_column_double(stmt, 11),
                    servingDescription: getString(stmt, 12),
                    servingSizeG: sqlite3_column_double(stmt, 13),
                    isPerUnit: sqlite3_column_int(stmt, 14) == 1,
                    ingredients: getString(stmt, 15),
                    cleaningStatus: getString(stmt, 16, default: "pending"),
                    queue: getString(stmt, 17, default: "staging"),
                    extraData: parseExtraData(getString(stmt, 18, default: "{}"))
                )
                rows.append(row)
            }
        } else {
            print("[StagingDB] ERROR in getRowsSorted: \(String(cString: sqlite3_errmsg(db)))")
            print("[StagingDB] SQL: \(sql.prefix(200))...")
        }
        sqlite3_finalize(stmt)
        return rows
    }

    func getFilteredCount(queue: String, barcodeFilter: BarcodeFilter, dataFilter: DataFilterPreset) -> Int {
        ensureOpen()
        var conditions: [String] = []

        // Queue filter - simple equality (migration ensures queue is never NULL/empty)
        conditions.append("queue = '\(queue)'")

        // Barcode filter - MUST match getRowsSorted exactly
        switch barcodeFilter {
        case .all: break
        case .ukOnly:
            // UK GS1 prefix: 50, plus supermarket own-brand prefixes
            conditions.append("""
                (barcode LIKE '50%' OR barcode LIKE '00%' OR barcode LIKE '01%' OR barcode LIKE '02%' OR
                 barcode LIKE '20%' OR barcode LIKE '21%' OR barcode LIKE '22%' OR barcode LIKE '23%' OR
                 barcode LIKE '24%' OR barcode LIKE '25%' OR barcode LIKE '26%' OR barcode LIKE '27%' OR
                 barcode LIKE '28%' OR barcode LIKE '29%' OR
                 barcode LIKE '4088600%' OR barcode LIKE '4088660%' OR barcode LIKE '4056489%')
                """)
        case .nonUK:
            conditions.append("""
                barcode != '' AND barcode NOT LIKE '50%' AND barcode NOT LIKE '00%' AND barcode NOT LIKE '01%' AND
                barcode NOT LIKE '02%' AND barcode NOT LIKE '20%' AND barcode NOT LIKE '21%' AND
                barcode NOT LIKE '22%' AND barcode NOT LIKE '23%' AND barcode NOT LIKE '24%' AND
                barcode NOT LIKE '25%' AND barcode NOT LIKE '26%' AND barcode NOT LIKE '27%' AND
                barcode NOT LIKE '28%' AND barcode NOT LIKE '29%' AND
                barcode NOT LIKE '4088600%' AND barcode NOT LIKE '4088660%' AND barcode NOT LIKE '4056489%'
                """)
        case .noBarcode:
            conditions.append("(barcode IS NULL OR barcode = '')")
        }

        // Data filter preset - MUST match getRowsSorted exactly
        if dataFilter != .all {
            conditions.append(dataFilter.sqlCondition)
        }

        let whereClause = conditions.isEmpty ? "" : "WHERE " + conditions.joined(separator: " AND ")
        let sql = "SELECT COUNT(*) FROM staging_foods \(whereClause)"

        var stmt: OpaquePointer?
        var count = 0
        let result = sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        if result == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                count = Int(sqlite3_column_int(stmt, 0))
            }
        } else {
            print("[StagingDB] ERROR in getFilteredCount: \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_finalize(stmt)
        return count
    }

    func updateRow(id: Int, name: String, brand: String, barcode: String,
                   calories: Double, protein: Double, carbs: Double, fat: Double,
                   saturatedFat: Double, fiber: Double, sugar: Double, sodium: Double,
                   servingDescription: String, servingSizeG: Double, isPerUnit: Bool,
                   ingredients: String, cleaningStatus: String) {
        ensureOpen()
        let sql = """
        UPDATE staging_foods SET name=?, brand=?, barcode=?, calories=?, protein=?, carbs=?, fat=?,
            saturated_fat=?, fiber=?, sugar=?, sodium=?, serving_description=?, serving_size_g=?,
            is_per_unit=?, ingredients=?, cleaning_status=? WHERE id=?
        """
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            // Use NSString for reliable UTF8 string binding
            let nsName = name as NSString
            let nsBrand = brand as NSString
            let nsBarcode = barcode as NSString
            let nsServing = servingDescription as NSString
            let nsIngredients = ingredients as NSString
            let nsStatus = cleaningStatus as NSString

            sqlite3_bind_text(stmt, 1, nsName.utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 2, nsBrand.utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 3, nsBarcode.utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_double(stmt, 4, calories)
            sqlite3_bind_double(stmt, 5, protein)
            sqlite3_bind_double(stmt, 6, carbs)
            sqlite3_bind_double(stmt, 7, fat)
            sqlite3_bind_double(stmt, 8, saturatedFat)
            sqlite3_bind_double(stmt, 9, fiber)
            sqlite3_bind_double(stmt, 10, sugar)
            sqlite3_bind_double(stmt, 11, sodium)
            sqlite3_bind_text(stmt, 12, nsServing.utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_double(stmt, 13, servingSizeG)
            sqlite3_bind_int(stmt, 14, isPerUnit ? 1 : 0)
            sqlite3_bind_text(stmt, 15, nsIngredients.utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 16, nsStatus.utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(stmt, 17, Int32(id))
            if sqlite3_step(stmt) != SQLITE_DONE {
                print("Error updating row: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
        sqlite3_finalize(stmt)
    }

    func deleteRow(id: Int) {
        ensureOpen()
        let sql = "DELETE FROM staging_foods WHERE id = ?"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(id))
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    func deleteRows(ids: [Int]) {
        guard !ids.isEmpty else { return }
        beginTransaction()
        for id in ids {
            deleteRow(id: id)
        }
        commitTransaction()
    }

    // MARK: - Bulk Delete Operations (fast SQL-based)

    /// Delete all non-UK items based on origin/countries field - returns count deleted
    /// Checks extra_data for countries, countries_tags, countries_en, origins fields
    @discardableResult
    func deleteAllNonUK() -> Int {
        ensureOpen()
        let countBefore = getTotalCount()
        // Delete items where extra_data doesn't contain UK-related origin
        // OpenFoodFacts uses: countries, countries_tags (en:united-kingdom), countries_en
        let sql = """
        DELETE FROM staging_foods WHERE
        extra_data NOT LIKE '%United Kingdom%' AND
        extra_data NOT LIKE '%united-kingdom%' AND
        extra_data NOT LIKE '%en:uk%' AND
        extra_data NOT LIKE '%"UK"%' AND
        extra_data NOT LIKE '%Great Britain%' AND
        extra_data NOT LIKE '%great-britain%' AND
        extra_data NOT LIKE '%England%' AND
        extra_data NOT LIKE '%Scotland%' AND
        extra_data NOT LIKE '%Wales%' AND
        extra_data NOT LIKE '%Ireland%'
        """
        sqlite3_exec(db, sql, nil, nil, nil)
        return countBefore - getTotalCount()
    }

    /// Delete all non-UK items based on barcode prefix - returns count deleted
    /// UK barcodes start with 50, plus store-brand prefixes (20-29), and Lidl/Aldi German prefixes
    @discardableResult
    func deleteAllNonUKBarcodes() -> Int {
        ensureOpen()
        let countBefore = getTotalCount()
        let sql = """
        DELETE FROM staging_foods WHERE
        barcode != '' AND
        barcode NOT LIKE '50%' AND
        barcode NOT LIKE '00%' AND barcode NOT LIKE '01%' AND barcode NOT LIKE '02%' AND
        barcode NOT LIKE '20%' AND barcode NOT LIKE '21%' AND barcode NOT LIKE '22%' AND
        barcode NOT LIKE '23%' AND barcode NOT LIKE '24%' AND barcode NOT LIKE '25%' AND
        barcode NOT LIKE '26%' AND barcode NOT LIKE '27%' AND barcode NOT LIKE '28%' AND
        barcode NOT LIKE '29%' AND
        barcode NOT LIKE '4088600%' AND barcode NOT LIKE '4088660%' AND barcode NOT LIKE '4056489%'
        """
        sqlite3_exec(db, sql, nil, nil, nil)
        return countBefore - getTotalCount()
    }

    /// Delete all items with no ingredients - returns count deleted
    @discardableResult
    func deleteAllNoIngredients() -> Int {
        ensureOpen()
        let countBefore = getTotalCount()
        let sql = "DELETE FROM staging_foods WHERE ingredients IS NULL OR ingredients = ''"
        sqlite3_exec(db, sql, nil, nil, nil)
        return countBefore - getTotalCount()
    }

    /// Delete all items with suspicious macros (has calories but ALL macros are 0) - returns count deleted
    /// Note: Items with 0 calories and 0 macros are valid (water, etc.)
    @discardableResult
    func deleteAllIncompleteMacros() -> Int {
        ensureOpen()
        let countBefore = getTotalCount()
        // Only delete if calories > 10 but ALL macros are 0 (nutritionally impossible)
        let sql = """
        DELETE FROM staging_foods WHERE
        calories > 10 AND
        (protein IS NULL OR protein = 0) AND
        (carbs IS NULL OR carbs = 0) AND
        (fat IS NULL OR fat = 0)
        """
        sqlite3_exec(db, sql, nil, nil, nil)
        return countBefore - getTotalCount()
    }

    /// Delete all items with suspicious zero calories (0 cals but has macros) - returns count deleted
    /// Note: Items with 0 calories AND 0 macros are valid (water, diet drinks, etc.)
    @discardableResult
    func deleteAllZeroCalories() -> Int {
        ensureOpen()
        let countBefore = getTotalCount()
        // Only delete if calories=0 but has macros (contradictory data)
        let sql = """
        DELETE FROM staging_foods WHERE
        (calories IS NULL OR calories = 0) AND
        (protein > 0 OR carbs > 0 OR fat > 0)
        """
        sqlite3_exec(db, sql, nil, nil, nil)
        return countBefore - getTotalCount()
    }

    // MARK: - Count Functions for Bulk Delete Preview

    /// Count items where origin doesn't contain UK
    func countNonUK() -> Int {
        ensureOpen()
        let sql = """
        SELECT COUNT(*) FROM staging_foods WHERE
        extra_data NOT LIKE '%United Kingdom%' AND
        extra_data NOT LIKE '%united-kingdom%' AND
        extra_data NOT LIKE '%en:uk%' AND
        extra_data NOT LIKE '%"UK"%' AND
        extra_data NOT LIKE '%Great Britain%' AND
        extra_data NOT LIKE '%great-britain%' AND
        extra_data NOT LIKE '%England%' AND
        extra_data NOT LIKE '%Scotland%' AND
        extra_data NOT LIKE '%Wales%' AND
        extra_data NOT LIKE '%Ireland%'
        """
        return countQuery(sql)
    }

    /// Count items with non-UK barcode prefixes
    func countNonUKBarcodes() -> Int {
        ensureOpen()
        let sql = """
        SELECT COUNT(*) FROM staging_foods WHERE
        barcode != '' AND
        barcode NOT LIKE '50%' AND
        barcode NOT LIKE '00%' AND barcode NOT LIKE '01%' AND barcode NOT LIKE '02%' AND
        barcode NOT LIKE '20%' AND barcode NOT LIKE '21%' AND barcode NOT LIKE '22%' AND
        barcode NOT LIKE '23%' AND barcode NOT LIKE '24%' AND barcode NOT LIKE '25%' AND
        barcode NOT LIKE '26%' AND barcode NOT LIKE '27%' AND barcode NOT LIKE '28%' AND
        barcode NOT LIKE '29%' AND
        barcode NOT LIKE '4088600%' AND barcode NOT LIKE '4088660%' AND barcode NOT LIKE '4056489%'
        """
        return countQuery(sql)
    }

    func countNoIngredients() -> Int {
        ensureOpen()
        return countQuery("SELECT COUNT(*) FROM staging_foods WHERE ingredients IS NULL OR ingredients = ''")
    }

    func countIncompleteMacros() -> Int {
        ensureOpen()
        // Only count items with calories > 10 but ALL macros are 0 (nutritionally impossible)
        let sql = """
        SELECT COUNT(*) FROM staging_foods WHERE
        calories > 10 AND
        (protein IS NULL OR protein = 0) AND
        (carbs IS NULL OR carbs = 0) AND
        (fat IS NULL OR fat = 0)
        """
        return countQuery(sql)
    }

    func countZeroCalories() -> Int {
        ensureOpen()
        // Only count items with 0 calories but has macros (contradictory data)
        let sql = """
        SELECT COUNT(*) FROM staging_foods WHERE
        (calories IS NULL OR calories = 0) AND
        (protein > 0 OR carbs > 0 OR fat > 0)
        """
        return countQuery(sql)
    }

    /// Delete items with junk/placeholder ingredients (none, n/a, nine, null, etc.)
    @discardableResult
    func deleteAllJunkIngredients() -> Int {
        ensureOpen()
        let countBefore = getTotalCount()
        let sql = """
        DELETE FROM staging_foods WHERE
        LOWER(ingredients) IN ('none', 'n/a', 'na', 'nine', 'null', 'undefined', 'unknown',
                               'not available', 'no ingredients', 'see package', 'voir emballage',
                               '-', '--', '---', '.', '..', '...', 'tbc', 'tbd', 'test') OR
        LOWER(ingredients) LIKE 'ingredients:%' OR
        LOWER(ingredients) LIKE 'contains:%' OR
        (LENGTH(ingredients) > 0 AND LENGTH(ingredients) < 3)
        """
        sqlite3_exec(db, sql, nil, nil, nil)
        return countBefore - getTotalCount()
    }

    func countJunkIngredients() -> Int {
        ensureOpen()
        let sql = """
        SELECT COUNT(*) FROM staging_foods WHERE
        LOWER(ingredients) IN ('none', 'n/a', 'na', 'nine', 'null', 'undefined', 'unknown',
                               'not available', 'no ingredients', 'see package', 'voir emballage',
                               '-', '--', '---', '.', '..', '...', 'tbc', 'tbd', 'test') OR
        LOWER(ingredients) LIKE 'ingredients:%' OR
        LOWER(ingredients) LIKE 'contains:%' OR
        (LENGTH(ingredients) > 0 AND LENGTH(ingredients) < 3)
        """
        return countQuery(sql)
    }

    /// Delete duplicate barcodes - keeps the first entry, removes duplicates
    @discardableResult
    func deduplicateBarcodes() -> Int {
        ensureOpen()
        let countBefore = getTotalCount()
        // Keep the row with the lowest id for each barcode
        let sql = """
        DELETE FROM staging_foods WHERE id NOT IN (
            SELECT MIN(id) FROM staging_foods WHERE barcode != '' GROUP BY barcode
        ) AND barcode != ''
        """
        sqlite3_exec(db, sql, nil, nil, nil)
        return countBefore - getTotalCount()
    }

    func countDuplicateBarcodes() -> Int {
        ensureOpen()
        let sql = """
        SELECT COUNT(*) FROM staging_foods WHERE id NOT IN (
            SELECT MIN(id) FROM staging_foods WHERE barcode != '' GROUP BY barcode
        ) AND barcode != ''
        """
        return countQuery(sql)
    }

    /// Run all cleanup operations in sequence - returns total deleted
    /// NOTE: Less aggressive by default - only removes clearly bad data
    func cleanAll(deleteNonUKByOrigin: Bool = false,  // OFF by default - too aggressive
                  deleteNonUKBarcodes: Bool = true,   // ON - uses barcode prefix which is reliable
                  deleteNoIngredients: Bool = false,  // OFF - many valid products have no ingredients listed
                  deleteNoNutrition: Bool = true,     // ON - zero cals with macros is contradictory
                  deleteJunk: Bool = true,            // ON - removes placeholder ingredients
                  dedupe: Bool = true,                // ON - removes duplicates
                  deleteForeign: Bool = true,         // ON - removes non-English
                  deleteNonLatin: Bool = true,        // ON - removes Arabic/Chinese/etc
                  deleteIncompleteMacros: Bool = true // ON - removes impossible nutrition
    ) -> (total: Int, details: String) {
        var totalDeleted = 0
        var details: [String] = []

        // 1. Remove non-Latin script first (Arabic, Chinese, Hebrew, etc.)
        if deleteNonLatin {
            let count = deleteAllNonLatinScript()
            totalDeleted += count
            if count > 0 { details.append("\(count) non-Latin script") }
        }

        // 2. Remove by barcode prefix (reliable UK filter)
        if deleteNonUKBarcodes {
            let count = deleteAllNonUKBarcodes()
            totalDeleted += count
            if count > 0 { details.append("\(count) non-UK barcodes") }
        }

        // 3. Remove by origin field (less reliable - OFF by default)
        if deleteNonUKByOrigin {
            let count = deleteAllNonUK()
            totalDeleted += count
            if count > 0 { details.append("\(count) non-UK origin") }
        }

        // 4. Remove foreign language ingredients
        if deleteForeign {
            let count = deleteAllNonEnglishIngredients()
            totalDeleted += count
            if count > 0 { details.append("\(count) foreign language") }
        }

        // 5. Remove junk/placeholder ingredients
        if deleteJunk {
            let count = deleteAllJunkIngredients()
            totalDeleted += count
            if count > 0 { details.append("\(count) junk ingredients") }
        }

        // 6. Remove contradictory nutrition (0 cals but has macros)
        if deleteNoNutrition {
            let count = deleteAllZeroCalories()
            totalDeleted += count
            if count > 0 { details.append("\(count) bad calories") }
        }

        // 7. Remove impossible macros (>10 cals but all macros are 0)
        if deleteIncompleteMacros {
            let count = deleteAllIncompleteMacros()
            totalDeleted += count
            if count > 0 { details.append("\(count) incomplete macros") }
        }

        // 8. Remove items with no ingredients (OFF by default)
        if deleteNoIngredients {
            let count = deleteAllNoIngredients()
            totalDeleted += count
            if count > 0 { details.append("\(count) no ingredients") }
        }

        // 9. Deduplicate by barcode
        if dedupe {
            let count = deduplicateBarcodes()
            totalDeleted += count
            if count > 0 { details.append("\(count) duplicates") }
        }

        return (totalDeleted, details.joined(separator: ", "))
    }

    // MARK: - Batched Delete with Progress (for live UI updates)

    /// Delete items matching a WHERE clause in batches, calling progress handler after each batch
    /// Returns total deleted. Cancel by returning false from onProgress.
    func batchedDelete(whereClause: String, batchSize: Int = 5000,
                       onProgress: @escaping (_ deleted: Int, _ remaining: Int) -> Bool) -> Int {
        ensureOpen()
        var totalDeleted = 0

        // First get IDs to delete
        let countSql = "SELECT COUNT(*) FROM staging_foods WHERE \(whereClause)"
        var initialCount = 0
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, countSql, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                initialCount = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)

        if initialCount == 0 { return 0 }

        var remaining = initialCount

        while remaining > 0 {
            // Delete a batch using LIMIT
            let deleteSql = "DELETE FROM staging_foods WHERE id IN (SELECT id FROM staging_foods WHERE \(whereClause) LIMIT \(batchSize))"
            sqlite3_exec(db, deleteSql, nil, nil, nil)

            let changes = Int(sqlite3_changes(db))
            if changes == 0 { break }

            totalDeleted += changes
            remaining -= changes

            // Call progress handler - if it returns false, stop
            if !onProgress(totalDeleted, remaining) {
                break
            }
        }

        return totalDeleted
    }

    /// Batched version of deleteAllNonUKBarcodes with progress
    func deleteNonUKBarcodesBatched(batchSize: Int = 5000,
                                     onProgress: @escaping (_ deleted: Int, _ remaining: Int) -> Bool) -> Int {
        let whereClause = """
        barcode != '' AND
        barcode NOT LIKE '50%' AND
        barcode NOT LIKE '00%' AND barcode NOT LIKE '01%' AND barcode NOT LIKE '02%' AND
        barcode NOT LIKE '20%' AND barcode NOT LIKE '21%' AND barcode NOT LIKE '22%' AND
        barcode NOT LIKE '23%' AND barcode NOT LIKE '24%' AND barcode NOT LIKE '25%' AND
        barcode NOT LIKE '26%' AND barcode NOT LIKE '27%' AND barcode NOT LIKE '28%' AND
        barcode NOT LIKE '29%' AND
        barcode NOT LIKE '4088600%' AND barcode NOT LIKE '4088660%' AND barcode NOT LIKE '4056489%'
        """
        return batchedDelete(whereClause: whereClause, batchSize: batchSize, onProgress: onProgress)
    }

    /// Batched version of deleteAllNoIngredients with progress
    func deleteNoIngredientsBatched(batchSize: Int = 5000,
                                     onProgress: @escaping (_ deleted: Int, _ remaining: Int) -> Bool) -> Int {
        return batchedDelete(whereClause: "ingredients IS NULL OR ingredients = ''",
                            batchSize: batchSize, onProgress: onProgress)
    }

    /// Batched version of deleteAllZeroCalories with progress
    func deleteZeroCaloriesBatched(batchSize: Int = 5000,
                                    onProgress: @escaping (_ deleted: Int, _ remaining: Int) -> Bool) -> Int {
        // Only delete items with 0 calories but has macros (contradictory data)
        let whereClause = """
        (calories IS NULL OR calories = 0) AND
        (protein > 0 OR carbs > 0 OR fat > 0)
        """
        return batchedDelete(whereClause: whereClause, batchSize: batchSize, onProgress: onProgress)
    }

    /// Batched version of deleteAllIncompleteMacros with progress
    func deleteIncompleteMacrosBatched(batchSize: Int = 5000,
                                        onProgress: @escaping (_ deleted: Int, _ remaining: Int) -> Bool) -> Int {
        // Only delete items with calories > 10 but ALL macros are 0 (nutritionally impossible)
        let whereClause = """
        calories > 10 AND
        (protein IS NULL OR protein = 0) AND
        (carbs IS NULL OR carbs = 0) AND
        (fat IS NULL OR fat = 0)
        """
        return batchedDelete(whereClause: whereClause, batchSize: batchSize, onProgress: onProgress)
    }

    /// Batched version of deleteAllJunkIngredients with progress
    func deleteJunkIngredientsBatched(batchSize: Int = 5000,
                                       onProgress: @escaping (_ deleted: Int, _ remaining: Int) -> Bool) -> Int {
        let whereClause = """
        LOWER(ingredients) IN ('none', 'n/a', 'na', 'nine', 'null', 'undefined', 'unknown',
                               'not available', 'no ingredients', 'see package', 'voir emballage',
                               '-', '--', '---', '.', '..', '...', 'tbc', 'tbd', 'test') OR
        LOWER(ingredients) LIKE 'ingredients:%' OR
        LOWER(ingredients) LIKE 'contains:%' OR
        (LENGTH(ingredients) > 0 AND LENGTH(ingredients) < 3)
        """
        return batchedDelete(whereClause: whereClause, batchSize: batchSize, onProgress: onProgress)
    }

    /// Batched version of deleteAllNonEnglishIngredients with progress
    func deleteNonEnglishIngredientsBatched(batchSize: Int = 5000,
                                             onProgress: @escaping (_ deleted: Int, _ remaining: Int) -> Bool) -> Int {
        let whereClause = """
        LOWER(ingredients) LIKE '%ingrédients%' OR
        LOWER(ingredients) LIKE '%sucre%' OR
        LOWER(ingredients) LIKE '%farine de blé%' OR
        LOWER(ingredients) LIKE '%huile de%' OR
        LOWER(ingredients) LIKE '%lait entier%' OR
        LOWER(ingredients) LIKE '%beurre%' OR
        LOWER(ingredients) LIKE '%oeufs%' OR
        LOWER(ingredients) LIKE '%zutaten%' OR
        LOWER(ingredients) LIKE '%zucker%' OR
        LOWER(ingredients) LIKE '%weizenmehl%' OR
        LOWER(ingredients) LIKE '%vollmilch%' OR
        LOWER(ingredients) LIKE '%ingredientes%' OR
        LOWER(ingredients) LIKE '%azúcar%' OR
        LOWER(ingredients) LIKE '%harina de trigo%' OR
        LOWER(ingredients) LIKE '%aceite de%' OR
        LOWER(ingredients) LIKE '%ingredienti%' OR
        LOWER(ingredients) LIKE '%zucchero%' OR
        LOWER(ingredients) LIKE '%farina di%' OR
        LOWER(ingredients) LIKE '%voir emballage%' OR
        LOWER(ingredients) LIKE '%siehe packung%' OR
        LOWER(ingredients) LIKE '%véase envase%' OR
        ingredients LIKE '%ä%' OR
        ingredients LIKE '%ö%' OR
        ingredients LIKE '%ü%' OR
        ingredients LIKE '%ß%' OR
        ingredients LIKE '%é%' OR
        ingredients LIKE '%è%' OR
        ingredients LIKE '%ê%' OR
        ingredients LIKE '%à%' OR
        ingredients LIKE '%ù%' OR
        ingredients LIKE '%ç%' OR
        ingredients LIKE '%ñ%' OR
        ingredients LIKE '%í%' OR
        ingredients LIKE '%ó%' OR
        ingredients LIKE '%ú%'
        """
        return batchedDelete(whereClause: whereClause, batchSize: batchSize, onProgress: onProgress)
    }

    // MARK: - Non-English Detection

    /// Delete items with non-English ingredients (French, German, Spanish, etc.)
    @discardableResult
    func deleteAllNonEnglishIngredients() -> Int {
        ensureOpen()
        let countBefore = getTotalCount()
        // Detect common non-English patterns:
        // French: ingrédients, sucre, farine, lait, huile, sel, eau, beurre, oeuf
        // German: zutaten, zucker, mehl, milch, öl, salz, wasser, butter, ei
        // Spanish: ingredientes, azúcar, harina, leche, aceite, sal, agua, mantequilla, huevo
        // Italian: ingredienti, zucchero, farina, latte, olio, sale, acqua, burro, uovo
        // Also detect accented characters common in foreign languages
        let sql = """
        DELETE FROM staging_foods WHERE
        LOWER(ingredients) LIKE '%ingrédients%' OR
        LOWER(ingredients) LIKE '%sucre%' OR
        LOWER(ingredients) LIKE '%farine de blé%' OR
        LOWER(ingredients) LIKE '%huile de%' OR
        LOWER(ingredients) LIKE '%lait entier%' OR
        LOWER(ingredients) LIKE '%beurre%' OR
        LOWER(ingredients) LIKE '%oeufs%' OR
        LOWER(ingredients) LIKE '%zutaten%' OR
        LOWER(ingredients) LIKE '%zucker%' OR
        LOWER(ingredients) LIKE '%weizenmehl%' OR
        LOWER(ingredients) LIKE '%vollmilch%' OR
        LOWER(ingredients) LIKE '%ingredientes%' OR
        LOWER(ingredients) LIKE '%azúcar%' OR
        LOWER(ingredients) LIKE '%harina de trigo%' OR
        LOWER(ingredients) LIKE '%aceite de%' OR
        LOWER(ingredients) LIKE '%ingredienti%' OR
        LOWER(ingredients) LIKE '%zucchero%' OR
        LOWER(ingredients) LIKE '%farina di%' OR
        LOWER(ingredients) LIKE '%voir emballage%' OR
        LOWER(ingredients) LIKE '%siehe packung%' OR
        LOWER(ingredients) LIKE '%véase envase%' OR
        ingredients LIKE '%ä%' OR
        ingredients LIKE '%ö%' OR
        ingredients LIKE '%ü%' OR
        ingredients LIKE '%ß%' OR
        ingredients LIKE '%é%' OR
        ingredients LIKE '%è%' OR
        ingredients LIKE '%ê%' OR
        ingredients LIKE '%à%' OR
        ingredients LIKE '%ù%' OR
        ingredients LIKE '%ç%' OR
        ingredients LIKE '%ñ%' OR
        ingredients LIKE '%í%' OR
        ingredients LIKE '%ó%' OR
        ingredients LIKE '%ú%'
        """
        sqlite3_exec(db, sql, nil, nil, nil)
        return countBefore - getTotalCount()
    }

    // MARK: - Non-Latin Script Detection (Arabic, Chinese, Hebrew, etc.)

    /// Delete items with non-Latin characters in name, brand, or ingredients
    /// This catches Arabic, Chinese, Hebrew, Russian, etc.
    @discardableResult
    func deleteAllNonLatinScript() -> Int {
        ensureOpen()
        let countBefore = getTotalCount()

        // Get IDs of items with non-Latin characters
        // We check if name/brand/ingredients contain characters outside ASCII + extended Latin
        let sql = """
        SELECT id, name, brand, ingredients FROM staging_foods
        """
        var stmt: OpaquePointer?
        var idsToDelete: [Int] = []

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(stmt, 0))
                let name = getString(stmt, 1)
                let brand = getString(stmt, 2)
                let ingredients = getString(stmt, 3)

                // Check for non-Latin characters
                let combined = name + brand + ingredients
                if containsNonLatinScript(combined) {
                    idsToDelete.append(id)
                }
            }
        }
        sqlite3_finalize(stmt)

        // Delete in batches
        if !idsToDelete.isEmpty {
            beginTransaction()
            for id in idsToDelete {
                let deleteSql = "DELETE FROM staging_foods WHERE id = ?"
                var deleteStmt: OpaquePointer?
                if sqlite3_prepare_v2(db, deleteSql, -1, &deleteStmt, nil) == SQLITE_OK {
                    sqlite3_bind_int(deleteStmt, 1, Int32(id))
                    sqlite3_step(deleteStmt)
                }
                sqlite3_finalize(deleteStmt)
            }
            commitTransaction()
        }

        return countBefore - getTotalCount()
    }

    /// Count items with non-Latin script (SLOW - iterates all rows)
    /// Use estimateNonLatinCount() for large datasets
    func countNonLatinScript() -> Int {
        ensureOpen()
        let sql = "SELECT name, brand, ingredients FROM staging_foods"
        var stmt: OpaquePointer?
        var count = 0

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let name = getString(stmt, 0)
                let brand = getString(stmt, 1)
                let ingredients = getString(stmt, 2)

                let combined = name + brand + ingredients
                if containsNonLatinScript(combined) {
                    count += 1
                }
            }
        }
        sqlite3_finalize(stmt)
        return count
    }

    /// FAST estimate of non-Latin items using random sample
    func estimateNonLatinCount(sampleSize: Int = 1000) -> Int {
        ensureOpen()
        let total = getTotalCount()
        if total == 0 { return 0 }
        if total <= sampleSize {
            return countNonLatinScript() // Small dataset, just count all
        }

        // Use random sampling
        let sql = "SELECT name, brand, ingredients FROM staging_foods ORDER BY RANDOM() LIMIT \(sampleSize)"
        var stmt: OpaquePointer?
        var matchCount = 0

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let name = getString(stmt, 0)
                let brand = getString(stmt, 1)
                let ingredients = getString(stmt, 2)

                let combined = name + brand + ingredients
                if containsNonLatinScript(combined) {
                    matchCount += 1
                }
            }
        }
        sqlite3_finalize(stmt)

        // Extrapolate to full dataset
        let ratio = Double(matchCount) / Double(sampleSize)
        return Int(Double(total) * ratio)
    }

    /// Check if string contains non-Latin characters (Arabic, Chinese, Hebrew, etc.)
    private func containsNonLatinScript(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            let value = scalar.value

            // Allow: Basic Latin (0-127), Latin Extended (128-591), Latin Extended Additional, common punctuation
            // Reject: Arabic (0x0600-0x06FF), Hebrew (0x0590-0x05FF), Chinese/CJK (0x4E00-0x9FFF),
            //         Cyrillic (0x0400-0x04FF), Greek (0x0370-0x03FF), Thai (0x0E00-0x0E7F), etc.

            // Simple check: if character is above Latin Extended range and not common symbols, it's non-Latin
            if value > 0x024F {  // Beyond Latin Extended-B
                // Allow common punctuation, currency, math symbols (up to 0x2000 area)
                // But reject scripts starting from 0x0370 (Greek) onwards
                if value >= 0x0370 && value < 0x0250 {
                    continue  // This won't trigger, but structure for clarity
                }
                // Arabic range
                if value >= 0x0600 && value <= 0x06FF { return true }
                // Hebrew range
                if value >= 0x0590 && value <= 0x05FF { return true }
                // CJK (Chinese/Japanese/Korean)
                if value >= 0x4E00 && value <= 0x9FFF { return true }
                if value >= 0x3400 && value <= 0x4DBF { return true }  // CJK Extension A
                if value >= 0x3040 && value <= 0x309F { return true }  // Hiragana
                if value >= 0x30A0 && value <= 0x30FF { return true }  // Katakana
                // Cyrillic
                if value >= 0x0400 && value <= 0x04FF { return true }
                // Greek
                if value >= 0x0370 && value <= 0x03FF { return true }
                // Thai
                if value >= 0x0E00 && value <= 0x0E7F { return true }
                // Devanagari (Hindi)
                if value >= 0x0900 && value <= 0x097F { return true }
            }
        }
        return false
    }

    /// Batched version of deleteAllNonLatinScript with progress
    func deleteNonLatinScriptBatched(batchSize: Int = 1000,
                                      onProgress: @escaping (_ deleted: Int, _ remaining: Int) -> Bool) -> Int {
        ensureOpen()

        // First, get all IDs to delete
        let sql = "SELECT id, name, brand, ingredients FROM staging_foods"
        var stmt: OpaquePointer?
        var idsToDelete: [Int] = []

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(stmt, 0))
                let name = getString(stmt, 1)
                let brand = getString(stmt, 2)
                let ingredients = getString(stmt, 3)

                let combined = name + brand + ingredients
                if containsNonLatinScript(combined) {
                    idsToDelete.append(id)
                }
            }
        }
        sqlite3_finalize(stmt)

        if idsToDelete.isEmpty { return 0 }

        let total = idsToDelete.count
        var deleted = 0

        // Delete in batches
        for batch in stride(from: 0, to: idsToDelete.count, by: batchSize) {
            let end = min(batch + batchSize, idsToDelete.count)
            let batchIds = Array(idsToDelete[batch..<end])

            beginTransaction()
            for id in batchIds {
                let deleteSql = "DELETE FROM staging_foods WHERE id = ?"
                var deleteStmt: OpaquePointer?
                if sqlite3_prepare_v2(db, deleteSql, -1, &deleteStmt, nil) == SQLITE_OK {
                    sqlite3_bind_int(deleteStmt, 1, Int32(id))
                    sqlite3_step(deleteStmt)
                }
                sqlite3_finalize(deleteStmt)
            }
            commitTransaction()

            deleted += batchIds.count

            // Progress callback
            if !onProgress(deleted, total - deleted) {
                break  // Cancelled
            }
        }

        return deleted
    }

    // MARK: - UK-Sold Products Filter

    /// Delete items NOT sold in UK (based on countries_tags in extra_data)
    /// More strict than origin - checks if UK is in the countries list
    @discardableResult
    func deleteNotSoldInUK() -> Int {
        ensureOpen()
        let countBefore = getTotalCount()

        // Delete items where extra_data doesn't contain UK in countries
        // OpenFoodFacts uses: "en:united-kingdom" in countries_tags
        let sql = """
        DELETE FROM staging_foods WHERE
        extra_data NOT LIKE '%united-kingdom%' AND
        extra_data NOT LIKE '%United Kingdom%' AND
        extra_data NOT LIKE '%"UK"%' AND
        extra_data NOT LIKE '%en:uk%' AND
        extra_data NOT LIKE '%great-britain%' AND
        extra_data NOT LIKE '%Great Britain%' AND
        extra_data NOT LIKE '%en:gb%'
        """
        sqlite3_exec(db, sql, nil, nil, nil)
        return countBefore - getTotalCount()
    }

    func countNotSoldInUK() -> Int {
        ensureOpen()
        let sql = """
        SELECT COUNT(*) FROM staging_foods WHERE
        extra_data NOT LIKE '%united-kingdom%' AND
        extra_data NOT LIKE '%United Kingdom%' AND
        extra_data NOT LIKE '%"UK"%' AND
        extra_data NOT LIKE '%en:uk%' AND
        extra_data NOT LIKE '%great-britain%' AND
        extra_data NOT LIKE '%Great Britain%' AND
        extra_data NOT LIKE '%en:gb%'
        """
        return countQuery(sql)
    }

    func countNonEnglishIngredients() -> Int {
        ensureOpen()
        let sql = """
        SELECT COUNT(*) FROM staging_foods WHERE
        LOWER(ingredients) LIKE '%ingrédients%' OR
        LOWER(ingredients) LIKE '%sucre%' OR
        LOWER(ingredients) LIKE '%farine de blé%' OR
        LOWER(ingredients) LIKE '%huile de%' OR
        LOWER(ingredients) LIKE '%lait entier%' OR
        LOWER(ingredients) LIKE '%beurre%' OR
        LOWER(ingredients) LIKE '%oeufs%' OR
        LOWER(ingredients) LIKE '%zutaten%' OR
        LOWER(ingredients) LIKE '%zucker%' OR
        LOWER(ingredients) LIKE '%weizenmehl%' OR
        LOWER(ingredients) LIKE '%vollmilch%' OR
        LOWER(ingredients) LIKE '%ingredientes%' OR
        LOWER(ingredients) LIKE '%azúcar%' OR
        LOWER(ingredients) LIKE '%harina de trigo%' OR
        LOWER(ingredients) LIKE '%aceite de%' OR
        LOWER(ingredients) LIKE '%ingredienti%' OR
        LOWER(ingredients) LIKE '%zucchero%' OR
        LOWER(ingredients) LIKE '%farina di%' OR
        LOWER(ingredients) LIKE '%voir emballage%' OR
        LOWER(ingredients) LIKE '%siehe packung%' OR
        LOWER(ingredients) LIKE '%véase envase%' OR
        ingredients LIKE '%ä%' OR
        ingredients LIKE '%ö%' OR
        ingredients LIKE '%ü%' OR
        ingredients LIKE '%ß%' OR
        ingredients LIKE '%é%' OR
        ingredients LIKE '%è%' OR
        ingredients LIKE '%ê%' OR
        ingredients LIKE '%à%' OR
        ingredients LIKE '%ù%' OR
        ingredients LIKE '%ç%' OR
        ingredients LIKE '%ñ%' OR
        ingredients LIKE '%í%' OR
        ingredients LIKE '%ó%' OR
        ingredients LIKE '%ú%'
        """
        return countQuery(sql)
    }

    // MARK: - Serving Size Counts

    /// Count items with no serving size (0 or NULL)
    func countNoServingSize() -> Int {
        ensureOpen()
        return countQuery("SELECT COUNT(*) FROM staging_foods WHERE serving_size_g IS NULL OR serving_size_g = 0")
    }

    /// Count items WITH serving size
    func countWithServingSize() -> Int {
        ensureOpen()
        return countQuery("SELECT COUNT(*) FROM staging_foods WHERE serving_size_g > 0")
    }

    /// Delete items with no serving size
    @discardableResult
    func deleteAllNoServingSize() -> Int {
        ensureOpen()
        let countBefore = getTotalCount()
        sqlite3_exec(db, "DELETE FROM staging_foods WHERE serving_size_g IS NULL OR serving_size_g = 0", nil, nil, nil)
        return countBefore - getTotalCount()
    }

    /// Batched version of deleteAllNoServingSize with progress
    func deleteNoServingSizeBatched(batchSize: Int = 5000,
                                     onProgress: @escaping (_ deleted: Int, _ remaining: Int) -> Bool) -> Int {
        return batchedDelete(whereClause: "serving_size_g IS NULL OR serving_size_g = 0",
                            batchSize: batchSize, onProgress: onProgress)
    }

    // MARK: - Search Function

    /// Search for foods by name, brand, barcode, or ingredients
    func searchRows(query: String, queue: String, limit: Int = 200) -> [StagingFoodRow] {
        ensureOpen()
        guard !query.isEmpty else {
            print("🔍 StagingDB.searchRows: Empty query, returning empty")
            return []
        }

        print("🔍 StagingDB.searchRows: Searching for '\(query)' in queue '\(queue)' with limit \(limit)")
        let searchTerm = "%\(query)%"
        let sql = """
        SELECT id, name, brand, barcode, calories, protein, carbs, fat,
               saturated_fat, fiber, sugar, sodium, serving_description,
               serving_size_g, is_per_unit, ingredients, cleaning_status, queue, extra_data
        FROM staging_foods
        WHERE queue = ?
          AND (name LIKE ? COLLATE NOCASE
               OR brand LIKE ? COLLATE NOCASE
               OR barcode LIKE ? COLLATE NOCASE
               OR ingredients LIKE ? COLLATE NOCASE)
        ORDER BY
            CASE
                WHEN name LIKE ? COLLATE NOCASE THEN 1
                WHEN brand LIKE ? COLLATE NOCASE THEN 2
                WHEN barcode = ? THEN 3
                ELSE 4
            END,
            name ASC
        LIMIT ?
        """

        var stmt: OpaquePointer?
        var rows: [StagingFoodRow] = []

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            let nsQueue = queue as NSString
            let nsSearch = searchTerm as NSString
            let nsExact = query as NSString

            sqlite3_bind_text(stmt, 1, nsQueue.utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 2, nsSearch.utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 3, nsSearch.utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 4, nsSearch.utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 5, nsSearch.utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 6, nsSearch.utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 7, nsSearch.utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 8, nsExact.utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(stmt, 9, Int32(limit))

            while sqlite3_step(stmt) == SQLITE_ROW {
                let row = StagingFoodRow(
                    id: Int(sqlite3_column_int(stmt, 0)),
                    name: getString(stmt, 1),
                    brand: getString(stmt, 2),
                    barcode: getString(stmt, 3),
                    calories: sqlite3_column_double(stmt, 4),
                    protein: sqlite3_column_double(stmt, 5),
                    carbs: sqlite3_column_double(stmt, 6),
                    fat: sqlite3_column_double(stmt, 7),
                    saturatedFat: sqlite3_column_double(stmt, 8),
                    fiber: sqlite3_column_double(stmt, 9),
                    sugar: sqlite3_column_double(stmt, 10),
                    sodium: sqlite3_column_double(stmt, 11),
                    servingDescription: getString(stmt, 12),
                    servingSizeG: sqlite3_column_double(stmt, 13),
                    isPerUnit: sqlite3_column_int(stmt, 14) == 1,
                    ingredients: getString(stmt, 15),
                    cleaningStatus: getString(stmt, 16, default: "pending"),
                    queue: getString(stmt, 17, default: "staging"),
                    extraData: parseExtraData(getString(stmt, 18, default: "{}"))
                )
                rows.append(row)
            }
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            print("❌ StagingDB.searchRows: SQL prepare failed: \(errorMsg)")
        }
        sqlite3_finalize(stmt)
        print("🔍 StagingDB.searchRows: Returning \(rows.count) results")
        return rows
    }

    /// Count search results
    func countSearchResults(query: String, queue: String) -> Int {
        ensureOpen()
        guard !query.isEmpty else { return 0 }

        let searchTerm = "%\(query)%"
        let sql = """
        SELECT COUNT(*) FROM staging_foods
        WHERE queue = ?
          AND (name LIKE ? COLLATE NOCASE
               OR brand LIKE ? COLLATE NOCASE
               OR barcode LIKE ? COLLATE NOCASE
               OR ingredients LIKE ? COLLATE NOCASE)
        """

        var stmt: OpaquePointer?
        var count = 0

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            let nsQueue = queue as NSString
            let nsSearch = searchTerm as NSString

            sqlite3_bind_text(stmt, 1, nsQueue.utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 2, nsSearch.utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 3, nsSearch.utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 4, nsSearch.utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 5, nsSearch.utf8String, -1, SQLITE_TRANSIENT)

            if sqlite3_step(stmt) == SQLITE_ROW {
                count = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        return count
    }

    // MARK: - Barcode Enrichment

    /// Count items with barcodes that have missing data (name or ingredients empty)
    func countNeedingBarcodeEnrichment() -> Int {
        ensureOpen()
        // Items with valid barcode but missing name or ingredients
        let sql = """
        SELECT COUNT(*) FROM staging_foods
        WHERE barcode != '' AND LENGTH(barcode) >= 8
          AND (name = '' OR name IS NULL
               OR ingredients = '' OR ingredients IS NULL
               OR (serving_size_g IS NULL OR serving_size_g = 0))
        """
        return countQuery(sql)
    }

    /// Get items with barcodes that need enrichment
    func getItemsNeedingEnrichment(limit: Int = 100) -> [StagingFoodRow] {
        ensureOpen()
        let sql = """
        SELECT id, name, brand, barcode, calories, protein, carbs, fat,
               saturated_fat, fiber, sugar, sodium, serving_description,
               serving_size_g, is_per_unit, ingredients, cleaning_status, queue, extra_data
        FROM staging_foods
        WHERE barcode != '' AND LENGTH(barcode) >= 8
          AND (name = '' OR name IS NULL
               OR ingredients = '' OR ingredients IS NULL
               OR (serving_size_g IS NULL OR serving_size_g = 0))
        LIMIT \(limit)
        """

        var stmt: OpaquePointer?
        var rows: [StagingFoodRow] = []

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let row = StagingFoodRow(
                    id: Int(sqlite3_column_int(stmt, 0)),
                    name: getString(stmt, 1),
                    brand: getString(stmt, 2),
                    barcode: getString(stmt, 3),
                    calories: sqlite3_column_double(stmt, 4),
                    protein: sqlite3_column_double(stmt, 5),
                    carbs: sqlite3_column_double(stmt, 6),
                    fat: sqlite3_column_double(stmt, 7),
                    saturatedFat: sqlite3_column_double(stmt, 8),
                    fiber: sqlite3_column_double(stmt, 9),
                    sugar: sqlite3_column_double(stmt, 10),
                    sodium: sqlite3_column_double(stmt, 11),
                    servingDescription: getString(stmt, 12),
                    servingSizeG: sqlite3_column_double(stmt, 13),
                    isPerUnit: sqlite3_column_int(stmt, 14) == 1,
                    ingredients: getString(stmt, 15),
                    cleaningStatus: getString(stmt, 16, default: "pending"),
                    queue: getString(stmt, 17, default: "staging"),
                    extraData: parseExtraData(getString(stmt, 18, default: "{}"))
                )
                rows.append(row)
            }
        }
        sqlite3_finalize(stmt)
        return rows
    }

    /// Update a row with enriched data from barcode lookup
    func enrichFromBarcodeLookup(id: Int, name: String?, brand: String?, ingredients: String?,
                                  servingDescription: String?, servingSizeG: Double?,
                                  calories: Double?, protein: Double?, carbs: Double?, fat: Double?,
                                  saturatedFat: Double?, fiber: Double?, sugar: Double?, sodium: Double?) {
        ensureOpen()
        guard let row = getRow(id: id) else { return }

        // Only fill in missing values, don't overwrite existing data
        let newName = (row.name.isEmpty && name != nil && !name!.isEmpty) ? name! : row.name
        let newBrand = (row.brand.isEmpty && brand != nil && !brand!.isEmpty) ? brand! : row.brand
        let newIngredients = (row.ingredients.isEmpty && ingredients != nil && !ingredients!.isEmpty) ? ingredients! : row.ingredients
        let newServingDesc = (row.servingDescription.isEmpty && servingDescription != nil && !servingDescription!.isEmpty) ? servingDescription! : row.servingDescription
        let newServingSizeG = (row.servingSizeG <= 0 && servingSizeG != nil && servingSizeG! > 0) ? servingSizeG! : row.servingSizeG

        // For nutrition, only fill if current value is 0 and lookup has a value
        let newCalories = (row.calories <= 0 && calories != nil && calories! > 0) ? calories! : row.calories
        let newProtein = (row.protein <= 0 && protein != nil && protein! > 0) ? protein! : row.protein
        let newCarbs = (row.carbs <= 0 && carbs != nil && carbs! > 0) ? carbs! : row.carbs
        let newFat = (row.fat <= 0 && fat != nil && fat! > 0) ? fat! : row.fat
        let newSaturatedFat = (row.saturatedFat <= 0 && saturatedFat != nil && saturatedFat! > 0) ? saturatedFat! : row.saturatedFat
        let newFiber = (row.fiber <= 0 && fiber != nil && fiber! > 0) ? fiber! : row.fiber
        let newSugar = (row.sugar <= 0 && sugar != nil && sugar! > 0) ? sugar! : row.sugar
        let newSodium = (row.sodium <= 0 && sodium != nil && sodium! > 0) ? sodium! : row.sodium

        updateRow(
            id: id,
            name: newName,
            brand: newBrand,
            barcode: row.barcode,
            calories: newCalories,
            protein: newProtein,
            carbs: newCarbs,
            fat: newFat,
            saturatedFat: newSaturatedFat,
            fiber: newFiber,
            sugar: newSugar,
            sodium: newSodium,
            servingDescription: newServingDesc,
            servingSizeG: newServingSizeG,
            isPerUnit: row.isPerUnit,
            ingredients: newIngredients,
            cleaningStatus: "enriched"
        )
    }

    // MARK: - Auto Tidy (Title Case Names & Ingredients)

    /// Apply Title Case to all names and ingredients (SQL-based, fast)
    /// Returns count of rows updated
    @discardableResult
    func autoTidyTitleCase() -> Int {
        ensureOpen()
        // SQLite doesn't have built-in Title Case, so we need to do this in batches
        // Read all rows, apply Title Case in Swift, update back
        var updatedCount = 0
        let batchSize = 5000
        var offset = 0

        while true {
            let sql = "SELECT id, name, brand, ingredients FROM staging_foods LIMIT \(batchSize) OFFSET \(offset)"
            var stmt: OpaquePointer?
            var updates: [(id: Int, name: String, brand: String, ingredients: String)] = []

            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let id = Int(sqlite3_column_int(stmt, 0))
                    let name = getString(stmt, 1)
                    let brand = getString(stmt, 2)
                    let ingredients = getString(stmt, 3)

                    let tidyName = titleCase(name)
                    let tidyBrand = titleCase(brand)
                    let tidyIngredients = titleCaseIngredients(ingredients)

                    // Only update if something changed
                    if tidyName != name || tidyBrand != brand || tidyIngredients != ingredients {
                        updates.append((id, tidyName, tidyBrand, tidyIngredients))
                    }
                }
            }
            sqlite3_finalize(stmt)

            if updates.isEmpty && offset > 0 {
                break // No more rows to process
            }

            // Apply updates in a transaction
            if !updates.isEmpty {
                beginTransaction()
                for update in updates {
                    let updateSql = "UPDATE staging_foods SET name = ?, brand = ?, ingredients = ? WHERE id = ?"
                    var updateStmt: OpaquePointer?
                    if sqlite3_prepare_v2(db, updateSql, -1, &updateStmt, nil) == SQLITE_OK {
                        let nsName = update.name as NSString
                        let nsBrand = update.brand as NSString
                        let nsIngredients = update.ingredients as NSString

                        sqlite3_bind_text(updateStmt, 1, nsName.utf8String, -1, SQLITE_TRANSIENT)
                        sqlite3_bind_text(updateStmt, 2, nsBrand.utf8String, -1, SQLITE_TRANSIENT)
                        sqlite3_bind_text(updateStmt, 3, nsIngredients.utf8String, -1, SQLITE_TRANSIENT)
                        sqlite3_bind_int(updateStmt, 4, Int32(update.id))
                        sqlite3_step(updateStmt)
                    }
                    sqlite3_finalize(updateStmt)
                }
                commitTransaction()
                updatedCount += updates.count
            }

            offset += batchSize
            if updates.count < batchSize { break }
        }

        return updatedCount
    }

    /// Convert string to Title Case (capitalize first letter of each word)
    private func titleCase(_ text: String) -> String {
        guard !text.isEmpty else { return text }

        // Split by spaces and capitalize each word
        let words = text.components(separatedBy: " ")
        let titleCased = words.map { word -> String in
            guard !word.isEmpty else { return word }
            // Keep certain words lowercase unless they're first
            let lowercaseWords = ["a", "an", "the", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by"]
            let lower = word.lowercased()
            if lowercaseWords.contains(lower) {
                return lower
            }
            return word.prefix(1).uppercased() + word.dropFirst().lowercased()
        }

        // First word should always be capitalized
        var result = titleCased
        if !result.isEmpty, let first = result.first {
            result[0] = first.prefix(1).uppercased() + first.dropFirst()
        }

        return result.joined(separator: " ")
    }

    /// Convert ingredients to Title Case (handles comma-separated lists)
    private func titleCaseIngredients(_ text: String) -> String {
        guard !text.isEmpty else { return text }

        // Split by common separators: comma, semicolon
        let parts = text.components(separatedBy: CharacterSet(charactersIn: ",;"))
        let titleCased = parts.map { part -> String in
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return part }

            // Handle parentheses - e.g., "sugar (from cane)"
            if let openParen = trimmed.firstIndex(of: "(") {
                let before = String(trimmed[..<openParen]).trimmingCharacters(in: .whitespaces)
                let parenContent = String(trimmed[openParen...])
                return titleCase(before) + " " + titleCaseParens(parenContent)
            }

            return titleCase(trimmed)
        }

        // Rejoin with proper spacing after commas
        var result = ""
        for (index, part) in titleCased.enumerated() {
            if index > 0 {
                // Preserve original separator (check if semicolon was used)
                let originalSeparators = text.components(separatedBy: CharacterSet(charactersIn: ",;").inverted).filter { !$0.isEmpty }
                let separator = (index - 1 < originalSeparators.count && originalSeparators[index - 1].contains(";")) ? "; " : ", "
                result += separator
            }
            result += part.trimmingCharacters(in: .whitespaces)
        }

        return result
    }

    /// Handle parentheses content - Title Case inside parens too
    private func titleCaseParens(_ text: String) -> String {
        guard text.hasPrefix("(") else { return text }

        // Extract content between parens
        var depth = 0
        var content = ""
        var remaining = ""

        for (index, char) in text.enumerated() {
            if char == "(" { depth += 1 }
            else if char == ")" { depth -= 1 }

            if depth == 0 && index > 0 {
                content = String(text.dropFirst().prefix(index - 1))
                remaining = String(text.dropFirst(index + 1))
                break
            }
        }

        if content.isEmpty {
            content = String(text.dropFirst().dropLast())
        }

        // Title case the content and reconstruct
        let tidyContent = content.components(separatedBy: ",").map { titleCase($0.trimmingCharacters(in: .whitespaces)) }.joined(separator: ", ")

        return "(\(tidyContent))" + remaining
    }

    private func countQuery(_ sql: String) -> Int {
        ensureOpen()
        var stmt: OpaquePointer?
        var count = 0
        let result = sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        if result == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                count = Int(sqlite3_column_int(stmt, 0))
            }
        } else {
            print("SQL Error in countQuery: \(String(cString: sqlite3_errmsg(db)))")
            print("SQL: \(sql.prefix(100))...")
        }
        sqlite3_finalize(stmt)
        return count
    }

    func getRow(id: Int) -> StagingFoodRow? {
        ensureOpen()
        let sql = """
        SELECT id, name, brand, barcode, calories, protein, carbs, fat,
               saturated_fat, fiber, sugar, sodium, serving_description,
               serving_size_g, is_per_unit, ingredients, cleaning_status, queue, extra_data
        FROM staging_foods WHERE id = ?
        """
        var stmt: OpaquePointer?
        var row: StagingFoodRow?

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(id))
            if sqlite3_step(stmt) == SQLITE_ROW {
                row = StagingFoodRow(
                    id: Int(sqlite3_column_int(stmt, 0)),
                    name: getString(stmt, 1),
                    brand: getString(stmt, 2),
                    barcode: getString(stmt, 3),
                    calories: sqlite3_column_double(stmt, 4),
                    protein: sqlite3_column_double(stmt, 5),
                    carbs: sqlite3_column_double(stmt, 6),
                    fat: sqlite3_column_double(stmt, 7),
                    saturatedFat: sqlite3_column_double(stmt, 8),
                    fiber: sqlite3_column_double(stmt, 9),
                    sugar: sqlite3_column_double(stmt, 10),
                    sodium: sqlite3_column_double(stmt, 11),
                    servingDescription: getString(stmt, 12),
                    servingSizeG: sqlite3_column_double(stmt, 13),
                    isPerUnit: sqlite3_column_int(stmt, 14) == 1,
                    ingredients: getString(stmt, 15),
                    cleaningStatus: getString(stmt, 16, default: "pending"),
                    queue: getString(stmt, 17, default: "staging"),
                    extraData: parseExtraData(getString(stmt, 18, default: "{}"))
                )
            }
        }
        sqlite3_finalize(stmt)
        return row
    }

    func getCleanedCount() -> Int {
        ensureOpen()
        let sql = "SELECT COUNT(*) FROM staging_foods WHERE cleaning_status = 'cleaned'"
        var stmt: OpaquePointer?
        var count = 0
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                count = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        return count
    }

    func getPendingIds(limit: Int) -> [Int] {
        ensureOpen()
        let sql = "SELECT id FROM staging_foods WHERE cleaning_status = 'pending' LIMIT ?"
        var stmt: OpaquePointer?
        var ids: [Int] = []
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(limit))
            while sqlite3_step(stmt) == SQLITE_ROW {
                ids.append(Int(sqlite3_column_int(stmt, 0)))
            }
        }
        sqlite3_finalize(stmt)
        return ids
    }

    func setCleaningStatus(id: Int, status: String) {
        ensureOpen()
        let sql = "UPDATE staging_foods SET cleaning_status = ? WHERE id = ?"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            let nsStatus = status as NSString
            sqlite3_bind_text(stmt, 1, nsStatus.utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(stmt, 2, Int32(id))
            if sqlite3_step(stmt) != SQLITE_DONE {
                print("Error setting cleaning status: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
        sqlite3_finalize(stmt)
    }

    // MARK: - Queue Management

    func moveToReady(ids: [Int]) {
        guard !ids.isEmpty else { return }
        ensureOpen()
        beginTransaction()
        for id in ids {
            let sql = "UPDATE staging_foods SET queue = 'ready' WHERE id = ?"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_int(stmt, 1, Int32(id))
                sqlite3_step(stmt)
            }
            sqlite3_finalize(stmt)
        }
        commitTransaction()
    }

    func moveToStaging(ids: [Int]) {
        guard !ids.isEmpty else { return }
        ensureOpen()
        beginTransaction()
        for id in ids {
            let sql = "UPDATE staging_foods SET queue = 'staging' WHERE id = ?"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_int(stmt, 1, Int32(id))
                sqlite3_step(stmt)
            }
            sqlite3_finalize(stmt)
        }
        commitTransaction()
    }

    func getQueueCount(queue: String) -> Int {
        ensureOpen()
        // Simple query - migration ensures queue is never NULL or empty
        let sql = "SELECT COUNT(*) FROM staging_foods WHERE queue = ?"
        var stmt: OpaquePointer?
        var count = 0
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            let nsQueue = queue as NSString
            sqlite3_bind_text(stmt, 1, nsQueue.utf8String, -1, SQLITE_TRANSIENT)
            if sqlite3_step(stmt) == SQLITE_ROW {
                count = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        return count
    }

    func getRowsByQueue(queue: String, offset: Int, limit: Int) -> [StagingFoodRow] {
        ensureOpen()
        // For 'staging', also include NULL and empty queue values (legacy data)
        let whereClause = queue == "staging"
            ? "WHERE queue = 'staging' OR queue IS NULL OR queue = ''"
            : "WHERE queue = ?"

        let sql = """
        SELECT id, name, brand, barcode, calories, protein, carbs, fat,
               saturated_fat, fiber, sugar, sodium, serving_description,
               serving_size_g, is_per_unit, ingredients, cleaning_status, queue, extra_data
        FROM staging_foods \(whereClause)
        ORDER BY id DESC LIMIT ? OFFSET ?
        """
        var stmt: OpaquePointer?
        var rows: [StagingFoodRow] = []

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if queue == "staging" {
                sqlite3_bind_int(stmt, 1, Int32(limit))
                sqlite3_bind_int(stmt, 2, Int32(offset))
            } else {
                sqlite3_bind_text(stmt, 1, queue, -1, nil)
                sqlite3_bind_int(stmt, 2, Int32(limit))
                sqlite3_bind_int(stmt, 3, Int32(offset))
            }

            while sqlite3_step(stmt) == SQLITE_ROW {
                let row = StagingFoodRow(
                    id: Int(sqlite3_column_int(stmt, 0)),
                    name: getString(stmt, 1),
                    brand: getString(stmt, 2),
                    barcode: getString(stmt, 3),
                    calories: sqlite3_column_double(stmt, 4),
                    protein: sqlite3_column_double(stmt, 5),
                    carbs: sqlite3_column_double(stmt, 6),
                    fat: sqlite3_column_double(stmt, 7),
                    saturatedFat: sqlite3_column_double(stmt, 8),
                    fiber: sqlite3_column_double(stmt, 9),
                    sugar: sqlite3_column_double(stmt, 10),
                    sodium: sqlite3_column_double(stmt, 11),
                    servingDescription: getString(stmt, 12),
                    servingSizeG: sqlite3_column_double(stmt, 13),
                    isPerUnit: sqlite3_column_int(stmt, 14) == 1,
                    ingredients: getString(stmt, 15),
                    cleaningStatus: getString(stmt, 16, default: "pending"),
                    queue: getString(stmt, 17, default: "staging"),
                    extraData: parseExtraData(getString(stmt, 18, default: "{}"))
                )
                rows.append(row)
            }
        }
        sqlite3_finalize(stmt)
        return rows
    }

    func getFilteredRowsByQueue(queue: String, filter: BarcodeFilter, offset: Int, limit: Int) -> [StagingFoodRow] {
        ensureOpen()
        // For 'staging', also include NULL and empty queue values (legacy data)
        var whereClause = queue == "staging"
            ? "WHERE (queue = 'staging' OR queue IS NULL OR queue = '')"
            : "WHERE queue = ?"

        // Comprehensive UK barcode detection including supermarket own-brands
        switch filter {
        case .all:
            break
        case .ukOnly:
            whereClause += """
             AND (barcode LIKE '50%' OR barcode LIKE '00%' OR barcode LIKE '01%' OR barcode LIKE '02%' OR
            barcode LIKE '20%' OR barcode LIKE '21%' OR barcode LIKE '22%' OR barcode LIKE '23%' OR
            barcode LIKE '24%' OR barcode LIKE '25%' OR barcode LIKE '26%' OR barcode LIKE '27%' OR
            barcode LIKE '28%' OR barcode LIKE '29%' OR
            barcode LIKE '4088600%' OR barcode LIKE '4088660%' OR barcode LIKE '4056489%')
            """
        case .nonUK:
            whereClause += """
             AND barcode != '' AND barcode NOT LIKE '50%' AND barcode NOT LIKE '00%' AND
            barcode NOT LIKE '01%' AND barcode NOT LIKE '02%' AND
            barcode NOT LIKE '20%' AND barcode NOT LIKE '21%' AND barcode NOT LIKE '22%' AND
            barcode NOT LIKE '23%' AND barcode NOT LIKE '24%' AND barcode NOT LIKE '25%' AND
            barcode NOT LIKE '26%' AND barcode NOT LIKE '27%' AND barcode NOT LIKE '28%' AND
            barcode NOT LIKE '29%' AND barcode NOT LIKE '4088600%' AND barcode NOT LIKE '4088660%' AND
            barcode NOT LIKE '4056489%'
            """
        case .noBarcode:
            whereClause += " AND (barcode = '' OR barcode IS NULL)"
        }

        let sql = """
        SELECT id, name, brand, barcode, calories, protein, carbs, fat,
               saturated_fat, fiber, sugar, sodium, serving_description,
               serving_size_g, is_per_unit, ingredients, cleaning_status, queue, extra_data
        FROM staging_foods \(whereClause)
        ORDER BY id DESC LIMIT ? OFFSET ?
        """

        var stmt: OpaquePointer?
        var rows: [StagingFoodRow] = []

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if queue == "staging" {
                sqlite3_bind_int(stmt, 1, Int32(limit))
                sqlite3_bind_int(stmt, 2, Int32(offset))
            } else {
                sqlite3_bind_text(stmt, 1, queue, -1, nil)
                sqlite3_bind_int(stmt, 2, Int32(limit))
                sqlite3_bind_int(stmt, 3, Int32(offset))
            }

            while sqlite3_step(stmt) == SQLITE_ROW {
                let row = StagingFoodRow(
                    id: Int(sqlite3_column_int(stmt, 0)),
                    name: getString(stmt, 1),
                    brand: getString(stmt, 2),
                    barcode: getString(stmt, 3),
                    calories: sqlite3_column_double(stmt, 4),
                    protein: sqlite3_column_double(stmt, 5),
                    carbs: sqlite3_column_double(stmt, 6),
                    fat: sqlite3_column_double(stmt, 7),
                    saturatedFat: sqlite3_column_double(stmt, 8),
                    fiber: sqlite3_column_double(stmt, 9),
                    sugar: sqlite3_column_double(stmt, 10),
                    sodium: sqlite3_column_double(stmt, 11),
                    servingDescription: getString(stmt, 12),
                    servingSizeG: sqlite3_column_double(stmt, 13),
                    isPerUnit: sqlite3_column_int(stmt, 14) == 1,
                    ingredients: getString(stmt, 15),
                    cleaningStatus: getString(stmt, 16, default: "pending"),
                    queue: getString(stmt, 17, default: "staging"),
                    extraData: parseExtraData(getString(stmt, 18, default: "{}"))
                )
                rows.append(row)
            }
        }
        sqlite3_finalize(stmt)
        return rows
    }

    func getFilteredCountByQueue(queue: String, filter: BarcodeFilter) -> Int {
        // For 'staging', also include NULL and empty queue values (legacy data)
        var whereClause = queue == "staging"
            ? "WHERE (queue = 'staging' OR queue IS NULL OR queue = '')"
            : "WHERE queue = ?"

        switch filter {
        case .all:
            break
        case .ukOnly:
            whereClause += """
             AND (barcode LIKE '50%' OR barcode LIKE '4088%' OR barcode LIKE '4061%' OR
            barcode LIKE '4056%' OR barcode LIKE '2000%' OR barcode LIKE '0113%' OR
            barcode LIKE '0000%')
            """
        case .nonUK:
            whereClause += """
             AND barcode != '' AND
            barcode NOT LIKE '50%' AND barcode NOT LIKE '4088%' AND barcode NOT LIKE '4061%' AND
            barcode NOT LIKE '4056%' AND barcode NOT LIKE '2000%' AND barcode NOT LIKE '0113%' AND
            barcode NOT LIKE '0000%'
            """
        case .noBarcode:
            whereClause += " AND (barcode = '' OR barcode IS NULL)"
        }

        let sql = "SELECT COUNT(*) FROM staging_foods \(whereClause)"
        var stmt: OpaquePointer?
        var count = 0
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if queue != "staging" {
                sqlite3_bind_text(stmt, 1, queue, -1, nil)
            }
            if sqlite3_step(stmt) == SQLITE_ROW {
                count = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        return count
    }

    func getReadyRows() -> [StagingFoodRow] {
        return getRowsByQueue(queue: "ready", offset: 0, limit: 1000000)
    }

    /// Check if a row with this barcode already exists (for duplicate detection during import)
    func existsByBarcode(_ barcode: String) -> Bool {
        guard !barcode.isEmpty else { return false }
        let sql = "SELECT 1 FROM staging_foods WHERE barcode = ? LIMIT 1"
        var stmt: OpaquePointer?
        var exists = false
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, barcode, -1, nil)
            exists = sqlite3_step(stmt) == SQLITE_ROW
        }
        sqlite3_finalize(stmt)
        return exists
    }

    /// Check if a row with this name and brand already exists (for duplicate detection)
    func existsByNameAndBrand(_ name: String, _ brand: String) -> Bool {
        guard !name.isEmpty else { return false }
        let sql = "SELECT 1 FROM staging_foods WHERE name = ? AND brand = ? LIMIT 1"
        var stmt: OpaquePointer?
        var exists = false
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, name, -1, nil)
            sqlite3_bind_text(stmt, 2, brand, -1, nil)
            exists = sqlite3_step(stmt) == SQLITE_ROW
        }
        sqlite3_finalize(stmt)
        return exists
    }

    // MARK: - Filtered Queries

    /// UK barcode prefixes: 50 = UK, plus retailer-specific prefixes
    static let ukBarcodePrefixes = [
        "50",       // UK GS1 prefix
        "0500",     // UK alternate
    ]

    /// UK retailer barcode prefixes (own-brand products)
    static let ukRetailerPrefixes: [(prefix: String, name: String)] = [
        // Tesco
        ("5000", "Tesco"),
        ("5010", "Tesco"),
        ("5018", "Tesco"),
        ("5051", "Tesco"),
        ("5052", "Tesco"),
        ("5053", "Tesco"),
        ("5054", "Tesco"),
        ("5057", "Tesco"),
        // Sainsbury's
        ("0113", "Sainsbury's"),
        ("5014", "Sainsbury's"),
        // M&S (Marks & Spencer)
        ("0000", "M&S"),  // M&S internal codes often start with 00
        ("5000013", "M&S"),
        ("5000024", "M&S"),
        // Asda
        ("5050", "Asda"),
        ("5051", "Asda"),
        // Morrisons
        ("5010", "Morrisons"),
        // Aldi UK
        ("4088", "Aldi"),
        ("4061", "Aldi"),
        ("4056", "Aldi"),
        ("2000", "Aldi"),  // Aldi internal
        // Lidl UK
        ("4056", "Lidl"),
        ("2000", "Lidl"),  // Lidl internal
        ("4088", "Lidl"),
        // Waitrose
        ("5000", "Waitrose"),
        // Co-op
        ("5000", "Co-op"),
        ("5018", "Co-op"),
        // Iceland
        ("5010", "Iceland"),
    ]

    func isUKBarcode(_ barcode: String) -> Bool {
        let trimmed = barcode.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }

        // Check if starts with UK GS1 prefix (50)
        if trimmed.hasPrefix("50") { return true }

        // Check retailer prefixes
        for (prefix, _) in Self.ukRetailerPrefixes {
            if trimmed.hasPrefix(prefix) { return true }
        }

        return false
    }

    func getRetailerName(_ barcode: String) -> String? {
        let trimmed = barcode.trimmingCharacters(in: .whitespaces)
        for (prefix, name) in Self.ukRetailerPrefixes {
            if trimmed.hasPrefix(prefix) { return name }
        }
        return nil
    }

    func getFilteredCount(filter: BarcodeFilter) -> Int {
        let sql: String
        switch filter {
        case .all:
            sql = "SELECT COUNT(*) FROM staging_foods"
        case .ukOnly:
            // UK barcodes start with 50, or retailer prefixes
            sql = """
            SELECT COUNT(*) FROM staging_foods WHERE
            barcode LIKE '50%' OR barcode LIKE '4088%' OR barcode LIKE '4061%' OR
            barcode LIKE '4056%' OR barcode LIKE '2000%' OR barcode LIKE '0113%' OR
            barcode LIKE '0000%'
            """
        case .nonUK:
            sql = """
            SELECT COUNT(*) FROM staging_foods WHERE
            barcode != '' AND
            barcode NOT LIKE '50%' AND barcode NOT LIKE '4088%' AND barcode NOT LIKE '4061%' AND
            barcode NOT LIKE '4056%' AND barcode NOT LIKE '2000%' AND barcode NOT LIKE '0113%' AND
            barcode NOT LIKE '0000%'
            """
        case .noBarcode:
            sql = "SELECT COUNT(*) FROM staging_foods WHERE barcode = '' OR barcode IS NULL"
        }

        var stmt: OpaquePointer?
        var count = 0
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                count = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        return count
    }

    func getFilteredRows(filter: BarcodeFilter, offset: Int, limit: Int) -> [StagingFoodRow] {
        let whereClause: String
        // Comprehensive UK barcode detection including supermarket own-brands
        switch filter {
        case .all:
            whereClause = ""
        case .ukOnly:
            whereClause = """
            WHERE (barcode LIKE '50%' OR barcode LIKE '00%' OR barcode LIKE '01%' OR barcode LIKE '02%' OR
            barcode LIKE '20%' OR barcode LIKE '21%' OR barcode LIKE '22%' OR barcode LIKE '23%' OR
            barcode LIKE '24%' OR barcode LIKE '25%' OR barcode LIKE '26%' OR barcode LIKE '27%' OR
            barcode LIKE '28%' OR barcode LIKE '29%' OR
            barcode LIKE '4088600%' OR barcode LIKE '4088660%' OR barcode LIKE '4056489%')
            """
        case .nonUK:
            whereClause = """
            WHERE barcode != '' AND barcode NOT LIKE '50%' AND barcode NOT LIKE '00%' AND
            barcode NOT LIKE '01%' AND barcode NOT LIKE '02%' AND
            barcode NOT LIKE '20%' AND barcode NOT LIKE '21%' AND barcode NOT LIKE '22%' AND
            barcode NOT LIKE '23%' AND barcode NOT LIKE '24%' AND barcode NOT LIKE '25%' AND
            barcode NOT LIKE '26%' AND barcode NOT LIKE '27%' AND barcode NOT LIKE '28%' AND
            barcode NOT LIKE '29%' AND barcode NOT LIKE '4088600%' AND barcode NOT LIKE '4088660%' AND
            barcode NOT LIKE '4056489%'
            """
        case .noBarcode:
            whereClause = "WHERE barcode = '' OR barcode IS NULL"
        }

        let sql = """
        SELECT id, name, brand, barcode, calories, protein, carbs, fat,
               saturated_fat, fiber, sugar, sodium, serving_description,
               serving_size_g, is_per_unit, ingredients, cleaning_status, queue, extra_data
        FROM staging_foods \(whereClause)
        ORDER BY id DESC LIMIT ? OFFSET ?
        """

        var stmt: OpaquePointer?
        var rows: [StagingFoodRow] = []

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(limit))
            sqlite3_bind_int(stmt, 2, Int32(offset))

            while sqlite3_step(stmt) == SQLITE_ROW {
                let row = StagingFoodRow(
                    id: Int(sqlite3_column_int(stmt, 0)),
                    name: getString(stmt, 1),
                    brand: getString(stmt, 2),
                    barcode: getString(stmt, 3),
                    calories: sqlite3_column_double(stmt, 4),
                    protein: sqlite3_column_double(stmt, 5),
                    carbs: sqlite3_column_double(stmt, 6),
                    fat: sqlite3_column_double(stmt, 7),
                    saturatedFat: sqlite3_column_double(stmt, 8),
                    fiber: sqlite3_column_double(stmt, 9),
                    sugar: sqlite3_column_double(stmt, 10),
                    sodium: sqlite3_column_double(stmt, 11),
                    servingDescription: getString(stmt, 12),
                    servingSizeG: sqlite3_column_double(stmt, 13),
                    isPerUnit: sqlite3_column_int(stmt, 14) == 1,
                    ingredients: getString(stmt, 15),
                    cleaningStatus: getString(stmt, 16, default: "pending"),
                    queue: getString(stmt, 17, default: "staging"),
                    extraData: parseExtraData(getString(stmt, 18, default: "{}"))
                )
                rows.append(row)
            }
        }
        sqlite3_finalize(stmt)
        return rows
    }

    func getAllRows() -> [StagingFoodRow] {
        return getRows(offset: 0, limit: 1000000)
    }

    // MARK: - Smart Deduplication

    /// Find potential duplicates using fuzzy matching
    /// Returns groups of rows that appear to be duplicates
    func findDuplicates(threshold: Double = 0.8) -> [[StagingFoodRow]] {
        let allRows = getRows(offset: 0, limit: 500000)  // Load all for comparison
        var duplicateGroups: [[StagingFoodRow]] = []
        var processedIds = Set<Int>()

        for row in allRows {
            if processedIds.contains(row.id) { continue }

            var group = [row]
            processedIds.insert(row.id)

            for other in allRows {
                if processedIds.contains(other.id) { continue }

                // Check if duplicate
                if isDuplicate(row, other, threshold: threshold) {
                    group.append(other)
                    processedIds.insert(other.id)
                }
            }

            if group.count > 1 {
                duplicateGroups.append(group)
            }
        }

        return duplicateGroups
    }

    /// Check if two rows are likely duplicates
    private func isDuplicate(_ a: StagingFoodRow, _ b: StagingFoodRow, threshold: Double) -> Bool {
        // 1. Exact barcode match (highest priority)
        if !a.barcode.isEmpty && !b.barcode.isEmpty {
            if a.barcode == b.barcode {
                return true
            }
            // Different barcodes = definitely different products
            return false
        }

        // 2. Compare brand + name with fuzzy matching
        let brandA = FuzzyMatcher.normalize(a.brand)
        let brandB = FuzzyMatcher.normalize(b.brand)
        let nameA = FuzzyMatcher.normalize(a.name)
        let nameB = FuzzyMatcher.normalize(b.name)

        // If brands are very different, probably not duplicates
        if !brandA.isEmpty && !brandB.isEmpty {
            let brandSimilarity = FuzzyMatcher.similarity(brandA, brandB)
            if brandSimilarity < 0.5 {
                return false
            }
        }

        // Check name similarity
        let nameSimilarity = FuzzyMatcher.similarity(nameA, nameB)
        if nameSimilarity >= threshold {
            return true
        }

        // Check if one name contains the other (with extra qualifiers)
        if nameA.contains(nameB) || nameB.contains(nameA) {
            // Additional check: similar nutrition values suggest same product
            if abs(a.calories - b.calories) < 10 &&
               abs(a.protein - b.protein) < 2 &&
               abs(a.carbs - b.carbs) < 2 {
                return true
            }
        }

        return false
    }

    /// Find rows with duplicate barcodes
    func findBarcodeduplicates() -> [[StagingFoodRow]] {
        let sql = """
        SELECT barcode FROM staging_foods
        WHERE barcode != '' AND barcode IS NOT NULL
        GROUP BY barcode HAVING COUNT(*) > 1
        """

        var duplicateBarcodes: [String] = []
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                duplicateBarcodes.append(getString(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)

        // Fetch all rows for each duplicate barcode
        var groups: [[StagingFoodRow]] = []
        for barcode in duplicateBarcodes {
            let fetchSql = """
            SELECT id, name, brand, barcode, calories, protein, carbs, fat,
                   saturated_fat, fiber, sugar, sodium, serving_description,
                   serving_size_g, is_per_unit, ingredients, cleaning_status, queue, extra_data
            FROM staging_foods WHERE barcode = ?
            """
            var fetchStmt: OpaquePointer?
            var group: [StagingFoodRow] = []

            if sqlite3_prepare_v2(db, fetchSql, -1, &fetchStmt, nil) == SQLITE_OK {
                sqlite3_bind_text(fetchStmt, 1, barcode, -1, SQLITE_TRANSIENT)
                while sqlite3_step(fetchStmt) == SQLITE_ROW {
                    let row = StagingFoodRow(
                        id: Int(sqlite3_column_int(fetchStmt, 0)),
                        name: getString(fetchStmt, 1),
                        brand: getString(fetchStmt, 2),
                        barcode: getString(fetchStmt, 3),
                        calories: sqlite3_column_double(fetchStmt, 4),
                        protein: sqlite3_column_double(fetchStmt, 5),
                        carbs: sqlite3_column_double(fetchStmt, 6),
                        fat: sqlite3_column_double(fetchStmt, 7),
                        saturatedFat: sqlite3_column_double(fetchStmt, 8),
                        fiber: sqlite3_column_double(fetchStmt, 9),
                        sugar: sqlite3_column_double(fetchStmt, 10),
                        sodium: sqlite3_column_double(fetchStmt, 11),
                        servingDescription: getString(fetchStmt, 12),
                        servingSizeG: sqlite3_column_double(fetchStmt, 13),
                        isPerUnit: sqlite3_column_int(fetchStmt, 14) == 1,
                        ingredients: getString(fetchStmt, 15),
                        cleaningStatus: getString(fetchStmt, 16, default: "pending"),
                        queue: getString(fetchStmt, 17, default: "staging"),
                        extraData: parseExtraData(getString(fetchStmt, 18, default: "{}"))
                    )
                    group.append(row)
                }
            }
            sqlite3_finalize(fetchStmt)

            if group.count > 1 {
                groups.append(group)
            }
        }

        return groups
    }

    /// Get count of duplicate barcodes
    func getDuplicateBarcodeCount() -> Int {
        let sql = """
        SELECT COUNT(*) FROM (
            SELECT barcode FROM staging_foods
            WHERE barcode != '' AND barcode IS NOT NULL
            GROUP BY barcode HAVING COUNT(*) > 1
        )
        """
        var stmt: OpaquePointer?
        var count = 0
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                count = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        return count
    }
}

// MARK: - Fuzzy String Matcher

struct FuzzyMatcher {
    /// Normalize string for comparison: lowercase, remove special chars, trim
    static func normalize(_ str: String) -> String {
        let lowercased = str.lowercased()
        // Remove common words that add noise
        let stopWords = ["the", "a", "an", "and", "&", "with", "w/", "in", "of", "-", "'s"]
        var cleaned = lowercased
        for word in stopWords {
            cleaned = cleaned.replacingOccurrences(of: " \(word) ", with: " ")
            cleaned = cleaned.replacingOccurrences(of: "\(word) ", with: "")
        }
        // Remove non-alphanumeric (except spaces)
        cleaned = cleaned.filter { $0.isLetter || $0.isNumber || $0 == " " }
        // Collapse multiple spaces
        while cleaned.contains("  ") {
            cleaned = cleaned.replacingOccurrences(of: "  ", with: " ")
        }
        return cleaned.trimmingCharacters(in: .whitespaces)
    }

    /// Calculate Levenshtein distance between two strings
    static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1)
        let b = Array(s2)
        let m = a.count
        let n = b.count

        if m == 0 { return n }
        if n == 0 { return m }

        var dp = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m { dp[i][0] = i }
        for j in 0...n { dp[0][j] = j }

        for i in 1...m {
            for j in 1...n {
                if a[i-1] == b[j-1] {
                    dp[i][j] = dp[i-1][j-1]
                } else {
                    dp[i][j] = min(dp[i-1][j-1], dp[i-1][j], dp[i][j-1]) + 1
                }
            }
        }

        return dp[m][n]
    }

    /// Calculate similarity between 0 and 1 (1 = identical)
    static func similarity(_ s1: String, _ s2: String) -> Double {
        if s1.isEmpty && s2.isEmpty { return 1.0 }
        if s1.isEmpty || s2.isEmpty { return 0.0 }

        let maxLen = max(s1.count, s2.count)
        let distance = levenshteinDistance(s1, s2)
        return 1.0 - (Double(distance) / Double(maxLen))
    }

    /// Check if strings are similar enough (convenience method)
    static func areSimilar(_ s1: String, _ s2: String, threshold: Double = 0.8) -> Bool {
        return similarity(normalize(s1), normalize(s2)) >= threshold
    }
}

// MARK: - Barcode Filter Enum

enum BarcodeFilter: String, CaseIterable {
    case all = "All"
    case ukOnly = "UK Only"
    case nonUK = "Non-UK"
    case noBarcode = "No Barcode"

    var icon: String {
        switch self {
        case .all: return "globe"
        case .ukOnly: return "flag.fill"
        case .nonUK: return "globe.europe.africa"
        case .noBarcode: return "barcode"
        }
    }

    var description: String {
        switch self {
        case .all: return "Show all products"
        case .ukOnly: return "UK barcodes (50xxx) + UK retailers"
        case .nonUK: return "International barcodes"
        case .noBarcode: return "Products without barcodes"
        }
    }
}

// MARK: - Sort Column Enum

enum SortColumn: String, CaseIterable {
    case id = "id"
    case name = "name"
    case brand = "brand"
    case barcode = "barcode"
    case servingDesc = "serving_description"
    case servingSize = "serving_size_g"
    case calories = "calories"
    case protein = "protein"
    case carbs = "carbs"
    case fat = "fat"
    case saturatedFat = "saturated_fat"
    case sugar = "sugar"
    case fiber = "fiber"
    case sodium = "sodium"
    case ingredients = "ingredients"

    var displayName: String {
        switch self {
        case .id: return "ID"
        case .name: return "Name"
        case .brand: return "Brand"
        case .barcode: return "Barcode"
        case .servingDesc: return "Serving Desc"
        case .servingSize: return "Size(g)"
        case .calories: return "Cal"
        case .protein: return "Prot"
        case .carbs: return "Carbs"
        case .fat: return "Fat"
        case .saturatedFat: return "SatF"
        case .sugar: return "Sugar"
        case .fiber: return "Fiber"
        case .sodium: return "Na"
        case .ingredients: return "Ingredients"
        }
    }

    var width: CGFloat {
        switch self {
        case .id: return 50
        case .name: return 180
        case .brand: return 100
        case .barcode: return 110
        case .servingDesc: return 100
        case .servingSize: return 55
        case .calories: return 45
        case .protein: return 45
        case .carbs: return 45
        case .fat: return 45
        case .saturatedFat: return 45
        case .sugar: return 45
        case .fiber: return 45
        case .sodium: return 45
        case .ingredients: return 150
        }
    }

    var alignment: Alignment {
        switch self {
        case .name, .brand, .barcode, .servingDesc, .ingredients:
            return .leading
        default:
            return .trailing
        }
    }

    // Default column order for display
    static var defaultOrder: [SortColumn] {
        [.name, .brand, .barcode, .servingDesc, .servingSize, .calories, .protein, .carbs, .fat, .saturatedFat, .sugar, .fiber, .sodium, .ingredients]
    }
}

// MARK: - Data Filter Preset Enum

enum DataFilterPreset: String, CaseIterable {
    case all = "All Data"
    // Cleaning status filters
    case cleaned = "✓ Cleaned"
    case pendingClean = "Pending Clean"
    case cleaningError = "Clean Errors"
    // Data quality filters
    case noCalories = "No Calories"
    case noProtein = "No Protein"
    case noCarbs = "No Carbs"
    case noFat = "No Fat"
    case missingMacros = "Missing Macros"
    case noName = "No Name"
    case noBrand = "No Brand"
    case noIngredients = "No Ingredients"
    case noServing = "No Serving Info"
    case hasAllData = "Complete Data"
    case zeroNutrition = "Zero Nutrition"

    var icon: String {
        switch self {
        case .all: return "tray.full"
        case .cleaned: return "checkmark.seal.fill"
        case .pendingClean: return "clock"
        case .cleaningError: return "exclamationmark.triangle.fill"
        case .noCalories: return "flame.fill"
        case .noProtein: return "leaf.fill"
        case .noCarbs: return "drop.fill"
        case .noFat: return "circle.fill"
        case .missingMacros: return "exclamationmark.triangle.fill"
        case .noName: return "textformat"
        case .noBrand: return "building.2"
        case .noIngredients: return "list.bullet"
        case .noServing: return "scalemass"
        case .hasAllData: return "checkmark.circle.fill"
        case .zeroNutrition: return "0.circle"
        }
    }

    var sqlCondition: String {
        switch self {
        case .all: return "1=1"
        case .cleaned: return "cleaning_status = 'cleaned'"
        case .pendingClean: return "cleaning_status = 'pending' OR cleaning_status IS NULL"
        case .cleaningError: return "cleaning_status = 'error'"
        case .noCalories: return "(calories IS NULL OR calories = 0)"
        case .noProtein: return "(protein IS NULL OR protein = 0)"
        case .noCarbs: return "(carbs IS NULL OR carbs = 0)"
        case .noFat: return "(fat IS NULL OR fat = 0)"
        case .missingMacros: return "(calories IS NULL OR calories = 0 OR protein IS NULL OR carbs IS NULL OR fat IS NULL)"
        case .noName: return "(name IS NULL OR name = '')"
        case .noBrand: return "(brand IS NULL OR brand = '')"
        case .noIngredients: return "(ingredients IS NULL OR ingredients = '')"
        case .noServing: return "(serving_description IS NULL OR serving_description = '') AND (serving_size_g IS NULL OR serving_size_g = 0)"
        case .hasAllData: return "name != '' AND calories > 0 AND protein >= 0 AND carbs >= 0 AND fat >= 0 AND ingredients != ''"
        case .zeroNutrition: return "calories = 0 AND protein = 0 AND carbs = 0 AND fat = 0"
        }
    }
}

// MARK: - Staging Food Row Model

struct StagingFoodRow: Identifiable {
    let id: Int
    var name: String
    var brand: String
    var barcode: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var saturatedFat: Double
    var fiber: Double
    var sugar: Double
    var sodium: Double
    var servingDescription: String
    var servingSizeG: Double
    var isPerUnit: Bool
    var ingredients: String
    var cleaningStatus: String
    var queue: String  // "staging" or "ready"
    var extraData: [String: String]  // All other CSV columns

    // Check if barcode is from UK (including supermarket own-brands)
    var isUKBarcode: Bool {
        guard !barcode.isEmpty else { return false }
        let bc = barcode.trimmingCharacters(in: .whitespaces)

        // UK GS1 prefix: 50
        if bc.hasPrefix("50") { return true }

        // UK supermarket own-brand prefixes
        let ukPrefixes = [
            "5000", "5010", "5011", "5012", "5013", "5014", "5015", "5016", "5017", "5018", "5019",  // UK general
            "5051", "5052", "5053", "5054",  // Asda
            "5057",  // Sainsbury's
            "5000119",  // Tesco
            "5000128",  // Tesco
            "5000157",  // Morrisons
            "5010081",  // Waitrose
            "5010251",  // Waitrose
            "5018374",  // M&S
            "00",  // M&S internal codes
            "01",  // Sainsbury's internal
            "02",  // Co-op internal
            "20", "21", "22", "23", "24", "25", "26", "27", "28", "29",  // In-store/variable weight
            "4088600",  // Aldi
            "4056489",  // Lidl
            "4088660",  // Aldi
        ]

        for prefix in ukPrefixes {
            if bc.hasPrefix(prefix) { return true }
        }

        return false
    }

    // Get value from extra data by key (case-insensitive)
    func getExtra(_ key: String) -> String {
        // Try exact match first
        if let val = extraData[key], !val.isEmpty { return val }
        // Try lowercase match
        let lowerKey = key.lowercased()
        for (k, v) in extraData {
            if k.lowercased() == lowerKey && !v.isEmpty { return v }
        }
        return ""
    }

    func toFoodItem() -> FoodItem {
        FoodItem(
            objectID: UUID().uuidString,
            name: name,
            brand: brand.isEmpty ? nil : brand,
            barcode: barcode.isEmpty ? nil : barcode,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            saturatedFat: saturatedFat > 0 ? saturatedFat : nil,
            servingDescription: servingDescription.isEmpty ? nil : servingDescription,
            servingSizeG: servingSizeG > 0 ? servingSizeG : nil,
            isPerUnit: isPerUnit,
            ingredientsText: ingredients.isEmpty ? nil : ingredients,
            isVerified: false,
            source: "import_clean_center"
        )
    }
}

// MARK: - Import Clean Center View

struct ImportCleanCenterView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var algoliaService: AlgoliaService
    @EnvironmentObject var claudeService: ClaudeService
    @Environment(\.openSettings) private var openSettings

    // Data state
    @State private var totalRowCount: Int = 0
    @State private var cleanedCount: Int = 0
    @State private var filteredRowCount: Int = 0

    // Filter state
    @State private var barcodeFilter: BarcodeFilter = .all
    @State private var searchQuery: String = ""
    @State private var isSearching: Bool = false
    @State private var searchTask: Task<Void, Never>?

    // Pagination
    @State private var currentPage: Int = 0
    @State private var displayedRows: [StagingFoodRow] = []
    @State private var selectedIds: Set<Int> = []
    @State private var pageSize: Int = 200  // Reduced for better memory usage
    @State private var isLoadingData = false
    @State private var jumpToPageText: String = ""
    @State private var listScrollPosition: Double = 0  // For the vertical scroll slider

    private let pageSizeOptions = [100, 200, 500, 1000, 2000]  // Capped at 2000 for memory

    // Dynamic extra columns discovered from data
    @State private var availableExtraColumns: [String] = []
    @State private var visibleExtraColumns: Set<String> = []

    // Import state
    @State private var isImporting = false
    @State private var importProgress: Double = 0
    @State private var importStatusText: String = ""
    @State private var importedRowCount: Int = 0
    @State private var lastImportCount: Int = 0
    @State private var showImportSuccess = false
    @State private var importStopped = false
    @State private var skippedDuplicates: Int = 0
    @State private var skippedByFilter: Int = 0
    @State private var skipDuplicateCheck = false  // For faster large imports

    // Import filters - only import products matching these criteria
    @State private var importFilterUKOnly = true
    @State private var importFilterHasName = true
    @State private var importFilterHasIngredients = true
    @State private var importFilterHasNutrition = true

    // Bulk delete state
    @State private var bulkDeleteResult: String = ""
    @State private var showBulkDeleteResult = false
    @State private var isBulkDeleting = false
    @State private var bulkDeleteProgress: Int = 0  // Items deleted so far
    @State private var bulkDeleteTarget: Int = 0    // Total items to delete
    @State private var bulkDeleteCancelled = false  // Allow cancellation
    @State private var isLoadingBulkCounts = true
    @State private var countNonUKItems: Int = 0           // Based on origin field
    @State private var countNonUKBarcodesItems: Int = 0   // Based on barcode prefix
    @State private var countNoIngredientsItems: Int = 0
    @State private var countIncompleteMacrosItems: Int = 0
    @State private var countNonLatinScriptItems: Int = 0  // Arabic, Chinese, etc.
    @State private var countZeroCaloriesItems: Int = 0
    @State private var countJunkIngredientsItems: Int = 0  // "none", "n/a", etc.
    @State private var countNonEnglishItems: Int = 0       // Foreign language ingredients
    @State private var countNoServingSizeItems: Int = 0    // Missing serving size
    @State private var countWithServingSizeItems: Int = 0  // Has serving size (for stats)
    @State private var isAutoTidying = false               // Title Case operation in progress

    // Import preview state
    @State private var showingImportPreview = false
    @State private var previewFileURL: URL?
    @State private var previewDelimiter: Character = ","
    @State private var previewDetectedColumns: [(field: String, mappedTo: String?)] = []
    @State private var previewTotalColumns: Int = 0
    @State private var previewSampleRows: [[String: String]] = []

    // Cleaning state
    @State private var isCleaning = false
    @State private var cleaningProgress: Double = 0
    @State private var cleaningStatusText: String = ""
    @State private var cleaningError: String?
    @State private var showCleaningError = false
    @State private var shouldStopCleaning = false

    // Cleaning options
    @State private var cleanOptionUKSpelling = true
    @State private var cleanOptionTitleCase = true
    @State private var cleanOptionBrands = true
    @State private var cleanOptionDeleteForeign = true  // DELETE items with foreign text
    @State private var cleanOptionFixTypos = true
    @State private var cleanOptionCleanIngredients = true  // Fix ingredients spelling & capitalization
    @State private var cleanOptionSmartValidation = true  // DELETE items with undefined, null, junk data
    @State private var cleanOptionVerifyBarcodes = true   // Verify suspicious barcodes online

    private var hasAnyCleaningOption: Bool {
        cleanOptionUKSpelling || cleanOptionTitleCase || cleanOptionBrands ||
        cleanOptionDeleteForeign || cleanOptionFixTypos || cleanOptionCleanIngredients ||
        cleanOptionSmartValidation || cleanOptionVerifyBarcodes
    }

    // Barcode enrichment state
    @State private var isEnrichingFromBarcodes = false
    @State private var barcodeEnrichmentProgress: Double = 0
    @State private var barcodeEnrichmentTotal: Int = 0
    @State private var barcodeEnrichmentProcessed: Int = 0
    @State private var barcodeEnrichmentEnriched: Int = 0
    @State private var barcodeEnrichmentFailed: Int = 0
    @State private var countNeedingEnrichment: Int = 0

    // Saving state
    @State private var isSaving = false
    @State private var saveProgress: Double = 0

    // UI state
    @State private var showingFileImporter = false
    @State private var showingClearConfirm = false
    @State private var importError: String?
    @State private var saveError: String?
    @State private var selectedDatabase: String = "foods"
    @State private var newDatabaseName: String = ""
    @State private var showingCreateDatabase = false
    @State private var availableDatabases: [String] = ["foods"]

    // Deduplication state
    @State private var showingDuplicates = false
    @State private var duplicateGroups: [[StagingFoodRow]] = []
    @State private var isFindingDuplicates = false
    @State private var duplicateCount: Int = 0

    // Editing
    @State private var editingRow: StagingFoodRow?

    // Sorting
    @State private var sortColumn: SortColumn = .id
    @State private var sortAscending: Bool = false

    // Column order (draggable)
    @State private var columnOrder: [SortColumn] = SortColumn.defaultOrder
    @State private var draggedColumn: SortColumn?

    // Data filter presets
    @State private var dataFilterPreset: DataFilterPreset = .all

    // Tab selection
    @State private var selectedTab: ImportCleanTab = .staging

    // Queue counts
    @State private var stagingCount: Int = 0
    @State private var readyCount: Int = 0

    private let stagingDb = StagingDatabase.shared

    // Comprehensive column name mappings for any data source
    // Includes OpenFoodFacts exact column names with hyphens
    private let columnMappings: [String: [String]] = [
        "name": [
            // OpenFoodFacts
            "product_name", "abbreviated_product_name", "generic_name",
            // Common variations
            "name", "product name", "productname", "item", "item_name",
            "food", "food_name", "foodname", "title", "description", "product",
            "product_name_en", "product_name_uk", "generic_name_en"
        ],
        "brand": [
            // OpenFoodFacts
            "brands", "brands_tags", "brands_en", "brand_owner",
            // Common variations
            "brand", "brandname", "brand_name", "brand name", "manufacturer",
            "company", "producer", "maker"
        ],
        "barcode": [
            // OpenFoodFacts uses "code"
            "code",
            // Common variations
            "barcode", "ean", "upc", "gtin", "ean13", "upc_code", "barcode_number",
            "ean_13", "upc_a", "product_code", "item_code"
        ],
        "calories": [
            // OpenFoodFacts (with hyphens!)
            "energy-kcal_100g", "energy_100g", "energy-kj_100g",
            // Common variations
            "calories", "cal", "kcal", "energy", "energy_kcal_100g",
            "energy_kcal", "energykcal", "energy (kcal)", "kcal_100g",
            "calories_100g", "nrg", "energy-kcal"
        ],
        "protein": [
            // OpenFoodFacts
            "proteins_100g",
            // Common variations
            "protein", "prot", "proteins", "protein_100g", "protein (g)",
            "protein_g", "protein_value", "proteins_value"
        ],
        "carbs": [
            // OpenFoodFacts
            "carbohydrates_100g", "carbohydrates-total_100g",
            // Common variations
            "carbs", "carbohydrates", "carbs_100g", "carbohydrate",
            "carbohydrate_100g", "carbs (g)", "total_carbohydrate", "carbohydrate_g",
            "carbohydrates_value", "carbohydrate_value"
        ],
        "fat": [
            // OpenFoodFacts
            "fat_100g",
            // Common variations
            "fat", "fats", "total_fat", "fat (g)", "lipid", "lipids",
            "fat_g", "fat_value", "total_fat_g"
        ],
        "saturatedFat": [
            // OpenFoodFacts (with hyphen!)
            "saturated-fat_100g",
            // Common variations
            "saturatedfat", "sat", "saturated_fat", "saturated fat",
            "sat_fat", "satfat", "saturated_fat_100g", "saturated", "saturated-fat",
            "saturated_fat_g", "saturated_fat_value"
        ],
        "fiber": [
            // OpenFoodFacts
            "fiber_100g",
            // Common variations
            "fiber", "fibre", "fibre_100g", "dietary_fiber", "dietary_fibre",
            "fiber (g)", "fibre (g)", "fiber_g", "fibre_g", "fiber_value", "fibre_value"
        ],
        "sugar": [
            // OpenFoodFacts
            "sugars_100g",
            // Common variations
            "sugar", "sugars", "sugar_100g", "total_sugars", "sugar (g)",
            "sugars_g", "sugar_g", "sugars_value", "sugar_value"
        ],
        "sodium": [
            // OpenFoodFacts (has both salt and sodium!)
            "sodium_100g", "salt_100g",
            // Common variations
            "sodium", "na", "salt", "sodium_mg", "sodium (mg)",
            "sodium_g", "sodium_value", "salt_value", "salt_g"
        ],
        "servingDescription": [
            // OpenFoodFacts
            "serving_size", "quantity",
            // Common variations
            "serving", "servingdescription", "serving size", "portion",
            "portion_size", "serving_description", "serving_size_text", "serving_quantity_text",
            "serving_size_string"
        ],
        "servingSizeG": [
            // OpenFoodFacts
            "serving_quantity", "product_quantity",
            // Common variations
            "servingsizeg", "serving size g", "serving_size_g",
            "portion_g", "serving_g", "serving_weight", "serving_size_grams",
            "serving_weight_grams", "serving_amount"
        ],
        "ingredients": [
            // OpenFoodFacts
            "ingredients_text",
            // Common variations
            "ingredients", "ingredientstext", "ingredients text",
            "ingredient_list", "ingredients_list", "ingredients_en", "ingredients_text_en",
            "ingredients_text_with_allergens", "ingredients_text_uk"
        ]
    ]

    enum ImportCleanTab: String, CaseIterable {
        case staging = "Staging"
        case ready = "Ready for Export"
        case importFile = "Import"

        var icon: String {
            switch self {
            case .staging: return "tray.full"
            case .ready: return "arrow.up.circle"
            case .importFile: return "square.and.arrow.down"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                ForEach(ImportCleanTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                        if tab == .staging || tab == .ready {
                            currentPage = 0
                            loadCurrentPage()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                            Text(tab.rawValue)
                            if tab == .staging && stagingCount > 0 {
                                Text("(\(stagingCount))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else if tab == .ready && readyCount > 0 {
                                Text("(\(readyCount))")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                        .foregroundColor(selectedTab == tab ? .accentColor : .primary)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()

                // Quick stats in tab bar
                if totalRowCount > 0 {
                    HStack(spacing: 16) {
                        Label("\(stagingCount) staging", systemImage: "tray")
                            .foregroundColor(.orange)
                        Label("\(readyCount) ready", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .font(.caption)
                    .padding(.trailing, 16)
                }
            }
            .background(Color(nsColor: .controlBackgroundColor))
            Divider()

            // Tab content
            switch selectedTab {
            case .staging:
                queueTabView(queue: "staging")
            case .ready:
                queueTabView(queue: "ready")
            case .importFile:
                importTabView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            loadData()
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.json, .commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .sheet(isPresented: $showingCreateDatabase) {
            createDatabaseSheet
        }
        .sheet(item: $editingRow) { row in
            EditRowSheet(row: row, onSave: { updatedRow in
                stagingDb.updateRow(
                    id: updatedRow.id, name: updatedRow.name, brand: updatedRow.brand,
                    barcode: updatedRow.barcode, calories: updatedRow.calories,
                    protein: updatedRow.protein, carbs: updatedRow.carbs, fat: updatedRow.fat,
                    saturatedFat: updatedRow.saturatedFat, fiber: updatedRow.fiber,
                    sugar: updatedRow.sugar, sodium: updatedRow.sodium,
                    servingDescription: updatedRow.servingDescription,
                    servingSizeG: updatedRow.servingSizeG, isPerUnit: updatedRow.isPerUnit,
                    ingredients: updatedRow.ingredients, cleaningStatus: updatedRow.cleaningStatus
                )
                loadCurrentPage()
                editingRow = nil
            }, onCancel: {
                editingRow = nil
            })
        }
        .alert("Import Error", isPresented: .init(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK") { importError = nil }
        } message: {
            Text(importError ?? "")
        }
        .alert("Clear All Data?", isPresented: $showingClearConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                stagingDb.clearAll()
                loadData()
            }
        } message: {
            Text("This will remove all \(totalRowCount) imported items from staging.")
        }
        .alert("Cleaning Issue", isPresented: $showCleaningError) {
            Button("OK") { cleaningError = nil }
        } message: {
            Text(cleaningError ?? "An unknown error occurred")
        }
        .alert("Bulk Delete Complete", isPresented: $showBulkDeleteResult) {
            Button("OK") { }
        } message: {
            Text(bulkDeleteResult)
        }
        .sheet(isPresented: $showingImportPreview) {
            importPreviewSheet
        }
        .sheet(isPresented: $showingDuplicates) {
            duplicatesSheet
        }
    }

    // MARK: - Duplicates Sheet

    private var duplicatesSheet: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duplicate Groups")
                        .font(.headline)
                    Text("\(duplicateGroups.count) groups found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()

                Button {
                    // Delete all duplicates (keep first in each group)
                    for group in duplicateGroups {
                        deleteAllButFirst(in: group)
                    }
                    duplicateGroups.removeAll()
                    showingDuplicates = false
                } label: {
                    Label("Remove All Duplicates", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(duplicateGroups.isEmpty)

                Button {
                    showingDuplicates = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Duplicate groups list
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(duplicateGroups.enumerated()), id: \.offset) { index, group in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Group \(index + 1)")
                                    .font(.headline)
                                Text("(\(group.count) items)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button {
                                    deleteAllButFirst(in: group)
                                    duplicateGroups.remove(at: index)
                                    if duplicateGroups.isEmpty {
                                        showingDuplicates = false
                                    }
                                } label: {
                                    Label("Keep First", systemImage: "checkmark")
                                }
                                .buttonStyle(.bordered)
                                .tint(.green)
                            }

                            // Show items in group
                            ForEach(group) { row in
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(row.name.isEmpty ? "(no name)" : row.name)
                                            .lineLimit(1)
                                            .fontWeight(.medium)
                                        Text(row.brand.isEmpty ? "(no brand)" : row.brand)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if !row.barcode.isEmpty {
                                        Text(row.barcode)
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                    Text("\(Int(row.calories)) kcal")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Button {
                                        stagingDb.deleteRow(id: row.id)
                                        if let groupIndex = duplicateGroups.firstIndex(where: { $0.contains(where: { $0.id == row.id }) }) {
                                            duplicateGroups[groupIndex].removeAll(where: { $0.id == row.id })
                                            if duplicateGroups[groupIndex].count <= 1 {
                                                duplicateGroups.remove(at: groupIndex)
                                            }
                                        }
                                        loadData()
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(8)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .cornerRadius(6)
                            }
                        }
                        .padding()
                        .background(Color(nsColor: .windowBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                .padding()
            }
        }
        .frame(width: 700, height: 600)
    }

    // MARK: - Import Preview Sheet

    private var importPreviewSheet: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Import Preview")
                        .font(.headline)
                    if let url = previewFileURL {
                        Text(url.lastPathComponent)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button {
                    showingImportPreview = false
                    previewFileURL?.stopAccessingSecurityScopedResource()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // File info
                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Format Detected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack(spacing: 6) {
                                Image(systemName: previewDelimiter == "\t" ? "arrow.right.arrow.left" : "comma")
                                Text(previewDelimiter == "\t" ? "TAB-separated (TSV)" : "Comma-separated (CSV)")
                                    .fontWeight(.medium)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Columns")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(previewTotalColumns)")
                                .fontWeight(.medium)
                        }

                        let mappedCount = previewDetectedColumns.filter { $0.mappedTo != nil }.count
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Columns Mapped")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack(spacing: 4) {
                                Text("\(mappedCount) of \(previewDetectedColumns.count)")
                                    .fontWeight(.medium)
                                if mappedCount == previewDetectedColumns.count {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else if mappedCount > 0 {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.orange)
                                } else {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)

                    // Column mappings
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Column Mappings")
                            .font(.headline)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(previewDetectedColumns, id: \.field) { col in
                                HStack(spacing: 6) {
                                    Image(systemName: col.mappedTo != nil ? "checkmark.circle.fill" : "xmark.circle")
                                        .foregroundColor(col.mappedTo != nil ? .green : .secondary)
                                        .font(.caption)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(col.field)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        if let mapped = col.mappedTo {
                                            Text("→ \(mapped)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        } else {
                                            Text("not found")
                                                .font(.caption2)
                                                .foregroundColor(.red)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(8)
                                .background(col.mappedTo != nil ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                                .cornerRadius(6)
                            }
                        }
                    }

                    // Sample data
                    if !previewSampleRows.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sample Data (first \(previewSampleRows.count) rows)")
                                .font(.headline)

                            ForEach(0..<previewSampleRows.count, id: \.self) { idx in
                                let row = previewSampleRows[idx]
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        if let name = row["name"], !name.isEmpty {
                                            Text(name)
                                                .fontWeight(.medium)
                                                .lineLimit(1)
                                        } else {
                                            Text("(no name)")
                                                .foregroundColor(.secondary)
                                                .italic()
                                        }
                                        Spacer()
                                        if let barcode = row["barcode"], !barcode.isEmpty {
                                            Text(barcode)
                                                .font(.caption)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.blue.opacity(0.15))
                                                .cornerRadius(4)
                                        }
                                    }
                                    HStack(spacing: 12) {
                                        if let brand = row["brand"], !brand.isEmpty {
                                            Label(brand, systemImage: "building.2")
                                        }
                                        if let cal = row["calories"], !cal.isEmpty {
                                            Label("\(cal) kcal", systemImage: "flame")
                                        }
                                        if let prot = row["protein"], !prot.isEmpty {
                                            Text("P:\(prot)g")
                                        }
                                        if let carbs = row["carbs"], !carbs.isEmpty {
                                            Text("C:\(carbs)g")
                                        }
                                        if let fat = row["fat"], !fat.isEmpty {
                                            Text("F:\(fat)g")
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
            }

            Divider()

            // Actions
            HStack {
                Button("Cancel") {
                    showingImportPreview = false
                    previewFileURL?.stopAccessingSecurityScopedResource()
                }
                .keyboardShortcut(.escape)

                Spacer()

                // Import options
                VStack(alignment: .leading, spacing: 4) {
                    Text("Import Filters")
                        .font(.caption)
                        .fontWeight(.semibold)

                    Toggle("UK Only", isOn: $importFilterUKOnly)
                        .toggleStyle(.checkbox)
                        .font(.caption)
                        .help("Only import products sold in United Kingdom")

                    Toggle("Has Name", isOn: $importFilterHasName)
                        .toggleStyle(.checkbox)
                        .font(.caption)
                        .help("Only import products with a name")

                    Toggle("Has Ingredients", isOn: $importFilterHasIngredients)
                        .toggleStyle(.checkbox)
                        .font(.caption)
                        .help("Only import products with ingredients listed")

                    Toggle("Has Nutrition", isOn: $importFilterHasNutrition)
                        .toggleStyle(.checkbox)
                        .font(.caption)
                        .help("Only import products with calorie data")

                    Divider()

                    Toggle("Fast Import", isOn: $skipDuplicateCheck)
                        .toggleStyle(.checkbox)
                        .font(.caption)
                        .help("Skip duplicate check for faster large imports")
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)

                Spacer()

                let mappedCount = previewDetectedColumns.filter { $0.mappedTo != nil }.count

                if mappedCount == 0 {
                    Text("No columns could be mapped!")
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button {
                    showingImportPreview = false
                    if let url = previewFileURL {
                        startStreamingImport(url: url)
                    }
                } label: {
                    Label("Start Import", systemImage: "arrow.down.doc")
                }
                .buttonStyle(.borderedProminent)
                .disabled(mappedCount == 0)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(width: 700, height: 600)
    }

    // MARK: - Deduplication

    private func findBarcodeDuplicates() {
        isFindingDuplicates = true
        Task {
            let db = StagingDatabase.shared
            let groups = await Task.detached(priority: .userInitiated) {
                db.findBarcodeduplicates()
            }.value
            await MainActor.run {
                duplicateGroups = groups
                isFindingDuplicates = false
                if !groups.isEmpty {
                    showingDuplicates = true
                }
            }
        }
    }

    private func findFuzzyDuplicates() {
        isFindingDuplicates = true
        Task {
            let db = StagingDatabase.shared
            let groups = await Task.detached(priority: .userInitiated) {
                db.findDuplicates(threshold: 0.85)
            }.value
            await MainActor.run {
                duplicateGroups = groups
                isFindingDuplicates = false
                if !groups.isEmpty {
                    showingDuplicates = true
                }
            }
        }
    }

    private func deleteAllButFirst(in group: [StagingFoodRow]) {
        guard group.count > 1 else { return }
        let idsToDelete = group.dropFirst().map { $0.id }
        stagingDb.deleteRows(ids: Array(idsToDelete))
        loadData()
    }

    // MARK: - Data Loading

    private func loadData() {
        isLoadingData = true
        // DON'T load bulk counts on initial load - they're too slow for 2M rows
        // User can manually refresh counts when they need them
        let db = StagingDatabase.shared

        // Load essential counts and data FAST (user sees results immediately)
        Task.detached(priority: .userInitiated) {
            // Quick counts only - these are fast with indexes
            let total = db.getTotalCount()
            let staging = db.getQueueCount(queue: "staging")
            let ready = db.getQueueCount(queue: "ready")

            await MainActor.run {
                totalRowCount = total
                stagingCount = staging
                readyCount = ready
                currentPage = 0
            }

            // Load the actual data rows IMMEDIATELY
            await loadCurrentPageAsync()
        }
    }

    private func updateFilteredCount() {
        Task.detached(priority: .userInitiated) {
            await updateFilteredCountAsync()
        }
    }

    private func updateFilteredCountAsync() async {
        let queue = await MainActor.run { selectedTab == .ready ? "ready" : "staging" }
        let filter = await MainActor.run { barcodeFilter }
        let dataFilter = await MainActor.run { dataFilterPreset }
        let db = StagingDatabase.shared
        let count = db.getFilteredCount(queue: queue, barcodeFilter: filter, dataFilter: dataFilter)
        await MainActor.run {
            filteredRowCount = count
        }
    }

    private func loadCurrentPage() {
        isLoadingData = true
        listScrollPosition = 0  // Reset scroll position when loading new page
        Task.detached(priority: .userInitiated) {
            await loadCurrentPageAsync()
        }
    }

    private func loadCurrentPageAsync() async {
        // Gather all UI state in a single MainActor call for efficiency
        let (page, size, queue, sort, asc, filter, dataFilter) = await MainActor.run {
            (currentPage,
             pageSize,
             selectedTab == .ready ? "ready" : "staging",
             sortColumn,
             sortAscending,
             barcodeFilter,
             dataFilterPreset)
        }
        let offset = page * size

        let db = StagingDatabase.shared

        print("[LoadPage] START - page \(page), offset \(offset), limit \(size), queue=\(queue)")

        // Run database query - THIS IS THE ONLY THING WE WAIT FOR
        let rows = db.getRowsSorted(
            offset: offset,
            limit: size,
            sortColumn: sort,
            ascending: asc,
            queue: queue,
            barcodeFilter: filter,
            dataFilter: dataFilter
        )

        print("[LoadPage] GOT \(rows.count) rows - updating UI NOW")

        // Discover available extra columns from loaded data (limit to first 50 rows for speed)
        var extraKeys = Set<String>()
        for row in rows.prefix(50) {
            for key in row.extraData.keys {
                extraKeys.insert(key)
            }
        }
        let sortedExtraKeys = extraKeys.sorted()

        // Update UI IMMEDIATELY with the rows - don't wait for counts!
        await MainActor.run {
            displayedRows = rows
            availableExtraColumns = sortedExtraKeys
            isLoadingData = false
            print("[LoadPage] UI DONE - \(rows.count) rows displayed")
        }

        // Queue counts run AFTER UI is updated (non-blocking)
        let cleaned = db.getCleanedCount()
        let stagingQueueCount = db.getQueueCount(queue: "staging")
        let readyQueueCount = db.getQueueCount(queue: "ready")

        await MainActor.run {
            cleanedCount = cleaned
            stagingCount = stagingQueueCount
            readyCount = readyQueueCount
        }
    }

    // MARK: - Bulk Delete Helpers

    private func refreshBulkDeleteCounts() {
        isLoadingBulkCounts = true
        let db = StagingDatabase.shared
        // Run in BACKGROUND priority - these are expensive operations
        Task.detached(priority: .background) {
            // Fast counts (use indexes)
            let nonUKBarcodes = db.countNonUKBarcodes()
            let noIngredients = db.countNoIngredients()
            let incompleteMacros = db.countIncompleteMacros()
            let zeroCalories = db.countZeroCalories()
            let noServing = db.countNoServingSize()
            let withServing = db.countWithServingSize()

            // Slower counts (LIKE queries but still SQL)
            let nonUK = db.countNonUK()
            let junkIngredients = db.countJunkIngredients()
            let nonEnglish = db.countNonEnglishIngredients()

            // SKIP countNonLatinScript() - it's TOO SLOW (iterates all rows in Swift)
            // Estimate: use sample of 1000 rows and extrapolate
            let nonLatinEstimate = db.estimateNonLatinCount(sampleSize: 1000)

            await MainActor.run {
                countNonUKItems = nonUK
                countNonUKBarcodesItems = nonUKBarcodes
                countNoIngredientsItems = noIngredients
                countIncompleteMacrosItems = incompleteMacros
                countZeroCaloriesItems = zeroCalories
                countJunkIngredientsItems = junkIngredients
                countNonEnglishItems = nonEnglish
                countNonLatinScriptItems = nonLatinEstimate
                countNoServingSizeItems = noServing
                countWithServingSizeItems = withServing
                isLoadingBulkCounts = false
            }
        }
    }

    private func performBulkDelete(action: @escaping () -> Int, description: @escaping () -> String) {
        isBulkDeleting = true
        Task.detached(priority: .userInitiated) {
            let deleted = action()
            await MainActor.run {
                isBulkDeleting = false
                bulkDeleteResult = "Deleted \(deleted) \(description())"
                showBulkDeleteResult = true
                loadData()
                refreshBulkDeleteCounts()
            }
        }
    }

    /// Thread-safe cancellation token for bulk deletes
    private class BulkDeleteCancellationToken: @unchecked Sendable {
        private var _isCancelled = false
        private let lock = NSLock()

        var isCancelled: Bool {
            lock.lock()
            defer { lock.unlock() }
            return _isCancelled
        }

        func cancel() {
            lock.lock()
            _isCancelled = true
            lock.unlock()
        }
    }

    /// Currently active cancellation token
    @State private var activeCancellationToken: BulkDeleteCancellationToken?

    /// Perform bulk delete with live progress updates - pages decrease in real-time!
    private func performBatchedBulkDelete(
        initialCount: Int,
        description: String,
        batchedAction: @escaping (@escaping (_ deleted: Int, _ remaining: Int) -> Bool) -> Int
    ) {
        isBulkDeleting = true
        bulkDeleteProgress = 0
        bulkDeleteTarget = initialCount
        bulkDeleteCancelled = false

        let db = StagingDatabase.shared
        let descriptionCopy = description
        let token = BulkDeleteCancellationToken()
        activeCancellationToken = token

        Task.detached(priority: .userInitiated) {
            let totalDeleted = batchedAction { deleted, remaining in
                // Update UI after each batch (fire and forget)
                Task { @MainActor in
                    bulkDeleteProgress = deleted
                    let newTotal = db.getTotalCount()
                    totalRowCount = newTotal
                }

                // Check thread-safe cancellation token
                return !token.isCancelled
            }

            let wasCancelled = token.isCancelled

            await MainActor.run {
                isBulkDeleting = false
                bulkDeleteProgress = 0
                bulkDeleteTarget = 0
                activeCancellationToken = nil
                bulkDeleteResult = wasCancelled
                    ? "Cancelled after \(totalDeleted) \(descriptionCopy)"
                    : "Deleted \(totalDeleted) \(descriptionCopy)"
                showBulkDeleteResult = true
                loadData()
                refreshBulkDeleteCounts()
            }
        }
    }

    /// Cancel the current bulk delete operation
    private func cancelBulkDelete() {
        activeCancellationToken?.cancel()
        bulkDeleteCancelled = true
    }

    @ViewBuilder
    private func bulkDeleteButton(title: String, count: Int, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                Spacer()
                Text("\(count.formatted())")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(count > 0 ? Color.red.opacity(0.2) : Color.gray.opacity(0.2))
                    .foregroundColor(count > 0 ? .red : .gray)
                    .cornerRadius(4)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(count > 0 ? .red : .gray)
        .disabled(count == 0 || isBulkDeleting)
    }

    /// Progress indicator shown during bulk delete
    @ViewBuilder
    private var bulkDeleteProgressView: some View {
        if isBulkDeleting && bulkDeleteTarget > 0 {
            VStack(spacing: 8) {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Deleting...")
                        .font(.headline)
                    Spacer()
                    Button("Cancel") {
                        cancelBulkDelete()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }

                ProgressView(value: Double(bulkDeleteProgress), total: Double(bulkDeleteTarget))
                    .progressViewStyle(.linear)

                HStack {
                    Text("\(bulkDeleteProgress.formatted()) of \(bulkDeleteTarget.formatted()) deleted")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Pages: \(totalPages.formatted())")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }

    private var filteredTotalPages: Int {
        max(1, (filteredRowCount + pageSize - 1) / pageSize)
    }

    // MARK: - Search Functions

    private func performSearch() {
        guard !searchQuery.isEmpty else {
            print("🔍 Staging search: Query empty, clearing search")
            isSearching = false
            loadCurrentPage()
            return
        }

        print("🔍 Staging search: Searching for '\(searchQuery)'")
        isSearching = true
        isLoadingData = true
        let db = StagingDatabase.shared
        let query = searchQuery
        let currentQueue = selectedTab == .ready ? "ready" : "staging"

        Task.detached(priority: .userInitiated) {
            print("🔍 Staging search: Executing SQL search in queue '\(currentQueue)'")
            let results = db.searchRows(query: query, queue: currentQueue, limit: 1000)
            let count = db.countSearchResults(query: query, queue: currentQueue)
            print("🔍 Staging search: Found \(results.count) results, total matching: \(count)")

            if !results.isEmpty {
                let preview = results.prefix(3).map { $0.name }.joined(separator: ", ")
                print("🔍 Staging search: First results: \(preview)")
            }

            await MainActor.run {
                displayedRows = results
                filteredRowCount = count
                isLoadingData = false
                print("🔍 Staging search: UI updated with \(results.count) rows")
            }
        }
    }

    private func clearSearch() {
        print("🔍 Staging search: Clearing search")
        searchTask?.cancel()
        searchTask = nil
        searchQuery = ""
        isSearching = false
        loadCurrentPage()
    }

    // MARK: - Queue Tab View

    private func queueTabView(queue: String) -> some View {
        let isReady = queue == "ready"
        let queueCount = isReady ? readyCount : stagingCount

        return VStack(spacing: 0) {
            // Search bar with live search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(isSearching ? .blue : .secondary)

                TextField("Search by name, brand, barcode, or ingredients...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        // Immediate search on Enter
                        searchTask?.cancel()
                        searchTask = nil
                        print("🔍 Staging: Enter pressed, searching for '\(searchQuery)'")
                        performSearch()
                    }
                    .onChange(of: searchQuery) { _, newValue in
                        // Cancel previous search
                        searchTask?.cancel()

                        if newValue.isEmpty {
                            // Immediately clear if empty
                            isSearching = false
                            loadCurrentPage()
                            return
                        }

                        // Debounced live search - 400ms
                        print("🔍 Staging: searchQuery changed to '\(newValue)', starting debounce")
                        searchTask = Task {
                            do {
                                try await Task.sleep(nanoseconds: 400_000_000) // 400ms
                                if !Task.isCancelled {
                                    print("🔍 Staging: Debounce complete, executing search")
                                    await MainActor.run {
                                        performSearch()
                                    }
                                }
                            } catch {
                                // Task was cancelled
                            }
                        }
                    }

                if isLoadingData && isSearching {
                    ProgressView()
                        .scaleEffect(0.6)
                }

                if !searchQuery.isEmpty {
                    Button {
                        clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Clear search")

                    Button {
                        searchTask?.cancel()
                        searchTask = nil
                        performSearch()
                    } label: {
                        HStack(spacing: 4) {
                            if isLoadingData {
                                ProgressView()
                                    .scaleEffect(0.5)
                            }
                            Text("Search")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }

                if isSearching && !isLoadingData {
                    Text("\(filteredRowCount) results")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .padding(8)
            .background(isSearching ? Color.blue.opacity(0.05) : Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSearching ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .padding(.horizontal, 12)
            .padding(.top, 8)

            // Filter bar - Barcode filters (hidden during search)
            if !isSearching {
                HStack(spacing: 12) {
                    Text("Barcode:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                ForEach(BarcodeFilter.allCases, id: \.self) { filter in
                    Button {
                        barcodeFilter = filter
                        currentPage = 0
                        updateFilteredCount()
                        loadCurrentPage()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: filter.icon)
                            Text(filter.rawValue)
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(barcodeFilter == filter ? Color.accentColor.opacity(0.2) : Color(nsColor: .controlBackgroundColor))
                        .foregroundColor(barcodeFilter == filter ? .accentColor : .primary)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help(filter.description)
                }

                Divider().frame(height: 20)

                // Data quality filters
                Text("Data:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Menu {
                    ForEach(DataFilterPreset.allCases, id: \.self) { preset in
                        Button {
                            dataFilterPreset = preset
                            currentPage = 0
                            updateFilteredCount()
                            loadCurrentPage()
                        } label: {
                            Label(preset.rawValue, systemImage: preset.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: dataFilterPreset.icon)
                        Text(dataFilterPreset.rawValue)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8))
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(dataFilterPreset != .all ? Color.orange.opacity(0.2) : Color(nsColor: .controlBackgroundColor))
                    .foregroundColor(dataFilterPreset != .all ? .orange : .primary)
                    .cornerRadius(6)
                }

                Spacer()

                if barcodeFilter != .all || dataFilterPreset != .all {
                    Text("Showing \(filteredRowCount) of \(queueCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Clear Filters") {
                        barcodeFilter = .all
                        dataFilterPreset = .all
                        currentPage = 0
                        updateFilteredCount()
                        loadCurrentPage()
                    }
                    .font(.caption)
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            }  // End of if !isSearching

            Divider()

            // Data header with pagination
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isReady ? "Ready for Import" : "Staging Area")
                        .font(.headline)
                    if filteredRowCount > 0 {
                        Text("Page \(currentPage + 1) of \(filteredTotalPages)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if filteredRowCount > 0 {
                    // Extra columns menu
                    if !availableExtraColumns.isEmpty {
                        Menu {
                            Text("Extra Columns (\(availableExtraColumns.count) available)")
                                .font(.caption)
                            Divider()
                            ForEach(availableExtraColumns.prefix(50), id: \.self) { col in
                                Button {
                                    if visibleExtraColumns.contains(col) {
                                        visibleExtraColumns.remove(col)
                                    } else {
                                        visibleExtraColumns.insert(col)
                                    }
                                } label: {
                                    HStack {
                                        Text(col)
                                        Spacer()
                                        if visibleExtraColumns.contains(col) {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                            if availableExtraColumns.count > 50 {
                                Divider()
                                Text("...and \(availableExtraColumns.count - 50) more")
                                    .foregroundColor(.secondary)
                            }
                            Divider()
                            Button("Show All") {
                                visibleExtraColumns = Set(availableExtraColumns.prefix(20))
                            }
                            Button("Hide All") {
                                visibleExtraColumns.removeAll()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "tablecells.badge.ellipsis")
                                Text("Columns")
                                if !visibleExtraColumns.isEmpty {
                                    Text("(\(visibleExtraColumns.count))")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .font(.caption)
                        }
                        .menuStyle(.borderlessButton)
                    }

                    // Page size picker
                    HStack(spacing: 4) {
                        Text("Show:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("", selection: $pageSize) {
                            ForEach(pageSizeOptions, id: \.self) { size in
                                Text(size >= 1000 ? "\(size/1000)k" : "\(size)").tag(size)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 80)
                        .onChange(of: pageSize) { _, _ in
                            currentPage = 0
                            loadCurrentPage()
                        }
                    }

                    // Jump to page
                    HStack(spacing: 4) {
                        Text("Go to:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("", text: $jumpToPageText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            .onSubmit {
                                if let page = Int(jumpToPageText), page >= 1, page <= filteredTotalPages {
                                    currentPage = page - 1
                                    loadCurrentPage()
                                }
                                jumpToPageText = ""
                            }
                        Text("/ \(filteredTotalPages)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Page slider for dragging through data
                    if filteredTotalPages > 1 {
                        HStack(spacing: 8) {
                            Text("1")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Slider(
                                value: Binding(
                                    get: { Double(currentPage) },
                                    set: { newValue in
                                        let newPage = Int(newValue.rounded())
                                        if newPage != currentPage {
                                            currentPage = newPage
                                            loadCurrentPage()
                                        }
                                    }
                                ),
                                in: 0...Double(max(1, filteredTotalPages - 1)),
                                step: 1
                            )
                            .frame(width: 200)

                            Text("\(filteredTotalPages)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Pagination controls
                    HStack(spacing: 8) {
                        Button {
                            currentPage = 0
                            loadCurrentPage()
                        } label: {
                            Image(systemName: "chevron.left.2")
                        }
                        .disabled(currentPage == 0)

                        Button {
                            if currentPage > 0 {
                                currentPage -= 1
                                loadCurrentPage()
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .disabled(currentPage == 0)

                        Text("\(currentPage + 1) / \(filteredTotalPages)")
                            .frame(width: 80)
                            .font(.caption)

                        Button {
                            if currentPage < filteredTotalPages - 1 {
                                currentPage += 1
                                loadCurrentPage()
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(currentPage >= filteredTotalPages - 1)

                        Button {
                            currentPage = filteredTotalPages - 1
                            loadCurrentPage()
                        } label: {
                            Image(systemName: "chevron.right.2")
                        }
                        .disabled(currentPage >= filteredTotalPages - 1)
                    }
                    .buttonStyle(.bordered)

                    if !isReady {
                        Button {
                            showingClearConfirm = true
                        } label: {
                            Label("Clear All", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(nsColor: .windowBackgroundColor))
            Divider()

            if queueCount == 0 {
                // Empty state - no data in this queue
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: isReady ? "checkmark.circle" : "tray")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text(isReady ? "No Items Ready" : "Staging Empty")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(isReady ? "Move items from Staging to prepare for import" : "Go to the Import tab to load a CSV or JSON file")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Button {
                        selectedTab = isReady ? .staging : .importFile
                    } label: {
                        Label(isReady ? "Go to Staging" : "Go to Import", systemImage: isReady ? "tray.full" : "square.and.arrow.down")
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredRowCount == 0 {
                // Empty state for current filter - has data but filter returns nothing
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: barcodeFilter.icon)
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No \(barcodeFilter.rawValue) Products")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("No products match the current filter")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Button {
                        barcodeFilter = .all
                        filteredRowCount = totalRowCount
                        loadCurrentPage()
                    } label: {
                        Label("Show All Products", systemImage: "globe")
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HSplitView {
                    tableView
                        .frame(minWidth: 800)
                    rightPanel(queue: queue)
                        .frame(width: 300)
                }
            }
        }
    }

    // MARK: - Import Tab View

    private var importTabView: some View {
        VStack(spacing: 0) {
            if isImporting {
                importProgressView
            } else {
                VStack(spacing: 24) {
                    Spacer()

                    Image(systemName: "square.and.arrow.down.on.square")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    VStack(spacing: 8) {
                        Text("Import Data")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Import CSV or JSON files - handles millions of rows")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }

                    // Import success banner
                    if showImportSuccess {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Successfully imported \(lastImportCount) rows")
                                .fontWeight(.medium)
                            Button("View Data") {
                                selectedTab = .staging
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }

                    // Import error banner
                    if let error = importError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(error)
                            if importedRowCount > 0 {
                                Text("(\(importedRowCount) rows were imported before error)")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }

                    HStack(spacing: 20) {
                        featureCard(icon: "doc.text", color: .blue, title: "CSV", subtitle: "Comma-separated files")
                        featureCard(icon: "curlybraces", color: .purple, title: "JSON", subtitle: "Array of objects")
                    }

                    Button {
                        showingFileImporter = true
                    } label: {
                        Label("Choose File to Import", systemImage: "doc.badge.plus")
                            .frame(width: 200)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    if totalRowCount > 0 {
                        Text("You have \(totalRowCount) rows already staged")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Header View (legacy, keeping for reference)

    private var headerView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Import & Clean Center")
                    .font(.title2)
                    .fontWeight(.bold)

                if totalRowCount > 0 {
                    Text("\(totalRowCount) items in staging • Page \(currentPage + 1) of \(totalPages)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Import data, clean with AI, and save to database")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Import success banner
            if showImportSuccess {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Imported \(lastImportCount) rows")
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.15))
                .cornerRadius(8)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation { showImportSuccess = false }
                    }
                }
            }

            if totalRowCount > 0 {
                // Pagination controls
                HStack(spacing: 8) {
                    Button {
                        if currentPage > 0 {
                            currentPage -= 1
                            loadCurrentPage()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(currentPage == 0)

                    Text("Page \(currentPage + 1)")
                        .frame(width: 70)

                    Button {
                        if currentPage < totalPages - 1 {
                            currentPage += 1
                            loadCurrentPage()
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(currentPage >= totalPages - 1)
                }
                .buttonStyle(.bordered)
            }

            Button {
                showingFileImporter = true
            } label: {
                Label("Import File", systemImage: "doc.badge.plus")
            }
            .buttonStyle(.borderedProminent)

            if totalRowCount > 0 {
                Button {
                    showingClearConfirm = true
                } label: {
                    Label("Clear All", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var totalPages: Int {
        max(1, (totalRowCount + pageSize - 1) / pageSize)
    }

    // MARK: - Import Progress View

    private var importProgressView: some View {
        VStack(spacing: 20) {
            Spacer()

            if importStopped {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
            } else {
                ProgressView()
                    .scaleEffect(1.5)
            }

            Text(importStopped ? "Import Stopped" : "Importing Data...")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                ProgressView(value: importProgress)
                    .frame(width: 400)

                Text(importStatusText)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 16) {
                    Text("\(importedRowCount) rows imported")
                    if skippedDuplicates > 0 {
                        Text("\(skippedDuplicates) duplicates skipped")
                            .foregroundColor(.orange)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            if importStopped {
                Text("Data imported so far has been saved. Continue import to resume.")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)

                Button {
                    importStopped = false
                    isImporting = false
                    lastImportCount = importedRowCount
                    showImportSuccess = importedRowCount > 0
                    loadData()
                } label: {
                    Label("Done", systemImage: "checkmark")
                        .frame(width: 120)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("Streaming directly to disk - memory safe!")
                    .font(.caption)
                    .foregroundColor(.green)

                Button {
                    importStopped = true
                    importStatusText = "Stopping..."
                } label: {
                    Label("Stop Import", systemImage: "stop.fill")
                        .frame(width: 140)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "square.and.arrow.down.on.square")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            VStack(spacing: 8) {
                Text("Import & Clean Your Data")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Import CSV or JSON files with thousands of rows")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 20) {
                featureCard(icon: "doc.text", color: .blue, title: "1. Import", subtitle: "Load CSV/JSON files")
                Image(systemName: "arrow.right").foregroundColor(.secondary)
                featureCard(icon: "wand.and.stars", color: .purple, title: "2. Clean", subtitle: "AI fixes spelling & formatting")
                Image(systemName: "arrow.right").foregroundColor(.secondary)
                featureCard(icon: "checkmark.circle", color: .green, title: "3. Save", subtitle: "Export to Firebase")
            }

            Button {
                showingFileImporter = true
            } label: {
                Label("Import File", systemImage: "doc.badge.plus")
                    .frame(width: 150)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func featureCard(icon: String, color: Color, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 150)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }

    // MARK: - Table View

    private var tableView: some View {
        VStack(spacing: 0) {
            // Horizontal scroll for wide table
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(spacing: 0) {
                    tableHeaderRow
                    Divider()

                    if displayedRows.isEmpty {
                        VStack {
                            Spacer()
                            Text("No data on this page")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .frame(height: 200)
                    } else {
                        HStack(spacing: 0) {
                            ScrollViewReader { proxy in
                                ScrollView(.vertical) {
                                    LazyVStack(spacing: 0) {
                                        ForEach(Array(displayedRows.enumerated()), id: \.element.id) { index, row in
                                            StagingRowView(
                                                row: row,
                                                isSelected: selectedIds.contains(row.id),
                                                columnOrder: columnOrder,
                                                visibleExtraColumns: visibleExtraColumns,
                                                onToggleSelect: {
                                                    if selectedIds.contains(row.id) {
                                                        selectedIds.remove(row.id)
                                                    } else {
                                                        selectedIds.insert(row.id)
                                                    }
                                                },
                                                onEdit: {
                                                    editingRow = row
                                                },
                                                onDelete: {
                                                    stagingDb.deleteRow(id: row.id)
                                                    totalRowCount -= 1
                                                    loadCurrentPage()
                                                }
                                            )
                                            .id(index)
                                            Divider()
                                        }
                                    }
                                }
                                .onChange(of: listScrollPosition) { _, newValue in
                                    let targetIndex = Int(Double(displayedRows.count - 1) * newValue)
                                    if targetIndex >= 0 && targetIndex < displayedRows.count {
                                        withAnimation(.easeOut(duration: 0.1)) {
                                            proxy.scrollTo(targetIndex, anchor: .top)
                                        }
                                    }
                                }
                            }

                            // Vertical scroll slider - always visible when there's data
                            if !displayedRows.isEmpty {
                                VStack(spacing: 8) {
                                    Button {
                                        listScrollPosition = 0
                                    } label: {
                                        Image(systemName: "chevron.up.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Jump to top")

                                    Slider(
                                        value: $listScrollPosition,
                                        in: 0...1
                                    )
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: 250, height: 24)
                                    .frame(height: 250)
                                    .tint(.blue)

                                    Button {
                                        listScrollPosition = 1
                                    } label: {
                                        Image(systemName: "chevron.down.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Jump to bottom")

                                    Spacer()

                                    VStack(spacing: 2) {
                                        Text("\(Int(listScrollPosition * Double(max(1, displayedRows.count - 1))) + 1)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                        Text("of")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text("\(displayedRows.count)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(width: 40)
                                .padding(.vertical, 12)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .frame(minWidth: 1280)
                .overlay {
                    if isLoadingData {
                        ZStack {
                            Color.black.opacity(0.1)
                            VStack(spacing: 8) {
                                ProgressView()
                                Text("Loading...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(.regularMaterial)
                            .cornerRadius(8)
                        }
                    }
                }
            }

            // Status bar
            HStack {
                Text("Showing \(displayedRows.count) of \(filteredRowCount) items")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if !selectedIds.isEmpty {
                    Text("\(selectedIds.count) selected")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }

                // Quick navigation
                HStack(spacing: 8) {
                    Button("First") {
                        currentPage = 0
                        loadCurrentPage()
                    }
                    .buttonStyle(.borderless)
                    .disabled(currentPage == 0)

                    Button("Last") {
                        currentPage = totalPages - 1
                        loadCurrentPage()
                    }
                    .buttonStyle(.borderless)
                    .disabled(currentPage >= totalPages - 1)
                }
                .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor))
        }
    }

    private var tableHeaderRow: some View {
        HStack(spacing: 0) {
            Button {
                if selectedIds.count == displayedRows.count && !displayedRows.isEmpty {
                    selectedIds.removeAll()
                } else {
                    selectedIds = Set(displayedRows.map { $0.id })
                }
            } label: {
                Image(systemName: selectedIds.count == displayedRows.count && !displayedRows.isEmpty ? "checkmark.square.fill" : "square")
            }
            .buttonStyle(.borderless)
            .frame(width: 30)

            // UK indicator column
            Text("UK")
                .frame(width: 30, alignment: .center)
                .foregroundColor(.secondary)

            // Render core columns in user-defined order
            ForEach(columnOrder, id: \.self) { column in
                draggableHeader(column: column)
            }

            // Render selected extra columns
            ForEach(Array(visibleExtraColumns).sorted(), id: \.self) { extraCol in
                Text(extraCol)
                    .lineLimit(1)
                    .frame(width: 100, alignment: .leading)
                    .foregroundColor(.orange)
            }

            Text("Status").frame(width: 70, alignment: .center)
            Text("").frame(width: 60)
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundColor(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func draggableHeader(column: SortColumn) -> some View {
        let isDragging = draggedColumn == column
        let isSorted = sortColumn == column

        return Button {
            if sortColumn == column {
                sortAscending.toggle()
            } else {
                sortColumn = column
                sortAscending = true
            }
            currentPage = 0
            loadCurrentPage()
        } label: {
            HStack(spacing: 3) {
                // Drag handle with better visual
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(isDragging ? .accentColor : .secondary.opacity(0.4))

                Text(column.displayName)
                    .fontWeight(isSorted ? .semibold : .regular)

                if isSorted {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isDragging ? Color.accentColor.opacity(0.15) :
                          isSorted ? Color.accentColor.opacity(0.08) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isDragging ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .frame(width: column.width, alignment: column.alignment)
        .foregroundColor(isSorted ? .accentColor : .secondary)
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isDragging)
        .onDrag {
            draggedColumn = column
            return NSItemProvider(object: column.rawValue as NSString)
        }
        .onDrop(of: [.text], delegate: ColumnDropDelegate(
            item: column,
            items: $columnOrder,
            draggedItem: $draggedColumn
        ))
    }

    // MARK: - Right Panel

    private func rightPanel(queue: String) -> some View {
        let isReady = queue == "ready"
        let queueCount = isReady ? readyCount : stagingCount

        return ScrollView {
            VStack(spacing: 0) {
                // Stats
                VStack(alignment: .leading, spacing: 12) {
                    Text("Summary")
                        .font(.headline)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(queueCount)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text(isReady ? "Ready" : "In Staging")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(selectedIds.count)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("Selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "tray")
                                    .foregroundColor(.orange)
                                Text("\(stagingCount)")
                                    .fontWeight(.semibold)
                            }
                            Text("Staging")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("\(readyCount)")
                                    .fontWeight(.semibold)
                            }
                            Text("Ready")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))

                Divider()

                // Move Between Queues
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "arrow.right.circle")
                            .foregroundColor(.blue)
                        Text("Move Items")
                            .font(.headline)
                    }

                    if isReady {
                        // On Ready tab - allow moving back to staging
                        Button {
                            stagingDb.moveToStaging(ids: Array(selectedIds))
                            selectedIds.removeAll()
                            loadData()
                        } label: {
                            Label("Move to Staging (\(selectedIds.count))", systemImage: "arrow.left.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(selectedIds.isEmpty)
                    } else {
                        // On Staging tab - allow moving to ready
                        Button {
                            stagingDb.moveToReady(ids: Array(selectedIds))
                            selectedIds.removeAll()
                            loadData()
                        } label: {
                            Label("Move to Ready (\(selectedIds.count))", systemImage: "checkmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .disabled(selectedIds.isEmpty)

                        // Move all filtered
                        if barcodeFilter != .all && filteredRowCount > 0 {
                            Button {
                                let allFilteredIds = displayedRows.map { $0.id }
                                stagingDb.moveToReady(ids: allFilteredIds)
                                selectedIds.removeAll()
                                loadData()
                            } label: {
                                Label("Move All \(barcodeFilter.rawValue) (\(filteredRowCount))", systemImage: "checkmark.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.green)
                        }
                    }
                }
                .padding()

                Divider()

                // AI Cleaning (only on staging tab)
                if !isReady {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .foregroundColor(.purple)
                            Text("AI Cleaning")
                                .font(.headline)
                        }

                        // Show configuration status
                        if !claudeService.isConfigured {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Claude API Key Required")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }

                                Text("Set your Anthropic API key to enable AI cleaning features.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Button {
                                    openSettings()
                                } label: {
                                    Label("Open Settings", systemImage: "gear")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(10)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }

                        if isCleaning {
                            VStack(spacing: 12) {
                                ProgressView(value: cleaningProgress)

                                Text(cleaningStatusText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Button {
                                    shouldStopCleaning = true
                                    cleaningStatusText = "Stopping..."
                                } label: {
                                    Label("Stop Cleaning", systemImage: "stop.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                                .disabled(shouldStopCleaning)

                                Text("Progress is saved - you can resume anytime")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            // Cleaning options toggles
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Formatting")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Toggle("UK Spelling (fibre, colour)", isOn: $cleanOptionUKSpelling)
                                    .toggleStyle(.checkbox)
                                Toggle("Title Case Names", isOn: $cleanOptionTitleCase)
                                    .toggleStyle(.checkbox)
                                Toggle("Fix Brand Capitalisation", isOn: $cleanOptionBrands)
                                    .toggleStyle(.checkbox)
                                Toggle("Clean Ingredients (spelling & caps)", isOn: $cleanOptionCleanIngredients)
                                    .toggleStyle(.checkbox)
                                Toggle("Fix Typos", isOn: $cleanOptionFixTypos)
                                    .toggleStyle(.checkbox)

                                Divider()

                                Text("Auto-Delete Bad Data")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Toggle("Smart Validation (undefined, null, junk)", isOn: $cleanOptionSmartValidation)
                                    .toggleStyle(.checkbox)
                                    .foregroundColor(.orange)
                                Toggle("Foreign Text Items", isOn: $cleanOptionDeleteForeign)
                                    .toggleStyle(.checkbox)
                                    .foregroundColor(.orange)

                                Divider()

                                Text("Online Verification")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Toggle("Verify Barcodes (OpenFoodFacts)", isOn: $cleanOptionVerifyBarcodes)
                                    .toggleStyle(.checkbox)
                                    .foregroundColor(.blue)
                            }
                            .font(.caption)

                            Divider()

                            VStack(spacing: 8) {
                                Button {
                                    Task { await cleanSelectedItems() }
                                } label: {
                                    Label("Clean Selected (\(selectedIds.count))", systemImage: "wand.and.stars")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.purple)
                                .disabled(selectedIds.isEmpty || !hasAnyCleaningOption || !claudeService.isConfigured)

                                Button {
                                    Task { await cleanAllPending() }
                                } label: {
                                    Label("Clean All Pending", systemImage: "wand.and.stars")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(stagingCount == cleanedCount || !hasAnyCleaningOption || !claudeService.isConfigured)
                            }
                        }
                    }
                    .padding()

                    Divider()

                    // Barcode Enrichment (No AI - Fast)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "barcode.viewfinder")
                                .foregroundColor(.green)
                            Text("Barcode Enrichment")
                                .font(.headline)
                            Spacer()
                            Text("No AI")
                                .font(.caption2)
                                .foregroundColor(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(4)
                        }

                        Text("Looks up barcodes on OpenFoodFacts & Google to fill in missing names, brands, ingredients, and nutrition data")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if isEnrichingFromBarcodes {
                            VStack(spacing: 8) {
                                ProgressView(value: barcodeEnrichmentProgress)
                                HStack {
                                    Text("Processing \(barcodeEnrichmentProcessed)/\(barcodeEnrichmentTotal)")
                                    Spacer()
                                    Text("Enriched: \(barcodeEnrichmentEnriched)")
                                        .foregroundColor(.green)
                                    Text("Failed: \(barcodeEnrichmentFailed)")
                                        .foregroundColor(.orange)
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)

                                Button("Cancel") {
                                    isEnrichingFromBarcodes = false
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                            }
                        } else {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Items needing data:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(countNeedingEnrichment)")
                                        .fontWeight(.semibold)
                                        .foregroundColor(countNeedingEnrichment > 0 ? .orange : .green)
                                }

                                Button {
                                    Task { await enrichFromBarcodes() }
                                } label: {
                                    Label("Enrich from Barcodes", systemImage: "arrow.down.circle")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                                .disabled(countNeedingEnrichment == 0)

                                Button {
                                    refreshEnrichmentCount()
                                } label: {
                                    Label("Refresh Count", systemImage: "arrow.clockwise")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    .padding()

                    Divider()

                    // Deduplication
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.orange)
                            Text("Find Duplicates")
                                .font(.headline)
                        }

                        Text("Finds duplicate products by barcode or similar name/brand")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if isFindingDuplicates {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            VStack(spacing: 8) {
                                Button {
                                    findBarcodeDuplicates()
                                } label: {
                                    Label("Find Barcode Duplicates", systemImage: "barcode.viewfinder")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(.orange)

                                Button {
                                    findFuzzyDuplicates()
                                } label: {
                                    Label("Find Similar Names (Slow)", systemImage: "text.magnifyingglass")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                            }

                            if !duplicateGroups.isEmpty {
                                Button {
                                    showingDuplicates = true
                                } label: {
                                    Label("View \(duplicateGroups.count) Duplicate Groups", systemImage: "eye")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)
                            }
                        }
                    }
                    .padding()

                    Divider()

                    // Bulk Cleanup - Fast Delete Operations
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "trash.slash")
                                .foregroundColor(.red)
                            Text("Bulk Cleanup")
                                .font(.headline)
                            Spacer()
                            Button {
                                refreshBulkDeleteCounts()
                            } label: {
                                Image(systemName: "arrow.clockwise")
                            }
                            .buttonStyle(.borderless)
                            .help("Refresh counts")
                        }

                        Text("Fast SQL deletion - no loading required")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if isBulkDeleting {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Deleting...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        } else if isLoadingBulkCounts {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Counting items...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        } else {
                            VStack(spacing: 6) {
                                // CLEAN ALL button - does everything at once
                                Button {
                                    isBulkDeleting = true
                                    let db = StagingDatabase.shared
                                    Task.detached(priority: .userInitiated) {
                                        let result = db.cleanAll()
                                        await MainActor.run {
                                            isBulkDeleting = false
                                            bulkDeleteResult = "Deleted \(result.total) items: \(result.details)"
                                            showBulkDeleteResult = true
                                            loadData()
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "sparkles")
                                        Text("CLEAN ALL FOR UK")
                                            .fontWeight(.semibold)
                                        Spacer()
                                        Text("Non-Latin + Non-UK Barcodes + Foreign + Junk + Dupes")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.purple)

                                Divider()
                                    .padding(.vertical, 4)

                                bulkDeleteButton(
                                    title: "Non-UK Origin",
                                    count: countNonUKItems,
                                    icon: "globe.europe.africa"
                                ) {
                                    performBulkDelete {
                                        StagingDatabase.shared.deleteAllNonUK()
                                    } description: { "non-UK origin items" }
                                }

                                bulkDeleteButton(
                                    title: "Non-UK Barcodes",
                                    count: countNonUKBarcodesItems,
                                    icon: "barcode"
                                ) {
                                    performBatchedBulkDelete(
                                        initialCount: countNonUKBarcodesItems,
                                        description: "non-UK barcode items"
                                    ) { onProgress in
                                        StagingDatabase.shared.deleteNonUKBarcodesBatched(onProgress: onProgress)
                                    }
                                }

                                bulkDeleteButton(
                                    title: "No Ingredients",
                                    count: countNoIngredientsItems,
                                    icon: "list.bullet"
                                ) {
                                    performBatchedBulkDelete(
                                        initialCount: countNoIngredientsItems,
                                        description: "items with no ingredients"
                                    ) { onProgress in
                                        StagingDatabase.shared.deleteNoIngredientsBatched(onProgress: onProgress)
                                    }
                                }

                                bulkDeleteButton(
                                    title: "Missing Macros",
                                    count: countIncompleteMacrosItems,
                                    icon: "chart.pie"
                                ) {
                                    performBatchedBulkDelete(
                                        initialCount: countIncompleteMacrosItems,
                                        description: "items missing macros"
                                    ) { onProgress in
                                        StagingDatabase.shared.deleteIncompleteMacrosBatched(onProgress: onProgress)
                                    }
                                }

                                bulkDeleteButton(
                                    title: "Zero Calories",
                                    count: countZeroCaloriesItems,
                                    icon: "flame"
                                ) {
                                    performBatchedBulkDelete(
                                        initialCount: countZeroCaloriesItems,
                                        description: "items with zero calories"
                                    ) { onProgress in
                                        StagingDatabase.shared.deleteZeroCaloriesBatched(onProgress: onProgress)
                                    }
                                }

                                bulkDeleteButton(
                                    title: "Junk Ingredients",
                                    count: countJunkIngredientsItems,
                                    icon: "xmark.circle"
                                ) {
                                    performBatchedBulkDelete(
                                        initialCount: countJunkIngredientsItems,
                                        description: "items with junk ingredients"
                                    ) { onProgress in
                                        StagingDatabase.shared.deleteJunkIngredientsBatched(onProgress: onProgress)
                                    }
                                }

                                bulkDeleteButton(
                                    title: "Foreign Language",
                                    count: countNonEnglishItems,
                                    icon: "globe"
                                ) {
                                    performBatchedBulkDelete(
                                        initialCount: countNonEnglishItems,
                                        description: "items with non-English ingredients"
                                    ) { onProgress in
                                        StagingDatabase.shared.deleteNonEnglishIngredientsBatched(onProgress: onProgress)
                                    }
                                }

                                bulkDeleteButton(
                                    title: "Non-Latin Script",
                                    count: countNonLatinScriptItems,
                                    icon: "character.book.closed"
                                ) {
                                    performBatchedBulkDelete(
                                        initialCount: countNonLatinScriptItems,
                                        description: "items with Arabic/Chinese/etc. text"
                                    ) { onProgress in
                                        StagingDatabase.shared.deleteNonLatinScriptBatched(onProgress: onProgress)
                                    }
                                }

                                bulkDeleteButton(
                                    title: "No Serving Size",
                                    count: countNoServingSizeItems,
                                    icon: "scalemass"
                                ) {
                                    performBatchedBulkDelete(
                                        initialCount: countNoServingSizeItems,
                                        description: "items without serving size"
                                    ) { onProgress in
                                        StagingDatabase.shared.deleteNoServingSizeBatched(onProgress: onProgress)
                                    }
                                }

                                // Progress indicator during bulk delete
                                bulkDeleteProgressView
                            }
                        }

                        Divider()
                            .padding(.vertical, 4)

                        // Auto Tidy Section - Fast formatting without AI
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "textformat")
                                    .foregroundColor(.blue)
                                Text("Auto Tidy")
                                    .font(.subheadline.bold())
                            }

                            Text("Fast Title Case for names, brands & ingredients (no AI)")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if isAutoTidying {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Applying Title Case...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                Button {
                                    isAutoTidying = true
                                    let db = StagingDatabase.shared
                                    Task.detached(priority: .userInitiated) {
                                        let updated = db.autoTidyTitleCase()
                                        await MainActor.run {
                                            isAutoTidying = false
                                            bulkDeleteResult = "Title Case applied to \(updated) items"
                                            showBulkDeleteResult = true
                                            loadData()
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "wand.and.stars.inverse")
                                        Text("AUTO TIDY")
                                            .fontWeight(.semibold)
                                        Spacer()
                                        Text("Title Case all names & ingredients")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                            }
                        }
                    }
                    .padding()
                    .onAppear {
                        refreshBulkDeleteCounts()
                    }

                    Divider()
                }

                // Save to Database (only on ready tab)
                if isReady {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "arrow.up.doc")
                                .foregroundColor(.green)
                            Text("Save to Firebase")
                                .font(.headline)
                        }

                        Picker("Database", selection: $selectedDatabase) {
                            ForEach(availableDatabases, id: \.self) { db in
                                Text(db).tag(db)
                            }
                        }
                        .pickerStyle(.menu)

                        Button {
                            showingCreateDatabase = true
                        } label: {
                            Label("New Database", systemImage: "plus.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        if isSaving {
                            ProgressView(value: saveProgress)
                        } else {
                            if let error = saveError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }

                            VStack(spacing: 8) {
                                Button {
                                    Task { await saveSelectedItems() }
                                } label: {
                                    Label("Save Selected (\(selectedIds.count))", systemImage: "square.and.arrow.up")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(selectedIds.isEmpty)

                                Button {
                                    Task { await saveReadyItems() }
                                } label: {
                                    Label("Save All Ready (\(readyCount))", systemImage: "square.and.arrow.up.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(readyCount == 0)
                            }
                        }
                    }
                    .padding()

                    Divider()
                }

                // Delete selected
                if !selectedIds.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Delete")
                                .font(.headline)
                        }

                        Button {
                            stagingDb.deleteRows(ids: Array(selectedIds))
                            selectedIds.removeAll()
                            loadData()
                        } label: {
                            Label("Delete Selected (\(selectedIds.count))", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                    .padding()
                }

                Spacer()
            }
        }
    }

    // MARK: - Create Database Sheet

    private var createDatabaseSheet: some View {
        VStack(spacing: 20) {
            Text("Create New Database")
                .font(.title2)
                .fontWeight(.bold)

            TextField("Database Name", text: $newDatabaseName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)

            Text("Creates a new Firestore collection.")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                Button("Cancel") {
                    showingCreateDatabase = false
                    newDatabaseName = ""
                }
                .buttonStyle(.bordered)

                Button("Create") {
                    if !newDatabaseName.isEmpty {
                        let sanitized = newDatabaseName.lowercased().replacingOccurrences(of: " ", with: "_")
                        if !availableDatabases.contains(sanitized) {
                            availableDatabases.append(sanitized)
                        }
                        selectedDatabase = sanitized
                        showingCreateDatabase = false
                        newDatabaseName = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newDatabaseName.isEmpty)
            }
        }
        .padding(30)
        .frame(width: 400)
    }

    // MARK: - File Handling

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            guard url.startAccessingSecurityScopedResource() else {
                importError = "Could not access file"
                return
            }

            // For CSV files, show preview first
            if url.pathExtension.lowercased() == "csv" {
                analyzeCSVForPreview(url: url)
            } else {
                // For JSON, go straight to import
                startStreamingImport(url: url)
            }

        case .failure(let error):
            importError = "Import failed: \(error.localizedDescription)"
        }
    }

    private func analyzeCSVForPreview(url: URL) {
        previewFileURL = url
        previewDetectedColumns = []
        previewSampleRows = []

        guard let handle = FileHandle(forReadingAtPath: url.path) else {
            importError = "Could not open file for preview"
            return
        }

        defer { try? handle.close() }

        // Read first 64KB to get headers and a few sample rows
        let data = handle.readData(ofLength: 65536)
        guard let content = String(data: data, encoding: .utf8) else {
            importError = "Could not read file as UTF-8"
            return
        }

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard let firstLine = lines.first else {
            importError = "Empty file"
            return
        }

        // Detect delimiter
        previewDelimiter = detectDelimiter(in: firstLine)

        // Parse headers
        let headers = parseDelimitedLine(firstLine, delimiter: previewDelimiter)
        previewTotalColumns = headers.count

        // Build column mapping preview
        var detectedColumns: [(field: String, mappedTo: String?)] = []
        var headerIndexMap: [String: Int] = [:]

        for (index, header) in headers.enumerated() {
            let key = header.lowercased().trimmingCharacters(in: .whitespaces)
            headerIndexMap[key] = index
        }

        // Check each of our target fields
        let targetFields = ["name", "barcode", "brand", "calories", "protein", "carbs", "fat",
                           "saturatedFat", "fiber", "sugar", "sodium", "servingDescription",
                           "servingSizeG", "ingredients"]

        for field in targetFields {
            var mappedColumn: String? = nil
            if let possibleNames = columnMappings[field] {
                for name in possibleNames {
                    if headerIndexMap[name] != nil {
                        mappedColumn = name
                        break
                    }
                }
            }
            detectedColumns.append((field: field, mappedTo: mappedColumn))
        }

        previewDetectedColumns = detectedColumns

        // Parse sample rows (up to 3)
        var samples: [[String: String]] = []
        for i in 1..<min(4, lines.count) {
            let values = parseDelimitedLine(lines[i], delimiter: previewDelimiter)
            var rowDict: [String: String] = [:]

            for (field, mappedTo) in detectedColumns {
                if let col = mappedTo, let idx = headerIndexMap[col], idx < values.count {
                    let val = values[idx].trimmingCharacters(in: .whitespaces)
                    if !val.isEmpty {
                        rowDict[field] = val
                    }
                }
            }
            if !rowDict.isEmpty {
                samples.append(rowDict)
            }
        }
        previewSampleRows = samples

        showingImportPreview = true
    }

    private func startStreamingImport(url: URL) {
        isImporting = true
        importProgress = 0
        importedRowCount = 0
        skippedDuplicates = 0
        importStopped = false
        importStatusText = "Starting import..."

        Task {
            if url.pathExtension.lowercased() == "csv" {
                await streamCSVToDatabase(url: url)
            } else if url.pathExtension.lowercased() == "json" {
                await streamJSONToDatabase(url: url)
            }

            await MainActor.run {
                // Only auto-close if not stopped
                if !importStopped {
                    isImporting = false
                    url.stopAccessingSecurityScopedResource()
                    lastImportCount = importedRowCount
                    showImportSuccess = importedRowCount > 0
                    loadData()
                }
            }
        }
    }

    // MARK: - Streaming CSV Import

    /// Detect delimiter by analyzing first line - supports TAB (OpenFoodFacts) and comma
    private func detectDelimiter(in line: String) -> Character {
        let tabCount = line.filter { $0 == "\t" }.count
        let commaCount = line.filter { $0 == "," }.count

        // OpenFoodFacts uses TAB, most others use comma
        // If tabs > 10, it's definitely tab-separated (OFF has 200+ columns)
        if tabCount > 10 {
            print("Detected TAB delimiter (\(tabCount) tabs found)")
            return "\t"
        } else if tabCount > commaCount {
            print("Detected TAB delimiter (\(tabCount) tabs vs \(commaCount) commas)")
            return "\t"
        } else {
            print("Detected COMMA delimiter (\(commaCount) commas vs \(tabCount) tabs)")
            return ","
        }
    }

    private func streamCSVToDatabase(url: URL) async {
        guard let handle = FileHandle(forReadingAtPath: url.path) else {
            await MainActor.run { importError = "Could not open file" }
            return
        }

        defer { try? handle.close() }

        // Get file size for progress
        let fileSize: UInt64
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
            fileSize = attrs[.size] as? UInt64 ?? 0
        } catch {
            fileSize = 0
        }

        var headerIndices: [String: Int] = [:]
        var currentLine = ""
        var lineNumber = 0
        var inQuotes = false
        var bytesRead: UInt64 = 0
        var rowsInBatch = 0
        var localSkipped = 0
        var delimiter: Character = ","  // Will be detected from first line
        var totalRowsProcessed = 0

        // PERFORMANCE: Large buffer and infrequent commits for 2M+ row imports
        let bufferSize = 1048576 // 1MB chunks (was 64KB)
        let commitInterval = 10000 // Commit every 10k rows (was 500)
        let uiUpdateInterval = 5000 // Update UI every 5k rows

        stagingDb.beginTransaction()

        outerLoop: while true {
            // Check if stopped (only once per buffer read, not per line)
            if await MainActor.run(body: { importStopped }) {
                break outerLoop
            }

            let data: Data = autoreleasepool {
                return handle.readData(ofLength: bufferSize)
            }

            if data.isEmpty { break }
            bytesRead += UInt64(data.count)

            guard let chunk = String(data: data, encoding: .utf8) else { continue }

            for char in chunk {
                if char == "\"" {
                    inQuotes.toggle()
                    currentLine.append(char)
                } else if char == "\n" && !inQuotes {
                    let line = currentLine.trimmingCharacters(in: CharacterSet(charactersIn: "\r"))
                    currentLine = ""

                    if lineNumber == 0 {
                        // FIRST LINE: Detect delimiter and parse headers
                        delimiter = detectDelimiter(in: line)

                        let headers = parseDelimitedLine(line, delimiter: delimiter)
                        for (index, header) in headers.enumerated() {
                            let key = header.lowercased().trimmingCharacters(in: .whitespaces)
                            headerIndices[key] = index
                        }

                        // Log which columns we found and mapped
                        print("=== CSV Import Analysis ===")
                        print("Total columns: \(headers.count)")
                        print("Delimiter: \(delimiter == "\t" ? "TAB" : "COMMA")")

                        // Check which of our target fields were found
                        for (field, possibleNames) in columnMappings {
                            var foundColumn: String? = nil
                            for name in possibleNames {
                                if headerIndices[name] != nil {
                                    foundColumn = name
                                    break
                                }
                            }
                            if let col = foundColumn {
                                print("✓ \(field) → '\(col)' (column \(headerIndices[col]!))")
                            } else {
                                print("✗ \(field) → NOT FOUND (tried: \(possibleNames.prefix(3).joined(separator: ", "))...)")
                            }
                        }
                        print("===========================")
                    } else {
                        // Data row - insert (duplicate check is conditional)
                        let inserted = insertDelimitedRowIfNew(line, delimiter: delimiter, headers: headerIndices)
                        if inserted {
                            importedRowCount += 1
                        } else {
                            localSkipped += 1
                        }
                        rowsInBatch += 1
                        totalRowsProcessed += 1

                        // Commit transaction periodically
                        if rowsInBatch >= commitInterval {
                            stagingDb.commitTransaction()
                            stagingDb.beginTransaction()
                            rowsInBatch = 0
                        }

                        // Update UI less frequently (every 5k rows)
                        if totalRowsProcessed % uiUpdateInterval == 0 {
                            let progress = fileSize > 0 ? Double(bytesRead) / Double(fileSize) : 0
                            let currentSkipped = localSkipped
                            let currentImported = importedRowCount
                            await MainActor.run {
                                importProgress = progress
                                skippedDuplicates = currentSkipped
                                if currentSkipped > 0 {
                                    importStatusText = "Imported \(currentImported) rows (\(currentSkipped) skipped)..."
                                } else {
                                    importStatusText = "Imported \(currentImported) rows..."
                                }
                            }
                        }
                    }

                    lineNumber += 1
                } else {
                    currentLine.append(char)
                }
            }
        }

        // Process remaining line (if not stopped mid-line)
        if !currentLine.isEmpty && lineNumber > 0 && !importStopped {
            let line = currentLine.trimmingCharacters(in: CharacterSet(charactersIn: "\r"))
            let inserted = insertDelimitedRowIfNew(line, delimiter: delimiter, headers: headerIndices)
            if inserted {
                importedRowCount += 1
            } else {
                localSkipped += 1
            }
        }

        stagingDb.commitTransaction()

        let finalSkipped = localSkipped
        await MainActor.run {
            skippedDuplicates = finalSkipped
            if importStopped {
                importStatusText = "Stopped at \(importedRowCount) rows"
            } else {
                importProgress = 1.0
                if finalSkipped > 0 {
                    importStatusText = "Imported \(importedRowCount) rows (\(finalSkipped) duplicates skipped)"
                } else {
                    importStatusText = "Imported \(importedRowCount) rows"
                }
            }
        }
    }

    /// Parse a line with the specified delimiter (TAB or comma)
    private func parseDelimitedLine(_ line: String, delimiter: Character) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == delimiter && !inQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current)
        return result
    }

    /// Legacy comma-only parser for backwards compatibility
    private func parseCSVLine(_ line: String) -> [String] {
        return parseDelimitedLine(line, delimiter: ",")
    }

    /// Insert row with specified delimiter, checking for duplicates
    /// Captures ALL CSV columns - mapped ones go to specific fields, rest goes to extra_data
    private func insertDelimitedRowIfNew(_ line: String, delimiter: Character, headers: [String: Int]) -> Bool {
        let values = parseDelimitedLine(line, delimiter: delimiter)

        // Build reverse lookup: index -> header name
        var indexToHeader: [Int: String] = [:]
        for (header, idx) in headers {
            indexToHeader[idx] = header
        }

        // Track which indices we've used for mapped columns
        var usedIndices = Set<Int>()

        func get(_ keys: [String]) -> String {
            for key in keys {
                if let idx = headers[key], idx < values.count {
                    usedIndices.insert(idx)
                    let val = values[idx].trimmingCharacters(in: .whitespaces)
                    if val.hasPrefix("\"") && val.hasSuffix("\"") && val.count >= 2 {
                        return String(val.dropFirst().dropLast())
                    }
                    return val
                }
            }
            return ""
        }

        func getDouble(_ keys: [String]) -> Double {
            let str = get(keys)
            // Handle European number format (comma as decimal separator)
            // But only if delimiter is TAB (so commas in numbers are actual decimals)
            let cleaned = delimiter == "\t" ? str.replacingOccurrences(of: ",", with: ".") : str
            return Double(cleaned) ?? 0
        }

        let name = get(columnMappings["name"]!)
        let barcode = get(columnMappings["barcode"]!)
        let brand = get(columnMappings["brand"]!)
        let calories = getDouble(columnMappings["calories"]!)
        let protein = getDouble(columnMappings["protein"]!)
        let carbs = getDouble(columnMappings["carbs"]!)
        let fat = getDouble(columnMappings["fat"]!)
        let saturatedFat = getDouble(columnMappings["saturatedFat"]!)
        let fiber = getDouble(columnMappings["fiber"]!)
        let sugar = getDouble(columnMappings["sugar"]!)
        let sodium = getDouble(columnMappings["sodium"]!)
        let servingDescription = get(columnMappings["servingDescription"]!)
        let servingSizeG = getDouble(columnMappings["servingSizeG"]!)
        let ingredients = get(columnMappings["ingredients"]!)

        // Collect ALL unmapped columns into extraData
        var extraData: [String: String] = [:]
        for (idx, value) in values.enumerated() {
            if !usedIndices.contains(idx), let header = indexToHeader[idx] {
                let trimmed = value.trimmingCharacters(in: .whitespaces)
                // Only store non-empty values
                if !trimmed.isEmpty && trimmed != "\"\"" {
                    // Clean up quoted values
                    var cleanVal = trimmed
                    if cleanVal.hasPrefix("\"") && cleanVal.hasSuffix("\"") && cleanVal.count >= 2 {
                        cleanVal = String(cleanVal.dropFirst().dropLast())
                    }
                    extraData[header] = cleanVal
                }
            }
        }

        // Debug: Log first 3 rows to console
        struct DebugCounter { static var count = 0 }
        if DebugCounter.count < 3 {
            DebugCounter.count += 1
            print("=== Row \(DebugCounter.count) Debug ===")
            print("  name: '\(name)' (len: \(name.count))")
            print("  brand: '\(brand)' (len: \(brand.count))")
            print("  barcode: '\(barcode)' (len: \(barcode.count))")
            print("  calories: \(calories), protein: \(protein)")
            print("  values count: \(values.count)")
            print("  extraData columns: \(extraData.count)")
            if DebugCounter.count == 1 {
                print("  Sample extra keys: \(Array(extraData.keys.prefix(10)))")
            }
        }

        // Skip completely empty rows
        guard !name.isEmpty || !barcode.isEmpty || calories > 0 else { return false }

        // Check for duplicates (unless fast import is enabled)
        if !skipDuplicateCheck {
            if !barcode.isEmpty && stagingDb.existsByBarcode(barcode) {
                return false
            }
            if !name.isEmpty && stagingDb.existsByNameAndBrand(name, brand) {
                return false
            }
        }

        stagingDb.insertRow(
            name: name,
            brand: brand,
            barcode: barcode,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            saturatedFat: saturatedFat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            servingDescription: servingDescription,
            servingSizeG: servingSizeG,
            isPerUnit: false,
            ingredients: ingredients,
            extraData: extraData
        )
        return true
    }

    private func insertCSVRowToDatabase(_ line: String, headers: [String: Int]) {
        _ = insertDelimitedRowIfNew(line, delimiter: ",", headers: headers)
    }

    /// Insert CSV row only if it doesn't already exist (by barcode or name+brand)
    /// Returns true if inserted, false if skipped as duplicate
    private func insertCSVRowToDatabaseIfNew(_ line: String, headers: [String: Int]) -> Bool {
        return insertDelimitedRowIfNew(line, delimiter: ",", headers: headers)
    }


    // MARK: - Streaming JSON Import

    private func streamJSONToDatabase(url: URL) async {
        do {
            let data = try Data(contentsOf: url, options: .mappedIfSafe)

            await MainActor.run {
                importStatusText = "Parsing JSON..."
            }

            guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                await MainActor.run { importError = "Invalid JSON format - expected array of objects" }
                return
            }

            let total = jsonArray.count
            var localSkipped = 0
            stagingDb.beginTransaction()

            for (index, dict) in jsonArray.enumerated() {
                // Check if stopped
                if await MainActor.run(body: { importStopped }) {
                    break
                }

                let name = getStringFromDict(dict, columnMappings["name"]!)
                let brand = getStringFromDict(dict, columnMappings["brand"]!)
                let barcode = getStringFromDict(dict, columnMappings["barcode"]!)

                // Check for duplicates
                if !barcode.isEmpty && stagingDb.existsByBarcode(barcode) {
                    localSkipped += 1
                    continue
                }
                if !name.isEmpty && stagingDb.existsByNameAndBrand(name, brand) {
                    localSkipped += 1
                    continue
                }

                stagingDb.insertRow(
                    name: name,
                    brand: brand,
                    barcode: barcode,
                    calories: getNumberFromDict(dict, columnMappings["calories"]!),
                    protein: getNumberFromDict(dict, columnMappings["protein"]!),
                    carbs: getNumberFromDict(dict, columnMappings["carbs"]!),
                    fat: getNumberFromDict(dict, columnMappings["fat"]!),
                    saturatedFat: getNumberFromDict(dict, columnMappings["saturatedFat"]!),
                    fiber: getNumberFromDict(dict, columnMappings["fiber"]!),
                    sugar: getNumberFromDict(dict, columnMappings["sugar"]!),
                    sodium: getNumberFromDict(dict, columnMappings["sodium"]!),
                    servingDescription: getStringFromDict(dict, columnMappings["servingDescription"]!),
                    servingSizeG: getNumberFromDict(dict, columnMappings["servingSizeG"]!),
                    isPerUnit: dict["isPerUnit"] as? Bool ?? dict["is_per_unit"] as? Bool ?? false,
                    ingredients: getStringFromDict(dict, columnMappings["ingredients"]!)
                )

                importedRowCount += 1

                if index % 500 == 0 {
                    stagingDb.commitTransaction()
                    stagingDb.beginTransaction()

                    let currentSkipped = localSkipped
                    await MainActor.run {
                        importProgress = Double(index) / Double(total)
                        skippedDuplicates = currentSkipped
                        if currentSkipped > 0 {
                            importStatusText = "Imported \(importedRowCount) of \(total) (\(currentSkipped) skipped)..."
                        } else {
                            importStatusText = "Imported \(importedRowCount) of \(total)..."
                        }
                    }
                }
            }

            stagingDb.commitTransaction()

            let finalSkipped = localSkipped
            await MainActor.run {
                skippedDuplicates = finalSkipped
                if importStopped {
                    importStatusText = "Stopped at \(importedRowCount) items"
                } else {
                    importProgress = 1.0
                    if finalSkipped > 0 {
                        importStatusText = "Imported \(importedRowCount) items (\(finalSkipped) duplicates skipped)"
                    } else {
                        importStatusText = "Imported \(importedRowCount) items"
                    }
                }
            }
        } catch {
            await MainActor.run {
                importError = "JSON error: \(error.localizedDescription)"
            }
        }
    }

    private func getStringFromDict(_ dict: [String: Any], _ keys: [String]) -> String {
        for key in keys {
            if let val = dict[key] as? String { return val }
        }
        return ""
    }

    private func getNumberFromDict(_ dict: [String: Any], _ keys: [String]) -> Double {
        for key in keys {
            if let num = dict[key] as? NSNumber { return num.doubleValue }
            if let str = dict[key] as? String {
                let cleaned = str.replacingOccurrences(of: ",", with: ".")
                return Double(cleaned) ?? 0
            }
        }
        return 0
    }

    // MARK: - Barcode Enrichment (No AI)

    private func refreshEnrichmentCount() {
        Task.detached(priority: .userInitiated) {
            let count = StagingDatabase.shared.countNeedingBarcodeEnrichment()
            await MainActor.run {
                countNeedingEnrichment = count
            }
        }
    }

    private func enrichFromBarcodes() async {
        isEnrichingFromBarcodes = true
        barcodeEnrichmentProgress = 0
        barcodeEnrichmentProcessed = 0
        barcodeEnrichmentEnriched = 0
        barcodeEnrichmentFailed = 0

        let db = StagingDatabase.shared
        barcodeEnrichmentTotal = db.countNeedingBarcodeEnrichment()

        // Process in batches
        while isEnrichingFromBarcodes {
            let items = db.getItemsNeedingEnrichment(limit: 50)
            if items.isEmpty { break }

            for item in items {
                guard isEnrichingFromBarcodes else { break }

                // Try OpenFoodFacts first
                if let lookup = await lookupBarcode(item.barcode) {
                    if lookup.found {
                        // Found on OpenFoodFacts - enrich the item
                        db.enrichFromBarcodeLookup(
                            id: item.id,
                            name: lookup.name.isEmpty ? nil : lookup.name,
                            brand: lookup.brand.isEmpty ? nil : lookup.brand,
                            ingredients: lookup.ingredients.isEmpty ? nil : lookup.ingredients,
                            servingDescription: lookup.servingSize.isEmpty ? nil : lookup.servingSize,
                            servingSizeG: lookup.servingSizeG > 0 ? lookup.servingSizeG : nil,
                            calories: lookup.calories > 0 ? lookup.calories : nil,
                            protein: lookup.protein > 0 ? lookup.protein : nil,
                            carbs: lookup.carbs > 0 ? lookup.carbs : nil,
                            fat: lookup.fat > 0 ? lookup.fat : nil,
                            saturatedFat: lookup.saturatedFat > 0 ? lookup.saturatedFat : nil,
                            fiber: lookup.fiber > 0 ? lookup.fiber : nil,
                            sugar: lookup.sugar > 0 ? lookup.sugar : nil,
                            sodium: lookup.sodium > 0 ? lookup.sodium : nil
                        )
                        barcodeEnrichmentEnriched += 1
                    } else {
                        // Not found on OpenFoodFacts - try Google search for brand/name
                        if let googleResult = await searchGoogleForBarcode(item.barcode) {
                            db.enrichFromBarcodeLookup(
                                id: item.id,
                                name: googleResult.name,
                                brand: googleResult.brand,
                                ingredients: nil,
                                servingDescription: nil,
                                servingSizeG: nil,
                                calories: nil,
                                protein: nil,
                                carbs: nil,
                                fat: nil,
                                saturatedFat: nil,
                                fiber: nil,
                                sugar: nil,
                                sodium: nil
                            )
                            barcodeEnrichmentEnriched += 1
                        } else {
                            barcodeEnrichmentFailed += 1
                        }
                    }
                } else {
                    barcodeEnrichmentFailed += 1
                }

                barcodeEnrichmentProcessed += 1
                barcodeEnrichmentProgress = Double(barcodeEnrichmentProcessed) / Double(max(1, barcodeEnrichmentTotal))
            }
        }

        isEnrichingFromBarcodes = false
        countNeedingEnrichment = db.countNeedingBarcodeEnrichment()
        loadCurrentPage()
    }

    /// Search Google for barcode to find product name/brand
    private func searchGoogleForBarcode(_ barcode: String) async -> (name: String?, brand: String?)? {
        // Use a simple search query
        let query = barcode.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? barcode
        guard let url = URL(string: "https://www.google.com/search?q=\(query)+barcode+product") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let html = String(data: data, encoding: .utf8) else {
                return nil
            }

            // Try to extract product info from Google results
            // Look for common patterns in search results
            var extractedName: String?
            var extractedBrand: String?

            // Look for title tags or result snippets
            // Pattern: <h3 class="...">Product Name - Brand</h3>
            if let titleRange = html.range(of: "<h3[^>]*>([^<]+)</h3>", options: .regularExpression) {
                let titleHTML = String(html[titleRange])
                // Extract text between > and <
                if let start = titleHTML.firstIndex(of: ">"),
                   let end = titleHTML.lastIndex(of: "<") {
                    let title = String(titleHTML[titleHTML.index(after: start)..<end])
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    // Often formatted as "Product Name - Brand" or "Brand Product Name"
                    if !title.isEmpty && title.count < 200 {
                        // Try to split on common separators
                        if title.contains(" - ") {
                            let parts = title.components(separatedBy: " - ")
                            if parts.count >= 2 {
                                extractedName = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                                extractedBrand = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                        } else if title.contains(" | ") {
                            let parts = title.components(separatedBy: " | ")
                            if parts.count >= 2 {
                                extractedName = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                                extractedBrand = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                        } else {
                            // Just use the whole title as the name
                            extractedName = title
                        }
                    }
                }
            }

            // Only return if we found something useful
            if extractedName != nil || extractedBrand != nil {
                return (name: extractedName, brand: extractedBrand)
            }

            return nil
        } catch {
            return nil
        }
    }

    // MARK: - AI Cleaning

    private func cleanSelectedItems() async {
        guard !selectedIds.isEmpty else { return }

        // Check if Claude API is configured
        guard claudeService.isConfigured else {
            cleaningError = "Claude API key not configured. Please set your API key in Settings to use AI cleaning."
            showCleaningError = true
            return
        }

        // Check if any cleaning options are selected
        guard hasAnyCleaningOption else {
            cleaningError = "No cleaning options selected. Please enable at least one cleaning option."
            showCleaningError = true
            return
        }

        isCleaning = true
        shouldStopCleaning = false
        cleaningProgress = 0
        var errorCount = 0
        var stoppedEarly = false

        let ids = Array(selectedIds)
        for (i, id) in ids.enumerated() {
            // Check if user requested stop
            if shouldStopCleaning {
                stoppedEarly = true
                break
            }

            cleaningStatusText = "Cleaning \(i + 1) of \(ids.count)..."
            let success = await cleanItemWithAI(id: id)
            if !success { errorCount += 1 }
            cleaningProgress = Double(i + 1) / Double(ids.count)
            cleanedCount = stagingDb.getCleanedCount()
        }

        loadCurrentPage()
        isCleaning = false
        shouldStopCleaning = false
        cleaningStatusText = ""

        // Show summary
        if stoppedEarly {
            cleaningError = "Cleaning stopped. \(Int(cleaningProgress * Double(ids.count))) items cleaned. You can resume anytime."
            showCleaningError = true
        } else if errorCount > 0 {
            cleaningError = "Cleaning completed with \(errorCount) error(s). Check items marked as 'error' status."
            showCleaningError = true
        }
    }

    private func cleanAllPending() async {
        // Check if Claude API is configured
        guard claudeService.isConfigured else {
            cleaningError = "Claude API key not configured. Please set your API key in Settings to use AI cleaning."
            showCleaningError = true
            return
        }

        // Check if any cleaning options are selected
        guard hasAnyCleaningOption else {
            cleaningError = "No cleaning options selected. Please enable at least one cleaning option."
            showCleaningError = true
            return
        }

        isCleaning = true
        shouldStopCleaning = false
        cleaningProgress = 0

        let total = totalRowCount - cleanedCount
        var cleaned = 0
        var errorCount = 0
        var stoppedEarly = false

        outerLoop: while true {
            // Check if user requested stop
            if shouldStopCleaning {
                stoppedEarly = true
                break
            }

            let pendingIds = stagingDb.getPendingIds(limit: 10)
            if pendingIds.isEmpty { break }

            for id in pendingIds {
                // Check if user requested stop
                if shouldStopCleaning {
                    stoppedEarly = true
                    break outerLoop
                }

                cleaned += 1
                cleaningStatusText = "Cleaning \(cleaned) of \(total)..."
                let success = await cleanItemWithAI(id: id)
                if !success { errorCount += 1 }
                cleaningProgress = Double(cleaned) / Double(max(1, total))
                cleanedCount = stagingDb.getCleanedCount()
            }
        }

        loadCurrentPage()
        isCleaning = false
        shouldStopCleaning = false
        cleaningStatusText = ""

        // Show summary
        if stoppedEarly {
            cleaningError = "Cleaning stopped. \(cleaned) items cleaned. You can resume anytime with 'Clean All Pending'."
            showCleaningError = true
        } else if errorCount > 0 {
            cleaningError = "Cleaning completed with \(errorCount) error(s). Check items marked as 'error' status."
            showCleaningError = true
        }
    }

    /// Check if text contains significant foreign (non-Latin) characters
    private func hasForeignText(_ text: String) -> Bool {
        // Characters from non-Latin scripts
        let foreignRanges: [ClosedRange<UnicodeScalar>] = [
            UnicodeScalar(0x0400)!...UnicodeScalar(0x04FF)!,  // Cyrillic
            UnicodeScalar(0x4E00)!...UnicodeScalar(0x9FFF)!,  // CJK (Chinese/Japanese/Korean)
            UnicodeScalar(0x3040)!...UnicodeScalar(0x309F)!,  // Hiragana
            UnicodeScalar(0x30A0)!...UnicodeScalar(0x30FF)!,  // Katakana
            UnicodeScalar(0x0600)!...UnicodeScalar(0x06FF)!,  // Arabic
            UnicodeScalar(0x0900)!...UnicodeScalar(0x097F)!,  // Devanagari (Hindi)
            UnicodeScalar(0x0E00)!...UnicodeScalar(0x0E7F)!,  // Thai
            UnicodeScalar(0x1100)!...UnicodeScalar(0x11FF)!,  // Hangul Jamo
            UnicodeScalar(0xAC00)!...UnicodeScalar(0xD7AF)!,  // Hangul Syllables
        ]

        var foreignCount = 0
        for scalar in text.unicodeScalars {
            for range in foreignRanges {
                if range.contains(scalar) {
                    foreignCount += 1
                    if foreignCount >= 3 {  // If 3+ foreign chars, consider it foreign
                        return true
                    }
                }
            }
        }
        return false
    }

    /// Check if text contains junk/invalid data patterns that should trigger deletion
    private func hasJunkData(_ text: String) -> Bool {
        let lowerText = text.lowercased()

        // Common invalid patterns
        let junkPatterns = [
            "undefined", "null", "none", "n/a", "na", "not available",
            "unknown", "test", "sample", "example", "placeholder",
            "lorem ipsum", "xxx", "...", "---", "___",
            "error", "invalid", "missing", "todo", "tbd",
            "asdf", "qwerty", "aaa", "bbb", "123456",
            "product name", "brand name", "enter name", "your brand",
            "[object object]", "nan", "#ref", "#value", "#n/a"
        ]

        for pattern in junkPatterns {
            if lowerText == pattern || lowerText.contains("\"\(pattern)\"") {
                return true
            }
        }

        // Check for repeated characters (like "aaaaaaa" or "1111111")
        if text.count >= 5 {
            let chars = Array(text)
            var repeatCount = 1
            for i in 1..<chars.count {
                if chars[i] == chars[i-1] {
                    repeatCount += 1
                    if repeatCount >= 5 { return true }
                } else {
                    repeatCount = 1
                }
            }
        }

        return false
    }

    /// Check if ingredients are valid (not undefined, null, or garbage)
    private func hasInvalidIngredients(_ ingredients: String) -> Bool {
        let trimmed = ingredients.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Obviously invalid
        if trimmed.isEmpty { return false }  // Empty is fine, we handle that separately

        let invalidPatterns = [
            "undefined", "null", "none", "n/a", "not available", "unknown",
            "ingredients:", "ingredient list:", "contains:", // Just labels with no content
            "[", "{", "<",  // Looks like code/JSON artifacts
            "product contains", "see package", "voir emballage"
        ]

        for pattern in invalidPatterns {
            if trimmed == pattern || (trimmed.count < 30 && trimmed.hasPrefix(pattern)) {
                return true
            }
        }

        // If it's very short and contains no letters, probably junk
        if trimmed.count < 3 && !trimmed.contains(where: { $0.isLetter }) {
            return true
        }

        return false
    }

    /// Check if numerical data looks suspicious
    private func hasSuspiciousNutrition(_ row: StagingFoodRow) -> Bool {
        // Impossibly high values per 100g
        if row.calories > 1000 { return true }  // Max is ~900 for pure fat
        if row.protein > 100 { return true }
        if row.carbs > 100 { return true }
        if row.fat > 100 { return true }
        if row.sugar > 100 { return true }
        if row.fiber > 100 { return true }

        // Macros don't add up (protein + carbs + fat should roughly equal calories/4-9)
        let minCals = (row.protein * 4) + (row.carbs * 4) + (row.fat * 9) - 50
        let maxCals = (row.protein * 4) + (row.carbs * 4) + (row.fat * 9) + 50
        if row.calories > 0 && row.protein + row.carbs + row.fat > 10 {
            if row.calories < minCals * 0.5 || row.calories > maxCals * 2 {
                // Calories way off from macros - suspicious but not auto-delete
                // Let AI handle this case
            }
        }

        return false
    }

    // MARK: - OpenFoodFacts Barcode Verification

    struct OpenFoodFactsProduct {
        let name: String
        let brand: String
        let ingredients: String
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
        let saturatedFat: Double
        let fiber: Double
        let sugar: Double
        let sodium: Double
        let servingSize: String      // e.g. "30g", "1 biscuit (25g)"
        let servingSizeG: Double     // numeric grams
        let quantity: String         // e.g. "300g", "6 x 25g"
        let found: Bool
    }

    /// Look up a barcode on OpenFoodFacts
    private func lookupBarcode(_ barcode: String) async -> OpenFoodFactsProduct? {
        guard !barcode.isEmpty else { return nil }

        let urlString = "https://world.openfoodfacts.org/api/v2/product/\(barcode).json?fields=product_name,brands,ingredients_text,nutriments,serving_size,serving_quantity,quantity,product_quantity"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let status = json["status"] as? Int,
                  status == 1,
                  let product = json["product"] as? [String: Any] else {
                return OpenFoodFactsProduct(name: "", brand: "", ingredients: "", calories: 0, protein: 0, carbs: 0, fat: 0, saturatedFat: 0, fiber: 0, sugar: 0, sodium: 0, servingSize: "", servingSizeG: 0, quantity: "", found: false)
            }

            let nutriments = product["nutriments"] as? [String: Any] ?? [:]

            // Parse serving size - try multiple fields
            let servingSize = product["serving_size"] as? String ?? ""
            var servingSizeG: Double = 0
            if let sq = product["serving_quantity"] as? Double {
                servingSizeG = sq
            } else if let sqStr = product["serving_quantity"] as? String, let sq = Double(sqStr) {
                servingSizeG = sq
            } else {
                // Try to extract grams from serving_size string (e.g. "30g" or "1 biscuit (25g)")
                servingSizeG = extractGramsFromString(servingSize)
            }

            let quantity = product["quantity"] as? String ?? product["product_quantity"] as? String ?? ""

            return OpenFoodFactsProduct(
                name: product["product_name"] as? String ?? "",
                brand: product["brands"] as? String ?? "",
                ingredients: product["ingredients_text"] as? String ?? "",
                calories: nutriments["energy-kcal_100g"] as? Double ?? nutriments["energy-kcal"] as? Double ?? 0,
                protein: nutriments["proteins_100g"] as? Double ?? nutriments["proteins"] as? Double ?? 0,
                carbs: nutriments["carbohydrates_100g"] as? Double ?? nutriments["carbohydrates"] as? Double ?? 0,
                fat: nutriments["fat_100g"] as? Double ?? nutriments["fat"] as? Double ?? 0,
                saturatedFat: nutriments["saturated-fat_100g"] as? Double ?? nutriments["saturated-fat"] as? Double ?? 0,
                fiber: nutriments["fiber_100g"] as? Double ?? nutriments["fiber"] as? Double ?? 0,
                sugar: nutriments["sugars_100g"] as? Double ?? nutriments["sugars"] as? Double ?? 0,
                sodium: nutriments["sodium_100g"] as? Double ?? nutriments["sodium"] as? Double ?? 0,
                servingSize: servingSize,
                servingSizeG: servingSizeG,
                quantity: quantity,
                found: true
            )
        } catch {
            return nil
        }
    }

    /// Extract grams from a serving size string like "30g" or "1 biscuit (25g)"
    private func extractGramsFromString(_ str: String) -> Double {
        // Look for patterns like "25g", "25 g", "(25g)", "25 grams"
        let pattern = #"(\d+(?:\.\d+)?)\s*(?:g|grams?)\b"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: str, range: NSRange(str.startIndex..., in: str)),
           let range = Range(match.range(at: 1), in: str) {
            return Double(str[range]) ?? 0
        }
        return 0
    }

    /// Check if a serving size seems reasonable for a product
    private func isServingSizeReasonable(_ servingSizeG: Double, productName: String, calories: Double) -> Bool {
        // Serving size should be between 5g and 500g for most products
        guard servingSizeG >= 5 && servingSizeG <= 500 else { return false }

        let nameLower = productName.lowercased()

        // Small items (biscuits, sweets, crisps) - serving usually 15-50g
        let smallItems = ["biscuit", "cookie", "crisp", "chip", "sweet", "candy", "chocolate bar", "snack"]
        if smallItems.contains(where: { nameLower.contains($0) }) {
            return servingSizeG <= 100
        }

        // Drinks - serving usually 200-500ml
        let drinks = ["juice", "drink", "cola", "lemonade", "water", "milk", "smoothie"]
        if drinks.contains(where: { nameLower.contains($0) }) {
            return servingSizeG >= 100 && servingSizeG <= 500
        }

        // Ready meals - serving usually 200-500g
        let meals = ["meal", "dinner", "lunch", "curry", "lasagne", "pie", "pizza"]
        if meals.contains(where: { nameLower.contains($0) }) {
            return servingSizeG >= 150 && servingSizeG <= 600
        }

        // Cereal - serving usually 30-50g
        if nameLower.contains("cereal") || nameLower.contains("muesli") || nameLower.contains("granola") {
            return servingSizeG >= 20 && servingSizeG <= 80
        }

        // If calories per 100g is very high (>400), serving should be smaller
        if calories > 400 && servingSizeG > 100 {
            return false
        }

        return true
    }

    /// Check if barcode format looks valid
    private func isValidBarcodeFormat(_ barcode: String) -> Bool {
        // Valid barcodes are typically 8, 12, 13, or 14 digits
        let digits = barcode.filter { $0.isNumber }
        return [8, 12, 13, 14].contains(digits.count)
    }

    /// Check if product data matches barcode lookup (to detect wrong barcodes)
    private func doesProductMatchBarcode(local: StagingFoodRow, online: OpenFoodFactsProduct) -> (matches: Bool, confidence: Double) {
        guard online.found else { return (true, 0) }  // Can't verify if not found online

        var score = 0.0
        var checks = 0.0

        // Compare names (fuzzy match)
        let localName = local.name.lowercased()
        let onlineName = online.name.lowercased()
        if !localName.isEmpty && !onlineName.isEmpty {
            checks += 1
            // Check for word overlap
            let localWords = Set(localName.split(separator: " ").map { String($0) })
            let onlineWords = Set(onlineName.split(separator: " ").map { String($0) })
            let overlap = localWords.intersection(onlineWords)
            if overlap.count >= 1 { score += 0.5 }
            if overlap.count >= 2 { score += 0.5 }
        }

        // Compare brands
        let localBrand = local.brand.lowercased()
        let onlineBrand = online.brand.lowercased()
        if !localBrand.isEmpty && !onlineBrand.isEmpty {
            checks += 1
            if localBrand.contains(onlineBrand) || onlineBrand.contains(localBrand) {
                score += 1
            }
        }

        // Compare calories (within 20%)
        if local.calories > 0 && online.calories > 0 {
            checks += 1
            let calDiff = abs(local.calories - online.calories) / max(local.calories, online.calories)
            if calDiff < 0.2 { score += 1 }
            else if calDiff < 0.5 { score += 0.5 }
        }

        // Compare protein (within 30%)
        if local.protein > 0 && online.protein > 0 {
            checks += 1
            let protDiff = abs(local.protein - online.protein) / max(local.protein, online.protein)
            if protDiff < 0.3 { score += 1 }
            else if protDiff < 0.5 { score += 0.5 }
        }

        let confidence = checks > 0 ? score / checks : 0
        return (confidence >= 0.4, confidence)  // 40% match threshold
    }

    @discardableResult
    private func cleanItemWithAI(id: Int) async -> Bool {
        guard let row = stagingDb.getRow(id: id) else { return false }

        // === PRE-AI VALIDATION (fast checks before calling API) ===

        // Check for foreign text - DELETE if option enabled
        if cleanOptionDeleteForeign {
            let textToCheck = "\(row.name) \(row.brand) \(row.ingredients)"
            if hasForeignText(textToCheck) {
                stagingDb.deleteRow(id: id)
                return true  // Successfully handled (deleted)
            }
        }

        // Smart validation - check for junk data patterns
        if cleanOptionSmartValidation {
            // Check name and brand for junk
            if hasJunkData(row.name) || hasJunkData(row.brand) {
                stagingDb.deleteRow(id: id)
                return true
            }

            // Check for invalid ingredients (undefined, null, etc.)
            if hasInvalidIngredients(row.ingredients) {
                stagingDb.deleteRow(id: id)
                return true
            }

            // Check for suspicious nutrition values
            if hasSuspiciousNutrition(row) {
                stagingDb.deleteRow(id: id)
                return true
            }

            // Name is too short or too long to be valid
            let nameLen = row.name.trimmingCharacters(in: .whitespacesAndNewlines).count
            if nameLen < 2 || nameLen > 200 {
                stagingDb.deleteRow(id: id)
                return true
            }
        }

        stagingDb.setCleaningStatus(id: id, status: "cleaning")

        // === BARCODE VERIFICATION (if enabled and barcode exists) ===
        var barcodeVerificationInfo = ""

        if cleanOptionVerifyBarcodes && !row.barcode.isEmpty && isValidBarcodeFormat(row.barcode) {
            if let lookup = await lookupBarcode(row.barcode) {
                let (matches, confidence) = doesProductMatchBarcode(local: row, online: lookup)

                if lookup.found {
                    if !matches {
                        // Barcode data doesn't match - this is suspicious
                        barcodeVerificationInfo = """

                        BARCODE VERIFICATION WARNING:
                        The barcode \(row.barcode) was found online but data doesn't match well (confidence: \(Int(confidence * 100))%):
                        - Online Name: \(lookup.name)
                        - Online Brand: \(lookup.brand)
                        - Online Ingredients: \(lookup.ingredients.prefix(200))
                        - Online Serving: \(lookup.servingSize) (\(lookup.servingSizeG)g)
                        - Online Calories: \(lookup.calories), Protein: \(lookup.protein)g, Carbs: \(lookup.carbs)g, Fat: \(lookup.fat)g

                        Consider: Is this the wrong barcode? Should we use online data instead? Delete if data is unreliable.
                        """
                    } else {
                        // Data matches - check for missing fields we can enrich
                        var enrichments: [String] = []

                        // Missing ingredients?
                        if (row.ingredients.isEmpty || row.ingredients.count < 10) && !lookup.ingredients.isEmpty {
                            enrichments.append("- Online Ingredients: \(lookup.ingredients.prefix(400))")
                        }

                        // Missing serving size?
                        if row.servingDescription.isEmpty && !lookup.servingSize.isEmpty {
                            // Check if serving size seems reasonable
                            if isServingSizeReasonable(lookup.servingSizeG, productName: row.name, calories: row.calories) {
                                enrichments.append("- Online Serving Size: \(lookup.servingSize) (\(lookup.servingSizeG)g)")
                            }
                        }

                        if !enrichments.isEmpty {
                            barcodeVerificationInfo = """

                            BARCODE ENRICHMENT - Use this data to fill missing fields:
                            \(enrichments.joined(separator: "\n"))
                            Only use serving size if it seems reasonable for the product type.
                            """
                        }
                    }
                }
            }
        }

        // Build rules based on selected options
        var rules: [String] = []
        if cleanOptionUKSpelling {
            rules.append("UK SPELLING: Use British English (fibre, colour, flavour, yoghurt, grey, metre, litre, centre)")
        }
        if cleanOptionTitleCase {
            rules.append("TITLE CASE: Capitalise Every Word In The Product Name. Example: 'chocolate digestive biscuits' → 'Chocolate Digestive Biscuits'. Example: 'ORGANIC WHOLE MILK' → 'Organic Whole Milk'. Every single word must start with a capital letter.")
        }
        if cleanOptionBrands {
            rules.append("BRAND NAMES: Proper capitalisation for brands (Cadbury, Tesco, Sainsbury's, Waitrose, M&S, Co-op, Aldi, Lidl, McVitie's, Kellogg's)")
        }
        if cleanOptionCleanIngredients {
            rules.append("INGREDIENTS: Capitalise The First Letter Of Every Word, use UK spelling, fix typos. Example: 'Sugar, Wheat Flour, Milk Chocolate (Cocoa Butter, Sugar), Palm Oil, Salt'. Remove 'undefined', 'null', or junk text.")
        }
        if cleanOptionFixTypos {
            rules.append("TYPOS: Fix all spelling mistakes and typos in every field")
        }

        // Add smart validation instruction
        var deletionCriteria: [String] = []
        if cleanOptionSmartValidation {
            deletionCriteria = [
                "Name is meaningless, placeholder, or test data",
                "Data appears to be corrupted or encoded incorrectly",
                "Values contain obvious errors that cannot be fixed",
                "Product is clearly not a food item",
                "Ingredients contain 'undefined', 'null', or garbage text that cannot be fixed"
            ]
        }
        if cleanOptionVerifyBarcodes && !barcodeVerificationInfo.isEmpty {
            deletionCriteria.append("Barcode data is completely wrong and cannot be trusted")
        }

        let rulesText = rules.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")

        let deletionText = deletionCriteria.isEmpty ? "" : """

        DELETION CRITERIA - Return {"action":"delete"} if ANY of these apply:
        \(deletionCriteria.enumerated().map { "- \($0.element)" }.joined(separator: "\n"))
        """

        let prompt = """
        You are a food database quality control AI. Clean this data for a UK supermarket database.

        CURRENT DATA:
        - Name: \(row.name)
        - Brand: \(row.brand)
        - Barcode: \(row.barcode)
        - Ingredients: \(row.ingredients.isEmpty ? "(missing)" : row.ingredients.prefix(500))
        - Serving: \(row.servingDescription.isEmpty ? "(missing)" : row.servingDescription)
        - Serving Size (g): \(row.servingSizeG > 0 ? String(row.servingSizeG) : "(missing)")
        - Calories: \(row.calories), Protein: \(row.protein)g, Carbs: \(row.carbs)g, Fat: \(row.fat)g
        \(barcodeVerificationInfo)

        CRITICAL FORMATTING RULES - YOU MUST FOLLOW THESE:
        \(rulesText)

        SERVING SIZE EXTRACTION:
        If the serving description contains a weight (e.g. "1 biscuit (25g)", "Per 30g serving", "2 slices (50g)"), extract the grams value for servingSizeG.
        Only extract if it looks like a reasonable per-serving amount (not the whole pack weight).
        \(deletionText)

        Return ONLY valid JSON, no explanation. Choose ONE:
        1. If data should be DELETED: {"action":"delete"}
        2. If data is OK or can be fixed: {"action":"clean","name":"...","brand":"...","ingredients":"...","serving":"...","servingSizeG":number or null}

        For servingSizeG: extract the grams from serving description if available and reasonable, otherwise null.
        If no changes needed, return original values in the clean response.
        """

        do {
            let response = try await claudeService.askClaude(prompt)

            if let jsonStart = response.firstIndex(of: "{"),
               let jsonEnd = response.lastIndex(of: "}") {
                let jsonString = String(response[jsonStart...jsonEnd])
                if let data = jsonString.data(using: .utf8),
                   let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {

                    // Check if AI recommends deletion
                    if let action = json["action"] as? String, action == "delete" {
                        stagingDb.deleteRow(id: id)
                        return true
                    }

                    // Extract serving size - use AI's extraction if provided, otherwise keep existing
                    var newServingSizeG = row.servingSizeG
                    if let extractedSize = json["servingSizeG"] as? Double, extractedSize > 0 {
                        // Validate it's reasonable (5-500g)
                        if extractedSize >= 5 && extractedSize <= 500 {
                            newServingSizeG = extractedSize
                        }
                    } else if let extractedSize = json["servingSizeG"] as? Int, extractedSize > 0 {
                        if extractedSize >= 5 && extractedSize <= 500 {
                            newServingSizeG = Double(extractedSize)
                        }
                    }

                    // Otherwise apply the cleaned values
                    stagingDb.updateRow(
                        id: id,
                        name: json["name"] as? String ?? row.name,
                        brand: json["brand"] as? String ?? row.brand,
                        barcode: row.barcode,
                        calories: row.calories,
                        protein: row.protein,
                        carbs: row.carbs,
                        fat: row.fat,
                        saturatedFat: row.saturatedFat,
                        fiber: row.fiber,
                        sugar: row.sugar,
                        sodium: row.sodium,
                        servingDescription: json["serving"] as? String ?? row.servingDescription,
                        servingSizeG: newServingSizeG,
                        isPerUnit: row.isPerUnit,
                        ingredients: json["ingredients"] as? String ?? row.ingredients,
                        cleaningStatus: "cleaned"
                    )
                    return true
                }
            }
            stagingDb.setCleaningStatus(id: id, status: "error")
            return false
        } catch {
            stagingDb.setCleaningStatus(id: id, status: "error")
            return false
        }
    }

    // MARK: - Saving

    private func saveSelectedItems() async {
        guard !selectedIds.isEmpty else { return }

        isSaving = true
        saveProgress = 0
        saveError = nil

        let ids = Array(selectedIds)
        var successCount = 0

        for (i, id) in ids.enumerated() {
            if let row = stagingDb.getRow(id: id) {
                let food = row.toFoodItem()
                let success = await algoliaService.saveFood(food, database: .foods)
                if success {
                    successCount += 1
                    stagingDb.deleteRow(id: id)
                }
            }
            saveProgress = Double(i + 1) / Double(ids.count)
        }

        selectedIds.removeAll()
        loadData()

        if successCount < ids.count {
            saveError = "Saved \(successCount)/\(ids.count)"
        }

        isSaving = false
    }

    private func saveAllItems() async {
        isSaving = true
        saveProgress = 0
        saveError = nil

        let allRows = stagingDb.getAllRows()
        var successCount = 0

        for (i, row) in allRows.enumerated() {
            let food = row.toFoodItem()
            let success = await algoliaService.saveFood(food, database: .foods)
            if success {
                successCount += 1
                stagingDb.deleteRow(id: row.id)
            }
            saveProgress = Double(i + 1) / Double(allRows.count)

            if i % 50 == 0 {
                await MainActor.run {
                    totalRowCount = stagingDb.getTotalCount()
                }
            }
        }

        selectedIds.removeAll()
        loadData()

        if successCount < allRows.count {
            saveError = "Saved \(successCount)/\(allRows.count)"
        }

        isSaving = false
    }

    private func saveReadyItems() async {
        isSaving = true
        saveProgress = 0
        saveError = nil

        let readyRows = stagingDb.getReadyRows()
        var successCount = 0

        for (i, row) in readyRows.enumerated() {
            let food = row.toFoodItem()
            let success = await algoliaService.saveFood(food, database: .foods)
            if success {
                successCount += 1
                stagingDb.deleteRow(id: row.id)
            }
            saveProgress = Double(i + 1) / Double(readyRows.count)

            if i % 50 == 0 {
                await MainActor.run {
                    readyCount = stagingDb.getQueueCount(queue: "ready")
                }
            }
        }

        selectedIds.removeAll()
        loadData()

        if successCount < readyRows.count {
            saveError = "Saved \(successCount)/\(readyRows.count)"
        }

        isSaving = false
    }
}

// MARK: - Staging Row View

struct StagingRowView: View {
    let row: StagingFoodRow
    let isSelected: Bool
    let columnOrder: [SortColumn]
    let visibleExtraColumns: Set<String>
    let onToggleSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onToggleSelect) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .buttonStyle(.borderless)
            .frame(width: 30)

            // UK indicator
            if row.isUKBarcode {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .frame(width: 30)
            } else {
                Text("-")
                    .foregroundColor(.secondary.opacity(0.3))
                    .frame(width: 30)
            }

            // Render core columns in the specified order
            ForEach(columnOrder, id: \.self) { column in
                cellView(for: column)
            }

            // Render extra columns
            ForEach(Array(visibleExtraColumns).sorted(), id: \.self) { extraCol in
                Text(row.getExtra(extraCol))
                    .lineLimit(1)
                    .frame(width: 100, alignment: .leading)
                    .font(.caption)
                    .foregroundColor(.orange.opacity(0.8))
            }

            statusBadge
                .frame(width: 70)

            HStack(spacing: 4) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.borderless)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
            }
            .frame(width: 60)
        }
        .font(.callout)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .textSelection(.enabled)  // Allow selecting and copying text
    }

    @ViewBuilder
    private func cellView(for column: SortColumn) -> some View {
        switch column {
        case .id:
            Text("\(row.id)")
                .frame(width: column.width, alignment: column.alignment)
                .foregroundColor(.secondary)
        case .name:
            Text(row.name.isEmpty ? "(no name)" : row.name)
                .lineLimit(1)
                .frame(width: column.width, alignment: column.alignment)
                .foregroundColor(row.name.isEmpty ? .secondary : .primary)
        case .brand:
            Text(row.brand)
                .lineLimit(1)
                .frame(width: column.width, alignment: column.alignment)
                .foregroundColor(.secondary)
        case .barcode:
            Text(row.barcode)
                .lineLimit(1)
                .frame(width: column.width, alignment: column.alignment)
                .font(.caption)
                .foregroundColor(row.barcode.isEmpty ? .secondary : .blue)
        case .servingDesc:
            Text(row.servingDescription.isEmpty ? "-" : row.servingDescription)
                .lineLimit(1)
                .frame(width: column.width, alignment: column.alignment)
                .font(.caption)
                .foregroundColor(row.servingDescription.isEmpty ? .secondary : .primary)
        case .servingSize:
            Text(row.servingSizeG > 0 ? String(format: "%.0f", row.servingSizeG) : "-")
                .frame(width: column.width, alignment: column.alignment)
                .foregroundColor(.secondary)
        case .calories:
            Text(row.calories > 0 ? String(format: "%.0f", row.calories) : "-")
                .frame(width: column.width, alignment: column.alignment)
        case .protein:
            Text(row.protein > 0 ? String(format: "%.1f", row.protein) : "-")
                .frame(width: column.width, alignment: column.alignment)
        case .carbs:
            Text(row.carbs > 0 ? String(format: "%.1f", row.carbs) : "-")
                .frame(width: column.width, alignment: column.alignment)
        case .fat:
            Text(row.fat > 0 ? String(format: "%.1f", row.fat) : "-")
                .frame(width: column.width, alignment: column.alignment)
        case .saturatedFat:
            Text(row.saturatedFat > 0 ? String(format: "%.1f", row.saturatedFat) : "-")
                .frame(width: column.width, alignment: column.alignment)
                .foregroundColor(.secondary)
        case .sugar:
            Text(row.sugar > 0 ? String(format: "%.1f", row.sugar) : "-")
                .frame(width: column.width, alignment: column.alignment)
                .foregroundColor(.secondary)
        case .fiber:
            Text(row.fiber > 0 ? String(format: "%.1f", row.fiber) : "-")
                .frame(width: column.width, alignment: column.alignment)
                .foregroundColor(.secondary)
        case .sodium:
            Text(row.sodium > 0 ? String(format: "%.0f", row.sodium) : "-")
                .frame(width: column.width, alignment: column.alignment)
                .foregroundColor(.secondary)
        case .ingredients:
            Text(row.ingredients.isEmpty ? "-" : String(row.ingredients.prefix(30)) + (row.ingredients.count > 30 ? "..." : ""))
                .lineLimit(1)
                .frame(width: column.width, alignment: column.alignment)
                .font(.caption)
                .foregroundColor(row.ingredients.isEmpty ? .secondary : .primary)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch row.cleaningStatus {
        case "pending":
            Text("Pending")
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.2))
                .foregroundColor(.orange)
                .cornerRadius(4)
        case "cleaning":
            HStack(spacing: 4) {
                ProgressView().scaleEffect(0.5)
                Text("...")
            }
            .font(.caption2)
        case "cleaned":
            HStack(spacing: 2) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Clean")
            }
            .font(.caption2)
            .foregroundColor(.green)
        case "error":
            HStack(spacing: 2) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
                Text("Error")
            }
            .font(.caption2)
            .foregroundColor(.red)
        default:
            Text(row.cleaningStatus)
                .font(.caption2)
        }
    }
}

// MARK: - Edit Row Sheet

struct EditRowSheet: View {
    @State var row: StagingFoodRow
    let onSave: (StagingFoodRow) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Food Item")
                .font(.title2)
                .fontWeight(.bold)

            ScrollView {
                VStack(spacing: 16) {
                    GroupBox("Basic Info") {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Name:").frame(width: 100, alignment: .trailing)
                                TextField("Name", text: $row.name)
                                    .textFieldStyle(.roundedBorder)
                            }
                            HStack {
                                Text("Brand:").frame(width: 100, alignment: .trailing)
                                TextField("Brand", text: $row.brand)
                                    .textFieldStyle(.roundedBorder)
                            }
                            HStack {
                                Text("Barcode:").frame(width: 100, alignment: .trailing)
                                TextField("Barcode", text: $row.barcode)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    GroupBox("Nutrition (per 100g)") {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            numericField("Calories", value: $row.calories)
                            numericField("Protein", value: $row.protein)
                            numericField("Carbs", value: $row.carbs)
                            numericField("Fat", value: $row.fat)
                            numericField("Sat Fat", value: $row.saturatedFat)
                            numericField("Fibre", value: $row.fiber)
                            numericField("Sugar", value: $row.sugar)
                            numericField("Sodium", value: $row.sodium)
                        }
                        .padding(.vertical, 4)
                    }

                    GroupBox("Serving") {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Description:").frame(width: 100, alignment: .trailing)
                                TextField("e.g. 1 biscuit (25g)", text: $row.servingDescription)
                                    .textFieldStyle(.roundedBorder)
                            }
                            HStack {
                                Text("Size (g):").frame(width: 100, alignment: .trailing)
                                TextField("0", value: $row.servingSizeG, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                                Spacer()
                                Toggle("Per Unit", isOn: $row.isPerUnit)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    GroupBox("Ingredients") {
                        TextEditor(text: $row.ingredients)
                            .frame(height: 80)
                            .font(.caption)
                    }
                }
            }
            .frame(height: 420)

            HStack(spacing: 16) {
                Button("Cancel") { onCancel() }
                    .buttonStyle(.bordered)

                Button("Save") { onSave(row) }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(30)
        .frame(width: 550)
    }

    private func numericField(_ label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundColor(.secondary)
            TextField("0", value: value, format: .number.precision(.fractionLength(1)))
                .textFieldStyle(.roundedBorder)
        }
    }
}

// Make StagingFoodRow work with sheet
extension StagingFoodRow: Equatable {
    static func == (lhs: StagingFoodRow, rhs: StagingFoodRow) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Column Drop Delegate

struct ColumnDropDelegate: DropDelegate {
    let item: SortColumn
    @Binding var items: [SortColumn]
    @Binding var draggedItem: SortColumn?

    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedItem = draggedItem,
              draggedItem != item,
              let fromIndex = items.firstIndex(of: draggedItem),
              let toIndex = items.firstIndex(of: item) else {
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            items.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
