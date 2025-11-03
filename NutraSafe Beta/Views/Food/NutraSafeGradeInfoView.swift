//
//  NutraSafeGradeInfoView.swift
//  NutraSafe Beta
//
//  Consumer-friendly explanation sheet for NutraSafe Processing Grade
//

import SwiftUI

struct NutraSafeGradeInfoView: View {
    let result: ProcessingScorer.NutraSafeProcessingGradeResult
    let food: FoodSearchResult
    @Environment(\.dismiss) private var dismiss

    private func color(for grade: String) -> Color {
        switch grade.uppercased() {
        case "A", "A+": return .green
        case "B": return .mint
        case "C": return .orange
        case "D", "E", "F": return .red
        default: return .gray
        }
    }

    private var tips: [String] {
        var out: [String] = []
        if food.protein < 7 { out.append("Boost protein: add eggs, yogurt, lean meat, or legumes.") }
        if food.fiber < 3 { out.append("Add fiber: include whole grains, fruit, veg, or nuts.") }
        if food.sugar > 10 { out.append("Choose lower-sugar options or reduce sweet add-ons.") }
        if (food.ingredients?.count ?? 0) > 15 { out.append("Simplify: shorter ingredient lists often mean gentler processing.") }
        if (food.additives?.count ?? 0) > 0 { out.append("Prefer versions with fewer additives when possible.") }
        return out.isEmpty ? ["Enjoy in balanced portions and pair with whole foods."] : out
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header card
                    HStack(alignment: .center, spacing: 12) {
                        Text(result.grade)
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundColor(color(for: result.grade))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.label)
                                .font(.headline)
                            Text("NutraSafe Processing Grade")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(color(for: result.grade).opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(color(for: result.grade).opacity(0.2), lineWidth: 1)
                            )
                    )

                    // Meaning
                    Group {
                        Text("What this means")
                            .font(.headline)
                        Text(result.label)
                            .font(.callout)
                            .foregroundColor(.primary)
                    }

                    // How we calculate
                    Group {
                        Text("How we calculate it")
                            .font(.headline)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Processing intensity: additives, industrial processes, and ingredient complexity.")
                            Text("• Nutrient integrity: balance of protein, fiber, sugar, and micronutrients.")
                            Text("• We combine these into a simple A–F grade for clarity.")
                        }
                        .font(.callout)
                        .foregroundColor(.secondary)
                    }

                    // Tips
                    Group {
                        Text("Tips to improve similar foods")
                            .font(.headline)
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(tips, id: \.self) { tip in
                                Text("• \(tip)")
                            }
                        }
                        .font(.callout)
                        .foregroundColor(.secondary)
                    }

                    // Detailed explanation
                    Group {
                        Text("Details")
                            .font(.headline)
                        Text(result.explanation)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }

                    // Citations section
                    Group {
                        Text("Research Sources")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(CitationManager.shared.citations(for: .foodProcessing)) { citation in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(citation.organization)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.blue)

                                    Text(citation.title)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.primary)

                                    Text(citation.description)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)

                                    Button(action: {
                                        if let url = URL(string: citation.url) {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "link")
                                                .font(.system(size: 11, weight: .medium))
                                            Text("View Source")
                                                .font(.system(size: 12, weight: .medium))
                                            Spacer()
                                            Image(systemName: "arrow.up.right")
                                                .font(.system(size: 10))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.blue)
                                        )
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(.systemGray6))
                                )
                            }
                        }

                        Text("Our grading system is based on internationally recognized food processing classification standards.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}