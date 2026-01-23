//
//  HealthSafetySettingsViews.swift
//  NutraSafe Beta
//
//  Health & Safety configuration views for Settings
//

import SwiftUI

// MARK: - Sensitivities Management View (Redesigned)
// Premium design matching onboarding aesthetic

struct SensitivitiesManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var firebaseManager: FirebaseManager

    @State private var selectedAllergens: Set<String> = []
    @State private var selectedOtherSensitivities: Set<String> = []
    @State private var isLoading = true
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isSaving = false

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    // UK/EU Major Allergens (required by law) - IDs match Allergen enum rawValues
    private let majorAllergens: [(id: String, name: String, icon: String)] = [
        ("celery", "Celery", "leaf"),
        ("gluten", "Gluten", "leaf.circle"),
        ("shellfish", "Crustaceans", "drop"),
        ("eggs", "Eggs", "oval"),
        ("fish", "Fish", "fish"),
        ("lupin", "Lupin", "leaf.fill"),
        ("dairy", "Milk / Dairy", "cup.and.saucer"),
        ("molluscs", "Molluscs", "tortoise"),
        ("mustard", "Mustard", "leaf"),
        ("treeNuts", "Tree Nuts", "leaf.arrow.circlepath"),
        ("peanuts", "Peanuts", "p.circle"),
        ("sesame", "Sesame", "circle.grid.3x3"),
        ("soy", "Soya", "leaf"),
        ("sulfites", "Sulphites", "s.circle")
    ]

    // Other sensitivities and preferences
    private let otherSensitivities: [(id: String, name: String, icon: String)] = [
        ("caffeine", "Caffeine", "cup.and.saucer.fill"),
        ("lactose", "Lactose", "drop.triangle"),
        ("histamines", "Histamines", "h.circle"),
        ("nightshades", "Nightshades", "moon"),
        ("alcohol", "Alcohol", "wineglass"),
        ("msg", "MSG", "flask"),
        ("corn", "Corn", "leaf.arrow.circlepath")
    ]

    var body: some View {
        ZStack {
            // Premium animated background
            AppAnimatedBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom navigation bar
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(palette.accent)
                    }
                    .disabled(isSaving)

                    Spacer()

                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                if isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading your sensitivities...")
                            .font(.system(size: 15))
                            .foregroundColor(Color(white: 0.5))
                    }
                    Spacer()
                } else {
                    // Headline
                    VStack(spacing: 8) {
                        Text("Your sensitivities")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundColor(colorScheme == .dark ? .white : Color(white: 0.2))

                        Text("We'll flag these when you scan foods")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Color(white: 0.5))
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 24)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 28) {
                            // Allergens Section
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.shield")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(palette.accent)

                                    Text("Allergens")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(colorScheme == .dark ? .white : Color(white: 0.3))

                                    Spacer()

                                    // Count badge
                                    if !selectedAllergens.isEmpty {
                                        Text("\(selectedAllergens.count)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Capsule().fill(palette.accent))
                                    }
                                }
                                .padding(.horizontal, 4)

                                Text("UK/EU regulated allergens that must be declared")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(white: 0.5))
                                    .padding(.horizontal, 4)

                                SettingsFlowLayout(spacing: 10) {
                                    ForEach(majorAllergens, id: \.id) { allergen in
                                        SettingsSensitivityChip(
                                            name: allergen.name,
                                            icon: allergen.icon,
                                            isSelected: selectedAllergens.contains(allergen.id),
                                            accentColor: palette.accent,
                                            onToggle: { toggleAllergen(allergen.id) }
                                        )
                                    }
                                }
                            }

                            // Other Sensitivities Section
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(spacing: 8) {
                                    Image(systemName: "hand.raised")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(palette.primary)

                                    Text("Other sensitivities")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(colorScheme == .dark ? .white : Color(white: 0.3))

                                    Spacer()

                                    // Count badge
                                    if !selectedOtherSensitivities.isEmpty {
                                        Text("\(selectedOtherSensitivities.count)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Capsule().fill(palette.primary))
                                    }
                                }
                                .padding(.horizontal, 4)

                                Text("Additional ingredients you may want to avoid")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(white: 0.5))
                                    .padding(.horizontal, 4)

                                SettingsFlowLayout(spacing: 10) {
                                    ForEach(otherSensitivities, id: \.id) { sensitivity in
                                        SettingsSensitivityChip(
                                            name: sensitivity.name,
                                            icon: sensitivity.icon,
                                            isSelected: selectedOtherSensitivities.contains(sensitivity.id),
                                            accentColor: palette.primary,
                                            onToggle: { toggleOtherSensitivity(sensitivity.id) }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }

                    // Bottom section
                    VStack(spacing: 16) {
                        // Info note
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14))
                                .foregroundColor(Color(white: 0.5))

                            Text("Changes are saved to your account")
                                .font(.system(size: 13))
                                .foregroundColor(Color(white: 0.5))
                        }

                        // Save button
                        NutraSafePrimaryButton(
                            hasChanges ? "Save Changes" : "Done",
                            isEnabled: !isSaving
                        ) {
                            if hasChanges {
                                saveSensitivities()
                            } else {
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await loadSensitivities()
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    // Track if user has made changes
    @State private var initialAllergens: Set<String> = []
    @State private var initialOtherSensitivities: Set<String> = []

    private var hasChanges: Bool {
        selectedAllergens != initialAllergens || selectedOtherSensitivities != initialOtherSensitivities
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

    private func loadSensitivities() async {
        do {
            let settings = try await firebaseManager.getUserSettings()
            await MainActor.run {
                // Load from Firebase
                var loadedAllergenIds = Set<String>()
                if let allergens = settings.allergens {
                    for allergen in allergens {
                        loadedAllergenIds.insert(allergen.rawValue)
                    }
                }

                // Merge with UserDefaults (onboarding saves here)
                if let savedStrings = UserDefaults.standard.stringArray(forKey: "userAllergens") {
                    loadedAllergenIds.formUnion(savedStrings)
                }

                // Separate into major allergens and other sensitivities
                let majorAllergenIds = Set(majorAllergens.map { $0.id })
                let otherSensitivityIds = Set(otherSensitivities.map { $0.id })

                selectedAllergens = loadedAllergenIds.intersection(majorAllergenIds)
                selectedOtherSensitivities = loadedAllergenIds.intersection(otherSensitivityIds)

                // Store initial state for change tracking
                initialAllergens = selectedAllergens
                initialOtherSensitivities = selectedOtherSensitivities

                isLoading = false
            }
        } catch {
            await MainActor.run {
                // If Firebase fails, still try to load from UserDefaults
                if let savedStrings = UserDefaults.standard.stringArray(forKey: "userAllergens") {
                    let majorAllergenIds = Set(majorAllergens.map { $0.id })
                    let otherSensitivityIds = Set(otherSensitivities.map { $0.id })
                    let savedSet = Set(savedStrings)

                    selectedAllergens = savedSet.intersection(majorAllergenIds)
                    selectedOtherSensitivities = savedSet.intersection(otherSensitivityIds)

                    initialAllergens = selectedAllergens
                    initialOtherSensitivities = selectedOtherSensitivities
                }
                isLoading = false
            }
        }
    }

    private func saveSensitivities() {
        isSaving = true

        // Combine all selected sensitivities
        let allSelected = selectedAllergens.union(selectedOtherSensitivities)

        // Save to UserDefaults for consistency with onboarding
        UserDefaults.standard.set(Array(allSelected), forKey: "userAllergens")

        // Convert to Allergen enum for Firebase
        let allergens: [Allergen] = allSelected.compactMap { Allergen(rawValue: $0) }

        Task {
            do {
                try await firebaseManager.saveAllergens(allergens)
                await MainActor.run {
                    // Update initial state
                    initialAllergens = selectedAllergens
                    initialOtherSensitivities = selectedOtherSensitivities

                    // Success haptic
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)

                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to save sensitivities: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Settings Sensitivity Chip

struct SettingsSensitivityChip: View {
    let name: String
    let icon: String
    let isSelected: Bool
    let accentColor: Color
    let onToggle: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .white : (colorScheme == .dark ? Color(white: 0.7) : Color(white: 0.4)))

                Text(name)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : (colorScheme == .dark ? Color(white: 0.7) : Color(white: 0.4)))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isSelected ? accentColor : (colorScheme == .dark ? Color(white: 0.2) : Color.white.opacity(0.9)))
                    .shadow(
                        color: isSelected ? accentColor.opacity(0.35) : Color.black.opacity(0.06),
                        radius: isSelected ? 10 : 4,
                        y: isSelected ? 4 : 2
                    )
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? Color.clear : (colorScheme == .dark ? Color(white: 0.3) : Color(white: 0.85)),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Settings Flow Layout

struct SettingsFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = calculateLayout(in: proposal.width ?? 0, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = calculateLayout(in: bounds.width, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(
                    x: bounds.minX + result.positions[index].x,
                    y: bounds.minY + result.positions[index].y
                ),
                proposal: .unspecified
            )
        }
    }

    private func calculateLayout(in maxWidth: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                // Move to next line
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))

            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
        }

        let totalHeight = currentY + lineHeight
        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}

// MARK: - Legacy Allergen Management View (Deprecated - kept for backwards compatibility)

struct AllergenManagementView: View {
    var body: some View {
        SensitivitiesManagementView()
    }
}

// MARK: - Safety Alerts Configuration View

struct SafetyAlertsConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseManager: FirebaseManager

    @State private var showAllergenAlerts = true
    @State private var showAdditiveAlerts = true
    @State private var showProcessingAlerts = false
    @State private var showChildWarnings = true
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView("Loading preferences...")
                } else {
                    Form {
                        Section {
                            Text("Configure which safety alerts you want to see when browsing foods")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }

                        Section(header: Text("Alert Types")) {
                            Toggle(isOn: $showAllergenAlerts) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Allergen Alerts")
                                        .font(.system(size: 16))
                                    Text("Warn about your saved allergens")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Toggle(isOn: $showAdditiveAlerts) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Additive Warnings")
                                        .font(.system(size: 16))
                                    Text("Show warnings for concerning E-numbers")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Toggle(isOn: $showChildWarnings) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Child Activity Warnings")
                                        .font(.system(size: 16))
                                    Text("Highlight additives that may affect children")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Toggle(isOn: $showProcessingAlerts) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Ultra-Processed Alerts")
                                        .font(.system(size: 16))
                                    Text("Warn about highly processed foods")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppAnimatedBackground().ignoresSafeArea())
            .navigationTitle("Safety Alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            saveSettings()
                        }
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            Task {
                await loadSettings()
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func loadSettings() async {
        do {
            let settings = try await firebaseManager.getUserSettings()
            await MainActor.run {
                showAllergenAlerts = settings.showAllergenAlerts ?? true
                showAdditiveAlerts = settings.showAdditiveAlerts ?? true
                showProcessingAlerts = settings.showProcessingAlerts ?? false
                showChildWarnings = settings.showChildWarnings ?? true
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load settings: \(error.localizedDescription)"
                showingError = true
                isLoading = false
            }
        }
    }

    private func saveSettings() {
        isSaving = true
        Task {
            do {
                try await firebaseManager.saveSafetyAlertSettings(
                    showAllergenAlerts: showAllergenAlerts,
                    showAdditiveAlerts: showAdditiveAlerts,
                    showProcessingAlerts: showProcessingAlerts,
                    showChildWarnings: showChildWarnings
                )
                await MainActor.run {
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to save settings: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Micronutrient Display Preferences View

struct MicronutrientDisplayView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseManager: FirebaseManager

    @State private var showMicronutrients = true
    @State private var showDailyValues = true
    @State private var prioritizeDeficiencies = false
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView("Loading preferences...")
                } else {
                    Form {
                        Section {
                            Text("Configure how micronutrient information is displayed throughout the app")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }

                        Section(header: Text("Display Options")) {
                            Toggle(isOn: $showMicronutrients) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Show Micronutrients")
                                        .font(.system(size: 16))
                                    Text("Display vitamins and minerals in food details")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Toggle(isOn: $showDailyValues) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Show Daily Value %")
                                        .font(.system(size: 16))
                                    Text("Show percentage of recommended daily intake")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .disabled(!showMicronutrients)

                            Toggle(isOn: $prioritizeDeficiencies) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Highlight Low Nutrients")
                                        .font(.system(size: 16))
                                    Text("Emphasize nutrients you're not getting enough of")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .disabled(!showMicronutrients)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppAnimatedBackground().ignoresSafeArea())
            .navigationTitle("Vitamins & Minerals Display")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            saveSettings()
                        }
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            Task {
                await loadSettings()
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func loadSettings() async {
        do {
            let settings = try await firebaseManager.getUserSettings()
            await MainActor.run {
                showMicronutrients = settings.showMicronutrients ?? true
                showDailyValues = settings.showDailyValues ?? true
                prioritizeDeficiencies = settings.prioritizeDeficiencies ?? false
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load settings: \(error.localizedDescription)"
                showingError = true
                isLoading = false
            }
        }
    }

    private func saveSettings() {
        isSaving = true
        Task {
            do {
                try await firebaseManager.saveMicronutrientDisplaySettings(
                    showMicronutrients: showMicronutrients,
                    showDailyValues: showDailyValues,
                    prioritizeDeficiencies: prioritizeDeficiencies
                )
                await MainActor.run {
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to save settings: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}
