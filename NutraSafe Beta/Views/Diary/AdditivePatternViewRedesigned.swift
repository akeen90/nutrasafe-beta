//
//  AdditivePatternViewRedesigned.swift
//  NutraSafe Beta
//
//  User-first additive insights: Show what they ate, explain why it matters
//  Design: Clear, informative, actionable
//

import SwiftUI

// MARK: - Redesigned Pattern-Based Additive Insights

struct AdditivePatternSectionRedesigned: View {
    @ObservedObject var viewModel: AdditiveTrackerViewModel
    @State private var patternScore: AdditivePatternScore?
    @State private var expandedAdditiveId: String?
    @State private var expandedSections: [String: Set<String>] = [:]
    @State private var showingSources = false
    @State private var isLoadingPattern = false
    @State private var watchedAdditives: Set<String> = [] // E-numbers user wants to track
    @Environment(\.colorScheme) private var colorScheme

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
            // Header
            HStack(spacing: 12) {
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

                Text("Additives This Week")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(appPalette.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            VStack(spacing: 20) {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.hasData {
                    // Summary card with real info (if pattern score loaded)
                    if let score = patternScore {
                        summaryCard(score)
                            .padding(.horizontal, 20)

                        // Full-width trend card (if changing)
                        if score.trend != .stable {
                            trendCard(score)
                                .padding(.horizontal, 20)
                        }
                    } else {
                        // Show simple summary while pattern loads
                        simpleSummary
                            .padding(.horizontal, 20)
                    }

                    // THE MAIN CONTENT: What they actually consumed
                    additivesListWithDetails
                        .padding(.horizontal, 20)

                    // Sources
                    sourcesLink
                        .padding(.horizontal, 20)
                } else {
                    emptyState
                        .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onAppear {
            loadWatchedAdditives()
            viewModel.loadData()
        }
        .task {
            await loadPatternScore()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WatchedAdditivesChanged"))) { _ in
            loadWatchedAdditives()
        }
        .fullScreenCover(isPresented: $showingSources) {
            SourcesAndCitationsView()
        }
    }

    // MARK: - Simple Summary (while pattern loads)

    private var simpleSummary: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(SemanticColors.positive.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(SemanticColors.positive)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("This week's additives")
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundColor(appPalette.textPrimary)

                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Text("\(viewModel.totalAdditiveCount)")
                                .font(.system(size: 13, weight: .bold))
                            Text("total")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(appPalette.textSecondary)
                    }
                }

                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(appPalette.tertiary.opacity(colorScheme == .dark ? 0.08 : 0.04))
        )
    }

    // MARK: - Summary Card (Clear, Informative)

    private func summaryCard(_ score: AdditivePatternScore) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                // Icon showing status
                ZStack {
                    Circle()
                        .fill(score.grade.color.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: score.grade.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(score.grade.color)
                }

                VStack(alignment: .leading, spacing: 6) {
                    // Clear headline
                    Text(score.message)
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundColor(appPalette.textPrimary)

                    // Actual useful stats
                    HStack(spacing: 12) {
                        if score.cleanStreakDays > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(SemanticColors.positive)
                                Text("\(score.cleanStreakDays)d clean")
                                    .font(.system(size: 13))
                                    .foregroundColor(appPalette.textSecondary)
                            }
                        }

                        HStack(spacing: 4) {
                            Text("\(viewModel.totalAdditiveCount)")
                                .font(.system(size: 13, weight: .bold))
                            Text("this week")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(appPalette.textSecondary)
                    }
                }

                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(score.grade.color.opacity(colorScheme == .dark ? 0.08 : 0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(score.grade.color.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Trend Card (Full Width, Explains What's Changing)

    private func trendCard(_ score: AdditivePatternScore) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: trendIcon(for: score.trend))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(score.trend.color)

                Text(trendTitle(for: score.trend))
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundColor(appPalette.textPrimary)
            }

            // EXPLAIN what's changing
            Text(trendExplanation(score: score))
                .font(.system(size: 14))
                .foregroundColor(appPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // Show the numbers
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("THIS WEEK")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(appPalette.textTertiary)
                        .tracking(0.5)

                    Text("\(score.recentScore)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor(score.recentScore))
                }

                Image(systemName: "arrow.right")
                    .font(.system(size: 14))
                    .foregroundColor(appPalette.textTertiary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("EARLIER")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(appPalette.textTertiary)
                        .tracking(0.5)

                    Text("\(score.earlierScore)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor(score.earlierScore))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            score.trend.color.opacity(colorScheme == .dark ? 0.12 : 0.06),
                            score.trend.color.opacity(colorScheme == .dark ? 0.06 : 0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(score.trend.color.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Additives List (THE MAIN CONTENT)

    private var additivesListWithDetails: some View {
        VStack(spacing: 14) {
            // Group by severity
            let avoid = viewModel.additiveAggregates.filter { $0.effectsVerdict.lowercased() == "avoid" }
            let caution = viewModel.additiveAggregates.filter { $0.effectsVerdict.lowercased() == "caution" }
            let neutral = viewModel.additiveAggregates.filter {
                $0.effectsVerdict.lowercased() == "neutral" || $0.effectsVerdict.isEmpty
            }

            if !avoid.isEmpty {
                additiveGroup(
                    title: "Worth noting",
                    subtitle: "These have research-backed health concerns",
                    additives: avoid,
                    color: .red
                )
            }

            if !caution.isEmpty {
                additiveGroup(
                    title: "Use in moderation",
                    subtitle: "Generally safe but worth limiting",
                    additives: caution,
                    color: .orange
                )
            }

            if !neutral.isEmpty {
                additiveGroup(
                    title: "Generally safe",
                    subtitle: "Approved and considered safe at typical levels",
                    additives: neutral,
                    color: SemanticColors.positive
                )
            }
        }
    }

    private func additiveGroup(title: String, subtitle: String, additives: [AdditiveAggregate], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with explanation - MORE PROMINENT
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    // Larger, clearer risk indicator
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 28, height: 28)

                        Circle()
                            .fill(color)
                            .frame(width: 10, height: 10)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 16, weight: .bold, design: .serif))
                            .foregroundColor(appPalette.textPrimary)

                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(appPalette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Text("\(additives.count)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(color.opacity(0.15))
                        )
                }
            }
            .padding(.bottom, 4)

            // Additive rows with expand for details
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
        let isWatched = watchedAdditives.contains(additive.code)

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                // Risk indicator
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)

                // Main content - tappable
                Button(action: {
                    withAnimation(.none) {
                        expandedAdditiveId = expandedAdditiveId == additive.id ? nil : additive.id
                    }
                }) {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                // Watched indicator
                                if isWatched {
                                    Image(systemName: "eye.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.orange)
                                }

                                Text(additive.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(appPalette.textPrimary)

                                if !additive.code.isEmpty {
                                    Text(additive.code)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(appPalette.textSecondary)
                                }
                            }

                            // Show occurrence count and foods
                            HStack(spacing: 8) {
                                Text("×\(additive.occurrenceCount)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(appPalette.textTertiary)

                                if !additive.foodItems.isEmpty {
                                    Text("in")
                                        .font(.system(size: 12))
                                        .foregroundColor(appPalette.textTertiary)
                                    Text(additive.foodItems.prefix(2).joined(separator: ", "))
                                        .font(.system(size: 12))
                                        .foregroundColor(appPalette.textSecondary)
                                        .lineLimit(1)
                                }
                            }
                        }

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.up" : "info.circle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(appPalette.textTertiary)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                // Watch/Flag button
                Button(action: {
                    toggleWatch(for: additive.code)
                }) {
                    Image(systemName: isWatched ? "eye.fill" : "eye")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isWatched ? .orange : appPalette.textTertiary.opacity(0.5))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())

            // Expanded: Show the actual useful info from AdditiveTrackerView
            if isExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    // What it is & why it's used (always visible)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("What it is")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(appPalette.textPrimary)

                        Text(additive.whatItIsAndWhyItsUsed)
                            .font(.system(size: 12))
                            .foregroundColor(appPalette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Known reactions (if any)
                    if !additive.knownReactions.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Known reactions")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(appPalette.textPrimary)

                            ForEach(additive.knownReactions.prefix(3), id: \.self) { reaction in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(color)
                                        .frame(width: 6, alignment: .center)

                                    Text(reaction)
                                        .font(.system(size: 12))
                                        .foregroundColor(appPalette.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    // Where found (show all now)
                    if !additive.whereItsFound.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Common in")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(appPalette.textPrimary)

                            Text(additive.whereItsFound.prefix(5).joined(separator: ", "))
                                .font(.system(size: 12))
                                .foregroundColor(appPalette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Helper Functions

    private func trendIcon(for trend: AdditiveTrendDirection) -> String {
        switch trend {
        case .improving: return "arrow.up.right.circle.fill"
        case .stable: return "arrow.right.circle.fill"
        case .declining: return "arrow.down.right.circle.fill"
        }
    }

    private func trendTitle(for trend: AdditiveTrendDirection) -> String {
        switch trend {
        case .improving: return "You're improving"
        case .stable: return "Staying steady"
        case .declining: return "Worth reviewing"
        }
    }

    private func trendExplanation(score: AdditivePatternScore) -> String {
        switch score.trend {
        case .improving:
            return "You're consuming fewer concerning additives compared to earlier this month. Keep it up!"
        case .stable:
            return "Your additive consumption has remained consistent over the past month."
        case .declining:
            return "You're consuming more concerning additives than earlier this month. Consider choosing foods with cleaner ingredient lists."
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        if score >= 70 { return SemanticColors.positive }
        if score >= 40 { return .orange }
        return .red
    }

    // MARK: - Loading & Empty States

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: palette.accent))
            Text("Analyzing your week...")
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

    private func loadPatternScore() async {
        isLoadingPattern = true
        patternScore = await viewModel.analyzeAdditivePattern()
        isLoadingPattern = false
    }

    private func toggleWatch(for code: String) {
        if watchedAdditives.contains(code) {
            watchedAdditives.remove(code)
        } else {
            watchedAdditives.insert(code)
        }
        // Persist to UserDefaults
        UserDefaults.standard.set(Array(watchedAdditives), forKey: "watchedAdditives")
        // Post notification for other views to update
        NotificationCenter.default.post(name: NSNotification.Name("WatchedAdditivesChanged"), object: nil)
    }

    private func loadWatchedAdditives() {
        if let saved = UserDefaults.standard.array(forKey: "watchedAdditives") as? [String] {
            watchedAdditives = Set(saved)
        }
    }
}
