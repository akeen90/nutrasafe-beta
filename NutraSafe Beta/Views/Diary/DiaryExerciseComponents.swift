//
//  DiaryExerciseComponents.swift
//  NutraSafe Beta
//
//  Diary exercise-related components extracted from ContentView.swift
//

import SwiftUI
import HealthKit

// MARK: - Diary Exercise Summary Card
struct DiaryExerciseSummaryCard: View {
    let totalCalories: Double
    let workouts: [HKWorkout]
    let manualExercises: [DiaryExerciseItem]
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    private var totalDuration: Int {
        let healthKitDuration = Int(workouts.reduce(0) { $0 + $1.duration })
        let manualDuration = manualExercises.reduce(0) { $0 + $1.duration }
        return healthKitDuration + manualDuration
    }
    
    private var totalManualCalories: Double {
        manualExercises.reduce(0) { $0 + $1.calories }
    }
    
    private var combinedTotalCalories: Double {
        totalCalories + totalManualCalories
    }
    
    private var workoutCount: Int {
        workouts.count + manualExercises.count
    }
    
    private var todaysSteps: Int {
        // This will be populated by HealthKit steps data
        healthKitManager.stepCount
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Exercise Summary")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("27 August 2025")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(combinedTotalCalories))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.red)
                    
                    Text("energy burnt")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                DiaryExerciseStat(name: "Duration", value: "\(totalDuration)", unit: "min", color: .blue)
                DiaryExerciseStat(name: "Activities", value: "\(workoutCount)", unit: "", color: .green)
                DiaryExerciseStat(name: "Energy", value: "\(Int(combinedTotalCalories))", unit: "kcal", color: .red)
                DiaryExerciseStat(name: "Steps", value: "\(todaysSteps)", unit: "", color: .orange)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Diary Exercise Stat
struct DiaryExerciseStat: View {
    let name: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value + unit)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            Text(name)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Diary Exercise Card
struct DiaryExerciseCard: View {
    let exerciseType: String
    @State var exercises: [DiaryExerciseItem]
    let color: Color
    @State private var showingExerciseSelector = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)
                    
                    Text(exerciseType)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if !exercises.isEmpty {
                    Text("\(Int(exercises.reduce(0) { $0 + $1.calories }))) cal")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            if exercises.isEmpty {
                Button(action: {
                    showingExerciseSelector = true
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(color.opacity(0.1))
                                .frame(width: 36, height: 36)
                            
                            Circle()
                                .fill(color.opacity(0.2))
                                .frame(width: 30, height: 30)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(color)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Add \(exerciseType)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text("Track your \(exerciseType.lowercased()) workout")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 4)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                VStack(spacing: 8) {
                    ForEach(exercises, id: \.id) { exercise in
                        DiaryExerciseRow(exercise: exercise)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button("Delete") {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        exercises.removeAll { $0.id == exercise.id }
                                    }
                                }
                                .tint(.red)
                            }
                    }
                    
                    Button(action: {
                        showingExerciseSelector = true
                    }) {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(color.opacity(0.08))
                                    .frame(width: 24, height: 24)
                                
                                Circle()
                                    .fill(color.opacity(0.15))
                                    .frame(width: 20, height: 20)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(color)
                            }
                            
                            Text("Add more")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(color)
                            
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showingExerciseSelector) {
            ExerciseDropdownSelector(
                exerciseType: exerciseType,
                color: color,
                isPresented: $showingExerciseSelector
            )
        }
    }
}

// MARK: - Diary Exercise Row
struct DiaryExerciseRow: View {
    let exercise: DiaryExerciseItem
    @State private var showingWeightTraining = false
    
    var body: some View {
        Button(action: {
            if exercise.exerciseType == .resistance {
                showingWeightTraining = true
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(exercise.name)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                        
                        if exercise.exerciseType == .resistance {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("\(exercise.time) • \(exercise.duration) min")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(exercise.calories)) cal")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingWeightTraining) {
            WeightTrainingView()
        }
    }
}