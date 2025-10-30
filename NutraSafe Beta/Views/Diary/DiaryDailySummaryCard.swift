//
//  DiaryDailySummaryCard.swift
//  NutraSafe Beta
//
//  Compact daily nutrition summary with efficient space usage
//

import SwiftUI

// MARK: - Daily Summary Card
struct DiaryDailySummaryCard: View {
    let totalCalories: Int
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let currentDate: Date
    let breakfastFoods: [DiaryFoodItem]
    let lunchFoods: [DiaryFoodItem]
    let dinnerFoods: [DiaryFoodItem]
    let snackFoods: [DiaryFoodItem]
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var firebaseManager: FirebaseManager
    @AppStorage("healthKitRingsEnabled") private var healthKitRingsEnabled = false

    @State private var calorieGoal: Double = 1800
    @State private var proteinGoal: Double = 135
    @State private var carbGoal: Double = 225
    @State private var fatGoal: Double = 40
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact header
            HStack(alignment: .center, spacing: 12) {
                // Left: Date and goal
                VStack(alignment: .leading, spacing: 2) {
                    Text(formatDateForDaily(currentDate))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("of \(Int(calorieGoal)) cal")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()
                
                // Right: Compact rings
                HStack(spacing: 12) {
                    // Main calorie ring - compact
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .stroke(Color(.systemGray6), lineWidth: 6)
                                .frame(width: 58, height: 58)
                            
                            Circle()
                                .trim(from: 0, to: min(1.0, Double(totalCalories) / calorieGoal))
                                .stroke(
                                    AngularGradient(
                                        gradient: Gradient(colors: [.blue, .purple.opacity(0.8), .blue]),
                                        center: .center
                                    ),
                                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                )
                                .frame(width: 58, height: 58)
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(response: 1.0, dampingFraction: 0.7), value: totalCalories)
                            
                            Text("\(totalCalories)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        
                        Text("FOOD")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .tracking(0.6)
                            .foregroundColor(.secondary)
                    }
                    
                    // Exercise ring - compact
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .stroke(Color(.systemGray6), lineWidth: 5)
                                .frame(width: 42, height: 42)
                            
                            Circle()
                                .trim(from: 0, to: min(1.0, healthKitManager.exerciseCalories / 400.0))
                                .stroke(
                                    AngularGradient(
                                        gradient: Gradient(colors: [.green, .mint.opacity(0.8), .green]),
                                        center: .center
                                    ),
                                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                                )
                                .frame(width: 42, height: 42)
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(response: 1.0, dampingFraction: 0.7), value: healthKitManager.exerciseCalories)
                            
                            Text("\(Int(healthKitManager.exerciseCalories))")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        
                        Text("EXERCISE")
                            .font(.system(size: 7, weight: .bold, design: .rounded))
                            .tracking(0.5)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
                .padding(.horizontal, 18)
            
            // Compact macro rows
            VStack(spacing: 10) {
                CompactMacroRow(
                    name: "Protein",
                    current: totalProtein,
                    goal: proteinGoal,
                    unit: "g",
                    color: Color(.systemRed)
                )
                
                CompactMacroRow(
                    name: "Carbs",
                    current: totalCarbs,
                    goal: carbGoal,
                    unit: "g",
                    color: Color(.systemOrange)
                )
                
                CompactMacroRow(
                    name: "Fat",
                    current: totalFat,
                    goal: fatGoal,
                    unit: "g",
                    color: Color(.systemYellow)
                )
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        .onAppear {
            Task {
                await loadNutritionGoals()
                if healthKitRingsEnabled {
                    await healthKitManager.updateExerciseCalories()
                } else {
                    await MainActor.run { healthKitManager.exerciseCalories = 0 }
                }
            }
        }
        .onChange(of: currentDate) { _ in
            Task {
                await loadNutritionGoals()
                if healthKitRingsEnabled {
                    await healthKitManager.updateExerciseCalories()
                }
            }
        }
        .onChange(of: healthKitRingsEnabled) { enabled in
            Task {
                if enabled {
                    await healthKitManager.updateExerciseCalories()
                } else {
                    await MainActor.run { healthKitManager.exerciseCalories = 0 }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .nutritionGoalsUpdated)) { _ in
            Task { await loadNutritionGoals() }
        }
    }

    private func loadNutritionGoals() async {
        do {
            let settings = try await firebaseManager.getUserSettings()

            await MainActor.run {
                calorieGoal = Double(settings.caloricGoal ?? 2000)

                let proteinPercent = Double(settings.proteinPercent ?? 30) / 100.0
                let carbsPercent = Double(settings.carbsPercent ?? 40) / 100.0
                let fatPercent = Double(settings.fatPercent ?? 30) / 100.0

                proteinGoal = (calorieGoal * proteinPercent) / 4.0
                carbGoal = (calorieGoal * carbsPercent) / 4.0
                fatGoal = (calorieGoal * fatPercent) / 9.0
            }
        } catch {
            print("⚠️ Failed to load nutrition goals: \(error.localizedDescription)")
        }
    }
    
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
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE"
                return formatter.string(from: date)
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "d MMM yyyy"
                return formatter.string(from: date)
            }
        }
    }
}

// MARK: - Compact Macro Row
struct CompactMacroRow: View {
    let name: String
    let current: Double
    let goal: Double
    let unit: String
    let color: Color
    
    private var progress: Double {
        min(1.0, current / goal)
    }
    
    private var remaining: Double {
        max(0, goal - current)
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // Color indicator
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
            
            // Macro name
            Text(name)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .frame(width: 60, alignment: .leading)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [color.opacity(0.8), color]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 6)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: current)
                }
            }
            .frame(height: 6)
            
            // Values
            VStack(alignment: .trailing, spacing: 0) {
                HStack(spacing: 2) {
                    Text("\(Int(current.rounded()))")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                    
                    Text("/")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(goal))")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text(unit)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 70, alignment: .trailing)
        }
    }
}
