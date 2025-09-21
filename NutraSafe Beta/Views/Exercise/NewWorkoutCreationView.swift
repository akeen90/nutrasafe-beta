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
                VStack(spacing: 16) {
                    
                    // Workout Status Banner
                    if workoutManager.isWorkoutActive {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.green)
                                
                                Text("Workout in Progress")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.green)
                                
                                Spacer()
                                
                                Text(workoutManager.currentWorkoutDuration)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("\(workoutManager.exercises.count) exercises")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.green.opacity(0.05))
                        )
                        .padding(.horizontal, 16)
                    }
                    
                    // Quick Action Buttons
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        
                        // Add Exercise Button
                        Button(action: {
                            showingExerciseSelector = true
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(.blue)
                                
                                Text("Add Exercise")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text("Build your workout")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(height: 120)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                        }
                        .buttonStyle(.plain)
                        
                        // Templates Button
                        Button(action: {
                            showingTemplates = true
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(.orange)
                                
                                Text("Templates")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text("Pre-built workouts")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(height: 120)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    
                    // Current Exercises
                    if !workoutManager.exercises.isEmpty {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Current Exercises")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if workoutManager.exercises.count > 1 {
                                    Button("Save as Template") {
                                        showingSaveTemplatePrompt = true
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            LazyVStack(spacing: 8) {
                                ForEach(workoutManager.exercises) { exercise in
                                    ExerciseRowView(exercise: exercise)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    
                    // Empty State
                    if workoutManager.exercises.isEmpty {
                        VStack(spacing: 24) {
                            Image(systemName: "dumbbell")
                                .font(.system(size: 48, weight: .light))
                                .foregroundColor(.secondary)
                            
                            VStack(spacing: 8) {
                                Text("Start Your Workout")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("Add exercises or choose a template to begin")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 60)
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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("\(exercise.sets.count) sets completed")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}