//
//  SmartRecommendationsView.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-10-21.
//  Smart food recommendations based on nutrient analysis
//

import SwiftUI

@available(iOS 16.0, *)
struct SmartRecommendationsView: View {
    @StateObject private var trackingManager = MicronutrientTrackingManager.shared
    @StateObject private var recommendationEngine = NutrientRecommendationEngine.shared
    @Environment(\.dismiss) var dismiss

    @State private var selectedCategory: FoodCategory? = nil
    @State private var selectedPriority: RecommendationPriority? = nil
    @State private var isRefreshing = false
    @State private var showingSources = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Disclaimer banner
                    disclaimerBanner

                    // Header
                    headerSection

                    // Priority Filter
                    priorityFilterSection

                    // Category Filter
                    categoryFilterSection

                    // Recommendations List
                    recommendationsListSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Smart Recommendations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showingSources) {
                SourcesAndCitationsView()
            }
            .refreshable {
                await refreshRecommendations()
            }
            .task {
                await refreshRecommendations()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Personalised Suggestions")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Based on your current nutrient levels")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange.opacity(0.1))
            )
        }
    }

    // MARK: - Priority Filter

    private var priorityFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filter by Priority")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // All button
                    RecommendationFilterChip(
                        label: "All",
                        count: recommendationEngine.recommendations.count,
                        isSelected: selectedPriority == nil,
                        color: .blue
                    ) {
                        selectedPriority = nil
                    }

                    // Priority filters
                    ForEach([RecommendationPriority.high, .medium, .suggested], id: \.self) { priority in
                        let count = recommendationEngine.getRecommendations(by: priority).count

                        if count > 0 {
                            RecommendationFilterChip(
                                label: priority.label,
                                count: count,
                                isSelected: selectedPriority == priority,
                                color: priority.color
                            ) {
                                selectedPriority = priority
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Category Filter

    private var categoryFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filter by Category")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // All button
                    CategoryChip(
                        category: nil,
                        label: "All",
                        count: recommendationEngine.recommendations.count,
                        isSelected: selectedCategory == nil
                    ) {
                        selectedCategory = nil
                    }

                    // Category filters
                    ForEach(FoodCategory.allCases, id: \.self) { category in
                        let count = recommendationEngine.getRecommendations(by: category).count

                        if count > 0 {
                            CategoryChip(
                                category: category,
                                label: category.rawValue,
                                count: count,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Recommendations List

    private var recommendationsListSection: some View {
        let filteredRecs = getFilteredRecommendations()

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(filteredRecs.count) Recommendations")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()
            }

            if filteredRecs.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredRecs) { recommendation in
                        RecommendationCard(recommendation: recommendation)
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text("Great Job!")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)

            Text("Your nutrient levels are well balanced.\nKeep up the good work!")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.adaptiveCard)
        )
    }

    // MARK: - Helper Functions

    private func getFilteredRecommendations() -> [FoodRecommendation] {
        var recs = recommendationEngine.recommendations

        if let priority = selectedPriority {
            recs = recs.filter { $0.priority == priority }
        }

        if let category = selectedCategory {
            recs = recs.filter { $0.category == category }
        }

        return recs
    }

    private func refreshRecommendations() async {
        isRefreshing = true
        defer { isRefreshing = false }

        let summaries = await trackingManager.getAllNutrientSummaries()
        await recommendationEngine.generateRecommendations(for: summaries)
    }

    // MARK: - Disclaimer Banner

    private var disclaimerBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("Food Suggestions Only")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                Text("These are informational suggestions based on nutrient data, not medical advice.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button(action: {
                showingSources = true
            }) {
                Image(systemName: "doc.text")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Filter Chip

struct RecommendationFilterChip: View {
    let label: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))

                Text("\(count)")
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color.white.opacity(0.3) : Color(.systemGray5))
                    )
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? color : Color(.systemGray6))
            )
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let category: FoodCategory?
    let label: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let category = category {
                    Text(category.icon)
                        .font(.system(size: 14))
                }

                Text(label)
                    .font(.system(size: 14, weight: .semibold))

                Text("\(count)")
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color.white.opacity(0.3) : Color(.systemGray5))
                    )
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
        }
    }
}

// MARK: - Recommendation Card

struct RecommendationCard: View {
    let recommendation: FoodRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack {
                Text(recommendation.category.icon)
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.foodName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)

                    Text(recommendation.category.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Priority badge
                Text(recommendation.priority.label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(recommendation.priority.color)
                    )
            }

            Divider()

            // Target nutrients
            VStack(alignment: .leading, spacing: 6) {
                Text("Rich in:")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)

                if #available(iOS 16.0, *) {
                    FlowLayout(spacing: 6) {
                        ForEach(recommendation.targetNutrients, id: \.self) { nutrient in
                            Text(nutrient)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.blue)
                                )
                        }
                    }
                }
            }

            // Expected impact
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 12))
                    .foregroundColor(.green)

                Text(recommendation.expectedImpact)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Reason
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)

                Text(recommendation.reason)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.adaptiveCard)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Flow Layout

@available(iOS 16.0, *)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        SmartRecommendationsView()
    }
}
