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

    /// Convert total points to percentage (0-100%) of daily nutrient target
    ///
    /// DAILY TRACKING ALGORITHM:
    /// Points accumulate from eating foods throughout the day:
    /// - Trace nutrient strength = 1 point
    /// - Moderate nutrient strength = 2 points
    /// - Strong nutrient strength = 3 points
    ///
    /// Point-to-percentage conversion:
    /// - 0-2 points → 0-30% (Low status)
    /// - 3-6 points → 31-70% (Adequate status)
    /// - 7+ points → 71-100% (Strong status)
    ///
    /// RATIONALE FOR NON-LINEAR SCALING:
    /// This algorithm is intentionally conservative to encourage dietary variety.
    /// A single "strong source" food (3 points = 31% DV) shows as "Low" status,
    /// prompting users to consume multiple nutrient-rich foods throughout the day.
    ///
    /// This approach aligns with public health guidance for varied diets and prevents
    /// over-reliance on single fortified foods or supplements.
    ///
    /// SCIENTIFIC BASIS:
    /// The Recommended Dietary Allowance (RDA) is designed to meet the nutrient needs
    /// of 97-98% of healthy individuals (Institute of Medicine DRI framework). Daily
    /// tracking thresholds reflect this conservative approach to ensure true adequacy.
    ///
    /// References:
    /// - Institute of Medicine Dietary Reference Intakes (DRI)
    ///   https://www.ncbi.nlm.nih.gov/books/NBK222871/
    /// - RDA methodology: Set at EAR (Estimated Average Requirement) + 2 standard deviations
    ///
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

/// User-facing nutrient status categories for daily tracking
///
/// DAILY TRACKING THRESHOLDS:
/// These thresholds are designed to provide actionable feedback across a full day of eating:
/// - Strong (80-100%): Meeting daily needs from tracked foods
/// - Adequate (40-79%): Approaching daily target, moderate intake
/// - Low (10-39%): Insufficient intake, needs attention
/// - None (0-9%): Minimal or no tracked intake
///
/// IMPORTANT: These thresholds DIFFER from food labeling regulations:
///
/// COMPARISON WITH FOOD LABELING STANDARDS:
/// • FDA (US): "Excellent source" = 20% DV per serving
/// • UK/EU: "High in" = 30% NRV per 100g
/// • NutraSafe daily tracking: "Strong" = 80% DV across all meals
///
/// WHY THE DIFFERENCE?
/// Food labeling describes INDIVIDUAL FOODS (per serving or per 100g).
/// Daily tracking aggregates MULTIPLE FOODS consumed throughout the day.
///
/// A single "excellent source" food (20% DV per FDA) provides only 20% of daily needs.
/// In NutraSafe daily tracking, this 20% would show as "Low" status (10-39% range),
/// which is correct - the user hasn't yet achieved adequate daily intake from one food.
///
/// RATIONALE:
/// This conservative approach:
/// 1. Encourages consumption of multiple nutrient-rich foods throughout the day
/// 2. Prevents over-reliance on single fortified foods or supplements
/// 3. Promotes dietary variety (aligned with public health guidance)
/// 4. Ensures users achieve true nutrient adequacy across the full day
///
/// The 80% threshold for "Strong" status reflects the Institute of Medicine's DRI framework:
/// RDA (Recommended Dietary Allowance) is set to meet the needs of 97-98% of the population.
/// Reaching 80-100% of RDA indicates genuine nutritional adequacy for most individuals.
///
/// References:
/// - Institute of Medicine DRI framework: RDA meets needs of 97-98% of population
///   https://www.ncbi.nlm.nih.gov/books/NBK222871/
/// - FDA food labeling (comparison): 21 CFR 101.54
///   https://www.ecfr.gov/current/title-21/section-101.54
/// - UK/EU food labeling (comparison): EC Regulation 1924/2006
///   https://www.legislation.gov.uk/eur/2006/1924/annex
enum MicronutrientStatus {
    case none      // 0–9%
    case low       // 10–39% (Trace)
    case adequate  // 40–79% (Moderate)
    case strong    // 80–100%

    static func from(percentage: Int) -> MicronutrientStatus {
        switch percentage {
        case 80...100:
            return .strong
        case 40...79:
            return .adequate
        case 10...39:
            return .low
        default:
            return .none
        }
    }

    var label: String {
        switch self {
        case .none: return "None"
        case .low: return "Rare"
        case .adequate: return "Occasional"
        case .strong: return "Regular"
        }
    }

    var color: Color {
        switch self {
        case .none: return .gray
        case .low: return .orange
        case .adequate: return .yellow
        case .strong: return .green
        }
    }

    var emoji: String {
        switch self {
        case .none: return "⚪️"
        case .low: return "🟠"
        case .adequate: return "🟡"
        case .strong: return "🟢"
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
        "🟢 \(strongCount) Strong 🟡 \(adequateCount) Moderate 🟠 \(lowCount) Trace"
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
    /// Focuses on areas needing attention (low nutrients only)
    static func generateInsights(for summaries: [MicronutrientSummary]) -> [String] {
        var insights: [String] = []

        // Bottom 3 trace nutrients (≤30%, but exclude 0% as they have no data)
        // These are the ones that need attention
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
                let percentage = Int(summary.todayPercentage)
                insights.append("\(summary.name) — \(percentage)% of target. Try \(finalSuggestion)")
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
        let statusText = "\(summary.statusEmoji) \(summary.todayStatus.label)"
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
