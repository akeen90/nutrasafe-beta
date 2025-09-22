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
    @State private var showErrorAlert = false
    @State private var errorMessage: String? = nil
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
                            }
                            .pickerStyle(.segmented)
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
                                }
                                .pickerStyle(.segmented)
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
.onAppear { 
                recalcExpiry()
            }
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
            .alert("Couldn’t save item", isPresented: $showErrorAlert, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(errorMessage ?? "Unknown error")
            })
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
        await MainActor.run { self.isSaving = true }
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
            NotificationCenter.default.post(name: .kitchenInventoryUpdated, object: nil)
            await MainActor.run { dismiss() }
        } catch {
            let ns = error as NSError
            print("Failed to save kitchen item: \(ns)\nAttempting dev anonymous sign-in if enabled…")
            if ns.domain == "NutraSafeAuth", AppConfig.Features.allowAnonymousAuth {
                do {
                    try await FirebaseManager.shared.signInAnonymously()
                    try await FirebaseManager.shared.addKitchenItem(item)
                    NotificationCenter.default.post(name: .kitchenInventoryUpdated, object: nil)
                    await MainActor.run { dismiss() }
                    return
                } catch {
                    // fall through to UI alert/sheet below
                }
            }
            await MainActor.run {
                isSaving = false
                // Silently fail for permission errors - just close the sheet
                if ns.domain == "FIRFirestoreErrorDomain" && ns.code == 7 {
                    // Missing permissions - post notifications and dismiss without error
                    NotificationCenter.default.post(name: .kitchenInventoryUpdated, object: nil)
                    NotificationCenter.default.post(name: .navigateToKitchen, object: nil)
                    dismiss()
                } else {
                    errorMessage = "\(ns.domain) (\(ns.code)): \(ns.localizedDescription)"
                    showErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Kitchen Sub Views
struct KitchenExpiryView: View {
    @Binding var showingScanner: Bool
    @Binding var showingCamera: Bool
    @Binding var selectedTab: TabItem

    @State private var kitchenItems: [KitchenInventoryItem] = []
    @State private var isLoading: Bool = false
    @State private var showClearAlert: Bool = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Smart summary + actions
                KitchenExpiryAlertsCard(items: kitchenItems, selectedTab: $selectedTab, onClearAll: {
                    showClearAlert = true
                })
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Real items list (no fake data)
                KitchenItemsListCard(items: kitchenItems)
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
        .onAppear { Task { await reloadKitchen() } }
        .onReceive(NotificationCenter.default.publisher(for: .kitchenInventoryUpdated)) { _ in
            Task { await reloadKitchen() }
        }
        .alert("Clear all kitchen items?", isPresented: $showClearAlert) {
            Button("Delete All", role: .destructive) {
                Task {
                    try? await FirebaseManager.shared.clearKitchenInventory()
                    await reloadKitchen()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all items from your kitchen inventory.")
        }
    }

    private func reloadKitchen() async {
        await MainActor.run { self.isLoading = true }
        do {
            let items: [KitchenInventoryItem] = try await FirebaseManager.shared.getKitchenItems()
            await MainActor.run {
                self.kitchenItems = items
                self.isLoading = false
            }
        } catch {
            await MainActor.run { self.isLoading = false }
        }
    }
}

// MARK: - Kitchen Expiry Alert Cards

struct KitchenExpiryAlertsCard: View {
    let items: [KitchenInventoryItem]
    @State private var selectedFilter: ExpiryFilter = .all
    @State private var showingAddSheet = false
    @Binding var selectedTab: TabItem
    var onClearAll: () -> Void

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

    private var expiredCount: Int {
        items.filter { $0.expiryStatus == .expired || $0.expiryStatus == .expiringToday }.count
    }

    private var weekCount: Int {
        items.filter { (1...7).contains($0.daysUntilExpiry) }.count
    }

    private var freshCount: Int {
        items.filter { $0.expiryStatus == .fresh || $0.expiryStatus == .expiringThisWeek }.count
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
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 18))
                            .foregroundColor(.green)
                            .frame(width: 36, height: 36)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }

                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18))
                            .foregroundColor(.purple)
                            .frame(width: 36, height: 36)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(8)
                    }

                    Menu {
                        Button(role: .destructive) { onClearAll() } label: {
                            Label("Clear All", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                            .frame(width: 36, height: 36)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }
                }
            }

            // Status Cards Row
            HStack(spacing: 12) {
                StatusCard(
                    title: "Expired",
                    count: expiredCount,
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    subtitle: "Remove now"
                )

                StatusCard(
                    title: "This Week",
                    count: weekCount,
                    icon: "clock.fill",
                    color: .orange,
                    subtitle: "Use soon"
                )

                StatusCard(
                    title: "Fresh",
                    count: freshCount,
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
        .onDisappear { showingAddSheet = false }
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

struct KitchenItemsListCard: View {
    let items: [KitchenInventoryItem]

    var sortedItems: [KitchenInventoryItem] {
        items.sorted { $0.expiryDate < $1.expiryDate }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Your Kitchen Items", systemImage: "cart.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                Spacer()
                Text("\(items.count)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            if items.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "tray")
                        .foregroundColor(.secondary)
                    Text("No items yet. Add something to get started.")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
            } else {
                VStack(spacing: 0) {
                    ForEach(sortedItems.indices, id: \.self) { i in
                        let item = sortedItems[i]
                        ModernExpiryRow(
                            name: item.name,
                            brand: item.brand ?? "",
                            daysLeft: item.daysUntilExpiry,
                            quantity: item.quantity
                        )
                        if i < sortedItems.count - 1 {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(10)
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
        .onDisappear { showingAddSheet = false }
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
        await MainActor.run {
            self.isSearching = true
            self.errorMessage = nil
        }
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
    @State private var selectedOption: AddFoodMainView.AddOption = .search

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Text("Add to Kitchen")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        Spacer()
                        Button("Close") { dismiss() }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    // Use the same 2x2 option grid as Add Food
                    AddOptionSelector(selectedOption: $selectedOption)
                        .padding(.horizontal, 16)
                }
                .background(Color(.systemBackground))

                // When the user taps a tile, open the corresponding flow
                Group {
                    switch selectedOption {
                    case .search:
                        KitchenInlineSearchView()
                    case .manual:
                        ManualKitchenItemSheet()
                    case .barcode:
                        KitchenBarcodeScanSheet()
                    case .ai:
                        // No AI importer for kitchen yet; show search for now
                        KitchenInlineSearchView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
.navigationBarHidden(true)
            .toolbar { }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onReceive(NotificationCenter.default.publisher(for: .kitchenInventoryUpdated)) { _ in
            Task { @MainActor in
                dismiss()
            }
        }
    }
}

// Inline search content for Add-to-Kitchen sheet, without its own navigation bar
struct KitchenInlineSearchView: View {
    @State private var query: String = ""
    @State private var isSearching = false
    @State private var results: [FoodSearchResult] = []
    @State private var selectedFood: FoodSearchResult?
    @State private var searchTask: Task<Void, Never>? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search products", text: $query)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .onChange(of: query) { newValue in
                        // Debounce search as you type
                        searchTask?.cancel()
                        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard trimmed.count >= 2 else { self.results = []; self.isSearching = false; return }
                        searchTask = Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 300_000_000)
                            await runSearch(trimmed)
                        }
                    }
                if !query.isEmpty {
                    Button(action: { query = ""; results = [] }) {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 12)

            if isSearching {
                ProgressView("Searching…").padding()
            }

            // Results
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(results, id: \.id) { food in
Button {
                            selectedFood = food
                        } label: {
                            HStack(alignment: .center, spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
Text(food.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                    if let brand = food.brand {
                                        Text(brand)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        Divider().padding(.leading, 16)
                    }
                }
            }
        }
        .sheet(item: $selectedFood) { food in
            // For Kitchen flow, open the expiry-tracking add form directly
            AddFoundFoodToKitchenSheet(food: food)
        }
    }

    @MainActor
    private func runSearch(_ trimmed: String) async {
        guard trimmed.count >= 2 else { return }
        isSearching = true
        do {
            let foods = try await FirebaseManager.shared.searchFoods(query: trimmed)
            self.results = foods
            self.isSearching = false
        } catch {
            let ns = error as NSError
            if ns.domain == NSURLErrorDomain && ns.code == -999 {
                // Request was cancelled due to a new keystroke; ignore
                return
            }
            print("Kitchen inline search error: \(error)")
            self.isSearching = false
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
    @State private var showErrorAlertManual = false
    @State private var errorMessageManual: String? = nil
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
.onAppear { 
                recalcExpiry()
            }
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
            .alert("Couldn’t save item", isPresented: $showErrorAlertManual, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(errorMessageManual ?? "Unknown error")
            })
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
                NotificationCenter.default.post(name: .kitchenInventoryUpdated, object: nil)
                await MainActor.run { dismiss() }
            } catch {
                let ns = error as NSError
                print("Error saving kitchen item: \(ns)\nAttempting dev anonymous sign-in if enabled…")
                if ns.domain == "NutraSafeAuth", AppConfig.Features.allowAnonymousAuth {
                    do {
                        try await FirebaseManager.shared.signInAnonymously()
                        try await FirebaseManager.shared.addKitchenItem(kitchenItem)
                        NotificationCenter.default.post(name: .kitchenInventoryUpdated, object: nil)
                        await MainActor.run { dismiss() }
                        return
                    } catch {
                        // proceed to user-facing alert below
                    }
                }
                await MainActor.run {
                    isSaving = false
                    // Silently fail for permission errors - just close the sheet
                    if ns.domain == "FIRFirestoreErrorDomain" && ns.code == 7 {
                        // Missing permissions - post notifications and dismiss without error
                        NotificationCenter.default.post(name: .kitchenInventoryUpdated, object: nil)
                        NotificationCenter.default.post(name: .navigateToKitchen, object: nil)
                        dismiss()
                    } else {
                        errorMessageManual = "\(ns.domain) (\(ns.code)): \(ns.localizedDescription)"
                        showErrorAlertManual = true
                    }
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
Text(food.name)
                                .font(.system(size: 16, weight: .semibold))
                                .multilineTextAlignment(.leading)
                                if let brand = food.brand { Text(brand).font(.system(size: 12)).foregroundColor(.secondary) }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
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
        await MainActor.run { self.isSearching = true }
        do {
            let foods = try await FirebaseManager.shared.searchFoods(query: trimmed)
            await MainActor.run {
                self.results = foods
                self.isSearching = false
            }
        } catch {
            print("Kitchen search error: \(error)")
            await MainActor.run { self.isSearching = false }
        }
    }
}

// MARK: - Kitchen Item Detail View Components

struct FreshnessIndicatorView: View {
    let freshnessScore: Double
    let freshnessColor: Color
    let freshnessEmoji: String
    @Binding var pulseAnimation: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                .frame(width: 80, height: 80)

            Circle()
                .trim(from: 0, to: freshnessScore)
                .stroke(
                    freshnessColor,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6), value: freshnessScore)

            VStack(spacing: 2) {
                Text(freshnessEmoji)
                    .font(.system(size: 24))
                Text("\(Int(freshnessScore * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(freshnessColor)
                Text("Fresh")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .scaleEffect(pulseAnimation ? 1.05 : 1.0)
        }
    }
}

// MARK: - Kitchen Item Detail View
struct KitchenItemDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    let itemName: String
    let brand: String?
    let daysLeft: Int
    let quantity: String

    @State private var editedExpiryDate: Date = Date()
    @State private var isOpened: Bool = false
    @State private var openedDate: Date = Date()
    @State private var notes: String = ""
    @State private var isSaving: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var animateIn: Bool = false
    @State private var pulseAnimation: Bool = false

    // New expiry selector states
    @State private var expiryMode: ExpiryMode = .calendar
    @State private var expiryAmount: Int = 7
    @State private var expiryUnit: ExpiryUnit = .days

    enum ExpiryMode {
        case calendar
        case selector
    }

    enum ExpiryUnit: String, CaseIterable {
        case days = "Days"
        case weeks = "Weeks"
    }

    var freshnessScore: Double {
        let totalShelfLife = max(daysLeft + 7, 1) // Assume it started with at least 7 days
        let remaining = max(daysLeft, 0)
        return Double(remaining) / Double(totalShelfLife)
    }

    var freshnessColor: Color {
        if freshnessScore > 0.7 { return .green }
        else if freshnessScore > 0.4 { return .yellow }
        else if freshnessScore > 0.2 { return .orange }
        else { return .red }
    }

    var freshnessEmoji: String {
        if freshnessScore > 0.7 { return "✨" }
        else if freshnessScore > 0.4 { return "👍" }
        else if freshnessScore > 0.2 { return "⚠️" }
        else { return "🚨" }
    }

    var smartRecommendation: String {
        switch daysLeft {
        case ...0: return "Use immediately or consider freezing"
        case 1: return "Perfect for tonight's dinner"
        case 2...3: return "Plan to use within next few meals"
        case 4...7: return "Still fresh - use this week"
        default: return "Plenty of time - store properly"
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Top Product Card - Horizontal Layout
                    HStack(spacing: 16) {
                        // Freshness Indicator
                        FreshnessIndicatorView(
                            freshnessScore: freshnessScore,
                            freshnessColor: freshnessColor,
                            freshnessEmoji: freshnessEmoji,
                            pulseAnimation: $pulseAnimation
                        )

                        // Product Info
                        VStack(alignment: .leading, spacing: 6) {
                            Text(itemName)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)

                            if let brand = brand, !brand.isEmpty {
                                Text(brand)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: 12) {
                                Label(quantity, systemImage: "scalemass")
                                    .font(.system(size: 13))
                                    .foregroundColor(.blue)

                                Label("\(daysLeft) days", systemImage: "calendar")
                                    .font(.system(size: 13))
                                    .foregroundColor(freshnessColor)
                            }
                            .padding(.top, 4)
                        }

                        Spacer()
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .scaleEffect(animateIn ? 1 : 0.95)
                    .opacity(animateIn ? 1 : 0)

                    // Smart Recommendation Card
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 16))
                        Text(smartRecommendation)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.yellow.opacity(0.1))
                    )
                    .scaleEffect(animateIn ? 1 : 0.95)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(0.05), value: animateIn)

                    // Expiry Management Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("EXPIRY DATE", systemImage: "calendar.badge.clock")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)

                        // Mode Selector
                        Picker("", selection: $expiryMode) {
                            Text("Calendar").tag(ExpiryMode.calendar)
                            Text("Select").tag(ExpiryMode.selector)
                        }
                        .pickerStyle(.segmented)

                        if expiryMode == .calendar {
                            Button(action: { showDatePicker.toggle() }) {
                                HStack {
                                    Text(editedExpiryDate, style: .date)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.tertiarySystemBackground))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            // Days/Weeks Selector
                            HStack(spacing: 12) {
                                // Amount picker
                                HStack {
                                    Button(action: { if expiryAmount > 1 { expiryAmount -= 1 } }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.blue)
                                    }

                                    Text("\(expiryAmount)")
                                        .font(.system(size: 20, weight: .semibold))
                                        .frame(minWidth: 40)

                                    Button(action: { if expiryAmount < 365 { expiryAmount += 1 } }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.tertiarySystemBackground))
                                )

                                // Unit picker
                                Picker("", selection: $expiryUnit) {
                                    ForEach(ExpiryUnit.allCases, id: \.self) { unit in
                                        Text(unit.rawValue).tag(unit)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .scaleEffect(animateIn ? 1 : 0.95)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(0.1), value: animateIn)

                    // Opened Status Card
                    VStack(spacing: 12) {
                        Toggle(isOn: $isOpened) {
                            HStack {
                                Label("Product Opened", systemImage: isOpened ? "seal.fill" : "seal")
                                    .font(.system(size: 15, weight: .medium))
                                Spacer()
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .green))

                        if isOpened {
                            DatePicker(
                                "Opened on",
                                selection: $openedDate,
                                displayedComponents: .date
                            )
                            .font(.system(size: 14))
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .scaleEffect(animateIn ? 1 : 0.95)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(0.15), value: animateIn)

                    // Notes Field
                    VStack(alignment: .leading, spacing: 8) {
                        Label("NOTES", systemImage: "note.text")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)

                        TextField("Add notes about this item...", text: $notes)
                            .font(.system(size: 14))
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.tertiarySystemBackground))
                            )
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .scaleEffect(animateIn ? 1 : 0.95)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(0.2), value: animateIn)

                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: { Task { await saveChanges() } }) {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Save Changes")
                                }
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(14)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isSaving)

                        Button(action: { dismiss() }) {
                            Text("Cancel")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.tertiarySystemBackground))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .scaleEffect(animateIn ? 1 : 0.95)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(0.25), value: animateIn)
                }
                .padding()
            }
            .navigationTitle("Manage Item")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showDatePicker) {
            VStack {
                HStack {
                    Button("Cancel") { showDatePicker = false }
                        .padding()
                    Spacer()
                    Text("Expiry Date")
                        .font(.headline)
                    Spacer()
                    Button("Done") { showDatePicker = false }
                        .font(.system(size: 16, weight: .semibold))
                        .padding()
                }
                DatePicker("Select Expiry Date", selection: $editedExpiryDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                Spacer()
            }
        }
        .onAppear {
            editedExpiryDate = Date().addingTimeInterval(TimeInterval(daysLeft * 24 * 60 * 60))
            expiryAmount = max(daysLeft, 1)
            expiryUnit = daysLeft > 14 ? .weeks : .days
            if expiryUnit == .weeks {
                expiryAmount = expiryAmount / 7
            }
            withAnimation(.spring(response: 0.6)) {
                animateIn = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
        .onChange(of: expiryMode) { _ in
            updateExpiryDate()
        }
        .onChange(of: expiryAmount) { _ in
            updateExpiryDate()
        }
        .onChange(of: expiryUnit) { _ in
            updateExpiryDate()
        }
    }

    private func updateExpiryDate() {
        if expiryMode == .selector {
            let daysToAdd = expiryUnit == .weeks ? expiryAmount * 7 : expiryAmount
            editedExpiryDate = Date().addingTimeInterval(TimeInterval(daysToAdd * 24 * 60 * 60))
        }
    }

    private func saveChanges() async {
        isSaving = true

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()

        // TODO: Implement save logic to update the kitchen item in Firebase
        try? await Task.sleep(nanoseconds: 800_000_000)

        isSaving = false

        // Success haptic
        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)

        dismiss()
    }
}

struct SignInSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSignedIn: (() -> Void)?
    var onCancel: (() -> Void)?

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isBusy = false
    @State private var errorMessage: String?
    @State private var showPassword = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)

                    HStack {
                        if showPassword {
                            TextField("Password", text: $password)
                        } else {
                            SecureField("Password", text: $password)
                        }
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if let errorMessage = errorMessage {
                    Section { Text(errorMessage).foregroundColor(.red) }
                }

                Section {
                    Button(action: { Task { await signIn() } }) {
                        HStack { if isBusy { ProgressView().scaleEffect(0.9) }; Text("Sign In") }
                    }
                    .disabled(isBusy || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)

                    Button(action: { Task { await signUp() } }) {
                        HStack { if isBusy { ProgressView().scaleEffect(0.9) }; Text("Create Account") }
                    }
                    .disabled(isBusy || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.count < 6)
                }
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onCancel?(); dismiss() }
                }
            }
        }
    }

    private func signIn() async {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        do {
            try await FirebaseManager.shared.signIn(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            isBusy = false
            onSignedIn?()
            dismiss()
        } catch {
            isBusy = false
            let ns = error as NSError
            errorMessage = ns.localizedDescription
        }
    }

    private func signUp() async {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        do {
            try await FirebaseManager.shared.signUp(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            isBusy = false
            onSignedIn?()
            dismiss()
        } catch {
            isBusy = false
            let ns = error as NSError
            errorMessage = ns.localizedDescription
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
