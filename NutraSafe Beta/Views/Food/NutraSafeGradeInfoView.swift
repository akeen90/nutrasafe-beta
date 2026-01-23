//
//  NutraSafeGradeInfoView.swift
//  NutraSafe Beta
//
//  Consumer-friendly explanation sheet for NutraSafe Processing Grade
//  Redesigned to match onboarding's calm, observational aesthetic
//

import SwiftUI

struct NutraSafeGradeInfoView: View {
    let result: ProcessingScorer.NutraSafeProcessingGradeResult
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

    private var gradeDescription: String {
        switch result.grade.uppercased() {
        case "A", "A+": return "Closest to natural"
        case "B": return "Lightly processed"
        case "C": return "Moderately processed"
        case "D": return "Heavily processed"
        case "E", "F": return "Extensively processed"
        default: return result.label
        }
    }

    private var tips: [String] {
        var out: [String] = []
        if food.protein < 7 { out.append("Pairing with eggs, yogurt, lean meat, or legumes can boost protein.") }
        if food.fiber < 3 { out.append("Adding whole grains, fruit, veg, or nuts brings more fibre.") }
        if food.sugar > 10 { out.append("Lower-sugar versions or smaller portions may be worth exploring.") }
        if (food.ingredients?.count ?? 0) > 15 { out.append("Shorter ingredient lists often mean gentler processing.") }
        if (food.additives?.count ?? 0) > 0 { out.append("Some versions have fewer additives worth considering.") }
        return out.isEmpty ? ["Enjoy in balanced portions alongside whole foods."] : out
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
                            Text(gradeDescription)
                                .font(.system(size: 22, weight: .medium, design: .serif))
                                .foregroundColor(.primary)

                            Text("Processing Grade")
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

                    // What this means - InfoCard style
                    GradeInfoCard(
                        icon: "info.circle.fill",
                        iconColor: palette.accent,
                        title: "What this means",
                        content: result.label
                    )

                    // How we calculate - InfoBullet style
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How we work it out")
                            .font(.system(size: 18, weight: .semibold, design: .serif))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 4)

                        GradeInfoBullet(
                            icon: "flask.fill",
                            color: SemanticColors.additive,
                            title: "Processing intensity",
                            description: "Additives, industrial processes, and ingredient complexity"
                        )

                        GradeInfoBullet(
                            icon: "leaf.fill",
                            color: SemanticColors.nutrient,
                            title: "Nutrient integrity",
                            description: "Balance of protein, fibre, sugar, and micronutrients"
                        )

                        GradeInfoBullet(
                            icon: "chart.bar.fill",
                            color: palette.accent,
                            title: "Combined score",
                            description: "We bring these together into a simple A–F grade"
                        )
                    }

                    // Tips section
                    if !tips.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Things to consider")
                                .font(.system(size: 18, weight: .semibold, design: .serif))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 4)

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
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                    }

                    // Detailed explanation
                    VStack(alignment: .leading, spacing: 12) {
                        Text("The details")
                            .font(.system(size: 18, weight: .semibold, design: .serif))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 4)

                        Text(result.explanation)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(palette.tertiary.opacity(0.08))
                            )
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

                        Text("Based on internationally recognised food processing classification standards.")
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

private struct GradeInfoBullet: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
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

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
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
