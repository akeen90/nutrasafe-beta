//
//  HevyStyleExerciseCard.swift
//  NutraSafe Beta
//
//  Enhanced exercise card component matching Hevy app design
//

import SwiftUI

struct HevyStyleExerciseCard: View {
    let exercise: String
    @Binding var sets: [WorkoutSet]
    let previousPerformance: [WorkoutSet]?
    let restTimerSeconds: Int
    var onAddSet: (WorkoutSet) -> Void
    var onRemoveSet: (Int) -> Void
    var onCompleteSet: (Int) -> Void
    var onDelete: () -> Void

    @State private var showingSetTypeMenu: Int? = nil
    @State private var showingRPEPicker: Int? = nil
    @State private var showingNotes = false
    @State private var exerciseNotes: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise Header
            HStack {
                Text(exercise)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                Menu {
                    Button(action: { showingNotes = true }) {
                        Label("Notes", systemImage: "note.text")
                    }

                    Button(role: .destructive, action: onDelete) {
                        Label("Delete Exercise", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
            }

            // Column Headers - Hevy style
            HStack(spacing: 8) {
                Text("SET")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .center)

                if previousPerformance != nil {
                    Text("PREVIOUS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 70, alignment: .center)
                }

                Text("WEIGHT")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)

                Text("REPS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)

                Spacer()
                    .frame(width: 40)
            }
            .padding(.horizontal, 4)

            // Sets List
            ForEach(Array(sets.enumerated()), id: \.offset) { index, set in
                HStack(spacing: 8) {
                    // Set Number with Type Indicator
                    Button(action: {
                        showingSetTypeMenu = index
                    }) {
                        ZStack {
                            Circle()
                                .fill(set.setType == .normal ? Color(.systemGray5) : set.setType.color.opacity(0.2))
                                .frame(width: 32, height: 32)

                            if set.setType != .normal {
                                Image(systemName: set.setType.icon)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(set.setType.color)
                            } else {
                                Text("\(index + 1)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .frame(width: 40)
                    .confirmationDialog("Set Type", isPresented: Binding(
                        get: { showingSetTypeMenu == index },
                        set: { if !$0 { showingSetTypeMenu = nil } }
                    )) {
                        ForEach(SetType.allCases, id: \.self) { type in
                            Button(type.rawValue) {
                                sets[index].setType = type
                                showingSetTypeMenu = nil
                            }
                        }
                    }

                    // Previous Performance
                    if let previous = previousPerformance, previous.indices.contains(index) {
                        Text("\(Int(previous[index].weight)) × \(previous[index].reps)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 70, alignment: .center)
                    } else if previousPerformance != nil {
                        Text("-")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 70, alignment: .center)
                    }

                    // Weight Input
                    TextField("0", value: $sets[index].weight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 15, weight: .medium))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity)

                    // Reps Input
                    TextField("0", value: $sets[index].reps, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 15, weight: .medium))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity)

                    // Complete Set Checkbox
                    Button(action: {
                        sets[index].isCompleted.toggle()
                        if sets[index].isCompleted {
                            onCompleteSet(index)
                        }
                    }) {
                        ZStack {
                            Circle()
                                .stroke(set.isCompleted ? Color.blue : Color(.systemGray4), lineWidth: 2)
                                .frame(width: 28, height: 28)

                            if set.isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .frame(width: 40)
                }
                .padding(.vertical, 4)
            }

            // Add Set Button
            Button(action: {
                let newSet = WorkoutSet(
                    weight: sets.last?.weight ?? 0,
                    reps: sets.last?.reps ?? 0,
                    previousWeight: previousPerformance?.last?.weight,
                    previousReps: previousPerformance?.last?.reps
                )
                onAddSet(newSet)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                    Text("Add Set")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showingNotes) {
            NavigationView {
                VStack {
                    TextEditor(text: $exerciseNotes)
                        .padding()

                    Spacer()
                }
                .navigationTitle("Exercise Notes")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showingNotes = false
                        }
                    }
                }
            }
        }
    }
}
