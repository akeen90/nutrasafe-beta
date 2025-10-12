import SwiftUI
import Foundation

struct NewWorkoutCreationView: View {
    let selectedDate: Date
    let template: WorkoutTemplate?
    let onWorkoutCreated: (WorkoutSessionSummary) -> Void
    
    @State private var showingExerciseSelector = false
    @State private var showingTemplates = false
    @State private var selectedExercises: [String] = []
    @State private var showingHistory = false
    @State private var showingDiscardAlert = false
    @State private var showingSaveTemplatePrompt = false
    @State private var workoutToComplete: WorkoutSessionSummary? = nil
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Content
            ScrollView {
                VStack(spacing: 24) {

                    // Workout Status Banner
                    if workoutManager.isWorkoutActive {
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Workout")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.primary)

                                    HStack(spacing: 16) {
                                        Label("Started \(Date().formatted(date: .omitted, time: .shortened))", systemImage: "clock")
                                            .font(.footnote)
                                            .foregroundColor(.secondary)

                                        Label("\(workoutManager.exercises.count) exercises", systemImage: "dumbbell")
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                VStack(spacing: 4) {
                                    Text(workoutManager.currentWorkoutDuration)
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.blue)

                                    Text("duration")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.blue.opacity(0.1))
                                )
                            }

                            // Progress indicator
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Workout Progress")
                                        .font(.callout.weight(.medium))
                                        .foregroundColor(.primary)

                                    Spacer()

                                    Text("Just started!")
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(.blue)
                                }

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.tertiarySystemBackground))
                                    .frame(height: 6)
                                    .overlay(
                                        HStack {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(.blue)
                                                .frame(width: 20)
                                            Spacer()
                                        }
                                    )
                            }
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)).shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4))
                        .padding(.horizontal, 16)
                    }
                    
                    // Quick Action Buttons - moved out of grid and into single section
                    VStack(spacing: 16) {
                        HStack {
                            Text("Quick Actions")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primary)
                            Spacer()
                        }

                        HStack(spacing: 16) {
                            // Add Exercise Button
                            Button(action: {
                                showingExerciseSelector = true
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundColor(.blue)

                                    Text("Add Exercise")
                                        .font(.callout.weight(.semibold))
                                        .foregroundColor(.primary)

                                    Text("Build your workout")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(height: 100)
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.secondarySystemBackground))
                                )
                            }
                            
                            // Templates Button
                            Button(action: {
                                showingTemplates = true
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "book.fill")
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundColor(.orange)

                                    Text("Templates")
                                        .font(.callout.weight(.semibold))
                                        .foregroundColor(.primary)

                                    Text("Pre-built workouts")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(height: 100)
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.secondarySystemBackground))
                                )
                            }
                                                    }
                    }
                    .padding(.horizontal, 16)
                    
                    // Current Exercises
                    if !workoutManager.exercises.isEmpty {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Current Exercises")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.primary)

                                Spacer()

                                if workoutManager.exercises.count > 1 {
                                    Button("Save as Template") {
                                        showingSaveTemplatePrompt = true
                                    }
                                    .font(.callout.weight(.medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .frame(height: 36)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(.blue))
                                }
                            }

                            LazyVStack(spacing: 8) {
                                ForEach(workoutManager.exercises) { exercise in
                                    ExerciseRowView(exercise: exercise)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Empty State
                    if workoutManager.exercises.isEmpty {
                        VStack(spacing: 32) {
                            VStack(spacing: 24) {
                                ZStack {
                                    Circle()
                                        .fill(.blue.opacity(0.1))
                                        .frame(width: 80, height: 80)

                                    Image(systemName: "dumbbell.fill")
                                        .font(.system(size: 32, weight: .light))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.blue, .green],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }

                                VStack(spacing: 8) {
                                    Text("Ready to Lift?")
                                        .font(.title)
                                        .foregroundColor(.primary)

                                    Text("Add exercises to start building your\nworkout and track your progress")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(2)
                                }
                            }

                            Button(action: {
                                showingExerciseSelector = true
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.headline)
                                    Text("Add Exercises")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                            }
                                                    }
                        .padding(.horizontal, 32)
                        .padding(.top, 48)
                    }
                    
                    Spacer(minLength: 120)
                }
            }
        }
        .navigationTitle("New Workout")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    if workoutManager.isWorkoutActive {
                        showingDiscardAlert = true
                    } else {
                        dismiss()
                    }
                }
                .foregroundColor(.blue)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Finish") {
                    completeWorkout()
                }
                .foregroundColor(workoutManager.isWorkoutActive ? .blue : .gray)
                .disabled(!workoutManager.isWorkoutActive)
            }
        }
        .sheet(isPresented: $showingExerciseSelector) {
            ExerciseSelectionView(selectedExercises: $selectedExercises)
                .onDisappear {
                    // When an exercise is selected, add it to the workout
                    if !selectedExercises.isEmpty {
                        for exerciseName in selectedExercises {
                            let exercise = ExerciseModel(
                                name: exerciseName,
                                category: .fullBody,
                                primaryMuscles: [],
                                secondaryMuscles: [],
                                equipment: .bodyweight,
                                movementType: .compound,
                                instructions: nil,
                                isPopular: false,
                                difficulty: 3
                            )
                            addExercise(exercise)
                        }
                        selectedExercises.removeAll()
                    }
                }
        }
        .sheet(isPresented: $showingTemplates) {
            Text("Template Selection")
        }
        .alert("Discard Workout?", isPresented: $showingDiscardAlert) {
            Button("Discard", role: .destructive) {
                // workoutManager.endWorkout()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your current workout progress will be lost.")
        }
        .alert("Save Template", isPresented: $showingSaveTemplatePrompt) {
            Button("Save") {
                saveAsTemplate()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Would you like to save this workout as a template?")
        }
    }
    
    private func addExercise(_ exercise: ExerciseModel) {
        let exerciseSummary = ExerciseSummary(
            name: exercise.name,
            exerciseType: exercise.name,
            sets: []
        )
        
        if !workoutManager.isWorkoutActive {
            workoutManager.startWorkout()
        }
        
        workoutManager.exercises.append(exerciseSummary)
        showingExerciseSelector = false
    }
    
    private func loadTemplate(_ template: WorkoutTemplate) {
        if !workoutManager.isWorkoutActive {
            workoutManager.startWorkout()
        }
        
        let exercises = template.exercises.map { exercise in
            ExerciseSummary(
                name: exercise.name,
                exerciseType: exercise.name,
                sets: []
            )
        }
        
        workoutManager.exercises = exercises
        showingTemplates = false
    }
    
    private func completeWorkout() {
        guard workoutManager.isWorkoutActive else { return }
        
        let summary = WorkoutSessionSummary(
            id: UUID(),
            name: "Workout", // workoutManager.workoutName,
            date: selectedDate,
            duration: 60, // workoutManager.workoutDuration,
            totalVolume: 0,
            averageHeartRate: nil,
            exercises: [], // workoutManager.exercises,
            status: .completed
        )
        
        // workoutManager.endWorkout()
        onWorkoutCreated(summary)
        dismiss()
    }
    
    private func saveAsTemplate() {
        let template = WorkoutTemplate(
            name: "Custom Template",
            exercises: workoutManager.exercises.map { summary in
                ExerciseModel(
                    name: summary.name,
                    category: .fullBody,
                    primaryMuscles: [],
                    secondaryMuscles: [],
                    equipment: .bodyweight,
                    movementType: .compound,
                    instructions: nil,
                    isPopular: false,
                    difficulty: 3
                )
            },
            category: .strength,
            estimatedDuration: 45,
            difficulty: .intermediate
        )
        
        var templates = UserDefaults.standard.object(forKey: "workoutTemplates") as? Data ?? Data()
        // Save template logic would go here
    }
    
    private func calculateCaloriesBurned() -> Int {
        // Basic calorie calculation based on workout duration
        let baseRate = 8 // calories per minute
        return workoutManager.workoutDuration * baseRate
    }
}

// Helper view for exercise rows
struct ExerciseRowView: View {
    let exercise: ExerciseSummary
    
    var body: some View {
        HStack(spacing: 16) {
            // Exercise icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("\(exercise.sets.count) sets completed")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Chevron with subtle background
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

