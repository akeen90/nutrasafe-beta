//
//  AdditiveTrackerView.swift
//  NutraSafe Beta
//
//  Displays additive consumption tracking over time periods
//

import SwiftUI

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

        if total == 0 { return .A }

        // Calculate score similar to the analyzer
        var score = 100
        score -= (avoid * 20) + (caution * 10) + (neutral * 2)
        if total > 5 { score -= (total - 5) * 2 }
        score = max(0, min(100, score))

        return AdditiveGrade.from(score: score)
    }

    // Generate actionable insight based on the data
    private var actionableInsight: (text: String, icon: String, color: Color)? {
        let avoid = avoidAdditives.count
        let caution = cautionAdditives.count
        let total = viewModel.totalAdditiveCount

        if total == 0 {
            return ("Great job! No additives detected in your food log.", "checkmark.circle.fill", SemanticColors.positive)
        }

        if avoid > 2 {
            // Find most common avoid additive
            if let topAvoid = avoidAdditives.sorted(by: { $0.occurrenceCount > $1.occurrenceCount }).first {
                return ("Consider reducing \(topAvoid.name) - appeared \(topAvoid.occurrenceCount) time\(topAvoid.occurrenceCount == 1 ? "" : "s")", "exclamationmark.triangle.fill", SemanticColors.caution)
            }
        }

        if avoid == 0 && caution <= 2 {
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
                    // Time Period Picker
                    timePeriodPicker

                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.hasData {
                        // Summary Card
                        summaryCard

                        // Additives grouped by observation category
                        if !avoidAdditives.isEmpty {
                            verdictSection(
                                title: "Worth noting",
                                subtitle: "Some studies suggest limiting these",
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
                                subtitle: "No significant concerns noted",
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
                // Grade circle
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

                    // Research notes (formerly Health Assessment)
                    detailRow(
                        color: additive.verdictColor,
                        title: "Research notes",
                        content: observationDescription
                    )

                    // Foods containing this additive
                    if !additive.foodItems.isEmpty {
                        detailRow(
                            color: palette.accent,
                            title: "Found in",
                            content: additive.foodItems.joined(separator: ", ")
                        )
                    }

                    // Safety rating bar (observational, not judgmental)
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

    // Observational description (not judgmental)
    private var observationDescription: String {
        switch additive.effectsVerdict.lowercased() {
        case "avoid":
            return "Some studies suggest limiting intake. Consider alternatives if you're concerned."
        case "caution":
            return "Generally fine in small amounts. Some people may prefer to limit consumption."
        default:
            return "Recognised as safe by food safety authorities (EFSA, FSA, FDA) within approved limits."
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
