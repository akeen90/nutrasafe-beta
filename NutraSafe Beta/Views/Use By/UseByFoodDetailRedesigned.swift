//
//  UseByFoodDetailRedesigned.swift
//  NutraSafe Beta
//
//  Redesigned food detail screen for adding items to Use By
//  Design philosophy: Emotion-first, calm, trust-building, minimal friction
//

import SwiftUI
import UIKit

struct UseByFoodDetailSheetRedesigned: View {
    // Either a FoodSearchResult (for adding from search) or nil (for editing existing)
    let food: FoodSearchResult?
    // Existing item for editing, nil for adding
    let existingItem: UseByInventoryItem?
    var onComplete: (() -> Void)? = nil

    // Convenience initializer for adding from search
    init(food: FoodSearchResult, onComplete: (() -> Void)? = nil) {
        self.food = food
        self.existingItem = nil
        self.onComplete = onComplete
        // Initialize state from food
        _itemName = State(initialValue: food.name)
        _itemBrand = State(initialValue: food.brand ?? "")
        _quantity = State(initialValue: "1")
        _expiryDate = State(initialValue: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date())
        _notes = State(initialValue: "")
        _expiryMode = State(initialValue: .selector)
        _expiryAmount = State(initialValue: 7)
        _expiryUnit = State(initialValue: .days)
    }

    // Initializer for editing existing item
    init(item: UseByInventoryItem, onComplete: (() -> Void)? = nil) {
        self.food = nil
        self.existingItem = item
        self.onComplete = onComplete
        // Initialize state from existing item
        _itemName = State(initialValue: item.name)
        _itemBrand = State(initialValue: item.brand ?? "")
        _quantity = State(initialValue: item.quantity)
        _expiryDate = State(initialValue: item.expiryDate)
        _notes = State(initialValue: item.notes ?? "")
        // For editing, use calendar mode with existing date
        _expiryMode = State(initialValue: .calendar)
        _expiryAmount = State(initialValue: 7)
        _expiryUnit = State(initialValue: .days)
    }

    // Initializer for manual/blank entry (no food or existing item)
    init(onComplete: (() -> Void)? = nil) {
        self.food = nil
        self.existingItem = nil
        self.onComplete = onComplete
        // Initialize with blank state for manual entry
        _itemName = State(initialValue: "")
        _itemBrand = State(initialValue: "")
        _quantity = State(initialValue: "1")
        _expiryDate = State(initialValue: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date())
        _notes = State(initialValue: "")
        _expiryMode = State(initialValue: .selector)
        _expiryAmount = State(initialValue: 7)
        _expiryUnit = State(initialValue: .days)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var itemName: String
    @State private var itemBrand: String
    @State private var quantity: String
    @State private var expiryDate: Date
    @State private var location: String = ""
    @State private var notes: String
    @State private var isSaving = false
    @State private var expiryMode: ExpiryMode
    @State private var expiryAmount: Int
    @State private var expiryUnit: ExpiryUnit

    // Photo capture states
    @State private var capturedImage: UIImage?
    @State private var existingImage: UIImage?  // Loaded from cache/URL when editing
    @State private var showCameraPicker: Bool = false
    @State private var showPhotoPicker: Bool = false
    @State private var showPhotoActionSheet: Bool = false
    @State private var isUploadingPhoto: Bool = false
    @State private var shouldDeleteExistingPhoto: Bool = false  // Track if user wants to delete existing photo

    @FocusState private var isAnyFieldFocused: Bool

    // User intent from onboarding
    @AppStorage("userIntent") private var userIntentRaw: String = "safer"
    private var userIntent: UserIntent {
        UserIntent(rawValue: userIntentRaw) ?? .safer
    }

    private var palette: OnboardingPalette {
        OnboardingPalette.forIntent(userIntent)
    }

    private var appPalette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    private var isEditMode: Bool {
        existingItem != nil
    }

    private var isManualEntry: Bool {
        food == nil && existingItem == nil
    }

    enum ExpiryMode {
        case calendar
        case selector
    }

    enum ExpiryUnit: String, CaseIterable {
        case days = "Days"
        case weeks = "Weeks"
    }

    private var calculatedExpiryDate: Date {
        let calendar = Calendar.current
        let baseDate = Date()
        switch expiryUnit {
        case .days:
            return calendar.date(byAdding: .day, value: expiryAmount, to: baseDate) ?? baseDate
        case .weeks:
            return calendar.date(byAdding: .day, value: expiryAmount * 7, to: baseDate) ?? baseDate
        }
    }

    private var daysLeft: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expiry = calendar.startOfDay(for: expiryMode == .selector ? calculatedExpiryDate : expiryDate)
        let components = calendar.dateComponents([.day], from: today, to: expiry)
        return components.day ?? 0
    }

    private var freshnessMessage: String {
        switch daysLeft {
        case ..<0: return "Expired"
        case 0: return "Use today"
        case 1: return "Use by tomorrow"
        case 2...3: return "Use within a few days"
        case 4...7: return "Still fresh - use this week"
        default: return "Plenty of time"
        }
    }

    private var freshnessColor: Color {
        if daysLeft > 7 { return palette.accent }
        else if daysLeft > 3 { return .green }
        else if daysLeft > 1 { return .yellow }
        else { return .orange }
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            mainContent
        }
        .onAppear {
            loadExistingPhoto()
        }
        .sheet(isPresented: $showCameraPicker) {
            ImagePicker(selectedImage: $capturedImage, sourceType: .camera) { image in
                capturedImage = image
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker(selectedImage: $capturedImage, sourceType: .photoLibrary) { image in
                capturedImage = image
            }
        }
        .confirmationDialog("Add Photo", isPresented: $showPhotoActionSheet) {
            Button("Take Photo") { showCameraPicker = true }
            Button("Choose from Library") { showPhotoPicker = true }
            Button("Cancel", role: .cancel) { }
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            appPalette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                scrollableContent
                bottomButton
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(appPalette.textTertiary)
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
    }

    // MARK: - Scrollable Content

    @ViewBuilder
    private var scrollableContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                headerSection
                expirySection
                notesSection
                photoSection
                Spacer().frame(height: 90)
            }
            .padding(.bottom, 20)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isManualEntry {
                // Editable name field for manual entry
                TextField("Item name", text: $itemName)
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundColor(appPalette.textPrimary)
                    .focused($isAnyFieldFocused)

                TextField("Brand (optional)", text: $itemBrand)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(appPalette.textSecondary)
                    .focused($isAnyFieldFocused)
            } else {
                Text(itemName)
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundColor(appPalette.textPrimary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                if !itemBrand.isEmpty {
                    Text(itemBrand)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(appPalette.textSecondary)
                        .tracking(0.2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    // MARK: - Expiry Section

    @ViewBuilder
    private var expirySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            expirySectionHeader
            expirySectionModeToggle
            expirySectionContent
        }
        .padding(18)
        .background(expirySectionBackground)
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var expirySectionHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(palette.accent)
            Text("Expiry Date")
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(appPalette.textPrimary)
        }
    }

    @ViewBuilder
    private var expirySectionModeToggle: some View {
        HStack(spacing: 10) {
            modeButton(icon: "calendar", label: "Date", mode: .calendar, isSelected: expiryMode == .calendar)
            modeButton(icon: "slider.horizontal.3", label: "Quick", mode: .selector, isSelected: expiryMode == .selector)
        }
    }

    @ViewBuilder
    private var expirySectionContent: some View {
        if expiryMode == .calendar {
            calendarPicker
        } else {
            quickSelector
        }
    }

    @ViewBuilder
    private var calendarPicker: some View {
        DatePicker("", selection: $expiryDate, displayedComponents: .date)
            .datePickerStyle(.compact)
            .labelsHidden()
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(appPalette.tertiary.opacity(colorScheme == .dark ? 0.12 : 0.06))
            )
    }

    @ViewBuilder
    private var quickSelector: some View {
        VStack(spacing: 14) {
            quickSelectorControls
            freshnessBadge
        }
    }

    @ViewBuilder
    private var quickSelectorControls: some View {
        HStack(spacing: 12) {
            amountStepper
            unitSelector
        }
    }

    @ViewBuilder
    private var amountStepper: some View {
        HStack(spacing: 0) {
            Button(action: { if expiryAmount > 1 { expiryAmount -= 1 } }) {
                Image(systemName: "minus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(palette.accent)
                    .frame(width: 44, height: 44)
            }
            Text("\(expiryAmount)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(appPalette.textPrimary)
                .frame(minWidth: 50)
            Button(action: { expiryAmount += 1 }) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(palette.accent)
                    .frame(width: 44, height: 44)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(appPalette.tertiary.opacity(colorScheme == .dark ? 0.12 : 0.06))
        )
    }

    @ViewBuilder
    private var unitSelector: some View {
        ForEach(ExpiryUnit.allCases, id: \.self) { unit in
            Button(action: { expiryUnit = unit }) {
                Text(unit.rawValue)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(expiryUnit == unit ? .white : appPalette.textSecondary)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(expiryUnit == unit ? palette.accent : appPalette.tertiary.opacity(colorScheme == .dark ? 0.12 : 0.06))
                    )
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    @ViewBuilder
    private var freshnessBadge: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 11))
                    .foregroundColor(freshnessColor)
                Text("\(daysLeft) days left")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(freshnessColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(freshnessColor.opacity(0.12)))

            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow.opacity(0.8))
                Text(freshnessMessage)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(appPalette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var expirySectionBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [
                        colorScheme == .dark ? Color(UIColor.secondarySystemGroupedBackground) : .white,
                        colorScheme == .dark ? Color(UIColor.secondarySystemGroupedBackground).opacity(0.95) : .white.opacity(0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Notes Section

    @ViewBuilder
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            notesSectionHeader
            notesSectionEditor
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var notesSectionHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "note.text")
                .font(.system(size: 14))
                .foregroundColor(palette.accent)
            Text("Notes")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(appPalette.textPrimary)
        }
    }

    @ViewBuilder
    private var notesSectionEditor: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $notes)
                .font(.system(size: 15))
                .frame(height: 100)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .focused($isAnyFieldFocused)

            if notes.isEmpty {
                Text("Add notes...")
                    .font(.system(size: 15))
                    .foregroundColor(appPalette.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.top, 8)
                    .allowsHitTesting(false)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(appPalette.tertiary.opacity(colorScheme == .dark ? 0.12 : 0.06))
        )
    }

    // MARK: - Photo Section

    @ViewBuilder
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            photoSectionHeader
            photoSectionContent
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var photoSectionHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "camera")
                .font(.system(size: 14))
                .foregroundColor(palette.accent)
            Text("Photo")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(appPalette.textPrimary)
        }
    }

    @ViewBuilder
    private var photoSectionContent: some View {
        // Priority: captured image > existing image (if not marked for deletion)
        if let displayImage = capturedImage {
            photoPreview(displayImage, isNewCapture: true)
        } else if let loadedImage = existingImage, !shouldDeleteExistingPhoto {
            photoPreview(loadedImage, isNewCapture: false)
        } else {
            photoPlaceholder
        }
    }

    @ViewBuilder
    private func photoPreview(_ image: UIImage, isNewCapture: Bool) -> some View {
        ZStack {
            // Make the entire image tappable to change photo
            Button(action: { showPhotoActionSheet = true }) {
                ZStack(alignment: .bottom) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Subtle hint overlay that photo is tappable
                    HStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12))
                        Text("Tap to change")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.7))
                    )
                    .padding(.bottom, 12)
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Delete button in top-right corner
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        if isNewCapture {
                            // Just clear the new capture
                            capturedImage = nil
                        } else {
                            // Mark existing photo for deletion
                            shouldDeleteExistingPhoto = true
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.6)).frame(width: 28, height: 28))
                    }
                    .padding(12)
                }
                Spacer()
            }
        }
        .frame(height: 180)
    }

    @ViewBuilder
    private var photoPlaceholder: some View {
        Button(action: { showPhotoActionSheet = true }) {
            VStack(spacing: 12) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 32))
                    .foregroundColor(palette.accent.opacity(0.6))
                Text("Tap to add photo")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(appPalette.textSecondary)
                    .tracking(0.2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(appPalette.tertiary.opacity(colorScheme == .dark ? 0.08 : 0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                            .foregroundColor(palette.accent.opacity(0.2))
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Load Existing Photo

    private func loadExistingPhoto() {
        guard isEditMode, let item = existingItem else { return }

        Task {
            // Try loading from local cache first
            if let cachedImage = await ImageCacheManager.shared.loadUseByImageAsync(for: item.id) {
                await MainActor.run {
                    existingImage = cachedImage
                }
                return
            }

            // If not in cache but has URL, try loading from URL
            if let imageURLString = item.imageURL,
               let imageURL = URL(string: imageURLString) {
                do {
                    let (data, _) = try await URLSession.shared.data(from: imageURL)
                    if let image = UIImage(data: data) {
                        await MainActor.run {
                            existingImage = image
                        }
                        // Cache it locally for future use
                        try? await ImageCacheManager.shared.saveUseByImageAsync(image, for: item.id)
                    }
                } catch {
                    print("📸 [UseBy] Failed to load image from URL: \(error)")
                }
            }
        }
    }

    // MARK: - Bottom Button

    @ViewBuilder
    private var bottomButton: some View {
        VStack(spacing: 0) {
            Divider().background(appPalette.textTertiary.opacity(0.2))

            Button(action: {
                isAnyFieldFocused = false
                saveToUseBy()
            }) {
                HStack(spacing: 10) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: isEditMode ? "checkmark.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text(isEditMode ? "Save Changes" : "Add Item")
                            .font(.system(size: 17, weight: .semibold))
                            .tracking(0.3)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [palette.accent, palette.accent.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: palette.accent.opacity(0.4), radius: 12, x: 0, y: 6)
                )
            }
            .disabled(isSaving)
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                colorScheme == .dark ? Color(UIColor.systemBackground) : .white
            )
        }
    }

    // MARK: - Mode Button

    private func modeButton(icon: String, label: String, mode: ExpiryMode, isSelected: Bool) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                expiryMode = mode
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : appPalette.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? palette.accent : appPalette.tertiary.opacity(colorScheme == .dark ? 0.12 : 0.06))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Save to Use By

    private func saveToUseBy() {
        guard !isSaving else { return }
        isSaving = true

        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        let finalExpiryDate = expiryMode == .selector ? calculatedExpiryDate : expiryDate
        let imageToUpload = capturedImage
        let notesText = notes.isEmpty ? nil : notes
        let foodName = itemName
        let foodBrand = itemBrand.isEmpty ? nil : itemBrand
        let foodQuantity = quantity

        if isEditMode, let existing = existingItem {
            // EDIT MODE - update existing item

            Task {
                // Determine the final imageURL based on user actions
                var finalImageURL: String? = existing.imageURL

                // Handle photo deletion FIRST
                if shouldDeleteExistingPhoto {
                    ImageCacheManager.shared.deleteUseByImage(for: existing.id)
                    finalImageURL = nil
                }

                // Handle new photo upload - cache immediately
                if let image = imageToUpload {
                    do {
                        try await ImageCacheManager.shared.saveUseByImageAsync(image, for: existing.id)
                        // Update the UI immediately to show the new photo
                        await MainActor.run {
                            existingImage = image
                            capturedImage = nil  // Clear captured image since it's now the existing image
                        }
                    } catch {
                        print("📸 [UseBy] Failed to cache image: \(error)")
                    }
                }

                // Create updated item with current imageURL state
                let updatedItem = UseByInventoryItem(
                    id: existing.id,
                    name: foodName,
                    brand: foodBrand,
                    quantity: foodQuantity,
                    expiryDate: finalExpiryDate,
                    addedDate: existing.addedDate,
                    barcode: existing.barcode,
                    category: existing.category,
                    imageURL: finalImageURL,
                    notes: notesText
                )

                // Update local data manager
                await MainActor.run {
                    if let index = UseByDataManager.shared.items.firstIndex(where: { $0.id == existing.id }) {
                        UseByDataManager.shared.items[index] = updatedItem
                    }
                    UseByDataManager.shared.items.sort { $0.expiryDate < $1.expiryDate }
                    NotificationCenter.default.post(name: .useByInventoryUpdated, object: nil)
                }

                // Update Firebase with current state
                do {
                    try await FirebaseManager.shared.updateUseByItem(updatedItem)
                } catch {
                    print("💾 [UseBy] Failed to update item in Firebase: \(error)")
                }

                // Schedule notifications
                Task.detached(priority: .background) {
                    await UseByNotificationManager.shared.scheduleNotifications(for: updatedItem)
                }

                // If new photo was captured, upload it in the background and update URL
                if let image = imageToUpload {
                    Task.detached(priority: .utility) {
                        do {
                            let url = try await FirebaseManager.shared.uploadUseByItemPhoto(image)
                            let itemWithPhoto = UseByInventoryItem(
                                id: existing.id,
                                name: foodName,
                                brand: foodBrand,
                                quantity: foodQuantity,
                                expiryDate: finalExpiryDate,
                                addedDate: existing.addedDate,
                                barcode: existing.barcode,
                                category: existing.category,
                                imageURL: url,
                                notes: notesText
                            )
                            try await FirebaseManager.shared.updateUseByItem(itemWithPhoto)
                            await MainActor.run {
                                if let index = UseByDataManager.shared.items.firstIndex(where: { $0.id == existing.id }) {
                                    UseByDataManager.shared.items[index] = itemWithPhoto
                                }
                            }
                        } catch {
                            print("📸 [UseBy] Failed to upload image to Firebase: \(error)")
                        }
                    }
                }

                // Dismiss and complete AFTER all critical updates are done
                await MainActor.run {
                    isSaving = false
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)
                    dismiss()
                    onComplete?()
                }
            }
        } else {
            // ADD MODE - create new item
            let itemId = UUID().uuidString

            let newItem = UseByInventoryItem(
                id: itemId,
                name: foodName,
                brand: foodBrand,
                quantity: foodQuantity,
                expiryDate: finalExpiryDate,
                addedDate: Date(),
                barcode: nil,
                category: nil,
                imageURL: nil,
                notes: notesText
            )

            Task {
                if let image = imageToUpload {
                    do {
                        try await ImageCacheManager.shared.saveUseByImageAsync(image, for: itemId)
                    } catch {
                        print("📸 [UseBy] Failed to cache image: \(error)")
                    }
                }

                await MainActor.run {
                    UseByDataManager.shared.items.append(newItem)
                    UseByDataManager.shared.items.sort { $0.expiryDate < $1.expiryDate }
                    NotificationCenter.default.post(name: .useByInventoryUpdated, object: nil)
                }

                await MainActor.run {
                    isSaving = false
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)
                    dismiss()
                    onComplete?()
                }

                do {
                    try await FirebaseManager.shared.addUseByItem(newItem)
                } catch {
                    print("💾 [UseBy] Failed to save item to Firebase: \(error)")
                }

                Task.detached(priority: .background) {
                    await UseByNotificationManager.shared.scheduleNotifications(for: newItem)
                }

                if let image = imageToUpload {
                    Task.detached(priority: .utility) {
                        do {
                            let url = try await FirebaseManager.shared.uploadUseByItemPhoto(image)
                            let updatedItem = UseByInventoryItem(
                                id: itemId,
                                name: foodName,
                                brand: foodBrand,
                                quantity: foodQuantity,
                                expiryDate: finalExpiryDate,
                                addedDate: Date(),
                                barcode: nil,
                                category: nil,
                                imageURL: url,
                                notes: notesText
                            )
                            try await FirebaseManager.shared.updateUseByItem(updatedItem)
                            await MainActor.run {
                                if let index = UseByDataManager.shared.items.firstIndex(where: { $0.id == itemId }) {
                                    UseByDataManager.shared.items[index] = updatedItem
                                }
                            }
                        } catch {
                            print("📸 [UseBy] Failed to upload image to Firebase: \(error)")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct UseByFoodDetailSheetRedesigned_Previews: PreviewProvider {
    static var previews: some View {
        UseByFoodDetailSheetRedesigned(
            food: FoodSearchResult(
                id: "preview",
                name: "Apple Raw",
                brand: nil,
                calories: 52,
                protein: 0.3,
                carbs: 14,
                fat: 0.2,
                fiber: 2.4,
                sugar: 10.4,
                sodium: 1
            ),
            onComplete: {}
        )
        .preferredColorScheme(.light)

        UseByFoodDetailSheetRedesigned(
            food: FoodSearchResult(
                id: "preview",
                name: "Organic Whole Milk",
                brand: "Tesco",
                calories: 65,
                protein: 3.4,
                carbs: 4.8,
                fat: 3.6,
                saturatedFat: 2.3,
                fiber: 0,
                sugar: 4.8,
                sodium: 44
            ),
            onComplete: {}
        )
        .preferredColorScheme(.dark)
    }
}
#endif
