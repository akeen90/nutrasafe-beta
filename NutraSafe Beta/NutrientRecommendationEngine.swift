//
//  NutrientRecommendationEngine.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-10-21.
//  Smart food recommendation engine based on nutrient intake tracking
//

import Foundation
import SwiftUI

// MARK: - Food Recommendation

struct FoodRecommendation: Identifiable {
    let id = UUID()
    let foodName: String
    let targetNutrients: [String] // Nutrients this food is a good source of
    let expectedImpact: String // e.g., "Provides 40% Vitamin C, 25% Iron"
    let reason: String // Why this food is suggested
    let priority: RecommendationPriority
    let category: FoodCategory
}

enum RecommendationPriority: Int, Comparable {
    case high = 3      // Multiple nutrients tracked at lower levels
    case medium = 2    // One or more nutrients tracked at lower levels
    case suggested = 1 // Additional nutrient sources

    static func < (lhs: RecommendationPriority, rhs: RecommendationPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .high: return "Rich in Multiple Nutrients"
        case .medium: return "Good Source"
        case .suggested: return "Also Consider"
        }
    }

    var color: Color {
        switch self {
        case .high: return .blue
        case .medium: return .green
        case .suggested: return .gray
        }
    }
}

enum FoodCategory: String, CaseIterable {
    case vegetables = "Vegetables"
    case fruits = "Fruits"
    case proteins = "Proteins"
    case dairy = "Dairy"
    case grains = "Grains"
    case nuts = "Nuts & Seeds"
    case seafood = "Seafood"
    case other = "Other"

    var icon: String {
        switch self {
        case .vegetables: return "🥬"
        case .fruits: return "🍎"
        case .proteins: return "🍗"
        case .dairy: return "🥛"
        case .grains: return "🌾"
        case .nuts: return "🥜"
        case .seafood: return "🐟"
        case .other: return "🍽️"
        }
    }
}

// MARK: - Recommendation Engine

@MainActor
class NutrientRecommendationEngine: ObservableObject {
    static let shared = NutrientRecommendationEngine()

    @Published private(set) var recommendations: [FoodRecommendation] = []
    @Published private(set) var isAnalyzing = false

    private let database = MicronutrientDatabase.shared

    private init() {}

    // MARK: - Generate Recommendations

    /// Generate personalized food suggestions based on current nutrient intake tracking
    func generateRecommendations(for summaries: [MicronutrientSummary]) async {
        isAnalyzing = true
        defer { isAnalyzing = false }

        var newRecommendations: [FoodRecommendation] = []

        // Identify nutrients tracked at lower levels (0-30%)
        let lowerTrackedNutrients = summaries.filter { $0.todayPercentage <= 30 }

        // Identify moderate intake levels (31-70%)
        let moderateNutrients = summaries.filter { $0.todayPercentage > 30 && $0.todayPercentage <= 70 }

        // Generate suggestions for nutrients tracked at lower levels
        for nutrient in lowerTrackedNutrients {
            if let nutrientRecs = generateRecommendationsForNutrient(nutrient, priority: .medium) {
                newRecommendations.append(contentsOf: nutrientRecs)
            }
        }

        // Generate suggestions for moderate intake nutrients
        for nutrient in moderateNutrients.prefix(3) { // Limit to top 3
            if let nutrientRecs = generateRecommendationsForNutrient(nutrient, priority: .suggested) {
                newRecommendations.append(contentsOf: nutrientRecs)
            }
        }

        // Check for foods rich in multiple nutrients
        let multiNutrientCombos = findMultiNutrientCombinations(lowerTrackedNutrients)
        for combo in multiNutrientCombos {
            if let comboRecs = generateRecommendationsForCombination(combo) {
                newRecommendations.append(contentsOf: comboRecs)
            }
        }

        // Deduplicate and sort by priority
        let uniqueRecs = Dictionary(grouping: newRecommendations) { $0.foodName }
            .compactMap { $0.value.first }

        recommendations = uniqueRecs.sorted { $0.priority > $1.priority }
    }

    // MARK: - Private Recommendation Logic

    private func generateRecommendationsForNutrient(
        _ summary: MicronutrientSummary,
        priority: RecommendationPriority
    ) -> [FoodRecommendation]? {

        guard let info = summary.info,
              let sources = info.commonSources else {
            return nil
        }

        // Parse JSON array format into individual foods
        let foods = parseArrayString(sources)

        return foods.prefix(3).map { foodName in
            FoodRecommendation(
                foodName: foodName,
                targetNutrients: [summary.name],
                expectedImpact: "Excellent source of \(summary.name)",
                reason: "You're at \(summary.todayPercentage)% of recommended \(summary.name)",
                priority: priority,
                category: categorizeFood(foodName)
            )
        }
    }

    /// Parse JSON array string format like ["Item1", "Item2"] into clean string array
    private func parseArrayString(_ content: String) -> [String] {
        // Try to decode as JSON array first
        if let data = content.data(using: .utf8),
           let array = try? JSONDecoder().decode([String].self, from: data) {
            return array.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }

        // Fallback: manually parse array format
        let trimmed = content.trimmingCharacters(in: CharacterSet(charactersIn: "[]\""))
        if trimmed.contains(",") {
            return trimmed
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: " \"")) }
                .filter { !$0.isEmpty }
        }

        // Return as single item if not parseable and not empty
        return trimmed.isEmpty ? [] : [trimmed]
    }

    private func generateRecommendationsForCombination(
        _ nutrients: [MicronutrientSummary]
    ) -> [FoodRecommendation]? {

        // Find foods that are good sources for multiple nutrients
        let nutrientNames = nutrients.map { $0.nutrient }

        // Predefined multi-nutrient rich foods
        // Data based on USDA FoodData Central nutrient composition
        // Source: https://fdc.nal.usda.gov/
        let nutrientRichFoods: [(String, [String], FoodCategory)] = [
            ("Spinach", ["vitamin_a", "iron", "vitamin_c", "folate"], .vegetables),
            ("Salmon", ["vitamin_d", "vitamin_b12", "omega3"], .seafood),
            ("Eggs", ["vitamin_d", "vitamin_b12", "vitamin_a"], .proteins),
            ("Almonds", ["vitamin_e", "magnesium", "calcium"], .nuts),
            ("Sweet Potato", ["vitamin_a", "vitamin_c", "potassium"], .vegetables),
            ("Kale", ["vitamin_k", "vitamin_a", "vitamin_c", "calcium"], .vegetables),
            ("Lentils", ["iron", "folate", "zinc"], .proteins),
            ("Greek Yogurt", ["calcium", "vitamin_b12", "vitamin_d"], .dairy),
            ("Quinoa", ["iron", "magnesium", "zinc"], .grains),
            ("Blueberries", ["vitamin_c", "vitamin_k"], .fruits)
        ]

        var recs: [FoodRecommendation] = []

        for (food, foodNutrients, category) in nutrientRichFoods {
            let matches = foodNutrients.filter { nutrientNames.contains($0) }

            if matches.count >= 2 {
                let matchedNames = nutrients.filter { matches.contains($0.nutrient) }.map { $0.name }

                recs.append(FoodRecommendation(
                    foodName: food,
                    targetNutrients: matchedNames,
                    expectedImpact: "Provides \(matchedNames.joined(separator: ", "))",
                    reason: "Rich source of \(matches.count) nutrients you're tracking",
                    priority: .high,
                    category: category
                ))
            }
        }

        return recs.isEmpty ? nil : recs
    }

    private func findMultiNutrientCombinations(_ lowerTrackedNutrients: [MicronutrientSummary]) -> [[MicronutrientSummary]] {
        // Group multiple nutrients to suggest foods rich in several nutrients
        var combinations: [[MicronutrientSummary]] = []

        if lowerTrackedNutrients.count >= 3 {
            // If 3+ nutrients are at lower intake levels, suggest foods rich in multiple nutrients
            combinations.append(Array(lowerTrackedNutrients.prefix(5)))
        }

        return combinations
    }

    private func categorizeFood(_ foodName: String) -> FoodCategory {
        let name = foodName.lowercased()

        // Vegetables
        if name.contains("spinach") || name.contains("kale") || name.contains("broccoli") ||
           name.contains("carrot") || name.contains("pepper") || name.contains("lettuce") {
            return .vegetables
        }

        // Fruits
        if name.contains("berry") || name.contains("apple") || name.contains("orange") ||
           name.contains("banana") || name.contains("grape") || name.contains("melon") {
            return .fruits
        }

        // Proteins
        if name.contains("chicken") || name.contains("beef") || name.contains("pork") ||
           name.contains("turkey") || name.contains("egg") || name.contains("lentil") ||
           name.contains("bean") {
            return .proteins
        }

        // Seafood
        if name.contains("fish") || name.contains("salmon") || name.contains("tuna") ||
           name.contains("shrimp") || name.contains("sardine") {
            return .seafood
        }

        // Dairy
        if name.contains("milk") || name.contains("yogurt") || name.contains("cheese") ||
           name.contains("dairy") {
            return .dairy
        }

        // Nuts & Seeds
        if name.contains("almond") || name.contains("walnut") || name.contains("seed") ||
           name.contains("nut") {
            return .nuts
        }

        // Grains
        if name.contains("bread") || name.contains("rice") || name.contains("pasta") ||
           name.contains("quinoa") || name.contains("oat") || name.contains("wheat") {
            return .grains
        }

        return .other
    }

    // MARK: - Quick Recommendations

    /// Get top 3 quick recommendations for display
    func getTopRecommendations() -> [FoodRecommendation] {
        Array(recommendations.prefix(3))
    }

    /// Get recommendations by category
    func getRecommendations(by category: FoodCategory) -> [FoodRecommendation] {
        recommendations.filter { $0.category == category }
    }

    /// Get recommendations by priority
    func getRecommendations(by priority: RecommendationPriority) -> [FoodRecommendation] {
        recommendations.filter { $0.priority == priority }
    }
}
