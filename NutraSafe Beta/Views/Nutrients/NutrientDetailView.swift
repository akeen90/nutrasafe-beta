//
//  NutrientDetailView.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-10-20.
//  Detailed view for individual nutrient with charts and heatmaps
//

import SwiftUI
import Charts

@available(iOS 16.0, *)
struct NutrientDetailView: View {
    let nutrient: TrackedNutrient

    @StateObject private var trackingManager = NutrientTrackingManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTimeRange: TimeRange = .thirtyDays
    @State private var showingFoodSources = false

    private var frequency: NutrientFrequency? {
        trackingManager.getFrequency(for: nutrient.id)
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.95),
                    Color(red: 0.1, green: 0.1, blue: 0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header with large ring
                    if let freq = frequency {
                        headerSection(frequency: freq)
                    }

                    // Stats cards
                    if let freq = frequency {
                        statsSection(frequency: freq)
                    }

                    // 30-day heatmap
                    if let freq = frequency {
                        heatmapSection(frequency: freq)
                    }

                    // Trend chart
                    if let freq = frequency, !freq.monthlySnapshots.isEmpty {
                        trendChartSection(frequency: freq)
                    }

                    // Top food sources
                    if let freq = frequency, !freq.topFoodSources.isEmpty {
                        foodSourcesSection(frequency: freq)
                    }

                    // Tips section
                    tipsSection
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(.white)
            }
        }
    }

    // MARK: - Header Section

    private func headerSection(frequency: NutrientFrequency) -> some View {
        VStack(spacing: 20) {
            // Large animated ring
            LargeNutrientRing(nutrient: nutrient, frequency: frequency)

            // Title
            Text(nutrient.displayName)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            // Summary text
            Text(summaryText(for: frequency))
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Stats Section

    private func statsSection(frequency: NutrientFrequency) -> some View {
        VStack(spacing: 16) {
            Text("Statistics")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Streaks
            StreakBadge(
                currentStreak: frequency.currentStreak,
                bestStreak: frequency.bestStreak,
                color: nutrient.glowColor
            )

            // Frequency card
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Frequency")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(frequency.last30DaysAppearances)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("/ \(frequency.totalLoggedDays) days")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Text("in last 30 logged days")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                // Percentage circle
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: frequency.consistencyPercentage / 100)
                        .stroke(nutrient.glowColor, lineWidth: 8)
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(frequency.consistencyPercentage))%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Material.ultraThinMaterial)
            )
        }
    }

    // MARK: - Heatmap Section

    private func heatmapSection(frequency: NutrientFrequency) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("30-Day Activity")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            NutrientHeatmap(
                nutrientId: nutrient.id,
                glowColor: nutrient.glowColor,
                dayActivities: trackingManager.dayActivities
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Material.ultraThinMaterial)
        )
    }

    // MARK: - Trend Chart Section

    private func trendChartSection(frequency: NutrientFrequency) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Consistency Trend")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Picker("Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            NutrientTrendChart(
                nutrient: nutrient,
                monthlySnapshots: frequency.monthlySnapshots,
                timeRange: selectedTimeRange
            )
            .frame(height: 200)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Material.ultraThinMaterial)
        )
    }

    // MARK: - Food Sources Section

    private func foodSourcesSection(frequency: NutrientFrequency) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Food Sources")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            ForEach(frequency.topFoodSources.prefix(5)) { source in
                FoodSourceRow(source: source, color: nutrient.glowColor)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Material.ultraThinMaterial)
        )
    }

    // MARK: - Tips Section

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Tips to Increase Intake")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            ForEach(foodTips, id: \.self) { tip in
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(nutrient.glowColor)
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)

                    Text(tip)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Helpers

    private func summaryText(for frequency: NutrientFrequency) -> String {
        let percentage = Int(frequency.consistencyPercentage)
        let days = frequency.last30DaysAppearances
        let total = frequency.totalLoggedDays

        return "\(nutrient.displayName) appeared in \(days) of your last \(total) logged days (\(percentage)% consistency)"
    }

    private var foodTips: [String] {
        let tips = NutrientDetector.nutrientFoodSources[nutrient.id] ?? []
        return Array(tips.prefix(5)).map { "Try adding \($0) to your meals" }
    }
}

// MARK: - Supporting Views

struct FoodSourceRow: View {
    let source: FoodSource
    let color: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(source.foodName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                if let brand = source.brand {
                    Text(brand)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(source.timesConsumed)x")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)

                Text(timeAgo(from: source.lastConsumed))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func timeAgo(from date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days == 0 {
            return "today"
        } else if days == 1 {
            return "yesterday"
        } else {
            return "\(days)d ago"
        }
    }
}

enum TimeRange: String, CaseIterable {
    case thirtyDays = "30D"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case year = "1Y"
}

#Preview {
    if #available(iOS 16.0, *) {
        NavigationView {
            NutrientDetailView(
                nutrient: NutrientDatabase.allNutrients[0]
            )
        }
    }
}
