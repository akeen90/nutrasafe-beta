import SwiftUI
import Foundation

struct AddTabView: View {
    @Binding var selectedTab: TabItem
    
    var body: some View {
        AddFoodMainView(selectedTab: $selectedTab)
    }
}