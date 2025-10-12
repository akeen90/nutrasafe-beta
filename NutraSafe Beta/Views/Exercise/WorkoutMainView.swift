import SwiftUI
import Foundation

struct WorkoutMainView: View {
    let selectedDate: Date
    
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var showingNewWorkout = false
    @State private var showingWorkoutTemplates = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Active Workout Banner
                if workoutManager.isWorkoutActive {
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Workout in Progress")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.9))
                                Text(workoutManager.workoutName)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(workoutManager.currentWorkoutDuration)
                                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                Text("\(workoutManager.exercises.count) exercises")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                        }

                        NavigationLink(destination: NewWorkoutCreationView(selectedDate: selectedDate, template: nil, onWorkoutCreated: { workout in
                            // Handle completed workout
                        }).environmentObject(workoutManager)) {
                            HStack(spacing: 8) {
                                Text("Continue Workout")
                                    .font(.system(size: 17, weight: .semibold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.blue)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                            )
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        .accessibilityLabel("Continue workout in progress")
                    }
                    .padding(16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(red: 0.3, green: 0.7, blue: 0.4), Color(red: 0.2, green: 0.5, blue: 0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 16)
                }
                
                // Quick Actions Section
                VStack(spacing: 16) {
                    HStack {
                        Text("Quick Actions")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)

                        Spacer()
                    }

                    HStack(spacing: 16) {
                        // Start Empty Workout
                        NavigationLink(destination: NewWorkoutCreationView(selectedDate: selectedDate, template: nil, onWorkoutCreated: { workout in
                            // Handle completed workout
                        }).environmentObject(workoutManager)) {
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(.blue)
                                
                                Text("Empty Workout")
                                    .font(.system(size: 16, weight: .regular).weight(.semibold))
                                    .foregroundColor(.primary)

                                // Visual distinction chips
                                HStack(spacing: 6) {
                                    ChipView(title: "Lifting", icon: "dumbbell.fill", color: .blue)
                                    ChipView(title: "Cardio", icon: "figure.run", color: .orange)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("Start an empty workout")
                        
                        // Workout Templates
                        Button(action: {
                            showingWorkoutTemplates = true
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(.green)
                                
                                Text("Templates")
                                    .font(.system(size: 16, weight: .regular).weight(.semibold))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("Browse workout templates")
                    }
                }
                .padding(.horizontal, 16)
                
                // Recent Workouts Section
                VStack(spacing: 16) {
                    HStack {
                        Text("Recent Workouts")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No workouts yet")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Text("Start your first workout to see it here")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
        }
        .sheet(isPresented: $showingWorkoutTemplates) {
            WorkoutTemplatesView { template in
                showingWorkoutTemplates = false
                showingNewWorkout = true
            }
        }
        .sheet(isPresented: $showingNewWorkout) {
            NavigationView {
                NewWorkoutCreationView(selectedDate: selectedDate, template: nil, onWorkoutCreated: { workout in
                    showingNewWorkout = false
                })
                .environmentObject(workoutManager)
            }
        }
    }
}

// MARK: - Small Components
struct ChipView: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(title)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(color.opacity(0.1))
        )
    }
}