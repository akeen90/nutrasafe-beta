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

    private init() {}

    /// Register background tasks on app launch
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.notificationRefreshTaskId,
            using: nil
        ) { task in
            self.handleNotificationRefresh(task: task as! BGAppRefreshTask)
        }

        #if DEBUG
        print("✅ Background tasks registered: \(Self.notificationRefreshTaskId)")
        #endif
    }

    /// Schedule next background refresh task
    func scheduleNotificationRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.notificationRefreshTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60) // 24 hours

        do {
            try BGTaskScheduler.shared.submit(request)
            #if DEBUG
            print("📅 Background refresh scheduled for \(request.earliestBeginDate!)")
            #endif
        } catch {
            #if DEBUG
            print("❌ Could not schedule background refresh: \(error)")
            #endif
        }
    }

    /// Handle background notification refresh task
    private func handleNotificationRefresh(task: BGAppRefreshTask) {
        #if DEBUG
        print("⏰ Background notification refresh task started")
        #endif

        // Schedule next iteration before processing
        scheduleNotificationRefresh()

        // Set expiration handler
        task.expirationHandler = {
            #if DEBUG
            print("⚠️ Background task expired")
            #endif
        }

        // Execute refresh asynchronously
        Task {
            do {
                let needsRefresh = await FastingNotificationManager.shared.checkNotificationQueue()
                if needsRefresh {
                    try await FastingNotificationManager.shared.refreshNotificationsForActivePlans()
                }

                do {
                    let items: [UseByInventoryItem] = try await FirebaseManager.shared.getUseByItems()
                    await UseByNotificationManager.shared.refreshAllNotifications(for: items)
                } catch {
                    #if DEBUG
                    print("⚠️ Failed to refresh Use By notifications: \(error)")
                    #endif
                }

                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
    }
}
