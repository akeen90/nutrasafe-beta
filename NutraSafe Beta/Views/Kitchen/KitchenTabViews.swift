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
    @State private var selectedFilter: ExpiryFilter = .all

    enum ExpiryFilter: String, CaseIterable {
        case all = "All Items"
        case expiring = "Expiring Soon"
        case expired = "Expired"

        var color: Color {
            switch self {
            case .all: return .blue
            case .expiring: return .orange
            case .expired: return .red
            }
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Smart Summary Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Smart Inventory")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Track freshness & reduce waste")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: {}) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                            .frame(width: 36, height: 36)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }

                    Button(action: {}) {
                        Image(systemName: "plus")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                            .frame(width: 36, height: 36)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }

            // Status Cards Row
            HStack(spacing: 12) {
                StatusCard(
                    title: "Use Today",
                    count: 3,
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    subtitle: "Expires today"
                )

                StatusCard(
                    title: "This Week",
                    count: 8,
                    icon: "clock.fill",
                    color: .orange,
                    subtitle: "Use soon"
                )

                StatusCard(
                    title: "Fresh",
                    count: 42,
                    icon: "checkmark.circle.fill",
                    color: .green,
                    subtitle: "Good to go"
                )
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatusCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)

                Text(String(count))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
            }

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)

            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

struct KitchenCriticalExpiryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Expiring Today", systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.red)

                Spacer()

                Button("View All") {
                    // Action
                }
                .font(.system(size: 14))
                .foregroundColor(.blue)
            }

            VStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { index in
                    ModernExpiryRow(
                        name: ["Greek Yoghurt", "Chicken Breast", "Baby Spinach"][index],
                        brand: ["Fage", "Organic Valley", "Fresh Express"][index],
                        location: "Fridge",
                        daysLeft: index,
                        quantity: ["2 cups", "1.5 lbs", "5 oz bag"][index]
                    )

                    if index < 2 {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct KitchenWeeklyExpiryCard: View {
    @State private var expandedDays: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("This Week", systemImage: "calendar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.orange)

                Spacer()

                Text("8 items")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 0) {
                ForEach(["Tomorrow", "Wednesday", "Thursday", "Friday"], id: \.self) { day in
                    VStack(spacing: 0) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if expandedDays.contains(day) {
                                    expandedDays.remove(day)
                                } else {
                                    expandedDays.insert(day)
                                }
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(day)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.primary)

                                    Text(day == "Tomorrow" ? "2 items" : day == "Wednesday" ? "1 item" : "3 items")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: expandedDays.contains(day) ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(PlainButtonStyle())

                        if expandedDays.contains(day) {
                            VStack(spacing: 0) {
                                Divider()

                                ForEach(0..<2, id: \.self) { index in
                                    HStack {
                                        Circle()
                                            .fill(Color.orange.opacity(0.2))
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Image(systemName: "leaf")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.orange)
                                            )

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(index == 0 ? "Organic Milk" : "Whole Wheat Bread")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.primary)

                                            Text(index == 0 ? "1/2 gallon" : "1 loaf")
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        Text("Fridge")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color(.systemGray5))
                                            .cornerRadius(6)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)

                                    if index < 1 {
                                        Divider()
                                            .padding(.leading, 44)
                                    }
                                }
                            }
                            .transition(.opacity)
                        }

                        if day != "Friday" {
                            Divider()
                        }
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Kitchen Expiry Item Management

struct ModernExpiryRow: View {
    let name: String
    let brand: String
    let location: String
    let daysLeft: Int
    let quantity: String

    private var urgencyColor: Color {
        switch daysLeft {
        case 0: return .red
        case 1...2: return .orange
        case 3...7: return .yellow
        default: return .green
        }
    }

    private var urgencyText: String {
        switch daysLeft {
        case 0: return "Expires today"
        case 1: return "Tomorrow"
        case 2...7: return "\(daysLeft) days"
        default: return "\(daysLeft) days"
        }
    }

    private var urgencyIcon: String {
        switch daysLeft {
        case 0: return "exclamationmark.circle.fill"
        case 1...2: return "clock.fill"
        default: return "checkmark.circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(urgencyColor.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: urgencyIcon)
                    .font(.system(size: 16))
                    .foregroundColor(urgencyColor)
            }

            // Item Details
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Text(brand)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    Text(quantity)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Location & Urgency
            VStack(alignment: .trailing, spacing: 4) {
                Text(urgencyText)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(urgencyColor)

                Text(location)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// Removed KitchenExpiryDayRow - replaced with expandable day sections in KitchenWeeklyExpiryCard

// MARK: - Kitchen Quick Add Interface

struct KitchenQuickAddCard: View {
    @State private var showingAddSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Quick Actions", systemImage: "bolt.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)

                Spacer()
            }

            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "barcode.viewfinder",
                    title: "Scan Item",
                    subtitle: "Add by barcode",
                    color: .blue,
                    action: {
                        // Scan barcode action
                    }
                )

                QuickActionButton(
                    icon: "camera.fill",
                    title: "Photo Receipt",
                    subtitle: "Import items",
                    color: .green,
                    action: {
                        // Photo receipt action
                    }
                )

                QuickActionButton(
                    icon: "plus.circle.fill",
                    title: "Manual Add",
                    subtitle: "Type details",
                    color: .purple,
                    action: {
                        showingAddSheet = true
                    }
                )
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showingAddSheet) {
            AddKitchenItemSheet()
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.1))
                    .cornerRadius(10)

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AddKitchenItemSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var itemName = ""
    @State private var brand = ""
    @State private var quantity = ""
    @State private var location = "Fridge"
    @State private var expiryDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days from now

    private let locations = ["Fridge", "Freezer", "Pantry", "Cupboard", "Counter"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    TextField("Item name", text: $itemName)
                    TextField("Brand (optional)", text: $brand)
                    TextField("Quantity", text: $quantity)
                }

                Section(header: Text("Storage")) {
                    Picker("Location", selection: $location) {
                        ForEach(locations, id: \.self) { loc in
                            Text(loc).tag(loc)
                        }
                    }

                    DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Add item logic
                        dismiss()
                    }) {
                        Text("Add")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .disabled(itemName.isEmpty)
                }
            }
        }
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