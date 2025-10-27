//
//  SettingsView.swift
//  NutraSafe Beta
//
//  Comprehensive settings interface with user account management,
//  nutrition goals, progress tracking, and app preferences
//

import SwiftUI
import FirebaseAuth
import FirebaseStorage
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseManager: FirebaseManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

    @State private var showingSignOutAlert = false
    @State private var showingPasswordResetAlert = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var successMessage = ""
    @State private var showingPaywall = false

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {

                    // PHASE 1: Account Section
                    AccountSection(
                        userEmail: firebaseManager.currentUser?.email ?? "No email",
                        onChangePassword: handleChangePassword,
                        onSignOut: { showingSignOutAlert = true }
                    )

                    // PHASE 2: Nutrition Goals Section
                    NutritionGoalsSection()

                    // PHASE 3: Progress Goals Section
                    ProgressGoalsSection()

                    // PHASE 4: Health & Safety Section
                    HealthSafetySection()

                    // PHASE 5: App Preferences Section
                    AppPreferencesSection()

                    // Premium Subscription Section
                    SettingsSection(title: "Premium Subscription") {
                        SettingsRow(
                            icon: "star.circle",
                            title: "Unlock NutraSafe Pro",
                            iconColor: .purple,
                            action: { showingPaywall = true }
                        )

                        Divider()
                            .padding(.leading, 52)

                        SettingsRow(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Restore Purchases",
                            iconColor: .blue,
                            action: {
                                Task { try? await subscriptionManager.restore() }
                            }
                        )

                        Divider()
                            .padding(.leading, 52)

                        SettingsRow(
                            icon: "creditcard",
                            title: "Manage Subscription",
                            iconColor: .blue,
                            action: {
                                Task { await subscriptionManager.manageSubscriptions() }
                            }
                        )
                    }

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
        .preferredColorScheme(appearanceMode.colorScheme)
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView()
                .environmentObject(subscriptionManager)
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


}

// MARK: - Account Section (PHASE 1)

struct AccountSection: View {
    let userEmail: String
    let onChangePassword: () -> Void
    let onSignOut: () -> Void

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


        }
    }
}

// MARK: - About Section

struct AboutSection: View {
    @State private var showingHealthDisclaimer = false
    @Environment(\.dismiss) private var dismiss

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
                    if let url = URL(string: "https://nutrasafe-705c7.web.app/terms") {
                        UIApplication.shared.open(url)
                    }
                }
            )

            Divider()
                .padding(.leading, 52)

            SettingsRow(
                icon: "hand.raised",
                title: "Privacy Policy",
                iconColor: .blue,
                action: {
                    if let url = URL(string: "https://nutrasafe-705c7.web.app/privacy") {
                        UIApplication.shared.open(url)
                    }
                }
            )

            Divider()
                .padding(.leading, 52)

            SettingsRow(
                icon: "heart.text.square",
                title: "Health Disclaimer",
                iconColor: .blue,
                action: {
                    showingHealthDisclaimer = true
                }
            )

            Divider()
                .padding(.leading, 52)

            SettingsRow(
                icon: "arrow.clockwise.circle",
                title: "Restart Onboarding",
                iconColor: .green,
                action: {
                    OnboardingManager.shared.resetOnboarding()
                    // Dismiss Settings first so root can present onboarding immediately
                    dismiss()
                    // Trigger onboarding after sheet dismiss animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        NotificationCenter.default.post(name: .restartOnboarding, object: nil)
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                }
            )
        }
        .sheet(isPresented: $showingHealthDisclaimer) {
            HealthDisclaimerView()
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
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)
                                .frame(width: 24)

                            Text("Daily Caloric Goal")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)

                            Spacer()
                        }

                        HStack {
                            Spacer()

                            Stepper(value: $caloricGoal, in: 1000...5000, step: 50) {
                                Text("\(formatNumber(caloricGoal)) cal")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.orange)
                            }
                            .onChange(of: caloricGoal) { newValue in
                                saveCaloricGoal(newValue)
                            }

                            Spacer()
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

            await MainActor.run {
                caloricGoal = settings.caloricGoal ?? 2000
                proteinPercent = settings.proteinPercent ?? 30
                carbsPercent = settings.carbsPercent ?? 40
                fatPercent = settings.fatPercent ?? 30
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

                // Notify diary view to update immediately
                await MainActor.run {
                    NotificationCenter.default.post(name: .nutritionGoalsUpdated, object: nil)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save caloric goal: \(error.localizedDescription)"
                    showingError = true
                }
                // Reload on error to revert to saved value
                await loadNutritionGoals()
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

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Progress Goals Section (PHASE 3)

struct ProgressGoalsSection: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric

    @State private var currentWeight: Double?
    @State private var goalWeight: Double?
    @State private var height: Double?
    @State private var heightUnit: String = "cm"
    @State private var weightEntries: [WeightEntry] = []

    @State private var isLoading = true
    @State private var showingWeightHistory = false
    @State private var showingHeightEditor = false
    @State private var showingGoalEditor = false
    @State private var showingWeightEditor = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        SettingsSection(title: "Progress Goals") {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                // Current Weight
                VStack(spacing: 0) {
                    Button(action: { showingWeightEditor = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "scalemass.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                                .frame(width: 24)

                            Text("Current Weight")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)

                            Spacer()

                            if let weight = currentWeight {
                                Text(formatWeight(weight))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blue)
                                    .fixedSize()
                            } else {
                                Text("Not set")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            }

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

                    // Goal Weight
                    Button(action: { showingGoalEditor = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "flag.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                                .frame(width: 24)

                            Text("Goal Weight")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)

                            Spacer()

                            if let goal = goalWeight {
                                Text(formatWeight(goal))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.green)
                                    .fixedSize()
                            } else {
                                Text("Not set")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            }

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

                    // Height
                    Button(action: { showingHeightEditor = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "ruler.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.purple)
                                .frame(width: 24)

                            Text("Height")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)

                            Spacer()

                            if let h = height {
                                Text(formatHeight(h))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.purple)
                                    .fixedSize()
                            } else {
                                Text("Not set")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            }

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // BMI Display (if height and weight are set)
                    if let h = height, let w = currentWeight, h > 0 {
                        Divider()
                            .padding(.leading, 52)

                        Button(action: { }) {
                            HStack(spacing: 12) {
                                Image(systemName: "heart.text.square.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.pink)
                                    .frame(width: 24)

                                Text("BMI")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)

                                Spacer()

                                let bmi = calculateBMI(weight: w, heightCm: h)
                                HStack(spacing: 8) {
                                    Text(bmiCategory(bmi))
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)

                                    Text(String(format: "%.1f", bmi))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(bmiColor(bmi))
                                }
                                .fixedSize()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    Divider()
                        .padding(.leading, 52)

                    // Weight History
                    Button(action: { showingWeightHistory = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)
                                .frame(width: 24)

                            Text("Weight History")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)

                            Spacer()

                            Text("\(weightEntries.count) entries")
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
                }
            }
        }
        .onAppear {
            Task { await loadProgressData() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .weightHistoryUpdated)) { _ in
            Task { await loadProgressData() }
        }
        .sheet(isPresented: $showingWeightHistory) {
            WeightTrackingView(showingSettings: $showingWeightHistory)
                .environmentObject(firebaseManager)
        }
        .onChange(of: showingWeightHistory) { isShowing in
            if !isShowing {
                // Reload data when returning from Weight History
                Task {
                    await loadProgressData()
                }
            }
        }
        .sheet(isPresented: $showingWeightEditor) {
            CurrentWeightEditorView(
                currentWeight: $currentWeight,
                onSave: saveCurrentWeight
            )
            .environmentObject(firebaseManager)
        }
        .sheet(isPresented: $showingHeightEditor) {
            HeightEditorView(height: $height, onSave: saveHeight)
        }
        .sheet(isPresented: $showingGoalEditor) {
            GoalWeightEditorView(
                currentWeight: currentWeight,
                goalWeight: $goalWeight,
                onSave: saveGoalWeight
            )
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func loadProgressData() async {
        let manager = firebaseManager
        do {
            let settings = try await manager.getUserSettings()
            let entries = try await manager.getWeightHistory()

            await MainActor.run {
                height = settings.height
                goalWeight = settings.goalWeight
                weightEntries = entries
                currentWeight = entries.first?.weight
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load progress data: \(error.localizedDescription)"
                showingError = true
                isLoading = false
            }
        }
    }

    private func saveHeight() {
        let manager = firebaseManager
        Task {
            do {
                try await manager.saveUserSettings(height: height, goalWeight: nil, caloricGoal: nil)
                print("✅ Height saved: \(height ?? 0) cm")

                // Reload data to update the UI immediately
                await loadProgressData()
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save height: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }

    private func saveGoalWeight() {
        let manager = firebaseManager
        Task {
            do {
                try await manager.saveUserSettings(height: nil, goalWeight: goalWeight, caloricGoal: nil)
                print("✅ Goal weight saved: \(goalWeight ?? 0) kg")

                // Reload data to update the UI immediately
                await loadProgressData()
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save goal weight: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }

    private func saveCurrentWeight() {
        guard let weight = currentWeight else { return }
        // Optimistic UI update: insert new entry locally for instant feedback
        let newEntry = WeightEntry(weight: weight, date: Date())
        // Immediate UI update on main thread
        weightEntries.insert(newEntry, at: 0)
        currentWeight = weight

        let manager = firebaseManager
        Task {
            do {
                // Save to Firebase
                try await manager.saveWeightEntry(newEntry)
                print("✅ Current weight saved to Firebase: \(weight) kg")

                // Write to Apple Health
                try? await HealthKitManager.shared.writeBodyWeight(weightKg: weight, date: newEntry.date)

                // Refresh from server to reconcile
                await loadProgressData()
            } catch {
                // Roll back optimistic insert on error
                await MainActor.run {
                    weightEntries.removeAll { $0.id == newEntry.id }
                    errorMessage = "Failed to save current weight: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }

    private func calculateBMI(weight: Double, heightCm: Double) -> Double {
        let heightM = heightCm / 100.0
        return weight / (heightM * heightM)
    }

    private func bmiCategory(_ bmi: Double) -> String {
        switch bmi {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Overweight"
        default: return "Obese"
        }
    }

    private func bmiColor(_ bmi: Double) -> Color {
        switch bmi {
        case ..<18.5: return .blue
        case 18.5..<25: return .green
        case 25..<30: return .orange
        default: return .red
        }
    }

    private func formatWeight(_ kg: Double) -> String {
        switch unitSystem {
        case .metric:
            return String(format: "%.1f kg", kg)
        case .imperial:
            let lbs = kg * 2.20462
            return String(format: "%.1f lbs", lbs)
        }
    }

    private func formatHeight(_ cm: Double) -> String {
        switch unitSystem {
        case .metric:
            return String(format: "%.0f cm", cm)
        case .imperial:
            let totalInches = cm / 2.54
            let feet = Int(totalInches / 12)
            let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
            return "\(feet)' \(inches)\""
        }
    }
}

// MARK: - Height Editor

struct HeightEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var height: Double?
    let onSave: () -> Void

    @State private var tempHeight: String

    init(height: Binding<Double?>, onSave: @escaping () -> Void) {
        self._height = height
        self.onSave = onSave
        self._tempHeight = State(initialValue: height.wrappedValue.map { String(format: "%.0f", $0) } ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Height (cm)")) {
                    TextField("Enter height", text: $tempHeight)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 18))
                }

                Section(header: Text("Common Heights")) {
                    Button("150 cm") { tempHeight = "150" }
                    Button("160 cm") { tempHeight = "160" }
                    Button("170 cm") { tempHeight = "170" }
                    Button("180 cm") { tempHeight = "180" }
                    Button("190 cm") { tempHeight = "190" }
                }
            }
            .navigationTitle("Height")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveHeight()
                    }
                }
            }
        }
    }

    private func saveHeight() {
        if let value = Double(tempHeight), value > 0, value < 300 {
            height = value
            onSave()
            dismiss()
        }
    }
}

// MARK: - Current Weight Editor

struct CurrentWeightEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseManager: FirebaseManager
    @Binding var currentWeight: Double?
    let onSave: () -> Void

    @State private var tempWeight: String
    @State private var isSaving = false

    init(currentWeight: Binding<Double?>, onSave: @escaping () -> Void) {
        self._currentWeight = currentWeight
        self.onSave = onSave
        self._tempWeight = State(initialValue: currentWeight.wrappedValue.map { String(format: "%.1f", $0) } ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Current Weight (kg)")) {
                    TextField("Enter weight", text: $tempWeight)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 18))
                }

                Section(header: Text("Quick Entry")) {
                    if let current = currentWeight {
                        Button("Keep Current: \(String(format: "%.1f kg", current))") {
                            tempWeight = String(format: "%.1f", current)
                        }
                    }
                }

                Section {
                    Text("This will create a new entry in your weight history for today.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Current Weight")
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
                            saveWeight()
                        }
                    }
                }
            }
        }
    }

    private func saveWeight() {
        let sanitized = tempWeight.replacingOccurrences(of: ",", with: ".")
        if let value = Double(sanitized), value > 0, value < 500 {
            isSaving = true
            currentWeight = value
            onSave()
            // Dismiss immediately; parent will refresh and reconcile asynchronously
            dismiss()
        }
    }
}

// MARK: - Goal Weight Editor

struct GoalWeightEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let currentWeight: Double?
    @Binding var goalWeight: Double?
    let onSave: () -> Void

    @State private var tempWeight: String
    @State private var isSaving = false

    init(currentWeight: Double?, goalWeight: Binding<Double?>, onSave: @escaping () -> Void) {
        self.currentWeight = currentWeight
        self._goalWeight = goalWeight
        self.onSave = onSave

        // Initialize with goal weight if set, otherwise use current weight
        if let goal = goalWeight.wrappedValue {
            self._tempWeight = State(initialValue: String(format: "%.1f", goal))
        } else if let current = currentWeight {
            self._tempWeight = State(initialValue: String(format: "%.1f", current))
        } else {
            self._tempWeight = State(initialValue: "")
        }
    }

    var body: some View {
        NavigationView {
            Form {
                // Current Weight Info (if available)
                if let current = currentWeight {
                    Section {
                        HStack {
                            Text("Current Weight")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f kg", current))
                                .fontWeight(.semibold)
                        }
                    }
                }

                Section(header: Text("Goal Weight (kg)")) {
                    TextField(currentWeight != nil ? String(format: "%.1f", currentWeight!) : "Enter goal weight", text: $tempWeight)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 18))
                }

                // Smart Quick Adjustments based on current weight
                if let current = currentWeight {
                    Section(header: Text("From Current Weight")) {
                        Button {
                            tempWeight = String(format: "%.1f", current - 5)
                        } label: {
                            HStack {
                                Text("Lose 5 kg")
                                Spacer()
                                Text(String(format: "%.1f kg", current - 5))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Button {
                            tempWeight = String(format: "%.1f", current - 10)
                        } label: {
                            HStack {
                                Text("Lose 10 kg")
                                Spacer()
                                Text(String(format: "%.1f kg", current - 10))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Button {
                            tempWeight = String(format: "%.1f", current + 5)
                        } label: {
                            HStack {
                                Text("Gain 5 kg")
                                Spacer()
                                Text(String(format: "%.1f kg", current + 5))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Goal Weight")
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
                            saveWeight()
                        }
                    }
                }
            }
        }
    }

    private func saveWeight() {
        let sanitized = tempWeight.replacingOccurrences(of: ",", with: ".")
        if let value = Double(sanitized), value > 0, value < 500 {
            isSaving = true
            goalWeight = value
            onSave()
            // Dismiss immediately; parent will refresh and reconcile asynchronously
            dismiss()
        }
    }
}

// MARK: - Health & Safety Section (PHASE 4)

struct HealthSafetySection: View {
    @EnvironmentObject var firebaseManager: FirebaseManager

    @State private var reactionCount: Int = 0
    @State private var isLoading = true
    @State private var showingError = false
    @State private var errorMessage = ""

    // Sheet presentation states
    @State private var showingAllergenManagement = false
    @State private var showingReactionsHistory = false

    var body: some View {
        SettingsSection(title: "Health & Safety") {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                VStack(spacing: 0) {
                    // Allergen Management
                    SettingsRow(
                        icon: "exclamationmark.triangle.fill",
                        title: "Allergen Management",
                        iconColor: .red,
                        action: {
                            showingAllergenManagement = true
                        }
                    )

                    Divider()
                        .padding(.leading, 52)

                    // Food Reactions History
                    Button(action: {
                        showingReactionsHistory = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)
                                .frame(width: 24)

                            Text("Food Reactions History")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)

                            Spacer()

                            Text("\(reactionCount) logged")
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

                    // Removed non-functional Safety Alerts and Micronutrient Display rows
                }
            }
        }
        .onAppear {
            Task {
                await loadHealthSafetyData()
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingAllergenManagement) {
            AllergenManagementView()
                .environmentObject(firebaseManager)
        }
        .sheet(isPresented: $showingReactionsHistory) {
            FoodReactionsHistoryView()
                .environmentObject(firebaseManager)
        }
        // Removed sheets for Safety Alerts and Micronutrient Display
    }

    private func loadHealthSafetyData() async {
        let manager = firebaseManager
        do {
            let reactions = try await manager.getReactions()

            await MainActor.run {
                reactionCount = reactions.count
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load health & safety data: \(error.localizedDescription)"
                showingError = true
                isLoading = false
            }
        }
    }
}

// MARK: - App Preferences Section (PHASE 5)

struct AppPreferencesSection: View {
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("useByNotificationsEnabled") private var useByNotificationsEnabled = true
    @AppStorage("fastingNotificationsEnabled") private var fastingNotificationsEnabled = true
    @AppStorage("healthKitRingsEnabled") private var healthKitRingsEnabled = false

    @EnvironmentObject var healthKitManager: HealthKitManager

    @State private var showingThemeSelector = false
    @State private var showingUnitsSelector = false
    @State private var showingDataPrivacy = false
    @State private var showingNotificationSettings = false

    var body: some View {
        SettingsSection(title: "App Preferences") {
            VStack(spacing: 0) {
                // Theme
                Button(action: { showingThemeSelector = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "paintbrush.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.purple)
                            .frame(width: 24)

                        Text("Theme")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)

                        Spacer()

                        Text(appearanceMode.displayName)
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

                // Apple Health Menu
                NavigationLink(destination: AppleHealthSettingsView()) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white)
                                .frame(width: 28, height: 28)
                                .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 0.5)

                            Image(systemName: "heart.fill")
                                .font(.system(size: 15))
                                .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19))
                        }
                        .frame(width: 28)

                        Text("Apple Health")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                Divider()
                    .padding(.leading, 52)

                // Units
                Button(action: { showingUnitsSelector = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "ruler.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                            .frame(width: 24)

                        Text("Units")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)

                        Spacer()

                        Text(unitSystem.displayName)
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

                // Notifications
                Button(action: { showingNotificationSettings = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                            .frame(width: 24)

                        Text("Notifications")
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

                Divider()
                    .padding(.leading, 52)

                // Data & Privacy
                SettingsRow(
                    icon: "lock.shield.fill",
                    title: "Data & Privacy",
                    iconColor: .orange,
                    action: {
                        showingDataPrivacy = true
                    }
                )
            }
        }
        .sheet(isPresented: $showingThemeSelector) {
            ThemeSelectorView(selectedTheme: $appearanceMode)
        }
        .sheet(isPresented: $showingUnitsSelector) {
            UnitsSelectorView(selectedUnit: $unitSystem)
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView(
                notificationsEnabled: $notificationsEnabled,
                useByNotificationsEnabled: $useByNotificationsEnabled,
                fastingNotificationsEnabled: $fastingNotificationsEnabled
            )
        }
        .sheet(isPresented: $showingDataPrivacy) {
            DataPrivacyView()
        }
    }
}

// MARK: - Supporting Enums for App Preferences

enum UnitSystem: String, CaseIterable {
    case metric = "metric"
    case imperial = "imperial"

    var displayName: String {
        switch self {
        case .metric: return "Metric"
        case .imperial: return "Imperial"
        }
    }

    var icon: String {
        switch self {
        case .metric: return "chart.bar.fill"
        case .imperial: return "scalemass.fill"
        }
    }

    var description: String {
        switch self {
        case .metric: return "Kilograms, centimetres, litres"
        case .imperial: return "Pounds, inches, fluid ounces"
        }
    }
}

// MARK: - Theme Selector View

struct ThemeSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTheme: AppearanceMode

    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Choose how NutraSafe appears on your device")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Section {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Button(action: {
                            selectedTheme = mode
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: mode.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(.purple)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mode.displayName)
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary)

                                    if mode == .system {
                                        Text("Matches system settings")
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                if selectedTheme == mode {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        let notificationFeedback = UINotificationFeedbackGenerator()
                        notificationFeedback.notificationOccurred(.success)
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(selectedTheme.colorScheme)
    }
}

// MARK: - Units Selector View

struct UnitsSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedUnit: UnitSystem

    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Choose your preferred measurement system")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Section {
                    ForEach(UnitSystem.allCases, id: \.self) { system in
                        Button(action: {
                            selectedUnit = system
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: system.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(system.displayName)
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary)

                                    Text(system.description)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if selectedUnit == system {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                Section {
                    Text("Weight and height values will be converted automatically when you switch between metric and imperial units.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Units")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        let notificationFeedback = UINotificationFeedbackGenerator()
                        notificationFeedback.notificationOccurred(.success)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Data & Privacy View

struct DataPrivacyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseManager: FirebaseManager

    @State private var showingExportData = false
    @State private var showingDeleteDataConfirmation = false
    @State private var isExporting = false
    @State private var isDeleting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var successMessage = ""
    @State private var showingDeleteAccountConfirmation = false
    @State private var showingReauthPrompt = false
    @State private var reauthPassword = ""

    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Manage your personal data and privacy settings")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Your Data")) {
                    Button(action: { showingExportData = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Export Data")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)

                                Text("Download all your app data")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { showingDeleteDataConfirmation = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Delete All Data")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red)

                                Text("Permanently remove all your data")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Section(header: Text("Account")) {
                    Button(action: { showingDeleteAccountConfirmation = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.xmark")
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Delete Account")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red)

                                Text("Permanently delete your account and all data")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Section(header: Text("Storage")) {
                    HStack {
                        Image(systemName: "internaldrive")
                            .font(.system(size: 16))
                            .foregroundColor(.purple)
                            .frame(width: 24)

                        Text("Data Storage")
                            .font(.system(size: 16))

                        Spacer()

                        Text("Firebase Cloud")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("Privacy")) {
                    Button(action: {
                        if let url = URL(string: "https://nutrasafe-705c7.web.app/privacy") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)
                                .frame(width: 24)

                            Text("Privacy Policy")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Data & Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Export Data", isPresented: $showingExportData) {
            Button("Cancel", role: .cancel) { }
            Button("Export") {
                exportUserData()
            }
        } message: {
            Text("Data export feature coming soon. You'll be able to download all your data in JSON format.")
        }
        .alert("Delete All Data", isPresented: $showingDeleteDataConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAllUserData()
            }
        } message: {
            Text("This will permanently delete all your diary entries, weight history, settings, and allergen data. This action cannot be undone.")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                showingReauthPrompt = true
            }
        } message: {
            Text("This will permanently delete your account and all associated data. This action cannot be undone.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showingSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(successMessage)
        }
        .sheet(isPresented: $showingReauthPrompt) {
            NavigationView {
                VStack(spacing: 16) {
                    Text("Re-authenticate to Delete Account")
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.top, 12)

                    Text("For security, please enter your current password.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    SecureField("Current Password", text: $reauthPassword)
                        .textContentType(.password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                        .padding(.horizontal)

                    HStack {
                        Button("Cancel") {
                            reauthPassword = ""
                            showingReauthPrompt = false
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .cornerRadius(8)

                        Button("Confirm") {
                            let pwd = reauthPassword
                            reauthPassword = ""
                            showingReauthPrompt = false
                            reauthenticateAndDelete(with: pwd)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding()
                .navigationTitle("Confirm Deletion")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private func exportUserData() {
        // TODO: Implement data export
        errorMessage = "Data export feature is coming soon!"
        showingError = true
    }

    private func deleteAllUserData() {
        isDeleting = true
        Task {
            do {
                // Delete all user data from Firestore
                try await firebaseManager.deleteAllUserData()
                await MainActor.run {
                    successMessage = "All your data has been permanently deleted."
                    showingSuccess = true
                    isDeleting = false

                    // Dismiss after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete data: \(error.localizedDescription)"
                    showingError = true
                    isDeleting = false
                }
            }
        }
    }

    private func reauthenticateAndDelete(with password: String) {
        guard let user = Auth.auth().currentUser, let email = user.email else {
            errorMessage = "Unable to reauthenticate: missing user or email."
            showingError = true
            return
        }
        isDeleting = true
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                errorMessage = "Reauthentication failed: \(error.localizedDescription)"
                showingError = true
                isDeleting = false
                return
            }
            Task {
                do {
                    // Delete Firestore data first
                    try await firebaseManager.deleteAllUserData()
                    // Delete Storage assets best-effort
                    await deleteUserStorageAssets(for: user.uid)
                    // Finally delete the Auth user
                    user.delete { err in
                        if let err = err {
                            errorMessage = "Account deletion failed: \(err.localizedDescription)"
                            showingError = true
                            isDeleting = false
                        } else {
                            successMessage = "Your account has been deleted."
                            showingSuccess = true
                            isDeleting = false
                            // Optionally dismiss after a delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                dismiss()
                            }
                        }
                    }
                } catch {
                    errorMessage = "Failed to delete data: \(error.localizedDescription)"
                    showingError = true
                    isDeleting = false
                }
            }
        }
    }

    private func deleteUserStorageAssets(for uid: String) async {
        let storage = Storage.storage()
        let rootRef = storage.reference().child("users/\(uid)")
        await withCheckedContinuation { continuation in
            rootRef.listAll { result, error in
                if let _ = error {
                    continuation.resume()
                    return
                }
                guard let result = result else {
                    continuation.resume()
                    return
                }
                let group = DispatchGroup()
                for itemRef in result.items {
                    group.enter()
                    itemRef.delete { _ in group.leave() }
                }
                for prefixRef in result.prefixes {
                    group.enter()
                    prefixRef.listAll { inner, _ in
                        guard let inner = inner else {
                            group.leave()
                            return
                        }
                        for item in inner.items {
                            group.enter()
                            item.delete { _ in group.leave() }
                        }
                        group.leave()
                    }
                }
                group.notify(queue: .main) {
                    continuation.resume()
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

// MARK: - Health Disclaimer View

struct HealthDisclaimerView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Icon
                    HStack {
                        Spacer()
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding(.top, 20)

                    // Title
                    Text("Health Disclaimer")
                        .font(.system(size: 28, weight: .bold))
                        .padding(.horizontal)

                    // Content
                    VStack(alignment: .leading, spacing: 16) {
                        DisclaimerSection(
                            title: "Not Medical Advice",
                            text: "NutraSafe is a nutrition tracking and food safety information tool. It is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition."
                        )

                        DisclaimerSection(
                            title: "Food Allergies & Intolerances",
                            text: "While we strive to provide accurate allergen and ingredient information, we cannot guarantee the completeness or accuracy of all data. Always verify food labels and ingredients yourself, especially if you have severe allergies or medical conditions."
                        )

                        DisclaimerSection(
                            title: "Dietary Recommendations",
                            text: "Any nutritional information, calorie goals, or dietary suggestions provided by this app are general guidelines only. Individual nutritional needs vary greatly based on age, sex, weight, activity level, and health conditions. Consult with a registered dietitian or healthcare provider for personalized dietary advice."
                        )

                        DisclaimerSection(
                            title: "Third-Party Data",
                            text: "Food information is sourced from various databases and user contributions. While we work to maintain accuracy, we are not responsible for errors or omissions in third-party data. Use this information as a guide, not as absolute truth."
                        )

                        DisclaimerSection(
                            title: "Health Conditions",
                            text: "If you have any medical conditions (including but not limited to diabetes, cardiovascular disease, kidney disease, or eating disorders), consult your healthcare provider before making significant changes to your diet or exercise routine."
                        )

                        DisclaimerSection(
                            title: "Emergency Situations",
                            text: "If you experience a severe allergic reaction or any medical emergency, call emergency services immediately. Do not rely on this app in emergency situations."
                        )
                    }
                    .padding(.horizontal)

                    // Footer
                    Text("By using NutraSafe, you acknowledge that you have read and understood this disclaimer and agree to use the app at your own risk.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)

                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 40)
                }
            }
            .navigationTitle("Disclaimer")
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
}

struct DisclaimerSection: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
            }

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

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
                try await firebaseManager.saveAllergens(Array(selectedAllergens))
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
                        ForEach(reactions.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() })) { reaction in
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

            Text(reaction.timestamp.dateValue(), style: .date)
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            if !reaction.symptoms.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Text(reaction.symptoms.prefix(3).joined(separator: ", "))
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

// MARK: - Safety Alerts Configuration View

struct SafetyAlertsConfigView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("showAllergenAlerts") private var showAllergenAlerts = true
    @AppStorage("showAdditiveAlerts") private var showAdditiveAlerts = true
    @AppStorage("showProcessingAlerts") private var showProcessingAlerts = false
    @AppStorage("showChildWarnings") private var showChildWarnings = true

    var body: some View {
        NavigationView {
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
            .navigationTitle("Safety Alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        let notificationFeedback = UINotificationFeedbackGenerator()
                        notificationFeedback.notificationOccurred(.success)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Micronutrient Display Preferences View

struct MicronutrientDisplayView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("showMicronutrients") private var showMicronutrients = true
    @AppStorage("showDailyValues") private var showDailyValues = true
    @AppStorage("prioritizeDeficiencies") private var prioritizeDeficiencies = false

    var body: some View {
        NavigationView {
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
            .navigationTitle("Micronutrient Display")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        let notificationFeedback = UINotificationFeedbackGenerator()
                        notificationFeedback.notificationOccurred(.success)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Notification Settings View

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var notificationsEnabled: Bool
    @Binding var useByNotificationsEnabled: Bool
    @Binding var fastingNotificationsEnabled: Bool

    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var showingPermissionAlert = false
    @State private var isCheckingPermissions = true

    var body: some View {
        NavigationView {
            List {
                // Header Section
                Section {
                    Text("Control when and how NutraSafe sends you notifications")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                // Permission Status Section
                Section {
                    HStack {
                        Image(systemName: permissionStatusIcon)
                            .foregroundColor(permissionStatusColor)
                            .font(.system(size: 20))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("System Permissions")
                                .font(.system(size: 16, weight: .semibold))

                            Text(permissionStatusText)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if permissionStatus == .denied {
                            Button("Open Settings") {
                                openSystemSettings()
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 8)
                } footer: {
                    if permissionStatus == .denied {
                        Text("Notifications are disabled in system settings. Open Settings to enable them for NutraSafe.")
                            .font(.system(size: 12))
                    }
                }

                // Notification Types Section
                Section(header: Text("Notification Types")) {
                    // Use-By Reminders
                    Toggle(isOn: $useByNotificationsEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(.orange)
                                Text("Use-By Reminders")
                                    .font(.system(size: 16))
                            }

                            Text("Get notified when food is about to expire")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(permissionStatus != .authorized && permissionStatus != .provisional)
                    .onChange(of: useByNotificationsEnabled) { newValue in
                        if newValue {
                            // Request permission if needed
                            if permissionStatus == .notDetermined {
                                requestNotificationPermission()
                            }
                            // Reschedule all notifications for existing items
                            Task {
                                do {
                                    let items: [UseByInventoryItem] = try await FirebaseManager.shared.getUseByItems()
                                    await UseByNotificationManager.shared.refreshAllNotifications(for: items)
                                    print("✅ Rescheduled notifications for \(items.count) use-by items")
                                } catch {
                                    print("❌ Error refreshing use-by notifications: \(error)")
                                }
                            }
                        } else {
                            // Cancel all notifications when disabled
                            UseByNotificationManager.shared.cancelAllNotifications()
                            print("🔕 Cancelled all use-by notifications")
                        }
                    }

                    // Fasting Notifications
                    Toggle(isOn: $fastingNotificationsEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.badge.checkmark")
                                    .foregroundColor(.blue)
                                Text("Fasting Tracker")
                                    .font(.system(size: 16))
                            }

                            Text("Persistent notifications for fasting progress")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(permissionStatus != .authorized && permissionStatus != .provisional)
                    .onChange(of: fastingNotificationsEnabled) { newValue in
                        if newValue && permissionStatus == .notDetermined {
                            requestNotificationPermission()
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        dismiss()
                    }
                }
            }
            .task {
                // Check permissions immediately when view appears
                await checkNotificationPermission()
            }
        }
    }

    // MARK: - Computed Properties

    private var permissionStatusIcon: String {
        switch permissionStatus {
        case .authorized, .provisional:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        case .ephemeral:
            return "checkmark.circle.fill"
        @unknown default:
            return "questionmark.circle.fill"
        }
    }

    private var permissionStatusColor: Color {
        switch permissionStatus {
        case .authorized, .provisional:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        case .ephemeral:
            return .green
        @unknown default:
            return .gray
        }
    }

    private var permissionStatusText: String {
        switch permissionStatus {
        case .authorized:
            return "Notifications are enabled"
        case .provisional:
            return "Quiet notifications enabled"
        case .denied:
            return "Notifications are disabled"
        case .notDetermined:
            return "Not yet configured"
        case .ephemeral:
            return "Temporary notifications enabled"
        @unknown default:
            return "Unknown status"
        }
    }

    // MARK: - Helper Methods

    private func checkNotificationPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        permissionStatus = settings.authorizationStatus
        isCheckingPermissions = false
    }

    private func requestNotificationPermission() {
        Task {
            let granted = await UseByNotificationManager.shared.requestNotificationPermissions()
            if granted {
                permissionStatus = .authorized
            } else {
                permissionStatus = .denied
                useByNotificationsEnabled = false
                fastingNotificationsEnabled = false
            }
            await checkNotificationPermission()
        }
    }

    private func openSystemSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}
import SwiftUI
import HealthKit

struct AppleHealthSettingsView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @AppStorage("healthKitRingsEnabled") private var healthKitRingsEnabled = false
    @State private var isConnected = false
    @State private var showManageInstructions = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Apple Health Logo & Header
                VStack(spacing: 16) {
                    // Apple Health Logo - heart on white (like in Health app UI)
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)

                        Image(systemName: "heart.fill")
                            .font(.system(size: 42))
                            .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19))
                    }

                    Text("Apple Health")
                        .font(.system(size: 28, weight: .bold))

                    Text("By linking NutraSafe to Apple Health, you can allow NutraSafe to read and update your calories and body measurements.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 32)

                // Connect / Manage Button
                if !isConnected {
                    // First time connection - trigger native HealthKit dialog
                    Button(action: {
                        Task {
                            await requestHealthKitPermission()
                        }
                    }) {
                        HStack {
                            Image(systemName: "cross.case.fill")
                                .symbolRenderingMode(.multicolor)
                            Text("Connect to Apple Health")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                } else {
                    // Already connected - show instructions
                    Button(action: {
                        showManageInstructions = true
                    }) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                            Text("Manage Permissions")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }

                // What We Read Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("What We Read")
                        .font(.system(size: 20, weight: .semibold))
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        HealthDataRow(
                            icon: "flame.fill",
                            title: "Active Energy",
                            description: "Calories burned from physical activity"
                        )

                        Divider()
                            .padding(.leading, 52)

                        HealthDataRow(
                            icon: "scalemass.fill",
                            title: "Body Weight",
                            description: "Your current weight measurements"
                        )
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.top, 8)

                // What We Write Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("What We Update")
                        .font(.system(size: 20, weight: .semibold))
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        HealthDataRow(
                            icon: "fork.knife",
                            title: "Calories Consumed",
                            description: "Nutrition data from meals you log"
                        )

                        Divider()
                            .padding(.leading, 52)

                        HealthDataRow(
                            icon: "scalemass.fill",
                            title: "Body Weight",
                            description: "Weight measurements you track"
                        )
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.top, 8)

                // Privacy Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Privacy")
                        .font(.system(size: 20, weight: .semibold))
                        .padding(.horizontal)

                    Text("NutraSafe reads your exercise and body data to provide better nutrition insights, and updates your calorie and weight data when you log meals or measurements. We never share your health information with third parties.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding(.top, 8)

                Spacer()
            }
        }
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkConnectionStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Refresh connection status when returning to app
            checkConnectionStatus()
        }
        .alert("Manage Apple Health Permissions", isPresented: $showManageInstructions) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("To manage NutraSafe's Apple Health permissions:\n\n1. Open the Settings app\n2. Scroll down and tap 'Health'\n3. Tap 'Data Access & Devices'\n4. Tap 'NutraSafe'\n5. Toggle permissions on or off")
        }
    }

    private func requestHealthKitPermission() async {
        // DEBUG LOG: print("🔵 requestHealthKitPermission() called")

        // Trigger the native HealthKit authorization dialog
        await healthKitManager.requestAuthorization()
        // DEBUG LOG: print("🔵 Authorization complete")

        // Enable rings after authorization
        await MainActor.run {
            healthKitRingsEnabled = true
        // DEBUG LOG: print("🔵 Rings enabled: \(healthKitRingsEnabled)")
        }

        // Update exercise calories
        await healthKitManager.updateExerciseCalories()
        // DEBUG LOG: print("🔵 Exercise calories updated")

        // Refresh connection status
        await MainActor.run {
            checkConnectionStatus()
        // DEBUG LOG: print("🔵 Final connection status: \(isConnected)")
        }
    }

    private func checkConnectionStatus() {
        // Check if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            isConnected = false
            print("🏥 HealthKit not available")
            return
        }

        let healthStore = HKHealthStore()
        let exerciseType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!

        let authStatus = healthStore.authorizationStatus(for: exerciseType)

        // Consider connected if:
        // 1. HealthKit says we're authorized, OR
        // 2. User has enabled rings (they went through authorization process)
        let newConnectionStatus = (authStatus == .sharingAuthorized) || healthKitRingsEnabled

        print("🏥 HealthKit Status - Auth: \(authStatus.rawValue), RingsEnabled: \(healthKitRingsEnabled)")
        print("🏥 Calculating: authStatus == .sharingAuthorized? \(authStatus == .sharingAuthorized)")
        print("🏥 Setting isConnected to: \(newConnectionStatus)")

        isConnected = newConnectionStatus
    }

    private func openHealthKitSettings() {
        // DEBUG LOG: print("🔵 openHealthKitSettings() called")

        // Open Settings > Health > Data Access & Devices > NutraSafe
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        let healthUrlString = "x-apple-health://Sources/\(bundleId)"
        // DEBUG LOG: print("🔵 Attempting to open: \(healthUrlString)")

        if let url = URL(string: healthUrlString) {
            UIApplication.shared.open(url) { success in
        // DEBUG LOG: print("🔵 Health settings opened: \(success)")
            }
        } else if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
        // DEBUG LOG: print("🔵 Fallback to app settings")
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Health Data Row

struct HealthDataRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.red)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct AppleHealthSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AppleHealthSettingsView()
                .environmentObject(HealthKitManager.shared)
        }
    }
}
