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

/// Represents a portion/serving size option for foods with multiple sizes (e.g., McNuggets 6pc, 9pc, 20pc)
struct PortionOption: Codable, Equatable, Identifiable {
    var id: String { name }
    let name: String
    let calories: Double
    let serving_g: Double

    enum CodingKeys: String, CodingKey {
        case name
        case calories
        case serving_g
    }
}

struct FoodSearchResult: Identifiable, Decodable, Equatable {
    let id: String
    let name: String
    let brand: String?
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let saturatedFat: Double?
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let servingDescription: String?
    let servingSizeG: Double? // Numeric serving size in grams
    let isPerUnit: Bool? // true = values are per unit (e.g., "1 burger"), false/nil = per 100g
    let ingredients: [String]?
    let confidence: Double? // For AI recognition results
    let isVerified: Bool // Indicates if food comes from internal verified database
    let additives: [NutritionAdditiveInfo]?
    let additivesDatabaseVersion: String? // Database version used for additive analysis
    let processingScore: Int?
    let processingGrade: String?
    let processingLabel: String?
    let barcode: String?
    let micronutrientProfile: MicronutrientProfile?
    let portions: [PortionOption]? // Available portion sizes (e.g., McNuggets 6pc, 9pc, 20pc)
    let source: String? // Source index (e.g., "tesco_products", "uk_foods_cleaned") for tier-based ranking
    let imageUrl: String? // Product image URL (from Tesco/external sources)

    // Firebase category-based serving sizes (from AI categorization)
    let foodCategory: String? // Category ID (e.g., "chocolate_bar", "raw_beef", "spirits")
    let suggestedServingSize: Double? // Default serving size for this category (e.g., 45, 150, 25)
    let suggestedServingUnit: String? // "g" or "ml"
    let suggestedServingDescription: String? // e.g., "per bar", "per portion", "per 25ml measure"

    init(id: String, name: String, brand: String? = nil, calories: Double, protein: Double, carbs: Double, fat: Double, saturatedFat: Double? = nil, fiber: Double, sugar: Double, sodium: Double, servingDescription: String? = nil, servingSizeG: Double? = nil, isPerUnit: Bool? = nil, ingredients: [String]? = nil, confidence: Double? = nil, isVerified: Bool = false, additives: [NutritionAdditiveInfo]? = nil, additivesDatabaseVersion: String? = nil, processingScore: Int? = nil, processingGrade: String? = nil, processingLabel: String? = nil, barcode: String? = nil, micronutrientProfile: MicronutrientProfile? = nil, portions: [PortionOption]? = nil, source: String? = nil, imageUrl: String? = nil, foodCategory: String? = nil, suggestedServingSize: Double? = nil, suggestedServingUnit: String? = nil, suggestedServingDescription: String? = nil) {
        self.id = id
        self.name = name
        self.brand = brand
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.saturatedFat = saturatedFat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.servingDescription = servingDescription
        self.servingSizeG = servingSizeG
        self.isPerUnit = isPerUnit
        self.ingredients = ingredients
        self.confidence = confidence
        self.isVerified = isVerified
        self.additives = additives
        self.additivesDatabaseVersion = additivesDatabaseVersion
        self.processingScore = processingScore
        self.processingGrade = processingGrade
        self.processingLabel = processingLabel
        self.barcode = barcode
        self.micronutrientProfile = micronutrientProfile
        self.portions = portions
        self.source = source
        self.imageUrl = imageUrl
        self.foodCategory = foodCategory
        self.suggestedServingSize = suggestedServingSize
        self.suggestedServingUnit = suggestedServingUnit
        self.suggestedServingDescription = suggestedServingDescription
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
        case saturatedFat
        case fiber
        case sugar
        case sodium
        case servingDescription
        case servingSizeG
        case ingredients
        case confidence
        case isVerified
        case verifiedBy
        case verificationMethod
        case verifiedAt
        case additives
        case additivesDatabaseVersion
        case processingScore
        case processingGrade
        case processingLabel
        case barcode
        case micronutrientProfile
        case isPerUnit = "per_unit_nutrition"
        case portions
        case source
        case imageUrl
        // Firebase category-based serving sizes
        case foodCategory
        case suggestedServingSize
        case suggestedServingUnit
        case suggestedServingDescription
    }
    
    // Helper structs for nested nutrition format from Firebase
    private struct CalorieInfo: Codable {
        let kcal: Double
    }

    private struct NutrientInfo: Codable {
        let per100g: Double
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.name = try c.decode(String.self, forKey: .name)
        self.brand = try c.decodeIfPresent(String.self, forKey: .brand)

        // Handle calories - try direct Double, then nested {kcal: Double}
        if let directValue = try? c.decode(Double.self, forKey: .calories) {
            self.calories = directValue
        } else if let nested = try? c.decode(CalorieInfo.self, forKey: .calories) {
            self.calories = nested.kcal
        } else {
            self.calories = 0
        }

        // Handle protein - try direct Double, then nested {per100g: Double}
        if let directValue = try? c.decode(Double.self, forKey: .protein) {
            self.protein = directValue
        } else if let nested = try? c.decode(NutrientInfo.self, forKey: .protein) {
            self.protein = nested.per100g
        } else {
            self.protein = 0
        }

        // Handle carbs - try direct Double, then nested {per100g: Double}
        if let directValue = try? c.decode(Double.self, forKey: .carbs) {
            self.carbs = directValue
        } else if let nested = try? c.decode(NutrientInfo.self, forKey: .carbs) {
            self.carbs = nested.per100g
        } else {
            self.carbs = 0
        }

        // Handle fat - try direct Double, then nested {per100g: Double}
        if let directValue = try? c.decode(Double.self, forKey: .fat) {
            self.fat = directValue
        } else if let nested = try? c.decode(NutrientInfo.self, forKey: .fat) {
            self.fat = nested.per100g
        } else {
            self.fat = 0
        }

        // Handle saturatedFat - try direct Double, then nested {per100g: Double}
        if let directValue = try? c.decode(Double.self, forKey: .saturatedFat) {
            self.saturatedFat = directValue
        } else if let nested = try? c.decode(NutrientInfo.self, forKey: .saturatedFat) {
            self.saturatedFat = nested.per100g
        } else {
            self.saturatedFat = nil
        }

        // Handle fiber - try direct Double, then nested {per100g: Double}
        if let directValue = try? c.decode(Double.self, forKey: .fiber) {
            self.fiber = directValue
        } else if let nested = try? c.decode(NutrientInfo.self, forKey: .fiber) {
            self.fiber = nested.per100g
        } else {
            self.fiber = 0
        }

        // Handle sugar - try direct Double, then nested {per100g: Double}
        if let directValue = try? c.decode(Double.self, forKey: .sugar) {
            self.sugar = directValue
        } else if let nested = try? c.decode(NutrientInfo.self, forKey: .sugar) {
            self.sugar = nested.per100g
        } else {
            self.sugar = 0
        }

        // Handle sodium - try direct Double, then nested {per100g: Double}
        if let directValue = try? c.decode(Double.self, forKey: .sodium) {
            self.sodium = directValue
        } else if let nested = try? c.decode(NutrientInfo.self, forKey: .sodium) {
            self.sodium = nested.per100g
        } else {
            self.sodium = 0
        }
        self.servingDescription = try? c.decode(String.self, forKey: .servingDescription)
        self.servingSizeG = try? c.decode(Double.self, forKey: .servingSizeG)
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
        // Check isVerified field directly first, then fall back to verification markers
        if let directVerified = try? c.decode(Bool.self, forKey: .isVerified) {
            self.isVerified = directVerified
        } else {
            // Legacy fallback: consider verified if backend included any verification markers
            let hasVerifier = (try? c.decodeIfPresent(String.self, forKey: .verifiedBy)) != nil || (try? c.decodeIfPresent(String.self, forKey: .verificationMethod)) != nil || (try? c.decodeIfPresent(String.self, forKey: .verifiedAt)) != nil
            self.isVerified = hasVerifier
        }
        self.additives = try? c.decode([NutritionAdditiveInfo].self, forKey: .additives)
        self.additivesDatabaseVersion = try? c.decode(String.self, forKey: .additivesDatabaseVersion)
        self.processingScore = try? c.decode(Int.self, forKey: .processingScore)
        self.processingGrade = try? c.decode(String.self, forKey: .processingGrade)
        self.processingLabel = try? c.decode(String.self, forKey: .processingLabel)
        self.barcode = try? c.decode(String.self, forKey: .barcode)
        self.micronutrientProfile = try? c.decode(MicronutrientProfile.self, forKey: .micronutrientProfile)
        self.isPerUnit = try? c.decode(Bool.self, forKey: .isPerUnit)
        self.portions = try? c.decode([PortionOption].self, forKey: .portions)
        self.source = try? c.decode(String.self, forKey: .source)
        self.imageUrl = try? c.decode(String.self, forKey: .imageUrl)
        // Firebase category-based serving sizes
        self.foodCategory = try? c.decode(String.self, forKey: .foodCategory)
        self.suggestedServingSize = try? c.decode(Double.self, forKey: .suggestedServingSize)
        self.suggestedServingUnit = try? c.decode(String.self, forKey: .suggestedServingUnit)
        self.suggestedServingDescription = try? c.decode(String.self, forKey: .suggestedServingDescription)
    }

    /// Returns true if this food has multiple portion options (e.g., McNuggets with 6pc, 9pc, 20pc)
    var hasPortionOptions: Bool {
        guard let portions = portions else { return false }
        return portions.count > 1
    }

    /// Calculate nutrition values for a specific portion
    func nutritionForPortion(_ portion: PortionOption) -> (calories: Double, protein: Double, carbs: Double, fat: Double) {
        // Find the base portion (matching current servingDescription)
        guard let portions = portions,
              let basePortion = portions.first(where: { $0.name == servingDescription }) ?? portions.first else {
            return (calories, protein, carbs, fat)
        }

        // Calculate multiplier based on serving weight ratio
        let multiplier = portion.serving_g / basePortion.serving_g

        return (
            calories: calories * multiplier,
            protein: protein * multiplier,
            carbs: carbs * multiplier,
            fat: fat * multiplier
        )
    }

    var servingSize: String {
        // If we have a serving description, use it
        if let desc = servingDescription {
            return desc
        }
        // Otherwise, show "per unit" or "per 100g" based on flag
        return (isPerUnit == true) ? "per unit" : "per 100g"
    }

    // MARK: - Firebase Category-Based Portions

    /// Returns true if this food has Firebase category data with suggested serving size
    var hasFirebaseCategoryPortions: Bool {
        guard let category = foodCategory, !category.isEmpty,
              let servingSize = suggestedServingSize, servingSize > 0 else {
            return false
        }
        return true
    }

    /// Generates portion options based on Firebase category data (from AI categorization)
    /// These are more accurate than local detection since they're determined by Gemini AI
    var firebaseCategoryPortions: [PortionOption] {
        guard let servingSize = suggestedServingSize, servingSize > 0 else { return [] }

        let unit = suggestedServingUnit ?? "g"
        let description = suggestedServingDescription ?? "1 serving"
        let caloriesPer100 = calories
        let isLiquid = unit == "ml"

        // Generate smart portion options based on the default serving size
        // Create 4 options: half, 1x, 1.5x, and 2x the suggested serving

        // Format the portion name with the unit
        func formatPortion(_ grams: Double, _ label: String) -> String {
            let rounded = Int(grams)
            return "\(label) (\(rounded)\(unit))"
        }

        // Calculate calories for a given portion size
        func caloriesFor(_ grams: Double) -> Double {
            return caloriesPer100 * (grams / 100)
        }

        // Clean up the description for display (remove "per " prefix if present)
        let cleanDesc = description.hasPrefix("per ") ? String(description.dropFirst(4)) : description

        // For very small servings (like aromatics: 3g), use different multipliers
        if servingSize < 15 {
            return [
                PortionOption(name: formatPortion(servingSize, "1 \(cleanDesc)"), calories: caloriesFor(servingSize), serving_g: servingSize),
                PortionOption(name: formatPortion(servingSize * 2, "2x"), calories: caloriesFor(servingSize * 2), serving_g: servingSize * 2),
                PortionOption(name: formatPortion(servingSize * 3, "3x"), calories: caloriesFor(servingSize * 3), serving_g: servingSize * 3),
                PortionOption(name: formatPortion(servingSize * 4, "4x"), calories: caloriesFor(servingSize * 4), serving_g: servingSize * 4)
            ]
        }

        // For liquid portions, use appropriate multipliers
        if isLiquid {
            // Round to nice ml values
            let half = (servingSize * 0.5).rounded()
            let one = servingSize
            let oneHalf = (servingSize * 1.5).rounded()
            let double = servingSize * 2

            return [
                PortionOption(name: formatPortion(half, "Half"), calories: caloriesFor(half), serving_g: half),
                PortionOption(name: formatPortion(one, "1 \(cleanDesc)"), calories: caloriesFor(one), serving_g: one),
                PortionOption(name: formatPortion(oneHalf, "Large"), calories: caloriesFor(oneHalf), serving_g: oneHalf),
                PortionOption(name: formatPortion(double, "2x"), calories: caloriesFor(double), serving_g: double)
            ]
        }

        // For solid portions
        let half = (servingSize * 0.5).rounded()
        let one = servingSize
        let oneHalf = (servingSize * 1.5).rounded()
        let double = servingSize * 2

        return [
            PortionOption(name: formatPortion(half, "Half"), calories: caloriesFor(half), serving_g: half),
            PortionOption(name: formatPortion(one, "1 \(cleanDesc)"), calories: caloriesFor(one), serving_g: one),
            PortionOption(name: formatPortion(oneHalf, "1.5x"), calories: caloriesFor(oneHalf), serving_g: oneHalf),
            PortionOption(name: formatPortion(double, "2x"), calories: caloriesFor(double), serving_g: double)
        ]
    }

    // MARK: - Auto-detected Food Category for Smart Portion Presets

    /// Food category for determining preset portion sizes
    enum FoodCategory {
        // Drinks
        case softDrink      // Carbonated drinks, sodas
        case cordial        // Cordials, squash (concentrated - need diluting)
        case juice          // Fruit juices, smoothies
        case hotDrink       // Coffee, tea
        case water          // Water, flavoured water
        case alcoholicDrink // Beer, wine (larger portions)
        case spirit         // Vodka, gin, whisky, rum (shot portions)
        // Snacks
        case chocolateBar   // Chocolate bars (Mars, Snickers, Twix)
        case chocolateBag   // Bagged/boxed chocolates (Revels, Maltesers, M&Ms)
        case sweets         // Sweets, gummy candy, hard candy
        case crisps         // Crisps, chips
        case iceCream       // Ice cream, frozen desserts
        // Generic Foods
        case oil            // Cooking oils
        case butter         // Butter, spreads
        case condiment      // Jam, honey, mayo, ketchup, sauces
        case dip            // Hummus, guacamole, salsa, tzatziki
        case fruit          // Whole fruits (apple, banana, orange)
        case driedFruit     // Raisins, dates, prunes, dried apricots
        case egg            // Eggs
        case rice           // Cooked rice, grains
        case pasta          // Cooked pasta
        case bread          // Sliced bread, toast
        case bakeryItem     // Whole items: bagels, croissants, muffins, naan, pitta
        case cereal         // Oats, granola, muesli, cornflakes
        case nuts           // Nuts and seeds
        case cheese         // Cheese portions
        case milk           // Milk, plant milk
        case yogurt         // Yogurt, fromage frais
        case processedMeat  // Bacon, sausages, ham (per-item portions)
        case meat           // Meat portions (chicken, beef, pork, lamb)
        case fish           // Fish portions
        case vegetable      // Vegetable portions
        case aromatics      // Garlic, ginger, shallots (small portions)
        case legume         // Beans, lentils
        case tofu           // Tofu, tempeh, seitan
        case other          // Default - no presets
    }

    // MARK: - Serving Size Classification System

    /// Classification for serving size recommendation purposes
    /// Determines whether specific serving templates can be safely suggested
    enum ServingClassification: String {
        case atomicRaw = "ATOMIC_RAW"           // Single ingredient, raw: "salmon fillet", "raw broccoli"
        case atomicPrepared = "ATOMIC_PREPARED" // Single ingredient, cooked: "grilled salmon", "boiled egg"
        case compositeDish = "COMPOSITE_DISH"   // Multi-ingredient dish: "salmon en croute", "chicken curry"
        case brandedPackaged = "BRANDED_PACKAGED" // Retail product: "Mars bar", "tinned tuna"
        case ambiguous = "AMBIGUOUS"            // Too vague: "salmon", "chicken", "pasta"
    }

    /// Confidence level for serving size suggestions
    struct ServingConfidence {
        let score: Double           // 0.0 to 1.0
        let classification: ServingClassification
        let usesSafeOutput: Bool    // True if should use generic portions
        let reasons: [String]       // Explainability

        /// Threshold for using category-specific presets vs safe generic options
        static let highConfidenceThreshold: Double = 0.7
    }

    // MARK: - Composite Dish Detection

    /// Comprehensive list of indicators that suggest a composite/prepared dish
    /// These patterns take PRIORITY over single-ingredient keyword matching
    private static let compositeDishIndicators: Set<String> = [
        // Pastry-wrapped
        "en croute", "encroute", "wellington", "pie", "pies", "pasty", "pasties",
        "pastry", "puff pastry", "shortcrust", "filo", "phyllo", "strudel",
        "samosa", "samosas", "spring roll", "spring rolls", "egg roll",
        "dumpling", "dumplings", "gyoza", "wonton", "wontons",
        "calzone", "empanada", "empanadas", "cornish pasty", "sausage roll",

        // Curries & Asian sauced dishes
        "curry", "curries", "korma", "masala", "tikka masala", "tikka",
        "madras", "vindaloo", "jalfrezi", "rogan josh", "bhuna", "balti",
        "dopiaza", "pathia", "biryani", "dhansak", "saag",
        "satay", "rendang", "massaman", "panang", "green curry", "red curry",
        "katsu", "teriyaki", "sweet and sour", "kung pao", "szechuan",
        "chow mein", "chop suey",

        // Pasta dishes (complete)
        "bolognese", "bolognaise", "carbonara", "arrabiata", "arrabbiata",
        "alfredo", "puttanesca", "amatriciana", "cacio e pepe",
        "lasagne", "lasagna", "cannelloni", "manicotti",
        "spaghetti and meatballs", "pasta bake", "mac and cheese", "mac n cheese",
        "macaroni cheese", "tuna pasta bake",

        // Sandwiches & filled items
        "sandwich", "sandwiches", "butty", "buttie", "sarnie",
        "wrap", "wraps", "burrito", "burritos", "taco", "tacos",
        "quesadilla", "enchilada", "fajita", "fajitas",
        "panini", "paninis", "baguette filled",
        "sub", "hoagie", "hero", "grinder",
        "club sandwich", "toastie", "toasted sandwich",

        // Soups & liquid dishes
        "soup", "soups", "broth", "consomme",
        "chowder", "bisque", "gazpacho", "minestrone",
        "stew", "stews", "casserole", "casseroles",
        "hotpot", "hot pot", "goulash", "bourguignon",
        "tagine", "ragu", "ragout",

        // Baked & gratin
        "bake", "bakes", "gratin", "au gratin", "dauphinoise",
        "crumble", "cobbler", "crisp",
        "quiche", "frittata",

        // Stir-fried
        "stir fry", "stir-fry", "stirfry", "stir fried", "stir-fried",
        "pad thai", "fried rice",

        // Coated & processed
        "battered", "in batter", "beer battered",
        "breaded", "crumbed", "coated", "crispy coated",
        "tempura", "panko", "southern fried",
        "nuggets", "nugget", "fingers", "finger",
        "goujons", "goujon", "bites", "popcorn chicken", "popcorn shrimp",
        "kiev", "kyiv", "cordon bleu", "schnitzel", "escalope",

        // Stuffed & filled
        "stuffed", "filled", "loaded", "topped", "covered",

        // Complete meals
        "meal", "ready meal", "microwave meal",
        "dinner", "platter", "combo", "meal deal",
        "roast dinner", "sunday roast", "sunday lunch",
        "full english", "full breakfast", "fry up", "fry-up",
        "mixed grill",

        // UK specific dishes
        "fish and chips", "fish n chips", "fish & chips",
        "bangers and mash", "sausage and mash",
        "shepherd's pie", "shepherds pie", "cottage pie",
        "toad in the hole", "bubble and squeak",
        "ploughman's", "ploughmans",
        "beans on toast", "cheese on toast",

        // International dishes
        "moussaka", "paella", "risotto",
        "ramen", "pho", "laksa",
        "falafel wrap", "shawarma", "kebab", "doner",
        "burrito bowl", "poke bowl", "buddha bowl",
    ]

    /// Phrase patterns that indicate composite dishes (checked with "contains")
    private static let compositePatterns: [String] = [
        " with ", " and ", " in sauce", " in gravy", " in cream",
        " on toast", " on a bed of", " on rice", " on chips",
        " with sauce", " with gravy", " with vegetables", " with rice",
        " with noodles", " with salad", " with chips", " with fries",
        " with mash", " with coleslaw",
    ]

    /// Single-word queries that are too ambiguous for specific serving suggestions
    private static let ambiguousSingleWords: Set<String> = [
        "salmon", "chicken", "beef", "pork", "lamb", "turkey", "duck",
        "fish", "tuna", "cod", "haddock", "mackerel", "trout",
        "pasta", "rice", "bread", "noodles", "couscous",
        "curry", "pizza", "steak", "mince", "mincemeat",
        "sausage", "sausages", "bacon",
    ]

    /// Vague preparation words that don't clarify form factor
    private static let vaguePreparations: Set<String> = [
        "cooked", "fried", "roast", "roasted", "baked", "grilled",
        "steamed", "boiled", "poached",
    ]

    /// Form factor qualifiers that increase confidence
    private static let formFactorQualifiers: Set<String> = [
        "fillet", "breast", "thigh", "drumstick", "wing", "leg",
        "slice", "sliced", "diced", "cubed", "chopped", "minced",
        "whole", "half", "quarter",
        "steak", "chop", "cutlet", "escalope",
        "raw", "fresh",
    ]

    /// Packaged/prepared format indicators
    private static let packagedFormatIndicators: Set<String> = [
        "tinned", "canned", "jarred", "bottled",
        "frozen", "packet", "sachet", "pouch",
        "smoked", "cured", "dried",
    ]

    /// Check if text contains any composite dish indicator
    private func containsCompositeDishIndicator(_ text: String) -> Bool {
        let textLower = text.lowercased()

        // Check exact indicators
        for indicator in Self.compositeDishIndicators {
            if textLower.contains(indicator) {
                return true
            }
        }

        // Check pattern indicators
        for pattern in Self.compositePatterns {
            if textLower.contains(pattern) {
                return true
            }
        }

        return false
    }

    /// Check if the food item appears to be packaged/prepared format
    private func hasPackagedFormatIndicator(_ text: String) -> Bool {
        let textLower = text.lowercased()
        return Self.packagedFormatIndicators.contains(where: { textLower.contains($0) })
    }

    /// Check if the query contains form factor qualifiers
    private func hasFormFactorQualifier(_ text: String) -> Bool {
        let textLower = text.lowercased()
        return Self.formFactorQualifiers.contains(where: { textLower.contains($0) })
    }

    /// Calculate serving confidence and classification for a given query
    /// - Parameter query: The user's search query (if available, otherwise empty string)
    /// - Returns: ServingConfidence with classification and confidence score
    func servingConfidence(forQuery query: String = "") -> ServingConfidence {
        var score: Double = 0.5  // Start neutral
        var reasons: [String] = []
        var classification: ServingClassification = .ambiguous

        let queryLower = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let nameLower = name.lowercased()
        let queryWords = queryLower.split(separator: " ").map { String($0) }

        // ========================================
        // STEP 1: Check for COMPOSITE DISH (highest priority)
        // ========================================
        if containsCompositeDishIndicator(nameLower) || containsCompositeDishIndicator(queryLower) {
            classification = .compositeDish
            score = 0.9  // High confidence it's composite
            reasons.append("Contains composite dish indicator")

            return ServingConfidence(
                score: score,
                classification: classification,
                usesSafeOutput: true,  // ALWAYS use safe output for composite dishes
                reasons: reasons
            )
        }

        // ========================================
        // STEP 2: Check for BRANDED/PACKAGED
        // ========================================
        // Check if packaged format (tinned, canned, etc.)
        if hasPackagedFormatIndicator(nameLower) || hasPackagedFormatIndicator(queryLower) {
            classification = .brandedPackaged
            if servingSizeG != nil && servingSizeG! > 0 {
                score = 0.95
                reasons.append("Packaged item with known serving size")
            } else {
                score = 0.4  // Packaged but no serving info
                reasons.append("Packaged item without serving data")
            }
            return ServingConfidence(
                score: score,
                classification: classification,
                usesSafeOutput: score < ServingConfidence.highConfidenceThreshold,
                reasons: reasons
            )
        }

        // Check if it's a branded product (chocolate bars, drinks, etc. - already well-handled)
        // These already work well with the existing category system
        let brandLower = (brand ?? "").lowercased()
        let isBrandedSnack = Self.chocolateBarProducts.contains(where: { nameLower.contains($0) }) ||
                             Self.baggedChocolateProducts.contains(where: { nameLower.contains($0) }) ||
                             Self.softDrinkBrands.contains(where: { brandLower.contains($0) || nameLower.contains($0) })
        if isBrandedSnack {
            classification = .brandedPackaged
            score = 0.85
            reasons.append("Known branded product")
            return ServingConfidence(
                score: score,
                classification: classification,
                usesSafeOutput: false,  // Branded items can use their specific presets
                reasons: reasons
            )
        }

        // ========================================
        // STEP 3: Check for AMBIGUOUS query
        // ========================================

        // Rule 3a: Single-word generic ingredients are ambiguous
        if queryWords.count == 1 && Self.ambiguousSingleWords.contains(queryLower) {
            classification = .ambiguous
            score = 0.2
            reasons.append("Single-word generic ingredient")
            return ServingConfidence(
                score: score,
                classification: classification,
                usesSafeOutput: true,
                reasons: reasons
            )
        }

        // Rule 3b: Vague preparation + generic ingredient = ambiguous
        if queryWords.count == 2 {
            let firstWord = queryWords[0]
            let secondWord = queryWords[1]
            if Self.vaguePreparations.contains(firstWord) && Self.ambiguousSingleWords.contains(secondWord) {
                classification = .ambiguous
                score = 0.3
                reasons.append("Vague preparation with generic ingredient")
                return ServingConfidence(
                    score: score,
                    classification: classification,
                    usesSafeOutput: true,
                    reasons: reasons
                )
            }
        }

        // Rule 3c: Query significantly shorter than matched item name
        if !queryLower.isEmpty && queryLower.count < nameLower.count / 3 && queryLower.count < 8 {
            classification = .ambiguous
            score = 0.35
            reasons.append("Query much shorter than matched item")
            return ServingConfidence(
                score: score,
                classification: classification,
                usesSafeOutput: true,
                reasons: reasons
            )
        }

        // ========================================
        // STEP 4: ATOMIC classification (RAW or PREPARED)
        // ========================================

        // Determine if prepared based on cooking indicators in name
        let preparedIndicators = ["grilled", "roasted", "baked", "fried", "steamed", "boiled", "poached", "smoked", "cured"]
        let isPrepared = preparedIndicators.contains(where: { nameLower.contains($0) || queryLower.contains($0) })

        classification = isPrepared ? .atomicPrepared : .atomicRaw

        // Confidence adjustments
        score = 0.5

        // Boost: Has form factor qualifier (fillet, breast, etc.)
        if hasFormFactorQualifier(queryLower) || hasFormFactorQualifier(nameLower) {
            score += 0.25
            reasons.append("Has form factor qualifier")
        }

        // Boost: Verified item
        if isVerified {
            score += 0.1
            reasons.append("Verified item")
        }

        // Boost: Query closely matches item name
        if !queryLower.isEmpty && nameLower.hasPrefix(queryLower) {
            score += 0.15
            reasons.append("Query matches item name prefix")
        }

        // Reduce: Short query without qualifiers
        if queryLower.count < 12 && !hasFormFactorQualifier(queryLower) {
            score -= 0.1
            reasons.append("Short query without qualifiers")
        }

        // Ensure score is in valid range
        score = min(1.0, max(0.0, score))

        // Determine if should use safe output
        let usesSafeOutput = score < ServingConfidence.highConfidenceThreshold

        return ServingConfidence(
            score: score,
            classification: classification,
            usesSafeOutput: usesSafeOutput,
            reasons: reasons
        )
    }

    // Helper sets for branded product detection (extracted for reuse)
    // NOTE: Avoid short generic words that could match unrelated foods
    // e.g., "flake" matches "cornflakes" - use "cadbury flake" instead
    private static let chocolateBarProducts: Set<String> = [
        "mars bar", "mars chocolate", "snickers", "twix", "bounty", "milky way bar", "kitkat", "kit kat",
        "aero bar", "yorkie", "wispa bar", "cadbury flake", "flake bar", "crunchie", "double decker",
        "boost bar", "picnic bar", "dairy milk bar", "fruit & nut", "whole nut", "caramel bar",
        "turkish delight", "fudge bar", "curly wurly", "chomp", "freddo", "timeout",
        "toffee crisp", "drifter", "lion bar", "star bar", "topic bar"
    ]

    private static let baggedChocolateProducts: Set<String> = [
        "revels", "maltesers", "celebrations", "minstrels", "m&m", "m&ms",
        "buttons", "giant buttons", "heroes", "roses", "quality street",
        "after eight", "matchmakers", "galaxy counters", "milkybar buttons",
        "smarties", "aero bubbles", "bitsa wispa", "lindor", "lindt lindor",
        "ferrero rocher", "ferrero", "thorntons", "godiva", "guylian", "toblerone"
    ]

    private static let softDrinkBrands: Set<String> = [
        "coca-cola", "coca cola", "coke", "diet coke", "coke zero", "pepsi",
        "pepsi max", "fanta", "sprite", "7up", "7-up", "dr pepper", "irn-bru",
        "irn bru", "lucozade", "red bull", "monster", "relentless", "rockstar",
        "tango", "oasis", "schweppes", "san pellegrino", "fever-tree"
    ]

    // Track the query used for this food item (for serving classification)
    // This is set when the food is selected from search results
    private var _searchQuery: String = ""

    /// Set the search query that led to this food item
    mutating func setSearchQuery(_ query: String) {
        _searchQuery = query
    }

    /// Auto-detect food category from name, brand, and serving info
    var detectedCategory: FoodCategory {
        let nameLower = name.lowercased()
        let brandLower = (brand ?? "").lowercased()
        let servingLower = (servingDescription ?? "").lowercased()

        // Helper to check if word appears with word boundaries (not as substring of another word)
        // e.g., "tea" should match "green tea" but NOT "steak" (s-tea-k)
        func containsWholeWord(_ text: String, _ word: String) -> Bool {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
            return text.range(of: pattern, options: .regularExpression) != nil
        }

        // Drink brands
        let softDrinkBrands = ["coca-cola", "coca cola", "coke", "diet coke", "coke zero", "pepsi", "pepsi max", "fanta", "sprite", "7up", "7-up", "dr pepper", "irn-bru", "irn bru", "lucozade", "red bull", "monster", "relentless", "rockstar", "tango", "oasis", "ribena", "vimto", "schweppes", "san pellegrino", "fever-tree"]
        let juiceBrands = ["tropicana", "innocent", "naked", "copella", "del monte"]
        let hotDrinkBrands = ["nescafe", "kenco", "douwe egberts", "twinings", "pg tips", "yorkshire tea", "tetley"]
        let waterBrands = ["evian", "volvic", "buxton", "highland spring", "perrier", "badoit"]

        // Bagged/boxed chocolate products (check BEFORE generic brand detection)
        // These come in bags/pouches/boxes, not as bars
        let baggedChocolateProducts = ["revels", "maltesers", "celebrations", "minstrels", "m&m", "m&ms", "buttons", "giant buttons", "heroes", "roses", "quality street", "after eight", "matchmakers", "galaxy counters", "milkybar buttons", "smarties", "aero bubbles", "bitsa wispa", "lindor", "lindt lindor", "ferrero rocher", "ferrero", "thorntons", "godiva", "guylian", "toblerone"]

        // Actual chocolate BAR products (single bars, not bags)
        // NOTE: Avoid short words that could match unrelated foods (e.g., "flake" matches "cornflakes")
        let chocolateBarProducts = ["mars bar", "mars chocolate", "snickers", "twix", "bounty", "milky way bar", "kitkat", "kit kat", "aero bar", "yorkie", "wispa bar", "cadbury flake", "flake bar", "crunchie", "double decker", "boost bar", "picnic bar", "dairy milk bar", "fruit & nut", "whole nut", "caramel bar", "turkish delight", "fudge bar", "curly wurly", "chomp", "freddo", "timeout", "toffee crisp", "drifter", "lion bar", "star bar", "topic bar"]

        // Sweet/candy brands
        let sweetBrands = ["haribo", "maynards", "rowntrees", "skittles", "starburst", "jelly belly", "swizzels", "chupa chups", "chewits", "refreshers", "drumstick", "love hearts", "parma violets"]

        // Check for specific bagged chocolate products FIRST (most specific)
        if baggedChocolateProducts.contains(where: { nameLower.contains($0) }) {
            return .chocolateBag
        }

        // Check for specific chocolate bar products
        if chocolateBarProducts.contains(where: { nameLower.contains($0) }) {
            return .chocolateBar
        }

        // Check brands (less specific)
        if softDrinkBrands.contains(where: { brandLower.contains($0) || nameLower.contains($0) }) {
            return .softDrink
        }
        if juiceBrands.contains(where: { brandLower.contains($0) || nameLower.contains($0) }) {
            return .juice
        }
        if hotDrinkBrands.contains(where: { brandLower.contains($0) || nameLower.contains($0) }) {
            return .hotDrink
        }
        if waterBrands.contains(where: { brandLower.contains($0) || nameLower.contains($0) }) {
            return .water
        }
        if sweetBrands.contains(where: { brandLower.contains($0) || nameLower.contains($0) }) {
            return .sweets
        }

        // Check name keywords - Drinks & Snacks
        let softDrinkKeywords = ["cola", "lemonade", "soda", "fizzy", "carbonated", "energy drink", "sparkling"]
        // Cordial/squash keywords and UK brands - check BEFORE juice since these are concentrated
        let cordialKeywords = ["cordial", "squash", "dilute", "diluting", "concentrate"]
        let cordialBrands = ["robinsons", "robinson's", "ribena", "vimto", "miwadi", "mi wadi", "rocks", "belvoir", "bottlegreen", "bottle green", "elderflower cordial", "lime cordial", "barley water"]
        let juiceKeywords = ["juice", "smoothie"]  // Removed squash/cordial - now separate category
        let hotDrinkKeywords = ["coffee", "tea", "latte", "cappuccino", "espresso", "americano", "hot chocolate", "mocha"]
        let waterKeywords = ["water", "sparkling water", "still water", "mineral water"]
        let alcoholKeywords = ["beer", "lager", "ale", "wine", "cider", "prosecco", "champagne"]
        let spiritKeywords = ["vodka", "gin", "whisky", "whiskey", "rum", "brandy", "tequila", "bourbon", "scotch", "liqueur", "schnapps", "sambuca", "jagermeister", "baileys"]
        let chocolateKeywords = ["chocolate bar", "chocolate", "truffle"]
        let sweetKeywords = ["gummy", "jelly", "sweets", "candy", "lollipop", "toffee", "fudge", "mints"]
        let crispKeywords = ["crisps", "chips", "pretzels", "popcorn", "puffs"]

        // Check cordials FIRST - these are concentrated and need diluting
        // Also check serving description for "dilute" hints from Tesco/supermarket data
        if cordialKeywords.contains(where: { nameLower.contains($0) }) { return .cordial }
        if cordialBrands.contains(where: { brandLower.contains($0) || nameLower.contains($0) }) { return .cordial }
        // Check serving description for dilution instructions (common in Tesco data)
        if servingLower.contains("dilute") || servingLower.contains("to taste") || servingLower.contains("add water") { return .cordial }

        if softDrinkKeywords.contains(where: { nameLower.contains($0) }) { return .softDrink }
        if juiceKeywords.contains(where: { nameLower.contains($0) }) { return .juice }
        // Use word boundary matching for short words that could be substrings
        // "tea" in "steak", "water" in "freshwater fish", "ale" in "bale"
        let hotDrinkShortWords = ["tea", "coffee", "latte", "mocha", "cocoa"]
        let hotDrinkLongWords = ["cappuccino", "espresso", "americano", "hot chocolate"]
        if hotDrinkLongWords.contains(where: { nameLower.contains($0) }) { return .hotDrink }
        if hotDrinkShortWords.contains(where: { containsWholeWord(nameLower, $0) }) { return .hotDrink }
        // Water - use word boundary to avoid "freshwater fish", "watermelon" etc.
        if containsWholeWord(nameLower, "water") && !nameLower.contains("watermelon") { return .water }
        if spiritKeywords.contains(where: { nameLower.contains($0) }) { return .spirit }
        // Alcohol - use word boundary for "ale" (could be in "bale", "sale", etc.)
        let alcoholShortWords = ["ale", "beer", "wine"]
        let alcoholLongWords = ["lager", "cider", "prosecco", "champagne"]
        if alcoholLongWords.contains(where: { nameLower.contains($0) }) { return .alcoholicDrink }
        if alcoholShortWords.contains(where: { containsWholeWord(nameLower, $0) }) { return .alcoholicDrink }
        if chocolateKeywords.contains(where: { nameLower.contains($0) }) { return .chocolateBar }
        if sweetKeywords.contains(where: { nameLower.contains($0) }) { return .sweets }
        if crispKeywords.contains(where: { nameLower.contains($0) }) { return .crisps }

        // Generic food keywords (check AFTER snacks/drinks to avoid false matches)
        let oilKeywords = ["olive oil", "vegetable oil", "sunflower oil", "coconut oil", "rapeseed oil", "sesame oil", "avocado oil", "cooking oil"]
        let butterKeywords = ["butter", "margarine", "spread"]
        let condimentKeywords = ["jam", "marmalade", "honey", "syrup", "maple syrup", "golden syrup", "treacle", "mayonnaise", "mayo", "ketchup", "mustard", "brown sauce", "bbq sauce", "hot sauce", "sriracha", "pesto", "chutney", "pickle", "relish", "salad cream", "tartar sauce", "vinaigrette", "dressing"]
        let fruitKeywords = ["apple", "banana", "orange", "pear", "peach", "plum", "grape", "strawberr", "blueberr", "raspberr", "blackberr", "cherry", "mango", "pineapple", "kiwi", "melon", "watermelon", "grapefruit", "nectarine", "apricot", "fig", "papaya", "pomegranate", "passion fruit", "lychee", "dragon fruit", "avocado", "clementine", "satsuma", "tangerine", "lime", "lemon"]
        let driedFruitKeywords = ["raisin", "sultana", "currant", "dried apricot", "dried mango", "dried cranberr", "dried fig", "prune", "date", "dried fruit", "trail mix", "mixed dried"]
        let eggKeywords = ["egg", "eggs", "omelette", "scrambled", "poached egg", "fried egg", "boiled egg"]
        let riceKeywords = ["rice", "basmati", "jasmine rice", "brown rice", "wild rice", "risotto", "pilau", "pilaf", "fried rice", "quinoa", "couscous", "bulgur"]
        let pastaKeywords = ["pasta", "spaghetti", "penne", "fusilli", "tagliatelle", "linguine", "macaroni", "lasagne", "ravioli", "tortellini", "gnocchi", "noodles", "ramen", "udon"]
        // Sliced bread only - whole items moved to bakeryItem
        let breadKeywords = ["bread", "toast", "sliced bread", "loaf", "sandwich bread"]
        // Whole bakery items - not sliced
        let bakeryItemKeywords = ["bagel", "croissant", "pitta", "pita", "naan", "chapati", "tortilla", "wrap", "ciabatta", "baguette", "brioche", "muffin", "english muffin", "scone", "crumpet", "pancake", "waffle", "roll", "bun", "hot dog bun", "burger bun", "sourdough roll", "flatbread", "roti", "paratha"]
        let cerealKeywords = ["oats", "porridge", "oatmeal", "granola", "muesli", "cornflakes", "corn flakes", "bran flakes", "weetabix", "shreddies", "cheerios", "special k", "rice krispies", "coco pops", "frosties", "cereal"]
        let nutKeywords = ["almond", "walnut", "cashew", "pistachio", "hazelnut", "pecan", "macadamia", "brazil nut", "peanut", "mixed nuts", "sunflower seed", "pumpkin seed", "chia seed", "flaxseed", "sesame seed"]
        let cheeseKeywords = ["cheese", "cheddar", "mozzarella", "parmesan", "brie", "camembert", "stilton", "feta", "gouda", "edam", "gruyere", "emmental", "halloumi", "cottage cheese", "cream cheese", "ricotta", "mascarpone"]
        let milkKeywords = ["milk", "whole milk", "semi-skimmed", "skimmed milk", "oat milk", "almond milk", "soya milk", "coconut milk"]
        let yogurtKeywords = ["yogurt", "yoghurt", "greek yogurt", "natural yogurt", "fromage frais", "skyr", "kefir"]
        // Processed meats with per-item portions (bacon rashers, sausages, ham slices)
        let processedMeatKeywords = ["bacon", "sausage", "sausages", "ham", "salami", "chorizo", "pepperoni", "prosciutto", "pancetta", "hot dog", "frankfurter", "bratwurst", "black pudding", "white pudding", "haggis"]
        // Regular meat portions (chicken breast, beef steak, etc.)
        let meatKeywords = ["chicken", "beef", "pork", "lamb", "turkey", "duck", "mince", "steak", "chop", "roast", "fillet", "breast", "thigh", "drumstick", "wing", "ribeye", "sirloin", "rump"]
        let fishKeywords = ["salmon", "tuna", "cod", "haddock", "mackerel", "sardine", "trout", "sea bass", "bream", "plaice", "sole", "halibut", "prawn", "shrimp", "crab", "lobster", "mussel", "scallop", "squid", "fish finger", "fish cake"]
        // Aromatics - small portions (cloves, pieces)
        let aromaticsKeywords = ["garlic", "ginger", "shallot", "fresh ginger", "garlic clove"]
        // Vegetables (removed garlic - now in aromatics)
        let vegetableKeywords = ["broccoli", "carrot", "potato", "sweet potato", "onion", "pepper", "tomato", "cucumber", "lettuce", "spinach", "kale", "cabbage", "cauliflower", "courgette", "aubergine", "zucchini", "mushroom", "asparagus", "green bean", "pea", "sweetcorn", "beetroot", "parsnip", "turnip", "swede", "leek", "celery", "sprout"]
        // Dips - tablespoon portions
        let dipKeywords = ["hummus", "houmous", "guacamole", "salsa", "tzatziki", "raita", "baba ganoush", "taramasalata", "sour cream dip", "onion dip", "cheese dip", "bean dip"]
        // Legumes (removed hummus - now in dips)
        let legumeKeywords = ["beans", "lentils", "chickpea", "black bean", "kidney bean", "butter bean", "cannellini", "borlotti", "edamame", "baked beans"]
        let tofuKeywords = ["tofu", "tempeh", "seitan", "quorn", "textured vegetable protein", "tvp", "soya mince", "veggie mince"]

        // Check generic food categories (order matters - more specific first)
        if oilKeywords.contains(where: { nameLower.contains($0) }) { return .oil }
        if butterKeywords.contains(where: { nameLower.contains($0) }) && !nameLower.contains("peanut butter") && !nameLower.contains("almond butter") { return .butter }
        if condimentKeywords.contains(where: { nameLower.contains($0) }) { return .condiment }
        if dipKeywords.contains(where: { nameLower.contains($0) }) { return .dip }
        if eggKeywords.contains(where: { nameLower.contains($0) }) && !nameLower.contains("aubergine") { return .egg }
        if yogurtKeywords.contains(where: { nameLower.contains($0) }) { return .yogurt }
        if cheeseKeywords.contains(where: { nameLower.contains($0) }) { return .cheese }
        // Check milk but exclude "milk chocolate" products and butter/margarine products
        if milkKeywords.contains(where: { nameLower.contains($0) }) &&
           !nameLower.contains("milk chocolate") &&
           !nameLower.contains("chocolate milk") &&
           !nameLower.contains("buttermilk") &&
           !butterKeywords.contains(where: { nameLower.contains($0) }) { return .milk }
        if cerealKeywords.contains(where: { nameLower.contains($0) }) { return .cereal }
        if nutKeywords.contains(where: { nameLower.contains($0) }) { return .nuts }
        if riceKeywords.contains(where: { nameLower.contains($0) }) { return .rice }
        if pastaKeywords.contains(where: { nameLower.contains($0) }) { return .pasta }
        // Check bakery items BEFORE bread (more specific - whole items vs sliced)
        if bakeryItemKeywords.contains(where: { nameLower.contains($0) }) { return .bakeryItem }
        if breadKeywords.contains(where: { nameLower.contains($0) }) { return .bread }
        if tofuKeywords.contains(where: { nameLower.contains($0) }) { return .tofu }
        // Check processed meats BEFORE general meat (per-item vs weight portions)
        if processedMeatKeywords.contains(where: { nameLower.contains($0) }) { return .processedMeat }
        if meatKeywords.contains(where: { nameLower.contains($0) }) { return .meat }
        if fishKeywords.contains(where: { nameLower.contains($0) }) { return .fish }
        // Check aromatics BEFORE vegetables (small portions vs regular)
        if aromaticsKeywords.contains(where: { nameLower.contains($0) }) { return .aromatics }
        // Check dips BEFORE legumes (hummus is a dip, not a bean dish)
        if legumeKeywords.contains(where: { nameLower.contains($0) }) { return .legume }
        if vegetableKeywords.contains(where: { nameLower.contains($0) }) { return .vegetable }
        // Check dried fruit BEFORE fresh fruit (more specific)
        if driedFruitKeywords.contains(where: { nameLower.contains($0) }) { return .driedFruit }
        if fruitKeywords.contains(where: { nameLower.contains($0) }) { return .fruit }

        // Check serving description for ml - but ONLY if it's clearly a drink
        // Don't assume ml = drink (sauces, marinades, etc also use ml)
        if servingLower.contains("ml") {
            // It's measured in ml - check if it's actually a drink
            if nameLower.contains("juice") || nameLower.contains("smoothie") { return .juice }
            if nameLower.contains("water") && !nameLower.contains("sauce") { return .water }
            // DON'T default to softDrink - could be a sauce, marinade, etc.
        }

        return .other
    }

    /// Returns true if this food category represents a liquid/drink
    /// IMPORTANT: Chocolate products are NEVER liquid, even if their serving description mentions ml
    var isLiquidCategory: Bool {
        // PRIORITY: Firebase category data is authoritative (from AI categorization)
        // If the backend says it uses "ml", it's a liquid
        if let unit = suggestedServingUnit, !unit.isEmpty {
            return unit == "ml"
        }

        let nameLower = name.lowercased()

        // FIRST: Check for explicit powder/mix forms - these are ALWAYS solids (grams)
        // "Hot Chocolate Powder", "Milkshake Mix", "Coffee Granules" etc
        let powderIndicators = ["powder", "mix", "granules", "instant", "sachet", "packet",
                                "dry mix", "concentrate"]
        if powderIndicators.contains(where: { nameLower.contains($0) }) {
            return false  // Powders are measured in grams
        }

        // SECOND: Use serving size to detect likely powders even without "powder" in name
        // Hot chocolate/cocoa/milkshake with small serving (under 50g) is almost certainly powder
        // Ready-to-drink versions are typically 200-500ml
        let couldBePowder = nameLower.contains("hot chocolate") || nameLower.contains("cocoa") ||
                           nameLower.contains("milkshake") || nameLower.contains("drinking chocolate")
        if couldBePowder, let servingG = servingSizeG, servingG > 0 && servingG < 50 {
            return false  // Small serving size indicates powder form
        }

        // THEN: Check for explicit drink indicators (ready-to-drink liquids)
        // This ensures "Chocolate Milkshake", "Mars Milk Drink" etc are correctly treated as liquids
        // IMPORTANT: Use word boundary matching for short words to avoid false positives
        // e.g., "steak" contains "tea", "water" is in "freshwater fish"

        // Helper to check if word appears with word boundaries (not as substring of another word)
        func containsWholeWord(_ text: String, _ word: String) -> Bool {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
            return text.range(of: pattern, options: .regularExpression) != nil
        }

        // Long/specific drink words - safe to use simple contains
        let safeDrinkIndicators = ["milkshake", "milk shake", "smoothie", "lemonade", "cappuccino",
                                   "espresso", "frappuccino", "hot chocolate", "drinking chocolate",
                                   "flat white", "americano", "macchiato", "iced coffee", "cold brew"]
        if safeDrinkIndicators.contains(where: { nameLower.contains($0) }) {
            return true
        }

        // Coffee shop brands - almost everything they sell is a drink
        let coffeeShopBrands = ["starbucks", "costa", "caffe nero", "pret a manger", "pret"]
        let brandLower = (brand ?? "").lowercased()
        if coffeeShopBrands.contains(where: { brandLower.contains($0) || nameLower.contains($0) }) {
            // Exception: food items from coffee shops
            let foodExceptions = ["sandwich", "wrap", "panini", "cake", "muffin", "cookie", "brownie", "croissant", "pastry", "bagel", "toast"]
            if !foodExceptions.contains(where: { nameLower.contains($0) }) {
                return true
            }
        }

        // Short words that could be substrings - use word boundary matching
        // "tea" in "steak", "water" in "freshwater", "cola" in "chocolate", "juice" in various
        let shortDrinkWords = ["tea", "coffee", "water", "cola", "juice", "drink", "shake",
                               "squash", "cordial", "latte", "mocha", "cocoa", "pepsi", "fanta", "sprite"]
        if shortDrinkWords.contains(where: { containsWholeWord(nameLower, $0) }) {
            return true
        }

        // THEN: Check for chocolate BARS/SNACKS (not drinks - those were caught above)
        // This prevents "Mars Chocolate Bar" from showing ml portions
        let chocolateSnackIndicators = ["chocolate bar", "mars bar", "snickers", "twix", "bounty",
                                        "kitkat", "kit kat", "milky way bar", "aero bar", "yorkie",
                                        "wispa", "flake", "crunchie", "double decker", "boost",
                                        "picnic", "dairy milk", "freddo", "timeout", "lion bar"]
        if chocolateSnackIndicators.contains(where: { nameLower.contains($0) }) {
            return false
        }

        // Also check for generic "chocolate" WITHOUT drink indicators (already checked above)
        // If it just says "chocolate" and isn't a drink, it's likely a bar/snack
        if nameLower.contains("chocolate") && !nameLower.contains("milk") {
            return false
        }

        switch detectedCategory {
        case .softDrink, .cordial, .juice, .hotDrink, .water, .alcoholicDrink, .milk:
            return true
        case .chocolateBar, .chocolateBag, .sweets, .crisps:
            // Never treat snacks as liquid
            return false
        default:
            return false
        }
    }

    /// Formats a serving size with appropriate unit (ml for drinks, g for solids)
    /// This ensures drinks show as "330ml" instead of "330g"
    func formattedServingSize(_ grams: Double) -> String {
        if isLiquidCategory {
            // Use ml for drinks
            if grams >= 1000 {
                let liters = grams / 1000
                if liters == liters.rounded() {
                    return "\(Int(liters))L"
                } else {
                    return String(format: "%.1fL", liters)
                }
            } else {
                return "\(Int(grams))ml"
            }
        } else {
            // Use g for solid foods
            return "\(Int(grams))g"
        }
    }

    /// Returns true if this item has a meaningful serving size (not just default 100g)
    /// Used for ranking to prefer items with actual serving data
    var hasActualServingSize: Bool {
        // Has explicit servingSizeG that isn't 100g
        if let g = servingSizeG, g > 0 && g != 100 {
            return true
        }
        // Has a description that contains size info
        if let desc = servingDescription,
           desc.lowercased().contains("ml") || desc.lowercased().contains("g)") {
            return true
        }
        // Name contains size info (e.g., "330ml", "51g")
        let nameLower = name.lowercased()
        if nameLower.range(of: "\\d+\\s*(ml|g)\\b", options: .regularExpression) != nil {
            return true
        }
        return false
    }

    // MARK: - Fasting Philosophy Helpers

    /// Determines if this food is allowed during a fast based on the user's drinks philosophy
    /// Returns true if the food should bypass the fasting prompt (i.e., allowed during fast)
    func isAllowedDuringFast(philosophy: AllowedDrinksPhilosophy) -> Bool {
        switch philosophy {
        case .strict:
            // Strict: Only water, plain tea, black coffee (essentially 0 cal, 0 sugar)
            // Water is always allowed
            if detectedCategory == .water && calories <= 5 {
                return true
            }
            // Plain black coffee or tea with negligible calories
            if detectedCategory == .hotDrink && calories <= 5 && sugar <= 0.5 {
                return true
            }
            return false

        case .practical:
            // Practical: Sugar-free drinks allowed (low/no sugar, low/no calories)
            // This includes diet sodas, Coke Zero, sugar-free energy drinks, etc.
            guard isLiquidCategory else { return false }

            // Allow drinks with low sugar (<1g per 100ml) and low calories (<10 per 100ml)
            // This covers diet/zero drinks which typically have 0-1 cal and 0 sugar
            let isSugarFree = sugar < 1.0
            let isLowCalorie = calories < 10.0

            return isSugarFree && isLowCalorie
        }
    }

    /// Fast food restaurant brands that shouldn't show generic preset portions
    /// These items are inherently per-unit (burger, meal, etc.) even if not marked as such
    private static let fastFoodBrandsNoPresets: Set<String> = [
        "mcdonald's", "mcdonalds", "burger king", "kfc", "domino's", "dominos",
        "pizza hut", "starbucks", "dunkin", "krispy kreme", "nando's", "nandos",
        "greggs", "costa", "pret", "pret a manger", "wendy's", "wendys",
        "taco bell", "five guys", "shake shack", "chick-fil-a", "chickfila",
        "popeyes", "tim hortons", "wetherspoon", "wetherspoons", "subway",
        "chipotle", "papa john's", "papa johns", "pizza express", "wagamama",
        "gourmet burger kitchen", "gbk", "byron", "honest burgers", "leon",
        "itsu", "tortilla", "yo! sushi", "harvester", "toby carvery", "beefeater",
        "frankie & benny's", "arby's", "carl's jr", "sonic", "white castle",
        "whataburger", "del taco", "wingstop", "buffalo wild wings", "zaxby's",
        "bojangles", "raising cane's", "jack in the box"
    ]

    /// Returns true if this food should show preset portion options
    /// NOTE: This uses the basic category detection. For query-aware detection
    /// that prevents inappropriate presets for composite dishes, use
    /// `shouldShowCategoryPresets(forQuery:)` instead.
    var hasPresetPortions: Bool {
        // If already has database portions, use those instead
        if hasPortionOptions { return false }
        // Per-unit items don't need presets
        if isPerUnit == true { return false }
        // Fast food restaurant items are inherently per-unit - don't show generic presets
        // Normalize apostrophes for matching (curly ' vs straight ')
        let brandLower = (brand?.lowercased() ?? "").replacingOccurrences(of: "'", with: "'")
        let nameLower = name.lowercased().replacingOccurrences(of: "'", with: "'")
        if Self.fastFoodBrandsNoPresets.contains(where: { brandLower.contains($0) || nameLower.contains($0) }) {
            return false
        }

        // CRITICAL: Check for composite dish indicators BEFORE category detection
        // This prevents "salmon en croute" from getting fish fillet presets
        if containsCompositeDishIndicator(nameLower) {
            return false  // Composite dishes should use safe output, not category presets
        }

        // Only show presets for detectable categories
        return detectedCategory != .other
    }

    /// Query-aware check for whether to show category-specific presets
    /// Use this when you have the original search query available
    /// - Parameter query: The user's search query
    /// - Returns: true if category-specific presets are appropriate
    func shouldShowCategoryPresets(forQuery query: String) -> Bool {
        // First check basic prerequisites
        if hasPortionOptions { return false }
        if isPerUnit == true { return false }

        let brandLower = (brand?.lowercased() ?? "").replacingOccurrences(of: "'", with: "'")
        let nameLower = name.lowercased().replacingOccurrences(of: "'", with: "'")

        if Self.fastFoodBrandsNoPresets.contains(where: { brandLower.contains($0) || nameLower.contains($0) }) {
            return false
        }

        // Use the confidence system to determine appropriate output
        let confidence = servingConfidence(forQuery: query)

        // If classification indicates safe output should be used, don't show category presets
        if confidence.usesSafeOutput {
            return false
        }

        // Only show presets for detectable categories with high confidence
        return detectedCategory != .other
    }

    /// Get appropriate portion options based on query and classification
    /// This is the RECOMMENDED method for getting portion options
    /// - Parameter query: The user's search query
    /// - Returns: Array of portion options appropriate for this food/query combination
    func portionsForQuery(_ query: String) -> [PortionOption] {
        // 1. Database portions always take priority
        if let dbPortions = portions, !dbPortions.isEmpty {
            return dbPortions
        }

        // 2. If food has a real serving size (not default 100g), just use that
        // No need for multiple presets - user can adjust with quantity or custom amount
        if let servingG = servingSizeG, servingG > 0 && servingG != 100 {
            let unit = isLiquidCategory ? "ml" : "g"
            let caloriesForServing = calories * (servingG / 100)
            return [
                PortionOption(name: "1 serving (\(Int(servingG))\(unit))", calories: caloriesForServing, serving_g: servingG)
            ]
        }

        // 3. Firebase category-based portions (from AI categorization)
        // Only used when serving size is default 100g
        if hasFirebaseCategoryPortions {
            return firebaseCategoryPortions
        }

        // 4. Per-unit items don't need presets
        if isPerUnit == true {
            return []
        }

        // 5. Fast food items don't need presets
        let brandLower = (brand?.lowercased() ?? "").replacingOccurrences(of: "'", with: "'")
        let nameLower = name.lowercased().replacingOccurrences(of: "'", with: "'")
        if Self.fastFoodBrandsNoPresets.contains(where: { brandLower.contains($0) || nameLower.contains($0) }) {
            return []
        }

        // 6. Fallback: Only show local category presets if detected, otherwise no presets
        if detectedCategory != .other {
            return presetPortions
        }

        // No presets - user can use custom amount
        return []
    }

    /// Preset serving size options based on food category
    /// Each preset includes: name, size in ml or g, calculated calories
    var presetPortions: [PortionOption] {
        guard hasPresetPortions else { return [] }

        // Nutrition is per 100g/100ml, calculate for each preset size
        let caloriesPer100 = calories

        switch detectedCategory {
        case .softDrink:
            return [
                PortionOption(name: "200ml Glass", calories: caloriesPer100 * 2, serving_g: 200),
                PortionOption(name: "250ml", calories: caloriesPer100 * 2.5, serving_g: 250),
                PortionOption(name: "330ml Can", calories: caloriesPer100 * 3.3, serving_g: 330),
                PortionOption(name: "500ml Bottle", calories: caloriesPer100 * 5, serving_g: 500)
            ]
        case .cordial:
            // Cordials are concentrated - show undiluted serving sizes
            // Typical dilution is 1:4 or 1:5 (e.g., 50ml cordial makes 250ml drink)
            return [
                PortionOption(name: "25ml (makes 1 glass)", calories: caloriesPer100 * 0.25, serving_g: 25),
                PortionOption(name: "40ml (makes 200ml)", calories: caloriesPer100 * 0.40, serving_g: 40),
                PortionOption(name: "50ml (makes 250ml)", calories: caloriesPer100 * 0.50, serving_g: 50),
                PortionOption(name: "75ml (makes 375ml)", calories: caloriesPer100 * 0.75, serving_g: 75)
            ]
        case .juice:
            return [
                PortionOption(name: "150ml Glass", calories: caloriesPer100 * 1.5, serving_g: 150),
                PortionOption(name: "200ml", calories: caloriesPer100 * 2, serving_g: 200),
                PortionOption(name: "250ml Carton", calories: caloriesPer100 * 2.5, serving_g: 250),
                PortionOption(name: "330ml", calories: caloriesPer100 * 3.3, serving_g: 330)
            ]
        case .hotDrink:
            return [
                PortionOption(name: "Small (250ml)", calories: caloriesPer100 * 2.5, serving_g: 250),
                PortionOption(name: "Regular (350ml)", calories: caloriesPer100 * 3.5, serving_g: 350),
                PortionOption(name: "Large (450ml)", calories: caloriesPer100 * 4.5, serving_g: 450)
            ]
        case .water:
            return [
                PortionOption(name: "250ml Glass", calories: caloriesPer100 * 2.5, serving_g: 250),
                PortionOption(name: "500ml Bottle", calories: caloriesPer100 * 5, serving_g: 500),
                PortionOption(name: "750ml", calories: caloriesPer100 * 7.5, serving_g: 750),
                PortionOption(name: "1L Bottle", calories: caloriesPer100 * 10, serving_g: 1000)
            ]
        case .alcoholicDrink:
            return [
                PortionOption(name: "125ml Glass", calories: caloriesPer100 * 1.25, serving_g: 125),
                PortionOption(name: "175ml Glass", calories: caloriesPer100 * 1.75, serving_g: 175),
                PortionOption(name: "250ml Glass", calories: caloriesPer100 * 2.5, serving_g: 250),
                PortionOption(name: "330ml Bottle", calories: caloriesPer100 * 3.3, serving_g: 330)
            ]
        case .spirit:
            return [
                PortionOption(name: "Single (25ml)", calories: caloriesPer100 * 0.25, serving_g: 25),
                PortionOption(name: "Double (50ml)", calories: caloriesPer100 * 0.50, serving_g: 50),
                PortionOption(name: "Large (75ml)", calories: caloriesPer100 * 0.75, serving_g: 75)
            ]
        case .chocolateBar:
            return [
                PortionOption(name: "Fun Size (20g)", calories: caloriesPer100 * 0.2, serving_g: 20),
                PortionOption(name: "Standard Bar (45g)", calories: caloriesPer100 * 0.45, serving_g: 45),
                PortionOption(name: "Duo/King Size (75g)", calories: caloriesPer100 * 0.75, serving_g: 75),
                PortionOption(name: "Sharing (100g)", calories: caloriesPer100 * 1, serving_g: 100)
            ]
        case .chocolateBag:
            return [
                PortionOption(name: "Treat Bag (36g)", calories: caloriesPer100 * 0.36, serving_g: 36),
                PortionOption(name: "Standard Bag (85g)", calories: caloriesPer100 * 0.85, serving_g: 85),
                PortionOption(name: "Pouch (112g)", calories: caloriesPer100 * 1.12, serving_g: 112),
                PortionOption(name: "Share Bag (175g)", calories: caloriesPer100 * 1.75, serving_g: 175)
            ]
        case .sweets:
            return [
                PortionOption(name: "Small Bag (30g)", calories: caloriesPer100 * 0.3, serving_g: 30),
                PortionOption(name: "Regular Bag (50g)", calories: caloriesPer100 * 0.5, serving_g: 50),
                PortionOption(name: "Share Bag (100g)", calories: caloriesPer100 * 1, serving_g: 100),
                PortionOption(name: "Large Bag (175g)", calories: caloriesPer100 * 1.75, serving_g: 175)
            ]
        case .crisps:
            return [
                PortionOption(name: "Snack Bag (25g)", calories: caloriesPer100 * 0.25, serving_g: 25),
                PortionOption(name: "Standard Bag (32.5g)", calories: caloriesPer100 * 0.325, serving_g: 32),
                PortionOption(name: "Grab Bag (50g)", calories: caloriesPer100 * 0.5, serving_g: 50),
                PortionOption(name: "Share Bag (150g)", calories: caloriesPer100 * 1.5, serving_g: 150)
            ]
        case .iceCream:
            return [
                PortionOption(name: "1 Scoop (60g)", calories: caloriesPer100 * 0.6, serving_g: 60),
                PortionOption(name: "2 Scoops (120g)", calories: caloriesPer100 * 1.2, serving_g: 120),
                PortionOption(name: "Small Tub (100g)", calories: caloriesPer100 * 1, serving_g: 100)
            ]
        // MARK: - Generic Food Presets
        case .oil:
            return [
                PortionOption(name: "1 tsp (5g)", calories: caloriesPer100 * 0.05, serving_g: 5),
                PortionOption(name: "1 tbsp (14g)", calories: caloriesPer100 * 0.14, serving_g: 14),
                PortionOption(name: "2 tbsp (28g)", calories: caloriesPer100 * 0.28, serving_g: 28)
            ]
        case .butter:
            return [
                PortionOption(name: "Pat (5g)", calories: caloriesPer100 * 0.05, serving_g: 5),
                PortionOption(name: "Spread (10g)", calories: caloriesPer100 * 0.10, serving_g: 10),
                PortionOption(name: "1 tbsp (14g)", calories: caloriesPer100 * 0.14, serving_g: 14),
                PortionOption(name: "Generous (20g)", calories: caloriesPer100 * 0.20, serving_g: 20)
            ]
        case .condiment:
            return [
                PortionOption(name: "1 tsp (7g)", calories: caloriesPer100 * 0.07, serving_g: 7),
                PortionOption(name: "1 tbsp (15g)", calories: caloriesPer100 * 0.15, serving_g: 15),
                PortionOption(name: "2 tbsp (30g)", calories: caloriesPer100 * 0.30, serving_g: 30),
                PortionOption(name: "Generous (50g)", calories: caloriesPer100 * 0.50, serving_g: 50)
            ]
        case .dip:
            return [
                PortionOption(name: "1 tbsp (15g)", calories: caloriesPer100 * 0.15, serving_g: 15),
                PortionOption(name: "2 tbsp (30g)", calories: caloriesPer100 * 0.30, serving_g: 30),
                PortionOption(name: "Small pot (50g)", calories: caloriesPer100 * 0.50, serving_g: 50),
                PortionOption(name: "Regular pot (85g)", calories: caloriesPer100 * 0.85, serving_g: 85)
            ]
        case .fruit:
            return [
                PortionOption(name: "Small (80g)", calories: caloriesPer100 * 0.8, serving_g: 80),
                PortionOption(name: "Medium (120g)", calories: caloriesPer100 * 1.2, serving_g: 120),
                PortionOption(name: "Large (180g)", calories: caloriesPer100 * 1.8, serving_g: 180)
            ]
        case .driedFruit:
            return [
                PortionOption(name: "Small handful (20g)", calories: caloriesPer100 * 0.2, serving_g: 20),
                PortionOption(name: "Handful (30g)", calories: caloriesPer100 * 0.3, serving_g: 30),
                PortionOption(name: "Snack portion (40g)", calories: caloriesPer100 * 0.4, serving_g: 40),
                PortionOption(name: "Generous (50g)", calories: caloriesPer100 * 0.5, serving_g: 50)
            ]
        case .egg:
            return [
                PortionOption(name: "1 egg (50g)", calories: caloriesPer100 * 0.5, serving_g: 50),
                PortionOption(name: "2 eggs (100g)", calories: caloriesPer100 * 1.0, serving_g: 100),
                PortionOption(name: "3 eggs (150g)", calories: caloriesPer100 * 1.5, serving_g: 150)
            ]
        case .rice:
            return [
                PortionOption(name: "Small (100g)", calories: caloriesPer100 * 1.0, serving_g: 100),
                PortionOption(name: "Medium (150g)", calories: caloriesPer100 * 1.5, serving_g: 150),
                PortionOption(name: "Large (200g)", calories: caloriesPer100 * 2.0, serving_g: 200),
                PortionOption(name: "Extra Large (250g)", calories: caloriesPer100 * 2.5, serving_g: 250)
            ]
        case .pasta:
            return [
                PortionOption(name: "Small (150g)", calories: caloriesPer100 * 1.5, serving_g: 150),
                PortionOption(name: "Medium (200g)", calories: caloriesPer100 * 2.0, serving_g: 200),
                PortionOption(name: "Large (250g)", calories: caloriesPer100 * 2.5, serving_g: 250),
                PortionOption(name: "Extra Large (300g)", calories: caloriesPer100 * 3.0, serving_g: 300)
            ]
        case .bread:
            return [
                PortionOption(name: "1 slice (36g)", calories: caloriesPer100 * 0.36, serving_g: 36),
                PortionOption(name: "2 slices (72g)", calories: caloriesPer100 * 0.72, serving_g: 72),
                PortionOption(name: "Thick slice (50g)", calories: caloriesPer100 * 0.50, serving_g: 50)
            ]
        case .bakeryItem:
            return [
                PortionOption(name: "Half (35g)", calories: caloriesPer100 * 0.35, serving_g: 35),
                PortionOption(name: "1 item (70g)", calories: caloriesPer100 * 0.70, serving_g: 70),
                PortionOption(name: "Large (100g)", calories: caloriesPer100 * 1.0, serving_g: 100)
            ]
        case .cereal:
            return [
                PortionOption(name: "Small bowl (30g)", calories: caloriesPer100 * 0.30, serving_g: 30),
                PortionOption(name: "Regular bowl (45g)", calories: caloriesPer100 * 0.45, serving_g: 45),
                PortionOption(name: "Large bowl (60g)", calories: caloriesPer100 * 0.60, serving_g: 60),
                PortionOption(name: "Extra large (80g)", calories: caloriesPer100 * 0.80, serving_g: 80)
            ]
        case .nuts:
            return [
                PortionOption(name: "Small handful (15g)", calories: caloriesPer100 * 0.15, serving_g: 15),
                PortionOption(name: "Handful (30g)", calories: caloriesPer100 * 0.30, serving_g: 30),
                PortionOption(name: "1/4 cup (35g)", calories: caloriesPer100 * 0.35, serving_g: 35),
                PortionOption(name: "1/2 cup (65g)", calories: caloriesPer100 * 0.65, serving_g: 65)
            ]
        case .cheese:
            return [
                PortionOption(name: "Slice (20g)", calories: caloriesPer100 * 0.20, serving_g: 20),
                PortionOption(name: "Portion (30g)", calories: caloriesPer100 * 0.30, serving_g: 30),
                PortionOption(name: "Generous (50g)", calories: caloriesPer100 * 0.50, serving_g: 50),
                PortionOption(name: "Grated cup (100g)", calories: caloriesPer100 * 1.0, serving_g: 100)
            ]
        case .milk:
            return [
                PortionOption(name: "Splash (30ml)", calories: caloriesPer100 * 0.3, serving_g: 30),
                PortionOption(name: "Small glass (150ml)", calories: caloriesPer100 * 1.5, serving_g: 150),
                PortionOption(name: "Glass (244ml)", calories: caloriesPer100 * 2.44, serving_g: 244),
                PortionOption(name: "Half pint (284ml)", calories: caloriesPer100 * 2.84, serving_g: 284)
            ]
        case .yogurt:
            return [
                PortionOption(name: "Small pot (125g)", calories: caloriesPer100 * 1.25, serving_g: 125),
                PortionOption(name: "Regular pot (150g)", calories: caloriesPer100 * 1.50, serving_g: 150),
                PortionOption(name: "Large pot (200g)", calories: caloriesPer100 * 2.0, serving_g: 200)
            ]
        case .processedMeat:
            return [
                PortionOption(name: "1 rasher/slice (25g)", calories: caloriesPer100 * 0.25, serving_g: 25),
                PortionOption(name: "2 rashers/slices (50g)", calories: caloriesPer100 * 0.50, serving_g: 50),
                PortionOption(name: "3 rashers (75g)", calories: caloriesPer100 * 0.75, serving_g: 75),
                PortionOption(name: "2 sausages (100g)", calories: caloriesPer100 * 1.0, serving_g: 100)
            ]
        case .meat:
            return [
                PortionOption(name: "Small (85g)", calories: caloriesPer100 * 0.85, serving_g: 85),
                PortionOption(name: "Medium (120g)", calories: caloriesPer100 * 1.2, serving_g: 120),
                PortionOption(name: "Large (170g)", calories: caloriesPer100 * 1.7, serving_g: 170),
                PortionOption(name: "Extra Large (225g)", calories: caloriesPer100 * 2.25, serving_g: 225)
            ]
        case .fish:
            return [
                PortionOption(name: "Small fillet (100g)", calories: caloriesPer100 * 1.0, serving_g: 100),
                PortionOption(name: "Medium fillet (140g)", calories: caloriesPer100 * 1.4, serving_g: 140),
                PortionOption(name: "Large fillet (180g)", calories: caloriesPer100 * 1.8, serving_g: 180)
            ]
        case .aromatics:
            return [
                PortionOption(name: "1 clove (3g)", calories: caloriesPer100 * 0.03, serving_g: 3),
                PortionOption(name: "2 cloves (6g)", calories: caloriesPer100 * 0.06, serving_g: 6),
                PortionOption(name: "1 tsp minced (5g)", calories: caloriesPer100 * 0.05, serving_g: 5),
                PortionOption(name: "1 tbsp minced (10g)", calories: caloriesPer100 * 0.10, serving_g: 10)
            ]
        case .vegetable:
            return [
                PortionOption(name: "1 portion (80g)", calories: caloriesPer100 * 0.8, serving_g: 80),
                PortionOption(name: "2 portions (160g)", calories: caloriesPer100 * 1.6, serving_g: 160),
                PortionOption(name: "Side dish (120g)", calories: caloriesPer100 * 1.2, serving_g: 120)
            ]
        case .legume:
            return [
                PortionOption(name: "Half cup (80g)", calories: caloriesPer100 * 0.8, serving_g: 80),
                PortionOption(name: "Cup (160g)", calories: caloriesPer100 * 1.6, serving_g: 160),
                PortionOption(name: "Half tin (200g)", calories: caloriesPer100 * 2.0, serving_g: 200)
            ]
        case .tofu:
            return [
                PortionOption(name: "Small (75g)", calories: caloriesPer100 * 0.75, serving_g: 75),
                PortionOption(name: "Medium (100g)", calories: caloriesPer100 * 1.0, serving_g: 100),
                PortionOption(name: "Large (150g)", calories: caloriesPer100 * 1.5, serving_g: 150),
                PortionOption(name: "Block (200g)", calories: caloriesPer100 * 2.0, serving_g: 200)
            ]
        case .processedMeat:
            return [
                PortionOption(name: "1 slice (20g)", calories: caloriesPer100 * 0.2, serving_g: 20),
                PortionOption(name: "2 slices (40g)", calories: caloriesPer100 * 0.4, serving_g: 40),
                PortionOption(name: "3 slices (60g)", calories: caloriesPer100 * 0.6, serving_g: 60),
                PortionOption(name: "1 sausage (50g)", calories: caloriesPer100 * 0.5, serving_g: 50),
                PortionOption(name: "2 rashers bacon (60g)", calories: caloriesPer100 * 0.6, serving_g: 60)
            ]
        case .aromatics:
            return [
                PortionOption(name: "1 clove garlic (3g)", calories: caloriesPer100 * 0.03, serving_g: 3),
                PortionOption(name: "1 tsp minced (5g)", calories: caloriesPer100 * 0.05, serving_g: 5),
                PortionOption(name: "1 tbsp minced (15g)", calories: caloriesPer100 * 0.15, serving_g: 15),
                PortionOption(name: "1 small onion (70g)", calories: caloriesPer100 * 0.7, serving_g: 70),
                PortionOption(name: "1 medium onion (110g)", calories: caloriesPer100 * 1.1, serving_g: 110)
            ]
        case .other:
            return []
        }
    }

    /// Combined portions: database portions OR calculated presets
    /// NOTE: This uses basic category detection. For query-aware portions that
    /// properly handle composite dishes and ambiguous queries, use
    /// `portionsForQuery(_:)` instead.
    var availablePortions: [PortionOption] {
        // Prefer database portions if available
        if let dbPortions = portions, !dbPortions.isEmpty {
            return dbPortions
        }
        // Otherwise return calculated presets
        return presetPortions
    }

    /// Returns true if either database portions or presets are available
    /// NOTE: This uses basic category detection. For query-aware checking, use
    /// the confidence system methods instead.
    var hasAnyPortionOptions: Bool {
        return hasPortionOptions || hasPresetPortions
    }

    /// Query-aware check for portion options
    /// This properly handles composite dishes and ambiguous queries by returning
    /// appropriate safe options when needed.
    /// - Parameter query: The user's search query
    /// - Returns: true if any portion options are available (may be safe defaults)
    func hasAnyPortionOptions(forQuery query: String) -> Bool {
        // Database portions always available
        if hasPortionOptions { return true }
        // Per-unit items have no portions
        if isPerUnit == true { return false }
        // Fast food has no portions
        let brandLower = (brand?.lowercased() ?? "").replacingOccurrences(of: "'", with: "'")
        let nameLower = name.lowercased().replacingOccurrences(of: "'", with: "'")
        if Self.fastFoodBrandsNoPresets.contains(where: { brandLower.contains($0) || nameLower.contains($0) }) {
            return false
        }
        // Otherwise, we always have some options (either category presets or safe defaults)
        return true
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
    let consumerGuide: String?
    let origin: String?

    // Regular init for manual construction
    init(code: String, name: String, category: String, healthScore: Int, childWarning: Bool, effectsVerdict: String, consumerGuide: String? = nil, origin: String? = nil) {
        self.code = code
        self.name = name
        self.category = category
        self.healthScore = healthScore
        self.childWarning = childWarning
        self.effectsVerdict = effectsVerdict
        self.consumerGuide = consumerGuide
        self.origin = origin
    }

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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try container.decode(String.self, forKey: .code)
        self.name = try container.decode(String.self, forKey: .name)
        self.category = try container.decode(String.self, forKey: .category)

        // healthScore might not exist in Firebase data
        self.healthScore = (try? container.decode(Int.self, forKey: .healthScore)) ?? 0

        // Handle both snake_case (from Firebase) and camelCase
        if let childWarn = try? container.decode(Bool.self, forKey: .childWarning) {
            self.childWarning = childWarn
        } else {
            self.childWarning = false
        }

        if let verdict = try? container.decode(String.self, forKey: .effectsVerdict) {
            self.effectsVerdict = verdict
        } else {
            self.effectsVerdict = "neutral"
        }

        // Optional fields
        self.consumerGuide = try? container.decode(String.self, forKey: .consumerGuide)
        self.origin = try? container.decode(String.self, forKey: .origin)
    }
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
    let timestamp: FirebaseFirestore.Timestamp
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
    let timestamp: FirebaseFirestore.Timestamp
    let severity: ReactionSeverity
    let symptoms: [String]
    let suspectedIngredients: [String]
    let notes: String?

    init(foodName: String, foodId: String? = nil, foodBrand: String? = nil, timestamp: FirebaseFirestore.Timestamp, severity: ReactionSeverity, symptoms: [String], suspectedIngredients: [String], notes: String? = nil) {
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
            "dateLogged": timestamp, // Use same timestamp for both
            "date": timestamp // Match query field name
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
              let reactionTimeTimestamp = data["reactionTime"] as? FirebaseFirestore.Timestamp,
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
    let calcium: Double?
    let ingredients: [String]?
    let additives: [NutritionAdditiveInfo]?
    let barcode: String?
    let micronutrientProfile: MicronutrientProfile?
    let isPerUnit: Bool?  // true = per unit (e.g., "1 burger"), false/nil = per 100g
    let mealType: MealType
    let date: Date
    let dateLogged: Date

    // AI-Inferred Meal Analysis: For foods without known ingredient labels
    // These are ESTIMATED exposures and may be incomplete or incorrect
    var inferredIngredients: [InferredIngredient]?

    /// Returns true if this food has AI-inferred ingredients (generic/takeaway food)
    var hasInferredIngredients: Bool {
        inferredIngredients != nil && !(inferredIngredients?.isEmpty ?? true)
    }

    /// Returns true if this food is a generic food without exact ingredients
    var isGenericFood: Bool {
        (ingredients == nil || ingredients?.isEmpty == true) && brandName == nil && barcode == nil
    }

    /// All ingredients for pattern analysis (exact + inferred)
    /// Returns ingredient names with their reaction weights applied
    func allIngredientsForAnalysis() -> [(name: String, weight: Double, isEstimated: Bool)] {
        var result: [(name: String, weight: Double, isEstimated: Bool)] = []

        // Add exact ingredients with full weight
        if let exact = ingredients {
            for ingredient in exact {
                result.append((name: ingredient, weight: 1.0, isEstimated: false))
            }
        }

        // Add inferred ingredients with their confidence-based weights
        if let inferred = inferredIngredients {
            for ingredient in inferred {
                result.append((name: ingredient.name, weight: ingredient.reactionWeight, isEstimated: ingredient.isEstimated))
            }
        }

        return result
    }

    init(id: String = UUID().uuidString, userId: String, foodName: String, brandName: String? = nil,
         servingSize: Double, servingUnit: String, calories: Double, protein: Double,
         carbohydrates: Double, fat: Double, fiber: Double? = nil, sugar: Double? = nil,
         sodium: Double? = nil, calcium: Double? = nil, ingredients: [String]? = nil, additives: [NutritionAdditiveInfo]? = nil, barcode: String? = nil, micronutrientProfile: MicronutrientProfile? = nil, isPerUnit: Bool? = nil, mealType: MealType, date: Date, dateLogged: Date = Date(), inferredIngredients: [InferredIngredient]? = nil) {
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
        self.calcium = calcium
        self.ingredients = ingredients
        self.additives = additives
        self.barcode = barcode
        self.micronutrientProfile = micronutrientProfile
        self.isPerUnit = isPerUnit
        self.mealType = mealType
        self.date = date
        self.dateLogged = dateLogged
        self.inferredIngredients = inferredIngredients
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
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
            "calcium": calcium ?? 0.0,
            "mealType": mealType.rawValue,
            "date": FirebaseFirestore.Timestamp(date: date),
            "dateLogged": FirebaseFirestore.Timestamp(date: dateLogged),
            "isPerUnit": isPerUnit ?? false
        ]

        // Add ingredients if available
        if let ingredients = ingredients {
            dict["ingredients"] = ingredients
        }

        // Add additives if available
        if let additives = additives,
           let additivesData = try? JSONEncoder().encode(additives),
           let additivesArray = try? JSONSerialization.jsonObject(with: additivesData, options: []) as? [[String: Any]],
           JSONSerialization.isValidJSONObject(additivesArray) {
            dict["additives"] = additivesArray
        }

        // Add barcode if available
        if let barcode = barcode {
            dict["barcode"] = barcode
        }

        // Add micronutrient profile if available
        if let micronutrients = micronutrientProfile,
           let micronutrientsData = try? JSONEncoder().encode(micronutrients),
           let micronutrientsDict = try? JSONSerialization.jsonObject(with: micronutrientsData, options: []) as? [String: Any],
           JSONSerialization.isValidJSONObject(micronutrientsDict) {
            dict["micronutrientProfile"] = micronutrientsDict
        }

        // Add inferred ingredients if available (AI-estimated ingredients for generic foods)
        if let inferred = inferredIngredients,
           let inferredData = try? JSONEncoder().encode(inferred),
           let inferredArray = try? JSONSerialization.jsonObject(with: inferredData, options: []) as? [[String: Any]],
           JSONSerialization.isValidJSONObject(inferredArray) {
            dict["inferredIngredients"] = inferredArray
        }

        return dict
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
              let dateTimestamp = data["date"] as? FirebaseFirestore.Timestamp,
              let dateLoggedTimestamp = data["dateLogged"] as? FirebaseFirestore.Timestamp else {
            return nil
        }

        // Deserialize ingredients with type safety (prevents NSIndexPath crash)
        var ingredients: [String]? = nil
        if let ingredientsArray = data["ingredients"] as? [String] {
            ingredients = ingredientsArray
        } else if data["ingredients"] != nil {
            // CRITICAL: Reject entire entry if ingredients field contains invalid type
            return nil
        }

        // Deserialize additives if available with type safety
        var additives: [NutritionAdditiveInfo]? = nil
        if let additivesArray = data["additives"] as? [[String: Any]],
           JSONSerialization.isValidJSONObject(additivesArray),
           let additivesData = try? JSONSerialization.data(withJSONObject: additivesArray, options: []) {
            additives = try? JSONDecoder().decode([NutritionAdditiveInfo].self, from: additivesData)
        } else if data["additives"] != nil {
            // CRITICAL: Reject entire entry if additives field contains invalid type
            return nil
        }

        // Deserialize micronutrient profile if available with type safety
        var micronutrientProfile: MicronutrientProfile? = nil
        if let micronutrientsDict = data["micronutrientProfile"] as? [String: Any],
           JSONSerialization.isValidJSONObject(micronutrientsDict) {
            // Additional validation: ensure required fields are dictionaries, not numbers or other types
            let vitaminsValid = micronutrientsDict["vitamins"] == nil || micronutrientsDict["vitamins"] is [String: Any]
            let mineralsValid = micronutrientsDict["minerals"] == nil || micronutrientsDict["minerals"] is [String: Any]
            let recommendedIntakesValid = micronutrientsDict["recommendedIntakes"] == nil || micronutrientsDict["recommendedIntakes"] is [String: Any]

            if vitaminsValid && mineralsValid && recommendedIntakesValid,
               let micronutrientsData = try? JSONSerialization.data(withJSONObject: micronutrientsDict, options: []) {
                micronutrientProfile = try? JSONDecoder().decode(MicronutrientProfile.self, from: micronutrientsData)
            } else {
                                                                                // Don't reject the entire entry, just skip the micronutrient data
                micronutrientProfile = nil
            }
        } else if data["micronutrientProfile"] != nil {
            // CRITICAL: Reject entire entry if micronutrientProfile field contains invalid type
            return nil
        }

        // Deserialize inferred ingredients if available (AI-estimated ingredients for generic foods)
        var inferredIngredients: [InferredIngredient]? = nil
        if let inferredArray = data["inferredIngredients"] as? [[String: Any]],
           JSONSerialization.isValidJSONObject(inferredArray),
           let inferredData = try? JSONSerialization.data(withJSONObject: inferredArray, options: []) {
            inferredIngredients = try? JSONDecoder().decode([InferredIngredient].self, from: inferredData)
        }
        // Note: Don't reject entry if inferredIngredients has wrong type - it's optional

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
            calcium: data["calcium"] as? Double,
            ingredients: ingredients,
            additives: additives,
            barcode: data["barcode"] as? String,
            micronutrientProfile: micronutrientProfile,
            isPerUnit: data["isPerUnit"] as? Bool,
            mealType: mealType,
            date: dateTimestamp.dateValue(),
            dateLogged: dateLoggedTimestamp.dateValue(),
            inferredIngredients: inferredIngredients
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
    let brand: String?
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let calcium: Double
    let saturatedFat: Double
    let servingDescription: String
    let quantity: Double
    let time: String?
    let processedScore: String?
    let sugarLevel: String?
    let ingredients: [String]?
    let additives: [NutritionAdditiveInfo]?
    let barcode: String?
    let micronutrientProfile: MicronutrientProfile?
    let isPerUnit: Bool?  // true = per unit (e.g., "1 burger"), false/nil = per 100g

    // AI-Inferred Meal Analysis: For foods without known ingredient labels
    // These are ESTIMATED exposures and may be incomplete or incorrect
    var inferredIngredients: [InferredIngredient]?

    /// Returns true if this food has AI-inferred ingredients (generic/takeaway food)
    var hasInferredIngredients: Bool {
        inferredIngredients != nil && !(inferredIngredients?.isEmpty ?? true)
    }

    /// Returns true if this food is a generic food without exact ingredients
    var isGenericFood: Bool {
        (ingredients == nil || ingredients?.isEmpty == true) && brand == nil && barcode == nil
    }

    /// All ingredients for pattern analysis (exact + inferred)
    func allIngredientsForAnalysis() -> [(name: String, weight: Double, isEstimated: Bool)] {
        var result: [(name: String, weight: Double, isEstimated: Bool)] = []

        // Add exact ingredients with full weight
        if let exact = ingredients {
            for ingredient in exact {
                result.append((name: ingredient, weight: 1.0, isEstimated: false))
            }
        }

        // Add inferred ingredients with their confidence-based weights
        if let inferred = inferredIngredients {
            for ingredient in inferred {
                result.append((name: ingredient.name, weight: ingredient.reactionWeight, isEstimated: ingredient.isEstimated))
            }
        }

        return result
    }

    init(id: UUID = UUID(), name: String, brand: String? = nil, calories: Int, protein: Double, carbs: Double, fat: Double, fiber: Double = 0, sugar: Double = 0, sodium: Double = 0, calcium: Double = 0, saturatedFat: Double = 0, servingDescription: String = "100g serving", quantity: Double = 1.0, time: String? = nil, processedScore: String? = nil, sugarLevel: String? = nil, ingredients: [String]? = nil, additives: [NutritionAdditiveInfo]? = nil, barcode: String? = nil, micronutrientProfile: MicronutrientProfile? = nil, isPerUnit: Bool? = nil, inferredIngredients: [InferredIngredient]? = nil) {
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
        self.calcium = calcium
        self.saturatedFat = saturatedFat
        self.servingDescription = servingDescription
        self.quantity = quantity
        self.time = time
        self.processedScore = processedScore
        self.sugarLevel = sugarLevel
        self.ingredients = ingredients
        self.additives = additives
        self.barcode = barcode
        self.micronutrientProfile = micronutrientProfile
        self.isPerUnit = isPerUnit
        self.inferredIngredients = inferredIngredients
    }

    static func == (lhs: DiaryFoodItem, rhs: DiaryFoodItem) -> Bool {
        return lhs.id == rhs.id
    }

    // MARK: - Custom Codable for backward compatibility
    // Allows decoding older cached data that may be missing newer fields

    enum CodingKeys: String, CodingKey {
        case id, name, brand, calories, protein, carbs, fat, fiber, sugar, sodium
        case calcium, saturatedFat, servingDescription, quantity, time
        case processedScore, sugarLevel, ingredients, additives, barcode
        case micronutrientProfile, isPerUnit, inferredIngredients
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required fields
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        calories = try container.decode(Int.self, forKey: .calories)
        protein = try container.decode(Double.self, forKey: .protein)
        carbs = try container.decode(Double.self, forKey: .carbs)
        fat = try container.decode(Double.self, forKey: .fat)

        // Optional fields with defaults for backward compatibility
        brand = try container.decodeIfPresent(String.self, forKey: .brand)
        fiber = try container.decodeIfPresent(Double.self, forKey: .fiber) ?? 0
        sugar = try container.decodeIfPresent(Double.self, forKey: .sugar) ?? 0
        sodium = try container.decodeIfPresent(Double.self, forKey: .sodium) ?? 0
        calcium = try container.decodeIfPresent(Double.self, forKey: .calcium) ?? 0
        saturatedFat = try container.decodeIfPresent(Double.self, forKey: .saturatedFat) ?? 0
        servingDescription = try container.decodeIfPresent(String.self, forKey: .servingDescription) ?? "100g serving"
        quantity = try container.decodeIfPresent(Double.self, forKey: .quantity) ?? 1.0
        time = try container.decodeIfPresent(String.self, forKey: .time)
        processedScore = try container.decodeIfPresent(String.self, forKey: .processedScore)
        sugarLevel = try container.decodeIfPresent(String.self, forKey: .sugarLevel)
        ingredients = try container.decodeIfPresent([String].self, forKey: .ingredients)
        additives = try container.decodeIfPresent([NutritionAdditiveInfo].self, forKey: .additives)
        barcode = try container.decodeIfPresent(String.self, forKey: .barcode)
        micronutrientProfile = try container.decodeIfPresent(MicronutrientProfile.self, forKey: .micronutrientProfile)
        isPerUnit = try container.decodeIfPresent(Bool.self, forKey: .isPerUnit)
        inferredIngredients = try container.decodeIfPresent([InferredIngredient].self, forKey: .inferredIngredients)
    }

    // Convert DiaryFoodItem back to FoodSearchResult for full feature access
    func toFoodSearchResult() -> FoodSearchResult {
        // PERFORMANCE: Set database version to current to prevent re-analysis
        // DiaryFoodItem doesn't store database version, so we set it here to mark as "current"
        let currentVersion = ProcessingScorer.shared.databaseVersion

        // For per-unit foods, preserve the unit-based serving description and values
        if self.isPerUnit == true {
            // Per-unit foods: values are stored as totals (per-unit * quantity)
            // Divide by quantity to get per-unit values
            let perUnitCalories = quantity > 0 ? Double(calories) / quantity : Double(calories)
            let perUnitProtein = quantity > 0 ? protein / quantity : protein
            let perUnitCarbs = quantity > 0 ? carbs / quantity : carbs
            let perUnitFat = quantity > 0 ? fat / quantity : fat
            let perUnitFiber = quantity > 0 ? fiber / quantity : fiber
            let perUnitSugar = quantity > 0 ? sugar / quantity : sugar
            let perUnitSodium = quantity > 0 ? sodium / quantity : sodium

            return FoodSearchResult(
                id: self.id.uuidString,
                name: self.name,
                brand: self.brand,
                calories: perUnitCalories,
                protein: perUnitProtein,
                carbs: perUnitCarbs,
                fat: perUnitFat,
                fiber: perUnitFiber,
                sugar: perUnitSugar,
                sodium: perUnitSodium,
                servingDescription: self.servingDescription, // Keep the unit name (e.g., "burger")
                servingSizeG: nil, // No gram size for per-unit foods
                isPerUnit: true,
                ingredients: self.ingredients,
                confidence: 1.0,
                isVerified: true,
                additives: self.additives,
                additivesDatabaseVersion: currentVersion,
                processingScore: nil,
                processingGrade: self.processedScore,
                processingLabel: self.processedScore,
                barcode: self.barcode,
                micronutrientProfile: self.micronutrientProfile
            )
        }

        // For per-100g foods, extract serving size and convert back to per-100g values
        let servingSize = extractServingSize(from: servingDescription)

        // DiaryFoodItem stores total values (servingSize * quantity)
        // We need to reverse-calculate to per-100g base values
        let multiplier = (servingSize / 100.0) * quantity

        // Convert stored totals back to per-100g values
        let per100gCalories = multiplier > 0 ? Double(calories) / multiplier : Double(calories)
        let per100gProtein = multiplier > 0 ? protein / multiplier : protein
        let per100gCarbs = multiplier > 0 ? carbs / multiplier : carbs
        let per100gFat = multiplier > 0 ? fat / multiplier : fat
        let per100gFiber = multiplier > 0 ? fiber / multiplier : fiber
        let per100gSugar = multiplier > 0 ? sugar / multiplier : sugar
        let per100gSodium = multiplier > 0 ? sodium / multiplier : sodium

        return FoodSearchResult(
            id: self.id.uuidString,
            name: self.name,
            brand: self.brand,
            calories: per100gCalories,
            protein: per100gProtein,
            carbs: per100gCarbs,
            fat: per100gFat,
            fiber: per100gFiber,
            sugar: per100gSugar,
            sodium: per100gSodium,
            servingDescription: "\(servingSize.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(servingSize)) : String(servingSize))g",
            servingSizeG: servingSize,
            isPerUnit: false,
            ingredients: self.ingredients,
            confidence: 1.0, // High confidence for saved items
            isVerified: true,
            additives: self.additives,
            additivesDatabaseVersion: currentVersion, // Mark as current version to prevent re-analysis
            processingScore: nil,
            processingGrade: self.processedScore,
            processingLabel: self.processedScore,
            barcode: self.barcode,
            micronutrientProfile: self.micronutrientProfile
        )
    }

    private func extractServingSize(from servingDesc: String?) -> Double {
        guard let servingDesc = servingDesc else { return 100.0 }

        // Try to extract grams first (direct match)
        let gramPatterns = [
            #"(\d+(?:\.\d+)?)\s*g"#,          // Match "150g" or "150 g"
            #"\((\d+(?:\.\d+)?)\s*g\)"#        // Match "(150g)" in parentheses
        ]

        for pattern in gramPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: servingDesc, options: [], range: NSRange(location: 0, length: servingDesc.count)),
               let range = Range(match.range(at: 1), in: servingDesc) {
                return Double(String(servingDesc[range])) ?? 100.0
            }
        }

        // Try to extract ml and treat as grams (approximate density ~1g/ml)
        let mlPatterns = [
            #"(\d+(?:\.\d+)?)\s*ml"#,          // Match "330ml" or "330 ml"
            #"\((\d+(?:\.\d+)?)\s*ml\)"#        // Match "(330ml)" in parentheses
        ]

        for pattern in mlPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: servingDesc, options: [], range: NSRange(location: 0, length: servingDesc.count)),
               let range = Range(match.range(at: 1), in: servingDesc) {
                return Double(String(servingDesc[range])) ?? 100.0
            }
        }

        // If just a number, assume it's grams
        if let number = Double(servingDesc.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return number
        }

        // Default to 100g if no parseable size found
        return 100.0
    }

    private func extractServingUnit(from servingDesc: String?) -> String {
        guard let servingDesc = servingDesc?.lowercased() else { return "g" }
        if servingDesc.contains("ml") { return "ml" }
        // Preserve unit words for per‑unit descriptions like "1 burger serving"
        if servingDesc.hasPrefix("1 ") {
            let cleaned = servingDesc.replacingOccurrences(of: "serving", with: "").trimmingCharacters(in: .whitespaces)
            let parts = cleaned.split(separator: " ")
            if parts.count >= 2 {
                return String(parts[1])
            }
        }
        let unitWords = ["piece","slice","burger","wrap","taco","burrito","sandwich","portion","serving"]
        if let found = unitWords.first(where: { servingDesc.contains($0) }) {
            return found == "serving" ? "g" : found
        }
        return "g"
    }

    // Convert DiaryFoodItem to FoodEntry for Firebase sync
    func toFoodEntry(userId: String, mealType: MealType, date: Date) -> FoodEntry {
        // For per-unit foods, servingSize is the quantity count and servingUnit is the unit name
        // For per-100g foods, servingSize is the gram amount and servingUnit is "g" or "ml"
        let servingSize: Double
        let servingUnit: String

        if self.isPerUnit == true {
            // Per-unit: store quantity as servingSize, unit name as servingUnit
            servingSize = self.quantity
            servingUnit = self.servingDescription
        } else {
            // Per-100g: extract gram amount and multiply by quantity
            servingSize = extractServingSize(from: servingDescription) * self.quantity
            servingUnit = extractServingUnit(from: servingDescription)
        }

        return FoodEntry(
            id: self.id.uuidString,
            userId: userId,
            foodName: self.name,
            brandName: self.brand,
            servingSize: servingSize,
            servingUnit: servingUnit,
            calories: Double(self.calories),
            protein: self.protein,
            carbohydrates: self.carbs,
            fat: self.fat,
            fiber: self.fiber,
            sugar: self.sugar,
            sodium: self.sodium,
            calcium: self.calcium,
            ingredients: self.ingredients,
            additives: self.additives,
            barcode: self.barcode,
            micronutrientProfile: self.micronutrientProfile,
            isPerUnit: self.isPerUnit,
            mealType: mealType,
            date: date,
            dateLogged: Date()
        )
    }

    // Convert FoodEntry from Firebase back to DiaryFoodItem
    static func fromFoodEntry(_ entry: FoodEntry) -> DiaryFoodItem {
        // For per-unit foods, servingSize is the quantity and servingUnit is the unit name
        // For per-100g foods, servingSize includes quantity already, so we set quantity to 1.0
        let servingDescription: String
        let quantity: Double

        if entry.isPerUnit == true {
            // Per-unit: servingDescription is just the unit name, quantity comes from servingSize
            servingDescription = entry.servingUnit
            quantity = entry.servingSize
        } else {
            // Per-100g: show "Xg serving" format, quantity is 1.0 (already multiplied into servingSize)
            let sizeStr = entry.servingSize.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(entry.servingSize))
                : String(format: "%.1f", entry.servingSize)
            servingDescription = "\(sizeStr)\(entry.servingUnit) serving"
            quantity = 1.0
        }

        return DiaryFoodItem(
            id: UUID(uuidString: entry.id) ?? UUID(),
            name: entry.foodName,
            brand: entry.brandName,
            calories: Int(entry.calories),
            protein: entry.protein,
            carbs: entry.carbohydrates,
            fat: entry.fat,
            fiber: entry.fiber ?? 0,
            sugar: entry.sugar ?? 0,
            sodium: entry.sodium ?? 0,
            calcium: entry.calcium ?? 0,
            servingDescription: servingDescription,
            quantity: quantity,
            time: nil,
            processedScore: nil,
            sugarLevel: nil,
            ingredients: entry.ingredients,
            additives: entry.additives,
            barcode: entry.barcode,
            micronutrientProfile: entry.micronutrientProfile,
            isPerUnit: entry.isPerUnit
        )
    }
}

// MARK: - Micronutrient Profile Models

struct MicronutrientProfile: Codable, Equatable {
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

struct RecommendedIntakes: Codable, Equatable {
    let age: Int
    let gender: Gender
    let dailyValues: [String: Double]

    /// Returns daily recommended value for a nutrient
    /// - Parameter nutrient: Nutrient name (e.g., "vitaminA", "calcium")
    /// - Returns: Daily value in appropriate unit (mg, mcg, g)
    ///
    /// **Sources:**
    /// - FDA Daily Values: https://www.fda.gov/food/nutrition-facts-label/daily-value-nutrition-and-supplement-facts-labels
    /// - UK SACN Dietary Reference Values: https://www.gov.uk/government/collections/sacn-reports-and-position-statements
    /// - NIH/National Academies DRI Tables: https://www.ncbi.nlm.nih.gov/books/NBK222881/
    /// - EFSA Health Claims: https://www.efsa.europa.eu/en/topics/topic/health-claims
    func getDailyValue(for nutrient: String) -> Double {
        // First check if it exists in the provided daily values
        if let value = dailyValues[nutrient], value > 0 {
            return value
        }

        // Fall back to standard recommended daily values for adults (age 19-50)
        // Values based on FDA Daily Values (2016) and UK Reference Nutrient Intakes
        let standardDailyValues: [String: Double] = [
            // Vitamins
            "vitaminA": 900.0,        // mcg RAE
            "vitaminC": 90.0,         // mg
            "vitaminD": 20.0,         // mcg
            "vitaminE": 15.0,         // mg
            "vitaminK": 120.0,        // mcg
            "thiamine": 1.2,          // mg (B1)
            "riboflavin": 1.3,        // mg (B2)
            "niacin": 16.0,           // mg (B3)
            "pantothenicAcid": 5.0,   // mg (B5)
            "vitaminB6": 1.7,         // mg
            "biotin": 30.0,           // mcg (B7)
            "folate": 400.0,          // mcg (B9)
            "vitaminB12": 2.4,        // mcg
            "choline": 550.0,         // mg

            // Minerals
            "calcium": 1000.0,        // mg
            "iron": 18.0,             // mg
            "magnesium": 420.0,       // mg
            "phosphorus": 700.0,      // mg
            "potassium": 4700.0,      // mg
            "sodium": 2300.0,         // mg
            "zinc": 11.0,             // mg
            "copper": 0.9,            // mg
            "manganese": 2.3,         // mg
            "selenium": 55.0,         // mcg
            "chromium": 35.0,         // mcg
            "molybdenum": 45.0,       // mcg
            "iodine": 150.0,          // mcg

            // Legacy naming for compatibility
            "vitamin_c": 90.0,
            "protein": 50.0           // g
        ]

        return standardDailyValues[nutrient] ?? 0
    }
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

    /// Estimates micronutrient content based on macronutrient composition and food category
    ///
    /// **IMPORTANT**: These are ESTIMATED values based on typical food composition patterns.
    /// Actual micronutrient content may vary significantly. Where possible, verified nutritional
    /// data from databases should be preferred.
    ///
    /// **Methodology**: Food category multipliers applied to macronutrient base values
    ///
    /// **Data Sources** (for typical food composition patterns):
    /// - USDA FoodData Central: https://fdc.nal.usda.gov/
    /// - UK CoFID Database: https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid
    ///
    /// - Parameters:
    ///   - food: Food item to estimate nutrients for
    ///   - quantity: Serving quantity multiplier
    /// - Returns: Estimated micronutrient profile with confidence score
    func getMicronutrientProfile(for food: FoodSearchResult, quantity: Double = 1.0) -> MicronutrientProfile {
        // Detect food type for more accurate estimates
        let foodName = food.name.lowercased()
        let foodType = detectFoodType(foodName)

        // Apply food-type-specific multipliers
        let multipliers = getFoodTypeMultipliers(foodType)

        // Debug logging removed to prevent excessive output

        // Create improved micronutrient profile with food-type awareness
        let basicVitamins: [String: Double] = [
            "vitaminA": food.protein * 2.5 * quantity * multipliers.vitaminA,
            "vitaminC": food.carbs * 0.8 * quantity * multipliers.vitaminC,
            "vitaminD": food.fat * 0.4 * quantity * multipliers.vitaminD,
            "vitaminE": food.fat * 0.6 * quantity * multipliers.vitaminE,
            "vitaminK": food.fiber * 1.2 * quantity * multipliers.vitaminK,
            "thiamine": food.protein * 0.3 * quantity * multipliers.thiamine,
            "riboflavin": food.protein * 0.35 * quantity * multipliers.riboflavin,
            "niacin": food.protein * 0.8 * quantity * multipliers.niacin,
            "pantothenicAcid": food.protein * 0.25 * quantity,
            "vitaminB6": food.protein * 0.4 * quantity * multipliers.vitaminB6,
            "biotin": food.protein * 0.05 * quantity,
            "folate": food.carbs * 0.6 * quantity * multipliers.folate,
            "vitaminB12": food.protein * 0.15 * quantity * multipliers.vitaminB12,
            "choline": food.protein * 2.1 * quantity
        ]

        let basicMinerals: [String: Double] = [
            "calcium": food.protein * 8.0 * quantity * multipliers.calcium,
            "iron": food.protein * 1.2 * quantity * multipliers.iron,
            "magnesium": food.carbs * 2.4 * quantity * multipliers.magnesium,
            "phosphorus": food.protein * 6.5 * quantity,
            "potassium": food.carbs * 15.0 * quantity * multipliers.potassium,
            "sodium": food.sodium * quantity,
            "zinc": food.protein * 0.8 * quantity * multipliers.zinc,
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

    // MARK: - Food Type Detection

    private enum FoodType {
        case citrusFruit      // Oranges, lemons, grapefruit
        case berries          // Strawberries, blueberries
        case leafyGreens      // Spinach, kale
        case dairy            // Milk, cheese, yogurt
        case meat             // Beef, chicken, pork
        case fish             // Salmon, tuna
        case nuts             // Almonds, walnuts
        case legumes          // Beans, lentils
        case grains           // Rice, bread, pasta
        case other
    }

    private func detectFoodType(_ foodName: String) -> FoodType {
        let name = foodName.lowercased()

        // Citrus fruits - very high in Vitamin C
        if name.contains("orange") || name.contains("lemon") || name.contains("lime") ||
           name.contains("grapefruit") || name.contains("tangerine") || name.contains("mandarin") {
            return .citrusFruit
        }

        // Berries - high in Vitamin C, antioxidants
        if name.contains("strawberry") || name.contains("strawberries") || name.contains("blueberry") ||
           name.contains("raspberry") || name.contains("blackberry") {
            return .berries
        }

        // Leafy greens - high in Vitamin K, folate, iron
        if name.contains("spinach") || name.contains("kale") || name.contains("lettuce") ||
           name.contains("arugula") || name.contains("chard") {
            return .leafyGreens
        }

        // Dairy - high in calcium, Vitamin D, B12
        if name.contains("milk") || name.contains("cheese") || name.contains("yogurt") ||
           name.contains("cream") || name.contains("butter") {
            return .dairy
        }

        // Fish - high in Vitamin D, B12, omega-3
        if name.contains("salmon") || name.contains("tuna") || name.contains("fish") ||
           name.contains("cod") || name.contains("mackerel") || name.contains("sardine") {
            return .fish
        }

        // Meat - high in B vitamins, iron, zinc
        if name.contains("chicken") || name.contains("beef") || name.contains("pork") ||
           name.contains("turkey") || name.contains("lamb") || name.contains("steak") {
            return .meat
        }

        // Nuts - high in Vitamin E, magnesium
        if name.contains("almond") || name.contains("walnut") || name.contains("peanut") ||
           name.contains("cashew") || name.contains("pistachio") {
            return .nuts
        }

        // Legumes - high in folate, iron, magnesium
        if name.contains("bean") || name.contains("lentil") || name.contains("chickpea") ||
           name.contains("pea") {
            return .legumes
        }

        // Grains - high in B vitamins, magnesium
        if name.contains("bread") || name.contains("rice") || name.contains("pasta") ||
           name.contains("cereal") || name.contains("oat") || name.contains("wheat") {
            return .grains
        }

        return .other
    }

    private struct NutrientMultipliers {
        var vitaminA: Double = 1.0
        var vitaminC: Double = 1.0
        var vitaminD: Double = 1.0
        var vitaminE: Double = 1.0
        var vitaminK: Double = 1.0
        var thiamine: Double = 1.0
        var riboflavin: Double = 1.0
        var niacin: Double = 1.0
        var vitaminB6: Double = 1.0
        var folate: Double = 1.0
        var vitaminB12: Double = 1.0
        var calcium: Double = 1.0
        var iron: Double = 1.0
        var magnesium: Double = 1.0
        var potassium: Double = 1.0
        var zinc: Double = 1.0
    }

    private func getFoodTypeMultipliers(_ foodType: FoodType) -> NutrientMultipliers {
        var multipliers = NutrientMultipliers()

        switch foodType {
        case .citrusFruit:
            // Citrus is EXTREMELY high in Vitamin C
            // Orange juice has ~50mg Vitamin C per 100ml
            multipliers.vitaminC = 6.0  // Boost from 0.8x to 4.8x
            multipliers.potassium = 2.0
            multipliers.folate = 1.5

        case .berries:
            multipliers.vitaminC = 5.0  // Very high in Vitamin C
            multipliers.vitaminK = 2.0
            multipliers.folate = 1.5

        case .leafyGreens:
            multipliers.vitaminK = 5.0  // Extremely high
            multipliers.vitaminA = 3.0
            multipliers.folate = 3.0
            multipliers.iron = 2.0
            multipliers.calcium = 2.0

        case .dairy:
            multipliers.calcium = 4.0   // Very high
            multipliers.vitaminD = 3.0
            multipliers.vitaminB12 = 4.0
            multipliers.riboflavin = 2.0

        case .fish:
            multipliers.vitaminD = 5.0  // Extremely high
            multipliers.vitaminB12 = 4.0
            multipliers.niacin = 2.0

        case .meat:
            multipliers.vitaminB12 = 3.0
            multipliers.niacin = 2.5
            multipliers.iron = 2.0
            multipliers.zinc = 2.5
            multipliers.thiamine = 2.0

        case .nuts:
            multipliers.vitaminE = 4.0  // Very high
            multipliers.magnesium = 3.0

        case .legumes:
            multipliers.folate = 3.0
            multipliers.iron = 2.0
            multipliers.magnesium = 2.0

        case .grains:
            multipliers.thiamine = 2.0
            multipliers.niacin = 2.0
            multipliers.folate = 1.5
            multipliers.magnesium = 1.5

        case .other:
            // Use baseline multipliers
            break
        }

        return multipliers
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
        let recommendedAmount = recommendedIntakes.getDailyValue(for: nutrient)
        guard recommendedAmount > 0 else { return nil }
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
