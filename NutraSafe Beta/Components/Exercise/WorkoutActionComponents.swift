import SwiftUI
import Foundation

// MARK: - Quick Actions Bar

struct QuickActionsBar: View {
    let onAddExercise: () -> Void
    let exerciseCount: Int
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onAddExercise) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Exercise")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.blue, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Exercise count indicator
            HStack(spacing: 4) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("\(exerciseCount) exercises")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Advanced Exercise Card

struct AdvancedExerciseCard: View {
    @Binding var exercise: ExerciseSummary
    let onDelete: () -> Void
    let onStartRestTimer: (Int) -> Void
    @ObservedObject var workoutManager: WorkoutManager
    
    @State private var showingSetDetails = false
    @State private var newWeight: Double = 0
    @State private var newReps: Int = 10
    @State private var notes: String = ""
    
    var body: some View {
        VStack(spacing: 16) {
            // Exercise Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 16) {
                        Text("\(exercise.sets.count) sets")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        if exercise.totalVolume > 0 {
                            Text("•")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(exercise.totalVolume)) lbs")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Menu {
                    Button("Edit Exercise") {
                        // Edit action
                    }
                    
                    Button("View History") {
                        // History action
                    }
                    
                    Button("Delete", role: .destructive) {
                        onDelete()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color(.systemGray6))
                        )
                }
            }
            
            // Quick Set Addition
            VStack(spacing: 8) {
                HStack(spacing: 16) {
                    // Weight input
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weight")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("0", value: $newWeight, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .frame(width: 70)
                    }
                    
                    // Reps input
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("10", value: $newReps, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                    }
                    
                    Spacer()
                    
                    // Add Set Button
                    Button(action: addSet) {
                        Text("Add Set")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.blue)
                            )
                    }
                    .buttonStyle(.plain)
                }
                
                // Previous set quick-fill
                if let lastSet = exercise.sets.last {
                    Button("Previous: \(Int(lastSet.weight)) lbs × \(lastSet.reps) reps") {
                        newWeight = lastSet.weight
                        newReps = lastSet.reps
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.blue)
                }
            }
            
            // Sets List
            if !exercise.sets.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(exercise.sets.enumerated()), id: \.offset) { index, set in
                        AdvancedSetRow(
                            set: .constant(set),
                            setNumber: index + 1,
                            onDelete: {
                                exercise.sets.remove(at: index)
                                updateTotalVolume()
                            }
                        )
                    }
                }
            }
            
            // Notes Section
            VStack(alignment: .leading, spacing: 4) {
                Text("Notes")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                TextField("Add notes...", text: $notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .onAppear {
            setDefaultValues()
        }
    }
    
    private func addSet() {
        let newSet = WorkoutSet(
            weight: newWeight,
            reps: newReps,
            duration: 0,
            distance: 0,
            isCompleted: false,
            restTime: 90
        )
        
        exercise.sets.append(newSet)
        updateTotalVolume()
    }
    
    private func setDefaultValues() {
        if let lastSet = exercise.sets.last {
            newWeight = lastSet.weight
            newReps = lastSet.reps
        } else {
            newWeight = 0
            newReps = 10
        }
    }
    
    private func updateTotalVolume() {
        exercise.totalVolume = exercise.sets.reduce(0) { total, set in
            total + (set.weight * Double(set.reps))
        }
    }
}

// MARK: - Advanced Set Row

struct AdvancedSetRow: View {
    @Binding var set: WorkoutSet
    let setNumber: Int
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Set number
            Text("\(setNumber)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            // Weight
            Text("\(Int(set.weight)) lbs")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 60, alignment: .leading)
            
            // Reps
            Text("\(set.reps) reps")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 60, alignment: .leading)
            
            // Volume
            Text("\(Int(set.weight * Double(set.reps))) lbs")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Completion toggle
            Button(action: {
                set.isCompleted.toggle()
            }) {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(set.isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(set.isCompleted ? .green.opacity(0.05) : .clear)
        )
    }
}