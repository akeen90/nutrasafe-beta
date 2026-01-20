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
    @State private var showingCalendarPicker = false
    @State private var displayedMonth: Date = Date()
    @State private var datesWithEntries: Set<Date> = []
    @State private var isLoadingCalendarEntries = false

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
                // Previous week/month
                Button(action: {
                    if showingCalendarPicker {
                        displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                    } else {
                        navigateToPreviousWeek()
                    }
                }) {
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

                // Calendar toggle button
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showingCalendarPicker.toggle()
                        if showingCalendarPicker {
                            displayedMonth = currentDisplayDate
                            loadDatesWithEntries()
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: showingCalendarPicker ? "calendar.circle.fill" : "calendar")
                            .font(.system(size: 12, weight: .semibold))
                        Text(showingCalendarPicker ? "Close" : "Pick Week")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: showingCalendarPicker ? [Color.gray, Color.gray.opacity(0.8)] : [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: (showingCalendarPicker ? Color.gray : Color.blue).opacity(0.3), radius: 8, x: 0, y: 4)
                }

                Spacer()

                // Next week/month
                Button(action: {
                    if showingCalendarPicker {
                        displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                    } else {
                        navigateToNextWeek()
                    }
                }) {
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

            // Week range or month/year when calendar is shown
            if showingCalendarPicker {
                Text(formatMonthYear(displayedMonth))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            } else {
                Text(formatWeekRange())
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }

            // Calendar picker section
            if showingCalendarPicker {
                calendarPickerSection
            }
        }
    }

    // MARK: - Calendar Picker Section
    @ViewBuilder
    private var calendarPickerSection: some View {
        VStack(spacing: 0) {
            // Day of week headers
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Calendar grid
            calendarGrid
                .padding(.bottom, 12)

            // This Week button
            Button(action: {
                navigateToThisWeek()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showingCalendarPicker = false
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 12, weight: .semibold))
                    Text("This Week")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.blue.opacity(0.12))
                )
            }
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 12, x: 0, y: 4)
        )
        .onChange(of: displayedMonth) {
            loadDatesWithEntries()
        }
    }

    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else {
            return AnyView(EmptyView())
        }

        let weekdayOfFirst = calendar.component(.weekday, from: monthStart)
        let firstWeekdayOffset = weekdayOfFirst - 1
        let daysInMonth = calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
        let totalCells = firstWeekdayOffset + daysInMonth

        return AnyView(
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                ForEach(0..<totalCells, id: \.self) { index in
                    if index < firstWeekdayOffset {
                        Color.clear
                            .frame(height: 44)
                    } else {
                        let day = index - firstWeekdayOffset + 1
                        if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                            calendarDayCell(date: date, day: day)
                        }
                    }
                }
            }
        )
    }

    // MARK: - Calendar Day Cell
    private func calendarDayCell(date: Date, day: Int) -> some View {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)
        let isInSelectedWeek = isDateInCurrentWeek(date)
        let hasEntries = datesWithEntries.contains(where: { calendar.isDate($0, inSameDayAs: date) })
        let isFuture = date > Date()

        return Button(action: {
            // Select the week containing this date
            currentDisplayDate = date
            displayedMonth = date
            loadWeek()

            // Close calendar after selection
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showingCalendarPicker = false
                }
            }
        }) {
            VStack(spacing: 2) {
                // Day number
                ZStack {
                    if isInSelectedWeek {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 32, height: 32)
                    }

                    if isToday {
                        Circle()
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(width: 28, height: 28)
                    }

                    Text("\(day)")
                        .font(.system(size: 16, weight: isToday || isInSelectedWeek ? .bold : .regular))
                        .foregroundColor(
                            isFuture ? .secondary.opacity(0.5) :
                            isInSelectedWeek ? .blue :
                            .primary
                        )
                }

                // Entry indicator dot
                if hasEntries && !isFuture {
                    Circle()
                        .fill(isInSelectedWeek ? Color.blue : Color.green)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isFuture)
    }

    // MARK: - Check if date is in current selected week
    private func isDateInCurrentWeek(_ date: Date) -> Bool {
        let calendar = Calendar.current

        // Get the Monday of the week containing currentDisplayDate
        let weekday = calendar.component(.weekday, from: currentDisplayDate)
        let daysFromMonday = (weekday == 1) ? -6 : 2 - weekday

        guard let monday = calendar.date(byAdding: .day, value: daysFromMonday, to: currentDisplayDate),
              let sunday = calendar.date(byAdding: .day, value: 6, to: monday) else {
            return false
        }

        let startOfMonday = calendar.startOfDay(for: monday)
        let endOfSunday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: sunday) ?? sunday

        return date >= startOfMonday && date <= endOfSunday
    }

    // MARK: - Load Dates With Entries
    private func loadDatesWithEntries() {
        guard !isLoadingCalendarEntries else { return }
        isLoadingCalendarEntries = true

        Task {
            let calendar = Calendar.current
            guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)),
                  let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart),
                  let monthEndWithTime = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: monthEnd) else {
                await MainActor.run {
                    isLoadingCalendarEntries = false
                }
                return
            }

            do {
                let entries = try await FirebaseManager.shared.getFoodEntriesInRange(from: monthStart, to: monthEndWithTime)

                var dates = Set<Date>()
                for entry in entries {
                    let startOfDay = calendar.startOfDay(for: entry.date)
                    dates.insert(startOfDay)
                }

                await MainActor.run {
                    datesWithEntries = dates
                    isLoadingCalendarEntries = false
                }
            } catch {
                await MainActor.run {
                    isLoadingCalendarEntries = false
                }
            }
        }
    }

    // MARK: - Format Month Year
    private func formatMonthYear(_ date: Date) -> String {
        DateHelper.fullMonthYearFormatter.string(from: date)
    }

    // MARK: - Hero Stats Card
    private func heroStatsCard(summary: WeeklySummary) -> some View {
        let calorieDifference = summary.totalCalories - weeklyCalorieGoal
        let percentDiff = weeklyCalorieGoal > 0 ? Double(calorieDifference) / Double(weeklyCalorieGoal) : 0

        // Healthier status calculation - doesn't celebrate extreme restriction
        // Based on psychology research: avoid reinforcing restrictive eating patterns
        let calorieStatus = getHealthyCalorieStatus(percentDiff: percentDiff, difference: calorieDifference, daysLogged: summary.daysLogged)

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

            // Healthy calorie status indicator
            if summary.daysLogged > 0 {
                HStack(spacing: 6) {
                    Image(systemName: calorieStatus.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(calorieStatus.color)

                    Text(calorieStatus.message)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(calorieStatus.color)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(calorieStatus.color.opacity(0.12))
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
        let difference = value - goal
        let isOver = difference > 0
        let isOnTarget = goal > 0 && abs(Double(difference) / Double(goal)) < 0.05 // Within 5%

        return VStack(spacing: 8) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)

            // Value
            Text("\(value)g")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            // Goal text
            Text("of \(goal)g goal")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)

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

            // Over/Under indicator
            if goal > 0 {
                Text(isOnTarget ? "On target" : (isOver ? "\(difference)g over" : "\(abs(difference))g under"))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(isOnTarget ? .green : (isOver ? .red : .green))
            }

            // Label
            Text(name)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
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

    // MARK: - Healthy Calorie Status
    // Psychology-informed messaging that doesn't reinforce restrictive eating patterns
    // Based on research showing calorie apps can contribute to eating disorder symptoms
    private func getHealthyCalorieStatus(percentDiff: Double, difference: Int, daysLogged: Int) -> (message: String, icon: String, color: Color) {
        // Calculate expected progress based on days logged
        // If 2 of 7 days logged, we expect ~28% of weekly calories consumed
        let expectedProgress = Double(daysLogged) / 7.0

        // Calculate what the difference SHOULD be at this point in the week
        // e.g., on day 2, being 5/7 "under" the WEEKLY goal is perfectly normal
        let expectedCaloriesAtThisPoint = Double(weeklyCalorieGoal) * expectedProgress
        let actualVsExpected = expectedCaloriesAtThisPoint > 0
            ? (Double(weeklyCalorieGoal) + Double(difference)) / expectedCaloriesAtThisPoint
            : 1.0

        // Full week completed (7 days logged) - show actual totals
        if daysLogged == 7 {
            let absDiff = abs(difference)
            if abs(percentDiff) < 0.05 {
                // Within 5% - on target
                return ("On track", "checkmark.circle.fill", .green)
            } else if difference < 0 {
                // Under - show number but don't celebrate extreme deficits
                if percentDiff < -0.20 {
                    // More than 20% under - concerning
                    return ("\(formatNumber(absDiff)) under", "arrow.down.circle.fill", .orange)
                } else {
                    return ("\(formatNumber(absDiff)) under", "arrow.down.circle.fill", .green)
                }
            } else {
                // Over
                if percentDiff > 0.15 {
                    return ("\(formatNumber(difference)) over", "arrow.up.circle.fill", .red)
                } else {
                    return ("\(formatNumber(difference)) over", "arrow.up.circle.fill", .orange)
                }
            }
        }

        // Partial week - compare against expected progress
        // actualVsExpected: 1.0 = exactly on pace, <1.0 = behind pace, >1.0 = ahead of pace
        if actualVsExpected >= 0.85 && actualVsExpected <= 1.15 {
            // Within 15% of expected pace - on track
            return ("On track", "checkmark.circle.fill", .green)
        } else if actualVsExpected < 0.85 {
            // Behind pace - but don't celebrate restriction
            if actualVsExpected < 0.60 {
                // Significantly behind - concerning
                return ("Below pace", "exclamationmark.circle.fill", .orange)
            } else {
                return ("Under pace", "arrow.down.circle.fill", .blue)
            }
        } else {
            // Ahead of pace
            if actualVsExpected > 1.30 {
                return ("Over pace", "arrow.up.circle.fill", .red)
            } else {
                return ("Slightly ahead", "arrow.up.circle.fill", .orange)
            }
        }
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

    private var calorieStatus: (text: String, color: Color, isOnTarget: Bool) {
        if !day.isLogged {
            return ("–", .secondary, false)
        }
        let diff = day.calories - Int(calorieGoal)
        let percentDiff = abs(Double(diff)) / calorieGoal
        if percentDiff < 0.05 {
            // Within 5% of goal - on target
            return ("On target", .green, true)
        } else if diff > 0 {
            // Over goal - red
            return ("+\(diff)", .red, false)
        } else {
            // Under goal - green
            return ("\(diff)", .green, false)
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

                        // Calorie difference indicator
                        Text(calorieStatus.text)
                            .font(.system(size: calorieStatus.isOnTarget ? 10 : 12, weight: .bold, design: .rounded))
                            .foregroundColor(calorieStatus.color)
                            .frame(minWidth: 50, alignment: .trailing)

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
