import Foundation
import Firebase
import SwiftUI

// MARK: - Allergen Detection System
enum Allergen: String, CaseIterable, Identifiable {
    case dairy = "dairy"
    case eggs = "eggs"  
    case fish = "fish"
    case shellfish = "shellfish"
    case treeNuts = "treeNuts"
    case peanuts = "peanuts"
    case wheat = "wheat"
    case soy = "soy"
    case sesame = "sesame"
    case gluten = "gluten"
    case lactose = "lactose"
    case sulfites = "sulfites"
    case msg = "msg"
    case corn = "corn"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .dairy: return "Dairy"
        case .eggs: return "Eggs"
        case .fish: return "Fish"
        case .shellfish: return "Shellfish"
        case .treeNuts: return "Tree Nuts"
        case .peanuts: return "Peanuts"
        case .wheat: return "Wheat"
        case .soy: return "Soy"
        case .sesame: return "Sesame"
        case .gluten: return "Gluten"
        case .lactose: return "Lactose"
        case .sulfites: return "Sulfites"
        case .msg: return "MSG"
        case .corn: return "Corn"
        }
    }
    
    var icon: String {
        switch self {
        case .dairy: return "🥛"
        case .eggs: return "🥚"
        case .fish: return "🐟"
        case .shellfish: return "🦐"
        case .treeNuts: return "🌰"
        case .peanuts: return "🥜"
        case .wheat: return "🌾"
        case .soy: return "🫘"
        case .sesame: return "🫰"
        case .gluten: return "🍞"
        case .lactose: return "🥛"
        case .sulfites: return "🍷"
        case .msg: return "🧂"
        case .corn: return "🌽"
        }
    }
    
    // Common ingredient keywords that contain this allergen
    var keywords: [String] {
        switch self {
        case .dairy:
            return ["milk", "cream", "butter", "cheese", "yogurt", "whey", "casein", "lactose", "ghee", "custard", "ice cream"]
        case .eggs:
            return ["egg", "albumin", "mayonnaise", "meringue", "ovalbumin", "lecithin"]
        case .fish:
            return ["salmon", "tuna", "cod", "bass", "trout", "anchovy", "sardine", "mackerel", "fish sauce", "worcestershire"]
        case .shellfish:
            return ["shrimp", "crab", "lobster", "clam", "mussel", "oyster", "scallop", "crawfish", "crayfish"]
        case .treeNuts:
            return ["almond", "walnut", "cashew", "pistachio", "pecan", "hazelnut", "brazil nut", "macadamia", "pine nut"]
        case .peanuts:
            return ["peanut", "groundnut", "arachis oil", "peanut butter", "peanut oil"]
        case .wheat:
            return ["wheat", "flour", "bread", "pasta", "bulgur", "couscous", "farina", "graham", "semolina", "spelt"]
        case .soy:
            return ["soy", "soya", "tofu", "tempeh", "miso", "shoyu", "tamari", "edamame", "soy sauce"]
        case .sesame:
            return ["sesame", "tahini", "sesame oil", "sesame seed", "sesamum"]
        case .gluten:
            return ["gluten", "wheat", "barley", "rye", "malt", "brewer's yeast", "oats"]
        case .lactose:
            return ["lactose", "milk", "dairy", "whey", "cream", "butter", "cheese"]
        case .sulfites:
            return ["sulfite", "sulfur dioxide", "wine", "dried fruit", "preservative"]
        case .msg:
            return ["monosodium glutamate", "msg", "glutamate", "hydrolyzed protein", "yeast extract"]
        case .corn:
            return ["corn", "maize", "corn syrup", "corn starch", "dextrose", "glucose", "fructose"]
        }
    }
    
    var severity: AllergenSeverity {
        switch self {
        case .dairy, .eggs, .fish, .shellfish, .treeNuts, .peanuts:
            return .high
        case .wheat, .soy, .gluten:
            return .medium
        case .sesame, .lactose, .sulfites, .msg, .corn:
            return .low
        }
    }
}

enum AllergenSeverity: String {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var color: String {
        switch self {
        case .low: return "yellow"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
}

struct AllergenDetectionResult {
    let detectedAllergens: [Allergen]
    let confidence: Double // 0.0 to 1.0
    let riskLevel: AllergenSeverity
    let warnings: [String]
    let safeForUser: Bool
}

class AllergenDetector {
    static let shared = AllergenDetector()
    
    private init() {}
    
    func detectAllergens(in foodName: String, ingredients: [String] = [], userAllergens: [Allergen]) -> AllergenDetectionResult {
        let searchText = (foodName + " " + ingredients.joined(separator: " ")).lowercased()
        var detectedAllergens: [Allergen] = []
        var confidence = 0.0
        var warnings: [String] = []
        
        // Check each user allergen against the food
        for allergen in userAllergens {
            let matchingKeywords = allergen.keywords.filter { keyword in
                searchText.contains(keyword.lowercased())
            }
            
            if !matchingKeywords.isEmpty {
                detectedAllergens.append(allergen)
                warnings.append("Contains \(allergen.displayName): \(matchingKeywords.joined(separator: ", "))")
                
                // Increase confidence based on number of matches
                confidence += Double(matchingKeywords.count) * 0.2
            }
        }
        
        // Cap confidence at 1.0
        confidence = min(confidence, 1.0)
        
        // Determine risk level
        let riskLevel: AllergenSeverity
        if detectedAllergens.contains(where: { $0.severity == .high }) {
            riskLevel = .high
        } else if detectedAllergens.contains(where: { $0.severity == .medium }) {
            riskLevel = .medium
        } else if !detectedAllergens.isEmpty {
            riskLevel = .low
        } else {
            riskLevel = .low
            confidence = max(confidence, 0.8) // High confidence if no allergens detected
        }
        
        return AllergenDetectionResult(
            detectedAllergens: detectedAllergens,
            confidence: confidence,
            riskLevel: riskLevel,
            warnings: warnings,
            safeForUser: detectedAllergens.isEmpty
        )
    }
    
    func generateSafetyScore(for food: String, userAllergens: [Allergen]) -> Double {
        let result = detectAllergens(in: food, userAllergens: userAllergens)
        
        if result.safeForUser {
            return 1.0 // 100% safe
        }
        
        // Calculate safety score based on detected allergens and their severity
        let severityPenalty = result.detectedAllergens.reduce(0.0) { penalty, allergen in
            switch allergen.severity {
            case .high: return penalty + 0.4
            case .medium: return penalty + 0.25
            case .low: return penalty + 0.1
            }
        }
        
        return max(0.0, 1.0 - severityPenalty)
    }
}

// MARK: - Nutrition Score System

struct NutritionScoreResult {
    let overallScore: Double // 0-100
    let grade: NutritionGrade
    let positiveFactors: [String]
    let negativeFactors: [String]
    let recommendations: [String]
}

enum NutritionGrade: String, CaseIterable {
    case excellent = "A+"
    case veryGood = "A"
    case good = "B"
    case average = "C"
    case poor = "D"
    case veryPoor = "F"
    
    var color: String {
        switch self {
        case .excellent, .veryGood:
            return "green"
        case .good:
            return "lightGreen"
        case .average:
            return "orange"
        case .poor, .veryPoor:
            return "red"
        }
    }
    
    var description: String {
        switch self {
        case .excellent:
            return "Excellent nutritional choice"
        case .veryGood:
            return "Very good nutritional value"
        case .good:
            return "Good nutritional choice"
        case .average:
            return "Average nutritional value"
        case .poor:
            return "Poor nutritional choice"
        case .veryPoor:
            return "Very poor nutritional value"
        }
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
        foodName: String = ""
    ) -> NutritionScoreResult {
        
        var score: Double = 50.0 // Start with neutral score
        var positiveFactors: [String] = []
        var negativeFactors: [String] = []
        var recommendations: [String] = []
        
        // POSITIVE FACTORS (add to score)
        
        // High protein content
        let proteinPerCalorie = protein * 4 / calories // protein calories per total calories
        if proteinPerCalorie > 0.25 {
            score += 15
            positiveFactors.append("High protein content (\(String(format: "%.1f", protein))g)")
        } else if proteinPerCalorie > 0.15 {
            score += 8
            positiveFactors.append("Good protein content (\(String(format: "%.1f", protein))g)")
        }
        
        // High fibre content
        let fiberPerCalorie = fiber / (calories / 100) // fibre per 100 calories
        if fiberPerCalorie > 3.0 {
            score += 12
            positiveFactors.append("Excellent fibre content (\(String(format: "%.1f", fiber))g)")
        } else if fiberPerCalorie > 2.0 {
            score += 6
            positiveFactors.append("Good fibre content (\(String(format: "%.1f", fiber))g)")
        }
        
        // Low calorie density
        if calories < 100 {
            score += 10
            positiveFactors.append("Low energy density")
        }
        
        // Natural whole foods bonus
        if isWholeFood(foodName) {
            score += 8
            positiveFactors.append("Whole food")
        }
        
        // NEGATIVE FACTORS (subtract from score)
        
        // High sugar content
        let sugarPerCalorie = sugar * 4 / calories
        if sugarPerCalorie > 0.3 {
            score -= 15
            negativeFactors.append("Very high sugar content (\(String(format: "%.1f", sugar))g)")
            recommendations.append("Limit foods high in added sugars")
        } else if sugarPerCalorie > 0.15 {
            score -= 8
            negativeFactors.append("High sugar content (\(String(format: "%.1f", sugar))g)")
        }
        
        // High sodium content
        let sodiumPer100Cal = sodium / (calories / 100)
        if sodiumPer100Cal > 200 {
            score -= 12
            negativeFactors.append("Very high sodium (\(Int(sodium))mg)")
            recommendations.append("Choose lower sodium alternatives")
        } else if sodiumPer100Cal > 100 {
            score -= 6
            negativeFactors.append("High sodium (\(Int(sodium))mg)")
        }
        
        // High saturated fat
        let satFatPerCalorie = saturatedFat * 9 / calories
        if satFatPerCalorie > 0.2 {
            score -= 10
            negativeFactors.append("High saturated fat (\(String(format: "%.1f", saturatedFat))g)")
            recommendations.append("Limit saturated fats for heart health")
        }
        
        // Very high calorie density
        if calories > 400 {
            score -= 8
            negativeFactors.append("Very high energy density")
            recommendations.append("Watch portion sizes for energy-dense foods")
        }
        
        // Processed food penalty
        if isProcessedFood(foodName) {
            score -= 5
            negativeFactors.append("Processed food")
            recommendations.append("Choose whole foods when possible")
        }
        
        // BONUS POINTS for superfoods
        if isSuperfood(foodName) {
            score += 15
            positiveFactors.append("Superfood - rich in antioxidants and nutrients")
        }
        
        // Ensure score is within bounds
        score = max(0, min(100, score))
        
        let grade = gradeFromScore(score)
        
        // Add general recommendations based on grade
        if grade == .poor || grade == .veryPoor {
            recommendations.append("Consider healthier alternatives")
        }
        
        return NutritionScoreResult(
            overallScore: score,
            grade: grade,
            positiveFactors: positiveFactors,
            negativeFactors: negativeFactors,
            recommendations: recommendations
        )
    }
    
    private func gradeFromScore(_ score: Double) -> NutritionGrade {
        switch score {
        case 85...100:
            return .excellent
        case 75..<85:
            return .veryGood
        case 65..<75:
            return .good
        case 50..<65:
            return .average
        case 25..<50:
            return .poor
        default:
            return .veryPoor
        }
    }
    
    private func isWholeFood(_ foodName: String) -> Bool {
        let wholeFoods = [
            "banana", "apple", "orange", "berries", "spinach", "kale", "broccoli",
            "chicken breast", "salmon", "tuna", "cod", "eggs", "quinoa", "oats",
            "brown rice", "sweet potato", "avocado", "nuts", "seeds", "lentils",
            "beans", "greek yogurt", "cottage cheese"
        ]
        let lowerName = foodName.lowercased()
        return wholeFoods.contains { lowerName.contains($0) }
    }
    
    private func isProcessedFood(_ foodName: String) -> Bool {
        let processedIndicators = [
            "pizza", "burger", "chips", "crisps", "biscuits", "cookies", "cake",
            "pastry", "soda", "soft drink", "energy drink", "candy", "sweets",
            "ice cream", "frozen meal", "instant", "microwave"
        ]
        let lowerName = foodName.lowercased()
        return processedIndicators.contains { lowerName.contains($0) }
    }
    
    private func isSuperfood(_ foodName: String) -> Bool {
        let superfoods = [
            "blueberries", "salmon", "kale", "spinach", "quinoa", "chia seeds",
            "avocado", "sweet potato", "greek yogurt", "broccoli", "almonds",
            "walnuts", "green tea", "dark chocolate"
        ]
        let lowerName = foodName.lowercased()
        return superfoods.contains { lowerName.contains($0) }
    }
}

// MARK: - Food Reaction Pattern Analysis (Non-Medical)

struct FoodReaction {
    let id: UUID
    let foodName: String
    let foodIngredients: [String]
    let reactionTime: Date
    let symptoms: [String]
    let severity: ReactionSeverity
    let notes: String?
    let dateLogged: Date
    
    init(foodName: String, foodIngredients: [String], reactionTime: Date, 
         symptoms: [String], severity: ReactionSeverity, notes: String? = nil) {
        self.id = UUID()
        self.foodName = foodName
        self.foodIngredients = foodIngredients
        self.reactionTime = reactionTime
        self.symptoms = symptoms
        self.severity = severity
        self.notes = notes
        self.dateLogged = Date()
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "foodName": foodName,
            "foodIngredients": foodIngredients,
            "reactionTime": Timestamp(date: reactionTime),
            "symptoms": symptoms,
            "severity": severity.rawValue,
            "notes": notes ?? "",
            "dateLogged": Timestamp(date: dateLogged)
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> FoodReaction? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let foodName = data["foodName"] as? String,
              let foodIngredients = data["foodIngredients"] as? [String],
              let reactionTimeTimestamp = data["reactionTime"] as? Timestamp,
              let symptoms = data["symptoms"] as? [String],
              let severityRaw = data["severity"] as? String,
              let severity = ReactionSeverity(rawValue: severityRaw),
              let dateLoggedTimestamp = data["dateLogged"] as? Timestamp else {
            return nil
        }
        
        let notes = data["notes"] as? String
        
        return FoodReaction(
            id: id,
            foodName: foodName,
            foodIngredients: foodIngredients,
            reactionTime: reactionTimeTimestamp.dateValue(),
            symptoms: symptoms,
            severity: severity,
            notes: notes,
            dateLogged: dateLoggedTimestamp.dateValue()
        )
    }
}

extension FoodReaction {
    init(id: UUID, foodName: String, foodIngredients: [String], reactionTime: Date,
         symptoms: [String], severity: ReactionSeverity, notes: String?, dateLogged: Date) {
        self.id = id
        self.foodName = foodName
        self.foodIngredients = foodIngredients
        self.reactionTime = reactionTime
        self.symptoms = symptoms
        self.severity = severity
        self.notes = notes
        self.dateLogged = dateLogged
    }
}

enum ReactionSeverity: String, CaseIterable {
    case mild = "mild"
    case moderate = "moderate"
    case severe = "severe"
    
    var description: String {
        switch self {
        case .mild:
            return "Mild discomfort"
        case .moderate:
            return "Noticeable reaction"
        case .severe:
            return "Significant reaction"
        }
    }
    
    var color: String {
        switch self {
        case .mild:
            return "yellow"
        case .moderate:
            return "orange"
        case .severe:
            return "red"
        }
    }
}

struct PatternAnalysisResult {
    let suspiciousFoods: [SuspiciousFood]
    let commonIngredients: [IngredientPattern]
    let timePatterns: [TimePattern]
    let recommendations: [String]
    let confidence: Double // 0-1
}

struct SuspiciousFood {
    let foodName: String
    let reactionCount: Int
    let averageSeverity: ReactionSeverity
    let lastReaction: Date
    let confidence: Double
}

struct IngredientPattern {
    let ingredient: String
    let occurrenceCount: Int
    let averageSeverity: ReactionSeverity
    let confidence: Double
}

struct TimePattern {
    let pattern: String
    let description: String
    let occurrenceCount: Int
}

class FoodReactionAnalyser {
    static let shared = FoodReactionAnalyser()
    
    private init() {}
    
    func analyseReactionPatterns(reactions: [FoodReaction]) -> PatternAnalysisResult {
        guard !reactions.isEmpty else {
            return PatternAnalysisResult(
                suspiciousFoods: [],
                commonIngredients: [],
                timePatterns: [],
                recommendations: ["Start logging food reactions to identify patterns"],
                confidence: 0.0
            )
        }
        
        let suspiciousFoods = identifySuspiciousFoods(reactions: reactions)
        let commonIngredients = identifyCommonIngredients(reactions: reactions)
        let timePatterns = identifyTimePatterns(reactions: reactions)
        let recommendations = generateRecommendations(
            suspiciousFoods: suspiciousFoods,
            commonIngredients: commonIngredients,
            timePatterns: timePatterns,
            totalReactions: reactions.count
        )
        
        let confidence = calculateOverallConfidence(
            reactions: reactions,
            suspiciousFoods: suspiciousFoods,
            ingredients: commonIngredients
        )
        
        return PatternAnalysisResult(
            suspiciousFoods: suspiciousFoods,
            commonIngredients: commonIngredients,
            timePatterns: timePatterns,
            recommendations: recommendations,
            confidence: confidence
        )
    }
    
    private func identifySuspiciousFoods(reactions: [FoodReaction]) -> [SuspiciousFood] {
        // Group reactions by food name
        let foodGroups = Dictionary(grouping: reactions, by: { $0.foodName.lowercased() })
        
        var suspiciousFoods: [SuspiciousFood] = []
        
        for (foodName, foodReactions) in foodGroups {
            // Only consider foods that have caused multiple reactions
            if foodReactions.count >= 2 {
                let averageSeverity = calculateAverageSeverity(reactions: foodReactions)
                let lastReaction = foodReactions.map { $0.reactionTime }.max() ?? Date()
                
                // Calculate confidence based on reaction frequency and consistency
                let confidence = calculateFoodConfidence(
                    reactionCount: foodReactions.count,
                    totalReactions: reactions.count,
                    severities: foodReactions.map { $0.severity }
                )
                
                suspiciousFoods.append(SuspiciousFood(
                    foodName: foodName.capitalized,
                    reactionCount: foodReactions.count,
                    averageSeverity: averageSeverity,
                    lastReaction: lastReaction,
                    confidence: confidence
                ))
            }
        }
        
        // Sort by confidence and reaction count
        return suspiciousFoods.sorted { first, second in
            if first.confidence != second.confidence {
                return first.confidence > second.confidence
            }
            return first.reactionCount > second.reactionCount
        }
    }
    
    private func identifyCommonIngredients(reactions: [FoodReaction]) -> [IngredientPattern] {
        // Flatten all ingredients from all reactions
        var ingredientCounts: [String: [FoodReaction]] = [:]
        
        for reaction in reactions {
            for ingredient in reaction.foodIngredients {
                let lowercaseIngredient = ingredient.lowercased()
                if ingredientCounts[lowercaseIngredient] == nil {
                    ingredientCounts[lowercaseIngredient] = []
                }
                ingredientCounts[lowercaseIngredient]?.append(reaction)
            }
        }
        
        var ingredientPatterns: [IngredientPattern] = []
        
        for (ingredient, ingredientReactions) in ingredientCounts {
            // Only consider ingredients that appear in multiple reactions
            if ingredientReactions.count >= 2 {
                let averageSeverity = calculateAverageSeverity(reactions: ingredientReactions)
                let confidence = calculateIngredientConfidence(
                    occurrenceCount: ingredientReactions.count,
                    totalReactions: reactions.count
                )
                
                ingredientPatterns.append(IngredientPattern(
                    ingredient: ingredient.capitalized,
                    occurrenceCount: ingredientReactions.count,
                    averageSeverity: averageSeverity,
                    confidence: confidence
                ))
            }
        }
        
        return ingredientPatterns.sorted { $0.confidence > $1.confidence }
    }
    
    private func identifyTimePatterns(reactions: [FoodReaction]) -> [TimePattern] {
        var patterns: [TimePattern] = []
        
        // Analyse day of week patterns
        let dayGroups = Dictionary(grouping: reactions) { reaction in
            Calendar.current.component(.weekday, from: reaction.reactionTime)
        }
        
        for (dayOfWeek, dayReactions) in dayGroups {
            if dayReactions.count >= 3 { // Significant pattern
                let dayName = DateFormatter().weekdaySymbols[dayOfWeek - 1]
                patterns.append(TimePattern(
                    pattern: "Day of Week",
                    description: "More reactions on \(dayName)s (\(dayReactions.count) reactions)",
                    occurrenceCount: dayReactions.count
                ))
            }
        }
        
        // Analyse time of day patterns
        let hourGroups = Dictionary(grouping: reactions) { reaction in
            Calendar.current.component(.hour, from: reaction.reactionTime)
        }
        
        let morningReactions = hourGroups.filter { $0.key >= 6 && $0.key < 12 }.values.flatMap { $0 }
        let afternoonReactions = hourGroups.filter { $0.key >= 12 && $0.key < 18 }.values.flatMap { $0 }
        let eveningReactions = hourGroups.filter { $0.key >= 18 && $0.key < 22 }.values.flatMap { $0 }
        
        if morningReactions.count >= 3 {
            patterns.append(TimePattern(
                pattern: "Time of Day",
                description: "More reactions in the morning (\(morningReactions.count) reactions)",
                occurrenceCount: morningReactions.count
            ))
        }
        
        if afternoonReactions.count >= 3 {
            patterns.append(TimePattern(
                pattern: "Time of Day",
                description: "More reactions in the afternoon (\(afternoonReactions.count) reactions)",
                occurrenceCount: afternoonReactions.count
            ))
        }
        
        if eveningReactions.count >= 3 {
            patterns.append(TimePattern(
                pattern: "Time of Day",
                description: "More reactions in the evening (\(eveningReactions.count) reactions)",
                occurrenceCount: eveningReactions.count
            ))
        }
        
        return patterns.sorted { $0.occurrenceCount > $1.occurrenceCount }
    }
    
    private func generateRecommendations(
        suspiciousFoods: [SuspiciousFood],
        commonIngredients: [IngredientPattern],
        timePatterns: [TimePattern],
        totalReactions: Int
    ) -> [String] {
        var recommendations: [String] = []
        
        // Add disclaimer
        recommendations.append("⚠️ This analysis is for pattern identification only and is not medical advice")
        
        // Food-based recommendations
        for food in suspiciousFoods.prefix(3) {
            if food.confidence > 0.7 {
                recommendations.append("Consider avoiding '\(food.foodName)' - linked to \(food.reactionCount) reactions")
            } else if food.confidence > 0.5 {
                recommendations.append("Monitor reactions after eating '\(food.foodName)' - potential trigger")
            }
        }
        
        // Ingredient-based recommendations
        for ingredient in commonIngredients.prefix(2) {
            if ingredient.confidence > 0.6 {
                recommendations.append("Check labels for '\(ingredient.ingredient)' - appears in \(ingredient.occurrenceCount) reactions")
            }
        }
        
        // Time-based recommendations
        if let timePattern = timePatterns.first {
            recommendations.append("Pattern noticed: \(timePattern.description)")
        }
        
        // General recommendations
        if totalReactions < 5 {
            recommendations.append("Continue logging reactions for more accurate patterns")
        }
        
        recommendations.append("Keep a detailed food diary including ingredients and meal times")
        recommendations.append("Consult a healthcare professional for persistent or severe reactions")
        
        return recommendations
    }
    
    private func calculateAverageSeverity(reactions: [FoodReaction]) -> ReactionSeverity {
        let severityScores = reactions.map { reaction -> Int in
            switch reaction.severity {
            case .mild: return 1
            case .moderate: return 2
            case .severe: return 3
            }
        }
        
        let average = Double(severityScores.reduce(0, +)) / Double(severityScores.count)
        
        switch average {
        case 0..<1.5:
            return .mild
        case 1.5..<2.5:
            return .moderate
        default:
            return .severe
        }
    }
    
    private func calculateFoodConfidence(
        reactionCount: Int,
        totalReactions: Int,
        severities: [ReactionSeverity]
    ) -> Double {
        // Base confidence on frequency
        let frequencyScore = Double(reactionCount) / Double(totalReactions)
        
        // Boost confidence if severities are consistent
        let severityConsistency = calculateSeverityConsistency(severities: severities)
        
        // Boost confidence for multiple reactions
        let reactionCountBoost = min(1.0, Double(reactionCount) / 5.0)
        
        return min(1.0, (frequencyScore + severityConsistency + reactionCountBoost) / 3.0)
    }
    
    private func calculateIngredientConfidence(
        occurrenceCount: Int,
        totalReactions: Int
    ) -> Double {
        let frequencyScore = Double(occurrenceCount) / Double(totalReactions)
        let occurrenceBoost = min(1.0, Double(occurrenceCount) / 4.0)
        
        return min(1.0, (frequencyScore + occurrenceBoost) / 2.0)
    }
    
    private func calculateSeverityConsistency(severities: [ReactionSeverity]) -> Double {
        guard severities.count > 1 else { return 1.0 }
        
        let severityCounts = Dictionary(grouping: severities, by: { $0 })
        let maxCount = severityCounts.values.map { $0.count }.max() ?? 0
        
        return Double(maxCount) / Double(severities.count)
    }
    
    private func calculateOverallConfidence(
        reactions: [FoodReaction],
        suspiciousFoods: [SuspiciousFood],
        ingredients: [IngredientPattern]
    ) -> Double {
        guard !reactions.isEmpty else { return 0.0 }
        
        // More reactions = higher confidence
        let reactionCountFactor = min(1.0, Double(reactions.count) / 10.0)
        
        // Having high-confidence suspicious foods increases confidence
        let foodConfidenceFactor = suspiciousFoods.first?.confidence ?? 0.0
        
        // Having common ingredients increases confidence
        let ingredientConfidenceFactor = ingredients.first?.confidence ?? 0.0
        
        return (reactionCountFactor + foodConfidenceFactor + ingredientConfidenceFactor) / 3.0
    }
}

// MARK: - User Profile
struct UserProfile {
    let userId: String
    let name: String
    let email: String?
    let dateOfBirth: Date?
    let height: Double? // cm
    let weight: Double? // kg
    let activityLevel: ActivityLevel
    let dietaryGoals: DietaryGoals
    let allergies: [String]
    let medicalConditions: [String]
    let dateCreated: Date
    let lastUpdated: Date
    
    enum ActivityLevel: String, CaseIterable {
        case sedentary = "sedentary"
        case lightlyActive = "lightlyActive"
        case moderatelyActive = "moderatelyActive"
        case veryActive = "veryActive"
        case extremelyActive = "extremelyActive"
    }
    
    struct DietaryGoals {
        let dailyCalories: Int
        let proteinPercentage: Double
        let carbsPercentage: Double
        let fatPercentage: Double
        let waterIntake: Double // litres
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "userId": userId,
            "name": name,
            "email": email ?? "",
            "dateOfBirth": dateOfBirth != nil ? Timestamp(date: dateOfBirth!) : NSNull(),
            "height": height ?? NSNull(),
            "weight": weight ?? NSNull(),
            "activityLevel": activityLevel.rawValue,
            "dietaryGoals": [
                "dailyCalories": dietaryGoals.dailyCalories,
                "proteinPercentage": dietaryGoals.proteinPercentage,
                "carbsPercentage": dietaryGoals.carbsPercentage,
                "fatPercentage": dietaryGoals.fatPercentage,
                "waterIntake": dietaryGoals.waterIntake
            ],
            "allergies": allergies,
            "medicalConditions": medicalConditions,
            "dateCreated": Timestamp(date: dateCreated),
            "lastUpdated": Timestamp(date: lastUpdated)
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> UserProfile? {
        guard let userId = data["userId"] as? String,
              let name = data["name"] as? String,
              let activityLevelRaw = data["activityLevel"] as? String,
              let activityLevel = ActivityLevel(rawValue: activityLevelRaw),
              let goalsData = data["dietaryGoals"] as? [String: Any],
              let dailyCalories = goalsData["dailyCalories"] as? Int,
              let proteinPercentage = goalsData["proteinPercentage"] as? Double,
              let carbsPercentage = goalsData["carbsPercentage"] as? Double,
              let fatPercentage = goalsData["fatPercentage"] as? Double,
              let waterIntake = goalsData["waterIntake"] as? Double,
              let allergies = data["allergies"] as? [String],
              let medicalConditions = data["medicalConditions"] as? [String],
              let dateCreatedTimestamp = data["dateCreated"] as? Timestamp,
              let lastUpdatedTimestamp = data["lastUpdated"] as? Timestamp else {
            return nil
        }
        
        let email = data["email"] as? String
        let height = data["height"] as? Double
        let weight = data["weight"] as? Double
        let dateOfBirth = (data["dateOfBirth"] as? Timestamp)?.dateValue()
        
        let dietaryGoals = DietaryGoals(
            dailyCalories: dailyCalories,
            proteinPercentage: proteinPercentage,
            carbsPercentage: carbsPercentage,
            fatPercentage: fatPercentage,
            waterIntake: waterIntake
        )
        
        return UserProfile(
            userId: userId,
            name: name,
            email: email,
            dateOfBirth: dateOfBirth,
            height: height,
            weight: weight,
            activityLevel: activityLevel,
            dietaryGoals: dietaryGoals,
            allergies: allergies,
            medicalConditions: medicalConditions,
            dateCreated: dateCreatedTimestamp.dateValue(),
            lastUpdated: lastUpdatedTimestamp.dateValue()
        )
    }
}

// MARK: - Food Entry
struct FoodEntry {
    let id: String
    let userId: String
    let foodName: String
    let brandName: String?
    let servingSize: Double
    let servingUnit: String
    let calories: Double
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let fiber: Double?
    let sugar: Double?
    let sodium: Double?
    let mealType: MealType
    let date: Date
    let dateLogged: Date
    
    enum MealType: String, CaseIterable {
        case breakfast = "breakfast"
        case lunch = "lunch"
        case dinner = "dinner"
        case snacks = "snacks"
    }
    
    init(userId: String, foodName: String, brandName: String? = nil, 
         servingSize: Double, servingUnit: String, calories: Double, 
         protein: Double, carbohydrates: Double, fat: Double, 
         fiber: Double? = nil, sugar: Double? = nil, sodium: Double? = nil,
         mealType: MealType, date: Date) {
        self.id = UUID().uuidString
        self.userId = userId
        self.foodName = foodName
        self.brandName = brandName
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.mealType = mealType
        self.date = date
        self.dateLogged = Date()
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "foodName": foodName,
            "brandName": brandName ?? "",
            "servingSize": servingSize,
            "servingUnit": servingUnit,
            "calories": calories,
            "protein": protein,
            "carbohydrates": carbohydrates,
            "fat": fat,
            "fiber": fiber ?? NSNull(),
            "sugar": sugar ?? NSNull(),
            "sodium": sodium ?? NSNull(),
            "mealType": mealType.rawValue,
            "date": Timestamp(date: date),
            "dateLogged": Timestamp(date: dateLogged)
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> FoodEntry? {
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let foodName = data["foodName"] as? String,
              let servingSize = data["servingSize"] as? Double,
              let servingUnit = data["servingUnit"] as? String,
              let calories = data["calories"] as? Double,
              let protein = data["protein"] as? Double,
              let carbohydrates = data["carbohydrates"] as? Double,
              let fat = data["fat"] as? Double,
              let mealTypeRaw = data["mealType"] as? String,
              let mealType = MealType(rawValue: mealTypeRaw),
              let dateTimestamp = data["date"] as? Timestamp,
              let dateLoggedTimestamp = data["dateLogged"] as? Timestamp else {
            return nil
        }
        
        let brandName = data["brandName"] as? String
        let fiber = data["fiber"] as? Double
        let sugar = data["sugar"] as? Double
        let sodium = data["sodium"] as? Double
        
        var entry = FoodEntry(
            userId: userId,
            foodName: foodName,
            brandName: brandName,
            servingSize: servingSize,
            servingUnit: servingUnit,
            calories: calories,
            protein: protein,
            carbohydrates: carbohydrates,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            mealType: mealType,
            date: dateTimestamp.dateValue()
        )
        
        // Override the generated values with stored ones
        return FoodEntry(
            id: id,
            userId: userId,
            foodName: foodName,
            brandName: brandName,
            servingSize: servingSize,
            servingUnit: servingUnit,
            calories: calories,
            protein: protein,
            carbohydrates: carbohydrates,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            mealType: mealType,
            date: dateTimestamp.dateValue(),
            dateLogged: dateLoggedTimestamp.dateValue()
        )
    }
}

extension FoodEntry {
    init(id: String, userId: String, foodName: String, brandName: String?, 
         servingSize: Double, servingUnit: String, calories: Double, 
         protein: Double, carbohydrates: Double, fat: Double, 
         fiber: Double?, sugar: Double?, sodium: Double?,
         mealType: MealType, date: Date, dateLogged: Date) {
        self.id = id
        self.userId = userId
        self.foodName = foodName
        self.brandName = brandName
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.mealType = mealType
        self.date = date
        self.dateLogged = dateLogged
    }
}

// MARK: - Kitchen Item
struct KitchenItem {
    let id: UUID
    let userId: String
    let name: String
    let quantity: Int
    let unit: String
    let expiryDate: Date?
    let category: String
    let notes: String?
    let dateAdded: Date
    
    init(userId: String, name: String, quantity: Int, unit: String, 
         expiryDate: Date? = nil, category: String = "Other", notes: String? = nil) {
        self.id = UUID()
        self.userId = userId
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.expiryDate = expiryDate
        self.category = category
        self.notes = notes
        self.dateAdded = Date()
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "userId": userId,
            "name": name,
            "quantity": quantity,
            "unit": unit,
            "expiryDate": expiryDate != nil ? Timestamp(date: expiryDate!) : NSNull(),
            "category": category,
            "notes": notes ?? "",
            "dateAdded": Timestamp(date: dateAdded)
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> KitchenItem? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let userId = data["userId"] as? String,
              let name = data["name"] as? String,
              let quantity = data["quantity"] as? Int,
              let unit = data["unit"] as? String,
              let category = data["category"] as? String,
              let dateAddedTimestamp = data["dateAdded"] as? Timestamp else {
            return nil
        }
        
        let notes = data["notes"] as? String
        let expiryDate = (data["expiryDate"] as? Timestamp)?.dateValue()
        
        var item = KitchenItem(
            userId: userId,
            name: name,
            quantity: quantity,
            unit: unit,
            expiryDate: expiryDate,
            category: category,
            notes: notes
        )
        
        // Override generated values with stored ones
        return KitchenItem(
            id: id,
            userId: userId,
            name: name,
            quantity: quantity,
            unit: unit,
            expiryDate: expiryDate,
            category: category,
            notes: notes,
            dateAdded: dateAddedTimestamp.dateValue()
        )
    }
}

extension KitchenItem {
    init(id: UUID, userId: String, name: String, quantity: Int, unit: String, 
         expiryDate: Date?, category: String, notes: String?, dateAdded: Date) {
        self.id = id
        self.userId = userId
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.expiryDate = expiryDate
        self.category = category
        self.notes = notes
        self.dateAdded = dateAdded
    }
}

// MARK: - Shopping List
struct ShoppingList {
    let id: UUID
    let userId: String
    let name: String
    let items: [ShoppingItem]
    let isCompleted: Bool
    let dateCreated: Date
    let dateCompleted: Date?
    
    struct ShoppingItem {
        let id: UUID
        let name: String
        let quantity: Int
        let unit: String
        let category: String
        let isCompleted: Bool
        let notes: String?
        
        init(name: String, quantity: Int = 1, unit: String = "item", 
             category: String = "Other", notes: String? = nil) {
            self.id = UUID()
            self.name = name
            self.quantity = quantity
            self.unit = unit
            self.category = category
            self.isCompleted = false
            self.notes = notes
        }
        
        func toDictionary() -> [String: Any] {
            return [
                "id": id.uuidString,
                "name": name,
                "quantity": quantity,
                "unit": unit,
                "category": category,
                "isCompleted": isCompleted,
                "notes": notes ?? ""
            ]
        }
        
        static func fromDictionary(_ data: [String: Any]) -> ShoppingItem? {
            guard let idString = data["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let name = data["name"] as? String,
                  let quantity = data["quantity"] as? Int,
                  let unit = data["unit"] as? String,
                  let category = data["category"] as? String,
                  let isCompleted = data["isCompleted"] as? Bool else {
                return nil
            }
            
            let notes = data["notes"] as? String
            
            return ShoppingItem(
                id: id,
                name: name,
                quantity: quantity,
                unit: unit,
                category: category,
                isCompleted: isCompleted,
                notes: notes
            )
        }
    }
    
    init(userId: String, name: String, items: [ShoppingItem] = []) {
        self.id = UUID()
        self.userId = userId
        self.name = name
        self.items = items
        self.isCompleted = false
        self.dateCreated = Date()
        self.dateCompleted = nil
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "userId": userId,
            "name": name,
            "items": items.map { $0.toDictionary() },
            "isCompleted": isCompleted,
            "dateCreated": Timestamp(date: dateCreated),
            "dateCompleted": dateCompleted != nil ? Timestamp(date: dateCompleted!) : NSNull()
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> ShoppingList? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let userId = data["userId"] as? String,
              let name = data["name"] as? String,
              let itemsData = data["items"] as? [[String: Any]],
              let isCompleted = data["isCompleted"] as? Bool,
              let dateCreatedTimestamp = data["dateCreated"] as? Timestamp else {
            return nil
        }
        
        let items = itemsData.compactMap { ShoppingItem.fromDictionary($0) }
        let dateCompleted = (data["dateCompleted"] as? Timestamp)?.dateValue()
        
        return ShoppingList(
            id: id,
            userId: userId,
            name: name,
            items: items,
            isCompleted: isCompleted,
            dateCreated: dateCreatedTimestamp.dateValue(),
            dateCompleted: dateCompleted
        )
    }
}

extension ShoppingList {
    init(id: UUID, userId: String, name: String, items: [ShoppingItem], 
         isCompleted: Bool, dateCreated: Date, dateCompleted: Date?) {
        self.id = id
        self.userId = userId
        self.name = name
        self.items = items
        self.isCompleted = isCompleted
        self.dateCreated = dateCreated
        self.dateCompleted = dateCompleted
    }
}

extension ShoppingList.ShoppingItem {
    init(id: UUID, name: String, quantity: Int, unit: String, 
         category: String, isCompleted: Bool, notes: String?) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.isCompleted = isCompleted
        self.notes = notes
    }
}

// MARK: - Exercise Entry
struct ExerciseEntry {
    let id: UUID
    let userId: String
    let exerciseName: String
    let type: ExerciseType
    let duration: TimeInterval // in seconds
    let caloriesBurned: Int
    let distance: Double? // in km for cardio
    let sets: Int? // for strength training
    let reps: Int? // for strength training
    let weight: Double? // in kg for strength training
    let notes: String?
    let date: Date
    let dateLogged: Date
    
    enum ExerciseType: String, CaseIterable {
        case cardio = "cardio"
        case strength = "strength"
        case flexibility = "flexibility"
        case sports = "sports"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .cardio:
                return "Cardio"
            case .strength:
                return "Strength Training"
            case .flexibility:
                return "Flexibility/Yoga"
            case .sports:
                return "Sports"
            case .other:
                return "Other"
            }
        }
    }
    
    init(userId: String, exerciseName: String, type: ExerciseType, 
         duration: TimeInterval, caloriesBurned: Int, distance: Double? = nil,
         sets: Int? = nil, reps: Int? = nil, weight: Double? = nil,
         notes: String? = nil, date: Date) {
        self.id = UUID()
        self.userId = userId
        self.exerciseName = exerciseName
        self.type = type
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.distance = distance
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.notes = notes
        self.date = date
        self.dateLogged = Date()
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "userId": userId,
            "exerciseName": exerciseName,
            "type": type.rawValue,
            "duration": duration,
            "caloriesBurned": caloriesBurned,
            "distance": distance ?? NSNull(),
            "sets": sets ?? NSNull(),
            "reps": reps ?? NSNull(),
            "weight": weight ?? NSNull(),
            "notes": notes ?? "",
            "date": Timestamp(date: date),
            "dateLogged": Timestamp(date: dateLogged)
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> ExerciseEntry? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let userId = data["userId"] as? String,
              let exerciseName = data["exerciseName"] as? String,
              let typeRaw = data["type"] as? String,
              let type = ExerciseType(rawValue: typeRaw),
              let duration = data["duration"] as? TimeInterval,
              let caloriesBurned = data["caloriesBurned"] as? Int,
              let dateTimestamp = data["date"] as? Timestamp,
              let dateLoggedTimestamp = data["dateLogged"] as? Timestamp else {
            return nil
        }
        
        let distance = data["distance"] as? Double
        let sets = data["sets"] as? Int
        let reps = data["reps"] as? Int
        let weight = data["weight"] as? Double
        let notes = data["notes"] as? String
        
        return ExerciseEntry(
            id: id,
            userId: userId,
            exerciseName: exerciseName,
            type: type,
            duration: duration,
            caloriesBurned: caloriesBurned,
            distance: distance,
            sets: sets,
            reps: reps,
            weight: weight,
            notes: notes,
            date: dateTimestamp.dateValue(),
            dateLogged: dateLoggedTimestamp.dateValue()
        )
    }
}

extension ExerciseEntry {
    init(id: UUID, userId: String, exerciseName: String, type: ExerciseType, 
         duration: TimeInterval, caloriesBurned: Int, distance: Double?,
         sets: Int?, reps: Int?, weight: Double?, notes: String?,
         date: Date, dateLogged: Date) {
        self.id = id
        self.userId = userId
        self.exerciseName = exerciseName
        self.type = type
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.distance = distance
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.notes = notes
        self.date = date
        self.dateLogged = dateLogged
    }
}

// MARK: - Safe Food
struct SafeFood {
    let id: UUID
    let userId: String
    let name: String
    let notes: String?
    let dateAdded: Date
    
    init(userId: String, name: String, notes: String? = nil) {
        self.id = UUID()
        self.userId = userId
        self.name = name
        self.notes = notes
        self.dateAdded = Date()
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "userId": userId,
            "name": name,
            "notes": notes ?? "",
            "dateAdded": Timestamp(date: dateAdded)
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> SafeFood? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let userId = data["userId"] as? String,
              let name = data["name"] as? String,
              let dateAddedTimestamp = data["dateAdded"] as? Timestamp else {
            return nil
        }
        
        let notes = data["notes"] as? String
        
        return SafeFood(
            id: id,
            userId: userId,
            name: name,
            notes: notes,
            dateAdded: dateAddedTimestamp.dateValue()
        )
    }
}

extension SafeFood {
    init(id: UUID, userId: String, name: String, notes: String?, dateAdded: Date) {
        self.id = id
        self.userId = userId
        self.name = name
        self.notes = notes
        self.dateAdded = dateAdded
    }
}

// MARK: - Ingredient Analysis System

struct Ingredient {
    let name: String
    let category: IngredientCategory
    let allergens: [Allergen]
    let micronutrients: [Micronutrient]
    let additives: [FoodAdditive]
    let riskLevel: IngredientRiskLevel
}

enum IngredientCategory: String, CaseIterable {
    case protein = "protein"
    case carbohydrate = "carbohydrate"
    case fat = "fat"
    case vitamin = "vitamin"
    case mineral = "mineral"
    case additive = "additive"
    case preservative = "preservative"
    case flavoring = "flavoring"
    case coloring = "coloring"
    case emulsifier = "emulsifier"
    case stabilizer = "stabilizer"
    case sweetener = "sweetener"
    case fiber = "fiber"
    case other = "other"
}

enum IngredientRiskLevel: String {
    case safe = "safe"
    case caution = "caution"
    case avoid = "avoid"
    case unknown = "unknown"
    
    var color: String {
        switch self {
        case .safe: return "green"
        case .caution: return "orange"
        case .avoid: return "red"
        case .unknown: return "gray"
        }
    }
}

struct Micronutrient {
    let name: String
    let type: MicronutrientType
    let amount: Double? // in appropriate units (mg, mcg, IU, etc.)
    let unit: String
    let dailyValuePercentage: Double?
    let benefits: [String]
    let deficiencyRisks: [String]
}

enum MicronutrientType: String, CaseIterable {
    case vitamin = "vitamin"
    case mineral = "mineral"
    case antioxidant = "antioxidant"
    case essentialFattyAcid = "essential_fatty_acid"
    case amino_acid = "amino_acid"
    case phytonutrient = "phytonutrient"
}

struct FoodAdditive {
    let name: String
    let code: String? // E-number or other code
    let purpose: AdditivePurpose
    let safetyRating: AdditiveRating
    let commonNames: [String]
    let potentialEffects: [String]
}

enum AdditivePurpose: String, CaseIterable {
    case preservative = "preservative"
    case colorant = "colorant"
    case flavoring = "flavoring"
    case emulsifier = "emulsifier"
    case stabilizer = "stabilizer"
    case thickener = "thickener"
    case sweetener = "sweetener"
    case antioxidant = "antioxidant"
    case acidRegulator = "acid_regulator"
    case other = "other"
}

enum AdditiveRating: String {
    case safe = "safe"
    case generallyRecognizedAsSafe = "gras"
    case limitedUse = "limited_use"
    case caution = "caution"
    case avoid = "avoid"
    case banned = "banned"
    
    var color: String {
        switch self {
        case .safe, .generallyRecognizedAsSafe: return "green"
        case .limitedUse: return "yellow"
        case .caution: return "orange"
        case .avoid, .banned: return "red"
        }
    }
}

struct IngredientAnalysisResult {
    let ingredients: [Ingredient]
    let detectedAllergens: [Allergen]
    let micronutrients: [Micronutrient]
    let additives: [FoodAdditive]
    let overallRiskLevel: IngredientRiskLevel
    let warnings: [String]
    let benefits: [String]
    let recommendations: [String]
}

class IngredientAnalyzer {
    static let shared = IngredientAnalyzer()
    
    private init() {}
    
    func analyseIngredients(_ ingredientList: [String], userAllergens: [Allergen] = []) -> IngredientAnalysisResult {
        var analyzedIngredients: [Ingredient] = []
        var detectedAllergens: [Allergen] = []
        var micronutrients: [Micronutrient] = []
        var additives: [FoodAdditive] = []
        var warnings: [String] = []
        var benefits: [String] = []
        var recommendations: [String] = []
        
        for ingredientName in ingredientList {
            let ingredient = analyseIndividualIngredient(ingredientName)
            analyzedIngredients.append(ingredient)
            
            // Check for allergens
            for allergen in ingredient.allergens {
                if userAllergens.contains(allergen) && !detectedAllergens.contains(allergen) {
                    detectedAllergens.append(allergen)
                    warnings.append("Contains \(allergen.displayName): \(ingredientName)")
                }
            }
            
            // Collect micronutrients
            micronutrients.append(contentsOf: ingredient.micronutrients)
            
            // Collect additives
            additives.append(contentsOf: ingredient.additives)
            
            // Add warnings for risky ingredients
            if ingredient.riskLevel == .avoid {
                warnings.append("Avoid: \(ingredientName) - potential health concerns")
            } else if ingredient.riskLevel == .caution {
                warnings.append("Caution: \(ingredientName) - consume in moderation")
            }
            
            // Add benefits for beneficial ingredients
            if ingredient.riskLevel == .safe && !ingredient.micronutrients.isEmpty {
                let nutrientNames = ingredient.micronutrients.map { $0.name }
                benefits.append("\(ingredientName): Rich in \(nutrientNames.joined(separator: ", "))")
            }
        }
        
        // Calculate overall risk level
        let overallRiskLevel = calculateOverallRiskLevel(analyzedIngredients)
        
        // Generate recommendations
        recommendations = generateRecommendations(
            ingredients: analyzedIngredients,
            allergens: detectedAllergens,
            additives: additives
        )
        
        return IngredientAnalysisResult(
            ingredients: analyzedIngredients,
            detectedAllergens: detectedAllergens,
            micronutrients: Array(Set(micronutrients.map { $0.name })).compactMap { name in
                micronutrients.first { $0.name == name }
            }, // Remove duplicates
            additives: additives,
            overallRiskLevel: overallRiskLevel,
            warnings: warnings,
            benefits: benefits,
            recommendations: recommendations
        )
    }
    
    private func analyseIndividualIngredient(_ ingredientName: String) -> Ingredient {
        let lowerName = ingredientName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Determine category
        let category = categorizeIngredient(lowerName)
        
        // Detect allergens
        let allergens = detectAllergensInIngredient(lowerName)
        
        // Get micronutrients
        let micronutrients = getMicronutrientsForIngredient(lowerName)
        
        // Detect additives
        let additives = detectAdditives(lowerName)
        
        // Calculate risk level
        let riskLevel = calculateIngredientRiskLevel(lowerName, additives: additives)
        
        return Ingredient(
            name: ingredientName,
            category: category,
            allergens: allergens,
            micronutrients: micronutrients,
            additives: additives,
            riskLevel: riskLevel
        )
    }
    
    private func categorizeIngredient(_ ingredient: String) -> IngredientCategory {
        // Proteins
        if ingredient.contains("protein") || ingredient.contains("casein") || ingredient.contains("whey") ||
           ["egg", "milk", "meat", "chicken", "beef", "pork", "fish", "tofu", "soy"].contains(where: ingredient.contains) {
            return .protein
        }
        
        // Carbohydrates
        if ["sugar", "glucose", "fructose", "sucrose", "maltose", "starch", "flour", "rice", "wheat", "corn"].contains(where: ingredient.contains) {
            return .carbohydrate
        }
        
        // Fats
        if ingredient.contains("oil") || ingredient.contains("fat") || ingredient.contains("butter") ||
           ["palm", "coconut", "olive", "sunflower", "canola", "lard"].contains(where: ingredient.contains) {
            return .fat
        }
        
        // Vitamins
        if ingredient.contains("vitamin") || ["ascorbic acid", "thiamine", "riboflavin", "niacin", "folate", "biotin"].contains(where: ingredient.contains) {
            return .vitamin
        }
        
        // Minerals
        if ["calcium", "iron", "magnesium", "zinc", "potassium", "sodium", "phosphorus"].contains(where: ingredient.contains) {
            return .mineral
        }
        
        // Additives with E-numbers
        if ingredient.hasPrefix("e") && ingredient.count >= 3 {
            return .additive
        }
        
        // Preservatives
        if ["preservative", "sodium benzoate", "potassium sorbate", "citric acid"].contains(where: ingredient.contains) {
            return .preservative
        }
        
        // Sweeteners
        if ["sweetener", "aspartame", "sucralose", "stevia", "saccharin"].contains(where: ingredient.contains) {
            return .sweetener
        }
        
        // Colors
        if ingredient.contains("color") || ingredient.contains("colour") || ["caramel", "annatto", "turmeric"].contains(where: ingredient.contains) {
            return .coloring
        }
        
        // Flavors
        if ingredient.contains("flavor") || ingredient.contains("flavour") || ingredient.contains("extract") {
            return .flavoring
        }
        
        // Fiber
        if ingredient.contains("fiber") || ingredient.contains("fibre") || ["cellulose", "pectin", "inulin"].contains(where: ingredient.contains) {
            return .fiber
        }
        
        return .other
    }
    
    private func detectAllergensInIngredient(_ ingredient: String) -> [Allergen] {
        var detectedAllergens: [Allergen] = []
        
        for allergen in Allergen.allCases {
            for keyword in allergen.keywords {
                if ingredient.contains(keyword.lowercased()) {
                    if !detectedAllergens.contains(allergen) {
                        detectedAllergens.append(allergen)
                    }
                    break
                }
            }
        }
        
        return detectedAllergens
    }
    
    private func getMicronutrientsForIngredient(_ ingredient: String) -> [Micronutrient] {
        var micronutrients: [Micronutrient] = []
        
        // Common micronutrient mappings
        if ingredient.contains("spinach") || ingredient.contains("kale") {
            micronutrients.append(Micronutrient(
                name: "Iron",
                type: .mineral,
                amount: 2.7,
                unit: "mg",
                dailyValuePercentage: 15,
                benefits: ["Oxygen transport", "Energy production"],
                deficiencyRisks: ["Anemia", "Fatigue"]
            ))
            micronutrients.append(Micronutrient(
                name: "Vitamin K",
                type: .vitamin,
                amount: 483,
                unit: "mcg",
                dailyValuePercentage: 402,
                benefits: ["Blood clotting", "Bone health"],
                deficiencyRisks: ["Bleeding disorders", "Weak bones"]
            ))
        }
        
        if ingredient.contains("orange") || ingredient.contains("citrus") {
            micronutrients.append(Micronutrient(
                name: "Vitamin C",
                type: .vitamin,
                amount: 53,
                unit: "mg",
                dailyValuePercentage: 59,
                benefits: ["Immune support", "Antioxidant", "Collagen synthesis"],
                deficiencyRisks: ["Scurvy", "Impaired wound healing"]
            ))
        }
        
        if ingredient.contains("milk") || ingredient.contains("dairy") {
            micronutrients.append(Micronutrient(
                name: "Calcium",
                type: .mineral,
                amount: 276,
                unit: "mg",
                dailyValuePercentage: 28,
                benefits: ["Bone health", "Muscle function"],
                deficiencyRisks: ["Osteoporosis", "Muscle cramps"]
            ))
        }
        
        if ingredient.contains("fish") || ingredient.contains("salmon") {
            micronutrients.append(Micronutrient(
                name: "Omega-3 Fatty Acids",
                type: .essentialFattyAcid,
                amount: 1.8,
                unit: "g",
                dailyValuePercentage: nil,
                benefits: ["Heart health", "Brain function", "Anti-inflammatory"],
                deficiencyRisks: ["Cardiovascular disease", "Cognitive decline"]
            ))
        }
        
        return micronutrients
    }
    
    private func detectAdditives(_ ingredient: String) -> [FoodAdditive] {
        var additives: [FoodAdditive] = []
        
        // Common food additives
        if ingredient.contains("sodium benzoate") || ingredient.contains("e211") {
            additives.append(FoodAdditive(
                name: "Sodium Benzoate",
                code: "E211",
                purpose: .preservative,
                safetyRating: .generallyRecognizedAsSafe,
                commonNames: ["Sodium benzoate"],
                potentialEffects: ["May cause hyperactivity in sensitive individuals"]
            ))
        }
        
        if ingredient.contains("aspartame") || ingredient.contains("e951") {
            additives.append(FoodAdditive(
                name: "Aspartame",
                code: "E951",
                purpose: .sweetener,
                safetyRating: .caution,
                commonNames: ["NutraSweet", "Equal"],
                potentialEffects: ["Not suitable for phenylketonuria", "May cause headaches in sensitive individuals"]
            ))
        }
        
        if ingredient.contains("msg") || ingredient.contains("monosodium glutamate") || ingredient.contains("e621") {
            additives.append(FoodAdditive(
                name: "Monosodium Glutamate",
                code: "E621",
                purpose: .flavoring,
                safetyRating: .caution,
                commonNames: ["MSG", "Flavour enhancer"],
                potentialEffects: ["May cause headaches", "Flushing", "Sweating in sensitive individuals"]
            ))
        }
        
        return additives
    }
    
    private func calculateIngredientRiskLevel(_ ingredient: String, additives: [FoodAdditive]) -> IngredientRiskLevel {
        // Check for banned or avoid-level additives
        if additives.contains(where: { $0.safetyRating == .avoid || $0.safetyRating == .banned }) {
            return .avoid
        }
        
        // Check for caution-level additives
        if additives.contains(where: { $0.safetyRating == .caution }) {
            return .caution
        }
        
        // Check for known problematic ingredients
        let problematicIngredients = [
            "trans fat", "partially hydrogenated", "high fructose corn syrup",
            "sodium nitrite", "sodium nitrate", "artificial colors"
        ]
        
        for problematic in problematicIngredients {
            if ingredient.contains(problematic) {
                return .avoid
            }
        }
        
        // Natural whole food ingredients are generally safe
        let wholeFoodIngredients = [
            "apple", "banana", "orange", "spinach", "broccoli", "carrot",
            "chicken", "beef", "fish", "rice", "oats", "quinoa"
        ]
        
        for wholeFood in wholeFoodIngredients {
            if ingredient.contains(wholeFood) {
                return .safe
            }
        }
        
        return .unknown
    }
    
    private func calculateOverallRiskLevel(_ ingredients: [Ingredient]) -> IngredientRiskLevel {
        let riskLevels = ingredients.map { $0.riskLevel }
        
        if riskLevels.contains(.avoid) {
            return .avoid
        } else if riskLevels.contains(.caution) {
            return .caution
        } else if riskLevels.allSatisfy({ $0 == .safe }) {
            return .safe
        } else {
            return .unknown
        }
    }
    
    private func generateRecommendations(
        ingredients: [Ingredient],
        allergens: [Allergen],
        additives: [FoodAdditive]
    ) -> [String] {
        var recommendations: [String] = []
        
        if !allergens.isEmpty {
            recommendations.append("⚠️ Contains allergens you're sensitive to - consider alternatives")
        }
        
        let avoidAdditives = additives.filter { $0.safetyRating == .avoid || $0.safetyRating == .banned }
        if !avoidAdditives.isEmpty {
            recommendations.append("🚫 Contains additives you should avoid: \(avoidAdditives.map { $0.name }.joined(separator: ", "))")
        }
        
        let cautionAdditives = additives.filter { $0.safetyRating == .caution }
        if !cautionAdditives.isEmpty {
            recommendations.append("⚠️ Use caution with: \(cautionAdditives.map { $0.name }.joined(separator: ", "))")
        }
        
        let beneficialIngredients = ingredients.filter { $0.riskLevel == .safe && !$0.micronutrients.isEmpty }
        if !beneficialIngredients.isEmpty {
            recommendations.append("✅ Good sources of nutrients from: \(beneficialIngredients.map { $0.name }.joined(separator: ", "))")
        }
        
        recommendations.append("💡 Always check full ingredient lists and consult healthcare providers for specific concerns")
        
        return recommendations
    }
}

// MARK: - Comprehensive Nutrition Processing Score System

enum ProcessingGrade: String, CaseIterable {
    case aPlus = "A+"
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    case f = "F"
    
    var numericValue: Int {
        switch self {
        case .aPlus: return 5
        case .a: return 4
        case .b: return 3
        case .c: return 2
        case .d: return 1
        case .f: return 0
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
        }
    }
}

struct NutritionProcessingScore {
    let grade: ProcessingGrade
    let score: Int  // 0-100
    let explanation: String
    let factors: [String]
    let processingLevel: ProcessingLevel
    let additiveCount: Int
    let eNumberCount: Int
    let naturalScore: Int
    
    var color: Color {
        switch grade {
        case .aPlus, .a:
            return Color.green
        case .b:
            return Color.orange
        case .c:
            return Color.yellow
        case .d:
            return Color.red.opacity(0.8)
        case .f:
            return Color.red
        }
    }
}

enum ProcessingLevel: String, CaseIterable {
    case unprocessed = "Unprocessed"           // Fresh fruits, vegetables, raw meat, plain water
    case minimally = "Minimally Processed"     // Frozen vegetables, plain yoghurt, tinned beans
    case processed = "Processed"               // Bread, cheese, tinned fruit in syrup
    case ultraProcessed = "Ultra-Processed"    // Ready meals, fizzy drinks, crisps, biscuits
    
    var score: Int {
        switch self {
        case .unprocessed: return 100
        case .minimally: return 80
        case .processed: return 50
        case .ultraProcessed: return 10
        }
    }
}

class ProcessingScorer {
    static let shared = ProcessingScorer()
    
    private init() {}
    
    func calculateProcessingScore(for foodName: String) -> NutritionProcessingScore {
        let foodLower = foodName.lowercased()
        
        // Determine base processing level
        let processingLevel = determineProcessingLevel(foodLower)
        
        // Analyze additives and E-numbers
        let additiveAnalysis = analyseAdditives(in: foodLower)
        
        // Calculate natural food bonus
        let naturalScore = calculateNaturalScore(foodLower)
        
        // Calculate base score from processing level
        var totalScore = processingLevel.score
        
        // Apply additive penalties
        totalScore -= (additiveAnalysis.eNumbers.count * 15)  // Heavy penalty for E-numbers
        totalScore -= (additiveAnalysis.additives.count * 8)   // Moderate penalty for additives
        totalScore -= (additiveAnalysis.preservatives.count * 10) // Heavy penalty for preservatives
        
        // Apply natural bonuses
        totalScore += naturalScore
        
        // Apply ultra-processed penalties
        if processingLevel == .ultraProcessed {
            totalScore -= 30  // Heavy penalty for ultra-processed foods
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
    
    private func determineProcessingLevel(_ food: String) -> ProcessingLevel {
        // Ultra-processed foods (F grade territory)
        let ultraProcessedTerms = [
            "fizzy drink", "soda", "cola", "pepsi", "coca cola", "energy drink",
            "ready meal", "microwave meal", "instant", "processed meat", "sausage",
            "burger", "chips", "crisps", "biscuits", "cookies", "cake mix",
            "ice cream", "chocolate bar", "sweets", "candy", "margarine",
            "chicken nuggets", "fish fingers", "frozen pizza", "pot noodle"
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
        
        // Default to processed for unknown foods
        return .processed
    }
    
    private struct AdditiveAnalysis {
        let eNumbers: [String]
        let additives: [String]
        let preservatives: [String]
        let goodAdditives: [String]  // Things like matcha, turmeric
    }
    
    private func analyseAdditives(in food: String) -> AdditiveAnalysis {
        var eNumbers: [String] = []
        var additives: [String] = []
        var preservatives: [String] = []
        var goodAdditives: [String] = []
        
        // Common E-numbers (bad)
        let commonENumbers = [
            "e100", "e102", "e104", "e110", "e122", "e124", "e129", // Colourings
            "e200", "e202", "e211", "e220", "e223", "e224", "e228", // Preservatives
            "e621", "e627", "e631", "e635", // Flavour enhancers (MSG family)
            "e951", "e952", "e954", "e955" // Artificial sweeteners
        ]
        
        // Common bad additives
        let badAdditives = [
            "monosodium glutamate", "msg", "high fructose corn syrup",
            "sodium nitrite", "sodium nitrate", "potassium sorbate",
            "sodium benzoate", "artificial colours", "artificial flavours",
            "trans fat", "hydrogenated oil", "aspartame", "sucralose"
        ]
        
        // Common preservatives
        let preservativeTerms = [
            "preservative", "sodium", "potassium", "calcium", "benzoate",
            "sorbate", "nitrate", "nitrite", "sulfite", "bisulfite"
        ]
        
        // Good additives that should boost score
        let beneficialAdditives = [
            "matcha", "turmeric", "curcumin", "green tea extract",
            "vitamin c", "vitamin e", "beta carotene", "lycopene",
            "probiotics", "prebiotics", "omega 3", "antioxidants"
        ]
        
        // Scan for E-numbers
        eNumbers = commonENumbers.filter { food.contains($0) }
        
        // Scan for bad additives
        additives = badAdditives.filter { food.contains($0) }
        
        // Scan for preservatives
        preservatives = preservativeTerms.filter { food.contains($0) }
        
        // Scan for good additives
        goodAdditives = beneficialAdditives.filter { food.contains($0) }
        
        return AdditiveAnalysis(
            eNumbers: eNumbers,
            additives: additives,
            preservatives: preservatives,
            goodAdditives: goodAdditives
        )
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
        
        if additiveAnalysis.eNumbers.count > 0 {
            explanation += "\(additiveAnalysis.eNumbers.count) E-number(s) detected. "
        }
        
        if additiveAnalysis.additives.count > 0 {
            explanation += "\(additiveAnalysis.additives.count) additive(s) detected. "
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
        
        if additiveAnalysis.eNumbers.count > 0 {
            factors.append("⚠️ \(additiveAnalysis.eNumbers.count) E-number(s)")
        }
        
        if additiveAnalysis.additives.count > 0 {
            factors.append("⚠️ \(additiveAnalysis.additives.count) additive(s)")
        }
        
        if additiveAnalysis.preservatives.count > 0 {
            factors.append("⚠️ \(additiveAnalysis.preservatives.count) preservative(s)")
        }
        
        if additiveAnalysis.goodAdditives.count > 0 {
            factors.append("✅ \(additiveAnalysis.goodAdditives.count) beneficial additive(s)")
        }
        
        if naturalScore > 0 {
            factors.append("✅ Natural food bonus")
        }
        
        return factors
    }
}

// MARK: - Glycemic Index System

enum GICategory: String, CaseIterable {
    case low = "Low GI"
    case medium = "Medium GI" 
    case high = "High GI"
    case unknown = "GI Unknown"
    
    var range: String {
        switch self {
        case .low: return "< 55"
        case .medium: return "55-70"
        case .high: return "> 70"
        case .unknown: return "N/A"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .unknown: return .gray
        }
    }
    
    var description: String {
        switch self {
        case .low: return "Slow glucose release - good for blood sugar control"
        case .medium: return "Moderate glucose release - consume mindfully"
        case .high: return "Rapid glucose release - limit portion size"
        case .unknown: return "GI data not available for this food"
        }
    }
}

struct GlycemicIndexData {
    let value: Int?  // nil if unknown
    let category: GICategory
    let servingSize: String
    let carbsPer100g: Double
    let isEstimated: Bool
    
    func calculateGIImpact(servingGrams: Double, carbsInServing: Double) -> Double? {
        guard let giValue = value, carbsInServing > 0 else { return nil }
        
        // Calculate GL (Glycemic Load) = (GI × carbs in serving) / 100
        let glycemicLoad = (Double(giValue) * carbsInServing) / 100.0
        return glycemicLoad
    }
}

class GlycemicIndexDatabase {
    static let shared = GlycemicIndexDatabase()
    
    private init() {}
    
    // Scientifically-validated GI values for common foods
    private let giDatabase: [String: GlycemicIndexData] = [
        // Fruits (clinically tested values)
        "apple": GlycemicIndexData(value: 36, category: .low, servingSize: "1 medium (120g)", carbsPer100g: 14.0, isEstimated: false),
        "banana": GlycemicIndexData(value: 51, category: .low, servingSize: "1 medium (120g)", carbsPer100g: 23.0, isEstimated: false),
        "orange": GlycemicIndexData(value: 43, category: .low, servingSize: "1 medium (150g)", carbsPer100g: 12.0, isEstimated: false),
        "grapes": GlycemicIndexData(value: 46, category: .low, servingSize: "1 cup (150g)", carbsPer100g: 16.0, isEstimated: false),
        "watermelon": GlycemicIndexData(value: 76, category: .high, servingSize: "1 cup (150g)", carbsPer100g: 8.0, isEstimated: false),
        
        // Vegetables
        "potato": GlycemicIndexData(value: 78, category: .high, servingSize: "1 medium (150g)", carbsPer100g: 17.0, isEstimated: false),
        "sweet potato": GlycemicIndexData(value: 70, category: .high, servingSize: "1 medium (150g)", carbsPer100g: 20.0, isEstimated: false),
        "carrot": GlycemicIndexData(value: 47, category: .low, servingSize: "1 cup (120g)", carbsPer100g: 10.0, isEstimated: false),
        "broccoli": GlycemicIndexData(value: 10, category: .low, servingSize: "1 cup (90g)", carbsPer100g: 7.0, isEstimated: false),
        
        // Grains & Cereals
        "white rice": GlycemicIndexData(value: 73, category: .high, servingSize: "1 cup cooked (150g)", carbsPer100g: 28.0, isEstimated: false),
        "brown rice": GlycemicIndexData(value: 68, category: .medium, servingSize: "1 cup cooked (150g)", carbsPer100g: 23.0, isEstimated: false),
        "oats": GlycemicIndexData(value: 55, category: .medium, servingSize: "1 cup cooked (240g)", carbsPer100g: 12.0, isEstimated: false),
        "quinoa": GlycemicIndexData(value: 53, category: .low, servingSize: "1 cup cooked (185g)", carbsPer100g: 22.0, isEstimated: false),
        "white bread": GlycemicIndexData(value: 75, category: .high, servingSize: "1 slice (30g)", carbsPer100g: 49.0, isEstimated: false),
        "wholemeal bread": GlycemicIndexData(value: 74, category: .high, servingSize: "1 slice (30g)", carbsPer100g: 41.0, isEstimated: false),
        
        // Legumes
        "lentils": GlycemicIndexData(value: 32, category: .low, servingSize: "1 cup cooked (200g)", carbsPer100g: 20.0, isEstimated: false),
        "chickpeas": GlycemicIndexData(value: 28, category: .low, servingSize: "1 cup cooked (165g)", carbsPer100g: 27.0, isEstimated: false),
        "kidney beans": GlycemicIndexData(value: 24, category: .low, servingSize: "1 cup cooked (180g)", carbsPer100g: 25.0, isEstimated: false),
        
        // Dairy
        "milk": GlycemicIndexData(value: 39, category: .low, servingSize: "1 cup (240ml)", carbsPer100g: 5.0, isEstimated: false),
        "yoghurt": GlycemicIndexData(value: 41, category: .low, servingSize: "1 cup (245g)", carbsPer100g: 4.7, isEstimated: false),
        
        // Nuts (very low/no GI impact)
        "almonds": GlycemicIndexData(value: 0, category: .low, servingSize: "30g", carbsPer100g: 4.0, isEstimated: false),
        "nuts": GlycemicIndexData(value: 15, category: .low, servingSize: "30g", carbsPer100g: 7.0, isEstimated: false),
    ]
    
    func getGIData(for foodName: String) -> GlycemicIndexData? {
        let searchTerm = foodName.lowercased()
        
        // Direct match first
        if let data = giDatabase[searchTerm] {
            return data
        }
        
        // Partial match for compound foods
        for (key, data) in giDatabase {
            if searchTerm.contains(key) || key.contains(searchTerm) {
                return data
            }
        }
        
        // No data available - return unknown
        return GlycemicIndexData(
            value: nil, 
            category: .unknown, 
            servingSize: "N/A", 
            carbsPer100g: 0.0, 
            isEstimated: false
        )
    }
    
    func calculateGICategory(from value: Int) -> GICategory {
        switch value {
        case 0..<55:
            return .low
        case 55...70:
            return .medium
        default:
            return .high
        }
    }
}

// MARK: - Enhanced Food Detail System

struct FoodServingOption {
    let id = UUID()
    let name: String
    let unit: String
    let gramsPerServing: Double
    let isDefault: Bool
}

struct DetailedFoodInfo {
    let name: String
    let brand: String?
    let energy: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fibre: Double
    let sugar: Double
    let sodium: Double
    let servingOptions: [FoodServingOption]
    let nutritionPer100g: Bool
    let ingredients: [String]?
    let allergens: [Allergen]
    let processingScore: NutritionProcessingScore
    let glycemicIndex: GlycemicIndexData
}