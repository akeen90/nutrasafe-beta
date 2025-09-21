//
//  NewWorkoutView.swift
//  NutraSafe Beta
//
//  Full workout creation and management system with exercise selection and set tracking
//  Extracted from ContentView.swift - 231 lines of comprehensive workout interface functionality
//

import SwiftUI
import Foundation

// MARK: - New Full Page Workout View

struct NewWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var restTimerManager: ExerciseRestTimerManager
    
    @State private var selectedExercises: [String] = []
    @State private var exerciseSets: [String: [WorkoutSet]] = [:]
    @State private var showingExercisePicker = false
    @State private var workoutName: String = ""
    @State private var workoutStartTime: Date?
    @State private var notes = ""
    @State private var elapsedTime: TimeInterval = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // MARK: - Enhanced Workout Header
                VStack(spacing: 0) {
                    // Main Header Card
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("Workout Name", text: $workoutName)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .foregroundColor(.primary)

                                HStack(spacing: 12) {
                                    Label("Started \(formatTime(workoutStartTime ?? Date()))", systemImage: "clock.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)

                                    Label("0 exercises", systemImage: "dumbbell.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            // Enhanced Duration Display
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 64, height: 64)

                                    VStack(spacing: 2) {
                                        Text(formatWorkoutDuration())
                                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                                            .foregroundColor(.primary)

                                        Text("duration")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }

                        // Progress Bar
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Workout Progress")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)

                                Spacer()

                                Text("Just started!")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.blue)
                            }

                            RoundedRectangle(cornerRadius: 4)
                                .fill(.blue.opacity(0.1))
                                .frame(height: 6)
                                .overlay(
                                    HStack {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(
                                                LinearGradient(
                                                    colors: [.blue, .purple],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: 20)
                                        Spacer()
                                    }
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
                
                // MARK: - Exercise Content
                if selectedExercises.isEmpty {
                    // Enhanced Add First Exercise
                    VStack(spacing: 0) {
                        Spacer()

                        VStack(spacing: 32) {
                            // Hero Section
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 80, height: 80)

                                    Image(systemName: "dumbbell.fill")
                                        .font(.system(size: 32, weight: .light))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }

                                VStack(spacing: 8) {
                                    Text("Ready to Lift?")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)

                                    Text("Add exercises to start building your\nworkout and track your progress")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(2)
                                }
                            }

                            // Enhanced Add Button
                            Button(action: {
                                showingExercisePicker = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                    Text("Add Exercises")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(SpringyButtonStyle())
                        }
                        .padding(.horizontal, 32)

                        Spacer()
                    }
                } else {
                    // MARK: - Vertical Exercise Flow
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(selectedExercises, id: \.self) { exercise in
                                let index = selectedExercises.firstIndex(of: exercise) ?? 0
                                ExerciseWorkoutCard(
                                    exercise: exercise,
                                    sets: exerciseSets[exercise] ?? [],
                                    onAddSet: { set in
                                        addSet(to: exercise, set: set)
                                    },
                                    onRemoveSet: { setIndex in
                                        removeSet(from: exercise, at: setIndex)
                                    },
                                    onMove: { fromIndex, toIndex in
                                        moveExercise(from: fromIndex, to: toIndex)
                                    },
                                    exerciseIndex: index,
                                    totalExercises: selectedExercises.count
                                )
                            }
                            .onDelete(perform: deleteExercise)
                            
                            // MARK: - Add More Exercises Button
                            Button(action: {
                                showingExercisePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                    Text("Add" + " More Exercises")
                                }
                                .font(.body)
                                .foregroundColor(.blue)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExerciseSelectionView(
                selectedExercises: $selectedExercises
            )
        }
        .onAppear {
            if workoutName.isEmpty {
                workoutName = "Workout"
            }
        }
        // Note: Rest timer overlay temporarily disabled due to compilation issues
    }
    
    // MARK: - Set Management Methods
    
    private func addSet(to exercise: String, set: WorkoutSet) {
        if exerciseSets[exercise] != nil {
            exerciseSets[exercise]!.append(set)
        } else {
            exerciseSets[exercise] = [set]
            // Start workout timer when first set is added to the workout
            if workoutStartTime == nil {
                startWorkoutTimer()
            }
        }
    }
    
    private func removeSet(from exercise: String, at index: Int) {
        exerciseSets[exercise]?.remove(at: index)
    }
    
    // MARK: - Exercise Management Methods
    
    private func moveExercise(from source: Int, to destination: Int) {
        guard source != destination && 
              source < selectedExercises.count && 
              destination < selectedExercises.count else { return }
        
        let movedExercise = selectedExercises.remove(at: source)
        selectedExercises.insert(movedExercise, at: destination)
    }
    
    private func deleteExercise(at offsets: IndexSet) {
        for index in offsets {
            let exercise = selectedExercises[index]
            // Remove the exercise and its sets
            selectedExercises.remove(at: index)
            exerciseSets.removeValue(forKey: exercise)
        }
    }
    
    // MARK: - Workout Management Methods
    
    private func finishWorkout() {
        // TODO: Save workout to history
        dismiss()
    }
    
    // MARK: - Formatting Methods
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatWorkoutDuration() -> String {
        let minutes = Int(elapsedTime) / Int(60.0)
        let seconds = Int(elapsedTime) % Int(60.0)
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Timer Management
    
    private func startWorkoutTimer() {
        guard workoutStartTime == nil else { return } // Already started
        
        workoutStartTime = Date()
        
        // Start updating elapsed time every second
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if let startTime = workoutStartTime {
                elapsedTime = Date().timeIntervalSince(startTime)
            } else {
                timer.invalidate()
            }
        }
    }
}