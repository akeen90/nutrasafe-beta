import Foundation
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

class FastingService: ObservableObject {
    private let db = Firestore.firestore()
    private let userId: String

    /// Initialize FastingService. Returns nil if user is not authenticated.
    /// Callers should check authentication state before creating this service.
    init?() {
        guard let currentUser = Auth.auth().currentUser else {
            return nil
        }
        self.userId = currentUser.uid
    }
    
    // MARK: - Fasting Plans
    
    func createFastingPlan(
        name: String,
        durationHours: Int,
        daysOfWeek: [String],
        preferredStartTime: Date,
        allowedDrinks: AllowedDrinksPhilosophy,
        reminderEnabled: Bool,
        reminderMinutesBeforeEnd: Int
    ) async throws -> FastingPlan {

        // Deactivate all existing plans for this user
        try await deactivateAllPlans()

        let plan = FastingPlan(
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
        
        let docRef = try db.collection("fasting_plans").addDocument(from: plan)
        var newPlan = plan
        newPlan.id = docRef.documentID
        
        return newPlan
    }
    
    func getActivePlan() async throws -> FastingPlan? {
        let snapshot = try await db.collection("fasting_plans")
            .whereField("user_id", isEqualTo: userId)
            .whereField("active", isEqualTo: true)
            .limit(to: 1)
            .getDocuments()
        
        return try snapshot.documents.first?.data(as: FastingPlan.self)
    }
    
    func getAllPlans() async throws -> [FastingPlan] {
        let snapshot = try await db.collection("fasting_plans")
            .whereField("user_id", isEqualTo: userId)
            .order(by: "created_at", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: FastingPlan.self) }
    }
    
    func updatePlan(_ plan: FastingPlan) async throws {
        guard let planId = plan.id else { throw FastingError.invalidPlanId }
        
        // If activating this plan, deactivate all others
        if plan.active {
            try await deactivateAllPlans(excluding: planId)
        }
        
        try db.collection("fasting_plans").document(planId).setData(from: plan)
    }
    
    func deletePlan(_ plan: FastingPlan) async throws {
        guard let planId = plan.id else { throw FastingError.invalidPlanId }
        
        // Cannot delete active plans
        if plan.active {
            throw FastingError.cannotDeleteActivePlan
        }
        
        try await db.collection("fasting_plans").document(planId).delete()
    }
    
    private func deactivateAllPlans(excluding planId: String? = nil) async throws {
        let query = db.collection("fasting_plans").whereField("user_id", isEqualTo: userId)

        let snapshot = try await query.getDocuments()

        for document in snapshot.documents {
            if let excludeId = planId, document.documentID == excludeId {
                continue
            }

            try await document.reference.updateData(["active": false])
        }
    }

    // MARK: - Regime Control

    func startRegime(planId: String) async throws {
        try await db.collection("users").document(userId).collection("fastingPlans").document(planId).updateData([
            "regime_active": true,
            "regime_started_at": Timestamp(date: Date())
        ])
    }

    func stopRegime(planId: String) async throws {
        try await db.collection("users").document(userId).collection("fastingPlans").document(planId).updateData([
            "regime_active": false,
            "regime_started_at": FieldValue.delete()
        ])
    }

    // MARK: - Fasting Sessions
    
    func startFastingSession(plan: FastingPlan?) async throws -> FastingSession {
        // Check for existing active session
        if let activeSession = try await getActiveSession() {
            throw FastingError.sessionAlreadyActive(activeSession)
        }
        
        let session = FastingSession(
            userId: userId,
            planId: plan?.id,
            startTime: Date(),
            endTime: nil,
            manuallyEdited: false,
            skipped: false,
            completionStatus: .active,
            targetDurationHours: plan?.durationHours ?? 16, // Default to 16 hours if no plan
            notes: nil,
            createdAt: Date()
        )
        
        let docRef = try db.collection("fasting_sessions").addDocument(from: session)
        var newSession = session
        newSession.id = docRef.documentID
        
        // Schedule notifications if plan has reminders enabled
        if let plan = plan, plan.reminderEnabled {
            try await scheduleNotifications(for: newSession, plan: plan)
        }
        
        return newSession
    }
    
    func endFastingSession(_ session: FastingSession, completionStatus: FastingCompletionStatus) async throws {
        guard let sessionId = session.id else { throw FastingError.invalidSessionId }

        var updatedSession = session
        updatedSession.endTime = Date()
        updatedSession.completionStatus = completionStatus

        try db.collection("fasting_sessions").document(sessionId).setData(from: updatedSession)

        // Cancel all pending notifications for this session
        try await cancelNotifications(for: sessionId)
    }
    
    func skipFastingSession(_ session: FastingSession) async throws {
        guard let sessionId = session.id else { throw FastingError.invalidSessionId }
        
        var updatedSession = session
        updatedSession.skipped = true
        updatedSession.completionStatus = .skipped
        updatedSession.endTime = Date()
        
        try db.collection("fasting_sessions").document(sessionId).setData(from: updatedSession)

        // Cancel all pending notifications for this session
        try await cancelNotifications(for: sessionId)
    }

    func editSessionTimes(_ session: FastingSession, startTime: Date, endTime: Date?) async throws {
        guard let sessionId = session.id else { throw FastingError.invalidSessionId }
        
        // Validate that end time is after start time
        if let end = endTime, end <= startTime {
            throw FastingError.invalidTimeRange
        }
        
        var updatedSession = session
        updatedSession.startTime = startTime
        updatedSession.endTime = endTime
        updatedSession.manuallyEdited = true
        
        // Update completion status based on new times
        if let end = endTime {
            let duration = end.timeIntervalSince(startTime) / 3600
            let target = Double(session.targetDurationHours)
            
            if duration >= target {
                updatedSession.completionStatus = .completed
            } else if duration > 0 {
                updatedSession.completionStatus = .earlyEnd
            } else {
                updatedSession.completionStatus = .failed
            }
        } else {
            updatedSession.completionStatus = .active
        }
        
        try db.collection("fasting_sessions").document(sessionId).setData(from: updatedSession)
    }

    func getActiveSession() async throws -> FastingSession? {
        let snapshot = try await db.collection("fasting_sessions")
            .whereField("user_id", isEqualTo: userId)
            .whereField("completion_status", isEqualTo: "active")
            .limit(to: 1)
            .getDocuments()
        
        return try snapshot.documents.first?.data(as: FastingSession.self)
    }
    
    func getRecentSessions(limit: Int = 30) async throws -> [FastingSession] {
        let snapshot = try await db.collection("fasting_sessions")
            .whereField("user_id", isEqualTo: userId)
            .whereField("completion_status", in: ["completed", "earlyEnd", "overGoal"])
            .order(by: "start_time", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: FastingSession.self) }
    }
    
    func getSessionsForDateRange(start: Date, end: Date) async throws -> [FastingSession] {
        let snapshot = try await db.collection("fasting_sessions")
            .whereField("user_id", isEqualTo: userId)
            .whereField("start_time", isGreaterThanOrEqualTo: start)
            .whereField("start_time", isLessThanOrEqualTo: end)
            .order(by: "start_time", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: FastingSession.self) }
    }
    
    // MARK: - Analytics
    
    func getFastingAnalytics() async throws -> FastingAnalytics {
        let calendar = Calendar.current
        let now = Date()
        
        // Get last 30 days of completed sessions
        guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) else {
            throw FastingError.dateCalculationError
        }
        
        let recentSessions = try await getSessionsForDateRange(start: thirtyDaysAgo, end: now)
        let completedSessions = recentSessions.filter { 
            $0.completionStatus == .completed || 
            $0.completionStatus == .earlyEnd || 
            $0.completionStatus == .overGoal 
        }
        
        // Calculate analytics
        let totalFastsCompleted = completedSessions.count
        
        let averageCompletionPercentage = completedSessions.isEmpty ? 0 : 
            completedSessions.map { $0.progressPercentage * 100 }.reduce(0, +) / Double(completedSessions.count)
        
        let averageDurationVsGoal = completedSessions.isEmpty ? 0 :
            completedSessions.map { $0.actualDurationHours }.reduce(0, +) / Double(completedSessions.count)
        
        let longestFastHours = completedSessions.map { $0.actualDurationHours }.max() ?? 0
        
        // Calculate most consistent day
        let dayOfWeekCounts = Dictionary(
            completedSessions.map { session in
                calendar.component(.weekday, from: session.startTime)
            }.map { ($0, 1) },
            uniquingKeysWith: +
        )
        let mostConsistentDayNumber = dayOfWeekCounts.max(by: { $0.value < $1.value })?.key
        let mostConsistentDay = mostConsistentDayNumber.map { calendar.weekdaySymbols[$0 - 1] }
        
        // Calculate phase distribution
        var phaseDistribution: [FastingPhase: Int] = [:]
        for session in completedSessions {
            for phase in session.phasesReached {
                phaseDistribution[phase, default: 0] += 1
            }
        }
        
        // Get last 7 days sessions
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) else {
            throw FastingError.dateCalculationError
        }
        
        let last7DaysSessions = recentSessions.filter { $0.startTime >= sevenDaysAgo }

        // Calculate streaks
        let currentStreak = calculateCurrentStreak(from: completedSessions)
        let longestStreak = calculateLongestStreak(from: completedSessions)

        return FastingAnalytics(
            totalFastsCompleted: totalFastsCompleted,
            averageCompletionPercentage: averageCompletionPercentage,
            averageDurationVsGoal: averageDurationVsGoal,
            longestFastHours: longestFastHours,
            mostConsistentDay: mostConsistentDay,
            phaseDistribution: phaseDistribution,
            last7DaysSessions: last7DaysSessions,
            last30DaysSessions: recentSessions,
            currentWeeklyStreak: currentStreak,
            bestWeeklyStreak: longestStreak
        )
    }
    
    // MARK: - Notifications
    
    private func scheduleNotifications(for session: FastingSession, plan: FastingPlan) async throws {
        guard plan.reminderEnabled else { return }
        
        let notifications = createNotificationSchedule(for: session, plan: plan)
        
        for notification in notifications {
            try db.collection("fasting_notifications").addDocument(from: notification)
            
            // Schedule local notification
            let content = UNMutableNotificationContent()
            content.title = notification.title
            content.body = notification.body
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: notification.scheduledDate.timeIntervalSinceNow,
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: notification.id,
                content: content,
                trigger: trigger
            )
            
            try await UNUserNotificationCenter.current().add(request)
        }
    }
    
    private func createNotificationSchedule(for session: FastingSession, plan: FastingPlan) -> [FastingNotification] {
        var notifications: [FastingNotification] = []
        let now = Date()
        let targetEndTime = session.startTime.addingTimeInterval(TimeInterval(plan.durationHours) * 3600)
        
        // Start notification
        notifications.append(FastingNotification(
            id: "\(session.id ?? "")_start",
            type: .fastStart,
            title: "Fasting Started",
            body: "Your \(plan.durationDisplay) fast has begun. Stay focused!",
            scheduledDate: now.addingTimeInterval(5), // 5 seconds after start
            sessionId: session.id ?? ""
        ))
        
        // Midway check-in
        let midwayTime = session.startTime.addingTimeInterval(TimeInterval(plan.durationHours / 2) * 3600)
        if midwayTime > now {
            notifications.append(FastingNotification(
                id: "\(session.id ?? "")_midway",
                type: .midwayCheckIn,
                title: "Halfway There",
                body: "You're doing great — stay steady.",
                scheduledDate: midwayTime,
                sessionId: session.id ?? ""
            ))
        }
        
        // Reminder before end
        if plan.reminderMinutesBeforeEnd > 0 {
            let reminderTime = targetEndTime.addingTimeInterval(-TimeInterval(plan.reminderMinutesBeforeEnd) * 60)
            if reminderTime > now {
                notifications.append(FastingNotification(
                    id: "\(session.id ?? "")_reminder",
                    type: .reminderBeforeEnd,
                    title: "Fast Almost Complete",
                    body: "Your fast ends in \(plan.reminderMinutesBeforeEnd) minutes. Prepare to break gently.",
                    scheduledDate: reminderTime,
                    sessionId: session.id ?? ""
                ))
            }
        }
        
        // Target reached
        notifications.append(FastingNotification(
            id: "\(session.id ?? "")_target",
            type: .targetReached,
            title: "Target Achieved!",
            body: "You completed your \(plan.durationDisplay) fast. Great job!",
            scheduledDate: targetEndTime,
            sessionId: session.id ?? ""
        ))
        
        return notifications.filter { $0.scheduledDate > now }
    }
    
    private func cancelNotifications(for sessionId: String) async throws {
        // Get all notifications for this session
        let snapshot = try await db.collection("fasting_notifications")
            .whereField("session_id", isEqualTo: sessionId)
            .whereField("scheduled_date", isGreaterThan: Date())
            .getDocuments()
        
        // Delete from Firestore and cancel local notifications
        for document in snapshot.documents {
            try await document.reference.delete()
            
            let notificationId = document.documentID
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
        }
    }
    
    // MARK: - User Settings
    
    func getUserSettings() async throws -> [String: Any]? {
        let document = try await db.collection("fasting_settings").document(userId).getDocument()
        return document.data()
    }
    
    func updateUserSettings(_ settings: [String: Any]) async throws {
        var updatedSettings = settings
        updatedSettings["user_id"] = userId
        updatedSettings["updated_at"] = Timestamp(date: Date())

        try await db.collection("fasting_settings").document(userId).setData(updatedSettings, merge: true)
    }

    // MARK: - Streak Calculations

    private func calculateCurrentStreak(from sessions: [FastingSession]) -> Int {
        let sortedSessions = sessions.sorted { $0.startTime > $1.startTime }

        guard let latest = sortedSessions.first else { return 0 }

        var streak = 1
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: latest.startTime)

        for session in sortedSessions.dropFirst() {
            let sessionDate = calendar.startOfDay(for: session.startTime)
            let daysBetween = calendar.dateComponents([.day], from: sessionDate, to: currentDate).day ?? 0

            if daysBetween <= 1 {
                streak += 1
                currentDate = sessionDate
            } else {
                break
            }
        }

        return streak
    }

    private func calculateLongestStreak(from sessions: [FastingSession]) -> Int {
        let sortedSessions = sessions.sorted { $0.startTime < $1.startTime }

        guard !sortedSessions.isEmpty else { return 0 }

        var longestStreak = 1
        var currentStreak = 1
        let calendar = Calendar.current

        for i in 1..<sortedSessions.count {
            let previousDate = calendar.startOfDay(for: sortedSessions[i-1].startTime)
            let currentDate = calendar.startOfDay(for: sortedSessions[i].startTime)
            let daysBetween = calendar.dateComponents([.day], from: previousDate, to: currentDate).day ?? 0

            if daysBetween <= 1 {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }

        return longestStreak
    }
}

// MARK: - Error Types

enum FastingError: LocalizedError {
    case invalidPlanId
    case invalidSessionId
    case cannotDeleteActivePlan
    case sessionAlreadyActive(FastingSession)
    case invalidTimeRange
    case dateCalculationError
    
    var errorDescription: String? {
        switch self {
        case .invalidPlanId:
            return "Invalid fasting plan ID"
        case .invalidSessionId:
            return "Invalid fasting session ID"
        case .cannotDeleteActivePlan:
            return "Cannot delete an active fasting plan"
        case .sessionAlreadyActive(let session):
            return "A fasting session is already active (started \(session.startTime.formatted()))"
        case .invalidTimeRange:
            return "End time must be after start time"
        case .dateCalculationError:
            return "Error calculating date range"
        }
    }
}