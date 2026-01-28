//
//  ExtendedOnboardingScreens.swift
//  NutraSafe Beta
//
//  Extended onboarding screens for personal details, sensitivities, and permissions
//  Designed to feel like a seamless continuation of the premium onboarding flow
//

import SwiftUI
import AVFoundation
import UserNotifications
import HealthKit

// MARK: - Personal Details Screen

struct PersonalDetailsScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    let onContinue: () -> Void
    var onBack: (() -> Void)? = nil

    @State private var hasBirthdayBeenSet = false
    @State private var heightText: String = ""
    @State private var weightText: String = ""
    @State private var weightStoneText: String = ""
    @State private var weightPoundsText: String = ""
    @State private var isEditingHeight = false
    @State private var isEditingWeight = false
    @State private var selectedWeightUnit: WeightUnit = .kg
    @State private var isInitializingStoneFields = false  // Prevents race condition during initialization
    @FocusState private var heightFieldFocused: Bool
    @FocusState private var weightFieldFocused: Bool
    @FocusState private var stoneFieldFocused: Bool
    @FocusState private var poundsFieldFocused: Bool
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }

    // Height range (100cm - 250cm)
    private let heightRange: ClosedRange<Double> = 100...250
    // Weight range (30kg - 300kg)
    private let weightRange: ClosedRange<Double> = 30...300

    // Date range for birthday picker (ages 13 to 120)
    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let minAge = calendar.date(byAdding: .year, value: -120, to: Date())!
        let maxAge = calendar.date(byAdding: .year, value: -13, to: Date())!
        return minAge...maxAge
    }

    var body: some View {
        VStack(spacing: 0) {
            // Back button
            if let onBack = onBack {
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(state.palette.primary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }

            Spacer()

            // Headline - larger on iPad
            VStack(spacing: 8) {
                Text("A little about you")
                    .font(.system(size: isIPad ? 36 : 28, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))

                Text("For accurate calorie targets")
                    .font(.system(size: isIPad ? 18 : 15, weight: .regular))
                    .foregroundColor(Color(white: 0.5))
            }
            .padding(.bottom, isIPad ? 12 : 8)

            // Helper text
            Text("We use this to calculate your personal BMR and daily calorie needs.")
                .font(.system(size: isIPad ? 16 : 14, weight: .regular))
                .foregroundColor(Color(white: 0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, isIPad ? 60 : 40)
                .padding(.bottom, isIPad ? 20 : 24)

            VStack(spacing: isIPad ? 24 : 20) {
                // Date of Birth
                PersonalDetailCard(
                    icon: "calendar",
                    title: "Date of birth",
                    palette: state.palette
                ) {
                    DatePicker(
                        "Birthday",
                        selection: $state.birthDate,
                        in: dateRange,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .onChange(of: state.birthDate) { _, _ in
                        hasBirthdayBeenSet = true
                    }

                    if hasBirthdayBeenSet || state.age != 30 {
                        Text("\(state.age) years old")
                            .font(.system(size: isIPad ? 15 : 13))
                            .foregroundColor(state.palette.primary)
                    }
                }

                // Height - with text input option
                PersonalDetailCard(
                    icon: "ruler",
                    title: "Height",
                    palette: state.palette
                ) {
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            Slider(value: $state.heightCm, in: heightRange, step: 1)
                                .accentColor(state.palette.primary)

                            // Tappable text field - larger on iPad
                            Button {
                                heightText = "\(Int(state.heightCm))"
                                isEditingHeight = true
                                heightFieldFocused = true
                            } label: {
                                if isEditingHeight {
                                    TextField("", text: $heightText)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.center)
                                        .font(.system(size: horizontalSizeClass == .regular ? 22 : 15, weight: .medium))
                                        .foregroundColor(Color(white: 0.3))
                                        .frame(width: horizontalSizeClass == .regular ? 80 : 50)
                                        .padding(.vertical, horizontalSizeClass == .regular ? 12 : 0)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.white.opacity(0.7))
                                        )
                                        .focused($heightFieldFocused)
                                        .onChange(of: heightFieldFocused) { _, focused in
                                            if !focused {
                                                isEditingHeight = false
                                                if let value = Double(heightText), heightRange.contains(value) {
                                                    state.heightCm = value
                                                }
                                            }
                                        }
                                } else {
                                    Text("\(Int(state.heightCm))")
                                        .font(.system(size: horizontalSizeClass == .regular ? 22 : 15, weight: .medium))
                                        .foregroundColor(Color(white: 0.3))
                                        .frame(width: horizontalSizeClass == .regular ? 80 : 50)
                                        .padding(.vertical, horizontalSizeClass == .regular ? 12 : 0)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.white.opacity(0.5))
                                        )
                                }
                            }
                            .buttonStyle(.plain)

                            Text("cm")
                                .font(.system(size: horizontalSizeClass == .regular ? 18 : 14))
                                .foregroundColor(Color(white: 0.5))
                        }

                        // Show feet/inches conversion
                        let feet = Int(state.heightCm / 30.48)
                        let inches = Int((state.heightCm / 2.54).truncatingRemainder(dividingBy: 12))
                        Text("\(feet)'\(inches)\"")
                            .font(.system(size: 13))
                            .foregroundColor(Color(white: 0.5))
                    }
                }

                // Weight - with unit selector and text input
                PersonalDetailCard(
                    icon: "scalemass",
                    title: "Current weight",
                    palette: state.palette
                ) {
                    VStack(spacing: 12) {
                        // Unit selector
                        HStack(spacing: 8) {
                            ForEach([WeightUnit.kg, .stones], id: \.self) { unit in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        // Convert current weight to new unit for display
                                        if unit != selectedWeightUnit {
                                            if unit == .stones {
                                                // Converting from kg to stone - prevent onChange from firing
                                                isInitializingStoneFields = true
                                                let converted = WeightUnit.stones.fromKg(state.weightKg)
                                                weightStoneText = String(format: "%.0f", converted.primary)
                                                weightPoundsText = String(format: "%.0f", converted.secondary ?? 0)
                                                DispatchQueue.main.async {
                                                    isInitializingStoneFields = false
                                                }
                                            } else {
                                                // Converting from stone to kg
                                                weightText = String(format: "%.1f", state.weightKg)
                                            }
                                            selectedWeightUnit = unit
                                        }
                                    }
                                } label: {
                                    Text(unit == .kg ? "kg" : "stone")
                                        .font(.system(size: isIPad ? 15 : 13, weight: selectedWeightUnit == unit ? .semibold : .regular))
                                        .foregroundColor(selectedWeightUnit == unit ? .white : Color(white: 0.4))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(selectedWeightUnit == unit ? state.palette.primary : Color.white.opacity(0.6))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                            Spacer()
                        }

                        if selectedWeightUnit == .kg {
                            // Kilograms input
                            HStack(spacing: 12) {
                                Slider(value: $state.weightKg, in: weightRange, step: 0.5)
                                    .accentColor(state.palette.primary)

                                // Tappable text field
                                Button {
                                    weightText = String(format: "%.1f", state.weightKg)
                                    isEditingWeight = true
                                    weightFieldFocused = true
                                } label: {
                                    if isEditingWeight {
                                        TextField("", text: $weightText)
                                            .keyboardType(.decimalPad)
                                            .multilineTextAlignment(.center)
                                            .font(.system(size: isIPad ? 22 : 15, weight: .medium))
                                            .foregroundColor(Color(white: 0.3))
                                            .frame(width: isIPad ? 90 : 55)
                                            .padding(.vertical, isIPad ? 12 : 0)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.white.opacity(0.7))
                                            )
                                            .focused($weightFieldFocused)
                                            .onChange(of: weightFieldFocused) { _, focused in
                                                if !focused {
                                                    isEditingWeight = false
                                                    if let value = Double(weightText), weightRange.contains(value) {
                                                        state.weightKg = value
                                                    }
                                                }
                                            }
                                    } else {
                                        Text(String(format: "%.1f", state.weightKg))
                                            .font(.system(size: isIPad ? 22 : 15, weight: .medium))
                                            .foregroundColor(Color(white: 0.3))
                                            .frame(width: isIPad ? 90 : 55)
                                            .padding(.vertical, isIPad ? 12 : 0)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.white.opacity(0.5))
                                            )
                                    }
                                }
                                .buttonStyle(.plain)

                                Text("kg")
                                    .font(.system(size: isIPad ? 18 : 14))
                                    .foregroundColor(Color(white: 0.5))
                            }

                            // Show stone/pounds conversion
                            let totalPounds = state.weightKg * 2.20462
                            let stone = Int(totalPounds / 14)
                            let pounds = Int(totalPounds.truncatingRemainder(dividingBy: 14))
                            Text("\(stone) st \(pounds) lb")
                                .font(.system(size: 13))
                                .foregroundColor(Color(white: 0.5))
                        } else {
                            // Stone & pounds input
                            HStack(spacing: 8) {
                                // Stone field
                                VStack(spacing: 4) {
                                    TextField("0", text: $weightStoneText)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.center)
                                        .font(.system(size: isIPad ? 24 : 18, weight: .medium))
                                        .foregroundColor(Color(white: 0.3))
                                        .frame(width: isIPad ? 70 : 50)
                                        .padding(.vertical, isIPad ? 12 : 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.white.opacity(0.7))
                                        )
                                        .focused($stoneFieldFocused)
                                        .onChange(of: weightStoneText) { _, _ in
                                            guard !isInitializingStoneFields else { return }
                                            updateWeightFromStone()
                                        }
                                    Text("stone")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(white: 0.5))
                                }

                                // Pounds field
                                VStack(spacing: 4) {
                                    TextField("0", text: $weightPoundsText)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.center)
                                        .font(.system(size: isIPad ? 24 : 18, weight: .medium))
                                        .foregroundColor(Color(white: 0.3))
                                        .frame(width: isIPad ? 70 : 50)
                                        .padding(.vertical, isIPad ? 12 : 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.white.opacity(0.7))
                                        )
                                        .focused($poundsFieldFocused)
                                        .onChange(of: weightPoundsText) { _, _ in
                                            guard !isInitializingStoneFields else { return }
                                            updateWeightFromStone()
                                        }
                                    Text("lbs")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(white: 0.5))
                                }

                                Spacer()
                            }

                            // Show kg conversion
                            Text(String(format: "%.1f kg", state.weightKg))
                                .font(.system(size: 13))
                                .foregroundColor(Color(white: 0.5))
                        }
                    }
                }

                // Gender
                PersonalDetailCard(
                    icon: "person",
                    title: "Biological sex",
                    subtitle: "For BMR calculation",
                    palette: state.palette
                ) {
                    HStack(spacing: 10) {
                        ForEach([UserGender.male, .female, .other], id: \.self) { gender in
                            GenderChip(
                                gender: gender,
                                isSelected: state.gender == gender,
                                palette: state.palette,
                                onSelect: { state.gender = gender }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, isIPad ? 32 : 24)

            // Note about changing later
            HStack(spacing: 6) {
                Image(systemName: "pencil.circle")
                    .font(.system(size: isIPad ? 16 : 14))
                    .foregroundColor(Color(white: 0.5))
                Text("You can adjust these anytime in Settings")
                    .font(.system(size: isIPad ? 15 : 13))
                    .foregroundColor(Color(white: 0.5))
            }
            .padding(.top, isIPad ? 24 : 16)

            Spacer()

            // Continue button
            PremiumButton(
                text: "Continue",
                palette: state.palette,
                action: {
                    savePersonalDetails()
                    onContinue()
                }
            )
            .padding(.horizontal, isIPad ? 48 : 32)
            .padding(.bottom, isIPad ? 70 : 50)
        }
        .onTapGesture {
            // Dismiss keyboard on tap outside
            heightFieldFocused = false
            weightFieldFocused = false
            stoneFieldFocused = false
            poundsFieldFocused = false
        }
        .keyboardDismissButton()
        .onAppear {
            // Initialize stone/pounds fields from current weight
            // Use flag to prevent onChange handlers from triggering during initialization
            isInitializingStoneFields = true
            let converted = WeightUnit.stones.fromKg(state.weightKg)
            weightStoneText = String(format: "%.0f", converted.primary)
            weightPoundsText = String(format: "%.0f", converted.secondary ?? 0)
            // Clear flag after a brief delay to ensure SwiftUI has processed the state changes
            DispatchQueue.main.async {
                isInitializingStoneFields = false
            }
        }
    }

    /// Updates state.weightKg from stone/pounds text fields
    private func updateWeightFromStone() {
        let stoneValue = Double(weightStoneText) ?? 0
        let poundsValue = Double(weightPoundsText) ?? 0

        // Validate pounds (0-13 in a stone)
        let validPounds = min(max(poundsValue, 0), 13.9)

        // Convert to kg: (stone * 14 + pounds) / 2.20462
        let totalPounds = (stoneValue * 14) + validPounds
        let kg = totalPounds / 2.20462

        // Only update if within valid range
        if weightRange.contains(kg) {
            state.weightKg = kg
        }
    }

    private func savePersonalDetails() {
        // Save to OnboardingManager for persistence
        let manager = OnboardingManager.shared
        manager.saveBirthday(state.birthDate)
        manager.saveHeight(state.heightCm)
        manager.saveWeight(state.weightKg)
        if state.gender != .notSet {
            manager.saveGender(state.gender)
        }

        // Save weight unit preference for use elsewhere in the app
        UserDefaults.standard.set(selectedWeightUnit.rawValue, forKey: "weightUnit")
    }
}

// MARK: - Personal Detail Card

struct PersonalDetailCard<Content: View>: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let palette: OnboardingPalette
    @ViewBuilder let content: () -> Content
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isIPad ? 16 : 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: isIPad ? 20 : 16, weight: .medium))
                    .foregroundColor(palette.primary)

                Text(title)
                    .font(.system(size: isIPad ? 18 : 16, weight: .semibold))
                    .foregroundColor(Color(white: 0.3))

                if let subtitle = subtitle {
                    Text("(\(subtitle))")
                        .font(.system(size: isIPad ? 15 : 13))
                        .foregroundColor(Color(white: 0.5))
                }

                Spacer()
            }

            content()
        }
        .padding(isIPad ? 20 : 16)
        .background(
            RoundedRectangle(cornerRadius: isIPad ? 20 : 16)
                .fill(Color.white.opacity(0.8))
                .shadow(color: Color.black.opacity(0.05), radius: isIPad ? 12 : 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: isIPad ? 20 : 16)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Gender Chip

struct GenderChip: View {
    let gender: UserGender
    let isSelected: Bool
    let palette: OnboardingPalette
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                Image(systemName: gender.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : Color(white: 0.4))

                Text(shortLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(white: 0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? palette.primary : Color.white.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color(white: 0.8), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var shortLabel: String {
        switch gender {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        case .notSet: return "Skip"
        }
    }
}

// MARK: - Sensitivities Screen

struct SensitivitiesScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    let onContinue: () -> Void

    @State private var selectedAllergens: Set<String> = []
    @State private var selectedOtherSensitivities: Set<String> = []

    // UK/EU Major Allergens (required by law)
    // IMPORTANT: IDs must match Allergen enum rawValues exactly for sync to work
    private let majorAllergens: [(id: String, name: String, icon: String)] = [
        ("celery", "Celery", "leaf"),
        ("gluten", "Gluten", "leaf.circle"),
        ("shellfish", "Crustaceans", "drop"),          // Allergen.shellfish
        ("eggs", "Eggs", "oval"),
        ("fish", "Fish", "fish"),
        ("lupin", "Lupin", "leaf.fill"),
        ("dairy", "Milk / Dairy", "cup.and.saucer"),
        ("molluscs", "Molluscs", "tortoise"),
        ("mustard", "Mustard", "leaf"),
        ("treeNuts", "Tree Nuts", "leaf.arrow.circlepath"),  // Allergen.treeNuts
        ("peanuts", "Peanuts", "p.circle"),
        ("sesame", "Sesame", "circle.grid.3x3"),
        ("soy", "Soya", "leaf"),
        ("sulfites", "Sulphites", "s.circle")          // Allergen.sulfites (US spelling)
    ]

    // Other sensitivities and preferences
    private let otherSensitivities: [(id: String, name: String, icon: String)] = [
        ("caffeine", "Caffeine", "cup.and.saucer.fill"),
        ("highSugar", "High sugar", "cube"),
        ("artificialSweeteners", "Artificial sweeteners", "drop.triangle"),
        ("ultraProcessed", "Ultra-processed foods", "exclamationmark.triangle"),
        ("additives", "Additives / E-numbers", "flask"),
        ("alcohol", "Alcohol", "wineglass"),
        ("histamines", "Histamines", "h.circle"),
        ("nightshades", "Nightshades", "moon")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 50)

            // Headline
            VStack(spacing: 8) {
                Text("Things you're sensitive to")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))

                Text("We'll flag these when you scan foods")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(white: 0.5))
            }
            .padding(.bottom, 24)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Allergens Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.shield")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(state.palette.primary)

                            Text("Allergens")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(white: 0.3))
                        }
                        .padding(.horizontal, 4)

                        OnboardingFlowLayout(spacing: 8) {
                            ForEach(majorAllergens, id: \.id) { allergen in
                                SensitivityChip(
                                    name: allergen.name,
                                    icon: allergen.icon,
                                    isSelected: selectedAllergens.contains(allergen.id),
                                    palette: state.palette,
                                    onToggle: {
                                        toggleAllergen(allergen.id)
                                    }
                                )
                            }
                        }
                    }

                    // Other Sensitivities Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.raised")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(state.palette.accent)

                            Text("Other sensitivities & preferences")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(white: 0.3))
                        }
                        .padding(.horizontal, 4)

                        Text("These are preferences, not medical diagnoses")
                            .font(.system(size: 13))
                            .foregroundColor(Color(white: 0.5))
                            .padding(.horizontal, 4)

                        OnboardingFlowLayout(spacing: 8) {
                            ForEach(otherSensitivities, id: \.id) { sensitivity in
                                SensitivityChip(
                                    name: sensitivity.name,
                                    icon: sensitivity.icon,
                                    isSelected: selectedOtherSensitivities.contains(sensitivity.id),
                                    palette: state.palette,
                                    isPreference: true,
                                    onToggle: {
                                        toggleOtherSensitivity(sensitivity.id)
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(maxHeight: 420)

            // Note
            HStack(spacing: 6) {
                Image(systemName: "pencil.circle")
                    .font(.system(size: 14))
                    .foregroundColor(Color(white: 0.5))
                Text("Adjust anytime in Settings")
                    .font(.system(size: 13))
                    .foregroundColor(Color(white: 0.5))
            }
            .padding(.top, 16)

            Spacer()

            // Continue button
            PremiumButton(
                text: selectedAllergens.isEmpty && selectedOtherSensitivities.isEmpty ? "Skip for now" : "Continue",
                palette: state.palette,
                action: {
                    saveSensitivities()
                    onContinue()
                }
            )
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }

    private func toggleAllergen(_ id: String) {
        withAnimation(.easeOut(duration: 0.2)) {
            if selectedAllergens.contains(id) {
                selectedAllergens.remove(id)
            } else {
                selectedAllergens.insert(id)
            }
        }

        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    private func toggleOtherSensitivity(_ id: String) {
        withAnimation(.easeOut(duration: 0.2)) {
            if selectedOtherSensitivities.contains(id) {
                selectedOtherSensitivities.remove(id)
            } else {
                selectedOtherSensitivities.insert(id)
            }
        }

        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    private func saveSensitivities() {
        let manager = OnboardingManager.shared
        manager.saveAllergens(Array(selectedAllergens))
        manager.saveOtherSensitivities(Array(selectedOtherSensitivities))

        // CRITICAL: Sync to state.selectedSensitivities so saveToManager() has correct data
        // This prevents saveToManager() from overwriting "userAllergens" with empty array
        syncToOnboardingState()
    }

    /// Maps string allergen IDs to FoodSensitivity enum values and syncs to state
    private func syncToOnboardingState() {
        var sensitivities = Set<FoodSensitivity>()

        // Map allergen string IDs to FoodSensitivity
        for allergenId in selectedAllergens {
            if let sensitivity = foodSensitivityFromAllergenId(allergenId) {
                sensitivities.insert(sensitivity)
            }
        }

        // Map other sensitivities
        for sensitivityId in selectedOtherSensitivities {
            if let sensitivity = foodSensitivityFromOtherId(sensitivityId) {
                sensitivities.insert(sensitivity)
            }
        }

        // Update the shared state
        state.selectedSensitivities = sensitivities
    }

    /// Maps allergen string ID to FoodSensitivity enum
    private func foodSensitivityFromAllergenId(_ id: String) -> FoodSensitivity? {
        switch id {
        case "celery": return .celery
        case "gluten": return .gluten
        case "shellfish": return .shellfish
        case "eggs": return .eggs
        case "fish": return .fish
        case "lupin": return .lupin
        case "dairy": return .dairy
        case "molluscs": return .molluscs
        case "mustard": return .mustard
        case "treeNuts": return .treeNuts
        case "peanuts": return .peanuts
        case "sesame": return .sesame
        case "soy": return .soy
        case "sulfites": return .sulphites  // Map US spelling to UK enum
        default: return nil
        }
    }

    /// Maps other sensitivity string ID to FoodSensitivity enum
    private func foodSensitivityFromOtherId(_ id: String) -> FoodSensitivity? {
        switch id {
        case "caffeine": return .caffeine
        case "alcohol": return .alcohol
        case "histamines": return .histamines
        case "nightshades": return .nightshades
        // Note: highSugar, artificialSweeteners, ultraProcessed, additives don't map to FoodSensitivity
        default: return nil
        }
    }
}

// MARK: - Sensitivity Chip

struct SensitivityChip: View {
    let name: String
    let icon: String
    let isSelected: Bool
    let palette: OnboardingPalette
    var isPreference: Bool = false
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : Color(white: 0.4))

                Text(name)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : Color(white: 0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? (isPreference ? palette.accent : palette.primary) : Color.white.opacity(0.7))
                    .shadow(color: isSelected ? (isPreference ? palette.accent : palette.primary).opacity(0.3) : Color.black.opacity(0.05), radius: isSelected ? 8 : 3, y: 2)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Camera Permission Screen (Updated Tone)

struct CameraPermissionScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    let onContinue: () -> Void

    @State private var permissionRequested = false
    @State private var permissionGranted = false
    @State private var hasAdvanced = false  // Prevents race condition on double-trigger

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // Headline - Updated tone (removed "protect you")
            VStack(spacing: 8) {
                Text("Scan labels instantly")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))

                Text("Quick access to nutrition info")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(white: 0.5))
            }

            // Subtext
            Text("Camera access lets you scan barcodes and capture nutrition labels for analysis.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(white: 0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 12)

            Spacer().frame(height: 50)

            // Camera icon animation
            ZStack {
                Circle()
                    .fill(state.palette.primary.opacity(0.1))
                    .frame(width: 160, height: 160)

                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(state.palette.primary)
            }

            // Privacy note
            HStack(spacing: 8) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 14))
                    .foregroundColor(Color(white: 0.5))

                Text("Images stay on your device unless you choose to share")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(white: 0.5))
            }
            .padding(.top, 30)
            .padding(.horizontal, 32)

            Spacer()

            // Permission buttons
            VStack(spacing: 12) {
                if !permissionRequested {
                    PremiumButton(
                        text: "Allow Camera Access",
                        palette: state.palette,
                        action: requestCameraPermission
                    )

                    Button(action: {
                        guard !hasAdvanced else { return }
                        hasAdvanced = true
                        permissionRequested = true
                        onContinue()
                    }) {
                        Text("Maybe later")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(white: 0.5))
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: permissionGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(permissionGranted ? .green : Color(white: 0.5))
                        Text(permissionGranted ? "Camera enabled" : "Skipped for now")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(permissionGranted ? .green : Color(white: 0.5))
                    }
                    .frame(height: 56)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }

    private func requestCameraPermission() {
        guard !hasAdvanced else { return }
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                permissionRequested = true
                permissionGranted = granted

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    guard !hasAdvanced else { return }
                    hasAdvanced = true
                    onContinue()
                }
            }
        }
    }
}

// MARK: - Apple Health Permission Screen (Updated Tone)

struct HealthPermissionScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    @EnvironmentObject var healthKitManager: HealthKitManager
    let onContinue: () -> Void

    @State private var permissionRequested = false
    @State private var permissionGranted = false
    @State private var hasAdvanced = false  // Prevents race condition on double-trigger

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // Headline
            VStack(spacing: 8) {
                Text("Connect Apple Health")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))

                Text("For a more complete picture")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(white: 0.5))
            }

            // Subtext
            Text("Sync steps, calories burned, and activity data to see how exercise fits with your nutrition.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(white: 0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 12)

            Spacer().frame(height: 40)

            // Health icon
            ZStack {
                Circle()
                    .fill(Color.pink.opacity(0.1))
                    .frame(width: 140, height: 140)

                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.pink)
            }

            // What we read
            VStack(alignment: .leading, spacing: 10) {
                OnboardingHealthDataRow(icon: "figure.walk", text: "Steps & distance", color: .green)
                OnboardingHealthDataRow(icon: "flame.fill", text: "Active calories", color: .orange)
                OnboardingHealthDataRow(icon: "scalemass.fill", text: "Weight (read & write)", color: .blue)
            }
            .padding(.top, 30)
            .padding(.horizontal, 40)

            // Note
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                    .foregroundColor(Color(white: 0.5))

                Text("This is optional and can be enabled later in Settings")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(white: 0.5))
            }
            .padding(.top, 20)
            .padding(.horizontal, 32)

            Spacer()

            // Permission buttons
            VStack(spacing: 12) {
                if !permissionRequested {
                    Button(action: requestHealthPermission) {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                            Text("Connect Apple Health")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(colors: [.pink, .red.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(16)
                    }

                    Button(action: {
                        guard !hasAdvanced else { return }
                        hasAdvanced = true
                        permissionRequested = true
                        onContinue()
                    }) {
                        Text("Maybe later")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(white: 0.5))
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: permissionGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(permissionGranted ? .green : Color(white: 0.5))
                        Text(permissionGranted ? "Apple Health connected" : "Skipped for now")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(permissionGranted ? .green : Color(white: 0.5))
                    }
                    .frame(height: 56)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }

    private func requestHealthPermission() {
        guard !hasAdvanced else { return }
        Task {
            await healthKitManager.requestAuthorization()
            await MainActor.run {
                permissionRequested = true
                permissionGranted = healthKitManager.isAuthorized

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    guard !hasAdvanced else { return }
                    hasAdvanced = true
                    onContinue()
                }
            }
        }
    }
}

struct OnboardingHealthDataRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(Color(white: 0.4))

            Spacer()
        }
    }
}

// MARK: - Notifications Permission Screen

struct NotificationsPermissionScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    let onContinue: () -> Void

    @State private var permissionRequested = false
    @State private var permissionGranted = false
    @State private var hasAdvanced = false  // Prevents race condition on double-trigger

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // Headline
            VStack(spacing: 8) {
                Text("Helpful reminders")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))

                Text("Stay on track, your way")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(white: 0.5))
            }

            // Subtext
            Text("Get reminders for things like expiry dates, fasting timers, and gentle nudges to log meals.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(white: 0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 12)

            Spacer().frame(height: 40)

            // Bell icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 140, height: 140)

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
            }

            // What notifications include
            VStack(alignment: .leading, spacing: 10) {
                OnboardingNotificationRow(icon: "calendar.badge.clock", text: "Food expiry reminders", color: .red)
                OnboardingNotificationRow(icon: "timer", text: "Fasting stage updates", color: .purple)
                OnboardingNotificationRow(icon: "chart.bar.fill", text: "Weekly nutrition summaries", color: .blue)
            }
            .padding(.top, 30)
            .padding(.horizontal, 40)

            // Note
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14))
                    .foregroundColor(Color(white: 0.5))

                Text("Customise which notifications you receive in Settings")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(white: 0.5))
            }
            .padding(.top, 20)
            .padding(.horizontal, 32)

            Spacer()

            // Permission buttons
            VStack(spacing: 12) {
                if !permissionRequested {
                    PremiumButton(
                        text: "Enable Notifications",
                        palette: state.palette,
                        action: requestNotificationPermission
                    )

                    Button(action: {
                        guard !hasAdvanced else { return }
                        hasAdvanced = true
                        permissionRequested = true
                        onContinue()
                    }) {
                        Text("Maybe later")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(white: 0.5))
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: permissionGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(permissionGranted ? .green : Color(white: 0.5))
                        Text(permissionGranted ? "Notifications enabled" : "Skipped for now")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(permissionGranted ? .green : Color(white: 0.5))
                    }
                    .frame(height: 56)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }

    private func requestNotificationPermission() {
        guard !hasAdvanced else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                permissionRequested = true
                permissionGranted = granted

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    guard !hasAdvanced else { return }
                    hasAdvanced = true
                    onContinue()
                }
            }
        }
    }
}

struct OnboardingNotificationRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(Color(white: 0.4))

            Spacer()
        }
    }
}

// MARK: - Completion Screen

struct OnboardingCompletionScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    let onComplete: () -> Void

    @State private var showCheckmark = false
    @State private var showText = false
    @State private var showButton = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated checkmark
            ZStack {
                Circle()
                    .fill(state.palette.primary.opacity(0.1))
                    .frame(width: 160, height: 160)
                    .scaleEffect(showCheckmark ? 1 : 0.5)
                    .opacity(showCheckmark ? 1 : 0)

                Image(systemName: "checkmark")
                    .font(.system(size: 70, weight: .light))
                    .foregroundColor(state.palette.primary)
                    .scaleEffect(showCheckmark ? 1 : 0)
                    .opacity(showCheckmark ? 1 : 0)
            }
            .padding(.bottom, 40)

            // Headline
            VStack(spacing: 12) {
                Text("You're all set")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))
                    .opacity(showText ? 1 : 0)

                Text("NutraSafe is ready to work for you")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(Color(white: 0.5))
                    .opacity(showText ? 1 : 0)
            }
            .padding(.bottom, 40)

            // Summary points
            VStack(alignment: .leading, spacing: 16) {
                CompletionPoint(
                    icon: "person.crop.circle",
                    text: "Personalised based on your details",
                    palette: state.palette,
                    show: showText
                )

                CompletionPoint(
                    icon: "exclamationmark.shield",
                    text: "Foods will be flagged based on your preferences",
                    palette: state.palette,
                    show: showText
                )

                CompletionPoint(
                    icon: "gearshape",
                    text: "Adjust anything in Settings whenever you like",
                    palette: state.palette,
                    show: showText
                )
            }
            .padding(.horizontal, 40)
            .opacity(showText ? 1 : 0)

            Spacer()

            // Enter button
            if showButton {
                PremiumButton(
                    text: "Start exploring",
                    palette: state.palette,
                    action: onComplete,
                    showShimmer: true
                )
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showCheckmark = true
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                showText = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showButton = true
                }
            }
        }
    }
}

struct CompletionPoint: View {
    let icon: String
    let text: String
    let palette: OnboardingPalette
    let show: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(palette.primary)
                .frame(width: 28)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(Color(white: 0.4))

            Spacer()
        }
        .opacity(show ? 1 : 0)
    }
}

// MARK: - Post-Auth Permissions View
// Shows permission screens AFTER user has signed up
// This completes the onboarding flow started before authentication

struct PostAuthPermissionsView: View {
    @StateObject private var state = PremiumOnboardingState()
    @State private var currentScreen = 0
    @State private var transitionOpacity: Double = 1
    @State private var showingPaywall = false
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    let onComplete: () -> Void

    // Permission screens + paywall: Camera(0) → Health(1) → Notifications(2) → ProUpgrade(3) → Done(4)
    // Note: ProUpgrade screen is skipped if user already has subscription access
    private let totalScreens = 5

    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground(palette: state.palette)

            // Screen content
            Group {
                switch currentScreen {
                case 0:
                    CameraPermissionScreen(state: state, onContinue: { advanceScreen() })
                case 1:
                    HealthPermissionScreen(state: state, onContinue: { advanceScreen() })
                        .environmentObject(healthKitManager)
                case 2:
                    NotificationsPermissionScreen(state: state, onContinue: { advanceScreen() })
                case 3:
                    // Paywall shown after permissions, before entering the app
                    // Skip if user already has subscription access (prevents showing upsell to subscribers)
                    if subscriptionManager.hasAccess {
                        Color.clear.onAppear { advanceScreen() }
                    } else {
                        ProUpgradeScreen(
                            state: state,
                            onUpgrade: { showingPaywall = true },
                            onContinueFree: { advanceScreen() }
                        )
                    }
                case 4:
                    PermissionsCompletionScreen(state: state, onComplete: {
                        OnboardingManager.shared.completePermissions()
                        OnboardingManager.shared.completeOnboarding()
                        onComplete()
                    })
                default:
                    CameraPermissionScreen(state: state, onContinue: { advanceScreen() })
                }
            }
            .opacity(transitionOpacity)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
                .onDisappear {
                    advanceScreen()
                }
        }
        .onAppear {
            // Load user intent from saved preferences to get correct palette
            state.loadFromDefaults()
            AnalyticsManager.shared.trackOnboardingStep(step: currentScreen, stepName: "PostAuth_" + postAuthScreenName(currentScreen))
        }
        .onChange(of: currentScreen) { _, newScreen in
            AnalyticsManager.shared.trackOnboardingStep(step: newScreen, stepName: "PostAuth_" + postAuthScreenName(newScreen))
        }
    }

    private func advanceScreen() {
        guard currentScreen < totalScreens - 1 else { return }

        withAnimation(.easeOut(duration: 0.3)) {
            transitionOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentScreen += 1
            withAnimation(.easeIn(duration: 0.4)) {
                transitionOpacity = 1
            }
        }
    }

    private func postAuthScreenName(_ screen: Int) -> String {
        switch screen {
        case 0: return "CameraPermission"
        case 1: return "HealthPermission"
        case 2: return "NotificationPermission"
        case 3: return "ProUpgrade"
        case 4: return "Completion"
        default: return "Unknown"
        }
    }
}

// MARK: - Permissions Completion Screen
// Final screen after all permissions are granted

struct PermissionsCompletionScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    let onComplete: () -> Void

    @State private var showCheckmark = false
    @State private var showText = false
    @State private var showButton = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated checkmark
            ZStack {
                Circle()
                    .fill(state.palette.primary.opacity(0.1))
                    .frame(width: 160, height: 160)
                    .scaleEffect(showCheckmark ? 1 : 0.5)
                    .opacity(showCheckmark ? 1 : 0)

                Image(systemName: "checkmark")
                    .font(.system(size: 70, weight: .light))
                    .foregroundColor(state.palette.primary)
                    .scaleEffect(showCheckmark ? 1 : 0)
                    .opacity(showCheckmark ? 1 : 0)
            }
            .padding(.bottom, 40)

            // Headline
            VStack(spacing: 12) {
                Text("You're all set")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))
                    .opacity(showText ? 1 : 0)

                Text("NutraSafe is ready to work for you")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(Color(white: 0.5))
                    .opacity(showText ? 1 : 0)
            }
            .padding(.bottom, 40)

            // Summary points
            VStack(alignment: .leading, spacing: 16) {
                CompletionPoint(
                    icon: "camera.viewfinder",
                    text: "Scan barcodes and labels instantly",
                    palette: state.palette,
                    show: showText
                )

                CompletionPoint(
                    icon: "heart.fill",
                    text: "Your health data is connected",
                    palette: state.palette,
                    show: showText
                )

                CompletionPoint(
                    icon: "bell.fill",
                    text: "Helpful reminders are enabled",
                    palette: state.palette,
                    show: showText
                )
            }
            .padding(.horizontal, 40)
            .opacity(showText ? 1 : 0)

            Spacer()

            // Start button
            if showButton {
                PremiumButton(
                    text: "Start exploring",
                    palette: state.palette,
                    action: onComplete,
                    showShimmer: true
                )
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showCheckmark = true
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                showText = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showButton = true
                }
            }
        }
    }
}
