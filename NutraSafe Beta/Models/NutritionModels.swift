//
//  NutritionModels.swift
//  NutraSafe Beta
//
//  Domain models for Nutrition
//

import Foundation
import SwiftUI
import FirebaseFirestore

// MARK: - Nutrition Models
// Uses shared types from CoreModels and FoodSafetyModels where appropriate

struct FoodSearchResult: Identifiable, Decodable, Equatable {
    let id: String
    let name: String
    let brand: String?
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let servingDescription: String?
    let ingredients: [String]?
    let confidence: Double? // For AI recognition results
    let isVerified: Bool // Indicates if food comes from internal verified database
    let additives: [NutritionAdditiveInfo]?
    let processingScore: Int?
    let processingGrade: String?
    let processingLabel: String?
    
    init(id: String, name: String, brand: String? = nil, calories: Double, protein: Double, carbs: Double, fat: Double, fiber: Double, sugar: Double, sodium: Double, servingDescription: String? = nil, ingredients: [String]? = nil, confidence: Double? = nil, isVerified: Bool = false, additives: [NutritionAdditiveInfo]? = nil, processingScore: Int? = nil, processingGrade: String? = nil, processingLabel: String? = nil) {
        self.id = id
        self.name = name
        self.brand = brand
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.servingDescription = servingDescription
        self.ingredients = ingredients
        self.confidence = confidence
        self.isVerified = isVerified
        self.additives = additives
        self.processingScore = processingScore
        self.processingGrade = processingGrade
        self.processingLabel = processingLabel
    }
    
    // Custom decoder to handle flexible payloads from Cloud Functions
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case brand
        case calories
        case protein
        case carbs
        case fat
        case fiber
        case sugar
        case sodium
        case servingDescription
        case ingredients
        case confidence
        case verifiedBy
        case verificationMethod
        case verifiedAt
        case additives
        case processingScore
        case processingGrade
        case processingLabel
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.name = try c.decode(String.self, forKey: .name)
        self.brand = try c.decodeIfPresent(String.self, forKey: .brand)
        self.calories = (try? c.decode(Double.self, forKey: .calories)) ?? 0
        self.protein = (try? c.decode(Double.self, forKey: .protein)) ?? 0
        self.carbs = (try? c.decode(Double.self, forKey: .carbs)) ?? 0
        self.fat = (try? c.decode(Double.self, forKey: .fat)) ?? 0
        self.fiber = (try? c.decode(Double.self, forKey: .fiber)) ?? 0
        self.sugar = (try? c.decode(Double.self, forKey: .sugar)) ?? 0
        self.sodium = (try? c.decode(Double.self, forKey: .sodium)) ?? 0
        self.servingDescription = try? c.decode(String.self, forKey: .servingDescription)
        // ingredients could be string or array - normalize to [String]
        if let arr = try? c.decode([String].self, forKey: .ingredients) {
            self.ingredients = arr
        } else if let str = try? c.decode(String.self, forKey: .ingredients) {
            let parts = str.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            self.ingredients = parts.isEmpty ? nil : parts
        } else {
            self.ingredients = nil
        }
        self.confidence = try? c.decode(Double.self, forKey: .confidence)
        // Consider the result verified if backend included any verification markers
        let hasVerifier = (try? c.decodeIfPresent(String.self, forKey: .verifiedBy)) != nil || (try? c.decodeIfPresent(String.self, forKey: .verificationMethod)) != nil || (try? c.decodeIfPresent(String.self, forKey: .verifiedAt)) != nil
        self.isVerified = hasVerifier
        self.additives = try? c.decode([NutritionAdditiveInfo].self, forKey: .additives)
        self.processingScore = try? c.decode(Int.self, forKey: .processingScore)
        self.processingGrade = try? c.decode(String.self, forKey: .processingGrade)
        self.processingLabel = try? c.decode(String.self, forKey: .processingLabel)
    }
    
    var servingSize: String {
        return servingDescription ?? "per 100g"
    }
}

// MARK: - Barcode Response Models

struct BarcodeSearchResponse: Codable {
    let success: Bool
    let food: BarcodeFood?
    let error: String?
    let message: String?
    let action: String?
    let placeholder_id: String?
    let barcode: String?

    // Convert to FoodSearchResult for compatibility
    func toFoodSearchResult() -> FoodSearchResult? {
        guard let food = food else { return nil }

        return FoodSearchResult(
            id: food.food_id,
            name: food.food_name,
            brand: food.brand_name,
            calories: food.calories,
            protein: food.protein,
            carbs: food.carbohydrates,
            fat: food.fat,
            fiber: food.fiber,
            sugar: food.sugar,
            sodium: food.sodium,
            servingDescription: food.serving_description,
            ingredients: food.ingredients?.components(separatedBy: ", "),
            isVerified: food.source_collection != "pendingFoods"
        )
    }
}

struct BarcodeFood: Codable {
    let food_id: String
    let food_name: String
    let brand_name: String?
    let barcode: String
    let calories: Double
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let serving_description: String
    let ingredients: String?
    let source_collection: String?
}

struct PendingFoodContribution: Identifiable {
    let id: String
    let barcode: String
    let placeholderName: String

    init(placeholderId: String, barcode: String) {
        self.id = placeholderId
        self.barcode = barcode
        self.placeholderName = "Unknown Product (\(barcode))"
    }
}

// Local nutrition-specific AdditiveInfo to avoid conflicts with FoodSafetyModels
struct NutritionAdditiveInfo: Codable, Equatable {
    let code: String
    let name: String
    let category: String
    let healthScore: Int
    let childWarning: Bool
    let effectsVerdict: String
}

// Local nutrition-specific TimePattern to avoid conflicts with FoodSafetyModels
struct NutritionTimePattern {
    let pattern: String
    let description: String
    let occurrenceCount: Int
}

// MARK: - Nutrition Analysis Models

struct NutritionProfile {
    let foodName: String
    let brand: String?
    let calories: Double
    let macronutrients: Macronutrients
    let micronutrients: Micronutrients
    let ingredients: [NutritionIngredient]
    let nutritionScore: NutritionScore
    let allergens: [NutritionAllergen]
    let dietaryFlags: [DietaryFlag]
    let servingInfo: ServingInfo
    let processingLevel: ProcessingLevel // Uses CoreModels.ProcessingLevel
    let timestamp: Timestamp
}

struct Macronutrients {
    let protein: Double // grams
    let carbohydrates: Double // grams
    let fat: Double // grams
    let fiber: Double // grams
    let sugar: Double // grams
    let sodium: Double // mg
    let saturatedFat: Double? // grams
    let transFat: Double? // grams
    let cholesterol: Double? // mg
}

struct Micronutrients {
    let vitamins: [Vitamin]
    let minerals: [Mineral]
    let dailyValuePercentages: [String: Double] // nutrient name -> percentage
}

struct Vitamin {
    let name: String
    let amount: Double
    let unit: String
    let dailyValuePercentage: Double?
}

struct Mineral {
    let name: String
    let amount: Double
    let unit: String
    let dailyValuePercentage: Double?
}

struct NutritionScore {
    let overallScore: Double // 0-100
    let grade: NutritionGrade
    let positivePoints: Int
    let negativePoints: Int
    let breakdown: ScoreBreakdown
}

enum NutritionGrade: String, CaseIterable {
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    case e = "E"
    case f = "F"
    
    var color: Color {
        switch self {
        case .a: return .green
        case .b: return Color(red: 0.7, green: 0.8, blue: 0.2)
        case .c: return .yellow
        case .d: return .orange
        case .e: return Color(red: 1.0, green: 0.6, blue: 0.0)
        case .f: return .red
        }
    }
}

struct ScoreBreakdown {
    let proteinPoints: Int
    let fiberPoints: Int
    let fruitVegPoints: Int
    let energyPoints: Int
    let saturatedFatPoints: Int
    let sodiumPoints: Int
    let sugarPoints: Int
}

// Nutrition-specific allergen model (different from FoodSafetyModels.Allergen)
struct NutritionAllergen: Identifiable {
    let id = UUID()
    let name: String
    let severity: NutritionAllergenSeverity
    let sourceIngredient: String?
}

enum NutritionAllergenSeverity: String, CaseIterable {
    case mild = "mild"
    case moderate = "moderate"
    case severe = "severe"
    
    var color: Color {
        switch self {
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        }
    }
}

struct DietaryFlag: Identifiable {
    let id = UUID()
    let name: String
    let type: DietaryFlagType
    let confidence: Double // 0-1
}

enum DietaryFlagType: String, CaseIterable {
    case vegan = "vegan"
    case vegetarian = "vegetarian"
    case glutenFree = "gluten_free"
    case dairyFree = "dairy_free"
    case kosher = "kosher"
    case halal = "halal"
    case organic = "organic"
    case nonGMO = "non_gmo"
}

struct ServingInfo {
    let size: Double
    let unit: String
    let containerServings: Double?
    let description: String
}

// Nutrition-specific ingredient model
struct NutritionIngredient {
    let name: String
    let category: IngredientCategory // Uses FoodSafetyModels.IngredientCategory
    let percentage: Double?
    let allergens: [String]
    let additives: [NutritionFoodAdditive]
    let riskLevel: IngredientRiskLevel // Uses FoodSafetyModels.IngredientRiskLevel
}

struct NutritionFoodAdditive {
    let code: String
    let name: String
    let category: String
    let healthScore: Int
    let childWarning: Bool
}

class NutritionReactionAnalyser {
    static let shared = NutritionReactionAnalyser()
    
    private init() {}
    
    func analysePatterns(reactions: [FoodReaction]) -> NutritionPatternAnalysisResult {
        let ingredientPatterns = identifyIngredientPatterns(reactions: reactions)
        let timePatterns = identifyTimePatterns(reactions: reactions)
        let severityTrends = analyseSeverityTrends(reactions: reactions)
        
        return NutritionPatternAnalysisResult(
            ingredientPatterns: ingredientPatterns,
            timePatterns: timePatterns,
            severityTrends: severityTrends,
            totalReactions: reactions.count
        )
    }
    
    private func identifyIngredientPatterns(reactions: [FoodReaction]) -> [NutritionIngredientPattern] {
        var ingredientCounts: [String: Int] = [:]
        
        for reaction in reactions {
            for ingredient in reaction.suspectedIngredients {
                ingredientCounts[ingredient, default: 0] += 1
            }
        }
        
        return ingredientCounts.compactMap { (ingredient, count) in
            guard count > 1 else { return nil }
            let frequency = Double(count) / Double(reactions.count)
            return NutritionIngredientPattern(
                ingredient: ingredient,
                frequency: frequency,
                occurrences: count,
                averageSeverity: calculateAverageSeverity(for: ingredient, in: reactions)
            )
        }.sorted { $0.frequency > $1.frequency }
    }
    
    private func identifyTimePatterns(reactions: [FoodReaction]) -> [NutritionTimePattern] {
        var patterns: [NutritionTimePattern] = []
        
        // Group reactions by time of day
        let timeGroups = Dictionary(grouping: reactions) { reaction in
            let hour = Calendar.current.component(.hour, from: reaction.timestamp.dateValue())
            return hour
        }
        
        for (hour, groupReactions) in timeGroups {
            if groupReactions.count > 1 {
                patterns.append(NutritionTimePattern(
                    pattern: "\(hour):00",
                    description: "Reactions around \(hour):00",
                    occurrenceCount: groupReactions.count
                ))
            }
        }
        
        // Common meal time patterns
        let morningReactions = reactions.filter { reaction in
            let hour = Calendar.current.component(.hour, from: reaction.timestamp.dateValue())
            return hour >= 6 && hour <= 10
        }
        
        if morningReactions.count > 1 {
            patterns.append(NutritionTimePattern(
                pattern: "morning",
                description: "Morning meal reactions",
                occurrenceCount: morningReactions.count
            ))
        }
        
        let eveningReactions = reactions.filter { reaction in
            let hour = Calendar.current.component(.hour, from: reaction.timestamp.dateValue())
            return hour >= 17 && hour <= 21
        }
        
        if eveningReactions.count > 1 {
            patterns.append(NutritionTimePattern(
                pattern: "evening",
                description: "Evening meal reactions",
                occurrenceCount: eveningReactions.count
            ))
        }
        
        return patterns.sorted { $0.occurrenceCount > $1.occurrenceCount }
    }
    
    private func analyseSeverityTrends(reactions: [FoodReaction]) -> SeverityTrend {
        guard !reactions.isEmpty else {
            return SeverityTrend(
                trend: .stable,
                currentAverage: 0,
                previousAverage: 0,
                changePercentage: 0
            )
        }
        
        let sortedReactions = reactions.sorted { $0.timestamp.dateValue() < $1.timestamp.dateValue() }
        let midpoint = sortedReactions.count / 2
        
        let earlierReactions = Array(sortedReactions[..<midpoint])
        let laterReactions = Array(sortedReactions[midpoint...])
        
        let earlierAverage = earlierReactions.isEmpty ? 0 : Double(earlierReactions.map(\.severity.numericValue).reduce(0, +)) / Double(earlierReactions.count)
        let laterAverage = laterReactions.isEmpty ? 0 : Double(laterReactions.map(\.severity.numericValue).reduce(0, +)) / Double(laterReactions.count)
        
        let changePercentage = earlierAverage == 0 ? 0 : ((laterAverage - earlierAverage) / earlierAverage) * 100
        
        let trend: TrendDirection
        if abs(changePercentage) < 10 {
            trend = .stable
        } else if changePercentage > 0 {
            trend = .increasing
        } else {
            trend = .decreasing
        }
        
        return SeverityTrend(
            trend: trend,
            currentAverage: laterAverage,
            previousAverage: earlierAverage,
            changePercentage: changePercentage
        )
    }
    
    private func calculateAverageSeverity(for ingredient: String, in reactions: [FoodReaction]) -> Double {
        let relevantReactions = reactions.filter { $0.suspectedIngredients.contains(ingredient) }
        guard !relevantReactions.isEmpty else { return 0 }
        
        let totalSeverity = relevantReactions.map(\.severity.numericValue).reduce(0, +)
        return Double(totalSeverity) / Double(relevantReactions.count)
    }
}

// Nutrition-specific pattern analysis result
struct NutritionPatternAnalysisResult {
    let ingredientPatterns: [NutritionIngredientPattern]
    let timePatterns: [NutritionTimePattern]
    let severityTrends: SeverityTrend
    let totalReactions: Int
}

// Nutrition-specific ingredient pattern
struct NutritionIngredientPattern {
    let ingredient: String
    let frequency: Double // 0-1
    let occurrences: Int
    let averageSeverity: Double
}

struct SeverityTrend {
    let trend: TrendDirection
    let currentAverage: Double
    let previousAverage: Double
    let changePercentage: Double
}

enum TrendDirection {
    case increasing
    case decreasing
    case stable
}

// MARK: - Food Reaction Models

struct FoodReaction: Identifiable, Codable {
    var id = UUID()
    let foodName: String
    let foodId: String? // Reference to the food database ID
    let foodBrand: String? // Store brand for better identification
    let timestamp: Timestamp
    let severity: ReactionSeverity // Uses CoreModels.ReactionSeverity
    let symptoms: [String]
    let suspectedIngredients: [String]
    let notes: String?

    init(foodName: String, foodId: String? = nil, foodBrand: String? = nil, timestamp: Timestamp, severity: ReactionSeverity, symptoms: [String], suspectedIngredients: [String], notes: String? = nil) {
        self.foodName = foodName
        self.foodId = foodId
        self.foodBrand = foodBrand
        self.timestamp = timestamp
        self.severity = severity
        self.symptoms = symptoms
        self.suspectedIngredients = suspectedIngredients
        self.notes = notes
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id.uuidString,
            "foodName": foodName,
            "foodIngredients": suspectedIngredients, // Keep old field name for compatibility
            "reactionTime": timestamp, // Already a Timestamp
            "symptoms": symptoms,
            "severity": severity.rawValue,
            "notes": notes ?? "",
            "dateLogged": timestamp // Use same timestamp for both
        ]

        // Add new fields
        if let foodId = foodId {
            dict["foodId"] = foodId
        }
        if let foodBrand = foodBrand {
            dict["foodBrand"] = foodBrand
        }

        return dict
    }

    static func fromDictionary(_ data: [String: Any]) -> FoodReaction? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let foodName = data["foodName"] as? String,
              let foodIngredients = data["foodIngredients"] as? [String],
              let reactionTimeTimestamp = data["reactionTime"] as? Timestamp,
              let symptoms = data["symptoms"] as? [String],
              let severityRaw = data["severity"] as? String,
              let severity = ReactionSeverity(rawValue: severityRaw) else {
            return nil
        }

        let notes = data["notes"] as? String
        let foodId = data["foodId"] as? String
        let foodBrand = data["foodBrand"] as? String

        var reaction = FoodReaction(
            foodName: foodName,
            foodId: foodId,
            foodBrand: foodBrand,
            timestamp: reactionTimeTimestamp,
            severity: severity,
            symptoms: symptoms,
            suspectedIngredients: foodIngredients,
            notes: notes
        )
        reaction.id = id
        return reaction
    }
}

// MARK: - Food Entry Models

struct FoodEntry: Identifiable, Codable {
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

    init(id: String = UUID().uuidString, userId: String, foodName: String, brandName: String? = nil,
         servingSize: Double, servingUnit: String, calories: Double, protein: Double,
         carbohydrates: Double, fat: Double, fiber: Double? = nil, sugar: Double? = nil,
         sodium: Double? = nil, mealType: MealType, date: Date, dateLogged: Date = Date()) {
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
            "fiber": fiber ?? 0.0,
            "sugar": sugar ?? 0.0,
            "sodium": sodium ?? 0.0,
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

        return FoodEntry(
            id: id,
            userId: userId,
            foodName: foodName,
            brandName: data["brandName"] as? String,
            servingSize: servingSize,
            servingUnit: servingUnit,
            calories: calories,
            protein: protein,
            carbohydrates: carbohydrates,
            fat: fat,
            fiber: data["fiber"] as? Double,
            sugar: data["sugar"] as? Double,
            sodium: data["sodium"] as? Double,
            mealType: mealType,
            date: dateTimestamp.dateValue(),
            dateLogged: dateLoggedTimestamp.dateValue()
        )
    }
}

// MARK: - Food Diary Models

struct FoodDiaryEntry: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let meals: [MealEntry]
    let totalNutrition: DayNutritionSummary
    let waterIntake: Double // liters
    let notes: String?
    
    init(date: Date, meals: [MealEntry], totalNutrition: DayNutritionSummary, waterIntake: Double = 0, notes: String? = nil) {
        self.date = date
        self.meals = meals
        self.totalNutrition = totalNutrition
        self.waterIntake = waterIntake
        self.notes = notes
    }
}

struct MealEntry: Identifiable, Codable {
    var id = UUID()
    let type: MealType
    let timestamp: Date
    let foods: [DiaryFoodItem]
    let totalCalories: Int
    
    init(type: MealType, timestamp: Date, foods: [DiaryFoodItem], totalCalories: Int) {
        self.type = type
        self.timestamp = timestamp
        self.foods = foods
        self.totalCalories = totalCalories
    }
}

struct DayNutritionSummary: Codable {
    let totalCalories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sodium: Double
    let sugar: Double
    let saturatedFat: Double
}

// MARK: - Goal Tracking Models

struct NutritionGoals: Codable {
    let dailyCalories: Double
    let proteinPercentage: Double // % of calories
    let carbPercentage: Double // % of calories
    let fatPercentage: Double // % of calories
    let fiberGrams: Double
    let sodiumLimit: Double // mg
    let sugarLimit: Double // grams
    let waterGoal: Double // liters
}

struct GoalProgress {
    let goal: Double
    let current: Double
    let percentage: Double
    let isExceeded: Bool
    
    init(goal: Double, current: Double) {
        self.goal = goal
        self.current = current
        self.percentage = goal > 0 ? (current / goal) * 100 : 0
        self.isExceeded = current > goal
    }
}

// MARK: - Food Serving Models

struct FoodServingOption {
    let id = UUID()
    let name: String
    let unit: String
    let grams: Double
    let isCommon: Bool
}

struct FoodPortion {
    let servingOption: FoodServingOption
    let quantity: Double
    let totalGrams: Double
    
    var description: String {
        return "\(quantity) \(servingOption.name) (\(totalGrams)g)"
    }
}

// MARK: - Nutrition Label Models

struct NutritionLabel {
    let servingSize: String
    let servingsPerContainer: Double?
    let calories: Double
    let caloriesFromFat: Double?
    let totalFat: NutrientAmount
    let saturatedFat: NutrientAmount
    let transFat: NutrientAmount
    let cholesterol: NutrientAmount
    let sodium: NutrientAmount
    let totalCarbs: NutrientAmount
    let dietaryFiber: NutrientAmount
    let sugars: NutrientAmount
    let addedSugars: NutrientAmount?
    let protein: NutrientAmount
    let vitamins: [NutrientAmount]
    let minerals: [NutrientAmount]
    let additionalNutrients: [NutrientAmount]
}

struct NutrientAmount {
    let name: String
    let amount: Double
    let unit: String
    let dailyValuePercentage: Double?
}

// MARK: - Food Diary Item Models

struct DiaryFoodItem: Identifiable, Equatable, Codable {
    var id = UUID()
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let servingDescription: String
    let quantity: Double
    let time: String?
    let processedScore: String?
    let sugarLevel: String?
    let ingredients: [String]?
    let additives: [NutritionAdditiveInfo]?

    init(id: UUID = UUID(), name: String, calories: Int, protein: Double, carbs: Double, fat: Double, servingDescription: String = "100g serving", quantity: Double = 1.0, time: String? = nil, processedScore: String? = nil, sugarLevel: String? = nil, ingredients: [String]? = nil, additives: [NutritionAdditiveInfo]? = nil) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servingDescription = servingDescription
        self.quantity = quantity
        self.time = time
        self.processedScore = processedScore
        self.sugarLevel = sugarLevel
        self.ingredients = ingredients
        self.additives = additives
    }

    static func == (lhs: DiaryFoodItem, rhs: DiaryFoodItem) -> Bool {
        return lhs.id == rhs.id
    }

    // Convert DiaryFoodItem back to FoodSearchResult for full feature access
    func toFoodSearchResult() -> FoodSearchResult {
        return FoodSearchResult(
            id: self.id.uuidString,
            name: self.name,
            brand: nil,
            calories: Double(self.calories),
            protein: self.protein,
            carbs: self.carbs,
            fat: self.fat,
            fiber: 0, // Default values for missing data
            sugar: 0,
            sodium: 0,
            servingDescription: self.servingDescription,
            ingredients: self.ingredients,
            confidence: 1.0, // High confidence for saved items
            isVerified: true,
            additives: self.additives,
            processingScore: nil,
            processingGrade: self.processedScore,
            processingLabel: self.processedScore
        )
    }
}

// MARK: - Micronutrient Profile Models

struct MicronutrientProfile: Codable {
    let vitamins: [String: Double]
    let minerals: [String: Double]
    let recommendedIntakes: RecommendedIntakes
    let confidenceScore: MicronutrientConfidence
}

struct VitaminProfile: Codable {
    let vitaminA: Double // mcg RAE
    let vitaminC: Double // mg
    let vitaminD: Double // mcg
    let vitaminE: Double // mg
    let vitaminK: Double // mcg
    let thiamine: Double // mg (B1)
    let riboflavin: Double // mg (B2)
    let niacin: Double // mg (B3)
    let pantothenicAcid: Double // mg (B5)
    let vitaminB6: Double // mg
    let biotin: Double // mcg (B7)
    let folate: Double // mcg (B9)
    let vitaminB12: Double // mcg
    let choline: Double // mg
}

struct MineralProfile: Codable {
    let calcium: Double // mg
    let iron: Double // mg
    let magnesium: Double // mg
    let phosphorus: Double // mg
    let potassium: Double // mg
    let sodium: Double // mg
    let zinc: Double // mg
    let copper: Double // mg
    let manganese: Double // mg
    let selenium: Double // mcg
    let chromium: Double // mcg
    let molybdenum: Double // mcg
    let iodine: Double // mcg
}

struct RecommendedIntakes: Codable {
    let age: Int
    let gender: Gender
    let dailyValues: [String: Double]
}

enum Gender: String, CaseIterable, Codable {
    case male = "male"
    case female = "female"
    case other = "other"
}

enum MicronutrientConfidence: String, CaseIterable, Codable {
    case high = "high"
    case medium = "medium"
    case low = "low"
    case estimated = "estimated"

    var color: Color {
        switch self {
        case .high: return .green
        case .medium: return .orange
        case .low: return .red
        case .estimated: return .blue
        }
    }

    var description: String {
        switch self {
        case .high: return "High confidence - based on verified nutritional data"
        case .medium: return "Medium confidence - based on similar foods"
        case .low: return "Low confidence - estimated values"
        case .estimated: return "Estimated - calculated approximation"
        }
    }
}

// MARK: - Micronutrient Manager

class MicronutrientManager: ObservableObject {
    static let shared = MicronutrientManager()

    private init() {}

    @Published var currentProfile: MicronutrientProfile?

    func getMicronutrientProfile(for food: FoodSearchResult, quantity: Double = 1.0) -> MicronutrientProfile {
        // Create a basic micronutrient profile - this would be enhanced with real data
        let basicVitamins: [String: Double] = [
            "vitaminA": food.protein * 2.5 * quantity,
            "vitaminC": food.carbs * 0.8 * quantity,
            "vitaminD": food.fat * 0.4 * quantity,
            "vitaminE": food.fat * 0.6 * quantity,
            "vitaminK": food.fiber * 1.2 * quantity,
            "thiamine": food.protein * 0.3 * quantity,
            "riboflavin": food.protein * 0.35 * quantity,
            "niacin": food.protein * 0.8 * quantity,
            "pantothenicAcid": food.protein * 0.25 * quantity,
            "vitaminB6": food.protein * 0.4 * quantity,
            "biotin": food.protein * 0.05 * quantity,
            "folate": food.carbs * 0.6 * quantity,
            "vitaminB12": food.protein * 0.15 * quantity,
            "choline": food.protein * 2.1 * quantity
        ]

        let basicMinerals: [String: Double] = [
            "calcium": food.protein * 8.0 * quantity,
            "iron": food.protein * 1.2 * quantity,
            "magnesium": food.carbs * 2.4 * quantity,
            "phosphorus": food.protein * 6.5 * quantity,
            "potassium": food.carbs * 15.0 * quantity,
            "sodium": food.sodium * quantity,
            "zinc": food.protein * 0.8 * quantity,
            "copper": food.protein * 0.08 * quantity,
            "manganese": food.carbs * 0.12 * quantity,
            "selenium": food.protein * 0.5 * quantity,
            "chromium": food.carbs * 0.02 * quantity,
            "molybdenum": food.protein * 0.03 * quantity,
            "iodine": food.protein * 0.1 * quantity
        ]

        let recommendedIntakes = RecommendedIntakes(
            age: 30,
            gender: .other,
            dailyValues: [
                "vitamin_c": 90.0,
                "calcium": 1000.0,
                "iron": 18.0,
                "protein": 50.0
            ]
        )

        return MicronutrientProfile(
            vitamins: basicVitamins,
            minerals: basicMinerals,
            recommendedIntakes: recommendedIntakes,
            confidenceScore: .estimated
        )
    }

    func updateCurrentProfile(_ profile: MicronutrientProfile) {
        DispatchQueue.main.async {
            self.currentProfile = profile
        }
    }
}

// MARK: - Daily Nutrition Tracking Models

struct DailyNutrition {
    let calories: NutrientTarget
    let protein: NutrientTarget
    let carbs: NutrientTarget
    let fat: NutrientTarget
    let fiber: NutrientTarget
    let sodium: NutrientTarget
    let sugar: NutrientTarget
}

struct NutrientTarget {
    let current: Double
    let target: Double

    var percentage: Double {
        guard target > 0 else { return 0 }
        return (current / target) * 100
    }

    var isExceeded: Bool {
        return current > target
    }

    var remaining: Double {
        return max(0, target - current)
    }
}

// MARK: - Nutrition Tracking Models

struct NutritionTracker {
    private let goals: NutritionGoals
    
    init(goals: NutritionGoals) {
        self.goals = goals
    }
    
    func calculateProgress(for summary: DayNutritionSummary) -> [String: GoalProgress] {
        return [
            "calories": GoalProgress(goal: goals.dailyCalories, current: summary.totalCalories),
            "protein": GoalProgress(goal: (goals.dailyCalories * goals.proteinPercentage / 100) / 4, current: summary.protein),
            "carbs": GoalProgress(goal: (goals.dailyCalories * goals.carbPercentage / 100) / 4, current: summary.carbs),
            "fat": GoalProgress(goal: (goals.dailyCalories * goals.fatPercentage / 100) / 9, current: summary.fat),
            "fiber": GoalProgress(goal: goals.fiberGrams, current: summary.fiber),
            "sodium": GoalProgress(goal: goals.sodiumLimit, current: summary.sodium),
            "sugar": GoalProgress(goal: goals.sugarLimit, current: summary.sugar)
        ]
    }
}

// MARK: - Nutrition Analysis Extensions

extension NutritionProfile {
    var healthScore: Double {
        return nutritionScore.overallScore
    }
    
    var isHighProtein: Bool {
        return macronutrients.protein > 20 // grams per 100g
    }
    
    var isLowSodium: Bool {
        return macronutrients.sodium < 140 // mg per 100g
    }
    
    var isHighFiber: Bool {
        return macronutrients.fiber > 6 // grams per 100g
    }
}

extension MicronutrientProfile {
    func getDailyValuePercentage(for nutrient: String, amount: Double) -> Double? {
        guard let recommendedAmount = recommendedIntakes.dailyValues[nutrient] else { return nil }
        return (amount / recommendedAmount) * 100
    }
    
    var vitaminAdequacy: Double {
        let vitaminKeys = ["vitaminA", "vitaminC", "vitaminD", "vitaminE", "vitaminK", "thiamine", "riboflavin", "niacin", "pantothenicAcid", "vitaminB6", "biotin", "folate", "vitaminB12", "choline"]

        let adequateVitamins = vitaminKeys.compactMap { vitamins[$0] }.filter { $0 > 0 }
        return Double(adequateVitamins.count) / Double(vitaminKeys.count) * 100
    }
    
    var mineralAdequacy: Double {
        let mineralKeys = ["calcium", "iron", "magnesium", "phosphorus", "potassium", "zinc", "copper", "manganese", "selenium", "chromium", "molybdenum", "iodine"]

        let adequateMinerals = mineralKeys.compactMap { minerals[$0] }.filter { $0 > 0 }
        return Double(adequateMinerals.count) / Double(mineralKeys.count) * 100
    }
}