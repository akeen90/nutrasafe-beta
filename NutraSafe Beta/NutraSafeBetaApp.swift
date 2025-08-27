import SwiftUI
import Firebase

@main
struct NutraSafeBetaApp: App {
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(firebaseManager)
        }
    }
}