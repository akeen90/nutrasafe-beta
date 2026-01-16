//
//  SQLiteFoodDatabase.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-10-21.
//  Local SQLite database for food nutrition data
//  OPTIMIZED: Converted to actor for async queries off main thread
//

import Foundation
import SQLite3

actor SQLiteFoodDatabase {
    static let shared = SQLiteFoodDatabase()

    private var db: OpaquePointer?
    private let dbPath: String
    private var isInitialized = false
    private var ftsAvailable = false
    private var ftsInitialized = false  // PERFORMANCE: Track FTS lazy initialization

    private init() {
        // Store database in app's documents directory
        let fileManager = FileManager.default
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            // Fallback: Use temporary directory if documents directory is unavailable (extremely rare)
            let tempDirectory = fileManager.temporaryDirectory
            dbPath = tempDirectory.appendingPathComponent("nutrasafe_foods.db").path
                        return
        }
        dbPath = documentDirectory.appendingPathComponent("nutrasafe_foods.db").path

            }

    /// Perform database initialization
    private func performInitialization() {
        guard !isInitialized else { return }

        copyDatabaseFromBundleIfNeeded()
        openDatabase()
        createTables()
        checkAndImportInitialData()
        isInitialized = true
            }

    /// Ensure database is initialized before use
    private func ensureInitialized() async {
        if !isInitialized {
            performInitialization()
        }
    }

    private func copyDatabaseFromBundleIfNeeded() {
        let fileManager = FileManager.default

        // Find database in app bundle - try multiple methods
        var bundlePath: String?

        // Method 1: Try standard resource lookup
        if let path = Bundle.main.path(forResource: "nutrasafe_foods", ofType: "db") {
            bundlePath = path
                    }
        // Method 2: Try URL-based lookup
        else if let url = Bundle.main.url(forResource: "nutrasafe_foods", withExtension: "db") {
            bundlePath = url.path
                    }
        // Method 3: Try direct bundle path
        else {
            let directPath = Bundle.main.bundlePath + "/nutrasafe_foods.db"
            if fileManager.fileExists(atPath: directPath) {
                bundlePath = directPath
                            }
        }

        guard let bundlePath = bundlePath else {
                        return
        }

        
        // Always force refresh by comparing file sizes OR modification dates
        // This ensures new data is picked up even if dates are similar
        var shouldCopy = false

        if fileManager.fileExists(atPath: dbPath) {
            do {
                let bundleAttributes = try fileManager.attributesOfItem(atPath: bundlePath)
                let docsAttributes = try fileManager.attributesOfItem(atPath: dbPath)

                let bundleSize = bundleAttributes[.size] as? Int64 ?? 0
                let docsSize = docsAttributes[.size] as? Int64 ?? 0

                // Check both size and modification date
                if let bundleDate = bundleAttributes[.modificationDate] as? Date,
                   let docsDate = docsAttributes[.modificationDate] as? Date {

                    // If size is different OR bundle is newer, update
                    if bundleSize != docsSize || bundleDate > docsDate {
                                                shouldCopy = true

                        // Remove old database
                        try fileManager.removeItem(atPath: dbPath)
                    } else {
                                            }
                }
            } catch {
                            }
        } else {
            // Database doesn't exist, copy it
            shouldCopy = true
                    }

        // Copy from bundle to Documents if needed
        if shouldCopy {
            do {
                try fileManager.copyItem(atPath: bundlePath, toPath: dbPath)
                } catch {
                            }
        }
    }

    // MARK: - Database Setup

    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            // Note: Database operations will fail gracefully if db is nil
            return
        }
            }

    private func createTables() {
        let createFoodsTable = """
        CREATE TABLE IF NOT EXISTS foods (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            brand TEXT,
            barcode TEXT,

            -- Macronutrients (per 100g)
            calories REAL NOT NULL,
            protein REAL NOT NULL,
            carbs REAL NOT NULL,
            fat REAL NOT NULL,
            fiber REAL NOT NULL,
            sugar REAL NOT NULL,
            sodium REAL NOT NULL,

            -- Serving info
            serving_description TEXT,
            serving_size_g REAL,

            -- Micronutrients (per 100g) - Vitamins
            vitamin_a REAL DEFAULT 0,
            vitamin_c REAL DEFAULT 0,
            vitamin_d REAL DEFAULT 0,
            vitamin_e REAL DEFAULT 0,
            vitamin_k REAL DEFAULT 0,
            thiamin_b1 REAL DEFAULT 0,
            riboflavin_b2 REAL DEFAULT 0,
            niacin_b3 REAL DEFAULT 0,
            pantothenic_b5 REAL DEFAULT 0,
            vitamin_b6 REAL DEFAULT 0,
            biotin_b7 REAL DEFAULT 0,
            folate_b9 REAL DEFAULT 0,
            vitamin_b12 REAL DEFAULT 0,
            choline REAL DEFAULT 0,

            -- Micronutrients (per 100g) - Minerals
            calcium REAL DEFAULT 0,
            iron REAL DEFAULT 0,
            magnesium REAL DEFAULT 0,
            phosphorus REAL DEFAULT 0,
            potassium REAL DEFAULT 0,
            zinc REAL DEFAULT 0,
            copper REAL DEFAULT 0,
            manganese REAL DEFAULT 0,
            selenium REAL DEFAULT 0,
            chromium REAL DEFAULT 0,
            molybdenum REAL DEFAULT 0,
            iodine REAL DEFAULT 0,

            -- Processing & Safety
            processing_score INTEGER,
            processing_grade TEXT,
            processing_label TEXT,

            -- Metadata
            is_verified BOOLEAN DEFAULT 0,
            verified_by TEXT,
            verified_at INTEGER,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
        );
        """

        let createBarcodeIndex = """
        CREATE INDEX IF NOT EXISTS idx_foods_barcode ON foods(barcode);
        """

        let createNameIndex = """
        CREATE INDEX IF NOT EXISTS idx_foods_name ON foods(name COLLATE NOCASE);
        """

        let createBrandIndex = """
        CREATE INDEX IF NOT EXISTS idx_foods_brand ON foods(brand COLLATE NOCASE);
        """

        let createIngredientsTable = """
        CREATE TABLE IF NOT EXISTS food_ingredients (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            food_id TEXT NOT NULL,
            ingredient TEXT NOT NULL,
            position INTEGER NOT NULL,
            FOREIGN KEY(food_id) REFERENCES foods(id) ON DELETE CASCADE
        );
        """

        let createIngredientsIndex = """
        CREATE INDEX IF NOT EXISTS idx_ingredients_food_id ON food_ingredients(food_id);
        """

        let createIngredientsSearchIndex = """
        CREATE INDEX IF NOT EXISTS idx_ingredients_text ON food_ingredients(ingredient COLLATE NOCASE);
        """

        let createAdditivesTable = """
        CREATE TABLE IF NOT EXISTS food_additives (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            food_id TEXT NOT NULL,
            additive_code TEXT NOT NULL,
            additive_name TEXT,
            safety_rating TEXT,
            FOREIGN KEY(food_id) REFERENCES foods(id) ON DELETE CASCADE
        );
        """

        let createAdditivesIndex = """
        CREATE INDEX IF NOT EXISTS idx_additives_food_id ON food_additives(food_id);
        """

        let createFTSTable = """
        CREATE VIRTUAL TABLE IF NOT EXISTS foods_fts USING fts5(
            id UNINDEXED,
            name,
            brand,
            ingredients
        );
        """

        // Execute all SQL statements
        executeSQL(createFoodsTable)
        executeSQL(createBarcodeIndex)
        executeSQL(createNameIndex)
        executeSQL(createBrandIndex)
        executeSQL(createIngredientsTable)
        executeSQL(createIngredientsIndex)
        executeSQL(createIngredientsSearchIndex)
        executeSQL(createAdditivesTable)
        executeSQL(createAdditivesIndex)
        executeSQL(createFTSTable)

        ftsAvailable = tableExists("foods_fts")
        // PERFORMANCE: Don't rebuild FTS on init - do it lazily on first search
        // This saves 400ms on app startup
    }

    private func executeSQL(_ sql: String) {
        guard let db = db else {
                        return
        }

        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) != SQLITE_DONE {
                if let errorCString = sqlite3_errmsg(db) {
                    let errorMessage = String(cString: errorCString)
                                    }
            }
        } else {
            if let errorCString = sqlite3_errmsg(db) {
                let errorMessage = String(cString: errorCString)
                            }
        }

        sqlite3_finalize(statement)
    }

    private func tableExists(_ name: String) -> Bool {
        var statement: OpaquePointer?
        let query = "SELECT name FROM sqlite_master WHERE type='table' AND name=?;"
        var exists = false
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (name as NSString).utf8String, -1, nil)
            if sqlite3_step(statement) == SQLITE_ROW { exists = true }
        }
        sqlite3_finalize(statement)
        return exists
    }

    private func rebuildFTSIndex() {
        var statement: OpaquePointer?
        let deleteSQL = "DELETE FROM foods_fts;"
        _ = sqlite3_exec(db, deleteSQL, nil, nil, nil)
        let insertSQL = """
        INSERT INTO foods_fts (id, name, brand, ingredients)
        SELECT f.id, f.name, IFNULL(f.brand,''), IFNULL((
            SELECT GROUP_CONCAT(ingredient, ' ')
            FROM food_ingredients fi WHERE fi.food_id = f.id
        ), '')
        FROM foods f;
        """
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW { }
        }
        sqlite3_finalize(statement)
    }

    private func checkAndImportInitialData() {
        // Check if database has any foods
        var statement: OpaquePointer?
        let query = "SELECT COUNT(*) FROM foods;"

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                let count = sqlite3_column_int(statement, 0)

                }
        }
        sqlite3_finalize(statement)
    }

    // MARK: - Search Operations

    /// Search foods by name, brand, or barcode with intelligent fuzzy ranking
    func searchFoods(query: String, limit: Int = 20) async -> [FoodSearchResult] {
        await ensureInitialized()

        // PERFORMANCE: Lazy FTS index rebuild (background, non-blocking)
        // Only rebuild on first search to avoid 400ms app startup delay
        if ftsAvailable && !ftsInitialized {
            ftsInitialized = true
            Task.detached(priority: .utility) {
                await self.rebuildFTSIndex()
                            }
        }

        let sql = """
        SELECT
            id, name, brand, barcode,
            calories, protein, carbs, fat, fiber, sugar, sodium,
            serving_description, serving_size_g,
            vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k,
            thiamin_b1, riboflavin_b2, niacin_b3, pantothenic_b5,
            vitamin_b6, biotin_b7, folate_b9, vitamin_b12, choline,
            calcium, iron, magnesium, phosphorus, potassium,
            zinc, copper, manganese, selenium, chromium, molybdenum, iodine,
            processing_score, processing_grade, processing_label,
            is_verified,
            ingredients
        FROM foods
        WHERE name LIKE ? COLLATE NOCASE OR brand LIKE ? COLLATE NOCASE OR barcode = ?
        ORDER BY
            CASE
                -- Priority 0: Generic brand items that start with the query (highest priority for fruits/veg)
                -- This ensures "Banana (small)" from Generic brand appears before "Banana Loaf" from Soreen
                WHEN LOWER(brand) = 'generic' AND name LIKE ? COLLATE NOCASE THEN 0

                -- Priority 1: Exact barcode match
                WHEN barcode = ? THEN 1

                -- Priority 2: Exact name match (case insensitive)
                WHEN LOWER(name) = LOWER(?) THEN 2

                -- Priority 3: Name starts with query followed by comma/space/parenthesis (e.g., "Banana, raw" or "Banana (small)")
                -- These are likely generic/unprocessed items
                WHEN name LIKE ? COLLATE NOCASE OR name LIKE ? COLLATE NOCASE OR name LIKE ? COLLATE NOCASE THEN 3

                -- Priority 4: Name starts with query (whole word) but no comma/space immediately after
                WHEN name LIKE ? COLLATE NOCASE THEN 4

                -- Priority 5: Name contains query as whole word with spaces
                WHEN name LIKE ? COLLATE NOCASE OR name LIKE ? COLLATE NOCASE THEN 5

                -- Priority 6: Brand starts with query
                WHEN brand LIKE ? COLLATE NOCASE THEN 6

                -- Priority 7: Name contains query anywhere
                WHEN name LIKE ? COLLATE NOCASE THEN 7

                -- Priority 8: Brand contains query
                WHEN brand LIKE ? COLLATE NOCASE THEN 8

                ELSE 9
            END,
            -- Secondary sort: Generic brand items first within same priority
            CASE WHEN LOWER(brand) = 'generic' THEN 0 ELSE 1 END,
            -- Tertiary sort: shorter names first (more likely to be exact item)
            LENGTH(name) ASC,
            -- Quaternary sort: alphabetical
            name ASC
        LIMIT ?;
        """

        var statement: OpaquePointer?
        var results: [FoodSearchResult] = []

        let queryLower = query.lowercased()
        let searchPattern = "%\(query)%"
        let startsWithQuery = "\(query)%"
        let startsWithComma = "\(query),%"
        let startsWithDash = "\(query) -%"
        let startsWithParen = "\(query) (%"
        let wholeWordSpace = "% \(query) %"
        let wholeWordStart = "\(query) %"

        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            // WHERE clause bindings
            sqlite3_bind_text(statement, 1, (searchPattern as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (searchPattern as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (query as NSString).utf8String, -1, nil)

            // ORDER BY clause bindings
            sqlite3_bind_text(statement, 4, (startsWithQuery as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 5, (query as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 6, (queryLower as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 7, (startsWithComma as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 8, (startsWithDash as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 9, (startsWithParen as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 10, (startsWithQuery as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 11, (wholeWordSpace as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 12, (wholeWordStart as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 13, (startsWithQuery as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 14, (searchPattern as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 15, (searchPattern as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 16, Int32(limit * 2))

            var rowCount = 0
            while sqlite3_step(statement) == SQLITE_ROW {
                rowCount += 1
                if let food = parseFoodRow(statement: statement) {
                    results.append(food)
                } else {
                                    }
            }
                    } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
                    }

        sqlite3_finalize(statement)

        // Return only the requested limit
        return Array(results.prefix(limit))
    }

    /// Search by barcode (exact match) - async
    func searchByBarcode(_ barcode: String) async -> FoodSearchResult? {
        await ensureInitialized()

        let sql = """
        SELECT
            id, name, brand, barcode,
            calories, protein, carbs, fat, fiber, sugar, sodium,
            serving_description, serving_size_g,
            vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k,
            thiamin_b1, riboflavin_b2, niacin_b3, pantothenic_b5,
            vitamin_b6, biotin_b7, folate_b9, vitamin_b12, choline,
            calcium, iron, magnesium, phosphorus, potassium,
            zinc, copper, manganese, selenium, chromium, molybdenum, iodine,
            processing_score, processing_grade, processing_label,
            is_verified,
            ingredients
        FROM foods
        WHERE barcode = ?
        LIMIT 1;
        """

        var statement: OpaquePointer?
        var result: FoodSearchResult?

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (barcode as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_ROW {
                result = parseFoodRow(statement: statement)
            }
        }

        sqlite3_finalize(statement)
        return result
    }

    /// Get food by ID - async
    func getFoodById(_ id: String) async -> FoodSearchResult? {
        await ensureInitialized()

        let sql = """
        SELECT
            id, name, brand, barcode,
            calories, protein, carbs, fat, fiber, sugar, sodium,
            serving_description, serving_size_g,
            vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k,
            thiamin_b1, riboflavin_b2, niacin_b3, pantothenic_b5,
            vitamin_b6, biotin_b7, folate_b9, vitamin_b12, choline,
            calcium, iron, magnesium, phosphorus, potassium,
            zinc, copper, manganese, selenium, chromium, molybdenum, iodine,
            processing_score, processing_grade, processing_label,
            is_verified,
            ingredients
        FROM foods
        WHERE id = ?
        LIMIT 1;
        """

        var statement: OpaquePointer?
        var result: FoodSearchResult?

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (id as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_ROW {
                result = parseFoodRow(statement: statement)
            }
        }

        sqlite3_finalize(statement)
        return result
    }

    // MARK: - Helper Methods

    private func parseFoodRow(statement: OpaquePointer?) -> FoodSearchResult? {
        guard let statement = statement else { return nil }

        guard let idText = sqlite3_column_text(statement, 0),
              let nameText = sqlite3_column_text(statement, 1) else {
            return nil
        }

        let id = String(cString: idText)
        let name = String(cString: nameText)
        let brand = sqlite3_column_text(statement, 2) != nil ? String(cString: sqlite3_column_text(statement, 2)) : nil
        let barcode = sqlite3_column_text(statement, 3) != nil ? String(cString: sqlite3_column_text(statement, 3)) : nil

        let calories = sqlite3_column_double(statement, 4)
        let protein = sqlite3_column_double(statement, 5)
        let carbs = sqlite3_column_double(statement, 6)
        let fat = sqlite3_column_double(statement, 7)
        let fiber = sqlite3_column_double(statement, 8)
        let sugar = sqlite3_column_double(statement, 9)
        let sodium = sqlite3_column_double(statement, 10)

        let servingDescription = sqlite3_column_text(statement, 11) != nil ? String(cString: sqlite3_column_text(statement, 11)) : nil
        let servingSizeG = sqlite3_column_double(statement, 12)

        // Extract micronutrients into profile
        let vitamins: [String: Double] = [
            "vitaminA": sqlite3_column_double(statement, 13),
            "vitaminC": sqlite3_column_double(statement, 14),
            "vitaminD": sqlite3_column_double(statement, 15),
            "vitaminE": sqlite3_column_double(statement, 16),
            "vitaminK": sqlite3_column_double(statement, 17),
            "thiamine": sqlite3_column_double(statement, 18),
            "riboflavin": sqlite3_column_double(statement, 19),
            "niacin": sqlite3_column_double(statement, 20),
            "pantothenicAcid": sqlite3_column_double(statement, 21),
            "vitaminB6": sqlite3_column_double(statement, 22),
            "biotin": sqlite3_column_double(statement, 23),
            "folate": sqlite3_column_double(statement, 24),
            "vitaminB12": sqlite3_column_double(statement, 25),
            "choline": sqlite3_column_double(statement, 26)
        ]

        let minerals: [String: Double] = [
            "calcium": sqlite3_column_double(statement, 27),
            "iron": sqlite3_column_double(statement, 28),
            "magnesium": sqlite3_column_double(statement, 29),
            "phosphorus": sqlite3_column_double(statement, 30),
            "potassium": sqlite3_column_double(statement, 31),
            "zinc": sqlite3_column_double(statement, 32),
            "copper": sqlite3_column_double(statement, 33),
            "manganese": sqlite3_column_double(statement, 34),
            "selenium": sqlite3_column_double(statement, 35),
            "chromium": sqlite3_column_double(statement, 36),
            "molybdenum": sqlite3_column_double(statement, 37),
            "iodine": sqlite3_column_double(statement, 38)
        ]

        let processingScore = sqlite3_column_int(statement, 39)
        let processingGrade = sqlite3_column_text(statement, 40) != nil ? String(cString: sqlite3_column_text(statement, 40)) : nil
        let processingLabel = sqlite3_column_text(statement, 41) != nil ? String(cString: sqlite3_column_text(statement, 41)) : nil
        let isVerified = sqlite3_column_int(statement, 42) == 1

        // Parse ingredients from the ingredients column (comma-separated string)
        var ingredients: [String]? = nil
        if let ingredientsText = sqlite3_column_text(statement, 43) {
            let ingredientsString = String(cString: ingredientsText)
            if !ingredientsString.isEmpty {
                // Try splitting by ", " first (comma + space), then fallback to just ","
                let separated = ingredientsString.components(separatedBy: ", ")
                if separated.count > 1 {
                    ingredients = separated
                } else {
                    // Fallback: split by comma only and trim whitespace
                    ingredients = ingredientsString.components(separatedBy: ",").map {
                        $0.trimmingCharacters(in: .whitespaces)
                    }
                }
            }
        }

        // Create micronutrient profile from vitamins and minerals
        let recommendedIntakes = RecommendedIntakes(age: 25, gender: .other, dailyValues: [:])
        let micronutrientProfile = MicronutrientProfile(
            vitamins: vitamins,
            minerals: minerals,
            recommendedIntakes: recommendedIntakes,
            confidenceScore: .high  // High confidence for internal database foods
        )

        return FoodSearchResult(
            id: id,
            name: name,
            brand: brand,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            servingDescription: servingDescription,
            servingSizeG: servingSizeG > 0 ? servingSizeG : nil,
            ingredients: ingredients,
            confidence: 1.0, // Local database = 100% confidence
            isVerified: isVerified,
            additives: nil,
            additivesDatabaseVersion: nil,
            processingScore: processingScore != 0 ? Int(processingScore) : nil,
            processingGrade: processingGrade,
            processingLabel: processingLabel,
            barcode: barcode,
            micronutrientProfile: micronutrientProfile
        )
    }

    private func getIngredients(for foodId: String) -> [String]? {
        let sql = "SELECT ingredient FROM food_ingredients WHERE food_id = ? ORDER BY position ASC;"

        var statement: OpaquePointer?
        var ingredients: [String] = []

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (foodId as NSString).utf8String, -1, nil)

            while sqlite3_step(statement) == SQLITE_ROW {
                let ingredient = String(cString: sqlite3_column_text(statement, 0))
                ingredients.append(ingredient)
            }
        }

        sqlite3_finalize(statement)
        return ingredients.isEmpty ? nil : ingredients
    }

    // MARK: - Import Operations

    /// Get database statistics
    func getStats() -> (totalFoods: Int, withBarcodes: Int, verified: Int) {
        var statement: OpaquePointer?
        let sql = """
        SELECT
            COUNT(*) as total,
            SUM(CASE WHEN barcode IS NOT NULL THEN 1 ELSE 0 END) as with_barcodes,
            SUM(CASE WHEN is_verified = 1 THEN 1 ELSE 0 END) as verified
        FROM foods;
        """

        var total = 0, withBarcodes = 0, verified = 0

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                total = Int(sqlite3_column_int(statement, 0))
                withBarcodes = Int(sqlite3_column_int(statement, 1))
                verified = Int(sqlite3_column_int(statement, 2))
            }
        }

        sqlite3_finalize(statement)
        return (total, withBarcodes, verified)
    }

    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }
}
