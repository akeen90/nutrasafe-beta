//
//  FastingTimerView.swift
//  NutraSafe Beta
//
//  Comprehensive intermittent fasting tracking system with timer, stages, and presets
//  Extracted from ContentView.swift to achieve 10,000-line milestone
//

import SwiftUI
import ActivityKit
import UserNotifications

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
    @State private var streakSettings = FastingStreakSettings.default
    @State private var showStopConfirm = false
    @State private var stopConfirmText = ""
    @State private var showStopError = false
    @State private var stopErrorText = ""
    @State private var fastHistory: [FastRecord] = []

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

    private var remainingText: String {
        let remaining = max(0, Double(fastingGoal) * 3600 - fastingDuration)
        let remainingHours = Int(remaining) / 3600
        let remainingMinutes = (Int(remaining) % 3600) / 60
        return "\(remainingHours)h \(remainingMinutes)m"
    }
    
    private var analytics: FastingAnalyticsSummary {
        FastingManager.analytics(from: fastHistory, settings: streakSettings)
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
                            Text(remainingText)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        if isFasting {
                            Button(action: prepareStopFasting) {
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
                
                // Fasting History Dropdown
                FastingHistoryDropdown()
                    .environmentObject(firebaseManager)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                
                // Fasting Streak Summary
                VStack(alignment: .leading, spacing: 16) {
                    Text("Fasting Streak")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        metricChip(title: "Current", value: "\(analytics.currentWeeklyStreak)")
                        metricChip(title: "Best", value: "\(analytics.bestWeeklyStreak)")
                        metricChip(title: "Goal", value: "\(streakSettings.daysPerWeekGoal) days per week")
                        metricChip(title: "Total Fasts", value: "\(fastHistory.count)")
                        metricChip(title: "Average", value: String(format: "%.1f h", analytics.averageDurationHours))
                        metricChip(title: "Longest", value: String(format: "%.1f h", analytics.longestFastHours))
                    }
                }
                .padding(24)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .padding(.horizontal, 16)
                
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
                
                // History moved above stages; duplicate removed
                
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
                do {
                    let settings = try await firebaseManager.getFastingStreakSettings()
                    await MainActor.run { streakSettings = settings }
                } catch {
                    // keep defaults if load fails
                    print("⚠️ Failed to load fasting streak settings: \(error.localizedDescription)")
                }
                do {
                    let records = try await firebaseManager.getFastHistory()
                    await MainActor.run { fastHistory = records }
                } catch {
                    print("⚠️ Failed to load fast history: \(error.localizedDescription)")
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .fastHistoryUpdated)) { _ in
            Task {
                do {
                    let records = try await firebaseManager.getFastHistory()
                    await MainActor.run { fastHistory = records }
                } catch {
                    print("⚠️ Failed to refresh fast history: \(error.localizedDescription)")
                }
            }
        }
        .alert("Confirm End Fast", isPresented: $showStopConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Save Fast & Stop", role: .destructive) {
                stopFastingAndRecord()
            }
        } message: {
            Text(stopConfirmText)
        }
        .alert("Fast Not Allowed", isPresented: $showStopError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(stopErrorText)
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
                streakSettings: $streakSettings,
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

            // Restart Live Activity and notifications if user was fasting
            if state.isFasting {
                if #available(iOS 16.1, *) {
                    await startLiveActivity()
                }
                await scheduleFastingNotifications()
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

            // Schedule fasting notifications
            await scheduleFastingNotifications()
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

            // Cancel all fasting notifications
            cancelFastingNotifications()
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
        print("🔵 Current device: \(UIDevice.current.model)")
        print("🔵 iOS version: \(UIDevice.current.systemVersion)")

        let authInfo = ActivityAuthorizationInfo()
        print("🔵 Live Activities enabled: \(authInfo.areActivitiesEnabled)")

        #if targetEnvironment(simulator)
        print("⚠️  Running in SIMULATOR - Live Activities won't appear")
        print("ℹ️  Deploy to real iPhone 14 Pro/15 Pro/16 Pro to see Dynamic Island")
        #else
        print("✅ Running on REAL DEVICE")
        #endif

        guard authInfo.areActivitiesEnabled else {
            print("❌ Live Activities not enabled by system")
            print("ℹ️  Check: Settings > [Your App Name] > Allow Live Activities")
            return
        }

        guard let startTime = fastingStartTime else {
            print("❌ No fasting start time")
            return
        }

        let hours = Int(fastingDuration / 3600)
        let minutes = Int((fastingDuration.truncatingRemainder(dividingBy: 3600)) / 60)

        print("🔵 Creating Live Activity with:")
        print("   - Goal: \(fastingGoal)h")
        print("   - Current: \(hours)h \(minutes)m")
        print("   - Start time: \(startTime)")

        let attributes = FastingActivityAttributes(fastingGoalHours: fastingGoal)
        let contentState = FastingActivityAttributes.ContentState(
            fastingStartTime: startTime,
            currentHours: hours,
            currentMinutes: minutes
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            currentActivity = activity
            print("✅ Live Activity created successfully!")
            print("   - Activity ID: \(activity.id)")
            print("   - Activity state: \(activity.activityState)")
            print("   - This should now appear in Dynamic Island")

            // List all active activities to verify
            let activeActivities = Activity<FastingActivityAttributes>.activities
            print("📋 Total active fasting activities: \(activeActivities.count)")
        } catch {
            print("❌ Failed to start Live Activity: \(error)")
            print("   - Error type: \(type(of: error))")
            print("   - Error details: \(error.localizedDescription)")
        }
    }

    @available(iOS 16.1, *)
    private func updateLiveActivity() async {
        guard let activity = currentActivity as? Activity<FastingActivityAttributes> else {
            print("⚠️  No active Live Activity to update")
            return
        }
        guard let startTime = fastingStartTime else { return }

        let hours = Int(fastingDuration / 3600)
        let minutes = Int((fastingDuration.truncatingRemainder(dividingBy: 3600)) / 60)

        let contentState = FastingActivityAttributes.ContentState(
            fastingStartTime: startTime,
            currentHours: hours,
            currentMinutes: minutes
        )

        await activity.update(using: contentState)
        print("🔄 Live Activity updated: \(hours)h \(minutes)m")
    }

    @available(iOS 16.1, *)
    private func endLiveActivity() async {
        guard let activity = currentActivity as? Activity<FastingActivityAttributes> else {
            print("⚠️  No active Live Activity to end")
            return
        }
        await activity.end(dismissalPolicy: .immediate)
        currentActivity = nil
        print("✅ Fasting Live Activity ended and removed from Dynamic Island")
    }

    // MARK: - Fasting Notifications
    private func scheduleFastingNotifications() async {
        guard notificationsEnabled else {
            print("⏸️ Fasting notifications disabled - not scheduling")
            return
        }

        guard let startTime = fastingStartTime else { return }

        // Request permission
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        if settings.authorizationStatus == .notDetermined {
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                if !granted {
                    print("❌ Notification permission denied")
                    return
                }
            } catch {
                print("❌ Error requesting notification permission: \(error)")
                return
            }
        } else if settings.authorizationStatus != .authorized {
            print("❌ Notifications not authorized")
            return
        }

        // Clear any existing fasting notifications
        cancelFastingNotifications()

        // Schedule stage notifications
        let stages = [
            (hours: 4, title: "Early Fat Burning 🔥", body: "Your body is starting to burn stored fat for energy"),
            (hours: 8, title: "Fat Burning Mode 💪", body: "You're in active fat burning! Keep going!"),
            (hours: 12, title: "Ketosis Beginning 🌟", body: "Great progress! Your body is entering ketosis"),
            (hours: 16, title: "Deep Ketosis Achieved 🎯", body: "Amazing! You've reached deep ketosis and autophagy")
        ]

        for stage in stages {
            let triggerDate = startTime.addingTimeInterval(TimeInterval(stage.hours * 3600))

            // Only schedule if in the future
            if triggerDate > Date() {
                let content = UNMutableNotificationContent()
                content.title = stage.title
                content.body = stage.body
                content.sound = .default
                content.badge = 1

                let timeInterval = triggerDate.timeIntervalSinceNow
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "fasting-stage-\(stage.hours)h",
                    content: content,
                    trigger: trigger
                )

                do {
                    try await center.add(request)
                    print("✅ Scheduled \(stage.hours)h fasting notification")
                } catch {
                    print("❌ Error scheduling \(stage.hours)h notification: \(error)")
                }
            }
        }

        // Schedule periodic reminders based on user interval
        await schedulePeriodicReminders(startTime: startTime)
    }

    private func schedulePeriodicReminders(startTime: Date) async {
        guard notificationsEnabled else { return }

        let center = UNUserNotificationCenter.current()
        let goalHours = fastingGoal
        var currentHour = reminderInterval

        // Schedule reminders at user-defined intervals until goal
        while currentHour < goalHours {
            let triggerDate = startTime.addingTimeInterval(TimeInterval(currentHour * 3600))

            // Only schedule if in the future and not a stage notification
            if triggerDate > Date() && ![4, 8, 12, 16].contains(currentHour) {
                let content = UNMutableNotificationContent()
                content.title = "Fasting Progress ⏰"
                content.body = "\(currentHour)h of your \(goalHours)h fast complete!"
                content.sound = .default

                let timeInterval = triggerDate.timeIntervalSinceNow
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "fasting-reminder-\(currentHour)h",
                    content: content,
                    trigger: trigger
                )

                do {
                    try await center.add(request)
                    print("✅ Scheduled \(currentHour)h reminder notification")
                } catch {
                    print("❌ Error scheduling reminder: \(error)")
                }
            }

            currentHour += reminderInterval
        }

        // Goal reached notification
        let goalDate = startTime.addingTimeInterval(TimeInterval(goalHours * 3600))
        if goalDate > Date() {
            let content = UNMutableNotificationContent()
            content.title = "Fasting Goal Achieved! 🎉"
            content.body = "Congratulations! You've completed your \(goalHours)-hour fast!"
            content.sound = .default

            let timeInterval = goalDate.timeIntervalSinceNow
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
            let request = UNNotificationRequest(
                identifier: "fasting-goal-complete",
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
                print("✅ Scheduled goal completion notification")
            } catch {
                print("❌ Error scheduling goal notification: \(error)")
            }
        }
    }

    private func cancelFastingNotifications() {
        let center = UNUserNotificationCenter.current()

        // Build list of all possible notification identifiers
        var identifiers = [
            "fasting-stage-4h",
            "fasting-stage-8h",
            "fasting-stage-12h",
            "fasting-stage-16h",
            "fasting-goal-complete"
        ]

        // Add reminder identifiers (up to 24 hours with 2-hour intervals)
        for hour in stride(from: 2, through: 24, by: 2) {
            identifiers.append("fasting-reminder-\(hour)h")
        }

        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🗑️ Cancelled all fasting notifications")
    }

    private func prepareStopFasting() {
        guard let start = fastingStartTime else {
            stopErrorText = "No start time found."
            showStopError = true
            return
        }
        let end = Date()
        let result = FastingManager.buildRecord(startTime: start,
                                                endTime: end,
                                                settings: streakSettings,
                                                goalHours: fastingGoal)
        switch result {
        case .failure(let err):
            stopErrorText = err.reason
            showStopError = true
        case .success(let record):
            let within = record.withinTarget ? "within target" : "outside target"
            stopConfirmText = String(format: "Duration: %.1f h (%@). Save to NutraSafe history?",
                                     record.durationHours, within)
            showStopConfirm = true
        }
    }

    private func stopFastingAndRecord() {
        guard let start = fastingStartTime else {
            stopErrorText = "No start time found."
            showStopError = true
            return
        }
        let end = Date()
        let result = FastingManager.buildRecord(startTime: start,
                                                endTime: end,
                                                settings: streakSettings,
                                                goalHours: fastingGoal)
        switch result {
        case .failure(let err):
            stopErrorText = err.reason
            showStopError = true
        case .success(let record):
            Task {
                do {
                    _ = try await firebaseManager.saveFastRecord(record)
                } catch {
                    print("❌ Error saving fast record: \(error.localizedDescription)")
                }
            }
            stopFasting()
        }
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
    @Binding var streakSettings: FastingStreakSettings
    @State private var customGoal: Int
    @State private var daysGoal: Int
    @State private var minHours: Int
    @State private var maxHours: Int
    let onSave: () -> Void
    
    init(fastingGoal: Binding<Int>, notificationsEnabled: Binding<Bool>, reminderInterval: Binding<Int>, streakSettings: Binding<FastingStreakSettings>, onSave: @escaping () -> Void) {
        self._fastingGoal = fastingGoal
        self._notificationsEnabled = notificationsEnabled
        self._reminderInterval = reminderInterval
        self._streakSettings = streakSettings
        self._customGoal = State(initialValue: fastingGoal.wrappedValue)
        self._daysGoal = State(initialValue: streakSettings.wrappedValue.daysPerWeekGoal)
        self._minHours = State(initialValue: streakSettings.wrappedValue.targetMinHours)
        self._maxHours = State(initialValue: streakSettings.wrappedValue.targetMaxHours)
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

                Section(header: Text("Streak Settings"), footer: Text("Used to compute weekly streaks and target window.")) {
                    Stepper("Days per week goal: \(daysGoal)/wk", value: $daysGoal, in: 1...7)
                    Stepper("Min hours: \(minHours)h", value: $minHours, in: 12...36, step: 1)
                    Stepper("Max hours: \(maxHours)h", value: $maxHours, in: max(minHours, 12)...48, step: 1)
                    Text("Target window: \(minHours)–\(maxHours) h")
                        .font(.footnote)
                        .foregroundColor(.secondary)
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
                    Button("Cancel") { dismiss() }
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
        streakSettings.daysPerWeekGoal = daysGoal
        streakSettings.targetMinHours = minHours
        streakSettings.targetMaxHours = maxHours
        onSave()
        
        Task {
            do {
                try await firebaseManager.saveFastingStreakSettings(streakSettings)
            } catch {
                print("❌ Error saving streak settings: \(error.localizedDescription)")
            }
        }

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


private func metricChip(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 64)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }