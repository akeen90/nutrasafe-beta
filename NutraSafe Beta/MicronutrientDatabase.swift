//
//  MicronutrientDatabase.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-10-21.
//  SQLite wrapper for comprehensive micronutrient intelligence system
//

import Foundation
import SQLite3

// MARK: - Data Models

/// Represents a single ingredient with its micronutrient profile
struct MicronutrientIngredient {
    let id: Int
    let name: String
    let category: String?
    let nutrients: [NutrientStrength]
}

/// Nutrient with strength level for an ingredient
struct NutrientStrength {
    let nutrient: String
    let strength: Strength

    enum Strength: String {
        case trace = "trace"
        case moderate = "moderate"
        case strong = "strong"

        /// Numeric value for scoring: trace=1, moderate=2, strong=3
        var points: Int {
            switch self {
            case .trace: return 1
            case .moderate: return 2
            case .strong: return 3
            }
        }
    }
}

/// Comprehensive nutrient information for educational display
struct NutrientInfo {
    let nutrient: String
    let name: String
    let category: String?
    let benefits: String?
    let deficiencySigns: String?
    let commonSources: String?
    let recommendedDailyIntake: String?
}

/// Synonym mapping for ingredient name normalization
struct IngredientSynonym {
    let altName: String
    let canonical: String
}

/// Token mapping for micronutrient detection
struct MicronutrientToken {
    let token: String
    let nutrient: String
}

// MARK: - SQLite Database Manager

class MicronutrientDatabase {
    static let shared = MicronutrientDatabase()

    private var db: OpaquePointer?
    private var isInitialized = false

    private init() {
        openDatabase()
    }

    deinit {
        closeDatabase()
    }

    // MARK: - Database Connection

    private func openDatabase() {
        guard let dbPath = Bundle.main.path(forResource: "micronutrients_ingredients_v6", ofType: "db") else {
            print("❌ MicronutrientDatabase: Database file not found in bundle")
            return
        }

        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            print("✅ MicronutrientDatabase: Successfully opened database at \(dbPath)")
            isInitialized = true

            // DIAGNOSTIC: Test database readability
            testDatabaseConnection()
        } else {
            print("❌ MicronutrientDatabase: Failed to open database")
            if let error = sqlite3_errmsg(db) {
                print("   Error: \(String(cString: error))")
            }
        }
    }

    private func testDatabaseConnection() {
        guard let db = db else { return }

        // Test 1: Count total nutrients
        let countQuery = "SELECT COUNT(*) FROM nutrient_info;"
        var countStmt: OpaquePointer?

        defer { sqlite3_finalize(countStmt) }

        if sqlite3_prepare_v2(db, countQuery, -1, &countStmt, nil) == SQLITE_OK {
            if sqlite3_step(countStmt) == SQLITE_ROW {
                let count = sqlite3_column_int(countStmt, 0)
                print("📊 Database contains \(count) nutrients")
            }
        }

        // Test 2: List all nutrient IDs
        let listQuery = "SELECT nutrient FROM nutrient_info ORDER BY nutrient LIMIT 10;"
        var listStmt: OpaquePointer?

        defer { sqlite3_finalize(listStmt) }

        if sqlite3_prepare_v2(db, listQuery, -1, &listStmt, nil) == SQLITE_OK {
            print("📋 First 10 nutrients in database:")
            var index = 1
            while sqlite3_step(listStmt) == SQLITE_ROW {
                let nutrient = String(cString: sqlite3_column_text(listStmt, 0))
                print("   \(index). \(nutrient)")
                index += 1
            }
        }

        // Test 3: Try to query a specific nutrient
        let testQuery = "SELECT nutrient, name FROM nutrient_info WHERE nutrient = 'Niacin_B3' LIMIT 1;"
        var testStmt: OpaquePointer?

        defer { sqlite3_finalize(testStmt) }

        if sqlite3_prepare_v2(db, testQuery, -1, &testStmt, nil) == SQLITE_OK {
            if sqlite3_step(testStmt) == SQLITE_ROW {
                let nutrient = String(cString: sqlite3_column_text(testStmt, 0))
                let name = String(cString: sqlite3_column_text(testStmt, 1))
                print("✅ Test query successful: Found '\(nutrient)' with name '\(name)'")
            } else {
                print("❌ Test query failed: Could not find 'Niacin_B3'")
            }
        } else {
            print("❌ Test query prepare failed")
        }
    }

    private func closeDatabase() {
        if db != nil {
            sqlite3_close(db)
            db = nil
            isInitialized = false
        }
    }

    // MARK: - Synonym Lookup

    /// Get canonical name for an ingredient, applying synonyms
    func canonicalize(_ name: String) -> String {
        let lowercased = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if this is a synonym
        if let canonical = lookupSynonym(lowercased) {
            return canonical
        }

        return lowercased
    }

    private func lookupSynonym(_ altName: String) -> String? {
        guard isInitialized, let db = db else { return nil }

        let query = "SELECT canonical FROM synonyms WHERE alt_name = ? LIMIT 1;"
        var statement: OpaquePointer?

        defer {
            sqlite3_finalize(statement)
        }

        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return nil
        }

        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(statement, 1, (altName as NSString).utf8String, -1, SQLITE_TRANSIENT)

        if sqlite3_step(statement) == SQLITE_ROW {
            if let cString = sqlite3_column_text(statement, 0) {
                return String(cString: cString)
            }
        }

        return nil
    }

    // MARK: - Ingredient Lookup

    /// Look up an ingredient by name and return its micronutrient profile
    func lookupIngredient(_ name: String) -> MicronutrientIngredient? {
        guard isInitialized, let db = db else { return nil }

        let canonicalName = canonicalize(name)

        // First get the ingredient details
        let ingredientQuery = "SELECT id, name, category FROM ingredients WHERE name = ? LIMIT 1;"
        var ingredientStmt: OpaquePointer?

        defer {
            sqlite3_finalize(ingredientStmt)
        }

        guard sqlite3_prepare_v2(db, ingredientQuery, -1, &ingredientStmt, nil) == SQLITE_OK else {
            return nil
        }

        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(ingredientStmt, 1, (canonicalName as NSString).utf8String, -1, SQLITE_TRANSIENT)

        guard sqlite3_step(ingredientStmt) == SQLITE_ROW else {
            return nil
        }

        let id = Int(sqlite3_column_int(ingredientStmt, 0))
        let ingredientName = String(cString: sqlite3_column_text(ingredientStmt, 1))
        let category = sqlite3_column_text(ingredientStmt, 2).map { String(cString: $0) }

        // Now get all nutrients for this ingredient
        let nutrients = lookupNutrientsForIngredient(id: id)

        return MicronutrientIngredient(
            id: id,
            name: ingredientName,
            category: category,
            nutrients: nutrients
        )
    }

    private func lookupNutrientsForIngredient(id: Int) -> [NutrientStrength] {
        guard isInitialized, let db = db else { return [] }

        let query = "SELECT nutrient, strength FROM nutrients WHERE ingredient_id = ?;"
        var statement: OpaquePointer?
        var results: [NutrientStrength] = []

        defer {
            sqlite3_finalize(statement)
        }

        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return []
        }

        sqlite3_bind_int(statement, 1, Int32(id))

        while sqlite3_step(statement) == SQLITE_ROW {
            let nutrient = String(cString: sqlite3_column_text(statement, 0))
            let strengthStr = String(cString: sqlite3_column_text(statement, 1))

            if let strength = NutrientStrength.Strength(rawValue: strengthStr) {
                results.append(NutrientStrength(nutrient: nutrient, strength: strength))
            }
        }

        return results
    }

    // MARK: - Token Matching

    /// Check if food name contains micronutrient tokens (e.g., "multivitamin" → vitamin_supplement)
    func matchTokens(in foodName: String) -> [String] {
        guard isInitialized, let db = db else { return [] }

        let lowercased = foodName.lowercased()
        let query = "SELECT DISTINCT nutrient FROM micronutrient_tokens WHERE ? LIKE '%' || token || '%';"
        var statement: OpaquePointer?
        var matchedNutrients: [String] = []

        defer {
            sqlite3_finalize(statement)
        }

        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return []
        }

        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(statement, 1, (lowercased as NSString).utf8String, -1, SQLITE_TRANSIENT)

        while sqlite3_step(statement) == SQLITE_ROW {
            let nutrient = String(cString: sqlite3_column_text(statement, 0))
            matchedNutrients.append(nutrient)
        }

        return matchedNutrients
    }

    // MARK: - Nutrient Info

    /// Get comprehensive information about a nutrient
    func getNutrientInfo(_ nutrient: String) -> NutrientInfo? {
        guard isInitialized, let db = db else { return nil }

        // Map detector IDs to database IDs
        let nutrientMapping: [String: String] = [
            // Vitamins with specific names
            "vitamin_a": "Vitamin_A",
            "vitamin_b1": "Thiamin_B1",
            "vitamin_b2": "Riboflavin_B2",
            "vitamin_b3": "Niacin_B3",
            "vitamin_b5": "Pantothenic_B5",
            "vitamin_b6": "Vitamin_B6",
            "vitamin_b7": "Biotin_B7",
            "vitamin_b9": "Folate_B9",
            "vitamin_b12": "Vitamin_B12",
            "vitamin_c": "Vitamin_C",
            "vitamin_d": "Vitamin_D",
            "vitamin_e": "Vitamin_E",
            "vitamin_k": "Vitamin_K",

            // Alternative names
            "biotin": "Biotin_B7",
            "folate": "Folate_B9",
            "beta_carotene": "Beta_Carotene",

            // Minerals (capitalize first letter)
            "calcium": "Calcium",
            "iron": "Iron",
            "magnesium": "Magnesium",
            "potassium": "Potassium",
            "zinc": "Zinc",
            "selenium": "Selenium",
            "phosphorus": "Phosphorus",
            "copper": "Copper",
            "manganese": "Manganese",
            "iodine": "Iodine",
            "chromium": "Chromium",
            "molybdenum": "Molybdenum",
            "sodium": "Sodium",
            "fluoride": "Fluoride",

            // Other nutrients
            "choline": "Choline",
            "omega_3": "Omega3_EPA_DHA",
            "omega3": "Omega3_EPA_DHA",
            "lutein": "Lutein_Zeaxanthin",
            "zeaxanthin": "Lutein_Zeaxanthin",
            "lycopene": "Lycopene"
        ]

        // Try mapping first, then fall back to PascalCase conversion
        let normalizedNutrient: String
        if let mapped = nutrientMapping[nutrient.lowercased()] {
            normalizedNutrient = mapped
            print("🔍 Mapped '\(nutrient)' -> '\(normalizedNutrient)'")
        } else {
            // For minerals and other nutrients: "iron" -> "Iron", "calcium" -> "Calcium"
            normalizedNutrient = nutrient.split(separator: "_")
                .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
                .joined(separator: "_")
            print("🔍 Converted '\(nutrient)' -> '\(normalizedNutrient)' (no mapping)")
        }

        let query = """
        SELECT nutrient, name, category, benefits, deficiency_signs, common_sources, recommended_daily_intake
        FROM nutrient_info
        WHERE nutrient = ?
        LIMIT 1;
        """
        var statement: OpaquePointer?

        defer {
            sqlite3_finalize(statement)
        }

        let prepareResult = sqlite3_prepare_v2(db, query, -1, &statement, nil)
        guard prepareResult == SQLITE_OK else {
            print("❌ Failed to prepare statement: result = \(prepareResult)")
            if let error = sqlite3_errmsg(db) {
                print("   Prepare Error: \(String(cString: error))")
            }
            return nil
        }

        print("🔎 Executing query for: '\(normalizedNutrient)'")

        // CRITICAL: Use SQLITE_TRANSIENT to copy the string
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(statement, 1, (normalizedNutrient as NSString).utf8String, -1, SQLITE_TRANSIENT)

        let stepResult = sqlite3_step(statement)
        guard stepResult == SQLITE_ROW else {
            print("❌ Query failed for '\(normalizedNutrient)': step result = \(stepResult), expected \(SQLITE_ROW)")
            if let error = sqlite3_errmsg(db) {
                print("   SQL Error: \(String(cString: error))")
            }

            // Try a direct query without binding to see if the data exists
            let directQuery = "SELECT COUNT(*) FROM nutrient_info WHERE nutrient = '\(normalizedNutrient)';"
            var directStmt: OpaquePointer?
            defer { sqlite3_finalize(directStmt) }

            if sqlite3_prepare_v2(db, directQuery, -1, &directStmt, nil) == SQLITE_OK {
                if sqlite3_step(directStmt) == SQLITE_ROW {
                    let count = sqlite3_column_int(directStmt, 0)
                    print("   🔍 Direct query found \(count) matching records")
                }
            }

            return nil
        }

        print("✅ Found data for '\(normalizedNutrient)'!")

        return NutrientInfo(
            nutrient: String(cString: sqlite3_column_text(statement, 0)),
            name: String(cString: sqlite3_column_text(statement, 1)),
            category: sqlite3_column_text(statement, 2).map { String(cString: $0) },
            benefits: sqlite3_column_text(statement, 3).map { String(cString: $0) },
            deficiencySigns: sqlite3_column_text(statement, 4).map { String(cString: $0) },
            commonSources: sqlite3_column_text(statement, 5).map { String(cString: $0) },
            recommendedDailyIntake: sqlite3_column_text(statement, 6).map { String(cString: $0) }
        )
    }

    /// Get all available nutrients for display
    func getAllNutrients() -> [NutrientInfo] {
        guard isInitialized, let db = db else { return [] }

        let query = """
        SELECT nutrient, name, category, benefits, deficiency_signs, common_sources, recommended_daily_intake
        FROM nutrient_info
        ORDER BY name;
        """
        var statement: OpaquePointer?
        var results: [NutrientInfo] = []

        defer {
            sqlite3_finalize(statement)
        }

        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return []
        }

        while sqlite3_step(statement) == SQLITE_ROW {
            let info = NutrientInfo(
                nutrient: String(cString: sqlite3_column_text(statement, 0)),
                name: String(cString: sqlite3_column_text(statement, 1)),
                category: sqlite3_column_text(statement, 2).map { String(cString: $0) },
                benefits: sqlite3_column_text(statement, 3).map { String(cString: $0) },
                deficiencySigns: sqlite3_column_text(statement, 4).map { String(cString: $0) },
                commonSources: sqlite3_column_text(statement, 5).map { String(cString: $0) },
                recommendedDailyIntake: sqlite3_column_text(statement, 6).map { String(cString: $0) }
            )
            results.append(info)
        }

        return results
    }

    // MARK: - Analysis Methods

    /// Analyze a food item and return all detected micronutrients with their strengths
    /// Combines ingredient matching and token matching
    func analyzeFoodItem(name: String, ingredients: [String] = []) -> [String: NutrientStrength.Strength] {
        var nutrientScores: [String: NutrientStrength.Strength] = [:]

        // 1. Check for tokens in food name (these are always "strong")
        let tokenMatches = matchTokens(in: name)
        for nutrient in tokenMatches {
            nutrientScores[nutrient] = .strong
        }

        // 2. Process each ingredient
        for ingredient in ingredients {
            if let ingredientData = lookupIngredient(ingredient) {
                for nutrientStrength in ingredientData.nutrients {
                    // Keep the strongest occurrence
                    if let existing = nutrientScores[nutrientStrength.nutrient] {
                        if nutrientStrength.strength.points > existing.points {
                            nutrientScores[nutrientStrength.nutrient] = nutrientStrength.strength
                        }
                    } else {
                        nutrientScores[nutrientStrength.nutrient] = nutrientStrength.strength
                    }
                }
            }
        }

        return nutrientScores
    }
}
