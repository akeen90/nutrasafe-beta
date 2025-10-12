//
//  SimpleExerciseTabView.swift
//  NutraSafe Beta
//
//  Simplified exercise view for basic functionality
//

import SwiftUI

struct SimpleExerciseTabView: View {
    @Binding var selectedTab: TabItem
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var showingStartWorkout = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                Text("Exercise")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                
                if workoutManager.isWorkoutActive {
                    // Active Workout
                    VStack(spacing: 16) {
                        Text("Workout in Progress")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        if let workout = workoutManager.currentWorkout {
                            Text(workout.name)
                                .font(.title2)
                                .bold()
                            
                            Text("Started: \(workout.startTime.formatted(.dateTime.hour().minute()))")
                                .foregroundColor(.secondary)
                        }
                        
                        Button("Finish Workout") {
                            let _ = workoutManager.endWorkout()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        Button("Cancel Workout") {
                            workoutManager.cancelWorkout()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(.green.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else {
                    // No Active Workout
                    VStack(spacing: 24) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Ready to Work Out?")
                            .font(.title)
                            .bold()
                        
                        Text("Track your exercises and build strength")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        VStack(spacing: 12) {
                            Button("Start Empty Workout") {
                                workoutManager.startWorkout(name: "Workout")
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            
                            Button("Choose Template") {
                                showingStartWorkout = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Workout History
                if !workoutManager.workoutHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Workouts")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(workoutManager.workoutHistory.prefix(5)) { workout in
                                    WorkoutHistoryRow(workout: workout)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 30))
                            .foregroundColor(.secondary)
                        
                        Text("No workout history yet")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 32)
                }
                
                Spacer()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingStartWorkout) {
            WorkoutTemplateView()
        }
    }
}

struct WorkoutHistoryRow: View {
    let workout: WorkoutSessionSummary
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(workout.name)
                    .font(.headline)
                
                Text(workout.startTime.formatted(.dateTime.day().month().hour().minute()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(workout.formattedDuration)
                    .font(.subheadline)
                    .bold()
                
                Text("\(workout.caloriesBurned) kcal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct WorkoutTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Workout Templates")
                    .font(.title)
                    .bold()
                    .padding()
                
                List {
                    WorkoutTemplateRow(name: "Push Day", description: "Chest, Shoulders, Triceps") {
                        workoutManager.startWorkout(name: "Push Day")
                        dismiss()
                    }
                    
                    WorkoutTemplateRow(name: "Pull Day", description: "Back, Biceps") {
                        workoutManager.startWorkout(name: "Pull Day")
                        dismiss()
                    }
                    
                    WorkoutTemplateRow(name: "Leg Day", description: "Quadriceps, Hamstrings, Glutes") {
                        workoutManager.startWorkout(name: "Leg Day")
                        dismiss()
                    }
                    
                    WorkoutTemplateRow(name: "Full Body", description: "Complete workout") {
                        workoutManager.startWorkout(name: "Full Body")
                        dismiss()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct WorkoutTemplateRow: View {
    let name: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Button Styles

struct SpringyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    SimpleExerciseTabView(selectedTab: .constant(.exercise))
        .environmentObject(WorkoutManager.shared)
}