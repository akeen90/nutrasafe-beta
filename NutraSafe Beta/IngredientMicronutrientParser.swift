//
//  IngredientMicronutrientParser.swift
//  NutraSafe Beta
//
//  Deterministic pattern-based ingredient parser for extracting micronutrients
//  from complex ingredient lists (e.g., fortified foods)
//
//  UPDATED 2025-01-20: Integrated with StrictMicronutrientValidator for
//  evidence-based detection. Now uses conservative rules to prevent false positives.
//

import Foundation

// MARK: - Data Models

struct DetectedMicronutrient {
    let nutrient: String          // e.g., "vitamin_c", "calcium"
    let strength: NutrientStrength.Strength
    let source: NutrientSource
    let rawText: String           // Original ingredient phrase
    let confidence: Double        // 0.0 to 1.0

    enum NutrientSource {
        case fortification        // "vitamin C (as ascorbic acid)" - EXPLICIT declaration
        case naturalIngredient    // "spinach" contains iron naturally (NOT used in strict mode)
        case ai(String)           // AI-detected, with source description
    }
}

// MARK: - Pattern-Based Parser

class IngredientMicronutrientParser {
    static let shared = IngredientMicronutrientParser()

    // MARK: - Strict Validation Integration

    private let strictValidator = StrictMicronutrientValidator.shared

    // MARK: - Comprehensive Vitamin & Mineral Patterns (FORTIFICATION ONLY)
    //
    // IMPORTANT: These patterns are now used ONLY for detecting EXPLICIT fortification.
    // They are NOT used for inferring nutrients from natural ingredients.
    //
    // The patterns have been refined to require explicit vitamin/mineral declarations
    // and exclude antioxidant/preservative uses of compounds like ascorbic acid.

    private struct NutrientPattern {
        let pattern: String
        let nutrient: String
        let strength: NutrientStrength.Strength
        let requiresExplicitContext: Bool  // Must appear in vitamin/fortification context

        init(pattern: String, nutrient: String, strength: NutrientStrength.Strength = .strong, requiresExplicitContext: Bool = false) {
            self.pattern = pattern
            self.nutrient = nutrient
            self.strength = strength
            self.requiresExplicitContext = requiresExplicitContext
        }

        var regex: NSRegularExpression? {
            try? NSRegularExpression(pattern: "\\b\(pattern)", options: .caseInsensitive)
        }
    }

    // MARK: - Fortification Patterns (Strict Mode)
    //
    // These patterns detect EXPLICIT fortification declarations only.
    // Ascorbic acid alone is NOT included - it must be accompanied by "vitamin C".

    private let fortificationPatterns: [NutrientPattern] = [
        // VITAMIN C - STRICT: Must explicitly say "vitamin C"
        // Ascorbic acid alone is assumed to be antioxidant/preservative
        NutrientPattern(pattern: "vitamin c|vitamin-c", nutrient: "vitamin_c"),
        NutrientPattern(pattern: "l-ascorbic acid\\s*\\(\\s*vitamin\\s*c\\s*\\)", nutrient: "vitamin_c"),
        NutrientPattern(pattern: "ascorbic acid\\s*\\(\\s*vitamin\\s*c\\s*\\)", nutrient: "vitamin_c"),

        // VITAMIN A - Explicit declarations
        NutrientPattern(pattern: "vitamin a", nutrient: "vitamin_a"),
        NutrientPattern(pattern: "retinyl acetate|retinyl palmitate", nutrient: "vitamin_a"),
        NutrientPattern(pattern: "beta[\\s-]*carotene", nutrient: "vitamin_a"),

        // B VITAMINS - Explicit declarations
        NutrientPattern(pattern: "vitamin b1|thiamin(?:e)?(?:\\s*\\(|\\s*mononitrate|\\s*hydrochloride)?", nutrient: "vitamin_b1"),
        NutrientPattern(pattern: "vitamin b2|riboflavin", nutrient: "vitamin_b2"),
        NutrientPattern(pattern: "vitamin b3|niacin(?:amide)?|nicotinamide", nutrient: "vitamin_b3"),
        NutrientPattern(pattern: "vitamin b5|pantothenic acid|calcium d-pantothenate|d-pantothenate", nutrient: "vitamin_b5"),
        NutrientPattern(pattern: "vitamin b6|pyridoxine(?:\\s*hydrochloride)?", nutrient: "vitamin_b6"),
        NutrientPattern(pattern: "vitamin b7|biotin|d-biotin", nutrient: "vitamin_b7"),
        NutrientPattern(pattern: "vitamin b9|folate|folic acid|calcium l-methylfolate|methylfolate|l-methylfolate", nutrient: "vitamin_b9"),
        NutrientPattern(pattern: "vitamin b12|cobalamin|cyanocobalamin|methylcobalamin", nutrient: "vitamin_b12"),

        // VITAMIN D - Explicit declarations
        NutrientPattern(pattern: "vitamin d[23]?|cholecalciferol|ergocalciferol", nutrient: "vitamin_d"),

        // VITAMIN E - Explicit declarations only
        // Note: Tocopherols as antioxidants are excluded
        NutrientPattern(pattern: "vitamin e", nutrient: "vitamin_e"),
        NutrientPattern(pattern: "d-alpha[\\s-]*tocopherol(?:yl)?(?:\\s*acetate)?", nutrient: "vitamin_e"),
        NutrientPattern(pattern: "tocopheryl acetate", nutrient: "vitamin_e"),

        // VITAMIN K - Explicit declarations
        NutrientPattern(pattern: "vitamin k[12]?|phylloquinone|menaquinone", nutrient: "vitamin_k"),

        // CALCIUM - Added as mineral fortification
        NutrientPattern(pattern: "calcium carbonate|calcium citrate|calcium phosphate|calcium lactate", nutrient: "calcium"),
        // Note: "calcium" alone might be part of another compound (e.g., calcium d-pantothenate)
        // Only match when it's clearly added as a mineral

        // IRON - Added as mineral fortification
        NutrientPattern(pattern: "iron\\b(?!\\s*oxide)", nutrient: "iron"),  // Exclude iron oxide (colouring)
        NutrientPattern(pattern: "ferrous\\s*(?:sulfate|sulphate|fumarate|gluconate)", nutrient: "iron"),

        // MAGNESIUM - Fortification compounds
        NutrientPattern(pattern: "magnesium oxide|magnesium citrate|magnesium carbonate", nutrient: "magnesium"),

        // ZINC - Fortification compounds
        NutrientPattern(pattern: "zinc\\s*(?:oxide|citrate|gluconate|sulphate|sulfate)", nutrient: "zinc"),

        // POTASSIUM - Fortification compounds (not just any potassium compound)
        NutrientPattern(pattern: "potassium chloride|potassium citrate", nutrient: "potassium", requiresExplicitContext: true),

        // IODINE - Fortification
        NutrientPattern(pattern: "iodine|potassium iodide|iodised salt|iodized salt", nutrient: "iodine"),

        // PHOSPHORUS - Only as explicit fortification
        NutrientPattern(pattern: "phosphorus", nutrient: "phosphorus", requiresExplicitContext: true),

        // SELENIUM - Fortification
        NutrientPattern(pattern: "selenium|sodium selenite|selenomethionine", nutrient: "selenium"),

        // COPPER - Fortification
        NutrientPattern(pattern: "copper\\s*(?:sulfate|sulphate|gluconate)", nutrient: "copper"),

        // MANGANESE - Fortification
        NutrientPattern(pattern: "manganese\\s*(?:sulfate|sulphate|gluconate)", nutrient: "manganese"),

        // CHROMIUM - Fortification
        NutrientPattern(pattern: "chromium|chromium picolinate|chromium chloride", nutrient: "chromium"),

        // MOLYBDENUM - Fortification
        NutrientPattern(pattern: "molybdenum|sodium molybdate", nutrient: "molybdenum"),

        // SPECIALTY NUTRIENTS - Explicit additions
        NutrientPattern(pattern: "omega[\\s-]?3|epa[\\s/]+dha", nutrient: "omega_3"),
        NutrientPattern(pattern: "lutein", nutrient: "lutein"),
        NutrientPattern(pattern: "lycopene", nutrient: "lycopene"),
        NutrientPattern(pattern: "choline", nutrient: "choline"),
    ]

    // MARK: - Excluded Patterns (Antioxidants/Preservatives)
    //
    // These compounds should NOT be counted as vitamins/minerals when used
    // as antioxidants, preservatives, or processing aids.

    private let excludedAntioxidantPatterns: [String] = [
        "ascorbic acid",           // When NOT accompanied by "vitamin C"
        "e300",                    // Ascorbic acid E-number
        "e301",                    // Sodium ascorbate (antioxidant)
        "e302",                    // Calcium ascorbate (antioxidant)
        "e304",                    // Ascorbyl palmitate (antioxidant)
        "e306",                    // Tocopherol-rich extract (antioxidant)
        "e307",                    // Alpha-tocopherol (antioxidant)
        "e308",                    // Gamma-tocopherol (antioxidant)
        "e309",                    // Delta-tocopherol (antioxidant)
        "citric acid",             // NOT vitamin C
        "malic acid",              // NOT a vitamin
        "tartaric acid",           // NOT a vitamin
        "lactic acid",             // NOT a vitamin
        "fumaric acid",            // NOT a vitamin
    ]

    private init() {}

    // MARK: - Main Parsing Method (STRICT MODE)

    /// Parse ingredient text and extract CONFIRMED micronutrients only.
    /// Uses strict validation rules to prevent false positives.
    ///
    /// - Parameter ingredientsText: Raw ingredient list text
    /// - Returns: Array of detected micronutrients (fortification only)
    func parseIngredients(_ ingredientsText: String) -> [DetectedMicronutrient] {
        guard !ingredientsText.isEmpty else { return [] }

        var detected: [DetectedMicronutrient] = []
        let lowercasedText = ingredientsText.lowercased()

        // Check if ascorbic acid is used as antioxidant (exclude from vitamin C)
        let ascorbicIsAntioxidant = isAscorbicAcidUsedAsAntioxidant(lowercasedText)

        // Split into individual ingredient phrases (by comma)
        let phrases = ingredientsText.components(separatedBy: ",")

        for phrase in phrases {
            let cleanPhrase = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
            let lowercasePhrase = cleanPhrase.lowercased()

            // Skip if this phrase contains an excluded antioxidant pattern
            // and we're looking for vitamin C
            let isAntioxidantPhrase = excludedAntioxidantPatterns.contains { lowercasePhrase.contains($0) }

            // Check each pattern against this phrase
            for pattern in fortificationPatterns {
                // Skip vitamin C patterns if ascorbic acid is used as antioxidant
                if pattern.nutrient == "vitamin_c" && ascorbicIsAntioxidant {
                    // Only detect if phrase explicitly contains "vitamin c"
                    if !lowercasePhrase.contains("vitamin c") && !lowercasePhrase.contains("vitamin-c") {
                        continue
                    }
                }

                // Skip vitamin E patterns if this appears to be an antioxidant
                if pattern.nutrient == "vitamin_e" && isAntioxidantPhrase {
                    if !lowercasePhrase.contains("vitamin e") {
                        continue
                    }
                }

                // For patterns requiring explicit context, check for vitamin/fortification keywords
                if pattern.requiresExplicitContext {
                    let hasContext = lowercasedText.contains("vitamins:") ||
                                    lowercasedText.contains("minerals:") ||
                                    lowercasedText.contains("fortified") ||
                                    lowercasedText.contains("added vitamins") ||
                                    lowercasedText.contains("added minerals")
                    if !hasContext {
                        continue
                    }
                }

                if let regex = pattern.regex {
                    let range = NSRange(cleanPhrase.startIndex..., in: cleanPhrase)
                    if regex.firstMatch(in: cleanPhrase, range: range) != nil {
                        detected.append(DetectedMicronutrient(
                            nutrient: pattern.nutrient,
                            strength: pattern.strength,
                            source: .fortification,
                            rawText: cleanPhrase,
                            confidence: 0.95  // High confidence for explicit fortification matches
                        ))
                    }
                }
            }
        }

        return removeDuplicates(detected)
    }

    /// Parse ingredients array and extract CONFIRMED micronutrients only.
    func parseIngredientsArray(_ ingredients: [String]) -> [DetectedMicronutrient] {
        // Join and delegate to main parser for consistent handling
        let joinedText = ingredients.joined(separator: ", ")
        return parseIngredients(joinedText)
    }

    // MARK: - Strict Validation Method

    /// Validate micronutrients using strict evidence-based rules.
    /// This is the preferred method for production use.
    ///
    /// - Parameters:
    ///   - foodName: Name of the food product
    ///   - ingredients: Array of ingredient strings
    ///   - nutritionTableMicronutrients: Optional nutrients from nutrition label
    /// - Returns: Array of validated micronutrients (confirmed tier only)
    func validateMicronutrientsStrict(
        foodName: String,
        ingredients: [String],
        nutritionTableMicronutrients: [String: Double]? = nil
    ) -> [ValidatedMicronutrient] {
        return strictValidator.validateMicronutrients(
            foodName: foodName,
            ingredients: ingredients,
            nutritionTableMicronutrients: nutritionTableMicronutrients
        )
    }

    /// Check if micronutrient inference should be restricted for this food
    func shouldRestrictInference(foodName: String, ingredients: [String]) -> Bool {
        return strictValidator.shouldRestrictMicronutrientInference(
            foodName: foodName,
            ingredients: ingredients
        )
    }

    // MARK: - Helper Methods

    /// Check if ascorbic acid appears to be used as an antioxidant
    private func isAscorbicAcidUsedAsAntioxidant(_ text: String) -> Bool {
        // If text contains ascorbic acid but NOT "vitamin c", assume antioxidant
        let hasAscorbicAcid = text.contains("ascorbic acid") ||
                              text.contains("e300") ||
                              text.contains("e301") ||
                              text.contains("e302")
        let hasExplicitVitaminC = text.contains("vitamin c") || text.contains("vitamin-c")

        if hasAscorbicAcid && !hasExplicitVitaminC {
            return true
        }

        // Check for explicit antioxidant context
        let antioxidantContextPatterns = [
            "ascorbic acid (antioxidant)",
            "ascorbic acid as antioxidant",
            "antioxidant: ascorbic",
            "antioxidants: e300",
            "antioxidant (e300)",
            "antioxidant (ascorbic",
            "preservative: ascorbic"
        ]

        for pattern in antioxidantContextPatterns {
            if text.contains(pattern) {
                return true
            }
        }

        return false
    }

    /// Remove duplicate nutrients, keeping the highest strength
    private func removeDuplicates(_ nutrients: [DetectedMicronutrient]) -> [DetectedMicronutrient] {
        var uniqueNutrients: [String: DetectedMicronutrient] = [:]

        for nutrient in nutrients {
            if let existing = uniqueNutrients[nutrient.nutrient] {
                // Keep the one with higher strength
                if nutrient.strength.points > existing.strength.points {
                    uniqueNutrients[nutrient.nutrient] = nutrient
                }
            } else {
                uniqueNutrients[nutrient.nutrient] = nutrient
            }
        }

        return Array(uniqueNutrients.values)
    }
}
