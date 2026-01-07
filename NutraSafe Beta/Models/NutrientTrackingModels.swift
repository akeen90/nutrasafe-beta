//
//  NutrientTrackingModels.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-10-20.
//  Comprehensive vitamin and mineral frequency tracking models
//

import Foundation
import SwiftUI
import FirebaseFirestore

// MARK: - Core Nutrient Models

/// Represents a nutrient being tracked (vitamin or mineral)
struct TrackedNutrient: Identifiable {
    let id: String
    let name: String
    let displayName: String
    let category: NutrientCategory
    let unit: String
    let glowColor: Color
    let icon: String
}

enum NutrientCategory: String, Codable, CaseIterable {
    case vitamin = "vitamin"
    case mineral = "mineral"
    case other = "other"
}

// MARK: - Frequency Tracking Models

/// Tracks frequency of a nutrient appearing in user's diet
struct NutrientFrequency: Codable {
    let nutrientId: String
    let nutrientName: String
    var last30DaysAppearances: Int // How many logged days contained this nutrient
    var totalLoggedDays: Int // Total days with meals logged in last 30 days
    var currentStreak: Int // Consecutive days with this nutrient
    var bestStreak: Int // Best streak ever
    var lastAppearance: Date?
    var topFoodSources: [FoodSource] // Top 5 foods providing this nutrient
    var monthlySnapshots: [MonthlySnapshot]
    var yearlySnapshots: [YearlySnapshot]

    var consistencyPercentage: Double {
        guard totalLoggedDays > 0 else { return 0 }
        return (Double(last30DaysAppearances) / Double(totalLoggedDays)) * 100
    }

    var status: NutrientActivityStatus {
        let daysSinceLastAppearance = lastAppearance.map { Calendar.current.dateComponents([.day], from: $0, to: Date()).day ?? 999 } ?? 999

        if daysSinceLastAppearance > 14 {
            return .dormant
        } else if consistencyPercentage >= 70 {
            return .active
        } else if consistencyPercentage >= 40 {
            return .inconsistent
        } else {
            return .needsAttention
        }
    }

    // MARK: - Human-Readable Descriptions

    /// Main description based on consistency percentage
    var frequencyDescription: String {
        if totalLoggedDays == 0 {
            return "No recent data"
        }

        if last30DaysAppearances == 0 {
            return "Not detected in your recent meals"
        }

        let percentage = consistencyPercentage

        if percentage == 100 {
            return "Present in all logged meals this month"
        } else if percentage >= 70 {
            return "Seen in most meals recently"
        } else if percentage >= 30 {
            return "Appeared occasionally"
        } else {
            return "Rarely seen lately"
        }
    }

    /// Data summary line (e.g., "Found in 8 of your last 10 logged days")
    var dataSummary: String {
        if totalLoggedDays == 0 {
            return "Log meals to start tracking"
        }

        if last30DaysAppearances == 0 {
            return "Not found in \(totalLoggedDays) logged days"
        }

        return "Found in \(last30DaysAppearances) of your last \(totalLoggedDays) logged days"
    }

    /// Ring color based on performance
    var ringColor: Color {
        if totalLoggedDays == 0 || last30DaysAppearances == 0 {
            return .gray
        }

        let percentage = consistencyPercentage

        if percentage >= 70 {
            return .green
        } else if percentage >= 30 {
            return .yellow
        } else {
            return .red
        }
    }

    init(nutrientId: String, nutrientName: String, last30DaysAppearances: Int = 0, totalLoggedDays: Int = 0, currentStreak: Int = 0, bestStreak: Int = 0, lastAppearance: Date? = nil, topFoodSources: [FoodSource] = [], monthlySnapshots: [MonthlySnapshot] = [], yearlySnapshots: [YearlySnapshot] = []) {
        self.nutrientId = nutrientId
        self.nutrientName = nutrientName
        self.last30DaysAppearances = last30DaysAppearances
        self.totalLoggedDays = totalLoggedDays
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.lastAppearance = lastAppearance
        self.topFoodSources = topFoodSources
        self.monthlySnapshots = monthlySnapshots
        self.yearlySnapshots = yearlySnapshots
    }
}

enum NutrientActivityStatus: String, Codable {
    case active = "active"
    case inconsistent = "inconsistent"
    case needsAttention = "needs_attention"
    case dormant = "dormant"

    var label: String {
        switch self {
        case .active: return "Active"
        case .inconsistent: return "Inconsistent"
        case .needsAttention: return "Needs Attention"
        case .dormant: return "Dormant"
        }
    }

    var color: Color {
        switch self {
        case .active: return .green
        case .inconsistent: return .orange
        case .needsAttention: return .yellow
        case .dormant: return .gray
        }
    }
}

struct FoodSource: Codable, Identifiable {
    let id: String
    let foodName: String
    let brand: String?
    let timesConsumed: Int
    let lastConsumed: Date

    init(id: String = UUID().uuidString, foodName: String, brand: String? = nil, timesConsumed: Int, lastConsumed: Date) {
        self.id = id
        self.foodName = foodName
        self.brand = brand
        self.timesConsumed = timesConsumed
        self.lastConsumed = lastConsumed
    }
}

struct MonthlySnapshot: Codable, Identifiable {
    let id: String // Format: "YYYY-MM"
    let month: Int
    let year: Int
    let appearanceDays: Int
    let totalLoggedDays: Int
    let consistencyPercentage: Double
    let topFoodSources: [FoodSource]

    init(month: Int, year: Int, appearanceDays: Int, totalLoggedDays: Int, topFoodSources: [FoodSource] = []) {
        self.id = String(format: "%04d-%02d", year, month)
        self.month = month
        self.year = year
        self.appearanceDays = appearanceDays
        self.totalLoggedDays = totalLoggedDays
        self.consistencyPercentage = totalLoggedDays > 0 ? (Double(appearanceDays) / Double(totalLoggedDays)) * 100 : 0
        self.topFoodSources = topFoodSources
    }
}

struct YearlySnapshot: Codable, Identifiable {
    let id: String // Format: "YYYY"
    let year: Int
    let averageMonthlyConsistency: Double
    let bestMonth: Int
    let worstMonth: Int
    let totalAppearanceDays: Int

    init(year: Int, averageMonthlyConsistency: Double, bestMonth: Int, worstMonth: Int, totalAppearanceDays: Int) {
        self.id = String(format: "%04d", year)
        self.year = year
        self.averageMonthlyConsistency = averageMonthlyConsistency
        self.bestMonth = bestMonth
        self.worstMonth = worstMonth
        self.totalAppearanceDays = totalAppearanceDays
    }
}

// MARK: - Day Activity Models

/// Tracks which nutrients appeared on a specific day
struct DayNutrientActivity: Codable {
    let date: Date
    let nutrientsPresent: [String] // Array of nutrient IDs
    let mealCount: Int

    var dateId: String {
        // PERFORMANCE: Use cached static formatter instead of creating new one
        DateHelper.isoDateFormatter.string(from: date)
    }

    init(date: Date, nutrientsPresent: [String], mealCount: Int) {
        self.date = date
        self.nutrientsPresent = nutrientsPresent
        self.mealCount = mealCount
    }
}

// MARK: - Predefined Nutrients Database

struct NutrientDatabase {
    static let allNutrients: [TrackedNutrient] = [
        // Vitamins
        TrackedNutrient(id: "vitamin_c", name: "Vitamin C", displayName: "Vitamin C", category: .vitamin, unit: "mg", glowColor: Color.orange, icon: "c.circle.fill"),
        TrackedNutrient(id: "vitamin_d", name: "Vitamin D", displayName: "Vitamin D", category: .vitamin, unit: "mcg", glowColor: Color.yellow, icon: "sun.max.fill"),
        TrackedNutrient(id: "vitamin_a", name: "Vitamin A", displayName: "Vitamin A", category: .vitamin, unit: "mcg", glowColor: Color.green, icon: "eye.fill"),
        TrackedNutrient(id: "vitamin_e", name: "Vitamin E", displayName: "Vitamin E", category: .vitamin, unit: "mg", glowColor: Color.mint, icon: "leaf.fill"),
        TrackedNutrient(id: "vitamin_k", name: "Vitamin K", displayName: "Vitamin K", category: .vitamin, unit: "mcg", glowColor: Color.teal, icon: "drop.fill"),
        TrackedNutrient(id: "vitamin_b1", name: "Thiamine", displayName: "Vitamin B1 (Thiamine)", category: .vitamin, unit: "mg", glowColor: Color.indigo, icon: "bolt.fill"),
        TrackedNutrient(id: "vitamin_b2", name: "Riboflavin", displayName: "Vitamin B2 (Riboflavin)", category: .vitamin, unit: "mg", glowColor: Color.purple, icon: "sparkles"),
        TrackedNutrient(id: "vitamin_b3", name: "Niacin", displayName: "Vitamin B3 (Niacin)", category: .vitamin, unit: "mg", glowColor: Color.pink, icon: "flame.fill"),
        TrackedNutrient(id: "vitamin_b6", name: "Vitamin B6", displayName: "Vitamin B6", category: .vitamin, unit: "mg", glowColor: Color.cyan, icon: "brain.head.profile"),
        TrackedNutrient(id: "vitamin_b12", name: "Vitamin B12", displayName: "Vitamin B12", category: .vitamin, unit: "mcg", glowColor: Color.red, icon: "heart.fill"),
        TrackedNutrient(id: "folate", name: "Folate", displayName: "Folate (B9)", category: .vitamin, unit: "mcg", glowColor: Color.green.opacity(0.7), icon: "leaf.arrow.circlepath"),
        TrackedNutrient(id: "biotin", name: "Biotin", displayName: "Biotin (B7)", category: .vitamin, unit: "mcg", glowColor: Color.brown, icon: "scissors"),
        TrackedNutrient(id: "vitamin_b5", name: "Pantothenic Acid", displayName: "Vitamin B5 (Pantothenic Acid)", category: .vitamin, unit: "mg", glowColor: Color.blue.opacity(0.7), icon: "star.fill"),

        // Minerals
        TrackedNutrient(id: "calcium", name: "Calcium", displayName: "Calcium", category: .mineral, unit: "mg", glowColor: Color.white, icon: "figure.strengthtraining.traditional"),
        TrackedNutrient(id: "iron", name: "Iron", displayName: "Iron", category: .mineral, unit: "mg", glowColor: Color(red: 0.8, green: 0.2, blue: 0.2), icon: "drop.triangle.fill"),
        TrackedNutrient(id: "magnesium", name: "Magnesium", displayName: "Magnesium", category: .mineral, unit: "mg", glowColor: Color(red: 0.5, green: 0.8, blue: 0.5), icon: "bolt.heart.fill"),
        TrackedNutrient(id: "potassium", name: "Potassium", displayName: "Potassium", category: .mineral, unit: "mg", glowColor: Color.yellow.opacity(0.8), icon: "waveform.path.ecg"),
        TrackedNutrient(id: "zinc", name: "Zinc", displayName: "Zinc", category: .mineral, unit: "mg", glowColor: Color.gray, icon: "shield.fill"),
        TrackedNutrient(id: "selenium", name: "Selenium", displayName: "Selenium", category: .mineral, unit: "mcg", glowColor: Color.orange.opacity(0.6), icon: "shield.checkered"),
        TrackedNutrient(id: "phosphorus", name: "Phosphorus", displayName: "Phosphorus", category: .mineral, unit: "mg", glowColor: Color.blue.opacity(0.6), icon: "atom"),
        TrackedNutrient(id: "copper", name: "Copper", displayName: "Copper", category: .mineral, unit: "mg", glowColor: Color.orange.opacity(0.8), icon: "circle.hexagongrid.fill"),
        TrackedNutrient(id: "manganese", name: "Manganese", displayName: "Manganese", category: .mineral, unit: "mg", glowColor: Color.purple.opacity(0.5), icon: "hexagon.fill"),
        TrackedNutrient(id: "iodine", name: "Iodine", displayName: "Iodine", category: .mineral, unit: "mcg", glowColor: Color.indigo.opacity(0.7), icon: "drop.keypad.rectangle"),
        TrackedNutrient(id: "chromium", name: "Chromium", displayName: "Chromium", category: .mineral, unit: "mcg", glowColor: Color(red: 0.75, green: 0.75, blue: 0.75), icon: "sparkle"),
        TrackedNutrient(id: "molybdenum", name: "Molybdenum", displayName: "Molybdenum", category: .mineral, unit: "mcg", glowColor: Color.gray.opacity(0.8), icon: "circle.grid.cross.fill"),

        // Other nutrients
        TrackedNutrient(id: "omega_3", name: "Omega-3", displayName: "Omega-3 Fatty Acids", category: .other, unit: "g", glowColor: Color.blue, icon: "fish.fill")
    ]

    static func nutrient(for id: String) -> TrackedNutrient? {
        return allNutrients.first { $0.id == id }
    }
}

// MARK: - Nutrient Detection Logic

struct NutrientDetector {
    /// Food source keywords for each nutrient
    /// TIGHTENED: Only includes foods that are SIGNIFICANT sources (>15% DV per typical serving)
    /// Based on USDA FoodData Central and UK CoFID database values
    static let nutrientFoodSources: [String: [String]] = [
        // Vitamin C: 90mg DV - only high sources (>15mg per serving)
        "vitamin_c": ["orange", "lemon", "lime", "grapefruit", "strawberry", "strawberries", "kiwi", "bell pepper", "peppers", "broccoli", "papaya", "guava", "mango"],
        // Vitamin D: 20mcg DV - very few natural sources
        "vitamin_d": ["salmon", "mackerel", "sardines", "herring", "cod liver oil", "fortified milk", "fortified cereal", "egg yolk"],
        // Vitamin A: 900mcg DV - only rich sources
        "vitamin_a": ["liver", "sweet potato", "carrot", "spinach", "kale", "butternut squash", "cantaloupe", "red pepper", "mango"],
        // Vitamin E: 15mg DV - concentrated sources only
        "vitamin_e": ["sunflower seeds", "almonds", "hazelnuts", "wheat germ", "sunflower oil", "safflower oil"],
        // Vitamin K: 120mcg DV - leafy greens dominate
        "vitamin_k": ["kale", "spinach", "collard greens", "swiss chard", "broccoli", "brussels sprouts", "parsley", "natto"],
        // B1 Thiamine: 1.2mg DV
        "vitamin_b1": ["pork", "sunflower seeds", "fortified cereals", "black beans", "lentils", "green peas"],
        // B2 Riboflavin: 1.3mg DV - removed generic terms
        "vitamin_b2": ["liver", "fortified cereals", "oats", "yogurt", "milk", "mushrooms", "almonds"],
        // B3 Niacin: 16mg DV
        "vitamin_b3": ["chicken breast", "turkey breast", "tuna", "salmon", "peanuts", "fortified cereals", "liver"],
        // B6: 1.7mg DV
        "vitamin_b6": ["chickpeas", "salmon", "tuna", "chicken breast", "turkey", "potato", "banana", "fortified cereals"],
        // B12: 2.4mcg DV - only animal/fortified sources
        "vitamin_b12": ["liver", "clams", "sardines", "salmon", "tuna", "beef", "fortified cereals", "nutritional yeast"],
        // Folate: 400mcg DV
        "folate": ["liver", "spinach", "black-eyed peas", "asparagus", "brussels sprouts", "fortified cereals", "avocado", "broccoli"],
        // Biotin: 30mcg DV - TIGHTENED: removed cheese (not significant)
        "biotin": ["liver", "egg yolk", "eggs", "salmon", "pork", "sunflower seeds", "sweet potato", "almonds"],
        // B5 Pantothenic Acid: 5mg DV - TIGHTENED: removed minor sources
        "vitamin_b5": ["liver", "shiitake mushrooms", "sunflower seeds", "chicken", "avocado", "fortified cereals"],
        // Calcium: 1000mg DV
        "calcium": ["milk", "yogurt", "yoghurt", "cheese", "sardines", "fortified orange juice", "tofu", "fortified cereals", "kale"],
        // Iron: 18mg DV - TIGHTENED: only significant sources
        "iron": ["liver", "oysters", "beef", "fortified cereals", "spinach", "lentils", "kidney beans", "tofu"],
        // Magnesium: 420mg DV
        "magnesium": ["pumpkin seeds", "chia seeds", "almonds", "spinach", "cashews", "black beans", "edamame", "dark chocolate"],
        // Potassium: 4700mg DV - very high threshold
        "potassium": ["potato", "sweet potato", "white beans", "spinach", "banana", "acorn squash", "salmon", "avocado"],
        // Zinc: 11mg DV - TIGHTENED
        "zinc": ["oysters", "beef", "crab", "lobster", "pork", "fortified cereals", "pumpkin seeds", "chickpeas"],
        // Selenium: 55mcg DV
        "selenium": ["brazil nuts", "tuna", "halibut", "sardines", "ham", "shrimp", "turkey"],
        // Phosphorus: 1250mg DV
        "phosphorus": ["salmon", "yogurt", "milk", "turkey", "chicken", "pumpkin seeds", "lentils"],
        // Copper: 0.9mg DV
        "copper": ["liver", "oysters", "shiitake mushrooms", "cashews", "crab", "sunflower seeds", "dark chocolate"],
        // Manganese: 2.3mg DV
        "manganese": ["mussels", "hazelnuts", "pecans", "brown rice", "oatmeal", "pineapple", "spinach"],
        // Iodine: 150mcg DV
        "iodine": ["seaweed", "cod", "iodized salt", "milk", "shrimp", "tuna", "eggs"],
        // Chromium: 35mcg DV - TIGHTENED: removed generic terms
        "chromium": ["broccoli", "grape juice", "mashed potatoes", "garlic", "green beans", "turkey breast"],
        // Molybdenum: 45mcg DV
        "molybdenum": ["black-eyed peas", "lima beans", "kidney beans", "lentils", "oats", "almonds"],
        // Omega-3: No official DV, but significant sources only
        "omega_3": ["salmon", "sardines", "mackerel", "herring", "anchovies", "trout", "walnuts", "flaxseed", "chia seeds"]
    ]

    /// Minimum meaningful thresholds - requires 10% Daily Value to count as a source
    /// This matches the DiaryTabView classify function for consistency
    /// Units match MicronutrientProfile fields (mg or mcg as annotated in the model)
    private static let nutrientThresholds: [String: Double] = [
        // Vitamins (10% of Daily Value)
        "vitamin_a": 90,       // mcg RAE (DV: 900mcg)
        "vitamin_c": 9,        // mg (DV: 90mg)
        "vitamin_d": 2,        // mcg (DV: 20mcg)
        "vitamin_e": 1.5,      // mg (DV: 15mg)
        "vitamin_k": 12,       // mcg (DV: 120mcg)
        "vitamin_b1": 0.12,    // mg (DV: 1.2mg)
        "vitamin_b2": 0.13,    // mg (DV: 1.3mg)
        "vitamin_b3": 1.6,     // mg (DV: 16mg)
        "vitamin_b6": 0.17,    // mg (DV: 1.7mg)
        "vitamin_b12": 0.24,   // mcg (DV: 2.4mcg)
        "folate": 40,          // mcg (DV: 400mcg)
        "biotin": 3,           // mcg (DV: 30mcg)
        "vitamin_b5": 0.5,     // mg (DV: 5mg)
        // Minerals (10% of Daily Value)
        "calcium": 100,        // mg (DV: 1000mg)
        "iron": 1.8,           // mg (DV: 18mg)
        "magnesium": 42,       // mg (DV: 420mg)
        "phosphorus": 125,     // mg (DV: 1250mg)
        "potassium": 470,      // mg (DV: 4700mg)
        "zinc": 1.1,           // mg (DV: 11mg)
        "selenium": 5.5,       // mcg (DV: 55mcg)
        "copper": 0.09,        // mg (DV: 0.9mg)
        "manganese": 0.23,     // mg (DV: 2.3mg)
        "iodine": 15,          // mcg (DV: 150mcg)
        "chromium": 3.5,       // mcg (DV: 35mcg)
        "molybdenum": 4.5      // mcg (DV: 45mcg)
    ]

    /// Detect which nutrients are present in a food item based on its micronutrient profile
    /// - Parameters:
    ///   - food: The food item to analyze
    ///   - strictThresholds: If true, requires 10% DV (for diary tracking). If false, shows any non-zero amounts (for display).
    static func detectNutrients(in food: DiaryFoodItem, strictThresholds: Bool = true) -> [String] {
        var detectedNutrients: Set<String> = []

        // Use actual micronutrient data if available
        if let profile = food.micronutrientProfile {
            // Check vitamins
            for (vitaminKey, amount) in profile.vitamins {
                if amount > 0 {
                    let nutrientId = mapVitaminKeyToNutrientId(vitaminKey)
                    if !nutrientId.isEmpty {
                        // For display (non-strict), show any non-zero value
                        // For diary tracking (strict), require 10% DV
                        if !strictThresholds || passesThreshold(nutrientId: nutrientId, amount: amount) {
                            detectedNutrients.insert(nutrientId)
                        }
                    }
                }
            }

            // Check minerals
            for (mineralKey, amount) in profile.minerals {
                if amount > 0 {
                    let nutrientId = mapMineralKeyToNutrientId(mineralKey)
                    if !nutrientId.isEmpty {
                        if !strictThresholds || passesThreshold(nutrientId: nutrientId, amount: amount) {
                            detectedNutrients.insert(nutrientId)
                        }
                    }
                }
            }
        }

        // Use pattern-based parser for fortified nutrients from ingredients
        if let ingredients = food.ingredients, !ingredients.isEmpty {
            let fortifiedNutrients = IngredientMicronutrientParser.shared.parseIngredientsArray(ingredients)
            for detected in fortifiedNutrients {
                detectedNutrients.insert(detected.nutrient)
            }
        }

        // Keyword-based detection from ingredients
        if let ingredients = food.ingredients, !ingredients.isEmpty {
            let lowerIngredients = ingredients.map { $0.lowercased() }
            let topIngredients = Array(lowerIngredients.prefix(5)) // focus on primary ingredients to reduce false positives

            for (nutrientId, keywords) in nutrientFoodSources {
                var matched = false
                for ingredient in topIngredients {
                    for keyword in keywords {
                        if containsWholeWord(in: ingredient, keyword: keyword) {
                            matched = true
                            break
                        }
                    }
                    if matched { break }
                }
                if matched {
                    detectedNutrients.insert(nutrientId)
                }
            }
        }

        // ALSO check food name for whole food matches (e.g., "Apple" as food name)
        let lowerName = food.name.lowercased()
        for (nutrientId, keywords) in nutrientFoodSources {
            for keyword in keywords {
                if containsWholeWord(in: lowerName, keyword: keyword) {
                    detectedNutrients.insert(nutrientId)
                    break
                }
            }
        }

        let ordering = NutrientDatabase.allNutrients.map { $0.id }
        return Array(detectedNutrients).sorted { a, b in
            let ia = ordering.firstIndex(of: a) ?? Int.max
            let ib = ordering.firstIndex(of: b) ?? Int.max
            if ia != ib { return ia < ib }
            return a < b
        }
    }

    /// Apply minimum meaningful thresholds for micronutrient profile amounts
    private static func passesThreshold(nutrientId: String, amount: Double) -> Bool {
        guard let threshold = nutrientThresholds[nutrientId] else {
            return amount > 0
        }
        return amount >= threshold
    }

    /// Whole-word match helper to avoid matching flavours/aromas
    private static func containsWholeWord(in text: String, keyword: String) -> Bool {
        // Quick rejects
        if text.isEmpty || keyword.isEmpty { return false }

        // Avoid matching flavour-only mentions
        if text.contains("flavor") || text.contains("flavour") || text.contains("aroma") {
            // Require exact whole-word match to reduce false positives in flavour strings
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: keyword.lowercased()))\\b"
            return text.range(of: pattern, options: .regularExpression) != nil
        }

        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: keyword.lowercased()))\\b"
        return text.range(of: pattern, options: .regularExpression) != nil
    }

    /// Map vitamin dictionary keys to nutrient IDs
    private static func mapVitaminKeyToNutrientId(_ key: String) -> String {
        let mapping: [String: String] = [
            "vitaminA": "vitamin_a",
            "vitamin_a": "vitamin_a",
            "vitaminC": "vitamin_c",
            "vitamin_c": "vitamin_c",
            "vitaminD": "vitamin_d",
            "vitamin_d": "vitamin_d",
            "vitaminE": "vitamin_e",
            "vitamin_e": "vitamin_e",
            "vitaminK": "vitamin_k",
            "vitamin_k": "vitamin_k",
            "thiamine": "vitamin_b1",
            "vitamin_b1": "vitamin_b1",
            "riboflavin": "vitamin_b2",
            "vitamin_b2": "vitamin_b2",
            "niacin": "vitamin_b3",
            "vitamin_b3": "vitamin_b3",
            "vitaminB6": "vitamin_b6",
            "vitamin_b6": "vitamin_b6",
            "vitaminB12": "vitamin_b12",
            "vitamin_b12": "vitamin_b12",
            "folate": "folate",
            "biotin": "biotin",
            "vitamin_b7": "biotin",
            "pantothenicAcid": "vitamin_b5",
            "pantothenic_acid": "vitamin_b5",
            "vitamin_b5": "vitamin_b5"
        ]
        return mapping[key] ?? ""
    }

    /// Map mineral dictionary keys to nutrient IDs
    private static func mapMineralKeyToNutrientId(_ key: String) -> String {
        let mapping: [String: String] = [
            "calcium": "calcium",
            "iron": "iron",
            "magnesium": "magnesium",
            "phosphorus": "phosphorus",
            "potassium": "potassium",
            "sodium": "", // sodium not tracked as a nutrient here; ignore
            "zinc": "zinc",
            "selenium": "selenium",
            "copper": "copper",
            "manganese": "manganese",
            "iodine": "iodine",
            "chromium": "chromium",
            "molybdenum": "molybdenum"
        ]
        return mapping[key] ?? ""
    }
}
