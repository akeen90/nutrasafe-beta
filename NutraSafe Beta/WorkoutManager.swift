//
//  WorkoutManager.swift
//  NutraSafe Beta
//
//  Manages workout sessions and exercise tracking
//

import SwiftUI
import Foundation

class WorkoutManager: ObservableObject {
    static let shared = WorkoutManager()

    @Published var isWorkoutActive = false
    @Published var currentWorkout: Workout?
    @Published var workoutDuration: TimeInterval = 0
    @Published var workoutStartTime: Date?
    @Published var completedExercises: [Exercise] = []
    @Published var activeExercise: Exercise?
    @Published var workoutHistory: [WorkoutSessionSummary] = []

    private var workoutTimer: Timer?

    // Computed properties
    var workoutName: String {
        return currentWorkout?.name ?? "Workout"
    }

    var workoutDurationFormatted: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: workoutDuration) ?? "00:00"
    }

    var exercises: [Exercise] {
        return completedExercises
    }

    var totalVolume: Double {
        return completedExercises.reduce(0) { total, exercise in
            if let weight = exercise.weight {
                return total + (weight * Double(exercise.sets * exercise.reps))
            }
            return total
        }
    }

    // Workout session management
    func startWorkout() {
        startWorkout(name: "Workout")
    }

    func startWorkout(name: String) {
        isWorkoutActive = true
        workoutStartTime = Date()
        workoutDuration = 0
        currentWorkout = Workout(name: name, exercises: [], date: Date(), duration: 0)
        completedExercises = []
        startTimer()
    }

    func endWorkout() -> WorkoutSessionSummary? {
        guard isWorkoutActive, let startTime = workoutStartTime else { return nil }

        isWorkoutActive = false
        stopTimer()

        let finalDuration = Date().timeIntervalSince(startTime)
        let summary = WorkoutSessionSummary(
            id: UUID(),
            name: workoutName,
            startTime: startTime,
            duration: finalDuration,
            exercises: completedExercises,
            caloriesBurned: Int(totalVolume * 0.1) // Simple calorie estimation
        )

        workoutHistory.insert(summary, at: 0)

        currentWorkout = nil
        activeExercise = nil
        completedExercises = []
        workoutDuration = 0
        workoutStartTime = nil

        return summary
    }

    func cancelWorkout() {
        isWorkoutActive = false
        stopTimer()
        currentWorkout = nil
        activeExercise = nil
        completedExercises = []
        workoutDuration = 0
        workoutStartTime = nil
    }

    func pauseWorkout() {
        stopTimer()
    }

    func resumeWorkout() {
        if isWorkoutActive {
            startTimer()
        }
    }

    private func startTimer() {
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let startTime = self.workoutStartTime {
                self.workoutDuration = Date().timeIntervalSince(startTime)
            }
        }
    }

    private func stopTimer() {
        workoutTimer?.invalidate()
        workoutTimer = nil
    }

    // Exercise management
    func addExercise(_ exercise: Exercise) {
        completedExercises.append(exercise)
    }

    func setActiveExercise(_ exercise: Exercise) {
        activeExercise = exercise
    }

    func completeCurrentExercise() {
        if let exercise = activeExercise {
            completedExercises.append(exercise)
            activeExercise = nil
        }
    }
}

// Basic Workout model
struct Workout: Identifiable {
    let id = UUID()
    var name: String
    var exercises: [Exercise]
    var date: Date
    var duration: TimeInterval
}

// Workout Session Summary for history
struct WorkoutSessionSummary: Identifiable {
    let id: UUID
    let name: String
    let startTime: Date
    let duration: TimeInterval
    let exercises: [Exercise]
    let caloriesBurned: Int

    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
}

// Basic Exercise model
struct Exercise: Identifiable {
    let id = UUID()
    var name: String
    var sets: Int
    var reps: Int
    var weight: Double?
    var duration: TimeInterval?
    var isCompleted: Bool = false
}