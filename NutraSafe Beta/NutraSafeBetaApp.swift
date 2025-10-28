import SwiftUI
import Firebase
import UserNotifications
import WidgetKit
import ActivityKit
import StoreKit
#if DEBUG && canImport(StoreKitTest)
import StoreKitTest
#endif

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
        return true
    }

    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo

        // Validate fasting notifications
        if let type = userInfo["type"] as? String, type == "fasting" {
            // Get current active fast session ID from AppStorage
            let activeFastSessionId = UserDefaults.standard.string(forKey: "activeFastSessionId") ?? ""
            let notificationSessionId = userInfo["sessionId"] as? String ?? ""

            // Only show notification if it matches the current active fast session
            if activeFastSessionId.isEmpty || notificationSessionId != activeFastSessionId {
                print("🚫 Suppressing fasting notification - fast is no longer active")
                print("   - Active session: \(activeFastSessionId)")
                print("   - Notification session: \(notificationSessionId)")
                completionHandler([]) // Don't show notification
                return
            }

            print("✅ Showing fasting notification - session matches: \(notificationSessionId)")
        }

        // Show banner even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap (when user taps notification)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        // Check if this is a fasting notification
        if let type = userInfo["type"] as? String, type == "fasting" {
            // Validate session ID before acting on notification
            let activeFastSessionId = UserDefaults.standard.string(forKey: "activeFastSessionId") ?? ""
            let notificationSessionId = userInfo["sessionId"] as? String ?? ""

            if activeFastSessionId.isEmpty || notificationSessionId != activeFastSessionId {
                print("🚫 Ignoring tap on stale fasting notification")
                print("   - Active session: \(activeFastSessionId)")
                print("   - Notification session: \(notificationSessionId)")
                completionHandler()
                return
            }

            print("📱 User tapped valid fasting notification - navigating to Fasting tab")

            // Post notification to trigger navigation to Fasting
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .navigateToFasting, object: nil)
            }
        }

        // Check if this is a use-by notification
        if let type = userInfo["type"] as? String, type == "useBy" {
            print("📱 User tapped use-by notification - navigating to Use By tab")

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
    @StateObject private var workoutManager = WorkoutManager.shared
    @StateObject private var restTimerManager = ExerciseRestTimerManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    
    init() {
        // Initialize StoreKitTest session for reliable local testing in debug builds
        #if DEBUG && canImport(StoreKitTest)
        if #available(iOS 15.0, *) {
            if let storeKitURL = Bundle.main.url(forResource: "NutraSafe", withExtension: "storekit") {
                do {
                    let session = try SKTestSession(configurationFileURL: storeKitURL)
                    session.resetToDefaultState()
                    SKTestSession.default = session
                    print("StoreKitTest: Initialized session with NutraSafe.storekit at \(storeKitURL)")
                } catch {
                    print("StoreKitTest: Failed to initialize with error: \(error)")
                }
            } else {
                print("StoreKitTest: Could not find NutraSafe.storekit in bundle")
            }
        }
        #endif
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
                .environmentObject(workoutManager)
                .environmentObject(restTimerManager)
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
                    await requestNotificationPermission()
                    await clearAppBadge()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                Task {
                    await clearAppBadge()
                }
            }
            .onChange(of: healthKitRingsEnabled) { enabled in
                Task {
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
            print("📱 Notification permission already determined: \(settings.authorizationStatus.rawValue)")
            return
        }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            print("📱 Notification permission requested - granted: \(granted)")
        } catch {
            print("❌ Error requesting notification permission: \(error)")
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
            print("🔔 App badge cleared")
        } catch {
            print("❌ Error clearing badge: \(error)")
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
