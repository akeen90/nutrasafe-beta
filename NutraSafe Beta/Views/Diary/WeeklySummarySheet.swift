//
//  WeeklySummarySheet.swift
//  NutraSafe Beta
//
//  Premium weekly summary with emotion-first design
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
    @State private var navButtonPressed: String? = nil

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

    // MARK: - Emotion-First Messaging
    private var weeklyInsightMessage: String {
        guard let summary = weeklySummary else { return "" }
        let progress = calorieProgress
        let daysLogged = summary.daysLogged

        if daysLogged == 0 {
            return "A fresh week ahead. Every meal is an opportunity."
        } else if daysLogged < 3 {
            if progress < 0.4 {
                return "You're building momentum. Keep going."
            } else {
                return "Great start to your week."
            }
        } else if daysLogged < 6 {
            if progress < 0.85 {
                return "Steady progress. You're finding your rhythm."
            } else if progress <= 1.05 {
                return "Balanced and consistent. Well done."
            } else {
                return "A little over, but awareness is what matters."
            }
        } else {
            if progress < 0.85 {
                return "You stayed mindful all week."
            } else if progress <= 1.05 {
                return "A week of balance. Be proud."
            } else {
                return "You showed up every day. That's what counts."
            }
        }
    }

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Adaptive background
                backgroundGradient
                    .ignoresSafeArea()

                if let summary = weeklySummary {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Emotional headline
                            weeklyHeadlineSection

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
                        .padding(.top, 16)
                    }
                } else if isLoading {
                    loadingState
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Your Week")
                        .font(.system(size: 17, weight: .semibold, design: .serif))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(palette.accent)
                }
            }
            .onAppear {
                loadWeek()
            }
        }
    }

    // MARK: - Background Gradient
    private var backgroundGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(red: 0.08, green: 0.08, blue: 0.10), Color(red: 0.05, green: 0.05, blue: 0.07)]
                : [palette.background.opacity(0.3), Color.white],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Loading State
    private var loadingState: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(palette.accent)

            Text("Gathering your week...")
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundColor(.secondary)

            Text("Understanding your patterns")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.secondary.opacity(0.7))
        }
    }

    // MARK: - Weekly Headline Section
    private var weeklyHeadlineSection: some View {
        VStack(spacing: 8) {
            Text(weeklyInsightMessage)
                .font(.system(size: 20, weight: .medium, design: .serif))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, 8)
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
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary.opacity(0.7))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                        )
                }
                .scaleEffect(navButtonPressed == "prev" ? 0.95 : 1.0)
                .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                    navButtonPressed = pressing ? "prev" : nil
                }, perform: {})

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
                        Image(systemName: showingCalendarPicker ? "xmark" : "calendar")
                            .font(.system(size: 12, weight: .semibold))
                        Text(showingCalendarPicker ? "Close" : "Jump to week")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: showingCalendarPicker
                                        ? [Color.secondary.opacity(0.6), Color.secondary.opacity(0.4)]
                                        : [palette.accent, palette.accent.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: (showingCalendarPicker ? Color.clear : palette.accent).opacity(0.25), radius: 8, x: 0, y: 4)
                }
                .scaleEffect(navButtonPressed == "calendar" ? 0.97 : 1.0)
                .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                    navButtonPressed = pressing ? "calendar" : nil
                }, perform: {})

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
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary.opacity(0.7))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                        )
                }
                .scaleEffect(navButtonPressed == "next" ? 0.95 : 1.0)
                .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                    navButtonPressed = pressing ? "next" : nil
                }, perform: {})
            }

            // Week range or month/year when calendar is shown
            if showingCalendarPicker {
                Text(formatMonthYear(displayedMonth))
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundColor(.primary)
            } else {
                Text(formatWeekRange())
                    .font(.system(size: 14, weight: .medium))
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

            // Back to current week button
            Button(action: {
                navigateToThisWeek()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showingCalendarPicker = false
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Back to this week")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(palette.accent)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(palette.accent.opacity(0.10))
                )
            }
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.06), radius: 12, x: 0, y: 4)
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
                            .fill(palette.accent.opacity(0.2))
                            .frame(width: 32, height: 32)
                    }

                    if isToday {
                        Circle()
                            .stroke(palette.accent, lineWidth: 2)
                            .frame(width: 28, height: 28)
                    }

                    Text("\(day)")
                        .font(.system(size: 16, weight: isToday || isInSelectedWeek ? .semibold : .regular))
                        .foregroundColor(
                            isFuture ? .secondary.opacity(0.4) :
                            isInSelectedWeek ? palette.accent :
                            .primary
                        )
                }

                // Entry indicator dot
                if hasEntries && !isFuture {
                    Circle()
                        .fill(isInSelectedWeek ? palette.accent : palette.accent.opacity(0.5))
                        .frame(width: 5, height: 5)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 5, height: 5)
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
        let isOver = calorieDifference > 0
        let absDiff = abs(calorieDifference)

        // Contextual message based on status
        let statusMessage: String = {
            let percentDiff = weeklyCalorieGoal > 0 ? abs(Double(calorieDifference)) / Double(weeklyCalorieGoal) : 0
            if percentDiff < 0.03 {
                return "Right on target"
            } else if isOver {
                return "\(formatNumber(absDiff)) over your goal"
            } else {
                return "\(formatNumber(absDiff)) remaining"
            }
        }()

        let daysMessage: String = {
            switch summary.daysLogged {
            case 0: return "Start logging to see your week"
            case 1: return "1 day tracked"
            case 7: return "Full week tracked"
            default: return "\(summary.daysLogged) days tracked"
            }
        }()

        return VStack(spacing: 16) {
            HStack(spacing: 20) {
                // Calorie Ring
                ZStack {
                    Circle()
                        .stroke(
                            colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04),
                            lineWidth: 10
                        )
                        .frame(width: 90, height: 90)

                    Circle()
                        .trim(from: 0, to: calorieProgress)
                        .stroke(
                            LinearGradient(
                                colors: [palette.accent, palette.accent.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(calorieProgress * 100))")
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .foregroundColor(.primary)
                        Text("%")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                // Stats Column
                VStack(alignment: .leading, spacing: 8) {
                    // Total eaten
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatNumber(summary.totalCalories))
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundColor(.primary)
                        Text("of \(formatNumber(weeklyCalorieGoal)) weekly")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    // Status message
                    Text(statusMessage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isOver ? Color.orange : palette.accent)
                }

                Spacer()
            }

            // Days logged bar
            HStack {
                Text(daysMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                // Mini day indicators
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { index in
                        Circle()
                            .fill(index < summary.daysLogged ? palette.accent : Color.secondary.opacity(0.2))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.15 : 0.06), radius: 12, x: 0, y: 4)
        )
    }

    // MARK: - Macro Progress Section
    private func macroProgressSection(summary: WeeklySummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your macros this week")
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundColor(.primary.opacity(0.8))

            HStack(spacing: 12) {
                macroCard(
                    name: "Protein",
                    value: Int(summary.totalProtein),
                    goal: Int(proteinGoal * 7),
                    color: Color(red: 0.85, green: 0.35, blue: 0.35),
                    icon: "bolt.fill"
                )

                macroCard(
                    name: "Carbs",
                    value: Int(summary.totalCarbs),
                    goal: Int(carbGoal * 7),
                    color: Color(red: 0.95, green: 0.65, blue: 0.25),
                    icon: "leaf.fill"
                )

                macroCard(
                    name: "Fat",
                    value: Int(summary.totalFat),
                    goal: Int(fatGoal * 7),
                    color: Color(red: 0.90, green: 0.75, blue: 0.30),
                    icon: "drop.fill"
                )
            }
        }
    }

    private func macroCard(name: String, value: Int, goal: Int, color: Color, icon: String) -> some View {
        let progress = goal > 0 ? min(Double(value) / Double(goal), 1.0) : 0
        let difference = value - goal
        let isOver = difference > 0
        let isOnTarget = goal > 0 && abs(Double(difference) / Double(goal)) < 0.08 // Within 8%

        // Contextual status text
        let statusText: String = {
            if goal == 0 { return "No goal set" }
            if isOnTarget { return "On track" }
            if isOver { return "+\(difference)g" }
            return "\(abs(difference))g to go"
        }()

        let statusColor: Color = {
            if isOnTarget { return palette.accent }
            if isOver { return Color.orange }
            return .secondary
        }()

        return VStack(spacing: 10) {
            // Icon with subtle background
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }

            // Value
            Text("\(value)g")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundColor(.primary)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.12))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 5)

            // Status text
            Text(statusText)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(statusColor)

            // Label
            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.12 : 0.05), radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - Daily Breakdown Section
    private func dailyBreakdownSection(summary: WeeklySummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Day by day")
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundColor(.primary.opacity(0.8))

            VStack(spacing: 10) {
                ForEach(summary.dailyBreakdowns) { day in
                    PremiumDayCard(
                        day: day,
                        calorieGoal: calorieGoal,
                        proteinGoal: proteinGoal,
                        carbGoal: carbGoal,
                        fatGoal: fatGoal,
                        isExpanded: expandedDays.contains(day.id.uuidString),
                        colorScheme: colorScheme,
                        palette: palette
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

// MARK: - Premium Day Card
struct PremiumDayCard: View {
    let day: DailyBreakdown
    let calorieGoal: Double
    let proteinGoal: Double
    let carbGoal: Double
    let fatGoal: Double
    let isExpanded: Bool
    let colorScheme: ColorScheme
    let palette: AppPalette
    let onTap: () -> Void

    @State private var isPressed = false

    private var calorieProgress: Double {
        guard calorieGoal > 0 else { return 0 }
        return Double(day.calories) / calorieGoal
    }

    // Status message - show calorie difference
    private var dayStatus: (message: String, color: Color) {
        if !day.isLogged {
            return ("No entries", .secondary)
        }
        let diff = day.calories - Int(calorieGoal)
        let percentDiff = calorieGoal > 0 ? abs(Double(diff)) / calorieGoal : 0

        // Only show "On target" if very close (within 2%)
        if percentDiff < 0.02 {
            return ("On target", palette.accent)
        } else if diff > 0 {
            return ("+\(diff)", Color.orange)
        } else {
            return ("\(abs(diff)) under", .secondary)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            Button(action: onTap) {
                HStack(spacing: 14) {
                    // Day indicator - cleaner design
                    VStack(spacing: 3) {
                        Text(day.dayName.prefix(3))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text("\(Calendar.current.component(.day, from: day.date))")
                            .font(.system(size: 22, weight: .bold, design: .serif))
                            .foregroundColor(day.isLogged ? .primary : .secondary.opacity(0.4))
                    }
                    .frame(width: 46)

                    if day.isLogged {
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))

                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [palette.accent, palette.accent.opacity(0.6)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * min(calorieProgress, 1.0))
                            }
                        }
                        .frame(height: 10)

                        // Calories - simplified
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("\(day.calories)")
                                .font(.system(size: 17, weight: .bold, design: .serif))
                                .foregroundColor(.primary)

                            Text("of \(Int(calorieGoal))")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 65, alignment: .trailing)

                        // Status
                        Text(dayStatus.message)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(dayStatus.color)
                            .frame(minWidth: 55, alignment: .trailing)

                        // Chevron
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.4))
                    } else {
                        Spacer()

                        Text("Rest day")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.5))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.02))
                            )
                    }
                }
                .padding(14)
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                isPressed = pressing
            }, perform: {})

            // Expanded content
            if isExpanded && day.isLogged {
                VStack(spacing: 14) {
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                        .frame(height: 1)
                        .padding(.horizontal, 16)

                    HStack(spacing: 20) {
                        expandedMacro(name: "Protein", value: Int(day.protein), goal: Int(proteinGoal), color: Color(red: 0.85, green: 0.35, blue: 0.35))
                        expandedMacro(name: "Carbs", value: Int(day.carbs), goal: Int(carbGoal), color: Color(red: 0.95, green: 0.65, blue: 0.25))
                        expandedMacro(name: "Fat", value: Int(day.fat), goal: Int(fatGoal), color: Color(red: 0.90, green: 0.75, blue: 0.30))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.12 : 0.04), radius: 8, x: 0, y: 2)
        )
    }

    private func expandedMacro(name: String, value: Int, goal: Int, color: Color) -> some View {
        let progress = goal > 0 ? min(Double(value) / Double(goal), 1.0) : 0
        let difference = value - goal
        let isOver = difference > 0
        let isOnTarget = goal > 0 && abs(Double(difference) / Double(goal)) < 0.10

        // Simpler status
        let statusText: String = {
            if goal == 0 { return "–" }
            if isOnTarget { return "✓" }
            if isOver { return "+\(difference)g" }
            return "\(difference)g"
        }()

        return VStack(spacing: 6) {
            // Value
            Text("\(value)g")
                .font(.system(size: 16, weight: .bold, design: .serif))
                .foregroundColor(.primary)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.12))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 4)

            // Status
            Text(statusText)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(isOnTarget ? palette.accent : (isOver ? .orange : .secondary))

            Text(name)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
