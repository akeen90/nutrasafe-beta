import SwiftUI
import Foundation

struct AddTabView: View {
    @Binding var selectedTab: TabItem
    var sourceDestination: AddFoodMainView.AddDestination? = nil

    var body: some View {
        AddFoodMainView(
            selectedTab: $selectedTab,
            sourceDestination: determineDestination()
        )
        .onAppear {
            // Clear the preselected destination after using it
            UserDefaults.standard.removeObject(forKey: "preselectedDestination")
        }
    }

    private func determineDestination() -> AddFoodMainView.AddDestination? {
        // Check if there's a preselected destination from Kitchen or other tabs
        if let preselected = UserDefaults.standard.string(forKey: "preselectedDestination") {
            if preselected == "Kitchen" {
                return .kitchen
            }
        }
        // Otherwise use the passed sourceDestination
        return sourceDestination
    }
}