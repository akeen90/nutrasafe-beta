import SwiftUI
import Foundation

struct AddTabView: View {
    @Binding var selectedTab: TabItem
    @Environment(\.dismiss) private var dismiss
    var sourceDestination: AddFoodMainView.AddDestination? = nil

    var body: some View {
        AddFoodMainView(
            selectedTab: $selectedTab,
            sourceDestination: determineDestination(),
            onDismiss: {
                dismiss()
            },
            onComplete: { tab in
                selectedTab = tab
                dismiss()
            }
        )
        // Force re-init when desired default destination changes to avoid sticky last state
        .id(determineDestination() ?? .diary)
        .onAppear {
            // Clear the preselected destination after using it
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