//
//  FastingManager.swift
//  NutraSafe Beta
//
//  Manages fasting tracking with persistent notifications and Live Activity support
//  Automatically tracks time since last meal and displays in Dynamic Island
//

import Foundation
import SwiftUI
import UserNotifications
import ActivityKit

// MARK: - Fasting State Model
struct FastingState: Codable {
    var lastMealTime: Date?
    var isActive: Bool
    var fastingStartTime: Date?

    var hoursSinceLastMeal: Double? {
        guard let lastMeal = lastMealTime else { return nil }
        return Date().timeIntervalSince(lastMeal) / 3600
    }

    var formattedDuration: String {
        guard let hours = hoursSinceLastMeal else { return "Not fasting" }
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return String(format: "%dh %dm", h, m)
    }
}

// MARK: - Live Activity Attributes
@available(iOS 16.1, *)
struct FastingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var fastingStartTime: Date
        var currentHours: Int
        var currentMinutes: Int
    }

    var fastingGoalHours: Int
}

// MARK: - Fasting Manager
@MainActor
class FastingManager: ObservableObject {
    static let shared = FastingManager()

    @Published var fastingState = FastingState(lastMealTime: nil, isActive: false, fastingStartTime: nil)
    @Published var notificationPermissionGranted = false

    private let userDefaults = UserDefaults.standard
    private let fastingStateKey = "fastingState"
    private let fastingThresholdHours: Double = 12.0 // Consider fasting after 12 hours

    // Check if user has enabled fasting notifications in settings
    // Default to true if not set (matches AppStorage default)
    private var fastingNotificationsEnabled: Bool {
        if userDefaults.object(forKey: "fastingNotificationsEnabled") == nil {
            return true // Default value
        }
        return userDefaults.bool(forKey: "fastingNotificationsEnabled")
    }

    private var updateTimer: Timer?
    private var currentActivity: Any? // Holds Activity<FastingActivityAttributes> on iOS 16.1+

    private init() {
        loadFastingState()
        checkNotificationPermission()
        startMonitoring()
    }

    // MARK: - Persistence
    private func loadFastingState() {
        if let data = userDefaults.data(forKey: fastingStateKey),
           let state = try? JSONDecoder().decode(FastingState.self, from: data) {
            fastingState = state
        }
    }

    private func saveFastingState() {
        if let data = try? JSONEncoder().encode(fastingState) {
            userDefaults.set(data, forKey: fastingStateKey)
        }
    }

    // MARK: - Permission Management
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }

    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                notificationPermissionGranted = granted
            }
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    // MARK: - Meal Tracking
    func recordMeal() {
        let now = Date()
        fastingState.lastMealTime = now
        fastingState.isActive = false
        fastingState.fastingStartTime = nil
        saveFastingState()

        // End fasting notification and Live Activity
        endFastingNotification()
        if #available(iOS 16.1, *) {
            endLiveActivity()
        }
    }

    // MARK: - Monitoring
    func startMonitoring() {
        // Check every minute
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkFastingStatus()
            }
        }

        // Initial check
        Task {
            await checkFastingStatus()
        }
    }

    private func checkFastingStatus() async {
        guard let hours = fastingState.hoursSinceLastMeal else { return }

        // Start fasting tracking if threshold exceeded
        if hours >= fastingThresholdHours && !fastingState.isActive {
            fastingState.isActive = true
            fastingState.fastingStartTime = fastingState.lastMealTime
            saveFastingState()

            // Only start notifications and Live Activity if user has enabled them in settings
            guard fastingNotificationsEnabled else {
                print("⏸️ Fasting notifications disabled in settings")
                return
            }

            // Start persistent notification and Live Activity
            await startFastingNotification()
            if #available(iOS 16.1, *) {
                await startLiveActivity()
            }
        } else if fastingState.isActive {
            // Only update if user has enabled fasting notifications
            guard fastingNotificationsEnabled else { return }

            // Update existing notification and Live Activity
            await updateFastingNotification()
            if #available(iOS 16.1, *) {
                await updateLiveActivity()
            }
        }
    }

    // MARK: - Notifications
    private func startFastingNotification() async {
        guard fastingNotificationsEnabled else {
            print("⏸️ Fasting notifications disabled in settings - not starting notification")
            return
        }

        guard notificationPermissionGranted else {
            _ = await requestNotificationPermission()
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Fasting Active"
        content.body = "You've been fasting for \(fastingState.formattedDuration)"
        content.sound = nil // Silent for persistent notification
        content.categoryIdentifier = "FASTING"
        content.threadIdentifier = "fasting-tracker"

        // Create a repeating notification that updates
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: true) // Update hourly
        let request = UNNotificationRequest(identifier: "fasting-active", content: content, trigger: trigger)

        try? await UNUserNotificationCenter.current().add(request)
        print("✅ Fasting notification started")
    }

    private func updateFastingNotification() async {
        guard notificationPermissionGranted, fastingState.isActive else { return }

        let content = UNMutableNotificationContent()
        content.title = "Fasting Active"
        content.body = "You've been fasting for \(fastingState.formattedDuration)"
        content.sound = nil
        content.categoryIdentifier = "FASTING"
        content.threadIdentifier = "fasting-tracker"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: true)
        let request = UNNotificationRequest(identifier: "fasting-active", content: content, trigger: trigger)

        try? await UNUserNotificationCenter.current().add(request)
    }

    private func endFastingNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["fasting-active"])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["fasting-active"])
    }

    // MARK: - Live Activities (Dynamic Island)
    @available(iOS 16.1, *)
    private func startLiveActivity() async {
        guard fastingNotificationsEnabled else {
            print("⏸️ Fasting notifications disabled in settings - not starting Live Activity")
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("❌ Live Activities not enabled by system")
            return
        }

        guard let startTime = fastingState.fastingStartTime else { return }

        let hours = Int(fastingState.hoursSinceLastMeal ?? 0)
        let minutes = Int(((fastingState.hoursSinceLastMeal ?? 0) - Double(hours)) * 60)

        let attributes = FastingActivityAttributes(fastingGoalHours: 16)
        let contentState = FastingActivityAttributes.ContentState(
            fastingStartTime: startTime,
            currentHours: hours,
            currentMinutes: minutes
        )

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            print("✅ Fasting Live Activity started - will appear in Dynamic Island")
        } catch {
            print("❌ Failed to start Live Activity: \(error)")
        }
    }

    @available(iOS 16.1, *)
    private func updateLiveActivity() async {
        guard let activity = currentActivity as? Activity<FastingActivityAttributes> else { return }
        guard let startTime = fastingState.fastingStartTime else { return }

        let hours = Int(fastingState.hoursSinceLastMeal ?? 0)
        let minutes = Int(((fastingState.hoursSinceLastMeal ?? 0) - Double(hours)) * 60)

        let contentState = FastingActivityAttributes.ContentState(
            fastingStartTime: startTime,
            currentHours: hours,
            currentMinutes: minutes
        )

        await activity.update(using: contentState)
    }

    @available(iOS 16.1, *)
    private func endLiveActivity() {
        Task {
            guard let activity = currentActivity as? Activity<FastingActivityAttributes> else { return }
            await activity.end(dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }

    deinit {
        updateTimer?.invalidate()
    }
}
