//
//  DiaryDailySummaryCard.swift
//  NutraSafe Beta
//
//  Modern daily nutrition summary with enhanced visual design
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

    // MARK: - Daily Goals
    @State private var calorieGoal: Double = 1800
    @State private var proteinGoal: Double = 135
    @State private var carbGoal: Double = 225
    @State private var fatGoal: Double = 40
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Modern header with gradient background
            VStack(spacing: 20) {
                // Date and calories header
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatDateForDaily(currentDate))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.primary, Color.primary.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("of \(Int(calorieGoal)) calories")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                // Enhanced rings layout
                HStack(spacing: 24) {
                    // Main calorie ring with modern design
                    VStack(spacing: 8) {
                        ZStack {
                            // Outer glow effect
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.blue.opacity(0.15),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 35,
                                        endRadius: 45
                                    )
                                )
                                .frame(width: 90, height: 90)
                            
                            // Background ring
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(.systemGray6),
                                            Color(.systemGray5).opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 10
                                )
                                .frame(width: 80, height: 80)
                            
                            // Progress ring with enhanced gradient
                            Circle()
                                .trim(from: 0, to: min(1.0, Double(totalCalories) / calorieGoal))
                                .stroke(
                                    AngularGradient(
                                        gradient: Gradient(colors: [
                                            Color.blue,
                                            Color.blue.opacity(0.9),
                                            Color.purple.opacity(0.8),
                                            Color.blue
                                        ]),
                                        center: .center,
                                        startAngle: .degrees(0),
                                        endAngle: .degrees(360 * min(1.0, Double(totalCalories) / calorieGoal))
                                    ),
                                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                )
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                                .shadow(color: Color.blue.opacity(0.4), radius: 6, x: 0, y: 3)
                                .animation(.spring(response: 1.2, dampingFraction: 0.7), value: totalCalories)
                            
                            // Center value
                            VStack(spacing: 2) {
                                Text("\(totalCalories)")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.primary, Color.primary.opacity(0.8)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .animation(.easeInOut(duration: 1.0), value: totalCalories)
                                
                                Text("kcal")
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Label with modern styling
                        Text("FOOD")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .tracking(1)
                            .foregroundColor(.secondary)
                    }
                    
                    // Exercise ring with enhanced design
                    VStack(spacing: 8) {
                        ZStack {
                            // Outer glow
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.green.opacity(0.15),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 22,
                                        endRadius: 30
                                    )
                                )
                                .frame(width: 60, height: 60)
                            
                            // Background ring
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(.systemGray6),
                                            Color(.systemGray5).opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 7
                                )
                                .frame(width: 50, height: 50)
                            
                            // Progress ring
                            Circle()
                                .trim(from: 0, to: min(1.0, healthKitManager.exerciseCalories / 400.0))
                                .stroke(
                                    AngularGradient(
                                        gradient: Gradient(colors: [
                                            Color.green,
                                            Color.green.opacity(0.9),
                                            Color.mint.opacity(0.8),
                                            Color.green
                                        ]),
                                        center: .center,
                                        startAngle: .degrees(0),
                                        endAngle: .degrees(360 * min(1.0, healthKitManager.exerciseCalories / 400.0))
                                    ),
                                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                                )
                                .frame(width: 50, height: 50)
                                .rotationEffect(.degrees(-90))
                                .shadow(color: Color.green.opacity(0.3), radius: 4, x: 0, y: 2)
                                .animation(.spring(response: 1.2, dampingFraction: 0.7), value: healthKitManager.exerciseCalories)
                            
                            // Center value
                            VStack(spacing: 1) {
                                Text("\(Int(healthKitManager.exerciseCalories))")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                    .animation(.easeInOut(duration: 1.0), value: healthKitManager.exerciseCalories)
                                
                                Text("kcal")
                                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text("EXERCISE")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .tracking(0.8)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                
                // Enhanced macro progress bars
                VStack(spacing: 14) {
                    ModernMacroProgressView(
                        name: "Protein",
                        current: totalProtein,
                        goal: proteinGoal,
                        unit: "g",
                        color: Color(.systemRed)
                    )
                    
                    ModernMacroProgressView(
                        name: "Carbs",
                        current: totalCarbs,
                        goal: carbGoal,
                        unit: "g",
                        color: Color(.systemOrange)
                    )
                    
                    ModernMacroProgressView(
                        name: "Fat",
                        current: totalFat,
                        goal: fatGoal,
                        unit: "g",
                        color: Color(.systemYellow)
                    )
                }
            }
            .padding(24)
        }
        .background(
            ZStack {
                // Base card background
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                
                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color(.systemGray6).opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.06),
                            Color.black.opacity(0.03)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
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

    // MARK: - Data Loading
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

// MARK: - Modern Macro Progress View
struct ModernMacroProgressView: View {
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
        VStack(spacing: 8) {
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    // Enhanced color indicator
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [color.opacity(0.4), color.opacity(0.2)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 6
                                )
                            )
                            .frame(width: 12, height: 12)
                        
                        Circle()
                            .fill(color)
                            .frame(width: 10, height: 10)
                            .shadow(color: color.opacity(0.4), radius: 2, x: 0, y: 1)
                    }
                    
                    Text(name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("\(Int(current.rounded()))")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [color, color.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("/ \(Int(goal))")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        Text(unit)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    
                    if remaining > 0 {
                        Text("\(Int(remaining.rounded())) left")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }
            }
            
            // Enhanced progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track with subtle gradient
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(.systemGray6),
                                    Color(.systemGray5).opacity(0.8)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 10)
                    
                    // Progress fill with enhanced gradient and glow
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: color.opacity(0.7), location: 0),
                                    .init(color: color, location: 0.5),
                                    .init(color: color.opacity(0.9), location: 1.0)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(8, geometry.size.width * progress),
                            height: 10
                        )
                        .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 2)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: current)
                        .overlay(
                            // Highlight effect
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.4),
                                            Color.clear
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 4)
                                .offset(y: -1.5),
                            alignment: .top
                        )
                }
            }
            .frame(height: 10)
        }
    }
}
