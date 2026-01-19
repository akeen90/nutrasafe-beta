//
//  InferredIngredientModels.swift
//  NutraSafe Beta
//
//  AI-Inferred Meal Analysis - Data Models
//  Supports ingredient inference for foods without labels (takeaway, restaurant, generic)
//
//  IMPORTANT: This system provides EDUCATED GUESSES only and does NOT provide medical advice.
//  AI-inferred ingredients may be incomplete or incorrect.
//

import Foundation

// MARK: - Inferred Ingredient

/// Represents an ingredient or exposure that may be exact (from label) or estimated (AI-inferred)
struct InferredIngredient: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    let category: InferredIngredientCategory
    let confidence: InferredIngredientConfidence
    var source: InferredIngredientSource
    let explanation: String?  // "Why this appears" - helps user understand inference
    var isUserEdited: Bool    // true if user confirmed, added, or modified this ingredient

    init(
        id: String = UUID().uuidString,
        name: String,
        category: InferredIngredientCategory,
        confidence: InferredIngredientConfidence,
        source: InferredIngredientSource,
        explanation: String? = nil,
        isUserEdited: Bool = false
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.confidence = confidence
        self.source = source
        self.explanation = explanation
        self.isUserEdited = isUserEdited
    }

    // MARK: - Reaction Weight

    /// Weight used in the reaction engine for pattern analysis
    /// Exact ingredients: 1.0 (full weight)
    /// User-edited estimated: 1.0 (user confirmed = treated as exact)
    /// Estimated high/medium confidence: 0.6
    /// Estimated low confidence: 0.3
    var reactionWeight: Double {
        switch source {
        case .exact:
            return 1.0
        case .userEdited:
            return 1.0  // User confirmed = full weight
        case .estimated:
            if isUserEdited {
                return 1.0  // User confirmed an estimated ingredient
            }
            switch confidence {
            case .high, .medium:
                return 0.6
            case .low:
                return 0.3
            }
        }
    }

    /// Returns true if this is an AI-estimated ingredient (not from label or user edit)
    var isEstimated: Bool {
        source == .estimated && !isUserEdited
    }

    /// Display-friendly confidence label
    var confidenceLabel: String {
        switch confidence {
        case .high: return "High likelihood"
        case .medium: return "Medium likelihood"
        case .low: return "Low likelihood"
        }
    }

    // MARK: - Factory Methods

    /// Create an exact ingredient from a known label
    static func exact(name: String, category: InferredIngredientCategory = .base) -> InferredIngredient {
        InferredIngredient(
            name: name,
            category: category,
            confidence: .high,
            source: .exact,
            explanation: nil,
            isUserEdited: false
        )
    }

    /// Create an estimated ingredient from AI inference
    static func estimated(
        name: String,
        category: InferredIngredientCategory,
        confidence: InferredIngredientConfidence,
        explanation: String
    ) -> InferredIngredient {
        InferredIngredient(
            name: name,
            category: category,
            confidence: confidence,
            source: .estimated,
            explanation: explanation,
            isUserEdited: false
        )
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: InferredIngredient, rhs: InferredIngredient) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Ingredient Category

/// Categories of ingredients and exposures for pattern analysis
enum InferredIngredientCategory: String, Codable, CaseIterable {
    case allergen       // Major allergens (wheat, dairy, nuts, eggs, soy, etc.)
    case preparation    // Preparation exposures (fried oil, reused oil, charred, smoked)
    case additive       // Additive classes (preservatives, MSG, sulfites, nitrates)
    case histamine      // Histamine-related (aged, fermented, processed meats)
    case base           // Core ingredients (meat type, grain, vegetable)
    case crossContact   // Cross-contamination risks (shared fryer, kitchen)

    var displayName: String {
        switch self {
        case .allergen: return "Allergen"
        case .preparation: return "Preparation"
        case .additive: return "Additive"
        case .histamine: return "Histamine"
        case .base: return "Ingredient"
        case .crossContact: return "Cross-Contact"
        }
    }

    var icon: String {
        switch self {
        case .allergen: return "exclamationmark.triangle.fill"
        case .preparation: return "flame.fill"
        case .additive: return "testtube.2"
        case .histamine: return "clock.fill"
        case .base: return "leaf.fill"
        case .crossContact: return "arrow.triangle.2.circlepath"
        }
    }

    var color: String {
        switch self {
        case .allergen: return "red"
        case .preparation: return "orange"
        case .additive: return "purple"
        case .histamine: return "yellow"
        case .base: return "green"
        case .crossContact: return "blue"
        }
    }
}

// MARK: - Ingredient Confidence

/// Confidence level for estimated ingredients
enum InferredIngredientConfidence: String, Codable, CaseIterable, Comparable {
    case high       // Very common, appears in majority of UK versions
    case medium     // Moderately common, likely present
    case low        // Occasionally present, brand/recipe specific

    var displayName: String {
        switch self {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }

    var sortOrder: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }

    static func < (lhs: InferredIngredientConfidence, rhs: InferredIngredientConfidence) -> Bool {
        lhs.sortOrder > rhs.sortOrder  // Higher confidence = lower sort order
    }
}

// MARK: - Ingredient Source

/// Source of ingredient information
enum InferredIngredientSource: String, Codable {
    case exact          // From ingredient label (branded product)
    case estimated      // AI-inferred (generic food)
    case userEdited     // User confirmed, added, or modified

    var displayName: String {
        switch self {
        case .exact: return "From Label"
        case .estimated: return "Estimated"
        case .userEdited: return "User Confirmed"
        }
    }

    var badgeText: String? {
        switch self {
        case .exact: return nil
        case .estimated: return "Estimated"
        case .userEdited: return "Confirmed"
        }
    }
}

// MARK: - Inferred Meal Analysis

/// Complete AI inference result for a meal without known ingredients
struct InferredMealAnalysis: Codable {
    let foodName: String
    let analysisDate: Date
    let isGenericFood: Bool  // true = no brand, takeaway, restaurant

    // Inferred exposures
    let likelyIngredients: [InferredIngredient]
    let preparationExposures: [InferredIngredient]
    let possibleCrossContamination: [InferredIngredient]

    // Uncertainty notice
    let uncertaintyNotice: String

    /// All inferred ingredients combined
    var allInferredIngredients: [InferredIngredient] {
        likelyIngredients + preparationExposures + possibleCrossContamination
    }

    /// Count of high/medium confidence items
    var highConfidenceCount: Int {
        allInferredIngredients.filter { $0.confidence == .high || $0.confidence == .medium }.count
    }

    init(
        foodName: String,
        isGenericFood: Bool = true,
        likelyIngredients: [InferredIngredient] = [],
        preparationExposures: [InferredIngredient] = [],
        possibleCrossContamination: [InferredIngredient] = []
    ) {
        self.foodName = foodName
        self.analysisDate = Date()
        self.isGenericFood = isGenericFood
        self.likelyIngredients = likelyIngredients
        self.preparationExposures = preparationExposures
        self.possibleCrossContamination = possibleCrossContamination
        self.uncertaintyNotice = """
            These ingredients are estimated and may be incomplete. \
            Some real ingredients may be missing. \
            You can edit them if you know more details.
            """
    }
}

// MARK: - Food Entry Extension

/// Extension to track whether a food has inferred ingredients
extension InferredMealAnalysis {
    /// Determines if this food needs ingredient inference
    /// Returns true for: takeaway, restaurant, generic foods without barcodes/brands
    static func needsInference(hasBarcode: Bool, hasBrand: Bool, hasIngredients: Bool) -> Bool {
        // If we already have ingredients, no inference needed
        if hasIngredients { return false }

        // If branded product with barcode, likely has known ingredients
        if hasBarcode && hasBrand { return false }

        // Generic food without ingredients = needs inference
        return true
    }
}

// MARK: - Weighted Ingredient Extension

/// Extension to track estimated vs exact sources in pattern analysis
struct IngredientExposureStats: Codable {
    let exactCount: Int      // Times ingredient appeared from exact sources
    let estimatedCount: Int  // Times ingredient appeared from estimated sources
    let userEditedCount: Int // Times ingredient was user-confirmed

    /// Total appearances
    var totalCount: Int {
        exactCount + estimatedCount + userEditedCount
    }

    /// Percentage from exact sources
    var exactPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(exactCount + userEditedCount) / Double(totalCount) * 100
    }

    /// Weighted total using reaction weights
    var weightedTotal: Double {
        Double(exactCount) * 1.0 +
        Double(userEditedCount) * 1.0 +
        Double(estimatedCount) * 0.6  // Using medium confidence weight as average
    }

    /// Returns true if majority of exposures are estimated
    var isPrimarilyEstimated: Bool {
        estimatedCount > (exactCount + userEditedCount)
    }

    init(exactCount: Int = 0, estimatedCount: Int = 0, userEditedCount: Int = 0) {
        self.exactCount = exactCount
        self.estimatedCount = estimatedCount
        self.userEditedCount = userEditedCount
    }
}
