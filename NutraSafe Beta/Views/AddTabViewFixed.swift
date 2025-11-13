import SwiftUI
import Foundation

// Safety-hardened wrapper for AddFoodMainView to prevent cross-loading between Diary and Use By.
// Use this in place of AddTabView when presenting the Add tab.
struct AddTabViewFixed: View {
    @Binding var selectedTab: TabItem
    @Binding var isPresented: Bool
    var sourceDestination: AddFoodMainView.AddDestination? = nil

    var body: some View {
        let dest = determineDestination() ?? .diary
        AddFoodMainView(
            selectedTab: $selectedTab,
            sourceDestination: dest,
            isPresented: $isPresented,
            onDismiss: {
                isPresented = false
            },
            onComplete: { tab in
                selectedTab = tab
                isPresented = false
            }
        )
        .id(dest)
        .onAppear {
            // Clear the preselected destination after use to avoid leakage across sessions
            UserDefaults.standard.removeObject(forKey: "preselectedDestination")
        }
    }

    private func determineDestination() -> AddFoodMainView.AddDestination? {
        // Prioritize explicit sourceDestination over UserDefaults
        if let explicit = sourceDestination {
            return explicit
        }

        // If a preselected meal type exists, this add flow originated from Diary.
        // Force destination to .diary to prevent stale Use By state from leaking in.
        if UserDefaults.standard.string(forKey: "preselectedMealType") != nil {
            return .diary
        }

        // Check UserDefaults only when no explicit source
        if let preselected = UserDefaults.standard.string(forKey: "preselectedDestination") {
            if preselected == "Use By" {
                return .useBy
            }
        }

        // Default to diary
        return .diary
    }
}