//
//  DiaryDailySummaryCard.swift
//  NutraSafe Beta
//
//  Comprehensive daily nutrition summary with rings and macro tracking
//  Extracted from ContentView.swift - 230+ lines
//

import SwiftUI

// MARK: - Daily Summary Card
struct DiaryDailySummaryCard: View {
    let totalCalories: Int
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let totalFiber: Double
    let currentDate: Date
    let breakfastFoods: [DiaryFoodItem]
    let lunchFoods: [DiaryFoodItem]
    let dinnerFoods: [DiaryFoodItem]
    let snackFoods: [DiaryFoodItem]
    let fetchWeeklySummary: (Date, Double, Double, Double, Double) async -> WeeklySummary?
    let setSelectedDate: (Date) -> Void
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var firebaseManager: FirebaseManager
    @AppStorage("healthKitRingsEnabled") private var healthKitRingsEnabled = false
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Palette for Intent-Aware Colors
    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    // MARK: - Breathing Animation State
    @State private var isBreathing = false

    // MARK: - Daily Goals (using AppStorage for instant load, no flash)
    @AppStorage("cachedCaloricGoal") private var cachedCaloricGoal: Int = 1800
    @AppStorage("cachedStepGoal") private var cachedStepGoal: Int = 10000
    @AppStorage("cachedExerciseGoal") private var cachedExerciseGoal: Int = 400
    @AppStorage("dailyWaterGoal") private var dailyWaterGoal: Int = 8

    private var calorieGoal: Double { Double(cachedCaloricGoal) }
    private var stepGoal: Double { Double(cachedStepGoal) }
    private var exerciseGoal: Double { Double(cachedExerciseGoal) }
    @State private var macroGoals: [MacroGoal] = MacroGoal.defaultMacros

    // MARK: - Water Tracking
    @State private var waterCount: Int = 0
    @State private var waterStreak: Int = 0
    @State private var showingWaterCelebration: Bool = false
    @State private var hasShownCelebrationToday: Bool = false

    // MARK: - Weekly Summary Sheet
    @State private var showWeeklySummary = false
    @State private var weeklyCaloriesConsumed: Int = 0
    @State private var weeklyCalorieGoal: Int = 0

    // MARK: - Body (Compact Premium Layout)
    var body: some View {
        VStack(spacing: DiaryLayoutTokens.sectionSpacing) {
            // MARK: Hero Row - Ring + Macros side by side
            HStack(alignment: .center, spacing: 16) {
                // Calorie ring (left)
                HeroCalorieRing(calories: totalCalories, goal: calorieGoal)

                // Macros grid (right) - 2x2 compact
                VStack(spacing: 6) {
                    let macros = Array(macroGoals.prefix(4))
                    if macros.count >= 2 {
                        HStack(spacing: 6) {
                            MacroCapsule(
                                name: macros[0].macroType.displayName,
                                current: calculateMacroTotal(for: macros[0].macroType),
                                goal: macros[0].calculateGramGoal(from: calorieGoal),
                                color: macros[0].macroType.color
                            )
                            MacroCapsule(
                                name: macros[1].macroType.displayName,
                                current: calculateMacroTotal(for: macros[1].macroType),
                                goal: macros[1].calculateGramGoal(from: calorieGoal),
                                color: macros[1].macroType.color
                            )
                        }
                    }
                    if macros.count >= 4 {
                        HStack(spacing: 6) {
                            MacroCapsule(
                                name: macros[2].macroType.displayName,
                                current: calculateMacroTotal(for: macros[2].macroType),
                                goal: macros[2].calculateGramGoal(from: calorieGoal),
                                color: macros[2].macroType.color
                            )
                            MacroCapsule(
                                name: macros[3].macroType.displayName,
                                current: calculateMacroTotal(for: macros[3].macroType),
                                goal: macros[3].calculateGramGoal(from: calorieGoal),
                                color: macros[3].macroType.color
                            )
                        }
                    }
                }
            }
            .padding(.top, 4)

            // MARK: Compact Activity Strip (Water, Steps, Burned)
            CompactActivityStrip(
                waterCount: waterCount,
                waterGoal: dailyWaterGoal,
                waterStreak: waterStreak,
                steps: healthKitManager.stepCount,
                stepGoal: stepGoal,
                caloriesBurned: healthKitManager.activeEnergyBurned,
                caloriesGoal: exerciseGoal,
                onWaterTap: addWater
            )

            // MARK: Bottom Row - Weekly Summary + Insight inline
            HStack(spacing: 8) {
                // Weekly summary (compact)
                WeeklySummaryPill(
                    consumed: weeklyCaloriesConsumed,
                    goal: weeklyCalorieGoal,
                    onTap: { showWeeklySummary = true }
                )
                .frame(maxWidth: .infinity)

                // Coaching insight (if any) - compact icon-only version
                if let insight = generateNutritionInsight() {
                    CompactInsightBadge(icon: insight.icon, color: insight.color, message: insight.message)
                }
            }

            // Water celebration overlay
            if showingWaterCelebration {
                waterCelebrationBanner
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.xl))
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 3)
        .onAppear { handleOnAppear(); loadWaterData() }
        .onChange(of: currentDate) { handleDateChange() }
        .onChange(of: healthKitRingsEnabled) { _, enabled in handleHealthKitToggle(enabled) }
        .onReceive(NotificationCenter.default.publisher(for: .nutritionGoalsUpdated)) { _ in
            Task { await loadNutritionGoals() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .waterUpdated)) { _ in
            loadWaterData()
        }
        .fullScreenCover(isPresented: $showWeeklySummary) {
            WeeklySummarySheet(
                initialDate: currentDate,
                calorieGoal: calorieGoal,
                macroGoals: macroGoals,
                fetchWeeklySummary: fetchWeeklySummary,
                setSelectedDate: setSelectedDate
            )
        }
    }

    // MARK: - Water Celebration Banner
    private var waterCelebrationBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "hands.clap.fill")
                .font(.system(size: 18))
                .foregroundColor(.green)

            Text("Well done! You've hit your water goal!")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.green.opacity(0.12))
        )
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Nutrition Insights
    private struct NutritionInsight {
        let icon: String
        let message: String
        let color: Color
        let isPositive: Bool
    }

    private func generateNutritionInsight() -> NutritionInsight? {
        let allFoods = breakfastFoods + lunchFoods + dinnerFoods + snackFoods
        guard !allFoods.isEmpty else { return nil }

        // Calculate goals
        let proteinGoal = macroGoals.first { $0.macroType == .protein }?.calculateGramGoal(from: calorieGoal) ?? 50
        let carbsGoal = macroGoals.first { $0.macroType == .carbs }?.calculateGramGoal(from: calorieGoal) ?? 250
        let fatGoal = macroGoals.first { $0.macroType == .fat }?.calculateGramGoal(from: calorieGoal) ?? 65
        let totalSugar = allFoods.reduce(0.0) { $0 + $1.sugar }

        // Check for significant deviations (prioritize warnings over positive)
        let carbsOverage = totalCarbs / carbsGoal
        let calorieOverage = Double(totalCalories) / calorieGoal
        let proteinProgress = totalProtein / proteinGoal
        let fatOverage = totalFat / fatGoal

        // Massively over carbs (>150%)
        if carbsOverage > 1.5 {
            return NutritionInsight(
                icon: "exclamationmark.triangle.fill",
                message: "Carb heavy day – \(Int((carbsOverage - 1) * 100))% over your goal",
                color: .orange,
                isPositive: false
            )
        }

        // High sugar warning (>50g)
        if totalSugar > 50 {
            return NutritionInsight(
                icon: "cube.fill",
                message: "High sugar intake today – \(Int(totalSugar))g consumed",
                color: .pink,
                isPositive: false
            )
        }

        // Way over calories (>120%)
        if calorieOverage > 1.2 {
            return NutritionInsight(
                icon: "flame.fill",
                message: "Over calorie goal by \(Int((calorieOverage - 1) * 100))%",
                color: .red,
                isPositive: false
            )
        }

        // Over fat (>130%)
        if fatOverage > 1.3 {
            return NutritionInsight(
                icon: "drop.fill",
                message: "Fat intake \(Int((fatOverage - 1) * 100))% above target",
                color: .yellow,
                isPositive: false
            )
        }

        // Positive insights (only if no warnings)
        // Great protein day (>90%)
        if proteinProgress > 0.9 && proteinProgress <= 1.2 {
            return NutritionInsight(
                icon: "bolt.fill",
                message: "Great protein day! \(Int(proteinProgress * 100))% of goal",
                color: .green,
                isPositive: true
            )
        }

        // Balanced day (all macros within range)
        if carbsOverage < 1.1 && fatOverage < 1.1 && calorieOverage < 1.05 && calorieOverage > 0.8 {
            return NutritionInsight(
                icon: "checkmark.seal.fill",
                message: "Well balanced day – on track!",
                color: .green,
                isPositive: true
            )
        }

        return nil
    }

    // MARK: - Water Tracking Actions

    private func addWater() {
        let previousCount = waterCount

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            waterCount += 1
        }
        saveWaterData()

        // Check if goal was just hit
        if previousCount < dailyWaterGoal && waterCount >= dailyWaterGoal && !hasShownCelebrationToday {
            hasShownCelebrationToday = true
            // Show celebration
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showingWaterCelebration = true
            }
            // Success haptic
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)

            // Update streak
            updateWaterStreak()

            // Hide celebration after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showingWaterCelebration = false
                }
            }
        } else {
            // Normal haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }

    private func loadWaterData() {
        let dateKey = formatDateKey(currentDate)
        let saved = UserDefaults.standard.dictionary(forKey: "hydrationData") as? [String: Int] ?? [:]
        waterCount = saved[dateKey] ?? 0

        // Check if we've already shown celebration today
        let celebrationKey = "waterCelebration_\(dateKey)"
        hasShownCelebrationToday = UserDefaults.standard.bool(forKey: celebrationKey)

        // Calculate streak
        calculateWaterStreak()
    }

    private func calculateWaterStreak() {
        let saved = UserDefaults.standard.dictionary(forKey: "hydrationData") as? [String: Int] ?? [:]
        var streak = 0
        var checkDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate

        // Count backwards from yesterday to find streak
        // Safety limit: max 365 days to prevent infinite loop edge cases
        let maxIterations = 365
        var iterations = 0

        while iterations < maxIterations {
            iterations += 1
            let dateKey = formatDateKey(checkDate)
            let count = saved[dateKey] ?? 0
            if count >= dailyWaterGoal {
                streak += 1
                let previousDate = checkDate
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
                // Safety check: ensure date actually changed to prevent infinite loop
                if checkDate == previousDate {
                    break
                }
            } else {
                break
            }
        }

        // Add today if goal met
        let todayKey = formatDateKey(currentDate)
        if (saved[todayKey] ?? 0) >= dailyWaterGoal {
            streak += 1
        }

        waterStreak = streak
    }

    private func updateWaterStreak() {
        let dateKey = formatDateKey(currentDate)
        UserDefaults.standard.set(true, forKey: "waterCelebration_\(dateKey)")
        calculateWaterStreak()
    }

    private func saveWaterData() {
        let dateKey = formatDateKey(currentDate)
        var hydrationData = UserDefaults.standard.dictionary(forKey: "hydrationData") as? [String: Int] ?? [:]
        hydrationData[dateKey] = waterCount
        UserDefaults.standard.set(hydrationData, forKey: "hydrationData")

        // Post notification so other views can update
        NotificationCenter.default.post(name: .waterUpdated, object: nil)
    }

    private func formatDateKey(_ date: Date) -> String {
        DateHelper.isoDateFormatter.string(from: date)
    }

    // MARK: - Card Background
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
            .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
    }

    // MARK: - Event Handlers
    // NOTE: HealthKit data is fetched by DiaryTabView - this view only observes values
    private func handleOnAppear() {
        Task {
            await loadNutritionGoals()
            await loadWeeklyCalories()
        }
    }

    private func handleDateChange() {
        loadWaterData()
        Task {
            await loadNutritionGoals()
            await loadWeeklyCalories()
        }
    }

    private func handleHealthKitToggle(_ enabled: Bool) {
        // HealthKit fetching is handled by DiaryTabView
        // This just reacts to the toggle for UI purposes
    }

    // MARK: - Data Loading
    private func loadNutritionGoals() async {
        do {
            let settings = try await firebaseManager.getUserSettings()
            let loadedMacroGoals = try await firebaseManager.getMacroGoals()

            await MainActor.run {
                // Update cached goals (AppStorage syncs instantly, no flash)
                cachedCaloricGoal = settings.caloricGoal ?? 2000
                cachedStepGoal = settings.stepGoal ?? 10000
                cachedExerciseGoal = settings.exerciseGoal ?? 400

                // Update macro goals from Firebase
                macroGoals = loadedMacroGoals
            }
        } catch {
            // Keep cached values if loading fails
        }
    }

    private func loadWeeklyCalories() async {
        // Calculate week range (Monday to Sunday)
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: currentDate)
        // weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
        let daysFromMonday = (weekday == 1) ? -6 : 2 - weekday

        guard let weekStart = calendar.date(byAdding: .day, value: daysFromMonday, to: currentDate),
              let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return
        }

        // Calculate weekly calorie goal (daily goal * 7)
        let dailyGoal = Int(calorieGoal)
        let weekGoal = dailyGoal * 7

        // Fetch weekly summary using the provided function
        if let summary = await fetchWeeklySummary(currentDate, calorieGoal, 0, 0, 0) {
            await MainActor.run {
                weeklyCaloriesConsumed = summary.totalCalories
                weeklyCalorieGoal = weekGoal
            }
        } else {
            await MainActor.run {
                weeklyCaloriesConsumed = 0
                weeklyCalorieGoal = weekGoal
            }
        }
    }

    // Use passed parameter values for accurate macro totals
    private func calculateMacroTotal(for macroType: MacroType) -> Double {
        switch macroType {
        case .protein: return totalProtein
        case .carbs: return totalCarbs
        case .fat: return totalFat
        case .fiber: return totalFiber
        case .sugar, .salt, .saturatedFat:
            // For macros not passed as parameters, calculate from food arrays
            let allFoods = breakfastFoods + lunchFoods + dinnerFoods + snackFoods
            return allFoods.reduce(0.0) { total, food in
                total + macroType.getValue(from: food)
            }
        }
    }

    // MARK: - Helper Methods
    private func formatDateForDaily(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDate(date, inSameDayAs: now) {
            return "Today"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now) ?? now) {
            return "Yesterday"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: now) ?? now) {
            return "Tomorrow"
        } else {
            let daysDiff = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            if abs(daysDiff) <= 6 {
                // Show day name for current week - PERFORMANCE: Use cached static formatter
                return DateHelper.fullDayOfWeekFormatter.string(from: date)
            } else {
                // Show full date for older entries - PERFORMANCE: Use cached static formatter
                return DateHelper.dayDateMonthFormatter.string(from: date)
            }
        }
    }
}

// MARK: - Premium Macro Progress View
struct PremiumMacroProgressView: View {
    let name: String
    let current: Double
    let goal: Double
    let unit: String
    let color: Color
    
    // MARK: - Computed Properties
    private var progress: Double {
        min(1.0, current / goal)
    }
    
    private var remaining: Double {
        max(0, goal - current)
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                        .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    Text(name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 1) {
                    HStack(spacing: 3) {
                        Text("\(Int(current.rounded()))")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(color)
                        
                        Text("/ \(Int(goal))")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        Text(unit)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.9))
                    }
                    
                    if remaining > 0 {
                        Text("\(Int(remaining.rounded())) left")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }
            }
            
            // Enhanced progress bar with subtle shadow
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(.systemGray6),
                                    Color(.systemGray5).opacity(0.9)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 8)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: color.opacity(0.7), location: 0),
                                    .init(color: color, location: 0.6),
                                    .init(color: color.opacity(0.9), location: 1.0)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(6, geometry.size.width * progress),
                            height: 8
                        )
                        .shadow(color: color.opacity(0.4), radius: 2, x: 0, y: 1)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: current)
                        .overlay(
                            // Highlight effect
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.3),
                                            Color.clear
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 3)
                                .offset(y: -1),
                            alignment: .top
                        )
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Apple-style Metric View
struct MetricView: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .tracking(0.5)
        }
    }
}

// Note: GlassShape is defined in ContentView.swift and available project-wide

// MARK: - Goal Editor Sheet
struct GoalEditorSheet: View {
    let title: String
    let icon: String
    let iconColor: Color
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let unit: String
    let onSave: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var tempValue: Int = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Icon and title
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.15))
                            .frame(width: 60, height: 60)

                        Image(systemName: icon)
                            .font(.system(size: 28))
                            .foregroundColor(iconColor)
                    }

                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding(.top, 20)

                // Value display
                HStack(spacing: 4) {
                    Text("\(formatNumber(tempValue))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(iconColor)

                    Text(unit)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.secondary)
                        .offset(y: 8)
                }

                // Stepper
                HStack(spacing: 20) {
                    Button(action: {
                        if tempValue - step >= range.lowerBound {
                            tempValue -= step
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(tempValue <= range.lowerBound ? .gray.opacity(0.3) : iconColor)
                    }
                    .disabled(tempValue <= range.lowerBound)

                    Button(action: {
                        if tempValue + step <= range.upperBound {
                            tempValue += step
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(tempValue >= range.upperBound ? .gray.opacity(0.3) : iconColor)
                    }
                    .disabled(tempValue >= range.upperBound)
                }
                .padding(.vertical, 10)

                Spacer()

                // Save button
                Button(action: {
                    onSave(tempValue)
                    dismiss()
                }) {
                    Text("Save")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(iconColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            tempValue = value
        }
    }

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}