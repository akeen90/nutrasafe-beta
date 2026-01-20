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

    // MARK: - Body
    var body: some View {
        VStack(spacing: 16) {
            // Calorie ring and micro macros
            HStack(spacing: 20) {
                calorieRingView

                Divider()
                    .frame(height: 80)

                microMacrosView
            }
            .padding(.vertical, 4)

            // Separator line
            Divider()
                .padding(.horizontal, -AppSpacing.medium)

            // Activity row: Steps + Cals burned on left, Water glass on right
            HStack(spacing: 12) {
                // Left side: Steps and Cals burned bars stacked
                VStack(spacing: 8) {
                    stepsProgressView
                    caloriesBurnedProgressView
                }

                // Right side: Water glass visualization
                waterGlassView
            }

            // Weekly Summary Card - tappable to see full breakdown
            weeklySummaryCard

            // Smart nutrition insights
            if let insight = generateNutritionInsight() {
                nutritionInsightView(insight)
            }

        }
        .padding(AppSpacing.medium)
        .background(cardBackground)
        .cardShadow()
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

    // MARK: - View Components (3 Rings)

    private var calorieRingView: some View {
        VStack(spacing: 6) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 14)
                    .frame(width: 130, height: 130)

                // Progress circle (teal)
                Circle()
                    .trim(from: 0, to: min(1.0, Double(totalCalories) / calorieGoal))
                    .stroke(
                        Color(.systemTeal),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.0, dampingFraction: 0.7), value: totalCalories)

                // Center text - stacked vertically
                VStack(spacing: 0) {
                    Text("\(totalCalories)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("/\(Int(calorieGoal))")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)

                    Text("Cals")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            }
        }
    }

    private var microMacrosView: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(macroGoals, id: \.macroType) { macroGoal in
                HStack(spacing: 3) {
                    Circle()
                        .fill(macroGoal.macroType.color)
                        .frame(width: 8, height: 8)

                    Text(macroGoal.macroType.displayName)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .fixedSize()

                    Spacer()

                    // Achieved value (fixed width for alignment)
                    Text("\(Int(calculateMacroTotal(for: macroGoal.macroType).rounded()))g")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(macroGoal.macroType.color)
                        .frame(width: 50, alignment: .trailing)

                    // Vertical divider
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 1, height: 14)
                        .padding(.horizontal, 4)

                    // Goal value (fixed width for alignment)
                    Text("\(Int(macroGoal.calculateGramGoal(from: calorieGoal)))g")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(width: 45, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stepsProgressView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background bar (fully rounded)
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(height: 24)

                // Progress bar (fully rounded) - only show sky blue if there are steps
                if healthKitManager.stepCount > 0 {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.4, green: 0.7, blue: 1.0))
                        .frame(
                            width: max(24, geometry.size.width * min(1.0, healthKitManager.stepCount / stepGoal)),
                            height: 24
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: healthKitManager.stepCount)
                }

                // Text overlay on top of bar
                HStack {
                    Text("Steps")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)

                    Spacer()

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(formatStepCount(healthKitManager.stepCount))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("/\(formatStepCount(stepGoal))")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .frame(height: 24)
    }

    private var caloriesBurnedProgressView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background bar (fully rounded)
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(height: 24)

                // Progress bar (fully rounded) - only show orange if calories burned
                if healthKitManager.activeEnergyBurned > 0 {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 1.0, green: 0.4, blue: 0.3))
                        .frame(
                            width: max(24, geometry.size.width * min(1.0, healthKitManager.activeEnergyBurned / exerciseGoal)),
                            height: 24
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: healthKitManager.activeEnergyBurned)
                }

                // Text overlay on top of bar
                HStack {
                    Text("Calories Burned")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)

                    Spacer()

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(Int(healthKitManager.activeEnergyBurned))")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("/\(Int(exerciseGoal))")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .frame(height: 24)
    }

    // MARK: - Weekly Summary Card
    private var weeklySummaryCard: some View {
        Button(action: {
            showWeeklySummary = true
        }) {
            HStack(spacing: 8) {
                // Weekly Summary label
                Text("Weekly Summary")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.blue)

                Spacer()

                // Calories: consumed / goal kcal
                HStack(spacing: 2) {
                    Text("\(formatNumber(weeklyCaloriesConsumed))")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("/")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)

                    Text("\(formatNumber(weeklyCalorieGoal))")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)

                    Text("kcal")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.4))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6).opacity(0.5))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
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

    @ViewBuilder
    private func nutritionInsightView(_ insight: NutritionInsight) -> some View {
        HStack(spacing: 8) {
            Image(systemName: insight.icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(insight.color)

            Text(insight.message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(insight.isPositive ? .primary : insight.color)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(insight.color.opacity(0.12))
        )
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .animation(.easeInOut(duration: 0.3), value: insight.message)
    }

    // MARK: - Water Glass Visualization
    private var waterGlassView: some View {
        Button(action: addWater) {
            VStack(spacing: 4) {
                // Glass container
                ZStack(alignment: .bottom) {
                    // Glass outline (tapered cup shape)
                    GlassShape()
                        .stroke(Color(.systemGray3), lineWidth: 2)
                        .frame(width: 50, height: 56)

                    // Water fill level
                    let fillPercent = min(1.0, Double(waterCount) / Double(dailyWaterGoal))
                    GlassShape()
                        .fill(
                            LinearGradient(
                                colors: waterCount >= dailyWaterGoal
                                    ? [Color.green.opacity(0.7), Color.green]
                                    : [Color.cyan.opacity(0.6), Color.cyan],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 50, height: 56)
                        .mask(
                            VStack {
                                Spacer()
                                Rectangle()
                                    .frame(height: 56 * fillPercent)
                            }
                            .frame(height: 56)
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: waterCount)

                    // Checkmark overlay when complete
                    if waterCount >= dailyWaterGoal {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            .offset(y: -16)
                    }
                }

                // Water count text
                HStack(spacing: 2) {
                    Text("\(waterCount)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(waterCount >= dailyWaterGoal ? .green : .primary)
                    Text("/\(dailyWaterGoal)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }

                // Streak badge (compact)
                if waterStreak > 1 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 8))
                        Text("\(waterStreak)")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        // Show celebration
        .overlay(alignment: .top) {
            if showingWaterCelebration {
                Image(systemName: "hands.clap.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
                    .offset(y: -24)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - Water Tracking (Legacy bar - kept for reference)
    private var waterProgressView: some View {
        VStack(spacing: 6) {
            Button(action: addWater) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background bar (fully rounded)
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(height: 24)

                        // Progress bar (fully rounded) - show cyan, green when complete
                        if waterCount > 0 {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(waterCount >= dailyWaterGoal ? Color.green : Color.cyan)
                                .frame(
                                    width: max(24, geometry.size.width * min(1.0, Double(waterCount) / Double(dailyWaterGoal))),
                                    height: 24
                                )
                                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: waterCount)
                        }

                        // Text overlay on top of bar
                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: waterCount >= dailyWaterGoal ? "checkmark.circle.fill" : "drop.fill")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(waterCount >= dailyWaterGoal ? .green : .cyan)
                                Text("Water")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("\(waterCount)")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)

                                Text("/\(dailyWaterGoal) glasses")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)

                                // Streak badge
                                if waterStreak > 1 {
                                    HStack(spacing: 2) {
                                        Image(systemName: "flame.fill")
                                            .font(.system(size: 9))
                                        Text("\(waterStreak)")
                                            .font(.system(size: 10, weight: .semibold))
                                    }
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.15))
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                }
                .frame(height: 24)
            }
            .buttonStyle(PlainButtonStyle())

            // Celebration message when goal hit
            if showingWaterCelebration {
                HStack(spacing: 6) {
                    Image(systemName: "hands.clap.fill")
                        .font(.system(size: 12))
                    Text("Well done! You've hit your water goal!")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.green)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color.green.opacity(0.15))
                .clipShape(Capsule())
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

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

    private var stepsTextView: some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(formatStepCount(healthKitManager.stepCount))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("/ \(formatStepCount(stepGoal))")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(minWidth: 100)

            Text("steps")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
    }

    private func formatStepCount(_ steps: Double) -> String {
        if steps >= 10000 {
            return String(format: "%.1fK", steps / 1000)
        } else if steps >= 1000 {
            return String(format: "%.1fK", steps / 1000)
        } else {
            return String(format: "%.0f", steps)
        }
    }

    private var progressBarsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            dateHeaderView
            macroProgressBarsView
        }
    }

    private var dateHeaderView: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                Text(formatDateForDaily(currentDate))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                viewWeekButton
            }

            Text("of \(Int(calorieGoal)) calories")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.secondary.opacity(0.9))
        }
    }

    private var viewWeekButton: some View {
        Button(action: {
            showWeeklySummary = true
        }) {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 13, weight: .semibold))
                Text("Week")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemBlue).opacity(0.1))
            )
        }
    }

    private var macroProgressBarsView: some View {
        VStack(spacing: 10) {
            ForEach(macroGoals, id: \.macroType) { macroGoal in
                PremiumMacroProgressView(
                    name: macroGoal.macroType.displayName,
                    current: calculateMacroTotal(for: macroGoal.macroType),
                    goal: macroGoal.calculateGramGoal(from: calorieGoal),
                    unit: macroGoal.macroType.unit,
                    color: macroGoal.macroType.color
                )
            }
        }
    }

    @Environment(\.colorScheme) private var colorScheme

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: AppRadius.large)
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