//
//  MicronutrientScoringModels.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-10-21.
//  Data models for micronutrient scoring and tracking
//

import Foundation
import SwiftUI

// MARK: - Daily Nutrient Score

/// Represents a nutrient's score for a single day
struct DailyNutrientScore: Codable, Identifiable {
    let id: String // "{nutrient}_{date}"
    let nutrient: String
    let date: Date
    let totalPoints: Int
    let sources: [String] // Food names that contributed

    var percentage: Int {
        calculatePercentage(from: totalPoints)
    }

    var status: MicronutrientStatus {
        MicronutrientStatus.from(percentage: percentage)
    }

    /// Convert total points to percentage (0-100%)
    /// 0-2 points = 0-30% (Low)
    /// 3-6 points = 31-70% (Adequate)
    /// 7+ points = 71-100% (Strong)
    private func calculatePercentage(from points: Int) -> Int {
        switch points {
        case 0...2:
            // 0-2 points → 0-30%
            return min(30, points * 15)
        case 3...6:
            // 3-6 points → 31-70%
            return 31 + ((points - 3) * 10)
        default:
            // 7+ points → 71-100%
            let excess = points - 7
            return min(100, 71 + (excess * 5))
        }
    }
}

// MARK: - Nutrient Status

enum MicronutrientStatus {
    case low      // 0-30%
    case adequate // 31-70%
    case strong   // 71-100%

    static func from(percentage: Int) -> MicronutrientStatus {
        switch percentage {
        case 0...30:
            return .low
        case 31...70:
            return .adequate
        default:
            return .strong
        }
    }

    var label: String {
        switch self {
        case .low: return "Trace"
        case .adequate: return "Moderate"
        case .strong: return "Strong"
        }
    }

    var color: Color {
        switch self {
        case .low: return .red
        case .adequate: return .yellow
        case .strong: return .green
        }
    }

    var emoji: String {
        switch self {
        case .low: return "🟠"  // Orange for Trace
        case .adequate: return "🟡"  // Yellow for Moderate
        case .strong: return "🟢"  // Green for Strong
        }
    }
}

// MARK: - Nutrient Trend

enum NutrientTrend {
    case improving  // ≥+10%
    case declining  // ≤-10%
    case stable     // -9% to +9%

    static func from(change: Double) -> NutrientTrend {
        if change >= 10.0 {
            return .improving
        } else if change <= -10.0 {
            return .declining
        } else {
            return .stable
        }
    }

    var symbol: String {
        switch self {
        case .improving: return "↑"
        case .declining: return "↓"
        case .stable: return "→"
        }
    }

    var label: String {
        switch self {
        case .improving: return "Improving"
        case .declining: return "Declining"
        case .stable: return "Stable"
        }
    }

    var color: Color {
        switch self {
        case .improving: return .green
        case .declining: return .red
        case .stable: return .secondary
        }
    }
}

// MARK: - Nutrient Summary

/// Complete summary of a nutrient's tracking over time
struct MicronutrientSummary: Identifiable {
    let id: String // nutrient identifier
    let nutrient: String
    let name: String

    // Current day
    let todayPercentage: Int
    let todayStatus: MicronutrientStatus

    // 7-day rolling average
    let sevenDayAverage: Double
    let sevenDayStatus: MicronutrientStatus

    // Trend
    let trend: NutrientTrend
    let trendPercentageChange: Double

    // Sources
    let recentSources: [String] // Top food sources from last 7 days

    // Metadata
    let info: NutrientInfo? // Educational info from database

    var statusEmoji: String {
        todayStatus.emoji
    }

    var trendText: String {
        let sign = trendPercentageChange >= 0 ? "+" : ""
        return "\(trend.symbol) \(trend.label) (\(sign)\(Int(trendPercentageChange))%)"
    }
}

// MARK: - Overall Nutrient Balance

/// Overall balance score across all nutrients
struct NutrientBalanceScore {
    let date: Date
    let totalNutrientsTracked: Int
    let strongCount: Int      // ≥71%
    let adequateCount: Int    // 31-70%
    let lowCount: Int         // 0-30%
    let averageCoverage: Int  // Average percentage across all nutrients

    var balancePercentage: Int {
        // Use average coverage as the primary metric (more intuitive)
        return averageCoverage
    }

    var balanceStatus: MicronutrientStatus {
        MicronutrientStatus.from(percentage: balancePercentage)
    }

    var summary: String {
        "\(strongCount) strong • \(adequateCount) adequate • \(lowCount) low"
    }
}

// MARK: - Food Micronutrient Analysis

/// Result of analyzing a food item for micronutrients
struct FoodMicronutrientAnalysis {
    let foodName: String
    let nutrients: [String: NutrientStrength.Strength]
    let totalPoints: Int

    init(foodName: String, nutrients: [String: NutrientStrength.Strength]) {
        self.foodName = foodName
        self.nutrients = nutrients
        self.totalPoints = nutrients.values.reduce(0) { $0 + $1.points }
    }

    /// Get nutrients grouped by strength
    var strongNutrients: [String] {
        nutrients.filter { $0.value == .strong }.map { $0.key }.sorted()
    }

    var moderateNutrients: [String] {
        nutrients.filter { $0.value == .moderate }.map { $0.key }.sorted()
    }

    var traceNutrients: [String] {
        nutrients.filter { $0.value == .trace }.map { $0.key }.sorted()
    }
}

// MARK: - Insight Generation

/// Generates human-readable insights from nutrient data
struct NutrientInsightGenerator {

    /// Generate insights for a collection of nutrient summaries
    static func generateInsights(for summaries: [MicronutrientSummary]) -> [String] {
        var insights: [String] = []

        // Top 3 strengths (≥70%)
        let strengths = summaries
            .filter { $0.todayPercentage >= 70 }
            .sorted { $0.todayPercentage > $1.todayPercentage }
            .prefix(3)

        if !strengths.isEmpty {
            for summary in strengths {
                let sources = summary.recentSources.prefix(2).joined(separator: ", ")
                insights.append("🟢 \(summary.name) strong from \(sources)")
            }
        }

        // Bottom 3 trace nutrients (≤30%, but exclude 0% as they have no data)
        let trace = summaries
            .filter { $0.todayPercentage > 0 && $0.todayPercentage <= 30 }
            .sorted { $0.todayPercentage < $1.todayPercentage }
            .prefix(3)

        if !trace.isEmpty {
            for summary in trace {
                // Parse array format from database
                let suggestions = parseArrayString(summary.info?.commonSources)
                    .prefix(2)
                    .joined(separator: " or ")

                let finalSuggestion = suggestions.isEmpty ? "nutrient-rich foods" : suggestions
                insights.append("🟠 \(summary.name) trace — Add \(finalSuggestion)")
            }
        }

        // Notable trends
        let trends = summaries
            .filter { $0.trend != .stable }
            .sorted { abs($0.trendPercentageChange) > abs($1.trendPercentageChange) }
            .prefix(2)

        for summary in trends {
            let sign = summary.trendPercentageChange >= 0 ? "+" : ""
            insights.append("\(summary.trend.symbol) \(summary.name) \(summary.trend.label.lowercased()) (\(sign)\(Int(summary.trendPercentageChange))%)")
        }

        return insights
    }

    /// Generate a single-line summary for a nutrient
    static func generateSummary(for summary: MicronutrientSummary) -> String {
        let statusText = "\(summary.statusEmoji) \(summary.todayPercentage)%"
        let trendText = summary.trend != .stable ? " \(summary.trend.symbol)" : ""
        return "\(statusText)\(trendText)"
    }

    /// Parse JSON array string format like ["Item1", "Item2"] into clean string array
    private static func parseArrayString(_ content: String?) -> [String] {
        guard let content = content else { return [] }

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
}
