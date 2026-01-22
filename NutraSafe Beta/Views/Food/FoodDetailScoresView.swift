//
//  FoodDetailScoresView.swift
//  NutraSafe Beta
//
//  Extracted from FoodDetailViewFromSearch.swift to reduce type complexity
//  and prevent stack overflow in SwiftUI's type resolution.
//

import SwiftUI

// MARK: - Scores Section View

struct FoodDetailScoresView: View {
    // Score data
    let nutraSafeGrade: ProcessingScorer.NutraSafeProcessingGradeResult?
    let sugarScore: SugarContentScore
    let hasIngredients: Bool
    let isPerUnit: Bool
    let isFastFood: Bool
    let palette: AppPalette

    // Bindings for info sheets
    @Binding var showingNutraSafeInfo: Bool
    @Binding var showingSugarInfo: Bool

    var body: some View {
        let gradeToShow = (hasIngredients && !isPerUnit && !isFastFood) ? nutraSafeGrade : nil

        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Processing score card
                if let ns = gradeToShow {
                    Button(action: { showingNutraSafeInfo = true }) {
                        scoreCard(
                            title: "Processing",
                            grade: ns.grade,
                            label: ns.label,
                            color: scoreColor(for: ns.grade)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Sugar score card
                if sugarScore.grade != .unknown {
                    Button(action: { showingSugarInfo = true }) {
                        scoreCard(
                            title: "Sugar",
                            grade: sugarScore.grade.rawValue,
                            label: sugarLabel(for: sugarScore.grade),
                            color: sugarScore.color
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            // Info tip
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb")
                    .font(.system(size: 14))
                    .foregroundColor(palette.accent)
                Text("A = closest to natural, F = heavily processed. Tap cards to learn more.")
                    .font(.system(size: 13))
                    .foregroundColor(palette.textSecondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(palette.accent.opacity(0.05))
            )
        }
    }

    // MARK: - Score Card

    private func scoreCard(title: String, grade: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(palette.textTertiary)
                .tracking(0.5)

            Text(grade)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(palette.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(color.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .stroke(color.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Score Color

    private func scoreColor(for grade: String) -> Color {
        switch grade.uppercased() {
        case "A+", "A": return SemanticColors.positive
        case "B": return SemanticColors.nutrient
        case "C", "D": return SemanticColors.neutral
        case "F": return SemanticColors.caution
        default: return palette.textTertiary
        }
    }

    // MARK: - Sugar Label

    private func sugarLabel(for grade: SugarGrade) -> String {
        switch grade {
        case .excellent, .veryGood: return "Low Sugar"
        case .good: return "Moderate"
        case .moderate: return "High Sugar"
        case .high, .veryHigh: return "Very High"
        case .unknown: return "Unknown"
        }
    }
}
