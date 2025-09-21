import SwiftUI
import Foundation

// MARK: - Rest Timer Views for Workout Management

struct RestTimerCompactView: View {
    @ObservedObject var restTimer: RestTimer
    let onAddTime: (Int) -> Void
    let onStop: () -> Void
    
    var body: some View {
        // Full-width rest timer bar
        HStack(spacing: 16) {
            // Timer display with circular progress
            ZStack {
                Circle()
                    .stroke(.blue.opacity(0.3), lineWidth: 2)
                    .frame(width: 36, height: 36)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(restTimer.progress))
                    .stroke(.blue, lineWidth: 2)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 36, height: 36)
                
                Text("\(restTimer.remainingTime)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            // Timer info
            VStack(alignment: .leading, spacing: 2) {
                Text("Rest Timer")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Take your time to recover")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Quick add time buttons
            HStack(spacing: 8) {
                Button("+15s") {
                    onAddTime(15)
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.blue.opacity(0.05))
                )
                
                Button("+30s") {
                    onAddTime(30)
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.blue.opacity(0.05))
                )
            }
            
            // Stop button
            Button(action: onStop) {
                Text("Stop")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.red)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct RestTimerFloatingView: View {
    @ObservedObject var restTimer: RestTimer
    let onAddTime: (Int) -> Void
    let onStop: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Large circular timer display
            ZStack {
                Circle()
                    .stroke(.blue.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(restTimer.progress))
                    .stroke(.blue, lineWidth: 8)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 120, height: 120)
                
                VStack(spacing: 4) {
                    Text("\(restTimer.remainingTime)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("seconds")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            // Timer label
            Text("Rest Timer")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("Take your time to recover between sets")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Action buttons
            VStack(spacing: 8) {
                // Add time buttons
                HStack(spacing: 16) {
                    Button("+15 sec") {
                        onAddTime(15)
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.blue, lineWidth: 1)
                    )
                    
                    Button("+30 sec") {
                        onAddTime(30)
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.blue, lineWidth: 1)
                    )
                }
                
                // Primary action buttons
                HStack(spacing: 16) {
                    Button("Skip Rest") {
                        onSkip()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    
                    Button("Stop Timer") {
                        onStop()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.red)
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Rest Timer Data Model

class RestTimer: ObservableObject {
    @Published var remainingTime: Int = 0
    @Published var totalTime: Int = 0
    @Published var isActive: Bool = false
    
    private var timer: Timer?
    
    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return Double(totalTime - remainingTime) / Double(totalTime)
    }
    
    func start(duration: Int) {
        totalTime = duration
        remainingTime = duration
        isActive = true
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            if self.remainingTime > 0 {
                self?.remainingTime -= 1
            } else {
                self.stop()
            }
        }
    }
    
    func stop() {
        isActive = false
        timer?.invalidate()
        timer = nil
        remainingTime = 0
    }
    
    func addTime(_ seconds: Int) {
        remainingTime += seconds
        totalTime += seconds
    }
    
    func skip() {
        stop()
    }
    
    deinit {
        timer?.invalidate()
    }
}