import SwiftUI

struct ContentView: View {
    @EnvironmentObject var watchDataManager: WatchDataManager
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Today's Summary
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }
                .tag(0)
            
            // Quick Add Food
            QuickAddView()
                .tabItem {
                    Label("Add Food", systemImage: "plus.circle")
                }
                .tag(1)
            
            // Nutrition Score
            NutritionScoreView()
                .tabItem {
                    Label("Score", systemImage: "star.circle")
                }
                .tag(2)
            
            // Health Stats
            HealthStatsView()
                .tabItem {
                    Label("Health", systemImage: "heart")
                }
                .tag(3)
        }
        .onAppear {
            // Request data from iPhone app
            connectivityManager.requestTodayData()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchDataManager())
        .environmentObject(WatchConnectivityManager())
}