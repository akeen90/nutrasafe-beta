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
    @Environment(\.colorScheme) var colorScheme
    @State private var currentDisplayDate: Date
    @State private var weeklySummary: WeeklySummary?
    @State private var isLoading = false
    @State private var expandedDays: Set<String> = []
    @State private var weeklyCache: [String: WeeklySummary] = [:]

    init(initialDate: Date, calorieGoal: Double, macroGoals: [MacroGoal], fetchWeeklySummary: @escaping (Date, Double, Double, Double, Double) async -> WeeklySummary?, setSelectedDate: @escaping (Date) -> Void) {
        self.initialDate = initialDate
        self.calorieGoal = calorieGoal
        self.macroGoals = macroGoals
        self.fetchWeeklySummary = fetchWeeklySummary
        self.setSelectedDate = setSelectedDate
        self._currentDisplayDate = State(initialValue: initialDate)
    }

    private var proteinGoal: Double {
        macroGoals.first(where: { $0.macroType == .protein })?.calculateGramGoal(from: calorieGoal) ?? 0
    }

    private var carbGoal: Double {
        macroGoals.first(where: { $0.macroType == .carbs })?.calculateGramGoal(from: calorieGoal) ?? 0
    }

    private var fatGoal: Double {
        macroGoals.first(where: { $0.macroType == .fat })?.calculateGramGoal(from: calorieGoal) ?? 0
    }

    private var weeklyCalorieGoal: Int {
        Int(calorieGoal * 7)
    }

    private var calorieProgress: Double {
        guard let summary = weeklySummary, weeklyCalorieGoal > 0 else { return 0 }
        return min(Double(summary.totalCalories) / Double(weeklyCalorieGoal), 1.0)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color(red: 0.08, green: 0.08, blue: 0.12), Color(red: 0.05, green: 0.05, blue: 0.08)]
                        : [Color(red: 0.95, green: 0.96, blue: 0.98), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if let summary = weeklySummary {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Week Navigation
                            weekNavigationBar

                            // Hero Stats Card
                            heroStatsCard(summary: summary)

                            // Macro Progress Section
                            macroProgressSection(summary: summary)

                            // Daily Breakdown
                            dailyBreakdownSection(summary: summary)

                            Spacer().frame(height: 40)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                } else if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading your week...")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Weekly Summary")
                        .font(.system(size: 17, weight: .semibold))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                }
            }
            .onAppear {
                loadWeek()
            }
        }
    }

    // MARK: - Week Navigation Bar
    private var weekNavigationBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Previous week
                Button(action: navigateToPreviousWeek) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary.opacity(0.7))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                        )
                }

                Spacer()

                // This Week button
                Button(action: navigateToThisWeek) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12, weight: .semibold))
                        Text("This Week")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }

                Spacer()

                // Next week
                Button(action: navigateToNextWeek) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary.opacity(0.7))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                        )
                }
            }

            // Week range
            Text(formatWeekRange())
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Hero Stats Card
    private func heroStatsCard(summary: WeeklySummary) -> some View {
        let calorieDifference = summary.totalCalories - weeklyCalorieGoal
        let isOverGoal = calorieDifference > 0
        let isOnTarget = abs(calorieDifference) < (weeklyCalorieGoal / 20) // Within 5%

        return VStack(spacing: 20) {
            // Calorie Ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05),
                        lineWidth: 12
                    )
                    .frame(width: 140, height: 140)

                // Progress ring
                Circle()
                    .trim(from: 0, to: calorieProgress)
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                // Center content
                VStack(spacing: 2) {
                    Text("\(summary.totalCalories)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("of \(formatNumber(weeklyCalorieGoal))")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)

                    Text("kcal")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
            .padding(.top, 8)

            // Over/Under calorie indicator
            if summary.daysLogged > 0 {
                HStack(spacing: 6) {
                    Image(systemName: isOnTarget ? "checkmark.circle.fill" : (isOverGoal ? "arrow.up.circle.fill" : "arrow.down.circle.fill"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isOnTarget ? .green : (isOverGoal ? .red : .green))

                    Text(isOnTarget ? "On target" : (isOverGoal ? "\(formatNumber(calorieDifference)) over" : "\(formatNumber(abs(calorieDifference))) under"))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(isOnTarget ? .green : (isOverGoal ? .red : .green))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill((isOnTarget ? Color.green : (isOverGoal ? Color.red : Color.green)).opacity(0.12))
                )
            }

            // Days logged badge
            HStack(spacing: 6) {
                Image(systemName: summary.daysLogged == 7 ? "checkmark.seal.fill" : "flame.fill")
                    .font(.system(size: 14))
                    .foregroundColor(summary.daysLogged == 7 ? .green : .orange)

                Text("\(summary.daysLogged) of 7 days logged")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
            )
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 20, x: 0, y: 8)
        )
    }

    // MARK: - Macro Progress Section
    private func macroProgressSection(summary: WeeklySummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Macros")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            HStack(spacing: 12) {
                macroCard(
                    name: "Protein",
                    value: Int(summary.totalProtein),
                    goal: Int(proteinGoal * 7),
                    color: Color(red: 0.95, green: 0.3, blue: 0.3),
                    icon: "bolt.fill"
                )

                macroCard(
                    name: "Carbs",
                    value: Int(summary.totalCarbs),
                    goal: Int(carbGoal * 7),
                    color: Color.orange,
                    icon: "leaf.fill"
                )

                macroCard(
                    name: "Fat",
                    value: Int(summary.totalFat),
                    goal: Int(fatGoal * 7),
                    color: Color(red: 0.95, green: 0.75, blue: 0.2),
                    icon: "drop.fill"
                )
            }
        }
    }

    private func macroCard(name: String, value: Int, goal: Int, color: Color, icon: String) -> some View {
        let progress = goal > 0 ? min(Double(value) / Double(goal), 1.0) : 0

        return VStack(spacing: 10) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)

            // Value
            Text("\(value)g")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.15))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 6)

            // Label
            Text(name)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - Daily Breakdown Section
    private func dailyBreakdownSection(summary: WeeklySummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Breakdown")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            VStack(spacing: 10) {
                ForEach(summary.dailyBreakdowns) { day in
                    ModernDayCard(
                        day: day,
                        calorieGoal: calorieGoal,
                        proteinGoal: proteinGoal,
                        carbGoal: carbGoal,
                        fatGoal: fatGoal,
                        isExpanded: expandedDays.contains(day.id.uuidString),
                        colorScheme: colorScheme
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            toggleExpanded(day.id.uuidString)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helper Functions
    private func toggleExpanded(_ dayId: String) {
        if expandedDays.contains(dayId) {
            expandedDays.remove(dayId)
        } else {
            expandedDays.insert(dayId)
        }
    }

    private func navigateToPreviousWeek() {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentDisplayDate) {
            currentDisplayDate = newDate
            loadWeek()
        }
    }

    private func navigateToNextWeek() {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDisplayDate) {
            currentDisplayDate = newDate
            loadWeek()
        }
    }

    private func navigateToThisWeek() {
        currentDisplayDate = Date()
        loadWeek()
    }

    private func getCacheKey(for date: Date) -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let daysFromMonday = (weekday == 1) ? -6 : 2 - weekday

        if let monday = calendar.date(byAdding: .day, value: daysFromMonday, to: date) {
            return DateHelper.isoDateFormatter.string(from: monday)
        }
        return "\(date.timeIntervalSince1970)"
    }

    private func loadWeek() {
        let cacheKey = getCacheKey(for: currentDisplayDate)

        if let cachedSummary = weeklyCache[cacheKey] {
            weeklySummary = cachedSummary
            return
        }

        isLoading = true
        Task {
            setSelectedDate(currentDisplayDate)

            if let summary = await fetchWeeklySummary(currentDisplayDate, calorieGoal, proteinGoal, carbGoal, fatGoal) {
                await MainActor.run {
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

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Modern Day Card
struct ModernDayCard: View {
    let day: DailyBreakdown
    let calorieGoal: Double
    let proteinGoal: Double
    let carbGoal: Double
    let fatGoal: Double
    let isExpanded: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void

    private var calorieProgress: Double {
        guard calorieGoal > 0 else { return 0 }
        return Double(day.calories) / calorieGoal
    }

    private var statusInfo: (icon: String, color: Color) {
        if !day.isLogged {
            return ("minus.circle", .secondary)
        }
        let diff = abs(Double(day.calories) - calorieGoal) / calorieGoal
        if diff < 0.1 {
            return ("checkmark.circle.fill", .green)
        } else if day.calories > Int(calorieGoal) {
            return ("arrow.up.circle.fill", .red)
        } else {
            return ("arrow.down.circle.fill", .orange)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            Button(action: onTap) {
                HStack(spacing: 14) {
                    // Day indicator
                    VStack(spacing: 2) {
                        Text(day.dayName.prefix(3).uppercased())
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)

                        Text("\(Calendar.current.component(.day, from: day.date))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(day.isLogged ? .primary : .secondary.opacity(0.5))
                    }
                    .frame(width: 44)

                    if day.isLogged {
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))

                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, Color.purple.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * min(calorieProgress, 1.0))
                            }
                        }
                        .frame(height: 12)

                        // Calories
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(spacing: 2) {
                                Text("\(day.calories)")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)

                                Text("kcal")
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                            }

                            Text("/ \(Int(calorieGoal))")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        .frame(width: 70, alignment: .trailing)

                        // Status icon
                        Image(systemName: statusInfo.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(statusInfo.color)

                        // Chevron
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.5))
                    } else {
                        Spacer()

                        Text("Not logged")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.6))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                            )
                    }
                }
                .padding(14)
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded content
            if isExpanded && day.isLogged {
                VStack(spacing: 12) {
                    Divider()
                        .padding(.horizontal, 14)

                    HStack(spacing: 16) {
                        expandedMacro(name: "Protein", value: Int(day.protein), goal: Int(proteinGoal), color: Color(red: 0.95, green: 0.3, blue: 0.3))
                        expandedMacro(name: "Carbs", value: Int(day.carbs), goal: Int(carbGoal), color: .orange)
                        expandedMacro(name: "Fat", value: Int(day.fat), goal: Int(fatGoal), color: Color(red: 0.95, green: 0.75, blue: 0.2))
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 8, x: 0, y: 2)
        )
    }

    private func expandedMacro(name: String, value: Int, goal: Int, color: Color) -> some View {
        let progress = goal > 0 ? min(Double(value) / Double(goal), 1.0) : 0

        return VStack(spacing: 6) {
            Text("\(value)g")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.15))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 4)

            Text(name)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
