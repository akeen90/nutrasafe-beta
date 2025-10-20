//
//  NutrientTimelineView.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-10-20.
//  Timeline view showing nutrient consumption over time
//

import SwiftUI
import FirebaseAuth

@available(iOS 16.0, *)
struct NutrientTimelineView: View {
    @StateObject private var trackingManager = NutrientTrackingManager.shared
    @State private var selectedDate: Date = Date()
    @State private var showingDatePicker = false

    private var sortedDates: [Date] {
        trackingManager.dayActivities.values
            .map { $0.date }
            .sorted(by: >)
    }

    private var recentDates: [Date] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<90).compactMap { daysAgo in
            calendar.date(byAdding: .day, value: -daysAgo, to: today)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with date selector
                headerSection

                // Recent 3 days highlight
                recentDaysSection

                // Timeline calendar view
                timelineCalendarSection

                // Selected day detail
                if let activity = getDayActivity(for: selectedDate) {
                    selectedDayDetailSection(activity: activity)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nutrient Timeline")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("Track your nutrient patterns over time")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    selectedDate = Date()
                }) {
                    Text("Today")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Recent 3 Days Section

    private var recentDaysSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                Text("Last 3 Days")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
            }

            VStack(spacing: 12) {
                ForEach(0..<3) { daysAgo in
                    if let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) {
                        RecentDayCard(
                            date: date,
                            activity: getDayActivity(for: date),
                            isToday: daysAgo == 0,
                            onTap: {
                                selectedDate = date
                                withAnimation {
                                    // Scroll will happen automatically
                                }
                            }
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Timeline Calendar Section

    private var timelineCalendarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.purple)
                Text("History")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                Text("Tap any day")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            // Month-by-month grid
            LazyVStack(spacing: 20) {
                ForEach(groupedByMonth(), id: \.0) { monthKey, dates in
                    MonthSection(
                        monthKey: monthKey,
                        dates: dates,
                        selectedDate: $selectedDate,
                        getDayActivity: getDayActivity
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Selected Day Detail Section

    private func selectedDayDetailSection(activity: DayNutrientActivity) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.green)
                Text(formatDate(activity.date))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                Text("\(activity.nutrientsPresent.count) nutrients")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.2))
                    )
            }

            if !activity.nutrientsPresent.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(activity.nutrientsPresent, id: \.self) { nutrientId in
                        if let nutrient = NutrientDatabase.allNutrients.first(where: { $0.id == nutrientId }) {
                            NutrientBadge(nutrient: nutrient)
                        }
                    }
                }
            } else {
                Text("No nutrient data for this day")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Helper Methods

    private func getDayActivity(for date: Date) -> DayNutrientActivity? {
        let dateId = formatDateId(date)
        return trackingManager.dayActivities[dateId]
    }

    private func formatDateId(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func groupedByMonth() -> [(String, [Date])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: recentDates) { date in
            let components = calendar.dateComponents([.year, .month], from: date)
            return "\(components.year!)-\(String(format: "%02d", components.month!))"
        }

        return grouped.sorted { $0.key > $1.key }.map { ($0.key, $0.value.sorted(by: >)) }
    }
}

// MARK: - Supporting Views

struct RecentDayCard: View {
    let date: Date
    let activity: DayNutrientActivity?
    let isToday: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dayLabel)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isToday ? .blue : .primary)

                    Text(formatDate(date))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let activity = activity {
                    VStack(spacing: 4) {
                        Text("\(activity.nutrientsPresent.count)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.green)

                        Text("nutrients")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                    )
                } else {
                    Text("No data")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                        )
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isToday ? Color.blue.opacity(0.05) : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var dayLabel: String {
        if isToday {
            return "Today"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

struct MonthSection: View {
    let monthKey: String
    let dates: [Date]
    @Binding var selectedDate: Date
    let getDayActivity: (Date) -> DayNutrientActivity?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(monthTitle)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                ForEach(dates, id: \.self) { date in
                    DayCell(
                        date: date,
                        activity: getDayActivity(date),
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        onTap: {
                            selectedDate = date
                        }
                    )
                }
            }
        }
    }

    private var monthTitle: String {
        let components = monthKey.split(separator: "-")
        guard components.count == 2,
              let year = Int(components[0]),
              let month = Int(components[1]) else {
            return monthKey
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: year, month: month))!
        return formatter.string(from: date)
    }
}

struct DayCell: View {
    let date: Date
    let activity: DayNutrientActivity?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(dayNumber)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .white : .primary)

                Circle()
                    .fill(activityColor)
                    .frame(width: 6, height: 6)
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(activityColor.opacity(0.3), lineWidth: activity != nil ? 2 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var activityColor: Color {
        guard let activity = activity else { return .gray }

        let count = activity.nutrientsPresent.count
        if count >= 15 {
            return .green
        } else if count >= 10 {
            return .yellow
        } else if count >= 5 {
            return .orange
        } else {
            return .red
        }
    }
}

struct NutrientBadge: View {
    let nutrient: TrackedNutrient

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: nutrient.icon)
                .font(.system(size: 14))
                .foregroundColor(nutrient.glowColor)

            Text(nutrient.displayName)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(nutrient.glowColor.opacity(0.1))
        )
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        NavigationView {
            NutrientTimelineView()
        }
    }
}
