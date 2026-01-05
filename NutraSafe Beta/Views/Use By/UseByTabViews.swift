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
    @Environment(\.colorScheme) var colorScheme
    @Binding var showingSettings: Bool
    @Binding var selectedTab: TabItem
    @State private var showingScanner = false
    @State private var showingCamera = false
    @State private var showingAddSheet = false
    @State private var selectedFoodForUseBy: FoodSearchResult? // Hoisted to avoid nested presentations

    // Temporary header counter until data is lifted to parent scope
    private var expiringSoonCount: Int { 0 }

    var body: some View {
        navigationContainer {
            VStack(spacing: 0) {
                // Header - AAA Modern Design
                HStack(spacing: 12) {
                    Text("Use By")
                        .font(AppTypography.largeTitle())
                        .frame(height: 44, alignment: .center)
                        .foregroundColor(.primary)

                    Spacer()

                        Button(action: { showingSettings = true }) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.cardBackgroundInteractive)
                                    .frame(width: 44, height: 44)
                                    .overlay(Circle().stroke(AppColors.borderLight, lineWidth: 1))
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                        }

                        Button(action: { showingAddSheet = true }) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.primary)
                                    .frame(width: 44, height: 44)
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(SpringyButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)

                ScrollView {
                    LazyVStack(spacing: 0) {
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
            .tabGradientBackground(.useBy)
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingAddSheet) {
            AddUseByItemSheet(onComplete: {
                showingAddSheet = false
            })
        }
        .sheet(isPresented: $showingScanner) {
            // Barcode scanner will be implemented
            Text("Barcode Scanner Coming Soon")
                .font(.title)
                .padding()
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(.systemBackground))
        }
        .sheet(isPresented: $showingCamera) {
            // Camera scanner will be implemented
            Text("Camera Scanner Coming Soon")
                .font(.title)
                .padding()
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(.systemBackground))
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
@Environment(\.colorScheme) var colorScheme
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
        VStack(spacing: 0) {
            // Custom header
            HStack {
                // Lifecycle tracing attached to a visible node
                EmptyView()
                    .onAppear { print("[UseBy] AddFoundFoodToUseBySheet onAppear for \(food.id) \(food.name)") }
                    .onDisappear { print("[UseBy] AddFoundFoodToUseBySheet onDisappear for \(food.id) \(food.name)") }
                Button("Cancel") { dismiss() }
                    .font(.system(size: 17))
                    .foregroundColor(.blue)

                Spacer()

                Text("Add to Use By")
                    .font(.system(size: 17, weight: .semibold))

                Spacer()

                Button(action: { Task { await save() } }) {
                    if isSaving || isUploadingPhoto {
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text(isUploadingPhoto ? "Uploading..." : "Saving...")
                                .font(.system(size: 13))
                        }
                    } else {
                        Text("Add")
                            .fontWeight(.semibold)
                            .font(.system(size: 17))
                    }
                }
                .foregroundColor(.blue)
                .disabled(isUploadingPhoto || isSaving)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(colorScheme == .dark ? Color.midnightBackground : Color(.systemBackground))

            Divider()

            ScrollView {
                LazyVStack(spacing: 16) {
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
                        .onChange(of: expiryAmount) { recalcExpiry() }
                        .onChange(of: expiryUnit) { recalcExpiry() }
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
            .background(colorScheme == .dark ? Color.midnightBackground : Color(.systemGroupedBackground))
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
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(.systemBackground))
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
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(.systemBackground))
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
        #if DEBUG
        print("📸 Image captured, will cache when saving...")
        #endif
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
                try await ImageCacheManager.shared.saveUseByImageAsync(image, for: itemId)
                #if DEBUG
                print("✅ Image cached locally for item: \(itemId)")
                #endif
            } catch {
                #if DEBUG
                print("⚠️ Failed to cache image locally: \(error)")
                #endif
            }

            // Upload to Firebase in background for backup/sync
            do {
                let url = try await FirebaseManager.shared.uploadUseByItemPhoto(image)
                #if DEBUG
                print("☁️ Image uploaded to Firebase: \(url)")
                #endif
                firebaseURL = url
            } catch {
                #if DEBUG
                print("⚠️ Firebase upload failed (using local cache): \(error)")
                #endif
            }
        }

        #if DEBUG
        print("📸 Saving useBy item (ID: \(itemId))")

        #endif
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
                #if DEBUG
                print("[UseBy] Save succeeded, dismissing sheet and completing to Use By")
                #endif
                dismiss()
                onComplete?(.useBy)
            }
        } catch {
            let ns = error as NSError
            #if DEBUG
            print("Failed to save useBy item: \(ns)")
            #endif
            await MainActor.run {
                isSaving = false
                // Silently fail for permission errors - just close the sheet
                if ns.domain == "FIRFirestoreErrorDomain" && ns.code == 7 {
                    // Missing permissions - post notifications and dismiss without error
                    NotificationCenter.default.post(name: .useByInventoryUpdated, object: nil)
                    NotificationCenter.default.post(name: .navigateToUseBy, object: nil)
                    #if DEBUG
                    print("[UseBy] Permission error (code 7), navigating to Use By and dismissing sheet")
                    #endif
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
    @Environment(\.scenePhase) var scenePhase
    @Binding var showingScanner: Bool
    @Binding var showingCamera: Bool
    @Binding var selectedTab: TabItem

    // PERFORMANCE: Use shared manager to persist data between tab switches
    @ObservedObject private var dataManager = UseByDataManager.shared

    @State private var isRefreshing: Bool = false
    @State private var showClearAlert: Bool = false
    @State private var showingAddSheet: Bool = false
    @State private var selectedFoodForUseBy: FoodSearchResult? // Hoisted to avoid nested presentations
    @State private var searchText: String = ""

    // PERFORMANCE: Debouncer to prevent search from running on every keystroke
    @StateObject private var searchDebouncer = Debouncer(milliseconds: 300)

    // PERFORMANCE: Cached computed values - only recalculate when data changes
    @State private var cachedSortedItems: [UseByInventoryItem] = []
    @State private var cachedUrgentCount: Int = 0
    @State private var cachedThisWeekCount: Int = 0
    @State private var cachedAdaptiveTitle: String = "All Good"
    @State private var cachedAdaptiveValue: String = "0"
    @State private var cachedAdaptiveIcon: String = "checkmark.circle.fill"
    @State private var cachedAdaptiveColor: Color = .green
    @State private var cachedAdaptiveSubtitle: String = "Nothing expiring soon"

    // PERFORMANCE: Fast O(1) accessors to cached values instead of O(n) computed properties
    private var sortedItems: [UseByInventoryItem] {
        cachedSortedItems
    }

    private var urgentCount: Int {
        cachedUrgentCount
    }

    private var thisWeekCount: Int {
        cachedThisWeekCount
    }

    private var adaptiveTitle: String {
        cachedAdaptiveTitle
    }

    private var adaptiveValue: String {
        cachedAdaptiveValue
    }

    private var adaptiveIcon: String {
        cachedAdaptiveIcon
    }

    private var adaptiveColor: Color {
        cachedAdaptiveColor
    }

    private var adaptiveSubtitle: String {
        cachedAdaptiveSubtitle
    }

    // PERFORMANCE: Recalculate all cached values only when data actually changes
    private func recalculateCache() {
        // Filter and sort items
        let filtered = searchText.isEmpty ? dataManager.items : dataManager.items.filter { item in
            item.name.localizedCaseInsensitiveContains(searchText) ||
            (item.brand?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
        cachedSortedItems = filtered.sorted { $0.expiryDate < $1.expiryDate }

        // Single-pass categorization: count urgent/this week items and find min urgent days
        var urgentCount = 0
        var thisWeekCount = 0
        var minUrgentDays: Int? = nil

        for item in dataManager.items {
            let days = item.daysUntilExpiry
            if days <= 2 {
                urgentCount += 1
                if let currentMin = minUrgentDays {
                    minUrgentDays = min(currentMin, days)
                } else {
                    minUrgentDays = days
                }
            } else if (3...7).contains(days) {
                thisWeekCount += 1
            }
        }

        cachedUrgentCount = urgentCount
        cachedThisWeekCount = thisWeekCount

        // Update adaptive card properties
        if cachedUrgentCount > 0 {
            cachedAdaptiveTitle = "Urgent"
            cachedAdaptiveValue = "\(cachedUrgentCount)"
            cachedAdaptiveIcon = "exclamationmark.triangle.fill"
            cachedAdaptiveColor = .red

            let minDays = minUrgentDays ?? 0
            if minDays <= 1 {
                cachedAdaptiveSubtitle = cachedUrgentCount == 1 ? "Use today" : "Use very soon"
            } else {
                cachedAdaptiveSubtitle = "Within 2 days"
            }
        } else if cachedThisWeekCount > 0 {
            cachedAdaptiveTitle = "This Week"
            cachedAdaptiveValue = "\(cachedThisWeekCount)"
            cachedAdaptiveIcon = "clock.fill"
            cachedAdaptiveColor = .orange
            cachedAdaptiveSubtitle = "Plan to use soon"
        } else {
            cachedAdaptiveTitle = "All Good"
            cachedAdaptiveValue = "0"
            cachedAdaptiveIcon = "checkmark.circle.fill"
            cachedAdaptiveColor = .green
            cachedAdaptiveSubtitle = "Nothing expiring soon"
        }
    }

    // MARK: - View Builders (extracted to help Swift type-checker)
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(.circular)
            Text("Loading your items...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                AnimatedFridgeIcon()
                    .frame(width: 200, height: 200)

                VStack(spacing: 12) {
                    Text("No items yet")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Never forget your food again. Add items to keep track of use-by dates.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                }
            }

            Spacer()

            Button(action: {
                showingAddSheet = true
            }) {
                Text("Add Your First Item")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.7, blue: 0.5),
                                Color(red: 1.0, green: 0.6, blue: 0.7),
                                Color(red: 0.7, green: 0.6, blue: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(28)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var body: some View {
        Group {
            if dataManager.isLoading {
                loadingView
            } else if dataManager.items.isEmpty {
                emptyStateView
            } else {
                // Modern premium design with gradients and depth
                ScrollView {
                    LazyVStack(spacing: 16) {
                        

                        // Ultra-modern compact stat cards
                        HStack(spacing: 10) {
                            CompactStatPill(
                                value: "\(sortedItems.count)",
                                label: "Items",
                                icon: "refrigerator.fill",
                                tint: Color.blue
                            )

                            CompactStatPill(
                                value: adaptiveValue,
                                label: adaptiveTitle == "This Week" ? "This Week" : "Expiring",
                                icon: adaptiveIcon,
                                tint: adaptiveColor
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)

                        // Ultra-modern items container
                        VStack(spacing: 0) {
                            // Modern gradient header
                            HStack {
                                Text("Your Items")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.primary, .primary.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )

                                Spacer()

                                // Modern count badge
                                HStack(spacing: 4) {
                                    Text("\(sortedItems.count)")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color.blue, Color.purple.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    Text("item\(sortedItems.count == 1 ? "" : "s")")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background {
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.blue.opacity(0.12),
                                                    Color.purple.opacity(0.08)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(
                                                    LinearGradient(
                                                        colors: [
                                                            Color.blue.opacity(0.3),
                                                            Color.purple.opacity(0.2)
                                                        ],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    ),
                                                    lineWidth: 1.5
                                                )
                                        )
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.top, 18)
                            .padding(.bottom, 14)

                            // Items list
                            if sortedItems.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.system(size: 60))
                                        .foregroundColor(.secondary.opacity(0.4))
                                        .padding(.top, 20)

                                    VStack(spacing: 8) {
                                        Text("No items tracked")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.primary)

                                        Text("Add use-by dates when logging food to avoid waste")
                                            .font(.system(size: 15))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 40)
                                    }

                                    // Helpful tip
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack(alignment: .top, spacing: 12) {
                                            Image(systemName: "lightbulb.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.orange)
                                                .frame(width: 20)

                                            Text("Tap the + button above to start tracking items and get notified before they expire")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                    .padding(14)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .padding(.horizontal, 30)
                                    .padding(.bottom, 20)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                LazyVStack(spacing: 8) {
                                    ForEach(sortedItems, id: \.id) { item in
                                        CleanUseByRow(item: item)
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(AppColors.cardBackgroundElevated)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .transaction { $0.disablesAnimations = true }
        .animation(nil, value: cachedSortedItems)
        .animation(nil, value: searchText)
        .onAppear {
            Task {
                if !dataManager.isLoaded {
                    await dataManager.loadItems()
                }
                recalculateCache()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .useByInventoryUpdated)) { _ in
            // Force reload when inventory changes
            Task { await dataManager.forceReload() }
        }
        // PERFORMANCE: Recalculate cached values only when data actually changes
        .onChange(of: dataManager.items) {
            recalculateCache()
        }
        .onChange(of: searchText) {
            // PERFORMANCE: Debounce search to avoid running expensive operations on every keystroke
            searchDebouncer.debounce {
                recalculateCache()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Recalculate days remaining when app becomes active (e.g., after overnight)
            if newPhase == .active {
                recalculateCache()
            }
        }
        .alert("Clear all Use By items?", isPresented: $showClearAlert) {
            Button("Delete All", role: .destructive) {
                Task {
                    try? await FirebaseManager.shared.clearUseByInventory()
                    await dataManager.forceReload()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all items from your useBy inventory.")
        }
        .fullScreenCover(isPresented: $showingAddSheet) {
            AddUseByItemSheet(onComplete: {
                showingAddSheet = false
            })
        }
    } // End of var body: some View
}

// MARK: - UseBy Expiry Alert Cards

struct UseByExpiryAlertsCard: View {
    let items: [UseByInventoryItem]
    @State private var selectedFilter: ExpiryFilter = .all
    @State private var showingAddSheet = false
    @State private var selectedFoodForUseBy: FoodSearchResult? // Hoisted to avoid nested presentations
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
            AddUseByItemSheet(onComplete: {
                showingAddSheet = false
            })
        }
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
    @Environment(\.colorScheme) var colorScheme

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
                .background(colorScheme == .dark ? Color.midnightCard : Color(.systemBackground))
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
    @Environment(\.colorScheme) var colorScheme

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
            .background(colorScheme == .dark ? Color.midnightCard : Color(.systemBackground))
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
    @Environment(\.colorScheme) var colorScheme

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
            .background(colorScheme == .dark ? Color.midnightCard : Color(.systemBackground))
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
    var onAddFirstItem: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 24) {
            AnimatedFridgeIcon()
                .frame(width: 160, height: 160)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("No items yet")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Text("Never forget your food again. Add items to keep track of use-by dates.")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
            }

            Button(action: { onAddFirstItem?() }) {
                Text("Add Your First Item")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.7, blue: 0.5),
                                Color(red: 1.0, green: 0.6, blue: 0.7),
                                Color(red: 0.7, green: 0.6, blue: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(24)
                    .accessibilityLabel("Add your first use-by item")
            }
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }
}


// MARK: - UseBy Expiry Item Management

struct ModernExpiryRow: View {
    let item: UseByInventoryItem
    @Environment(\.colorScheme) var colorScheme
    @State private var showingDetail = false
    @State private var showingDeleteAlert = false

    private var daysLeft: Int { item.daysUntilExpiry }
    private var brandText: String { item.brand ?? "" }

    private var urgencyColor: Color {
        item.expiryStatus.color
    }

    private var urgencyText: String {
        switch daysLeft {
        case ..<0: return "Expired"
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
            .background(colorScheme == .dark ? Color.midnightCard : Color(.systemBackground))
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
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(.systemBackground))
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
    @Environment(\.colorScheme) var colorScheme

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
                .background(colorScheme == .dark ? Color.midnightCard : Color(.systemBackground))
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
    @State private var selectedFoodForUseBy: FoodSearchResult? // Hoisted to avoid nested presentations

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
            AddUseByItemSheet(onComplete: {
                showingAddSheet = false
            })
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
    @Environment(\.colorScheme) var colorScheme
    @State private var isSearching = false
    @State private var scannedFood: FoodSearchResult?
    @State private var errorMessage: String?
    @State private var showAddForm = false
    @State private var pendingContribution: PendingFoodContribution?

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
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(.systemBackground))
        }
        .sheet(isPresented: $showAddForm) {
            VStack(spacing: 16) {
                Image(systemName: "square.and.pencil").font(.system(size: 50)).foregroundColor(.blue)
                Text("Product Not Found").font(.system(size: 20, weight: .semibold))
                if let pending = pendingContribution {
                    Text("Barcode: \(pending.barcode)").font(.system(size: 14, design: .monospaced)).foregroundColor(.secondary)
                }
                Button("Close") { showAddForm = false }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(colorScheme == .dark ? Color.midnightBackground : Color(.systemBackground))
            .presentationDragIndicator(.visible)
            .presentationBackground(Color(.systemBackground))
        }
    }

    private func lookup(barcode: String) async {
        guard !isSearching else { return }
        await MainActor.run {
            self.isSearching = true
            self.errorMessage = nil
        }
        // First: Algolia exact barcode lookup (fast path)
        do {
            if let found = try await AlgoliaSearchManager.shared.searchByBarcode(barcode) {
                await MainActor.run {
                    self.scannedFood = found
                    self.isSearching = false
                }
                return
            }
        } catch {
            // Ignore and continue to fallback
        }

        // Fallback: Cloud Function that itself falls back to OpenFoodFacts
        do {
            if let remote = try await searchProductByBarcodeRemote(barcode) {
                await MainActor.run {
                    self.scannedFood = remote
                    self.isSearching = false
                }
            } else {
                await MainActor.run {
                    self.isSearching = false
                    self.errorMessage = "Product not found. Try another scan or add manually."
                    self.pendingContribution = PendingFoodContribution(placeholderId: "", barcode: barcode)
                    self.showAddForm = true
                }
            }
        } catch {
            await MainActor.run {
                self.isSearching = false
                self.errorMessage = "Lookup failed. Please try again."
            }
        }
    }

    private func searchProductByBarcodeRemote(_ barcode: String) async throws -> FoodSearchResult? {
        guard let url = URL(string: "https://us-central1-nutrasafe-705c7.cloudfunctions.net/searchFoodByBarcode") else {
            throw NSError(domain: "InvalidURL", code: 0)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["barcode": barcode])

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        if let resp = try? decoder.decode(BarcodeSearchResponse.self, from: data) {
            if resp.success, let food = resp.toFoodSearchResult() { return food }
            if resp.action == "user_contribution_needed" {
                self.pendingContribution = PendingFoodContribution(placeholderId: resp.placeholder_id ?? "", barcode: barcode)
            }
            return nil
        }
        // Fallback: manual JSON parse
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let success = json["success"] as? Bool ?? false
            if success, let foodDict = json["food"] as? [String: Any] {
                // Minimal mapping to FoodSearchResult
                let food = try JSONSerialization.data(withJSONObject: foodDict)
                return try? JSONDecoder().decode(FoodSearchResult.self, from: food)
            }
        }
        return nil
    }
}

struct AddUseByItemSheet: View {
    @Environment(\.dismiss) var dismiss
    var onComplete: (() -> Void)? = nil
    @State private var showingManualAdd = false
    @State private var showingSearch = false
    @State private var showingBarcodeScan = false
    @State private var selectedOption: UseByAddOption = .search
    @State private var keyboardVisible = false

    enum UseByAddOption: String, CaseIterable {
        case search = "Search"
        case manual = "Manual"
        case barcode = "Barcode"

        var icon: String {
            switch self {
            case .search: return "magnifyingglass"
            case .manual: return "square.and.pencil"
            case .barcode: return "barcode.viewfinder"
            }
        }
    }

    // Lightweight button component matching Diary's OptionSelectorButton
    private struct UseByOptionSelectorButton: View {
        @Environment(\.colorScheme) var colorScheme
        let title: String
        let icon: String
        let isSelected: Bool
        let onTap: () -> Void

        var body: some View {
            Button(action: { onTap() }) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? (colorScheme == .dark ? Color.midnightBackground : Color.blue) : Color(.systemGray6))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Header with tab-style options
                    VStack(spacing: 12) {
                        // Option selector - tab-style buttons
                        HStack(spacing: 0) {
                            UseByOptionSelectorButton(
                                title: "Search",
                                icon: "magnifyingglass",
                                isSelected: selectedOption == .search
                            ) {
                                print("🔵 [UseBy] Search option tapped")
                                selectedOption = .search
                            }
                            UseByOptionSelectorButton(
                                title: "Manual",
                                icon: "square.and.pencil",
                                isSelected: selectedOption == .manual
                            ) {
                                print("🔵 [UseBy] Manual option tapped")
                                selectedOption = .manual
                            }
                            UseByOptionSelectorButton(
                                title: "Barcode",
                                icon: "barcode.viewfinder",
                                isSelected: selectedOption == .barcode
                            ) {
                                print("🔵 [UseBy] Barcode option tapped")
                                selectedOption = .barcode
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                    .background(Color.adaptiveBackground)
                    .zIndex(999)
                    .allowsHitTesting(true)

                    // Content based on selected option
                    Group {
                        switch selectedOption {
                        case .search:
                            UseByInlineSearchView(onComplete: onComplete)
                        case .manual:
                            UseByItemDetailView(item: nil, onComplete: {
                                dismiss()
                                onComplete?()
                            })
                        case .barcode:
                            UseByBarcodeScanSheet()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .zIndex(0)
                }
                .background(Color.adaptiveBackground)
            }
            .navigationTitle("Add to Use By")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("🔴 [UseBy] Close button tapped")
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .onAppear {
            print("🟢 [UseBy] AddUseByItemSheet APPEARED")
        }
        .onDisappear {
            print("🔴 [UseBy] AddUseByItemSheet DISAPPEARED")
        }
        .onChange(of: selectedOption) { _, newOption in
            print("🔄 [UseBy] Selected option changed to: \(newOption)")
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

// Inline search content for Add-to-UseBy sheet, without its own navigation bar
struct UseByInlineSearchView: View {
    var onComplete: (() -> Void)? = nil
    @State private var query: String = ""
    @State private var isSearching = false
    @State private var results: [FoodSearchResult] = []
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var showingFoodDetail = false
    @State private var selectedFood: FoodSearchResult?

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            ZStack(alignment: .trailing) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search products", text: $query)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .padding(.trailing, 28)
                        .onChange(of: query) { _, newValue in
                            searchTask?.cancel()
                            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard trimmed.count >= 2 else { self.results = []; self.isSearching = false; return }
                            searchTask = Task {
                                try? await Task.sleep(nanoseconds: 300_000_000)
                                await runSearch(trimmed)
                            }
                        }
                }
                if !query.isEmpty {
                    Button(action: { query = ""; results = [] }) {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                    .padding(.trailing, 4)
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
                            print("🔵 [UseBy Search] Food item tapped: \(food.name)")
                            print("🔵 [UseBy Search] Current selectedFood before assignment: \(selectedFood?.name ?? "nil")")
                            print("🔵 [UseBy Search] Current showingFoodDetail before assignment: \(showingFoodDetail)")
                            selectedFood = food
                            showingFoodDetail = true
                            print("🔵 [UseBy Search] selectedFood after assignment: \(selectedFood?.name ?? "nil")")
                            print("🔵 [UseBy Search] showingFoodDetail after assignment: \(showingFoodDetail)")
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
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color.adaptiveBackground)
        .sheet(isPresented: $showingFoodDetail) {
            if let food = selectedFood {
                UseByFoodDetailSheet(food: food, onComplete: onComplete)
                    .onAppear {
                        print("🟢 [UseBy Search] UseByFoodDetailSheet appeared for: \(food.name)")
                    }
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Color(.systemBackground))
            }
        }
        .onChange(of: showingFoodDetail) { _, newValue in
            print("🔄 [UseBy Search] showingFoodDetail changed to: \(newValue)")
            if newValue {
                print("🔄 [UseBy Search] selectedFood when showing sheet: \(selectedFood?.name ?? "nil")")
            }
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
            #if DEBUG
            print("UseBy inline search error: \(error)")
            #endif
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
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(.systemBackground))
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
            #if DEBUG
            print("UseBy search error: \(error)")
            #endif
            await MainActor.run { self.isSearching = false }
        }
    }
}

// MARK: - UseBy Item Detail View Components

struct FreshnessIndicatorView: View {
    let freshnessScore: Double
    let freshnessColor: Color
    let freshnessEmoji: String
    let freshnessLabel: String
    let daysLeft: Int
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
                Text(daysLeftText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(freshnessColor)
                Text(freshnessLabel)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .scaleEffect(pulseAnimation ? 1.05 : 1.0)
        }
    }

    var daysLeftText: String {
        if daysLeft < 0 {
            return "Expired"
        } else if daysLeft == 0 {
            return "Today"
        } else if daysLeft == 1 {
            return "1 day"
        } else {
            return "\(daysLeft) days"
        }
    }
}

// MARK: - UseBy Food Detail Sheet (from Search)

/// Food detail sheet for Use By - shows food info and allows adding to Use By inventory
struct UseByFoodDetailSheet: View {
    let food: FoodSearchResult
    var onComplete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var quantity: String = "1"
    @State private var expiryDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var location: String = ""
    @State private var notes: String = ""
    @State private var isSaving = false
    @State private var expiryMode: ExpiryMode = .selector
    @State private var expiryAmount: Int = 7
    @State private var expiryUnit: ExpiryUnit = .days

    enum ExpiryMode {
        case calendar
        case selector
    }

    enum ExpiryUnit: String, CaseIterable {
        case days = "Days"
        case weeks = "Weeks"
        case months = "Months"
    }

    private var calculatedExpiryDate: Date {
        let calendar = Calendar.current
        let baseDate = Date()

        switch expiryUnit {
        case .days:
            return calendar.date(byAdding: .day, value: expiryAmount, to: baseDate) ?? baseDate
        case .weeks:
            return calendar.date(byAdding: .day, value: expiryAmount * 7, to: baseDate) ?? baseDate
        case .months:
            return calendar.date(byAdding: .month, value: expiryAmount, to: baseDate) ?? baseDate
        }
    }

    private var daysLeft: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expiry = calendar.startOfDay(for: expiryMode == .selector ? calculatedExpiryDate : expiryDate)
        let components = calendar.dateComponents([.day], from: today, to: expiry)
        return components.day ?? 0
    }

    private var freshnessScore: Double {
        let totalShelfLife = max(daysLeft + 8, 1)
        let remaining = max(daysLeft + 1, 0)
        return Double(remaining) / Double(totalShelfLife)
    }

    private var freshnessColor: Color {
        if freshnessScore > 0.7 { return .green }
        else if freshnessScore > 0.4 { return .yellow }
        else if freshnessScore > 0.2 { return .orange }
        else { return .red }
    }

    private var freshnessEmoji: String {
        if freshnessScore > 0.7 { return "👍" }
        else if freshnessScore > 0.4 { return "👍" }
        else if freshnessScore > 0.2 { return "⚠️" }
        else { return "🚨" }
    }

    private var freshnessLabel: String {
        switch daysLeft {
        case ..<0: return "Expired"
        case 0: return "Last day"
        default: return "Fresh"
        }
    }

    private var smartRecommendation: String {
        switch daysLeft {
        case ..<0: return "Expired - discard item"
        case 0: return "Last day - use today"
        case 1: return "Perfect for tomorrow"
        case 2...3: return "Plan to use within next few meals"
        case 4...7: return "Still fresh - use this week"
        default: return "Plenty of time - store properly"
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Top Product Card with Freshness Indicator
                    HStack(spacing: 16) {
                        // Freshness Indicator
                        FreshnessIndicatorView(
                            freshnessScore: freshnessScore,
                            freshnessColor: freshnessColor,
                            freshnessEmoji: freshnessEmoji,
                            freshnessLabel: freshnessLabel,
                            daysLeft: daysLeft,
                            pulseAnimation: .constant(false)
                        )

                        // Product Info
                        VStack(alignment: .leading, spacing: 6) {
                            Text(food.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)

                            if let brand = food.brand, !brand.isEmpty {
                                Text(brand)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: 12) {
                                Label(daysLeft < 0 ? "Expired" : (daysLeft == 0 ? "Last day" : "\(daysLeft) days"), systemImage: "calendar")
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

                    // Expiry Date Section
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
                            DatePicker("", selection: $expiryDate, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .labelsHidden()
                        } else {
                            // Selector Mode
                            HStack(spacing: 12) {
                                // Amount stepper
                                HStack {
                                    Button(action: {
                                        if expiryAmount > 1 {
                                            expiryAmount -= 1
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(.blue)
                                    }

                                    Text("\(expiryAmount)")
                                        .font(.system(size: 28, weight: .bold))
                                        .frame(minWidth: 50)

                                    Button(action: {
                                        expiryAmount += 1
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(.blue)
                                    }
                                }

                                // Unit picker
                                Picker("", selection: $expiryUnit) {
                                    ForEach(ExpiryUnit.allCases, id: \.self) { unit in
                                        Text(unit.rawValue).tag(unit)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            .padding(.vertical, 8)

                            Text("Expires: \(calculatedExpiryDate, style: .date)")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    // Notes Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("NOTES", systemImage: "note.text")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)

                        TextEditor(text: $notes)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(8)
                            .overlay(
                                Group {
                                    if notes.isEmpty {
                                        Text("Add notes about this item...")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 14))
                                            .padding(.leading, 12)
                                            .padding(.top, 16)
                                            .allowsHitTesting(false)
                                    }
                                },
                                alignment: .topLeading
                            )
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    // Save Button
                    Button(action: saveToUseBy) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                Text("Add to Use By")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .disabled(isSaving || food.name.isEmpty)
                    .opacity((isSaving || food.name.isEmpty) ? 0.6 : 1.0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .background(colorScheme == .dark ? Color.midnightBackground : Color(.systemBackground))
    }

    private func saveToUseBy() {
        guard !food.name.isEmpty else { return }

        isSaving = true

        Task {
            do {
                let finalExpiryDate = expiryMode == .selector ? calculatedExpiryDate : expiryDate

                let newItem = UseByInventoryItem(
                    id: UUID().uuidString,
                    name: food.name,
                    brand: food.brand,
                    quantity: quantity,
                    expiryDate: finalExpiryDate,
                    addedDate: Date(),
                    barcode: nil,
                    category: nil,
                    imageURL: nil,
                    notes: notes.isEmpty ? nil : notes
                )

                try await FirebaseManager.shared.addUseByItem(newItem)

                await MainActor.run {
                    // Notify Use By tab to refresh
                    NotificationCenter.default.post(name: .useByInventoryUpdated, object: nil)
                    isSaving = false
                    dismiss()
                    onComplete?()
                }
            } catch {
                print("Error saving Use By item: \(error)")
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }
}

// MARK: - UseBy Item Detail View
struct UseByItemDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    let item: UseByInventoryItem? // Optional for add mode
    var onComplete: (() -> Void)? = nil

    @State private var editedName: String
    @State private var editedBrand: String
    @State private var editedQuantity: String
    @State private var editedExpiryDate: Date


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

    // Initializer to properly set initial values
    init(item: UseByInventoryItem? = nil, onComplete: (() -> Void)? = nil) {
        self.item = item
        self.onComplete = onComplete

        // Initialize @State properties based on item (edit mode) or defaults (add mode)
        if let item = item {
            _editedName = State(initialValue: item.name)
            _editedBrand = State(initialValue: item.brand ?? "")
            _editedQuantity = State(initialValue: item.quantity)
            _editedExpiryDate = State(initialValue: item.expiryDate)
            _notes = State(initialValue: item.notes ?? "")
            _uploadedImageURL = State(initialValue: item.imageURL)
        } else {
            _editedName = State(initialValue: "")
            _editedBrand = State(initialValue: "")
            _editedQuantity = State(initialValue: "")
            _editedExpiryDate = State(initialValue: Date().addingTimeInterval(7 * 24 * 60 * 60)) // Default: 7 days from now
            _notes = State(initialValue: "")
            _uploadedImageURL = State(initialValue: nil)
        }
    }

    // Computed properties that work for both add and edit modes
    private var isAddMode: Bool { item == nil }
    private var itemName: String { isAddMode ? editedName : (item?.name ?? "") }
    private var brand: String? {
        if isAddMode {
            return editedBrand.isEmpty ? nil : editedBrand
        }
        return item?.brand
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
        // When daysLeft < 0, item is expired (0%)
        // When daysLeft = 0, item is on last day (show ~12% to indicate still usable but urgent)
        // Add 1 so last day shows some freshness
        let totalShelfLife = max(daysLeft + 8, 1)
        let remaining = max(daysLeft + 1, 0)
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
        case ..<0: return "Expired - discard item"
        case 0: return "Last day - use today"
        case 1: return "Perfect for tomorrow"
        case 2...3: return "Plan to use within next few meals"
        case 4...7: return "Still fresh - use this week"
        default: return "Plenty of time - store properly"
        }
    }

    var freshnessLabel: String {
        switch daysLeft {
        case ..<0: return "Expired"
        case 0: return "Last day"
        default: return "Fresh"
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Top Product Card - Horizontal Layout
                    HStack(spacing: 16) {
                        // Freshness Indicator
                        FreshnessIndicatorView(
                            freshnessScore: freshnessScore,
                            freshnessColor: freshnessColor,
                            freshnessEmoji: freshnessEmoji,
                            freshnessLabel: freshnessLabel,
                            daysLeft: daysLeft,
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
                                Label(daysLeft < 0 ? "Expired" : (daysLeft == 0 ? "Last day" : "\(daysLeft) days"), systemImage: "calendar")
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
                            .fill(colorScheme == .dark ? Color.midnightCard : Color(.secondarySystemBackground))
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

                        if isAddMode {
                            // Full selector interface for new items
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
                                            .fill(colorScheme == .dark ? Color.midnightBackground.opacity(0.5) : Color(.tertiarySystemBackground))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                // Days/Weeks Selector
                                HStack(spacing: 6) {
                                    // Amount picker
                                    HStack {
                                        Button(action: { if expiryAmount > 0 { expiryAmount -= 1 } }) {
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
                                            .fill(colorScheme == .dark ? Color.midnightBackground.opacity(0.5) : Color(.tertiarySystemBackground))
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
                        } else {
                            // Simple display for existing items - tap to change via calendar
                            Button(action: { showDatePicker.toggle() }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Expiring on")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Image(systemName: "calendar")
                                            .font(.system(size: 14))
                                            .foregroundColor(.blue)
                                    }

                                    Text(editedExpiryDate, style: .date)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color.midnightBackground.opacity(0.5) : Color(.tertiarySystemBackground))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color.midnightCard : Color(.secondarySystemBackground))
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
                                .background(colorScheme == .dark ? Color.midnightBackground.opacity(0.5) : Color(.tertiarySystemBackground))
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
                            .fill(colorScheme == .dark ? Color.midnightCard : Color(.secondarySystemBackground))
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
                            .fill(colorScheme == .dark ? Color.midnightCard : Color(.secondarySystemBackground))
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
            .presentationDragIndicator(.visible)
            .presentationBackground(Color(.systemBackground))
        }
        .onAppear {
            // Load existing photo from URL if available (edit mode only)
            if let item = item, let imageURL = item.imageURL, capturedImage == nil {
                Task {
                    await loadExistingPhoto(from: imageURL)
                }
            }

            // Initialize expiry selector values based on mode
            if let item = item {
                // Edit mode: Calculate days from actual expiry date
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let expiry = calendar.startOfDay(for: item.expiryDate)
                let actualDaysLeft = calendar.dateComponents([.day], from: today, to: expiry).day ?? 7
                expiryAmount = max(actualDaysLeft, 0)
                expiryUnit = actualDaysLeft > 14 ? .weeks : .days
                if expiryUnit == .weeks {
                    expiryAmount = max(expiryAmount / 7, 0)
                }
            }

            withAnimation(.spring(response: 0.6)) {
                animateIn = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
        .onChange(of: expiryMode) {
            updateExpiryDate()
        }
        .onChange(of: expiryAmount) {
            updateExpiryDate()
        }
        .onChange(of: expiryUnit) {
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
            .presentationDragIndicator(.visible)
            .presentationBackground(Color(.systemBackground))
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
            .presentationDragIndicator(.visible)
            .presentationBackground(Color(.systemBackground))
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
            if let cachedImage = await ImageCacheManager.shared.loadUseByImageAsync(for: item.id) {
                await MainActor.run {
                    capturedImage = cachedImage
                    #if DEBUG
                    print("⚡️ Loaded image from local cache for item: \(item.id)")
                    #endif
                }
                return
            }
        }

        // Fallback to Firebase URL if not in local cache
        guard let url = URL(string: urlString) else { return }
        #if DEBUG
        print("📸 Loading existing photo from Firebase: \(urlString)")

        #endif
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                await MainActor.run {
                    capturedImage = image
                    #if DEBUG
                    print("📸 Photo loaded from Firebase successfully")
                    #endif
                }

                // Cache it locally for next time
                if let item = item {
                    do {
                        try await ImageCacheManager.shared.saveUseByImageAsync(image, for: item.id)
                        #if DEBUG
                        print("💾 Cached downloaded image locally for item: \(item.id)")
                        #endif
                    } catch {
                        #if DEBUG
                        print("⚠️ Failed to cache downloaded image: \(error)")
                        #endif
                    }
                }
            }
        } catch {
            #if DEBUG
            print("❌ Failed to load existing photo: \(error)")
            #endif
        }
    }

    private func uploadPhoto(_ image: UIImage) async {
        // No longer upload immediately - just store the image
        // Upload will happen when saving
        isUploadingPhoto = false
        #if DEBUG
        print("📸 Image captured, will cache when saving...")
        #endif
    }

    private func updateExpiryDate() {
        // Only update from selector in add mode - in edit mode, preserve the existing date
        if expiryMode == .selector && item == nil {
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
            #if DEBUG
            print("UseByItemDetailView: Creating new item")
            print("UseByItemDetailView: Name: \(editedName)")
            print("UseByItemDetailView: Brand: \(editedBrand)")
            print("UseByItemDetailView: Quantity: \(editedQuantity)")
            print("UseByItemDetailView: Expiry: \(editedExpiryDate)")

            // Generate ID for new item
            #endif
            let itemId = UUID().uuidString

            // Handle image caching and upload
            var firebaseURL: String? = uploadedImageURL
            if let image = capturedImage, uploadedImageURL == nil {
                // Save to local cache
                do {
                    try await ImageCacheManager.shared.saveUseByImageAsync(image, for: itemId)
                    #if DEBUG
                    print("✅ Image cached locally for new item: \(itemId)")
                    #endif
                } catch {
                    #if DEBUG
                    print("⚠️ Failed to cache image locally: \(error)")
                    #endif
                }

                // Upload to Firebase for backup/sync
                do {
                    let url = try await FirebaseManager.shared.uploadUseByItemPhoto(image)
                    #if DEBUG
                    print("☁️ Image uploaded to Firebase: \(url)")
                    #endif
                    firebaseURL = url
                } catch {
                    #if DEBUG
                    print("⚠️ Firebase upload failed (using local cache): \(error)")
                    #endif
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
                #if DEBUG
                print("UseByItemDetailView: Item added successfully!")

                // Schedule notifications for new item
                #endif
                await UseByNotificationManager.shared.scheduleNotifications(for: newItem)
                #if DEBUG
                print("UseByItemDetailView: Notifications scheduled")

                #endif
                NotificationCenter.default.post(name: .useByInventoryUpdated, object: nil)

                await MainActor.run {
                    isSaving = false

                    // Success haptic
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)

                    dismiss()
                    onComplete?()
                }
            } catch {
                #if DEBUG
                print("❌ UseByItemDetailView: Failed to add useBy item")
                print("❌ Error: \(error)")
                #endif
                await MainActor.run {
                    isSaving = false
                }
            }
        } else {
            // Edit mode: Update existing item
            guard let item = item else { return }

            #if DEBUG
            print("UseByItemDetailView: Starting save")
            print("UseByItemDetailView: Item ID: \(item.id)")
            print("UseByItemDetailView: Edited quantity: \(editedQuantity)")
            print("UseByItemDetailView: Edited expiry: \(editedExpiryDate)")

            // Handle image caching and upload
            #endif
            var firebaseURL: String? = uploadedImageURL ?? item.imageURL
            if let image = capturedImage {
                // Check if this is a new image (not previously cached)
                let hasExistingCache = ImageCacheManager.shared.hasUseByImage(for: item.id)
                let isNewImage = !hasExistingCache || uploadedImageURL == nil

                if isNewImage {
                    // Save to local cache
                    do {
                        try await ImageCacheManager.shared.saveUseByImageAsync(image, for: item.id)
                        #if DEBUG
                        print("✅ Image cached locally for item: \(item.id)")
                        #endif
                    } catch {
                        #if DEBUG
                        print("⚠️ Failed to cache image locally: \(error)")
                        #endif
                    }

                    // Upload to Firebase for backup/sync
                    if uploadedImageURL == nil {
                        do {
                            let url = try await FirebaseManager.shared.uploadUseByItemPhoto(image)
                            #if DEBUG
                            print("☁️ Image uploaded to Firebase: \(url)")
                            #endif
                            firebaseURL = url
                        } catch {
                            #if DEBUG
                            print("⚠️ Firebase upload failed (using local cache): \(error)")
                            #endif
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
                #if DEBUG
                print("UseByItemDetailView: Calling updateUseByItem")
                #endif
                try await FirebaseManager.shared.updateUseByItem(updatedItem)
                #if DEBUG
                print("UseByItemDetailView: Update successful!")

                // Reschedule notifications with updated expiry date
                #endif
                UseByNotificationManager.shared.cancelNotifications(for: item.id)
                await UseByNotificationManager.shared.scheduleNotifications(for: updatedItem)
                #if DEBUG
                print("UseByItemDetailView: Notifications rescheduled")

                #endif
                NotificationCenter.default.post(name: .useByInventoryUpdated, object: nil)

                await MainActor.run {
                    isSaving = false

                    // Success haptic
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)

                    dismiss()
                }
            } catch {
                #if DEBUG
                print("❌ UseByItemDetailView: Failed to update useBy item")
                print("❌ Error type: \(type(of: error))")
                print("❌ Error description: \(error)")
                print("❌ Error localized: \(error.localizedDescription)")
                #endif
                if let nsError = error as NSError? {
                    #if DEBUG
                    print("❌ Error domain: \(nsError.domain)")
                    print("❌ Error code: \(nsError.code)")
                    print("❌ Error userInfo: \(nsError.userInfo)")
                    #endif
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
        #if DEBUG
        print("🗑️ Deleted image from local cache for item: \(item.id)")

        #endif
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
            #if DEBUG
            print("✅ Photo deleted successfully from Firebase")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to delete photo from Firebase: \(error)")
            #endif
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

            // Main content - Premium modern card design
            HStack(spacing: 10) {
                // Enhanced product image with gradient border
                ZStack {
                    // Subtle gradient glow behind image
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            RadialGradient(
                                colors: [statusColor.opacity(0.12), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 40
                            )
                        )
                        .frame(width: 58, height: 58)
                        .blur(radius: 6)

                    Group {
                        if item.imageURL != nil {
                            CachedUseByImage(
                                itemId: item.id,
                                imageURL: item.imageURL,
                                width: 52,
                                height: 52,
                                cornerRadius: 10
                            )
                        } else {
                            PlaceholderImageView()
                        }
                    }
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        statusColor.opacity(0.2),
                                        statusColor.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: statusColor.opacity(0.15), radius: 6, x: 0, y: 3)
                    .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
                }

                // Item info with enhanced typography
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    if let brand = item.brand, !brand.isEmpty {
                        Text(brand)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.8))
                            .lineLimit(1)
                    }

                    // Modern status badge with gradient
                    HStack(spacing: 5) {
                        Image(systemName: statusIcon)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [statusColor, statusColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text(statusText)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [statusColor, statusColor.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background {
                        ZStack {
                            // Glassmorphic background
                            Capsule()
                                .fill(statusColor.opacity(0.15))

                            // Gradient overlay
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            statusColor.opacity(0.08),
                                            statusColor.opacity(0.03)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            // Border
                            Capsule()
                                .strokeBorder(
                                    statusColor.opacity(0.35),
                                    lineWidth: 1.5
                                )
                        }
                    }
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(.systemGray6), Color(.systemGray5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [statusColor, statusColor.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3)
                    .padding(.vertical, 8)
            }
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
            .clipShape(RoundedRectangle(cornerRadius: 14))
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
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(.systemBackground))
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
    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Enhanced icon with glassmorphic effect
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.15), color.opacity(0.05)],
                            center: .center,
                            startRadius: 10,
                            endRadius: 30
                        )
                    )
                    .frame(width: 56, height: 56)
                    .blur(radius: 4)

                // Main icon circle with glassmorphic background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.25), color.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                // Inner glassmorphic layer
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 46, height: 46)
                    .opacity(0.5)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .minimumScaleFactor(0.8)

                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.8))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                // Glassmorphic background
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)

                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.08),
                                color.opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Gradient border
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                color.opacity(0.3),
                                color.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            }
        }
        .shadow(color: color.opacity(0.15), radius: 12, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .scaleEffect(isVisible ? 1 : 0.95)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
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
        #if DEBUG
        print("📸 PHPicker created with config: selectionLimit=0 (shows Add button)")
        #endif
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
            #if DEBUG
            print("📸 PHPicker didFinishPicking called with \(results.count) results")

            // User cancelled if no results
            #endif
            if results.isEmpty {
                #if DEBUG
                print("📸 User cancelled, calling onImageSelected(nil)")
                #endif
                parent.onImageSelected(nil)
                return
            }

            // Only take the first photo even though we allow multiple selection
            guard let provider = results.first?.itemProvider else {
                #if DEBUG
                print("📸 No item provider, calling onImageSelected(nil)")
                #endif
                parent.onImageSelected(nil)
                return
            }

            if provider.canLoadObject(ofClass: UIImage.self) {
                #if DEBUG
                print("📸 Loading UIImage from provider...")
                #endif
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    if let error = error {
                        #if DEBUG
                        print("❌ Error loading image: \(error)")
                        #endif
                    }
                    DispatchQueue.main.async {
                        #if DEBUG
                        print("📸 Image loaded, calling onImageSelected")
                        #endif
                        self.parent.onImageSelected(image as? UIImage)
                    }
                }
            } else {
                #if DEBUG
                print("❌ Provider cannot load UIImage")
                #endif
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
        if let cachedImage = await ImageCacheManager.shared.loadUseByImageAsync(for: itemId) {
            loadedImage = cachedImage
            isLoading = false
            #if DEBUG
            print("⚡️ Loaded UseBy thumbnail from cache: \(itemId)")
            #endif
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
                    try await ImageCacheManager.shared.saveUseByImageAsync(image, for: itemId)
                    #if DEBUG
                    print("💾 Cached downloaded UseBy thumbnail: \(itemId)")
                    #endif
                } catch {
                    #if DEBUG
                    print("⚠️ Failed to cache thumbnail: \(error)")
                    #endif
                }
            }
        } catch {
            #if DEBUG
            print("❌ Failed to load image from URL: \(error)")
            #endif
        }

        isLoading = false
    }
}

// MARK: - Modern Visual Components for Empty State

struct ModernGradientBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            // Base gradient background
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.blue.opacity(0.03),
                    Color.purple.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Floating blur orbs
            GeometryReader { geometry in
                ZStack {
                    // Orb 1 - Top left
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.blue.opacity(0.15), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .offset(
                            x: animate ? -50 : -80,
                            y: animate ? 50 : 80
                        )
                        .blur(radius: 40)

                    // Orb 2 - Bottom right
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.purple.opacity(0.12), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 150
                            )
                        )
                        .frame(width: 250, height: 250)
                        .offset(
                            x: geometry.size.width - (animate ? 150 : 180),
                            y: geometry.size.height - (animate ? 200 : 230)
                        )
                        .blur(radius: 35)

                    // Orb 3 - Center right
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.cyan.opacity(0.08), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 120
                            )
                        )
                        .frame(width: 200, height: 200)
                        .offset(
                            x: geometry.size.width - (animate ? 80 : 110),
                            y: geometry.size.height / 2 + (animate ? 20 : -10)
                        )
                        .blur(radius: 30)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 8)
                    .repeatForever(autoreverses: true)
            ) {
                animate = true
            }
        }
    }
}

struct AnimatedFridgeIcon: View {
    var body: some View {
        ZStack {
            // Drop shadow
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.black.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 5,
                        endRadius: 40
                    )
                )
                .frame(width: 90, height: 15)
                .offset(y: 95)

            HStack(spacing: 0) {
                // Left side panel (3D depth)
                VStack(spacing: 0) {
                    // Top part of left panel
                    RoundedRectangle(cornerRadius: 0)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.60, green: 0.74, blue: 0.86),
                                    Color(red: 0.56, green: 0.71, blue: 0.84)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 15, height: 75)
                        .cornerRadius(25, corners: [.topLeft])

                    // Divider area
                    Rectangle()
                        .fill(Color(red: 0.56, green: 0.71, blue: 0.84))
                        .frame(width: 15, height: 2)

                    // Bottom part of left panel
                    RoundedRectangle(cornerRadius: 0)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.56, green: 0.71, blue: 0.84),
                                    Color(red: 0.54, green: 0.69, blue: 0.82)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 15, height: 103)
                        .cornerRadius(25, corners: [.bottomLeft])
                }

                // Main fridge body
                VStack(spacing: 0) {
                    // Top freezer compartment
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.76, green: 0.87, blue: 0.96),
                                        Color(red: 0.73, green: 0.85, blue: 0.95)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 95, height: 75)
                            .cornerRadius(25, corners: [.topRight])

                        // Recessed handle
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.64, green: 0.77, blue: 0.88),
                                        Color(red: 0.67, green: 0.79, blue: 0.90)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 12, height: 40)
                            .shadow(color: Color(red: 0.5, green: 0.65, blue: 0.8).opacity(0.4), radius: 2, x: 1, y: 1)
                            .padding(.leading, 18)
                    }

                    // Divider line
                    Rectangle()
                        .fill(Color(red: 0.68, green: 0.81, blue: 0.92))
                        .frame(height: 2)

                    // Bottom fridge compartment
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.73, green: 0.85, blue: 0.95),
                                        Color(red: 0.71, green: 0.84, blue: 0.94)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 95, height: 103)
                            .cornerRadius(25, corners: [.bottomRight])

                        // Recessed handle
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.64, green: 0.77, blue: 0.88),
                                        Color(red: 0.67, green: 0.79, blue: 0.90)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 12, height: 52)
                            .shadow(color: Color(red: 0.5, green: 0.65, blue: 0.8).opacity(0.4), radius: 2, x: 1, y: 1)
                            .padding(.leading, 18)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .shadow(color: Color.blue.opacity(0.12), radius: 12, x: 2, y: 4)
        }
        .frame(width: 110, height: 180)
    }
}

struct FloatingParticle: View {
    let index: Int
    @State private var isFloating = false

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 6, height: 6)
            .blur(radius: 1)
            .offset(
                x: particleOffset.x + (isFloating ? 20 : -20),
                y: particleOffset.y + (isFloating ? -30 : 30)
            )
            .opacity(isFloating ? 0 : 0.8)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 2.0 + Double(index) * 0.3)
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * 0.2)
                ) {
                    isFloating = true
                }
            }
    }

    var particleOffset: CGPoint {
        let angle = Double(index) * .pi / 3
        let radius: CGFloat = 80
        return CGPoint(
            x: cos(angle) * radius,
            y: sin(angle) * radius
        )
    }
}

struct ModernAddButton: View {
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20, weight: .semibold))

                Text("Add Your First Item")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background {
                ZStack {
                    // Gradient background
                    LinearGradient(
                        colors: [
                            Color(red: 0.3, green: 0.5, blue: 1.0),
                            Color(red: 0.5, green: 0.3, blue: 0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Glassmorphic overlay
                    Color.white.opacity(0.15)
                }
            }
            .cornerRadius(16)
            .shadow(
                color: Color.blue.opacity(0.4),
                radius: isPressed ? 8 : 15,
                x: 0,
                y: isPressed ? 4 : 8
            )
            .shadow(
                color: Color.purple.opacity(0.3),
                radius: isPressed ? 12 : 20,
                x: 0,
                y: isPressed ? 6 : 12
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
    }
}

struct ModernTipCard: View {
    let tip: String
    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 12) {
            // Gradient icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.2), Color.orange.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)

                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text(tip)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            ZStack {
                // Glassmorphic background
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)

                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.yellow.opacity(0.05),
                                Color.orange.opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Border
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.yellow.opacity(0.2),
                                Color.orange.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        }
        .shadow(color: Color.yellow.opacity(0.1), radius: 8, x: 0, y: 4)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.4)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Compact Stat Pill (Ultra-Modern)

struct CompactStatPill: View {
    let value: String
    let label: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(AppTypography.title3(weight: .bold))
                    .foregroundColor(tint)

                Text(label)
                    .font(AppTypography.caption2(weight: .semibold))
                    .foregroundColor(tint.opacity(0.9))
                    .textCase(.uppercase)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.cardBackgroundInteractive)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(tint.opacity(0.25), lineWidth: 1)
        )
    }
}
