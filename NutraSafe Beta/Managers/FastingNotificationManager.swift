//
//  FastingNotificationManager.swift
//  NutraSafe Beta
//
//  Handles scheduling notifications for fasting sessions
//

import Foundation
import UserNotifications

// MARK: - Notification Settings Model

struct FastingNotificationSettings: Codable {
    var startNotificationEnabled: Bool = true
    var endNotificationEnabled: Bool = true
    var stageNotificationsEnabled: Bool = true

    // Individual stage toggles
    var stage4hEnabled: Bool = true   // Post-meal processing complete
    var stage8hEnabled: Bool = true   // Fuel switching
    var stage12hEnabled: Bool = true  // Fat mobilisation
    var stage16hEnabled: Bool = true  // Mild ketosis
    var stage20hEnabled: Bool = true  // Autophagy potential

    static var `default`: FastingNotificationSettings {
        FastingNotificationSettings()
    }

    // UserDefaults key
    private static let storageKey = "fastingNotificationSettings"

    static func load() -> FastingNotificationSettings {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let settings = try? JSONDecoder().decode(FastingNotificationSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: FastingNotificationSettings.storageKey)
        }
    }
}

// MARK: - Notification Manager

class FastingNotificationManager {
    static let shared = FastingNotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()

    // Settings
    var settings: FastingNotificationSettings {
        didSet {
            settings.save()
        }
    }

    // Notification category identifiers
    private let fastStartCategoryId = "FAST_START"
    private let fastEndCategoryId = "FAST_END"
    private let fastStageCategoryId = "FAST_STAGE"

    // Action identifiers
    private let snooze15ActionId = "SNOOZE_15"
    private let snooze30ActionId = "SNOOZE_30"
    private let snooze60ActionId = "SNOOZE_60"
    private let startNowActionId = "START_NOW"

    private let extend15ActionId = "EXTEND_15"
    private let extend30ActionId = "EXTEND_30"
    private let extend60ActionId = "EXTEND_60"
    private let endNowActionId = "END_NOW"

    private let viewProgressActionId = "VIEW_PROGRESS"

    private init() {
        settings = FastingNotificationSettings.load()
        registerNotificationCategories()
    }

    // MARK: - Setup

    /// Register notification categories with actions
    private func registerNotificationCategories() {
        // Actions for start notification - snooze options
        let snooze15Action = UNNotificationAction(
            identifier: snooze15ActionId,
            title: "Snooze 15 min",
            options: []
        )
        let snooze30Action = UNNotificationAction(
            identifier: snooze30ActionId,
            title: "Snooze 30 min",
            options: []
        )
        let snooze60Action = UNNotificationAction(
            identifier: snooze60ActionId,
            title: "Snooze 1 hour",
            options: []
        )
        let startNowAction = UNNotificationAction(
            identifier: startNowActionId,
            title: "Start Now",
            options: [.foreground]
        )

        let startCategory = UNNotificationCategory(
            identifier: fastStartCategoryId,
            actions: [startNowAction, snooze15Action, snooze30Action, snooze60Action],
            intentIdentifiers: [],
            options: []
        )

        // Actions for end notification - extend options
        let extend15Action = UNNotificationAction(
            identifier: extend15ActionId,
            title: "Extend 15 min",
            options: []
        )
        let extend30Action = UNNotificationAction(
            identifier: extend30ActionId,
            title: "Extend 30 min",
            options: []
        )
        let extend60Action = UNNotificationAction(
            identifier: extend60ActionId,
            title: "Extend 1 hour",
            options: []
        )
        let endNowAction = UNNotificationAction(
            identifier: endNowActionId,
            title: "End Fast",
            options: [.foreground]
        )

        let endCategory = UNNotificationCategory(
            identifier: fastEndCategoryId,
            actions: [endNowAction, extend15Action, extend30Action, extend60Action],
            intentIdentifiers: [],
            options: []
        )

        // Actions for stage notification
        let viewProgressAction = UNNotificationAction(
            identifier: viewProgressActionId,
            title: "View Progress",
            options: [.foreground]
        )

        let stageCategory = UNNotificationCategory(
            identifier: fastStageCategoryId,
            actions: [viewProgressAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([startCategory, endCategory, stageCategory])
    }

    // MARK: - Handle Notification Actions

    /// Handle notification action response
    func handleNotificationAction(identifier: String, userInfo: [AnyHashable: Any]) {
        guard let planId = userInfo["planId"] as? String else { return }

        switch identifier {
        case snooze15ActionId:
            scheduleSnoozeNotification(planId: planId, userInfo: userInfo, minutes: 15)
        case snooze30ActionId:
            scheduleSnoozeNotification(planId: planId, userInfo: userInfo, minutes: 30)
        case snooze60ActionId:
            scheduleSnoozeNotification(planId: planId, userInfo: userInfo, minutes: 60)
        case extend15ActionId:
            scheduleExtendNotification(planId: planId, userInfo: userInfo, minutes: 15)
        case extend30ActionId:
            scheduleExtendNotification(planId: planId, userInfo: userInfo, minutes: 30)
        case extend60ActionId:
            scheduleExtendNotification(planId: planId, userInfo: userInfo, minutes: 60)
        default:
            break
        }
    }

    private func scheduleSnoozeNotification(planId: String, userInfo: [AnyHashable: Any], minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Time to start your fast"
        content.body = "Snoozed reminder - your fast is ready to begin"
        content.sound = .default
        content.categoryIdentifier = fastStartCategoryId
        content.userInfo = userInfo as! [String: Any]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let identifier = "fast_start_snooze_\(planId)_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule snooze notification: \(error)")
            } else {
                print("✅ Scheduled snooze notification for \(minutes) minutes")
            }
        }
    }

    private func scheduleExtendNotification(planId: String, userInfo: [AnyHashable: Any], minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Extended fast complete!"
        content.body = "You've extended your fast by \(minutes) minutes. Great willpower!"
        content.sound = .default
        content.categoryIdentifier = fastEndCategoryId
        content.userInfo = userInfo as! [String: Any]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let identifier = "fast_end_extend_\(planId)_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule extend notification: \(error)")
            } else {
                print("✅ Scheduled extend notification for \(minutes) minutes")
            }
        }
    }

    // MARK: - Schedule Notifications

    /// Schedule all notifications for a fasting plan
    func schedulePlanNotifications(for plan: FastingPlan) async throws {
        // Cancel any existing notifications for this plan
        await cancelPlanNotifications(planId: plan.id ?? "")

        // Get the next 4 weeks of scheduled days for this plan
        let scheduledDates = getNextScheduledDates(for: plan, weeksAhead: 4)

        for date in scheduledDates {
            if settings.startNotificationEnabled {
                try await scheduleStartNotification(for: plan, on: date)
            }
            if settings.endNotificationEnabled {
                try await scheduleEndNotification(for: plan, startingOn: date)
            }
            if settings.stageNotificationsEnabled {
                try await scheduleStageNotifications(for: plan, startingOn: date)
            }
        }

        #if DEBUG
        print("📅 Scheduled notifications for \(scheduledDates.count) days for plan: \(plan.name)")
        #endif
    }

    /// Schedule notifications for an immediate fast (when starting from now)
    func scheduleImmediateFastNotifications(for plan: FastingPlan, startingAt startDate: Date) async throws {
        // Schedule end notification
        if settings.endNotificationEnabled {
            try await scheduleEndNotification(for: plan, startingOn: startDate)
        }

        // Schedule stage notifications
        if settings.stageNotificationsEnabled {
            try await scheduleStageNotifications(for: plan, startingOn: startDate)
        }

        // Schedule reminder before end if enabled in plan
        if plan.reminderEnabled && plan.reminderMinutesBeforeEnd > 0 {
            let endDate = startDate.addingTimeInterval(TimeInterval(plan.durationHours * 3600))
            let reminderDate = endDate.addingTimeInterval(-TimeInterval(plan.reminderMinutesBeforeEnd * 60))

            if reminderDate > Date() {
                let content = UNMutableNotificationContent()
                content.title = "Fast Almost Complete"
                content.body = "Your fast ends in \(plan.reminderMinutesBeforeEnd) minutes. Prepare to break gently."
                content.sound = .default
                content.categoryIdentifier = fastEndCategoryId

                content.userInfo = [
                    "type": "fasting",
                    "fastingType": "reminder",
                    "planId": plan.id ?? "",
                    "planName": plan.displayName
                ]

                let calendar = Calendar.current
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

                let identifier = "fast_reminder_\(plan.id ?? "")_\(startDate.timeIntervalSince1970)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                try await notificationCenter.add(request)
            }
        }

        #if DEBUG
        print("📅 Scheduled immediate fast notifications for plan: \(plan.name)")
        #endif
    }

    /// Schedule a notification for fast start
    private func scheduleStartNotification(for plan: FastingPlan, on date: Date) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Time to start your fast"
        content.body = "\(plan.displayName) • \(plan.durationDisplay)"
        content.sound = .default
        content.categoryIdentifier = fastStartCategoryId

        // Add plan information to userInfo
        content.userInfo = [
            "type": "fasting",
            "fastingType": "start",
            "planId": plan.id ?? "",
            "planName": plan.displayName,
            "durationHours": plan.durationHours,
            "scheduledStartTime": date.timeIntervalSince1970
        ]

        // Create date components for trigger
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // Create identifier using plan ID and date
        let identifier = "fast_start_\(plan.id ?? "")_\(date.timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await notificationCenter.add(request)
    }

    /// Schedule a notification for fast end
    private func scheduleEndNotification(for plan: FastingPlan, startingOn startDate: Date) async throws {
        let endDate = startDate.addingTimeInterval(TimeInterval(plan.durationHours * 3600))

        let content = UNMutableNotificationContent()
        content.title = "Fast complete! 🎉"
        content.body = "You've completed your \(plan.durationDisplay) fast. Well done!"
        content.sound = .default
        content.categoryIdentifier = fastEndCategoryId

        // Add plan information to userInfo
        content.userInfo = [
            "type": "fasting",
            "fastingType": "end",
            "planId": plan.id ?? "",
            "planName": plan.displayName,
            "durationHours": plan.durationHours,
            "scheduledStartTime": startDate.timeIntervalSince1970,
            "scheduledEndTime": endDate.timeIntervalSince1970
        ]

        // Create date components for trigger
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: endDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // Create identifier using plan ID and start date
        let identifier = "fast_end_\(plan.id ?? "")_\(startDate.timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await notificationCenter.add(request)
    }

    /// Schedule stage notifications throughout the fast
    private func scheduleStageNotifications(for plan: FastingPlan, startingOn startDate: Date) async throws {
        let stages: [(hours: Int, title: String, body: String, settingEnabled: Bool)] = [
            (4, "4 hours in", "Post-meal processing complete. Your body is transitioning.", settings.stage4hEnabled),
            (8, "8 hours in", "Fuel switching activated. Fat burning is ramping up!", settings.stage8hEnabled),
            (12, "12 hours in", "Fat mobilisation underway. Your body is using fat stores.", settings.stage12hEnabled),
            (16, "16 hours in", "Mild ketosis reached. Ketone production increasing.", settings.stage16hEnabled),
            (20, "20 hours in", "Autophagy potential. Cellular cleanup may begin.", settings.stage20hEnabled)
        ]

        for stage in stages where stage.settingEnabled && stage.hours < plan.durationHours {
            let stageDate = startDate.addingTimeInterval(TimeInterval(stage.hours * 3600))

            // Only schedule if the stage time is in the future
            guard stageDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = stage.title
            content.body = stage.body
            content.sound = .default
            content.categoryIdentifier = fastStageCategoryId

            content.userInfo = [
                "type": "fasting",
                "fastingType": "stage",
                "planId": plan.id ?? "",
                "planName": plan.displayName,
                "stageHours": stage.hours
            ]

            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: stageDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let identifier = "fast_stage_\(plan.id ?? "")_\(stage.hours)h_\(startDate.timeIntervalSince1970)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            try await notificationCenter.add(request)
        }
    }

    // MARK: - Cancel Notifications

    /// Cancel all notifications for a specific plan
    func cancelPlanNotifications(planId: String) async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()

        let identifiersToRemove = pendingRequests
            .filter { request in
                // Check if userInfo contains matching planId
                if let storedPlanId = request.content.userInfo["planId"] as? String {
                    return storedPlanId == planId
                }
                return false
            }
            .map { $0.identifier }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)

        #if DEBUG
        print("🗑️ Cancelled \(identifiersToRemove.count) notifications for plan: \(planId)")
        #endif
    }

    /// Cancel all fasting notifications
    func cancelAllFastingNotifications() async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()

        let identifiersToRemove = pendingRequests
            .filter { request in
                if let type = request.content.userInfo["type"] as? String {
                    return type == "fasting"
                }
                return false
            }
            .map { $0.identifier }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)

        #if DEBUG
        print("🗑️ Cancelled all \(identifiersToRemove.count) fasting notifications")
        #endif
    }

    // MARK: - Helper Methods

    /// Get the next scheduled dates for a plan (up to specified weeks ahead)
    private func getNextScheduledDates(for plan: FastingPlan, weeksAhead: Int) -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        var scheduledDates: [Date] = []

        // Look ahead for the specified number of weeks
        for dayOffset in 0...(weeksAhead * 7) {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }

            let weekday = calendar.component(.weekday, from: date)
            let weekdaySymbols = calendar.shortWeekdaySymbols
            let dayName = weekdaySymbols[weekday - 1]

            // Check if this day is scheduled in the plan
            if plan.daysOfWeek.contains(dayName) {
                // Combine the date with the plan's preferred start time
                if let scheduledDateTime = combineDateWithTime(date: date, time: plan.preferredStartTime) {
                    // Only include future dates
                    if scheduledDateTime > Date() {
                        scheduledDates.append(scheduledDateTime)
                    }
                }
            }
        }

        return scheduledDates
    }

    /// Combine a date with a time from another date
    private func combineDateWithTime(date: Date, time: Date) -> Date? {
        let calendar = Calendar.current

        // Get date components (year, month, day) from the date
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)

        // Get time components (hour, minute) from the time
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        // Combine them
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute

        return calendar.date(from: combinedComponents)
    }

    // MARK: - Debug Helpers

    /// List all pending fasting notifications (for debugging)
    func listPendingNotifications() async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let fastingNotifications = pendingRequests.filter { request in
            if let type = request.content.userInfo["type"] as? String {
                return type == "fasting"
            }
            return false
        }

        #if DEBUG
        print("📋 Pending fasting notifications: \(fastingNotifications.count)")
        for (index, request) in fastingNotifications.enumerated() {
            print("   \(index + 1). \(request.content.title) - \(request.identifier)")
            if let trigger = request.trigger as? UNCalendarNotificationTrigger,
               let nextTriggerDate = trigger.nextTriggerDate() {
                print("      Scheduled for: \(nextTriggerDate)")
            }
        }
        #endif
    }
}
