//
//  WeeklySummarySheet.swift
//  NutraSafe Beta
//
//  Modern weekly nutrition summary with expandable days and week navigation
//

import SwiftUI

struct WeeklySummarySheet: View {
    let initialDate: Date
    let calorieGoal: Double
    let macroGoals: [MacroGoal]
    let fetchWeeklySummary: (Date, Double, Double, Double, Double) async -> WeeklySummary?
    let setSelectedDate: (Date) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var currentDisplayDate: Date // The date for the currently displayed week
    @State private var weeklySummary: WeeklySummary?
    @State private var isLoading = false
    @State private var expandedDays: Set<String> = [] // Track which days are expanded
    @State private var weeklyCache: [String: WeeklySummary] = [:] // Cache for loaded weeks

    init(initialDate: Date, calorieGoal: Double, macroGoals: [MacroGoal], fetchWeeklySummary: @escaping (Date, Double, Double, Double, Double) async -> WeeklySummary?, setSelectedDate: @escaping (Date) -> Void) {
        self.initialDate = initialDate
        self.calorieGoal = calorieGoal
        self.macroGoals = macroGoals
        self.fetchWeeklySummary = fetchWeeklySummary
        self.setSelectedDate = setSelectedDate
        self._currentDisplayDate = State(initialValue: initialDate)
    }

    // Computed properties for backwards compatibility with existing UI
    private var proteinGoal: Double {
        if let proteinMacro = macroGoals.first(where: { $0.macroType == .protein }) {
            return proteinMacro.calculateGramGoal(from: calorieGoal)
        }
        return 0
    }

    private var carbGoal: Double {
        if let carbMacro = macroGoals.first(where: { $0.macroType == .carbs }) {
            return carbMacro.calculateGramGoal(from: calorieGoal)
        }
        return 0
    }

    private var fatGoal: Double {
        if let fatMacro = macroGoals.first(where: { $0.macroType == .fat }) {
            return fatMacro.calculateGramGoal(from: calorieGoal)
        }
        return 0
    }

    var body: some View {
        NavigationView {
            ZStack {
                if let summary = weeklySummary {
                    ScrollView {
                        VStack(spacing: 20) {
                            // MARK: - Week Navigation
                            HStack(spacing: 12) {
                                // Previous (arrow-only pill)
                                Button(action: {
                                    navigateToPreviousWeek()
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                }
                                .foregroundColor(.blue)
                                .frame(height: 40)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                                )

                                // This Week (filled pill)
                                Button(action: {
                                    navigateToThisWeek()
                                }) {
                                    Text("This Week")
                                        .font(.system(size: 15, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                }
                                .foregroundColor(.white)
                                .frame(height: 40)
                                .background(Color.blue)
                                .clipShape(Capsule())
                                .shadow(color: Color.blue.opacity(0.25), radius: 6, x: 0, y: 3)

                                // Next (arrow-only pill)
                                Button(action: {
                                    navigateToNextWeek()
                                }) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                }
                                .foregroundColor(.blue)
                                .frame(height: 40)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                                )
                            }
                            .padding(.top, 8)

                            // Week range label
                            if let _ = weeklySummary {
                                Text(formatWeekRange())
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }

                            // MARK: - Weekly Summary Card
                            VStack(spacing: 16) {
                                VStack(spacing: 4) {
                                    Text("\(summary.totalCalories)")
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)

                                    Text("Total Calories")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.secondary)
                                }

                                HStack(spacing: 32) {
                                    MacroSummaryView(
                                        value: Int(summary.totalProtein),
                                        label: "Protein",
                                        color: .red
                                    )

                                    MacroSummaryView(
                                        value: Int(summary.totalCarbs),
                                        label: "Carbs",
                                        color: .orange
                                    )

                                    MacroSummaryView(
                                        value: Int(summary.totalFat),
                                        label: "Fat",
                                        color: .yellow
                                    )
                                }

                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)

                                    Text("\(summary.daysLogged) of 7 days logged")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                            }
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppColors.cardBackgroundElevated)
                            )
                            .cardShadow()

                            // MARK: - Daily List (Expandable)
                            VStack(spacing: 10) {
                                ForEach(summary.dailyBreakdowns) { day in
                                    ExpandableDayCard(
                                        day: day,
                                        calorieGoal: calorieGoal,
                                        proteinGoal: proteinGoal,
                                        carbGoal: carbGoal,
                                        fatGoal: fatGoal,
                                        isExpanded: expandedDays.contains(day.id.uuidString)
                                    ) {
                                        toggleExpanded(day.id.uuidString)
                                    }
                                }
                            }
                            .padding(.bottom, 24)
                        }
                        .padding(.horizontal, 16)
                    }
                } else if isLoading {
                    ProgressView("Loading...")
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .navigationTitle("Weekly Summary")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
                }
            }
            .onAppear {
                loadWeek()
            }
        }
    }

    private func toggleExpanded(_ dayId: String) {
        if expandedDays.contains(dayId) {
            expandedDays.remove(dayId)
        } else {
            expandedDays.insert(dayId)
        }
    }

    private func navigateToPreviousWeek() {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .weekOfYear, value: -1, to: currentDisplayDate) {
            currentDisplayDate = newDate
            loadWeek()
        }
    }

    private func navigateToNextWeek() {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDisplayDate) {
            currentDisplayDate = newDate
            loadWeek()
        }
    }

    private func navigateToThisWeek() {
        currentDisplayDate = Date() // Always jump to today's date
        loadWeek()
    }

    private func getCacheKey(for date: Date) -> String {
        // Use the Monday of the week as the cache key (consistent for all dates in the same week)
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let daysFromMonday = (weekday == 1) ? -6 : 2 - weekday

        if let monday = calendar.date(byAdding: .day, value: daysFromMonday, to: date) {
            // PERFORMANCE: Use cached static formatter
            return DateHelper.isoDateFormatter.string(from: monday)
        }

        return "\(date.timeIntervalSince1970)" // Fallback
    }

    private func loadWeek() {
        let cacheKey = getCacheKey(for: currentDisplayDate)

        // Check cache first
        if let cachedSummary = weeklyCache[cacheKey] {
            weeklySummary = cachedSummary
            return
        }

        // Not in cache, fetch from Firebase
        isLoading = true
        Task {
            // Update parent-selected date
            setSelectedDate(currentDisplayDate)

            if let summary = await fetchWeeklySummary(currentDisplayDate, calorieGoal, proteinGoal, carbGoal, fatGoal) {
                await MainActor.run {
                    // Store in cache
                    weeklyCache[cacheKey] = summary
                    weeklySummary = summary
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }

    private func formatWeekRange() -> String {
        guard let summary = weeklySummary else { return "" }

        // PERFORMANCE: Use cached static formatters
        let startStr = DateHelper.monthDayFormatter.string(from: summary.weekStartDate)

        let calendar = Calendar.current
        let startMonth = calendar.component(.month, from: summary.weekStartDate)
        let endMonth = calendar.component(.month, from: summary.weekEndDate)

        if startMonth == endMonth {
            return "\(startStr) - \(DateHelper.dayNumberFormatter.string(from: summary.weekEndDate))"
        } else {
            let endStr = DateHelper.monthDayFormatter.string(from: summary.weekEndDate)
            return "\(startStr) - \(endStr)"
        }
    }
}

// MARK: - Macro Summary View
struct MacroSummaryView: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text("\(label)")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)

            Text("g")
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundColor(.secondary.opacity(0.6))
        }
    }
}

// MARK: - Expandable Day Card
struct ExpandableDayCard: View {
    let day: DailyBreakdown
    let calorieGoal: Double
    let proteinGoal: Double
    let carbGoal: Double
    let fatGoal: Double
    let isExpanded: Bool
    let onTap: () -> Void

    private var caloriePercentage: Double {
        guard calorieGoal > 0 else { return 0 }
        return Double(day.calories) / calorieGoal
    }

    private var calorieStatusColor: Color {
        let diff = abs(Double(day.calories) - calorieGoal) / calorieGoal
        if diff < 0.05 {
            return .green
        } else if day.calories > Int(calorieGoal) {
            return .red
        } else {
            return .orange
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Collapsed View (Always Visible)
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Day info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(day.dayName)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text(day.shortDateString)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if day.isLogged {
                        // Calorie info
                        HStack(spacing: 8) {
                            VStack(alignment: .trailing, spacing: 2) {
                                HStack(spacing: 4) {
                                    Text("\(day.calories)")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)

                                    Text("/")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.secondary.opacity(0.5))

                                    Text("\(Int(calorieGoal))")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                }

                                Text("calories")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                            }

                            // Status icon
                            Image(systemName: caloriePercentage > 0.95 && caloriePercentage < 1.05 ? "checkmark.circle.fill" : (day.calories > Int(calorieGoal) ? "arrow.up.circle.fill" : "arrow.down.circle.fill"))
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(calorieStatusColor)
                        }

                        // Expand chevron
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    } else {
                        Text("Not Logged")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())

            // MARK: - Expanded View (Macros)
            if isExpanded && day.isLogged {
                VStack(spacing: 8) {
                    Divider()
                        .padding(.horizontal, 16)

                    VStack(spacing: 8) {
                        NutrientRow(
                            name: "Protein",
                            current: Int(day.protein),
                            goal: Int(proteinGoal),
                            unit: "g",
                            color: .red
                        )

                        NutrientRow(
                            name: "Carbs",
                            current: Int(day.carbs),
                            goal: Int(carbGoal),
                            unit: "g",
                            color: .orange
                        )

                        NutrientRow(
                            name: "Fat",
                            current: Int(day.fat),
                            goal: Int(fatGoal),
                            unit: "g",
                            color: .yellow
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackgroundElevated)
        )
        .cardShadow()
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

// MARK: - Nutrient Row
struct NutrientRow: View {
    let name: String
    let current: Int
    let goal: Int
    let unit: String
    let color: Color

    private var percentage: Double {
        guard goal > 0 else { return 0 }
        return Double(current) / Double(goal)
    }

    private var isOverGoal: Bool {
        current > goal
    }

    private var isOnTarget: Bool {
        let diff = abs(Double(current) - Double(goal)) / Double(goal)
        return diff < 0.05
    }

    private var statusColor: Color {
        if isOnTarget {
            return .green
        } else if isOverGoal {
            return .red
        } else {
            return .orange
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text(name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 65, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: min(geometry.size.width * CGFloat(percentage), geometry.size.width), height: 6)
                }
            }
            .frame(height: 6)

            HStack(spacing: 4) {
                Text("\(current)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("/")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary.opacity(0.5))

                Text("\(goal)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, alignment: .trailing)

            Image(systemName: isOnTarget ? "checkmark.circle.fill" : (isOverGoal ? "arrow.up.circle.fill" : "arrow.down.circle.fill"))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(statusColor)
                .frame(width: 20)
        }
    }
}
