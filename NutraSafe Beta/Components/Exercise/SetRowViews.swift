import SwiftUI
import Foundation

// MARK: - Set Row Views for Exercise Tracking

struct SetRowView: View {
    @Binding var set: ExerciseSet
    let setNumber: Int
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Set number
            Text("\(setNumber)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            // Weight input
            HStack(spacing: 4) {
                TextField("Weight", value: $set.weight, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .frame(width: 60)
                
                Text("lbs")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Text("×")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            // Reps input
            HStack(spacing: 4) {
                TextField("Reps", value: $set.reps, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .frame(width: 50)
                
                Text("reps")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Completion checkbox
            Button(action: {
                set.isCompleted.toggle()
            }) {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(set.isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(set.isCompleted ? .green.opacity(0.05) : Color(.systemGray6))
        )
    }
}

struct CardioSetRowView: View {
    @Binding var set: ExerciseSet
    let setNumber: Int
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Set number
            Text("\(setNumber)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            // Duration input
            HStack(spacing: 4) {
                TextField("Duration", value: $set.duration, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .frame(width: 70)
                
                Text("min")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            // Distance input
            HStack(spacing: 4) {
                TextField("Distance", value: $set.distance, formatter: {
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .decimal
                    formatter.maximumFractionDigits = 2
                    return formatter
                }())
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .frame(width: 70)
                
                Text("mi")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            // Pace calculation (if both duration and distance exist)
            if set.duration > 0 && set.distance > 0 {
                let paceMinutes = Int(set.duration / set.distance)
                let paceSeconds = Int((set.duration / set.distance - Double(paceMinutes)) * 60)
                
                Text("\(paceMinutes):\(String(format: "%02d", paceSeconds))/mi")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(.gray.opacity(0.05))
                    )
            }
            
            Spacer()
            
            // Completion checkbox
            Button(action: {
                set.isCompleted.toggle()
            }) {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(set.isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(set.isCompleted ? .green.opacity(0.05) : Color(.systemGray6))
        )
    }
}

// MARK: - Supporting Data Models

struct ExerciseSet: Identifiable {
    let id = UUID()
    var weight: Double = 0
    var reps: Int = 0
    var duration: Double = 0 // in minutes
    var distance: Double = 0 // in miles
    var isCompleted: Bool = false
    var restTime: Int = 90 // in seconds
    
    var volume: Double {
        return weight * Double(reps)
    }
    
    var pace: Double? {
        guard duration > 0, distance > 0 else { return nil }
        return duration / distance // minutes per mile
    }
}