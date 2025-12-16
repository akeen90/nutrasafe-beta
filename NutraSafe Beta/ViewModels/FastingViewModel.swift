//
//  FastingViewModel.swift
//  NutraSafe Beta
//
//  Created by Claude
//

import Foundation
import SwiftUI
import Combine
import UserNotifications

@MainActor
class FastingViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var activePlan: FastingPlan?
    @Published var allPlans: [FastingPlan] = []
    @Published var activeSession: FastingSession?
    @Published var recentSessions: [FastingSession] = []
    @Published var analytics: FastingAnalytics?

    @Published var showError = false
    @Published var error: Error?
    @Published var isLoading = false

    // Group sessions by week (Monday to Sunday)
    var weekSummaries: [WeekSummary] {
        let calendar = Calendar.current
        var weekMap: [Date: [FastingSession]] = [:]

        // Group sessions by their week start (Monday), using END date for reporting
        // This ensures multi-day fasts (e.g., Sun→Mon) appear on the day they ended
        for session in recentSessions {
            // Use endTime if available, otherwise startTime (for active sessions)
            let reportDate = session.endTime ?? session.startTime
            let weekStart = getWeekStart(for: reportDate, calendar: calendar)
            if weekMap[weekStart] == nil {
                weekMap[weekStart] = []
            }
            weekMap[weekStart]?.append(session)
        }

        // Include current week even if no sessions yet
        let currentWeekStart = getWeekStart(for: Date(), calendar: calendar)
        if weekMap[currentWeekStart] == nil {
            weekMap[currentWeekStart] = []
        }

        // Convert to WeekSummary array and sort by week start (most recent first)
        let summaries = weekMap.map { weekStart, sessions in
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
            return WeekSummary(weekStart: weekStart, weekEnd: weekEnd, sessions: sessions)
        }.sorted { $0.weekStart > $1.weekStart }

        return summaries
    }

    private func getWeekStart(for date: Date, calendar: Calendar) -> Date {
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        components.weekday = 2 // Monday (1 = Sunday, 2 = Monday in Gregorian calendar)
        return calendar.date(from: components)!
    }

    // MARK: - Private Properties

    let firebaseManager: FirebaseManager // Exposed for early-end modal
    private var timer: Timer?
    let userId: String
    private let fastingService = FastingService()

    // MARK: - Regime State Tracking
    private var previousRegimeState: FastingPlan.RegimeState?
    private var lastRecordedFastWindowEnd: Date?

    // Computed property to check if regime is snoozed
    var isRegimeSnoozed: Bool {
        guard let plan = activePlan, let planId = plan.id else { return false }
        guard let snoozeUntil = UserDefaults.standard.object(forKey: "regimeSnoozedUntil_\(planId)") as? Date else {
            return false
        }
        return snoozeUntil > Date()
    }

    var regimeSnoozedUntil: Date? {
        guard let plan = activePlan, let planId = plan.id else { return nil }
        return UserDefaults.standard.object(forKey: "regimeSnoozedUntil_\(planId)") as? Date
    }

    // Persisted storage for ended windows (survives app restart)
    private static let endedWindowKey = "lastEndedFastingWindowEnd"

    private var lastEndedWindowEnd: Date? {
        get {
            return UserDefaults.standard.object(forKey: Self.endedWindowKey) as? Date
        }
        set {
            if let date = newValue {
                UserDefaults.standard.set(date, forKey: Self.endedWindowKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.endedWindowKey)
            }
        }
    }

    // MARK: - Motivational Messages

    private let motivationalMessages = [
        "You're doing great — stay steady.",
        "Hydration helps the journey.",
        "Progress compounds.",
        "Consistency > perfection.",
        "Breathe and stay present.",
        "Your body is adapting beautifully.",
        "Every hour counts.",
        "Trust the process.",
        "You're stronger than you think.",
        "One hour at a time."
    ]

    private var lastMessageChangeTime: Date = Date()
    private var currentMessageIndex = 0

    // MARK: - Computed Properties

    var currentProgress: Double {
        guard let session = activeSession else { return 0 }
        return session.progressPercentage
    }

    var currentElapsedTime: String {
        guard let session = activeSession else { return "0:00:00" }
        let totalSeconds = Int(session.actualDurationHours * 3600)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }

    var timeUntilEnd: String {
        guard let session = activeSession else { return "0:00:00" }
        let targetSeconds = Double(session.targetDurationHours) * 3600
        let elapsedSeconds = session.actualDurationHours * 3600
        let remainingSeconds = max(0, Int(targetSeconds - elapsedSeconds))
        let hours = remainingSeconds / 3600
        let minutes = (remainingSeconds % 3600) / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }

    var previousEatingWindowDuration: String {
        guard let currentSession = activeSession else { return "0:00" }

        // Find the most recent completed session before this one
        let previousSession = recentSessions.first { session in
            guard let endTime = session.endTime else { return false }
            return endTime < currentSession.startTime && session.id != currentSession.id
        }

        guard let lastFastEnd = previousSession?.endTime else {
            return "0:00"
        }

        // Calculate time between last fast ending and current fast starting
        let eatingWindowSeconds = currentSession.startTime.timeIntervalSince(lastFastEnd)
        let totalSeconds = Int(eatingWindowSeconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        return String(format: "%d:%02d", hours, minutes)
    }

    var currentPhase: FastingPhase? {
        return activeSession?.currentPhase
    }

    var nextMilestone: String {
        guard let session = activeSession else { return "" }
        let elapsed = session.actualDurationHours
        let target = Double(session.targetDurationHours)

        if elapsed < target {
            let remaining = target - elapsed
            let totalSeconds = Int(remaining * 3600)
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60
            return "\(hours)h \(minutes)m \(seconds)s until target"
        } else {
            let over = elapsed - target
            let totalSeconds = Int(over * 3600)
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60
            return "\(hours)h \(minutes)m \(seconds)s past target"
        }
    }

    // MARK: - Eating Window Counter

    var eatingWindowTime: String {
        // Get the last completed fast
        guard let lastCompletedFast = recentSessions.first(where: { $0.endTime != nil && !$0.isActive }),
              let endTime = lastCompletedFast.endTime else {
            return "0:00:00"
        }

        // Calculate time since last fast ended
        let timeSinceEnd = Date().timeIntervalSince(endTime)
        let totalSeconds = Int(timeSinceEnd)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }

    var isInEatingWindow: Bool {
        // User is in eating window if there's no active session and they've completed a fast recently
        return activeSession == nil && recentSessions.first(where: { $0.endTime != nil }) != nil
    }

    var motivationalMessage: String {
        // Change message every 5 minutes instead of every second
        let now = Date()
        if now.timeIntervalSince(lastMessageChangeTime) >= 300 { // 5 minutes
            lastMessageChangeTime = now
            currentMessageIndex = (currentMessageIndex + 1) % motivationalMessages.count
        }
        return motivationalMessages[currentMessageIndex]
    }

    // MARK: - Initialization

    init(firebaseManager: FirebaseManager, userId: String) {
        self.firebaseManager = firebaseManager
        self.userId = userId

        // Listen for session updates
        NotificationCenter.default.addObserver(
            forName: .fastHistoryUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🔔 Received .fastHistoryUpdated notification - refreshing sessions")
            Task {
                await self?.loadRecentSessions()
                await self?.loadActiveSession()
                await self?.loadAnalytics()
            }
        }

        Task {
            await loadInitialData()
            startTimer()
        }
    }

    deinit {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self, name: .fastHistoryUpdated, object: nil)
    }

    // MARK: - Data Loading

    private func loadInitialData() async {
        await loadActivePlan()

        // PERFORMANCE: Fetch sessions once and share across all functions
        // This eliminates triple-fetching (getFastingSessions was called 3 times)
        do {
            let sessions = try await firebaseManager.getFastingSessions()

            // Pass shared sessions to all loaders to avoid redundant fetches
            await loadActiveSession(from: sessions)
            await loadRecentSessions(from: sessions)
            await loadAnalytics(from: sessions)
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func loadActivePlan() async {
        // If we already have an active plan set locally (e.g., just created one),
        // skip the Firestore fetch to avoid race condition with eventual consistency
        if self.activePlan != nil {
            print("   ℹ️  Active plan already set locally - skipping Firestore fetch to avoid race condition")
            return
        }

        await fetchActivePlanFromFirebase()
    }

    /// Force refresh the active plan from Firebase - used when returning from background
    func refreshActivePlan() async {
        await fetchActivePlanFromFirebase()
    }

    private func fetchActivePlanFromFirebase() async {
        do {
            print("   📥 Fetching plans from Firebase...")
            let plans = try await firebaseManager.getFastingPlans()
            print("   📊 Received \(plans.count) total plans from Firebase")
            let activePlan = plans.first(where: { $0.active })
            if let active = activePlan {
                print("   ✅ Found active plan: '\(active.name)' (ID: \(active.id ?? "nil"))")
                self.activePlan = active
            } else {
                print("   ⚠️ No active plan found in \(plans.count) plans")
                self.activePlan = nil
            }
        } catch {
            print("   ❌ Failed to load active plan: \(error.localizedDescription)")
            self.error = error
            self.showError = true
        }
    }

    func loadAllPlans() async {
        do {
            print("   📥 Fetching all plans from Firebase...")
            let plans = try await firebaseManager.getFastingPlans()
            print("   📊 Received \(plans.count) total plans")
            for (index, plan) in plans.enumerated() {
                print("      Plan \(index + 1): '\(plan.name)' - Active: \(plan.active) - ID: \(plan.id ?? "nil")")
            }
            self.allPlans = plans
            print("   ✅ Updated allPlans array with \(plans.count) plans")
        } catch {
            print("   ❌ Failed to load all plans: \(error.localizedDescription)")
            self.error = error
            self.showError = true
        }
    }

    // PERFORMANCE: Accept optional pre-fetched sessions to avoid redundant network calls
    private func loadActiveSession(from sessions: [FastingSession]? = nil) async {
        do {
            let allSessions: [FastingSession]
            if let providedSessions = sessions {
                allSessions = providedSessions
            } else {
                allSessions = try await firebaseManager.getFastingSessions()
            }
            self.activeSession = allSessions.prefix(1).first(where: { $0.isActive })
        } catch {
            self.error = error
            self.showError = true
        }
    }

    // PERFORMANCE: Accept optional pre-fetched sessions to avoid redundant network calls
    private func loadRecentSessions(from sessions: [FastingSession]? = nil) async {
        do {
            let allSessions: [FastingSession]
            if let providedSessions = sessions {
                allSessions = providedSessions
            } else {
                allSessions = try await firebaseManager.getFastingSessions()
            }
            self.recentSessions = Array(allSessions.prefix(10))
        } catch {
            self.error = error
            self.showError = true
        }
    }

    // PERFORMANCE: Accept optional pre-fetched sessions to avoid redundant network calls
    private func loadAnalytics(from sessions: [FastingSession]? = nil) async {
        do {
            let allSessions: [FastingSession]
            if let providedSessions = sessions {
                allSessions = providedSessions
            } else {
                allSessions = try await firebaseManager.getFastingSessions()
            }
            self.analytics = FastingManager.calculateAnalytics(from: Array(allSessions.prefix(100)))
        } catch {
            self.error = error
            self.showError = true
        }
    }

    // MARK: - Session Management

    func deleteSession(_ session: FastingSession) async {
        guard let sessionId = session.id else { return }

        do {
            try await firebaseManager.deleteFastingSession(id: sessionId)
            // Remove from local array
            self.recentSessions.removeAll { $0.id == sessionId }
        } catch {
            self.error = error
            self.showError = true
        }
    }

    /// Clear a session by setting its duration to 0 (endTime = startTime)
    /// This keeps the record but shows 0 hours fasted for that day
    func clearSession(_ session: FastingSession) async {
        guard let sessionId = session.id else { return }

        // Create updated session with endTime = startTime (0 duration)
        var clearedSession = session
        clearedSession.endTime = session.startTime
        clearedSession.completionStatus = .failed // Mark as not completed
        clearedSession.manuallyEdited = true

        do {
            _ = try await firebaseManager.saveFastingSession(clearedSession)
            // Update local array
            if let index = self.recentSessions.firstIndex(where: { $0.id == sessionId }) {
                self.recentSessions[index] = clearedSession
            }
            // Notify about history update
            NotificationCenter.default.post(name: .fastHistoryUpdated, object: nil)
        } catch {
            self.error = error
            self.showError = true
        }
    }

    /// Clear all sessions for a specific day
    func clearAllSessionsForDay(_ sessions: [FastingSession]) async {
        for session in sessions {
            await clearSession(session)
        }
    }

    /// Delete all sessions for a specific day permanently
    func deleteAllSessionsForDay(_ sessions: [FastingSession]) async {
        for session in sessions {
            await deleteSession(session)
        }
    }

    // MARK: - Timer

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.objectWillChange.send()
                self?.checkRegimeStateTransition()
            }
        }
    }

    /// Check for regime state transitions and record completed fasts
    private func checkRegimeStateTransition() {
        guard isRegimeActive else {
            previousRegimeState = nil
            return
        }

        // Clean up expired overrides
        clearExpiredOverrides()

        let currentState = currentRegimeState

        // Check if we transitioned from fasting to eating
        if case .fasting(let windowStart, let windowEnd) = previousRegimeState,
           case .eating = currentState {
            // Transition detected - record the completed fast
            recordCompletedRegimeFast(windowStart: windowStart, windowEnd: windowEnd)
        }

        previousRegimeState = currentState
    }

    /// Record a completed fasting session from regime mode
    private func recordCompletedRegimeFast(windowStart: Date, windowEnd: Date) {
        // Prevent duplicate recordings for the same window
        if let lastRecorded = lastRecordedFastWindowEnd,
           abs(lastRecorded.timeIntervalSince(windowEnd)) < 60 {
            return
        }

        guard let plan = activePlan else { return }

        let session = FastingSession(
            userId: userId,
            planId: plan.id,
            startTime: windowStart,
            endTime: windowEnd,
            manuallyEdited: false,
            skipped: false,
            completionStatus: .completed,
            targetDurationHours: plan.durationHours,
            notes: "Auto-recorded from regime",
            createdAt: Date()
        )

        lastRecordedFastWindowEnd = windowEnd

        Task {
            do {
                let savedId = try await firebaseManager.saveFastingSession(session)
                print("✅ Auto-recorded regime fast: \(savedId)")

                // Refresh sessions and analytics
                await loadRecentSessions()
                await loadAnalytics()
            } catch {
                print("❌ Failed to auto-record regime fast: \(error)")
            }
        }
    }

    // MARK: - Plan Management

    func createFastingPlan(
        name: String,
        durationHours: Int,
        daysOfWeek: [String],
        preferredStartTime: Date,
        allowedDrinks: AllowedDrinksPhilosophy,
        reminderEnabled: Bool,
        reminderMinutesBeforeEnd: Int
    ) async {
        print("📝 FastingViewModel.createFastingPlan called")
        print("   Name: '\(name)'")
        print("   Duration: \(durationHours) hours")
        print("   Days: \(daysOfWeek)")

        isLoading = true
        defer { isLoading = false }

        // Validate plan
        print("   🔍 Validating plan...")
        let validationResult = FastingManager.validatePlan(
            name: name,
            durationHours: durationHours,
            daysOfWeek: daysOfWeek
        )

        guard case .success = validationResult else {
            if case .failure(let error) = validationResult {
                print("   ❌ Validation failed: \(error.reason)")
                self.error = error
                self.showError = true
            }
            return
        }

        print("   ✅ Validation passed")

        // Deactivate current plan if exists
        if let currentPlan = activePlan {
            print("   📋 Deactivating current plan: \(currentPlan.name)")
            var deactivatedPlan = currentPlan
            deactivatedPlan.active = false
            do {
                try await firebaseManager.updateFastingPlan(deactivatedPlan)
                print("   ✅ Current plan deactivated")
            } catch {
                print("   ❌ Failed to deactivate current plan: \(error.localizedDescription)")
                self.error = error
                self.showError = true
                return
            }
        } else {
            print("   📋 No active plan to deactivate")
        }

        // Create new plan
        print("   📝 Creating new plan...")
        let newPlan = FastingPlan(
            userId: userId,
            name: name,
            durationHours: durationHours,
            daysOfWeek: daysOfWeek,
            preferredStartTime: preferredStartTime,
            allowedDrinks: allowedDrinks,
            reminderEnabled: reminderEnabled,
            reminderMinutesBeforeEnd: reminderMinutesBeforeEnd,
            active: true,
            regimeActive: false,
            regimeStartedAt: nil,
            createdAt: Date()
        )

        print("   💾 Saving plan to Firebase...")
        do {
            let docId = try await firebaseManager.saveFastingPlan(newPlan)
            print("   ✅ Plan saved to Firebase successfully with ID: \(docId)")

            // Update the plan with the returned document ID
            var savedPlan = newPlan
            savedPlan.id = docId

            // Update local state immediately instead of waiting for Firebase fetch
            // (Firestore has eventual consistency - the document might not be immediately available for reads)
            print("   🔄 Updating local state with saved plan...")
            self.activePlan = savedPlan
            self.allPlans.insert(savedPlan, at: 0) // Insert at beginning (most recent)
            print("   ✅ Local state updated - createFastingPlan complete")
        } catch {
            print("   ❌ Failed to save plan to Firebase: \(error.localizedDescription)")
            self.error = error
            self.showError = true
        }
    }

    func setActivePlan(_ plan: FastingPlan) async {
        isLoading = true
        defer { isLoading = false }

        // Deactivate current plan
        if let currentPlan = activePlan, currentPlan.id != plan.id {
            var deactivatedPlan = currentPlan
            deactivatedPlan.active = false
            do {
                try await firebaseManager.updateFastingPlan(deactivatedPlan)
            } catch {
                self.error = error
                self.showError = true
                return
            }
        }

        // Activate new plan
        var activatedPlan = plan
        activatedPlan.active = true

        do {
            try await firebaseManager.updateFastingPlan(activatedPlan)
            await loadActivePlan()
            await loadAllPlans()
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func updatePlan(_ plan: FastingPlan) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await firebaseManager.updateFastingPlan(plan)
            await loadActivePlan()
            await loadAllPlans()
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func deletePlan(_ plan: FastingPlan) async {
        isLoading = true
        defer { isLoading = false }

        guard let planId = plan.id else { return }

        do {
            try await firebaseManager.deleteFastingPlan(id: planId)
            await loadAllPlans()

            // Cancel notifications for this plan
            await FastingNotificationManager.shared.cancelPlanNotifications(planId: planId)

            // If deleted plan was active, clear it
            if plan.id == activePlan?.id {
                activePlan = nil
            }
        } catch {
            self.error = error
            self.showError = true
        }
    }

    // MARK: - Regime Management

    /// Activate the regime for the active plan
    /// - Parameter startFromNow: If true, starts the fast from the current time instead of scheduled time
    func startRegime(startFromNow: Bool = false) async {
        print("🔵 startRegime(startFromNow: \(startFromNow)) called")
        print("   Active plan exists: \(activePlan != nil)")
        print("   Active plan ID: \(activePlan?.id ?? "nil")")
        print("   Active plan name: \(activePlan?.name ?? "N/A")")

        guard let plan = activePlan, let planId = plan.id else {
            print("❌ startRegime() guard failed - plan or planId is nil")
            print("   activePlan: \(activePlan != nil ? "exists" : "nil")")
            print("   activePlan.id: \(activePlan?.id ?? "nil")")
            self.error = NSError(domain: "FastingViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "No active plan found"])
            self.showError = true
            print("   showError set to: \(self.showError)")
            return
        }

        print("✅ Starting regime for plan: '\(plan.name)' (ID: \(planId))")
        isLoading = true
        defer { isLoading = false }

        do {
            try await fastingService.startRegime(planId: planId)

            // Update local state immediately for instant UI feedback
            var updatedPlan = plan
            updatedPlan.regimeActive = true
            updatedPlan.regimeStartedAt = Date()
            self.activePlan = updatedPlan

            // Clear any previous ended window markers to start fresh
            lastEndedWindowEnd = nil
            print("🧹 Cleared lastEndedWindowEnd marker")

            // Clear any old snooze data from previous regime
            UserDefaults.standard.removeObject(forKey: "regimeSnoozedUntil_\(planId)")
            print("🧹 Cleared any old snooze data")

            // Store custom start time if starting from now
            if startFromNow {
                customStartTimeOverride = Date()
                print("📝 Custom start time override set to now: \(Date())")
            } else {
                customStartTimeOverride = nil
            }

            print("✅ Regime started successfully and local state updated for plan: \(plan.name)")
            print("   regimeActive is now: \(self.activePlan?.regimeActive ?? false)")

            // Request notification permissions and schedule notifications
            do {
                let center = UNUserNotificationCenter.current()
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                if granted {
                    // Schedule future plan notifications
                    try await FastingNotificationManager.shared.schedulePlanNotifications(for: updatedPlan)

                    // If starting from now, also schedule immediate fast notifications
                    if startFromNow {
                        try await FastingNotificationManager.shared.scheduleImmediateFastNotifications(
                            for: updatedPlan,
                            startingAt: Date()
                        )
                        print("📅 Scheduled immediate fast notifications for plan: \(plan.name)")
                    }

                    print("📅 Notifications scheduled for plan: \(plan.name)")
                } else {
                    print("⚠️ Notification permissions not granted")
                }
            } catch {
                print("⚠️ Failed to schedule notifications: \(error.localizedDescription)")
            }
        } catch {
            self.error = error
            self.showError = true
            print("❌ Failed to start regime: \(error.localizedDescription)")
        }
    }

    /// Deactivate the regime for the active plan
    func stopRegime() async {
        guard let plan = activePlan, let planId = plan.id else {
            self.error = NSError(domain: "FastingViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "No active plan found"])
            self.showError = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // End current session if active (manual mode)
            if let session = activeSession {
                let endedSession = FastingManager.endSession(session)
                try await firebaseManager.updateFastingSession(endedSession)
                self.activeSession = nil
            }

            // Record partial fast if currently in fasting window (regime mode)
            // Use self.currentRegimeState to check for already-ended windows, not activePlan?.currentRegimeState
            if case .fasting(let windowStart, let windowEnd) = self.currentRegimeState {
                let session = FastingSession(
                    userId: userId,
                    planId: plan.id,
                    startTime: windowStart,
                    endTime: Date(),
                    manuallyEdited: false,
                    skipped: false,
                    completionStatus: .earlyEnd,
                    targetDurationHours: plan.durationHours,
                    notes: "Regime stopped early",
                    createdAt: Date()
                )

                let savedId = try await firebaseManager.saveFastingSession(session)
                print("✅ Recorded partial regime fast: \(savedId)")

                // Mark this window as already ended so it won't be reused if regime is restarted
                lastEndedWindowEnd = windowEnd
                print("📝 Marked window ending at \(windowEnd) as already used")
            } else {
                print("ℹ️ Not in fasting window - no session to record")
            }

            // Clear regime tracking state
            previousRegimeState = nil
            lastRecordedFastWindowEnd = nil
            customStartTimeOverride = nil

            // Clear any snooze data
            UserDefaults.standard.removeObject(forKey: "regimeSnoozedUntil_\(planId)")
            print("🧹 Cleared snooze data for stopped regime")

            // Stop the regime
            try await fastingService.stopRegime(planId: planId)

            // Update local state immediately for instant UI feedback
            var updatedPlan = plan
            updatedPlan.regimeActive = false
            updatedPlan.regimeStartedAt = nil
            self.activePlan = updatedPlan

            // Cancel notifications for this plan
            await FastingNotificationManager.shared.cancelPlanNotifications(planId: planId)
            print("🗑️ Notifications cancelled for plan: \(plan.name)")

            await loadRecentSessions()
            await loadAnalytics()
            print("✅ Regime stopped successfully and local state updated for plan: \(plan.name)")
            print("   regimeActive is now: \(self.activePlan?.regimeActive ?? false)")
        } catch {
            self.error = error
            self.showError = true
            print("❌ Failed to stop regime: \(error.localizedDescription)")
        }
    }

    /// Current regime state (inactive, fasting, or eating)
    var currentRegimeState: FastingPlan.RegimeState {
        guard let planState = activePlan?.currentRegimeState else {
            return .inactive
        }

        // Check if there's a snooze that just expired - auto-resume the fast
        if let plan = activePlan,
           let snoozeUntil = regimeSnoozedUntil,
           !isRegimeSnoozed { // Snooze time has passed
            let now = Date()

            // If the snooze just expired (within last 5 minutes), auto-resume fasting
            if now.timeIntervalSince(snoozeUntil) < 300 && now.timeIntervalSince(snoozeUntil) >= 0 {
                print("⏰ Snooze expired at \(snoozeUntil.formatted(date: .omitted, time: .shortened)) - auto-resuming fast")

                // Start a new custom fast from now
                customStartTimeOverride = now
                let customEnd = now.addingTimeInterval(Double(plan.durationHours) * 3600)

                // Clear the expired snooze marker
                if let planId = plan.id {
                    UserDefaults.standard.removeObject(forKey: "regimeSnoozedUntil_\(planId)")
                }
                lastEndedWindowEnd = nil

                return .fasting(windowStart: now, windowEnd: customEnd)
            }

            // Clear old expired snooze data (more than 5 minutes old)
            if now.timeIntervalSince(snoozeUntil) >= 300 {
                if let planId = plan.id {
                    UserDefaults.standard.removeObject(forKey: "regimeSnoozedUntil_\(planId)")
                    print("🧹 Cleared old expired snooze data")
                }
            }
        }

        // If there's a manually ended window marker, we're in eating mode until next scheduled fast
        if let endedWindow = lastEndedWindowEnd {
            let now = Date()

            // If the marker is recent (within last hour), we're definitely in eating window
            if now.timeIntervalSince(endedWindow) < 3600 {
                if let nextFast = activePlan?.nextScheduledFastingWindow() {
                    print("🍽️ In eating window due to recent manual end at \(endedWindow.formatted(date: .omitted, time: .shortened))")
                    return .eating(nextFastStart: nextFast)
                }
            }

            // Clear old markers (more than an hour old and we've moved to a new window)
            if case .fasting(let windowStart, _) = planState {
                // If the plan's current window started after the marker, clear it
                if windowStart > endedWindow {
                    print("🧹 Clearing old ended window marker - moved to new window")
                    lastEndedWindowEnd = nil
                }
            }
        }

        // Apply custom start time override if set (for manual starts)
        if let customStart = customStartTimeOverride,
           let plan = activePlan {
            let hours = customTargetHoursOverride ?? plan.durationHours
            let customEnd = customStart.addingTimeInterval(Double(hours) * 3600)

            // If we're still within the custom fasting window
            if Date() < customEnd {
                return .fasting(windowStart: customStart, windowEnd: customEnd)
            } else {
                // Custom window ended - find next fast
                customStartTimeOverride = nil
                customTargetHoursOverride = nil
                if let nextFast = plan.nextScheduledFastingWindow() {
                    return .eating(nextFastStart: nextFast)
                }
            }
        }

        return planState
    }

    /// Clear custom start time override when window changes
    func clearExpiredOverrides() {
        guard let customStart = customStartTimeOverride,
              let plan = activePlan else { return }

        let hours = customTargetHoursOverride ?? plan.durationHours
        let customEnd = customStart.addingTimeInterval(Double(hours) * 3600)
        if Date() >= customEnd {
            customStartTimeOverride = nil
            customTargetHoursOverride = nil
            print("🧹 Cleared expired custom start time override")
        }
    }

    /// Whether the regime is currently active
    var isRegimeActive: Bool {
        return activePlan?.regimeActive ?? false
    }

    /// Check if we're past a scheduled start time (today or yesterday's that extends into today)
    /// Returns (isPastStartTime, startTime) tuple
    func checkIfPastTodaysStartTime() -> (isPast: Bool, startTime: Date?) {
        guard let plan = activePlan else { return (false, nil) }

        let calendar = Calendar.current
        let now = Date()
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"

        let startComponents = calendar.dateComponents([.hour, .minute], from: plan.preferredStartTime)

        // First, check if we're in a fasting window that started yesterday
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now) {
            let yesterdayName = dayFormatter.string(from: yesterday)
            if plan.daysOfWeek.contains(yesterdayName) {
                if let yesterdaysStartTime = calendar.date(bySettingHour: startComponents.hour ?? 0,
                                                            minute: startComponents.minute ?? 0,
                                                            second: 0,
                                                            of: yesterday) {
                    let fastEndTime = yesterdaysStartTime.addingTimeInterval(Double(plan.durationHours) * 3600)
                    // If we're still in yesterday's fasting window
                    if now > yesterdaysStartTime && now < fastEndTime {
                        return (true, yesterdaysStartTime)
                    }
                }
            }
        }

        // Then check today's scheduled start time
        let todayName = dayFormatter.string(from: now)

        // Check if today is a scheduled fasting day
        guard plan.daysOfWeek.contains(todayName) else {
            return (false, nil)
        }

        // Get today's scheduled start time
        guard let todaysStartTime = calendar.date(bySettingHour: startComponents.hour ?? 0,
                                                   minute: startComponents.minute ?? 0,
                                                   second: 0,
                                                   of: now) else {
            return (false, nil)
        }

        // Calculate end of fasting window
        let fastEndTime = todaysStartTime.addingTimeInterval(Double(plan.durationHours) * 3600)

        // Check if we're past start time but before fast end time
        let isPast = now > todaysStartTime && now < fastEndTime

        return (isPast, todaysStartTime)
    }

    // MARK: - Custom Start Time Override
    private static let customStartTimeKey = "customFastingStartTimeOverride"
    private static let customTargetHoursKey = "customFastingTargetHoursOverride"

    /// Store a custom start time override for the current fasting window
    private var customStartTimeOverride: Date? {
        get {
            return UserDefaults.standard.object(forKey: Self.customStartTimeKey) as? Date
        }
        set {
            if let date = newValue {
                UserDefaults.standard.set(date, forKey: Self.customStartTimeKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.customStartTimeKey)
            }
        }
    }

    private var customTargetHoursOverride: Int? {
        get {
            return UserDefaults.standard.object(forKey: Self.customTargetHoursKey) as? Int
        }
        set {
            if let hours = newValue {
                UserDefaults.standard.set(hours, forKey: Self.customTargetHoursKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.customTargetHoursKey)
            }
        }
    }

    /// Time until next fasting window starts (for UI display)
    var timeUntilNextFast: String {
        // If snoozed, show time until snooze resume instead
        if isRegimeSnoozed, let snoozeUntil = regimeSnoozedUntil {
            let timeInterval = snoozeUntil.timeIntervalSinceNow
            guard timeInterval > 0 else { return "Resuming now" }

            let totalSeconds = Int(timeInterval)
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60

            if hours > 0 {
                return "\(hours)h \(minutes)m \(seconds)s"
            } else if minutes > 0 {
                return "\(minutes)m \(seconds)s"
            } else {
                return "\(seconds)s"
            }
        }

        // Otherwise, show time until next scheduled fast
        guard case .eating(let nextFastStart) = currentRegimeState else {
            return ""
        }

        let timeInterval = nextFastStart.timeIntervalSinceNow
        guard timeInterval > 0 else { return "Starting soon" }

        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 24 {
            let days = hours / 24
            return "\(days)d \(hours % 24)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    /// Time until current fasting window ends (for UI display)
    var timeUntilFastEnds: String {
        guard case .fasting(_, let windowEnd) = currentRegimeState else {
            return ""
        }

        let timeInterval = windowEnd.timeIntervalSinceNow
        guard timeInterval > 0 else { return "Ending now" }

        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }

    /// Hours into current fast for regime mode (used for phase tracking)
    var hoursIntoCurrentFast: Double {
        guard case .fasting(let started, _) = currentRegimeState else {
            return 0
        }
        return Date().timeIntervalSince(started) / 3600
    }

    // MARK: - Session Management

    func startFastingSession() async {
        print("🚀 startFastingSession() called")
        print("   📌 Current userId: '\(userId)'")
        guard let plan = activePlan else {
            print("   ❌ No active plan found")
            self.error = NSError(domain: "FastingViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "No active plan found"])
            self.showError = true
            return
        }

        print("   ✅ Active plan found: '\(plan.name)'")
        isLoading = true
        defer { isLoading = false }

        print("   📝 Creating session with userId: '\(userId)'")
        let session = FastingManager.createSession(
            userId: userId,
            plan: plan,
            targetDurationHours: plan.durationHours
        )

        print("   📋 Session created - userId: '\(session.userId)', planId: '\(session.planId ?? "nil")', target: \(session.targetDurationHours)h")

        print("   💾 Saving session to Firebase...")
        do {
            let docId = try await firebaseManager.saveFastingSession(session)
            print("   ✅ Session saved with ID: \(docId)")

            // Update local state immediately (same fix as for plan creation)
            var savedSession = session
            savedSession.id = docId
            self.activeSession = savedSession
            self.recentSessions.insert(savedSession, at: 0)

            print("   ✅ Local state updated - startFastingSession complete")
        } catch {
            print("   ❌ Failed to save session: \(error.localizedDescription)")
            self.error = error
            self.showError = true
        }
    }

    func endFastingSession() async -> FastingSession? {
        guard let session = activeSession else { return nil }

        isLoading = true
        defer { isLoading = false }

        // Use FastingManager to automatically determine completion status
        let endedSession = FastingManager.endSession(session)

        do {
            try await firebaseManager.updateFastingSession(endedSession)
            self.activeSession = nil
            await loadRecentSessions()
            await loadAnalytics()

            // Post notification to refresh history dropdown
            NotificationCenter.default.post(name: .fastHistoryUpdated, object: nil)

            return endedSession
        } catch {
            self.error = error
            self.showError = true
            return nil
        }
    }

    func skipCurrentSession() async {
        guard let session = activeSession else { return }

        isLoading = true
        defer { isLoading = false }

        let skippedSession = FastingManager.skipSession(session)

        do {
            try await firebaseManager.updateFastingSession(skippedSession)
            self.activeSession = nil
            await loadRecentSessions()
            await loadAnalytics()
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func skipSession(_ session: FastingSession) async {
        isLoading = true
        defer { isLoading = false }

        let skippedSession = FastingManager.skipSession(session)

        do {
            try await firebaseManager.updateFastingSession(skippedSession)
            await loadRecentSessions()
            await loadAnalytics()
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func snoozeSession(_ session: FastingSession, minutes: Int) async {
        isLoading = true
        defer { isLoading = false }

        let snoozedSession = FastingManager.snoozeSession(session, snoozeDurationMinutes: minutes)

        do {
            try await firebaseManager.updateFastingSession(snoozedSession)
            await loadRecentSessions()
            // Schedule a notification for when snooze ends
            if let snoozeUntil = snoozedSession.snoozedUntil {
                await scheduleSnoozeNotification(for: snoozedSession, at: snoozeUntil)
            }
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func startSessionNow(_ session: FastingSession) async {
        isLoading = true
        defer { isLoading = false }

        var newSession = session
        newSession.startTime = Date()

        do {
            try await firebaseManager.saveFastingSession(newSession)
            self.activeSession = newSession
            await loadRecentSessions()
            await loadAnalytics()
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func adjustSessionStartTime(_ session: FastingSession, newTime: Date) async {
        isLoading = true
        defer { isLoading = false }

        let adjustedSession = FastingManager.adjustSessionStartTime(session, newStartTime: newTime)

        do {
            try await firebaseManager.updateFastingSession(adjustedSession)
            self.activeSession = adjustedSession
            await loadRecentSessions()
            await loadAnalytics()
        } catch {
            self.error = error
            self.showError = true
        }
    }

    // MARK: - Regime-specific Skip and Snooze

    func skipCurrentRegimeFast() async {
        guard let plan = activePlan, plan.regimeActive else {
            print("❌ Skip failed: No active plan or regime not active")
            return
        }

        // Get current regime state to find the window end time
        guard case .fasting(let started, let ends) = currentRegimeState else {
            print("⚠️ Not currently in a fasting window - cannot skip")
            return
        }

        print("🔍 SKIP FAST DEBUG:")
        print("   Started: \(started.formatted(date: .abbreviated, time: .complete))")
        print("   Ends: \(ends.formatted(date: .abbreviated, time: .complete))")
        print("   Plan ID: \(plan.id ?? "nil")")
        print("   User ID: \(userId)")

        isLoading = true
        defer { isLoading = false }

        do {
            // Calculate how long the fast has been running
            let now = Date()
            let fastDuration = now.timeIntervalSince(started)
            let oneHourInSeconds: TimeInterval = 3600

            // Determine whether to skip or end early based on duration
            let shouldSkip = fastDuration < oneHourInSeconds

            print("   Fast duration: \(String(format: "%.1f", fastDuration / 3600)) hours")
            print("   Action: \(shouldSkip ? "Skip" : "End Early")")

            // Create a session for the current fasting window
            var session = FastingManager.createSession(
                userId: userId,
                plan: plan,
                targetDurationHours: plan.durationHours,
                startTime: started
            )

            print("   Created session - before action:")
            print("      userId: \(session.userId)")
            print("      planId: \(session.planId ?? "nil")")
            print("      startTime: \(session.startTime.formatted(date: .abbreviated, time: .complete))")
            print("      endTime: \(session.endTime?.formatted(date: .abbreviated, time: .complete) ?? "nil")")

            if shouldSkip {
                // Under 1 hour - mark as skipped
                session = FastingManager.skipSession(session)
                print("   Marking as skipped (under 1 hour)")
            } else {
                // 1 hour or more - mark as ended early
                session.endTime = now
                session.completionStatus = .earlyEnd
                session.manuallyEdited = false
                print("   Marking as ended early (1+ hours)")
            }

            print("   After action:")
            print("      endTime: \(session.endTime?.formatted(date: .abbreviated, time: .complete) ?? "nil")")
            print("      skipped: \(session.skipped)")
            print("      completionStatus: \(session.completionStatus)")
            print("      actualDurationHours: \(session.actualDurationHours)")

            // Save the session
            let savedId = try await firebaseManager.saveFastingSession(session)
            print("   ✅ Session SAVED to Firebase with ID: \(savedId)")

            // Mark this fasting window as ended AND prevent auto-record duplicate
            lastEndedWindowEnd = ends
            lastRecordedFastWindowEnd = ends  // Prevent recordCompletedRegimeFast() from creating duplicate

            print("✅ \(shouldSkip ? "Skipped" : "Ended early") current fast - regime continues")
            print("   Fast window: \(started.formatted(date: .omitted, time: .shortened)) - \(ends.formatted(date: .omitted, time: .shortened))")

            // Refresh sessions to show the fast
            print("   Refreshing sessions...")
            await loadRecentSessions()
            print("   📊 After refresh: recentSessions count = \(recentSessions.count)")
            print("   Recent sessions:")
            for (index, session) in recentSessions.enumerated() {
                print("      \(index + 1). ID: \(session.id ?? "nil"), status: \(session.completionStatus), skipped: \(session.skipped), duration: \(String(format: "%.1f", session.actualDurationHours))h")
            }

            await loadAnalytics()

            // Cancel and reschedule notifications to prevent orphaned notifications
            if let planId = plan.id {
                print("🔔 Cancelling old notifications for plan: \(planId)")
                await FastingNotificationManager.shared.cancelPlanNotifications(planId: planId)
                if plan.regimeActive {
                    do {
                        try await FastingNotificationManager.shared.schedulePlanNotifications(for: plan)
                        print("✅ Notifications rescheduled")
                    } catch {
                        print("⚠️ Failed to reschedule notifications: \(error)")
                    }
                }
            }

            // Trigger UI refresh
            objectWillChange.send()

            // The regime stays active and will start the next scheduled fast
        } catch {
            print("❌ SKIP/END FAST ERROR: \(error.localizedDescription)")
            self.error = error
            self.showError = true
        }
    }

    func snoozeCurrentRegimeFast(until snoozeUntil: Date) async {
        guard let plan = activePlan, plan.regimeActive else { return }

        // Get current regime state to find the window end time
        guard case .fasting(let started, let ends) = currentRegimeState else {
            print("⚠️ Not currently in a fasting window")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Create an ended session for the partial fast
            let partialSession = FastingSession(
                userId: userId,
                planId: plan.id,
                startTime: started,
                endTime: Date(),
                manuallyEdited: false,
                skipped: false,
                completionStatus: .earlyEnd,
                targetDurationHours: plan.durationHours,
                notes: "Snoozed until \(snoozeUntil.formatted(date: .omitted, time: .shortened))",
                createdAt: Date()
            )

            // Save the partial session
            try await firebaseManager.saveFastingSession(partialSession)

            // Mark this fasting window as ended
            lastEndedWindowEnd = ends

            // Store snooze time in UserDefaults
            UserDefaults.standard.set(snoozeUntil, forKey: "regimeSnoozedUntil_\(plan.id ?? "")")

            print("⏰ Snoozed regime fast until \(snoozeUntil.formatted(date: .abbreviated, time: .shortened))")
            print("   Fast window: \(started.formatted(date: .omitted, time: .shortened)) - \(ends.formatted(date: .omitted, time: .shortened))")

            // Request notification permission and schedule notification
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])

            if granted {
                // Create notification content
                let content = UNMutableNotificationContent()
                content.title = "Fasting Reminder"
                content.body = "Your snooze period is over. Resume your fast?"
                content.sound = .default
                content.categoryIdentifier = "FASTING_SNOOZE"

                // Calculate time interval until snooze ends
                let timeInterval = snoozeUntil.timeIntervalSinceNow
                guard timeInterval > 0 else {
                    print("⚠️ Snooze time is in the past, skipping notification")
                    return
                }

                // Create trigger
                let trigger = UNTimeIntervalNotificationTrigger(
                    timeInterval: timeInterval,
                    repeats: false
                )

                // Create request
                let request = UNNotificationRequest(
                    identifier: "regime_snooze_\(plan.id ?? "")",
                    content: content,
                    trigger: trigger
                )

                // Schedule notification
                try await center.add(request)
                print("✅ Snooze notification scheduled for \(snoozeUntil.formatted(date: .abbreviated, time: .shortened))")
            }

            // Refresh sessions to show the partial fast
            await loadRecentSessions()
            await loadAnalytics()

            // Cancel and reschedule notifications to prevent orphaned notifications
            if let planId = plan.id {
                print("🔔 Cancelling old notifications for plan: \(planId)")
                await FastingNotificationManager.shared.cancelPlanNotifications(planId: planId)
                if plan.regimeActive {
                    do {
                        try await FastingNotificationManager.shared.schedulePlanNotifications(for: plan)
                        print("✅ Notifications rescheduled after snooze")
                    } catch {
                        print("⚠️ Failed to reschedule notifications: \(error)")
                    }
                }
            }

            // Trigger UI refresh to show eating window
            objectWillChange.send()

            print("✅ Fast snoozed - transitioned to eating window")
        } catch {
            print("❌ Failed to snooze regime fast: \(error)")
            self.error = error
            self.showError = true
        }
    }

    private func scheduleSnoozeNotification(for session: FastingSession, at date: Date) async {
        // TODO: Implement notification scheduling
        // This would use UNUserNotificationCenter to schedule a local notification
    }

    func endFastingRegime() async {
        isLoading = true
        defer { isLoading = false }

        // End current session if active
        if let session = activeSession {
            let endedSession = FastingManager.endSession(session)
            do {
                try await firebaseManager.updateFastingSession(endedSession)
            } catch {
                self.error = error
                self.showError = true
                return
            }
        }

        // Deactivate the current plan
        if var plan = activePlan {
            plan.active = false
            do {
                _ = try await firebaseManager.saveFastingPlan(plan)
                self.activePlan = nil
                self.activeSession = nil
                await loadRecentSessions()
                await loadAnalytics()
            } catch {
                self.error = error
                self.showError = true
            }
        }
    }

    func editSessionTimes(startTime: Date, endTime: Date?) async {
        guard var session = activeSession else { return }

        isLoading = true
        defer { isLoading = false }

        session.startTime = startTime
        session.endTime = endTime
        session.manuallyEdited = true

        do {
            try await firebaseManager.updateFastingSession(session)
            await loadActiveSession()
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func editActiveFast(startTime: Date, targetHours: Int) async {
        if var session = activeSession {
            isLoading = true
            defer { isLoading = false }
            session.startTime = startTime
            session.targetDurationHours = targetHours
            session.manuallyEdited = true
            do {
                try await firebaseManager.updateFastingSession(session)
                await MainActor.run {
                    self.activeSession = session
                    self.customStartTimeOverride = startTime
                    self.customTargetHoursOverride = targetHours
                    self.objectWillChange.send()
                }
            } catch {
                self.error = error
                self.showError = true
            }
        } else {
            await MainActor.run {
                self.customStartTimeOverride = startTime
                self.customTargetHoursOverride = targetHours
                self.objectWillChange.send()
                NotificationCenter.default.post(name: .fastHistoryUpdated, object: nil)
            }
        }
    }

    // MARK: - Error Handling

    func clearError() {
        error = nil
        showError = false
    }

    // MARK: - Early End & Restart Logic

    func continuePreviousFast(_ session: FastingSession) async {
        guard var previousSession = activeSession ?? (recentSessions.first { $0.id == session.id }) else {
            print("❌ Cannot continue fast - session not found")
            return
        }

        print("🔄 Continuing previous fast from early end")
        isLoading = true
        defer { isLoading = false }

        // Reactivate the session
        previousSession.endTime = nil
        previousSession.mergedFromEarlyEnd = true
        previousSession.completionStatus = .active

        do {
            try await firebaseManager.updateFastingSession(previousSession)
            self.activeSession = previousSession
            print("✅ Session reactivated successfully")
        } catch {
            print("❌ Failed to reactivate session: \(error.localizedDescription)")
            self.error = error
            self.showError = true
        }
    }

    var isEarlyEnd: Bool {
        guard let session = activeSession else { return false }
        let completionPercentage = session.actualDurationHours / Double(session.targetDurationHours)
        return completionPercentage < 0.25
    }

    func checkForQuickRestart() -> FastingSession? {
        // Check if user ended a fast within the last 60 minutes
        guard let lastSession = recentSessions.first,
              lastSession.completionStatus == .earlyEnd,
              let endTime = lastSession.endTime else {
            return nil
        }

        let minutesSinceEnd = Date().timeIntervalSince(endTime) / 60
        return minutesSinceEnd <= 60 ? lastSession : nil
    }

    // MARK: - Preview

    static var preview: FastingViewModel {
        let vm = FastingViewModel(
            firebaseManager: FirebaseManager.shared,
            userId: "preview_user"
        )

        // Setup preview data
        vm.activePlan = FastingPlan(
            userId: "preview_user",
            name: "16:8 Intermittent Fast",
            durationHours: 16,
            daysOfWeek: ["Mon", "Tue", "Wed", "Thu", "Fri"],
            preferredStartTime: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date(),
            allowedDrinks: .practical,
            reminderEnabled: true,
            reminderMinutesBeforeEnd: 30,
            active: true,
            regimeActive: false,
            regimeStartedAt: nil,
            createdAt: Date()
        )

        vm.activeSession = FastingSession(
            userId: "preview_user",
            planId: "preview_plan",
            startTime: Date().addingTimeInterval(-3600 * 8), // 8 hours ago
            endTime: nil,
            manuallyEdited: false,
            skipped: false,
            completionStatus: .active,
            targetDurationHours: 16,
            notes: nil,
            createdAt: Date()
        )

        vm.analytics = FastingAnalytics(
            totalFastsCompleted: 42,
            averageCompletionPercentage: 87.5,
            averageDurationVsGoal: 15.8,
            longestFastHours: 24.0,
            mostConsistentDay: "Monday",
            phaseDistribution: [:],
            last7DaysSessions: [],
            last30DaysSessions: [],
            currentWeeklyStreak: 5,
            bestWeeklyStreak: 12
        )

        return vm
    }
}
