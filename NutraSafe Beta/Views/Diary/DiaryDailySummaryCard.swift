//
//  DiaryDailySummaryCard.swift
//  NutraSafe Beta
//
//  Google-inspired daily nutrition summary with premium visual design
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
            // Premium header with refined typography
            VStack(spacing: 24) {
                // Date header with elevated design
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(formatDateForDaily(currentDate))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.primary, Color.primary.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("of \(Int(calorieGoal)) calories")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .opacity(0.8)
                    }

                    Spacer()
                    
                    // Net calories badge
                    VStack(spacing: 4) {
                        Text("\(Int(calorieGoal - Double(totalCalories)))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(calorieGoal - Double(totalCalories) > 0 ? .green : .orange)
                        
                        Text("remaining")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.secondarySystemBackground))
                    )
                }

                // Redesigned rings - more premium layout
                HStack(spacing: 0) {
                    // Main calorie ring - hero element
                    VStack(spacing: 12) {
                        ZStack {
                            // Sophisticated outer glow
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.blue.opacity(0.18),
                                            Color.blue.opacity(0.05),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 45,
                                        endRadius: 65
                                    )
                                )
                                .frame(width: 130, height: 130)
                            
                            // Background ring with premium gradient
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(.systemGray6).opacity(0.6),
                                            Color(.systemGray5).opacity(0.4)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 12
                                )
                                .frame(width: 100, height: 100)
                            
                            // Progress ring with refined gradient
                            Circle()
                                .trim(from: 0, to: min(1.0, Double(totalCalories) / calorieGoal))
                                .stroke(
                                    AngularGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: Color(hex: "#4A90E2"), location: 0),
                                            .init(color: Color(hex: "#667EEA"), location: 0.5),
                                            .init(color: Color(hex: "#764BA2"), location: 1.0)
                                        ]),
                                        center: .center,
                                        startAngle: .degrees(0),
                                        endAngle: .degrees(360 * min(1.0, Double(totalCalories) / calorieGoal))
                                    ),
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                )
                                .frame(width: 100, height: 100)
                                .rotationEffect(.degrees(-90))
                                .shadow(color: Color.blue.opacity(0.35), radius: 8, x: 0, y: 4)
                                .animation(.spring(response: 1.0, dampingFraction: 0.75), value: totalCalories)
                            
                            // Center value with refined typography
                            VStack(spacing: 2) {
                                Text("\(totalCalories)")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.primary, Color.primary.opacity(0.85)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .animation(.spring(response: 0.8, dampingFraction: 0.8), value: totalCalories)
                                
                                Text("kcal")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .opacity(0.7)
                            }
                        }
                        
                        // Label with refined styling
                        Text("FOOD")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.2)
                            .foregroundColor(.secondary)
                            .opacity(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Visual divider
                    Rectangle()
                        .fill(Color(.systemGray5).opacity(0.5))
                        .frame(width: 1, height: 100)
                        .padding(.vertical, 20)
                    
                    // Exercise ring with balanced design
                    VStack(spacing: 12) {
                        ZStack {
                            // Refined outer glow
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.green.opacity(0.18),
                                            Color.green.opacity(0.05),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 30,
                                        endRadius: 45
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            // Background ring
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(.systemGray6).opacity(0.6),
                                            Color(.systemGray5).opacity(0.4)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 10
                                )
                                .frame(width: 70, height: 70)
                            
                            // Progress ring with premium gradient
                            Circle()
                                .trim(from: 0, to: min(1.0, healthKitManager.exerciseCalories / 400.0))
                                .stroke(
                                    AngularGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: Color(hex: "#11998E"), location: 0),
                                            .init(color: Color(hex: "#38EF7D"), location: 0.7),
                                            .init(color: Color(hex: "#11998E"), location: 1.0)
                                        ]),
                                        center: .center,
                                        startAngle: .degrees(0),
                                        endAngle: .degrees(360 * min(1.0, healthKitManager.exerciseCalories / 400.0))
                                    ),
                                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                )
                                .frame(width: 70, height: 70)
                                .rotationEffect(.degrees(-90))
                                .shadow(color: Color.green.opacity(0.3), radius: 6, x: 0, y: 3)
                                .animation(.spring(response: 1.0, dampingFraction: 0.75), value: healthKitManager.exerciseCalories)
                            
                            // Center value with refined typography
                            VStack(spacing: 1) {
                                Text("\(Int(healthKitManager.exerciseCalories))")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                    .animation(.spring(response: 0.8, dampingFraction: 0.8), value: healthKitManager.exerciseCalories)
                                
                                Text("kcal")
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .opacity(0.7)
                            }
                        }
                        
                        Text("EXERCISE")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(1.0)
                            .foregroundColor(.secondary)
                            .opacity(0.7)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 8)
                
                // Premium divider
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color(.systemGray5).opacity(0.5),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .padding(.horizontal, -4)
                
                // Refined macro progress bars with better spacing
                VStack(spacing: 16) {
                    PremiumMacroProgressView(
                        name: "Protein",
                        current: totalProtein,
                        goal: proteinGoal,
                        unit: "g",
                        color: Color(hex: "#FF6B6B")
                    )
                    
                    PremiumMacroProgressView(
                        name: "Carbs",
                        current: totalCarbs,
                        goal: carbGoal,
                        unit: "g",
                        color: Color(hex: "#FFA93A")
                    )
                    
                    PremiumMacroProgressView(
                        name: "Fat",
                        current: totalFat,
                        goal: fatGoal,
                        unit: "g",
                        color: Color(hex: "#FFD93D")
                    )
                }
                .padding(.top, 8)
            }
            .padding(28)
        }
        .background(
            ZStack {
                // Premium card background
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                
                // Sophisticated gradient overlay
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color(.systemGray6).opacity(0.2),
                                Color(.systemGray5).opacity(0.15)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.black.opacity(0.04),
                            Color.black.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
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

// MARK: - Premium Macro Progress View
struct PremiumMacroProgressView: View {
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
    
    private var percentage: Int {
        Int((progress * 100).rounded())
    }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                HStack(spacing: 10) {
                    // Premium color indicator with depth
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [color.opacity(0.5), color.opacity(0.2), Color.clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 9
                                )
                            )
                            .frame(width: 18, height: 18)
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 12, height: 12)
                            .shadow(color: color.opacity(0.5), radius: 3, x: 0, y: 1.5)
                    }
                    
                    Text(name)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 3) {
                    HStack(spacing: 5) {
                        Text("\(Int(current.rounded()))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [color, color.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("/ \(Int(goal))")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .opacity(0.8)
                        
                        Text(unit)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .opacity(0.6)
                    }
                    
                    if remaining > 0 {
                        Text("\(Int(remaining.rounded())) left")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .opacity(0.7)
                    } else {
                        Text("\(percentage)% complete")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(color)
                    }
                }
            }
            
            // Premium progress bar with sophisticated design
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track with refined gradient
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(.systemGray6).opacity(0.6),
                                    Color(.systemGray5).opacity(0.4)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black.opacity(0.03), lineWidth: 1)
                        )
                    
                    // Progress fill with premium gradient and depth
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: color.opacity(0.75), location: 0),
                                    .init(color: color, location: 0.4),
                                    .init(color: color.opacity(0.95), location: 1.0)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(10, geometry.size.width * progress),
                            height: 12
                        )
                        .shadow(color: color.opacity(0.4), radius: 5, x: 0, y: 2)
                        .animation(.spring(response: 0.7, dampingFraction: 0.75), value: current)
                        .overlay(
                            // Refined highlight effect
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: Color.white.opacity(0.5), location: 0),
                                            .init(color: Color.white.opacity(0.2), location: 0.5),
                                            .init(color: Color.clear, location: 1.0)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 5)
                                .offset(y: -1.5),
                            alignment: .top
                        )
                        .overlay(
                            // Progress indicator dot for visual interest
                            Circle()
                                .fill(Color.white)
                                .frame(width: 6, height: 6)
                                .shadow(color: color.opacity(0.6), radius: 2, x: 0, y: 1)
                                .offset(x: max(3, geometry.size.width * progress) - 3),
                            alignment: .leading
                        )
                }
            }
            .frame(height: 12)
        }
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
