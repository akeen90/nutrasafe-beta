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

// MARK: - Styled helpers
struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 12) { content }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemBackground)))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
        }
    }
}

struct SegmentedContainer<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
    }
}

struct CounterPill: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    var body: some View {
        HStack(spacing: 0) {
            Button(action: { if value > range.lowerBound { value -= 1 } }) {
                Image(systemName: "minus").font(.system(size: 16, weight: .semibold))
            }
            .frame(width: 40, height: 36)

            Divider().frame(height: 20)

            Text("\(value)")
                .frame(minWidth: 44)
                .font(.system(size: 16, weight: .semibold))

            Divider().frame(height: 20)

            Button(action: { if value < range.upperBound { value += 1 } }) {
                Image(systemName: "plus").font(.system(size: 16, weight: .semibold))
            }
            .frame(width: 40, height: 36)
        }
        .foregroundColor(.primary)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

struct AddFoundFoodToKitchenSheet: View {
    @Environment(\.dismiss) var dismiss
    let food: FoodSearchResult
    @State private var expiryDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var isSaving = false
    @State private var openedMode: OpenedMode = .today
    @State private var openedDate: Date = Date()
    @State private var expiryAmount: Int = 7
    @State private var expiryUnit: ExpiryUnit = .days

    enum OpenedMode { case today, chooseDate }
    enum ExpiryUnit: String, CaseIterable { case days = "Days", weeks = "Weeks" }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    SectionCard(title: "ITEM") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(food.name)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                            if let brand = food.brand { Text(brand).font(.system(size: 14)).foregroundColor(.secondary) }
                            if let serving = food.servingDescription { Text(serving).font(.system(size: 12)).foregroundColor(.secondary) }
                        }
                    }
                    SectionCard(title: "OPENED") {
                        SegmentedContainer {
                            Picker("", selection: $openedMode) {
                                Text("Opened Today").tag(OpenedMode.today)
                                Text("Choose Date").tag(OpenedMode.chooseDate)
                            }.pickerStyle(.segmented)
                        }
                        if openedMode == .chooseDate {
                            DatePicker("Opened Date", selection: $openedDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                        }
                    }
                    SectionCard(title: "EXPIRY") {
                        HStack(spacing: 12) {
                            CounterPill(value: $expiryAmount, range: 1...365)
                            SegmentedContainer {
                                Picker("Unit", selection: $expiryUnit) {
                                    ForEach(ExpiryUnit.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                                }.pickerStyle(.segmented)
                            }
                        }
                        .onChange(of: expiryAmount) { _ in recalcExpiry() }
                        .onChange(of: expiryUnit) { _ in recalcExpiry() }
                        HStack {
                            Text("Expiry Date").font(.system(size: 14, weight: .medium)).foregroundColor(.secondary)
                            Spacer()
                            DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                        }
                    }
                }
                .padding(16)
                .onAppear { recalcExpiry() }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add to Kitchen")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await save() } }) {
                        if isSaving { ProgressView() } else { Text("Add").fontWeight(.semibold) }
                    }
                }
            }
        }
    }

    private func recalcExpiry() {
        var comps = DateComponents()
        switch expiryUnit {
        case .days: comps.day = expiryAmount
        case .weeks: comps.day = expiryAmount * 7
        }
        expiryDate = Calendar.current.date(byAdding: comps, to: Date()) ?? Date()
    }

    private func save() async {
        guard !isSaving else { return }
        isSaving = true
        let item = KitchenInventoryItem(
            name: food.name,
            brand: food.brand,
            quantity: "1",
            expiryDate: expiryDate,
            addedDate: Date(),
            openedDate: openedMode == .today ? Date() : openedDate
        )
        do {
            try await FirebaseManager.shared.addKitchenItem(item)
            await MainActor.run { dismiss() }
        } catch {
            print("Failed to save kitchen item: \\(error)")
            await MainActor.run { isSaving = false }
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
.fullScreenCover(isPresented: $showingAddSheet) {
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
    let daysLeft: Int
    let quantity: String
    @State private var showingDetail = false
    @State private var foodDetail: FoodSearchResult?

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
        Button(action: {
            showingDetail = true
        }) {
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

            // Urgency
            VStack(alignment: .trailing, spacing: 4) {
                Text(urgencyText)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(urgencyColor)
            }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            KitchenItemDetailView(itemName: name, brand: brand, daysLeft: daysLeft, quantity: quantity)
        }
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
.fullScreenCover(isPresented: $showingAddSheet) {
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

struct KitchenBarcodeScanSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var isSearching = false
    @State private var scannedFood: FoodSearchResult?
    @State private var errorMessage: String?
    @State private var showAddForm = false

    var body: some View {
        NavigationView {
            ZStack {
                ModernBarcodeScanner { barcode in
                    Task { await lookup(barcode: barcode) }
                }

                VStack(spacing: 12) {
                    if isSearching {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Looking up product...").foregroundColor(.white)
                    } else {
                        Text("Position barcode within the frame").foregroundColor(.white)
                    }
                    if let errorMessage = errorMessage {
                        Text(errorMessage).foregroundColor(.red).padding(.horizontal)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(Color.black.opacity(0.7))
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .navigationTitle("Scan Barcode")
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Close") { dismiss() } } }
        }
        .navigationViewStyle(StackNavigationViewStyle())
.sheet(item: $scannedFood) { food in
            AddFoundFoodToKitchenSheet(food: food)
        }
    }

    private func lookup(barcode: String) async {
        guard !isSearching else { return }
        isSearching = true
        errorMessage = nil
        do {
            let results = try await FirebaseManager.shared.searchFoodsByBarcode(barcode: barcode)
            await MainActor.run {
                self.isSearching = false
                if let first = results.first {
self.scannedFood = first
                } else {
                    self.errorMessage = "Product not found. Try another scan or search manually."
                }
            }
        } catch {
            await MainActor.run {
                self.isSearching = false
                self.errorMessage = "Lookup failed. Please try again."
            }
        }
    }
}

struct AddKitchenItemSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingManualAdd = false
    @State private var showingSearch = false
    @State private var showingBarcodeScan = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add to Kitchen")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Choose how to add your item")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                VStack(spacing: 16) {
                    AddOptionButton(
                        icon: "magnifyingglass",
                        title: "Search Database",
                        subtitle: "Find from our food database",
                        color: .blue
                    ) {
                        showingSearch = true
                    }

                    AddOptionButton(
                        icon: "barcode.viewfinder",
                        title: "Scan Barcode",
                        subtitle: "Scan product barcode",
                        color: .green
                    ) {
                        showingBarcodeScan = true
                    }

                    AddOptionButton(
                        icon: "plus.circle",
                        title: "Manual Entry",
                        subtitle: "Add item details manually",
                        color: .purple
                    ) {
                        showingManualAdd = true
                    }
                }

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
.sheet(isPresented: $showingManualAdd) {
            ManualKitchenItemSheet()
        }
.sheet(isPresented: $showingSearch) {
            KitchenSearchSheet()
        }
.sheet(isPresented: $showingBarcodeScan) {
            KitchenBarcodeScanSheet()
        }
    }
}

struct AddOptionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 50, height: 50)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ManualKitchenItemSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var itemName = ""
    @State private var brand = ""
    @State private var expiryDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @State private var isSaving = false
    @State private var openedMode: OpenedMode = .today
    @State private var openedDate: Date = Date()
    @State private var expiryAmount: Int = 7
    @State private var expiryUnit: ExpiryUnit = .days

    enum OpenedMode { case today, chooseDate }
    enum ExpiryUnit: String, CaseIterable { case days = "Days", weeks = "Weeks" }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    SectionCard(title: "ITEM DETAILS") {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("Item name", text: $itemName).textFieldStyle(.roundedBorder)
                            TextField("Brand (optional)", text: $brand).textFieldStyle(.roundedBorder)
                        }
                    }
                    SectionCard(title: "OPENED") {
                        SegmentedContainer {
                            Picker("", selection: $openedMode) {
                                Text("Opened Today").tag(OpenedMode.today)
                                Text("Choose Date").tag(OpenedMode.chooseDate)
                            }.pickerStyle(.segmented)
                        }
                        if openedMode == .chooseDate {
                            DatePicker("Opened Date", selection: $openedDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                        }
                    }
                    SectionCard(title: "EXPIRY") {
                        HStack(spacing: 12) {
                            CounterPill(value: $expiryAmount, range: 1...365)
                            SegmentedContainer {
                                Picker("Unit", selection: $expiryUnit) {
                                    ForEach(ExpiryUnit.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                                }.pickerStyle(.segmented)
                            }
                        }
                        .onChange(of: expiryAmount) { _ in recalcExpiry() }
                        .onChange(of: expiryUnit) { _ in recalcExpiry() }
                        HStack {
                            Text("Expiry Date").font(.system(size: 14, weight: .medium)).foregroundColor(.secondary)
                            Spacer()
                            DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                        }
                    }
                }
                .padding(16)
                .onAppear { recalcExpiry() }
            }
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { saveKitchenItem() }) {
                        if isSaving { ProgressView().scaleEffect(0.8) } else { Text("Add").font(.system(size: 16, weight: .semibold)) }
                    }
                    .disabled(itemName.isEmpty || isSaving)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func recalcExpiry() {
        var comps = DateComponents()
        switch expiryUnit {
        case .days: comps.day = expiryAmount
        case .weeks: comps.day = expiryAmount * 7
        }
        expiryDate = Calendar.current.date(byAdding: comps, to: Date()) ?? Date()
    }

    private func saveKitchenItem() {
        isSaving = true

        let kitchenItem = KitchenInventoryItem(
            name: itemName,
            brand: brand.isEmpty ? nil : brand,
            quantity: "1",
            expiryDate: expiryDate,
            addedDate: Date(),
            openedDate: openedMode == .today ? Date() : openedDate
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

// Fallback inline implementation to ensure sheet compiles within this target
struct KitchenSearchSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var query: String = ""
    @State private var isSearching = false
    @State private var results: [FoodSearchResult] = []
    @State private var selectedFood: FoodSearchResult?
    @State private var showAddForm = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search products", text: $query)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .onSubmit { Task { await runSearch() } }
                    if !query.isEmpty {
                        Button { query = ""; results = [] } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 12)

                if isSearching { ProgressView("Searching…").padding() }

List(results, id: \.id) { food in
                    Button { selectedFood = food } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(food.name).font(.system(size: 16, weight: .semibold))
                                if let brand = food.brand { Text(brand).font(.system(size: 12)).foregroundColor(.secondary) }
                            }
                            Spacer()
                            Text("\\(Int(food.calories)) kcal/100g")
                                .font(.system(size: 12)).foregroundColor(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Search Database")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Search") { Task { await runSearch() } }
                        .disabled(query.trimmingCharacters(in: .whitespaces).count < 2)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
.sheet(item: $selectedFood) { selectedFood in
            AddFoundFoodToKitchenSheet(food: selectedFood)
        }
    }

    private func runSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return }
        isSearching = true
        do {
            let foods = try await FirebaseManager.shared.searchFoods(query: trimmed)
            await MainActor.run { self.results = foods; self.isSearching = false }
        } catch {
            print("Kitchen search error: \\(error)")
            await MainActor.run { self.isSearching = false }
        }
    }
}

// MARK: - Kitchen Item Detail View
struct KitchenItemDetailView: View {
    @Environment(\.dismiss) var dismiss
    let itemName: String
    let brand: String?
    let daysLeft: Int
    let quantity: String
    @State private var isLoading = true
    @State private var foodDetail: FoodSearchResult?
    @State private var showingFoodDetail = false
    
    var urgencyColor: Color {
        switch daysLeft {
        case 0: return .red
        case 1...2: return .orange
        case 3...7: return .yellow
        default: return .green
        }
    }
    
    var urgencyText: String {
        switch daysLeft {
        case 0: return "Expires today"
        case 1: return "Expires tomorrow"
        case 2...7: return "\(daysLeft) days left"
        default: return "\(daysLeft) days left"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                        Text("Loading nutrition information...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Item Header
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(itemName)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        if let brand = brand, !brand.isEmpty {
                                            Text(brand)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                }
                                
                                // Status badges
                                HStack(spacing: 12) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "clock.fill")
                                            .font(.system(size: 14))
                                        Text(urgencyText)
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(urgencyColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(urgencyColor.opacity(0.1))
                                    .cornerRadius(20)
                                    
                                    HStack(spacing: 6) {
                                        Image(systemName: "scalemass")
                                            .font(.system(size: 14))
                                        Text(quantity)
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(20)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            
                            if let food = foodDetail {
                                // Nutrition Info
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Nutrition per 100g")
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    HStack(spacing: 12) {
                                        NutrientCard(title: "Calories", value: "\(Int(food.calories))", unit: "kcal", color: .orange)
                                        NutrientCard(title: "Protein", value: String(format: "%.1f", food.protein), unit: "g", color: .red)
                                    }
                                    .padding(.horizontal)
                                    
                                    HStack(spacing: 12) {
                                        NutrientCard(title: "Carbs", value: String(format: "%.1f", food.carbs), unit: "g", color: .blue)
                                        NutrientCard(title: "Fat", value: String(format: "%.1f", food.fat), unit: "g", color: .purple)
                                    }
                                    .padding(.horizontal)
                                    
                                    Button(action: {
                                        showingFoodDetail = true
                                    }) {
                                        HStack {
                                            Text("View Full Nutrition Details")
                                            Image(systemName: "chevron.right")
                                        }
                                        .font(.system(size: 16, weight: .medium))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                }
                                .padding(.vertical)
                            } else {
                                VStack(spacing: 20) {
                                    Image(systemName: "exclamationmark.circle")
                                        .font(.system(size: 48))
                                        .foregroundColor(.orange)
                                    
                                    Text("Nutrition information not found")
                                        .font(.headline)
                                    
                                    Text("We couldn't find detailed nutrition data for this item. Try searching for it in our food database.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                .padding(.vertical, 40)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Kitchen Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            print("[KitchenItemDetailView] appear: item=\(itemName), brand=\(brand ?? "nil"), daysLeft=\(daysLeft), qty=\(quantity)")
            Task {
                await loadFoodDetails()
            }
        }
        .fullScreenCover(isPresented: $showingFoodDetail) {
            if let food = foodDetail {
                FoodDetailViewFromSearch(
                    food: food,
                    sourceType: .kitchen,
                    selectedTab: .constant(.kitchen)
                )
            } else {
                NavigationView {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading details...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                    .navigationTitle("Food Details")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") { showingFoodDetail = false }
                        }
                    }
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
        }
    }
    
    private func loadFoodDetails() async {
        // Try to search for the food by name (and brand if available)
        let searchQuery = brand != nil && !brand!.isEmpty ? "\(brand!) \(itemName)" : itemName
        print("[KitchenItemDetailView] fetching details for query=\(searchQuery)")
        do {
            let results = try await FirebaseManager.shared.searchFoods(query: searchQuery)
            print("[KitchenItemDetailView] results count=\(results.count)")
            await MainActor.run {
                if let firstResult = results.first {
                    self.foodDetail = firstResult
                    print("[KitchenItemDetailView] assigned first result: id=\(firstResult.id)")
                } else {
                    print("[KitchenItemDetailView] no results found")
                }
                self.isLoading = false
            }
        } catch {
            print("[KitchenItemDetailView] error loading food details: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

private struct NutrientCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(color)
                Text(unit)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
