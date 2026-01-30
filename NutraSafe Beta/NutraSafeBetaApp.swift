import SwiftUI
import Firebase
import UserNotifications
import WidgetKit
import ActivityKit
import StoreKit
import BackgroundTasks

// Explicit app delegate for proper Firebase initialization and to satisfy swizzler expectations
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    // Static property to communicate selected tab to ContentView
    static var selectedTabFromNotification: TabItem?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        // Set notification delegate to handle notification taps
        UNUserNotificationCenter.current().delegate = self

        // Register background tasks for notification refresh
        BackgroundTaskManager.shared.registerBackgroundTasks()

        // Schedule initial background refresh
        BackgroundTaskManager.shared.scheduleNotificationRefresh()

        return true
    }

    // CRIT-7 FIX: Sync pending data before app is terminated
    // This prevents data loss when user adds food then immediately swipes app away
    func applicationWillTerminate(_ application: UIApplication) {
        print("[AppDelegate] CRIT-7: App terminating - forcing sync of pending data")
        // Synchronously flush any pending sync operations
        // We have limited time here, so just mark the need for urgent sync on next launch
        UserDefaults.standard.set(true, forKey: "pendingSyncOnNextLaunch")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastTerminationTime")
    }

    // CRIT-7 FIX: Also handle willResignActive for when app goes to background
    func applicationWillResignActive(_ application: UIApplication) {
        print("[AppDelegate] CRIT-7: App resigning active - triggering background sync")
        // Request background time to complete sync
        var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
        backgroundTaskID = application.beginBackgroundTask(withName: "SyncPendingData") {
            // LOW-10 FIX: Log when iOS terminates background task early for debugging
            print("[AppDelegate] WARNING: Background sync task expired - iOS terminated early. Pending data may not be synced.")
            application.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }

        // Trigger sync with completion handler
        Task {
            await OfflineSyncManager.shared.forceSync()
            // End background task when sync completes
            DispatchQueue.main.async {
                if backgroundTaskID != .invalid {
                    application.endBackgroundTask(backgroundTaskID)
                    backgroundTaskID = .invalid
                }
            }
        }
    }

    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo

        if let type = userInfo["type"] as? String, type == "fasting" {
            let hasPlanContext = userInfo["fastingType"] != nil || userInfo["planId"] != nil
            if !hasPlanContext {
                let activeFastSessionId = UserDefaults.standard.string(forKey: "activeFastSessionId") ?? ""
                let notificationSessionId = userInfo["sessionId"] as? String ?? ""
                if activeFastSessionId.isEmpty || notificationSessionId != activeFastSessionId {
                                        completionHandler([])
                    return
                }
                            }
        }

        // Show banner even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap (when user taps notification)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        // Handle notification actions (snooze, extend, etc.)
        if let type = userInfo["type"] as? String, type == "fasting" {
            FastingNotificationManager.shared.handleNotificationAction(
                identifier: response.actionIdentifier,
                userInfo: userInfo
            )
        }

        // Check if this is a fasting notification
        if let type = userInfo["type"] as? String, type == "fasting" {
            let fastingType = userInfo["fastingType"] as? String ?? ""

            // Extract notification context for confirmation flow
            let planId = userInfo["planId"] as? String ?? ""
            let planName = userInfo["planName"] as? String ?? ""

            // Helper to extract numeric values (notification userInfo stores as NSNumber)
            func getNumber(_ key: String) -> Double? {
                if let val = userInfo[key] as? Double { return val }
                if let val = userInfo[key] as? Int { return Double(val) }
                if let nsNum = userInfo[key] as? NSNumber { return nsNum.doubleValue }
                return nil
            }

            let durationHours = Int(getNumber("durationHours") ?? 16)
            let scheduledStartTime = getNumber("scheduledStartTime")
            let scheduledEndTime = getNumber("scheduledEndTime")

            // Navigate to Fasting tab first
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .navigateToFasting, object: nil)
            }

            // Then trigger confirmation flow with context after navigation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let confirmationInfo: [String: Any] = [
                    "fastingType": fastingType,
                    "planId": planId,
                    "planName": planName,
                    "durationHours": durationHours,
                    "scheduledStartTime": scheduledStartTime ?? Date().timeIntervalSince1970,
                    "scheduledEndTime": scheduledEndTime ?? Date().timeIntervalSince1970
                ]
                NotificationCenter.default.post(
                    name: .fastingConfirmationRequired,
                    object: nil,
                    userInfo: confirmationInfo
                )
            }
        }

        // Check if this is a use-by notification
        if let type = userInfo["type"] as? String, type == "useBy" {
            
            // Set the tab to navigate to
            AppDelegate.selectedTabFromNotification = .useBy

            // Post notification to trigger navigation
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .navigateToUseBy, object: nil)
            }
        }

        completionHandler()
    }
}

@main
struct NutraSafeBetaApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager()
    
    init() {
        // Check for app version change and clear caches if needed
        CacheManager.shared.checkAndClearCachesIfNeeded()

        // Initialize local database and image manager early
        // This ensures the SQLite database is ready for offline search
        // and image mappings are loaded before any views try to use them
        print("🚀 App Init: Initializing local database and image manager...")
        let dbAvailable = LocalDatabaseManager.shared.isAvailable
        let imageCount = LocalFoodImageManager.shared.localImageCount
        print("🚀 App Init: LocalDB available: \(dbAvailable), Local images: \(imageCount)")

        // Debug: print full state of image manager
        LocalFoodImageManager.shared.debugPrintState()

        // Initialize offline data manager for user-generated data
        // This provides offline-first storage for diary entries, Use By items, etc.
        print("🚀 App Init: Initializing offline data manager...")
        OfflineDataManager.shared.initialize()
        print("🚀 App Init: Offline data manager initialized")

        // CRIT-1 FIX: Check if app was terminated with pending sync operations
        // The flag is set in applicationWillTerminate but was never consumed
        if UserDefaults.standard.bool(forKey: "pendingSyncOnNextLaunch") {
            UserDefaults.standard.set(false, forKey: "pendingSyncOnNextLaunch")
            print("🚀 App Init: CRIT-1 - Pending sync detected from previous termination, triggering urgent sync")
            // Trigger sync immediately on next run loop to ensure managers are ready
            DispatchQueue.main.async {
                Task {
                    await OfflineSyncManager.shared.forceSync()
                }
            }
        }
    }

    // Add theme binding at the scene level so changes apply instantly across sheets and overlays
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

    var body: some Scene {
        WindowGroup {
            MainAppView()
                .environmentObject(firebaseManager)
                .environmentObject(healthKitManager)
                .environmentObject(subscriptionManager)
                .keyboardDismissButton()
                .preferredColorScheme(appearanceMode.colorScheme)
        }
    }
}

struct MainAppView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("healthKitRingsEnabled") private var healthKitRingsEnabled = false

    var body: some View {
        AuthenticationView()
            .preferredColorScheme(appearanceMode.colorScheme)
            .onAppear {
                Task {
                    if healthKitRingsEnabled {
                        await healthKitManager.requestAuthorization()
                        await healthKitManager.updateExerciseCalories()
                    } else {
                        await MainActor.run { healthKitManager.exerciseCalories = 0 }
                    }
                    // Don't auto-request notification permission on launch
                    // Let the user choose during onboarding or when they use features that need it
                    await clearAppBadge()

                    // Check and refresh notification queue on app launch
                    await checkAndRefreshNotifications()
                    await prewarmSettingsCache()

                    // Check if local food database needs sync
                    DatabaseSyncManager.shared.syncIfNeeded()

                    // Trigger offline sync for user-generated data
                    OfflineSyncManager.shared.triggerSync()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Clear search cache to ensure fresh data (e.g., verified status changes)
                AlgoliaSearchManager.shared.clearCache()

                // Sync local food database if needed when returning to foreground
                DatabaseSyncManager.shared.syncIfNeeded()

                // Trigger offline sync for user-generated data
                OfflineSyncManager.shared.triggerSync()

                Task {
                    await clearAppBadge()

                    // Check and refresh notification queue when returning from background
                    await checkAndRefreshNotifications()
                }
            }
            .onChange(of: healthKitRingsEnabled) { _, enabled in
                Task<Void, Never> {
                    if enabled {
                        await healthKitManager.requestAuthorization()
                        await healthKitManager.updateExerciseCalories()
                    } else {
                        await MainActor.run { healthKitManager.exerciseCalories = 0 }
                    }
                }
            }
    }

    /// Request notification permissions on app launch
    private func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()

        // Check current status first
        let settings = await center.notificationSettings()

        // Only request if not yet determined (don't bother user if already denied/granted)
        guard settings.authorizationStatus == .notDetermined else {
                        return
        }

        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            // Silently handle authorization errors
        }
    }

    /// Clear app icon badge when app becomes active
    private func clearAppBadge() async {
        let center = UNUserNotificationCenter.current()

        // Clear all delivered notifications from notification center
        center.removeAllDeliveredNotifications()

        // Reset badge count to 0
        do {
            try await center.setBadgeCount(0)
                    } catch {
                    }
    }

    /// Check and refresh notification queue if needed
    private func checkAndRefreshNotifications() async {
        let needsRefresh = await FastingNotificationManager.shared.checkNotificationQueue()
        if needsRefresh {
            do {
                try await FastingNotificationManager.shared.refreshNotificationsForActivePlans()
                            } catch {
                            }
        }
    }

    /// Prewarm settings caches for instant settings load
    /// OFFLINE FIX: Uses timeout to prevent blocking on network issues
    /// Falls back to cached values if Firebase is unavailable
    private func prewarmSettingsCache() async {
        // Check network status first - don't block on network if offline
        guard NetworkMonitor.shared.isConnected else {
            #if DEBUG
            print("[SettingsCache] Offline - using cached values")
            #endif
            return
        }

        let manager = FirebaseManager.shared

        // OFFLINE FIX: Use Task with timeout to prevent blocking UI
        // Timeout after 10 seconds and fall back to cached values
        let timeoutSeconds: UInt64 = 10
        let timeoutNanoseconds = timeoutSeconds * 1_000_000_000

        // Use a struct to wrap the settings result for TaskGroup compatibility
        struct SettingsResult: Sendable {
            let caloricGoal: Int?
            let exerciseGoal: Int?
            let stepGoal: Int?
        }

        // Fetch settings with timeout
        let settings: SettingsResult? = await withTaskGroup(of: SettingsResult?.self) { group in
            group.addTask {
                if let result = try? await manager.getUserSettings() {
                    return SettingsResult(
                        caloricGoal: result.caloricGoal,
                        exerciseGoal: result.exerciseGoal,
                        stepGoal: result.stepGoal
                    )
                }
                return nil
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: timeoutNanoseconds)
                return nil
            }
            // Return first result (either success or nil from timeout)
            if let result = await group.next() {
                group.cancelAll()
                return result
            }
            return nil
        }

        // Fetch macro goals with timeout (in parallel)
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                _ = try? await manager.getMacroGoals()
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: timeoutNanoseconds)
            }
            _ = await group.next()
            group.cancelAll()
        }

        // Only update cache if we got fresh data
        if let settings = settings {
            let caloric = settings.caloricGoal ?? UserDefaults.standard.integer(forKey: "cachedCaloricGoal")
            let exercise = settings.exerciseGoal ?? UserDefaults.standard.integer(forKey: "cachedExerciseGoal")
            let steps = settings.stepGoal ?? UserDefaults.standard.integer(forKey: "cachedStepGoal")
            UserDefaults.standard.set(caloric, forKey: "cachedCaloricGoal")
            UserDefaults.standard.set(exercise, forKey: "cachedExerciseGoal")
            UserDefaults.standard.set(steps, forKey: "cachedStepGoal")
            // Store cache timestamp for UX truth indicator
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "settingsCacheTimestamp")
        } else {
            #if DEBUG
            print("[SettingsCache] Timeout or error - using cached values")
            #endif
        }
    }
}

// MARK: - Supporting Enums for Theme
enum AppearanceMode: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}
