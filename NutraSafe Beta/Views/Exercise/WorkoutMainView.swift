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
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(workoutManager.workoutName)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(workoutManager.currentWorkoutDuration)
                                    .font(.title2.weight(.bold))
                                    .foregroundColor(.white)
                                Text("\(workoutManager.exercises.count) exercises")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        
                        NavigationLink(destination: NewWorkoutCreationView(selectedDate: selectedDate, template: nil, onWorkoutCreated: { workout in
                            // Handle completed workout
                        }).environmentObject(workoutManager)) {
                            HStack {
                                Text("Continue Workout")
                                    .font(.system(size: 16, weight: .semibold))
                                Image(systemName: "arrow.right")
                            }
                            .foregroundColor(.blue)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.white)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Quick Actions Section
                VStack(spacing: 12) {
                    HStack {
                        Text("Quick Actions")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        // Start Empty Workout
                        NavigationLink(destination: NewWorkoutCreationView(selectedDate: selectedDate, template: nil, onWorkoutCreated: { workout in
                            // Handle completed workout
                        }).environmentObject(workoutManager)) {
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.blue)
                                
                                Text("Empty Workout")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Workout Templates
                        Button(action: {
                            showingWorkoutTemplates = true
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.green)
                                
                                Text("Templates")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                
                // Recent Workouts Section
                VStack(spacing: 12) {
                    HStack {
                        Text("Recent Workouts")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No workouts yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Start your first workout to see it here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
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