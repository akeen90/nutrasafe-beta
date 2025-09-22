import SwiftUI
import Firebase

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

    var body: some Scene {
        WindowGroup {
            MainAppView()
                .environmentObject(firebaseManager)
                .environmentObject(healthKitManager)
                .environmentObject(workoutManager)
                .environmentObject(restTimerManager)
        }
    }
}

struct MainAppView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    var body: some View {
        ContentView()
            .onAppear {
                Task { await healthKitManager.requestAuthorization() }
            }
    }
}
