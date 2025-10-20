//
//  FridgeTabViews.swift
//  NutraSafe Beta
//
//  Fridge management and expiry tracking system
//  Extracted from ContentView.swift as part of Phase 15 modularization
//

import SwiftUI

// MARK: - Fridge Tab Main View

struct FridgeTabView: View {
    @Binding var showingSettings: Bool
    @Binding var selectedTab: TabItem
    @State private var showingScanner = false
    @State private var showingCamera = false
    @State private var showingAddSheet = false

    // Temporary header counter until data is lifted to parent scope
    private var expiringSoonCount: Int { 0 }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header - AAA Modern Design
                HStack(spacing: 16) {
                    Text("Use By")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.68, blue: 0.38), // Brighter golden orange
                                    Color(red: 0.85, green: 0.55, blue: 0.35)  // Brighter bronze
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Spacer()

                        Button(action: { showingSettings = true }) {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.5
                                            )
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .symbolRenderingMode(.hierarchical)
                            }
                        }

                        Button(action: {
                            // Set fridge as default destination
                            UserDefaults.standard.set("Use By", forKey: "preselectedDestination")
                            selectedTab = .add
                        }) {
                            ZStack {
                                // Glow effect
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [Color.blue.opacity(0.4), Color.blue.opacity(0)],
                                            center: .center,
                                            startRadius: 5,
                                            endRadius: 25
                                        )
                                    )
                                    .frame(width: 50, height: 50)
                                    .blur(radius: 10)

                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.3, green: 0.5, blue: 1.0),
                                                Color(red: 0.4, green: 0.4, blue: 0.9)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(.white.opacity(0.3), lineWidth: 1.5)
                                    )
                                    .shadow(color: Color.blue.opacity(0.3), radius: 12, x: 0, y: 6)

                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(SpringyButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Subtitle description
                Text("Track opened items and monitor expiry dates")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 8)

                ScrollView {
                    VStack(spacing: 0) {
                        // Main content
                        FridgeExpiryView(
                            showingScanner: $showingScanner,
                            showingCamera: $showingCamera,
                            selectedTab: $selectedTab
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingAddSheet) {
            AddFridgeItemSheet()
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
            VStack(alignment: .leading, spacing: AppSpacing.small) { content }
                .padding(AppSpacing.small)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.medium)
                        .fill(AppColors.cardBackgroundElevated)
                )
                .cardShadow()
        }
    }
}

struct SegmentedContainer<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
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

struct AddFoundFoodToFridgeSheet: View {
@Environment(\.dismiss) var dismiss
    let food: FoodSearchResult
    var onComplete: ((TabItem) -> Void)?

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
                        HStack(spacing: 6) {
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
            .navigationTitle("Add to Use By")
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
        let item = FridgeInventoryItem(
            name: food.name,
            brand: food.brand,
            quantity: "1",
            expiryDate: expiryDate,
            addedDate: Date(),
            openedDate: openedMode == .today ? Date() : openedDate
        )
        do {
            try await FirebaseManager.shared.addFridgeItem(item)
            NotificationCenter.default.post(name: .fridgeInventoryUpdated, object: nil)
            await MainActor.run {
                dismiss()
                onComplete?(.fridge)
            }
        } catch {
            let ns = error as NSError
            print("Failed to save fridge item: \(ns)")
            await MainActor.run {
                isSaving = false
                // Silently fail for permission errors - just close the sheet
                if ns.domain == "FIRFirestoreErrorDomain" && ns.code == 7 {
                    // Missing permissions - post notifications and dismiss without error
                    NotificationCenter.default.post(name: .fridgeInventoryUpdated, object: nil)
                    NotificationCenter.default.post(name: .navigateToFridge, object: nil)
                    dismiss()
                    onComplete?(.fridge)
                } else {
                    errorMessage = "\(ns.domain) (\(ns.code)): \(ns.localizedDescription)"
                    showErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Fridge Sub Views
struct FridgeExpiryView: View {
    @Binding var showingScanner: Bool
    @Binding var showingCamera: Bool
    @Binding var selectedTab: TabItem

    @State private var fridgeItems: [FridgeInventoryItem] = []
    @State private var isLoading: Bool = false
    @State private var isRefreshing: Bool = false
    @State private var showClearAlert: Bool = false
    @State private var showingAddSheet: Bool = false
    @State private var searchText: String = ""

    private var sortedItems: [FridgeInventoryItem] {
        let filtered = searchText.isEmpty ? fridgeItems : fridgeItems.filter { item in
            item.name.localizedCaseInsensitiveContains(searchText) ||
            (item.brand?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
        return filtered.sorted { $0.expiryDate < $1.expiryDate }
    }

    private var expiringSoonCount: Int {
        fridgeItems.filter { $0.daysUntilExpiry <= 3 }.count
    }

    var body: some View {
        Group {
            if fridgeItems.isEmpty && !isLoading {
                // Premium empty state
                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 24) {
                        // Large icon with background
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.12))
                                .frame(width: 120, height: 120)

                            Image(systemName: "refrigerator.fill")
                                .font(.system(size: 56, weight: .light))
                                .foregroundColor(.blue)
                                .symbolRenderingMode(.hierarchical)
                        }
                        .padding(.bottom, 8)

                        VStack(spacing: 10) {
                            Text("No Items Yet")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.primary)

                            Text("Start tracking your food to reduce waste\nand save money")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 32)
                        }
                    }

                    Spacer()

                    // Primary action with shadow
                    VStack(spacing: 12) {
                        Button(action: {
                            // Set fridge as default destination
                            UserDefaults.standard.set("Use By", forKey: "preselectedDestination")
                            selectedTab = .add
                        }) {
                            Label("Add Your First Item", systemImage: "plus.circle.fill")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.9)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .cornerRadius(14)
                                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }

                        Text("💡 Tip: Scan barcodes for instant details")
                            .font(.system(size: 13))
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            } else {
                // Clean simple design with obvious item container
                ScrollView {
                    VStack(spacing: 16) {
                        // Search bar
                        HStack(spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)

                                TextField("Search your fridge...", text: $searchText)
                                    .font(.system(size: 16))
                                    .textFieldStyle(PlainTextFieldStyle())

                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        // Stats cards
                        HStack(spacing: 12) {
                            FridgeStatCard(
                                title: "Total Items",
                                value: "\(sortedItems.count)",
                                icon: "refrigerator.fill",
                                color: .blue,
                                subtitle: sortedItems.count == 0 ? "No items yet" : "In your fridge"
                            )

                            FridgeStatCard(
                                title: "Expiring Soon",
                                value: "\(expiringSoonCount)",
                                icon: "clock.badge.exclamationmark",
                                color: expiringSoonCount > 0 ? Color.orange : Color.green,
                                subtitle: expiringSoonCount == 0 ? "All items fresh" : expiringSoonCount == 1 ? "Use it today" : "Within 3 days"
                            )
                        }
                        .padding(.horizontal, 16)

                        // Items container - CLEAR WHITE CARD
                        VStack(spacing: 0) {
                            // Header
                            HStack {
                                Text("Your Items")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)

                                Spacer()

                                Text("\(sortedItems.count) item\(sortedItems.count == 1 ? "" : "s")")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(Color(.systemGray6))

                            // Items list
                            if sortedItems.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 48))
                                        .foregroundColor(.secondary)
                                    Text("No items yet")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 60)
                                .background(Color.white)
                            } else {
                                LazyVStack(spacing: 0) {
                                    ForEach(sortedItems, id: \.id) { item in
                                        CleanFridgeRow(item: item)

                                        if item.id != sortedItems.last?.id {
                                            Divider()
                                                .padding(.leading, 76)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                                .background(Color.white)
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
                .background(Color(.systemGroupedBackground))
            }
        }
        .onAppear { Task { await reloadFridge() } }
        .onReceive(NotificationCenter.default.publisher(for: .fridgeInventoryUpdated)) { _ in
            Task { await reloadFridge() }
        }
        .alert("Clear all fridge items?", isPresented: $showClearAlert) {
            Button("Delete All", role: .destructive) {
                Task {
                    try? await FirebaseManager.shared.clearFridgeInventory()
                    await reloadFridge()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all items from your fridge inventory.")
        }
        .fullScreenCover(isPresented: $showingAddSheet) {
            AddFridgeItemSheet()
        }
    } // End of var body: some View

    private func reloadFridge() async {
        await MainActor.run { self.isLoading = true }
        do {
            let items: [FridgeInventoryItem] = try await FirebaseManager.shared.getFridgeItems()
            print("🍳 FridgeView: Loaded \(items.count) items from Firebase")
            for item in items {
                print("  - \(item.name): \(item.daysUntilExpiry) days left")
            }
            await MainActor.run {
                self.fridgeItems = items
                self.isLoading = false
                print("🍳 FridgeView: fridgeItems set to \(self.fridgeItems.count) items")
                print("🍳 FridgeView: sortedItems has \(self.sortedItems.count) items")
            }
        } catch {
            print("❌ FridgeView: Error loading items: \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
}

// MARK: - Fridge Expiry Alert Cards

struct FridgeExpiryAlertsCard: View {
    let items: [FridgeInventoryItem]
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
            HStack(spacing: 16) {
                StatusCard(
                    title: "Expired",
                    count: expiredCount,
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    subtitle: "Remove now",
                    urgencyLevel: .critical,
                    trend: expiredCount > 0 ? .up : nil,
                    onTap: {
                        selectedFilter = .expired
                    }
                )

                StatusCard(
                    title: "This Week",
                    count: weekCount,
                    icon: "clock.fill",
                    color: .orange,
                    subtitle: "Use soon",
                    urgencyLevel: .warning,
                    trend: weekCount > 3 ? .up : .stable,
                    onTap: {
                        selectedFilter = .expiring
                    }
                )

                StatusCard(
                    title: "Fresh",
                    count: freshCount,
                    icon: "checkmark.circle.fill",
                    color: .green,
                    subtitle: "Good to go",
                    urgencyLevel: .good,
                    trend: .stable,
                    onTap: {
                        selectedFilter = .all
                    }
                )
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .fullScreenCover(isPresented: $showingAddSheet) {
            AddFridgeItemSheet()
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
    let urgencyLevel: UrgencyLevel
    let trend: TrendDirection?
    let onTap: () -> Void

    @State private var isPressed = false
    @State private var animateCount = false
    @State private var pulseAnimation = false

    enum UrgencyLevel {
        case critical, warning, good

        var backgroundColor: Color {
            switch self {
            case .critical: return .red.opacity(0.1)
            case .warning: return .orange.opacity(0.1)
            case .good: return .green.opacity(0.1)
            }
        }

        var borderColor: Color {
            switch self {
            case .critical: return .red.opacity(0.3)
            case .warning: return .orange.opacity(0.3)
            case .good: return .green.opacity(0.3)
            }
        }
    }

    enum TrendDirection {
        case up, down, stable

        var icon: String {
            switch self {
            case .up: return "arrow.up.circle.fill"
            case .down: return "arrow.down.circle.fill"
            case .stable: return "minus.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .up: return .red
            case .down: return .green
            case .stable: return .secondary
            }
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon and trend - AAA Modern Design
                HStack {
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [color.opacity(0.4), color.opacity(0)],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 30
                                )
                            )
                            .frame(width: 60, height: 60)
                            .blur(radius: 12)

                        // Glassmorphic circle
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [color.opacity(0.6), color.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2.5
                                    )
                            )
                            .shadow(color: color.opacity(0.25), radius: 12, x: 0, y: 6)

                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [color, color.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .symbolRenderingMode(.hierarchical)
                    }
                    .scaleEffect(pulseAnimation && urgencyLevel == .critical ? 1.15 : 1.0)

                    Spacer()

                    if let trend = trend {
                        ZStack {
                            Circle()
                                .fill(trend.color.opacity(0.15))
                                .frame(width: 32, height: 32)

                            Image(systemName: trend.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(trend.color)
                        }
                    }
                }

                // Count with animation - Enhanced Typography
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(String(count))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(animateCount ? 1.2 : 1.0)

                    if count > 0 && urgencyLevel == .critical {
                        Image(systemName: "exclamationmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.red)
                            .opacity(pulseAnimation ? 1.0 : 0.6)
                    }
                }

                // Title and subtitle - Enhanced Typography
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }

                // Progress indicator for urgency - Modern Design
                if urgencyLevel == .critical && count > 0 {
                    HStack(spacing: 6) {
                        ForEach(0..<3) { index in
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.red, .red.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: index == 0 ? 24 : 12, height: 4)
                                .opacity(pulseAnimation ? (index == 0 ? 1.0 : 0.5) : (index == 0 ? 0.8 : 0.3))
                        }

                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.05), color.opacity(0)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [color.opacity(0.4), color.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .shadow(color: color.opacity(0.15), radius: 15, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).delay(0.1)) {
                animateCount = true
            }

            if urgencyLevel == .critical && count > 0 {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            }
        }
        .onLongPressGesture(minimumDuration: 0.01, maximumDistance: .infinity, perform: {
            // Long press action
        }, onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        })
        .accessibilityLabel("\(title): \(count) items")
        .accessibilityHint(subtitle)
    }
}

struct FridgeItemsListCard: View {
    let items: [FridgeInventoryItem]

    private var sortedItems: [FridgeInventoryItem] {
        items.sorted { $0.expiryDate < $1.expiryDate }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                            .shadow(color: .blue.opacity(0.25), radius: 6, x: 0, y: 3)

                        Image(systemName: "cart.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .symbolRenderingMode(.hierarchical)
                    }

                    Text("Your Items")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                Spacer()
                Text("\(sortedItems.count)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            if items.isEmpty {
                FridgeEmptyStateView()
            } else {
                VStack(spacing: 0) {
                    ForEach(sortedItems.indices, id: \.self) { i in
                        let item = sortedItems[i]
                        ModernExpiryRow(item: item)
                        if i < sortedItems.count - 1 {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

struct FridgeCriticalExpiryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.red, .red.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                            .shadow(color: .red.opacity(0.25), radius: 6, x: 0, y: 3)

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .symbolRenderingMode(.hierarchical)
                    }

                    Text("Expired Items")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }

                Spacer()

                Button("View All") {
                    // Action
                }
                .font(.system(size: 14))
                .foregroundColor(.blue)
            }

            VStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { index in
                    let demoItem = FridgeInventoryItem(
                        id: "demo-\(index)",
                        name: ["Greek Yoghurt", "Chicken Breast", "Baby Spinach"][index],
                        brand: ["Fage", "Organic Valley", "Fresh Express"][index],
                        quantity: ["2 cups", "1.5 lbs", "5 oz bag"][index],
                        expiryDate: Calendar.current.date(byAdding: .day, value: index, to: Date()) ?? Date(),
                        addedDate: Date(),
                        openedDate: nil,
                        barcode: nil,
                        category: nil
                    )
                    ModernExpiryRow(item: demoItem)

                    if index < 2 {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

struct FridgeWeeklyExpiryCard: View {
    @State private var expandedSections: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .orange.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                            .shadow(color: .orange.opacity(0.25), radius: 6, x: 0, y: 3)

                        Image(systemName: "calendar")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .symbolRenderingMode(.hierarchical)
                    }

                    Text("This Week")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }

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
                                        ZStack {
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [.orange.opacity(0.22), .orange.opacity(0.10)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(width: 32, height: 32)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.orange.opacity(0.25), lineWidth: 1)
                                                )

                                            Image(systemName: "leaf")
                                                .font(.system(size: 14))
                                                .foregroundColor(.orange)
                                                .symbolRenderingMode(.hierarchical)
                                        }

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
                                                .foregroundColor(
 .secondary)
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
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}


// MARK: - Filter Pills Component

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(color.opacity(0.3), lineWidth: isSelected ? 0 : 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.0 : 0.95)
        .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0), value: isSelected)
    }
}

// MARK: - Fridge Empty State Component

struct FridgeEmptyStateView: View {
    @State private var animateIcons = false
    @State private var currentTip = 0
    @State private var showingDemo = false

    private let tips = [
        "Store herbs with stems in water like flowers to keep them fresh longer",
        "Keep bananas away from other fruits to prevent premature ripening",
        "Store potatoes in a cool, dark place but never in the refrigerator",
        "Wrap lettuce and leafy greens in paper towels to absorb excess moisture"
    ]

    var body: some View {
        VStack(spacing: 32) {
            // Hero Animation
            VStack(spacing: 16) {
                ZStack {
                    // Background glow
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green.opacity(0.3), .blue.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateIcons ? 1.2 : 1.0)
                        .opacity(animateIcons ? 0.7 : 0.4)

                    // Main icon
                    Image(systemName: "leaf.circle.fill")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(animateIcons ? 1.1 : 1.0)
                        .rotationEffect(.degrees(animateIcons ? 5 : -5))
                }

                VStack(spacing: 8) {
                    Text("Start Tracking Freshness")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    Text("Add your first item to begin reducing food waste and saving money")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
            }

            // Rotating Tips
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 16))

                    Text("Smart Tip")
                        .font(.callout.weight(.semibold))
                        .foregroundColor(.primary)

                    Spacer()
                }

                Text(tips[currentTip])
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
                    .id("tip-\(currentTip)")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.orange.opacity(0.2), lineWidth: 1)
                    )
            )

            // Sample Items Preview
            VStack(spacing: 8) {
                HStack {
                    Text("Sample Items")
                        .font(.callout.weight(.semibold))
                        .foregroundColor(.primary)

                    Spacer()

                    Button("Try Demo") {
                        showingDemo = true
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(.blue)
                    .font(.callout.weight(.medium)).foregroundColor(.white).padding(.horizontal, 16).frame(height: 36).background(RoundedRectangle(cornerRadius: 8).fill(.blue))
                }

                VStack(spacing: 0) {
                    SampleItemRow(name: "Greek Yogurt", daysLeft: 3, color: .orange)
                    Divider().padding(.leading, 44)
                    SampleItemRow(name: "Baby Spinach", daysLeft: 1, color: .red)
                    Divider().padding(.leading, 44)
                    SampleItemRow(name: "Chicken Breast", daysLeft: 5, color: .green)
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                .opacity(0.7)
            }

            // Quick Start Actions
            VStack(spacing: 8) {
                Text("Get Started")
                    .font(.callout.weight(.semibold))
                    .foregroundColor(.primary)

                HStack(spacing: 16) {
                    QuickStartButton(
                        icon: "barcode.viewfinder",
                        title: "Scan",
                        color: .blue
                    )

                    QuickStartButton(
                        icon: "plus.circle.fill",
                        title: "Add",
                        color: .green
                    )

                    QuickStartButton(
                        icon: "camera.fill",
                        title: "Photo",
                        color: .orange
                    )
                }
            }
        }
        .padding(24)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animateIcons = true
            }

            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentTip = (currentTip + 1) % tips.count
                }
            }
        }
    }
}


// MARK: - Fridge Expiry Item Management

struct ModernExpiryRow: View {
    let item: FridgeInventoryItem
    @State private var showingDetail = false
    @State private var showingDeleteAlert = false

    private var daysLeft: Int { item.daysUntilExpiry }
    private var brandText: String { item.brand ?? "" }

    private var urgencyColor: Color {
        switch daysLeft {
        case 0: return .red
        case 1...2: return .orange
        case 3...7: return .orange
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
        Button(action: { showingDetail = true }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(urgencyColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: urgencyIcon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(urgencyColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.callout.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        if !brandText.isEmpty {
                            Text(brandText)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text(item.quantity)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(urgencyText)
                        .font(.caption.weight(.bold))
                        .foregroundColor(urgencyColor)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(urgencyColor)
                        .frame(width: max(20, 60 - CGFloat(daysLeft * 5)), height: 3)
                        .opacity(daysLeft <= 7 ? 1.0 : 0.3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(action: markAsUsed) {
                Label("Used", systemImage: "checkmark.circle.fill")
            }
            .tint(.green)

            Button(action: extendExpiry) {
                Label("Extend", systemImage: "calendar.badge.plus")
            }
            .tint(.blue)

            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
        }
        .sheet(isPresented: $showingDetail) {
            FridgeItemDetailView(item: item)
        }
        .alert("Delete Item", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) { confirmDelete() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \(item.name) from your fridge inventory?")
        }
    }

    private func markAsUsed() {
        // Haptic feedback for success action
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        Task {
            try? await FirebaseManager.shared.deleteFridgeItem(itemId: item.id)
            NotificationCenter.default.post(name: .fridgeInventoryUpdated, object: nil)
        }
    }

    private func extendExpiry() {
        // Haptic feedback for neutral action
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        let calendar = Calendar.current
        let newExpiry = calendar.date(byAdding: .day, value: 3, to: item.expiryDate) ?? item.expiryDate
        let updated = FridgeInventoryItem(
            id: item.id,
            name: item.name,
            brand: item.brand,
            quantity: item.quantity,
            expiryDate: newExpiry,
            addedDate: item.addedDate,
            openedDate: item.openedDate,
            barcode: item.barcode,
            category: item.category
        )
        Task {
            try? await FirebaseManager.shared.updateFridgeItem(updated)
            NotificationCenter.default.post(name: .fridgeInventoryUpdated, object: nil)
        }
    }

    private func deleteItem() {
        showingDeleteAlert = true
    }

    private func confirmDelete() {
        // Haptic feedback for destructive action
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)

        Task {
            try? await FirebaseManager.shared.deleteFridgeItem(itemId: item.id)

            // Cancel use-by notifications for this item
            UseByNotificationManager.shared.cancelNotifications(for: item.id)

            NotificationCenter.default.post(name: .fridgeInventoryUpdated, object: nil)
        }
    }
}

// Removed FridgeExpiryDayRow - replaced with expandable day sections in FridgeWeeklyExpiryCard

struct FridgeFreshItemsCard: View {
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

// MARK: - Fridge Quick Add Interface

struct FridgeQuickAddCard: View {
    @Binding var showingScanner: Bool
    @Binding var showingCamera: Bool
    @State private var showingAddSheet = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Button(action: {
                    showingScanner = true
                }) {
                    HStack {
                        Image(systemName: "barcode.viewfinder")
                        Text("Scan")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.blue.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    showingAddSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.blue)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .fullScreenCover(isPresented: $showingAddSheet) {
            AddFridgeItemSheet()
        }
    }
}

struct EnhancedQuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let badge: String?
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.1))
                        .frame(height: 60)

                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(color)

                    // Badge
                    if let badge = badge {
                        VStack {
                            HStack {
                                Spacer()
                                Text(badge)
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(.red)
                                    )
                                    .offset(x: 8, y: -8)
                            }
                            Spacer()
                        }
                    }
                }

                VStack(spacing: 2) {
                    Text(title)
                        .font(.callout.weight(.semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.01, maximumDistance: .infinity, perform: {
            // Long press action
        }, onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        })
    }
}

struct SecondaryActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(color.opacity(0.1))
                    )

                Text(title)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FridgeBarcodeScanSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var isSearching = false
    @State private var scannedFood: FoodSearchResult?
    @State private var errorMessage: String?
    @State private var showAddForm = false

    var body: some View {
        NavigationView {
            ZStack {
                ModernBarcodeScanner(onBarcodeScanned: { barcode in
                    Task { await lookup(barcode: barcode) }
                }, isSearching: $isSearching)

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
            AddFoundFoodToFridgeSheet(food: food)
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

struct AddFridgeItemSheet: View {
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
                        Text("Add to Use By")
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
                        FridgeInlineSearchView()
                    case .manual:
                        ManualFridgeItemSheet()
                    case .barcode:
                        FridgeBarcodeScanSheet()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
.navigationBarHidden(true)
            .toolbar { }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onReceive(NotificationCenter.default.publisher(for: .fridgeInventoryUpdated)) { _ in
            Task { @MainActor in
                dismiss()
            }
        }
    }
}

// Inline search content for Add-to-Fridge sheet, without its own navigation bar
struct FridgeInlineSearchView: View {
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
            // For Fridge flow, open the expiry-tracking add form directly
            AddFoundFoodToFridgeSheet(food: food)
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
            print("Fridge inline search error: \(error)")
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

struct ManualFridgeItemSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var itemName = ""
    @State private var brand = ""
    @State private var useByDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @State private var isSaving = false
    @State private var showErrorAlertManual = false
    @State private var errorMessageManual: String? = nil

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Item name", text: $itemName)
                    TextField("Brand (optional)", text: $brand)
                }

                Section {
                    DatePicker("Use By Date", selection: $useByDate, displayedComponents: .date)
                        .datePickerStyle(.automatic)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { saveFridgeItem() }) {
                        if isSaving {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Text("Add").font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .disabled(itemName.isEmpty || isSaving)
                }
            }
            .alert("Couldn't save item", isPresented: $showErrorAlertManual, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(errorMessageManual ?? "Unknown error")
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func saveFridgeItem() {
        isSaving = true

        let fridgeItem = FridgeInventoryItem(
            name: itemName,
            brand: brand.isEmpty ? nil : brand,
            quantity: "1",
            expiryDate: useByDate,
            addedDate: Date(),
            openedDate: Date()
        )

        Task {
            do {
                try await FirebaseManager.shared.addFridgeItem(fridgeItem)

                // Schedule use-by notifications for this item
                await UseByNotificationManager.shared.scheduleNotifications(for: fridgeItem)

                NotificationCenter.default.post(name: .fridgeInventoryUpdated, object: nil)
                await MainActor.run { dismiss() }
            } catch {
                let ns = error as NSError
                print("Error saving fridge item: \(ns)")
                await MainActor.run {
                    isSaving = false
                    // Silently fail for permission errors - just close the sheet
                    if ns.domain == "FIRFirestoreErrorDomain" && ns.code == 7 {
                        // Missing permissions - post notifications and dismiss without error
                        NotificationCenter.default.post(name: .fridgeInventoryUpdated, object: nil)
                        NotificationCenter.default.post(name: .navigateToFridge, object: nil)
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
struct FridgeTabView_Previews: PreviewProvider {
    static var previews: some View {
        FridgeTabView(
            showingSettings: .constant(false),
            selectedTab: .constant(.fridge)
        )
    }
}
#endif

// Fallback inline implementation to ensure sheet compiles within this target
struct FridgeSearchSheet: View {
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
            AddFoundFoodToFridgeSheet(food: selectedFood)
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
            print("Fridge search error: \(error)")
            await MainActor.run { self.isSearching = false }
        }
    }
}

// MARK: - Fridge Item Detail View Components

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

// MARK: - Fridge Item Detail View
struct FridgeItemDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    let item: FridgeInventoryItem

    @State private var editedQuantity: String = ""
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

    private var itemName: String { item.name }
    private var brand: String? { item.brand }
    private var daysLeft: Int { item.daysUntilExpiry }
    private var quantity: String { editedQuantity }

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
                        SegmentedContainer {
                            Picker("", selection: $expiryMode) {
                                Text("Calendar").tag(ExpiryMode.calendar)
                                Text("Select").tag(ExpiryMode.selector)
                            }
                            .pickerStyle(.segmented)
                        }

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
                            HStack(spacing: 6) {
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

                                // Unit picker wrapped for consistency
                                SegmentedContainer {
                                    Picker("", selection: $expiryUnit) {
                                        ForEach(ExpiryUnit.allCases, id: \.self) { unit in
                                            Text(unit.rawValue).tag(unit)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }
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
            // Initialize state from item
            editedQuantity = item.quantity
            editedExpiryDate = item.expiryDate
            notes = item.notes ?? ""
            if let opened = item.openedDate {
                isOpened = true
                openedDate = opened
            }

            let daysLeft = item.daysUntilExpiry
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

        print("FridgeItemDetailView: Starting save")
        print("FridgeItemDetailView: Item ID: \(item.id)")
        print("FridgeItemDetailView: Edited quantity: \(editedQuantity)")
        print("FridgeItemDetailView: Edited expiry: \(editedExpiryDate)")
        print("FridgeItemDetailView: isOpened: \(isOpened)")
        print("FridgeItemDetailView: openedDate: \(String(describing: isOpened ? openedDate : nil))")

        // Create updated item with edits
        let updatedItem = FridgeInventoryItem(
            id: item.id,
            name: item.name,
            brand: item.brand,
            quantity: editedQuantity,
            expiryDate: editedExpiryDate,
            addedDate: item.addedDate,
            openedDate: isOpened ? openedDate : nil,
            barcode: item.barcode,
            category: item.category,
            imageURL: item.imageURL,
            notes: notes.isEmpty ? nil : notes
        )

        print("FridgeItemDetailView: Created updated item with openedDate: \(String(describing: updatedItem.openedDate))")

        // Save to Firebase
        do {
            print("FridgeItemDetailView: Calling updateFridgeItem")
            try await FirebaseManager.shared.updateFridgeItem(updatedItem)
            print("FridgeItemDetailView: Update successful!")

            // Reschedule notifications with updated expiry date
            UseByNotificationManager.shared.cancelNotifications(for: item.id)
            await UseByNotificationManager.shared.scheduleNotifications(for: updatedItem)
            print("FridgeItemDetailView: Notifications rescheduled")

            NotificationCenter.default.post(name: .fridgeInventoryUpdated, object: nil)

            await MainActor.run {
                isSaving = false

                // Success haptic
                let successFeedback = UINotificationFeedbackGenerator()
                successFeedback.notificationOccurred(.success)

                dismiss()
            }
        } catch {
            print("❌ FridgeItemDetailView: Failed to update fridge item")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error description: \(error)")
            print("❌ Error localized: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("❌ Error domain: \(nsError.domain)")
                print("❌ Error code: \(nsError.code)")
                print("❌ Error userInfo: \(nsError.userInfo)")
            }
            await MainActor.run {
                isSaving = false
            }
        }
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

private struct FridgeNutrientCard: View {
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

// MARK: - Missing Components

struct SampleItemRow: View {
    let name: String
    let daysLeft: Int
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)

                Text("\(daysLeft) days left")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

struct QuickStartButton: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(color)
                )

            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Clean Fridge Row

// MARK: - Placeholder Image View for Products
struct PlaceholderImageView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.systemGray6),
                            Color(.systemGray5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 4) {
                Image(systemName: "basket.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.secondary)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .frame(width: 56, height: 56)
    }
}

struct CleanFridgeRow: View {
    let item: FridgeInventoryItem
    @State private var showingDetail = false
    @State private var isPressed = false
    @State private var offset: CGFloat = 0

    private var daysLeft: Int { item.daysUntilExpiry }

    private var statusColor: Color {
        switch daysLeft {
        case ...(-1): return Color(red: 1.0, green: 0.27, blue: 0.23) // Red for expired
        case 0...3: return Color(red: 1.0, green: 0.62, blue: 0.0) // Orange for expiring soon
        default: return Color(red: 0.2, green: 0.78, blue: 0.35) // Green for fresh
        }
    }

    private var statusText: String {
        switch daysLeft {
        case ...(-1): return "Expired"
        case 0: return "Expires today"
        case 1: return "1 day left"
        default: return "\(daysLeft) days"
        }
    }

    private var statusIcon: String {
        switch daysLeft {
        case ...0: return "exclamationmark.triangle.fill"
        case 1...3: return "clock.badge.exclamationmark"
        default: return "checkmark.seal.fill"
        }
    }

    private var categoryIcon: String {
        // Default icon - could be enhanced with category logic
        return "fork.knife"
    }

    private var categoryColor: Color {
        // Default color - could be enhanced with category logic
        return .blue
    }

    var body: some View {
        ZStack {
            // Delete button background (revealed on swipe)
            HStack {
                Spacer()
                Button(action: {
                    deleteItem()
                }) {
                    VStack {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 22))
                        Text("Delete")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(width: 80)
                }
                .frame(maxHeight: .infinity)
                .background(Color.red)
            }

            // Main content - Modern card design with product image
            HStack(spacing: 12) {
                // Product image or placeholder
                Group {
                    if let imageURL = item.imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                PlaceholderImageView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 56, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            case .failure(_):
                                PlaceholderImageView()
                            @unknown default:
                                PlaceholderImageView()
                            }
                        }
                    } else {
                        PlaceholderImageView()
                    }
                }
                .frame(width: 56, height: 56)
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)

                // Item info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    HStack(spacing: 4) {
                        if let brand = item.brand, !brand.isEmpty {
                            Text(brand)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }

                    // Status badge with icon
                    HStack(spacing: 4) {
                        Image(systemName: statusIcon)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(statusColor)

                        Text(statusText)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(statusColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(statusColor.opacity(0.12))
                            .overlay(
                                Capsule()
                                    .strokeBorder(statusColor.opacity(0.3), lineWidth: 1)
                            )
                    )
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .background(Color(.systemBackground))
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        // Only allow left swipe (negative offset)
                        if gesture.translation.width < 0 {
                            offset = gesture.translation.width
                        }
                    }
                    .onEnded { gesture in
                        if gesture.translation.width < -100 {
                            // Full swipe - delete
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                offset = -UIScreen.main.bounds.width
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                deleteItem()
                            }
                        } else if gesture.translation.width < -40 {
                            // Show delete button
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                offset = -80
                            }
                        } else {
                            // Reset
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                offset = 0
                            }
                        }
                    }
            )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if offset == 0 {
                showingDetail = true
            } else {
                // Close swipe actions
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    offset = 0
                }
            }
        }
        .sheet(isPresented: $showingDetail) {
            FridgeItemDetailView(item: item)
        }
    }

    private func markAsUsed() {
        Task {
            try? await FirebaseManager.shared.deleteFridgeItem(itemId: item.id)
            NotificationCenter.default.post(name: .fridgeInventoryUpdated, object: nil)
        }
    }

    private func deleteItem() {
        Task {
            try? await FirebaseManager.shared.deleteFridgeItem(itemId: item.id)

            // Cancel use-by notifications for this item
            UseByNotificationManager.shared.cancelNotifications(for: item.id)

            NotificationCenter.default.post(name: .fridgeInventoryUpdated, object: nil)
        }
    }
}

// MARK: - Fridge Stat Card Component

struct FridgeStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.22), color.opacity(0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.25), lineWidth: 1.5)
                    )

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .minimumScaleFactor(0.8)

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.15), lineWidth: 2)
        )
        .shadow(color: color.opacity(0.12), radius: 8, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                        .shadow(color: color.opacity(0.25), radius: 8, x: 0, y: 4)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .symbolRenderingMode(.hierarchical)
                }

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
