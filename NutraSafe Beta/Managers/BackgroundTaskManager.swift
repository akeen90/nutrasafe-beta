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

    /// Schedule next background refresh task with retry logic for failed submissions
    func scheduleNotificationRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.notificationRefreshTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60) // 24 hours

        do {
            try BGTaskScheduler.shared.submit(request)
            print("[BackgroundTask] Scheduled notification refresh for 24 hours from now")
        } catch BGTaskScheduler.Error.unavailable {
            print("[BackgroundTask] Background tasks unavailable on this device")
        } catch BGTaskScheduler.Error.tooManyPendingTaskRequests {
            print("[BackgroundTask] Too many pending requests, will retry later")
            // Schedule retry after 1 hour
            DispatchQueue.main.asyncAfter(deadline: .now() + 3600) { [weak self] in
                self?.scheduleNotificationRefresh()
            }
        } catch {
            print("[BackgroundTask] Failed to schedule notification refresh: \(error.localizedDescription)")
        }
    }

    /// Handle background notification refresh task
    private func handleNotificationRefresh(task: BGAppRefreshTask) {
        print("[BackgroundTask] Starting notification refresh task")

        // Schedule next iteration before processing
        scheduleNotificationRefresh()

        // Track the background task for cancellation
        var backgroundTask: Task<Void, Never>?

        // RACE CONDITION FIX: Atomic flag to prevent double completion
        var taskCompleted = false
        let completionLock = NSLock()

        func markComplete(success: Bool) {
            completionLock.lock()
            defer { completionLock.unlock() }
            guard !taskCompleted else { return }
            taskCompleted = true
            task.setTaskCompleted(success: success)
        }

        // Set expiration handler - cancel work and mark task complete
        task.expirationHandler = {
            print("[BackgroundTask] Notification refresh task expired - cancelling")
            backgroundTask?.cancel()
            markComplete(success: false)
        }

        // Timeout protection - complete task before system forces expiration (25 seconds)
        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 25_000_000_000)
            print("[BackgroundTask] Notification refresh task timeout - marking complete")
            markComplete(success: false)
        }

        // RACE CONDITION FIX: Route Task to MainActor to ensure @Published property updates
        // happen on the main thread, preventing "Publishing changes from background threads" crashes
        backgroundTask = Task { @MainActor in
            defer { timeoutTask.cancel() }

            do {
                // Check for cancellation
                guard !Task.isCancelled else { return }

                let needsRefresh = await FastingNotificationManager.shared.checkNotificationQueue()
                if needsRefresh {
                    try await FastingNotificationManager.shared.refreshNotificationsForActivePlans()
                }

                guard !Task.isCancelled else { return }

                do {
                    let items: [UseByInventoryItem] = try await FirebaseManager.shared.getUseByItems()
                    await UseByNotificationManager.shared.refreshAllNotifications(for: items)
                } catch {
                    print("[BackgroundTask] Failed to refresh Use By notifications: \(error.localizedDescription)")
                }

                print("[BackgroundTask] Notification refresh completed successfully")
                markComplete(success: true)
            } catch {
                print("[BackgroundTask] Notification refresh failed: \(error.localizedDescription)")
                markComplete(success: false)
            }
        }
    }

    // MARK: - Database Sync Background Task

    /// Schedule database sync background task with retry logic for failed submissions
    func scheduleDatabaseSync() {
        let request = BGAppRefreshTaskRequest(identifier: Self.databaseSyncTaskId)
        // Schedule for 6 hours from now - balance between freshness and battery
        request.earliestBeginDate = Date(timeIntervalSinceNow: 6 * 60 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("[BackgroundTask] Scheduled database sync for 6 hours from now")
        } catch BGTaskScheduler.Error.unavailable {
            print("[BackgroundTask] Background tasks unavailable on this device")
        } catch BGTaskScheduler.Error.tooManyPendingTaskRequests {
            print("[BackgroundTask] Too many pending requests, will retry later")
            // Schedule retry after 1 hour
            DispatchQueue.main.asyncAfter(deadline: .now() + 3600) { [weak self] in
                self?.scheduleDatabaseSync()
            }
        } catch {
            print("[BackgroundTask] Failed to schedule database sync: \(error.localizedDescription)")
        }
    }

    /// Handle database sync background task
    private func handleDatabaseSync(task: BGAppRefreshTask) {
        print("[BackgroundTask] Starting database sync task")

        // Schedule next iteration before processing
        scheduleDatabaseSync()

        // Track the background task for cancellation
        var backgroundTask: Task<Void, Never>?

        // RACE CONDITION FIX: Atomic flag to prevent double completion
        var taskCompleted = false
        let completionLock = NSLock()

        func markComplete(success: Bool) {
            completionLock.lock()
            defer { completionLock.unlock() }
            guard !taskCompleted else { return }
            taskCompleted = true
            task.setTaskCompleted(success: success)
        }

        // Set expiration handler - cancel work and mark task complete
        task.expirationHandler = {
            print("[BackgroundTask] Database sync task expired - cancelling")
            backgroundTask?.cancel()
            markComplete(success: false)
        }

        // Timeout protection - complete task before system forces expiration (25 seconds)
        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 25_000_000_000)
            print("[BackgroundTask] Database sync task timeout - marking complete")
            markComplete(success: false)
        }

        // RACE CONDITION FIX: Route Task to MainActor to ensure any @Published property updates
        // in the managers happen on the main thread
        backgroundTask = Task { @MainActor in
            defer { timeoutTask.cancel() }

            guard !Task.isCancelled else { return }

            // Force a food database sync (server -> client)
            await DatabaseSyncManager.shared.forceSync()

            guard !Task.isCancelled else { return }

            // Force an offline data sync (client -> server)
            // This pushes any pending user-generated data to Firebase
            await OfflineSyncManager.shared.forceSync()

            print("[BackgroundTask] Database sync completed successfully")
            markComplete(success: true)
        }
    }
}
