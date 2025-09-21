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
    @Binding var selectedTab: TabItem
    @State private var showingScanner = false
    @State private var showingCamera = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Kitchen")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Track freshness & reduce waste")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

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
                .padding(.bottom, 8)
                .background(Color(.systemBackground))

                // Main content
                KitchenExpiryView(
                    showingScanner: $showingScanner,
                    showingCamera: $showingCamera,
                    selectedTab: $selectedTab
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingScanner) {
            // Barcode scanner will be implemented
            Text("Barcode Scanner Coming Soon")
                .font(.title)
                .padding()
        }
        .sheet(isPresented: $showingCamera) {
            // Camera scanner will be implemented
            Text("Camera Scanner Coming Soon")
                .font(.title)
                .padding()
        }
    }
}

// MARK: - Kitchen Sub Views

struct KitchenExpiryView: View {
    @Binding var showingScanner: Bool
    @Binding var showingCamera: Bool
    @Binding var selectedTab: TabItem

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Expiry Alerts Summary
                KitchenExpiryAlertsCard(selectedTab: $selectedTab)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                // Critical Expiring Items
                KitchenCriticalExpiryCard()
                    .padding(.horizontal, 16)

                // This Week's Expiry
                KitchenWeeklyExpiryCard()
                    .padding(.horizontal, 16)

                // Fresh Items
                KitchenFreshItemsCard()
                    .padding(.horizontal, 16)

                // Quick Add Item
                KitchenQuickAddCard(
                    showingScanner: $showingScanner,
                    showingCamera: $showingCamera
                )
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
    @State private var showingAddSheet = false
    @Binding var selectedTab: TabItem

    enum ExpiryFilter: String, CaseIterable {
        case all = "All Items"
        case expiring = "Expiring Soon"
        case expired = "Expired"

        var color: Color {
            switch self {
            case .all: return .green
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
                    Button(action: {
                        // Navigate to add tab for barcode scanning
                        showingAddSheet = true
                    }) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 18))
                            .foregroundColor(.green)
                            .frame(width: 36, height: 36)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }

                    Button(action: {
                        showingAddSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18))
                            .foregroundColor(.purple)
                            .frame(width: 36, height: 36)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }

            // Status Cards Row
            HStack(spacing: 12) {
                StatusCard(
                    title: "Expired",
                    count: 3,
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    subtitle: "Remove now"
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
        .sheet(isPresented: $showingAddSheet) {
            AddKitchenItemSheet()
        }
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
                Label("Expired Items", systemImage: "exclamationmark.triangle.fill")
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
    @State private var expandedSections: Set<String> = []

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
                // Simplified sections instead of day-by-day
                ForEach(["Next 1-2 Days", "Later This Week"], id: \.self) { section in
                    VStack(spacing: 0) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if expandedSections.contains(section) {
                                    expandedSections.remove(section)
                                } else {
                                    expandedSections.insert(section)
                                }
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(section)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.primary)

                                    Text(section == "Next 1-2 Days" ? "3 items" : "5 items")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: expandedSections.contains(section) ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(PlainButtonStyle())

                        if expandedSections.contains(section) {
                            VStack(spacing: 0) {
                                Divider()

                                ForEach(0..<3, id: \.self) { index in
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
                                            Text(section == "Next 1-2 Days" ?
                                                ["Organic Milk", "Whole Wheat Bread", "Cheese"][index] :
                                                ["Apples", "Carrots", "Yogurt"][index])
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.primary)

                                            Text(section == "Next 1-2 Days" ?
                                                ["1/2 gallon", "1 loaf", "8 oz block"][index] :
                                                ["2 lbs bag", "1 lb bag", "6 pack"][index])
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

                                    if index < 2 {
                                        Divider()
                                            .padding(.leading, 44)
                                    }
                                }
                            }
                            .transition(.opacity)
                        }

                        if section != "Later This Week" {
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

struct KitchenFreshItemsCard: View {
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Label("Fresh Items", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.green)

                    Spacer()

                    Text("42 items")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { index in
                        HStack {
                            Circle()
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.green)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(["Organic Bananas", "Pasta", "Canned Tomatoes", "Rice", "Olive Oil"][index])
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)

                                HStack(spacing: 4) {
                                    Text(["Dole", "Barilla", "San Marzano", "Jasmine", "Extra Virgin"][index])
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)

                                    Text("•")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)

                                    Text(["6 count", "1 lb box", "28 oz can", "2 lb bag", "500ml bottle"][index])
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(["2 weeks", "1 month", "6 months", "1 year", "2 years"][index])
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.green)

                                Text(["Counter", "Pantry", "Pantry", "Pantry", "Pantry"][index])
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

                        if index < 4 {
                            Divider()
                                .padding(.leading, 44)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .transition(.opacity)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Kitchen Quick Add Interface

struct KitchenQuickAddCard: View {
    @Binding var showingScanner: Bool
    @Binding var showingCamera: Bool
    @State private var showingAddSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Quick Actions", systemImage: "bolt.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.orange)

                Spacer()
            }

            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "barcode.viewfinder",
                    title: "Scan Item",
                    subtitle: "Add by barcode",
                    color: .blue,
                    action: {
                        showingScanner = true
                    }
                )

                QuickActionButton(
                    icon: "camera.fill",
                    title: "Photo Receipt",
                    subtitle: "Import items",
                    color: .green,
                    action: {
                        showingCamera = true
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
    @State private var isSaving = false

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
            .navigationTitle("Add Kitchen Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        saveKitchenItem()
                    }) {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Add")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .disabled(itemName.isEmpty || isSaving)
                }
            }
        }
    }

    private func saveKitchenItem() {
        isSaving = true

        // Create kitchen item data
        let kitchenItem = KitchenInventoryItem(
            name: itemName,
            brand: brand.isEmpty ? nil : brand,
            quantity: quantity.isEmpty ? "1" : quantity,
            location: location,
            expiryDate: expiryDate,
            addedDate: Date()
        )

        Task {
            do {
                try await FirebaseManager.shared.addKitchenItem(kitchenItem)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Error saving kitchen item: \(error)")
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }
}

// MARK: - Preview Support

#if DEBUG
struct KitchenTabView_Previews: PreviewProvider {
    static var previews: some View {
        KitchenTabView(
            showingSettings: .constant(false),
            selectedTab: .constant(.kitchen)
        )
    }
}
#endif