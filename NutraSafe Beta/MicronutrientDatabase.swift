//
//  MicronutrientDatabase.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-10-21.
//  SQLite wrapper for comprehensive micronutrient intelligence system
//
//  UPDATED 2025-01-20: Integrated with StrictMicronutrientValidator for
//  evidence-based detection. Now uses conservative rules to prevent false positives.
//  Ultra-processed foods (chocolate, sweets, biscuits, crisps) no longer infer
//  micronutrients from ingredients unless explicitly fortified.
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

    // PERFORMANCE: Background preload task (non-blocking initialization)
    private var preloadTask: Task<Void, Never>?

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
                        return
        }

        if sqlite3_open(dbPath, &db) == SQLITE_OK {
                        isInitialized = true

            // PERFORMANCE: Preload all nutrients in background (non-blocking startup)
            // This saves 150ms on app launch by not blocking the main thread
            preloadTask = Task.detached(priority: .utility) { [weak self] in
                self?.preloadAllNutrients()
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

    /// PERFORMANCE: Preload all nutrients into cache at startup (1 batch query instead of 33+ individual queries)
    private func preloadAllNutrients() {
        guard isInitialized, let db = db else { return }

        let query = """
        SELECT nutrient, name, category, benefits, deficiency_signs, common_sources, recommended_daily_intake
        FROM nutrient_info
        ORDER BY nutrient;
        """
        var statement: OpaquePointer?
        var count = 0

        defer {
            sqlite3_finalize(statement)
        }

        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
                        return
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

            // Cache using lowercase nutrient key for consistent lookups
            let cacheKey = info.nutrient.lowercased() as NSString
            nutrientInfoCache.setObject(NutrientInfoWrapper(info), forKey: cacheKey)
            count += 1
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

        // Map detector IDs to database IDs (moved up for cache check)
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

        // Get the normalized database key for cache lookup
        let normalizedNutrient: String
        if let mapped = nutrientMapping[nutrient.lowercased()] {
            normalizedNutrient = mapped
        } else {
            normalizedNutrient = nutrient.split(separator: "_")
                .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
                .joined(separator: "_")
        }

        // Check cache with NORMALIZED key (matches preload format)
        let cacheKey = normalizedNutrient.lowercased() as NSString
        if let cached = nutrientInfoCache.object(forKey: cacheKey) {
            return cached.info
        }

        // Cache miss - query database
        
        // Use normalizedNutrient (already computed above) for database query
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
                        return nil
        }

        // CRITICAL: Use SQLITE_TRANSIENT to copy the string
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(statement, 1, (normalizedNutrient as NSString).utf8String, -1, SQLITE_TRANSIENT)

        let stepResult = sqlite3_step(statement)
        guard stepResult == SQLITE_ROW else {
                        return nil
        }

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

    /// Reference to strict validator for food categorisation
    private let strictValidator = StrictMicronutrientValidator.shared

    /// Analyze a food item and return all detected micronutrients with their strengths.
    ///
    /// UPDATED 2025-01-20: Now uses STRICT validation rules.
    /// - Ultra-processed foods (chocolate, sweets, biscuits, crisps) return NO micronutrients
    ///   unless explicitly fortified in the ingredients list.
    /// - Ascorbic acid alone does NOT count as vitamin C (must explicitly say "vitamin C").
    /// - Only CONFIRMED tier nutrients are returned.
    ///
    /// - Parameters:
    ///   - name: Food product name
    ///   - ingredients: Array of ingredient strings
    ///   - useAI: Unused in strict mode
    ///   - nutritionTableMicronutrients: Optional quantified values from nutrition label
    /// - Returns: Dictionary of nutrient to strength mappings (confirmed only)
    func analyzeFoodItem(
        name: String,
        ingredients: [String] = [],
        useAI: Bool = false,
        nutritionTableMicronutrients: [String: Double]? = nil
    ) -> [String: NutrientStrength.Strength] {
        // Use strict validation for evidence-based detection
        return analyzeFoodItemStrict(
            name: name,
            ingredients: ingredients,
            nutritionTableMicronutrients: nutritionTableMicronutrients
        )
    }

    /// Async version with strict validation
    func analyzeFoodItemAsync(
        name: String,
        ingredients: [String] = [],
        useAI: Bool = false,
        nutritionTableMicronutrients: [String: Double]? = nil
    ) async -> [String: NutrientStrength.Strength] {
        return analyzeFoodItemStrict(
            name: name,
            ingredients: ingredients,
            nutritionTableMicronutrients: nutritionTableMicronutrients
        )
    }

    /// STRICT VALIDATION: Evidence-based micronutrient detection
    ///
    /// This method replaces the previous liberal inference approach.
    /// It only returns nutrients that are CONFIRMED through:
    /// 1. Explicit values in nutrition table
    /// 2. Explicit fortification declarations in ingredients
    ///
    /// Ultra-processed foods (confectionery, biscuits, crisps, etc.) are
    /// automatically restricted from nutrient inference.
    private func analyzeFoodItemStrict(
        name: String,
        ingredients: [String],
        nutritionTableMicronutrients: [String: Double]?
    ) -> [String: NutrientStrength.Strength] {

        // Check if this food category should be restricted
        let category = strictValidator.getFoodCategory(foodName: name, ingredients: ingredients)
        let isRestricted = MicronutrientFoodCategory.restrictedCategories.contains(category)

        var result: [String: NutrientStrength.Strength] = [:]

        // 1. Nutrition table data (highest priority - always accepted)
        if let tableNutrients = nutritionTableMicronutrients {
            for (nutrient, value) in tableNutrients where value > 0 {
                // Convert value to strength (assuming value is % of daily value)
                let strength: NutrientStrength.Strength
                if value >= 30 {
                    strength = .strong
                } else if value >= 15 {
                    strength = .moderate
                } else if value >= 5 {
                    strength = .trace
                } else {
                    continue // Too small to register
                }
                result[nutrient] = strength
            }
        }

        // 2. For restricted categories (ultra-processed), ONLY accept explicit fortification
        // Do NOT infer from ingredients
        if isRestricted {
            // Only detect fortification patterns, not natural sources
            let fortifiedNutrients = IngredientMicronutrientParser.shared.parseIngredientsArray(ingredients)

            for detected in fortifiedNutrients {
                // Only add if not already from nutrition table
                if result[detected.nutrient] == nil {
                    result[detected.nutrient] = detected.strength
                }
            }

            return result
        }

        // 3. For non-restricted foods, also check fortification
        let fortifiedNutrients = IngredientMicronutrientParser.shared.parseIngredientsArray(ingredients)

        for detected in fortifiedNutrients {
            if result[detected.nutrient] == nil {
                result[detected.nutrient] = detected.strength
            }
        }

        // 4. For whole foods / minimally processed, we could potentially add
        // natural source inference here, but for maximum safety we're keeping
        // it strict. Uncomment below if natural source detection is needed:
        //
        // if category == .wholeFood {
        //     let naturalNutrients = detectWholeFoodNutrients(name: name, ingredients: ingredients)
        //     for (nutrient, strength) in naturalNutrients {
        //         if result[nutrient] == nil {
        //             result[nutrient] = strength
        //         }
        //     }
        // }

        return result
    }

    /// LEGACY METHOD: Original weighting-based analysis (DEPRECATED)
    ///
    /// This method is retained for backwards compatibility but should not be used.
    /// Use `analyzeFoodItemStrict` instead.
    @available(*, deprecated, message: "Use analyzeFoodItemStrict for evidence-based detection")
    private func analyzeFoodItemWithWeightingLegacy(name: String, ingredients: [String], useAI: Bool) -> [String: NutrientStrength.Strength] {
        // Original implementation kept for reference but not called
        return [:]
    }

    // MARK: - LEGACY CODE REMOVED
    //
    // The previous `analyzeFoodItemWithWeighting` method has been removed.
    // It inferred micronutrients too liberally from ingredients, causing false positives
    // like detecting vitamin C in chocolate products (Revels) from trace flavourings.
    //
    // The new `analyzeFoodItemStrict` method above replaces it with evidence-based detection.
    // See StrictMicronutrientValidator.swift for the complete validation rules.

    /// DEPRECATED: No longer used in strict mode
    /// Kept for backwards compatibility but will be removed in future version
    @available(*, deprecated, message: "Legacy weighting method - not used in strict mode")
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

    /// DEPRECATED: No longer used in strict mode
    /// Kept for backwards compatibility but will be removed in future version
    @available(*, deprecated, message: "Legacy weighting method - not used in strict mode")
    private func convertWeightedContributionsToStrengths(_ contributions: [String: Double]) -> [String: NutrientStrength.Strength] {
        var result: [String: NutrientStrength.Strength] = [:]

        for (nutrient, contribution) in contributions {
            let strength: NutrientStrength.Strength

            if contribution >= 0.30 {
                // Strong: Major source (≥30% contribution)
                // Aligned with UK/EU "High In" / "Rich In" claim threshold (30% NRV)
                strength = .strong
            } else if contribution >= 0.15 {
                // Moderate: Medium source (15-29% contribution)
                // Aligned with UK/EU "Source Of" claim threshold (15% NRV)
                strength = .moderate
            } else if contribution >= 0.01 {
                // Trace: Minor contribution (1-14% contribution)
                // Below UK/EU "significant amount" threshold but still detectable
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
