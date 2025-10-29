//
//  DailyNutrientNudgeCard.swift
//  NutraSafe Beta
//
//  Smart daily nutrient nudge card with expandable insights
//

import SwiftUI

struct DailyNutrientNudgeCard: View {
    @StateObject private var viewModel: NutrientInsightsViewModel
    @State private var isExpanded: Bool = false
    @State private var showingPreferences: Bool = false
    @EnvironmentObject var diaryDataManager: DiaryDataManager

    let date: Date
    let firebaseManager: FirebaseManager

    init(date: Date, firebaseManager: FirebaseManager) {
        self.date = date
        self.firebaseManager = firebaseManager
        _viewModel = StateObject(wrappedValue: NutrientInsightsViewModel(firebaseManager: firebaseManager))
    }

    var body: some View {
        VStack(spacing: 0) {
            if let summary = viewModel.dailySummary, !summary.insights.isEmpty {
                collapsedView(summary: summary)

                if isExpanded {
                    expandedView(summary: summary)
                        .transition(.opacity)
                }
            } else if viewModel.isLoading {
                loadingView
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.orange.opacity(0.15), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1.5)
        )
        .task(id: date) {
            await viewModel.calculateDailyInsights(for: date)
        }
        .onChange(of: diaryDataManager.dataReloadTrigger) { _ in
            Task {
                await viewModel.calculateDailyInsights(for: date)
            }
        }
        .sheet(isPresented: $showingPreferences) {
            NutrientFocusPreferencesView(viewModel: viewModel)
        }
    }

    // MARK: - Collapsed View
    private func collapsedView(summary: DailyNutrientSummary) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        }) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                    .frame(width: 32, height: 32)

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Nutrient Focus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)

                    if summary.topInsightsForNudge.isEmpty {
                        Text("All key nutrients looking good today!")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        let nutrients = summary.topInsightsForNudge.map { $0.nutrient }.joined(separator: ", ")
                        Text("Low in \(nutrients)")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Expand/collapse indicator
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Expanded View
    private func expandedView(summary: DailyNutrientSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()

            // Today's Gaps Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Today's Nutrient Gaps")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)

                    Spacer()

                    Button(action: {
                        showingPreferences = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                            Text("Focus")
                        }
                        .font(.caption.weight(.medium))
                        .foregroundColor(.orange)
                    }
                }

                if summary.topInsightsForNudge.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("No significant gaps today!")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(summary.topInsightsForNudge) { insight in
                        NutrientGapRow(insight: insight)
                    }
                }
            }

            Divider()

            // Smart Suggestions Section
            if !summary.topInsightsForNudge.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Foods to Boost These Nutrients")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)

                    ForEach(summary.topInsightsForNudge.prefix(2)) { insight in
                        if !insight.suggestedFoods.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(insight.nutrient)
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.orange)

                                FlowLayout(spacing: 8) {
                                    ForEach(insight.suggestedFoods.prefix(4)) { food in
                                        FoodSuggestionPill(food: food)
                                    }
                                }
                            }
                        }
                    }
                }

                Divider()
            }

            // Tip
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue.opacity(0.7))

                Text("These are suggestions based on today's intake. Consult a healthcare professional for personalised advice.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
    }

    // MARK: - Loading View
    private var loadingView: some View {
        HStack {
            ProgressView()
                .padding(.trailing, 8)

            Text("Analysing today's nutrition...")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8)
        )
    }
}

// MARK: - Nutrient Gap Row
struct NutrientGapRow: View {
    let insight: DailyNutrientInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                // Nutrient name with priority indicator
                HStack(spacing: 4) {
                    if insight.isPriorityNutrient {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    Text(insight.nutrient)
                        .font(.callout.weight(.medium))
                        .foregroundColor(.primary)
                }

                Spacer()

                // Status badge
                Text(insight.shortDescription)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(severityColor(insight.severity))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(severityColor(insight.severity).opacity(0.15))
                    )
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [severityColor(insight.severity).opacity(0.7), severityColor(insight.severity)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(insight.percentageOfTarget / 100, 1.0), height: 8)
                }
            }
            .frame(height: 8)

            // Level description
            Text(levelDescription(for: insight.severity) + " (\(insight.displayPercentage))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func severityColor(_ severity: InsightLevel) -> Color {
        switch severity {
        case .critical: return .red
        case .low: return .orange
        case .good: return .green
        case .excellent: return .blue
        }
    }

    private func levelDescription(for severity: InsightLevel) -> String {
        switch severity {
        case .critical: return "Could use a boost today"
        case .low: return "Room for improvement"
        case .good: return "On track"
        case .excellent: return "Going strong"
        }
    }
}

// MARK: - Food Suggestion Pill
struct FoodSuggestionPill: View {
    let food: FoodSuggestion

    var body: some View {
        Text(food.name)
            .font(.caption.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    colors: [Color.green.opacity(0.8), Color.green],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(8)
            .shadow(color: Color.green.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Nutrient Focus Preferences View
struct NutrientFocusPreferencesView: View {
    @ObservedObject var viewModel: NutrientInsightsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedNutrients: Set<String> = []

    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Select up to 5 nutrients to prioritise in your daily focus. These will always appear in your nudge card, helping you track specific dietary needs.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .listRowBackground(Color.clear)
                }

                Section(header: Text("Available Nutrients")) {
                    ForEach(viewModel.allNutrients, id: \.self) { nutrient in
                        Button(action: {
                            toggleSelection(nutrient)
                        }) {
                            HStack {
                                Text(nutrient)
                                    .foregroundColor(.primary)

                                Spacer()

                                if selectedNutrients.contains(nutrient) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.orange)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray.opacity(0.3))
                                }
                            }
                        }
                        .disabled(selectedNutrients.count >= 5 && !selectedNutrients.contains(nutrient))
                    }
                }

                if selectedNutrients.count >= 5 {
                    Section {
                        Text("Maximum of 5 nutrients selected")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .listRowBackground(Color.orange.opacity(0.1))
                    }
                }
            }
            .navigationTitle("Nutrient Focus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.updateFocusNutrients(Array(selectedNutrients))
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                selectedNutrients = Set(viewModel.userPreferences.focusNutrients)
            }
        }
    }

    private func toggleSelection(_ nutrient: String) {
        if selectedNutrients.contains(nutrient) {
            selectedNutrients.remove(nutrient)
        } else if selectedNutrients.count < 5 {
            selectedNutrients.insert(nutrient)
        }
    }
}

#Preview {
    DailyNutrientNudgeCard(date: Date(), firebaseManager: .shared)
}
