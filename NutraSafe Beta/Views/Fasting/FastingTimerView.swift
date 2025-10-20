//
//  FastingTimerView.swift
//  NutraSafe Beta
//
//  Comprehensive intermittent fasting tracking system with timer, stages, and presets
//  Extracted from ContentView.swift to achieve 10,000-line milestone
//

import SwiftUI
import ActivityKit

// MARK: - Fasting Timer Main View

struct FastingTimerView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager

    @State private var isFasting = false
    @State private var fastingStartTime: Date?
    @State private var fastingGoal = 16
    @State private var notificationsEnabled = false
    @State private var reminderInterval = 4
    @State private var currentTime = Date()
    @State private var showingSettings = false
    @State private var isLoading = true

    // Live Activity
    @State private var currentActivity: Any? // Holds Activity<FastingActivityAttributes> on iOS 16.1+
    
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
        let seconds = Int(fastingDuration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
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
                        
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                        }
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
            Task {
                await loadFastingState()
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            currentTime = Date()

            // Update Live Activity every minute
            if isFasting && Int(fastingDuration) % 60 == 0 {
                Task {
                    if #available(iOS 16.1, *) {
                        await updateLiveActivity()
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            FastingSettingsView(
                fastingGoal: $fastingGoal,
                notificationsEnabled: $notificationsEnabled,
                reminderInterval: $reminderInterval,
                onSave: saveFastingSettings
            )
            .environmentObject(firebaseManager)
        }
    }

    // MARK: - Private Methods

    private func loadFastingState() async {
        do {
            let state = try await firebaseManager.getFastingState()
            await MainActor.run {
                isFasting = state.isFasting
                fastingStartTime = state.startTime
                fastingGoal = state.goal
                notificationsEnabled = state.notificationsEnabled
                reminderInterval = state.reminderInterval
                isLoading = false
            }

            // Restart Live Activity if user was fasting
            if state.isFasting {
                if #available(iOS 16.1, *) {
                    await startLiveActivity()
                }
            }
        } catch {
            print("❌ Error loading fasting state: \(error.localizedDescription)")
            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func startFasting() {
        isFasting = true
        fastingStartTime = Date()

        Task {
            do {
                try await firebaseManager.saveFastingState(
                    isFasting: true,
                    startTime: fastingStartTime,
                    goal: fastingGoal,
                    notificationsEnabled: notificationsEnabled,
                    reminderInterval: reminderInterval
                )
            } catch {
                print("❌ Error saving fasting start: \(error.localizedDescription)")
            }

            // Start Live Activity for Dynamic Island
            if #available(iOS 16.1, *) {
                await startLiveActivity()
            }
        }

        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    private func stopFasting() {
        isFasting = false
        fastingStartTime = nil

        Task {
            do {
                try await firebaseManager.saveFastingState(
                    isFasting: false,
                    startTime: nil,
                    goal: fastingGoal,
                    notificationsEnabled: notificationsEnabled,
                    reminderInterval: reminderInterval
                )
            } catch {
                print("❌ Error saving fasting stop: \(error.localizedDescription)")
            }

            // End Live Activity
            if #available(iOS 16.1, *) {
                await endLiveActivity()
            }
        }

        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }

    private func setFastingGoal(_ hours: Int) {
        fastingGoal = hours

        Task {
            do {
                try await firebaseManager.saveFastingState(
                    isFasting: isFasting,
                    startTime: fastingStartTime,
                    goal: hours,
                    notificationsEnabled: notificationsEnabled,
                    reminderInterval: reminderInterval
                )
            } catch {
                print("❌ Error saving fasting goal: \(error.localizedDescription)")
            }
        }

        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    private func saveFastingSettings() {
        Task {
            do {
                try await firebaseManager.saveFastingState(
                    isFasting: isFasting,
                    startTime: fastingStartTime,
                    goal: fastingGoal,
                    notificationsEnabled: notificationsEnabled,
                    reminderInterval: reminderInterval
                )
            } catch {
                print("❌ Error saving fasting settings: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Live Activities (Dynamic Island)
    @available(iOS 16.1, *)
    private func startLiveActivity() async {
        print("🔵 startLiveActivity called")

        let authInfo = ActivityAuthorizationInfo()
        print("🔵 Live Activities enabled: \(authInfo.areActivitiesEnabled)")

        guard authInfo.areActivitiesEnabled else {
            print("❌ Live Activities not enabled by system")
            print("ℹ️  Note: Live Activities don't work in simulator - test on real device with Dynamic Island")
            return
        }

        guard let startTime = fastingStartTime else {
            print("❌ No fasting start time")
            return
        }

        let hours = Int(fastingDuration / 3600)
        let minutes = Int((fastingDuration.truncatingRemainder(dividingBy: 3600)) / 60)

        let attributes = FastingActivityAttributes(fastingGoalHours: fastingGoal)
        let contentState = FastingActivityAttributes.ContentState(
            fastingStartTime: startTime,
            currentHours: hours,
            currentMinutes: minutes
        )

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            print("✅ Fasting Live Activity started - will appear in Dynamic Island")
        } catch {
            print("❌ Failed to start Live Activity: \(error)")
        }
    }

    @available(iOS 16.1, *)
    private func updateLiveActivity() async {
        guard let activity = currentActivity as? Activity<FastingActivityAttributes> else { return }
        guard let startTime = fastingStartTime else { return }

        let hours = Int(fastingDuration / 3600)
        let minutes = Int((fastingDuration.truncatingRemainder(dividingBy: 3600)) / 60)

        let contentState = FastingActivityAttributes.ContentState(
            fastingStartTime: startTime,
            currentHours: hours,
            currentMinutes: minutes
        )

        await activity.update(using: contentState)
    }

    @available(iOS 16.1, *)
    private func endLiveActivity() async {
        guard let activity = currentActivity as? Activity<FastingActivityAttributes> else { return }
        await activity.end(dismissalPolicy: .immediate)
        currentActivity = nil
        print("✅ Fasting Live Activity ended")
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
            // Time badge - fixed width
            Text(hours)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isActive ? .white : color)
                .frame(width: 60)
                .padding(.vertical, 6)
                .background(isActive ? color : Color(.systemGray5))
                .cornerRadius(8)

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
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("\(hours) hours")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.orange)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Fasting Settings View

struct FastingSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseManager: FirebaseManager
    @Binding var fastingGoal: Int
    @Binding var notificationsEnabled: Bool
    @Binding var reminderInterval: Int
    @State private var customGoal: Int
    let onSave: () -> Void

    init(fastingGoal: Binding<Int>, notificationsEnabled: Binding<Bool>, reminderInterval: Binding<Int>, onSave: @escaping () -> Void) {
        self._fastingGoal = fastingGoal
        self._notificationsEnabled = notificationsEnabled
        self._reminderInterval = reminderInterval
        self._customGoal = State(initialValue: fastingGoal.wrappedValue)
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Fasting Goal")) {
                    Picker("Goal Duration", selection: $customGoal) {
                        ForEach([12, 14, 16, 18, 20, 22, 24], id: \.self) { hours in
                            Text("\(hours) hours").tag(hours)
                        }
                    }
                    .pickerStyle(.wheel)

                    HStack {
                        Text("Current Goal")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(customGoal)h")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                }

                Section(header: Text("Quick Presets")) {
                    HStack(spacing: 12) {
                        PresetButton(title: "12h", subtitle: "Beginner", hours: 12, currentGoal: $customGoal)
                        PresetButton(title: "16h", subtitle: "Popular", hours: 16, currentGoal: $customGoal)
                        PresetButton(title: "18h", subtitle: "Advanced", hours: 18, currentGoal: $customGoal)
                        PresetButton(title: "20h", subtitle: "Expert", hours: 20, currentGoal: $customGoal)
                    }
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 8)
                }

                Section(header: Text("Notifications"), footer: Text("Get reminders during your fasting window")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        .tint(.blue)

                    if notificationsEnabled {
                        Picker("Reminder Interval", selection: $reminderInterval) {
                            Text("Every 2 hours").tag(2)
                            Text("Every 4 hours").tag(4)
                            Text("Every 6 hours").tag(6)
                            Text("Every 8 hours").tag(8)
                        }
                    }
                }

                Section(header: Text("About Intermittent Fasting")) {
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(icon: "clock.fill", color: .orange, title: "12:12", description: "Good for beginners, gentle fasting")
                        InfoRow(icon: "flame.fill", color: .red, title: "16:8", description: "Most popular, effective fat burning")
                        InfoRow(icon: "bolt.fill", color: .purple, title: "18:6", description: "Enhanced autophagy and ketosis")
                        InfoRow(icon: "star.fill", color: .yellow, title: "20:4", description: "Advanced, maximum benefits")
                    }
                }
            }
            .navigationTitle("Fasting Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveSettings() {
        fastingGoal = customGoal
        onSave()

        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Settings Components

struct PresetButton: View {
    let title: String
    let subtitle: String
    let hours: Int
    @Binding var currentGoal: Int

    var body: some View {
        Button(action: {
            currentGoal = hours
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(currentGoal == hours ? .white : .primary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(currentGoal == hours ? .white.opacity(0.9) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(currentGoal == hours ?
                        LinearGradient(
                            colors: [
                                Color(red: 0.3, green: 0.5, blue: 1.0),
                                Color(red: 0.5, green: 0.3, blue: 0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color(.systemGray6), Color(.systemGray6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InfoRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }
}