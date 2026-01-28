//
//  BackgroundTaskManager.swift
//  NutraSafe Beta
//
//  Created by Claude Code
//  Manages background tasks for automatic notification refresh
//

import Foundation
import BackgroundTasks
import UIKit

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    static let notificationRefreshTaskId = "com.nutrasafe.refresh-notifications"
    static let databaseSyncTaskId = "com.nutrasafe.sync-database"

    private init() {}

    /// Register background tasks on app launch
    func registerBackgroundTasks() {
        // Register notification refresh task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.notificationRefreshTaskId,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handleNotificationRefresh(task: refreshTask)
        }

        // Register database sync task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.databaseSyncTaskId,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handleDatabaseSync(task: refreshTask)
        }
    }

    /// Schedule next background refresh task
    func scheduleNotificationRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.notificationRefreshTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60) // 24 hours

        do {
            try BGTaskScheduler.shared.submit(request)
                    } catch {
                    }
    }

    /// Handle background notification refresh task
    private func handleNotificationRefresh(task: BGAppRefreshTask) {

        // Schedule next iteration before processing
        scheduleNotificationRefresh()

        // Set expiration handler
        task.expirationHandler = {
                    }

        // RACE CONDITION FIX: Route Task to MainActor to ensure @Published property updates
        // happen on the main thread, preventing "Publishing changes from background threads" crashes
        Task { @MainActor in
            do {
                let needsRefresh = await FastingNotificationManager.shared.checkNotificationQueue()
                if needsRefresh {
                    try await FastingNotificationManager.shared.refreshNotificationsForActivePlans()
                }

                do {
                    let items: [UseByInventoryItem] = try await FirebaseManager.shared.getUseByItems()
                    await UseByNotificationManager.shared.refreshAllNotifications(for: items)
                } catch {
                                    }

                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
    }

    // MARK: - Database Sync Background Task

    /// Schedule database sync background task
    func scheduleDatabaseSync() {
        let request = BGAppRefreshTaskRequest(identifier: Self.databaseSyncTaskId)
        // Schedule for 6 hours from now - balance between freshness and battery
        request.earliestBeginDate = Date(timeIntervalSinceNow: 6 * 60 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Task scheduling failed - will sync on next app launch instead
        }
    }

    /// Handle database sync background task
    private func handleDatabaseSync(task: BGAppRefreshTask) {
        // Schedule next iteration before processing
        scheduleDatabaseSync()

        // Set expiration handler
        task.expirationHandler = {
            // Task expired - will retry next scheduled time
        }

        // RACE CONDITION FIX: Route Task to MainActor to ensure any @Published property updates
        // in the managers happen on the main thread
        Task { @MainActor in
            // Force a food database sync (server -> client)
            await DatabaseSyncManager.shared.forceSync()

            // Force an offline data sync (client -> server)
            // This pushes any pending user-generated data to Firebase
            await OfflineSyncManager.shared.forceSync()

            task.setTaskCompleted(success: true)
        }
    }
}
