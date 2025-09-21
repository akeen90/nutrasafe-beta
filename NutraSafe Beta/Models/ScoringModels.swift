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
    
    private init() {}
    
    func calculateProcessingScore(for foodName: String, ingredients: String? = nil, sugarPer100g: Double? = nil) -> NutritionProcessingScore {
        let foodLower = foodName.lowercased()
        
        // CRITICAL: If no real ingredients provided, return "Not enough data" for anything that's not obviously unprocessed
        guard let ingredients = ingredients, !ingredients.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // Only allow high scores for very obviously unprocessed single foods
            if isObviouslyUnprocessedSingleFood(foodLower) {
                return NutritionProcessingScore(
                    grade: ProcessingGrade.a,
                    score: 85,
                    explanation: "Single unprocessed food",
                    factors: ["Fresh whole food"],
                    processingLevel: ProcessingLevel.unprocessed,
                    additiveCount: 0,
                    eNumberCount: 0,
                    naturalScore: 85
                )
            }
            
            // Everything else gets "Not enough data" 
            return NutritionProcessingScore(
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
            let colorAdditives = additiveAnalysis.additives.filter { additive in
                additive.contains("blue") || additive.contains("yellow") || additive.contains("red") ||
                additive.contains("tartrazine") || additive.contains("brilliant") || additive.contains("sunset")
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
        
        return NutritionProcessingScore(
            grade: grade,
            score: totalScore,
            explanation: explanation,
            factors: factors,
            processingLevel: processingLevel,
            additiveCount: additiveAnalysis.additives.count,
            eNumberCount: additiveAnalysis.eNumbers.count,
            naturalScore: naturalScore
        )
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
    }
    
    private var comprehensiveAdditives: [String: AdditiveInfo]? = {
        guard let path = Bundle.main.path(forResource: "comprehensiveAdditives", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let additives = try? JSONDecoder().decode([String: AdditiveInfo].self, from: data) else {
            print("Warning: Could not load comprehensive additives database")
            return nil
        }
        return additives
    }()
    
    private func analyseAdditives(in food: String) -> AdditiveAnalysis {
        let foodLower = food.lowercased()
        var detectedAdditives: [AdditiveInfo] = []
        var eNumbers: [String] = []
        var additives: [String] = []
        var preservatives: [String] = []
        var goodAdditives: [String] = []
        
        // Use comprehensive database if available
        if let comprehensiveDB = comprehensiveAdditives {
            // Check for E-numbers and additive names
            for (code, additiveInfo) in comprehensiveDB {
                // Check E-number code
                if foodLower.contains(code.lowercased()) {
                    detectedAdditives.append(additiveInfo)
                    eNumbers.append(code)
                    continue
                }
                
                // Check additive name and synonyms
                for searchTerm in additiveInfo.synonyms {
                    if foodLower.contains(searchTerm.lowercased()) {
                        detectedAdditives.append(additiveInfo)
                        if additiveInfo.category.rawValue.lowercased().contains("preservative") {
                            preservatives.append(additiveInfo.name)
                        } else {
                            additives.append(additiveInfo.name)
                        }
                        break
                    }
                }
            }
        }
        
        // Fallback to basic analysis if comprehensive database not available
        if detectedAdditives.isEmpty {
            // Common E-numbers (fallback)
            let commonENumbers = [
                "e100", "e102", "e104", "e110", "e122", "e124", "e129",
                "e200", "e202", "e211", "e220", "e223", "e224", "e228",
                "e621", "e627", "e631", "e635", "e951", "e952", "e954", "e955"
            ]
            
            // Common bad additives (fallback) - Enhanced for color detection
            let badAdditives = [
                "monosodium glutamate", "msg", "high fructose corn syrup", "glucose syrup",
                "sodium nitrite", "sodium nitrate", "potassium sorbate", "sodium benzoate",
                "artificial colours", "artificial flavours", "artificial colors", "artificial flavors",
                "trans fat", "hydrogenated oil", "palm fat", "palm oil", 
                "emulsifier", "lecithin", "stabiliser", "thickener",
                "aspartame", "sucralose", "syrup", "modified starch",
                // Color additives that should be heavily penalized
                "brilliant blue fcf", "brilliant blue", "blue fcf", "fd&c blue",
                "tartrazine", "yellow 5", "fd&c yellow 5", "sunset yellow fcf", "sunset yellow",
                "yellow 6", "fd&c yellow 6", "allura red", "red 40", "fd&c red 40",
                "red 3", "erythrosine", "carmine", "cochineal", "carmoisine", "azorubine",
                "quinoline yellow", "green s", "patent blue", "indigo carmine",
                "corn syrup", "invert sugar", "dextrose"
            ]
            
            // Common preservatives (fallback)
            let preservativeTerms = [
                "preservative", "sodium", "potassium", "calcium", "benzoate",
                "sorbate", "nitrate", "nitrite", "sulfite", "bisulfite"
            ]
            
            eNumbers = commonENumbers.filter { foodLower.contains($0) }
            additives = badAdditives.filter { foodLower.contains($0) }
            preservatives = preservativeTerms.filter { foodLower.contains($0) }
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
        
        return AdditiveAnalysis(
            eNumbers: eNumbers,
            additives: additives,
            preservatives: preservatives,
            goodAdditives: goodAdditives,
            comprehensiveAdditives: detectedAdditives,
            totalHealthScore: totalHealthScore,
            worstVerdict: worstVerdict,
            hasChildWarnings: hasChildWarnings,
            hasAllergenWarnings: hasAllergenWarnings
        )
    }
    
    private func getHealthScore(for additive: AdditiveInfo) -> Int {
        // Convert AdditiveVerdict to health score
        switch additive.effectsVerdict {
        case .neutral: return 70
        case .caution: return 40
        case .avoid: return 10
        }
    }

    private func calculateNaturalScore(_ food: String) -> Int {
        let naturalBonusTerms = [
            "organic": 10,
            "fresh": 8,
            "raw": 12,
            "natural": 6,
            "whole": 8,
            "unprocessed": 15,
            "homemade": 10,
            "farm fresh": 12,
            "wild caught": 8,
            "grass fed": 8,
            "free range": 6
        ]
        
        var bonus = 0
        for (term, value) in naturalBonusTerms {
            if food.contains(term) {
                bonus += value
            }
        }
        
        return min(bonus, 25) // Cap natural bonus at 25 points
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
        
        // Use comprehensive additive analysis if available
        if !additiveAnalysis.comprehensiveAdditives.isEmpty {
            let count = additiveAnalysis.comprehensiveAdditives.count
            explanation += "\(count) additive(s) analyzed with health scoring. "
            
            if additiveAnalysis.totalHealthScore < 30 {
                explanation += "Contains additives with significant health concerns. "
            } else if additiveAnalysis.totalHealthScore < 50 {
                explanation += "Contains additives with moderate health concerns. "
            }
            
            if additiveAnalysis.hasChildWarnings {
                explanation += "⚠️ Contains additives that may affect children's behavior. "
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
            explanation += "Excellent choice - whole, natural food."
        case .minimally:
            explanation += "Good choice - lightly processed for convenience."
        case .processed:
            explanation += "Moderate choice - some processing involved."
        case .ultraProcessed:
            explanation += "Consider limiting - highly processed with many additives."
        }
        
        return explanation
    }
    
    private func buildFactors(processingLevel: ProcessingLevel, 
                            additiveAnalysis: AdditiveAnalysis, 
                            naturalScore: Int) -> [String] {
        var factors: [String] = []
        
        factors.append("Processing: \(processingLevel.rawValue)")
        
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
        var ultraProcessedScore = 0
        
        // Industrial sweeteners and additives
        let ultraProcessedIndicators = [
            "glucose syrup", "high fructose corn syrup", "invert sugar", "maltodextrin",
            "hydrolysed protein", "soy protein isolate", "modified starch",
            "hydrogenated oil", "palm oil", "palm fat", "trans fat",
            "emulsifier", "stabiliser", "thickener", "gelling agent",
            "flavouring", "artificial flavour", "natural flavour", "flavour enhancer",
            "lecithin", "mono- and diglycerides", "polyglycerol",
            "sodium benzoate", "potassium sorbate", "calcium propionate",
            "bht", "bha", "tbhq", "sodium nitrite", "sodium nitrate",
            "carrageenan", "xanthan gum", "guar gum", "locust bean gum",
            "aspartame", "sucralose", "acesulfame", "cyclamate"
        ]
        
        // E-numbers (typically ultra-processed)
        let eNumberPattern = "e\\d{3,4}"
        let regex = try? NSRegularExpression(pattern: eNumberPattern)
        let eNumberMatches = regex?.numberOfMatches(in: ingredientList, range: NSRange(ingredientList.startIndex..., in: ingredientList)) ?? 0
        
        // Count ultra-processed indicators
        for indicator in ultraProcessedIndicators {
            if ingredientList.contains(indicator) {
                ultraProcessedScore += 1
            }
        }
        
        // Add E-number penalties
        ultraProcessedScore += eNumberMatches
        
        // Classify based on NOVA system
        if ultraProcessedScore >= 3 {
            return .ultraProcessed  // 3+ ultra-processed indicators = NOVA Group 4
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
        
        if processedScore >= 2 {
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
        let fiberScore = min(fiber * 3, 15) // Up to 15 points for fiber
        score += fiberScore
        breakdown += "Fiber: +\(String(format: "%.1f", fiberScore)) "

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
    
    func calculateSugarScore(sugarPer100g: Double?) -> SugarContentScore {
        guard let sugar = sugarPer100g, sugar >= 0 else {
            return SugarContentScore(
                grade: SugarGrade.unknown,
                sugarPer100g: 0,
                explanation: "No sugar content data available",
                healthImpact: "Cannot assess sugar content without data",
                recommendation: "Check nutrition label for sugar content"
            )
        }
        
        let grade: SugarGrade
        let explanation: String
        let healthImpact: String
        let recommendation: String
        
        switch sugar {
        case 0..<5:
            grade = .excellent
            explanation = "Very low sugar content"
            healthImpact = "Excellent choice for blood sugar management"
            recommendation = "Perfect for regular consumption"
            
        case 5..<10:
            grade = .veryGood
            explanation = "Low sugar content"
            healthImpact = "Good choice with minimal blood sugar impact"
            recommendation = "Great for daily consumption"
            
        case 10..<20:
            grade = .good
            explanation = "Moderate sugar content"
            healthImpact = "Some blood sugar impact, suitable in moderation"
            recommendation = "Enjoy as part of balanced meals"
            
        case 20..<30:
            grade = .moderate
            explanation = "Moderately high sugar"
            healthImpact = "Noticeable blood sugar impact"
            recommendation = "Consume in smaller portions"
            
        case 30..<50:
            grade = .high
            explanation = "High sugar content"
            healthImpact = "Significant blood sugar spike likely"
            recommendation = "Limit intake, pair with protein/fiber"
            
        default: // 50+
            grade = .veryHigh
            explanation = "Very high sugar content"
            healthImpact = "Major blood sugar spike expected"
            recommendation = "Consume rarely and in very small amounts"
        }
        
        return SugarContentScore(
            grade: grade,
            sugarPer100g: sugar,
            explanation: explanation,
            healthImpact: healthImpact,
            recommendation: recommendation
        )
    }
}

