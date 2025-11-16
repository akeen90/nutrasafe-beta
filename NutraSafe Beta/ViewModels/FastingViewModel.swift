//
//  FastingViewModel.swift
//  NutraSafe Beta
//
//  Created by Claude
//

import Foundation
import SwiftUI
import Combine

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

    // MARK: - Private Properties

    private let firebaseManager: FirebaseManager
    private var timer: Timer?
    private let userId: String

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
        guard let session = activeSession else { return "0:00" }
        let hours = Int(session.actualDurationHours)
        let minutes = Int((session.actualDurationHours - Double(hours)) * 60)
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
            let hours = Int(remaining)
            let minutes = Int((remaining - Double(hours)) * 60)
            return "\(hours)h \(minutes)m until target"
        } else {
            let over = elapsed - target
            let hours = Int(over)
            let minutes = Int((over - Double(hours)) * 60)
            return "\(hours)h \(minutes)m past target"
        }
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

        Task {
            await loadInitialData()
            startTimer()
        }
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Data Loading

    private func loadInitialData() async {
        await loadActivePlan()
        await loadActiveSession()
        await loadRecentSessions()
        await loadAnalytics()
    }

    func loadActivePlan() async {
        do {
            let plans = try await firebaseManager.getFastingPlans()
            self.activePlan = plans.first(where: { $0.active })
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func loadAllPlans() async {
        do {
            self.allPlans = try await firebaseManager.getFastingPlans()
        } catch {
            self.error = error
            self.showError = true
        }
    }

    private func loadActiveSession() async {
        do {
            let sessions = try await firebaseManager.getFastingSessions()
            self.activeSession = sessions.prefix(1).first(where: { $0.isActive })
        } catch {
            self.error = error
            self.showError = true
        }
    }

    private func loadRecentSessions() async {
        do {
            let sessions = try await firebaseManager.getFastingSessions()
            self.recentSessions = Array(sessions.prefix(10))
        } catch {
            self.error = error
            self.showError = true
        }
    }

    private func loadAnalytics() async {
        do {
            let sessions = try await firebaseManager.getFastingSessions()
            self.analytics = FastingManager.calculateAnalytics(from: Array(sessions.prefix(100)))
        } catch {
            self.error = error
            self.showError = true
        }
    }

    // MARK: - Timer

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.objectWillChange.send()
            }
        }
    }

    // MARK: - Plan Management

    func createFastingPlan(
        name: String,
        durationHours: Int,
        daysOfWeek: [String],
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

        // Create new plan
        let newPlan = FastingPlan(
            userId: userId,
            name: name,
            durationHours: durationHours,
            daysOfWeek: daysOfWeek,
            allowedDrinks: allowedDrinks,
            reminderEnabled: reminderEnabled,
            reminderMinutesBeforeEnd: reminderMinutesBeforeEnd,
            active: true,
            createdAt: Date()
        )

        do {
            try await firebaseManager.saveFastingPlan(newPlan)
            await loadActivePlan()
            await loadAllPlans()
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

            // If deleted plan was active, clear it
            if plan.id == activePlan?.id {
                activePlan = nil
            }
        } catch {
            self.error = error
            self.showError = true
        }
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
            plan: plan,
            targetDurationHours: plan.durationHours
        )

        do {
            try await firebaseManager.saveFastingSession(session)
            await loadActiveSession()
            await loadRecentSessions()
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func endFastingSession() async {
        guard let session = activeSession else { return }

        isLoading = true
        defer { isLoading = false }

        // Use FastingManager to automatically determine completion status
        let endedSession = FastingManager.endSession(session)

        do {
            try await firebaseManager.updateFastingSession(endedSession)
            self.activeSession = nil
            await loadRecentSessions()
            await loadAnalytics()
        } catch {
            self.error = error
            self.showError = true
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

    // MARK: - Error Handling

    func clearError() {
        error = nil
        showError = false
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
            allowedDrinks: .practical,
            reminderEnabled: true,
            reminderMinutesBeforeEnd: 30,
            active: true,
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
