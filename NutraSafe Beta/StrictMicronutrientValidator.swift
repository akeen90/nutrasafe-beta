//
//  StrictMicronutrientValidator.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-01-20.
//  Evidence-based micronutrient detection with strict validation rules.
//
//  DESIGN PHILOSOPHY:
//  This validator prioritises FALSE NEGATIVES over FALSE POSITIVES.
//  It is better to miss a micronutrient than to incorrectly claim one is present.
//
//  VALIDATION RULES:
//  1. A vitamin/mineral is ONLY detected if:
//     - Explicitly listed in nutrition table with quantified value, OR
//     - Explicitly declared as fortification in ingredients, OR
//     - Food is predominantly composed of a well-established primary source
//
//  2. DO NOT infer micronutrients from:
//     - Minor ingredients
//     - Flavourings
//     - Cocoa solids
//     - Emulsifiers
//     - Acids used as preservatives (e.g., citric acid, ascorbic acid as antioxidant)
//     - General plant presence
//     - Processing by-products
//
//  3. Ultra-processed foods (chocolate, sweets, biscuits, crisps, sauces) default to
//     NO micronutrients unless fortification is explicitly declared.
//
//  4. Ascorbic acid ONLY counts as vitamin C if explicitly labelled as such or
//     declared for nutritional purposes (not as antioxidant/preservative).
//

import Foundation

// MARK: - Confidence Tier System

/// Confidence tiers for micronutrient detection.
/// Only `.confirmed` tier is surfaced to users.
enum MicronutrientConfidenceTier: String, Comparable {
    /// Explicit nutritional data or declared fortification
    case confirmed = "confirmed"

    /// Well-established whole food as dominant ingredient
    /// (Internal use only - NOT surfaced to user)
    case naturalPrimarySource = "natural_primary_source"

    /// Insufficient evidence - default state
    case notDetected = "not_detected"

    static func < (lhs: MicronutrientConfidenceTier, rhs: MicronutrientConfidenceTier) -> Bool {
        let order: [MicronutrientConfidenceTier] = [.notDetected, .naturalPrimarySource, .confirmed]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else { return false }
        return lhsIndex < rhsIndex
    }
}

/// Result of strict micronutrient validation
struct ValidatedMicronutrient {
    let nutrient: String
    let confidenceTier: MicronutrientConfidenceTier
    let source: ValidationSource
    let evidence: String

    enum ValidationSource {
        case nutritionTable           // Quantified value in nutrition facts
        case declaredFortification    // "Vitamins: vitamin C, vitamin D" in ingredients
        case wholeFoodPrimarySource   // Orange juice → vitamin C (dominant ingredient)
    }

    /// Whether this nutrient should be shown to users
    var shouldSurfaceToUser: Bool {
        confidenceTier == .confirmed
    }
}

// MARK: - Food Category Classification

/// Categories of foods that require special handling for micronutrient detection.
/// Named with "Micronutrient" prefix to avoid conflict with other MicronutrientFoodCategory enums.
enum MicronutrientFoodCategory {
    case wholeFood          // Single-ingredient or minimally processed
    case fortifiedFood      // Explicitly fortified (cereals, milk alternatives)
    case ultraProcessed     // NOVA Group 4: confectionery, snacks, etc.
    case standardProcessed  // Normal processed foods

    /// Categories where micronutrients should NOT be inferred
    static let restrictedCategories: Set<MicronutrientFoodCategory> = [.ultraProcessed]
}

// MARK: - Strict Micronutrient Validator

class StrictMicronutrientValidator {
    static let shared = StrictMicronutrientValidator()

    private init() {}

    // MARK: - Ultra-Processed Food Detection

    /// Keywords that indicate ultra-processed confectionery/snack foods
    /// These foods should NOT have micronutrients inferred from ingredients
    private let ultraProcessedKeywords: Set<String> = [
        // Confectionery
        "chocolate", "chocolates", "choc", "cocoa",
        "sweet", "sweets", "candy", "candies",
        "toffee", "caramel", "fudge", "nougat",
        "gummy", "gummies", "jelly", "jellies",
        "marshmallow", "liquorice", "licorice",
        "revels", "maltesers", "minstrels", "galaxy", "milky way",
        "snickers", "mars", "twix", "bounty", "kitkat", "kit kat",
        "cadbury", "dairy milk", "buttons", "freddo",
        "haribo", "wine gums", "fruit pastilles",

        // Biscuits & Cookies
        "biscuit", "biscuits", "cookie", "cookies",
        "wafer", "wafers", "digestive", "hobnob",
        "oreo", "bourbon", "custard cream", "shortbread",

        // Crisps & Savoury Snacks
        "crisp", "crisps", "chip", "chips", "pringles",
        "dorito", "doritos", "cheeto", "cheetos",
        "wotsit", "wotsits", "quaver", "quavers",
        "monster munch", "skips", "hula hoops",
        "popcorn", // unless plain
        "corn puff", "cheese puff",

        // Sugary Drinks
        "cola", "soda", "pop", "fizzy",
        "energy drink", "sports drink",
        "squash", "cordial", // unless fortified

        // Cakes & Pastries
        "cake", "cakes", "pastry", "pastries",
        "doughnut", "donut", "muffin", "brownie",
        "croissant", "danish",

        // Ice Cream & Frozen Desserts
        "ice cream", "ice lolly", "gelato", "sorbet",
        "frozen dessert", "magnum", "cornetto",

        // Processed Sauces (unless fortified)
        "ketchup", "mayonnaise", "mayo",
        "barbecue sauce", "bbq sauce",
        "brown sauce", "hp sauce",

        // Fast Food & Takeaway
        "big mac", "mcchicken", "quarter pounder", "filet-o-fish",
        "whopper", "chicken nuggets", "mcnuggets", "nugget",
        "burger", "cheeseburger", "hamburger",
        "hot dog", "hotdog", "corn dog",
        "kebab", "doner", "shawarma",
        "pizza", "pepperoni", "pizza hut", "dominos",
        "fried chicken", "kfc", "popcorn chicken",
        "wrap", "burrito", "taco", "quesadilla",
        "subway", "meal deal"
    ]

    /// Ingredients that are markers of ultra-processed foods
    /// When these dominate an ingredient list, restrict micronutrient inference
    private let ultraProcessedIngredientMarkers: Set<String> = [
        "glucose syrup", "glucose-fructose syrup", "corn syrup",
        "high fructose corn syrup", "maltodextrin", "dextrose",
        "hydrogenated", "palm oil", "vegetable fat",
        "emulsifier", "e471", "e322", "lecithin",
        "flavouring", "flavoring", "natural flavouring",
        "modified starch", "modified maize starch",
        "milk chocolate", "dark chocolate", "white chocolate",
        "cocoa butter", "cocoa mass", "cocoa solids",
        "sugar", "icing sugar", "invert sugar"
    ]

    // MARK: - Whole Food Primary Sources

    /// Well-established whole foods that are PRIMARY sources of specific nutrients
    /// The food must be PREDOMINANTLY composed of this ingredient to count
    private let wholeFoodPrimarySources: [String: [String]] = [
        // Vitamin C - only count if juice/whole fruit is primary
        "vitamin_c": [
            "orange juice", "orange", "oranges",
            "lemon juice", "lemon", "lemons",
            "lime juice", "lime", "limes",
            "grapefruit juice", "grapefruit",
            "kiwi", "kiwis", "kiwifruit",
            "strawberry", "strawberries",
            "bell pepper", "red pepper", "capsicum",
            "broccoli", "brussels sprout", "brussels sprouts",
            "blackcurrant", "blackcurrants"
        ],

        // Calcium - only count if dairy/fortified alternative is primary
        "calcium": [
            "milk", "whole milk", "semi-skimmed milk", "skimmed milk",
            "yoghurt", "yogurt", "greek yoghurt",
            "cheese", "cheddar", "mozzarella", "parmesan",
            "sardine", "sardines", "whitebait",
            "tofu", "calcium-set tofu"
        ],

        // Iron - only count if meat/legume is primary
        "iron": [
            "beef", "steak", "lamb", "liver",
            "chicken liver", "pate",
            "spinach", "kale", "swiss chard",
            "lentil", "lentils", "chickpea", "chickpeas",
            "kidney bean", "kidney beans",
            "black bean", "black beans"
        ],

        // Vitamin D - very few natural sources
        "vitamin_d": [
            "salmon", "mackerel", "sardine", "sardines",
            "herring", "trout", "tuna",
            "egg yolk", "eggs",
            "mushroom", "mushrooms" // if UV-exposed
        ],

        // Vitamin B12 - animal products only
        "vitamin_b12": [
            "beef", "lamb", "liver", "kidney",
            "salmon", "trout", "tuna", "sardine", "sardines",
            "milk", "cheese", "yoghurt", "yogurt",
            "egg", "eggs"
        ],

        // Potassium
        "potassium": [
            "banana", "bananas",
            "potato", "potatoes", "sweet potato",
            "avocado", "avocados",
            "spinach", "swiss chard",
            "salmon", "tuna"
        ],

        // Magnesium
        "magnesium": [
            "almond", "almonds",
            "cashew", "cashews",
            "pumpkin seed", "pumpkin seeds",
            "spinach", "swiss chard",
            "black bean", "black beans",
            "dark chocolate" // Note: only in very high cocoa % products
        ],

        // Zinc
        "zinc": [
            "oyster", "oysters",
            "beef", "lamb",
            "pumpkin seed", "pumpkin seeds",
            "chickpea", "chickpeas",
            "cashew", "cashews"
        ],

        // Folate/B9
        "vitamin_b9": [
            "spinach", "kale", "brussels sprout", "brussels sprouts",
            "asparagus", "broccoli",
            "lentil", "lentils",
            "chickpea", "chickpeas",
            "black-eyed pea", "black-eyed peas"
        ],

        // Vitamin A
        "vitamin_a": [
            "carrot", "carrots",
            "sweet potato", "sweet potatoes",
            "spinach", "kale",
            "liver", "chicken liver",
            "egg", "eggs",
            "butter"
        ],

        // Vitamin E
        "vitamin_e": [
            "almond", "almonds",
            "sunflower seed", "sunflower seeds",
            "hazelnut", "hazelnuts",
            "avocado", "avocados",
            "spinach"
        ],

        // Omega-3 (EPA/DHA)
        "omega_3": [
            "salmon", "mackerel", "sardine", "sardines",
            "herring", "anchovy", "anchovies",
            "trout", "tuna"
        ],

        // Vitamin K
        "vitamin_k": [
            "kale", "spinach", "broccoli",
            "brussels sprout", "brussels sprouts",
            "cabbage", "lettuce"
        ],

        // Iodine
        "iodine": [
            "cod", "haddock", "seaweed", "nori",
            "prawn", "prawns", "shrimp"
        ],

        // Selenium
        "selenium": [
            "brazil nut", "brazil nuts",
            "tuna", "sardine", "sardines",
            "egg", "eggs"
        ]
    ]

    // MARK: - Explicit Fortification Patterns

    /// Patterns that indicate EXPLICIT vitamin/mineral fortification
    /// These must clearly state the nutrient is added for nutritional purposes
    private let explicitFortificationPatterns: [String: [NSRegularExpression]] = {
        var patterns: [String: [NSRegularExpression]] = [:]

        // Vitamin C - must explicitly say "vitamin C" not just "ascorbic acid"
        patterns["vitamin_c"] = [
            try? NSRegularExpression(pattern: "\\bvitamin\\s*c\\b", options: .caseInsensitive),
            try? NSRegularExpression(pattern: "\\b(?:l-)?ascorbic\\s*acid\\s*\\(\\s*vitamin\\s*c\\s*\\)", options: .caseInsensitive),
            try? NSRegularExpression(pattern: "vitamins?[:\\s]+[^,]*vitamin\\s*c", options: .caseInsensitive),
            try? NSRegularExpression(pattern: "fortified\\s+with[^,]*vitamin\\s*c", options: .caseInsensitive),
            try? NSRegularExpression(pattern: "added\\s+vitamin\\s*c", options: .caseInsensitive)
        ].compactMap { $0 }

        // Vitamin D
        patterns["vitamin_d"] = [
            try? NSRegularExpression(pattern: "\\bvitamin\\s*d[23]?\\b", options: .caseInsensitive),
            try? NSRegularExpression(pattern: "\\bcholecalciferol\\b", options: .caseInsensitive),
            try? NSRegularExpression(pattern: "\\bergocalciferol\\b", options: .caseInsensitive),
            try? NSRegularExpression(pattern: "fortified\\s+with[^,]*vitamin\\s*d", options: .caseInsensitive)
        ].compactMap { $0 }

        // Iron
        patterns["iron"] = [
            try? NSRegularExpression(pattern: "\\biron\\b(?!\\s*oxide)", options: .caseInsensitive),
            try? NSRegularExpression(pattern: "\\bferrous\\s*(?:sulfate|sulphate|fumarate|gluconate)\\b", options: .caseInsensitive),
            try? NSRegularExpression(pattern: "fortified\\s+with[^,]*iron", options: .caseInsensitive)
        ].compactMap { $0 }

        // Calcium
        patterns["calcium"] = [
            try? NSRegularExpression(pattern: "\\bcalcium\\s*(?:carbonate|citrate|phosphate|lactate)\\b", options: .caseInsensitive),
            try? NSRegularExpression(pattern: "fortified\\s+with[^,]*calcium", options: .caseInsensitive),
            try? NSRegularExpression(pattern: "added\\s+calcium", options: .caseInsensitive)
        ].compactMap { $0 }

        // B Vitamins
        patterns["vitamin_b1"] = [
            try? NSRegularExpression(pattern: "\\bvitamin\\s*b1\\b|\\bthiamin(?:e)?\\b", options: .caseInsensitive)
        ].compactMap { $0 }
        patterns["vitamin_b2"] = [
            try? NSRegularExpression(pattern: "\\bvitamin\\s*b2\\b|\\briboflavin\\b", options: .caseInsensitive)
        ].compactMap { $0 }
        patterns["vitamin_b3"] = [
            try? NSRegularExpression(pattern: "\\bvitamin\\s*b3\\b|\\bniacin(?:amide)?\\b|\\bnicotinamide\\b", options: .caseInsensitive)
        ].compactMap { $0 }
        patterns["vitamin_b6"] = [
            try? NSRegularExpression(pattern: "\\bvitamin\\s*b6\\b|\\bpyridoxine\\b", options: .caseInsensitive)
        ].compactMap { $0 }
        patterns["vitamin_b9"] = [
            try? NSRegularExpression(pattern: "\\bvitamin\\s*b9\\b|\\bfolic\\s*acid\\b|\\bfolate\\b", options: .caseInsensitive)
        ].compactMap { $0 }
        patterns["vitamin_b12"] = [
            try? NSRegularExpression(pattern: "\\bvitamin\\s*b12\\b|\\bcyanocobalamin\\b|\\bmethylcobalamin\\b", options: .caseInsensitive)
        ].compactMap { $0 }

        // Vitamin A
        patterns["vitamin_a"] = [
            try? NSRegularExpression(pattern: "\\bvitamin\\s*a\\b", options: .caseInsensitive),
            try? NSRegularExpression(pattern: "\\bretinyl\\s*(?:acetate|palmitate)\\b", options: .caseInsensitive),
            try? NSRegularExpression(pattern: "\\bbeta[\\s-]*carotene\\b", options: .caseInsensitive)
        ].compactMap { $0 }

        // Vitamin E
        patterns["vitamin_e"] = [
            try? NSRegularExpression(pattern: "\\bvitamin\\s*e\\b", options: .caseInsensitive),
            try? NSRegularExpression(pattern: "\\bd-alpha[\\s-]*tocopherol\\b", options: .caseInsensitive),
            try? NSRegularExpression(pattern: "\\btocopheryl\\s*acetate\\b", options: .caseInsensitive)
        ].compactMap { $0 }

        // Zinc
        patterns["zinc"] = [
            try? NSRegularExpression(pattern: "\\bzinc\\s*(?:oxide|citrate|gluconate|sulphate|sulfate)?\\b", options: .caseInsensitive),
            try? NSRegularExpression(pattern: "fortified\\s+with[^,]*zinc", options: .caseInsensitive)
        ].compactMap { $0 }

        // Iodine
        patterns["iodine"] = [
            try? NSRegularExpression(pattern: "\\biodine\\b|\\bpotassium\\s*iodide\\b", options: .caseInsensitive)
        ].compactMap { $0 }

        return patterns
    }()

    // MARK: - Excluded Ascorbic Acid Contexts

    /// Phrases indicating ascorbic acid is used as antioxidant/preservative, NOT as vitamin
    private let ascorbicAcidAntioxidantPatterns: [NSRegularExpression] = [
        try? NSRegularExpression(pattern: "ascorbic\\s*acid\\s*\\(\\s*antioxidant\\s*\\)", options: .caseInsensitive),
        try? NSRegularExpression(pattern: "antioxidant[:\\s]+[^,]*ascorbic\\s*acid", options: .caseInsensitive),
        try? NSRegularExpression(pattern: "antioxidants?[:\\s]+(?:e300|ascorbic)", options: .caseInsensitive),
        try? NSRegularExpression(pattern: "e300(?:\\s*\\(ascorbic\\s*acid\\))?", options: .caseInsensitive),
        try? NSRegularExpression(pattern: "preservative[:\\s]+[^,]*ascorbic", options: .caseInsensitive),
        // Standalone ascorbic acid without vitamin context is assumed to be antioxidant
        try? NSRegularExpression(pattern: "^[^v]*\\bascorbic\\s*acid\\b[^v]*$", options: .caseInsensitive)
    ].compactMap { $0 }

    // MARK: - Main Validation Method

    /// Validate micronutrients for a food item using strict evidence-based rules.
    ///
    /// - Parameters:
    ///   - foodName: The name of the food product
    ///   - ingredients: Array of ingredient strings
    ///   - nutritionTableMicronutrients: Optional dictionary of nutrients with quantified values from nutrition table
    ///
    /// - Returns: Array of validated micronutrients (only confirmed tier is surfaced)
    func validateMicronutrients(
        foodName: String,
        ingredients: [String],
        nutritionTableMicronutrients: [String: Double]? = nil
    ) -> [ValidatedMicronutrient] {

        var validatedNutrients: [ValidatedMicronutrient] = []
        let ingredientsText = ingredients.joined(separator: ", ").lowercased()
        let foodNameLower = foodName.lowercased()

        // 1. Determine food category
        let category = classifyFoodCategory(foodName: foodNameLower, ingredients: ingredients)

        // 2. Check nutrition table first (highest confidence)
        if let tableNutrients = nutritionTableMicronutrients {
            for (nutrient, value) in tableNutrients where value > 0 {
                validatedNutrients.append(ValidatedMicronutrient(
                    nutrient: nutrient,
                    confidenceTier: .confirmed,
                    source: .nutritionTable,
                    evidence: "Listed in nutrition table with value: \(value)"
                ))
            }
        }

        // 3. Check for explicit fortification declarations
        let fortifiedNutrients = detectExplicitFortification(ingredientsText: ingredientsText)
        for nutrient in fortifiedNutrients {
            // Skip if already detected from nutrition table
            if !validatedNutrients.contains(where: { $0.nutrient == nutrient }) {
                validatedNutrients.append(ValidatedMicronutrient(
                    nutrient: nutrient,
                    confidenceTier: .confirmed,
                    source: .declaredFortification,
                    evidence: "Explicitly declared fortification in ingredients"
                ))
            }
        }

        // 4. For non-restricted categories, check whole food primary sources
        // ONLY if the food is predominantly that ingredient
        if !MicronutrientFoodCategory.restrictedCategories.contains(category) {
            let wholeFoodNutrients = detectWholeFoodPrimarySources(
                foodName: foodNameLower,
                ingredients: ingredients,
                category: category
            )

            for (nutrient, evidence) in wholeFoodNutrients {
                // Skip if already detected
                if !validatedNutrients.contains(where: { $0.nutrient == nutrient }) {
                    validatedNutrients.append(ValidatedMicronutrient(
                        nutrient: nutrient,
                        confidenceTier: .naturalPrimarySource,
                        source: .wholeFoodPrimarySource,
                        evidence: evidence
                    ))
                }
            }
        }

        // 5. Filter to only return user-surfaceable nutrients
        return validatedNutrients.filter { $0.shouldSurfaceToUser }
    }

    // MARK: - Food Category Classification

    private func classifyFoodCategory(foodName: String, ingredients: [String]) -> MicronutrientFoodCategory {
        let ingredientsText = ingredients.joined(separator: " ").lowercased()

        // Check ultra-processed keywords in food name
        for keyword in ultraProcessedKeywords {
            if foodName.contains(keyword) {
                return .ultraProcessed
            }
        }

        // Check for ultra-processed ingredient markers dominating the list
        var ultraProcessedMarkerCount = 0
        for marker in ultraProcessedIngredientMarkers {
            if ingredientsText.contains(marker) {
                ultraProcessedMarkerCount += 1
            }
        }

        // If more than 3 ultra-processed markers, classify as ultra-processed
        if ultraProcessedMarkerCount >= 3 {
            return .ultraProcessed
        }

        // Check if it's a fortified food
        if ingredientsText.contains("fortified") ||
           ingredientsText.contains("vitamins:") ||
           ingredientsText.contains("minerals:") ||
           ingredientsText.contains("added vitamins") {
            return .fortifiedFood
        }

        // Check if single ingredient / whole food
        if ingredients.count <= 3 {
            let firstIngredient = ingredients.first?.lowercased() ?? ""
            // Check if the food name essentially matches the first ingredient
            if foodName.contains(firstIngredient) || firstIngredient.contains(foodName) {
                return .wholeFood
            }
        }

        return .standardProcessed
    }

    // MARK: - Explicit Fortification Detection

    private func detectExplicitFortification(ingredientsText: String) -> [String] {
        var detectedNutrients: [String] = []

        for (nutrient, patterns) in explicitFortificationPatterns {
            // Special handling for vitamin C - check antioxidant context
            if nutrient == "vitamin_c" {
                if isAscorbicAcidUsedAsAntioxidant(ingredientsText) {
                    // Check if there's ALSO an explicit vitamin C declaration
                    let hasExplicitVitaminC = patterns.contains { regex in
                        let range = NSRange(ingredientsText.startIndex..., in: ingredientsText)
                        return regex.firstMatch(in: ingredientsText, range: range) != nil
                    }

                    // Only count if explicitly called "vitamin C"
                    if hasExplicitVitaminC && ingredientsText.contains("vitamin c") {
                        detectedNutrients.append(nutrient)
                    }
                    continue
                }
            }

            // Standard pattern matching
            for regex in patterns {
                let range = NSRange(ingredientsText.startIndex..., in: ingredientsText)
                if regex.firstMatch(in: ingredientsText, range: range) != nil {
                    detectedNutrients.append(nutrient)
                    break
                }
            }
        }

        return detectedNutrients
    }

    /// Check if ascorbic acid appears to be used as an antioxidant/preservative rather than vitamin
    private func isAscorbicAcidUsedAsAntioxidant(_ ingredientsText: String) -> Bool {
        // If ingredients contain "ascorbic acid" but NOT "vitamin c", assume antioxidant
        let hasAscorbicAcid = ingredientsText.contains("ascorbic acid") || ingredientsText.contains("e300")
        let hasExplicitVitaminC = ingredientsText.contains("vitamin c")

        if hasAscorbicAcid && !hasExplicitVitaminC {
            return true
        }

        // Check explicit antioxidant context patterns
        for pattern in ascorbicAcidAntioxidantPatterns {
            let range = NSRange(ingredientsText.startIndex..., in: ingredientsText)
            if pattern.firstMatch(in: ingredientsText, range: range) != nil {
                return true
            }
        }

        return false
    }

    // MARK: - Whole Food Primary Source Detection

    private func detectWholeFoodPrimarySources(
        foodName: String,
        ingredients: [String],
        category: MicronutrientFoodCategory
    ) -> [(String, String)] {

        var detected: [(nutrient: String, evidence: String)] = []

        // Only check if food appears to be predominantly one ingredient
        guard category == .wholeFood || ingredients.count <= 5 else {
            return []
        }

        let firstIngredient = ingredients.first?.lowercased() ?? ""
        let secondIngredient = ingredients.count > 1 ? ingredients[1].lowercased() : ""

        for (nutrient, primarySources) in wholeFoodPrimarySources {
            for source in primarySources {
                // Check if food name IS the primary source
                if foodName == source || foodName.hasPrefix(source + " ") || foodName.hasSuffix(" " + source) {
                    detected.append((nutrient, "Food is primarily \(source)"))
                    break
                }

                // Check if first ingredient is the primary source
                if firstIngredient.contains(source) || source.contains(firstIngredient) {
                    // Additional check: first ingredient should be substantial
                    // (not just "water" or similar)
                    if !["water", "sugar", "salt", "oil"].contains(firstIngredient) {
                        detected.append((nutrient, "Primary ingredient is \(source)"))
                        break
                    }
                }

                // Check second ingredient for 2-ingredient whole foods (e.g., "orange juice from concentrate")
                if ingredients.count == 2 && (secondIngredient.contains(source) || source.contains(secondIngredient)) {
                    detected.append((nutrient, "Contains substantial \(source)"))
                    break
                }
            }
        }

        return detected
    }

    // MARK: - Convenience Methods

    /// Check if a specific food should have micronutrients restricted
    func shouldRestrictMicronutrientInference(foodName: String, ingredients: [String]) -> Bool {
        let category = classifyFoodCategory(foodName: foodName.lowercased(), ingredients: ingredients)
        return MicronutrientFoodCategory.restrictedCategories.contains(category)
    }

    /// Get the food category for a product
    func getFoodCategory(foodName: String, ingredients: [String]) -> MicronutrientFoodCategory {
        return classifyFoodCategory(foodName: foodName.lowercased(), ingredients: ingredients)
    }
}

// MARK: - Test Cases (Development Only)

#if DEBUG
extension StrictMicronutrientValidator {
    /// Run validation test cases to verify strict rules
    static func runTestCases() {
        let validator = StrictMicronutrientValidator.shared

        print("=== STRICT MICRONUTRIENT VALIDATION TEST CASES ===\n")

        // Test 1: Revels (should detect NO vitamin C)
        let revels = validator.validateMicronutrients(
            foodName: "Revels",
            ingredients: [
                "Sugar", "Glucose Syrup", "Cocoa Butter", "Skimmed Milk Powder",
                "Cocoa Mass", "Vegetable Fats (Palm, Shea)", "Lactose",
                "Milk Fat", "Whey Powder (from Milk)", "Maltodextrin",
                "Emulsifier (Soya Lecithin)", "Dried Glucose Syrup",
                "Wheat Flour", "Coconut", "Flavourings", "Salt",
                "Fat Reduced Cocoa Powder", "Raising Agent (Sodium Bicarbonate)",
                "Vegetable Fat (Palm)", "Colour (Plain Caramel)"
            ]
        )
        print("1. Revels (chocolate confectionery):")
        print("   Expected: NO micronutrients")
        print("   Result: \(revels.isEmpty ? "PASS - No micronutrients detected" : "FAIL - Detected: \(revels.map { $0.nutrient })")")
        print()

        // Test 2: Orange juice with vitamin C listed
        let orangeJuice = validator.validateMicronutrients(
            foodName: "Tropicana Orange Juice",
            ingredients: ["Oranges", "Orange Juice from Concentrate"],
            nutritionTableMicronutrients: ["vitamin_c": 50.0]
        )
        print("2. Orange juice with vitamin C in nutrition table:")
        print("   Expected: vitamin_c (confirmed)")
        print("   Result: \(orangeJuice.contains { $0.nutrient == "vitamin_c" && $0.confidenceTier == .confirmed } ? "PASS" : "FAIL")")
        print("   Detected: \(orangeJuice.map { "\($0.nutrient) (\($0.confidenceTier))" })")
        print()

        // Test 3: Fortified breakfast cereal
        let cereal = validator.validateMicronutrients(
            foodName: "Kellogg's Corn Flakes",
            ingredients: [
                "Maize", "Sugar", "Barley Malt Extract", "Salt",
                "Vitamins: Niacin, Vitamin B6, Vitamin B2 (Riboflavin), Vitamin B1 (Thiamin), Folic Acid, Vitamin D, Vitamin B12",
                "Iron"
            ]
        )
        print("3. Fortified breakfast cereal:")
        print("   Expected: Multiple vitamins + iron (confirmed)")
        print("   Result: Detected \(cereal.count) nutrients")
        print("   Nutrients: \(cereal.map { $0.nutrient })")
        print()

        // Test 4: Plain chicken breast
        let chicken = validator.validateMicronutrients(
            foodName: "Chicken Breast",
            ingredients: ["Chicken Breast"]
        )
        print("4. Plain chicken breast (whole food):")
        print("   Expected: Minimal or no confirmed micronutrients (no nutrition table data)")
        print("   Detected: \(chicken.map { "\($0.nutrient) (\($0.confidenceTier))" })")
        print()

        // Test 5: Milk chocolate with cocoa solids only
        let milkChoc = validator.validateMicronutrients(
            foodName: "Cadbury Dairy Milk",
            ingredients: [
                "Milk", "Sugar", "Cocoa Butter", "Cocoa Mass",
                "Vegetable Fats (Palm, Shea)", "Emulsifiers (E442, E476)",
                "Flavourings"
            ]
        )
        print("5. Milk chocolate (ultra-processed confectionery):")
        print("   Expected: NO micronutrients (even though milk is present)")
        print("   Result: \(milkChoc.isEmpty ? "PASS - No micronutrients detected" : "FAIL - Detected: \(milkChoc.map { $0.nutrient })")")
        print()

        // Test 6: Ascorbic acid as antioxidant (should NOT count as vitamin C)
        let juiceWithAntioxidant = validator.validateMicronutrients(
            foodName: "Apple Juice",
            ingredients: ["Apple Juice from Concentrate", "Water", "Ascorbic Acid (Antioxidant)"]
        )
        print("6. Apple juice with ascorbic acid as antioxidant:")
        print("   Expected: NO vitamin C (ascorbic acid is preservative)")
        print("   Result: \(!juiceWithAntioxidant.contains { $0.nutrient == "vitamin_c" } ? "PASS" : "FAIL")")
        print()

        // Test 7: Juice with explicit vitamin C fortification
        let fortifiedJuice = validator.validateMicronutrients(
            foodName: "Orange Juice with Added Vitamin C",
            ingredients: ["Orange Juice", "Water", "Vitamin C (Ascorbic Acid)"]
        )
        print("7. Orange juice with explicit vitamin C fortification:")
        print("   Expected: vitamin_c (confirmed)")
        print("   Result: \(fortifiedJuice.contains { $0.nutrient == "vitamin_c" } ? "PASS" : "FAIL")")
        print()

        // Test 8: Biscuits (should detect nothing)
        let biscuits = validator.validateMicronutrients(
            foodName: "McVitie's Digestives",
            ingredients: [
                "Wheat Flour", "Vegetable Oils (Palm, Rapeseed)", "Sugar",
                "Wholemeal Wheat Flour", "Raising Agents (Sodium Bicarbonate, Ammonium Bicarbonate)",
                "Salt"
            ]
        )
        print("8. Digestive biscuits:")
        print("   Expected: NO micronutrients")
        print("   Result: \(biscuits.isEmpty ? "PASS - No micronutrients detected" : "FAIL - Detected: \(biscuits.map { $0.nutrient })")")
        print()

        // Test 9: Fortified plant milk
        let oatMilk = validator.validateMicronutrients(
            foodName: "Oatly Oat Drink",
            ingredients: [
                "Water", "Oats (10%)", "Rapeseed Oil", "Calcium Carbonate",
                "Calcium Phosphate", "Iodised Salt", "Vitamins (D2, Riboflavin, B12)"
            ]
        )
        print("9. Fortified oat milk:")
        print("   Expected: Calcium, Vitamin D, B2, B12, Iodine (confirmed)")
        print("   Detected: \(oatMilk.map { $0.nutrient })")
        print()

        // Test 10: Crisps (should detect nothing)
        let crisps = validator.validateMicronutrients(
            foodName: "Walkers Ready Salted Crisps",
            ingredients: [
                "Potatoes", "Sunflower Oil", "Rapeseed Oil", "Salt"
            ]
        )
        print("10. Crisps:")
        print("   Expected: NO micronutrients (even though potatoes contain potassium)")
        print("   Result: \(crisps.isEmpty ? "PASS - No micronutrients detected" : "FAIL - Detected: \(crisps.map { $0.nutrient })")")
        print()

        print("=== END TEST CASES ===")
    }
}
#endif
