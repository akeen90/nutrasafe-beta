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

    private init() {
        // Store database in app's documents directory
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        dbPath = documentDirectory.appendingPathComponent("nutrasafe_foods.db").path

        print("📂 SQLite database path: \(dbPath)")

        // Copy database from bundle to documents if needed
        copyDatabaseFromBundleIfNeeded()

        // Open/create database
        openDatabase()

        // Create tables if needed
        createTables()

        // Check if we need to import initial data
        checkAndImportInitialData()
    }

    private func copyDatabaseFromBundleIfNeeded() {
        let fileManager = FileManager.default

        // Find database in app bundle - try multiple methods
        var bundlePath: String?

        // Method 1: Try standard resource lookup
        if let path = Bundle.main.path(forResource: "nutrasafe_foods", ofType: "db") {
            bundlePath = path
            print("✅ Found database using path(forResource:)")
        }
        // Method 2: Try URL-based lookup
        else if let url = Bundle.main.url(forResource: "nutrasafe_foods", withExtension: "db") {
            bundlePath = url.path
            print("✅ Found database using url(forResource:)")
        }
        // Method 3: Try direct bundle path
        else {
            let directPath = Bundle.main.bundlePath + "/nutrasafe_foods.db"
            if fileManager.fileExists(atPath: directPath) {
                bundlePath = directPath
                print("✅ Found database using direct bundle path")
            }
        }

        guard let bundlePath = bundlePath else {
            print("⚠️ Database not found in app bundle - searched all locations")
            print("   Bundle path: \(Bundle.main.bundlePath)")
            return
        }

        print("📦 Bundle database path: \(bundlePath)")

        // Check if we should update the database
        var shouldCopy = false

        if fileManager.fileExists(atPath: dbPath) {
            // Compare modification dates - if bundle DB is newer, replace it
            do {
                let bundleAttributes = try fileManager.attributesOfItem(atPath: bundlePath)
                let docsAttributes = try fileManager.attributesOfItem(atPath: dbPath)

                if let bundleDate = bundleAttributes[.modificationDate] as? Date,
                   let docsDate = docsAttributes[.modificationDate] as? Date {

                    if bundleDate > docsDate {
                        print("📦 Bundle database is newer - updating...")
                        print("   Bundle date: \(bundleDate)")
                        print("   Docs date: \(docsDate)")
                        shouldCopy = true

                        // Remove old database
                        try fileManager.removeItem(atPath: dbPath)
                    } else {
                        print("✅ Database already exists and is up to date")
                    }
                }
            } catch {
                print("⚠️ Could not compare database dates: \(error.localizedDescription)")
                print("   Keeping existing database")
            }
        } else {
            // Database doesn't exist, copy it
            shouldCopy = true
        }

        // Copy from bundle to Documents if needed
        if shouldCopy {
            do {
                try fileManager.copyItem(atPath: bundlePath, toPath: dbPath)
                print("✅ Copied database from bundle to Documents directory")
                print("   Bundle: \(bundlePath)")
                print("   Target: \(dbPath)")
            } catch {
                print("❌ Failed to copy database: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Database Setup

    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("❌ Error opening database")
            return
        }
        print("✅ SQLite database opened successfully")
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
    }

    private func executeSQL(_ sql: String) {
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) != SQLITE_DONE {
                let errorMessage = String(cString: sqlite3_errmsg(db)!)
                print("❌ SQL execution error: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db)!)
            print("❌ SQL preparation error: \(errorMessage)")
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
                print("📊 Current food count in SQLite: \(count)")

                if count == 0 {
                    print("⚠️ Database is empty. You need to import data from Firebase or a CSV file.")
                    print("   Run the export script: node firebase/scripts/exportToSQLite.js")
                }
            }
        }
        sqlite3_finalize(statement)
    }

    // MARK: - Search Operations

    /// Search foods by name, brand, or barcode (async - runs off main thread)
    func searchFoods(query: String, limit: Int = 20) async -> [FoodSearchResult] {
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
        WHERE name LIKE ? OR brand LIKE ? OR barcode = ?
        ORDER BY
            CASE
                WHEN barcode = ? THEN 1
                WHEN name LIKE ? THEN 2
                WHEN brand LIKE ? THEN 3
                ELSE 4
            END,
            name ASC
        LIMIT ?;
        """

        var statement: OpaquePointer?
        var results: [FoodSearchResult] = []

        let searchPattern = "%\(query)%"
        let exactName = "\(query)%"
        let exactBrand = "\(query)%"

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (searchPattern as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (searchPattern as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (query as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, (query as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 5, (exactName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 6, (exactBrand as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 7, Int32(limit))

            while sqlite3_step(statement) == SQLITE_ROW {
                if let food = parseFoodRow(statement: statement) {
                    results.append(food)
                }
            }
        }

        sqlite3_finalize(statement)
        return results
    }

    /// Search by barcode (exact match) - async
    func searchByBarcode(_ barcode: String) async -> FoodSearchResult? {
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
                ingredients = ingredientsString.components(separatedBy: ", ")
            }
        }

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
            additives: nil, // TODO: Load from additives table
            additivesDatabaseVersion: nil,
            processingScore: processingScore != 0 ? Int(processingScore) : nil,
            processingGrade: processingGrade,
            processingLabel: processingLabel,
            barcode: barcode
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

    /// Insert or update a food item
    func upsertFood(_ food: FoodSearchResult, ingredients: [String]?, vitamins: [String: Double]?, minerals: [String: Double]?) -> Bool {
        // TODO: Implement food insertion/update
        // This will be used by the import script
        return false
    }

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
