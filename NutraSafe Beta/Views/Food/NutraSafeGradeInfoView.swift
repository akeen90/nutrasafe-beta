//
//  NutraSafeGradeInfoView.swift
//  NutraSafe Beta
//
//  Consumer-friendly explanation sheet for NutraSafe Unified Score
//  Redesigned to match onboarding's calm, observational aesthetic
//

import SwiftUI

struct NutraSafeGradeInfoView: View {
    let result: ProcessingScorer.NutraSafeUnifiedScoreResult
    let food: FoodSearchResult
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    private func color(for grade: String) -> Color {
        switch grade.uppercased() {
        case "A", "A+": return SemanticColors.positive
        case "B": return .mint
        case "C": return .orange
        case "D", "E", "F": return SemanticColors.caution
        default: return .gray
        }
    }

    private var tips: [String] {
        var out: [String] = []
        if food.protein < 7 { out.append("Pairing with eggs, yogurt, lean meat, or legumes can boost protein.") }
        if food.fiber < 3 { out.append("Adding whole grains, fruit, veg, or nuts brings more fibre.") }
        if result.hasSugarWarning { out.append("Lower-sugar versions or smaller portions may be worth exploring.") }
        if result.ingredientCount > 15 { out.append("Shorter ingredient lists often mean gentler processing.") }
        if result.additiveCount > 0 { out.append("Some versions have fewer additives worth considering.") }
        return out.isEmpty ? ["Enjoy in balanced portions alongside whole foods."] : out
    }

    // Component score color (1.0 = best/green, 5.0 = worst/red)
    private func componentColor(for value: Double) -> Color {
        switch value {
        case ...1.6: return SemanticColors.positive
        case 1.61...2.4: return .mint
        case 2.41...3.2: return .orange
        default: return SemanticColors.caution
        }
    }

    // Format component score for display
    private func formatScore(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header - Grade display with signal styling
                    VStack(spacing: 16) {
                        ZStack {
                            // Radial glow
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [color(for: result.grade).opacity(0.15), Color.clear],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 60
                                    )
                                )
                                .frame(width: 120, height: 120)

                            Circle()
                                .fill(color(for: result.grade).opacity(0.12))
                                .frame(width: 88, height: 88)

                            Text(result.grade)
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(color(for: result.grade))
                        }

                        VStack(spacing: 6) {
                            Text(result.label)
                                .font(.system(size: 22, weight: .medium, design: .serif))
                                .foregroundColor(.primary)

                            Text("NutraSafe Score")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(color(for: result.grade).opacity(0.2), lineWidth: 1)
                            )
                    )

                    // Sugar warning indicator
                    if result.hasSugarWarning {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)

                            Text("High sugar: \(Int(result.sugarPer100g))g per 100g")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)

                            Spacer()
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.orange.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }

                    // What this means - InfoCard style
                    GradeInfoCard(
                        icon: "info.circle.fill",
                        iconColor: palette.accent,
                        title: "What this means",
                        content: result.explanation
                    )

                    // Score breakdown - Three components
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Score breakdown")
                            .font(.system(size: 18, weight: .semibold, design: .serif))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 4)

                        // Processing component (50%)
                        ScoreComponentCard(
                            icon: "gearshape.2.fill",
                            color: componentColor(for: result.processingComponent),
                            title: "Processing",
                            weight: "50%",
                            score: formatScore(result.processingComponent),
                            factors: result.processingFactors,
                            palette: palette
                        )

                        // Additive risk component (35%)
                        ScoreComponentCard(
                            icon: "flask.fill",
                            color: componentColor(for: result.additiveRiskComponent),
                            title: "Additive safety",
                            weight: "35%",
                            score: formatScore(result.additiveRiskComponent),
                            factors: result.additiveFactors,
                            palette: palette
                        )

                        // Nutrient deficit component (15%)
                        ScoreComponentCard(
                            icon: "leaf.fill",
                            color: componentColor(for: result.nutrientDeficitComponent),
                            title: "Nutrient quality",
                            weight: "15%",
                            score: formatScore(result.nutrientDeficitComponent),
                            factors: result.nutrientFactors,
                            palette: palette
                        )
                    }

                    // Final score calculation
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Final calculation")
                            .font(.system(size: 18, weight: .semibold, design: .serif))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 4)

                        VStack(spacing: 8) {
                            HStack {
                                Text("Processing")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(formatScore(result.processingComponent)) × 0.50 = \(formatScore(result.processingComponent * 0.50))")
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundColor(.primary)
                            }

                            HStack {
                                Text("Additives")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(formatScore(result.additiveRiskComponent)) × 0.35 = \(formatScore(result.additiveRiskComponent * 0.35))")
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundColor(.primary)
                            }

                            HStack {
                                Text("Nutrients")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(formatScore(result.nutrientDeficitComponent)) × 0.15 = \(formatScore(result.nutrientDeficitComponent * 0.15))")
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundColor(.primary)
                            }

                            Divider()
                                .padding(.vertical, 4)

                            HStack {
                                Text("Final index")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(formatScore(result.finalIndex))
                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                                    .foregroundColor(color(for: result.grade))
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(palette.tertiary.opacity(0.08))
                        )
                    }

                    // Tips section
                    if !tips.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Things to consider")
                                .font(.system(size: 18, weight: .semibold, design: .serif))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 4)

                            VStack(spacing: 0) {
                                ForEach(tips, id: \.self) { tip in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "lightbulb.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.orange)
                                            .frame(width: 24)

                                        Text(tip)
                                            .font(.system(size: 15, weight: .regular))
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)

                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                }
                            }
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                    }

                    // Research sources
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Research sources")
                            .font(.system(size: 18, weight: .semibold, design: .serif))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 4)

                        ForEach(CitationManager.shared.citations(for: .foodProcessing)) { citation in
                            GradeCitationCard(citation: citation, palette: palette)
                        }

                        Text("Based on internationally recognised food processing and additive safety research.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(24)
            }
            .background(AppAnimatedBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Components

private struct GradeInfoCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }

            Text(content)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 3)
        )
    }
}

private struct ScoreComponentCard: View {
    let icon: String
    let color: Color
    let title: String
    let weight: String
    let score: String
    let factors: [String]
    let palette: AppPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon, title, weight and score
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(weight)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(score)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }

            // Factors list
            if !factors.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(factors, id: \.self) { factor in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(palette.tertiary.opacity(0.5))
                                .frame(width: 5, height: 5)
                                .padding(.top, 6)

                            Text(factor)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

private struct GradeCitationCard: View {
    let citation: CitationManager.Citation
    let palette: AppPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(citation.organization)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(palette.accent)

            Text(citation.title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)

            Text(citation.description)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.secondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: {
                if let url = URL(string: citation.url) {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .semibold))
                    Text("View source")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(palette.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(palette.accent.opacity(0.1))
                )
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}
