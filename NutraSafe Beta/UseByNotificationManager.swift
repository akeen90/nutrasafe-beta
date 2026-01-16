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
                        return
        }

        let useByDate = item.expiryDate
        let itemName = item.name

        // Ensure we have permission
        guard await requestNotificationPermissions() else {
                        return
        }

        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let expiryDay = calendar.startOfDay(for: useByDate)

        // Calculate tomorrow notification (day before expiry)
        if let tomorrowDate = calendar.date(byAdding: .day, value: -1, to: expiryDay) {
            let daysBetween = calendar.dateComponents([.day], from: today, to: tomorrowDate).day ?? 0
            if daysBetween >= 0 {
                await scheduleSingleNotification(
                    itemId: item.id,
                    itemName: itemName,
                    on: tomorrowDate,
                    title: "🔔 Food Expiring Tomorrow",
                    body: "\(itemName) expires tomorrow. Use it soon!",
                    identifier: "tomorrow-\(item.id)"
                )
            }
        }

        // Calculate expiry day notification
        let daysUntilExpiry = calendar.dateComponents([.day], from: today, to: expiryDay).day ?? 0
        if daysUntilExpiry >= 0 {
            await scheduleSingleNotification(
                itemId: item.id,
                itemName: itemName,
                on: expiryDay,
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

        // Add userInfo for deep linking
        content.userInfo = [
            "type": "useBy",
            "itemId": itemId,
            "itemName": itemName
        ]

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 9
        components.minute = 0
        components.second = 0
        components.timeZone = calendar.timeZone

        guard let targetDate = calendar.date(from: components) else {
            return
        }

        guard targetDate > Date() else {
            return
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            
            // Verify it was added
            await printPendingNotifications()
        } catch {
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
    }

    /// Cancel all use-by related notifications
    func cancelAllNotifications() {
        Task {
            let center = UNUserNotificationCenter.current()
            let requests = await center.pendingNotificationRequests()
            let ids = requests.filter { ($0.content.userInfo["type"] as? String) == "useBy" }.map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
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

    }

    // MARK: - Debugging

    /// Print all pending notifications (for debugging)
    func printPendingNotifications() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
                for request in requests {
                    }
    }
}
