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
        VStack(spacing: 24) {
            // Header with ring layout
            HStack(spacing: 20) {
                // Left side - Ring stack
                VStack(spacing: 16) {
                    // Big calorie ring - Premium design
                    VStack(spacing: 6) {
                        ZStack {
                            // Background ring with subtle gradient
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray5)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 8
                                )
                                .frame(width: 72, height: 72)
                            
                            // Progress ring with enhanced gradient
                            Circle()
                                .trim(from: 0, to: min(1.0, Double(totalCalories) / calorieGoal))
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(.systemBlue),
                                            Color(.systemIndigo),
                                            Color(.systemPurple)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .frame(width: 72, height: 72)
                                .rotationEffect(.degrees(-90))
                                .shadow(color: Color(.systemBlue).opacity(0.3), radius: 4, x: 0, y: 2)
                                .animation(.spring(response: 1.0, dampingFraction: 0.7), value: totalCalories)
                            
                            // Inner shadow effect
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 1)
                                .frame(width: 56, height: 56)
                                .opacity(0.9)
                        }
                        
                        VStack(spacing: 1) {
                            Text("\(totalCalories)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .animation(.easeInOut(duration: 1.0), value: totalCalories)
                            
                            Text("cal")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            Text("FOOD")
                                .font(.system(size: 8, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary.opacity(0.9))
                                .tracking(0.8)
                        }
                    }
                    
                    // Small exercise ring - Premium design
                    VStack(spacing: 4) {
                        ZStack {
                            // Background ring
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray5)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 5
                                )
                                .frame(width: 44, height: 44)
                            
                            // Progress ring
                            Circle()
                                .trim(from: 0, to: min(1.0, healthKitManager.exerciseCalories / 400.0))
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(.systemGreen),
                                            Color(.systemMint),
                                            Color(.systemTeal)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                                )
                                .frame(width: 44, height: 44)
                                .rotationEffect(.degrees(-90))
                                .shadow(color: Color(.systemGreen).opacity(0.3), radius: 3, x: 0, y: 1)
                                .animation(.spring(response: 1.0, dampingFraction: 0.7), value: healthKitManager.exerciseCalories)
                        }
                        
                        VStack(spacing: 1) {
                            Text("\(Int(healthKitManager.exerciseCalories))")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .animation(.easeInOut(duration: 1.0), value: healthKitManager.exerciseCalories)
                            
                            Text("cal")
                                .font(.system(size: 8, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            Text("EXERCISE")
                                .font(.system(size: 7, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary.opacity(0.9))
                                .tracking(0.6)
                        }
                    }
                }
                
                // Right side - Enhanced Progress bars
                VStack(alignment: .leading, spacing: 12) {
                    // Date header with improved typography
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Text(formatDateForDaily(currentDate))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)

                            Spacer()
                        }

                        Text("of \(Int(calorieGoal)) calories")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.9))
                    }
                    
                    // Enhanced Macro progress bars
                    VStack(spacing: 10) {
                        // Protein
                        PremiumMacroProgressView(
                            name: "Protein",
                            current: totalProtein,
                            goal: proteinGoal,
                            unit: "g",
                            color: Color(.systemRed)
                        )
                        
                        // Carbs  
                        PremiumMacroProgressView(
                            name: "Carbs",
                            current: totalCarbs,
                            goal: carbGoal,
                            unit: "g",
                            color: Color(.systemOrange)
                        )
                        
                        // Fat
                        PremiumMacroProgressView(
                            name: "Fat",
                            current: totalFat,
                            goal: fatGoal,
                            unit: "g",
                            color: Color(.systemYellow)
                        )
                    }
                }
            }
        }
        .padding(AppSpacing.xLarge)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .fill(AppColors.cardBackgroundElevated)
        )
        .cardShadow()
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
                // Update calorie goal
                calorieGoal = Double(settings.caloricGoal ?? 2000)

                // Calculate macro goals based on percentages
                let proteinPercent = Double(settings.proteinPercent ?? 30) / 100.0
                let carbsPercent = Double(settings.carbsPercent ?? 40) / 100.0
                let fatPercent = Double(settings.fatPercent ?? 30) / 100.0

                // Convert calorie percentages to grams
                // Protein: 4 cal/g, Carbs: 4 cal/g, Fat: 9 cal/g
                proteinGoal = (calorieGoal * proteinPercent) / 4.0
                carbGoal = (calorieGoal * carbsPercent) / 4.0
                fatGoal = (calorieGoal * fatPercent) / 9.0
            }
        } catch {
            print("⚠️ Failed to load nutrition goals: \(error.localizedDescription)")
            // Keep default values if loading fails
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
                // Show day name for current week
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE"
                return formatter.string(from: date)
            } else {
                // Show full date for older entries
                let formatter = DateFormatter()
                formatter.dateFormat = "d MMM yyyy"
                return formatter.string(from: date)
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