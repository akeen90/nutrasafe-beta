//
//  NutrientInsightsViewModel.swift
//  NutraSafe Beta
//
//  ViewModel for calculating daily nutrient insights and suggestions
//

import Foundation
import SwiftUI

@MainActor
class NutrientInsightsViewModel: ObservableObject {
    @Published var dailySummary: DailyNutrientSummary?
    @Published var userPreferences: UserNutrientPreferences = .default
    @Published var isLoading: Bool = false

    private let firebaseManager: FirebaseManager

    // Nutrient database reference - use the same system as the rest of the app
    private let nutrientDatabase = NutrientDatabase.allNutrients
        .filter { nut in
            let id = nut.id.lowercased()
            let name = nut.name.lowercased()
            return !(id.contains("omega3") || id.contains("omega_3") || name.contains("omega-3") || name.contains("omega 3"))
        }

    // Daily Values for micronutrients (UK/EU recommendations for adults) - for display only
    private let dailyValues: [String: (amount: Double, unit: String)] = [
        "Vitamin A": (800, "μg"),
        "Vitamin C": (80, "mg"),
        "Vitamin D": (10, "μg"),
        "Vitamin E": (12, "mg"),
        "Vitamin K": (75, "μg"),
        "Thiamin (B1)": (1.1, "mg"),
        "Riboflavin (B2)": (1.4, "mg"),
        "Niacin (B3)": (16, "mg"),
        "Vitamin B6": (1.4, "mg"),
        "Folate": (200, "μg"),
        "Vitamin B12": (2.5, "μg"),
        "Calcium": (800, "mg"),
        "Iron": (14, "mg"),
        "Magnesium": (375, "mg"),
        "Zinc": (10, "mg"),
        "Selenium": (55, "μg"),
        "Potassium": (2000, "mg"),
        "Phosphorus": (700, "mg")
    ]

    // Food sources database for suggestions
    private let foodSources: [String: [FoodSuggestion]] = [
        "Vitamin A": [
            FoodSuggestion(name: "Sweet Potato", nutrientAmount: 1043, unit: "μg", servingSize: "100g"),
            FoodSuggestion(name: "Carrots", nutrientAmount: 835, unit: "μg", servingSize: "100g"),
            FoodSuggestion(name: "Spinach", nutrientAmount: 469, unit: "μg", servingSize: "100g"),
            FoodSuggestion(name: "Butternut Squash", nutrientAmount: 532, unit: "μg", servingSize: "100g")
        ],
        "Vitamin C": [
            FoodSuggestion(name: "Red Pepper", nutrientAmount: 128, unit: "mg", servingSize: "100g"),
            FoodSuggestion(name: "Orange", nutrientAmount: 53, unit: "mg", servingSize: "100g"),
            FoodSuggestion(name: "Strawberries", nutrientAmount: 59, unit: "mg", servingSize: "100g"),
            FoodSuggestion(name: "Kiwi", nutrientAmount: 93, unit: "mg", servingSize: "100g")
        ],
        "Vitamin D": [
            FoodSuggestion(name: "Salmon", nutrientAmount: 13, unit: "μg", servingSize: "100g"),
            FoodSuggestion(name: "Mackerel", nutrientAmount: 16, unit: "μg", servingSize: "100g"),
            FoodSuggestion(name: "Egg Yolk", nutrientAmount: 2, unit: "μg", servingSize: "100g"),
            FoodSuggestion(name: "Fortified Milk", nutrientAmount: 1.3, unit: "μg", servingSize: "100ml")
        ],
        "Calcium": [
            FoodSuggestion(name: "Milk", nutrientAmount: 120, unit: "mg", servingSize: "100ml"),
            FoodSuggestion(name: "Cheddar Cheese", nutrientAmount: 720, unit: "mg", servingSize: "100g"),
            FoodSuggestion(name: "Greek Yogurt", nutrientAmount: 110, unit: "mg", servingSize: "100g"),
            FoodSuggestion(name: "Tofu", nutrientAmount: 350, unit: "mg", servingSize: "100g")
        ],
        "Iron": [
            FoodSuggestion(name: "Beef Steak", nutrientAmount: 2.6, unit: "mg", servingSize: "100g"),
            FoodSuggestion(name: "Spinach", nutrientAmount: 2.7, unit: "mg", servingSize: "100g"),
            FoodSuggestion(name: "Lentils", nutrientAmount: 3.3, unit: "mg", servingSize: "100g"),
            FoodSuggestion(name: "Chickpeas", nutrientAmount: 2.9, unit: "mg", servingSize: "100g")
        ],
        "Magnesium": [
            FoodSuggestion(name: "Almonds", nutrientAmount: 270, unit: "mg", servingSize: "100g"),
            FoodSuggestion(name: "Spinach", nutrientAmount: 79, unit: "mg", servingSize: "100g"),
            FoodSuggestion(name: "Cashews", nutrientAmount: 292, unit: "mg", servingSize: "100g"),
            FoodSuggestion(name: "Black Beans", nutrientAmount: 70, unit: "mg", servingSize: "100g")
        ],
        "Zinc": [
            FoodSuggestion(name: "Oysters", nutrientAmount: 78, unit: "mg", servingSize: "100g"),
            FoodSuggestion(name: "Beef", nutrientAmount: 4.8, unit: "mg", servingSize: "100g"),
            FoodSuggestion(name: "Pumpkin Seeds", nutrientAmount: 7.6, unit: "mg", servingSize: "100g"),
            FoodSuggestion(name: "Chickpeas", nutrientAmount: 1.5, unit: "mg", servingSize: "100g")
        ],
        "Vitamin B12": [
            FoodSuggestion(name: "Salmon", nutrientAmount: 3.2, unit: "μg", servingSize: "100g"),
            FoodSuggestion(name: "Beef", nutrientAmount: 2.4, unit: "μg", servingSize: "100g"),
            FoodSuggestion(name: "Eggs", nutrientAmount: 1.1, unit: "μg", servingSize: "100g"),
            FoodSuggestion(name: "Milk", nutrientAmount: 0.5, unit: "μg", servingSize: "100ml")
        ],
        "Folate": [
            FoodSuggestion(name: "Spinach", nutrientAmount: 194, unit: "μg", servingSize: "100g"),
            FoodSuggestion(name: "Lentils", nutrientAmount: 181, unit: "μg", servingSize: "100g"),
            FoodSuggestion(name: "Asparagus", nutrientAmount: 149, unit: "μg", servingSize: "100g"),
            FoodSuggestion(name: "Broccoli", nutrientAmount: 108, unit: "μg", servingSize: "100g")
        ],
        "Potassium": [
            FoodSuggestion(name: "Banana", nutrientAmount: 358, unit: "mg", servingSize: "100g"),
            FoodSuggestion(name: "Sweet Potato", nutrientAmount: 337, unit: "mg", servingSize: "100g"),
            FoodSuggestion(name: "Avocado", nutrientAmount: 485, unit: "mg", servingSize: "100g"),
            FoodSuggestion(name: "Salmon", nutrientAmount: 363, unit: "mg", servingSize: "100g")
        ]
    ]

    init(firebaseManager: FirebaseManager = .shared) {
        self.firebaseManager = firebaseManager
    }

    // MARK: - Load User Preferences
    func loadUserPreferences() async {
        do {
            if let preferences = try await firebaseManager.loadNutrientPreferences() {
                self.userPreferences = preferences
            }
        } catch {
            print("Error loading nutrient preferences: \(error.localizedDescription)")
        }
    }

    // MARK: - Calculate Daily Insights
    func calculateDailyInsights(for date: Date) async {
        isLoading = true
        defer { isLoading = false }

        // Load user preferences first
        await loadUserPreferences()

        // Get diary entries for the specified date
        let allEntries = (try? await firebaseManager.getFoodEntries(for: date)) ?? []

        // Calculate nutrient levels using the same system as DiaryTabView
        var nutrientLevels: [String: SourceLevel] = [:]
        var contributingFoodsMap: [String: [ContributingFood]] = [:]

        for nutrient in nutrientDatabase {
            let level = highestLevel(for: nutrient.id, entries: allEntries)
            nutrientLevels[nutrient.name] = level

            // Track contributing foods
            for entry in allEntries {
                // Recalculate micronutrient profile with improved estimation
                let freshProfile = recalculateMicronutrientProfile(for: entry)
                let profileKey = nutrientIdToProfileKey(nutrient.id)

                if let amt = freshProfile.vitamins[profileKey] ?? freshProfile.minerals[profileKey] {
                    let foodLevel = classify(amount: amt, key: profileKey, profile: freshProfile)
                    if foodLevel != .none {
                        let food = ContributingFood(
                            name: entry.foodName,
                            amount: amt,
                            unit: dailyValues[nutrient.name]?.unit ?? "mg",
                            mealType: entry.mealType.rawValue
                        )
                        contributingFoodsMap[nutrient.name, default: []].append(food)
                    }
                }
            }
        }

        // Generate insights
        var insights: [DailyNutrientInsight] = []

        for nutrient in nutrientDatabase {
            let dvInfo = dailyValues[nutrient.name] ?? (0, "mg")
            let target = dvInfo.amount

            // Calculate ACTUAL consumed amount from food entries
            var totalConsumed: Double = 0
            let profileKey = nutrientIdToProfileKey(nutrient.id)

            for entry in allEntries {
                let freshProfile = recalculateMicronutrientProfile(for: entry)
                if let amt = freshProfile.vitamins[profileKey] ?? freshProfile.minerals[profileKey] {
                    totalConsumed += amt
                }
            }

            // Calculate actual percentage
            let percentage = target > 0 ? (totalConsumed / target) * 100 : 0

            // Skip nutrients with no meaningful data
            if percentage < 1 {
                continue
            }

            // Determine severity based on actual percentage
            let severity: InsightLevel
            if percentage < 30 {
                severity = .critical
            } else if percentage < 70 {
                severity = .low
            } else if percentage < 100 {
                severity = .good
            } else {
                severity = .excellent
            }

            let isPriority = userPreferences.focusNutrients.contains(nutrient.name)

            // Get food suggestions
            let suggestions = foodSources[nutrient.name] ?? []

            let insight = DailyNutrientInsight(
                nutrient: nutrient.name,
                consumed: totalConsumed,
                target: target,
                unit: dvInfo.unit,
                severity: severity,
                suggestedFoods: suggestions,
                isPriorityNutrient: isPriority
            )

            insights.append(insight)
        }

        // Create summary
        dailySummary = DailyNutrientSummary(
            date: date,
            insights: insights,
            contributingFoods: contributingFoodsMap
        )
    }

    // MARK: - Helper Methods (same as DiaryTabView)

    private func highestLevel(for nutrientId: String, entries: [FoodEntry]) -> SourceLevel {
        var best: SourceLevel = .none
        let profileKey = nutrientIdToProfileKey(nutrientId)

        for entry in entries {
            let freshProfile = recalculateMicronutrientProfile(for: entry)

            if let amt = freshProfile.vitamins[profileKey] ?? freshProfile.minerals[profileKey] {
                let level = classify(amount: amt, key: profileKey, profile: freshProfile)
                best = max(best, level)
            } else {
                // Fallback: use keyword detection
                let food = DiaryFoodItem.fromFoodEntry(entry)
                let present = NutrientDetector.detectNutrients(in: food).contains(nutrientId)
                best = max(best, present ? .trace : .none)
            }
        }

        return best
    }

    private func classify(amount: Double, key: String, profile: MicronutrientProfile) -> SourceLevel {
        if amount <= 0 { return .none }
        let dvKey = dvKey(for: key)

        if let percent = profile.getDailyValuePercentage(for: dvKey, amount: amount) {
            if percent >= 70 { return .strong }
            if percent >= 30 { return .moderate }
            return .trace
        }

        return .trace
    }

    private func nutrientIdToProfileKey(_ nutrientId: String) -> String {
        switch nutrientId.lowercased() {
        case "vitamin_c": return "vitaminC"
        case "vitamin_d": return "vitaminD"
        case "vitamin_a": return "vitaminA"
        case "vitamin_e": return "vitaminE"
        case "vitamin_k": return "vitaminK"
        case "vitamin_b1": return "thiamine"
        case "vitamin_b2": return "riboflavin"
        case "vitamin_b3": return "niacin"
        case "vitamin_b5": return "pantothenicAcid"
        case "vitamin_b6": return "vitaminB6"
        case "vitamin_b7", "biotin": return "biotin"
        case "vitamin_b9", "folate": return "folate"
        case "vitamin_b12": return "vitaminB12"
        case "choline": return "choline"
        case "calcium": return "calcium"
        case "iron": return "iron"
        case "magnesium": return "magnesium"
        case "phosphorus": return "phosphorus"
        case "potassium": return "potassium"
        case "sodium": return "sodium"
        case "zinc": return "zinc"
        case "copper": return "copper"
        case "manganese": return "manganese"
        case "selenium": return "selenium"
        case "chromium": return "chromium"
        case "molybdenum": return "molybdenum"
        case "iodine": return "iodine"
        default: return nutrientId.lowercased()
        }
    }

    private func dvKey(for key: String) -> String {
        switch key.lowercased() {
        case "vitaminc": return "vitaminC"
        case "vitamina": return "vitaminA"
        case "vitamind": return "vitaminD"
        case "vitamine": return "vitaminE"
        case "vitamink": return "vitaminK"
        case "thiamine": return "thiamine"
        case "riboflavin": return "riboflavin"
        case "niacin": return "niacin"
        case "pantothenicacid": return "pantothenicAcid"
        case "vitaminb6": return "vitaminB6"
        case "biotin": return "biotin"
        case "folate": return "folate"
        case "vitaminb12": return "vitaminB12"
        case "choline": return "choline"
        default: return key.lowercased()
        }
    }

    private func recalculateMicronutrientProfile(for entry: FoodEntry) -> MicronutrientProfile {
        let servingSize = entry.servingSize
        let multiplier = servingSize / 100.0

        let per100gCalories = multiplier > 0 ? entry.calories / multiplier : entry.calories
        let per100gProtein = multiplier > 0 ? entry.protein / multiplier : entry.protein
        let per100gCarbs = multiplier > 0 ? entry.carbohydrates / multiplier : entry.carbohydrates
        let per100gFat = multiplier > 0 ? entry.fat / multiplier : entry.fat
        let per100gFiber = multiplier > 0 ? (entry.fiber ?? 0) / multiplier : (entry.fiber ?? 0)
        let per100gSugar = multiplier > 0 ? (entry.sugar ?? 0) / multiplier : (entry.sugar ?? 0)
        let per100gSodium = multiplier > 0 ? (entry.sodium ?? 0) / multiplier : (entry.sodium ?? 0)

        let foodSearchResult = FoodSearchResult(
            id: entry.id,
            name: entry.foodName,
            brand: entry.brandName,
            calories: per100gCalories,
            protein: per100gProtein,
            carbs: per100gCarbs,
            fat: per100gFat,
            fiber: per100gFiber,
            sugar: per100gSugar,
            sodium: per100gSodium,
            servingDescription: "100g",
            servingSizeG: 100.0,
            ingredients: entry.ingredients,
            isVerified: true,
            micronutrientProfile: nil
        )

        return MicronutrientManager.shared.getMicronutrientProfile(for: foodSearchResult, quantity: multiplier)
    }

    // MARK: - Update User Preferences
    func updateFocusNutrients(_ nutrients: [String]) async {
        userPreferences.focusNutrients = nutrients
        userPreferences.lastUpdated = Date()

        do {
            try await firebaseManager.saveNutrientPreferences(userPreferences)
        } catch {
            print("Error saving nutrient preferences: \(error.localizedDescription)")
        }
    }

    // MARK: - Get Contributing Foods for Nutrient
    func getContributingFoods(for nutrient: String, on date: Date) -> [ContributingFood] {
        guard let summary = dailySummary,
              Calendar.current.isDate(summary.date, inSameDayAs: date) else {
            return []
        }

        return summary.contributingFoods[nutrient] ?? []
    }

    // MARK: - Get Available Nutrients
    var allNutrients: [String] {
        return Array(dailyValues.keys).sorted()
    }
}
