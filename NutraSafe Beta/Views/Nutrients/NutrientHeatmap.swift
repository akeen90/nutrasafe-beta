//
//  NutrientHeatmap.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-10-20.
//  30-day heatmap visualization for nutrient activity
//

import SwiftUI

struct NutrientHeatmap: View {
    let nutrientId: String
    let glowColor: Color
    let dayActivities: [String: DayNutrientActivity]

    @State private var animateCells = false

    private let columns = 7
    private let spacing: CGFloat = 6

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Day labels
            HStack(spacing: spacing) {
                ForEach(dayLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns), spacing: spacing) {
                ForEach(last30Days, id: \.self) { date in
                    HeatmapCell(
                        date: date,
                        hasNutrient: hasNutrient(on: date),
                        color: glowColor,
                        isToday: Calendar.current.isDateInToday(date),
                        animate: animateCells
                    )
                }
            }

            // Legend
            HStack(spacing: 16) {
                LegendItem(color: Color.white.opacity(0.1), label: "No data")
                LegendItem(color: glowColor.opacity(0.3), label: "Not present")
                LegendItem(color: glowColor, label: "Present")
            }
            .font(.system(size: 11))
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
                animateCells = true
            }
        }
    }

    // MARK: - Helpers

    private var last30Days: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<30).reversed().compactMap { daysAgo in
            calendar.date(byAdding: .day, value: -daysAgo, to: today)
        }
    }

    private var dayLabels: [String] {
        ["S", "M", "T", "W", "T", "F", "S"]
    }

    private func hasNutrient(on date: Date) -> Bool? {
        let dateId = formatDateId(date)
        guard let activity = dayActivities[dateId] else { return nil }
        return activity.nutrientsPresent.contains(nutrientId)
    }

    private func formatDateId(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct HeatmapCell: View {
    let date: Date
    let hasNutrient: Bool?
    let color: Color
    let isToday: Bool
    let animate: Bool

    @State private var scale: CGFloat = 0.5

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(cellColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isToday ? Color.white : Color.clear, lineWidth: 2)
                )
                .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 0)

            if isToday {
                Circle()
                    .fill(Color.white)
                    .frame(width: 4, height: 4)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .scaleEffect(animate ? 1.0 : scale)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
            }
        }
    }

    private var cellColor: Color {
        guard let hasNutrient = hasNutrient else {
            return Color.white.opacity(0.1) // No data
        }

        if hasNutrient {
            return color // Nutrient present
        } else {
            return color.opacity(0.3) // Logged but no nutrient
        }
    }

    private var shadowColor: Color {
        guard let hasNutrient = hasNutrient, hasNutrient else {
            return Color.clear
        }
        return color.opacity(0.4)
    }

    private var shadowRadius: CGFloat {
        guard let hasNutrient = hasNutrient, hasNutrient else {
            return 0
        }
        return 4
    }
}

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 12, height: 12)

            Text(label)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

#Preview {
    ZStack {
        Color.black
        NutrientHeatmap(
            nutrientId: "vitamin_c",
            glowColor: .orange,
            dayActivities: [:]
        )
        .padding()
    }
}
