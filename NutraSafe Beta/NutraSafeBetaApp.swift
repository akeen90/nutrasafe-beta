import SwiftUI
import Firebase

@main
struct NutraSafeBetaApp: App {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    
    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(firebaseManager)
                .environmentObject(healthKitManager)
                .onAppear {
                    Task {
                        await healthKitManager.requestAuthorization()
                    }
                }
        }
    }
}