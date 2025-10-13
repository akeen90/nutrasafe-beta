//
//  SettingsView.swift
//  NutraSafe Beta
//
//  Comprehensive settings interface with user account management,
//  nutrition goals, progress tracking, and app preferences
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseManager: FirebaseManager

    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingPasswordResetAlert = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var successMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {

                    // PHASE 1: Account Section
                    AccountSection(
                        userEmail: firebaseManager.currentUser?.email ?? "No email",
                        onChangePassword: handleChangePassword,
                        onSignOut: { showingSignOutAlert = true },
                        onDeleteAccount: { showingDeleteAccountAlert = true }
                    )

                    // PHASE 2: Nutrition Goals Section
                    NutritionGoalsSection()

                    // PHASE 3-5: Placeholder sections (will be implemented in later phases)
                    PlaceholderSection(title: "Progress Goals", icon: "chart.line.uptrend.xyaxis")
                    PlaceholderSection(title: "Health & Safety", icon: "heart.text.square")
                    PlaceholderSection(title: "App Preferences", icon: "gearshape")

                    // About Section
                    AboutSection()

                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        // Sign Out Confirmation
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                handleSignOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        // Delete Account Confirmation
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                handleDeleteAccount()
            }
        } message: {
            Text("This will permanently delete your account and all data. This action cannot be undone.")
        }
        // Password Reset Success
        .alert("Password Reset Email Sent", isPresented: $showingPasswordResetAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Check your email for instructions to reset your password.")
        }
        // Error Alert
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        // Success Alert
        .alert("Success", isPresented: $showingSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(successMessage)
        }
    }

    // MARK: - Actions

    private func handleChangePassword() {
        guard let email = firebaseManager.currentUser?.email else {
            errorMessage = "No email address found for your account."
            showingError = true
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                errorMessage = error.localizedDescription
                showingError = true
            } else {
                showingPasswordResetAlert = true
            }
        }
    }

    private func handleSignOut() {
        do {
            try firebaseManager.signOut()
            dismiss()
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
            showingError = true
        }
    }

    private func handleDeleteAccount() {
        // TODO: Implement account deletion
        // This requires re-authentication and should delete:
        // - All user data from Firestore
        // - Firebase Auth account
        errorMessage = "Account deletion is not yet implemented. Please contact support."
        showingError = true
    }
}

// MARK: - Account Section (PHASE 1)

struct AccountSection: View {
    let userEmail: String
    let onChangePassword: () -> Void
    let onSignOut: () -> Void
    let onDeleteAccount: () -> Void

    var body: some View {
        SettingsSection(title: "Account") {
            // User Email Display
            HStack {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Email")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text(userEmail)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .padding(.leading, 52)

            // Change Password
            SettingsRow(
                icon: "lock.rotation",
                title: "Change Password",
                iconColor: .orange,
                action: onChangePassword
            )

            Divider()
                .padding(.leading, 52)

            // Sign Out
            SettingsRow(
                icon: "rectangle.portrait.and.arrow.right",
                title: "Sign Out",
                iconColor: .red,
                action: onSignOut
            )

            Divider()
                .padding(.leading, 52)

            // Delete Account
            SettingsRow(
                icon: "trash",
                title: "Delete Account",
                iconColor: .red,
                action: onDeleteAccount
            )
        }
    }
}

// MARK: - About Section

struct AboutSection: View {
    var body: some View {
        SettingsSection(title: "About") {
            // App Version
            HStack {
                Image(systemName: "info.circle")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                    .frame(width: 24)

                Text("Version")
                    .font(.system(size: 16))
                    .foregroundColor(.primary)

                Spacer()

                Text(appVersion)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .padding(.leading, 52)

            SettingsRow(
                icon: "doc.text",
                title: "Terms & Conditions",
                iconColor: .blue,
                action: {
                    // TODO: Open terms URL
                }
            )

            Divider()
                .padding(.leading, 52)

            SettingsRow(
                icon: "hand.raised",
                title: "Privacy Policy",
                iconColor: .blue,
                action: {
                    // TODO: Open privacy policy URL
                }
            )

            Divider()
                .padding(.leading, 52)

            SettingsRow(
                icon: "heart.text.square",
                title: "Health Disclaimer",
                iconColor: .blue,
                action: {
                    // TODO: Show health disclaimer
                }
            )
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Placeholder Section (for future phases)

struct PlaceholderSection: View {
    let title: String
    let icon: String

    var body: some View {
        SettingsSection(title: title) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(width: 24)

                Text("Coming soon")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .italic()

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Reusable Components

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                content
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var iconColor: Color = .blue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Nutrition Goals Section (PHASE 2)

struct NutritionGoalsSection: View {
    @EnvironmentObject var firebaseManager: FirebaseManager

    @State private var caloricGoal: Int = 2000
    @State private var fastingGoalHours: Int = 16
    @State private var proteinPercent: Int = 30
    @State private var carbsPercent: Int = 40
    @State private var fatPercent: Int = 30

    @State private var isLoading = true
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingMacroEditor = false

    var body: some View {
        SettingsSection(title: "Nutrition Goals") {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                // Daily Caloric Goal
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                            .frame(width: 24)

                        Text("Daily Caloric Goal")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)

                        Spacer()

                        Stepper(value: $caloricGoal, in: 1000...5000, step: 50) {
                            Text("\(caloricGoal) cal")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.orange)
                        }
                        .onChange(of: caloricGoal) { newValue in
                            saveCaloricGoal(newValue)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    Divider()
                        .padding(.leading, 52)

                    // Macro Split
                    Button(action: { showingMacroEditor = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "chart.pie.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                                .frame(width: 24)

                            Text("Macro Split")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)

                            Spacer()

                            Text("\(proteinPercent)% • \(carbsPercent)% • \(fatPercent)%")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Divider()
                        .padding(.leading, 52)

                    // Fasting Goal
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.purple)
                            .frame(width: 24)

                        Text("Fasting Goal")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)

                        Spacer()

                        Stepper(value: $fastingGoalHours, in: 8...24, step: 1) {
                            Text("\(fastingGoalHours) hours")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.purple)
                        }
                        .onChange(of: fastingGoalHours) { newValue in
                            saveFastingGoal(newValue)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .onAppear {
            Task {
                await loadNutritionGoals()
            }
        }
        .sheet(isPresented: $showingMacroEditor) {
            MacroEditorView(
                proteinPercent: $proteinPercent,
                carbsPercent: $carbsPercent,
                fatPercent: $fatPercent,
                onSave: saveMacroPercentages
            )
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func loadNutritionGoals() async {
        do {
            // Load user settings
            let settings = try await firebaseManager.getUserSettings()
            let fastingState = try await firebaseManager.getFastingState()

            await MainActor.run {
                caloricGoal = settings.caloricGoal ?? 2000
                proteinPercent = settings.proteinPercent ?? 30
                carbsPercent = settings.carbsPercent ?? 40
                fatPercent = settings.fatPercent ?? 30
                fastingGoalHours = fastingState.goal
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load nutrition goals: \(error.localizedDescription)"
                showingError = true
                isLoading = false
            }
        }
    }

    private func saveCaloricGoal(_ goal: Int) {
        Task {
            do {
                try await firebaseManager.saveUserSettings(height: nil, goalWeight: nil, caloricGoal: goal)
                print("✅ Caloric goal updated to \(goal)")
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save caloric goal: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }

    private func saveFastingGoal(_ hours: Int) {
        Task {
            do {
                let currentState = try await firebaseManager.getFastingState()
                try await firebaseManager.saveFastingState(
                    isFasting: currentState.isFasting,
                    startTime: currentState.startTime,
                    goal: hours,
                    notificationsEnabled: currentState.notificationsEnabled,
                    reminderInterval: currentState.reminderInterval
                )
                print("✅ Fasting goal updated to \(hours) hours")
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save fasting goal: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }

    private func saveMacroPercentages() {
        Task {
            do {
                try await firebaseManager.saveMacroPercentages(
                    protein: proteinPercent,
                    carbs: carbsPercent,
                    fat: fatPercent
                )
                print("✅ Macro percentages updated: P\(proteinPercent)% C\(carbsPercent)% F\(fatPercent)%")
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save macro percentages: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Macro Editor View

struct MacroEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var proteinPercent: Int
    @Binding var carbsPercent: Int
    @Binding var fatPercent: Int

    @State private var tempProtein: Double
    @State private var tempCarbs: Double
    @State private var tempFat: Double

    let onSave: () -> Void

    init(proteinPercent: Binding<Int>, carbsPercent: Binding<Int>, fatPercent: Binding<Int>, onSave: @escaping () -> Void) {
        self._proteinPercent = proteinPercent
        self._carbsPercent = carbsPercent
        self._fatPercent = fatPercent
        self._tempProtein = State(initialValue: Double(proteinPercent.wrappedValue))
        self._tempCarbs = State(initialValue: Double(carbsPercent.wrappedValue))
        self._tempFat = State(initialValue: Double(fatPercent.wrappedValue))
        self.onSave = onSave
    }

    private var totalPercent: Int {
        Int(tempProtein + tempCarbs + tempFat)
    }

    private var isValid: Bool {
        totalPercent == 100
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Total:")
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                            Text("\(totalPercent)%")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(isValid ? .green : .red)
                        }

                        if !isValid {
                            Text("Percentages must total 100%")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section(header: Text("Protein")) {
                    HStack {
                        Text("\(Int(tempProtein))%")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.orange)
                            .frame(width: 60, alignment: .trailing)

                        Slider(value: $tempProtein, in: 10...50, step: 1)
                            .tint(.orange)
                    }
                }

                Section(header: Text("Carbohydrates")) {
                    HStack {
                        Text("\(Int(tempCarbs))%")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(width: 60, alignment: .trailing)

                        Slider(value: $tempCarbs, in: 20...60, step: 1)
                            .tint(.blue)
                    }
                }

                Section(header: Text("Fat")) {
                    HStack {
                        Text("\(Int(tempFat))%")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.purple)
                            .frame(width: 60, alignment: .trailing)

                        Slider(value: $tempFat, in: 15...45, step: 1)
                            .tint(.purple)
                    }
                }

                Section(header: Text("Common Presets")) {
                    Button(action: { applyPreset(protein: 30, carbs: 40, fat: 30) }) {
                        HStack {
                            Text("Balanced")
                            Spacer()
                            Text("30% • 40% • 30%")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: { applyPreset(protein: 40, carbs: 30, fat: 30) }) {
                        HStack {
                            Text("High Protein")
                            Spacer()
                            Text("40% • 30% • 30%")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: { applyPreset(protein: 20, carbs: 50, fat: 30) }) {
                        HStack {
                            Text("High Carb")
                            Spacer()
                            Text("20% • 50% • 30%")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: { applyPreset(protein: 25, carbs: 20, fat: 55) }) {
                        HStack {
                            Text("Keto")
                            Spacer()
                            Text("25% • 20% • 55%")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Macro Split")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private func applyPreset(protein: Int, carbs: Int, fat: Int) {
        tempProtein = Double(protein)
        tempCarbs = Double(carbs)
        tempFat = Double(fat)

        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    private func saveChanges() {
        proteinPercent = Int(tempProtein)
        carbsPercent = Int(tempCarbs)
        fatPercent = Int(tempFat)
        onSave()
        dismiss()

        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}
