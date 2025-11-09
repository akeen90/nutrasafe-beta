import SwiftUI
import Foundation

struct AddTabView: View {
    @Binding var selectedTab: TabItem
    @Environment(\.dismiss) private var dismiss
    var sourceDestination: AddFoodMainView.AddDestination? = nil
    @State private var resolvedDestination: AddFoodMainView.AddDestination? = nil

    var body: some View {
        let dest = resolvedDestination ?? determineDestination() ?? .diary
        AddFoodMainView(
            selectedTab: $selectedTab,
            sourceDestination: dest,
            onDismiss: {
                dismiss()
            },
            onComplete: { tab in
                selectedTab = tab
                dismiss()
            }
        )
        // Stabilize identity using the initially resolved destination to prevent mid-session reinit
        .id(dest)
        .onAppear {
            // Capture destination once per presentation to avoid identity flip after clearing defaults
            if resolvedDestination == nil {
                resolvedDestination = determineDestination()
            }
            // Clear the preselected destination after capturing it
            UserDefaults.standard.removeObject(forKey: "preselectedDestination")
        }
    }

    private func determineDestination() -> AddFoodMainView.AddDestination? {
        // Prefer explicit preselection
        if let preselected = UserDefaults.standard.string(forKey: "preselectedDestination") {
            if preselected == "Use By" {
                return .useBy
            }
        }
        // If no preselection, default based on origin: Use Diary for all non-Use By pages
        return sourceDestination ?? .diary
    }
}