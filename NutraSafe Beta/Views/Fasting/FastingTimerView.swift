//
//  FastingTimerView.swift
//  NutraSafe Beta
//
//  Comprehensive intermittent fasting tracking system with timer, stages, and presets
//  Extracted from ContentView.swift to achieve 10,000-line milestone
//

import SwiftUI

// MARK: - Fasting Timer Main View

struct FastingTimerView: View {
    @State private var isFasting = UserDefaults.standard.bool(forKey: "isFasting")
    @State private var fastingStartTime = UserDefaults.standard.object(forKey: "fastingStartTime") as? Date
    @State private var fastingGoal = UserDefaults.standard.integer(forKey: "fastingGoal") == 0 ? 16 : UserDefaults.standard.integer(forKey: "fastingGoal")
    @State private var currentTime = Date()
    
    private var fastingDuration: TimeInterval {
        guard isFasting, let startTime = fastingStartTime else { return 0 }
        return currentTime.timeIntervalSince(startTime)
    }
    
    private var fastingProgress: Double {
        let goalSeconds = Double(fastingGoal) * 3600 // Convert hours to seconds
        return min(fastingDuration / goalSeconds, 1.0)
    }
    
    private var formattedDuration: String {
        let hours = Int(fastingDuration) / 3600
        let minutes = (Int(fastingDuration) % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                
                // Fasting Timer Main Card
                VStack(spacing: 24) {
                    HStack {
                        Text("Intermittent Fasting")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button("Settings") {
                            // TODO: Add fasting settings
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                    }
                    
                    // Circular Progress Timer
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 12)
                            .frame(width: 200, height: 200)
                        
                        Circle()
                            .trim(from: 0, to: fastingProgress)
                            .stroke(
                                LinearGradient(
                                    colors: [.orange, .red, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.0), value: fastingProgress)
                        
                        VStack(spacing: 4) {
                            if isFasting {
                                Text(formattedDuration)
                                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                                    .foregroundColor(.primary)
                                
                                Text("Fasting")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            } else {
                                Image(systemName: "clock")
                                    .font(.system(size: 40))
                                    .foregroundColor(.orange)
                                
                                Text("Not Fasting")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Progress Stats
                    HStack(spacing: 40) {
                        VStack(spacing: 4) {
                            Text("Goal")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            Text("\(fastingGoal)h")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.orange)
                        }
                        
                        VStack(spacing: 4) {
                            Text("Progress")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            Text("\(Int(fastingProgress * 100))%")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                        
                        VStack(spacing: 4) {
                            Text("Remaining")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            let remaining = max(0, Double(fastingGoal) * 3600 - fastingDuration)
                            let remainingHours = Int(remaining) / 3600
                            let remainingMinutes = (Int(remaining) % 3600) / 60
                            Text("\(remainingHours)h \(remainingMinutes)m")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        if isFasting {
                            Button(action: stopFasting) {
                                HStack(spacing: 8) {
                                    Image(systemName: "stop.circle.fill")
                                        .font(.system(size: 18))
                                    Text("Stop Fasting")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.red)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Button(action: startFasting) {
                                HStack(spacing: 8) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 18))
                                    Text("Start Fasting")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(20)
                .background(Color(.systemGray6))
                .cornerRadius(24)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Fasting Benefits Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Fasting Stages")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        FastingStageRow(
                            hours: "0-4h",
                            title: "Digestion",
                            description: "Body processes last meal",
                            color: .orange,
                            isActive: fastingDuration < 4 * 3600
                        )
                        
                        FastingStageRow(
                            hours: "4-8h",
                            title: "Early Fat Burning",
                            description: "Glycogen stores depleting",
                            color: .yellow,
                            isActive: fastingDuration >= 4 * 3600 && fastingDuration < 8 * 3600
                        )
                        
                        FastingStageRow(
                            hours: "8-12h",
                            title: "Fat Burning",
                            description: "Body switches to fat for energy",
                            color: .blue,
                            isActive: fastingDuration >= 8 * 3600 && fastingDuration < 12 * 3600
                        )
                        
                        FastingStageRow(
                            hours: "12-16h",
                            title: "Ketosis Begins",
                            description: "Enhanced fat burning and mental clarity",
                            color: .purple,
                            isActive: fastingDuration >= 12 * 3600 && fastingDuration < 16 * 3600
                        )
                        
                        FastingStageRow(
                            hours: "16+h",
                            title: "Deep Ketosis",
                            description: "Autophagy and cellular repair",
                            color: .indigo,
                            isActive: fastingDuration >= 16 * 3600
                        )
                    }
                }
                .padding(24)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .padding(.horizontal, 16)
                
                // Quick Goal Presets
                VStack(alignment: .leading, spacing: 16) {
                    Text("Popular Fasting Plans")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        FastingPresetButton(hours: 12, title: "12:12", subtitle: "Beginner") {
                            setFastingGoal(12)
                        }
                        
                        FastingPresetButton(hours: 16, title: "16:8", subtitle: "Popular") {
                            setFastingGoal(16)
                        }
                        
                        FastingPresetButton(hours: 18, title: "18:6", subtitle: "Advanced") {
                            setFastingGoal(18)
                        }
                        
                        FastingPresetButton(hours: 20, title: "20:4", subtitle: "Expert") {
                            setFastingGoal(20)
                        }
                    }
                }
                .padding(24)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
        }
        .onAppear {
            updateFastingState()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            currentTime = Date()
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            updateFastingState()
        }
    }
    
    // MARK: - Private Methods
    
    private func updateFastingState() {
        isFasting = UserDefaults.standard.bool(forKey: "isFasting")
        fastingStartTime = UserDefaults.standard.object(forKey: "fastingStartTime") as? Date
        fastingGoal = UserDefaults.standard.integer(forKey: "fastingGoal") == 0 ? 16 : UserDefaults.standard.integer(forKey: "fastingGoal")
    }
    
    private func startFasting() {
        isFasting = true
        fastingStartTime = Date()
        UserDefaults.standard.set(true, forKey: "isFasting")
        UserDefaults.standard.set(fastingStartTime, forKey: "fastingStartTime")
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func stopFasting() {
        isFasting = false
        fastingStartTime = nil
        UserDefaults.standard.set(false, forKey: "isFasting")
        UserDefaults.standard.removeObject(forKey: "fastingStartTime")
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    private func setFastingGoal(_ hours: Int) {
        fastingGoal = hours
        UserDefaults.standard.set(hours, forKey: "fastingGoal")
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Fasting Stage Row Component

struct FastingStageRow: View {
    let hours: String
    let title: String
    let description: String
    let color: Color
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Time badge
            Text(hours)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isActive ? .white : color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isActive ? color : Color(.systemGray5))
                .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isActive ? color : .primary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Fasting Preset Button Component

struct FastingPresetButton: View {
    let hours: Int
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("\(hours) hours")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}