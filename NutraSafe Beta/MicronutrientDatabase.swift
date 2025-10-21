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
        } else {
            print("❌ MicronutrientDatabase: Failed to open database")
            if let error = sqlite3_errmsg(db) {
                print("   Error: \(String(cString: error))")
            }
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

        sqlite3_bind_text(statement, 1, altName, -1, nil)

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

        sqlite3_bind_text(ingredientStmt, 1, canonicalName, -1, nil)

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

        sqlite3_bind_text(statement, 1, lowercased, -1, nil)

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

        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return nil
        }

        sqlite3_bind_text(statement, 1, nutrient, -1, nil)

        guard sqlite3_step(statement) == SQLITE_ROW else {
            return nil
        }

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
