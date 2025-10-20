//
//  NutrientTrendChart.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-10-20.
//  Swift Charts visualization for nutrient consistency trends
//

import SwiftUI
import Charts

@available(iOS 16.0, *)
struct NutrientTrendChart: View {
    let nutrient: TrackedNutrient
    let monthlySnapshots: [MonthlySnapshot]
    let timeRange: TimeRange

    @State private var selectedSnapshot: MonthlySnapshot?
    @State private var animateChart = false

    var body: some View {
        VStack(spacing: 0) {
            if filteredSnapshots.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("Not enough data yet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)

                    Text("Track more meals to see trends")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
            } else {
                Chart {
                    ForEach(filteredSnapshots) { snapshot in
                        // Area gradient
                        AreaMark(
                            x: .value("Month", monthLabel(for: snapshot)),
                            y: .value("Consistency", animateChart ? snapshot.consistencyPercentage : 0)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    nutrient.glowColor.opacity(0.6),
                                    nutrient.glowColor.opacity(0.1)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        // Line
                        LineMark(
                            x: .value("Month", monthLabel(for: snapshot)),
                            y: .value("Consistency", animateChart ? snapshot.consistencyPercentage : 0)
                        )
                        .foregroundStyle(nutrient.glowColor)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .symbol {
                            Circle()
                                .fill(nutrient.glowColor)
                                .frame(width: 8, height: 8)
                        }

                        // Point markers
                        PointMark(
                            x: .value("Month", monthLabel(for: snapshot)),
                            y: .value("Consistency", animateChart ? snapshot.consistencyPercentage : 0)
                        )
                        .foregroundStyle(nutrient.glowColor)
                        .symbolSize(selectedSnapshot?.id == snapshot.id ? 120 : 80)
                    }

                    // Rule mark for 70% threshold (active status)
                    RuleMark(y: .value("Target", 70))
                        .foregroundStyle(Color.green.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Active (70%)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.green.opacity(0.8))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.green.opacity(0.1))
                                )
                        }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisValueLabel()
                            .foregroundStyle(.secondary)
                            .font(.system(size: 11))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .stride(by: 25)) { value in
                        AxisGridLine()
                            .foregroundStyle(Color(.systemGray5))

                        AxisValueLabel()
                            .foregroundStyle(.secondary)
                            .font(.system(size: 11))
                    }
                }
                .chartYScale(domain: 0...100)
                .frame(height: 200)
                .padding(.top, 20)
            }

            // Selected point details
            if let selected = selectedSnapshot {
                selectedPointDetails(for: selected)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animateChart = true
            }
        }
    }

    // MARK: - Selected Point Details

    @ViewBuilder
    private func selectedPointDetails(for snapshot: MonthlySnapshot) -> some View {
        VStack(spacing: 8) {
            Divider()
                .background(Color(.systemGray4))
                .padding(.vertical, 8)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(fullMonthLabel(for: snapshot))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)

                    Text("\(snapshot.appearanceDays) of \(snapshot.totalLoggedDays) days")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(Int(snapshot.consistencyPercentage))%")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(nutrient.glowColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .padding(.top, 12)
    }

    // MARK: - Helpers

    private var filteredSnapshots: [MonthlySnapshot] {
        let now = Date()
        let calendar = Calendar.current

        let monthsToShow: Int
        switch timeRange {
        case .thirtyDays:
            monthsToShow = 1
        case .threeMonths:
            monthsToShow = 3
        case .sixMonths:
            monthsToShow = 6
        case .year:
            monthsToShow = 12
        }

        let cutoffDate = calendar.date(byAdding: .month, value: -monthsToShow, to: now)!

        return monthlySnapshots
            .filter { snapshot in
                guard let snapshotDate = calendar.date(from: DateComponents(year: snapshot.year, month: snapshot.month)) else {
                    return false
                }
                return snapshotDate >= cutoffDate
            }
            .sorted { snapshot1, snapshot2 in
                if snapshot1.year != snapshot2.year {
                    return snapshot1.year < snapshot2.year
                }
                return snapshot1.month < snapshot2.month
            }
    }

    private func monthLabel(for snapshot: MonthlySnapshot) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        guard let date = Calendar.current.date(from: DateComponents(year: snapshot.year, month: snapshot.month)) else {
            return ""
        }

        return formatter.string(from: date)
    }

    private func fullMonthLabel(for snapshot: MonthlySnapshot) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        guard let date = Calendar.current.date(from: DateComponents(year: snapshot.year, month: snapshot.month)) else {
            return ""
        }

        return formatter.string(from: date)
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        ZStack {
            Color.black

            NutrientTrendChart(
                nutrient: NutrientDatabase.allNutrients[0],
                monthlySnapshots: [
                    MonthlySnapshot(month: 7, year: 2025, appearanceDays: 15, totalLoggedDays: 28),
                    MonthlySnapshot(month: 8, year: 2025, appearanceDays: 20, totalLoggedDays: 30),
                    MonthlySnapshot(month: 9, year: 2025, appearanceDays: 22, totalLoggedDays: 28),
                    MonthlySnapshot(month: 10, year: 2025, appearanceDays: 25, totalLoggedDays: 30)
                ],
                timeRange: .threeMonths
            )
            .padding()
        }
    }
}
