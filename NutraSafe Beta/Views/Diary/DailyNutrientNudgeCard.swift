//
//  DailyNutrientNudgeCard.swift
//  NutraSafe Beta
//
//  Modern daily nutrient nudge card with smart insights
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
            if viewModel.userPreferences.focusNutrients.isEmpty {
                emptyStateView
            } else if let summary = viewModel.dailySummary, !summary.insights.isEmpty {
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
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.orange.opacity(0.08), radius: 6, x: 0, y: 2)
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
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        }) {
            HStack(spacing: 14) {
                // Icon with gradient
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.orange, Color.orange.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Nutrient Focus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)

                    if summary.topInsightsForNudge.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                            Text("All tracked nutrients looking good")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        let nutrients = summary.topInsightsForNudge.map { $0.nutrient }.joined(separator: ", ")
                        Text("Low in \(nutrients)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.orange)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(16)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Expanded View
    private func expandedView(summary: DailyNutrientSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Divider()
                .padding(.horizontal, 16)

            // Gaps Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Today's Status")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    Button(action: {
                        showingPreferences = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 12))
                            Text("Focus")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.1))
                        )
                    }
                }
                .padding(.horizontal, 16)

                if summary.topInsightsForNudge.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                        Text("Great job! All tracked nutrients are on target.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                } else {
                    VStack(spacing: 8) {
                        ForEach(summary.topInsightsForNudge) { insight in
                            CompactNutrientGapRow(insight: insight)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }

            // Suggestions Section
            if !summary.topInsightsForNudge.isEmpty {
                Divider()
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Boost With")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)

                    ForEach(summary.topInsightsForNudge.prefix(2)) { insight in
                        if !insight.suggestedFoods.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(insight.nutrient)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 16)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(insight.suggestedFoods.prefix(5)) { food in
                                            ModernFoodSuggestionPill(food: food)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                    }
                }
            }

            // Info footer
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.blue.opacity(0.6))

                Text("Suggestions based on today's intake")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.9)

            Text("Analysing nutrients...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(16)
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        Button(action: {
            showingPreferences = true
        }) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.orange)
                }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text("Track Your Nutrients")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Get daily insights on your intake")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Arrow
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
            }
            .padding(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Compact Nutrient Gap Row
struct CompactNutrientGapRow: View {
    let insight: DailyNutrientInsight

    var body: some View {
        HStack(spacing: 10) {
            // Priority star
            if insight.isPriorityNutrient {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
            }

            // Nutrient name
            Text(insight.nutrient)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray6))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [severityColor(insight.severity).opacity(0.8), severityColor(insight.severity)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(insight.percentageOfTarget / 100, 1.0), height: 6)
                }
            }
            .frame(height: 6)

            // Percentage
            Text(insight.displayPercentage)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(severityColor(insight.severity))
                .frame(width: 45, alignment: .trailing)
        }
        .padding(.vertical, 6)
    }

    private func severityColor(_ severity: InsightLevel) -> Color {
        switch severity {
        case .critical: return .red
        case .low: return .orange
        case .good: return .green
        case .excellent: return .blue
        }
    }
}

// MARK: - Modern Food Suggestion Pill
struct ModernFoodSuggestionPill: View {
    let food: FoodSuggestion

    var body: some View {
        Text(food.name)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.9), Color.green],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: Color.green.opacity(0.2), radius: 3, x: 0, y: 1)
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
                    Text("Select up to 5 nutrients to track daily. These will appear in your Nutrient Focus card.")
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
