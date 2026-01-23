//
//  AdditiveTrackerView.swift
//  NutraSafe Beta
//
//  Displays additive consumption tracking over time periods
//

import SwiftUI

// MARK: - Research Insight Model

private struct ResearchInsight {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

// MARK: - Main Additive Tracker Section

struct AdditiveTrackerSection: View {
    @ObservedObject var viewModel: AdditiveTrackerViewModel
    @State private var expandedAdditiveId: String?
    @State private var isExpanded = true
    @State private var showingSources = false

    // Group additives by verdict
    private var avoidAdditives: [AdditiveAggregate] {
        viewModel.additiveAggregates.filter { $0.effectsVerdict.lowercased() == "avoid" }
    }

    private var cautionAdditives: [AdditiveAggregate] {
        viewModel.additiveAggregates.filter { $0.effectsVerdict.lowercased() == "caution" }
    }

    private var neutralAdditives: [AdditiveAggregate] {
        viewModel.additiveAggregates.filter { $0.effectsVerdict.lowercased() == "neutral" || $0.effectsVerdict.isEmpty }
    }

    // Calculate overall additive grade for the period
    private var overallGrade: AdditiveGrade {
        let avoid = avoidAdditives.count
        let caution = cautionAdditives.count
        let neutral = neutralAdditives.count
        let total = avoid + caution + neutral

        if total == 0 { return .none }

        // Calculate score similar to the analyzer
        var score = 100
        score -= (avoid * 20) + (caution * 10) + (neutral * 2)
        if total > 5 { score -= (total - 5) * 2 }
        score = max(0, min(100, score))

        return AdditiveGrade.from(score: score, hasAdditives: total > 0)
    }

    // Generate actionable insight based on the data
    private var actionableInsight: (text: String, icon: String, color: Color)? {
        let avoid = avoidAdditives.count
        let caution = cautionAdditives.count
        let total = viewModel.totalAdditiveCount
        let grade = overallGrade

        if total == 0 {
            return ("Great job! No additives detected in your food log.", "checkmark.circle.fill", SemanticColors.positive)
        }

        if grade == .poor || grade == .belowAverage {
            let topAvoid = avoidAdditives.sorted(by: { $0.occurrenceCount > $1.occurrenceCount }).first?.name
            if let top = topAvoid {
                return ("High additive load. Reducing \(top) would have the biggest impact.", "exclamationmark.triangle.fill", SemanticColors.caution)
            }
            return ("High additive load. Focus on reducing additive-heavy foods this period.", "exclamationmark.triangle.fill", SemanticColors.caution)
        }

        if avoid > 2 {
            // Find most common avoid additive
            if let topAvoid = avoidAdditives.sorted(by: { $0.occurrenceCount > $1.occurrenceCount }).first {
                return ("Consider reducing \(topAvoid.name) - appeared \(topAvoid.occurrenceCount) time\(topAvoid.occurrenceCount == 1 ? "" : "s")", "exclamationmark.triangle.fill", SemanticColors.caution)
            }
        }

        if avoid == 0 && caution <= 2 && grade != .belowAverage && grade != .poor {
            return ("You're doing well! Mostly safe additives in your diet.", "hand.thumbsup.fill", SemanticColors.positive)
        }

        if caution > 3 {
            return ("Try swapping some processed foods for whole foods to reduce additives.", "lightbulb.fill", palette.accent)
        }

        return nil
    }

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    /// Dynamic header title based on selected time period
    private var headerTitle: String {
        switch viewModel.selectedPeriod {
        case .day:
            return "Additives today"
        case .week:
            return "Additives this week"
        case .month:
            return "Additives this month"
        case .ninetyDays:
            return "Additives over 90 days"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header - observational tone with dynamic title
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    // Signal icon instead of flask
                    SignalIconContainer(color: palette.accent, size: 32)

                    Text(headerTitle)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(palette.textPrimary)
                        .animation(.none, value: viewModel.selectedPeriod)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(palette.textTertiary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 16)

            if isExpanded {
                VStack(spacing: 16) {
                    // Educational explanation (like Reactions section)
                    whyTrackAdditivesCard

                    // Time Period Picker
                    timePeriodPicker

                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.hasData {
                        // Summary Card with trends
                        summaryCard

                        // Research-backed insights
                        researchInsightsSection

                        // Additives grouped by observation category
                        if !avoidAdditives.isEmpty {
                            verdictSection(
                                title: "Worth noting",
                                subtitle: "Research suggests limiting these",
                                color: .red,
                                additives: avoidAdditives
                            )
                        }

                        if !cautionAdditives.isEmpty {
                            verdictSection(
                                title: "In moderation",
                                subtitle: "Generally fine in small amounts",
                                color: SemanticColors.neutral,
                                additives: cautionAdditives
                            )
                        }

                        if !neutralAdditives.isEmpty {
                            verdictSection(
                                title: "Generally safe",
                                subtitle: "Approved by EFSA, FSA, and FDA",
                                color: palette.accent,
                                additives: neutralAdditives
                            )
                        }

                        // Sources link
                        Button {
                            showingSources = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 12))
                                Text("View Sources (EFSA, FSA, FDA)")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(AppPalette.standard.accent)
                            .padding(.top, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        emptyStateView
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.adaptiveCard)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
        .onAppear {
            viewModel.loadData()
        }
        .fullScreenCover(isPresented: $showingSources) {
            SourcesAndCitationsView()
        }
    }

    // MARK: - Why Track Additives (Educational)

    private var whyTrackAdditivesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.nutrient)
                Text("Why track additives?")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(palette.textPrimary)
            }

            Text("Your body processes hundreds of additives daily. While most are safe individually, the cumulative effect over time is less understood. Tracking helps you:")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                benefitRow(icon: "eye", text: "See patterns in what you're consuming")
                benefitRow(icon: "chart.line.downtrend.xyaxis", text: "Reduce additives linked to health concerns")
                benefitRow(icon: "figure.child", text: "Make informed choices for your family")
                benefitRow(icon: "heart.text.square", text: "Connect symptoms to potential triggers")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(SemanticColors.nutrient.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(SemanticColors.nutrient.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(palette.accent)
                .frame(width: 16)
            Text(text)
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(palette.textSecondary)
        }
    }

    // MARK: - Research Insights Section

    private var researchInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "text.book.closed.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.purple)
                Text("What the research says")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(palette.textPrimary)
            }

            VStack(spacing: 10) {
                ForEach(relevantResearchInsights, id: \.title) { insight in
                    researchInsightRow(insight)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(palette.tertiary.opacity(colorScheme == .dark ? 0.08 : 0.05))
        )
    }

    private func researchInsightRow(_ insight: ResearchInsight) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: insight.icon)
                .font(.system(size: 12))
                .foregroundColor(insight.color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(palette.textPrimary)
                Text(insight.description)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // Research insight data based on user's actual additives
    private var relevantResearchInsights: [ResearchInsight] {
        var insights: [ResearchInsight] = []

        // Check for Southampton Six colours (E102, E104, E110, E122, E124, E129)
        let southamptonCodes = ["e102", "e104", "e110", "e122", "e124", "e129"]
        let hasColours = viewModel.additiveAggregates.contains { add in
            southamptonCodes.contains(add.code.lowercased()) ||
            add.category.lowercased().contains("colour") ||
            add.category.lowercased().contains("color")
        }
        if hasColours {
            insights.append(ResearchInsight(
                title: "Artificial colours & children",
                description: "The Southampton Study found links between certain artificial colours and hyperactivity in children. The EU now requires warning labels on foods with these additives.",
                icon: "figure.child",
                color: SemanticColors.caution
            ))
        }

        // Check for nitrates/nitrites (E249-E252)
        let nitrateCodes = ["e249", "e250", "e251", "e252"]
        let hasNitrates = viewModel.additiveAggregates.contains { add in
            nitrateCodes.contains(add.code.lowercased()) ||
            add.name.lowercased().contains("nitrate") ||
            add.name.lowercased().contains("nitrite")
        }
        if hasNitrates {
            insights.append(ResearchInsight(
                title: "Nitrates in processed meat",
                description: "WHO classifies processed meat as carcinogenic (Group 1). Nitrates form N-nitroso compounds linked to increased cancer risk. FSA recommends limiting to 70g daily.",
                icon: "exclamationmark.triangle.fill",
                color: .red
            ))
        }

        // Check for titanium dioxide (E171)
        let hasTitaniumDioxide = viewModel.additiveAggregates.contains { add in
            add.code.lowercased() == "e171" ||
            add.name.lowercased().contains("titanium dioxide")
        }
        if hasTitaniumDioxide {
            insights.append(ResearchInsight(
                title: "Titanium dioxide (E171)",
                description: "Banned in the EU since 2022 after EFSA found it could no longer be considered safe. Still permitted in the UK. Consider alternatives.",
                icon: "xmark.octagon.fill",
                color: .red
            ))
        }

        // Check for artificial sweeteners
        let sweetenerCodes = ["e950", "e951", "e952", "e954", "e955", "e960", "e961", "e962"]
        let hasSweeteners = viewModel.additiveAggregates.contains { add in
            sweetenerCodes.contains(add.code.lowercased()) ||
            add.category.lowercased().contains("sweetener")
        }
        if hasSweeteners {
            insights.append(ResearchInsight(
                title: "Artificial sweeteners",
                description: "Research is ongoing. Some studies link high consumption to gut microbiome changes. WHO advises against using them for weight control.",
                icon: "drop.fill",
                color: SemanticColors.neutral
            ))
        }

        // Check for sodium benzoate (E211)
        let hasSodiumBenzoate = viewModel.additiveAggregates.contains { add in
            add.code.lowercased() == "e211" ||
            add.name.lowercased().contains("sodium benzoate")
        }
        if hasSodiumBenzoate {
            insights.append(ResearchInsight(
                title: "Sodium benzoate (E211)",
                description: "Part of the Southampton Study mix linked to hyperactivity. Can form benzene when combined with vitamin C in acidic drinks.",
                icon: "flask.fill",
                color: SemanticColors.neutral
            ))
        }

        // Default insight if no specific matches
        if insights.isEmpty {
            insights.append(ResearchInsight(
                title: "Building your profile",
                description: "Keep logging foods to see personalised insights based on the specific additives in your diet. We'll highlight research relevant to what you're eating.",
                icon: "chart.bar.doc.horizontal",
                color: palette.accent
            ))
        }

        return Array(insights.prefix(3)) // Limit to 3 most relevant
    }

    // MARK: - Time Period Picker

    private var timePeriodPicker: some View {
        let additiveAccent = SemanticColors.additive

        return HStack(spacing: 8) {
            ForEach(AdditiveTimePeriod.allCases, id: \.self) { period in
                let isSelected = viewModel.selectedPeriod == period

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.selectPeriod(period)
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium, design: .rounded))
                        .foregroundColor(isSelected ? additiveAccent : .secondary.opacity(0.7))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            ZStack {
                                if isSelected {
                                    // Soft gradient tint for selected
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            LinearGradient(
                                                colors: [additiveAccent.opacity(0.12), additiveAccent.opacity(0.06)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(additiveAccent.opacity(0.25), lineWidth: 1)
                                } else {
                                    // Frosted neutral background
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(palette.tertiary.opacity(0.15))
                                }
                            }
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(AdditiveTabButtonStyle())
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        )
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: 16) {
            // Grade + Stats row
            HStack(spacing: 16) {
                // Grade circle with trend indicator
                ZStack {
                    Circle()
                        .fill(overallGrade.color)
                        .frame(width: 56, height: 56)

                    Text(overallGrade.rawValue)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }

                // Stats
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(viewModel.totalAdditiveCount)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(palette.textPrimary)
                            Text("additives")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(palette.textTertiary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(viewModel.foodItemCount)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(palette.textPrimary)
                            Text("foods")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(palette.textTertiary)
                        }

                        // Per-food average
                        if viewModel.foodItemCount > 0 {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(format: "%.1f", Double(viewModel.totalAdditiveCount) / Double(viewModel.foodItemCount)))
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(palette.textPrimary)
                                Text("per food")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundColor(palette.textTertiary)
                            }
                        }

                        Spacer()
                    }

                    // Risk breakdown pills
                    HStack(spacing: 6) {
                        if avoidAdditives.count > 0 {
                            riskPill(count: avoidAdditives.count, label: "avoid", color: .red)
                        }
                        if cautionAdditives.count > 0 {
                            riskPill(count: cautionAdditives.count, label: "caution", color: SemanticColors.neutral)
                        }
                        if neutralAdditives.count > 0 {
                            riskPill(count: neutralAdditives.count, label: "safe", color: SemanticColors.positive)
                        }
                    }
                }
            }

            // Progress tip based on data
            progressTipCard

            // Actionable insight
            if let insight = actionableInsight {
                HStack(spacing: 10) {
                    Image(systemName: insight.icon)
                        .font(.system(size: 14))
                        .foregroundColor(insight.color)

                    Text(insight.text)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(insight.color.opacity(0.08))
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(palette.tertiary.opacity(colorScheme == .dark ? 0.1 : 0.06))
        )
    }

    // Risk pill helper
    private func riskPill(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Text("\(count)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 10, design: .rounded))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
        )
    }

    // MARK: - Progress Tip Card

    private var progressTipCard: some View {
        let avoid = avoidAdditives.count
        let caution = cautionAdditives.count
        let total = viewModel.additiveAggregates.count
        let perFood = viewModel.foodItemCount > 0 ? Double(viewModel.totalAdditiveCount) / Double(viewModel.foodItemCount) : 0

        // Generate contextual tip based on the data
        let tip: (text: String, icon: String, color: Color) = {
            if total == 0 {
                return ("Keep logging to build your additive profile. The more you track, the more patterns we can show you.", "chart.bar.doc.horizontal", palette.accent)
            }

            if overallGrade == .poor || overallGrade == .belowAverage || avoid >= 3 || perFood > 6 {
                return ("Additives are high this period. Swap some processed items for whole foods to bring this down.", "exclamationmark.triangle.fill", SemanticColors.caution)
            }

            if avoid == 0 && caution <= 1 && overallGrade != .belowAverage {
                return ("Excellent choices! Your food selections have very few concerning additives. Keep it up.", "star.fill", SemanticColors.positive)
            }

            if perFood > 5 {
                return ("Your foods average \(String(format: "%.1f", perFood)) additives each. Choosing less processed options can reduce this significantly.", "arrow.down.circle", SemanticColors.neutral)
            }

            if viewModel.selectedPeriod == .week || viewModel.selectedPeriod == .month {
                return ("Tracking over \(viewModel.selectedPeriod.rawValue.lowercased()) helps spot patterns. Compare different periods to see your progress.", "calendar", palette.accent)
            }

            return ("You're building awareness of what's in your food. Knowledge is power when making healthier choices.", "brain.head.profile", palette.accent)
        }()

        return HStack(spacing: 10) {
            Image(systemName: tip.icon)
                .font(.system(size: 14))
                .foregroundColor(tip.color)

            Text(tip.text)
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(palette.tertiary.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(tip.color.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Observation Section (formerly Verdict Section)

    private func verdictSection(title: String, subtitle: String, color: Color, additives: [AdditiveAggregate]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header with signal icon
            HStack(spacing: 10) {
                NutraSafeSignalIcon(color: color, size: 18)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(palette.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(palette.textTertiary)
                }

                Spacer()

                Text("\(additives.count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(color.opacity(0.12))
                    )
            }

            // Additives list
            VStack(spacing: 0) {
                ForEach(additives) { additive in
                    ExpandableAdditiveRow(
                        additive: additive,
                        isExpanded: expandedAdditiveId == additive.id,
                        palette: palette,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if expandedAdditiveId == additive.id {
                                    expandedAdditiveId = nil
                                } else {
                                    expandedAdditiveId = additive.id
                                }
                            }
                        }
                    )

                    if additive.id != additives.last?.id {
                        Divider()
                            .padding(.leading, 20)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(palette.tertiary.opacity(colorScheme == .dark ? 0.08 : 0.05))
        )
    }

    // MARK: - Loading View

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Spacer()
        }
        .padding(.vertical, 40)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            NutraSafeSignalIcon(color: palette.textTertiary.opacity(0.5), size: 40)

            Text("No additives detected")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(palette.textTertiary)

            Text("Log foods with ingredients to see what's in them")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(palette.textTertiary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Expandable Additive Row

private struct ExpandableAdditiveRow: View {
    let additive: AdditiveAggregate
    let isExpanded: Bool
    let palette: AppPalette
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row (always visible)
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Status indicator dot
                    Circle()
                        .fill(additive.verdictColor)
                        .frame(width: 8, height: 8)

                    VStack(alignment: .leading, spacing: 2) {
                        // Code and name
                        HStack(spacing: 6) {
                            if !additive.code.isEmpty {
                                Text(additive.code)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(palette.accent)
                            }
                            Text(additive.name)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(palette.textPrimary)
                                .lineLimit(1)
                        }

                        // Category
                        HStack(spacing: 4) {
                            Text(additive.category)
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(palette.textTertiary)

                            if additive.childWarning {
                                Text("·")
                                    .foregroundColor(palette.textTertiary)
                                NutraSafeSignalIcon(color: SemanticColors.neutral, size: 10)
                                Text("Note for children")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundColor(SemanticColors.neutral)
                            }
                        }
                    }

                    Spacer()

                    // Occurrence count
                    Text("×\(additive.occurrenceCount)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(palette.textPrimary)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(palette.textTertiary)
                }
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()

                    // What is it - using signal icon
                    detailRow(
                        color: .purple,
                        title: "What is it?",
                        content: additive.whatIsIt
                    )

                    // Where is it from
                    detailRow(
                        color: .teal,
                        title: "Origin",
                        content: additive.whereIsItFrom
                    )

                    // Research notes - specific to additive
                    detailRow(
                        color: additive.verdictColor,
                        title: "What research says",
                        content: researchDescription
                    )

                    // Actionable tip - what can user do
                    detailRow(
                        color: SemanticColors.positive,
                        title: "What you can do",
                        content: actionableTip
                    )

                    // Foods containing this additive
                    if !additive.foodItems.isEmpty {
                        detailRow(
                            color: palette.accent,
                            title: "Found in your log",
                            content: additive.foodItems.joined(separator: ", ")
                        )
                    }

                    // Safety rating bar
                    HStack(alignment: .center, spacing: 10) {
                        NutraSafeSignalIcon(color: safetyColor, size: 14)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Safety rating")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(palette.textTertiary)

                            HStack(spacing: 8) {
                                Text("\(additive.healthScore)/100")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(safetyColor)

                                // Progress bar
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(palette.tertiary.opacity(0.15))
                                            .frame(height: 4)
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(safetyColor)
                                            .frame(width: geo.size.width * CGFloat(additive.healthScore) / 100, height: 4)
                                    }
                                }
                                .frame(height: 4)
                            }
                        }
                    }
                }
                .padding(.leading, 20)
                .padding(.bottom, 10)
            }
        }
    }

    // Reusable detail row with signal icon
    private func detailRow(color: Color, title: String, content: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            NutraSafeSignalIcon(color: color, size: 14)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(palette.textTertiary)
                Text(content)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // Research-backed description for specific additives
    private var researchDescription: String {
        let code = additive.code.lowercased()
        let name = additive.name.lowercased()

        // Southampton Six - artificial colours linked to hyperactivity
        if ["e102", "e104", "e110", "e122", "e124", "e129"].contains(code) {
            return "Part of the 'Southampton Six' studied by UK researchers. The 2007 Lancet study found links to increased hyperactivity in children. EU now requires warning labels. Effects vary by individual."
        }

        // Titanium dioxide
        if code == "e171" || name.contains("titanium dioxide") {
            return "Banned in EU since 2022 after EFSA concluded genotoxicity concerns couldn't be ruled out. Still permitted in UK. May accumulate in the body after ingestion."
        }

        // Nitrates/Nitrites
        if ["e249", "e250", "e251", "e252"].contains(code) || name.contains("nitrate") || name.contains("nitrite") {
            return "WHO classifies processed meat as Group 1 carcinogen, partly due to nitrates forming N-nitroso compounds. FSA advises limiting processed meat to 70g/day."
        }

        // Sodium benzoate
        if code == "e211" || name.contains("sodium benzoate") {
            return "Included in Southampton Study mix linked to child hyperactivity. Can form benzene (a carcinogen) when combined with vitamin C in acidic conditions."
        }

        // Aspartame
        if code == "e951" || name.contains("aspartame") {
            return "One of the most studied additives ever. EFSA set ADI at 40mg/kg body weight. 2023 WHO review found possible carcinogenicity at very high doses."
        }

        // MSG
        if code == "e621" || name.contains("msg") || name.contains("monosodium glutamate") {
            return "Despite its reputation, extensive research shows MSG is safe for most people. Some individuals report sensitivity symptoms ('Chinese restaurant syndrome')."
        }

        // Carrageenan
        if code == "e407" || name.contains("carrageenan") {
            return "Some studies suggest degraded carrageenan may cause gut inflammation. Food-grade carrageenan is different but debate continues. EFSA recently re-evaluated."
        }

        // Generic based on verdict
        switch additive.effectsVerdict.lowercased() {
        case "avoid":
            return "Research suggests some health concerns at typical consumption levels. EFSA and FSA have flagged this additive for review or recommend limiting intake."
        case "caution":
            return "Generally considered safe within limits. Some studies suggest caution for specific groups (children, pregnant women) or at high consumption levels."
        default:
            return "Extensively reviewed by EFSA, FSA, and FDA. No significant health concerns identified at permitted use levels."
        }
    }

    // Actionable tip - what the user can actually do
    private var actionableTip: String {
        let code = additive.code.lowercased()
        let name = additive.name.lowercased()
        let category = additive.category.lowercased()
        let count = additive.occurrenceCount

        // High occurrence - general reduction advice
        if count >= 5 {
            return "This appeared \(count) times in your log. Consider varying your food choices to reduce repeated exposure to the same additives."
        }

        // Specific advice by additive type
        if ["e102", "e104", "e110", "e122", "e124", "e129"].contains(code) {
            return "Look for products labelled 'no artificial colours' or those using natural alternatives like beetroot, turmeric, or paprika extract."
        }

        if code == "e171" || name.contains("titanium dioxide") {
            return "Common in white coatings on sweets and medicines. Many brands now offer titanium dioxide-free alternatives."
        }

        if ["e249", "e250", "e251", "e252"].contains(code) || name.contains("nitrate") || name.contains("nitrite") {
            return "Choose uncured or nitrate-free bacon, ham, and sausages. These use alternatives like celery juice powder."
        }

        if category.contains("sweetener") {
            return "If reducing artificial sweeteners, try gradually cutting back on sweetness overall. Your taste buds adapt within 2-3 weeks."
        }

        if category.contains("preservative") {
            return "Fresh and frozen foods typically have fewer preservatives than long-shelf-life products. Check 'best before' dates as a guide."
        }

        if category.contains("colour") || category.contains("color") {
            return "Natural alternatives exist for most food colours. Look for products that use fruit and vegetable extracts instead."
        }

        // Default based on verdict
        switch additive.effectsVerdict.lowercased() {
        case "avoid":
            return "Check ingredient labels for alternatives. Many brands now offer versions without this additive."
        case "caution":
            return "No need to avoid completely, but balance with whole foods. Variety helps reduce cumulative exposure."
        default:
            return "This is considered safe. No action needed, but tracking helps you stay informed about what you're eating."
        }
    }

    private var safetyColor: Color {
        if additive.healthScore >= 70 {
            return SemanticColors.positive
        } else if additive.healthScore >= 40 {
            return SemanticColors.neutral
        } else {
            return SemanticColors.caution
        }
    }
}

// MARK: - Additive Tab Button Style

/// Subtle scale effect for additive time period buttons
private struct AdditiveTabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Preview

#if DEBUG
struct AdditiveTrackerSection_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            AdditiveTrackerSection(viewModel: AdditiveTrackerViewModel())
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
