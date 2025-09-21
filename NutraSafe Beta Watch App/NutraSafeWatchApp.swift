import SwiftUI

@main
struct NutraSafe_Beta_Watch_AppApp: App {
    @StateObject private var watchDataManager = WatchDataManager()
    @StateObject private var connectivityManager = WatchConnectivityManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(watchDataManager)
                .environmentObject(connectivityManager)
                .onAppear {
                    connectivityManager.startSession()
                }
        }
    }
}