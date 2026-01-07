//
//  FoodModels.swift
//  NutraSafe Database Manager
//
//  Data models for food items matching Algolia database structure
//

import Foundation

// MARK: - Food Item Model

struct FoodItem: Identifiable, Codable, Hashable {
    var objectID: String
    var name: String
    var brand: String?
    var barcode: String?

    // Nutrition (per 100g unless isPerUnit is true)
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double
    var sugar: Double
    var sodium: Double
    var saturatedFat: Double?
    var transFat: Double?
    var cholesterol: Double?

    // Serving info
    var servingDescription: String?
    var servingSizeG: Double?
    var isPerUnit: Bool?

    // Ingredients
    var ingredients: [String]?
    var ingredientsText: String?

    // Additives
    var additives: [AdditiveEntry]?

    // Processing info
    var processingScore: Int?
    var processingGrade: String?
    var processingLabel: String?

    // Verification
    var isVerified: Bool?
    var verifiedBy: String?
    var verifiedAt: String?
    var verificationMethod: String?

    // Source tracking
    var source: String?
    var sourceId: String?
    var lastUpdated: String?

    // Images
    var imageURL: String?
    var thumbnailURL: String?

    // Micronutrients
    var micronutrientProfile: MicronutrientProfile?

    // Categories/Tags
    var categories: [String]?
    var tags: [String]?

    var id: String { objectID }

    // Computed property for display
    var displayName: String {
        if let brand = brand, !brand.isEmpty {
            return "\(brand) - \(name)"
        }
        return name
    }

    // Empty initializer for creating new foods
    init() {
        self.objectID = UUID().uuidString
        self.name = ""
        self.calories = 0
        self.protein = 0
        self.carbs = 0
        self.fat = 0
        self.fiber = 0
        self.sugar = 0
        self.sodium = 0
    }

    // Full initializer
    init(objectID: String, name: String, brand: String? = nil, barcode: String? = nil,
         calories: Double, protein: Double, carbs: Double, fat: Double,
         fiber: Double, sugar: Double, sodium: Double,
         saturatedFat: Double? = nil, transFat: Double? = nil, cholesterol: Double? = nil,
         servingDescription: String? = nil, servingSizeG: Double? = nil, isPerUnit: Bool? = nil,
         ingredients: [String]? = nil, ingredientsText: String? = nil,
         additives: [AdditiveEntry]? = nil,
         processingScore: Int? = nil, processingGrade: String? = nil, processingLabel: String? = nil,
         isVerified: Bool? = nil, verifiedBy: String? = nil, verifiedAt: String? = nil, verificationMethod: String? = nil,
         source: String? = nil, sourceId: String? = nil, lastUpdated: String? = nil,
         imageURL: String? = nil, thumbnailURL: String? = nil,
         micronutrientProfile: MicronutrientProfile? = nil,
         categories: [String]? = nil, tags: [String]? = nil) {
        self.objectID = objectID
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.saturatedFat = saturatedFat
        self.transFat = transFat
        self.cholesterol = cholesterol
        self.servingDescription = servingDescription
        self.servingSizeG = servingSizeG
        self.isPerUnit = isPerUnit
        self.ingredients = ingredients
        self.ingredientsText = ingredientsText
        self.additives = additives
        self.processingScore = processingScore
        self.processingGrade = processingGrade
        self.processingLabel = processingLabel
        self.isVerified = isVerified
        self.verifiedBy = verifiedBy
        self.verifiedAt = verifiedAt
        self.verificationMethod = verificationMethod
        self.source = source
        self.sourceId = sourceId
        self.lastUpdated = lastUpdated
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
        self.micronutrientProfile = micronutrientProfile
        self.categories = categories
        self.tags = tags
    }
}

// MARK: - Additive Entry

struct AdditiveEntry: Codable, Hashable, Identifiable {
    var code: String
    var name: String
    var category: String?
    var healthScore: Int?
    var childWarning: Bool?
    var effectsVerdict: String?
    var consumerGuide: String?
    var origin: String?

    var id: String { code + name }

    enum CodingKeys: String, CodingKey {
        case code
        case name
        case category
        case healthScore
        case childWarning = "child_warning"
        case effectsVerdict = "effects_verdict"
        case consumerGuide = "consumer_guide"
        case origin
    }
}

// MARK: - Micronutrient Profile

struct MicronutrientProfile: Codable, Hashable {
    var vitamins: [String: Double]
    var minerals: [String: Double]

    init(vitamins: [String: Double] = [:], minerals: [String: Double] = [:]) {
        self.vitamins = vitamins
        self.minerals = minerals
    }
}

// MARK: - Additive Database Model

struct AdditiveItem: Identifiable, Codable, Hashable {
    var objectID: String?
    var name: String
    var eNumbers: [String]
    var category: String
    var group: String?
    var origin: String?
    var overview: String?
    var whatItIs: String?
    var whyItsUsed: String?
    var whereItComesFrom: String?
    var typicalUses: String?
    var effectsVerdict: String
    var effectsSummary: String?
    var concerns: String?
    var hasChildWarning: Bool
    var hasPKUWarning: Bool
    var hasSulphitesAllergenLabel: Bool
    var hasPolyolsWarning: Bool
    var isPermittedGB: Bool
    var isPermittedNI: Bool
    var isPermittedEU: Bool
    var synonyms: [String]
    var sources: [AdditiveSource]?
    var processingPenalty: Int
    var novaGroup: Int

    var id: String { objectID ?? name }

    enum CodingKeys: String, CodingKey {
        case objectID
        case name
        case eNumbers
        case category
        case group
        case origin
        case overview
        case whatItIs = "what_it_is"
        case whyItsUsed = "why_its_used"
        case whereItComesFrom = "where_it_comes_from"
        case typicalUses
        case effectsVerdict
        case effectsSummary
        case concerns
        case hasChildWarning
        case hasPKUWarning
        case hasSulphitesAllergenLabel
        case hasPolyolsWarning
        case isPermittedGB
        case isPermittedNI
        case isPermittedEU
        case synonyms
        case sources
        case processingPenalty
        case novaGroup
    }

    init() {
        self.name = ""
        self.eNumbers = []
        self.category = ""
        self.effectsVerdict = "neutral"
        self.hasChildWarning = false
        self.hasPKUWarning = false
        self.hasSulphitesAllergenLabel = false
        self.hasPolyolsWarning = false
        self.isPermittedGB = true
        self.isPermittedNI = true
        self.isPermittedEU = true
        self.synonyms = []
        self.processingPenalty = 0
        self.novaGroup = 0
    }
}

struct AdditiveSource: Codable, Hashable {
    var title: String
    var url: String
    var covers: String?
}

// MARK: - Ultra-Processed Ingredient Model

struct UltraProcessedIngredient: Identifiable, Codable, Hashable {
    var objectID: String?
    var name: String
    var synonyms: [String]
    var processingPenalty: Int
    var category: String
    var concerns: String?
    var novaGroup: Int
    var whatItIs: String?
    var whyItsUsed: String?
    var whereItComesFrom: String?
    var sources: [AdditiveSource]?

    var id: String { objectID ?? name }

    enum CodingKeys: String, CodingKey {
        case objectID
        case name
        case synonyms
        case processingPenalty = "processing_penalty"
        case category
        case concerns
        case novaGroup = "nova_group"
        case whatItIs = "what_it_is"
        case whyItsUsed = "why_its_used"
        case whereItComesFrom = "where_it_comes_from"
        case sources
    }

    init() {
        self.name = ""
        self.synonyms = []
        self.processingPenalty = 0
        self.category = ""
        self.novaGroup = 4
    }
}

// MARK: - Search/Filter Models

struct FoodFilter {
    var showVerifiedOnly: Bool = false
    var showUnverifiedOnly: Bool = false
    var minCalories: Double?
    var maxCalories: Double?
    var hasBarcode: Bool?
    var hasBrand: Bool?
    var processingGrades: Set<String> = []
    var categories: Set<String> = []

    var isActive: Bool {
        showVerifiedOnly || showUnverifiedOnly ||
        minCalories != nil || maxCalories != nil ||
        hasBarcode != nil || hasBrand != nil ||
        !processingGrades.isEmpty || !categories.isEmpty
    }
}

// MARK: - Bulk Edit Models

struct BulkEditOperation {
    enum Field: String, CaseIterable {
        case brand = "Brand"
        case source = "Source"
        case processingGrade = "Processing Grade"
        case isVerified = "Verified Status"
        case category = "Category"
        case addTag = "Add Tag"
        case removeTag = "Remove Tag"
    }

    var field: Field
    var value: String
}

// MARK: - Import/Export Models

struct ImportResult {
    var successCount: Int
    var failureCount: Int
    var errors: [String]
}

enum ExportFormat: String, CaseIterable {
    case json = "JSON"
    case csv = "CSV"

    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        }
    }
}
