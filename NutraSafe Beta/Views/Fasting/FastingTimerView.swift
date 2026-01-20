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
    @Environment(\.colorScheme) private var colorScheme

    // PERFORMANCE: Static gradient to avoid recreation on every render
    private static let progressGradient = LinearGradient(
        colors: [.orange, .red, .purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    @State private var currentSession: FastingSession? = nil
    @State private var currentPlan: FastingPlan? = nil
    @State private var sessions: [FastingSession] = []
    @State private var fastingGoal = 16
    @State private var notificationsEnabled = false
    @State private var currentTime = Date()
    @State private var showingSettings = false
    @State private var isLoading = true
    @State private var showStopConfirm = false
    @State private var stopConfirmText = ""
    @State private var showStopError = false
    @State private var stopErrorText = ""
    @State private var showingCitations = false
    @State private var showingStartOptions = false
    @State private var startOverride = Date()
    @State private var showingEditFast = false
    @State private var editStartTime = Date()
    @State private var editTargetHours = 16
    private var isRegimeActive: Bool { currentPlan?.active == true }

    // Live Activity
    @State private var currentActivity: Any? // Holds Activity<FastingActivityAttributes> on iOS 16.1+

    // Fast Session ID for notification validation
    @AppStorage("activeFastSessionId") private var activeFastSessionId: String = ""

    private var isFasting: Bool {
        currentSession?.isActive ?? false
    }

    private var fastingStartTime: Date? {
        currentSession?.startTime
    }

    private var fastingDuration: TimeInterval {
        guard let session = currentSession, session.isActive else { return 0 }
        let elapsed = currentTime.timeIntervalSince(session.startTime)
        return max(0, elapsed) // Ensure we never return negative duration
    }

    private var fastingProgress: Double {
        guard let session = currentSession else { return 0 }
        let goalSeconds = Double(session.targetDurationHours) * 3600
        return min(fastingDuration / goalSeconds, 1.0)
    }

    private var formattedDuration: String {
        let hours = Int(fastingDuration) / 3600
        let minutes = (Int(fastingDuration) % 3600) / 60
        let seconds = Int(fastingDuration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private var remainingText: String {
        guard let session = currentSession, session.isActive else { return "0h 0m" }
        let targetSeconds = Double(session.targetDurationHours) * 3600
        let elapsedSeconds = fastingDuration
        let remainingSeconds = max(0, targetSeconds - elapsedSeconds)
        
        let remainingHours = Int(remainingSeconds) / 3600
        let remainingMinutes = (Int(remainingSeconds) % 3600) / 60
        
        return "\(remainingHours)h \(remainingMinutes)m"
    }
    
    private var analytics: FastingAnalytics {
        FastingManager.calculateAnalytics(from: sessions)
    }

    private var timerCard: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Intermittent Fasting")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                if !isRegimeActive {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
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
                        Self.progressGradient, // PERFORMANCE: Use static gradient
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
                            .fixedSize()

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
                .frame(minHeight: 80)
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
                        .foregroundColor(AppPalette.standard.accent)
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
                    Button(action: { showingStartOptions = true }) {
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
                if isFasting {
                    Button(action: {
                        editStartTime = currentSession?.startTime ?? Date()
                        editTargetHours = currentSession?.targetDurationHours ?? fastingGoal
                        showingEditFast = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 18))
                            Text("Edit Fast")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
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
    }

    private var streakSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fasting Streak")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.primary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                metricChip(title: "Current", value: "\(analytics.currentWeeklyStreak)")
                metricChip(title: "Best", value: "\(analytics.bestWeeklyStreak)")
                metricChip(title: "Plans", value: "\(sessions.count) completed")
                metricChip(title: "Total Fasts", value: "\(sessions.count)")
                metricChip(title: "Average", value: String(format: "%.1f h", analytics.averageDurationHours))
                metricChip(title: "Longest", value: String(format: "%.1f h", analytics.longestFastHours))
            }
        }
        .padding(24)
        .background(Color.adaptiveCard)
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }

    private var stagesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Fasting Stages")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Button(action: {
                    showingCitations = true
                }) {
                    Text("View Sources")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppPalette.standard.accent)
                }
            }

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
        .background(Color.adaptiveCard)
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }

    private var presetsCard: some View {
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
        .background(Color.adaptiveCard)
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                timerCard

                FastingHistoryDropdown()
                    .environmentObject(firebaseManager)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                streakSummary
                stagesCard
                presetsCard

                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
        }
        .onAppear {
            Task {
                await loadFastingData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .fastHistoryUpdated)) { _ in
            Task {
                do {
                    let sessions = try await firebaseManager.getFastingSessions()
                    await MainActor.run { self.sessions = sessions }
                } catch {
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
            // PERFORMANCE: Only update when there's an active fasting session
            guard let session = currentSession, session.isActive else { return }

            currentTime = Date()

            // Validate session timing to prevent edge cases
            let elapsed = currentTime.timeIntervalSince(session.startTime)
            guard elapsed >= 0 else { return }

            // Update Live Activity every minute for valid sessions
            if isFasting && Int(elapsed) % 60 == 0 {
                Task {
                    if #available(iOS 16.1, *) {
                        await updateLiveActivity()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingSettings) {
            FastingSettingsView(
                fastingGoal: $fastingGoal,
                notificationsEnabled: $notificationsEnabled,
                onSave: saveFastingSettings
            )
            .environmentObject(firebaseManager)
        }
        .fullScreenCover(isPresented: $showingCitations) {
            FastingCitationsView()
        }
        .fullScreenCover(isPresented: $showingStartOptions) {
            VStack(spacing: 16) {
                DatePicker("Started At", selection: $startOverride, in: ...Date(), displayedComponents: .hourAndMinute)
                HStack {
                    Stepper("Goal: \(editTargetHours)h", value: $editTargetHours, in: 8...24)
                }
                Button {
                    fastingGoal = editTargetHours
                    startFasting(at: startOverride)
                    showingStartOptions = false
                } label: {
                    Text("Start")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .fullScreenCover(isPresented: $showingEditFast) {
            VStack(spacing: 16) {
                DatePicker("Start Time", selection: $editStartTime, in: ...Date(), displayedComponents: .hourAndMinute)
                Stepper("Goal: \(editTargetHours)h", value: $editTargetHours, in: 8...24)
                Button {
                    editActiveFast()
                    showingEditFast = false
                } label: {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    // MARK: - Private Methods

    private func loadFastingData() async {
        do {
            let plans = try await firebaseManager.getFastingPlans()
            let allSessions = try await firebaseManager.getFastingSessions()

            // Find active session
            let activeSession = allSessions.first { $0.isActive }

            await MainActor.run {
                self.sessions = allSessions
                self.currentPlan = plans.first(where: { $0.isActive })
                self.currentSession = activeSession

                // Set goal from active session or plan
                if let session = activeSession {
                    self.fastingGoal = session.targetDurationHours
                } else if let plan = self.currentPlan {
                    self.fastingGoal = plan.durationHours
                }

                self.isLoading = false
            }

            // Restart Live Activity and notifications if user has active session
            if activeSession != nil {
                if #available(iOS 16.1, *) {
                    await startLiveActivity()
                }
                await scheduleFastingNotifications()
            }
        } catch {
                        await MainActor.run {
                isLoading = false
            }
        }
    }

    private func startFasting() {
        // Generate unique session ID for this fast
        activeFastSessionId = UUID().uuidString
        
        // Create new session
        let newSession = FastingManager.createSession(
            userId: firebaseManager.currentUser?.uid ?? "",
            plan: currentPlan,
            targetDurationHours: fastingGoal,
            startTime: Date()
        )

        Task {
            do {
                _ = try await firebaseManager.saveFastingSession(newSession)

                // Reload to get the saved session with ID
                await loadFastingData()
            } catch {
                // Silently handle save errors
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

    private func startFasting(at startTime: Date) {
        activeFastSessionId = UUID().uuidString
        let newSession = FastingManager.createSession(
            userId: firebaseManager.currentUser?.uid ?? "",
            plan: currentPlan,
            targetDurationHours: fastingGoal,
            startTime: startTime
        )
        Task {
            do {
                let _ = try await firebaseManager.saveFastingSession(newSession)
                await loadFastingData()
            } catch {
            }
            if #available(iOS 16.1, *) {
                await startLiveActivity()
            }
            await scheduleFastingNotifications()
        }
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    private func editActiveFast() {
        guard var session = currentSession else { return }
        session.startTime = editStartTime
        session.targetDurationHours = editTargetHours
        session.manuallyEdited = true
        Task {
            do {
                try await firebaseManager.updateFastingSession(session)
                await MainActor.run {
                    currentSession = session
                    fastingGoal = session.targetDurationHours
                }
                // Persist overrides so regime view picks up changes immediately
                UserDefaults.standard.set(editStartTime, forKey: "customFastingStartTimeOverride")
                UserDefaults.standard.set(editTargetHours, forKey: "customFastingTargetHoursOverride")
                NotificationCenter.default.post(name: .fastHistoryUpdated, object: nil)
            } catch {
            }
        }
    }

    private func stopFasting() {
        // Clear session ID immediately to prevent notifications
                activeFastSessionId = ""

        // Cancel all fasting notifications IMMEDIATELY (synchronous)
        cancelFastingNotifications()

        // Clear current session locally
        currentSession = nil

        Task {
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

        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    private func saveFastingSettings() {
        // Settings are now saved with the session
            }

    // MARK: - Live Activities (Dynamic Island)
    @available(iOS 16.1, *)
    private func startLiveActivity() async {

        let authInfo = ActivityAuthorizationInfo()

        #if targetEnvironment(simulator)
                        #else
                #endif

        guard authInfo.areActivitiesEnabled else {
                                    return
        }

        guard let startTime = fastingStartTime else {
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
            let content = ActivityContent(state: contentState, staleDate: nil)
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            currentActivity = activity
        } catch {
            // Silently handle Live Activity errors
        }
    }

    @available(iOS 16.1, *)
    private func updateLiveActivity() async {
        guard let activity = currentActivity as? Activity<FastingActivityAttributes> else {
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

        let content = ActivityContent(state: contentState, staleDate: nil)
        await activity.update(content)
    }

    @available(iOS 16.1, *)
    private func endLiveActivity() async {
        guard let activity = currentActivity as? Activity<FastingActivityAttributes> else {
                        return
        }
        await activity.end(nil, dismissalPolicy: .immediate)
        currentActivity = nil
            }

    // MARK: - Fasting Notifications
    private func scheduleFastingNotifications() async {
        guard notificationsEnabled else {
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
                                        return
                }
            } catch {
                                return
            }
        } else if settings.authorizationStatus != .authorized {
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

                // Add session ID and type to userInfo for validation
                content.userInfo = [
                    "type": "fasting",
                    "sessionId": activeFastSessionId,
                    "stageHours": stage.hours
                ]

                let timeInterval = triggerDate.timeIntervalSinceNow
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "fasting-stage-\(stage.hours)h",
                    content: content,
                    trigger: trigger
                )

                do {
                    try await center.add(request)
                                    } catch {
                                    }
            }
        }

        // Schedule goal completion notification
        await scheduleGoalNotification(startTime: startTime)
    }

    private func scheduleGoalNotification(startTime: Date) async {
        guard notificationsEnabled else { return }

        let center = UNUserNotificationCenter.current()
        let goalHours = fastingGoal

        // Goal reached notification
        let goalDate = startTime.addingTimeInterval(TimeInterval(goalHours * 3600))
        if goalDate > Date() {
            let content = UNMutableNotificationContent()
            content.title = "Fasting Goal Achieved! 🎉"
            content.body = "Congratulations! You've completed your \(goalHours)-hour fast!"
            content.sound = .default

            // Add session ID and type to userInfo for validation
            content.userInfo = [
                "type": "fasting",
                "sessionId": activeFastSessionId,
                "isGoal": true
            ]

            let timeInterval = goalDate.timeIntervalSinceNow
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
            let request = UNNotificationRequest(
                identifier: "fasting-goal-complete",
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
                            } catch {
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
    }

    private func prepareStopFasting() {
        guard let start = fastingStartTime else {
            stopErrorText = "No start time found."
            showStopError = true
            return
        }
        let end = Date()
        let duration = end.timeIntervalSince(start) / 3600.0
        let withinTarget = duration >= Double(fastingGoal)

        stopConfirmText = String(format: "Duration: %.1f h (%@). Save to NutraSafe history?",
                                 duration, withinTarget ? "within target" : "outside target")
        showStopConfirm = true
    }

    private func stopFastingAndRecord() {
        guard let session = currentSession else {
            stopErrorText = "No active session found."
            showStopError = true
            return
        }

        let end = Date()
        let completedSession = FastingManager.endSession(session, endTime: end)

        Task {
            do {
                _ = try await firebaseManager.saveFastingSession(completedSession)
                
                // Reload sessions to update history
                await loadFastingData()

                // Post notification to update history dropdown
                NotificationCenter.default.post(name: .fastHistoryUpdated, object: nil)
            } catch {
                            }
        }
        stopFasting()
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
    @State private var customGoal: Int
    @State private var notificationSettings: FastingNotificationSettings
    let onSave: () -> Void

    init(fastingGoal: Binding<Int>, notificationsEnabled: Binding<Bool>, onSave: @escaping () -> Void) {
        self._fastingGoal = fastingGoal
        self._notificationsEnabled = notificationsEnabled
        self._customGoal = State(initialValue: fastingGoal.wrappedValue)
        self._notificationSettings = State(initialValue: FastingNotificationManager.shared.settings)
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
                    .padding(.horizontal, 16)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 8)
                }

                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        .tint(AppPalette.standard.accent)
                }

                if notificationsEnabled {
                    Section(header: Text("Notification Types"), footer: Text("Choose which notifications you'd like to receive")) {
                        Toggle("Fast Starting", isOn: $notificationSettings.startNotificationEnabled)
                            .tint(AppPalette.standard.accent)
                        Toggle("Fast Ending", isOn: $notificationSettings.endNotificationEnabled)
                            .tint(AppPalette.standard.accent)
                        Toggle("Stage Progress", isOn: $notificationSettings.stageNotificationsEnabled)
                            .tint(AppPalette.standard.accent)
                    }

                    if notificationSettings.stageNotificationsEnabled {
                        Section(header: Text("Stage Notifications"), footer: Text("Get notified as you reach each fasting milestone")) {
                            Toggle("4h - Post-meal complete", isOn: $notificationSettings.stage4hEnabled)
                                .tint(.orange)
                            Toggle("8h - Fuel switching", isOn: $notificationSettings.stage8hEnabled)
                                .tint(.orange)
                            Toggle("12h - Fat mobilisation", isOn: $notificationSettings.stage12hEnabled)
                                .tint(.orange)
                            Toggle("16h - Mild ketosis", isOn: $notificationSettings.stage16hEnabled)
                                .tint(.purple)
                            Toggle("20h - Autophagy potential", isOn: $notificationSettings.stage20hEnabled)
                                .tint(.purple)
                        }
                    }
                }

                Section(header: Text("About Intermittent Fasting")) {
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(icon: "clock.fill", color: .orange, title: "12:12", description: "Good for beginners, gentle fasting")
                        InfoRow(icon: "flame.fill", color: .red, title: "16:8", description: "Most popular plan, may support fat burning")
                        InfoRow(icon: "bolt.fill", color: .purple, title: "18:6", description: "May support autophagy and ketosis")
                        InfoRow(icon: "star.fill", color: .yellow, title: "20:4", description: "Advanced, longer fasting window")
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
        FastingNotificationManager.shared.settings = notificationSettings
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
