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
    @EnvironmentObject var workoutManager: WorkoutManager

    @State private var selectedExercises: [String] = []
    @State private var exerciseSets: [String: [WorkoutSet]] = [:]
    @State private var showingExercisePicker = false
    @State private var workoutName: String = ""
    @State private var workoutStartTime: Date?
    @State private var notes = ""
    @State private var elapsedTime: TimeInterval = 0

    // Rest Timer
    @State private var restTimerActive = false
    @State private var restTimeRemaining: TimeInterval = 0
    @State private var restTimerTotal: TimeInterval = 90
    @State private var restTimer: Timer?
    @State private var restTimerEnabled = true
    @State private var showingRestTimerSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Top Header Bar (Hevy Style)
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                }

                VStack(alignment: .leading, spacing: 2) {
                    TextField("Workout", text: $workoutName)
                        .font(.system(size: 24, weight: .bold))
                        .textFieldStyle(PlainTextFieldStyle())

                    Text(formatWorkoutDuration())
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: { finishWorkout() }) {
                    Text("Finish")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.red)
                        .cornerRadius(20)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(Color(.systemBackground))

            // Action Buttons Row
            HStack(spacing: 16) {
                Button(action: { showingRestTimerSettings = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: restTimerEnabled ? "timer" : "timer.slash")
                            .font(.system(size: 16))
                        Text("Rest Timer")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(restTimerEnabled ? .blue : .secondary)
                }

                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                        Text("Discard")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.red)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            // MARK: - Exercise Content
            ScrollView {
                VStack(spacing: 12) {
                    // Add Exercise Button
                    Button(action: { showingExercisePicker = true }) {
                        HStack {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Add Exercise")
                                .font(.system(size: 16, weight: .medium))
                            Spacer()
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    // Exercises List
                    if !selectedExercises.isEmpty {
                        ForEach(selectedExercises, id: \.self) { exercise in
                            let index = selectedExercises.firstIndex(of: exercise) ?? 0
                            ExerciseWorkoutCard(
                                exercise: exercise,
                                sets: Binding(
                                    get: { exerciseSets[exercise] ?? [] },
                                    set: { exerciseSets[exercise] = $0 }
                                ),
                                onAddSet: { set in
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    addSet(to: exercise, set: set)
                                },
                                onRemoveSet: { setIndex in
                                    removeSet(from: exercise, at: setIndex)
                                },
                                onCompleteSet: { setIndex in
                                    startRestTimer()
                                },
                                onMove: { fromIndex, toIndex in
                                    moveExercise(from: fromIndex, to: toIndex)
                                },
                                exerciseIndex: index,
                                totalExercises: selectedExercises.count
                            )
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                        }
                        .onDelete(perform: deleteExercise)
                    }
                }
                .padding(.bottom, 100)
                .padding(.top, restTimerActive ? 70 : 0)
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showingExercisePicker) {
            ExerciseSelectionView(
                selectedExercises: $selectedExercises
            )
        }
        .sheet(isPresented: $showingRestTimerSettings) {
            RestTimerSettingsView(
                isEnabled: $restTimerEnabled,
                duration: $restTimerTotal
            )
        }
        .overlay(alignment: .top) {
            if restTimerActive {
                RestTimerBanner(
                    timeRemaining: $restTimeRemaining,
                    totalTime: restTimerTotal,
                    onSkip: {
                        stopRestTimer()
                    },
                    onSubtractTime: {
                        if restTimeRemaining > 15 {
                            restTimeRemaining -= 15
                        }
                    },
                    onAddTime: {
                        restTimeRemaining += 15
                    }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            if workoutName.isEmpty {
                workoutName = "Workout"
            }
            if workoutStartTime == nil {
                startWorkoutTimer()
            }
        }
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
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private func calculateProgress() -> Int {
        guard !selectedExercises.isEmpty else { return 0 }

        var totalSets = 0
        var completedSets = 0

        for exercise in selectedExercises {
            if let sets = exerciseSets[exercise] {
                totalSets += sets.count
                completedSets += sets.filter { $0.weight > 0 || $0.reps > 0 }.count
            }
        }

        guard totalSets > 0 else { return 5 }
        return min(Int((Double(completedSets) / Double(totalSets)) * 100), 100)
    }
    
    // MARK: - Timer Management

    private func startWorkoutTimer() {
        guard workoutStartTime == nil else { return } // Already started

        workoutStartTime = Date()

        // Start updating elapsed time every second
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            DispatchQueue.main.async {
                if let startTime = workoutStartTime {
                    elapsedTime = Date().timeIntervalSince(startTime)
                } else {
                    timer.invalidate()
                }
            }
        }
    }

    // MARK: - Rest Timer Management

    private func startRestTimer() {
        guard restTimerEnabled else { return }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            restTimerActive = true
        }

        restTimeRemaining = restTimerTotal

        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if restTimeRemaining > 0 {
                    restTimeRemaining -= 1
                } else {
                    stopRestTimer()
                }
            }
        }
    }

    private func stopRestTimer() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            restTimerActive = false
        }

        restTimer?.invalidate()
        restTimer = nil
        restTimeRemaining = 0
        restTimerTotal = 90
    }
}

// MARK: - Rest Timer Banner (Compact, Non-Intrusive)
struct RestTimerBanner: View {
    @Binding var timeRemaining: TimeInterval
    let totalTime: TimeInterval
    let onSkip: () -> Void
    let onSubtractTime: () -> Void
    let onAddTime: () -> Void

    private var progress: Double {
        totalTime > 0 ? timeRemaining / totalTime : 0
    }

    private var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Compact Banner
            HStack(spacing: 12) {
                // Timer Display - Prominent
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color.blue.opacity(0.15), lineWidth: 3)
                            .frame(width: 40, height: 40)

                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: progress)
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        Text("Rest")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)

                        Text(formattedTime)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                            .monospacedDigit()
                    }
                }

                Spacer()

                // Quick Controls
                HStack(spacing: 8) {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        onSubtractTime()
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        onAddTime()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onSkip()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Color(.systemBackground)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 2)
            )
        }
    }
}

// MARK: - Rest Timer Settings View
struct RestTimerSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isEnabled: Bool
    @Binding var duration: TimeInterval

    private let durationOptions: [TimeInterval] = [30, 60, 90, 120, 150, 180, 210, 240, 270, 300]

    private var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 && seconds > 0 {
            return "\(minutes)m \(seconds)s"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Enable Rest Timer", isOn: $isEnabled)
                        .tint(.blue)
                }

                if isEnabled {
                    Section(header: Text("Default Rest Duration")) {
                        Picker("Duration", selection: $duration) {
                            ForEach(durationOptions, id: \.self) { time in
                                let mins = Int(time) / 60
                                let secs = Int(time) % 60
                                if mins > 0 && secs > 0 {
                                    Text("\(mins)m \(secs)s").tag(time)
                                } else if mins > 0 {
                                    Text("\(mins)m").tag(time)
                                } else {
                                    Text("\(secs)s").tag(time)
                                }
                            }
                        }
                        .pickerStyle(.wheel)
                    }

                    Section {
                        Text("The rest timer will automatically start when you complete a set.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Rest Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Scale Button Style for Tactile Feel
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}