//
//  DailyNutrientInsight.swift
//  NutraSafe Beta
//
//  Created for enhanced nutrition intelligence features
//

import Foundation
import SwiftUI

// MARK: - Source Level (used by nutrient tracking system)
enum SourceLevel: String, Comparable {
    case none = "None"
    case trace = "Low"
    case moderate = "Moderate"
    case strong = "Strong"

    static func < (lhs: SourceLevel, rhs: SourceLevel) -> Bool {
        rank(lhs) < rank(rhs)
    }

    private static func rank(_ level: SourceLevel) -> Int {
        switch level {
        case .none: return 0
        case .trace: return 1
        case .moderate: return 2
        case .strong: return 3
        }
    }

    var color: Color {
        switch self {
        case .strong: return Color(hex: "#3FD17C")
        case .moderate: return Color(hex: "#FFA93A")
        case .trace: return Color(hex: "#57A5FF")
        case .none: return Color(hex: "#CFCFCF")
        }
    }
}

// MARK: - Insight Level
enum InsightLevel: String, Codable {
    case critical  // < 30% DV
    case low       // 30-70% DV
    case good      // > 70% DV
    case excellent // > 100% DV

    var displayText: String {
        switch self {
        case .critical: return "Critical"
        case .low: return "Low"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }

    var color: String {
        switch self {
        case .critical: return "red"
        case .low: return "orange"
        case .good: return "green"
        case .excellent: return "blue"
        }
    }
}

// MARK: - Food Suggestion
struct FoodSuggestion: Identifiable, Codable {
    let id: String
    let name: String
    let nutrientAmount: Double
    let unit: String
    let servingSize: String

    init(id: String = UUID().uuidString, name: String, nutrientAmount: Double, unit: String, servingSize: String = "100g") {
        self.id = id
        self.name = name
        self.nutrientAmount = nutrientAmount
        self.unit = unit
        self.servingSize = servingSize
    }

    var displayText: String {
        return "\(name) (\(String(format: "%.1f", nutrientAmount))\(unit) per \(servingSize))"
    }
}

// MARK: - Daily Nutrient Insight
struct DailyNutrientInsight: Identifiable, Codable {
    let id: String
    let nutrient: String
    let consumed: Double
    let target: Double
    let unit: String
    let severity: InsightLevel
    let suggestedFoods: [FoodSuggestion]
    let isPriorityNutrient: Bool // User-selected focus nutrient

    init(id: String = UUID().uuidString,
         nutrient: String,
         consumed: Double,
         target: Double,
         unit: String,
         severity: InsightLevel,
         suggestedFoods: [FoodSuggestion] = [],
         isPriorityNutrient: Bool = false) {
        self.id = id
        self.nutrient = nutrient
        self.consumed = consumed
        self.target = target
        self.unit = unit
        self.severity = severity
        self.suggestedFoods = suggestedFoods
        self.isPriorityNutrient = isPriorityNutrient
    }

    var percentageOfTarget: Double {
        guard target > 0 else { return 0 }
        return (consumed / target) * 100
    }

    var displayPercentage: String {
        return String(format: "%.0f%%", percentageOfTarget)
    }

    var shortDescription: String {
        let percentage = percentageOfTarget
        if percentage < 30 {
            return "Very low"
        } else if percentage < 70 {
            return "Below target"
        } else if percentage < 100 {
            return "Nearly there"
        } else {
            return "Target met"
        }
    }

    var remaining: Double {
        return max(0, target - consumed)
    }
}

// MARK: - User Nutrient Preferences
struct UserNutrientPreferences: Codable {
    var focusNutrients: [String] // User-selected priority nutrients
    var lastUpdated: Date

    init(focusNutrients: [String] = [], lastUpdated: Date = Date()) {
        self.focusNutrients = focusNutrients
        self.lastUpdated = lastUpdated
    }

    static var `default`: UserNutrientPreferences {
        return UserNutrientPreferences(focusNutrients: [])
    }
}

// MARK: - Contributing Food
struct ContributingFood: Identifiable {
    let id: String
    let name: String
    let amount: Double
    let unit: String
    let mealType: String?

    init(id: String = UUID().uuidString, name: String, amount: Double, unit: String, mealType: String? = nil) {
        self.id = id
        self.name = name
        self.amount = amount
        self.unit = unit
        self.mealType = mealType
    }

    var displayText: String {
        return "\(name) (\(String(format: "%.1f", amount))\(unit))"
    }
}

// MARK: - Daily Nutrient Summary
struct DailyNutrientSummary {
    let date: Date
    let insights: [DailyNutrientInsight]
    let contributingFoods: [String: [ContributingFood]] // Nutrient name -> foods

    var criticalInsights: [DailyNutrientInsight] {
        return insights.filter { $0.severity == .critical }
    }

    var lowInsights: [DailyNutrientInsight] {
        return insights.filter { $0.severity == .low }
    }

    var topInsightsForNudge: [DailyNutrientInsight] {
        // Priority nutrients first, then by severity
        let sorted = insights.sorted { (a, b) in
            if a.isPriorityNutrient != b.isPriorityNutrient {
                return a.isPriorityNutrient
            }
            return a.percentageOfTarget < b.percentageOfTarget
        }

        // Return top 3 that need attention (< 70% DV and > 1% to exclude no-data cases)
        return Array(sorted.filter { $0.percentageOfTarget >= 1 && $0.percentageOfTarget < 70 }.prefix(3))
    }

    var hasGaps: Bool {
        return !criticalInsights.isEmpty || !lowInsights.isEmpty
    }
}
