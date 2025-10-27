//
//  IngredientMicronutrientParser.swift
//  NutraSafe Beta
//
//  Deterministic pattern-based ingredient parser for extracting micronutrients
//  from complex ingredient lists (e.g., fortified foods)
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
        case fortification        // "vitamin C (as ascorbic acid)"
        case naturalIngredient    // "spinach" contains iron naturally
        case ai(String)          // AI-detected, with source description
    }
}

// MARK: - Pattern-Based Parser

class IngredientMicronutrientParser {
    static let shared = IngredientMicronutrientParser()

    // MARK: - Comprehensive Vitamin & Mineral Patterns

    private struct NutrientPattern {
        let pattern: String
        let nutrient: String
        let strength: NutrientStrength.Strength

        var regex: NSRegularExpression? {
            try? NSRegularExpression(pattern: "\\b\(pattern)", options: .caseInsensitive)
        }
    }

    private let nutrientPatterns: [NutrientPattern] = [
        // VITAMIN C
        NutrientPattern(pattern: "vitamin c|l-ascorbic acid|ascorbic acid|ascorbate", nutrient: "vitamin_c", strength: .strong),

        // VITAMIN A
        NutrientPattern(pattern: "vitamin a|retinyl acetate|retinyl palmitate|beta-carotene|beta carotene", nutrient: "vitamin_a", strength: .strong),

        // B VITAMINS
        NutrientPattern(pattern: "vitamin b1|thiamin|thiamine mononitrate|thiamine hydrochloride", nutrient: "vitamin_b1", strength: .strong),
        NutrientPattern(pattern: "vitamin b2|riboflavin", nutrient: "vitamin_b2", strength: .strong),
        NutrientPattern(pattern: "vitamin b3|niacin|niacinamide|nicotinamide", nutrient: "vitamin_b3", strength: .strong),
        NutrientPattern(pattern: "vitamin b5|pantothenic acid|calcium d-pantothenate|d-pantothenate", nutrient: "vitamin_b5", strength: .strong),
        NutrientPattern(pattern: "vitamin b6|pyridoxine|pyridoxine hydrochloride", nutrient: "vitamin_b6", strength: .strong),
        NutrientPattern(pattern: "vitamin b7|biotin|d-biotin", nutrient: "vitamin_b7", strength: .strong),
        NutrientPattern(pattern: "vitamin b9|folate|folic acid|calcium l-methylfolate|methylfolate|l-methylfolate", nutrient: "vitamin_b9", strength: .strong),
        NutrientPattern(pattern: "vitamin b12|cobalamin|cyanocobalamin|methylcobalamin", nutrient: "vitamin_b12", strength: .strong),

        // VITAMIN D
        NutrientPattern(pattern: "vitamin d|cholecalciferol|ergocalciferol|d2 as ergocalciferol|d3 as plant-derived cholecalciferol|d2|d3", nutrient: "vitamin_d", strength: .strong),

        // VITAMIN E
        NutrientPattern(pattern: "vitamin e|d-alpha tocopherol|tocopherol|tocopheryl acetate|alpha-tocopherol", nutrient: "vitamin_e", strength: .strong),

        // VITAMIN K
        NutrientPattern(pattern: "vitamin k|phylloquinone|menaquinone|k1|k2|as menaquinone-7", nutrient: "vitamin_k", strength: .strong),

        // CALCIUM
        NutrientPattern(pattern: "calcium\\b(?!.*d-pantothenate)|calcium carbonate|calcium citrate|calcium phosphate|as calcium carbonate|as calcium l-methylfolate", nutrient: "calcium", strength: .strong),

        // IRON
        NutrientPattern(pattern: "iron\\b|ferrous sulfate|ferrous fumarate|ferric", nutrient: "iron", strength: .strong),

        // MAGNESIUM
        NutrientPattern(pattern: "magnesium|magnesium oxide|magnesium citrate", nutrient: "magnesium", strength: .strong),

        // ZINC
        NutrientPattern(pattern: "zinc|zinc oxide|zinc citrate", nutrient: "zinc", strength: .strong),

        // POTASSIUM
        NutrientPattern(pattern: "potassium(?!.*iodide)|potassium chloride|potassium citrate|as potassium chloride", nutrient: "potassium", strength: .strong),

        // IODINE
        NutrientPattern(pattern: "iodine|potassium iodide|as potassium iodide", nutrient: "iodine", strength: .strong),

        // PHOSPHORUS
        NutrientPattern(pattern: "phosphorus|calcium phosphate|sodium phosphate", nutrient: "phosphorus", strength: .strong),

        // SELENIUM
        NutrientPattern(pattern: "selenium|sodium selenite", nutrient: "selenium", strength: .strong),

        // COPPER
        NutrientPattern(pattern: "copper|copper sulfate|cupric", nutrient: "copper", strength: .strong),

        // MANGANESE
        NutrientPattern(pattern: "manganese|manganese sulfate", nutrient: "manganese", strength: .strong),

        // CHROMIUM
        NutrientPattern(pattern: "chromium|chromium picolinate", nutrient: "chromium", strength: .strong),

        // MOLYBDENUM
        NutrientPattern(pattern: "molybdenum|sodium molybdate", nutrient: "molybdenum", strength: .strong),

        // SPECIALTY NUTRIENTS
        NutrientPattern(pattern: "omega-3|omega 3|epa|dha|epa/dha", nutrient: "omega_3", strength: .strong),
        NutrientPattern(pattern: "lutein", nutrient: "lutein", strength: .strong),
        NutrientPattern(pattern: "lycopene", nutrient: "lycopene", strength: .strong),
        NutrientPattern(pattern: "choline", nutrient: "choline", strength: .strong),
    ]

    private init() {}

    // MARK: - Main Parsing Method

    /// Parse ingredient text and extract all micronutrients
    /// Returns detected nutrients with strength classification
    func parseIngredients(_ ingredientsText: String) -> [DetectedMicronutrient] {
        guard !ingredientsText.isEmpty else { return [] }

        var detected: [DetectedMicronutrient] = []

        // Split into individual ingredient phrases (by comma)
        let phrases = ingredientsText.components(separatedBy: ",")

        for phrase in phrases {
            let cleanPhrase = phrase.trimmingCharacters(in: .whitespacesAndNewlines)

            // Check each pattern against this phrase
            for pattern in nutrientPatterns {
                if let regex = pattern.regex {
                    let range = NSRange(cleanPhrase.startIndex..., in: cleanPhrase)
                    if regex.firstMatch(in: cleanPhrase, range: range) != nil {
                        detected.append(DetectedMicronutrient(
                            nutrient: pattern.nutrient,
                            strength: pattern.strength,
                            source: .fortification,
                            rawText: cleanPhrase,
                            confidence: 0.95  // High confidence for pattern matches
                        ))
                    }
                }
            }
        }

        return removeDuplicates(detected)
    }

    /// Parse ingredients array and extract micronutrients
    func parseIngredientsArray(_ ingredients: [String]) -> [DetectedMicronutrient] {
        var detected: [DetectedMicronutrient] = []

        for ingredient in ingredients {
            let cleanIngredient = ingredient.trimmingCharacters(in: .whitespacesAndNewlines)

            // Check each pattern
            for pattern in nutrientPatterns {
                if let regex = pattern.regex {
                    let range = NSRange(cleanIngredient.startIndex..., in: cleanIngredient)
                    if regex.firstMatch(in: cleanIngredient, range: range) != nil {
                        detected.append(DetectedMicronutrient(
                            nutrient: pattern.nutrient,
                            strength: pattern.strength,
                            source: .fortification,
                            rawText: cleanIngredient,
                            confidence: 0.95
                        ))
                    }
                }
            }
        }

        return removeDuplicates(detected)
    }

    // MARK: - Helper Methods

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

    /// Debug: List all nutrients that would be detected
    func testParsing(_ ingredientsText: String) {
        // DEBUG LOG: print("🔬 Testing ingredient parsing:")
        // DEBUG LOG: print("📝 Input: \(ingredientsText)")
        print("")

        let detected = parseIngredients(ingredientsText)

        if detected.isEmpty {
            print("❌ No micronutrients detected")
        } else {
            print("✅ Found \(detected.count) micronutrients:")
            for nutrient in detected.sorted(by: { $0.nutrient < $1.nutrient }) {
                print("   • \(nutrient.nutrient) (\(nutrient.strength)) - from: \(nutrient.rawText)")
            }
        }
        print("")
    }

    /// Run diagnostic tests with sample ingredient lists
    static func runDiagnosticTests() {
        let parser = IngredientMicronutrientParser.shared

        print("=" .repeating(80))
        print("DIAGNOSTIC TEST: Ingredient Micronutrient Parser")
        print("=" .repeating(80))
        print("")

        // Test 1: Your actual ingredient list from the screenshot
        let test1 = """
        Oat flour, Pea protein, Ground flaxseed, Tapioca starch, Brown rice protein, Natural flavourings, Sunflower oil powder, Micronutrient blend (minerals (potassium (as potassium chloride, Potassium citrate), Calcium (as calcium carbonate), Iodine (as potassium iodide)), Corn starch, Vitamins (vitamin C (as l-ascorbic acid), vitamin K (k2, As menaquinone-7), vitamin A (as retinyl acetate), vitamin E (d-alpha tocopherol acetate), niacin (as niacinamide), vitamin B12 (as cyanocobalamin), vitamin D (d2 as ergocalciferol, D3 as plant-derived cholecalciferol), Pantothenic acid (as calcium d-pantothenate), vitamin B6 (as pyridoxine hydrochloride), vitamin B2 (as riboflavin), Folate (as calcium l-methylfolate), vitamin B1 (as thiamin mononitrate)), Lutein), Medium-chain triglyceride powder (from coconut), Stabilisers: guar gum, Xanthan gum, Faba bean protein, Sweetener: sucralose.
        """

        parser.testParsing(test1)

        // Test 2: Simple fortified food
        let test2 = "Wheat flour (with added calcium, iron, niacin, thiamin), Water, Yeast"
        parser.testParsing(test2)

        // Test 3: Multivitamin supplement
        let test3 = "Vitamin C (ascorbic acid), Vitamin D3 (cholecalciferol), Calcium carbonate, Zinc oxide"
        parser.testParsing(test3)

        print("=" .repeating(80))
        print("END OF DIAGNOSTIC TESTS")
        print("=" .repeating(80))
    }
}

// String extension for repeating characters
extension String {
    func repeating(_ count: Int) -> String {
        return String(repeating: self, count: count)
    }
}
