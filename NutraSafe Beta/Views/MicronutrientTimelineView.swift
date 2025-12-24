//
//  MicronutrientTimelineView.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-10-21.
//  30-day timeline view for micronutrient tracking
//

import SwiftUI

@available(iOS 16.0, *)
struct MicronutrientTimelineView: View {
    @StateObject private var trackingManager = MicronutrientTrackingManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedNutrient: String?
    @State private var nutrientSummaries: [MicronutrientSummary] = []

    private var last30Days: [Date] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<30).compactMap { daysAgo in
            calendar.date(byAdding: .day, value: -daysAgo, to: today)
        }.reversed()
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Individual nutrient timelines
                    nutrientTimelinesSection
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("30-Day Timeline")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                nutrientSummaries = await trackingManager.getAllNutrientSummaries()
            }
        }
    }

    // MARK: - Balance History Chart

    private var balanceHistoryChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                Text("Nutrient Diversity Score")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
            }

            Text("Number of different nutrients tracked each day")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            // Chart
            GeometryReader { geometry in
                let balanceHistory = trackingManager.balanceHistory
                    .sorted { $0.date < $1.date }
                    .suffix(30)

                if !balanceHistory.isEmpty {
                    let maxNutrients = balanceHistory.map { $0.totalNutrientsTracked }.max() ?? 1

                    ZStack(alignment: .bottomLeading) {
                        // Grid lines
                        VStack(spacing: 0) {
                            ForEach(0..<5) { i in
                                HStack {
                                    let value = maxNutrients - (i * maxNutrients / 4)
                                    Text("\(value)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .frame(width: 40, alignment: .trailing)

                                    Rectangle()
                                        .fill(Color(.systemGray5))
                                        .frame(height: 1)

                                    Spacer()
                                }
                            }
                        }

                        // Line chart
                        Path { path in
                            let maxHeight = geometry.size.height - 20
                            let maxWidth = geometry.size.width - 50
                            let xStep = maxWidth / CGFloat(max(1, balanceHistory.count - 1))

                            for (index, balance) in balanceHistory.enumerated() {
                                let x = 50 + CGFloat(index) * xStep
                                let y = maxHeight - (CGFloat(balance.totalNutrientsTracked) / CGFloat(maxNutrients) * maxHeight)

                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.green, lineWidth: 2)
                        .shadow(color: Color.green.opacity(0.3), radius: 4, x: 0, y: 2)

                        // Data points
                        ForEach(Array(balanceHistory.enumerated()), id: \.offset) { index, balance in
                            let maxHeight = geometry.size.height - 20
                            let maxWidth = geometry.size.width - 50
                            let xStep = maxWidth / CGFloat(max(1, balanceHistory.count - 1))
                            let x = 50 + CGFloat(index) * xStep
                            let y = maxHeight - (CGFloat(balance.totalNutrientsTracked) / CGFloat(maxNutrients) * maxHeight)

                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                                .position(x: x, y: y)
                        }
                    }
                    .frame(height: 200)
                } else {
                    Text("Start logging meals to see your nutrient diversity")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(height: 200)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Nutrient Timelines

    private var nutrientTimelinesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(.blue)
                Text("Individual Nutrients")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
            }

            if nutrientSummaries.isEmpty {
                Text("Start logging meals to see nutrient timelines")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                    )
            } else {
                VStack(spacing: 12) {
                    ForEach(nutrientSummaries) { summary in
                        nutrientTimelineRow(summary: summary)
                    }
                }
            }
        }
    }

    private func nutrientTimelineRow(summary: MicronutrientSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(summary.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(summary.todayStatus.label)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(summary.todayStatus.color)

                        if summary.trend != .stable {
                            Text(summary.trend.symbol)
                                .font(.system(size: 14))
                                .foregroundColor(summary.trend.color)
                        }
                    }

                    Text("7-day: \(summary.sevenDayStatus.label)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            // 30-day activity bar
            HStack(spacing: 2) {
                ForEach(last30Days, id: \.self) { date in
                    let dateKey = formatDateId(date)
                    let score = trackingManager.dailyScores[summary.nutrient]?.first { formatDateId($0.date) == dateKey }

                    Rectangle()
                        .fill(score != nil ? summary.todayStatus.color.opacity(0.8) : Color(.systemGray5))
                        .frame(height: 20)
                        .cornerRadius(2)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }

    private func formatDateId(_ date: Date) -> String {
        // PERFORMANCE: Use cached static formatter
        DateHelper.isoDateFormatter.string(from: date)
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        MicronutrientTimelineView()
    }
}
