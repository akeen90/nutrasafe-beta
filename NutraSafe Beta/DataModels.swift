import Foundation
import Firebase

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
        
        // High fiber content
        let fiberPerCalorie = fiber / (calories / 100) // fiber per 100 calories
        if fiberPerCalorie > 3.0 {
            score += 12
            positiveFactors.append("Excellent fiber content (\(String(format: "%.1f", fiber))g)")
        } else if fiberPerCalorie > 2.0 {
            score += 6
            positiveFactors.append("Good fiber content (\(String(format: "%.1f", fiber))g)")
        }
        
        // Low calorie density
        if calories < 100 {
            score += 10
            positiveFactors.append("Low calorie density")
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
            negativeFactors.append("Very high calorie density")
            recommendations.append("Watch portion sizes for calorie-dense foods")
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