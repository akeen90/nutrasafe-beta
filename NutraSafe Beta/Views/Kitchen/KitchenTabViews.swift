//
//  KitchenTabViews.swift
//  NutraSafe Beta
//
//  Kitchen management and expiry tracking system
//  Extracted from ContentView.swift as part of Phase 15 modularization
//

import SwiftUI

// MARK: - Kitchen Tab Main View

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
                        Text("Kitchen")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.primary)
                                .frame(width: 40, height: 40)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // Sub-tab selector
                    KitchenSubTabSelector(selectedTab: $selectedKitchenSubTab)
                        .padding(.horizontal, 16)
                }
                .background(Color(.systemBackground))
                
                // Content based on selected sub-tab
                Group {
                    switch selectedKitchenSubTab {
                    case .expiry:
                        KitchenExpiryView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Kitchen Sub-Tab Selector

struct KitchenSubTabSelector: View {
    @Binding var selectedTab: KitchenTabView.KitchenSubTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(KitchenTabView.KitchenSubTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 14))
                        
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(selectedTab == tab ? .white : .primary)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(
                        selectedTab == tab 
                            ? Color.blue
                            : Color.clear
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }
}

// MARK: - Kitchen Sub Views

struct KitchenExpiryView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Expiry Alerts Summary
                KitchenExpiryAlertsCard()
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                // Critical Expiring Items
                KitchenCriticalExpiryCard()
                    .padding(.horizontal, 16)
                
                // This Week's Expiry
                KitchenWeeklyExpiryCard()
                    .padding(.horizontal, 16)
                
                // Quick Add Item
                KitchenQuickAddCard()
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
        }
    }
}

// MARK: - Kitchen Expiry Alert Cards

struct KitchenExpiryAlertsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expiry Alerts")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("5")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.red)
                    Text("Critical")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("12")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.orange)
                    Text("This week")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("28")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.green)
                    Text("Total items")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct KitchenCriticalExpiryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Critical - Use Today!")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.red)
            
            VStack(spacing: 8) {
                KitchenExpiryItemRow(
                    name: "Greek Yoghurt", 
                    location: "Fridge", 
                    daysLeft: 0,
                    urgency: .critical
                )
                KitchenExpiryItemRow(
                    name: "Chicken Breast", 
                    location: "Fridge", 
                    daysLeft: 1,
                    urgency: .high
                )
                KitchenExpiryItemRow(
                    name: "Spinach", 
                    location: "Fridge", 
                    daysLeft: 2,
                    urgency: .medium
                )
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct KitchenWeeklyExpiryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week's Expiry")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                KitchenExpiryDayRow(day: "Today", count: 3, items: ["Milk", "Yoghurt", "Lettuce"])
                KitchenExpiryDayRow(day: "Tomorrow", count: 2, items: ["Bread", "Bananas"])
                KitchenExpiryDayRow(day: "Thursday", count: 4, items: ["Cheese", "Tomatoes", "Carrots", "Eggs"])
                KitchenExpiryDayRow(day: "Friday", count: 3, items: ["Salmon", "Broccoli", "Mushrooms"])
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Kitchen Expiry Item Management

struct KitchenExpiryItemRow: View {
    let name: String
    let location: String
    let daysLeft: Int
    let urgency: ExpiryUrgency
    
    enum ExpiryUrgency {
        case critical, high, medium, low
        
        var color: Color {
            switch self {
            case .critical: return .red
            case .high: return .orange
            case .medium: return .yellow
            case .low: return .green
            }
        }
        
        func text(for days: Int) -> String {
            switch self {
            case .critical: return "Expires today!"
            default: return "\(days) days left"
            }
        }
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(urgency.color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(location)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(urgency.text(for: daysLeft))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(urgency.color)
        }
        .padding(.vertical, 4)
    }
}

struct KitchenExpiryDayRow: View {
    let day: String
    let count: Int
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(day)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(count) items")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Text(items.joined(separator: ", "))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Kitchen Quick Add Interface

struct KitchenQuickAddCard: View {
    @State private var newItem = ""
    @State private var selectedLocation = "Fridge"
    
    // Hardcoded storage locations for kitchen items
    private let locations = ["Fridge", "Freezer", "Pantry", "Cupboard"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Add Item")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                HStack {
                    TextField("Item name...", text: $newItem)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        // Camera functionality placeholder
                    }) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                }
                
                Picker("Location", selection: $selectedLocation) {
                    ForEach(locations, id: \.self) { location in
                        Text(location).tag(location)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Button("Add Item") {
                    // Add item functionality placeholder
                    addKitchenItem()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func addKitchenItem() {
        print("Adding kitchen item: \(newItem) to \(selectedLocation)")
        // Implementation for adding kitchen item would go here
        newItem = "" // Clear field after adding
    }
}

// MARK: - Preview Support

#if DEBUG
struct KitchenTabView_Previews: PreviewProvider {
    static var previews: some View {
        KitchenTabView(showingSettings: .constant(false))
    }
}
#endif