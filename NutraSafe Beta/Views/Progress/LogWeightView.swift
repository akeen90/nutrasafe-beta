//
//  LogWeightView.swift
//  NutraSafe Beta
//
//  Redesigned Log Weight screen - part of the Progress journey
//  Emotional, intentional, calming - not a utility form
//

import SwiftUI
import PhotosUI
import UIKit

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
    var onSave: (() -> Void)? = nil

    // User preferences
    @AppStorage("weightUnit") private var selectedUnit: WeightUnit = .kg
    @AppStorage("heightUnit") private var selectedHeightUnit: HeightUnit = .cm
    @AppStorage("userGender") private var userGender: Gender = .other
    @AppStorage("cachedCurrentWeight") private var cachedCurrentWeight: Double = 0

    // Weight state
    @State private var weightValue: Double = 70.0  // For kg/lbs: whole number; For stones: stones value
    @State private var hasInitializedWeight = false
    @State private var weightDecimal: Int = 0  // For kg/lbs: decimal (0-9); For stones: pounds (0-13)
    @State private var isEditingWeight = false
    @State private var weightTextInput: String = ""
    @State private var secondaryWeightInput: String = ""  // For stones: pounds input
    @FocusState private var weightFieldFocused: Bool
    @FocusState private var secondaryWeightFieldFocused: Bool

    // Height state
    @State private var primaryHeight: String = ""
    @State private var secondaryHeight: String = ""
    @State private var showHeightSection = false

    // Goal state
    @State private var goalWeightText: String = ""
    @State private var goalStoneText: String = ""
    @State private var goalPoundsText: String = ""
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
    @State private var showWaistSection = false
    @State private var showDressSection = false

    // UI state
    @State private var isUploading = false
    @State private var showSaveConfirmation = false
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    // MARK: - Computed Properties

    private var weightInKg: Double {
        switch selectedUnit {
        case .kg, .lbs:
            // For kg/lbs, weightDecimal is a decimal digit (0-9)
            let decimal = Double(weightDecimal) / 10.0
            let total = weightValue + decimal
            return selectedUnit.toKg(primary: total, secondary: nil)
        case .stones:
            // For stones, weightValue is stones and weightDecimal is pounds (0-13)
            return selectedUnit.toKg(primary: weightValue, secondary: Double(weightDecimal))
        }
    }

    private var displayWeight: String {
        switch selectedUnit {
        case .kg, .lbs:
            let decimal = Double(weightDecimal) / 10.0
            return String(format: "%.1f", weightValue + decimal)
        case .stones:
            // For stones, show just the stone value (lbs shown separately)
            return String(format: "%.0f", weightValue)
        }
    }

    private var displayPounds: String {
        // Only used for stones mode
        return String(format: "%.0f", Double(weightDecimal))
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
        switch selectedUnit {
        case .kg, .lbs:
            let sanitized = goalWeightText.replacingOccurrences(of: ",", with: ".")
            guard let value = Double(sanitized), value > 0 else { return nil }
            return selectedUnit == .kg ? value : value / UnitConversion.lbsPerKg
        case .stones:
            // Use separate stones/pounds fields
            let stones = Double(goalStoneText) ?? 0
            let pounds = Double(goalPoundsText) ?? 0
            guard stones > 0 || pounds > 0 else { return nil }
            return UnitConversion.stonesToKg(stones: stones, pounds: pounds)
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
            .scrollDismissesKeyboard(.interactively)
            .keyboardDismissButton()

            // Upload overlay
            if isUploading {
                uploadingOverlay
            }
        }
        .onAppear(perform: setupInitialValues)
        .onChange(of: currentWeight) { _, newWeight in
            // If weight binding updates after view appeared (data loaded late)
            // and user hasn't manually edited yet, update to the correct weight
            // Note: Only respond to currentWeight if weightHistory hasn't provided a value yet
            if !hasInitializedWeight && existingEntry == nil && newWeight > 0 {
                let converted = selectedUnit.fromKg(newWeight)
                weightValue = floor(converted.primary)
                switch selectedUnit {
                case .kg, .lbs:
                    weightDecimal = Int(round((converted.primary - weightValue) * 10))
                case .stones:
                    weightDecimal = Int(round(converted.secondary ?? 0))
                }
                hasInitializedWeight = true
            }
        }
        .onChange(of: weightHistory) { _, newHistory in
            // If weight history binding updates after view appeared
            // and we still haven't initialized, use the latest entry
            // Priority: weightHistory > currentWeight (history is more authoritative)
            guard !hasInitializedWeight && existingEntry == nil else { return }
            guard let latest = newHistory.first else { return }

            let converted = selectedUnit.fromKg(latest.weight)
            weightValue = floor(converted.primary)
            switch selectedUnit {
            case .kg, .lbs:
                weightDecimal = Int(round((converted.primary - weightValue) * 10))
            case .stones:
                weightDecimal = Int(round(converted.secondary ?? 0))
            }
            hasInitializedWeight = true
        }
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
        .alert("Save Failed", isPresented: $showSaveError) {
            Button("Try Again") {
                saveWeight()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(saveErrorMessage)
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
                // Large weight value - tap to edit
                if selectedUnit == .stones {
                    // Stones mode: show two values (stones + lbs)
                    stonesWeightDisplay
                } else {
                    // kg/lbs mode: single value with decimal
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        if isEditingWeight {
                            // Text input mode
                            TextField("", text: $weightTextInput)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [palette.accent, palette.primary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .multilineTextAlignment(.center)
                                .frame(minWidth: 120)
                                .focused($weightFieldFocused)
                                .onSubmit {
                                    commitWeightInput()
                                }
                                .onChange(of: weightFieldFocused) { _, focused in
                                    if !focused {
                                        commitWeightInput()
                                    }
                                }
                        } else {
                            // Display mode - tap to edit
                            Text(displayWeight)
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [palette.accent, palette.primary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .onTapGesture {
                                    startWeightEditing()
                                }
                        }

                        Text(selectedUnit.shortName)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(palette.textSecondary)
                    }
                }

                // Tap to edit hint
                if !isEditingWeight && selectedUnit != .stones {
                    Text("Tap to type")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(palette.textTertiary)
                        .padding(.top, 2)
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
            .onTapGesture {
                // Dismiss keyboard if tapping outside text field
                if isEditingWeight && !weightFieldFocused {
                    commitWeightInput()
                }
            }

            // Weight stepper controls (fine adjustment)
            weightStepperControls
        }
    }

    private func startWeightEditing() {
        weightTextInput = displayWeight
        isEditingWeight = true
        // Slight delay to ensure the text field is visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            weightFieldFocused = true
        }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func commitWeightInput() {
        isEditingWeight = false
        weightFieldFocused = false

        // Parse the input
        let sanitized = weightTextInput.replacingOccurrences(of: ",", with: ".")
        if let value = Double(sanitized), value > 0 {
            // Clamp to reasonable range
            let clamped = max(20.0, min(300.0, value))
            weightValue = floor(clamped)
            weightDecimal = Int(round((clamped - weightValue) * 10))

            // Handle decimal overflow
            if weightDecimal >= 10 {
                weightValue += 1
                weightDecimal = 0
            }
        }
        // If invalid input, just keep current value
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

    // MARK: - Stones Weight Display

    private var stonesWeightDisplay: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            // Stones value
            VStack(spacing: 2) {
                if isEditingWeight {
                    TextField("", text: $weightTextInput)
                        .keyboardType(.numberPad)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [palette.accent, palette.primary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .multilineTextAlignment(.center)
                        .frame(width: 80)
                        .focused($weightFieldFocused)
                        .onSubmit {
                            commitStonesInput()
                        }
                        .onChange(of: weightFieldFocused) { _, focused in
                            if !focused && !secondaryWeightFieldFocused {
                                commitStonesInput()
                            }
                        }
                } else {
                    Text(displayWeight)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [palette.accent, palette.primary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .onTapGesture {
                            startStonesEditing(editingStones: true)
                        }
                }

                Text("st")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(palette.textSecondary)
            }

            // Pounds value
            VStack(spacing: 2) {
                if isEditingWeight {
                    TextField("", text: $secondaryWeightInput)
                        .keyboardType(.numberPad)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [palette.accent, palette.primary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .multilineTextAlignment(.center)
                        .frame(width: 80)
                        .focused($secondaryWeightFieldFocused)
                        .onSubmit {
                            commitStonesInput()
                        }
                        .onChange(of: secondaryWeightFieldFocused) { _, focused in
                            if !focused && !weightFieldFocused {
                                commitStonesInput()
                            }
                        }
                } else {
                    Text(displayPounds)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [palette.accent, palette.primary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .onTapGesture {
                            startStonesEditing(editingStones: false)
                        }
                }

                Text("lbs")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(palette.textSecondary)
            }
        }
        .padding(.vertical, 8)
    }

    private func startStonesEditing(editingStones: Bool) {
        weightTextInput = String(format: "%.0f", weightValue)
        secondaryWeightInput = String(format: "%.0f", Double(weightDecimal))
        isEditingWeight = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if editingStones {
                weightFieldFocused = true
            } else {
                secondaryWeightFieldFocused = true
            }
        }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func commitStonesInput() {
        isEditingWeight = false
        weightFieldFocused = false
        secondaryWeightFieldFocused = false

        // Parse stones input
        if let stones = Double(weightTextInput), stones >= 0 {
            weightValue = floor(max(3, min(50, stones)))  // 3-50 stone range
        }

        // Parse pounds input
        if let pounds = Int(secondaryWeightInput) {
            weightDecimal = max(0, min(13, pounds))  // 0-13 lbs range
        }
    }

    private var weightStepperControls: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            // Label row
            Text("Fine Adjustment")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(palette.textTertiary)

            // Stepper buttons row
            HStack(spacing: DesignTokens.Spacing.md) {
                // Decrease buttons
                HStack(spacing: DesignTokens.Spacing.sm) {
                    stepperButton(icon: "minus", amount: 1.0, isLarge: true) {
                        adjustWeight(by: -1.0)
                    }
                    stepperButton(icon: "minus", amount: 0.1, isLarge: false) {
                        adjustWeight(by: -0.1)
                    }
                }

                Spacer()

                // Increase buttons
                HStack(spacing: DesignTokens.Spacing.sm) {
                    stepperButton(icon: "plus", amount: 0.1, isLarge: false) {
                        adjustWeight(by: 0.1)
                    }
                    stepperButton(icon: "plus", amount: 1.0, isLarge: true) {
                        adjustWeight(by: 1.0)
                    }
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
    }

    private func stepperButton(icon: String, amount: Double, isLarge: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
            let generator = UIImpactFeedbackGenerator(style: isLarge ? .medium : .light)
            generator.impactOccurred()
        }) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: isLarge ? 16 : 12, weight: .semibold))
                    .foregroundColor(palette.accent)

                Text(stepperLabel(amount: amount, isLarge: isLarge))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(palette.textTertiary)
            }
            .frame(width: isLarge ? 52 : 44, height: isLarge ? 52 : 44)
            .background(
                Circle()
                    .fill(palette.accent.opacity(isLarge ? 0.12 : 0.06))
            )
        }
        .buttonStyle(.plain)
    }

    private func stepperLabel(amount: Double, isLarge: Bool) -> String {
        switch selectedUnit {
        case .kg:
            return isLarge ? "±1 kg" : "±0.1"
        case .lbs:
            return isLarge ? "±1 lb" : "±0.1"
        case .stones:
            return isLarge ? "±1 st" : "±1 lb"
        }
    }

    private func adjustWeight(by amount: Double) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
            switch selectedUnit {
            case .kg, .lbs:
                // For kg/lbs: decimal is 0-9 representing 0.0-0.9
                let currentTotal = weightValue + Double(weightDecimal) / 10.0
                var newTotal = currentTotal + amount

                // Clamp to reasonable range (20-300 for kg, or equivalent)
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

            case .stones:
                // For stones: weightDecimal is pounds (0-13)
                // amount of 1.0 = 1 stone, amount of 0.1 = 1 lb
                if abs(amount) >= 1.0 {
                    // Adjusting stones
                    let stoneChange = amount >= 0 ? 1.0 : -1.0
                    var newStones = weightValue + stoneChange

                    // Clamp to 3-50 stone range
                    newStones = max(3.0, min(50.0, newStones))
                    weightValue = newStones
                } else {
                    // Adjusting pounds (0.1 = 1 lb)
                    let lbChange = amount >= 0 ? 1 : -1
                    var newLbs = weightDecimal + lbChange

                    // Handle rollover
                    if newLbs >= 14 {
                        weightValue += 1
                        newLbs = 0
                    } else if newLbs < 0 {
                        if weightValue > 3 {
                            weightValue -= 1
                            newLbs = 13
                        } else {
                            newLbs = 0
                        }
                    }

                    weightDecimal = newLbs
                }
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
            // Section header - outside the card for consistency with other sections
            HStack(spacing: 6) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(palette.accent.opacity(0.6))

                Text("Progress Photos")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(palette.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text("Optional")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(palette.textTertiary.opacity(0.5))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(palette.textTertiary.opacity(0.08))
                    )

                Spacer()
            }

            // Photo grid contained in card
            VStack(spacing: DesignTokens.Spacing.sm) {
                if !selectedPhotos.isEmpty {
                    // Show existing photos in horizontal scroll
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(selectedPhotos) { photo in
                                photoTile(photo: photo)
                            }

                            // Add more button if less than 3
                            if selectedPhotos.count < 3 {
                                addMorePhotoButton
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                } else {
                    // Empty state with action buttons
                    HStack(spacing: 12) {
                        addPhotoTile(type: .camera)
                        addPhotoTile(type: .library)
                    }
                }

                // Helper text
                if selectedPhotos.isEmpty {
                    Text("Track your progress visually over time")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(palette.textTertiary.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(Color.nutraSafeCard)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 3)
            )
        }
    }

    private var addMorePhotoButton: some View {
        Menu {
            Button(action: { activePickerType = .camera }) {
                Label("Take Photo", systemImage: "camera")
            }
            Button(action: { showingMultiImagePicker = true }) {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(palette.accent)

                Text("Add")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(palette.textSecondary)
            }
            .frame(width: 90, height: 90)
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
    }

    private func photoTile(photo: IdentifiableImage) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: photo.image)
                .resizable()
                .scaledToFill()
                .frame(width: 90, height: 90)
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
                    .frame(width: 20, height: 20)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.6))
                    )
            }
            .padding(4)
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
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(palette.accent)

                Text(type == .camera ? "Camera" : "Library")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(palette.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(palette.accent.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                            .strokeBorder(
                                palette.accent.opacity(0.15),
                                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                            )
                    )
            )
        }
        .buttonStyle(.plain)
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
                    isExpanded: $showDressSection,
                    hasValue: !dressSize.isEmpty
                ) {
                    dressSizeInputContent
                }
            } else {
                optionalSection(
                    title: "Waist Size",
                    icon: "ruler",
                    isExpanded: $showWaistSection,
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
            // Header button
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
                        .rotationEffect(.degrees(isExpanded.wrappedValue ? 0 : 0))
                }
                .padding(DesignTokens.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: isExpanded.wrappedValue ? DesignTokens.Radius.md : DesignTokens.Radius.md)
                        .fill(Color.nutraSafeCard)
                        .shadow(color: Color.black.opacity(0.03), radius: 6, y: 2)
                )
            }
            .buttonStyle(.plain)

            // Expanded content - contained within the same visual block
            if isExpanded.wrappedValue {
                VStack(spacing: 0) {
                    content()
                }
                .padding(.top, DesignTokens.Spacing.sm)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
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
            if selectedUnit == .stones {
                // Stones & pounds input for goal weight
                HStack(spacing: 12) {
                    // Stone input
                    VStack(spacing: 4) {
                        TextField("0", text: $goalStoneText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(palette.textPrimary)
                            .frame(width: 60)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                                    .fill(Color.nutraSafeCard)
                            )
                        Text("stone")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(palette.textSecondary)
                    }

                    // Pounds input
                    VStack(spacing: 4) {
                        TextField("0", text: $goalPoundsText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(palette.textPrimary)
                            .frame(width: 60)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                                    .fill(Color.nutraSafeCard)
                            )
                        Text("lbs")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(palette.textSecondary)
                    }

                    Spacer()
                }
            } else {
                // Single field input for kg/lbs
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
            }

            if let diff = weightDifferenceToGoal {
                HStack {
                    Text(diff > 0 ? "To lose:" : "To gain:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(palette.textSecondary)

                    Text(formattedWeightDifference(abs(diff)))
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

    /// Formats weight difference in the appropriate unit format
    private func formattedWeightDifference(_ kgDiff: Double) -> String {
        switch selectedUnit {
        case .kg:
            return String(format: "%.1f kg", kgDiff)
        case .lbs:
            return String(format: "%.1f lbs", kgDiff * UnitConversion.lbsPerKg)
        case .stones:
            let (stones, pounds) = UnitConversion.kgToStones(kgDiff)
            if stones > 0 {
                return "\(stones) st \(pounds) lb"
            } else {
                return "\(pounds) lb"
            }
        }
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

            Text(selectedHeightUnit == .cm ? "cm" : "in")
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
        // If editing an existing entry, load its values
        if let entry = existingEntry {
            // Load weight from existing entry
            let converted = selectedUnit.fromKg(entry.weight)
            weightValue = floor(converted.primary)
            switch selectedUnit {
            case .kg, .lbs:
                weightDecimal = Int(round((converted.primary - weightValue) * 10))
            case .stones:
                weightDecimal = Int(round(converted.secondary ?? 0))
            }
            hasInitializedWeight = true

            // Load date
            entryDate = entry.date

            // Load note
            if let entryNote = entry.note {
                note = entryNote
                showNoteField = true
            }

            // Load measurements (waistSize stored in cm, convert to inches if imperial)
            if let waist = entry.waistSize {
                let displayWaist = selectedHeightUnit == .cm ? waist : waist / 2.54
                waistSize = String(format: "%.1f", displayWaist)
                showWaistSection = true
            }
            if let dress = entry.dressSize {
                dressSize = dress
                showDressSection = true
            }

            // Load photos if available
            loadExistingPhotos(from: entry)
        } else {
            // Creating new entry - use best available weight source
            // Priority: currentWeight > weightHistory > cachedWeightHistory > AppStorage cache > default
            let weightToUse: Double
            if currentWeight > 0 {
                weightToUse = currentWeight
            } else if let latestEntry = weightHistory.first {
                // Fallback to most recent weight history entry from binding
                weightToUse = latestEntry.weight
            } else if let cachedEntry = firebaseManager.cachedWeightHistory.first {
                // Fallback to FirebaseManager's cache
                weightToUse = cachedEntry.weight
            } else if cachedCurrentWeight > 0 {
                // Fallback to locally persisted weight (AppStorage)
                weightToUse = cachedCurrentWeight
            } else {
                // No weight data available - keep default
                weightToUse = 0
            }

            if weightToUse > 0 {
                let converted = selectedUnit.fromKg(weightToUse)
                weightValue = floor(converted.primary)
                switch selectedUnit {
                case .kg, .lbs:
                    weightDecimal = Int(round((converted.primary - weightValue) * 10))
                case .stones:
                    weightDecimal = Int(round(converted.secondary ?? 0))
                }
                hasInitializedWeight = true
            }
        }

        // Set initial height (always from user profile)
        if userHeight > 0 {
            let converted = selectedHeightUnit.fromCm(userHeight)
            primaryHeight = String(format: converted.secondary != nil ? "%.0f" : "%.1f", converted.primary)
            if let secondary = converted.secondary {
                secondaryHeight = String(format: "%.1f", secondary)
            }
        }

        // Set initial goal (always from user profile)
        if goalWeight > 0 {
            if selectedUnit == .stones {
                initializeGoalStonesFields(from: goalWeight)
            } else {
                goalWeightText = goalWeightDisplayValue(goalWeight)
            }
        }
    }

    private func loadExistingPhotos(from entry: WeightEntry) {
        // Load photos from URLs if available
        guard let photoURLs = entry.photoURLs, !photoURLs.isEmpty else {
            // Try single photoURL for backwards compatibility
            if let singleURL = entry.photoURL {
                loadPhotoFromURL(singleURL)
            }
            return
        }

        for urlString in photoURLs {
            loadPhotoFromURL(urlString)
        }
    }

    private func loadPhotoFromURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        if selectedPhotos.count < 3 {
                            selectedPhotos.append(IdentifiableImage(image: image, url: urlString))
                        }
                    }
                }
            } catch {
                print("Failed to load photo from URL: \(error)")
            }
        }
    }

    private func goalWeightDisplayValue(_ kg: Double) -> String {
        switch selectedUnit {
        case .kg: return String(format: "%.1f", kg)
        case .lbs: return String(format: "%.1f", kg * UnitConversion.lbsPerKg)
        case .stones:
            // For stones mode, we use separate fields, so return empty
            // The caller should also call initializeGoalStonesFields()
            return ""
        }
    }

    /// Initialize stone/pounds goal weight fields from kg value
    private func initializeGoalStonesFields(from kg: Double) {
        let (stones, pounds) = UnitConversion.kgToStones(kg)
        goalStoneText = String(stones)
        goalPoundsText = String(pounds)
    }

    private func convertAndSetUnit(to newUnit: WeightUnit) {
        // Get current weight in kg (before changing unit)
        let currentKg = weightInKg

        // Update unit
        selectedUnit = newUnit

        // Convert to new unit
        let converted = newUnit.fromKg(currentKg)

        switch newUnit {
        case .kg, .lbs:
            // For kg/lbs: weightDecimal is a decimal digit (0-9)
            weightValue = floor(converted.primary)
            weightDecimal = Int(round((converted.primary - weightValue) * 10))
            // Handle overflow
            if weightDecimal >= 10 {
                weightValue += 1
                weightDecimal = 0
            }
        case .stones:
            // For stones: weightValue is stones, weightDecimal is pounds (0-13)
            weightValue = floor(converted.primary)
            weightDecimal = Int(round(converted.secondary ?? 0))
            // Ensure pounds is in valid range
            if weightDecimal >= 14 {
                weightValue += 1
                weightDecimal = 0
            }
        }

        // Update goal weight display
        if goalWeight > 0 {
            if newUnit == .stones {
                initializeGoalStonesFields(from: goalWeight)
            } else {
                goalWeightText = goalWeightDisplayValue(goalWeight)
            }
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
                // Use existing entry ID when editing, otherwise create new
                let entryId = existingEntry?.id ?? UUID()

                // Determine which images are new (need uploading) vs existing (already have URLs)
                var photoURLs: [String] = []
                var newImages: [UIImage] = []

                for photo in selectedPhotos {
                    if let existingURL = photo.url {
                        // Keep existing URL
                        photoURLs.append(existingURL)
                    } else {
                        // New image that needs uploading
                        newImages.append(photo.image)
                    }
                }

                // Upload new images if any
                if !newImages.isEmpty {
                    try? ImageCacheManager.shared.saveWeightImages(newImages, for: entryId.uuidString)

                    // Upload to Firebase
                    do {
                        let uploadedURLs = try await firebaseManager.uploadWeightPhotos(newImages)
                        photoURLs.append(contentsOf: uploadedURLs)
                    } catch {
                        print("Image upload failed: \(error)")
                    }
                }

                // Parse measurements (waist entered in display units, convert to cm for storage)
                let waistDisplayValue = waistSize.isEmpty ? nil : Double(waistSize)
                let waist = waistDisplayValue.map { selectedHeightUnit == .cm ? $0 : $0 * 2.54 }
                let dress = dressSize.isEmpty ? nil : dressSize

                // Create/update weight entry with all fields
                let updatedEntry = WeightEntry(
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

                // Save to Firebase (handles both create and update)
                try await firebaseManager.saveWeightEntry(updatedEntry)

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
                    // Persist to AppStorage for instant access on app restart
                    cachedCurrentWeight = weightInKg

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

                    // Call onSave callback to refresh history
                    onSave?()

                    // Dismiss
                    dismissView()
                }
            } catch {
                await MainActor.run {
                    isUploading = false
                    saveErrorMessage = "Failed to save. Please try again."
                    showSaveError = true
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
