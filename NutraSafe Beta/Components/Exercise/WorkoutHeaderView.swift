import SwiftUI
import Foundation

struct WorkoutHeaderView: View {
    @Binding var workoutName: String
    @ObservedObject var workoutManager: WorkoutManager
    let duration: Int
    let volume: Double
    let isActive: Bool
    let onStartStop: () -> Void
    let onShowTemplates: () -> Void
    let onShowHistory: () -> Void
    let onDiscard: () -> Void
    let onBack: () -> Void
    
    @State private var timer: Timer? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            // Top Navigation
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                // Menu Options
                HStack(spacing: 24) {
                    Button(action: onShowTemplates) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: onShowHistory) {
                        Image(systemName: "clock")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: onDiscard) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Workout Title
            VStack(spacing: 8) {
                TextField("Workout Name", text: $workoutName)
                    .font(.system(size: 24, weight: .bold))
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .foregroundColor(.primary)
                
                HStack(spacing: 20) {
                    // Duration
                    VStack(spacing: 2) {
                        Text("\(duration) min")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Duration")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    // Volume
                    VStack(spacing: 2) {
                        Text("\(Int(volume)) lbs")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Volume")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    // Exercises
                    VStack(spacing: 2) {
                        Text("\(workoutManager.exercises.count)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Exercises")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            
            // Start/Stop Button
            Button(action: onStartStop) {
                HStack(spacing: 8) {
                    Image(systemName: isActive ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Text(isActive ? "Pause Workout" : "Start Workout")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isActive ? .orange : .green)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }
}