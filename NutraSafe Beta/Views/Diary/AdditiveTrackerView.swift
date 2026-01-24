//
//  AdditiveInsightsRedesigned.swift
//  NutraSafe Beta
//
//  Redesigned additive insights matching premium onboarding aesthetic
//  Design philosophy: Emotion-first, calm, trust-building, minimal repetition
//

import SwiftUI
import UIKit

// MARK: - Premium Additive Insights Section

struct AdditiveTrackerSection: View {
    @ObservedObject var viewModel: AdditiveTrackerViewModel
    @State private var expandedAdditiveId: String?
    @State private var fullFactsExpandedId: String?
    @State private var funDescriptionExpandedId: String?
    @State private var isExpanded = true
    @State private var showingSources = false
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

    // Group additives by observation level
    private var noteworthyAdditives: [AdditiveAggregate] {
        viewModel.additiveAggregates.filter { $0.effectsVerdict.lowercased() == "avoid" }
    }

    private var moderateAdditives: [AdditiveAggregate] {
        viewModel.additiveAggregates.filter { $0.effectsVerdict.lowercased() == "caution" }
    }

    private var safeAdditives: [AdditiveAggregate] {
        viewModel.additiveAggregates.filter {
            $0.effectsVerdict.lowercased() == "neutral" || $0.effectsVerdict.isEmpty
        }
    }

    // Overall health signal
    private var healthSignal: (grade: AdditiveGrade, message: String, color: Color) {
        let avoid = noteworthyAdditives.count
        let caution = moderateAdditives.count
        let neutral = safeAdditives.count
        let total = avoid + caution + neutral

        if total == 0 {
            return (.none, "No additives detected", SemanticColors.positive)
        }

        var score = 100 - (avoid * 20) - (caution * 10) - (neutral * 2)
        if total > 5 { score -= (total - 5) * 2 }
        score = max(0, min(100, score))

        let grade = AdditiveGrade.from(score: score, hasAdditives: total > 0)

        // Message should match the grade being shown
        let message: String = {
            switch grade {
            case .none:
                return "No additives detected"
            case .average:
                // Low-risk only, few additives
                if avoid == 0 && caution == 0 {
                    return "Your choices look good"
                } else {
                    return "Balanced choices"
                }
            case .belowAverage:
                // Some caution additives or many neutral ones
                if avoid == 0 {
                    return "Mostly safe additives in moderation"
                } else {
                    return "A few worth noting"
                }
            case .poor:
                return "Worth noting what's in your food"
            }
        }()

        return (grade, message, grade.color)
    }

    // Dynamic header based on period
    private var headerTitle: String {
        switch viewModel.selectedPeriod {
        case .day: return "Today's additives"
        case .week: return "This week's additives"
        case .month: return "This month"
        case .ninetyDays: return "Last 90 days"
        }
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

                    Text(headerTitle)
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .foregroundColor(appPalette.textPrimary)
                        .animation(.none, value: viewModel.selectedPeriod)

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
                    // Time period picker - elegant, minimal
                    timePeriodSelector
                        .padding(.horizontal, 20)

                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.hasData {
                        // Single summary - no repetition
                        summaryCard
                            .padding(.horizontal, 20)

                        // Single insight card - contextual, not preachy
                        if let insight = singleRelevantInsight {
                            insightCard(insight)
                                .padding(.horizontal, 20)
                        }

                        // Additive lists - grouped simply
                        additivesList
                            .padding(.horizontal, 20)

                        // Minimal sources link
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
        .onAppear {
            viewModel.loadData()
        }
        .fullScreenCover(isPresented: $showingSources) {
            SourcesAndCitationsView()
        }
    }

    // MARK: - Time Period Selector (Clean, minimal)

    private var timePeriodSelector: some View {
        HStack(spacing: 8) {
            ForEach(AdditiveTimePeriod.allCases, id: \.self) { period in
                let isSelected = viewModel.selectedPeriod == period

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.selectPeriod(period)
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .regular, design: .default))
                        .foregroundColor(isSelected ? .white : appPalette.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected ? palette.accent : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.clear : appPalette.textTertiary.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(appPalette.tertiary.opacity(colorScheme == .dark ? 0.12 : 0.08))
        )
    }

    // MARK: - Summary Card (Single, clear message)

    private var summaryCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Signal icon - uses NutraSafe design language
                SignalIconContainer(color: healthSignal.color, size: 64)

                VStack(alignment: .leading, spacing: 6) {
                    Text(healthSignal.message)
                        .font(.system(size: 17, weight: .semibold, design: .serif))
                        .foregroundColor(appPalette.textPrimary)

                    if viewModel.totalAdditiveCount > 0 {
                        HStack(spacing: 12) {
                            statPill(value: "\(viewModel.totalAdditiveCount)", label: "total")

                            if noteworthyAdditives.count > 0 {
                                statPill(value: "\(noteworthyAdditives.count)", label: "worth noting", color: .red)
                            }
                        }
                    } else {
                        Text("No additives detected")
                            .font(.system(size: 14))
                            .foregroundColor(appPalette.textSecondary)
                    }
                }

                Spacer()
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            appPalette.tertiary.opacity(colorScheme == .dark ? 0.15 : 0.06),
                            appPalette.tertiary.opacity(colorScheme == .dark ? 0.08 : 0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private func statPill(value: String, label: String, color: Color? = nil) -> some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 12, design: .rounded))
        }
        .foregroundColor(color ?? appPalette.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill((color ?? appPalette.textTertiary).opacity(0.12))
        )
    }

    // MARK: - Single Relevant Insight (No repetition)

    private var singleRelevantInsight: (title: String, message: String, icon: String, color: Color)? {
        let avoid = noteworthyAdditives.count
        let total = viewModel.totalAdditiveCount

        // Only show ONE contextual insight, never multiple

        // Priority 1: Check for specific concerning additives
        if let titanium = viewModel.additiveAggregates.first(where: {
            $0.code.lowercased() == "e171" || $0.name.lowercased().contains("titanium dioxide")
        }) {
            return (
                "Titanium dioxide detected",
                "Banned in the EU since 2022. Still permitted in UK foods.",
                "info.circle.fill",
                .orange
            )
        }

        if noteworthyAdditives.contains(where: {
            ["e249", "e250", "e251", "e252"].contains($0.code.lowercased())
        }) {
            return (
                "Nitrates in your log",
                "Found in processed meats. FSA advises limiting to 70g daily.",
                "exclamationmark.triangle.fill",
                .orange
            )
        }

        // Priority 2: General patterns
        if total == 0 {
            return (
                "Clean eating",
                "You're choosing foods without added chemicals. Your body thanks you.",
                "leaf.fill",
                SemanticColors.positive
            )
        }

        if avoid >= 3 {
            return (
                "Patterns emerging",
                "Spotting these helps you make informed swaps over time.",
                "sparkles",
                palette.accent
            )
        }

        if avoid == 0 && moderateAdditives.count <= 2 {
            return (
                "Balanced choices",
                "Mostly safe additives in moderation.",
                "scale.3d",
                SemanticColors.positive
            )
        }

        // Default: no insight needed
        return nil
    }

    private func insightCard(_ insight: (title: String, message: String, icon: String, color: Color)) -> some View {
        HStack(spacing: 14) {
            Image(systemName: insight.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(insight.color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(insight.color.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundColor(appPalette.textPrimary)

                Text(insight.message)
                    .font(.system(size: 14))
                    .foregroundColor(appPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(insight.color.opacity(colorScheme == .dark ? 0.08 : 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(insight.color.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Additives List (Simple grouping)

    private var additivesList: some View {
        VStack(spacing: 14) {
            if !noteworthyAdditives.isEmpty {
                additiveGroup(
                    title: "Worth noting",
                    additives: noteworthyAdditives,
                    color: .red
                )
            }

            if !moderateAdditives.isEmpty {
                additiveGroup(
                    title: "In moderation",
                    additives: moderateAdditives,
                    color: SemanticColors.neutral
                )
            }

            if !safeAdditives.isEmpty {
                additiveGroup(
                    title: "Generally safe",
                    additives: safeAdditives,
                    color: palette.accent
                )
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
            // Main row - always visible
            Button(action: {
                withAnimation(.none) {
                    expandedAdditiveId = expandedAdditiveId == additive.id ? nil : additive.id
                }
            }) {
                HStack(spacing: 12) {
                    // Risk indicator
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)

                    // Name + Code
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

                    // Expand/Collapse indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(appPalette.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // PRIORITY 1: "What I need to know" - ALWAYS VISIBLE, TOP POSITION
                    if !additive.whatYouNeedToKnow.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What I need to know")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(appPalette.textPrimary)

                            ForEach(additive.whatYouNeedToKnow, id: \.self) { claim in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(color)
                                        .frame(width: 6, alignment: .center)

                                    Text(claim)
                                        .font(.system(size: 12))
                                        .foregroundColor(appPalette.textPrimary)
                                        .lineLimit(.max)

                                    Spacer()
                                }
                            }
                        }
                        .padding(.top, 8)
                    }

                    // PRIORITY 2: Fun descriptions - COLLAPSIBLE (starts closed)
                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: {
                            var transaction = Transaction()
                            transaction.disablesAnimations = true
                            withTransaction(transaction) {
                                if funDescriptionExpandedId == additive.id {
                                    funDescriptionExpandedId = nil
                                } else {
                                    funDescriptionExpandedId = additive.id
                                }
                            }
                        }) {
                            HStack {
                                Text("More about this additive")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(appPalette.textPrimary)

                                Spacer()

                                Image(systemName: funDescriptionExpandedId == additive.id ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(appPalette.textTertiary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        if funDescriptionExpandedId == additive.id {
                            VStack(alignment: .leading, spacing: 10) {
                                // Fun engaging description (what is it)
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.purple)
                                        .frame(width: 16)

                                    Text(additive.whatIsIt)
                                        .font(.system(size: 13))
                                        .foregroundColor(appPalette.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.leading, 4)

                                // Fun origin description (where from)
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.teal)
                                        .frame(width: 16)

                                    Text(additive.whereIsItFrom)
                                        .font(.system(size: 13))
                                        .foregroundColor(appPalette.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.leading, 4)
                            }
                            .padding(.top, 4)
                        }
                    }

                    // "Full Facts" section - collapsible
                    if !additive.fullFacts.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                var transaction = Transaction()
                                transaction.disablesAnimations = true
                                withTransaction(transaction) {
                                    // Toggle full facts visibility
                                    if fullFactsExpandedId == additive.id {
                                        fullFactsExpandedId = nil
                                    } else {
                                        fullFactsExpandedId = additive.id
                                    }
                                }
                            }) {
                                HStack {
                                    Text("Full Facts")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(appPalette.textPrimary)

                                    Spacer()

                                    Image(systemName: fullFactsExpandedId == additive.id ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(appPalette.textTertiary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())

                            if fullFactsExpandedId == additive.id {
                                Text(additive.fullFacts)
                                    .font(.system(size: 12))
                                    .foregroundColor(appPalette.textSecondary)
                                    .lineLimit(.max)
                            }
                        }
                    }

                    // Foods list
                    if !additive.foodItems.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Found in \(additive.occurrenceCount) food(s):")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(appPalette.textPrimary)

                            ForEach(additive.foodItems.prefix(5), id: \.self) { food in
                                HStack(spacing: 8) {
                                    Text("•")
                                        .font(.system(size: 11))
                                        .foregroundColor(appPalette.textTertiary)

                                    Text(food)
                                        .font(.system(size: 12))
                                        .foregroundColor(appPalette.textSecondary)
                                        .lineLimit(1)

                                    Spacer()
                                }
                            }

                            if additive.foodItems.count > 5 {
                                Text("and \(additive.foodItems.count - 5) more...")
                                    .font(.system(size: 11))
                                    .foregroundColor(appPalette.textTertiary)
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(8)
            }
        }
    }

    private func detailRow(icon: String, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(color)
                .frame(width: 16)

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(appPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, 4)
    }

    // MARK: - Loading & Empty States

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: palette.accent))
            Text("Reading your log...")
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

            Text("Log foods to see what's inside")
                .font(.system(size: 14))
                .foregroundColor(appPalette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Sources Link (Minimal, understated)

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
}

// MARK: - Preview

#if DEBUG
struct AdditiveTrackerSection_Redesigned_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            AdditiveTrackerSection(viewModel: AdditiveTrackerViewModel())
                .preferredColorScheme(.light)

            AdditiveTrackerSection(viewModel: AdditiveTrackerViewModel())
                .preferredColorScheme(.dark)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}
#endif
