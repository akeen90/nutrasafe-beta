import SwiftUI
import Foundation

struct CustomTabBar: View {
    @Binding var selectedTab: TabItem
    
    var body: some View {
        HStack {
            ForEach(TabItem.allCases, id: \.self) { tab in
                if tab == .add {
                    // Center Plus Button
                    Button(action: {
                        selectedTab = .add
                    }) {
                        ZStack {
                            Circle()
                                .fill(.blue)
                                .frame(width: 56, height: 56)
                                .shadow(color: .blue.opacity(0.3), 
                                       radius: 8, x: 0, y: 4)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .scaleEffect(selectedTab == .add ? 1.1 : 1.0)
                    .animation(.spring(response: 0.5, 
                                     dampingFraction: 0.7), 
                              value: selectedTab == .add)
                } else {
                    // Regular Tab Button
                    Button(action: {
                        selectedTab = tab
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: selectedTab == tab ? .semibold : .medium))
                                .foregroundColor(selectedTab == tab ? .blue : .gray)
                            
                            Text(tab.title)
                                .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .medium))
                                .foregroundColor(selectedTab == tab ? .blue : .gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .scaleEffect(selectedTab == tab ? 1.05 : 1.0)
                    .animation(.spring(response: 0.5, 
                                     dampingFraction: 0.7), 
                              value: selectedTab == tab)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), 
                       radius: 10, x: 0, y: -2)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}