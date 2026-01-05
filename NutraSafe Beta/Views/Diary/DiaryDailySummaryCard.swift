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

    private var calorieGoal: Double { Double(cachedCaloricGoal) }
    private var stepGoal: Double { Double(cachedStepGoal) }
    private var exerciseGoal: Double { Double(cachedExerciseGoal) }
    @State private var macroGoals: [MacroGoal] = MacroGoal.defaultMacros

    // MARK: - Weekly Summary Sheet
    @State private var showWeeklySummary = false
    
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

            // Steps section with overlay text
            stepsProgressView

            // Calories burned section
            caloriesBurnedProgressView

        }
        .padding(AppSpacing.medium)
        .background(cardBackground)
        .cardShadow()
        .onAppear { handleOnAppear() }
        .onChange(of: currentDate) { handleDateChange() }
        .onChange(of: healthKitRingsEnabled) { _, enabled in handleHealthKitToggle(enabled) }
        .onReceive(NotificationCenter.default.publisher(for: .nutritionGoalsUpdated)) { _ in
            Task { await loadNutritionGoals() }
        }
        .sheet(isPresented: $showWeeklySummary) {
            WeeklySummarySheet(
                initialDate: currentDate,
                calorieGoal: calorieGoal,
                macroGoals: macroGoals,
                fetchWeeklySummary: fetchWeeklySummary,
                setSelectedDate: setSelectedDate
            )
            .presentationDragIndicator(.visible)
            .presentationBackground(Color(.systemBackground))
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

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: AppRadius.medium)
            .fill(.ultraThinMaterial)
    }

    // MARK: - Event Handlers
    // NOTE: HealthKit data is fetched by DiaryTabView - this view only observes values
    private func handleOnAppear() {
        Task {
            await loadNutritionGoals()
        }
    }

    private func handleDateChange() {
        Task {
            await loadNutritionGoals()
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
                print("✅ Loaded nutrition goals: \(cachedCaloricGoal) cal, \(cachedStepGoal) steps, \(cachedExerciseGoal) cal burned")
            }
        } catch {
            print("⚠️ Failed to load nutrition goals: \(error.localizedDescription)")
            // Keep cached values if loading fails
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