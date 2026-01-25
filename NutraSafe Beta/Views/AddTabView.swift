import SwiftUI
import Foundation

struct AddTabView: View {
    @Binding var selectedTab: TabItem
    @Binding var isPresented: Bool

    var body: some View {
        AddFoodMainView(
            selectedTab: $selectedTab,
            isPresented: $isPresented,
            onDismiss: {
                isPresented = false
            },
            onComplete: { tab in
                selectedTab = tab
                isPresented = false
            }
        )
        .trackScreen("Add Food")
        .keyboardDismissButton()
    }
}