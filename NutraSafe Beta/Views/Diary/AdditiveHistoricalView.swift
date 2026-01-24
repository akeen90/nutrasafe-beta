//
//  AdditiveHistoricalView.swift
//  NutraSafe Beta
//
//  Historical visualization for additive pattern analysis
//  Design: Emotion-first, minimal, trust-building
//

import SwiftUI
import Charts

// MARK: - Historical Sparkline View

struct AdditiveSparklineChart: View {
    let dailyData: [DailyAdditiveData]
    @Environment(\.colorScheme) private var colorScheme

    private var appPalette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 30 days")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundColor(appPalette.textSecondary)

            if dailyData.isEmpty {
                emptyChart
            } else {
                Chart {
                    ForEach(dailyData) { day in
                        // Stacked bars for different severities
                        if day.avoidCount > 0 {
                            BarMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("Avoid", day.avoidCount)
                            )
                            .foregroundStyle(Color.red.opacity(0.8))
                        }

                        if day.cautionCount > 0 {
                            BarMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("Caution", day.cautionCount),
                                stacking: .standard
                            )
                            .foregroundStyle(Color.orange.opacity(0.7))
                        }

                        if day.neutralCount > 0 {
                            BarMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("Neutral", day.neutralCount),
                                stacking: .standard
                            )
                            .foregroundStyle(SemanticColors.positive.opacity(0.5))
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(appPalette.textTertiary.opacity(0.2))
                        AxisTick(stroke: StrokeStyle(lineWidth: 0))
                        AxisValueLabel(format: .dateTime.day(), centered: true)
                            .font(.system(size: 10))
                            .foregroundStyle(appPalette.textTertiary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                            .foregroundStyle(appPalette.textTertiary.opacity(0.2))
                        AxisTick(stroke: StrokeStyle(lineWidth: 0))
                        AxisValueLabel()
                            .font(.system(size: 10))
                            .foregroundStyle(appPalette.textTertiary)
                    }
                }
                .frame(height: 120)
                .chartLegend(.hidden)
            }

            // Legend
            HStack(spacing: 16) {
                legendItem(color: .red, label: "Avoid")
                legendItem(color: .orange, label: "Caution")
                legendItem(color: SemanticColors.positive, label: "Neutral")
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(appPalette.tertiary.opacity(colorScheme == .dark ? 0.08 : 0.04))
        )
    }

    private var emptyChart: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar")
                .font(.system(size: 32))
                .foregroundColor(appPalette.textTertiary.opacity(0.5))

            Text("Not enough data yet")
                .font(.system(size: 13))
                .foregroundColor(appPalette.textSecondary)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(appPalette.textSecondary)
        }
    }
}

// MARK: - "Now vs Then" Comparison View

struct AdditiveComparisonView: View {
    let recentScore: Int
    let earlierScore: Int
    let trend: AdditiveTrendDirection

    @Environment(\.colorScheme) private var colorScheme

    private var appPalette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 20) {
                // Recent (7 days)
                scorePill(
                    title: "This week",
                    score: recentScore,
                    color: gradeColor(for: recentScore)
                )

                // Trend arrow
                Image(systemName: trendIcon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(trend.color)

                // Earlier (8-30 days)
                scorePill(
                    title: "Earlier",
                    score: earlierScore,
                    color: gradeColor(for: earlierScore)
                )
            }

            // Trend message
            Text(trend.rawValue)
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundColor(trend.color)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            trend.color.opacity(colorScheme == .dark ? 0.15 : 0.08),
                            trend.color.opacity(colorScheme == .dark ? 0.08 : 0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(trend.color.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func scorePill(title: String, score: Int, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(appPalette.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)

            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))

                Text("\(score)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
        }
    }

    private func gradeColor(for score: Int) -> Color {
        if score >= 70 { return SemanticColors.positive }
        if score >= 40 { return .yellow }
        return .red
    }

    private var trendIcon: String {
        switch trend {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct AdditiveHistoricalView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                AdditiveSparklineChart(dailyData: sampleData)

                AdditiveComparisonView(
                    recentScore: 85,
                    earlierScore: 65,
                    trend: .improving
                )
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .preferredColorScheme(.light)
    }

    static var sampleData: [DailyAdditiveData] {
        let calendar = Calendar.current
        return (0..<30).map { day in
            let date = calendar.date(byAdding: .day, value: -day, to: Date()) ?? Date()
            return DailyAdditiveData(
                date: date,
                avoidCount: Int.random(in: 0...2),
                cautionCount: Int.random(in: 0...3),
                neutralCount: Int.random(in: 0...5)
            )
        }.reversed()
    }
}
#endif
