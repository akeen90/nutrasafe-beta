import SwiftUI
import Foundation

// Note: This file needs to be updated to use the centralized constants from:
// - Constants/AtomicConstants.swift
// - Constants/ColorConstants.swift  
// - Constants/StringConstants.swift
// For now, using local constants to fix build

struct WeightTrainingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRestTime = 90
    @State private var currentSet = 1
    @State private var sets: [WorkoutSet] = []
    @State private var exerciseName = "Bench Press"
    @State private var showingRestTimeSelector = false
    @State private var showingExerciseSelector = false
    @State private var exerciseSearchText = ""
    @State private var isCustomExercise = false
    
    private let restTimeOptions = [30, 60, 90, 120, 180, 240, 300]
    
    private let presetExercises = [
        // Chest
        "Bench Press", "Incline Bench Press", "Decline Bench Press", "Dumbbell Press",
        "Dumbbell Flyes", "Push-ups", "Chest Dips", "Cable Crossovers",
        
        // Back
        "Pull-ups", "Lat Pulldowns", "Barbell Rows", "Dumbbell Rows",
        "T-Bar Rows", "Seated Cable Rows", "Deadlifts", "Face Pulls",
        
        // Shoulders
        "Overhead Press", "Lateral Raises", "Front Raises", "Rear Delt Flyes",
        "Arnold Press", "Pike Push-ups", "Handstand Push-ups", "Shrugs",
        
        // Arms
        "Bicep Curls", "Hammer Curls", "Tricep Dips", "Close-Grip Bench Press",
        "Tricep Extensions", "21s", "Preacher Curls", "Tricep Pushdowns",
        
        // Legs
        "Squats", "Deadlifts", "Lunges", "Leg Press", "Leg Curls",
        "Leg Extensions", "Calf Raises", "Bulgarian Split Squats",
        
        // Core
        "Planks", "Russian Twists", "Mountain Climbers", "Bicycle Crunches",
        "Leg Raises", "Dead Bugs", "Hollow Body Holds", "Ab Wheel Rollouts"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("Weight Training")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button("Done") {
                        // Save workout logic
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .font(.system(size: 18, weight: .semibold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                
                // Exercise Selection
                VStack(spacing: 16) {
                    Button(action: {
                        showingExerciseSelector.toggle()
                    }) {
                        HStack {
                            Text(exerciseName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
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
                    
                    if showingExerciseSelector {
                        VStack(spacing: 8) {
                            TextField("Search exercises...", text: $exerciseSearchText)
                                .textFieldStyle(.roundedBorder)
                            
                            ScrollView {
                                LazyVStack(spacing: 8) {
                                    ForEach(filteredExercises, id: \.self) { exercise in
                                        Button(action: {
                                            exerciseName = exercise
                                            showingExerciseSelector = false
                                        }) {
                                            HStack {
                                                Text(exercise)
                                                    .foregroundColor(.primary)
                                                Spacer()
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(exerciseName == exercise ? Color.blue.opacity(0.1) : .clear)
                                            )
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                
                // Placeholder for remaining weight training implementation
                Text("WeightTrainingView modularization in progress...")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .padding()
                
                Spacer()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var filteredExercises: [String] {
        if exerciseSearchText.isEmpty {
            return presetExercises
        }
        return presetExercises.filter { $0.localizedCaseInsensitiveContains(exerciseSearchText) }
    }
}