import SwiftUI
import Firebase
import UserNotifications
import WidgetKit
import ActivityKit

// Explicit app delegate for proper Firebase initialization and to satisfy swizzler expectations
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        return true
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
    @StateObject private var fastingManager = FastingManager.shared

    var body: some Scene {
        WindowGroup {
            MainAppView()
                .environmentObject(firebaseManager)
                .environmentObject(healthKitManager)
                .environmentObject(workoutManager)
                .environmentObject(restTimerManager)
                .environmentObject(fastingManager)
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

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeString) ?? .system
    }

    var body: some View {
        AuthenticationView()
            .preferredColorScheme(appearanceMode.colorScheme)
            .id(appearanceModeString) // Force view refresh when theme changes
            .onAppear {
                Task {
                    await healthKitManager.requestAuthorization()
                    await requestNotificationPermission()
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
