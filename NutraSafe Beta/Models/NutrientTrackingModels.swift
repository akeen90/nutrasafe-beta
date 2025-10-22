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
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
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
    static let nutrientFoodSources: [String: [String]] = [
        "vitamin_c": ["orange", "lemon", "lime", "strawberry", "strawberries", "kiwi", "bell pepper", "peppers", "broccoli", "tomato", "potato", "papaya", "guava"],
        "vitamin_d": ["salmon", "tuna", "mackerel", "sardines", "egg", "eggs", "fortified milk", "fortified cereal", "mushrooms", "cod liver oil"],
        "vitamin_a": ["carrot", "sweet potato", "spinach", "kale", "pumpkin", "mango", "apricot", "liver", "egg yolk", "red pepper"],
        "vitamin_e": ["almonds", "sunflower seeds", "hazelnuts", "peanuts", "avocado", "spinach", "broccoli", "olive oil", "wheat germ"],
        "vitamin_k": ["kale", "spinach", "broccoli", "brussels sprouts", "cabbage", "lettuce", "asparagus", "parsley"],
        "vitamin_b1": ["pork", "beans", "lentils", "nuts", "whole grains", "fortified cereals", "sunflower seeds"],
        "vitamin_b2": ["milk", "yogurt", "cheese", "eggs", "lean meats", "almonds", "spinach"],
        "vitamin_b3": ["chicken", "turkey", "tuna", "salmon", "peanuts", "mushrooms", "green peas"],
        "vitamin_b6": ["chicken", "turkey", "tuna", "salmon", "potato", "chickpeas", "banana"],
        "vitamin_b12": ["meat", "fish", "dairy", "eggs", "nutritional yeast", "fortified", "clams", "liver"],
        "folate": ["leafy greens", "spinach", "asparagus", "avocado", "beans", "lentils", "fortified", "broccoli"],
        "biotin": ["eggs", "almonds", "sweet potato", "spinach", "broccoli", "cheese", "salmon"],
        "vitamin_b5": ["chicken", "beef", "potato", "oats", "tomato", "broccoli", "whole grains", "avocado", "mushrooms", "eggs"],
        "calcium": ["milk", "cheese", "yogurt", "yoghurt", "broccoli", "kale", "sardines", "almonds", "tofu", "fortified"],
        "iron": ["spinach", "beef", "chicken", "turkey", "lentils", "beans", "quinoa", "tofu", "liver", "oysters"],
        "magnesium": ["almonds", "spinach", "cashews", "peanuts", "black beans", "avocado", "dark chocolate"],
        "potassium": ["banana", "potato", "sweet potato", "spinach", "avocado", "beans", "lentils", "yogurt"],
        "zinc": ["oysters", "beef", "chicken", "beans", "nuts", "seeds", "dairy", "whole grains"],
        "selenium": ["brazil nuts", "tuna", "halibut", "sardines", "shrimp", "turkey", "chicken"],
        "phosphorus": ["dairy", "meat", "fish", "poultry", "beans", "lentils", "nuts", "whole grains"],
        "copper": ["shellfish", "nuts", "seeds", "organ meats", "beans", "dark chocolate"],
        "manganese": ["nuts", "beans", "whole grains", "tea", "leafy vegetables", "pineapple"],
        "iodine": ["seaweed", "cod", "dairy", "iodized salt", "shrimp", "eggs"],
        "chromium": ["broccoli", "grapes", "potatoes", "garlic", "whole grains", "beef", "turkey", "green beans"],
        "molybdenum": ["lentils", "beans", "peas", "nuts", "whole grains", "leafy vegetables", "liver"],
        "omega_3": ["salmon", "sardines", "mackerel", "walnuts", "flax", "flaxseed", "chia", "hemp", "tuna"]
    ]

    /// Detect which nutrients are present in a food item based on its micronutrient profile
    static func detectNutrients(in food: DiaryFoodItem) -> [String] {
        var detectedNutrients: Set<String> = []

        // Use actual micronutrient data if available
        if let profile = food.micronutrientProfile {
            print("🔍 Detecting nutrients in '\(food.name)' using micronutrient profile")

            // Check vitamins
            for (vitaminKey, amount) in profile.vitamins {
                if amount > 0 {
                    // Map vitamin keys to nutrient IDs
                    let nutrientId = mapVitaminKeyToNutrientId(vitaminKey)
                    if !nutrientId.isEmpty {
                        detectedNutrients.insert(nutrientId)
                        print("  ✅ Found vitamin: \(vitaminKey) -> \(nutrientId) (\(amount))")
                    }
                }
            }

            // Check minerals
            for (mineralKey, amount) in profile.minerals {
                if amount > 0 {
                    // Map mineral keys to nutrient IDs
                    let nutrientId = mapMineralKeyToNutrientId(mineralKey)
                    if !nutrientId.isEmpty {
                        detectedNutrients.insert(nutrientId)
                        print("  ✅ Found mineral: \(mineralKey) -> \(nutrientId) (\(amount))")
                    }
                }
            }

            print("  📊 Total nutrients from profile: \(detectedNutrients.count)")
        } else {
            print("🔍 Detecting nutrients in '\(food.name)' using keyword matching (no micronutrient profile)")
        }

        // ALWAYS do keyword-based detection for nutrients not in micronutrient profiles
        // (like omega-3, lutein, lycopene, etc.) regardless of whether food has a profile
        print("  🔎 Supplementing with keyword matching for special nutrients...")
        let searchText = "\(food.name.lowercased()) \(food.brand?.lowercased() ?? "") \(food.ingredients?.joined(separator: " ").lowercased() ?? "")"

        for (nutrientId, keywords) in nutrientFoodSources {
            for keyword in keywords {
                if searchText.contains(keyword.lowercased()) {
                    let wasNew = detectedNutrients.insert(nutrientId).inserted
                    if wasNew {
                        print("  ✅ Found keyword '\(keyword)' -> \(nutrientId)")
                    }
                    break
                }
            }
        }

        print("  📊 Total nutrients detected: \(detectedNutrients.count)")
        return Array(detectedNutrients)
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
            "sodium": "potassium", // sodium tracking not in our nutrient list
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
