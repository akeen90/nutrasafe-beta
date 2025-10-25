//
//  UseByNotificationManager.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-10-20.
//  Manages use-by date notifications for food items
//

import Foundation
import UserNotifications

class UseByNotificationManager {
    static let shared = UseByNotificationManager()

    private init() {}

    // Check if user has enabled use-by notifications in settings
    // Default to true if not set (matches AppStorage default)
    private var useByNotificationsEnabled: Bool {
        if UserDefaults.standard.object(forKey: "useByNotificationsEnabled") == nil {
            return true // Default value
        }
        return UserDefaults.standard.bool(forKey: "useByNotificationsEnabled")
    }

    // MARK: - Permission Request

    /// Request notification permissions if not already granted
    func requestNotificationPermissions() async -> Bool {
        let center = UNUserNotificationCenter.current()

        // Check current authorization status
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                return granted
            } catch {
                return false
            }
        case .ephemeral:
            return true
        @unknown default:
            return false
        }
    }

    // MARK: - Schedule Notifications

    /// Schedule notifications for a use-by item (tomorrow and on expiry day)
    func scheduleNotifications(for item: UseByInventoryItem) async {
        // Check if user has enabled use-by notifications in settings
        guard useByNotificationsEnabled else {
            print("⏸️ Use-by notifications disabled in settings - not scheduling for \(item.name)")
            return
        }

        let useByDate = item.expiryDate
        let itemName = item.name

        // Ensure we have permission
        guard await requestNotificationPermissions() else {
            print("❌ Notification permission not granted")
            return
        }

        let calendar = Calendar.current
        let now = Date()

        // Calculate tomorrow notification (day before expiry)
        if let tomorrowDate = calendar.date(byAdding: .day, value: -1, to: useByDate),
           tomorrowDate > now {
            await scheduleSingleNotification(
                itemId: item.id,
                itemName: itemName,
                on: tomorrowDate,
                title: "🔔 Food Expiring Tomorrow",
                body: "\(itemName) expires tomorrow. Use it soon!",
                identifier: "tomorrow-\(item.id)"
            )
        }

        // Calculate expiry day notification
        if useByDate > now {
            await scheduleSingleNotification(
                itemId: item.id,
                itemName: itemName,
                on: useByDate,
                title: "⚠️ Food Expiring Today",
                body: "\(itemName) expires today. Use it or freeze it!",
                identifier: "expiry-\(item.id)"
            )
        }
    }

    private func scheduleSingleNotification(
        itemId: String,
        itemName: String,
        on date: Date,
        title: String,
        body: String,
        identifier: String
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1

        // Set notification at 9 AM on the target date
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Use-by notification scheduled: '\(identifier)' for \(date)")
        } catch {
            print("❌ Error scheduling use-by notification: \(error)")
        }
    }

    // MARK: - Cancel Notifications

    /// Cancel all notifications for a specific use-by item
    func cancelNotifications(for itemId: String) {
        let identifiers = [
            "tomorrow-\(itemId)",
            "expiry-\(itemId)"
        ]

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🗑️ Cancelled notifications for item: \(itemId)")
    }

    /// Cancel all use-by related notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("🗑️ Cancelled all use-by notifications")
    }

    // MARK: - Refresh Notifications

    /// Refresh all notifications for all use-by items
    func refreshAllNotifications(for items: [UseByInventoryItem]) async {
        // Cancel all existing notifications
        cancelAllNotifications()

        // Schedule new notifications for each item
        for item in items {
            await scheduleNotifications(for: item)
        }

        print("🔄 Refreshed notifications for \(items.count) items")
    }

    // MARK: - Debugging

    /// Print all pending notifications (for debugging)
    func printPendingNotifications() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        print("📋 Pending Notifications: \(requests.count)")
        for request in requests {
            print("  - \(request.identifier): \(request.content.title)")
        }
    }
}
