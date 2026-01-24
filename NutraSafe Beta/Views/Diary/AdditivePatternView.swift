//
//  AdditivePatternView.swift
//  NutraSafe Beta
//
//  Pattern-based additive insights with time-decay scoring
//  Design: Emotion-first, trust-building, celebrates progress
//

import SwiftUI

// MARK: - Pattern-Based Additive Insights Section

struct AdditivePatternSection: View {
    @ObservedObject var viewModel: AdditiveTrackerViewModel
    @State private var patternScore: AdditivePatternScore?
    @State private var expandedAdditiveId: String?
    @State private var expandedSections: [String: Set<String>] = [:]
    @State private var isExpanded = true
    @State private var showingSources = false
    @State private var showingHistoricalView = false
    @State private var isLoadingPattern = false
    @Environment(\.colorScheme) private var colorScheme

    // User intent from onboarding (determines color palette)
    @AppStorage("userIntent") private var userIntentRaw: String = "safer"
    private var userIntent: UserIntent {
        UserIntent(rawValue: userIntentRaw) ?? .safer
    }

    private var palette: OnboardingPalette {
        OnboardingPalette.forIntent(userIntent)
    }

    private var appPalette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - simple, clean
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    // Simple circle icon matching onboarding style
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [palette.primary.opacity(0.8), palette.accent.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "chart.dots.scatter")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        )

                    Text("Your Additive Pattern")
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .foregroundColor(appPalette.textPrimary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(palette.accent.opacity(0.6))
                        .symbolRenderingMode(.hierarchical)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                VStack(spacing: 20) {
                    if isLoadingPattern {
                        loadingView
                    } else if let score = patternScore {
                        // Main pattern score card
                        patternScoreCard(score)
                            .padding(.horizontal, 20)

                        // Comparison view (Now vs Then)
                        AdditiveComparisonView(
                            recentScore: score.recentScore,
                            earlierScore: score.earlierScore,
                            trend: score.trend
                        )
                        .padding(.horizontal, 20)

                        // Historical visualization button
                        historicalButton
                            .padding(.horizontal, 20)

                        // Additive lists (from current implementation)
                        additivesList
                            .padding(.horizontal, 20)

                        // Sources link
                        sourcesLink
                            .padding(.horizontal, 20)
                    } else {
                        emptyState
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .task {
            await loadPatternScore()
        }
        .fullScreenCover(isPresented: $showingSources) {
            SourcesAndCitationsView()
        }
        .sheet(isPresented: $showingHistoricalView) {
            historicalDetailView
        }
    }

    // MARK: - Pattern Score Card

    private func patternScoreCard(_ score: AdditivePatternScore) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Grade icon
                ZStack {
                    Circle()
                        .fill(score.grade.color.opacity(0.15))
                        .frame(width: 64, height: 64)

                    Image(systemName: score.grade.icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(score.grade.color)
                }

                VStack(alignment: .leading, spacing: 6) {
                    // Main message
                    Text(score.message)
                        .font(.system(size: 17, weight: .semibold, design: .serif))
                        .foregroundColor(appPalette.textPrimary)

                    // Clean streak highlight
                    if score.cleanStreakDays > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)

                            Text("\(score.cleanStreakDays) day\(score.cleanStreakDays == 1 ? "" : "s") clean")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(appPalette.textSecondary)
                        }
                    }

                    // Frequency badge
                    HStack(spacing: 4) {
                        Text(score.frequency.rawValue)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(score.frequency.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(score.frequency.color.opacity(0.12))
                            )
                    }
                }

                Spacer()
            }

            // Last concerning additive (if any)
            if let lastAdditive = score.lastConcerningAdditive,
               let lastDate = score.lastConcerningDate {
                lastConcerningCard(additive: lastAdditive, date: lastDate)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            score.grade.color.opacity(colorScheme == .dark ? 0.12 : 0.06),
                            score.grade.color.opacity(colorScheme == .dark ? 0.06 : 0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(score.grade.color.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private func lastConcerningCard(additive: AdditiveAggregate, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last concerning additive:")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(appPalette.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(additive.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(appPalette.textPrimary)

                        if !additive.code.isEmpty {
                            Text(additive.code)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(appPalette.textSecondary)
                        }
                    }

                    Text(timeAgo(from: date))
                        .font(.system(size: 12))
                        .foregroundColor(appPalette.textTertiary)
                }

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(appPalette.tertiary.opacity(colorScheme == .dark ? 0.15 : 0.08))
            )
        }
    }

    // MARK: - Historical Button

    private var historicalButton: some View {
        Button {
            showingHistoricalView = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16, weight: .medium))

                Text("View 30-day history")
                    .font(.system(size: 15, weight: .medium))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(appPalette.textTertiary)
            }
            .foregroundColor(palette.accent)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(palette.accent.opacity(colorScheme == .dark ? 0.12 : 0.08))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Additives List (reuse from original)

    private var additivesList: some View {
        VStack(spacing: 14) {
            if !viewModel.additiveAggregates.isEmpty {
                let avoid = viewModel.additiveAggregates.filter { $0.effectsVerdict.lowercased() == "avoid" }
                let caution = viewModel.additiveAggregates.filter { $0.effectsVerdict.lowercased() == "caution" }
                let neutral = viewModel.additiveAggregates.filter {
                    $0.effectsVerdict.lowercased() == "neutral" || $0.effectsVerdict.isEmpty
                }

                if !avoid.isEmpty {
                    additiveGroup(title: "Worth noting", additives: avoid, color: .red)
                }

                if !caution.isEmpty {
                    additiveGroup(title: "In moderation", additives: caution, color: SemanticColors.neutral)
                }

                if !neutral.isEmpty {
                    additiveGroup(title: "Generally safe", additives: neutral, color: palette.accent)
                }
            }
        }
    }

    private func additiveGroup(title: String, additives: [AdditiveAggregate], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Simple header
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)

                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundColor(appPalette.textPrimary)

                Spacer()

                Text("\(additives.count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(color.opacity(0.12))
                    )
            }

            // Additive rows
            VStack(spacing: 0) {
                ForEach(additives) { additive in
                    additiveRow(additive, color: color)

                    if additive.id != additives.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(appPalette.tertiary.opacity(colorScheme == .dark ? 0.08 : 0.04))
        )
    }

    private func additiveRow(_ additive: AdditiveAggregate, color: Color) -> some View {
        let isExpanded = expandedAdditiveId == additive.id

        return VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.none) {
                    expandedAdditiveId = expandedAdditiveId == additive.id ? nil : additive.id
                }
            }) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(additive.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(appPalette.textPrimary)

                            if !additive.code.isEmpty {
                                Text(additive.code)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(appPalette.textSecondary)
                            }
                        }

                        Text("×\(additive.occurrenceCount)")
                            .font(.system(size: 12))
                            .foregroundColor(appPalette.textTertiary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(appPalette.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            // Use the same expanded content from AdditiveTrackerView
            if isExpanded {
                Text("Tap to see full details")
                    .font(.system(size: 12))
                    .foregroundColor(appPalette.textSecondary)
                    .padding(12)
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(8)
            }
        }
    }

    // MARK: - Loading & Empty States

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: palette.accent))
            Text("Analyzing your patterns...")
                .font(.system(size: 14, design: .serif))
                .foregroundColor(appPalette.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [palette.tertiary.opacity(0.3), palette.tertiary.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "chart.dots.scatter")
                        .font(.system(size: 24))
                        .foregroundColor(palette.tertiary)
                )

            Text("No data yet")
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundColor(appPalette.textPrimary)

            Text("Log foods to see your additive patterns")
                .font(.system(size: 14))
                .foregroundColor(appPalette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Sources Link

    private var sourcesLink: some View {
        Button {
            showingSources = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "doc.text")
                    .font(.system(size: 11))
                Text("View sources")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(palette.accent.opacity(0.8))
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Historical Detail View

    private var historicalDetailView: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let score = patternScore {
                        AdditiveSparklineChart(dailyData: score.dailyBreakdown)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("30-Day History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingHistoricalView = false
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(palette.accent)
                }
            }
        }
    }

    // MARK: - Helpers

    private func loadPatternScore() async {
        isLoadingPattern = true
        patternScore = await viewModel.analyzeAdditivePattern()
        isLoadingPattern = false
    }

    private func timeAgo(from date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        if days < 7 { return "\(days) days ago" }
        if days < 14 { return "1 week ago" }
        if days < 30 { return "\(days / 7) weeks ago" }
        return "\(days) days ago"
    }
}

// MARK: - Preview

#if DEBUG
struct AdditivePatternSection_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            AdditivePatternSection(viewModel: AdditiveTrackerViewModel())
                .preferredColorScheme(.light)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}
#endif
