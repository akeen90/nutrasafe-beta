import SwiftUI
import Foundation

struct FunctionalExerciseCard: View {
    @Binding var exercise: ExerciseSummary
    let onDelete: () -> Void
    let onStartRestTimer: (Int) -> Void
    @ObservedObject var workoutManager: WorkoutManager
    
    // Helper function to determine if an exercise is cardio
    private func isCardioExercise(_ exerciseName: String) -> Bool {
        let cardioExercises = [
            "Aerobics (High Impact)", "Aerobics (Low Impact)", "Badminton", "Baseball", "Basketball", 
            "Beach Volleyball", "Boxing", "Burpees", "Circuit Training", "CrossFit", 
            "Cycling (Leisure)", "Cycling (Moderate)", "Cycling (Vigorous)", 
            "Cycling (Racing)", "Cycling (Fast Racing)", "Dancing (Ballroom)", 
            "Dancing (Disco)", "Elliptical Trainer", "Fencing", 
            "Football (American)", "Golf (Walking)", "Gymnastics", "Handball", 
            "Hiking", "Hockey (Field)", "Hockey (Ice)", "Jogging", "Jump Rope", 
            "Kayaking", "Kickboxing", "Martial Arts", "Mountain Biking", 
            "Pilates", "Racquetball", "Rock Climbing", "Rowing Machine", 
            "Running (6 mph)", "Running (7.5 mph)", "Running (9 mph)", 
            "Running (10 mph)", "Skiing (Cross Country)", "Skiing (Downhill)", 
            "Soccer", "Spinning", "Squash", "Stair Climbing", "Swimming (Freestyle)", 
            "Swimming (Backstroke)", "Swimming (Breaststroke)", "Swimming (Butterfly)", 
            "Tennis (Singles)", "Tennis (Doubles)", "Treadmill", "Volleyball", 
            "Walking (Brisk)", "Walking (Moderate)", "Water Aerobics", "Yoga", "Zumba"
        ]
        return cardioExercises.contains(exerciseName)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Exercise Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("\(exercise.sets.count) sets")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Delete Button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(.red.opacity(0.05))
                        )
                }
            }
            
            // Sets List
            if !exercise.sets.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(exercise.sets.enumerated()), id: \.offset) { index, set in
                        HStack {
                            // Set Number
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                                .frame(width: 16 * 2)
                            
                            if isCardioExercise(exercise.name) {
                                // Cardio Set Row
                                CardioSetDisplay(set: set)
                            } else {
                                // Weight Set Row
                                WeightSetDisplay(set: set)
                            }
                            
                            // Checkmark
                            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(set.isCompleted ? .green : .gray)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(set.isCompleted ? .green.opacity(0.05) : Color(.systemGray6))
                        )
                    }
                }
            }
            
            // Add Set Button
            Button(action: {
                addNewSet()
            }) {
                HStack {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text("Add Set")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.blue, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func addNewSet() {
        let newSet: WorkoutSet
        
        if isCardioExercise(exercise.name) {
            newSet = WorkoutSet(
                weight: 0,
                reps: 0,
                duration: 300, // 5 minutes default
                distance: 1.0, // 1 mile default
                isCompleted: false,
                restTime: 60
            )
        } else {
            newSet = WorkoutSet(
                weight: exercise.sets.last?.weight ?? 0,
                reps: exercise.sets.last?.reps ?? 10,
                duration: 0,
                distance: 0,
                isCompleted: false,
                restTime: 90
            )
        }
        
        exercise.sets.append(newSet)
    }
}

// Helper views for different set types
struct WeightSetDisplay: View {
    let set: WorkoutSet
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Weight")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(Int(set.weight)) lbs")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Reps")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(set.reps)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

struct CardioSetDisplay: View {
    let set: WorkoutSet
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Duration")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(StringConstants.durationText(minutes: set.duration / 60))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Distance")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(String(format: "%.1f mi", set.distance))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}