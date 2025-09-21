//
//  EnhancedKitchenTabViews.swift
//  NutraSafe Beta
//
//  Enhanced kitchen management and expiry tracking system
//  Professional design with intuitive categorization
//

import SwiftUI

// MARK: - Kitchen Tab Main View

struct EnhancedKitchenTabView: View {
    @Binding var showingSettings: Bool
    @State private var selectedKitchenSubTab: KitchenSubTab = .pantry
    @State private var showingAddItem = false
    @State private var searchText = ""

    enum KitchenSubTab: String, CaseIterable {
        case pantry = "Pantry"
        case expiry = "Expiring"
        case shopping = "Shopping"

        var icon: String {
            switch self {
            case .pantry: return "cabinet.fill"
            case .expiry: return "exclamationmark.triangle.fill"
            case .shopping: return "cart.fill"
            }
        }

        var description: String {
            switch self {
            case .pantry: return "All Items"
            case .expiry: return "Track Dates"
            case .shopping: return "Need to Buy"
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Enhanced Header
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Kitchen Manager")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)

                            Text("Track your food inventory")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        HStack(spacing: 12) {
                            Button(action: {
                                showingAddItem = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                            }

                            Button(action: {
                                showingSettings = true
                            }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.primary)
                                    .frame(width: 44, height: 44)
                                    .background(Color(.systemGray6))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)

                        TextField("Search items...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())

                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)

                    // Enhanced Sub-tab selector
                    EnhancedKitchenSubTabSelector(selectedTab: $selectedKitchenSubTab)
                }
                .background(Color(.systemBackground))

                // Content based on selected sub-tab
                Group {
                    switch selectedKitchenSubTab {
                    case .pantry:
                        EnhancedPantryView(searchText: searchText)
                    case .expiry:
                        EnhancedExpiryTrackerView(searchText: searchText)
                    case .shopping:
                        EnhancedShoppingListView(searchText: searchText)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(.systemGray6).opacity(0.3))
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddItem) {
                AddKitchenItemSheet()
            }
        }
    }
}

// MARK: - Enhanced Sub-Tab Selector

struct EnhancedKitchenSubTabSelector: View {
    @Binding var selectedTab: EnhancedKitchenTabView.KitchenSubTab

    var body: some View {
        HStack(spacing: 8) {
            ForEach(EnhancedKitchenTabView.KitchenSubTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring()) {
                        selectedTab = tab
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .semibold))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(tab.rawValue)
                                .font(.system(size: 14, weight: .semibold))

                            Text(tab.description)
                                .font(.system(size: 10))
                                .opacity(0.7)
                        }
                    }
                    .foregroundColor(selectedTab == tab ? .white : .primary.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedTab == tab
                                ? LinearGradient(colors: [.blue, .blue.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.clear],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Enhanced Expiry Tracker View

struct EnhancedExpiryTrackerView: View {
    let searchText: String
    @State private var selectedCategory: ExpiryCategory = .today

    enum ExpiryCategory: String, CaseIterable {
        case expired = "Expired"
        case today = "Use Today"
        case tomorrow = "Tomorrow"
        case thisWeek = "This Week"
        case nextWeek = "Next Week"
        case later = "Later"

        var color: Color {
            switch self {
            case .expired: return .red
            case .today: return .orange
            case .tomorrow: return .yellow
            case .thisWeek: return .blue
            case .nextWeek: return .green
            case .later: return .gray
            }
        }

        var icon: String {
            switch self {
            case .expired: return "xmark.circle.fill"
            case .today: return "exclamationmark.circle.fill"
            case .tomorrow: return "clock.fill"
            case .thisWeek: return "calendar.circle.fill"
            case .nextWeek: return "calendar.badge.plus"
            case .later: return "calendar"
            }
        }

        var urgencyText: String {
            switch self {
            case .expired: return "Remove immediately"
            case .today: return "Use by end of day"
            case .tomorrow: return "24-48 hours left"
            case .thisWeek: return "2-7 days remaining"
            case .nextWeek: return "8-14 days remaining"
            case .later: return "More than 2 weeks"
            }
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Overview Dashboard
                ExpiryOverviewDashboard()
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                // Category Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ExpiryCategory.allCases, id: \.self) { category in
                            ExpiryPillButton(
                                category: category,
                                isSelected: selectedCategory == category,
                                count: getItemCount(for: category)
                            ) {
                                withAnimation {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // Category Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: selectedCategory.icon)
                            .font(.system(size: 20))
                            .foregroundColor(selectedCategory.color)

                        Text(selectedCategory.rawValue)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)

                        Spacer()

                        Text(selectedCategory.urgencyText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)

                // Items List
                VStack(spacing: 12) {
                    ForEach(getItems(for: selectedCategory)) { item in
                        EnhancedExpiryItemCard(item: item)
                    }
                }
                .padding(.horizontal, 16)

                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
        }
    }

    private func getItemCount(for category: ExpiryCategory) -> Int {
        // Mock data - replace with actual data
        switch category {
        case .expired: return 2
        case .today: return 3
        case .tomorrow: return 4
        case .thisWeek: return 8
        case .nextWeek: return 12
        case .later: return 15
        }
    }

    private func getItems(for category: ExpiryCategory) -> [KitchenItem] {
        // Mock data - replace with actual data from your model
        switch category {
        case .expired:
            return [
                KitchenItem(name: "Greek Yogurt", location: .fridge, expiryDate: Date().addingTimeInterval(-86400), quantity: "500g", category: "Dairy"),
                KitchenItem(name: "Strawberries", location: .fridge, expiryDate: Date().addingTimeInterval(-172800), quantity: "250g", category: "Fruit")
            ]
        case .today:
            return [
                KitchenItem(name: "Chicken Breast", location: .fridge, expiryDate: Date(), quantity: "400g", category: "Meat"),
                KitchenItem(name: "Baby Spinach", location: .fridge, expiryDate: Date(), quantity: "200g", category: "Vegetables"),
                KitchenItem(name: "Whole Milk", location: .fridge, expiryDate: Date(), quantity: "1L", category: "Dairy")
            ]
        case .tomorrow:
            return [
                KitchenItem(name: "Sourdough Bread", location: .pantry, expiryDate: Date().addingTimeInterval(86400), quantity: "1 loaf", category: "Bakery"),
                KitchenItem(name: "Avocados", location: .pantry, expiryDate: Date().addingTimeInterval(86400), quantity: "3 pieces", category: "Fruit"),
                KitchenItem(name: "Mushrooms", location: .fridge, expiryDate: Date().addingTimeInterval(86400), quantity: "250g", category: "Vegetables"),
                KitchenItem(name: "Fresh Mozzarella", location: .fridge, expiryDate: Date().addingTimeInterval(86400), quantity: "125g", category: "Dairy")
            ]
        default:
            return []
        }
    }
}

// MARK: - Expiry Overview Dashboard

struct ExpiryOverviewDashboard: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Inventory Status")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                Text("\(Date(), style: .date)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                StatCard(
                    title: "Total Items",
                    value: "44",
                    icon: "cube.box.fill",
                    color: .blue,
                    trend: "+3 this week"
                )

                StatCard(
                    title: "Expiring Soon",
                    value: "7",
                    icon: "exclamationmark.triangle.fill",
                    color: .orange,
                    trend: "Next 3 days"
                )

                StatCard(
                    title: "Fresh",
                    value: "31",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    trend: "Good to go"
                )
            }

            // Quick Actions
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Scan Receipt",
                    icon: "doc.text.viewfinder",
                    color: .purple
                )

                QuickActionButton(
                    title: "Meal Plan",
                    icon: "calendar.badge.plus",
                    color: .indigo
                )

                QuickActionButton(
                    title: "Waste Log",
                    icon: "trash.circle",
                    color: .red
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)

                Spacer()
            }

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            Text(trend)
                .font(.system(size: 9))
                .foregroundColor(color)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        Button(action: {
            // Action here
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
        }
    }
}

// MARK: - Expiry Pill Button

struct ExpiryPillButton: View {
    let category: EnhancedExpiryTrackerView.ExpiryCategory
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 12))

                Text(category.rawValue)
                    .font(.system(size: 13, weight: .medium))

                Text("\(count)")
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color.white.opacity(0.3) : category.color.opacity(0.2))
                    )
            }
            .foregroundColor(isSelected ? .white : category.color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? category.color : category.color.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(category.color, lineWidth: isSelected ? 0 : 1)
            )
        }
    }
}

// MARK: - Enhanced Expiry Item Card

struct EnhancedExpiryItemCard: View {
    let item: KitchenItem
    @State private var isExpanded = false

    var daysUntilExpiry: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: item.expiryDate).day ?? 0
    }

    var urgencyColor: Color {
        if daysUntilExpiry < 0 { return .red }
        if daysUntilExpiry == 0 { return .orange }
        if daysUntilExpiry == 1 { return .yellow }
        if daysUntilExpiry <= 3 { return .blue }
        if daysUntilExpiry <= 7 { return .green }
        return .gray
    }

    var expiryText: String {
        if daysUntilExpiry < 0 {
            return "Expired \(abs(daysUntilExpiry)) day\(abs(daysUntilExpiry) == 1 ? "" : "s") ago"
        } else if daysUntilExpiry == 0 {
            return "Expires today"
        } else if daysUntilExpiry == 1 {
            return "Expires tomorrow"
        } else {
            return "Expires in \(daysUntilExpiry) days"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                // Item Image/Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(urgencyColor.opacity(0.1))
                        .frame(width: 50, height: 50)

                    Image(systemName: item.categoryIcon)
                        .font(.system(size: 22))
                        .foregroundColor(urgencyColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        if item.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                        }
                    }

                    HStack(spacing: 12) {
                        Label(item.location.rawValue, systemImage: item.location.icon)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        Text(item.quantity)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)

                        Text(item.category)
                            .font(.system(size: 11))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .cornerRadius(4)
                    }

                    Text(expiryText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(urgencyColor)
                }

                Spacer()

                // Actions
                VStack(spacing: 8) {
                    Button(action: {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(12)

            if isExpanded {
                VStack(spacing: 12) {
                    Divider()

                    HStack(spacing: 16) {
                        ActionButton(title: "Used", icon: "checkmark.circle.fill", color: .green) {
                            // Mark as used
                        }

                        ActionButton(title: "Extended", icon: "calendar.badge.plus", color: .blue) {
                            // Extend expiry
                        }

                        ActionButton(title: "Shopping", icon: "cart.badge.plus", color: .orange) {
                            // Add to shopping
                        }

                        ActionButton(title: "Wasted", icon: "trash.circle", color: .red) {
                            // Log as waste
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Action Button Component

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.1))
            )
        }
    }
}

// MARK: - Enhanced Pantry View

struct EnhancedPantryView: View {
    let searchText: String

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                Text("All Pantry Items")
                    .font(.title2)
                    .padding()
            }
        }
    }
}

// MARK: - Enhanced Shopping List View

struct EnhancedShoppingListView: View {
    let searchText: String

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                Text("Shopping List")
                    .font(.title2)
                    .padding()
            }
        }
    }
}

// MARK: - Add Kitchen Item Sheet

struct AddKitchenItemSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var itemName = ""
    @State private var location: StorageLocation = .fridge
    @State private var expiryDate = Date().addingTimeInterval(604800) // 1 week from now
    @State private var quantity = ""
    @State private var category = "Other"
    @State private var notes = ""

    let categories = ["Dairy", "Meat", "Vegetables", "Fruit", "Bakery", "Pantry", "Frozen", "Beverages", "Condiments", "Other"]

    var body: some View {
        NavigationView {
            Form {
                Section("Item Details") {
                    TextField("Item name", text: $itemName)

                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }

                    TextField("Quantity (e.g., 500g, 2 pieces)", text: $quantity)
                }

                Section("Storage") {
                    Picker("Location", selection: $location) {
                        ForEach(StorageLocation.allCases, id: \.self) { loc in
                            Label(loc.rawValue, systemImage: loc.icon)
                                .tag(loc)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                }

                Section("Additional Info") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Kitchen Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addItem()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(itemName.isEmpty)
                }
            }
        }
    }

    private func addItem() {
        // Add item logic here
        print("Adding item: \(itemName)")
    }
}

// MARK: - Data Models

struct KitchenItem: Identifiable {
    let id = UUID()
    let name: String
    let location: StorageLocation
    let expiryDate: Date
    let quantity: String
    let category: String
    var isFavorite: Bool = false

    var categoryIcon: String {
        switch category {
        case "Dairy": return "drop.fill"
        case "Meat": return "fork.knife"
        case "Vegetables": return "leaf.fill"
        case "Fruit": return "apple"
        case "Bakery": return "birthday.cake.fill"
        case "Frozen": return "snowflake"
        case "Beverages": return "cup.and.saucer.fill"
        case "Condiments": return "flask.fill"
        default: return "cube.box.fill"
        }
    }
}

enum StorageLocation: String, CaseIterable {
    case fridge = "Fridge"
    case freezer = "Freezer"
    case pantry = "Pantry"
    case cupboard = "Cupboard"

    var icon: String {
        switch self {
        case .fridge: return "refrigerator.fill"
        case .freezer: return "snowflake"
        case .pantry: return "cabinet.fill"
        case .cupboard: return "square.stack.3d.up.fill"
        }
    }
}

// MARK: - Preview Support

#if DEBUG
struct EnhancedKitchenTabView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedKitchenTabView(showingSettings: .constant(false))
    }
}
#endif