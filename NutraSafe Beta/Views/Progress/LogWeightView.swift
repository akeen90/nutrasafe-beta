//
//  LogWeightView.swift
//  NutraSafe Beta
//
//  Redesigned Log Weight screen - part of the Progress journey
//  Emotional, intentional, calming - not a utility form
//

import SwiftUI
import PhotosUI

// MARK: - Main Log Weight View

struct LogWeightView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var firebaseManager: FirebaseManager

    // Bindings for data
    @Binding var currentWeight: Double
    @Binding var weightHistory: [WeightEntry]
    @Binding var userHeight: Double
    @Binding var goalWeight: Double
    var onInstantDismiss: (() -> Void)? = nil
    var existingEntry: WeightEntry? = nil

    // User preferences
    @AppStorage("weightUnit") private var selectedUnit: WeightUnit = .kg
    @AppStorage("heightUnit") private var selectedHeightUnit: HeightUnit = .cm
    @AppStorage("userGender") private var userGender: Gender = .other

    // Weight state
    @State private var weightValue: Double = 70.0
    @State private var weightDecimal: Int = 0

    // Height state
    @State private var primaryHeight: String = ""
    @State private var secondaryHeight: String = ""
    @State private var showHeightSection = false

    // Goal state
    @State private var goalWeightText: String = ""
    @State private var showGoalSection = false

    // Date state
    @State private var entryDate = Date()
    @State private var showDatePicker = false

    // Photo state
    @State private var selectedPhotos: [IdentifiableImage] = []
    @State private var activePickerType: PhotoPickerType? = nil
    @State private var showingMultiImagePicker = false
    @State private var selectedPhotoForViewing: IdentifiableImage? = nil

    // Note state
    @State private var note: String = ""
    @State private var showNoteField = false

    // Measurements
    @State private var waistSize: String = ""
    @State private var dressSize: String = ""

    // UI state
    @State private var isUploading = false
    @State private var showSaveConfirmation = false

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    // MARK: - Computed Properties

    private var weightInKg: Double {
        let decimal = Double(weightDecimal) / 10.0
        let total = weightValue + decimal
        return selectedUnit.toKg(primary: total, secondary: nil) ?? total
    }

    private var displayWeight: String {
        let decimal = Double(weightDecimal) / 10.0
        return String(format: "%.1f", weightValue + decimal)
    }

    private var heightInCm: Double? {
        guard let primary = Double(primaryHeight), primary > 0 else { return nil }
        let secondary = selectedHeightUnit == .ftIn ? Double(secondaryHeight) : nil
        return selectedHeightUnit.toCm(primary: primary, secondary: secondary)
    }

    private var calculatedBMI: Double? {
        guard let heightCm = heightInCm ?? (userHeight > 0 ? userHeight : nil), heightCm > 0 else { return nil }
        let heightInMeters = heightCm / 100
        return weightInKg / (heightInMeters * heightInMeters)
    }

    private var goalWeightInKg: Double? {
        let sanitized = goalWeightText.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(sanitized), value > 0 else { return nil }
        switch selectedUnit {
        case .kg: return value
        case .lbs: return value / 2.20462
        case .stones: return value * 6.35029
        }
    }

    private var weightDifferenceToGoal: Double? {
        guard let goalKg = goalWeightInKg ?? (goalWeight > 0 ? goalWeight : nil) else { return nil }
        return weightInKg - goalKg
    }

    private var isNow: Bool {
        abs(entryDate.timeIntervalSinceNow) < 60
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            backgroundGradient

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero Header
                    heroHeader

                    // Main Content
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        // Weight Input - Primary Focus
                        weightInputSection

                        // BMI Feedback (if available)
                        if let bmi = calculatedBMI {
                            bmiFeedbackCard(bmi: bmi)
                        }

                        // Date/Time Section
                        dateTimeSection

                        // Progress Photos
                        progressPhotosSection

                        // Optional Sections
                        optionalSectionsArea

                        // Save Button
                        saveButtonSection

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, DesignTokens.Spacing.screenEdge)
                }
            }

            // Upload overlay
            if isUploading {
                uploadingOverlay
            }
        }
        .onAppear(perform: setupInitialValues)
        .fullScreenCover(item: $activePickerType) { pickerType in
            if pickerType == .camera {
                ImagePicker(selectedImage: nil, sourceType: .camera) { image in
                    activePickerType = nil
                    if let image = image, selectedPhotos.count < 3 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedPhotos.append(IdentifiableImage(image: image, url: nil))
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingMultiImagePicker) {
            MultiImagePicker(maxSelection: 3 - selectedPhotos.count) { images in
                showingMultiImagePicker = false
                let availableSlots = 3 - selectedPhotos.count
                let photosToAdd = min(images.count, availableSlots)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    for i in 0..<photosToAdd {
                        selectedPhotos.append(IdentifiableImage(image: images[i], url: nil))
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedPhotoForViewing) { photo in
            PhotoDetailView(image: photo.image) {
                selectedPhotoForViewing = nil
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            palette.background.ignoresSafeArea()

            // Subtle accent gradient at top
            VStack {
                LinearGradient(
                    colors: [
                        palette.accent.opacity(0.08),
                        palette.primary.opacity(0.04),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 300)

                Spacer()
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Close button row
            HStack {
                Button(action: dismissView) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(palette.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.nutraSafeCard)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                        )
                }

                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.screenEdge)
            .padding(.top, DesignTokens.Spacing.md)

            // Title area
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text(existingEntry != nil ? "Update Entry" : "Log Today's Weight")
                    .font(DesignTokens.Typography.headline(26))
                    .foregroundColor(palette.textPrimary)

                Text("A moment to check in with yourself")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(palette.textSecondary)
            }
            .padding(.bottom, DesignTokens.Spacing.lg)
        }
    }

    // MARK: - Weight Input Section

    private var weightInputSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Weight display card
            VStack(spacing: DesignTokens.Spacing.sm) {
                // Large weight value
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(displayWeight)
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [palette.accent, palette.primary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text(selectedUnit.shortName)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(palette.textSecondary)
                }

                // Unit selector
                unitSelectorPills
            }
            .padding(.vertical, DesignTokens.Spacing.xl)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                    .fill(Color.nutraSafeCard)
                    .shadow(
                        color: palette.accent.opacity(0.1),
                        radius: 20,
                        y: 8
                    )
            )

            // Weight stepper controls
            weightStepperControls
        }
    }

    private var unitSelectorPills: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(WeightUnit.allCases, id: \.self) { unit in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        convertAndSetUnit(to: unit)
                    }
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }) {
                    Text(unit.rawValue)
                        .font(.system(size: 14, weight: selectedUnit == unit ? .semibold : .medium))
                        .foregroundColor(selectedUnit == unit ? .white : palette.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(
                                    selectedUnit == unit
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [palette.accent, palette.primary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ))
                                        : AnyShapeStyle(palette.textTertiary.opacity(0.1))
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var weightStepperControls: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            // Decrease buttons
            HStack(spacing: DesignTokens.Spacing.sm) {
                stepperButton(icon: "minus", large: true) {
                    adjustWeight(by: -1.0)
                }
                stepperButton(icon: "minus", large: false) {
                    adjustWeight(by: -0.1)
                }
            }

            Spacer()

            // Quick adjust label
            Text("Adjust")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(palette.textTertiary)

            Spacer()

            // Increase buttons
            HStack(spacing: DesignTokens.Spacing.sm) {
                stepperButton(icon: "plus", large: false) {
                    adjustWeight(by: 0.1)
                }
                stepperButton(icon: "plus", large: true) {
                    adjustWeight(by: 1.0)
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
    }

    private func stepperButton(icon: String, large: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
            let generator = UIImpactFeedbackGenerator(style: large ? .medium : .light)
            generator.impactOccurred()
        }) {
            Image(systemName: icon)
                .font(.system(size: large ? 18 : 14, weight: .semibold))
                .foregroundColor(palette.accent)
                .frame(width: large ? 52 : 40, height: large ? 52 : 40)
                .background(
                    Circle()
                        .fill(palette.accent.opacity(large ? 0.15 : 0.08))
                )
        }
        .buttonStyle(.plain)
    }

    private func adjustWeight(by amount: Double) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
            let currentTotal = weightValue + Double(weightDecimal) / 10.0
            var newTotal = currentTotal + amount

            // Clamp to reasonable range
            newTotal = max(20.0, min(300.0, newTotal))

            weightValue = floor(newTotal)
            weightDecimal = Int(round((newTotal - weightValue) * 10))

            // Handle decimal overflow
            if weightDecimal >= 10 {
                weightValue += 1
                weightDecimal = 0
            } else if weightDecimal < 0 {
                weightValue -= 1
                weightDecimal = 9
            }
        }
    }

    // MARK: - BMI Feedback Card

    private func bmiFeedbackCard(bmi: Double) -> some View {
        let (category, color, icon) = bmiCategoryInfo(bmi: bmi)

        return HStack(spacing: DesignTokens.Spacing.md) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text("BMI: \(String(format: "%.1f", bmi))")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(palette.textPrimary)

                Text(category)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(color)
            }

            Spacer()

            // Goal progress (if applicable)
            if let diff = weightDifferenceToGoal {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(diff > 0 ? "To lose" : "To gain")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(palette.textTertiary)

                    Text("\(String(format: "%.1f", abs(diff))) kg")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(diff > 0 ? Color.green : palette.accent)
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(Color.nutraSafeCard)
                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 3)
        )
    }

    private func bmiCategoryInfo(bmi: Double) -> (String, Color, String) {
        switch bmi {
        case ..<18.5:
            return ("Underweight", Color.orange, "arrow.down.circle")
        case 18.5..<25:
            return ("Healthy", Color.green, "checkmark.circle")
        case 25..<30:
            return ("Overweight", Color.orange, "exclamationmark.circle")
        default:
            return ("Obese", Color.red, "exclamationmark.triangle")
        }
    }

    // MARK: - Date/Time Section

    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Section label
            Text("When")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(palette.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)

            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showDatePicker.toggle()
                }
            }) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    // Calendar icon
                    Image(systemName: "calendar")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(palette.accent)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(palette.accent.opacity(0.1))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        if isNow {
                            Text("Right now")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(palette.textPrimary)
                        } else {
                            Text(entryDate, style: .date)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(palette.textPrimary)

                            Text(entryDate, style: .time)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(palette.textSecondary)
                        }
                    }

                    Spacer()

                    Image(systemName: showDatePicker ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(palette.textTertiary)
                }
                .padding(DesignTokens.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .fill(Color.nutraSafeCard)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 3)
                )
            }
            .buttonStyle(.plain)

            // Expanded date picker
            if showDatePicker {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    DatePicker(
                        "Select date and time",
                        selection: $entryDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .tint(palette.accent)

                    // Reset to now button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            entryDate = Date()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 14, weight: .medium))
                            Text("Set to now")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(palette.accent)
                        .padding(.vertical, 8)
                    }
                }
                .padding(DesignTokens.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .fill(Color.nutraSafeCard)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 3)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Progress Photos Section

    private var progressPhotosSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Section header
            HStack {
                Text("Progress Photos")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(palette.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text("Optional")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(palette.textTertiary.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(palette.textTertiary.opacity(0.1))
                    )
            }

            // Photo tiles grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                // Existing photos
                ForEach(selectedPhotos) { photo in
                    photoTile(photo: photo)
                }

                // Add photo tiles (up to 3 total)
                if selectedPhotos.count < 3 {
                    addPhotoTile(type: .camera)
                }
                if selectedPhotos.count < 2 {
                    addPhotoTile(type: .library)
                }
                if selectedPhotos.isEmpty {
                    emptyPhotoTile
                }
            }
        }
    }

    private func photoTile(photo: IdentifiableImage) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: photo.image)
                .resizable()
                .scaledToFill()
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                .onTapGesture {
                    selectedPhotoForViewing = photo
                }

            // Remove button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedPhotos.removeAll { $0.id == photo.id }
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.6))
                    )
            }
            .padding(6)
        }
    }

    private func addPhotoTile(type: PhotoTileType) -> some View {
        Button(action: {
            if type == .camera {
                activePickerType = .camera
            } else {
                showingMultiImagePicker = true
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: type == .camera ? "camera" : "photo.on.rectangle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(palette.accent)

                Text(type == .camera ? "Camera" : "Library")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(palette.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(palette.accent.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                            .strokeBorder(
                                palette.accent.opacity(0.2),
                                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var emptyPhotoTile: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(palette.textTertiary.opacity(0.5))

            Text("Track visually")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(palette.textTertiary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(palette.textTertiary.opacity(0.04))
        )
    }

    // MARK: - Optional Sections

    private var optionalSectionsArea: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Height section (collapsible)
            optionalSection(
                title: "Height",
                icon: "ruler",
                isExpanded: $showHeightSection,
                hasValue: !primaryHeight.isEmpty
            ) {
                heightInputContent
            }

            // Goal weight section (collapsible)
            optionalSection(
                title: "Goal Weight",
                icon: "target",
                isExpanded: $showGoalSection,
                hasValue: !goalWeightText.isEmpty || goalWeight > 0
            ) {
                goalWeightInputContent
            }

            // Note section (collapsible)
            optionalSection(
                title: "Note",
                icon: "note.text",
                isExpanded: $showNoteField,
                hasValue: !note.isEmpty
            ) {
                noteInputContent
            }

            // Measurements section (gender-based)
            if userGender == .female {
                optionalSection(
                    title: "Dress Size",
                    icon: "tshirt",
                    isExpanded: .constant(!dressSize.isEmpty),
                    hasValue: !dressSize.isEmpty
                ) {
                    dressSizeInputContent
                }
            } else {
                optionalSection(
                    title: "Waist Size",
                    icon: "ruler",
                    isExpanded: .constant(!waistSize.isEmpty),
                    hasValue: !waistSize.isEmpty
                ) {
                    waistSizeInputContent
                }
            }
        }
    }

    private func optionalSection<Content: View>(
        title: String,
        icon: String,
        isExpanded: Binding<Bool>,
        hasValue: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.wrappedValue.toggle()
                }
            }) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(hasValue ? palette.accent : palette.textTertiary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(hasValue ? palette.accent.opacity(0.1) : palette.textTertiary.opacity(0.08))
                        )

                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(palette.textPrimary)

                    if hasValue {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.green)
                    }

                    Spacer()

                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(palette.textTertiary)
                }
                .padding(DesignTokens.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(Color.nutraSafeCard)
                        .shadow(color: Color.black.opacity(0.03), radius: 6, y: 2)
                )
            }
            .buttonStyle(.plain)

            if isExpanded.wrappedValue {
                content()
                    .padding(.top, DesignTokens.Spacing.sm)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var heightInputContent: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // Unit selector
            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(HeightUnit.allCases, id: \.self) { unit in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedHeightUnit = unit
                        }
                    }) {
                        Text(unit.rawValue)
                            .font(.system(size: 13, weight: selectedHeightUnit == unit ? .semibold : .medium))
                            .foregroundColor(selectedHeightUnit == unit ? .white : palette.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(
                                        selectedHeightUnit == unit
                                            ? AnyShapeStyle(palette.accent)
                                            : AnyShapeStyle(palette.textTertiary.opacity(0.1))
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Input fields
            if selectedHeightUnit == .ftIn {
                HStack(spacing: DesignTokens.Spacing.md) {
                    heightTextField(placeholder: "Feet", text: $primaryHeight, suffix: "ft")
                    heightTextField(placeholder: "Inches", text: $secondaryHeight, suffix: "in")
                }
            } else {
                heightTextField(placeholder: "Height", text: $primaryHeight, suffix: selectedHeightUnit.shortName)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(palette.accent.opacity(0.04))
        )
    }

    private func heightTextField(placeholder: String, text: Binding<String>, suffix: String) -> some View {
        HStack(spacing: 8) {
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(palette.textPrimary)

            Text(suffix)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(palette.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                .fill(Color.nutraSafeCard)
        )
    }

    private var goalWeightInputContent: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            HStack(spacing: 8) {
                TextField("Goal weight", text: $goalWeightText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(palette.textPrimary)

                Text(selectedUnit.shortName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(palette.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                    .fill(Color.nutraSafeCard)
            )

            if let diff = weightDifferenceToGoal {
                HStack {
                    Text(diff > 0 ? "To lose:" : "To gain:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(palette.textSecondary)

                    Text("\(String(format: "%.1f", abs(diff))) \(selectedUnit.shortName)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(diff > 0 ? Color.green : palette.accent)
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(palette.accent.opacity(0.04))
        )
    }

    private var noteInputContent: some View {
        TextField("Add a note about today...", text: $note, axis: .vertical)
            .lineLimit(3...5)
            .font(.system(size: 15, weight: .regular))
            .foregroundColor(palette.textPrimary)
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(Color.nutraSafeCard)
            )
    }

    private var dressSizeInputContent: some View {
        TextField("e.g., UK 12", text: $dressSize)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(palette.textPrimary)
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(Color.nutraSafeCard)
            )
    }

    private var waistSizeInputContent: some View {
        HStack(spacing: 8) {
            TextField("Waist", text: $waistSize)
                .keyboardType(.decimalPad)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(palette.textPrimary)

            Text("cm")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(palette.textSecondary)
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(Color.nutraSafeCard)
        )
    }

    // MARK: - Save Button Section

    private var saveButtonSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            NutraSafePrimaryButton(
                existingEntry != nil ? "Update Entry" : "Save Progress",
                isEnabled: !isUploading
            ) {
                saveWeight()
            }

            // Cancel link
            Button(action: dismissView) {
                Text("Cancel")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(palette.textSecondary)
            }
        }
        .padding(.top, DesignTokens.Spacing.lg)
    }

    // MARK: - Upload Overlay

    private var uploadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: DesignTokens.Spacing.md) {
                ProgressView()
                    .scaleEffect(1.3)
                    .tint(.white)

                Text(selectedPhotos.isEmpty ? "Saving..." : "Uploading photos...")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(DesignTokens.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                    .fill(.ultraThinMaterial)
            )
        }
    }

    // MARK: - Helper Methods

    private func setupInitialValues() {
        // Set initial weight
        if currentWeight > 0 {
            let converted = selectedUnit.fromKg(currentWeight)
            weightValue = floor(converted.primary)
            weightDecimal = Int(round((converted.primary - weightValue) * 10))
        }

        // Set initial height
        if userHeight > 0 {
            let converted = selectedHeightUnit.fromCm(userHeight)
            primaryHeight = String(format: converted.secondary != nil ? "%.0f" : "%.1f", converted.primary)
            if let secondary = converted.secondary {
                secondaryHeight = String(format: "%.1f", secondary)
            }
        }

        // Set initial goal
        if goalWeight > 0 {
            goalWeightText = goalWeightDisplayValue(goalWeight)
        }
    }

    private func goalWeightDisplayValue(_ kg: Double) -> String {
        switch selectedUnit {
        case .kg: return String(format: "%.1f", kg)
        case .lbs: return String(format: "%.1f", kg * 2.20462)
        case .stones: return String(format: "%.1f", kg / 6.35029)
        }
    }

    private func convertAndSetUnit(to newUnit: WeightUnit) {
        // Get current weight in kg
        let currentKg = weightInKg

        // Update unit
        selectedUnit = newUnit

        // Convert to new unit
        let converted = newUnit.fromKg(currentKg)
        weightValue = floor(converted.primary)
        weightDecimal = Int(round((converted.primary - weightValue) * 10))

        // Update goal weight display
        if goalWeight > 0 {
            goalWeightText = goalWeightDisplayValue(goalWeight)
        }
    }

    private func dismissView() {
        if let instantDismiss = onInstantDismiss {
            instantDismiss()
        } else {
            dismiss()
        }
    }

    private func saveWeight() {
        isUploading = true

        Task {
            do {
                let entryId = UUID()
                let images = selectedPhotos.map { $0.image }

                // Save images locally first
                var photoURLs: [String] = []
                if !images.isEmpty {
                    try? ImageCacheManager.shared.saveWeightImages(images, for: entryId.uuidString)

                    // Upload to Firebase
                    do {
                        photoURLs = try await firebaseManager.uploadWeightPhotos(images)
                    } catch {
                        print("Image upload failed: \(error)")
                    }
                }

                // Parse measurements
                let waist = waistSize.isEmpty ? nil : Double(waistSize)
                let dress = dressSize.isEmpty ? nil : dressSize

                // Create weight entry with all fields
                let newEntry = WeightEntry(
                    id: entryId,
                    weight: weightInKg,
                    date: entryDate,
                    bmi: calculatedBMI,
                    note: note.isEmpty ? nil : note,
                    photoURL: photoURLs.first,
                    photoURLs: photoURLs.isEmpty ? nil : photoURLs,
                    waistSize: waist,
                    dressSize: dress
                )

                // Save to Firebase
                try await firebaseManager.saveWeightEntry(newEntry)

                // Save height changes if user modified it
                if let heightCm = heightInCm, heightCm != userHeight {
                    try await firebaseManager.saveUserSettings(height: heightCm, goalWeight: nil)
                }

                // Save goal weight if changed
                let newGoalKg = goalWeightInKg
                if let newGoal = newGoalKg, newGoal != goalWeight {
                    try await firebaseManager.saveUserSettings(height: nil, goalWeight: newGoal)
                    // Notify other views about goal weight change
                    await MainActor.run {
                        NotificationCenter.default.post(
                            name: .goalWeightUpdated,
                            object: nil,
                            userInfo: ["goalWeight": newGoal]
                        )
                    }
                }

                // Update local state
                await MainActor.run {
                    currentWeight = weightInKg

                    // Update height if changed
                    if let heightCm = heightInCm, heightCm != userHeight {
                        userHeight = heightCm
                    }

                    // Update goal if changed
                    if let newGoal = newGoalKg, newGoal != goalWeight {
                        goalWeight = newGoal
                    }

                    isUploading = false

                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)

                    // Dismiss
                    dismissView()
                }
            } catch {
                await MainActor.run {
                    isUploading = false
                    print("Save failed: \(error)")
                }
            }
        }
    }
}

// MARK: - Supporting Types

private enum PhotoTileType {
    case camera
    case library
}

// MARK: - Photo Detail View

private struct PhotoDetailView: View {
    let image: UIImage
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()

            VStack {
                HStack {
                    Spacer()

                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                            )
                    }
                    .padding()
                }

                Spacer()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LogWeightView(
        currentWeight: .constant(75.0),
        weightHistory: .constant([]),
        userHeight: .constant(175.0),
        goalWeight: .constant(70.0)
    )
    .environmentObject(FirebaseManager.shared)
}
