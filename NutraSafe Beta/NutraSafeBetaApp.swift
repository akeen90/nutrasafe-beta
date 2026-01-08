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
                    #if DEBUG
                    print("🚫 Suppressing fasting notification - fast is no longer active")
                    print("   - Active session: \(activeFastSessionId)")
                    print("   - Notification session: \(notificationSessionId)")
                    #endif
                    completionHandler([])
                    return
                }
                #if DEBUG
                print("✅ Showing fasting notification - session matches: \(notificationSessionId)")
                #endif
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
            let durationHours = userInfo["durationHours"] as? Int ?? 16
            let scheduledStartTime = userInfo["scheduledStartTime"] as? TimeInterval
            let scheduledEndTime = userInfo["scheduledEndTime"] as? TimeInterval

            #if DEBUG
            print("📱 Fasting notification tapped:")
            print("   - Type: \(fastingType)")
            print("   - Plan: \(planName) (\(durationHours)h)")
            if let startTime = scheduledStartTime {
                print("   - Scheduled start: \(Date(timeIntervalSince1970: startTime))")
            }
            #endif

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
            #if DEBUG
            print("📱 User tapped use-by notification - navigating to Use By tab")
            #endif

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
    }

    // Add theme binding at the scene level so changes apply instantly across sheets and overlays
    @AppStorage("appearanceMode") private var appearanceModeString: String = AppearanceMode.system.rawValue
    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeString) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            MainAppView()
                .environmentObject(firebaseManager)
                .environmentObject(healthKitManager)
                .environmentObject(subscriptionManager)
                .preferredColorScheme(appearanceMode.colorScheme)
        }
    }
}

// MARK: - Widget Bundle for Live Activities
@available(iOS 16.1, *)
struct FastingWidgets: WidgetBundle {
    var body: some Widget {
        FastingLiveActivity()
    }
}

struct MainAppView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @AppStorage("appearanceMode") private var appearanceModeString: String = AppearanceMode.system.rawValue
    @AppStorage("healthKitRingsEnabled") private var healthKitRingsEnabled = false

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeString) ?? .system
    }

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
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Clear search cache to ensure fresh data (e.g., verified status changes)
                AlgoliaSearchManager.shared.clearCache()

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
            #if DEBUG
            print("📱 Notification permission already determined: \(settings.authorizationStatus.rawValue)")
            #endif
            return
        }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            #if DEBUG
            print("📱 Notification permission requested - granted: \(granted)")
            #endif
        } catch {
            #if DEBUG
            print("❌ Error requesting notification permission: \(error)")
            #endif
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
            #if DEBUG
            print("🔔 App badge cleared")
            #endif
        } catch {
            #if DEBUG
            print("❌ Error clearing badge: \(error)")
            #endif
        }
    }

    /// Check and refresh notification queue if needed
    private func checkAndRefreshNotifications() async {
        let needsRefresh = await FastingNotificationManager.shared.checkNotificationQueue()
        if needsRefresh {
            do {
                try await FastingNotificationManager.shared.refreshNotificationsForActivePlans()
                #if DEBUG
                print("✅ Notification queue refreshed on foreground")
                #endif
            } catch {
                #if DEBUG
                print("❌ Failed to refresh notifications: \(error)")
                #endif
            }
        }
    }

    /// Prewarm settings caches for instant settings load
    private func prewarmSettingsCache() async {
        let manager = FirebaseManager.shared
        do {
            async let settingsTask = manager.getUserSettings()
            async let macroTask = manager.getMacroGoals()
            let settings = try await settingsTask
            _ = try await macroTask
            let caloric = settings.caloricGoal ?? UserDefaults.standard.integer(forKey: "cachedCaloricGoal")
            let exercise = settings.exerciseGoal ?? UserDefaults.standard.integer(forKey: "cachedExerciseGoal")
            let steps = settings.stepGoal ?? UserDefaults.standard.integer(forKey: "cachedStepGoal")
            UserDefaults.standard.set(caloric, forKey: "cachedCaloricGoal")
            UserDefaults.standard.set(exercise, forKey: "cachedExerciseGoal")
            UserDefaults.standard.set(steps, forKey: "cachedStepGoal")
            #if DEBUG
            print("🔥 Settings cache prewarmed")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ Failed to prewarm settings cache: \(error)")
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
