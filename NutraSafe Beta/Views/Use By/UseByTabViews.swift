//
//  UseByTabViews.swift
//  NutraSafe Beta
//
//  UseBy management and expiry tracking system
//  Extracted from ContentView.swift as part of Phase 15 modularization
//

import SwiftUI
import UIKit

// MARK: - Custom Midnight Blue Theme

extension Color {
    /// Midnight blue background - trading platform style
    static var midnightBackground: Color {
        Color(red: 0.08, green: 0.12, blue: 0.20) // #141F33
    }

    /// Slightly lighter midnight blue for cards
    static var midnightCard: Color {
        Color(red: 0.12, green: 0.16, blue: 0.24) // #1E293D
    }

    /// Even lighter for secondary cards
    static var midnightCardSecondary: Color {
        Color(red: 0.15, green: 0.20, blue: 0.28) // #263447
    }

    /// Adaptive background that switches between white and midnight blue
    static var adaptiveBackground: Color {
        Color(uiColor: .init { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.08, green: 0.12, blue: 0.20, alpha: 1.0)
                : UIColor.systemBackground
        })
    }

    /// Adaptive card background
    static var adaptiveCard: Color {
        Color(uiColor: .init { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.12, green: 0.16, blue: 0.24, alpha: 1.0)
                : UIColor.secondarySystemGroupedBackground
        })
    }

    /// Adaptive secondary card background
    static var adaptiveCardSecondary: Color {
        Color(uiColor: .init { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.15, green: 0.20, blue: 0.28, alpha: 1.0)
                : UIColor.tertiarySystemGroupedBackground
        })
    }
}

// MARK: - Image Cache (Performance Optimization)

/// Simple image cache using NSCache for automatic memory management
private class SimpleImageCache {
    static let shared = SimpleImageCache()
    private let cache = NSCache<NSString, UIImage>()

    init() {
        cache.countLimit = 50 // Max 50 images
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB
    }

    func image(from data: Data, key: String) -> UIImage? {
        let cacheKey = NSString(string: key)
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }
        guard let image = UIImage(data: data) else { return nil }
        cache.setObject(image, forKey: cacheKey, cost: data.count)
        return image
    }

    func isCached(key: String) -> Bool {
        return cache.object(forKey: NSString(string: key)) != nil
    }
}

// MARK: - UseBy Tab Main View

struct UseByTabView: View {
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
                        .frame(height: 44, alignment: .center)
                        .foregroundColor(.primary)

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
                            // Set useBy as default destination
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
                Text("Track items and monitor expiry dates")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 8)

                ScrollView {
                    VStack(spacing: 0) {
                        // Main content
                        UseByExpiryView(
                            showingScanner: $showingScanner,
                            showingCamera: $showingCamera,
                            selectedTab: $selectedTab
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.bottom, 80) // Space for tab bar
                }
            }
            .background(Color.adaptiveBackground)
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $showingAddSheet) {
            AddUseByItemSheet()
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

struct AddFoundFoodToUseBySheet: View {
@Environment(\.dismiss) var dismiss
    let food: FoodSearchResult
    var onComplete: ((TabItem) -> Void)?

    @State private var expiryDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var isSaving = false
    @State private var showErrorAlert = false
    @State private var errorMessage: String? = nil

@State private var expiryAmount: Int = 7
@State private var expiryUnit: ExpiryUnit = .days
    @State private var showPhotoActionSheet = false
    @State private var showCameraPicker = false
    @State private var showPhotoPicker = false
    @State private var capturedImage: UIImage?
    @State private var uploadedImageURL: String?
    @State private var isUploadingPhoto = false


    enum ExpiryUnit: String, CaseIterable { case days = "Days", weeks = "Weeks" }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    SectionCard(title: "ITEM") {
                        VStack(spacing: 16) {
                            // Horizontal layout with photo and details
                            HStack(spacing: 16) {
                                // Photo section - compact square
                                Button(action: { showPhotoActionSheet = true }) {
                                    ZStack {
                                        if let image = capturedImage {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                                                )
                                        } else {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.blue.opacity(0.1))
                                                .frame(width: 80, height: 80)
                                                .overlay(
                                                    VStack(spacing: 4) {
                                                        Image(systemName: "camera.fill")
                                                            .font(.system(size: 20))
                                                            .foregroundColor(.blue)
                                                        Text("Photo")
                                                            .font(.system(size: 10, weight: .medium))
                                                            .foregroundColor(.blue)
                                                    }
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                                                )
                                        }

                                        if isUploadingPhoto {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.black.opacity(0.5))
                                                .frame(width: 80, height: 80)
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(isUploadingPhoto)

                                // Item details
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(food.name)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)

                                    if let brand = food.brand {
                                        Text(brand)
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }

                                    if let serving = food.servingDescription {
                                        Text(serving)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(Color(.tertiarySystemBackground))
                                            )
                                    }
                                }

                                Spacer()
                            }
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
                        if isSaving || isUploadingPhoto {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text(isUploadingPhoto ? "Uploading..." : "Saving...")
                                    .font(.caption)
                            }
                        } else {
                            Text("Add").fontWeight(.semibold)
                        }
                    }
                    .disabled(isUploadingPhoto || isSaving)
                }
            }
            .alert("Couldn't save item", isPresented: $showErrorAlert, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(errorMessage ?? "Unknown error")
            })
            .confirmationDialog("Add Photo", isPresented: $showPhotoActionSheet) {
                Button("Take Photo") {
                    showCameraPicker = true
                }
                Button("Choose from Library") {
                    showPhotoPicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showCameraPicker) {
                ImagePicker(selectedImage: nil, sourceType: .camera) { image in
                    if let image = image {
                        capturedImage = image
                        Task {
                            await uploadPhoto(image)
                            await MainActor.run {
                                showCameraPicker = false
                            }
                        }
                    } else {
                        showCameraPicker = false
                    }
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoLibraryPicker { image in
                    showPhotoPicker = false
                    if let image = image {
                        capturedImage = image
                        Task {
                            await uploadPhoto(image)
                        }
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

    private func uploadPhoto(_ image: UIImage) async {
        // No longer upload immediately - just store locally
        // Upload will happen when saving the item
        await MainActor.run { isUploadingPhoto = false }
        print("📸 Image captured, will cache when saving...")
    }

    private func save() async {
        guard !isSaving else { return }
        await MainActor.run { self.isSaving = true }

        // Generate ID for new item
        let itemId = UUID().uuidString

        // Save image locally first if we have one
        var firebaseURL: String? = nil
        if let image = capturedImage {
            do {
                try await ImageCacheManager.shared.saveUseByImage(image, for: itemId)
                print("✅ Image cached locally for item: \(itemId)")
            } catch {
                print("⚠️ Failed to cache image locally: \(error)")
            }

            // Upload to Firebase in background for backup/sync
            do {
                let url = try await FirebaseManager.shared.uploadUseByItemPhoto(image)
                print("☁️ Image uploaded to Firebase: \(url)")
                firebaseURL = url
            } catch {
                print("⚠️ Firebase upload failed (using local cache): \(error)")
            }
        }

        print("📸 Saving useBy item (ID: \(itemId))")

        let item = UseByInventoryItem(
            id: itemId,
            name: food.name,
            brand: food.brand,
            quantity: "1",
            expiryDate: expiryDate,
            addedDate: Date(),
            imageURL: firebaseURL
        )
        do {
            try await FirebaseManager.shared.addUseByItem(item)
            NotificationCenter.default.post(name: .useByInventoryUpdated, object: nil)
            await MainActor.run {
                dismiss()
                onComplete?(.useBy)
            }
        } catch {
            let ns = error as NSError
            print("Failed to save useBy item: \(ns)")
            await MainActor.run {
                isSaving = false
                // Silently fail for permission errors - just close the sheet
                if ns.domain == "FIRFirestoreErrorDomain" && ns.code == 7 {
                    // Missing permissions - post notifications and dismiss without error
                    NotificationCenter.default.post(name: .useByInventoryUpdated, object: nil)
                    NotificationCenter.default.post(name: .navigateToUseBy, object: nil)
                    dismiss()
                    onComplete?(.useBy)
                } else {
                    errorMessage = "\(ns.domain) (\(ns.code)): \(ns.localizedDescription)"
                    showErrorAlert = true
                }
            }
        }
    }
}

// MARK: - UseBy Sub Views
struct UseByExpiryView: View {
    @Binding var showingScanner: Bool
    @Binding var showingCamera: Bool
    @Binding var selectedTab: TabItem

    @State private var useByItems: [UseByInventoryItem] = []
    @State private var isLoading: Bool = false
    @State private var isRefreshing: Bool = false
    @State private var showClearAlert: Bool = false
    @State private var showingAddSheet: Bool = false
    @State private var searchText: String = ""
    @State private var hasLoadedOnce = false // PERFORMANCE: Guard flag to prevent redundant loads

    private var sortedItems: [UseByInventoryItem] {
        let filtered = searchText.isEmpty ? useByItems : useByItems.filter { item in
            item.name.localizedCaseInsensitiveContains(searchText) ||
            (item.brand?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
        return filtered.sorted { $0.expiryDate < $1.expiryDate }
    }

    private var expiringSoonCount: Int {
        useByItems.filter { $0.daysUntilExpiry <= 3 }.count
    }

    var body: some View {
        Group {
            if useByItems.isEmpty && !isLoading {
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
                            // Set useBy as default destination
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

                                TextField("Search your useBy...", text: $searchText)
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
                            .background(Color.adaptiveCard)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        // Stats cards
                        HStack(spacing: 12) {
                            UseByStatCard(
                                title: "Total Items",
                                value: "\(sortedItems.count)",
                                icon: "refrigerator.fill",
                                color: .blue,
                                subtitle: sortedItems.count == 0 ? "No items yet" : "In your useBy"
                            )

                            UseByStatCard(
                                title: "≤3 Days Left",
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
                                .background(Color.adaptiveCard)
                            } else {
                                LazyVStack(spacing: 0) {
                                    ForEach(sortedItems, id: \.id) { item in
                                        CleanUseByRow(item: item)

                                        if item.id != sortedItems.last?.id {
                                            Divider()
                                                .padding(.leading, 76)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                                .background(Color.adaptiveCard)
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
        .onAppear {
            // PERFORMANCE: Skip if already loaded - prevents redundant Firebase calls on tab switches
            guard !hasLoadedOnce else {
        // DEBUG LOG: print("⚡️ UseByExpiryView: Skipping load - data already loaded (count: \(useByItems.count))")
                return
            }
            hasLoadedOnce = true
            Task { await reloadUseBy() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .useByInventoryUpdated)) { _ in
            hasLoadedOnce = false // Force reload when inventory changes
            Task { await reloadUseBy() }
        }
        .alert("Clear all Use By items?", isPresented: $showClearAlert) {
            Button("Delete All", role: .destructive) {
                Task {
                    try? await FirebaseManager.shared.clearUseByInventory()
                    await reloadUseBy()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all items from your useBy inventory.")
        }
        .fullScreenCover(isPresented: $showingAddSheet) {
            AddUseByItemSheet()
        }
    } // End of var body: some View

    private func reloadUseBy() async {
        await MainActor.run { self.isLoading = true }
        do {
            let items: [UseByInventoryItem] = try await FirebaseManager.shared.getUseByItems()
        // DEBUG LOG: print("🍳 UseByView: Loaded \(items.count) items from Firebase")
            for item in items {
                print("  - \(item.name): \(item.daysUntilExpiry) days left")
            }
            await MainActor.run {
                self.useByItems = items
                self.isLoading = false
        // DEBUG LOG: print("🍳 UseByView: useByItems set to \(self.useByItems.count) items")
        // DEBUG LOG: print("🍳 UseByView: sortedItems has \(self.sortedItems.count) items")
            }
        } catch {
            print("❌ UseByView: Error loading items: \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
}

// MARK: - UseBy Expiry Alert Cards

struct UseByExpiryAlertsCard: View {
    let items: [UseByInventoryItem]
    @State private var selectedFilter: ExpiryFilter = .all
    @State private var showingAddSheet = false
    @Binding var selectedTab: TabItem
    var onClearAll: () -> Void

    enum ExpiryFilter: String, CaseIterable {
        case all = "All Items"
        case expiring = "Days Left"
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
        items.filter { $0.expiryStatus == .expiringSoon || $0.expiryStatus == .expiringThisWeek }.count
    }

    private var daysLeftTitle: String {
        let weekItems = items.filter { $0.expiryStatus == .expiringSoon || $0.expiryStatus == .expiringThisWeek }
        guard !weekItems.isEmpty else { return "7 Days Left" }
        let minDays = weekItems.map { $0.daysUntilExpiry }.min() ?? 7
        let maxDays = weekItems.map { $0.daysUntilExpiry }.max() ?? 7
        if minDays == maxDays {
            return "\(minDays) \(minDays == 1 ? "Day" : "Days") Left"
        } else {
            return "\(minDays)-\(maxDays) Days Left"
        }
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

                    Button(action: {
                        UserDefaults.standard.set("Use By", forKey: "preselectedDestination")
                        selectedTab = .add
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }) {
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
                    title: daysLeftTitle,
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
            AddUseByItemSheet()
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

struct UseByItemsListCard: View {
    let items: [UseByInventoryItem]

    private var sortedItems: [UseByInventoryItem] {
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
                UseByEmptyStateView()
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

struct UseByCriticalExpiryCard: View {
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
                    let demoItem = UseByInventoryItem(
                        id: "demo-\(index)",
                        name: ["Greek Yoghurt", "Chicken Breast", "Baby Spinach"][index],
                        brand: ["Fage", "Organic Valley", "Fresh Express"][index],
                        quantity: ["2 cups", "1.5 lbs", "5 oz bag"][index],
                        expiryDate: Calendar.current.date(byAdding: .day, value: index, to: Date()) ?? Date(),
                        addedDate: Date(),
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

struct UseByWeeklyExpiryCard: View {
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

                    Text("Days Left")
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

// MARK: - UseBy Empty State Component

struct UseByEmptyStateView: View {
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
        }
        .onReceive(Timer.publish(every: 3, on: .main, in: .common).autoconnect()) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentTip = (currentTip + 1) % tips.count
            }
        }
    }
}


// MARK: - UseBy Expiry Item Management

struct ModernExpiryRow: View {
    let item: UseByInventoryItem
    @State private var showingDetail = false
    @State private var showingDeleteAlert = false

    private var daysLeft: Int { item.daysUntilExpiry }
    private var brandText: String { item.brand ?? "" }

    private var urgencyColor: Color {
        item.expiryStatus.color
    }

    private var urgencyText: String {
        switch daysLeft {
        case 0: return "Last day"
        case 1: return "Tomorrow"
        case 2...7: return "\(daysLeft) days"
        case 8...30: return "\(daysLeft) days"
        default:
            if daysLeft > 14 {
                let weeks = daysLeft / 7
                return "\(weeks) weeks"
            }
            return "\(daysLeft) days"
        }
    }

    private var urgencyIcon: String {
        switch item.expiryStatus {
        case .expired, .expiringToday:
            return "exclamationmark.circle.fill"
        case .expiringSoon:
            return "clock.fill"
        case .expiringThisWeek:
            return "calendar"
        case .fresh:
            return "checkmark.circle.fill"
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
            UseByItemDetailView(item: item)
        }
        .alert("Delete Item", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) { confirmDelete() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \(item.name) from your useBy inventory?")
        }
    }

    private func markAsUsed() {
        // Haptic feedback for success action
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        Task {
            try? await FirebaseManager.shared.deleteUseByItem(itemId: item.id)
            NotificationCenter.default.post(name: .useByInventoryUpdated, object: nil)
        }
    }

    private func extendExpiry() {
        // Haptic feedback for neutral action
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        let calendar = Calendar.current
        let newExpiry = calendar.date(byAdding: .day, value: 3, to: item.expiryDate) ?? item.expiryDate
        let updated = UseByInventoryItem(
            id: item.id,
            name: item.name,
            brand: item.brand,
            quantity: item.quantity,
            expiryDate: newExpiry,
            addedDate: item.addedDate,
            barcode: item.barcode,
            category: item.category,
            imageURL: item.imageURL,
            notes: item.notes
        )
        Task {
            try? await FirebaseManager.shared.updateUseByItem(updated)
            NotificationCenter.default.post(name: .useByInventoryUpdated, object: nil)
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
            try? await FirebaseManager.shared.deleteUseByItem(itemId: item.id)

            // Cancel use-by notifications for this item
            UseByNotificationManager.shared.cancelNotifications(for: item.id)

            NotificationCenter.default.post(name: .useByInventoryUpdated, object: nil)
        }
    }
}

// Removed UseByExpiryDayRow - replaced with expandable day sections in UseByWeeklyExpiryCard

struct UseByFreshItemsCard: View {
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

// MARK: - UseBy Quick Add Interface

struct UseByQuickAddCard: View {
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
            AddUseByItemSheet()
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

struct UseByBarcodeScanSheet: View {
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
            AddFoundFoodToUseBySheet(food: food)
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

struct AddUseByItemSheet: View {
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
                        UseByInlineSearchView()
                    case .manual:
                        UseByItemDetailView(item: nil)
                    case .barcode:
                        UseByBarcodeScanSheet()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
.navigationBarHidden(true)
            .toolbar { }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onReceive(NotificationCenter.default.publisher(for: .useByInventoryUpdated)) { _ in
            Task { @MainActor in
                dismiss()
            }
        }
    }
}

// Inline search content for Add-to-UseBy sheet, without its own navigation bar
struct UseByInlineSearchView: View {
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
                    .textInputAutocapitalization(.never)
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
                VStack(spacing: 0) {
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
            // For UseBy flow, open the expiry-tracking add form directly
            AddFoundFoodToUseBySheet(food: food)
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
            print("UseBy inline search error: \(error)")
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

// MARK: - Preview Support

#if DEBUG
struct UseByTabView_Previews: PreviewProvider {
    static var previews: some View {
        UseByTabView(
            showingSettings: .constant(false),
            selectedTab: .constant(.useBy)
        )
    }
}
#endif

// Fallback inline implementation to ensure sheet compiles within this target
struct UseBySearchSheet: View {
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
                        .textInputAutocapitalization(.never)
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
            AddFoundFoodToUseBySheet(food: selectedFood)
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
            print("UseBy search error: \(error)")
            await MainActor.run { self.isSearching = false }
        }
    }
}

// MARK: - UseBy Item Detail View Components

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

// MARK: - UseBy Item Detail View
struct UseByItemDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    let item: UseByInventoryItem? // Optional for add mode

    @State private var editedName: String = ""
    @State private var editedBrand: String = ""
    @State private var editedQuantity: String = ""
    @State private var editedExpiryDate: Date = Date()


    @State private var notes: String = ""
    @State private var isSaving: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var animateIn: Bool = false
    @State private var pulseAnimation: Bool = false

    // New expiry selector states
    @State private var expiryMode: ExpiryMode = .selector
    @State private var expiryAmount: Int = 7
    @State private var expiryUnit: ExpiryUnit = .days

    // Photo capture states
    @State private var capturedImage: UIImage?
    @State private var showCameraPicker: Bool = false
    @State private var showPhotoPicker: Bool = false
    @State private var showPhotoActionSheet: Bool = false
    @State private var isUploadingPhoto: Bool = false
    @State private var uploadedImageURL: String?

    // Computed properties that work for both add and edit modes
    private var isAddMode: Bool { item == nil }
    private var itemName: String { isAddMode ? editedName : item!.name }
    private var brand: String? {
        if isAddMode {
            return editedBrand.isEmpty ? nil : editedBrand
        }
        return item!.brand
    }
    private var daysLeft: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expiry = calendar.startOfDay(for: editedExpiryDate)
        let components = calendar.dateComponents([.day], from: today, to: expiry)
        return components.day ?? 0
    }
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
        let totalShelfLife = max(daysLeft + 7, 1)
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
                            if isAddMode {
                                TextField("Item name", text: $editedName)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)

                                TextField("Brand (optional)", text: $editedBrand)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            } else {
                                Text(itemName)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)

                                if let brand = brand, !brand.isEmpty {
                                    Text(brand)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                            }

                            HStack(spacing: 12) {
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


                    // Notes Field
                    VStack(alignment: .leading, spacing: 8) {
                        Label("NOTES", systemImage: "note.text")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)

                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $notes)
                                .font(.system(size: 14))
                                .frame(minHeight: 80)
                                .padding(4)
                                .scrollContentBackground(.hidden)
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(12)

                            if notes.isEmpty {
                                Text("Add notes about this item...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                                    .allowsHitTesting(false)
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
                    .animation(.spring(response: 0.5).delay(0.2), value: animateIn)

                    // Photo Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("PHOTO", systemImage: "camera.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)

                        if let displayImage = capturedImage ?? loadImageFromURL() {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: displayImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 200)
                                    .clipped()
                                    .cornerRadius(12)

                                Button(action: {
                                    capturedImage = nil
                                    uploadedImageURL = nil
                                    Task { await deletePhotoOnly() }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                }
                                .padding(8)
                            }
                        }

                        Button(action: { showPhotoActionSheet = true }) {
                            HStack {
                                if isUploadingPhoto {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: capturedImage != nil || uploadedImageURL != nil ? "camera.fill" : "camera")
                                    Text(capturedImage != nil || uploadedImageURL != nil ? "Change Photo" : "Add Photo")
                                }
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isUploadingPhoto)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .scaleEffect(animateIn ? 1 : 0.95)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(0.225), value: animateIn)

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
                                    Text(isAddMode ? "Add Item" : "Save Changes")
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
                        .disabled(isSaving || (isAddMode && editedName.isEmpty))

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
            .navigationTitle(isAddMode ? "Add Item" : "Manage Item")
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
            if let item = item {
                // Edit mode: Initialize state from item
                editedName = item.name
                editedBrand = item.brand ?? ""
                editedQuantity = item.quantity
                editedExpiryDate = item.expiryDate
                notes = item.notes ?? ""
                uploadedImageURL = item.imageURL

                // Load existing photo from URL if available
                if let imageURL = item.imageURL, capturedImage == nil {
                    Task {
                        await loadExistingPhoto(from: imageURL)
                    }
                }

                // Initialize expiry selector from actual expiry date
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let expiry = calendar.startOfDay(for: item.expiryDate)
                let actualDaysLeft = calendar.dateComponents([.day], from: today, to: expiry).day ?? 7
                expiryAmount = max(actualDaysLeft, 1)
                expiryUnit = actualDaysLeft > 14 ? .weeks : .days
                if expiryUnit == .weeks {
                    expiryAmount = expiryAmount / 7
                }
            } else {
                // Add mode: Set defaults
                editedQuantity = "1"
                expiryMode = .selector
                expiryAmount = 7
                expiryUnit = .days
                // Set expiry date based on selector values
                updateExpiryDate()
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
        .confirmationDialog("Add Photo", isPresented: $showPhotoActionSheet) {
            Button("Take Photo") {
                showCameraPicker = true
            }
            Button("Choose from Library") {
                showPhotoPicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showCameraPicker) {
            ImagePicker(selectedImage: nil, sourceType: .camera) { image in
                if let image = image {
                    capturedImage = image
                    Task {
                        await uploadPhoto(image)
                        await MainActor.run {
                            showCameraPicker = false
                        }
                    }
                } else {
                    showCameraPicker = false
                }
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoLibraryPicker { image in
                showPhotoPicker = false
                if let image = image {
                    capturedImage = image
                    Task {
                        await uploadPhoto(image)
                    }
                }
            }
        }
    }

    private func loadImageFromURL() -> UIImage? {
        // If we have uploadedImageURL but no capturedImage, try to load from URL
        // This is a synchronous placeholder - actual loading happens in onAppear
        return nil
    }

    private func loadExistingPhoto(from urlString: String) async {
        // First, try to load from local cache using item ID
        if let item = item {
            if let cachedImage = await ImageCacheManager.shared.loadUseByImage(for: item.id) {
                await MainActor.run {
                    capturedImage = cachedImage
                    print("⚡️ Loaded image from local cache for item: \(item.id)")
                }
                return
            }
        }

        // Fallback to Firebase URL if not in local cache
        guard let url = URL(string: urlString) else { return }
        print("📸 Loading existing photo from Firebase: \(urlString)")

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                await MainActor.run {
                    capturedImage = image
                    print("📸 Photo loaded from Firebase successfully")
                }

                // Cache it locally for next time
                if let item = item {
                    do {
                        try await ImageCacheManager.shared.saveUseByImage(image, for: item.id)
                        print("💾 Cached downloaded image locally for item: \(item.id)")
                    } catch {
                        print("⚠️ Failed to cache downloaded image: \(error)")
                    }
                }
            }
        } catch {
            print("❌ Failed to load existing photo: \(error)")
        }
    }

    private func uploadPhoto(_ image: UIImage) async {
        // No longer upload immediately - just store the image
        // Upload will happen when saving
        isUploadingPhoto = false
        print("📸 Image captured, will cache when saving...")
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

        if isAddMode {
            // Add mode: Create new item
            print("UseByItemDetailView: Creating new item")
            print("UseByItemDetailView: Name: \(editedName)")
            print("UseByItemDetailView: Brand: \(editedBrand)")
            print("UseByItemDetailView: Quantity: \(editedQuantity)")
            print("UseByItemDetailView: Expiry: \(editedExpiryDate)")

            // Generate ID for new item
            let itemId = UUID().uuidString

            // Handle image caching and upload
            var firebaseURL: String? = uploadedImageURL
            if let image = capturedImage, uploadedImageURL == nil {
                // Save to local cache
                do {
                    try await ImageCacheManager.shared.saveUseByImage(image, for: itemId)
                    print("✅ Image cached locally for new item: \(itemId)")
                } catch {
                    print("⚠️ Failed to cache image locally: \(error)")
                }

                // Upload to Firebase for backup/sync
                do {
                    let url = try await FirebaseManager.shared.uploadUseByItemPhoto(image)
                    print("☁️ Image uploaded to Firebase: \(url)")
                    firebaseURL = url
                } catch {
                    print("⚠️ Firebase upload failed (using local cache): \(error)")
                }
            }

            let newItem = UseByInventoryItem(
                id: itemId,
                name: editedName,
                brand: editedBrand.isEmpty ? nil : editedBrand,
                quantity: editedQuantity.isEmpty ? "1" : editedQuantity,
                expiryDate: editedExpiryDate,
                addedDate: Date(),
                barcode: nil,
                category: nil,
                imageURL: firebaseURL,
                notes: notes.isEmpty ? nil : notes
            )

            do {
                try await FirebaseManager.shared.addUseByItem(newItem)
                print("UseByItemDetailView: Item added successfully!")

                // Schedule notifications for new item
                await UseByNotificationManager.shared.scheduleNotifications(for: newItem)
                print("UseByItemDetailView: Notifications scheduled")

                NotificationCenter.default.post(name: .useByInventoryUpdated, object: nil)

                await MainActor.run {
                    isSaving = false

                    // Success haptic
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)

                    dismiss()
                }
            } catch {
                print("❌ UseByItemDetailView: Failed to add useBy item")
                print("❌ Error: \(error)")
                await MainActor.run {
                    isSaving = false
                }
            }
        } else {
            // Edit mode: Update existing item
            guard let item = item else { return }

            print("UseByItemDetailView: Starting save")
            print("UseByItemDetailView: Item ID: \(item.id)")
            print("UseByItemDetailView: Edited quantity: \(editedQuantity)")
            print("UseByItemDetailView: Edited expiry: \(editedExpiryDate)")

            // Handle image caching and upload
            var firebaseURL: String? = uploadedImageURL ?? item.imageURL
            if let image = capturedImage {
                // Check if this is a new image (not previously cached)
                let hasExistingCache = ImageCacheManager.shared.hasUseByImage(for: item.id)
                let isNewImage = !hasExistingCache || uploadedImageURL == nil

                if isNewImage {
                    // Save to local cache
                    do {
                        try await ImageCacheManager.shared.saveUseByImage(image, for: item.id)
                        print("✅ Image cached locally for item: \(item.id)")
                    } catch {
                        print("⚠️ Failed to cache image locally: \(error)")
                    }

                    // Upload to Firebase for backup/sync
                    if uploadedImageURL == nil {
                        do {
                            let url = try await FirebaseManager.shared.uploadUseByItemPhoto(image)
                            print("☁️ Image uploaded to Firebase: \(url)")
                            firebaseURL = url
                        } catch {
                            print("⚠️ Firebase upload failed (using local cache): \(error)")
                        }
                    }
                }
            }

            // Create updated item with edits
            let updatedItem = UseByInventoryItem(
                id: item.id,
                name: item.name,
                brand: item.brand,
                quantity: editedQuantity,
                expiryDate: editedExpiryDate,
                addedDate: item.addedDate,
                barcode: item.barcode,
                category: item.category,
                imageURL: firebaseURL,
                notes: notes.isEmpty ? nil : notes
            )

            // Save to Firebase
            do {
                print("UseByItemDetailView: Calling updateUseByItem")
                try await FirebaseManager.shared.updateUseByItem(updatedItem)
                print("UseByItemDetailView: Update successful!")

                // Reschedule notifications with updated expiry date
                UseByNotificationManager.shared.cancelNotifications(for: item.id)
                await UseByNotificationManager.shared.scheduleNotifications(for: updatedItem)
                print("UseByItemDetailView: Notifications rescheduled")

                NotificationCenter.default.post(name: .useByInventoryUpdated, object: nil)

                await MainActor.run {
                    isSaving = false

                    // Success haptic
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)

                    dismiss()
                }
            } catch {
                print("❌ UseByItemDetailView: Failed to update useBy item")
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

    private func deletePhotoOnly() async {
        // Delete photo from both local cache and Firebase
        guard let item = item else { return }

        // Delete from local cache
        ImageCacheManager.shared.deleteUseByImage(for: item.id)
        print("🗑️ Deleted image from local cache for item: \(item.id)")

        let updatedItem = UseByInventoryItem(
            id: item.id,
            name: item.name,
            brand: item.brand,
            quantity: editedQuantity,
            expiryDate: editedExpiryDate,
            addedDate: item.addedDate,
            barcode: item.barcode,
            category: item.category,
            imageURL: nil, // Remove the photo
            notes: notes.isEmpty ? nil : notes
        )

        do {
            try await FirebaseManager.shared.updateUseByItem(updatedItem)
            NotificationCenter.default.post(name: .useByInventoryUpdated, object: nil)
            print("✅ Photo deleted successfully from Firebase")
        } catch {
            print("❌ Failed to delete photo from Firebase: \(error)")
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

private struct UseByNutrientCard: View {
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

// MARK: - Clean UseBy Row

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

struct CleanUseByRow: View {
    let item: UseByInventoryItem
    @State private var showingDetail = false
    @State private var isPressed = false
    @State private var offset: CGFloat = 0
    @State private var isHorizontalDragging = false

    private var daysLeft: Int { item.daysUntilExpiry }

    private var statusColor: Color {
        item.expiryStatus.color
    }

    private var statusText: String {
        switch item.expiryStatus {
        case .expired: return "Expired"
        case .expiringToday: return "Last day"
        case .expiringSoon: return "\(daysLeft) \(daysLeft == 1 ? "day" : "days") left"
        case .expiringThisWeek: return "\(daysLeft) \(daysLeft == 1 ? "day" : "days") left"
        case .fresh: return "\(daysLeft) days left"
        }
    }

    private var statusIcon: String {
        switch item.expiryStatus {
        case .expired, .expiringToday:
            return "exclamationmark.triangle.fill"
        case .expiringSoon:
            return "clock.badge.exclamationmark"
        case .expiringThisWeek:
            return "calendar"
        case .fresh:
            return "checkmark.seal.fill"
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
            if offset < -1 {
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
                .transition(.opacity)
            }

            // Main content - Modern card design with product image
            HStack(spacing: 12) {
                // Product image or placeholder - using cached image for instant loading
                Group {
                    if item.imageURL != nil {
                        CachedUseByImage(
                            itemId: item.id,
                            imageURL: item.imageURL,
                            width: 56,
                            height: 56,
                            cornerRadius: 10
                        )
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
            .highPriorityGesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { gesture in
                        let dx = gesture.translation.width
                        let dy = gesture.translation.height
                        // Determine if this is a horizontal drag and only capture those
                        // Use stricter threshold to avoid interfering with vertical scrolling
                        if !isHorizontalDragging {
                            if abs(dx) > 20 && abs(dx) > abs(dy) * 2 {
                                // Must be 2x more horizontal than vertical
                                isHorizontalDragging = true
                            } else {
                                // Not clearly horizontal; let ScrollView handle drag
                                return
                            }
                        }

                        if isHorizontalDragging {
                            // Only allow left swipe (negative offset)
                            if dx < 0 {
                                offset = dx
                            }
                        }
                    }
                    .onEnded { gesture in
                        if isHorizontalDragging {
                            let dx = gesture.translation.width
                            if dx < -100 {
                                // Full swipe - delete
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    offset = -UIScreen.main.bounds.width
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    deleteItem()
                                }
                            } else if dx < -40 {
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

                        // Reset for next gesture
                        isHorizontalDragging = false
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
            UseByItemDetailView(item: item)
        }
    }

    private func markAsUsed() {
        Task {
            try? await FirebaseManager.shared.deleteUseByItem(itemId: item.id)
            NotificationCenter.default.post(name: .useByInventoryUpdated, object: nil)
        }
    }

    private func deleteItem() {
        Task {
            try? await FirebaseManager.shared.deleteUseByItem(itemId: item.id)

            // Cancel use-by notifications for this item
            UseByNotificationManager.shared.cancelNotifications(for: item.id)

            NotificationCenter.default.post(name: .useByInventoryUpdated, object: nil)
        }
    }
}

// MARK: - UseBy Stat Card Component

struct UseByStatCard: View {
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
                .fill(Color.adaptiveCard)
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

// MARK: - Photo Library Picker using PHPicker
import PhotosUI

struct PhotoLibraryPicker: UIViewControllerRepresentable {
    let onImageSelected: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        // Use 0 (unlimited) to show "Add" button instead of auto-selecting on tap
        config.selectionLimit = 0
        config.filter = .images
        config.selection = .default
        config.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        print("📸 PHPicker created with config: selectionLimit=0 (shows Add button)")
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryPicker

        init(_ parent: PhotoLibraryPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            print("📸 PHPicker didFinishPicking called with \(results.count) results")

            // User cancelled if no results
            if results.isEmpty {
                print("📸 User cancelled, calling onImageSelected(nil)")
                parent.onImageSelected(nil)
                return
            }

            // Only take the first photo even though we allow multiple selection
            guard let provider = results.first?.itemProvider else {
                print("📸 No item provider, calling onImageSelected(nil)")
                parent.onImageSelected(nil)
                return
            }

            if provider.canLoadObject(ofClass: UIImage.self) {
                print("📸 Loading UIImage from provider...")
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    if let error = error {
                        print("❌ Error loading image: \(error)")
                    }
                    DispatchQueue.main.async {
                        print("📸 Image loaded, calling onImageSelected")
                        self.parent.onImageSelected(image as? UIImage)
                    }
                }
            } else {
                print("❌ Provider cannot load UIImage")
                parent.onImageSelected(nil)
            }
        }
    }
}

// MARK: - Cached Image Component

/// Cached async image view for UseBy items - checks local cache first
struct CachedUseByImage: View {
    let itemId: String
    let imageURL: String?
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    @State private var loadedImage: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                // Placeholder while loading
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(.systemGray5))
                    .frame(width: width, height: height)
                    .overlay(
                        Group {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                            } else {
                                Image(systemName: "photo")
                                    .font(.system(size: width * 0.4))
                                    .foregroundColor(.gray)
                            }
                        }
                    )
            }
        }
        .task {
            await loadImage()
        }
    }

    @MainActor
    private func loadImage() async {
        // Check if already loaded
        guard loadedImage == nil else { return }

        isLoading = true

        // 1. Try local cache first (instant!)
        if let cachedImage = await ImageCacheManager.shared.loadUseByImage(for: itemId) {
            loadedImage = cachedImage
            isLoading = false
            print("⚡️ Loaded UseBy thumbnail from cache: \(itemId)")
            return
        }

        // 2. Load from Firebase URL if not cached
        guard let imageURL = imageURL, let url = URL(string: imageURL) else {
            isLoading = false
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                loadedImage = image

                // Cache for next time
                do {
                    try await ImageCacheManager.shared.saveUseByImage(image, for: itemId)
                    print("💾 Cached downloaded UseBy thumbnail: \(itemId)")
                } catch {
                    print("⚠️ Failed to cache thumbnail: \(error)")
                }
            }
        } catch {
            print("❌ Failed to load image from URL: \(error)")
        }

        isLoading = false
    }
}
