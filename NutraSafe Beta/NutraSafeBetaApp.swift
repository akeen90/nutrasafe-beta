import SwiftUI
import Firebase

@main
struct NutraSafeBetaApp: App {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var workoutManager = WorkoutManager.shared
    @StateObject private var restTimerManager = ExerciseRestTimerManager()

    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

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
                Task {
                    await healthKitManager.requestAuthorization()
                }
            }
    }
}