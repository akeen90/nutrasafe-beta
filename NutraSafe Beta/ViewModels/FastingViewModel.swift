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
import ActivityKit
import WidgetKit

@MainActor
class FastingViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var activePlan: FastingPlan?

    // MARK: - Live Activity
    private var currentLiveActivity: Any?
    @Published var allPlans: [FastingPlan] = []
    @Published var activeSession: FastingSession? {
        didSet {
            syncWidgetData()
        }
    }
    @Published var analytics: FastingAnalytics?

    @Published var showError = false
    @Published var error: Error?
    @Published var isLoading = false

    // MARK: - Confirmation Flow State (Clock-in/Clock-out)
    @Published var showingStartConfirmation = false
    @Published var showingEndConfirmation = false
    @Published var confirmationContext: FastingConfirmationContext?

    // MARK: - Stale Session Recovery
    @Published var staleSessionToResolve: FastingSession?
    @Published var showStaleSessionSheet: Bool = false

    // PERFORMANCE: Memoized week summaries - only recalculated when recentSessions changes
    @Published private(set) var weekSummaries: [WeekSummary] = []

    // PERFORMANCE: Cached snooze state to avoid UserDefaults reads in timer
    @Published private(set) var cachedSnoozeUntil: Date?

    // PERFORMANCE: Tracks if timer-dependent views are visible to avoid unnecessary updates
    var isTimerViewVisible: Bool = false

    // Backing storage for recentSessions with automatic weekSummaries update
    @Published var recentSessions: [FastingSession] = [] {
        didSet {
            updateWeekSummaries()
        }
    }

    // All sessions for timeline view (no limit)
    @Published var allSessions: [FastingSession] = []

    // PERFORMANCE: Calculate week summaries only when data changes, not on every access
    private func updateWeekSummaries() {
        let calendar = Calendar.current
        var weekMap: [Date: [FastingSession]] = [:]

        // Group sessions by their week start (Monday), using END date for reporting
        for session in recentSessions {
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
        weekSummaries = weekMap.compactMap { weekStart, sessions in
            // Safely unwrap the calendar date calculation
            guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
                return nil
            }
            return WeekSummary(weekStart: weekStart, weekEnd: weekEnd, sessions: sessions)
        }.sorted { $0.weekStart > $1.weekStart }
    }

    private func getWeekStart(for date: Date, calendar: Calendar) -> Date {
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        components.weekday = 2 // Monday (1 = Sunday, 2 = Monday in Gregorian calendar)
        // Safely unwrap with fallback to start of current day
        return calendar.date(from: components) ?? calendar.startOfDay(for: date)
    }

    // MARK: - Private Properties

    let firebaseManager: FirebaseManager // Exposed for early-end modal
    private var timer: Timer?
    let userId: String
    private let fastingService: FastingService?  // Optional - nil if user not authenticated

    // MARK: - Regime State Tracking
    private var previousRegimeState: FastingPlan.RegimeState?

    // Persisted storage for recorded fast windows (prevents duplicate recordings on app restart)
    private static let recordedWindowKey = "lastRecordedFastingWindowEnd"

    private var lastRecordedFastWindowEnd: Date? {
        get {
            return UserDefaults.standard.object(forKey: Self.recordedWindowKey) as? Date
        }
        set {
            if let date = newValue {
                UserDefaults.standard.set(date, forKey: Self.recordedWindowKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.recordedWindowKey)
            }
        }
    }

    // PERFORMANCE: Use cached snooze state instead of reading UserDefaults every second
    var isRegimeSnoozed: Bool {
        guard let snoozeUntil = cachedSnoozeUntil else { return false }
        return snoozeUntil > Date()
    }

    var regimeSnoozedUntil: Date? {
        return cachedSnoozeUntil
    }

    // PERFORMANCE: Refresh cached snooze state from UserDefaults (call sparingly)
    func refreshSnoozeCache() {
        guard let plan = activePlan, let planId = plan.id else {
            cachedSnoozeUntil = nil
            return
        }
        cachedSnoozeUntil = UserDefaults.standard.object(forKey: "regimeSnoozedUntil_\(planId)") as? Date
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

    // MARK: - Notification Observer
    private var historyObserver: NSObjectProtocol?

    // MARK: - Initialization

    init(firebaseManager: FirebaseManager, userId: String) {
        self.firebaseManager = firebaseManager
        self.userId = userId
        self.fastingService = FastingService()  // Optional - will be nil if user not authenticated

        // Listen for session updates - store observer token for proper cleanup
        historyObserver = NotificationCenter.default.addObserver(
            forName: .fastHistoryUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                // PERFORMANCE: Load all data in a single batch instead of sequential calls
                await self?.loadInitialData()
            }
        }

        Task { [weak self] in
            await self?.loadInitialData()
            self?.refreshSnoozeCache() // PERFORMANCE: Initialize snooze cache once at startup
            self?.startTimer()
        }
    }

    deinit {
        timer?.invalidate()
        // STABILITY: Use stored observer token for guaranteed cleanup
        if let observer = historyObserver {
            NotificationCenter.default.removeObserver(observer)
        }
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

            // Clean up orphaned notifications (from sessions deleted before the fix)
            await FastingNotificationManager.shared.cleanupOrphanedNotifications(activeSessions: sessions)
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func loadActivePlan() async {
        // If we already have an active plan set locally (e.g., just created one),
        // skip the Firestore fetch to avoid race condition with eventual consistency
        if self.activePlan != nil {
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
                        let plans = try await firebaseManager.getFastingPlans()
                        let activePlan = plans.first(where: { $0.active })
            if let active = activePlan {
                self.activePlan = active
            } else {
                                self.activePlan = nil
            }
        } catch {
                        self.error = error
            self.showError = true
        }
    }

    func loadAllPlans() async {
        do {
            let plans = try await firebaseManager.getFastingPlans()
            self.allPlans = plans
        } catch {
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

            if let activeCandidate = allSessions.first(where: { $0.isActive }) {
                // Check if this session is stale (orphaned)
                if activeCandidate.isLikelyStale {
                    // Show recovery UI instead of treating as active
                    await handleStaleSession(activeCandidate)
                    self.activeSession = nil
                } else {
                    self.activeSession = activeCandidate
                }
            } else {
                self.activeSession = nil
            }
        } catch {
            self.error = error
            self.showError = true
        }
    }

    // MARK: - Stale Session Handling

    /// Handle a stale session - prompt user for resolution
    private func handleStaleSession(_ session: FastingSession) async {
        await MainActor.run {
            self.staleSessionToResolve = session
            self.showStaleSessionSheet = true
        }
    }

    /// User confirms they completed the stale fast
    func resolveStaleSessionAsCompleted(_ session: FastingSession) async {
        guard session.id != nil else { return }

        var resolvedSession = session
        // Set end time to target duration after start
        resolvedSession.endTime = session.startTime.addingTimeInterval(Double(session.targetDurationHours) * 3600)
        resolvedSession.completionStatus = .completed
        resolvedSession.manuallyEdited = true
        resolvedSession.notes = (session.notes ?? "") + "\n[Resolved: Marked as completed]"

        do {
            try await firebaseManager.updateFastingSession(resolvedSession)
            self.staleSessionToResolve = nil
            self.showStaleSessionSheet = false
            await loadRecentSessions()
            NotificationCenter.default.post(name: .fastHistoryUpdated, object: nil)
        } catch {
            self.error = error
            self.showError = true
        }
    }

    /// User ended the stale fast early
    func resolveStaleSessionAsEarlyEnd(_ session: FastingSession) async {
        guard session.id != nil else { return }

        var resolvedSession = session
        // Set end time to target duration after start (reasonable estimate)
        resolvedSession.endTime = session.startTime.addingTimeInterval(Double(session.targetDurationHours) * 3600)
        resolvedSession.completionStatus = .earlyEnd
        resolvedSession.manuallyEdited = true
        resolvedSession.notes = (session.notes ?? "") + "\n[Resolved: Marked as ended early]"

        do {
            try await firebaseManager.updateFastingSession(resolvedSession)
            self.staleSessionToResolve = nil
            self.showStaleSessionSheet = false
            await loadRecentSessions()
            NotificationCenter.default.post(name: .fastHistoryUpdated, object: nil)
        } catch {
            self.error = error
            self.showError = true
        }
    }

    /// User wants to discard the stale session entirely
    func resolveStaleSessionAsDiscarded(_ session: FastingSession) async {
        guard let sessionId = session.id else { return }

        do {
            try await firebaseManager.deleteFastingSession(id: sessionId)
            self.staleSessionToResolve = nil
            self.showStaleSessionSheet = false
            await loadRecentSessions()
            NotificationCenter.default.post(name: .fastHistoryUpdated, object: nil)
        } catch {
            self.error = error
            self.showError = true
        }
    }

    // PERFORMANCE: Accept optional pre-fetched sessions to avoid redundant network calls
    private func loadRecentSessions(from sessions: [FastingSession]? = nil) async {
        do {
            let fetchedSessions: [FastingSession]
            if let providedSessions = sessions {
                fetchedSessions = providedSessions
            } else {
                fetchedSessions = try await firebaseManager.getFastingSessions()
            }
            // MEMORY: Limit stored sessions to prevent unbounded growth
            // 365 sessions = ~1 year of daily fasting, reasonable for timeline view
            self.allSessions = Array(fetchedSessions.prefix(365))
            self.recentSessions = Array(fetchedSessions.prefix(10))
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

            // Cancel any scheduled notifications for this session
            await FastingNotificationManager.shared.cancelSessionNotifications(session: session)

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

            // Cancel any scheduled notifications for this session
            await FastingNotificationManager.shared.cancelSessionNotifications(session: session)

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

    // PERFORMANCE: Track last update to throttle objectWillChange when timer view isn't visible
    private var lastTimerUpdate: Date = Date()

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                // PERFORMANCE: Always check for state transitions (lightweight)
                self.checkRegimeStateTransition()

                // PERFORMANCE: Only trigger view updates if timer-dependent views are visible
                // or if we have an active session/regime that needs real-time display
                let needsUpdate = self.isTimerViewVisible ||
                                  self.activeSession != nil ||
                                  self.isRegimeActive

                if needsUpdate {
                    self.objectWillChange.send()
                }
            }
        }
    }

    /// Call when timer view appears to enable frequent updates
    func timerViewDidAppear() {
        isTimerViewVisible = true
        refreshSnoozeCache() // Refresh cache when view appears
    }

    /// Call when timer view disappears to reduce update frequency
    func timerViewDidDisappear() {
        isTimerViewVisible = false
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
        // Prevent duplicate recordings for the same window (persisted check)
        if let lastRecorded = lastRecordedFastWindowEnd,
           abs(lastRecorded.timeIntervalSince(windowEnd)) < 60 {
            return
        }

        guard let plan = activePlan else { return }

        let calendar = Calendar.current

        // Check if a session with similar start/end time already exists in allSessions
        // This prevents duplicates when app restarts or view reloads
        let hasDuplicate = allSessions.contains { existingSession in
            // Check if start times are within 5 minutes of each other
            let startDiff = abs(existingSession.startTime.timeIntervalSince(windowStart))
            let endDiff: TimeInterval
            if let existingEnd = existingSession.endTime {
                endDiff = abs(existingEnd.timeIntervalSince(windowEnd))
            } else {
                endDiff = .infinity
            }
            // Consider duplicate if both start and end are within 5 minutes
            return startDiff < 300 && endDiff < 300
        }

        if hasDuplicate {
            lastRecordedFastWindowEnd = windowEnd
            return
        }

        // Additional check: Prevent multiple completed fasts ending on the same day
        // A 16-hour fast can only complete once per day
        let hasCompletedFastToday = allSessions.contains { existingSession in
            guard existingSession.completionStatus == .completed,
                  let existingEnd = existingSession.endTime else { return false }
            // Check if there's already a completed fast ending on the same day
            return calendar.isDate(existingEnd, inSameDayAs: windowEnd)
        }

        if hasCompletedFastToday {
            lastRecordedFastWindowEnd = windowEnd
            return
        }

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

        Task { [weak self] in
            do {
                _ = try await self?.firebaseManager.saveFastingSession(session)

                // Refresh sessions and analytics
                await self?.loadRecentSessions()
                await self?.loadAnalytics()
            } catch {
                // Retry once on auto-record failure
                do {
                    try await Task.sleep(nanoseconds: 500_000_000)
                    _ = try await self?.firebaseManager.saveFastingSession(session)
                    await self?.loadRecentSessions()
                    await self?.loadAnalytics()
                } catch {
                    // Show error so user knows auto-record failed
                    await MainActor.run {
                        self?.error = error
                        self?.showError = true
                    }
                }
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
                                
        isLoading = true
        defer { isLoading = false }

        // Validate plan
                let validationResult = FastingManager.validatePlan(
            name: name,
            durationHours: durationHours,
            daysOfWeek: daysOfWeek
        )

        guard case .success = validationResult else {
            if case .failure(let error) = validationResult {
                                self.error = error
                self.showError = true
            }
            return
        }

        
        // Deactivate current plan if exists
        if let currentPlan = activePlan {
                        var deactivatedPlan = currentPlan
            deactivatedPlan.active = false
            do {
                try await firebaseManager.updateFastingPlan(deactivatedPlan)
                            } catch {
                                self.error = error
                self.showError = true
                return
            }
        } else {
                    }

        // Create new plan
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

                do {
            let docId = try await firebaseManager.saveFastingPlan(newPlan)
            
            // Update the plan with the returned document ID
            var savedPlan = newPlan
            savedPlan.id = docId

            // Update local state immediately instead of waiting for Firebase fetch
            // (Firestore has eventual consistency - the document might not be immediately available for reads)
                        self.activePlan = savedPlan
            self.allPlans.insert(savedPlan, at: 0) // Insert at beginning (most recent)
                    } catch {
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
                
        guard let plan = activePlan, let planId = plan.id else {
                        self.error = NSError(domain: "FastingViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "No active plan found"])
            self.showError = true
                        return
        }

                isLoading = true
        defer { isLoading = false }

        guard let fastingService = fastingService else {
            self.error = NSError(domain: "FastingViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Fasting service unavailable - please sign in"])
            self.showError = true
            return
        }

        do {
            try await fastingService.startRegime(planId: planId)

            // Update local state immediately for instant UI feedback
            var updatedPlan = plan
            updatedPlan.regimeActive = true
            updatedPlan.regimeStartedAt = Date()
            self.activePlan = updatedPlan

            // Clear any previous ended window markers to start fresh
            lastEndedWindowEnd = nil
            
            // Clear any old snooze data from previous regime
            UserDefaults.standard.removeObject(forKey: "regimeSnoozedUntil_\(planId)")
            cachedSnoozeUntil = nil
            
            // Store custom start time if starting from now
            if startFromNow {
                customStartTimeOverride = Date()
                            } else {
                customStartTimeOverride = nil
            }

                        
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
                    }
                } else {
                }
            } catch {
            }

            // Start Live Activity for Dynamic Island
            if #available(iOS 16.1, *) {
                await startLiveActivity()
            }
        } catch {
            self.error = error
            self.showError = true
        }
    }

    /// Deactivate the regime for the active plan
    func stopRegime() async {
        guard let plan = activePlan, let planId = plan.id else {
            self.error = NSError(domain: "FastingViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "No active plan found"])
            self.showError = true
            return
        }

        guard let fastingService = fastingService else {
            self.error = NSError(domain: "FastingViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Fasting service unavailable - please sign in"])
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

                _ = try await firebaseManager.saveFastingSession(session)

                // Mark this window as already ended so it won't be reused if regime is restarted
                lastEndedWindowEnd = windowEnd
            }

            // Clear regime tracking state
            previousRegimeState = nil
            lastRecordedFastWindowEnd = nil
            customStartTimeOverride = nil

            // Clear any snooze data
            UserDefaults.standard.removeObject(forKey: "regimeSnoozedUntil_\(planId)")
            cachedSnoozeUntil = nil
            
            // Stop the regime
            try await fastingService.stopRegime(planId: planId)

            // Update local state immediately for instant UI feedback
            var updatedPlan = plan
            updatedPlan.regimeActive = false
            updatedPlan.regimeStartedAt = nil
            self.activePlan = updatedPlan

            // Cancel notifications for this plan
            await FastingNotificationManager.shared.cancelPlanNotifications(planId: planId)

            // End Live Activity
            if #available(iOS 16.1, *) {
                await endLiveActivity()
            }

            await loadRecentSessions()
            await loadAnalytics()
        } catch {
            self.error = error
            self.showError = true
        }
    }

    /// Current regime state (inactive, fasting, or eating)
    var currentRegimeState: FastingPlan.RegimeState {
        guard let planState = activePlan?.currentRegimeState else {
            return .inactive
        }

        // If regime is not active, return inactive immediately
        // (prevents lastEndedWindowEnd from incorrectly showing .eating state)
        if case .inactive = planState {
            return .inactive
        }

        // Check if there's a snooze that just expired - auto-resume the fast
        if let plan = activePlan,
           let snoozeUntil = regimeSnoozedUntil,
           !isRegimeSnoozed { // Snooze time has passed
            let now = Date()

            // If the snooze just expired (within last 5 minutes), auto-resume fasting
            if now.timeIntervalSince(snoozeUntil) < 300 && now.timeIntervalSince(snoozeUntil) >= 0 {
                
                // Start a new custom fast from now
                customStartTimeOverride = now
                let customEnd = now.addingTimeInterval(Double(plan.durationHours) * 3600)

                // Clear the expired snooze marker
                if let planId = plan.id {
                    UserDefaults.standard.removeObject(forKey: "regimeSnoozedUntil_\(planId)")
                    cachedSnoozeUntil = nil
                }
                lastEndedWindowEnd = nil

                return .fasting(windowStart: now, windowEnd: customEnd)
            }

            // Clear old expired snooze data (more than 5 minutes old)
            if now.timeIntervalSince(snoozeUntil) >= 300 {
                if let planId = plan.id {
                    UserDefaults.standard.removeObject(forKey: "regimeSnoozedUntil_\(planId)")
                    cachedSnoozeUntil = nil
                                    }
            }
        }

        // If there's a manually ended window marker, we're in eating mode until next scheduled fast
        if let endedWindow = lastEndedWindowEnd {
            let now = Date()

            // If the marker is recent (within last hour), we're definitely in eating window
            if now.timeIntervalSince(endedWindow) < 3600 {
                if let nextFast = activePlan?.nextScheduledFastingWindow() {
                    // Note: Debug logging removed - this computed property is called frequently
                    return .eating(nextFastStart: nextFast)
                }
            }

            // Clear old markers (more than an hour old and we've moved to a new window)
            if case .fasting(let windowStart, _) = planState {
                // If the plan's current window started after the marker, clear it
                if windowStart > endedWindow {
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
        // PERFORMANCE: Use cached static formatter instead of creating new one
        let dayFormatter = DateHelper.dayOfWeekFormatter

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

    /// Current fasting phase based on hours into fast (for regime mode)
    var currentRegimeFastingPhase: FastingPhase? {
        guard case .fasting = currentRegimeState else { return nil }
        let hours = hoursIntoCurrentFast

        // Determine phase based on hours fasted
        if hours >= 20 { return .deepAdaptive }
        if hours >= 16 { return .autophagyPotential }
        if hours >= 12 { return .mildKetosis }
        if hours >= 8 { return .fatMobilization }
        if hours >= 4 { return .fuelSwitching }
        return .postMeal
    }

    // MARK: - Session Management

    func startFastingSession() async {
        guard let plan = activePlan else {
            self.error = NSError(domain: "FastingViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "No active plan found"])
            self.showError = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        let session = FastingManager.createSession(
            userId: userId,
            plan: plan,
            targetDurationHours: plan.durationHours
        )

        do {
            let docId = try await firebaseManager.saveFastingSession(session)

            // Update local state immediately (same fix as for plan creation)
            var savedSession = session
            savedSession.id = docId
            self.activeSession = savedSession
            self.recentSessions.insert(savedSession, at: 0)

            // If regime is active, also set custom start time override so the regime UI shows fasting state
            // This ensures the regime timer switches from "eating" to "fasting" immediately
            if plan.regimeActive {
                customStartTimeOverride = Date()
                customTargetHoursOverride = plan.durationHours
                // Clear the "ended window" marker so the eating check doesn't override the custom start
                lastEndedWindowEnd = nil
            }
        } catch {
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

        // If we're in a regime fasting window, mark it as ended to prevent
        // duplicate auto-recording when the scheduled window ends naturally
        if case .fasting(_, let windowEnd) = currentRegimeState {
            lastEndedWindowEnd = windowEnd
            lastRecordedFastWindowEnd = windowEnd
                    }

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

        // If we're in a regime fasting window, mark it as ended to prevent
        // duplicate auto-recording when the scheduled window ends naturally
        if case .fasting(_, let windowEnd) = currentRegimeState {
            lastEndedWindowEnd = windowEnd
            lastRecordedFastWindowEnd = windowEnd
                    }

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
            _ = try await firebaseManager.saveFastingSession(newSession)
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
                        return
        }

        // Get current regime state to find the window end time
        guard case .fasting(let started, let ends) = currentRegimeState else {
                        return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Calculate how long the fast has been running
            let now = Date()
            let fastDuration = now.timeIntervalSince(started)
            let oneHourInSeconds: TimeInterval = 3600

            // Determine whether to skip or end early based on duration
            // Only mark as "ended early" if over 1 hour (not equal to)
            let shouldSkip = fastDuration <= oneHourInSeconds


            // Create a session for the current fasting window
            var session = FastingManager.createSession(
                userId: userId,
                plan: plan,
                targetDurationHours: plan.durationHours,
                startTime: started
            )

                                    
            if shouldSkip {
                // Under 1 hour - mark as skipped
                session = FastingManager.skipSession(session)
                            } else {
                // 1 hour or more - mark as ended early
                session.endTime = now
                session.completionStatus = .earlyEnd
                session.manuallyEdited = false
                            }

                                                
            // Save the session
            _ = try await firebaseManager.saveFastingSession(session)

            // Mark this fasting window as ended AND prevent auto-record duplicate
            lastEndedWindowEnd = ends
            lastRecordedFastWindowEnd = ends  // Prevent recordCompletedRegimeFast() from creating duplicate

            
            // Refresh sessions to show the fast
            await loadRecentSessions()
            await loadAnalytics()

            // Cancel and reschedule notifications to prevent orphaned notifications
            if let planId = plan.id {
                                await FastingNotificationManager.shared.cancelPlanNotifications(planId: planId)
                if plan.regimeActive {
                    do {
                        try await FastingNotificationManager.shared.schedulePlanNotifications(for: plan)
                                            } catch {
                                            }
                }
            }

            // Trigger UI refresh
            objectWillChange.send()

            // The regime stays active and will start the next scheduled fast
        } catch {
                        self.error = error
            self.showError = true
        }
    }

    func snoozeCurrentRegimeFast(until snoozeUntil: Date) async {
        guard let plan = activePlan, plan.regimeActive else { return }

        // Get current regime state to find the window end time
        guard case .fasting(let started, let ends) = currentRegimeState else {
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
            _ = try await firebaseManager.saveFastingSession(partialSession)

            // Mark this fasting window as ended
            lastEndedWindowEnd = ends

            // Store snooze time in UserDefaults and update cache
            UserDefaults.standard.set(snoozeUntil, forKey: "regimeSnoozedUntil_\(plan.id ?? "")")
            cachedSnoozeUntil = snoozeUntil

                        
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
                            }

            // Refresh sessions to show the partial fast
            await loadRecentSessions()
            await loadAnalytics()

            // Cancel and reschedule notifications to prevent orphaned notifications
            if let planId = plan.id {
                                await FastingNotificationManager.shared.cancelPlanNotifications(planId: planId)
                if plan.regimeActive {
                    do {
                        try await FastingNotificationManager.shared.schedulePlanNotifications(for: plan)
                                            } catch {
                                            }
                }
            }

            // Trigger UI refresh to show eating window
            objectWillChange.send()

                    } catch {
                        self.error = error
            self.showError = true
        }
    }

    private func scheduleSnoozeNotification(for session: FastingSession, at date: Date) async {
        // Notification scheduling not yet implemented
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
                        return
        }

                isLoading = true
        defer { isLoading = false }

        // Reactivate the session
        previousSession.endTime = nil
        previousSession.mergedFromEarlyEnd = true
        previousSession.completionStatus = .active

        do {
            try await firebaseManager.updateFastingSession(previousSession)
            self.activeSession = previousSession
                    } catch {
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

    // MARK: - Confirmation Flow (Clock-in/Clock-out)

    /// Handle incoming notification confirmation request
    func handleConfirmationNotification(userInfo: [AnyHashable: Any]) {
        let fastingType = userInfo["fastingType"] as? String ?? ""
        let planId = userInfo["planId"] as? String ?? ""
        let planName = userInfo["planName"] as? String ?? ""

        // Helper to extract numeric values (notification userInfo stores as NSNumber)
        func getNumber(_ key: String) -> Double? {
            if let val = userInfo[key] as? Double { return val }
            if let val = userInfo[key] as? Int { return Double(val) }
            if let nsNum = userInfo[key] as? NSNumber { return nsNum.doubleValue }
            return nil
        }

        let durationHours = Int(getNumber("durationHours") ?? 16)
        let scheduledTime: Date

        if fastingType == "end" {
            if let scheduledEndTime = getNumber("scheduledEndTime") {
                scheduledTime = Date(timeIntervalSince1970: scheduledEndTime)
            } else {
                scheduledTime = Date()
            }
        } else {
            if let scheduledStartTime = getNumber("scheduledStartTime") {
                scheduledTime = Date(timeIntervalSince1970: scheduledStartTime)
            } else {
                scheduledTime = Date()
            }
        }

        let context = FastingConfirmationContext(
            fastingType: fastingType,
            planId: planId,
            planName: planName,
            durationHours: durationHours,
            scheduledTime: scheduledTime
        )

        confirmationContext = context

        // For "end" notifications, we need to ensure the active session is loaded first
        // This handles the race condition when app launches from notification tap
        if fastingType == "end" {
            Task { [weak self] in
                await self?.ensureSessionLoadedThenShowEndConfirmation()
            }
        } else if fastingType == "start" {
            showingStartConfirmation = true
        }
    }

    /// Ensure active session is loaded before showing end confirmation sheet
    /// This prevents the blank sheet issue when tapping "Fast Complete" notification
    private func ensureSessionLoadedThenShowEndConfirmation() async {
        // If we already have an active session, show immediately
        if activeSession != nil {
            await MainActor.run {
                showingEndConfirmation = true
            }
            return
        }

        // Otherwise, try to load the active session from Firebase
        do {
            let sessions = try await firebaseManager.getFastingSessions()
            let active = sessions.first(where: { $0.isActive })

            await MainActor.run {
                if let session = active {
                    self.activeSession = session
                    self.showingEndConfirmation = true
                } else {
                    // No active session found - the fast may have already been ended
                    // Show a toast or silently dismiss
                    self.confirmationContext = nil
                }
            }
        } catch {
            await MainActor.run {
                self.confirmationContext = nil
            }
        }
    }

    /// Confirm start at scheduled time (clock-in)
    func confirmStartAtScheduledTime() async {
        guard let context = confirmationContext,
              let plan = activePlan else {
                        return
        }

        isLoading = true
        defer { isLoading = false }

        // Create a new session starting at the scheduled time
        var session = FastingManager.createSession(
            userId: userId,
            plan: plan,
            targetDurationHours: context.durationHours,
            startTime: context.scheduledTime
        )

        do {
            let savedId = try await firebaseManager.saveFastingSession(session)
            session.id = savedId
            self.activeSession = session
            await loadRecentSessions()

            // Schedule notifications for this immediate fast
            if let plan = activePlan {
                try await FastingNotificationManager.shared.scheduleImmediateFastNotifications(
                    for: plan,
                    startingAt: context.scheduledTime
                )

                // If regime is active, set custom start time override so the regime UI shows the correct fasting state
                if plan.regimeActive {
                    customStartTimeOverride = context.scheduledTime
                    customTargetHoursOverride = context.durationHours
                    lastEndedWindowEnd = nil
                }
            }

                    } catch {
            self.error = error
            self.showError = true
        }

        confirmationContext = nil
    }

    /// Confirm start at custom time (clock-in with adjustment)
    func confirmStartAtCustomTime(_ customTime: Date) async {
        guard let context = confirmationContext,
              let plan = activePlan else {
                        return
        }

        isLoading = true
        defer { isLoading = false }

        var session = FastingManager.createSession(
            userId: userId,
            plan: plan,
            targetDurationHours: context.durationHours,
            startTime: customTime
        )
        session.manuallyEdited = true
        session.originalScheduledStart = context.scheduledTime

        do {
            let savedId = try await firebaseManager.saveFastingSession(session)
            session.id = savedId
            self.activeSession = session
            await loadRecentSessions()

            // Schedule notifications from custom start time
            if let plan = activePlan {
                try await FastingNotificationManager.shared.scheduleImmediateFastNotifications(
                    for: plan,
                    startingAt: customTime
                )

                // If regime is active, set custom start time override so the regime UI shows the correct fasting state
                if plan.regimeActive {
                    customStartTimeOverride = customTime
                    customTargetHoursOverride = context.durationHours
                    lastEndedWindowEnd = nil
                }
            }

                    } catch {
            self.error = error
            self.showError = true
        }

        confirmationContext = nil
    }

    /// User wants to skip this fast entirely
    /// Also cancels any auto-started session that may have been created
    func skipCurrentFast() async {
        guard let plan = activePlan else {
            confirmationContext = nil
            return
        }

        // If there's an active session (auto-started), delete it as if it never happened
        if let session = activeSession, let sessionId = session.id {
            do {
                try await firebaseManager.deleteFastingSession(id: sessionId)
                self.activeSession = nil
                await loadRecentSessions()
            } catch {
                // Non-critical - session deletion failed but continue with skip
            }
        }

        // If we're in regime mode, mark this fasting window as skipped
        if plan.regimeActive {
            // Mark current window end so auto-record doesn't create a session
            if case .fasting(_, let ends) = currentRegimeState {
                lastEndedWindowEnd = ends
            }

            // Clear any existing snooze
            UserDefaults.standard.removeObject(forKey: "regimeSnoozedUntil_\(plan.id ?? "")")
            cachedSnoozeUntil = nil

            // Store skip marker until next fasting window
            UserDefaults.standard.set(Date(), forKey: "regimeSkippedAt_\(plan.id ?? "")")
        }

        // Trigger UI refresh
        objectWillChange.send()

        confirmationContext = nil
    }

    /// User wants to be reminded at a specific time
    func snoozeUntil(_ snoozeTime: Date) async {
        guard let plan = activePlan else {
            confirmationContext = nil
            return
        }

        // If there's an active session (auto-started), delete it as if it never happened
        if let session = activeSession, let sessionId = session.id {
            do {
                try await firebaseManager.deleteFastingSession(id: sessionId)
                self.activeSession = nil
                await loadRecentSessions()
            } catch {
                // Non-critical - session deletion failed but continue with snooze
            }
        }

        // If we're in regime mode, mark this fasting window as snoozed
        if plan.regimeActive {
            // Store snooze time in UserDefaults and update cache
            UserDefaults.standard.set(snoozeTime, forKey: "regimeSnoozedUntil_\(plan.id ?? "")")
            cachedSnoozeUntil = snoozeTime

            // Mark current window end so auto-record doesn't create a session
            if case .fasting(_, let ends) = currentRegimeState {
                lastEndedWindowEnd = ends
            }
        }

        // Schedule a snooze reminder notification
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])

            if granted {
                let content = UNMutableNotificationContent()
                content.title = "Time to start your fast"
                content.body = "You snoozed earlier - ready to start fasting now?"
                content.sound = .default
                content.categoryIdentifier = "FAST_START"
                content.userInfo = [
                    "type": "fasting",
                    "fastingType": "start",
                    "planId": plan.id ?? "",
                    "planName": plan.name,
                    "durationHours": plan.durationHours
                ]

                let timeInterval = snoozeTime.timeIntervalSinceNow
                if timeInterval > 0 {
                    let trigger = UNTimeIntervalNotificationTrigger(
                        timeInterval: timeInterval,
                        repeats: false
                    )

                    let request = UNNotificationRequest(
                        identifier: "fast_start_snooze_\(plan.id ?? "")_\(Date().timeIntervalSince1970)",
                        content: content,
                        trigger: trigger
                    )

                    try await center.add(request)
                }
            }
        } catch {
            // Non-critical - notification scheduling failed but continue
        }

        // Trigger UI refresh
        objectWillChange.send()

        confirmationContext = nil
    }

    /// Confirm end now (clock-out)
    func confirmEndNow() async {
        guard activeSession != nil else {
                        return
        }

        _ = await endFastingSession()
        confirmationContext = nil
    }

    /// Confirm end at custom time (clock-out with adjustment)
    func confirmEndAtCustomTime(_ customTime: Date) async {
        guard let session = activeSession else {
                        return
        }

        isLoading = true
        defer { isLoading = false }

        // Use FastingManager.endSession to properly calculate completion status
        var endedSession = FastingManager.endSession(session, endTime: customTime)
        endedSession.manuallyEdited = true

        do {
            try await firebaseManager.updateFastingSession(endedSession)
            self.activeSession = nil
            await loadRecentSessions()
            await loadAnalytics()

                    } catch {
            self.error = error
            self.showError = true
        }

        confirmationContext = nil
    }

    /// User wants to continue fasting past target
    func confirmContinueFasting() {
                // Don't end the session - let it continue
        confirmationContext = nil
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

    // MARK: - Live Activity Support

    @available(iOS 16.1, *)
    func startLiveActivity() async {
        let authInfo = ActivityAuthorizationInfo()
        guard authInfo.areActivitiesEnabled else { return }

        // End any existing activities first to avoid conflicts
        for activity in Activity<FastingActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        currentLiveActivity = nil

        guard let plan = activePlan else { return }

        let totalElapsedSeconds = hoursIntoCurrentFast * 3600
        let hours = Int(totalElapsedSeconds / 3600)
        let minutes = Int((totalElapsedSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(totalElapsedSeconds.truncatingRemainder(dividingBy: 60))

        let totalGoalSeconds = Double(plan.durationHours) * 3600
        let remainingTotalSeconds = max(0, totalGoalSeconds - totalElapsedSeconds)
        let remainingHours = Int(remainingTotalSeconds / 3600)
        let remainingMinutes = Int((remainingTotalSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        let remainingSeconds = Int(remainingTotalSeconds.truncatingRemainder(dividingBy: 60))

        let phaseInfo = FastingPhaseInfo.forHours(hours)

        // Calculate actual start and end times for live countdown
        let fastingStartTime = Date().addingTimeInterval(-totalElapsedSeconds)
        let fastingEndTime = fastingStartTime.addingTimeInterval(totalGoalSeconds)

        let attributes = FastingActivityAttributes(fastingGoalHours: plan.durationHours)
        let contentState = FastingActivityAttributes.ContentState(
            fastingStartTime: fastingStartTime,
            fastingEndTime: fastingEndTime,
            currentHours: hours,
            currentMinutes: minutes,
            currentSeconds: seconds,
            remainingHours: remainingHours,
            remainingMinutes: remainingMinutes,
            remainingSeconds: remainingSeconds,
            currentPhase: phaseInfo.name,
            phaseEmoji: phaseInfo.emoji
        )

        do {
            let content = ActivityContent(state: contentState, staleDate: nil)
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            currentLiveActivity = activity
        } catch {
            print("🔴 [LiveActivity] ERROR: \(error.localizedDescription)")
        }
    }

    @available(iOS 16.1, *)
    func updateLiveActivity() async {
        guard let activity = currentLiveActivity as? Activity<FastingActivityAttributes> else {
            return
        }

        guard let plan = activePlan else { return }

        let totalElapsedSeconds = hoursIntoCurrentFast * 3600
        let hours = Int(totalElapsedSeconds / 3600)
        let minutes = Int((totalElapsedSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(totalElapsedSeconds.truncatingRemainder(dividingBy: 60))

        let totalGoalSeconds = Double(plan.durationHours) * 3600
        let remainingTotalSeconds = max(0, totalGoalSeconds - totalElapsedSeconds)
        let remainingHours = Int(remainingTotalSeconds / 3600)
        let remainingMinutes = Int((remainingTotalSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        let remainingSeconds = Int(remainingTotalSeconds.truncatingRemainder(dividingBy: 60))

        let phaseInfo = FastingPhaseInfo.forHours(hours)

        // Calculate actual start and end times for live countdown
        let fastingStartTime = Date().addingTimeInterval(-totalElapsedSeconds)
        let fastingEndTime = fastingStartTime.addingTimeInterval(totalGoalSeconds)

        let contentState = FastingActivityAttributes.ContentState(
            fastingStartTime: fastingStartTime,
            fastingEndTime: fastingEndTime,
            currentHours: hours,
            currentMinutes: minutes,
            currentSeconds: seconds,
            remainingHours: remainingHours,
            remainingMinutes: remainingMinutes,
            remainingSeconds: remainingSeconds,
            currentPhase: phaseInfo.name,
            phaseEmoji: phaseInfo.emoji
        )

        let content = ActivityContent(state: contentState, staleDate: nil)
        await activity.update(content)
    }

    @available(iOS 16.1, *)
    func endLiveActivity() async {
        guard let activity = currentLiveActivity as? Activity<FastingActivityAttributes> else {
            return
        }
        await activity.end(nil, dismissalPolicy: .immediate)
        currentLiveActivity = nil
        print("🔴 [LiveActivity] Ended Live Activity")
    }

    // MARK: - Widget Data Sync

    /// Syncs the current fasting session state to the widget via App Group UserDefaults
    private func syncWidgetData() {
        if let session = activeSession {
            // Active session - update widget with session data
            syncActiveSessionToWidget(session)
        } else {
            // No active session - clear widget data
            clearWidgetData()
        }
    }

    private func syncActiveSessionToWidget(_ session: FastingSession) {
        let appGroupId = "group.com.nutrasafe.beta"
        guard let defaults = UserDefaults(suiteName: appGroupId) else { return }

        let data: [String: Any] = [
            "isActive": true,
            "startTime": session.startTime.timeIntervalSince1970,
            "targetDurationHours": session.targetDurationHours,
            "currentPhase": session.currentPhase.displayName,
            "planName": activePlan?.name ?? "",
            "lastUpdated": Date().timeIntervalSince1970
        ]

        if let encoded = try? JSONSerialization.data(withJSONObject: data) {
            defaults.set(encoded, forKey: "fastingSessionData")
            WidgetKit.WidgetCenter.shared.reloadTimelines(ofKind: "FastingSmallStatusWidget")
            WidgetKit.WidgetCenter.shared.reloadTimelines(ofKind: "FastingMediumProgressWidget")
            WidgetKit.WidgetCenter.shared.reloadTimelines(ofKind: "FastingQuickActionWidget")
        }
    }

    private func clearWidgetData() {
        let appGroupId = "group.com.nutrasafe.beta"
        guard let defaults = UserDefaults(suiteName: appGroupId) else { return }

        let data: [String: Any] = [
            "isActive": false,
            "lastUpdated": Date().timeIntervalSince1970
        ]

        if let encoded = try? JSONSerialization.data(withJSONObject: data) {
            defaults.set(encoded, forKey: "fastingSessionData")
            WidgetKit.WidgetCenter.shared.reloadTimelines(ofKind: "FastingSmallStatusWidget")
            WidgetKit.WidgetCenter.shared.reloadTimelines(ofKind: "FastingMediumProgressWidget")
            WidgetKit.WidgetCenter.shared.reloadTimelines(ofKind: "FastingQuickActionWidget")
        }
    }
}
