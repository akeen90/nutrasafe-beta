//
//  ScoringModels.swift
//  NutraSafe Beta
//
//  Domain models for Scoring
//

import Foundation
import SwiftUI

enum ProcessingGrade: String, CaseIterable {
    case aPlus = "A+"
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    case f = "F"
    case unknown = "?"
    
    var numericValue: Int {
        switch self {
        case .aPlus: return 5
        case .a: return 4
        case .b: return 3
        case .c: return 2
        case .d: return 1
        case .f: return 0
        case .unknown: return -1
        }
    }
    
    var color: Color {
        switch self {
        case .aPlus: return .green
        case .a: return .green
        case .b: return .yellow
        case .c: return .orange
        case .d: return .orange
        case .f: return .red
        case .unknown: return .gray
        }
    }
}

// ProcessingLevel is now defined in CoreModels.swift to avoid duplication

struct NutritionProcessingScore {
    let grade: ProcessingGrade
    let score: Int
    let explanation: String
    let factors: [String]
    let processingLevel: ProcessingLevel
    let additiveCount: Int
    let eNumberCount: Int
    let naturalScore: Int
}

class ProcessingScorer {
    static let shared = ProcessingScorer()

    // Expose database version for re-analysis comparison
    private(set) var databaseVersion: String = "2025.1"

    // PERFORMANCE: Memoization cache for processing scores
    private var scoreCache: [String: NutritionProcessingScore] = [:]

    // PERFORMANCE: Memoization cache for additive analysis
    private var additivesCache: [String: [AdditiveInfo]] = [:]

    private let cacheLock = NSLock()

    // PERFORMANCE: Precompiled regex patterns (compiled once, reused thousands of times)
    // These patterns are compile-time verified as valid regex literals - they cannot fail
    // swiftlint:disable force_try
    private static let gramPattern1 = try! NSRegularExpression(pattern: #"(\d+(?:\.\d+)?)\s*g"#, options: [])
    private static let gramPattern2 = try! NSRegularExpression(pattern: #"\((\d+(?:\.\d+)?)\s*g\)"#, options: [])
    private static let mlPattern1 = try! NSRegularExpression(pattern: #"(\d+(?:\.\d+)?)\s*ml"#, options: [])
    private static let mlPattern2 = try! NSRegularExpression(pattern: #"\((\d+(?:\.\d+)?)\s*ml\)"#, options: [])
    private static let eNumberPattern = try! NSRegularExpression(pattern: "e\\d{3,4}", options: [])
    // swiftlint:enable force_try

    // PERFORMANCE: Cache for dynamically generated word boundary patterns
    private var regexPatternCache: [String: NSRegularExpression] = [:]

    private init() {}

    // MARK: - NutraSafe Processing Grade™
    struct NutraSafeProcessingGradeResult: Codable, Equatable {
        let processing_intensity: Double
        let nutrient_integrity: Double
        let final_index: Double
        let grade: String
        let label: String
        let explanation: String
    }

    // MARK: - Beverage Detection & Sugar Analysis Helper Functions

    /// Detect if a product is a beverage based on name, nutritional profile, and serving description
    private func isBeverage(food: FoodSearchResult) -> Bool {
        let lowerName = food.name.lowercased()
        let lowerServing = (food.servingDescription ?? "").lowercased()

        // Check for beverage keywords in name or serving description
        let beverageKeywords = [
            "drink", "cola", "coke", "pepsi", "sprite", "fanta", "soda", "pop",
            "juice", "smoothie", "shake", "tea", "coffee", "latte", "cappuccino",
            "energy drink", "red bull", "monster", "sports drink", "gatorade", "powerade",
            "lemonade", "squash", "cordial", "fizzy", "carbonated", "soft drink",
            "frappuccino", "milkshake", "iced tea", "iced coffee", "bubble tea"
        ]

        let containsBeverageKeyword = beverageKeywords.contains(where: { lowerName.contains($0) || lowerServing.contains($0) })

        // Check for liquid serving units (ml, fl oz)
        let liquidServingUnits = lowerServing.contains("ml") || lowerServing.contains("fl oz") || lowerServing.contains("fluid")

        // Check nutritional profile: very low protein, fat, and fiber (typical of beverages)
        let isLowNutrientDensity = (food.protein < 2.0 && food.fat < 2.0 && food.fiber < 1.0)

        // Combine heuristics: keyword match OR (liquid units AND low nutrient density)
        return containsBeverageKeyword || (liquidServingUnits && isLowNutrientDensity)
    }

    /// Extract serving size in grams from serving description (e.g., "330ml", "1 can (330ml)")
    private func extractServingSize(from servingDescription: String?) -> Double {
        guard let serving = servingDescription else { return 100.0 }

        // PERFORMANCE: Use precompiled regex patterns (80% faster than compiling on each call)
        let gramPatterns = [Self.gramPattern1, Self.gramPattern2]
        let servingRange = NSRange(location: 0, length: serving.count)

        // Try to extract grams first (direct match)
        for regex in gramPatterns {
            if let match = regex.firstMatch(in: serving, options: [], range: servingRange),
               let range = Range(match.range(at: 1), in: serving) {
                return Double(String(serving[range])) ?? 100.0
            }
        }

        // Try to extract ml and treat as grams (water density ~1g/ml)
        let mlPatterns = [Self.mlPattern1, Self.mlPattern2]

        for regex in mlPatterns {
            if let match = regex.firstMatch(in: serving, options: [], range: servingRange),
               let range = Range(match.range(at: 1), in: serving) {
                return Double(String(serving[range])) ?? 100.0
            }
        }

        // Fallback: use provided servingSizeG if available
        // Default to 100g if no parseable serving size found
        return 100.0
    }

    /// Calculate sugar per serving for proper beverage analysis
    private func calculateSugarPerServing(food: FoodSearchResult) -> Double {
        // Use provided servingSizeG if available, otherwise parse from description
        let servingSize = food.servingSizeG ?? extractServingSize(from: food.servingDescription)

        // Sugar is per 100g, scale to actual serving size
        return food.sugar * (servingSize / 100.0)
    }

    /// Detect "empty calorie" products: zero nutrition, high sugar
    private func isEmptyCalorie(food: FoodSearchResult) -> Bool {
        return food.protein < 0.5 && food.fat < 0.5 && food.fiber < 0.5 && food.sugar > 5.0
    }

    func computeNutraSafeProcessingGrade(for food: FoodSearchResult) -> NutraSafeProcessingGradeResult {
        // CRITICAL: Cannot grade products without ingredient information
        let hasIngredients = food.ingredients != nil && !(food.ingredients?.isEmpty ?? true)

        if !hasIngredients {
            return NutraSafeProcessingGradeResult(
                processing_intensity: 0.0,
                nutrient_integrity: 0.0,
                final_index: 0.0,
                grade: "?",
                label: "Unable to grade",
                explanation: "Insufficient data: No ingredient information available to assess processing level. Add ingredients to get a NutraSafe Processing Grade™."
            )
        }

        // Aggregate text for additive/industrial detection
        let ingredientsText = (food.ingredients?.joined(separator: ", ") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let analysisText = (ingredientsText.isEmpty ? food.name : "\(food.name) \(ingredientsText)")
        let lowerText = analysisText.lowercased()
        let lowerName = food.name.lowercased()

        // TOTAL ingredient count (for complexity scoring - don't filter these)
        let totalIngredientCount = (food.ingredients ?? []).filter {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count

        // For additive analysis, we still filter to avoid false positives on additive detection
        // But we use TOTAL count for complexity scoring
        let filteredIngredients = (food.ingredients ?? []).filter { ingredient in
            let trimmed = ingredient.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            // Skip empty ingredients
            if trimmed.isEmpty {
                return false
            }

            // Skip ONLY exact matches of simple whole food names for ADDITIVE detection
            // This prevents "chicken" being detected as an additive, but doesn't affect ingredient COUNT
            let simpleWholeFoods = [
                "apple", "banana", "orange", "carrot", "potato", "tomato",
                "cucumber", "lettuce", "spinach", "broccoli", "rice", "water"
            ]

            // Only skip exact single-word matches
            if simpleWholeFoods.contains(trimmed) && !trimmed.contains(" ") {
                return false
            }

            return true
        }

        // CRITICAL FIX: Detect ready meals and prepared dishes by name
        let isReadyMeal = detectReadyMeal(name: lowerName, ingredientCount: totalIngredientCount)

        // Additive count (prefer provided additives; fallback to analysis with filtered ingredients)
        // CRITICAL FIX: Include ultra-processed ingredients as additives in the count
        let fullAnalysis: AdditiveAnalysis
        let filteredAnalysisText = filteredIngredients.joined(separator: ", ")
        fullAnalysis = analyseAdditives(in: filteredAnalysisText)

        // CRITICAL FIX: Deduplicate additives - many items appear in BOTH comprehensive and ultra-processed databases
        // E.g., lecithin (E322), glucose syrup, palm oil, xanthan gum all appear in both
        let additiveCount: Int = {
            if let additives = food.additives {
                // When we have provided additives, deduplicate against ultra-processed
                // NutritionAdditiveInfo uses 'code' not 'eNumber'
                let providedNames = Set(additives.map { $0.name.lowercased() })
                let providedCodes = Set(additives.map { $0.code.lowercased() }.filter { !$0.isEmpty })

                // Only count ultra-processed that aren't already in provided additives
                let uniqueUltraProcessed = fullAnalysis.ultraProcessedIngredients.filter { ultra in
                    let ultraNameLower = ultra.name.lowercased()
                    // Check if this ultra-processed ingredient is already counted
                    let isAlreadyCounted = providedNames.contains(ultraNameLower) ||
                        providedCodes.contains(where: { ultraNameLower.contains($0) || $0.contains(ultraNameLower) })
                    return !isAlreadyCounted
                }
                return additives.count + uniqueUltraProcessed.count
            } else {
                // Deduplicate between comprehensive additives and ultra-processed
                let comprehensiveNames = Set(fullAnalysis.comprehensiveAdditives.map { $0.name.lowercased() })
                let comprehensiveENumbers = Set(fullAnalysis.comprehensiveAdditives.map { $0.eNumber.lowercased() }.filter { !$0.isEmpty })

                // Only count ultra-processed that aren't already in comprehensive additives
                let uniqueUltraProcessed = fullAnalysis.ultraProcessedIngredients.filter { ultra in
                    let ultraNameLower = ultra.name.lowercased()
                    // Check if this ultra-processed ingredient has a matching E-number or name in comprehensive
                    let isAlreadyCounted = comprehensiveNames.contains(ultraNameLower) ||
                        comprehensiveENumbers.contains(where: { eNum in
                            // Match by E-number if ultra-processed has one associated
                            ultraNameLower.contains(eNum)
                        }) ||
                        comprehensiveNames.contains(where: { name in
                            // Match by name similarity (e.g., "Lecithins" matches "lecithin")
                            name.contains(ultraNameLower) || ultraNameLower.contains(name)
                        })
                    return !isAlreadyCounted
                }
                return fullAnalysis.comprehensiveAdditives.count + uniqueUltraProcessed.count
            }
        }()

        // CRITICAL FIX: Use TOTAL ingredient count for complexity, not filtered
        // Foods with many ingredients are inherently more processed
        let ingredientComplexityWeight: Double = {
            if totalIngredientCount >= 15 { return 1.5 }      // Very complex recipe
            else if totalIngredientCount >= 10 { return 1.0 } // Complex recipe
            else if totalIngredientCount >= 6 { return 0.5 }  // Moderate complexity
            else { return 0.0 }
        }()

        // CRITICAL FIX: Detect processed cooking ingredients (cream, butter, wine, stock)
        let processedCookingWeight = detectProcessedCookingIngredients(in: lowerText)

        // Industrial process weight - ENHANCED with ready meal detection
        let industrialProcessWeight: Double = {
            var weight = 0.0

            // Original industrial keywords
            let industrialKeywords = [
                "powder", "powdered", "protein powder", "isolate", "extruded",
                "blend", "blended", "shake", "smoothie", "instant mix", "meal replacement", "bar"
            ]
            if industrialKeywords.contains(where: { lowerText.contains($0) }) {
                weight += 0.5
            }

            // Ready meal penalty
            if isReadyMeal {
                weight += 1.0
            }

            return min(weight, 1.5)
        }()

        // Additive weight
        let additiveWeight: Double = additiveCount > 5 ? 1.5 : (additiveCount >= 3 ? 1.0 : (additiveCount >= 1 ? 0.5 : 0.0))

        // CRITICAL FIX: Detect beverages and apply per-serving sugar analysis
        let isBeverageProduct = isBeverage(food: food)

        // CRITICAL FIX: Extreme sugar penalty - use per-serving for beverages, per-100g for solids
        let extremeSugarWeight: Double = {
            if isBeverageProduct {
                // For beverages, use per-serving sugar analysis to catch diluted products like Coke
                let sugarPerServing = calculateSugarPerServing(food: food)
                if sugarPerServing >= 30 { return 2.0 }      // Very high sugar per serving (most sodas)
                else if sugarPerServing >= 20 { return 1.5 } // High sugar per serving (sweetened teas, juices)
                else if sugarPerServing >= 10 { return 1.0 } // Moderate sugar per serving (flavored waters)
                else if sugarPerServing >= 5 { return 0.5 }  // Light sugar per serving
                else { return 0.0 }
            } else {
                // For solid foods, use traditional per-100g analysis
                let sugar = food.sugar
                if sugar >= 70 { return 2.0 }      // Pure sugar products (candy, sweets)
                else if sugar >= 50 { return 1.5 } // Very high sugar (candy bars, etc.)
                else if sugar >= 30 { return 0.5 } // High sugar (sweetened products)
                else { return 0.0 }
            }
        }()

        // CRITICAL FIX: Empty calorie penalty for nutritionally void products (like Coke)
        let emptyCalorieWeight: Double = isEmptyCalorie(food: food) ? 1.5 : 0.0

        // Processing Intensity: clamp(1 + all weights, 1, 5)
        // ENHANCED: Now includes processedCookingWeight for cream, butter, wine, stock etc.
        let processingIntensity = clamp(
            1.0 + additiveWeight + ingredientComplexityWeight + industrialProcessWeight +
            extremeSugarWeight + emptyCalorieWeight + processedCookingWeight,
            min: 1.0, max: 5.0
        )

        // CRITICAL FIX: Detect whole, unprocessed foods (fruits, vegetables, etc.)
        // Must have: no additives, 1 or fewer ingredients, no industrial processing, no ready meal indicators
        let isWholeUnprocessedFood = (
            additiveCount == 0 &&
            totalIngredientCount <= 1 &&
            industrialProcessWeight == 0.0 &&
            processedCookingWeight == 0.0 &&
            !isReadyMeal
        )

        // Nutrient Integrity
        let base: Double = 2.0
        let macroBalance: Double = (food.protein > 10 && food.fiber > 2 && food.sugar < 10) ? 1.0 : 0.0
        let fortifiedCount = countFortifiedMicronutrients(food.micronutrientProfile)

        // FIX: Don't penalize natural foods for not being fortified - give them equivalent credit for being whole foods
        let fortificationBonus: Double
        if isWholeUnprocessedFood {
            // Whole foods get natural nutrient bonus instead of fortification bonus
            fortificationBonus = 2.0  // Higher than fortified foods to reward natural nutrition
        } else {
            fortificationBonus = fortifiedCount >= 10 ? 1.0 : 0.0
        }

        let sugarPenalty: Double = (food.sugar > 15) ? 1.0 : 0.0
        let fibreBonus: Double = (food.fiber > 3) ? 0.5 : 0.0

        // nutrient_integrity = clamp(base + macro_balance + fortification_bonus - sugar_penalty + fibre_bonus, 1, 5)
        let nutrientIntegrity = clamp(base + macroBalance + fortificationBonus - sugarPenalty + fibreBonus, min: 1.0, max: 5.0)

        // final_index = (processing_intensity * 0.6) + ((6 - nutrient_integrity) * 0.4)
        let finalIndex = (processingIntensity * 0.6) + ((6.0 - nutrientIntegrity) * 0.4)

        // Grade thresholds - neutral descriptive labels
        let (grade, label): (String, String) = {
            switch finalIndex {
            case 1.0...1.5: return ("A", "Minimal processing")
            case 1.6...2.3: return ("B", "Light processing")
            case 2.4...3.1: return ("C", "Moderate processing")
            case 3.2...3.8: return ("D", "Notable processing")
            case 3.9...4.5: return ("E", "High processing")
            default:         return ("F", "Extensive processing")
            }
        }()

        // Explanation (user-facing, branded)
        let explanation = buildNutraSafeExplanation(
            foodName: food.name,
            processingIntensity: processingIntensity,
            nutrientIntegrity: nutrientIntegrity,
            finalIndex: finalIndex,
            grade: grade,
            additiveCount: additiveCount,
            ingredientCount: totalIngredientCount,
            fortifiedCount: fortifiedCount,
            sugarPer100g: food.sugar,
            fiberPer100g: food.fiber,
            proteinPer100g: food.protein,
            industrialProcessApplied: industrialProcessWeight > 0,
            isWholeUnprocessedFood: isWholeUnprocessedFood,
            extremeSugarApplied: extremeSugarWeight > 0,
            isBeverageProduct: isBeverageProduct,
            emptyCalorieApplied: emptyCalorieWeight > 0,
            isReadyMeal: isReadyMeal,
            processedCookingApplied: processedCookingWeight > 0
        )

        return NutraSafeProcessingGradeResult(
            processing_intensity: processingIntensity,
            nutrient_integrity: nutrientIntegrity,
            final_index: finalIndex,
            grade: grade,
            label: label,
            explanation: explanation
        )
    }

    private func clamp(_ value: Double, min: Double, max: Double) -> Double {
        return Swift.max(min, Swift.min(max, value))
    }

    private func countFortifiedMicronutrients(_ profile: MicronutrientProfile?) -> Int {
        guard let profile = profile else { return 0 }
        let vitaminCount = profile.vitamins.values.filter { $0 > 0 }.count
        let mineralCount = profile.minerals.values.filter { $0 > 0 }.count
        return vitaminCount + mineralCount
    }

    // MARK: - Ready Meal Detection

    /// Detects if a food is a ready meal or prepared dish based on name patterns and ingredient complexity
    private func detectReadyMeal(name: String, ingredientCount: Int) -> Bool {
        // Only flag LOW-QUALITY ready meals - not premium brands using real ingredients
        // Premium brands that cook with real ingredients shouldn't be penalized
        let premiumReadyMealBrands = [
            "charlie bigham", "cook", "m&s dine in", "waitrose entertaining",
            "daylesford", "gail's", "ottolenghi"
        ]

        // If it's a premium brand, don't flag as "ready meal" for penalty purposes
        if premiumReadyMealBrands.contains(where: { name.contains($0) }) {
            return false
        }

        // Budget/mass-market ready meal indicators (these typically use more additives)
        let cheapReadyMealPatterns = [
            "ready meal", "microwave meal", "heat and eat", "heat & eat",
            "meal deal", "value", "basics", "everyday"
        ]

        let isCheapReadyMeal = cheapReadyMealPatterns.contains(where: { name.contains($0) })

        // Very high ingredient count (15+) without premium brand = likely industrial
        let veryHighIngredientCount = ingredientCount >= 15

        return isCheapReadyMeal || veryHighIngredientCount
    }

    /// Detects INDUSTRIAL processing indicators - NOT normal cooking ingredients
    /// Cream, butter, wine, stock are NORMAL cooking ingredients and should NOT be penalized
    private func detectProcessedCookingIngredients(in text: String) -> Double {
        var weight = 0.0

        // ONLY penalize truly industrial/processed indicators
        // Normal cooking ingredients (cream, butter, wine, stock, herbs) are NOT penalized
        let industrialIndicators: [(pattern: String, weight: Double)] = [
            // Industrial fats
            ("margarine", 0.3),
            ("vegetable fat", 0.2),

            // Industrial shortcuts (vs real cooking)
            ("stock cube", 0.15), ("bouillon cube", 0.15),
            ("onion powder", 0.1), ("garlic powder", 0.1),
            ("reconstituted", 0.2),
            ("from concentrate", 0.1),

            // Pre-made sauces (industrial vs homemade)
            ("cheese sauce", 0.15),
            ("white sauce", 0.1),
            ("bechamel", 0.1)
        ]

        for (pattern, patternWeight) in industrialIndicators {
            if text.contains(pattern) {
                weight += patternWeight
            }
        }

        // Cap at 0.5 - this shouldn't dominate the score
        return min(weight, 0.5)
    }

    private func buildNutraSafeExplanation(
        foodName: String,
        processingIntensity: Double,
        nutrientIntegrity: Double,
        finalIndex: Double,
        grade: String,
        additiveCount: Int,
        ingredientCount: Int,
        fortifiedCount: Int,
        sugarPer100g: Double,
        fiberPer100g: Double,
        proteinPer100g: Double,
        industrialProcessApplied: Bool,
        isWholeUnprocessedFood: Bool,
        extremeSugarApplied: Bool,
        isBeverageProduct: Bool,
        emptyCalorieApplied: Bool,
        isReadyMeal: Bool = false,
        processedCookingApplied: Bool = false
    ) -> String {
        var parts: [String] = []
        parts.append("NutraSafe Processing Grade™ for '\(foodName)': \(grade).")

        if isWholeUnprocessedFood {
            parts.append("This is a whole, unprocessed food with no additives.")
        } else {
            var processingFactors: [String] = []

            // Ready meal is the most significant factor
            if isReadyMeal {
                processingFactors.append("prepared/ready meal")
            }

            if additiveCount > 0 {
                processingFactors.append("\(additiveCount) additive(s)")
            }

            if industrialProcessApplied && !isReadyMeal {
                processingFactors.append("industrial processing indicators")
            }

            if processedCookingApplied {
                processingFactors.append("processed cooking ingredients")
            }

            if extremeSugarApplied {
                if isBeverageProduct {
                    processingFactors.append("high sugar per serving (beverage)")
                } else {
                    processingFactors.append("extreme sugar content")
                }
            }

            if emptyCalorieApplied {
                processingFactors.append("empty calories (zero nutrition)")
            }

            // Always show ingredient count for complex foods
            if ingredientCount >= 5 {
                processingFactors.append("\(ingredientCount) ingredients (complex recipe)")
            } else {
                processingFactors.append("\(ingredientCount) ingredient(s)")
            }

            parts.append("Processing intensity \(String(format: "%.1f", processingIntensity)) driven by \(processingFactors.joined(separator: ", ")).")
        }

        var nutritionBits: [String] = []
        nutritionBits.append("protein \(String(format: "%.0f", proteinPer100g))g")
        nutritionBits.append("fibre \(String(format: "%.1f", fiberPer100g))g")
        nutritionBits.append("sugar \(String(format: "%.0f", sugarPer100g))g")

        if isWholeUnprocessedFood {
            parts.append("Nutrient integrity \(String(format: "%.1f", nutrientIntegrity)) from naturally occurring vitamins and minerals (\(nutritionBits.joined(separator: ", "))).")
        } else {
            parts.append("Nutrient integrity \(String(format: "%.1f", nutrientIntegrity)) considering balanced macros (\(nutritionBits.joined(separator: ", "))) and \(fortifiedCount >= 10 ? "broad fortification (\(fortifiedCount) micronutrients)" : "limited micronutrient coverage").")
        }

        parts.append("Overall index \(String(format: "%.1f", finalIndex)).")
        let summary: String = {
            switch grade {
            case "A": return "Natural & nutrient-dense."
            case "B": return "Lightly processed and balanced."
            case "C": return "Moderately processed with acceptable nutrition."
            case "D": return "Heavily processed but functional."
            case "E": return "Ultra-processed with weak nutrition."
            default:  return "Highly processed with poor nutrition."
            }
        }()
        parts.append(summary)
        return parts.joined(separator: " ")
    }

    // Public method to analyze additives in ingredients
    func analyzeAdditives(in ingredientsText: String) -> [AdditiveInfo] {
        // PERFORMANCE: Check cache first
        let cacheKey = ingredientsText.lowercased()
        cacheLock.lock()
        if let cached = additivesCache[cacheKey] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

                let analysis = analyseAdditives(in: ingredientsText)

        // PERFORMANCE: Cache the result
        cacheLock.lock()
        additivesCache[cacheKey] = analysis.comprehensiveAdditives
        cacheLock.unlock()

        return analysis.comprehensiveAdditives
    }

    func calculateProcessingScore(for foodName: String, ingredients: String? = nil, sugarPer100g: Double? = nil) -> NutritionProcessingScore {
        // PERFORMANCE: Check cache first
        let cacheKey = "\(foodName)|\(ingredients ?? "")|\(sugarPer100g ?? 0)"
        cacheLock.lock()
        if let cached = scoreCache[cacheKey] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        let foodLower = foodName.lowercased()

        // CRITICAL: If no real ingredients provided, return "Not enough data" for anything that's not obviously unprocessed
        guard let ingredients = ingredients, !ingredients.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // Only allow high scores for very obviously unprocessed single foods
            let result: NutritionProcessingScore
            if isObviouslyUnprocessedSingleFood(foodLower) {
                result = NutritionProcessingScore(
                    grade: ProcessingGrade.a,
                    score: 85,
                    explanation: "Single unprocessed food",
                    factors: ["Fresh whole food"],
                    processingLevel: ProcessingLevel.unprocessed,
                    additiveCount: 0,
                    eNumberCount: 0,
                    naturalScore: 85
                )
            } else {
                // Everything else gets "Not enough data"
                result = NutritionProcessingScore(
                    grade: ProcessingGrade.unknown,
                    score: 0,
                    explanation: "No ingredient data available for accurate scoring",
                    factors: ["No ingredient list"],
                    processingLevel: ProcessingLevel.unprocessed,
                    additiveCount: 0,
                    eNumberCount: 0,
                    naturalScore: 0
                )
            }

            // PERFORMANCE: Cache and return
            cacheLock.lock()
            scoreCache[cacheKey] = result
            cacheLock.unlock()
            return result
        }
        
        // Use real ingredients for analysis
        let analysisText = ingredients.lowercased()
        
        // Determine base processing level from ingredients
        let processingLevel = determineProcessingLevel(analysisText, isIngredientList: true)
        
        // Analyze additives and E-numbers in ingredients
        let additiveAnalysis = analyseAdditives(in: analysisText)
        
        // Calculate natural food bonus
        let naturalScore = calculateNaturalScore(analysisText)
        
        // Calculate base score from processing level
        var totalScore = processingLevel.score
        
        // NEW: Apply ultra-processed ingredients penalty
        totalScore -= additiveAnalysis.ultraProcessedPenalty

        // Apply comprehensive additive penalties based on health scores
        if !additiveAnalysis.comprehensiveAdditives.isEmpty {
            // Use comprehensive health scoring (0-100 scale, lower is worse)
            let avgHealthScore = additiveAnalysis.totalHealthScore
            let healthPenalty = max(0, 50 - avgHealthScore) // Penalty when health score is below 50
            totalScore -= healthPenalty

            // Additional penalties for specific warning categories
            if additiveAnalysis.hasChildWarnings {
                totalScore -= 15  // Extra penalty for child warnings
            }
            if additiveAnalysis.hasAllergenWarnings {
                totalScore -= 10  // Extra penalty for allergen warnings
            }
            if additiveAnalysis.worstVerdict == "caution" {
                totalScore -= 10  // Extra penalty for caution verdict
            }
        } else {
            // Fallback to basic penalties if comprehensive data unavailable
            totalScore -= (additiveAnalysis.eNumbers.count * 15)  // Heavy penalty for E-numbers
            totalScore -= (additiveAnalysis.additives.count * 12)   // Increased penalty for additives
            totalScore -= (additiveAnalysis.preservatives.count * 10) // Heavy penalty for preservatives
            
            // Extra penalty for multiple artificial colors (common in candy)
            // Use specific artificial color names, not generic color words
            let artificialColorNames = [
                "tartrazine", "e102",
                "sunset yellow", "yellow 5", "yellow 6", "fd&c yellow",
                "allura red", "red 40", "red 3", "fd&c red",
                "brilliant blue", "blue fcf", "fd&c blue",
                "erythrosine", "carmoisine", "azorubine", "quinoline yellow"
            ]
            let colorAdditives = additiveAnalysis.additives.filter { additive in
                artificialColorNames.contains { additive.contains($0) }
            }
            if colorAdditives.count >= 2 {
                totalScore -= 20  // Multiple artificial colors penalty (candy indicator)
            }
        }
        
        // Apply natural bonuses
        totalScore += naturalScore
        
        // Apply ultra-processed penalties
        if processingLevel == .ultraProcessed {
            totalScore -= 30  // Heavy penalty for ultra-processed foods
        }
        
        // Apply sugar content penalties if nutritional data is available
        if let sugar = sugarPer100g {
            if sugar >= 50 {
                totalScore -= 25  // Extreme sugar penalty (like candy)
            } else if sugar >= 25 {
                totalScore -= 15  // High sugar penalty 
            } else if sugar >= 15 {
                totalScore -= 8   // Moderate sugar penalty
            } else if sugar >= 10 {
                totalScore -= 4   // Light sugar penalty
            }
        }
        
        // Clamp score between 0-100
        totalScore = max(0, min(100, totalScore))
        
        // Determine grade
        let grade = scoreToGrade(totalScore)
        
        // Build explanation
        let explanation = buildExplanation(processingLevel: processingLevel, 
                                         additiveAnalysis: additiveAnalysis, 
                                         naturalScore: naturalScore,
                                         totalScore: totalScore)
        
        // Build factors list
        let factors = buildFactors(processingLevel: processingLevel,
                                 additiveAnalysis: additiveAnalysis,
                                 naturalScore: naturalScore)

        let result = NutritionProcessingScore(
            grade: grade,
            score: totalScore,
            explanation: explanation,
            factors: factors,
            processingLevel: processingLevel,
            additiveCount: additiveAnalysis.additives.count,
            eNumberCount: additiveAnalysis.eNumbers.count,
            naturalScore: naturalScore
        )

        // PERFORMANCE: Cache the result for future calls
        cacheLock.lock()
        scoreCache[cacheKey] = result
        cacheLock.unlock()

        return result
    }
    
    private func determineProcessingLevel(_ food: String, isIngredientList: Bool = false) -> ProcessingLevel {
        
        // If we have real ingredients, analyze them scientifically
        if isIngredientList {
            return analyzeIngredientsProcessingLevel(food)
        }
        // Ultra-processed foods (F grade territory)
        let ultraProcessedTerms = [
            "fizzy drink", "soda", "cola", "pepsi", "coca cola", "energy drink",
            "ready meal", "microwave meal", "instant", "processed meat", "sausage",
            "burger", "chips", "crisps", "biscuits", "cookies", "cake mix",
            "ice cream", "chocolate bar", "candy bar", "sweets", "candy", "margarine",
            "milky way", "mars bar", "snickers", "twix", "kit kat", "bounty",
            "maltesers", "smarties", "haribo", "gummy", "jelly beans",
            "chicken nuggets", "fish fingers", "frozen pizza", "pot noodle",
            // Additional candy and junk food terms
            "nerds", "skittles", "starburst", "jolly rancher", "life savers", "mentos",
            "pop rocks", "warheads", "sour patch", "swedish fish", "mike and ike",
            "hot tamales", "lollipop", "lollies", "gobstopper", "laffy taffy",
            "airheads", "now and later", "blow pop", "ring pop", "fun dip",
            "pixie sticks", "sweet tart", "runts", "cheetos", "doritos", "fritos",
            "pringles", "lay's", "ruffles", "cheez-its", "goldfish", "oreos", "nutter butter",
            "chips ahoy", "fig newton", "pop tart", "toaster strudel", "ho ho", "twinkie",
            "ding dong", "hostess", "little debbie", "moon pie", "rice krispie treat"
        ]
        
        // Processed foods (C-D grade territory)
        let processedTerms = [
            "bread", "cheese", "tinned", "canned", "soup", "pasta sauce",
            "yoghurt drink", "fruit juice", "smoothie", "cereal", "granola",
            "ham", "bacon", "salami", "pickled", "jam", "marmalade"
        ]
        
        // Minimally processed foods (A-B grade territory)
        let minimallyProcessedTerms = [
            "frozen", "dried", "tinned beans", "plain yoghurt", "milk",
            "flour", "oats", "rice", "nuts", "nut butter", "olive oil"
        ]
        
        // Unprocessed foods (A+ grade territory)
        let unprocessedTerms = [
            "apple", "banana", "orange", "grapes", "berry", "strawberry",
            "carrot", "broccoli", "spinach", "lettuce", "tomato", "potato",
            "chicken breast", "salmon", "cod", "beef", "lamb", "egg",
            "avocado", "cucumber", "pepper", "onion", "garlic", "lemon",
            "fresh", "raw", "organic"
        ]
        
        // Check categories in order of processing level
        if ultraProcessedTerms.contains(where: { food.contains($0) }) {
            return .ultraProcessed
        } else if processedTerms.contains(where: { food.contains($0) }) {
            return .processed
        } else if minimallyProcessedTerms.contains(where: { food.contains($0) }) {
            return .minimally
        } else if unprocessedTerms.contains(where: { food.contains($0) }) {
            return .unprocessed
        }
        
        // Additional pattern-based ultra-processed detection
        let suspiciousPatterns = [
            // Any food with flavor descriptions is likely processed
            "flavor", "flavour", "flavored", "flavoured",
            // Brand-style naming patterns
            "original", "classic", "crispy", "crunchy", "chewy",
            // Processed food indicators
            "mix", "bar", "bite", "chunk", "piece", "strip",
            // Sweet treats not caught above
            "fudge", "caramel", "nougat", "truffle", "praline",
            "gum", "mint", "drop", "tablet", "pastille"
        ]
        
        if suspiciousPatterns.contains(where: { food.contains($0) }) {
            return .ultraProcessed
        }
        
        // More conservative default - if we can't classify it and it's not obviously whole food, 
        // assume it's at least processed
        return .processed
    }
    
    
    private struct AdditiveAnalysis {
        let eNumbers: [String]
        let additives: [String]
        let preservatives: [String]
        let goodAdditives: [String]
        let comprehensiveAdditives: [AdditiveInfo]  // New: Full additive analysis
        let totalHealthScore: Int
        let worstVerdict: String
        let hasChildWarnings: Bool
        let hasAllergenWarnings: Bool
        let ultraProcessedIngredients: [UltraProcessedIngredient]  // NEW: Ultra-processed ingredients detected
        let ultraProcessedPenalty: Int  // NEW: Total penalty from ultra-processed ingredients
    }
    
    // MARK: - Ultra-Processed Ingredients Database

    struct UltraProcessedIngredient: Codable {
        let name: String
        let synonyms: [String]
        let processing_penalty: Int
        let category: String
        let concerns: String
        let nova_group: Int
        let what_it_is: String?
        let why_its_used: String?
        let where_it_comes_from: String?
    }

    private lazy var ultraProcessedDatabase: [String: UltraProcessedIngredient]? = {
        guard let path = Bundle.main.path(forResource: "ultra_processed_ingredients", ofType: "json") else {
                        return nil
        }

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let ingredients = json["ultra_processed_ingredients"] as? [String: Any] else {
                        return nil
        }

        var database: [String: UltraProcessedIngredient] = [:]

        // Parse each category
        for (_, categoryData) in ingredients {
            if let categoryDict = categoryData as? [String: Any] {
                for (key, ingredientData) in categoryDict {
                    if let ingredientDict = ingredientData as? [String: Any],
                       let name = ingredientDict["name"] as? String,
                       let synonyms = ingredientDict["synonyms"] as? [String],
                       let penalty = ingredientDict["processing_penalty"] as? Int,
                       let category = ingredientDict["category"] as? String,
                       let concerns = ingredientDict["concerns"] as? String,
                       let novaGroup = ingredientDict["nova_group"] as? Int {

                        let ingredient = UltraProcessedIngredient(
                            name: name,
                            synonyms: synonyms,
                            processing_penalty: penalty,
                            category: category,
                            concerns: concerns,
                            nova_group: novaGroup,
                            what_it_is: ingredientDict["what_it_is"] as? String,
                            why_its_used: ingredientDict["why_its_used"] as? String,
                            where_it_comes_from: ingredientDict["where_it_comes_from"] as? String
                        )

                        // Store by lowercase name and synonyms
                        database[name.lowercased()] = ingredient
                        for synonym in synonyms {
                            database[synonym.lowercased()] = ingredient
                        }
                    }
                }
            }
        }

                return database
    }()

    private lazy var comprehensiveAdditives: [String: AdditiveInfo]? = {

        guard let path = Bundle.main.path(forResource: "ingredients_consolidated", ofType: "json") else {
                        return nil
        }

                guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
                        return nil
        }

                let decoder = JSONDecoder()
        do {
            let consolidated = try decoder.decode(ConsolidatedIngredientsDatabase.self, from: data)
                        ProcessingScorer.shared.databaseVersion = consolidated.metadata.version

            // Convert array to dictionary keyed by eNumber, name, AND synonyms (for better matching)
            var additives: [String: AdditiveInfo] = [:]
            var uniqueENumbers = Set<String>() // Track unique E-numbers across all ingredients

            for ingredient in consolidated.ingredients {
                // Index by ALL E-numbers for this ingredient (not just first one)
                for eNumber in ingredient.eNumbers {
                    if !eNumber.isEmpty {
                        additives[eNumber.lowercased()] = ingredient
                        uniqueENumbers.insert(eNumber)
                    }
                }

                // Index by name (e.g., "sodium nitrate", "Sodium Nitrate")
                if !ingredient.name.isEmpty {
                    additives[ingredient.name.lowercased()] = ingredient
                }

                // Index by synonyms (e.g., "MSG", "monosodium glutamate")
                for synonym in ingredient.synonyms {
                    if !synonym.isEmpty {
                        additives[synonym.lowercased()] = ingredient
                    }
                }
            }

            // Count ingredients with sources
            let withSources = consolidated.ingredients.filter { !$0.sources.isEmpty }.count
            let totalSources = consolidated.ingredients.reduce(0) { $0 + $1.sources.count }
            return additives
        } catch {
            // Decoding failed - try fallback format below
        }

        // Fallback: Try old nested format for backward compatibility
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        return nil
        }

                if let metadata = json["metadata"] as? [String: Any] {
            let version = metadata["version"] as? String ?? "2025.1"
                        ProcessingScorer.shared.databaseVersion = version
        }

        var additives: [String: AdditiveInfo] = [:]

        // Parse the nested category structure (legacy format)
        if let categories = json["categories"] as? [String: Any] {
                        for (categoryName, categoryData) in categories {
                if let categoryDict = categoryData as? [String: Any] {
                                        for (rangeName, rangeData) in categoryDict {
                        if let rangeDict = rangeData as? [String: Any] {
                                                        for (code, additiveData) in rangeDict {
                                if let additiveDict = additiveData as? [String: Any],
                                   let name = additiveDict["name"] as? String {

                                    let safety = additiveDict["safety"] as? String ?? "neutral"
                                    let concerns = additiveDict["concerns"] as? String ?? ""
                                    let synonyms = additiveDict["synonyms"] as? [String] ?? []
                                    let originString = additiveDict["origin"] as? String ?? "unknown"
                                    let uses = additiveDict["uses"] as? String ?? ""

                                    let verdict: AdditiveVerdict
                                    switch safety.lowercased() {
                                    case "positive": verdict = .neutral
                                    case "caution": verdict = .caution
                                    case "avoid": verdict = .avoid
                                    default: verdict = .neutral
                                    }

                                    let additiveCategory: AdditiveCategory
                                    if categoryName.contains("color") || categoryName.contains("colour") {
                                        additiveCategory = .colour
                                    } else if categoryName.contains("preserv") {
                                        additiveCategory = .preservative
                                    } else {
                                        additiveCategory = .other
                                    }

                                    let origin = Self.mapOrigin(originString)
                                    let hasChildWarning = concerns.lowercased().contains("child") || concerns.lowercased().contains("hyperactivity")
                                    let hasSulphitesWarning = concerns.lowercased().contains("sulphite") || concerns.lowercased().contains("sulfite")

                                    let overview: String
                                    if !uses.isEmpty && !originString.isEmpty {
                                        overview = "\(name) is a \(categoryName) additive from \(originString) origin. Typically used in \(uses)."
                                    } else if !originString.isEmpty {
                                        overview = "\(name) is a \(categoryName) additive from \(originString) origin."
                                    } else {
                                        overview = "\(name) used as a \(categoryName)."
                                    }

                                    let additiveInfo = AdditiveInfo(
                                        eNumbers: [code],
                                        name: name,
                                        group: Self.mapCategoryToGroup(categoryName),
                                        isPermittedGB: true,
                                        isPermittedNI: true,
                                        isPermittedEU: !concerns.lowercased().contains("banned"),
                                        statusNotes: concerns.isEmpty ? nil : concerns,
                                        hasChildWarning: hasChildWarning,
                                        hasPKUWarning: false,
                                        hasPolyolsWarning: false,
                                        hasSulphitesAllergenLabel: hasSulphitesWarning,
                                        category: additiveCategory,
                                        origin: origin,
                                        overview: overview,
                                        typicalUses: uses,
                                        effectsSummary: concerns.isEmpty ? "Generally recognised as safe when used as directed." : concerns,
                                        effectsVerdict: verdict,
                                        synonyms: synonyms,
                                        insNumber: nil,
                                        sources: [],  // Legacy format has no sources
                                        consumerInfo: nil
                                    )

                                    additives[code] = additiveInfo
                                }
                            }
                        }
                    }
                }
            }
        }

                return additives
    }()

    private static func mapCategoryToGroup(_ categoryName: String) -> AdditiveGroup {
        let lower = categoryName.lowercased()
        if lower.contains("color") || lower.contains("colour") {
            return .colour
        } else if lower.contains("preserv") {
            return .preservative
        } else if lower.contains("antioxidant") {
            return .antioxidant
        } else if lower.contains("emuls") {
            return .emulsifier
        } else if lower.contains("stab") {
            return .stabilizer
        } else if lower.contains("thick") {
            return .thickener
        } else if lower.contains("sweet") {
            return .sweetener
        } else if lower.contains("flavour") || lower.contains("flavor") {
            return .flavourEnhancer
        } else if lower.contains("acid") {
            return .acidRegulator
        } else {
            return .other
        }
    }

    private static func mapOrigin(_ originString: String) -> AdditiveOrigin {
        let lower = originString.lowercased()

        // Map origin strings from JSON to AdditiveOrigin enum
        // Priority order matters!
        if lower.contains("animal") {
            return .animal
        } else if lower.contains("plant") {
            return .plant
        } else if lower.contains("mineral") {
            return .mineral
        } else if lower.contains("ferment") || lower.contains("microbial") {
            // Fermentation is a natural process, map to plant-based
            return .plant
        } else if lower.contains("synthetic") && !lower.contains("natural") {
            return .synthetic
        } else {
            // Default for unknown/mixed origins
            return .syntheticPlantMineral
        }
    }
    
    // MARK: - Helper: Word Boundary Matching

    private func matchesWithWordBoundary(text: String, pattern: String) -> Bool {
        // Skip empty patterns
        if pattern.isEmpty {
            return false
        }

        // Escape special regex characters in the pattern
        let escapedPattern = NSRegularExpression.escapedPattern(for: pattern)

        // Use word boundaries (\b) to ensure we match complete words/codes only
        let regexPattern = "\\b\(escapedPattern)\\b"

        // PERFORMANCE: Use cached regex patterns to avoid repeated compilation
        let regex: NSRegularExpression
        cacheLock.lock()
        if let cached = regexPatternCache[regexPattern] {
            regex = cached
            cacheLock.unlock()
        } else {
            cacheLock.unlock()
            guard let newRegex = try? NSRegularExpression(pattern: regexPattern, options: .caseInsensitive) else {
                return false
            }
            cacheLock.lock()
            regexPatternCache[regexPattern] = newRegex
            regex = newRegex
            cacheLock.unlock()
        }

        let range = NSRange(text.startIndex..., in: text)
        let matched = regex.firstMatch(in: text, range: range) != nil

        // DEBUG: Log matches for problematic patterns
        return matched
    }

    // MARK: - Helper: Text Normalization

    private func normalizeIngredientText(_ text: String) -> String {
        var normalized = text.lowercased()

        // Add spaces around punctuation to create word boundaries
        // This helps detect "Colour: paprika extract" as "paprika extract"
        normalized = normalized.replacingOccurrences(of: ":", with: " : ")
        normalized = normalized.replacingOccurrences(of: ";", with: " ; ")
        normalized = normalized.replacingOccurrences(of: ",", with: " , ")
        normalized = normalized.replacingOccurrences(of: "(", with: " ( ")
        normalized = normalized.replacingOccurrences(of: ")", with: " ) ")

        // Remove extra spaces
        normalized = normalized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        // Normalize E-number formats (e-102 → e102, e 102 → e102)
        normalized = normalized.replacingOccurrences(of: "e-", with: "e")
        normalized = normalized.replacingOccurrences(of: "e ", with: "e")

        return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Helper: Match Confidence Scoring

    private func calculateMatchConfidence(additive: AdditiveInfo, text: String) -> Double {
        var score = 0.0
        let normalized = normalizeIngredientText(text)

        var matchDetails: [String] = []

        // E-number exact match with word boundaries (highest confidence)
        if matchesWithWordBoundary(text: normalized, pattern: additive.eNumber.lowercased()) {
            score += 0.95
            matchDetails.append("E-number")
        }

        // Full name exact match with word boundaries
        if matchesWithWordBoundary(text: normalized, pattern: additive.name.lowercased()) {
            score += 0.85
            matchDetails.append("Name")
        }

        // Synonym matches (with word boundaries)
        for synonym in additive.synonyms {
            if !synonym.isEmpty && matchesWithWordBoundary(text: normalized, pattern: synonym.lowercased()) {
                score += 0.70
                matchDetails.append("Synonym: \(synonym)")
                break
            }
        }

        // Debug logging for Tartrazine specifically
        if additive.eNumber == "E102" && score > 0 {
                    }

        // DEBUG: Log Invert sugar false positives
        if additive.name.lowercased() == "invert sugar" && score > 0 {
                    }

        return min(score, 1.0)  // Cap at 100%
    }

    // PERFORMANCE: Internal cache for AdditiveAnalysis results
    private var analysisCache: [String: AdditiveAnalysis] = [:]

    // Helper function to check if an ingredient is a common cooking ingredient (should NOT be flagged as additive)
    private func isCommonCookingIngredient(_ name: String) -> Bool {
        let nameLower = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Very basic ingredients that should NEVER be flagged as additives
        // ONLY exact matches to avoid false positives
        let basicIngredients = [
            "salt", "sea salt", "table salt",
            "sugar", "cane sugar", "brown sugar",
            "water", "flour", "wheat flour",
            "butter", "milk", "cream", "egg", "eggs",
            "oil", "olive oil", "vegetable oil", "sunflower oil", "rapeseed oil",
            "vanilla extract", "baking powder", "baking soda",
            "yeast", "pepper", "black pepper"
        ]

        // Only exclude if it's an EXACT match - no substring matching
        // This prevents excluding "Citric Acid (E330)" when "citric acid" is in the list
        return basicIngredients.contains(nameLower)
    }

    private func analyseAdditives(in food: String) -> AdditiveAnalysis {
        // PERFORMANCE: Check cache first
        let cacheKey = food.lowercased()
        cacheLock.lock()
        if let cached = analysisCache[cacheKey] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()


        let foodLower = food.lowercased()
        let normalizedFood = normalizeIngredientText(food)

        var detectedAdditives: [AdditiveInfo] = []
        var eNumbers: [String] = []
        var additives: [String] = []
        var preservatives: [String] = []
        var goodAdditives: [String] = []

        // Use comprehensive database if available
        if let comprehensiveDB = comprehensiveAdditives {
                        var matchCount = 0
            // Check for E-numbers and additive names with word boundary detection
            for (code, additiveInfo) in comprehensiveDB {
                // Calculate match confidence with word boundaries
                let confidence = calculateMatchConfidence(additive: additiveInfo, text: normalizedFood)

                // Only include matches with confidence >= 60%
                if confidence >= 0.6 {
                    matchCount += 1
                                        if !detectedAdditives.contains(where: { $0.eNumber == additiveInfo.eNumber }) {
                        detectedAdditives.append(additiveInfo)

                        // If E-number matched directly, add to eNumbers array
                        if matchesWithWordBoundary(text: normalizedFood, pattern: code.lowercased()) {
                            eNumbers.append(code)
                        }

                        // Categorize additive
                        if additiveInfo.category.rawValue.lowercased().contains("preservative") {
                            preservatives.append(additiveInfo.name)
                        } else {
                            additives.append(additiveInfo.name)
                        }
                    }
                }
            }

                    } else {
                    }
        
        // Fallback to basic analysis if comprehensive database not available
        if detectedAdditives.isEmpty {
            // Common E-numbers (fallback)
            let commonENumbers = [
                "e100", "e102", "e104", "e110", "e122", "e124", "e129",
                "e200", "e202", "e211", "e220", "e223", "e224", "e228",
                "e621", "e627", "e631", "e635", "e951", "e952", "e954", "e955"
            ]
            
            // Common bad additives (fallback) - Enhanced for specific additive detection
            let badAdditives = [
                "monosodium glutamate", "msg", "high fructose corn syrup", "glucose syrup",
                "sodium nitrite", "sodium nitrate",
                "aspartame", "sucralose", "modified starch",
                // Specific artificial colors
                "brilliant blue fcf", "tartrazine", "sunset yellow fcf", "quinoline yellow",
                "allura red", "red 40", "red 3", "erythrosine", "carmine", "cochineal", "carmoisine", "azorubine",
                "green s", "patent blue", "indigo carmine",
                // Texture agents when explicitly listed
                "lecithin"
            ]
            
            // Common preservatives (fallback)
            let preservativeTerms = [
                "sodium benzoate", "potassium sorbate", "calcium propionate",
                "sodium nitrite", "sodium nitrate", "potassium nitrate",
                "sulfur dioxide", "sodium metabisulfite", "potassium metabisulfite", "sodium bisulfite"
            ]
            
            eNumbers = commonENumbers.filter { matchesWithWordBoundary(text: normalizedFood, pattern: $0) }
            additives = badAdditives.filter { matchesWithWordBoundary(text: normalizedFood, pattern: $0) }
            preservatives = preservativeTerms.filter { matchesWithWordBoundary(text: normalizedFood, pattern: $0) }
        }
        
        // Good additives that should boost score
        let beneficialAdditives = [
            "matcha", "turmeric", "curcumin", "green tea extract",
            "vitamin c", "vitamin e", "beta carotene", "lycopene",
            "probiotics", "prebiotics", "omega 3", "antioxidants"
        ]
        goodAdditives = beneficialAdditives.filter { foodLower.contains($0) }
        
        // Calculate comprehensive health metrics
        let totalHealthScore = detectedAdditives.isEmpty ? 50 :
            detectedAdditives.reduce(into: 0) { $0 += getHealthScore(for: $1) } / detectedAdditives.count

        let worstVerdict = detectedAdditives.contains { $0.effectsVerdict == .caution } ? "caution" : "neutral"
        let hasChildWarnings = detectedAdditives.contains { $0.hasChildWarning }
        let hasAllergenWarnings = detectedAdditives.contains { $0.hasSulphitesAllergenLabel }

        // NEW: Detect ultra-processed ingredients
        var ultraProcessedIngredients: [UltraProcessedIngredient] = []
        var ultraProcessedPenalty = 0

        if let ultraDB = ultraProcessedDatabase {
            // Split ingredients by common delimiters (for future use)
            _ = normalizedFood.components(separatedBy: CharacterSet(charactersIn: ",;()[] "))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            // Check for multi-word ingredients (e.g., "glucose syrup", "palm oil")
            for (key, ingredient) in ultraDB {
                if matchesWithWordBoundary(text: normalizedFood, pattern: key) {
                    // Avoid duplicates
                    if !ultraProcessedIngredients.contains(where: { $0.name == ingredient.name }) {
                        ultraProcessedIngredients.append(ingredient)
                        ultraProcessedPenalty += ingredient.processing_penalty
                    }
                }
            }

        }

        let result = AdditiveAnalysis(
            eNumbers: eNumbers,
            additives: additives,
            preservatives: preservatives,
            goodAdditives: goodAdditives,
            comprehensiveAdditives: detectedAdditives,
            totalHealthScore: totalHealthScore,
            worstVerdict: worstVerdict,
            hasChildWarnings: hasChildWarnings,
            hasAllergenWarnings: hasAllergenWarnings,
            ultraProcessedIngredients: ultraProcessedIngredients,
            ultraProcessedPenalty: ultraProcessedPenalty
        )

        // PERFORMANCE: Cache the result
        cacheLock.lock()
        analysisCache[cacheKey] = result
        cacheLock.unlock()

        return result
    }
    
    private func getHealthScore(for additive: AdditiveInfo) -> Int {
        // Convert AdditiveVerdict enum to health score
        switch additive.effectsVerdict {
        case .neutral: return 70
        case .caution: return 40
        case .avoid: return 10
        }
    }

    private func calculateNaturalScore(_ food: String) -> Int {
        var bonus = 0
        let foodLower = food.lowercased()

        // Marketing/label terms
        let labelBonusTerms = [
            "organic": 10,
            "fresh": 5,
            "raw": 12,
            "whole": 5,
            "unprocessed": 15,
            "homemade": 10,
            "farm fresh": 12,
            "wild caught": 8,
            "grass fed": 8,
            "free range": 6
        ]

        for (term, value) in labelBonusTerms {
            if foodLower.contains(term) {
                bonus += value
            }
        }

        // REAL whole food ingredients - give substantial bonuses for these
        let wholeFoodIngredients: [(term: String, points: Int)] = [
            // Proteins (high value - these are quality ingredients)
            ("chicken", 8), ("beef", 8), ("lamb", 8), ("pork", 6), ("turkey", 8),
            ("salmon", 10), ("cod", 8), ("prawns", 8), ("fish", 6),
            ("egg", 6), ("eggs", 6),

            // Dairy (real dairy is a quality ingredient)
            ("cream", 6), ("double cream", 8), ("butter", 6), ("milk", 5),
            ("cheese", 5), ("parmesan", 6), ("cheddar", 5), ("mascarpone", 6),

            // Vegetables
            ("onion", 4), ("garlic", 4), ("tomato", 4), ("carrot", 4),
            ("celery", 4), ("leek", 4), ("mushroom", 4), ("spinach", 5),
            ("broccoli", 5), ("pepper", 4), ("courgette", 4), ("aubergine", 4),
            ("potato", 3), ("peas", 4), ("beans", 4), ("lentils", 5),

            // Herbs and aromatics (sign of real cooking)
            ("basil", 5), ("thyme", 5), ("rosemary", 5), ("parsley", 4),
            ("oregano", 4), ("sage", 4), ("bay leaf", 4), ("bay leaves", 4),
            ("coriander", 4), ("chives", 4), ("tarragon", 4), ("dill", 4),

            // Quality cooking ingredients
            ("olive oil", 6), ("rapeseed oil", 4), ("white wine", 5), ("red wine", 5),
            ("stock", 4), ("chicken stock", 5), ("beef stock", 5),
            ("lemon juice", 4), ("lime juice", 4), ("vinegar", 3),

            // Grains and carbs
            ("pasta", 3), ("rice", 3), ("flour", 2), ("breadcrumbs", 2),

            // Nuts and seeds
            ("almonds", 5), ("walnuts", 5), ("pine nuts", 5), ("cashews", 5)
        ]

        var wholeFoodCount = 0
        for (term, points) in wholeFoodIngredients {
            if foodLower.contains(term) {
                bonus += points
                wholeFoodCount += 1
            }
        }

        // Bonus for having many whole food ingredients (sign of real cooking)
        if wholeFoodCount >= 8 {
            bonus += 15  // Lots of real ingredients
        } else if wholeFoodCount >= 5 {
            bonus += 10  // Good variety of real ingredients
        } else if wholeFoodCount >= 3 {
            bonus += 5   // Some real ingredients
        }

        return min(bonus, 60) // Increased cap to 60 to allow real food to shine
    }
    
    private func scoreToGrade(_ score: Int) -> ProcessingGrade {
        switch score {
        case 90...100:
            return .aPlus
        case 80...89:
            return .a
        case 70...79:
            return .b
        case 60...69:
            return .c
        case 40...59:
            return .d
        default:
            return .f
        }
    }
    
    private func buildExplanation(processingLevel: ProcessingLevel, 
                                additiveAnalysis: AdditiveAnalysis, 
                                naturalScore: Int, 
                                totalScore: Int) -> String {
        var explanation = "Processing Level: \(processingLevel.rawValue). "
        
        // NEW: Ultra-processed ingredients mention
        if !additiveAnalysis.ultraProcessedIngredients.isEmpty {
            let count = additiveAnalysis.ultraProcessedIngredients.count
            explanation += "\(count) ultra-processed ingredient(s) detected. "
        }

        // Use comprehensive additive analysis if available
        if !additiveAnalysis.comprehensiveAdditives.isEmpty {
            let count = additiveAnalysis.comprehensiveAdditives.count
            explanation += "\(count) additive(s) detected. "

            if additiveAnalysis.totalHealthScore < 30 {
                explanation += "Contains multiple food additives. "
            } else if additiveAnalysis.totalHealthScore < 50 {
                explanation += "Contains several food additives. "
            }

            if additiveAnalysis.hasChildWarnings {
                explanation += "⚠️ Contains additives some studies have associated with hyperactivity in sensitive children. "
            }

            if additiveAnalysis.hasAllergenWarnings {
                explanation += "⚠️ Contains allergen-related additives. "
            }
        } else {
            // Fallback explanation
            if additiveAnalysis.eNumbers.count > 0 {
                explanation += "\(additiveAnalysis.eNumbers.count) E-number(s) detected. "
            }

            if additiveAnalysis.additives.count > 0 {
                explanation += "\(additiveAnalysis.additives.count) additive(s) detected. "
            }
        }
        
        if naturalScore > 0 {
            explanation += "Natural food bonus applied. "
        }
        
        switch processingLevel {
        case .unprocessed:
            explanation += "Whole, natural food with minimal processing."
        case .minimally:
            explanation += "Lightly processed for convenience or preservation."
        case .processed:
            explanation += "Some processing methods applied."
        case .ultraProcessed:
            explanation += "Highly processed with multiple additives."
        }
        
        return explanation
    }
    
    private func buildFactors(processingLevel: ProcessingLevel,
                            additiveAnalysis: AdditiveAnalysis,
                            naturalScore: Int) -> [String] {
        var factors: [String] = []

        factors.append("Processing: \(processingLevel.rawValue)")

        // NEW: Show ultra-processed ingredients
        if !additiveAnalysis.ultraProcessedIngredients.isEmpty {
            let count = additiveAnalysis.ultraProcessedIngredients.count
            let penalty = additiveAnalysis.ultraProcessedPenalty
            factors.append("🏭 \(count) ultra-processed ingredient(s) (-\(penalty) points)")

            // Show specific high-penalty ingredients
            let highPenalty = additiveAnalysis.ultraProcessedIngredients
                .filter { $0.processing_penalty >= 15 }
                .prefix(3)
            for ing in highPenalty {
                factors.append("   • \(ing.name)")
            }
        }

        // Use comprehensive additive analysis if available
        if !additiveAnalysis.comprehensiveAdditives.isEmpty {
            let count = additiveAnalysis.comprehensiveAdditives.count
            let healthScore = additiveAnalysis.totalHealthScore
            
            if healthScore < 30 {
                factors.append("🔴 \(count) high-risk additive(s) (Score: \(healthScore)/100)")
            } else if healthScore < 50 {
                factors.append("🟡 \(count) moderate-risk additive(s) (Score: \(healthScore)/100)")
            } else {
                factors.append("🟢 \(count) low-risk additive(s) (Score: \(healthScore)/100)")
            }
            
            if additiveAnalysis.hasChildWarnings {
                factors.append("⚠️ Child behavior warnings")
            }
            
            if additiveAnalysis.hasAllergenWarnings {
                factors.append("⚠️ Allergen concerns")
            }
            
            // Show specific high-concern additives
            let highConcernAdditives = additiveAnalysis.comprehensiveAdditives.filter { getHealthScore(for: $0) < 30 }
            for additive in highConcernAdditives.prefix(3) {
                factors.append("🔴 \(additive.name) (\(additive.eNumber))")
            }
        } else {
            // Fallback factors
            if additiveAnalysis.eNumbers.count > 0 {
                factors.append("⚠️ \(additiveAnalysis.eNumbers.count) E-number(s)")
            }
            
            if additiveAnalysis.additives.count > 0 {
                factors.append("⚠️ \(additiveAnalysis.additives.count) additive(s)")
            }
            
            if additiveAnalysis.preservatives.count > 0 {
                factors.append("⚠️ \(additiveAnalysis.preservatives.count) preservative(s)")
            }
        }
        
        if additiveAnalysis.goodAdditives.count > 0 {
            factors.append("✅ \(additiveAnalysis.goodAdditives.count) beneficial additive(s)")
        }
        
        if naturalScore > 0 {
            factors.append("✅ Natural food bonus")
        }
        
        return factors
    }
    
    // MARK: - Scientific Ingredient Analysis (NOVA Classification)
    
    private func analyzeIngredientsProcessingLevel(_ ingredients: String) -> ProcessingLevel {
        let ingredientList = ingredients.lowercased()

        // Count ultra-processed indicators (NOVA Group 4)
        // Only count genuinely concerning industrial additives
        var ultraProcessedScore = 0

        // HIGH concern - truly industrial additives (worth 2 points each)
        let highConcernIndicators = [
            "glucose syrup", "high fructose corn syrup", "invert sugar", "maltodextrin",
            "hydrolysed protein", "soy protein isolate", "modified starch",
            "hydrogenated oil", "trans fat",
            "mono- and diglycerides", "polyglycerol",
            "bht", "bha", "tbhq", "sodium nitrite", "sodium nitrate",
            "aspartame", "sucralose", "acesulfame", "cyclamate"
        ]

        // MEDIUM concern - processed but not terrible (worth 1 point each)
        let mediumConcernIndicators = [
            "palm oil", "palm fat",
            "artificial flavour", "flavour enhancer",
            "sodium benzoate", "potassium sorbate", "calcium propionate",
            "carrageenan"
        ]

        // LOW concern - naturally derived, often fine in quality food (worth 0.5 points)
        // These shouldn't heavily penalize otherwise good food
        let lowConcernIndicators = [
            "xanthan gum", "guar gum", "locust bean gum",  // Plant-derived thickeners
            "lecithin",  // Often from eggs or soy, natural emulsifier
            "emulsifier", "stabiliser", "thickener"  // Generic terms - could be natural
        ]

        // Don't penalize: "natural flavour", "natural flavouring" - these are often just herbs/spices

        // Count high concern (2 points each)
        for indicator in highConcernIndicators {
            if ingredientList.contains(indicator) {
                ultraProcessedScore += 2
            }
        }

        // Count medium concern (1 point each)
        for indicator in mediumConcernIndicators {
            if ingredientList.contains(indicator) {
                ultraProcessedScore += 1
            }
        }

        // Count low concern (0.5 points each, but only if no "natural" qualifier nearby)
        for indicator in lowConcernIndicators {
            if ingredientList.contains(indicator) {
                // Don't penalize if it says "natural" before it
                let naturalVersion = "natural " + indicator
                if !ingredientList.contains(naturalVersion) {
                    ultraProcessedScore += 1  // Using Int, so round up to 1
                }
            }
        }

        // PERFORMANCE: Use precompiled E-number regex pattern
        let eNumberMatches = Self.eNumberPattern.numberOfMatches(
            in: ingredientList,
            range: NSRange(ingredientList.startIndex..., in: ingredientList)
        )

        // Add E-number penalties (but cap it - lots of E numbers in one product shouldn't stack infinitely)
        ultraProcessedScore += min(eNumberMatches, 4)

        // Count whole food ingredients to offset processing score
        let wholeFoodIndicators = [
            "chicken", "beef", "lamb", "pork", "salmon", "cod", "prawns",
            "cream", "butter", "milk", "cheese", "egg",
            "onion", "garlic", "tomato", "carrot", "celery", "mushroom",
            "potato", "spinach", "broccoli", "pepper", "leek",
            "basil", "thyme", "rosemary", "parsley", "oregano", "sage",
            "olive oil", "white wine", "red wine", "stock"
        ]

        var wholeFoodCount = 0
        for indicator in wholeFoodIndicators {
            if ingredientList.contains(indicator) {
                wholeFoodCount += 1
            }
        }

        // Reduce ultra-processed score based on whole food content
        // Quality ready meals with real ingredients shouldn't be penalized as harshly
        if wholeFoodCount >= 6 {
            ultraProcessedScore -= 3  // Lots of real ingredients
        } else if wholeFoodCount >= 4 {
            ultraProcessedScore -= 2  // Good amount of real ingredients
        } else if wholeFoodCount >= 2 {
            ultraProcessedScore -= 1  // Some real ingredients
        }

        // Classify based on adjusted NOVA system
        // Threshold raised from 3 to 5 to account for weighted scoring
        if ultraProcessedScore >= 5 {
            return .ultraProcessed  // Genuinely ultra-processed
        }

        // Check for processed indicators (NOVA Group 3)
        let processedIndicators = [
            "salt", "sugar", "oil", "vinegar", "citric acid", "ascorbic acid",
            "sodium chloride", "calcium chloride", "lactic acid"
        ]

        var processedScore = 0
        for indicator in processedIndicators {
            if ingredientList.contains(indicator) {
                processedScore += 1
            }
        }

        if processedScore >= 2 || ultraProcessedScore >= 2 {
            return .processed  // Some processing with added substances
        }

        // Check for minimal processing indicators (NOVA Group 2)
        let minimalIndicators = [
            "pasteurised", "frozen", "dried", "fermented", "pressed", "ground"
        ]

        for indicator in minimalIndicators {
            if ingredientList.contains(indicator) {
                return .minimally  // Physical/chemical processes only
            }
        }

        // Default to unprocessed if no processing indicators found (NOVA Group 1)
        return .unprocessed
    }
    
    private func isObviouslyUnprocessedSingleFood(_ foodName: String) -> Bool {
        let unprocessedFoods = [
            // Fruits
            "apple", "banana", "orange", "grape", "strawberry", "blueberry", "raspberry", "blackberry",
            "peach", "pear", "plum", "cherry", "watermelon", "cantaloupe", "kiwi", "pineapple",
            "mango", "papaya", "avocado", "lemon", "lime", "grapefruit",
            
            // Vegetables
            "carrot", "broccoli", "spinach", "lettuce", "tomato", "cucumber", "pepper", "onion",
            "garlic", "potato", "sweet potato", "celery", "kale", "cabbage", "cauliflower",
            "zucchini", "mushroom", "corn", "peas", "beans",
            
            // Basic proteins
            "chicken breast", "salmon", "tuna", "cod", "beef", "pork", "lamb", "turkey",
            "egg", "eggs",
            
            // Basic grains/nuts (single ingredient)
            "rice", "oats", "quinoa", "barley", "almond", "walnut", "cashew", "peanut",
            "olive oil", "coconut oil",
            
            // Dairy basics
            "milk", "yogurt", "cheese"
        ]
        
        // Must be an exact match or very close to avoid false positives
        let foodLower = foodName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Direct matches
        if unprocessedFoods.contains(foodLower) {
            return true
        }
        
        // Simple plural/singular checks
        for unprocessedFood in unprocessedFoods {
            if foodLower == unprocessedFood + "s" || foodLower + "s" == unprocessedFood {
                return true
            }
        }
        
        return false
    }
}

enum SugarGrade: String, CaseIterable {
    case excellent = "A+"  // 0-5g per 100g
    case veryGood = "A"    // 5-10g per 100g
    case good = "B"        // 10-20g per 100g
    case moderate = "C"    // 20-30g per 100g
    case high = "D"        // 30-50g per 100g
    case veryHigh = "F"    // 50g+ per 100g
    case unknown = "?"

    var numericValue: Int {
        switch self {
        case .excellent: return 5
        case .veryGood: return 4
        case .good: return 3
        case .moderate: return 2
        case .high: return 1
        case .veryHigh: return 0
        case .unknown: return -1
        }
    }

    var color: Color {
        switch self {
        case .excellent: return .green
        case .veryGood: return .green
        case .good: return .yellow
        case .moderate: return .orange
        case .high: return .red
        case .veryHigh: return .red
        case .unknown: return .gray
        }
    }
}

struct SugarContentScore {
    let grade: SugarGrade
    let sugarPer100g: Double
    let sugarPerServing: Double?
    let servingSizeG: Double?
    let densityGrade: SugarGrade  // Grade based on per-100g
    let servingGrade: SugarGrade? // Grade based on per-serving (if applicable)
    let explanation: String
    let healthImpact: String
    let recommendation: String

    var color: Color {
        return grade.color
    }
}

class NutritionScorer {
    static let shared = NutritionScorer()

    private init() {}

    func calculateNutritionScore(
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double,
        sugar: Double,
        sodium: Double,
        saturatedFat: Double = 0.0,
        foodName: String
    ) -> (grade: NutritionGrade, score: Double, breakdown: String) {

        var score: Double = 50 // Start with neutral score
        var breakdown = ""

        // Protein scoring (positive factor)
        let proteinScore = min(protein * 2, 20) // Up to 20 points for protein
        score += proteinScore
        breakdown += "Protein: +\(String(format: "%.1f", proteinScore)) "

        // Fiber scoring (positive factor)
        let fiberScore = min(fiber * 3, 15) // Up to 15 points for fibre
        score += fiberScore
        breakdown += "Fibre: +\(String(format: "%.1f", fiberScore)) "

        // Sugar penalty (negative factor)
        let sugarPenalty = min(sugar * 1.5, 30) // Up to 30 point penalty
        score -= sugarPenalty
        breakdown += "Sugar: -\(String(format: "%.1f", sugarPenalty)) "

        // Sodium penalty (negative factor)
        let sodiumPenaltyValue = min(sodium / 50, 20) // Up to 20 point penalty for high sodium
        score -= sodiumPenaltyValue
        breakdown += "Sodium: -\(String(format: "%.1f", sodiumPenaltyValue)) "

        // Saturated fat penalty
        let satFatPenalty = min(saturatedFat * 2, 15) // Up to 15 point penalty
        score -= satFatPenalty
        breakdown += "SatFat: -\(String(format: "%.1f", satFatPenalty)) "

        // Calorie density consideration
        if calories > 400 {
            let caloriePenalty = min((calories - 400) / 20, 10)
            score -= caloriePenalty
            breakdown += "Calories: -\(String(format: "%.1f", caloriePenalty)) "
        }

        // Clamp score between 0 and 100
        score = max(0, min(100, score))

        // Determine grade
        let grade: NutritionGrade
        switch score {
        case 85...100:
            grade = .a
        case 70..<85:
            grade = .b
        case 55..<70:
            grade = .c
        case 40..<55:
            grade = .d
        case 25..<40:
            grade = .e
        default:
            grade = .f
        }

        return (grade: grade, score: score, breakdown: breakdown)
    }
}

class SugarContentScorer {
    static let shared = SugarContentScorer()

    private init() {}

    /// Calculate sugar score based on per-serving amount (preferred) or per-100g density (fallback)
    /// Uses realistic thresholds based on WHO 30g/day guideline
    func calculateSugarScore(sugarPer100g: Double?, sugarPerServing: Double? = nil, servingSizeG: Double? = nil) -> SugarContentScore {
        guard let sugar = sugarPer100g, sugar >= 0 else {
            return SugarContentScore(
                grade: .unknown,
                sugarPer100g: 0,
                sugarPerServing: nil,
                servingSizeG: nil,
                densityGrade: .unknown,
                servingGrade: nil,
                explanation: "No sugar content data available",
                healthImpact: "Cannot assess sugar content without data",
                recommendation: "Check nutrition label for sugar content"
            )
        }

        // SIMPLIFIED APPROACH: Score per-serving when available, otherwise use per-100g
        var finalGrade: SugarGrade
        var densityGrade: SugarGrade
        var servingGrade: SugarGrade? = nil
        var explanation = ""
        var healthImpact = ""
        var recommendation = ""

        if let perServing = sugarPerServing, let servingSize = servingSizeG, servingSize > 0 {
            // PRIORITY: Score based on per-serving amount (what user actually consumes)

            // Detect per-unit items (serving size ≤5g means "1 unit" encoding)
            let isPerUnitItem = servingSize <= 5 && perServing > (servingSize * 2)

            if isPerUnitItem {
                // Per-unit item: score the actual sugar content in the unit
                servingGrade = getGradeForServingAmount(perServing)
                finalGrade = servingGrade!
                explanation = "\(String(format: "%.1f", perServing))g sugar per unit"
            } else {
                // Regular food: score per-serving amount
                servingGrade = getGradeForServingAmount(perServing)
                finalGrade = servingGrade!
                explanation = "\(String(format: "%.1f", perServing))g sugar per \(String(format: "%.0f", servingSize))g serving"
            }

            // Calculate density grade for reference only
            densityGrade = getGradeForDensity(sugar)

            healthImpact = getHealthImpact(for: finalGrade)
            recommendation = getRecommendation(for: finalGrade)
        } else {
            // FALLBACK: Only have per-100g data, score based on density
            densityGrade = getGradeForDensity(sugar)
            finalGrade = densityGrade
            explanation = "\(String(format: "%.1f", sugar))g per 100g"
            healthImpact = getHealthImpact(for: densityGrade)
            recommendation = getRecommendation(for: densityGrade)
        }

        return SugarContentScore(
            grade: finalGrade,
            sugarPer100g: sugar,
            sugarPerServing: sugarPerServing,
            servingSizeG: servingSizeG,
            densityGrade: densityGrade,
            servingGrade: servingGrade,
            explanation: explanation,
            healthImpact: healthImpact,
            recommendation: recommendation
        )
    }

    /// Grade sugar based on per-serving amount (realistic daily intake thresholds)
    /// Based on WHO guideline: max 30g free sugars per day for adults
    private func getGradeForServingAmount(_ sugar: Double) -> SugarGrade {
        switch sugar {
        case 0..<3:      // <10% daily limit
            return .excellent
        case 3..<6:      // 10-20% daily limit
            return .veryGood
        case 6..<10:     // 20-33% daily limit (moderate)
            return .good
        case 10..<15:    // 33-50% daily limit (moderately high)
            return .moderate
        case 15..<24:    // 50-80% daily limit (high)
            return .high
        default:         // 80%+ daily limit (very high)
            return .veryHigh
        }
    }

    /// Grade sugar based on density (per 100g) - fallback when no serving data
    private func getGradeForDensity(_ sugar: Double) -> SugarGrade {
        switch sugar {
        case 0..<5:
            return .excellent
        case 5..<10:
            return .veryGood
        case 10..<20:
            return .good
        case 20..<30:
            return .moderate
        case 30..<50:
            return .high
        default: // 50+
            return .veryHigh
        }
    }

    private func getHealthImpact(for grade: SugarGrade) -> String {
        switch grade {
        case .excellent:
            return "Very low sugar content"
        case .veryGood:
            return "Low sugar content"
        case .good:
            return "Moderate sugar content"
        case .moderate:
            return "Moderately high sugar content"
        case .high:
            return "High sugar content"
        case .veryHigh:
            return "Very high sugar content"
        case .unknown:
            return "Sugar content data not available"
        }
    }

    private func getRecommendation(for grade: SugarGrade) -> String {
        switch grade {
        case .excellent:
            return "Contains minimal sugar"
        case .veryGood:
            return "Contains low amounts of sugar"
        case .good:
            return "Contains moderate amounts of sugar"
        case .moderate:
            return "Sugar is a significant component"
        case .high:
            return "High proportion of sugar"
        case .veryHigh:
            return "Very high proportion of sugar"
        case .unknown:
            return "Check nutrition label for sugar content"
        }
    }
}
