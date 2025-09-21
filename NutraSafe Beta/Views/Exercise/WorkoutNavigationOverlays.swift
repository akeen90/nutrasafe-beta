//
//  WorkoutNavigationOverlays.swift
//  NutraSafe Beta
//
//  Created by Claude on 12/9/24.
//

import SwiftUI

// MARK: - Workout Navigation Overlay
struct WorkoutNavigationOverlay: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var selectedDate = Date()
    @State private var showingWorkout = false
    @Binding var selectedTab: TabItem
    
    var body: some View {
        VStack {
            Spacer()
            
            // Bottom area logic
            if workoutManager.isInWorkoutView {
                // When IN workout: show rest timer at bottom (where tab bar would be)
                if workoutManager.hasActiveRestTimer, let activeTimer = workoutManager.activeRestTimer {
                    RestTimerAtBottomBarView(restTimer: activeTimer)
                }
            } else {
                // When NOT in workout: show workout banner above tab bar
                if workoutManager.isWorkoutActive {
                    WorkoutInProgressBanner(selectedTab: $selectedTab, selectedDate: selectedDate)
                        .padding(.bottom, 60) // Push it higher up above the nav bar
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: workoutManager.hasActiveRestTimer)
        .animation(.easeInOut(duration: 0.3), value: workoutManager.isInWorkoutView)
        .animation(.easeInOut(duration: 0.3), value: workoutManager.isWorkoutActive)
    }
    
    // MARK: - Rest Timer Navigation Bar
    @ViewBuilder
    private func RestTimerNavigationBar() -> some View {
        if let activeTimer = workoutManager.activeRestTimer {
            RestTimerNavigationBarView(restTimer: activeTimer)
        }
    }
    
    // MARK: - Workout In Progress Banner
    @ViewBuilder  
    private func WorkoutInProgressBanner(selectedTab: Binding<TabItem>, selectedDate: Date) -> some View {
        NavigationLink(destination: NewWorkoutCreationView(selectedDate: selectedDate, template: nil) { workout in
            // Handle completed workout - no need to dismiss since navigation will pop
        }.environmentObject(workoutManager)) {
            HStack(spacing: 0) {
            // Circular workout timer display (matching rest timer exactly)
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 3)
                    .frame(width: 50, height: 50)
                
                // Inner filled circle
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Text(workoutManager.currentWorkoutDuration)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Centered controls - matching rest timer layout
            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("Workout in Progress")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text("\(workoutManager.exercises.count) exercises")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Spacer()
            
            // Right side - rest timer or workout icon
            if workoutManager.hasActiveRestTimer, let activeTimer = workoutManager.activeRestTimer {
                VStack(spacing: 2) {
                    ZStack {
                        // Background circle (smaller)
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 36, height: 36)
                        
                        // Progress ring that counts down (smaller)
                        Circle()
                            .trim(from: 0, to: CGFloat(activeTimer.remainingTime / activeTimer.totalDuration))
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 36, height: 36)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.5), value: activeTimer.remainingTime / activeTimer.totalDuration)
                        
                        // Inner filled circle (smaller)
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        Text(formatTime(Int(activeTimer.remainingTime)))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    
                    // Rest timer labels (more compact)
                    VStack(spacing: 0) {
                        Text("Rest")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                            .frame(maxWidth: 45)
                    }
                }
                .frame(maxWidth: 50) // Constrain total width
            } else {
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 3)
                        .frame(width: 50, height: 50)
                    
                    // Inner filled circle
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(height: 70)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.8)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(20)
        .padding(.horizontal, 16)
        .padding(.bottom, 0)
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return "\(minutes):\(String(format: "%02d", remainingSeconds))"
    }
}

// MARK: - Rest Timer Navigation Bar View
struct RestTimerNavigationBarView: View {
    @ObservedObject var restTimer: RestTimer
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest Timer")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(restTimer.exerciseName)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatTime(Int(restTimer.remainingTime)))
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                    
                    // Progress bar
                    ProgressView(value: restTimer.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .white))
                        .scaleEffect(x: 1, y: 0.8, anchor: .center)
                        .frame(width: 80)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(0)
        }
        .frame(height: 64)
        .offset(y: -8) // Position where nav bar would be
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return "\(minutes):\(String(format: "%02d", remainingSeconds))"
    }
}

// MARK: - Rest Timer at Bottom Bar View (when in workout view)
struct RestTimerAtBottomBarView: View {
    @ObservedObject var restTimer: RestTimer
    
    private var progress: Double {
        guard restTimer.totalDuration > 0 else { return 0 }
        return restTimer.remainingTime / restTimer.totalDuration
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Circular timer display with animated progress ring
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 3)
                    .frame(width: 50, height: 50)
                
                // Progress ring that counts down
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: progress)
                
                // Inner filled circle
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Text(formatTime(Int(restTimer.remainingTime)))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Centered controls - all on one line, perfectly spaced
            HStack(spacing: 12) {
                Button(action: {
                    restTimer.addTime(-15)
                }) {
                    Text("-15s")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(width: 45, height: 32)
                .background(Color.white.opacity(0.2))
                .cornerRadius(16)
                
                Button(action: {
                    if restTimer.isPaused {
                        restTimer.resume()
                    } else {
                        restTimer.pause()
                    }
                }) {
                    Image(systemName: restTimer.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                .frame(width: 40, height: 32)
                .background(restTimer.isPaused ? Color.green.opacity(0.8) : Color.orange.opacity(0.8))
                .cornerRadius(16)
                
                Button(action: {
                    restTimer.addTime(15)
                }) {
                    Text("+15s")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(width: 45, height: 32)
                .background(Color.white.opacity(0.2))
                .cornerRadius(16)
                
                Button(action: {
                    restTimer.stop()
                }) {
                    Text("Skip")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 45, height: 32)
                .background(Color.white.opacity(0.3))
                .cornerRadius(16)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(height: 70)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.8)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(20)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: -2)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return "\(minutes):\(String(format: "%02d", remainingSeconds))"
    }
}