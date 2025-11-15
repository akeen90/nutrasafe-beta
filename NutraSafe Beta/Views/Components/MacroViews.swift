//
//  MacroViews.swift
//  NutraSafe Beta
//
//  Macro nutrient display components extracted from ContentView.swift
//

import SwiftUI

// MARK: - Macro Progress View
struct MacroProgressView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    @EnvironmentObject var healthKitManager: HealthKitManager

    @State private var trackedFoods: [DiaryFoodItem] = []
    @State private var trackedExercises: [ExerciseEntry] = []
    @State private var userCaloricGoal: Int = 2000
    
    private var totalCaloriesConsumed: Int {
        trackedFoods.reduce(0) { $0 + $1.calories }
    }
    
    private var totalCaloriesBurned: Int {
        trackedExercises.reduce(0) { $0 + $1.caloriesBurned }
    }
    
    private var netCalories: Int {
        totalCaloriesConsumed - totalCaloriesBurned
    }
    
    private var remainingCalories: Int {
        userCaloricGoal - netCalories
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Calorie Goal")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(remainingCalories)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(remainingCalories >= 0 ? .green : .red)
                
                Text("remaining")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue, .green]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: min(CGFloat(netCalories) / CGFloat(userCaloricGoal) * geometry.size.width, geometry.size.width), height: 12)
                }
            }
            .frame(height: 12)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            Task {
                await loadCaloricGoal()
            }
        }
    }

    private func loadCaloricGoal() async {
        do {
            let settings = try await firebaseManager.getUserSettings()
            await MainActor.run {
                if let goal = settings.caloricGoal {
                    userCaloricGoal = goal
                }
            }
        } catch {
            #if DEBUG
            print("❌ Error loading caloric goal: \(error.localizedDescription)")
            #endif
        }
    }
}

// MARK: - Compact Macro Item
struct CompactMacroItem: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Text("\(value)g")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

// MARK: - Macro Label
struct MacroLabel: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text(String(format: "%.0fg", value))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
        }
    }
}