//
//  FastingNotificationManager.swift
//  NutraSafe Beta
//
//  Handles scheduling notifications for fasting sessions
//

import Foundation
import UserNotifications

class FastingNotificationManager {
    static let shared = FastingNotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()

    // Notification category identifiers
    private let fastStartCategoryId = "FAST_START"
    private let fastEndCategoryId = "FAST_END"

    // Action identifiers
    private let confirmActionId = "CONFIRM_FAST"
    private let skipActionId = "SKIP_FAST"
    private let adjustActionId = "ADJUST_FAST"

    private init() {
        registerNotificationCategories()
    }

    // MARK: - Setup

    /// Register notification categories with actions
    private func registerNotificationCategories() {
        // Actions for start notification
        let confirmStartAction = UNNotificationAction(
            identifier: confirmActionId,
            title: "Confirm",
            options: [.foreground]
        )
        let skipTodayAction = UNNotificationAction(
            identifier: skipActionId,
            title: "Skip Today",
            options: [.destructive]
        )
        let adjustStartAction = UNNotificationAction(
            identifier: adjustActionId,
            title: "Adjust Time",
            options: [.foreground]
        )

        let startCategory = UNNotificationCategory(
            identifier: fastStartCategoryId,
            actions: [confirmStartAction, skipTodayAction, adjustStartAction],
            intentIdentifiers: [],
            options: []
        )

        // Actions for end notification
        let confirmEndAction = UNNotificationAction(
            identifier: confirmActionId,
            title: "Completed!",
            options: [.foreground]
        )
        let endedEarlyAction = UNNotificationAction(
            identifier: "ENDED_EARLY",
            title: "Ended Early",
            options: [.foreground]
        )

        let endCategory = UNNotificationCategory(
            identifier: fastEndCategoryId,
            actions: [confirmEndAction, endedEarlyAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([startCategory, endCategory])
    }

    // MARK: - Schedule Notifications

    /// Schedule all notifications for a fasting plan
    func schedulePlanNotifications(for plan: FastingPlan) async throws {
        // Cancel any existing notifications for this plan
        await cancelPlanNotifications(planId: plan.id ?? "")

        // Get the next 4 weeks of scheduled days for this plan
        let scheduledDates = getNextScheduledDates(for: plan, weeksAhead: 4)

        for date in scheduledDates {
            try await scheduleStartNotification(for: plan, on: date)
            try await scheduleEndNotification(for: plan, startingOn: date)
        }

        #if DEBUG
        print("📅 Scheduled \(scheduledDates.count) notification pairs for plan: \(plan.name)")
        #endif
    }

    /// Schedule a notification for fast start
    private func scheduleStartNotification(for plan: FastingPlan, on date: Date) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Time to start your fast"
        content.body = "\(plan.name) • \(plan.durationDisplay)"
        content.sound = .default
        content.categoryIdentifier = fastStartCategoryId

        // Add plan information to userInfo
        content.userInfo = [
            "type": "fasting",
            "fastingType": "start",
            "planId": plan.id ?? "",
            "planName": plan.name,
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
        content.title = "Fast complete!"
        content.body = "You've completed your \(plan.durationDisplay) fast. How did it go?"
        content.sound = .default
        content.categoryIdentifier = fastEndCategoryId

        // Add plan information to userInfo
        content.userInfo = [
            "type": "fasting",
            "fastingType": "end",
            "planId": plan.id ?? "",
            "planName": plan.name,
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
