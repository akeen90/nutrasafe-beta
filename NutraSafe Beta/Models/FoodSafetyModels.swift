//
//  FoodSafetyModels.swift
//  NutraSafe Beta
//
//  Domain models for FoodSafety
//

import Foundation
import SwiftUI
import FirebaseFirestore

// MARK: - Placeholder Types for Build Compatibility

struct SuspiciousFood {
    let id = UUID()
    let name: String
    let reason: String
    let flagged: Bool
}

struct Ingredient {
    let id = UUID()
    let name: String
    let category: IngredientCategory
    let allergens: [Allergen]
    let micronutrients: [Micronutrient]
    let additives: [FoodAdditive]
    let riskLevel: IngredientRiskLevel

    init(name: String, category: IngredientCategory, allergens: [Allergen] = [], micronutrients: [Micronutrient] = [], additives: [FoodAdditive] = [], riskLevel: IngredientRiskLevel = .unknown) {
        self.name = name
        self.category = category
        self.allergens = allergens
        self.micronutrients = micronutrients
        self.additives = additives
        self.riskLevel = riskLevel
    }
}

enum MicronutrientType: String, CaseIterable {
    case vitamin = "vitamin"
    case mineral = "mineral"
    case other = "other"
}

struct Micronutrient {
    let id = UUID()
    let name: String
    let type: MicronutrientType
    let amount: Double
    let unit: String
    let dailyValuePercentage: Double?
    let benefits: [String]
    let deficiencyRisks: [String]

    init(name: String, type: MicronutrientType, amount: Double, unit: String, dailyValuePercentage: Double? = nil, benefits: [String] = [], deficiencyRisks: [String] = []) {
        self.name = name
        self.type = type
        self.amount = amount
        self.unit = unit
        self.dailyValuePercentage = dailyValuePercentage
        self.benefits = benefits
        self.deficiencyRisks = deficiencyRisks
    }
}

struct FoodAdditive {
    let id = UUID()
    let name: String
    let code: String
    let purpose: AdditivePurpose
    let safetyRating: AdditiveRating
    let commonNames: [String]
    let potentialEffects: [String]

    init(name: String, code: String, purpose: AdditivePurpose, safetyRating: AdditiveRating, commonNames: [String] = [], potentialEffects: [String] = []) {
        self.name = name
        self.code = code
        self.purpose = purpose
        self.safetyRating = safetyRating
        self.commonNames = commonNames
        self.potentialEffects = potentialEffects
    }
}

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

struct IngredientPattern {
    let ingredient: String
    let occurrenceCount: Int
    let averageSeverity: ReactionSeverity
    let confidence: Double
}

struct PatternAnalysisResult {
    let suspiciousFoods: [SuspiciousFood]
    let commonIngredients: [IngredientPattern]
    let timePatterns: [TimePattern]
    let recommendations: [String]
    let confidence: Double
}

struct TimePattern {
    let pattern: String
    let description: String
    let occurrenceCount: Int
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

// MARK: - Safe Food Models

struct SafeFood: Identifiable, Codable {
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
            "dateAdded": FirebaseFirestore.Timestamp(date: dateAdded)
        ]
    }

    static func fromDictionary(_ data: [String: Any]) -> SafeFood? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let userId = data["userId"] as? String,
              let name = data["name"] as? String,
              let dateAddedTimestamp = data["dateAdded"] as? FirebaseFirestore.Timestamp else {
            return nil
        }

        let notes = data["notes"] as? String

        var safeFood = SafeFood(userId: userId, name: name, notes: notes)
        // We need to manually set the id and dateAdded since init() generates new ones
        return SafeFood(userId: userId, name: name, notes: notes)
    }
}

// MARK: - Pending Food Verification Models

struct PendingFoodVerification: Identifiable, Codable {
    let id: String
    let foodName: String
    let brandName: String?
    let ingredients: String?
    let submittedAt: Date
    let status: VerificationStatus
    let userId: String

    enum VerificationStatus: String, Codable, CaseIterable {
        case pending = "pending"
        case approved = "approved"
        case rejected = "rejected"
    }

    init(id: String = UUID().uuidString, foodName: String, brandName: String? = nil,
         ingredients: String? = nil, userId: String) {
        self.id = id
        self.foodName = foodName
        self.brandName = brandName
        self.ingredients = ingredients
        self.submittedAt = Date()
        self.status = .pending
        self.userId = userId
    }
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
        
        // COMPREHENSIVE MICRONUTRIENT MAPPINGS
        
        // FORTIFIED WHEAT FLOUR - UK law requires fortification
        if ingredient.contains("wheat flour") || ingredient.contains("flour") {
            // UK fortified flour contains iron, niacin, thiamin, and calcium carbonate
            micronutrients.append(Micronutrient(
                name: "Iron", type: .mineral, amount: 1.65, unit: "mg", dailyValuePercentage: 9,
                benefits: ["Oxygen transport", "Energy production"], deficiencyRisks: ["Anemia", "Fatigue"]
            ))
            micronutrients.append(Micronutrient(
                name: "Niacin", type: .vitamin, amount: 1.6, unit: "mg", dailyValuePercentage: 10,
                benefits: ["Energy metabolism", "Nervous system"], deficiencyRisks: ["Pellagra", "Fatigue"]
            ))
            micronutrients.append(Micronutrient(
                name: "Thiamine", type: .vitamin, amount: 0.24, unit: "mg", dailyValuePercentage: 20,
                benefits: ["Energy metabolism", "Nerve function"], deficiencyRisks: ["Beriberi", "Neurological issues"]
            ))
            if ingredient.contains("calcium carbonate") {
                micronutrients.append(Micronutrient(
                    name: "Calcium", type: .mineral, amount: 150, unit: "mg", dailyValuePercentage: 15,
                    benefits: ["Bone health", "Muscle function"], deficiencyRisks: ["Osteoporosis", "Muscle cramps"]
                ))
            }
        }
        
        // CALCIUM CARBONATE as separate ingredient
        if ingredient.contains("calcium carbonate") || ingredient == "calcium carbonate" {
            micronutrients.append(Micronutrient(
                name: "Calcium", type: .mineral, amount: 400, unit: "mg", dailyValuePercentage: 40,
                benefits: ["Bone health", "Muscle function"], deficiencyRisks: ["Osteoporosis", "Muscle cramps"]
            ))
        }
        
        // INDIVIDUAL VITAMIN AND MINERAL INGREDIENTS (from fortification)
        if ingredient == "iron" || ingredient.contains("iron") {
            micronutrients.append(Micronutrient(
                name: "Iron", type: .mineral, amount: 1.65, unit: "mg", dailyValuePercentage: 9,
                benefits: ["Oxygen transport", "Energy production"], deficiencyRisks: ["Anemia", "Fatigue"]
            ))
        }
        
        if ingredient == "niacin" || ingredient.contains("niacin") {
            micronutrients.append(Micronutrient(
                name: "Niacin", type: .vitamin, amount: 1.6, unit: "mg", dailyValuePercentage: 10,
                benefits: ["Energy metabolism", "Nervous system"], deficiencyRisks: ["Pellagra", "Fatigue"]
            ))
        }
        
        if ingredient == "thiamin" || ingredient.contains("thiamin") || ingredient == "thiamine" || ingredient.contains("thiamine") {
            micronutrients.append(Micronutrient(
                name: "Thiamine", type: .vitamin, amount: 0.24, unit: "mg", dailyValuePercentage: 20,
                benefits: ["Energy metabolism", "Nerve function"], deficiencyRisks: ["Beriberi", "Neurological issues"]
            ))
        }
        
        if ingredient == "folate" || ingredient.contains("folate") || ingredient == "folic acid" || ingredient.contains("folic acid") {
            micronutrients.append(Micronutrient(
                name: "Folate", type: .vitamin, amount: 40, unit: "mcg", dailyValuePercentage: 10,
                benefits: ["Cell division", "DNA synthesis"], deficiencyRisks: ["Anemia", "Birth defects"]
            ))
        }
        
        if ingredient == "riboflavin" || ingredient.contains("riboflavin") || ingredient == "vitamin b2" || ingredient.contains("vitamin b2") {
            micronutrients.append(Micronutrient(
                name: "Riboflavin", type: .vitamin, amount: 0.16, unit: "mg", dailyValuePercentage: 12,
                benefits: ["Energy metabolism", "Cell function"], deficiencyRisks: ["Skin problems", "Eye issues"]
            ))
        }
        
        // DAIRY PRODUCTS - comprehensive vitamin profile
        if ingredient.contains("milk") || ingredient.contains("dairy") || ingredient.contains("cheese") || 
           ingredient.contains("cheddar") || ingredient.contains("cream") || ingredient.contains("butter") {
            micronutrients.append(Micronutrient(
                name: "Calcium", type: .mineral, amount: 120, unit: "mg", dailyValuePercentage: 12,
                benefits: ["Bone health", "Muscle function"], deficiencyRisks: ["Osteoporosis", "Muscle cramps"]
            ))
            micronutrients.append(Micronutrient(
                name: "Vitamin B12", type: .vitamin, amount: 0.4, unit: "mcg", dailyValuePercentage: 17,
                benefits: ["Red blood cell formation", "Nervous system"], deficiencyRisks: ["Pernicious anemia", "Nerve damage"]
            ))
            micronutrients.append(Micronutrient(
                name: "Riboflavin", type: .vitamin, amount: 0.17, unit: "mg", dailyValuePercentage: 13,
                benefits: ["Energy metabolism", "Cell function"], deficiencyRisks: ["Skin problems", "Eye issues"]
            ))
            micronutrients.append(Micronutrient(
                name: "Vitamin A", type: .vitamin, amount: 47, unit: "mcg", dailyValuePercentage: 5,
                benefits: ["Vision", "Immune function"], deficiencyRisks: ["Night blindness", "Immune deficiency"]
            ))
            micronutrients.append(Micronutrient(
                name: "Phosphorus", type: .mineral, amount: 93, unit: "mg", dailyValuePercentage: 13,
                benefits: ["Bone health", "Energy storage"], deficiencyRisks: ["Weak bones", "Muscle weakness"]
            ))
            // Vitamin D in fortified dairy products
            micronutrients.append(Micronutrient(
                name: "Vitamin D", type: .vitamin, amount: 0.03, unit: "mcg", dailyValuePercentage: 1,
                benefits: ["Bone health", "Immune function"], deficiencyRisks: ["Rickets", "Bone weakness"]
            ))
        }
        
        // MEAT PRODUCTS - beef and pork
        if ingredient.contains("beef") || ingredient.contains("pork") || ingredient.contains("bacon") || ingredient.contains("meat") {
            micronutrients.append(Micronutrient(
                name: "Iron", type: .mineral, amount: 2.6, unit: "mg", dailyValuePercentage: 14,
                benefits: ["Oxygen transport", "Energy production"], deficiencyRisks: ["Anemia", "Fatigue"]
            ))
            micronutrients.append(Micronutrient(
                name: "Zinc", type: .mineral, amount: 4.8, unit: "mg", dailyValuePercentage: 44,
                benefits: ["Immune function", "Wound healing"], deficiencyRisks: ["Immune deficiency", "Poor wound healing"]
            ))
            micronutrients.append(Micronutrient(
                name: "Vitamin B6", type: .vitamin, amount: 0.4, unit: "mg", dailyValuePercentage: 24,
                benefits: ["Protein metabolism", "Brain function"], deficiencyRisks: ["Skin problems", "Anemia"]
            ))
            micronutrients.append(Micronutrient(
                name: "Vitamin B12", type: .vitamin, amount: 2.6, unit: "mcg", dailyValuePercentage: 108,
                benefits: ["Red blood cell formation", "Nervous system"], deficiencyRisks: ["Pernicious anemia", "Nerve damage"]
            ))
            micronutrients.append(Micronutrient(
                name: "Phosphorus", type: .mineral, amount: 200, unit: "mg", dailyValuePercentage: 20,
                benefits: ["Bone health", "Energy storage"], deficiencyRisks: ["Weak bones", "Muscle weakness"]
            ))
            micronutrients.append(Micronutrient(
                name: "Niacin", type: .vitamin, amount: 5.8, unit: "mg", dailyValuePercentage: 36,
                benefits: ["Energy metabolism", "Nervous system"], deficiencyRisks: ["Pellagra", "Fatigue"]
            ))
        }
        
        // TOMATOES and TOMATO PRODUCTS
        if ingredient.contains("tomato") {
            micronutrients.append(Micronutrient(
                name: "Vitamin C", type: .vitamin, amount: 13.7, unit: "mg", dailyValuePercentage: 15,
                benefits: ["Immune support", "Antioxidant"], deficiencyRisks: ["Scurvy", "Impaired wound healing"]
            ))
            micronutrients.append(Micronutrient(
                name: "Potassium", type: .mineral, amount: 237, unit: "mg", dailyValuePercentage: 5,
                benefits: ["Heart health", "Blood pressure"], deficiencyRisks: ["High blood pressure", "Muscle cramps"]
            ))
            micronutrients.append(Micronutrient(
                name: "Folate", type: .vitamin, amount: 15, unit: "mcg", dailyValuePercentage: 4,
                benefits: ["Cell division", "DNA synthesis"], deficiencyRisks: ["Anemia", "Birth defects"]
            ))
        }
        
        // CARROTS
        if ingredient.contains("carrot") {
            micronutrients.append(Micronutrient(
                name: "Vitamin A", type: .vitamin, amount: 835, unit: "mcg", dailyValuePercentage: 93,
                benefits: ["Vision", "Immune function"], deficiencyRisks: ["Night blindness", "Immune deficiency"]
            ))
            micronutrients.append(Micronutrient(
                name: "Vitamin K", type: .vitamin, amount: 13.2, unit: "mcg", dailyValuePercentage: 11,
                benefits: ["Blood clotting", "Bone health"], deficiencyRisks: ["Bleeding disorders", "Weak bones"]
            ))
        }
        
        // ONIONS
        if ingredient.contains("onion") {
            micronutrients.append(Micronutrient(
                name: "Vitamin C", type: .vitamin, amount: 7.4, unit: "mg", dailyValuePercentage: 8,
                benefits: ["Immune support", "Antioxidant"], deficiencyRisks: ["Scurvy", "Impaired wound healing"]
            ))
            micronutrients.append(Micronutrient(
                name: "Folate", type: .vitamin, amount: 19, unit: "mcg", dailyValuePercentage: 5,
                benefits: ["Cell division", "DNA synthesis"], deficiencyRisks: ["Anemia", "Birth defects"]
            ))
        }
        
        // CELERY
        if ingredient.contains("celery") {
            micronutrients.append(Micronutrient(
                name: "Vitamin K", type: .vitamin, amount: 29.3, unit: "mcg", dailyValuePercentage: 24,
                benefits: ["Blood clotting", "Bone health"], deficiencyRisks: ["Bleeding disorders", "Weak bones"]
            ))
        }
        
        // EGGS
        if ingredient.contains("egg") {
            micronutrients.append(Micronutrient(
                name: "Vitamin B12", type: .vitamin, amount: 0.9, unit: "mcg", dailyValuePercentage: 38,
                benefits: ["Red blood cell formation", "Nervous system"], deficiencyRisks: ["Pernicious anemia", "Nerve damage"]
            ))
            micronutrients.append(Micronutrient(
                name: "Vitamin D", type: .vitamin, amount: 2, unit: "mcg", dailyValuePercentage: 10,
                benefits: ["Bone health", "Immune function"], deficiencyRisks: ["Rickets", "Bone weakness"]
            ))
            micronutrients.append(Micronutrient(
                name: "Riboflavin", type: .vitamin, amount: 0.457, unit: "mg", dailyValuePercentage: 35,
                benefits: ["Energy metabolism", "Cell function"], deficiencyRisks: ["Skin problems", "Eye issues"]
            ))
            micronutrients.append(Micronutrient(
                name: "Phosphorus", type: .mineral, amount: 198, unit: "mg", dailyValuePercentage: 20,
                benefits: ["Bone health", "Energy storage"], deficiencyRisks: ["Weak bones", "Muscle weakness"]
            ))
        }
        
        // LEAFY GREENS
        if ingredient.contains("spinach") || ingredient.contains("kale") {
            micronutrients.append(Micronutrient(
                name: "Iron", type: .mineral, amount: 2.7, unit: "mg", dailyValuePercentage: 15,
                benefits: ["Oxygen transport", "Energy production"], deficiencyRisks: ["Anemia", "Fatigue"]
            ))
            micronutrients.append(Micronutrient(
                name: "Vitamin K", type: .vitamin, amount: 483, unit: "mcg", dailyValuePercentage: 402,
                benefits: ["Blood clotting", "Bone health"], deficiencyRisks: ["Bleeding disorders", "Weak bones"]
            ))
            micronutrients.append(Micronutrient(
                name: "Folate", type: .vitamin, amount: 194, unit: "mcg", dailyValuePercentage: 49,
                benefits: ["Cell division", "DNA synthesis"], deficiencyRisks: ["Anemia", "Birth defects"]
            ))
        }
        
        // CITRUS FRUITS
        if ingredient.contains("orange") || ingredient.contains("citrus") {
            micronutrients.append(Micronutrient(
                name: "Vitamin C", type: .vitamin, amount: 53, unit: "mg", dailyValuePercentage: 59,
                benefits: ["Immune support", "Antioxidant", "Collagen synthesis"], deficiencyRisks: ["Scurvy", "Impaired wound healing"]
            ))
        }
        
        // FISH
        if ingredient.contains("fish") || ingredient.contains("salmon") {
            micronutrients.append(Micronutrient(
                name: "Vitamin D", type: .vitamin, amount: 11, unit: "mcg", dailyValuePercentage: 44,
                benefits: ["Bone health", "Immune function"], deficiencyRisks: ["Rickets", "Bone weakness"]
            ))
            micronutrients.append(Micronutrient(
                name: "Vitamin B12", type: .vitamin, amount: 4.8, unit: "mcg", dailyValuePercentage: 200,
                benefits: ["Red blood cell formation", "Nervous system"], deficiencyRisks: ["Pernicious anemia", "Nerve damage"]
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

struct AdditiveInfo: Codable, Identifiable {
    let id: String
    let eNumber: String
    let name: String
    let group: AdditiveGroup
    let isPermittedGB: Bool
    let isPermittedNI: Bool
    let isPermittedEU: Bool
    let statusNotes: String?
    let hasChildWarning: Bool
    let hasPKUWarning: Bool
    let hasPolyolsWarning: Bool
    let hasSulphitesAllergenLabel: Bool
    let category: AdditiveCategory
    let origin: AdditiveOrigin
    let overview: String
    let typicalUses: String
    let effectsSummary: String
    let effectsVerdict: AdditiveVerdict
    let synonyms: [String]
    let insNumber: String?
    let sources: [AdditiveSource]
    let consumerInfo: String?

    init(id: String, eNumber: String, name: String, group: AdditiveGroup, isPermittedGB: Bool = true, isPermittedNI: Bool = true, isPermittedEU: Bool = true, statusNotes: String? = nil, hasChildWarning: Bool = false, hasPKUWarning: Bool = false, hasPolyolsWarning: Bool = false, hasSulphitesAllergenLabel: Bool = false, category: AdditiveCategory = .other, origin: AdditiveOrigin = .synthetic, overview: String = "", typicalUses: String = "", effectsSummary: String = "", effectsVerdict: AdditiveVerdict = .neutral, synonyms: [String] = [], insNumber: String? = nil, sources: [AdditiveSource] = [], consumerInfo: String? = nil) {
        self.id = id
        self.eNumber = eNumber
        self.name = name
        self.group = group
        self.isPermittedGB = isPermittedGB
        self.isPermittedNI = isPermittedNI
        self.isPermittedEU = isPermittedEU
        self.statusNotes = statusNotes
        self.hasChildWarning = hasChildWarning
        self.hasPKUWarning = hasPKUWarning
        self.hasPolyolsWarning = hasPolyolsWarning
        self.hasSulphitesAllergenLabel = hasSulphitesAllergenLabel
        self.category = category
        self.origin = origin
        self.overview = overview
        self.typicalUses = typicalUses
        self.effectsSummary = effectsSummary
        self.effectsVerdict = effectsVerdict
        self.synonyms = synonyms
        self.insNumber = insNumber
        self.sources = sources
        self.consumerInfo = consumerInfo
    }
}

struct AdditiveAnalysis {
    let eNumbers: [String]
    let additives: [String]
    let preservatives: [String]
    let goodAdditives: [String]
    let comprehensiveAdditives: [AdditiveInfo]
    let totalHealthScore: Int
    let worstVerdict: String
    let hasChildWarnings: Bool
    let hasAllergenWarnings: Bool
}

enum AdditiveGroup: String, Codable, CaseIterable {
    case colour = "colour"
    case preservative = "preservative"
    case antioxidant = "antioxidant"
    case emulsifier = "emulsifier"
    case stabilizer = "stabilizer"
    case thickener = "thickener"
    case sweetener = "sweetener"
    case flavourEnhancer = "flavour_enhancer"
    case acidRegulator = "acid_regulator"
    case anticaking = "anticaking"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .colour: return "Colour"
        case .preservative: return "Preservative"
        case .antioxidant: return "Antioxidant"
        case .emulsifier: return "Emulsifier"
        case .stabilizer: return "Stabilizer"
        case .thickener: return "Thickener"
        case .sweetener: return "Sweetener"
        case .flavourEnhancer: return "Flavour Enhancer"
        case .acidRegulator: return "Acid Regulator"
        case .anticaking: return "Anti-Caking Agent"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .colour: return "🎨"
        case .preservative: return "🛡️"
        case .antioxidant: return "⚗️"
        case .emulsifier: return "🫧"
        case .stabilizer: return "⚖️"
        case .thickener: return "🥄"
        case .sweetener: return "🍯"
        case .flavourEnhancer: return "✨"
        case .acidRegulator: return "🧪"
        case .anticaking: return "🧂"
        case .other: return "📦"
        }
    }
}

enum AdditiveCategory: String, Codable {
    case colour = "colour"
    case preservative = "preservative"
    case other = "other"
}

enum AdditiveOrigin: String, Codable {
    case synthetic = "synthetic"
    case plant = "plant"
    case animal = "animal"
    case mineral = "mineral"
    case syntheticPlantMineral = "synthetic/plant/mineral (varies by specification)"
    
    var displayName: String {
        switch self {
        case .synthetic: return "Synthetic"
        case .plant: return "Plant-based"
        case .animal: return "Animal-based"
        case .mineral: return "Mineral"
        case .syntheticPlantMineral: return "Various sources"
        }
    }
    
    var icon: String {
        switch self {
        case .synthetic: return "⚗️"
        case .plant: return "🌱"
        case .animal: return "🐄"
        case .mineral: return "⛰️"
        case .syntheticPlantMineral: return "🔄"
        }
    }
}

enum AdditiveVerdict: String, Codable {
    case neutral = "neutral"
    case caution = "caution"
    case avoid = "avoid"
    
    var color: Color {
        switch self {
        case .neutral: return .green
        case .caution: return .orange
        case .avoid: return .red
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .neutral: return .green.opacity(0.1)
        case .caution: return .orange.opacity(0.1)
        case .avoid: return .red.opacity(0.1)
        }
    }
}

struct AdditiveSource: Codable {
    let title: String
    let url: String
}

struct AdditiveDetectionResult {
    let detectedAdditives: [AdditiveInfo]
    let childWarnings: [AdditiveInfo]
    let hasChildConcernAdditives: Bool
    let analysisConfidence: Double
    let processingScore: ProcessingAnalysisResult?
    let comprehensiveWarnings: AdditiveWarningsResult?
    
    var childWarningMessage: String? {
        if hasChildConcernAdditives {
            let count = childWarnings.count
            let names = childWarnings.map { $0.name }.joined(separator: ", ")
            return "Contains \(count) additive\(count == 1 ? "" : "s") that may affect children's activity and attention: \(names)"
        }
        return nil
    }
}

struct ProcessingAnalysisResult {
    let score: Int
    let grade: String
    let label: String
    let breakdown: [String: ProcessingCategoryBreakdown]
}

struct AdditiveWarningsResult {
    let childWarnings: [String]
    let pkuWarnings: [String] 
    let sulphiteWarnings: [String]
    let polyolWarnings: [String]
    let regulatoryWarnings: [String]
    let hasRedFlags: Bool
    let overallRisk: String
    let riskExplanation: String
    
    var hasAnyWarnings: Bool {
        return !childWarnings.isEmpty || !pkuWarnings.isEmpty || 
               !sulphiteWarnings.isEmpty || !polyolWarnings.isEmpty || 
               !regulatoryWarnings.isEmpty || hasRedFlags
    }
    
    var totalWarningCount: Int {
        return childWarnings.count + pkuWarnings.count + sulphiteWarnings.count + 
               polyolWarnings.count + regulatoryWarnings.count + (hasRedFlags ? 1 : 0)
    }
}

class AdditiveWatchService {
    static let shared = AdditiveWatchService()
    private var additiveDatabase: [AdditiveInfo] = []
    private var isLoaded = false
    
    private init() {
        loadAdditiveDatabase()
    }
    
    private func loadAdditiveDatabase() {
        guard let url = Bundle.main.url(forResource: "additives_full_described_with_sources_2025", withExtension: "csv") else {
            print("❌ Could not find additive database CSV file")
            return
        }
        
        do {
            let content = try String(contentsOf: url)
            print("📄 CSV content length: \(content.count) characters")
            additiveDatabase = parseCSV(content)
            isLoaded = true
            print("✅✅✅ ADDITIVE DATABASE LOADED: \(additiveDatabase.count) additives ✅✅✅")
            // Print first few additives for verification
            for (i, additive) in additiveDatabase.prefix(3).enumerated() {
                print("  \(i+1). \(additive.eNumber) - \(additive.name)")
            }
        } catch {
            print("❌❌❌ ERROR LOADING ADDITIVE DATABASE: \(error) ❌❌❌")
        }
    }
    
    // REMOVED: Local analysis method - now using Firebase Cloud Function as SINGLE SOURCE OF TRUTH
    
    // Firebase Cloud Function analysis - SINGLE SOURCE OF TRUTH  
    func analyzeIngredients(_ ingredients: [String], completion: @escaping (AdditiveDetectionResult) -> Void) {
        // Default empty result if Firebase call fails
        let fallbackResult = AdditiveDetectionResult(detectedAdditives: [], childWarnings: [], hasChildConcernAdditives: false, analysisConfidence: 0.0, processingScore: nil, comprehensiveWarnings: nil)
        
        guard let url = URL(string: "https://us-central1-nutrasafe-705c7.cloudfunctions.net/analyzeAdditivesEnhanced") else {
            print("❌ Error: Invalid Firebase Cloud Function URL")
            completion(fallbackResult)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["ingredients": ingredients.joined(separator: ", ")]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("❌ Failed to encode request: \(error)")
            completion(fallbackResult)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Enhanced additive analysis error: \(error)")
                    completion(fallbackResult)
                    return
                }
                
                guard let data = data else {
                    print("❌ No data received from enhanced analysis")
                    completion(fallbackResult)
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let success = json["success"] as? Bool, success {
                        
                        // Parse processing score
                        let processingScore = self.parseProcessingScore(json["processing"] as? [String: Any])
                        
                        // Parse comprehensive warnings
                        let warnings = self.parseWarnings(json["warnings"] as? [String: Any])
                        
                        // Parse detected additives
                        let enhancedAdditives = self.parseEnhancedAdditives(json["additives"] as? [[String: Any]])
                        
                        // Create enhanced result
                        let enhancedResult = AdditiveDetectionResult(
                            detectedAdditives: enhancedAdditives.isEmpty ? fallbackResult.detectedAdditives : enhancedAdditives,
                            childWarnings: enhancedAdditives.filter { $0.hasChildWarning },
                            hasChildConcernAdditives: warnings?.childWarnings.isEmpty == false,
                            analysisConfidence: (json["metadata"] as? [String: Any])?["confidence"] as? Double ?? fallbackResult.analysisConfidence,
                            processingScore: processingScore,
                            comprehensiveWarnings: warnings
                        )
                        
                        completion(enhancedResult)
                    } else {
                        print("❌ Enhanced analysis failed, using fallback")
                        completion(fallbackResult)
                    }
                } catch {
                    print("❌ Failed to parse enhanced analysis response: \(error)")
                    completion(fallbackResult)
                }
            }
        }.resume()
    }
    
    private func parseProcessingScore(_ processing: [String: Any]?) -> ProcessingAnalysisResult? {
        guard let processing = processing,
              let score = processing["score"] as? Int,
              let grade = processing["grade"] as? String,
              let label = processing["label"] as? String,
              let breakdownData = processing["breakdown"] as? [String: [String: Any]] else {
            return nil
        }
        
        var breakdown: [String: ProcessingCategoryBreakdown] = [:]
        for (category, data) in breakdownData {
            if let count = data["count"] as? Int,
               let score = data["score"] as? Int,
               let details = data["details"] as? [String] {
                breakdown[category] = ProcessingCategoryBreakdown(count: count, score: score, details: details)
            }
        }
        
        return ProcessingAnalysisResult(score: score, grade: grade, label: label, breakdown: breakdown)
    }
    
    private func parseWarnings(_ warnings: [String: Any]?) -> AdditiveWarningsResult? {
        guard let warnings = warnings else { return nil }
        
        return AdditiveWarningsResult(
            childWarnings: warnings["children"] as? [String] ?? [],
            pkuWarnings: warnings["pku"] as? [String] ?? [],
            sulphiteWarnings: warnings["sulphites"] as? [String] ?? [],
            polyolWarnings: warnings["polyols"] as? [String] ?? [],
            regulatoryWarnings: warnings["regulatory"] as? [String] ?? [],
            hasRedFlags: warnings["hasRedFlags"] as? Bool ?? false,
            overallRisk: warnings["overallRisk"] as? String ?? "LOW",
            riskExplanation: warnings["riskExplanation"] as? String ?? ""
        )
    }
    
    private func parseEnhancedAdditives(_ additivesData: [[String: Any]]?) -> [AdditiveInfo] {
        guard let additivesData = additivesData else { return [] }
        
        var additives: [AdditiveInfo] = []
        for data in additivesData {
            if let code = data["code"] as? String,
               let name = data["name"] as? String,
               let category = data["category"] as? String {
                
                let additive = AdditiveInfo(
                    id: code,
                    eNumber: code,
                    name: name,
                    group: AdditiveGroup(rawValue: category) ?? .other,
                    isPermittedGB: data["permitted_GB"] as? Bool ?? true,
                    isPermittedNI: data["permitted_NI"] as? Bool ?? true,
                    isPermittedEU: data["permitted_EU"] as? Bool ?? true,
                    statusNotes: data["status_notes"] as? String,
                    hasChildWarning: data["child_warning"] as? Bool ?? false,
                    hasPKUWarning: data["PKU_warning"] as? Bool ?? false,
                    hasPolyolsWarning: data["polyols_warning"] as? Bool ?? false,
                    hasSulphitesAllergenLabel: data["sulphites_allergen_label"] as? Bool ?? false,
                    category: AdditiveCategory(rawValue: category) ?? .other,
                    origin: AdditiveOrigin(rawValue: data["origin"] as? String ?? "synthetic") ?? .synthetic,
                    overview: data["overview"] as? String ?? "",
                    typicalUses: data["typical_uses"] as? String ?? "",
                    effectsSummary: data["effects_summary"] as? String ?? "",
                    effectsVerdict: AdditiveVerdict(rawValue: data["effects_verdict"] as? String ?? "neutral") ?? .neutral,
                    synonyms: (data["synonyms"] as? [String]) ?? [],
                    insNumber: data["ins_number"] as? String,
                    sources: [], // Can be enhanced with source parsing
                    consumerInfo: data["consumerInfo"] as? String
                )
                additives.append(additive)
            }
        }
        
        return additives
    }
    
    private func calculateMatchScore(additive: AdditiveInfo, text: String) -> Double {
        var score = 0.0
        
        // Check E-number match (highest priority)
        if text.contains(additive.eNumber.lowercased()) {
            score += 0.9
        }
        
        // Check name match
        if text.contains(additive.name.lowercased()) {
            score += 0.8
        }
        
        // Check synonyms
        for synonym in additive.synonyms {
            if text.contains(synonym.lowercased()) {
                score += 0.6
                break
            }
        }
        
        // Check INS number if available
        if let insNumber = additive.insNumber, text.contains(insNumber) {
            score += 0.7
        }
        
        return min(score, 1.0)
    }
    
    private func parseCSV(_ content: String) -> [AdditiveInfo] {
        let lines = content.components(separatedBy: .newlines)
        guard lines.count > 2 else { return [] }
        
        // Skip table name row and header row
        let dataLines = Array(lines[2...]).filter { !$0.isEmpty }
        var additives: [AdditiveInfo] = []
        
        for line in dataLines {
            if let additive = parseCSVLine(line) {
                additives.append(additive)
            }
        }
        
        return additives
    }
    
    private func parseCSVLine(_ line: String) -> AdditiveInfo? {
        let components = parseCSVComponents(line)
        guard components.count >= 16 else { 
            print("❌ CSV line has \(components.count) components, need at least 16. Line: \(line.prefix(100))")
            return nil
        }
        
        let synonyms = components.count > 16 ? components[16].split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) } : []
        
        return AdditiveInfo(
            id: components[0],
            eNumber: components[0],
            name: components[1],
            group: AdditiveGroup(rawValue: components[2]) ?? .other,
            isPermittedGB: components[3] == "TRUE",
            isPermittedNI: components[4] == "TRUE",
            isPermittedEU: components[5] == "TRUE",
            statusNotes: components[6].isEmpty ? nil : components[6],
            hasChildWarning: components[7] == "TRUE",
            hasPKUWarning: components[8] == "TRUE",
            hasPolyolsWarning: components[9] == "TRUE",
            hasSulphitesAllergenLabel: components[10] == "TRUE",
            category: AdditiveCategory(rawValue: components[2]) ?? .other,
            origin: parseOrigin(components[11]),
            overview: components[12],
            typicalUses: components[13],
            effectsSummary: components[14],
            effectsVerdict: AdditiveVerdict(rawValue: components[15]) ?? .neutral,
            synonyms: synonyms,
            insNumber: components.count > 18 && !components[18].isEmpty ? components[18] : nil,
            sources: [],
            consumerInfo: nil
        )
    }
    
    private func parseOrigin(_ originString: String) -> AdditiveOrigin {
        switch originString.lowercased() {
        case "synthetic": return .synthetic
        case "plant": return .plant
        case "animal": return .animal
        case "mineral": return .mineral
        default: return .syntheticPlantMineral
        }
    }
    
    private func parseCSVComponents(_ line: String) -> [String] {
        var components: [String] = []
        var current = ""
        var inQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                components.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                current = ""
            } else {
                current.append(char)
            }
            
            i = line.index(after: i)
        }
        
        // Add the last component
        components.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        
        return components
    }
}

struct ReferenceFood: Codable {
    let id: String
    let name: String
    let category: String
    let nutritionalInfo: [String: Double]?
}

struct IngredientMapping: Codable {
    let ingredientName: String
    let quidPercentage: Double? // QUID percentage if available
    let estimatedWeight: Double // Weight per 100g of final product
    let matchedReferenceFood: ReferenceFood
    let matchConfidence: Double // 0.0 to 1.0
}

