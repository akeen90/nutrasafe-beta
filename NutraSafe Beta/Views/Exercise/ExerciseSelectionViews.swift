//
//  ExerciseSelectionViews.swift
//  NutraSafe Beta
//
//  Exercise selection and workout view components extracted from ContentView.swift
//  Contains DiaryExerciseView, ComprehensiveWorkoutView, ExerciseSelectionView, and ExerciseDropdownSelector
//

import SwiftUI

// MARK: - Diary Exercise View

struct DiaryExerciseView: View {
    enum ExerciseTab: String, CaseIterable {
        case workouts = "Workouts"
        case stats = "Stats"
        case history = "History"
        
        var icon: String {
            switch self {
            case .workouts: return "figure.strengthtraining.traditional"
            case .stats: return "chart.bar.fill"
            case .history: return "clock"
            }
        }
    }
    
    let selectedDate: Date
    @EnvironmentObject var diaryDataManager: DiaryDataManager
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var workouts: [WorkoutSessionSummary] = []
    @State private var totalCaloriesBurned: Int = 0
    @State private var hasActiveWorkout: Bool = false // TODO: Connect to actual workout state
    
    // Quick workout templates for the horizontal scroll
    private var quickWorkoutTemplates: [WorkoutTemplate] {
        [
            WorkoutTemplate(
                id: UUID(),
                name: "Push Day (Beginner)",
                exercises: [
                    ExerciseModel(name: "Push-ups", category: .chest, primaryMuscles: ["Chest", "Triceps"], secondaryMuscles: ["Shoulders"], equipment: .bodyweight, movementType: .compound, instructions: nil, isPopular: true, difficulty: 2),
                    ExerciseModel(name: "Dumbbell Shoulder Press", category: .shoulders, primaryMuscles: ["Shoulders"], secondaryMuscles: ["Triceps"], equipment: .dumbbell, movementType: .compound, instructions: nil, isPopular: true, difficulty: 2),
                    ExerciseModel(name: "Dumbbell Chest Press", category: .chest, primaryMuscles: ["Chest"], secondaryMuscles: ["Triceps"], equipment: .dumbbell, movementType: .compound, instructions: nil, isPopular: true, difficulty: 2),
                    ExerciseModel(name: "Tricep Dips", category: .triceps, primaryMuscles: ["Triceps"], secondaryMuscles: [], equipment: .bodyweight, movementType: .compound, instructions: nil, isPopular: true, difficulty: 2)
                ],
                category: .strength,
                estimatedDuration: 30,
                difficulty: .beginner,
                icon: "💪",
                description: nil
            ),
            WorkoutTemplate(
                id: UUID(),
                name: "Pull Day (Beginner)",
                exercises: [
                    ExerciseModel(name: "Pull-ups", category: .back, primaryMuscles: ["Lats", "Biceps"], secondaryMuscles: ["Rhomboids"], equipment: .bodyweight, movementType: .compound, instructions: nil, isPopular: true, difficulty: 3),
                    ExerciseModel(name: "Bent-over Dumbbell Row", category: .back, primaryMuscles: ["Lats", "Rhomboids"], secondaryMuscles: ["Biceps"], equipment: .dumbbell, movementType: .compound, instructions: nil, isPopular: true, difficulty: 2),
                    ExerciseModel(name: "Dumbbell Curls", category: .biceps, primaryMuscles: ["Biceps"], secondaryMuscles: [], equipment: .dumbbell, movementType: .isolation, instructions: nil, isPopular: true, difficulty: 1),
                    ExerciseModel(name: "Face Pulls", category: .shoulders, primaryMuscles: ["Rear Delts"], secondaryMuscles: ["Rhomboids"], equipment: .cable, movementType: .isolation, instructions: nil, isPopular: true, difficulty: 2)
                ],
                category: .strength,
                estimatedDuration: 35,
                difficulty: .beginner,
                icon: "🏋️",
                description: nil
            ),
            WorkoutTemplate(
                id: UUID(),
                name: "Leg Day (Beginner)",
                exercises: [
                    ExerciseModel(name: "Goblet Squat", category: .legs, primaryMuscles: ["Quadriceps", "Glutes"], secondaryMuscles: ["Core"], equipment: .dumbbell, movementType: .compound, instructions: nil, isPopular: true, difficulty: 2),
                    ExerciseModel(name: "Romanian Deadlift", category: .legs, primaryMuscles: ["Hamstrings", "Glutes"], secondaryMuscles: ["Lower Back"], equipment: .dumbbell, movementType: .compound, instructions: nil, isPopular: true, difficulty: 2),
                    ExerciseModel(name: "Lunges", category: .legs, primaryMuscles: ["Quadriceps", "Glutes"], secondaryMuscles: ["Hamstrings"], equipment: .bodyweight, movementType: .compound, instructions: nil, isPopular: true, difficulty: 2),
                    ExerciseModel(name: "Calf Raises", category: .legs, primaryMuscles: ["Calves"], secondaryMuscles: [], equipment: .bodyweight, movementType: .isolation, instructions: nil, isPopular: true, difficulty: 1)
                ],
                category: .strength,
                estimatedDuration: 40,
                difficulty: .beginner,
                icon: "🦵",
                description: nil
            ),
            WorkoutTemplate(
                id: UUID(),
                name: "HIIT Cardio Blast",
                exercises: [
                    ExerciseModel(name: "High Knees", category: .cardio, primaryMuscles: ["Legs", "Core"], secondaryMuscles: [], equipment: .bodyweight, movementType: .compound, instructions: nil, isPopular: true, difficulty: 2),
                    ExerciseModel(name: "Jump Squats", category: .cardio, primaryMuscles: ["Quadriceps", "Glutes"], secondaryMuscles: ["Calves"], equipment: .bodyweight, movementType: .compound, instructions: nil, isPopular: true, difficulty: 3),
                    ExerciseModel(name: "Burpees", category: .cardio, primaryMuscles: ["Full Body"], secondaryMuscles: [], equipment: .bodyweight, movementType: .compound, instructions: nil, isPopular: true, difficulty: 3),
                    ExerciseModel(name: "Mountain Climbers", category: .cardio, primaryMuscles: ["Core", "Shoulders"], secondaryMuscles: ["Legs"], equipment: .bodyweight, movementType: .compound, instructions: nil, isPopular: true, difficulty: 2)
                ],
                category: .hiit,
                estimatedDuration: 20,
                difficulty: .advanced,
                icon: "⚡",
                description: nil
            ),
            WorkoutTemplate(
                id: UUID(),
                name: "Core & Abs Focus",
                exercises: [
                    ExerciseModel(name: "Plank", category: .core, primaryMuscles: ["Core"], secondaryMuscles: ["Shoulders"], equipment: .bodyweight, movementType: .isolation, instructions: nil, isPopular: true, difficulty: 2),
                    ExerciseModel(name: "Russian Twists", category: .core, primaryMuscles: ["Obliques"], secondaryMuscles: ["Core"], equipment: .bodyweight, movementType: .isolation, instructions: nil, isPopular: true, difficulty: 2),
                    ExerciseModel(name: "Dead Bug", category: .core, primaryMuscles: ["Core"], secondaryMuscles: [], equipment: .bodyweight, movementType: .isolation, instructions: nil, isPopular: true, difficulty: 2),
                    ExerciseModel(name: "Bicycle Crunches", category: .core, primaryMuscles: ["Abs", "Obliques"], secondaryMuscles: [], equipment: .bodyweight, movementType: .isolation, instructions: nil, isPopular: true, difficulty: 1)
                ],
                category: .strength,
                estimatedDuration: 20,
                difficulty: .advanced,
                icon: "🎯",
                description: nil
            ),
            WorkoutTemplate(
                id: UUID(),
                name: "Full Body Circuit",
                exercises: [
                    ExerciseModel(name: "Burpees", category: .cardio, primaryMuscles: ["Full Body"], secondaryMuscles: [], equipment: .bodyweight, movementType: .compound, instructions: nil, isPopular: true, difficulty: 3),
                    ExerciseModel(name: "Mountain Climbers", category: .cardio, primaryMuscles: ["Core", "Shoulders"], secondaryMuscles: ["Legs"], equipment: .bodyweight, movementType: .compound, instructions: nil, isPopular: true, difficulty: 2),
                    ExerciseModel(name: "Jumping Jacks", category: .cardio, primaryMuscles: ["Full Body"], secondaryMuscles: [], equipment: .bodyweight, movementType: .compound, instructions: nil, isPopular: true, difficulty: 1),
                    ExerciseModel(name: "Plank", category: .core, primaryMuscles: ["Core"], secondaryMuscles: ["Shoulders"], equipment: .bodyweight, movementType: .isolation, instructions: nil, isPopular: true, difficulty: 2)
                ],
                category: .strength,
                estimatedDuration: 25,
                difficulty: .intermediate,
                icon: "🔥",
                description: nil
            )
        ]
    }
    
    private var dateDisplayText: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(selectedDate) {
            return "Today's Activity"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday's Activity"
        } else if calendar.isDateInTomorrow(selectedDate) {
            return "Tomorrow's Activity"
        } else {
            formatter.dateFormat = "EEEE's Activity"
            return formatter.string(from: selectedDate)
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                
                // Active Workout Banner - Enhanced Design
                if hasActiveWorkout {
                    NavigationLink(destination: NewWorkoutCreationView(selectedDate: selectedDate, template: nil, onWorkoutCreated: { workout in
                        addWorkout(workout)
                        hasActiveWorkout = false
                    })) {
                        VStack(spacing: 0) {
                            HStack(spacing: 16) {
                                // Animated workout icon
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 44 + 4, height: 44 + 4)
                                    
                                    Image(systemName: "figure.strengthtraining.traditional")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Text("Workout in Progress".uppercased())
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                            .tracking(0.5)
                                        
                                        // Pulsing live indicator
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 6, height: 6)
                                            .opacity(0.9)
                                    }
                                    
                                    Text("Tap to continue your session")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    // Time or progress indicator
                                    Text("Active Session")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.white.opacity(0.15))
                                        .cornerRadius(8)
                                }
                                
                                Spacer()
                                
                                VStack(spacing: 4) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Text("Continue Workout")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                        }
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.orange.opacity(0.9),
                                    Color.red.opacity(0.9)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            // Subtle pattern overlay
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.orange.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 16)
                }
                
                // Activity Summary
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dateDisplayText)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("\(totalCaloriesBurned) calories burned")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Start New Workout Button  
                Button(action: {
                    hasActiveWorkout = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Start New Workout")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Create a custom workout")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(24)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                
                // Workout Templates Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Workout Templates")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button("See All") {
                            // Show templates modal if needed
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 16)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) {
                            ForEach(quickWorkoutTemplates, id: \.name) { template in
                                NavigationLink(destination: NewWorkoutCreationView(selectedDate: selectedDate, template: template, onWorkoutCreated: { workout in
                                    addWorkout(workout)
                                    hasActiveWorkout = false
                                })) {
                                    WorkoutTemplateQuickCard(template: template) { }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 20)
                
                // Recent Workouts Section
                if !workouts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Workouts")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        
                        // Workout Cards
                        ForEach(workouts.sorted(by: { $0.date > $1.date })) { workout in
                            WorkoutSummaryCard(workout: workout)
                                .padding(.horizontal, 16)
                        }
                    }
                }
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
        }
        .onAppear {
            loadWorkoutDataForDate()
        }
        .onChange(of: selectedDate) { _ in
            saveWorkoutDataForCurrentDate()
            loadWorkoutDataForDate()
        }
    }
    
    private func loadWorkoutDataForDate() {
        workouts = diaryDataManager.getWorkoutData(for: selectedDate)
        calculateTotalCalories()
    }
    
    private func saveWorkoutDataForCurrentDate() {
        diaryDataManager.saveWorkoutData(for: selectedDate, workouts: workouts)
    }
    
    private func addWorkout(_ workout: WorkoutSessionSummary) {
        workouts.append(workout)
        saveWorkoutDataForCurrentDate()
        calculateTotalCalories()
    }
    
    private func calculateTotalCalories() {
        // Estimate calories based on workout duration and type
        totalCaloriesBurned = workouts.reduce(0) { total, workout in
            total + (workout.duration * 8) // Rough estimate: 8 calories per minute
        }
    }
}

// MARK: - Comprehensive Workout View

struct ComprehensiveWorkoutView: View {
    @State var workoutSession: WorkoutSession
    let onComplete: (WorkoutSession) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExercises: [String] = []
    @State private var currentExerciseIndex: Int = 0
    @State private var exerciseSets: [String: [WorkoutSet]] = [:]
    @State private var reps: String = ""
    @State private var weight: String = ""
    @State private var isTimerActive = false
    @State private var showingExercisePicker = false
    @State private var workoutNotes = ""
    
    // Get exercises from comprehensive database
    private var resistanceExercises: [String: [String]] {
        var groups: [String: [String]] = [:]
        
        // Get all resistance exercises from the comprehensive database
        let allExercises = ComprehensiveExerciseDatabase.shared.allExercises
        
        for exercise in allExercises {
            // Skip cardio exercises
            guard exercise.movementType != .cardio else { continue }
            
            let categoryName = exercise.category.rawValue
            if groups[categoryName] == nil {
                groups[categoryName] = []
            }
            groups[categoryName]?.append(exercise.name)
        }
        
        // Sort exercises alphabetically within each category
        for key in groups.keys {
            groups[key]?.sort()
        }
        
        return groups
    }
    
    private var currentExercise: String {
        selectedExercises.isEmpty ? "" : (currentExerciseIndex < selectedExercises.count ? selectedExercises[currentExerciseIndex] : "")
    }
    
    private var currentSets: [WorkoutSet] {
        exerciseSets[currentExercise] ?? []
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Workout Header
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(workoutSession.name)
                                .font(.title2)
                                .font(.system(size: 16, weight: .bold))
                            
                            Text("Started \(formatTime(workoutSession.startTime ?? Date()))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Workout Timer
                        VStack {
                            Text("Duration")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatDuration(0)) // Placeholder duration
                                .font(.title3)
                                .font(.headline.weight(.semibold))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    Divider()
                }
                .background(Color(.systemGray6))
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Exercise Selection
                        if selectedExercises.isEmpty {
                            VStack(spacing: 20) {
                                Text("Add Exercises")
                                    .font(.title2)
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(.primary)
                                
                                Text("Select exercises to build your workout")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                Button(action: {
                                    showingExercisePicker = true
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title3)
                                        
                                        Text("Add Exercises")
                                            .font(.body)
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(.blue)
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 40)
                        } else {
                            // Active Exercise Interface
                            VStack(spacing: 24) {
                                // Exercise Navigation Header
                                VStack(spacing: 12) {
                                    HStack {
                                        Button(action: {
                                            showingExercisePicker = true
                                        }) {
                                            HStack {
                                                Image(systemName: "plus.circle")
                                                Text("Add More")
                                            }
                                            .font(.body)
                                            .foregroundColor(.blue)
                                        }
                                        
                                        Spacer()
                                        
                                        Text("\(currentExerciseIndex + 1) of \(selectedExercises.count)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 24)
                                    
                                    // Exercise picker/navigator
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(Array(selectedExercises.enumerated()), id: \.offset) { index, exercise in
                                                Button(action: {
                                                    currentExerciseIndex = index
                                                }) {
                                                    VStack(spacing: 4) {
                                                        Text(exercise)
                                                            .font(.body)
                                                            .fontWeight(index == currentExerciseIndex ? .semibold : .regular)
                                                            .foregroundColor(index == currentExerciseIndex ? .white : .primary)
                                                        
                                                        let sets = exerciseSets[exercise]?.count ?? 0
                                                        if sets > 0 {
                                                            Text("\(sets) sets")
                                                                .font(.caption)
                                                                .foregroundColor(index == currentExerciseIndex ? .white.opacity(0.9) : .secondary)
                                                        }
                                                    }
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 12)
                                                    .background(index == currentExerciseIndex ? .blue : Color(.systemGray6))
                                                    .cornerRadius(8)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 24)
                                    }
                                }
                                
                                // Current Exercise Header
                                VStack(spacing: 8) {
                                    Text(currentExercise)
                                        .font(.title2)
                                        .font(.system(size: 16, weight: .bold))
                                    
                                    if !currentSets.isEmpty {
                                        Text("\(currentSets.count) sets completed")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 24)
                                
                                // Set Input Interface
                                VStack(spacing: 16) {
                                    HStack(spacing: 24) {
                                        VStack {
                                            Text("Weight (\("kg"))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            TextField("0", text: $weight)
                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                                .keyboardType(.decimalPad)
                                                .frame(width: 80)
                                        }
                                        
                                        VStack {
                                            Text("Reps")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            TextField("0", text: $reps)
                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                                .keyboardType(.numberPad)
                                                .frame(width: 60)
                                        }
                                        
                                        Button(action: addSet) {
                                            Text("Add Set")
                                                .font(.headline.weight(.semibold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 24)
                                                .padding(.vertical, 12)
                                                .background(canAddSet ? .blue : Color.gray)
                                                .cornerRadius(8)
                                        }
                                        .disabled(!canAddSet)
                                    }
                                    
                                }
                                .padding(.horizontal, 24)
                                
                                // Sets History
                                if !currentSets.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Sets")
                                            .font(.headline)
                                            .padding(.horizontal, 24)
                                        
                                        ForEach(Array(currentSets.enumerated()), id: \.offset) { index, set in
                                            HStack {
                                                Text("Set \(index + 1)")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                    .frame(width: 50, alignment: .leading)
                                                
                                                Spacer()
                                                
                                                Text("\(String(format: "%.1f", set.weight)) \("kg")")
                                                    .font(.subheadline)
                                                    .frame(width: 60, alignment: .center)
                                                
                                                Text("× \(set.reps)")
                                                    .font(.subheadline)
                                                    .frame(width: 40, alignment: .center)
                                                
                                                Text("\(String(format: "%.1f", Double(set.reps) * set.weight)) \("kg")")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .frame(width: 60, alignment: .trailing)
                                            }
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 8)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                            .padding(.horizontal, 24)
                                        }
                                    }
                                }
                                
                                // Exercise Actions
                                HStack(spacing: 12) {
                                    Button("Add More Exercises") {
                                        showingExercisePicker = true
                                    }
                                    .foregroundColor(.blue)
                                    
                                    Button("Next Exercise") {
                                        // Move to next exercise or finish if this is the last one
                                        if currentExerciseIndex < selectedExercises.count - 1 {
                                            currentExerciseIndex += 1
                                        }
                                    }
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(.green)
                                    .cornerRadius(8)
                                    .disabled(currentSets.isEmpty)
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                // Workout Actions
                VStack(spacing: 12) {
                    Divider()
                    
                    HStack(spacing: 16) {
                        Button("Cancel Workout") {
                            dismiss()
                        }
                        .foregroundColor(.red)
                        
                        Spacer()
                        
                        Button("Finish Workout") {
                            finishWorkout()
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(workoutSession.exercises.isEmpty ? Color.gray : .blue)
                        .cornerRadius(8)
                        .disabled(workoutSession.exercises.isEmpty)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .background(Color(.systemGray6))
            }
        .sheet(isPresented: $showingExercisePicker) {
            ExerciseSelectionView(
                selectedExercises: $selectedExercises
            )
        }
        .onAppear {
            print("🏋️‍♂️ ComprehensiveWorkoutView appeared!")
            print("🏋️‍♂️ Workout session: \(workoutSession.name)")
            print("🏋️‍♂️ Workout session: \(workoutSession.name)")
            print("🏋️‍♂️ Start time: \(workoutSession.startTime)")
        }
    }
    
    private var canAddSet: Bool {
        !weight.isEmpty && !reps.isEmpty && Double(weight) ?? 0 > 0 && Int(reps) ?? 0 > 0
    }
    
    private func addSet() {
        guard !currentExercise.isEmpty,
              let weightValue = Double(weight),
              let repsValue = Int(reps),
              weightValue > 0, repsValue > 0 else { return }
        
        let newSet = WorkoutSet(weight: weightValue, reps: repsValue)
        
        // Add to exercise-specific sets
        if exerciseSets[currentExercise] != nil {
            exerciseSets[currentExercise]!.append(newSet)
        } else {
            exerciseSets[currentExercise] = [newSet]
        }
        
        // Clear inputs
        weight = ""
        reps = ""
        
        // Rest timer functionality removed
        
        print("✅ Added set to \(currentExercise): \(repsValue) reps @ \(weightValue) kg")
    }
    
    private func finishCurrentExercise() {
        guard !currentExercise.isEmpty && !currentSets.isEmpty else { return }
        
        let exercise = WorkoutExercise(
            name: currentExercise,
            sets: currentSets
        )
        
        workoutSession = WorkoutSession(
            userId: workoutSession.userId,
            name: workoutSession.name,
            exercises: workoutSession.exercises + [exercise]
        )
        
        // Clear sets for current exercise
        exerciseSets[currentExercise] = []
        print("🏋️ Finished exercise: \(currentExercise)")
    }
    
    private func finishWorkout() {
        // Finish current exercise if any
        if !currentExercise.isEmpty && !currentSets.isEmpty {
            finishCurrentExercise()
        }
        
        // Update workout end time
        let completedWorkout = WorkoutSession(
            userId: workoutSession.userId,
            name: workoutSession.name,
            exercises: workoutSession.exercises
        )
        
        onComplete(completedWorkout)
        dismiss()
        print("🎉 Workout completed!")
    }
    
    private func getMuscleGroups(for exercise: String) -> [String] {
        for (muscleGroup, exercises) in resistanceExercises {
            if exercises.contains(exercise) {
                return [muscleGroup]
            }
        }
        return []
    }
    
    private func muscleGroupIcon(_ muscleGroup: String) -> String {
        switch muscleGroup {
        case "Chest": return "figure.strengthtraining.traditional"
        case "Back": return "figure.strengthtraining.functional"
        case "Shoulders": return "figure.arms.open"
        case "Arms": return "figure.flexibility"
        case "Legs": return "figure.walk"
        case "Core": return "figure.core.training"
        default: return "dumbbell.fill"
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Exercise Selection View

struct ExerciseSelectionView: View {
    @Binding var selectedExercises: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedTab: ExerciseTab = .resistance // Default to resistance
    @State private var selectedMuscleGroup: MuscleGroupFilter = .all
    
    enum ExerciseTab: String, CaseIterable {
        case resistance = "Resistance"
        case cardio = "Cardio"
        
        var icon: String {
            switch self {
            case .resistance: return "dumbbell.fill"
            case .cardio: return "heart.fill"
            }
        }
    }
    
    enum MuscleGroupFilter: String, CaseIterable {
        case all = "All"
        case chest = "Chest"
        case back = "Back"
        case shoulders = "Shoulders"
        case biceps = "Biceps"
        case triceps = "Triceps"
        case legs = "Legs"
        case calves = "Calves"
        case core = "Core"
        
        var displayName: String {
            return rawValue
        }
    }
    
    // Resistance exercises from comprehensive database with enhanced filtering
    private var resistanceExercises: [ExerciseModel] {
        var filtered = ComprehensiveExerciseDatabase.shared.allExercises.filter { exercise in
            exercise.movementType != ExerciseMovementType.cardio
        }
        
        // Filter by muscle group
        if selectedMuscleGroup != .all {
            filtered = filtered.filter { exercise in
                exercise.category.rawValue.lowercased() == selectedMuscleGroup.rawValue.lowercased()
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.category.rawValue.localizedCaseInsensitiveContains(searchText) ||
                exercise.primaryMuscles.joined(separator: " ").localizedCaseInsensitiveContains(searchText) ||
                exercise.equipment.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort alphabetically
        return filtered.sorted { $0.name < $1.name }
    }
    
    // Cardio exercises with MET values for calorie estimation
    private var cardioExercises: [CardioExercise] {
        let exercises = [
            // COMPREHENSIVE CARDIO DATABASE (Alphabetical with MET Values)
            // Distance-tracking exercises: Running, Cycling, Walking, Swimming, Hiking
            // Time-only exercises: Aerobics, Dancing, Sports, Strength training
            CardioExercise(name: "Aerobics (High Impact)", metValue: 7.3, icon: "figure.flexibility", requiresDistance: false),
            CardioExercise(name: "Aerobics (Low Impact)", metValue: 5.0, icon: "figure.flexibility", requiresDistance: false),
            CardioExercise(name: "Badminton", metValue: 5.5, icon: "tennisball.fill", requiresDistance: false),
            CardioExercise(name: "Baseball", metValue: 5.0, icon: "baseball.fill", requiresDistance: false),
            CardioExercise(name: "Basketball", metValue: 8.0, icon: "basketball.fill", requiresDistance: false),
            CardioExercise(name: "Beach Volleyball", metValue: 8.0, icon: "volleyball.fill", requiresDistance: false),
            CardioExercise(name: "Boxing", metValue: 12.8, icon: "figure.boxing", requiresDistance: false),
            CardioExercise(name: "Burpees", metValue: 8.0, icon: "figure.flexibility", requiresDistance: false),
            CardioExercise(name: "Circuit Training", metValue: 8.0, icon: "figure.strengthtraining.traditional", requiresDistance: false),
            CardioExercise(name: "CrossFit", metValue: 5.6, icon: "figure.strengthtraining.functional", requiresDistance: false),
            CardioExercise(name: "Cycling (Leisure)", metValue: 6.8, icon: "bicycle", requiresDistance: true),
            CardioExercise(name: "Cycling (Moderate)", metValue: 8.0, icon: "bicycle", requiresDistance: true),
            CardioExercise(name: "Cycling (Vigorous)", metValue: 10.0, icon: "bicycle", requiresDistance: true),
            CardioExercise(name: "Cycling (Racing)", metValue: 12.0, icon: "bicycle", requiresDistance: true),
            CardioExercise(name: "Cycling (Fast Racing)", metValue: 16.0, icon: "bicycle", requiresDistance: true),
            CardioExercise(name: "Dancing (Ballroom)", metValue: 3.0, icon: "figure.dance", requiresDistance: false),
            CardioExercise(name: "Dancing (Disco)", metValue: 4.8, icon: "figure.dance", requiresDistance: false),
            CardioExercise(name: "Elliptical Trainer", metValue: 7.0, icon: "figure.elliptical", requiresDistance: false),
            CardioExercise(name: "Fencing", metValue: 6.0, icon: "figure.fencing", requiresDistance: false),
            CardioExercise(name: "Football (American)", metValue: 8.0, icon: "football.fill", requiresDistance: false),
            CardioExercise(name: "Golf (Walking)", metValue: 4.8, icon: "figure.golf", requiresDistance: true),
            CardioExercise(name: "Gymnastics", metValue: 4.0, icon: "figure.gymnastics", requiresDistance: false),
            CardioExercise(name: "Handball", metValue: 12.0, icon: "handball", requiresDistance: false),
            CardioExercise(name: "High-Intensity Interval Training (HIIT)", metValue: 8.0, icon: "figure.strengthtraining.functional", requiresDistance: false),
            CardioExercise(name: "Hiking (Cross-Country)", metValue: 6.0, icon: "figure.hiking", requiresDistance: true),
            CardioExercise(name: "Hiking (Uphill)", metValue: 7.3, icon: "figure.hiking", requiresDistance: true),
            CardioExercise(name: "Hockey (Ice)", metValue: 8.0, icon: "hockey.puck.fill", requiresDistance: false),
            CardioExercise(name: "Horseback Riding", metValue: 4.0, icon: "figure.equestrian.sports", requiresDistance: true),
            CardioExercise(name: "Jumping Jacks", metValue: 7.7, icon: "figure.jumprope", requiresDistance: false),
            CardioExercise(name: "Jump Rope (High Intensity)", metValue: 11.8, icon: "figure.jumprope", requiresDistance: false),
            CardioExercise(name: "Jump Rope", metValue: 8.8, icon: "figure.jumprope", requiresDistance: false),
            CardioExercise(name: "Kayaking", metValue: 5.0, icon: "figure.outdoor.cycle", requiresDistance: true),
            CardioExercise(name: "Kickboxing", metValue: 10.3, icon: "figure.kickboxing", requiresDistance: false),
            CardioExercise(name: "Lacrosse", metValue: 8.0, icon: "figure.lacrosse", requiresDistance: false),
            CardioExercise(name: "Martial Arts", metValue: 10.3, icon: "figure.boxing", requiresDistance: false),
            CardioExercise(name: "Mountain Biking", metValue: 8.5, icon: "bicycle", requiresDistance: true),
            CardioExercise(name: "Mountain Climbing", metValue: 8.0, icon: "figure.climbing", requiresDistance: false),
            CardioExercise(name: "Pilates", metValue: 3.7, icon: "figure.pilates", requiresDistance: false),
            CardioExercise(name: "Racquetball", metValue: 7.0, icon: "tennisball.fill", requiresDistance: false),
            CardioExercise(name: "Rock Climbing", metValue: 8.0, icon: "figure.climbing", requiresDistance: false),
            CardioExercise(name: "Roller Skating", metValue: 7.0, icon: "figure.skating", requiresDistance: true),
            CardioExercise(name: "Rowing (Light)", metValue: 3.5, icon: "figure.rower", requiresDistance: true),
            CardioExercise(name: "Rowing (Moderate)", metValue: 7.0, icon: "figure.rower", requiresDistance: true),
            CardioExercise(name: "Rowing (Vigorous)", metValue: 8.5, icon: "figure.rower", requiresDistance: true),
            CardioExercise(name: "Rugby", metValue: 10.0, icon: "rugby.ball", requiresDistance: false),
            CardioExercise(name: "Running", metValue: 9.8, icon: "figure.run", requiresDistance: true),
            CardioExercise(name: "Running (Uphill)", metValue: 9.0, icon: "figure.run", requiresDistance: true),
            CardioExercise(name: "Skiing (Cross-Country)", metValue: 7.0, icon: "figure.skiing.crosscountry", requiresDistance: true),
            CardioExercise(name: "Skiing (Downhill)", metValue: 6.0, icon: "figure.skiing.downhill", requiresDistance: false),
            CardioExercise(name: "Snowboarding", metValue: 5.3, icon: "figure.snowboarding", requiresDistance: false),
            CardioExercise(name: "Soccer", metValue: 10.0, icon: "soccerball", requiresDistance: false),
            CardioExercise(name: "Softball", metValue: 5.0, icon: "baseball.fill", requiresDistance: false),
            CardioExercise(name: "Spinning Class", metValue: 8.5, icon: "bicycle", requiresDistance: false),
            CardioExercise(name: "Squash", metValue: 12.0, icon: "tennisball.fill", requiresDistance: false),
            CardioExercise(name: "Stair Climbing", metValue: 8.8, icon: "figure.stairs", requiresDistance: false),
            CardioExercise(name: "Step Aerobics", metValue: 7.0, icon: "figure.step.training", requiresDistance: false),
            CardioExercise(name: "Swimming (Backstroke)", metValue: 7.0, icon: "figure.pool.swim", requiresDistance: true),
            CardioExercise(name: "Swimming (Breaststroke)", metValue: 10.0, icon: "figure.pool.swim", requiresDistance: true),
            CardioExercise(name: "Swimming (Butterfly)", metValue: 11.0, icon: "figure.pool.swim", requiresDistance: true),
            CardioExercise(name: "Swimming (Freestyle)", metValue: 8.0, icon: "figure.pool.swim", requiresDistance: true),
            CardioExercise(name: "Swimming (General)", metValue: 6.0, icon: "figure.pool.swim", requiresDistance: true),
            CardioExercise(name: "Table Tennis", metValue: 4.0, icon: "tennisball.fill", requiresDistance: false),
            CardioExercise(name: "Tennis (Doubles)", metValue: 6.0, icon: "tennisball.fill", requiresDistance: false),
            CardioExercise(name: "Tennis (Singles)", metValue: 8.0, icon: "tennisball.fill", requiresDistance: false),
            CardioExercise(name: "Track and Field (General)", metValue: 6.0, icon: "figure.run", requiresDistance: true),
            CardioExercise(name: "Treadmill", metValue: 9.8, icon: "figure.run", requiresDistance: true),
            CardioExercise(name: "Ultimate Frisbee", metValue: 8.0, icon: "sportscourt.fill", requiresDistance: false),
            CardioExercise(name: "Volleyball", metValue: 4.0, icon: "volleyball.fill", requiresDistance: false),
            CardioExercise(name: "Walking", metValue: 3.5, icon: "figure.walk", requiresDistance: true),
            CardioExercise(name: "Walking (Brisk)", metValue: 4.3, icon: "figure.walk", requiresDistance: true),
            CardioExercise(name: "Water Aerobics", metValue: 4.0, icon: "figure.pool.swim", requiresDistance: false),
            CardioExercise(name: "Water Polo", metValue: 10.0, icon: "figure.waterpolo", requiresDistance: false),
            CardioExercise(name: "Yoga (Hatha)", metValue: 2.5, icon: "figure.mind.and.body", requiresDistance: false),
            CardioExercise(name: "Yoga (Power)", metValue: 4.0, icon: "figure.mind.and.body", requiresDistance: false),
            CardioExercise(name: "Zumba", metValue: 8.8, icon: "figure.dance", requiresDistance: false)
        ]
        
        if searchText.isEmpty {
            return exercises
        } else {
            return exercises.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selection
                HStack(spacing: 0) {
                    ForEach(ExerciseTab.allCases, id: \.self) { tab in
                        Button(action: {
                            selectedTab = tab
                            searchText = "" // Clear search when switching tabs
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 16, weight: .medium))
                                Text(tab.rawValue)
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(selectedTab == tab ? .white : .blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(selectedTab == tab ? .blue : Color.clear)
                            .cornerRadius(0)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .background(Color(.systemGray6))
                .cornerRadius(0)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField(selectedTab == .resistance ? "Search resistance exercises" : "Search cardio activities", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // Muscle group filter (only for resistance exercises)
                if selectedTab == .resistance {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(MuscleGroupFilter.allCases, id: \.self) { muscleGroup in
                                Button(action: {
                                    selectedMuscleGroup = muscleGroup
                                }) {
                                    Text(muscleGroup.displayName)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(selectedMuscleGroup == muscleGroup ? .white : .blue)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedMuscleGroup == muscleGroup ? .blue : Color.blue.opacity(0.05))
                                        .cornerRadius(24)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 8)
                }
                
                // Content based on selected tab
                if selectedTab == .resistance {
                    resistanceExercisesList
                } else {
                    cardioExercisesList
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                }
            }
        }
    }
    
    // MARK: - Enhanced Resistance Exercises List
    private var resistanceExercisesList: some View {
        VStack(spacing: 0) {
            // Exercise count header
            HStack {
                Text("\(resistanceExercises.count) exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if selectedExercises.count > 0 {
                    Text("\(selectedExercises.count) selected")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            
            List {
                ForEach(resistanceExercises, id: \.id) { exercise in
                    HStack(spacing: 12) {
                        // Exercise icon based on category
                        Image(systemName: exerciseIcon(for: exercise.category))
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                            .frame(width: 20, height: 20)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(exercise.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            
                            HStack(spacing: 8) {
                                // Category badge
                                Text(exercise.category.rawValue)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(categoryColor(for: exercise.category))
                                    .cornerRadius(8)
                                
                                // Equipment badge
                                Text(exercise.equipment.rawValue.capitalized.replacingOccurrences(of: "_", with: " "))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.05))
                                    .cornerRadius(6)
                                
                                // Primary muscle indicator
                                if !exercise.primaryMuscles.isEmpty {
                                    Text(exercise.primaryMuscles.first ?? "")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Enhanced selection indicator
                        if selectedExercises.contains(exercise.name) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 22))
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.gray.opacity(0.6))
                                .font(.system(size: 22))
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleExerciseSelection(exercise.name)
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    // MARK: - Helper Functions for Exercise Display
    private func exerciseIcon(for category: ExerciseCategory) -> String {
        switch category {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.strengthtraining.functional" 
        case .shoulders: return "figure.arms.open"
        case .biceps: return "figure.flexing"
        case .triceps: return "figure.arms.open"
        case .legs: return "figure.walk"
        case .glutes: return "figure.walk"
        case .calves: return "figure.walk"
        case .core: return "figure.core.training"
        case .cardio: return "heart.fill"
        case .fullBody: return "figure.strengthtraining.functional"
        }
    }
    
    private func categoryColor(for category: ExerciseCategory) -> Color {
        switch category {
        case .chest: return .red
        case .back: return .green
        case .shoulders: return .orange
        case .biceps: return .purple
        case .triceps: return .pink
        case .legs: return .blue
        case .glutes: return .indigo
        case .calves: return .cyan
        case .core: return .yellow
        case .cardio: return .red
        case .fullBody: return .mint
        }
    }
    
    // MARK: - Enhanced Cardio Exercises List
    private var cardioExercisesList: some View {
        VStack(spacing: 0) {
            // Exercise count header
            HStack {
                Text("\(cardioExercises.count) cardio activities")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if selectedExercises.count > 0 {
                    Text("\(selectedExercises.count) selected")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            
            List {
                ForEach(cardioExercises, id: \.id) { exercise in
                    HStack(spacing: 12) {
                        // Exercise icon
                        Image(systemName: exercise.icon)
                            .font(.system(size: 18))
                            .foregroundColor(.red)
                            .frame(width: 20, height: 20)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(exercise.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            
                            HStack(spacing: 8) {
                                // MET value badge
                                HStack(spacing: 2) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 8))
                                        .foregroundColor(.white)
                                    Text("\(String(format: "%.1f", exercise.metValue)) MET")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(metIntensityColor(for: exercise.metValue))
                                .cornerRadius(8)
                                
                                // Intensity indicator
                                Text(intensityLevel(for: exercise.metValue))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                // Estimated calories for 30 min
                                Text("~\(exercise.estimatedCalories(minutes: 30)) cal/30min")
                                    .font(.system(size: 11))
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        Spacer()
                        
                        // Enhanced selection indicator
                        if selectedExercises.contains(exercise.name) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 22))
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.gray.opacity(0.6))
                                .font(.system(size: 22))
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleExerciseSelection(exercise.name)
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    // MARK: - Cardio Helper Functions
    private func metIntensityColor(for metValue: Double) -> Color {
        if metValue < 3.0 {
            return .green // Light intensity
        } else if metValue < 6.0 {
            return .orange // Moderate intensity
        } else {
            return .red // High intensity
        }
    }
    
    private func intensityLevel(for metValue: Double) -> String {
        if metValue < 3.0 {
            return "Light"
        } else if metValue < 6.0 {
            return "Moderate"
        } else {
            return "Vigorous"
        }
    }
    
    private func toggleExerciseSelection(_ exerciseName: String) {
        if selectedExercises.contains(exerciseName) {
            selectedExercises.removeAll { $0 == exerciseName }
        } else {
            selectedExercises.append(exerciseName)
        }
    }
}

// MARK: - Cardio Exercise Models

struct CardioExercise: Identifiable {
    let id = UUID()
    let name: String
    let metValue: Double // Metabolic equivalent of task
    let icon: String
    let requiresDistance: Bool // Whether this exercise typically tracks distance
    
    // Calculate estimated calories burned based on duration and average weight
    func estimatedCalories(minutes: Int, weightKg: Double = 70.0) -> Int {
        let hours = Double(minutes) / 60.0
        let calories = metValue * weightKg * hours
        return Int(calories)
    }
}

struct CardioExerciseRow: View {
    let exercise: CardioExercise
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Exercise icon
                Image(systemName: exercise.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        // MET value badge
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 8))
                            Text("\(String(format: "%.1f", exercise.metValue)) MET")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.orange.opacity(0.05))
                        .cornerRadius(6)
                        
                        // Distance indicator
                        if exercise.requiresDistance {
                            Text("📍 Distance")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        
                        // Estimated calories for 30 min (assuming 70kg person)
                        Text("~\(exercise.estimatedCalories(minutes: 30)) cal/30min")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Exercise Dropdown Selector

struct ExerciseDropdownSelector: View {
    let exerciseType: String
    let color: Color
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var selectedExercise = ""
    
    private let exerciseDatabase: [String: [String]] = [
        "Cardio": [
            "Running", "Jogging", "Walking", "Cycling", "Swimming", "Rowing", "Elliptical",
            "Stair Climbing", "Dancing", "Jump Rope", "HIIT", "Boxing", "Kickboxing",
            "Spinning", "Treadmill", "Cross Training", "Aerobics", "Zumba", "Tennis",
            "Basketball", "Soccer", "Rugby", "Cricket", "Badminton", "Squash"
        ],
        "Strength": [
            "Bench Press", "Incline Bench Press", "Decline Bench Press", "Dumbbell Press",
            "Incline Dumbbell Press", "Dumbbell Flyes", "Push-ups", "Chest Dips",
            "Pull-ups", "Chin-ups", "Lat Pulldown", "Seated Cable Row", "Bent-over Row",
            "T-Bar Row", "Single-arm Dumbbell Row", "Deadlift", "Romanian Deadlift",
            "Overhead Press", "Military Press", "Dumbbell Shoulder Press", "Arnold Press",
            "Lateral Raises", "Front Raises", "Rear Delt Flyes", "Upright Rows", "Shrugs",
            "Barbell Curls", "Dumbbell Curls", "Hammer Curls", "Preacher Curls", "Cable Curls",
            "Tricep Dips", "Close-grip Bench Press", "Tricep Pushdowns", "Overhead Tricep Extension",
            "Squats", "Front Squats", "Leg Press", "Lunges", "Bulgarian Split Squats",
            "Leg Curls", "Leg Extensions", "Calf Raises", "Hip Thrusts", "Hyperextensions"
        ],
        "Other": [
            "Yoga", "Pilates", "Stretching", "Meditation", "Flexibility Training",
            "Balance Training", "Mobility Work", "Foam Rolling", "Recovery Session",
            "Physical Therapy", "Walking", "Hiking", "Rock Climbing", "Gymnastics",
            "Martial Arts", "Tai Chi", "Qigong", "Rehabilitation", "Core Strengthening"
        ]
    ]
    
    private var filteredExercises: [String] {
        let exercises = exerciseDatabase[exerciseType] ?? []
        if searchText.isEmpty {
            return exercises
        } else {
            return exercises.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    private func estimateCalories(for exercise: String, duration: Int = 30) -> Double {
        // Get user's height and weight from UserDefaults
        let weightKg = UserDefaults.standard.double(forKey: "userWeight") 
        let heightCm = UserDefaults.standard.double(forKey: "userHeight")
        let age = UserDefaults.standard.integer(forKey: "userAge")
        _ = UserDefaults.standard.string(forKey: "userGender") ?? "other"
        
        // Use default values if not set
        let weight = weightKg > 0 ? weightKg : 70.0 // default 70kg
        _ = heightCm > 0 ? heightCm : 170.0 // default 170cm
        _ = age > 0 ? age : 30 // default 30 years
        
        // MET (Metabolic Equivalent of Task) values for different exercises
        let metValue: Double
        switch exercise.lowercased() {
        // Cardio exercises (higher MET values)
        case let ex where ex.contains("running") || ex.contains("jogging"):
            metValue = 8.0
        case let ex where ex.contains("cycling") || ex.contains("bike"):
            metValue = 7.5
        case let ex where ex.contains("swimming"):
            metValue = 8.5
        case let ex where ex.contains("rowing"):
            metValue = 7.0
        case let ex where ex.contains("hiit") || ex.contains("boxing") || ex.contains("kickboxing"):
            metValue = 9.0
        case let ex where ex.contains("dancing") || ex.contains("aerobics") || ex.contains("zumba"):
            metValue = 6.5
        case let ex where ex.contains("walking"):
            metValue = 3.8
        case let ex where ex.contains("elliptical") || ex.contains("cross training"):
            metValue = 7.0
        case let ex where ex.contains("tennis") || ex.contains("badminton") || ex.contains("squash"):
            metValue = 7.5
        case let ex where ex.contains("basketball") || ex.contains("soccer") || ex.contains("rugby"):
            metValue = 8.0
            
        // Strength training exercises (moderate MET values)
        case let ex where ex.contains("bench press") || ex.contains("press"):
            metValue = 5.0
        case let ex where ex.contains("squat") || ex.contains("deadlift"):
            metValue = 6.0
        case let ex where ex.contains("pull") || ex.contains("row"):
            metValue = 5.5
        case let ex where ex.contains("curl") || ex.contains("extension"):
            metValue = 4.5
        case let ex where ex.contains("push-up") || ex.contains("dip"):
            metValue = 4.5
            
        // Low intensity exercises
        case let ex where ex.contains("yoga") || ex.contains("pilates"):
            metValue = 3.0
        case let ex where ex.contains("stretch") || ex.contains("flexibility"):
            metValue = 2.5
        case let ex where ex.contains("meditation") || ex.contains("tai chi"):
            metValue = 2.0
            
        // Default for unlisted exercises
        default:
            metValue = exerciseType == "Cardio" ? 7.0 : exerciseType == "Strength" ? 5.0 : 3.5
        }
        
        // Calculate calories burned: MET * weight (kg) * time (hours)
        let hours = Double(duration) / 60.0
        let caloriesBurned = metValue * weight * hours
        
        return caloriesBurned
    }
    
    private func addExerciseToDiary(_ exercise: String) {
        let estimatedCalories = estimateCalories(for: exercise)
        print("Adding \(exercise) to diary with estimated \(Int(estimatedCalories)) calories")
        
        // TODO: In a real implementation, this would add to the actual diary data structure
        // For now, just log the action with calorie estimation
    }
    
    
    private func getExerciseCategory(for exercise: String) -> String {
        // Determine category for each exercise
        if exerciseDatabase["Cardio"]?.contains(exercise) == true {
            return "Cardio"
        } else if exerciseDatabase["Strength"]?.contains(exercise) == true {
            return "Strength"
        } else {
            return "Other"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with search
                VStack(spacing: 16) {
                    HStack {
                        Text("Select Exercise")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button("Done") {
                            isPresented = false
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 16)
                    
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        TextField("Search exercises...", text: $searchText)
                            .font(.system(size: 16))
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    
                    // Add Custom Exercise button
                    if !searchText.isEmpty && !filteredExercises.contains(searchText) {
                        Button(action: {
                            addExerciseToDiary(searchText)
                            selectedExercise = searchText
                            // Don't close automatically - let user continue selecting or close manually
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                                
                                Text("Add Custom Exercise")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal, 16)
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.top, 16)
                .background(Color(.systemBackground))
                
                // Exercise list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredExercises, id: \.self) { exercise in
                            Button(action: {
                                selectedExercise = exercise
                                addExerciseToDiary(exercise)
                                // Don't close automatically - let user continue selecting or close manually
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(exercise)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                        
                                        Text(getExerciseCategory(for: exercise))
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedExercise == exercise {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(selectedExercise == exercise ? color.opacity(0.05) : Color.clear)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if exercise != filteredExercises.last {
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }
                    }
                }
                
                if filteredExercises.isEmpty && searchText.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.6))
                        
                        Text("Start typing to search exercises")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredExercises.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.6))
                        
                        Text("No results found")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("Try a different search term or add as custom")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .onAppear {
            searchText = ""
            selectedExercise = ""
        }
    }
}