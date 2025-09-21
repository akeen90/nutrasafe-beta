import SwiftUI
import Foundation

struct KitchenTabView: View {
    @Binding var showingSettings: Bool
    @State private var selectedKitchenSubTab: KitchenSubTab = .expiry
    
    enum KitchenSubTab: String, CaseIterable {
        case expiry = "Expiry"
        
        var icon: String {
            switch self {
            case .expiry: return "clock.arrow.circlepath"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Text(StringConstants.kitchenTabTitle)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: StringConstants.gearshapeFill)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                                .standardTouchTarget()
                                .background(
                                    RoundedRectangle(cornerRadius: 12 + 2)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                )
                        }
                        .buttonStyle(SpringyButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // Sub-tab Picker
                    HStack(spacing: 0) {
                        ForEach(KitchenSubTab.allCases, id: \.self) { tab in
                            Button(action: {
                                selectedKitchenSubTab = tab
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: tab.icon)
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    Text(tab.rawValue)
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(selectedKitchenSubTab == tab ? .blue : .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .background(
                                Rectangle()
                                    .fill(selectedKitchenSubTab == tab ? .blue.opacity(0.1) : .clear)
                            )
                        }
                    }
                    .background(.ultraThinMaterial)
                }
                
                // Placeholder for full KitchenTabView implementation
                Text("KitchenTabView modularization in progress...")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .padding()
                
                Spacer()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}