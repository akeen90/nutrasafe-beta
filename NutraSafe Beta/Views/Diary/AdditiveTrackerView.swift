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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "flask.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Additive Exposure")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
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

                        // Additives grouped by health verdict
                        if !avoidAdditives.isEmpty {
                            verdictSection(
                                title: "Avoid",
                                subtitle: "Health concerns identified",
                                icon: "exclamationmark.octagon.fill",
                                color: .red,
                                additives: avoidAdditives
                            )
                        }

                        if !cautionAdditives.isEmpty {
                            verdictSection(
                                title: "Caution",
                                subtitle: "Use in moderation",
                                icon: "exclamationmark.triangle.fill",
                                color: .orange,
                                additives: cautionAdditives
                            )
                        }

                        if !neutralAdditives.isEmpty {
                            verdictSection(
                                title: "Generally Safe",
                                subtitle: "No significant concerns",
                                icon: "checkmark.circle.fill",
                                color: .green,
                                additives: neutralAdditives
                            )
                        }
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
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
        .onAppear {
            viewModel.loadData()
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
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                Text("additive\(viewModel.totalAdditiveCount == 1 ? "" : "s") logged")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(viewModel.foodItemCount)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                Text("food\(viewModel.foodItemCount == 1 ? "" : "s") with additives")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.1), Color.red.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    // MARK: - Verdict Section

    private func verdictSection(title: String, subtitle: String, icon: String, color: Color, additives: [AdditiveAggregate]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(additives.count)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(color.opacity(0.15))
                    )
            }

            // Additives list
            VStack(spacing: 0) {
                ForEach(additives) { additive in
                    ExpandableAdditiveRow(
                        additive: additive,
                        isExpanded: expandedAdditiveId == additive.id,
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
                .fill(Color(.secondarySystemBackground))
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
            Image(systemName: "flask")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No additives detected")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)

            Text("Log foods with ingredients to track additive exposure")
                .font(.system(size: 13))
                .foregroundColor(.secondary.opacity(0.8))
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
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row (always visible)
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Verdict indicator
                    Circle()
                        .fill(additive.verdictColor)
                        .frame(width: 8, height: 8)

                    VStack(alignment: .leading, spacing: 2) {
                        // Code and name
                        HStack(spacing: 6) {
                            if !additive.code.isEmpty {
                                Text(additive.code)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.orange)
                            }
                            Text(additive.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }

                        // Category
                        HStack(spacing: 4) {
                            Text(additive.category)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            if additive.childWarning {
                                Text("·")
                                    .foregroundColor(.secondary)
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.orange)
                                Text("Child warning")
                                    .font(.system(size: 11))
                                    .foregroundColor(.orange)
                            }
                        }
                    }

                    Spacer()

                    // Occurrence count
                    Text("×\(additive.occurrenceCount)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()

                    // What is it
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.purple)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("What is it?")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text(additive.whatIsIt)
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // Where is it from
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "globe.europe.africa.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.teal)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Where does it come from?")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text(additive.whereIsItFrom)
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // Health verdict explanation
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: verdictIcon)
                            .font(.system(size: 14))
                            .foregroundColor(additive.verdictColor)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Health Assessment")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text(verdictDescription)
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // Foods containing this additive
                    if !additive.foodItems.isEmpty {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Found in")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Text(additive.foodItems.joined(separator: ", "))
                                    .font(.system(size: 13))
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    // Health score
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14))
                            .foregroundColor(healthScoreColor)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Health Score")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                            HStack(spacing: 8) {
                                Text("\(additive.healthScore)/100")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(healthScoreColor)

                                // Progress bar
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color(.systemGray5))
                                            .frame(height: 6)
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(healthScoreColor)
                                            .frame(width: geo.size.width * CGFloat(additive.healthScore) / 100, height: 6)
                                    }
                                }
                                .frame(height: 6)
                            }
                        }
                    }
                }
                .padding(.leading, 20)
                .padding(.bottom, 10)
            }
        }
    }

    private var verdictIcon: String {
        switch additive.effectsVerdict.lowercased() {
        case "avoid": return "xmark.octagon.fill"
        case "caution": return "exclamationmark.triangle.fill"
        default: return "checkmark.circle.fill"
        }
    }

    private var verdictDescription: String {
        switch additive.effectsVerdict.lowercased() {
        case "avoid":
            return "Studies suggest potential health concerns. Consider limiting intake or choosing alternatives."
        case "caution":
            return "May cause issues for some individuals. Use in moderation and monitor for any reactions."
        default:
            return "Generally recognised as safe by food safety authorities when used within approved limits."
        }
    }

    private var healthScoreColor: Color {
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
