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

// MARK: - Cache Wrappers (NSCache requires classes)

private class NutrientInfoWrapper {
    let info: NutrientInfo
    init(_ info: NutrientInfo) { self.info = info }
}

private class IngredientWrapper {
    let ingredient: MicronutrientIngredient
    init(_ ingredient: MicronutrientIngredient) { self.ingredient = ingredient }
}

// MARK: - SQLite Database Manager

class MicronutrientDatabase {
    static let shared = MicronutrientDatabase()

    private var db: OpaquePointer?
    private var isInitialized = false

    // MARK: - Performance Caches

    /// Cache for nutrient info lookups (most frequently called)
    private let nutrientInfoCache = NSCache<NSString, NutrientInfoWrapper>()

    /// Cache for ingredient lookups
    private let ingredientCache = NSCache<NSString, IngredientWrapper>()

    private init() {
        openDatabase()
        configureCache()
    }

    private func configureCache() {
        // Limit memory usage
        nutrientInfoCache.countLimit = 100  // Most nutrients fit here
        ingredientCache.countLimit = 500    // Common ingredients
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
        let cacheKey = canonicalName as NSString

        // Check cache first
        if let cached = ingredientCache.object(forKey: cacheKey) {
            return cached.ingredient
        }

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

        let ingredient = MicronutrientIngredient(
            id: id,
            name: ingredientName,
            category: category,
            nutrients: nutrients
        )

        // Cache the result
        ingredientCache.setObject(IngredientWrapper(ingredient), forKey: cacheKey)

        return ingredient
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

        // Check cache first
        let cacheKey = nutrient.lowercased() as NSString
        if let cached = nutrientInfoCache.object(forKey: cacheKey) {
            return cached.info
        }

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
            // "fluoride": "Fluoride", // REMOVED: Not tracked

            // Other nutrients
            "choline": "Choline",
            "omega_3": "Omega3_EPA_DHA",
            "omega3": "Omega3_EPA_DHA",
            "omega3_ala": "Omega3_ALA",
            "omega3_epa_dha": "Omega3_EPA_DHA",
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

        let info = NutrientInfo(
            nutrient: String(cString: sqlite3_column_text(statement, 0)),
            name: String(cString: sqlite3_column_text(statement, 1)),
            category: sqlite3_column_text(statement, 2).map { String(cString: $0) },
            benefits: sqlite3_column_text(statement, 3).map { String(cString: $0) },
            deficiencySigns: sqlite3_column_text(statement, 4).map { String(cString: $0) },
            commonSources: sqlite3_column_text(statement, 5).map { String(cString: $0) },
            recommendedDailyIntake: sqlite3_column_text(statement, 6).map { String(cString: $0) }
        )

        // Cache the result
        nutrientInfoCache.setObject(NutrientInfoWrapper(info), forKey: cacheKey)

        return info
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
    /// Set useAI=true to enable Phase 2 AI enhancement (requires internet)
    func analyzeFoodItem(name: String, ingredients: [String] = [], useAI: Bool = false) -> [String: NutrientStrength.Strength] {
        // Use intelligent weighting system for realistic nutrient contributions
        return analyzeFoodItemWithWeighting(name: name, ingredients: ingredients, useAI: useAI)
    }

    /// Async version with AI support
    /// Note: AI support (useAI=true) requires AIMicronutrientParser to be compiled
    /// For now, always uses local pattern-based parser
    func analyzeFoodItemAsync(name: String, ingredients: [String] = [], useAI: Bool = false) async -> [String: NutrientStrength.Strength] {
        // Phase 1: Use local pattern-based parser only (Phase 2 AI coming soon)
        return analyzeFoodItemWithWeighting(name: name, ingredients: ingredients, useAI: false)
    }

    /// INTELLIGENT WEIGHTING SYSTEM: Calculate realistic nutrient contributions
    /// Based on ingredient position, count, and dish complexity
    /// ENHANCED: Now includes pattern-based fortification detection
    private func analyzeFoodItemWithWeighting(name: String, ingredients: [String], useAI: Bool) -> [String: NutrientStrength.Strength] {
        var nutrientContributions: [String: Double] = [:]

        // 1. Check for tokens in food name (these are always "strong")
        let tokenMatches = matchTokens(in: name)
        for nutrient in tokenMatches {
            nutrientContributions[nutrient] = 1.0 // Maximum contribution
        }

        // 2. PATTERN-BASED FORTIFICATION DETECTION (Phase 1 of hybrid approach)
        // This catches vitamins/minerals in complex ingredient phrases like:
        // "vitamin C (as l-ascorbic acid)", "calcium carbonate", etc.
        let detectedFortifications = IngredientMicronutrientParser.shared.parseIngredientsArray(ingredients)

        print("🔬 Pattern parser detected \(detectedFortifications.count) fortified nutrients")

        for detected in detectedFortifications {
            // Fortified nutrients are ALWAYS strong sources (1.0 contribution)
            nutrientContributions[detected.nutrient] = 1.0
            print("   ✅ \(detected.nutrient) (fortified) - from: \(detected.rawText)")
        }

        // 3. Calculate dish complexity penalty
        let ingredientCount = ingredients.count
        let complexityPenalty: Double = ingredientCount > 8 ? 0.25 : 0.30 // 25-30% reduction for complex dishes

        // 4. Process each ingredient with weighted contribution (NATURAL SOURCES)
        for (index, ingredient) in ingredients.enumerated() {
            if let ingredientData = lookupIngredient(ingredient) {
                // Calculate ingredient weight based on position
                let baseWeight = calculateIngredientWeight(position: index, totalCount: ingredientCount)

                // Apply complexity penalty for dishes with many ingredients
                let adjustedWeight = ingredientCount > 8 ? baseWeight * (1.0 - complexityPenalty) : baseWeight

                // Add weighted contributions from this ingredient
                for nutrientStrength in ingredientData.nutrients {
                    let nutrientValue = Double(nutrientStrength.strength.points) / 3.0 // Normalize to 0.33-1.0
                    let weightedContribution = adjustedWeight * nutrientValue

                    // Accumulate contributions (max() ensures fortified sources aren't diluted)
                    let currentContribution = nutrientContributions[nutrientStrength.nutrient] ?? 0.0
                    nutrientContributions[nutrientStrength.nutrient] = max(currentContribution, weightedContribution)
                }
            }
        }

        // 5. Convert weighted contributions to strength levels
        return convertWeightedContributionsToStrengths(nutrientContributions)
    }

    /// Calculate ingredient weight based on its position in the ingredient list
    /// First 3-5 ingredients get boosted weights (assumed to be main components)
    private func calculateIngredientWeight(position: Int, totalCount: Int) -> Double {
        if totalCount <= 3 {
            // Simple meals: equal distribution
            return 1.0 / Double(totalCount)
        }

        // Complex meals: boost core ingredients (first 3-5)
        if position < 3 {
            // First 3 ingredients: major contributors (30-40% each for simple, 20-25% for complex)
            return totalCount <= 5 ? 0.35 : 0.22
        } else if position < 5 {
            // Next 2 ingredients: medium contributors (10-15%)
            return totalCount <= 10 ? 0.12 : 0.08
        } else {
            // Remaining ingredients: minor contributors (2-5% each)
            let remainingCount = max(totalCount - 5, 1)
            return 0.10 / Double(remainingCount) // Split 10% among all minor ingredients
        }
    }

    /// Convert weighted nutrient contributions to strength classifications
    /// Uses realistic thresholds: Strong ≥0.25, Moderate 0.10-0.24, Trace <0.10
    private func convertWeightedContributionsToStrengths(_ contributions: [String: Double]) -> [String: NutrientStrength.Strength] {
        var result: [String: NutrientStrength.Strength] = [:]

        for (nutrient, contribution) in contributions {
            let strength: NutrientStrength.Strength

            if contribution >= 0.25 {
                // Strong: Major source (≥25% contribution)
                strength = .strong
            } else if contribution >= 0.10 {
                // Moderate: Medium source or frequent appearance (10-24%)
                strength = .moderate
            } else if contribution >= 0.01 {
                // Trace: Minor contribution (1-9%)
                strength = .trace
            } else {
                // Too small to register - skip
                continue
            }

            result[nutrient] = strength
        }

        return result
    }
}
