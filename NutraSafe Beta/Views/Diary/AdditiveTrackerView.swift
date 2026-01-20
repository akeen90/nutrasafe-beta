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

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header - observational tone
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    // Signal icon instead of flask
                    SignalIconContainer(color: palette.accent, size: 32)

                    Text("Additives this week")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(palette.textPrimary)

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
                                color: .orange,
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
        HStack(spacing: 0) {
            ForEach(AdditiveTimePeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectPeriod(period)
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(viewModel.selectedPeriod == period ? .white : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.selectedPeriod == period
                                ? Capsule().fill(Color.orange)
                                : Capsule().fill(Color(.systemGray6))
                        )
                        .contentShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())

                if period != AdditiveTimePeriod.allCases.last {
                    Spacer(minLength: 4)
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.totalAdditiveCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(palette.textPrimary)
                Text("additive\(viewModel.totalAdditiveCount == 1 ? "" : "s") detected")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(palette.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(viewModel.foodItemCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(palette.textPrimary)
                Text("food\(viewModel.foodItemCount == 1 ? "" : "s") with additives")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(palette.textTertiary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(palette.tertiary.opacity(colorScheme == .dark ? 0.1 : 0.06))
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
                                NutraSafeSignalIcon(color: .orange, size: 10)
                                Text("Note for children")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundColor(.orange)
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
            return .green
        } else if additive.healthScore >= 40 {
            return .orange
        } else {
            return .red
        }
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
