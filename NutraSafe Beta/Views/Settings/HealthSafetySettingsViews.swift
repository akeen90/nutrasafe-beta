//
//  HealthSafetySettingsViews.swift
//  NutraSafe Beta
//
//  Health & Safety configuration views for Settings
//

import SwiftUI

// MARK: - Allergen Management View

struct AllergenManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseManager: FirebaseManager

    @State private var selectedAllergens: Set<Allergen> = []
    @State private var isLoading = true
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isSaving = false

    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView("Loading your allergens...")
                } else {
                    List {
                        Section {
                            Text("Select all allergens that you need to avoid. The app will warn you when foods contain these allergens.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }

                        Section(header: Text("Common Allergens")) {
                            ForEach(Allergen.allCases.filter { $0.severity == .high }, id: \.self) { allergen in
                                AllergenRow(
                                    allergen: allergen,
                                    isSelected: selectedAllergens.contains(allergen),
                                    onToggle: { toggleAllergen(allergen) }
                                )
                            }
                        }

                        Section(header: Text("Other Allergens & Sensitivities")) {
                            ForEach(Allergen.allCases.filter { $0.severity != .high }, id: \.self) { allergen in
                                AllergenRow(
                                    allergen: allergen,
                                    isSelected: selectedAllergens.contains(allergen),
                                    onToggle: { toggleAllergen(allergen) }
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Allergen Management")
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
                            saveAllergens()
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadAllergens()
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func toggleAllergen(_ allergen: Allergen) {
        if selectedAllergens.contains(allergen) {
            selectedAllergens.remove(allergen)
        } else {
            selectedAllergens.insert(allergen)
        }

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    private func loadAllergens() async {
        do {
            let settings = try await firebaseManager.getUserSettings()
            await MainActor.run {
                selectedAllergens = Set(settings.allergens ?? [])
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load allergens: \(error.localizedDescription)"
                showingError = true
                isLoading = false
            }
        }
    }

    private func saveAllergens() {
        isSaving = true
        Task {
            do {
                try await firebaseManager.saveUserAllergens(Array(selectedAllergens))
                await MainActor.run {
                    // Success haptic
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to save allergens: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}

struct AllergenRow: View {
    let allergen: Allergen
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Text(allergen.icon)
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: 2) {
                    Text(allergen.displayName)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)

                    Text(severityText)
                        .font(.system(size: 12))
                        .foregroundColor(severityColor)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .blue : .secondary.opacity(0.3))
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var severityText: String {
        switch allergen.severity {
        case .high: return "High Risk"
        case .medium: return "Medium Risk"
        case .low: return "Low Risk"
        }
    }

    private var severityColor: Color {
        switch allergen.severity {
        case .high: return .red
        case .medium: return .orange
        case .low: return .yellow
        }
    }
}

// MARK: - Food Reactions History View

struct FoodReactionsHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseManager: FirebaseManager

    @State private var reactions: [FoodReaction] = []
    @State private var isLoading = true
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var selectedReaction: FoodReaction?

    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView("Loading reactions...")
                } else if reactions.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("No Reactions Logged")
                            .font(.system(size: 22, weight: .semibold))

                        Text("Log food reactions in the Food tab to track patterns over time")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    List {
                        ForEach(reactions.sorted(by: { $0.timestamp > $1.timestamp })) { reaction in
                            ReactionRow(reaction: reaction)
                                .onTapGesture {
                                    selectedReaction = reaction
                                }
                        }
                    }
                }
            }
            .navigationTitle("Reaction History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadReactions()
            }
        }
        .sheet(item: $selectedReaction) { reaction in
            ReactionDetailView(reaction: reaction)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func loadReactions() async {
        do {
            let loadedReactions = try await firebaseManager.getReactions()
            await MainActor.run {
                reactions = loadedReactions
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load reactions: \(error.localizedDescription)"
                showingError = true
                isLoading = false
            }
        }
    }
}

struct ReactionRow: View {
    let reaction: FoodReaction

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(reaction.foodName)
                    .font(.system(size: 16, weight: .semibold))

                Spacer()

                severityBadge
            }

            Text(reaction.timestamp, style: .date)
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            if let symptoms = reaction.symptoms, !symptoms.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Text(symptoms.prefix(3).joined(separator: ", "))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var severityBadge: some View {
        Text(reaction.severity.rawValue.capitalized)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(severityColor)
            .cornerRadius(6)
    }

    private var severityColor: Color {
        switch reaction.severity {
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        }
    }
}

struct ReactionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let reaction: FoodReaction

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Food")) {
                    Text(reaction.foodName)
                        .font(.system(size: 18, weight: .semibold))
                }

                Section(header: Text("Severity")) {
                    HStack {
                        Text(reaction.severity.rawValue.capitalized)
                            .font(.system(size: 16))
                        Spacer()
                        Circle()
                            .fill(severityColor)
                            .frame(width: 12, height: 12)
                    }
                }

                if let symptoms = reaction.symptoms, !symptoms.isEmpty {
                    Section(header: Text("Symptoms")) {
                        ForEach(symptoms, id: \.self) { symptom in
                            Text(symptom)
                        }
                    }
                }

                if let notes = reaction.notes, !notes.isEmpty {
                    Section(header: Text("Notes")) {
                        Text(notes)
                            .font(.system(size: 15))
                    }
                }

                Section(header: Text("Date & Time")) {
                    Text(reaction.timestamp, style: .date)
                    Text(reaction.timestamp, style: .time)
                }
            }
            .navigationTitle("Reaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var severityColor: Color {
        switch reaction.severity {
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        }
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
            .navigationTitle("Micronutrient Display")
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
