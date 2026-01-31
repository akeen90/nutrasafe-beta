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
import HealthKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseManager: FirebaseManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

    /// Binding to navigate to a specific tab after dismissing
    var selectedTab: Binding<TabItem>?

    @State private var showingSignOutAlert = false
    @State private var showingPasswordResetAlert = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var successMessage = ""
    @State private var showingPaywall = false

    var body: some View {
        NavigationView {
            ScrollViewWithTopReset {
                VStack(spacing: 20) {

                    // PHASE 1: Account Section
                    AccountSection(
                        userEmail: firebaseManager.currentUser?.email ?? "No email",
                        onChangePassword: handleChangePassword,
                        onSignOut: { showingSignOutAlert = true }
                    )

                    // Profile Section (Gender & Birthday)
                    ProfileSection()

                    // PHASE 2: Nutrition Goals Section
                    NutritionGoalsSection()

                    // PHASE 3: Progress Goals Section
                    ProgressGoalsSection()

                    // PHASE 4: Health & Safety Section
                    HealthSafetySection()

                    // PHASE 5: App Preferences Section
                    AppPreferencesSection(selectedTab: selectedTab)

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
                                Task {
                                    do {
                                        try await subscriptionManager.restore()
                                        successMessage = subscriptionManager.isSubscribed
                                            ? "Subscription successfully restored!"
                                            : "No active subscriptions found to restore."
                                        showingSuccess = true
                                    } catch {
                                        errorMessage = "Failed to restore purchases. Please try again."
                                        showingError = true
                                    }
                                }
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
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .background(AppAnimatedBackground().ignoresSafeArea())
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
        .navigationViewStyle(.stack)
        .tabGradientBackground(.settings)
        .preferredColorScheme(appearanceMode.colorScheme)
        .trackScreen("Settings")
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
    @Environment(\.colorScheme) private var colorScheme
    let userEmail: String
    let onChangePassword: () -> Void
    let onSignOut: () -> Void

    var body: some View {
        SettingsSection(title: "Account") {
            // User Email Display
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppPalette.standard.accent.opacity(0.15), AppPalette.standard.accent.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)

                    Image(systemName: "envelope.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(AppPalette.standard.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Email")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Text(userEmail)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider()
                .padding(.leading, 56)

            // Change Password
            SettingsRow(
                icon: "lock.rotation",
                title: "Change Password",
                iconColor: .orange,
                action: onChangePassword
            )

            Divider()
                .padding(.leading, 56)

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

// MARK: - Profile Section (Gender & Birthday)

struct ProfileSection: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var onboardingManager = OnboardingManager.shared
    @State private var showingGenderPicker = false
    @State private var showingBirthdayPicker = false

    var body: some View {
        SettingsSection(title: "Profile") {
            // Gender
            Button(action: { showingGenderPicker = true }) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.15), Color.purple.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 38, height: 38)

                        Image(systemName: onboardingManager.userGender.icon)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.purple)
                    }

                    Text("Gender")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)

                    Spacer()

                    Text(onboardingManager.userGender.displayName)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            Divider()
                .padding(.leading, 56)

            // Birthday/Age
            Button(action: { showingBirthdayPicker = true }) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange.opacity(0.15), Color.orange.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 38, height: 38)

                        Image(systemName: "birthday.cake.fill")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.orange)
                    }

                    Text("Birthday")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)

                    Spacer()

                    if let age = onboardingManager.userAge {
                        Text("\(age) years old")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    } else {
                        Text("Not set")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showingGenderPicker) {
            GenderPickerSheet()
        }
        .sheet(isPresented: $showingBirthdayPicker) {
            BirthdayPickerSheet()
        }
    }
}

// MARK: - Gender Picker Sheet

struct GenderPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var onboardingManager = OnboardingManager.shared
    @State private var selectedGender: UserGender = OnboardingManager.shared.userGender

    var body: some View {
        NavigationView {
            List {
                ForEach([UserGender.male, .female, .other], id: \.self) { gender in
                    Button(action: {
                        selectedGender = gender
                    }) {
                        HStack {
                            Image(systemName: gender.icon)
                                .font(.system(size: 20))
                                .foregroundColor(.purple)
                                .frame(width: 30)

                            Text(gender.displayName)
                                .foregroundColor(.primary)

                            Spacer()

                            if selectedGender == gender {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppPalette.standard.accent)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Gender")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onboardingManager.saveGender(selectedGender)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Birthday Picker Sheet

struct BirthdayPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var onboardingManager = OnboardingManager.shared
    @State private var selectedDate: Date

    // Date range for birthday picker (ages 13 to 120)
    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let now = Date()
        let minAge = calendar.date(byAdding: .year, value: -120, to: now) ?? now
        let maxAge = calendar.date(byAdding: .year, value: -13, to: now) ?? now
        return minAge...maxAge
    }

    init() {
        let fallbackDate = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
        let defaultDate = OnboardingManager.shared.userBirthday ?? fallbackDate
        _selectedDate = State(initialValue: defaultDate)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                DatePicker(
                    "Birthday",
                    selection: $selectedDate,
                    in: dateRange,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()

                // Show calculated age
                let age = calculateAge(from: selectedDate)
                Text("\(age) years old")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()
            }
            .navigationTitle("Birthday")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onboardingManager.saveBirthday(selectedDate)
                        dismiss()
                    }
                }
            }
        }
    }

    private func calculateAge(from date: Date) -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: date, to: Date())
        return ageComponents.year ?? 0
    }
}

// MARK: - About Section

struct AboutSection: View {
    @State private var showingHealthDisclaimer = false
    @State private var showingDataSources = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SettingsSection(title: "About") {
            // App Version
            HStack {
                Image(systemName: "info.circle")
                    .font(.system(size: 16))
                    .foregroundColor(AppPalette.standard.accent)
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
                title: "Terms of Use",
                iconColor: .blue,
                action: {
                    if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
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
                icon: "link.circle",
                title: "Data Sources",
                iconColor: .blue,
                action: {
                    showingDataSources = true
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
                    // Notify ContentView to dismiss Settings and show onboarding
                    NotificationCenter.default.post(name: .restartOnboarding, object: nil)
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            )
        }
        .fullScreenCover(isPresented: $showingHealthDisclaimer) {
            HealthDisclaimerView()
        }
        .fullScreenCover(isPresented: $showingDataSources) {
            SourcesAndCitationsView()
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Reusable Components (Updated with Onboarding Design Language)

struct SettingsSection<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section title with icon container style
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(Color.nutraSafeCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .stroke(
                        colorScheme == .dark
                            ? Color.white.opacity(0.08)
                            : Color.black.opacity(0.04),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06),
                radius: 10,
                y: 4
            )
        }
    }
}

struct SettingsRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let title: String
    var iconColor: Color = .blue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon with gradient background matching brand style
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [iconColor.opacity(0.15), iconColor.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)

                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(iconColor)
                }

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Settings row with a value display on the right side
struct SettingsValueRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let title: String
    var iconColor: Color = .blue
    var value: String? = nil
    var valueColor: Color? = nil
    var subtitle: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon with gradient background matching brand style
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [iconColor.opacity(0.15), iconColor.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)

                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(iconColor)
                }

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                if let value = value {
                    Text(value)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(valueColor ?? iconColor)
                        .fixedSize()
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Nutrition Goal Row Component

/// Reusable row for nutrition goal settings with stepper
struct NutritionGoalRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let unit: String
    let onChange: (Int) -> Void

    // Fixed width for stepper to ensure alignment
    private let stepperWidth: CGFloat = 88

    var body: some View {
        HStack(spacing: 0) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [iconColor.opacity(0.15), iconColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)

                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(iconColor)
            }
            .padding(.trailing, 14)

            // Title and value - takes remaining space minus stepper
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if let subtitle = subtitle {
                        Spacer(minLength: 4)
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Text("\(formatNumber(value)) \(unit)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }

            Spacer(minLength: 12)

            // Compact stepper buttons - fixed width for alignment
            HStack(spacing: 0) {
                Button(action: {
                    if value - step >= range.lowerBound {
                        value -= step
                        onChange(value)
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(value <= range.lowerBound ? .secondary.opacity(0.3) : .primary)
                        .frame(width: 40, height: 36)
                }
                .disabled(value <= range.lowerBound)

                Divider()
                    .frame(height: 20)

                Button(action: {
                    if value + step <= range.upperBound {
                        value += step
                        onChange(value)
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(value >= range.upperBound ? .secondary.opacity(0.3) : .primary)
                        .frame(width: 40, height: 36)
                }
                .disabled(value >= range.upperBound)
            }
            .frame(width: stepperWidth)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Nutrition Goals Section (PHASE 2)

struct NutritionGoalsSection: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var firebaseManager: FirebaseManager

    @State private var caloricGoal: Int = 2000
    @State private var exerciseGoal: Int = 600
    @State private var stepGoal: Int = 10000
    @State private var waterGoal: Int = 8
    @State private var macroGoals: [MacroGoal] = MacroGoal.defaultMacros
    @State private var selectedDietType: DietType? = nil // Initialized from cache in loadGoals
    @State private var customCarbLimit: Int = 50
    @State private var showingCarbLimitEditor = false

    @AppStorage("dailyWaterGoal") private var savedWaterGoal: Int = 8
    @AppStorage("customCarbLimit") private var savedCarbLimit: Int = 50
    @AppStorage("cachedDietType") private var cachedDietType: String = "flexible"

    @State private var isLoading = true
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingMacroManagement = false

    var body: some View {
        SettingsSection(title: "Nutrition Goals") {
            // Always render content immediately from cached values - no loading state
            VStack(spacing: 0) {
                // Exercise Goal
                NutritionGoalRow(
                    icon: "figure.run",
                    iconColor: .orange,
                    title: "Exercise Goal",
                    value: $exerciseGoal,
                    range: 100...2000,
                    step: 50,
                    unit: "cal",
                    onChange: saveExerciseGoal
                )

                Divider()
                    .padding(.leading, 56)

                // Step Goal
                NutritionGoalRow(
                    icon: "figure.walk",
                    iconColor: .green,
                    title: "Step Goal",
                    value: $stepGoal,
                    range: 1000...30000,
                    step: 500,
                    unit: "steps",
                    onChange: saveStepGoal
                )

                Divider()
                    .padding(.leading, 56)

                // Water Goal
                NutritionGoalRow(
                    icon: "drop.fill",
                    iconColor: .cyan,
                    title: "Water Goal",
                    subtitle: "NHS: 6-8 glasses",
                    value: $waterGoal,
                    range: 4...16,
                    step: 1,
                    unit: "glasses",
                    onChange: { newValue in savedWaterGoal = newValue }
                )

                Divider()
                    .padding(.leading, 56)

                // Diet Management
                Button(action: { showingMacroManagement = true }) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green.opacity(0.15), Color.green.opacity(0.08)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 38, height: 38)

                            Image(systemName: "fork.knife")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.green)
                        }

                        Text("Diet Management")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)

                        Spacer()

                        Text(macroGoals.map { $0.macroType.displayName }.joined(separator: " • "))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .onAppear {
            // Instant render from cached values - no loading spinner
            exerciseGoal = cachedExerciseGoal
            stepGoal = cachedStepGoal
            waterGoal = savedWaterGoal
            isLoading = false
            // Load fresh data in background (updates silently)
            Task { await loadNutritionGoals() }
        }
        .fullScreenCover(isPresented: $showingMacroManagement) {
            DietManagementRedesigned(
                macroGoals: $macroGoals,
                dietType: $selectedDietType,
                customCarbLimit: $customCarbLimit,
                onSave: saveMacroGoals
            )
            .environmentObject(firebaseManager)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    @AppStorage("cachedCaloricGoal") private var cachedCaloricGoal: Int = 2000
    @AppStorage("cachedExerciseGoal") private var cachedExerciseGoal: Int = 600
    @AppStorage("cachedStepGoal") private var cachedStepGoal: Int = 10000

    private func loadNutritionGoals() async {
        // First, initialize from cached values (includes onboarding-set values)
        await MainActor.run {
            if selectedDietType == nil {
                selectedDietType = DietType(rawValue: cachedDietType) ?? .flexible
            }
            // Initialize other values from cache
            caloricGoal = cachedCaloricGoal
            exerciseGoal = cachedExerciseGoal
            stepGoal = cachedStepGoal
        }

        do {
            async let settingsTask = firebaseManager.getUserSettings()
            async let macroTask = firebaseManager.getMacroGoals()
            async let dietTask = firebaseManager.getDietType()
            let settings = try await settingsTask
            let loadedMacroGoals = try await macroTask
            let loadedDiet = try await dietTask

            await MainActor.run {
                // Only update if values differ from cached
                if let newCaloric = settings.caloricGoal, newCaloric != caloricGoal {
                    caloricGoal = newCaloric
                    cachedCaloricGoal = newCaloric
                }
                if let newExercise = settings.exerciseGoal, newExercise != exerciseGoal {
                    exerciseGoal = newExercise
                    cachedExerciseGoal = newExercise
                }
                if let newStep = settings.stepGoal, newStep != stepGoal {
                    stepGoal = newStep
                    cachedStepGoal = newStep
                }
                macroGoals = loadedMacroGoals
                // Only update diet type if Firebase has a value
                if let diet = loadedDiet {
                    selectedDietType = diet
                    cachedDietType = diet.rawValue
                }
                customCarbLimit = savedCarbLimit
            }
        } catch {
            // Keep cached values on error (already set above)
        }
    }

    private func saveCaloricGoal(_ goal: Int) {
        Task {
            do {
                cachedCaloricGoal = goal
                try await firebaseManager.saveUserSettings(height: nil, goalWeight: nil, caloricGoal: goal)
                
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

    private func saveExerciseGoal(_ goal: Int) {
        Task {
            do {
                cachedExerciseGoal = goal
                try await firebaseManager.saveUserSettings(height: nil, goalWeight: nil, exerciseGoal: goal)
                
                // Notify diary view to update immediately
                await MainActor.run {
                    NotificationCenter.default.post(name: .nutritionGoalsUpdated, object: nil)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save exercise goal: \(error.localizedDescription)"
                    showingError = true
                }
                // Reload on error to revert to saved value
                await loadNutritionGoals()
            }
        }
    }

    private func saveStepGoal(_ goal: Int) {
        Task {
            do {
                cachedStepGoal = goal
                try await firebaseManager.saveUserSettings(height: nil, goalWeight: nil, stepGoal: goal)
                
                // Notify diary view to update immediately
                await MainActor.run {
                    NotificationCenter.default.post(name: .nutritionGoalsUpdated, object: nil)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save step goal: \(error.localizedDescription)"
                    showingError = true
                }
                // Reload on error to revert to saved value
                await loadNutritionGoals()
            }
        }
    }

    private func saveMacroGoals(diet: DietType?) {
        Task {
            do {
                try await firebaseManager.saveMacroGoals(macroGoals, dietType: diet)
                // Notify diary view to update immediately
                await MainActor.run {
                    NotificationCenter.default.post(name: .nutritionGoalsUpdated, object: nil)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save macro goals: \(error.localizedDescription)"
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
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
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
            // Always render from cached values - no loading spinner
            VStack(spacing: 0) {
                // Current Weight
                SettingsValueRow(
                    icon: "scalemass.fill",
                    title: "Current Weight",
                    iconColor: AppPalette.standard.accent,
                    value: currentWeight.map { formatWeight($0) } ?? "Not set",
                    valueColor: currentWeight != nil ? AppPalette.standard.accent : .secondary,
                    action: { showingWeightEditor = true }
                )

                Divider()
                    .padding(.leading, 56)

                // Goal Weight
                SettingsValueRow(
                    icon: "flag.fill",
                    title: "Goal Weight",
                    iconColor: .green,
                    value: goalWeight.map { formatWeight($0) } ?? "Not set",
                    valueColor: goalWeight != nil ? .green : .secondary,
                    action: { showingGoalEditor = true }
                )

                Divider()
                    .padding(.leading, 56)

                // Height
                SettingsValueRow(
                    icon: "ruler.fill",
                    title: "Height",
                    iconColor: .purple,
                    value: height.map { formatHeight($0) } ?? "Not set",
                    valueColor: height != nil ? .purple : .secondary,
                    action: { showingHeightEditor = true }
                )

                // BMI Display (if height and weight are set)
                if let h = height, let w = currentWeight, h > 0 {
                    Divider()
                        .padding(.leading, 56)

                    let bmi = calculateBMI(weight: w, heightCm: h)
                    SettingsValueRow(
                        icon: "heart.text.square.fill",
                        title: "BMI",
                        iconColor: .pink,
                        value: String(format: "%.1f", bmi),
                        valueColor: bmiColor(bmi),
                        subtitle: bmiCategory(bmi),
                        action: { }
                    )
                }

                Divider()
                    .padding(.leading, 56)

                // Weight History
                SettingsValueRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Weight History",
                    iconColor: .orange,
                    value: "\(weightEntries.count) entries",
                    valueColor: .secondary,
                    action: { showingWeightHistory = true }
                )
            }
        }
        .onAppear {
            Task { await loadProgressData() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .weightHistoryUpdated)) { _ in
            Task { await loadProgressData() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .goalWeightUpdated)) { notification in
            // Sync goal weight from Progress tab updates
            if let gw = notification.userInfo?["goalWeight"] as? Double {
                goalWeight = gw
            } else {
                Task { await loadProgressData() }
            }
        }
        .fullScreenCover(isPresented: $showingWeightHistory) {
            WeightTrackingView(showingSettings: $showingWeightHistory, isActive: true, isPresentedAsModal: true)
                .environmentObject(firebaseManager)
                .environmentObject(healthKitManager)
                .environmentObject(subscriptionManager)
        }
        .onChange(of: showingWeightHistory) { _, isShowing in
            if !isShowing {
                // Reload data when returning from Weight History
                Task {
                    await loadProgressData()
                }
            }
        }
        .fullScreenCover(isPresented: $showingWeightEditor) {
            CurrentWeightEditorView(
                currentWeight: $currentWeight,
                onSave: saveCurrentWeight
            )
            .environmentObject(firebaseManager)
        }
        .fullScreenCover(isPresented: $showingHeightEditor) {
            HeightEditorView(height: $height, onSave: saveHeight)
        }
        .fullScreenCover(isPresented: $showingGoalEditor) {
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
            async let settingsTask = manager.getUserSettings()
            async let entriesTask = manager.getWeightHistory()
            let settings = try await settingsTask
            let entries = try await entriesTask

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
            .scrollContentBackground(.hidden)
            .background(AppAnimatedBackground().ignoresSafeArea())
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
        .navigationViewStyle(.stack)
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
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .kg

    @State private var tempWeight: String
    @State private var tempStonesLbs: (stones: String, lbs: String) = ("", "")
    @State private var isSaving = false

    init(currentWeight: Binding<Double?>, onSave: @escaping () -> Void) {
        self._currentWeight = currentWeight
        self.onSave = onSave
        // Initialize tempWeight with an empty string; we'll set it in onAppear based on weightUnit
        self._tempWeight = State(initialValue: "")
    }

    private func formatWeight(_ kg: Double) -> String {
        switch weightUnit {
        case .kg:
            return String(format: "%.1f kg", kg)
        case .lbs:
            let lbs = kg * 2.20462
            return String(format: "%.1f lbs", lbs)
        case .stones:
            let totalLbs = kg * 2.20462
            let stones = Int(totalLbs / 14)
            let remainingLbs = totalLbs.truncatingRemainder(dividingBy: 14)
            return "\(stones) st \(String(format: "%.0f", remainingLbs)) lbs"
        }
    }

    private func convertToDisplay(_ kg: Double) -> Double {
        switch weightUnit {
        case .kg:
            return kg
        case .lbs, .stones:
            return kg * 2.20462
        }
    }

    private func convertToKg(_ displayValue: Double) -> Double {
        switch weightUnit {
        case .kg:
            return displayValue
        case .lbs, .stones:
            return displayValue / 2.20462
        }
    }

    private var weightUnitLabel: String {
        switch weightUnit {
        case .kg:
            return "kg"
        case .lbs:
            return "lbs"
        case .stones:
            return "st/lbs"
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Current Weight (\(weightUnitLabel))")) {
                    TextField("Enter weight", text: $tempWeight)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 18))
                }

                Section(header: Text("Quick Entry")) {
                    if let current = currentWeight {
                        Button("Keep Current: \(formatWeight(current))") {
                            tempWeight = String(format: "%.1f", convertToDisplay(current))
                        }
                    }
                }

                Section {
                    Text("This will create a new entry in your weight history for today.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppAnimatedBackground().ignoresSafeArea())
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
            .onAppear {
                // Set initial value in the correct units when view appears
                if let weight = currentWeight, tempWeight.isEmpty {
                    tempWeight = String(format: "%.1f", convertToDisplay(weight))
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func saveWeight() {
        let sanitized = tempWeight.replacingOccurrences(of: ",", with: ".")
        if let displayValue = Double(sanitized), displayValue > 0 {
            let kgValue = convertToKg(displayValue)
            // Validate kg value is in reasonable range
            if kgValue > 0 && kgValue < 500 {
                isSaving = true
                currentWeight = kgValue
                onSave()
                // Dismiss immediately; parent will refresh and reconcile asynchronously
                dismiss()
            }
        }
    }
}

// MARK: - Goal Weight Editor

struct GoalWeightEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let currentWeight: Double?
    @Binding var goalWeight: Double?
    let onSave: () -> Void
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .kg

    @State private var tempWeight: String
    @State private var isSaving = false

    init(currentWeight: Double?, goalWeight: Binding<Double?>, onSave: @escaping () -> Void) {
        self.currentWeight = currentWeight
        self._goalWeight = goalWeight
        self.onSave = onSave
        // Initialize with empty string; we'll set it in onAppear based on weightUnit
        self._tempWeight = State(initialValue: "")
    }

    private func formatWeight(_ kg: Double) -> String {
        switch weightUnit {
        case .kg:
            return String(format: "%.1f kg", kg)
        case .lbs:
            let lbs = kg * 2.20462
            return String(format: "%.1f lbs", lbs)
        case .stones:
            let totalLbs = kg * 2.20462
            let stones = Int(totalLbs / 14)
            let remainingLbs = totalLbs.truncatingRemainder(dividingBy: 14)
            return "\(stones) st \(String(format: "%.0f", remainingLbs)) lbs"
        }
    }

    private func convertToDisplay(_ kg: Double) -> Double {
        switch weightUnit {
        case .kg:
            return kg
        case .lbs, .stones:
            return kg * 2.20462
        }
    }

    private func convertToKg(_ displayValue: Double) -> Double {
        switch weightUnit {
        case .kg:
            return displayValue
        case .lbs, .stones:
            return displayValue / 2.20462
        }
    }

    private var weightUnitLabel: String {
        switch weightUnit {
        case .kg:
            return "kg"
        case .lbs:
            return "lbs"
        case .stones:
            return "st/lbs"
        }
    }

    private var quickAdjustment: Double {
        // Use 5 kg or ~10 lbs as the quick adjustment
        switch weightUnit {
        case .kg:
            return 5
        case .lbs, .stones:
            return 11 // ~5kg in lbs
        }
    }

    private var largeAdjustment: Double {
        // Use 10 kg or ~20 lbs as the large adjustment
        switch weightUnit {
        case .kg:
            return 10
        case .lbs, .stones:
            return 22 // ~10kg in lbs
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
                            Text(formatWeight(current))
                                .fontWeight(.semibold)
                        }
                    }
                }

                Section(header: Text("Goal Weight (\(weightUnitLabel))")) {
                    TextField(currentWeight != nil ? String(format: "%.1f", convertToDisplay(currentWeight!)) : "Enter goal weight", text: $tempWeight)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 18))
                }

                // Smart Quick Adjustments based on current weight
                if let current = currentWeight {
                    let currentDisplay = convertToDisplay(current)
                    Section(header: Text("From Current Weight")) {
                        Button {
                            tempWeight = String(format: "%.1f", currentDisplay - quickAdjustment)
                        } label: {
                            HStack {
                                Text("Lose \(String(format: "%.0f", quickAdjustment)) \(weightUnitLabel)")
                                Spacer()
                                Text(String(format: "%.1f \(weightUnitLabel)", currentDisplay - quickAdjustment))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Button {
                            tempWeight = String(format: "%.1f", currentDisplay - largeAdjustment)
                        } label: {
                            HStack {
                                Text("Lose \(String(format: "%.0f", largeAdjustment)) \(weightUnitLabel)")
                                Spacer()
                                Text(String(format: "%.1f \(weightUnitLabel)", currentDisplay - largeAdjustment))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Button {
                            tempWeight = String(format: "%.1f", currentDisplay + quickAdjustment)
                        } label: {
                            HStack {
                                Text("Gain \(String(format: "%.0f", quickAdjustment)) \(weightUnitLabel)")
                                Spacer()
                                Text(String(format: "%.1f \(weightUnitLabel)", currentDisplay + quickAdjustment))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppAnimatedBackground().ignoresSafeArea())
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
            .onAppear {
                // Set initial value in the correct units when view appears
                if tempWeight.isEmpty {
                    if let goal = goalWeight {
                        tempWeight = String(format: "%.1f", convertToDisplay(goal))
                    } else if let current = currentWeight {
                        tempWeight = String(format: "%.1f", convertToDisplay(current))
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func saveWeight() {
        let sanitized = tempWeight.replacingOccurrences(of: ",", with: ".")
        if let displayValue = Double(sanitized), displayValue > 0 {
            let kgValue = convertToKg(displayValue)
            // Validate kg value is in reasonable range
            if kgValue > 0 && kgValue < 500 {
                isSaving = true
                goalWeight = kgValue
                onSave()
                // Dismiss immediately; parent will refresh and reconcile asynchronously
                dismiss()
            }
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
            VStack(spacing: 0) {
                // Allergen Management
                SettingsRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "Allergen Management",
                    iconColor: .red,
                    action: { showingAllergenManagement = true }
                )

                Divider()
                    .padding(.leading, 56)

                // Food Reactions History
                SettingsValueRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Food Reactions History",
                    iconColor: .orange,
                    value: "\(reactionCount) logged",
                    valueColor: .secondary,
                    action: { showingReactionsHistory = true }
                )
            }
        }
        .onAppear {
            Task { await loadHealthSafetyData() }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(isPresented: $showingAllergenManagement) {
            AllergenManagementView()
                .environmentObject(firebaseManager)
        }
        .fullScreenCover(isPresented: $showingReactionsHistory) {
            FoodReactionsHistoryView()
                .environmentObject(firebaseManager)
        }
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
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric
    @AppStorage("useByNotificationsEnabled") private var useByNotificationsEnabled = true
    @AppStorage("healthKitRingsEnabled") private var healthKitRingsEnabled = false

    @EnvironmentObject var healthKitManager: HealthKitManager

    /// Binding to navigate to a specific tab after dismissing (passed from parent)
    var selectedTab: Binding<TabItem>?

    @State private var showingThemeSelector = false
    @State private var showingUnitsSelector = false
    @State private var showingDataPrivacy = false
    @State private var showingNotificationSettings = false
    @State private var showingAppleHealth = false
    @State private var showingEmailPreferences = false
    @State private var showingFeatureTipsReset = false
    @State private var showingSyncStatus = false

    var body: some View {
        SettingsSection(title: "App Preferences") {
            VStack(spacing: 0) {
                // Theme
                SettingsValueRow(
                    icon: "paintbrush.fill",
                    title: "Theme",
                    iconColor: .purple,
                    value: appearanceMode.displayName,
                    valueColor: .secondary,
                    action: { showingThemeSelector = true }
                )

                Divider()
                    .padding(.leading, 56)

                // Apple Health
                SettingsRow(
                    icon: "heart.fill",
                    title: "Apple Health",
                    iconColor: Color(red: 1.0, green: 0.23, blue: 0.19),
                    action: { showingAppleHealth = true }
                )

                Divider()
                    .padding(.leading, 56)

                // Units
                SettingsValueRow(
                    icon: "ruler.fill",
                    title: "Units",
                    iconColor: AppPalette.standard.accent,
                    value: unitSystem.displayName,
                    valueColor: .secondary,
                    action: { showingUnitsSelector = true }
                )

                Divider()
                    .padding(.leading, 56)

                // Notifications
                SettingsRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    iconColor: .red,
                    action: { showingNotificationSettings = true }
                )

                Divider()
                    .padding(.leading, 56)

                // Data & Privacy
                SettingsRow(
                    icon: "lock.shield.fill",
                    title: "Data & Privacy",
                    iconColor: .orange,
                    action: { showingDataPrivacy = true }
                )

                Divider()
                    .padding(.leading, 56)

                // Email Marketing Consent
                SettingsRow(
                    icon: "envelope.fill",
                    title: "Email Preferences",
                    iconColor: AppPalette.standard.accent,
                    action: { showingEmailPreferences = true }
                )

                Divider()
                    .padding(.leading, 56)

                // Reset Feature Tips
                SettingsRow(
                    icon: "lightbulb.fill",
                    title: "Reset Feature Tips",
                    iconColor: .orange,
                    action: {
                        FeatureTipsManager.shared.resetAllTips()
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        showingFeatureTipsReset = true
                    }
                )

                Divider()
                    .padding(.leading, 56)

                // Sync Status
                SettingsRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Sync Status",
                    iconColor: .blue,
                    action: { showingSyncStatus = true }
                )
            }
        }
        .fullScreenCover(isPresented: $showingThemeSelector) {
            ThemeSelectorView(selectedTheme: $appearanceMode)
        }
        .fullScreenCover(isPresented: $showingUnitsSelector) {
            UnitsSelectorView(selectedUnit: $unitSystem)
                .preferredColorScheme(appearanceMode.colorScheme)
        }
        .fullScreenCover(isPresented: $showingNotificationSettings) {
            NotificationSettingsView(
                useByNotificationsEnabled: $useByNotificationsEnabled
            )
            .preferredColorScheme(appearanceMode.colorScheme)
        }
        .fullScreenCover(isPresented: $showingDataPrivacy) {
            DataPrivacyView()
                .preferredColorScheme(appearanceMode.colorScheme)
        }
        .fullScreenCover(isPresented: $showingAppleHealth) {
            AppleHealthSettingsView()
                .preferredColorScheme(appearanceMode.colorScheme)
        }
        .fullScreenCover(isPresented: $showingEmailPreferences) {
            EmailMarketingConsentView()
                .preferredColorScheme(appearanceMode.colorScheme)
        }
        .alert("Tips Reset", isPresented: $showingFeatureTipsReset) {
            Button("OK") {
                selectedTab?.wrappedValue = .diary
                dismiss()
            }
        } message: {
            Text("All feature tips have been reset. You'll see them again as you use the app.")
        }
        .sheet(isPresented: $showingSyncStatus) {
            SyncStatusView()
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
        case .imperial: return "Stones & lbs, feet & inches"
        }
    }
}

// MARK: - Theme Selector View

struct ThemeSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTheme: AppearanceMode

    /// Resolves the actual color scheme to use - for "system" mode, queries the device's current setting
    private var resolvedColorScheme: ColorScheme {
        switch selectedTheme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            // Query the actual system color scheme from UIKit
            let style = UIScreen.main.traitCollection.userInterfaceStyle
            return style == .dark ? .dark : .light
        }
    }

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
                                        .foregroundColor(AppPalette.standard.accent)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppAnimatedBackground().ignoresSafeArea())
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
        .navigationViewStyle(.stack)
        .preferredColorScheme(resolvedColorScheme)
    }
}

// MARK: - Units Selector View

struct UnitsSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedUnit: UnitSystem
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .kg
    @AppStorage("heightUnit") private var heightUnit: HeightUnit = .cm

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
                            // Synchronize weight and height units with system selection
                            if system == .metric {
                                weightUnit = .kg
                                heightUnit = .cm
                            } else {
                                weightUnit = .stones  // UK uses stones and lbs
                                heightUnit = .ftIn
                            }
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: system.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(AppPalette.standard.accent)
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
                                        .foregroundColor(AppPalette.standard.accent)
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
            .scrollContentBackground(.hidden)
            .background(AppAnimatedBackground().ignoresSafeArea())
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
        .navigationViewStyle(.stack)
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
    @State private var showingCleanupConfirmation = false
    @State private var isCleaning = false
    @State private var cleanupCount = 0

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
                                .foregroundColor(AppPalette.standard.accent)
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

                    Button(action: { showingCleanupConfirmation = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Clean Up Corrupt Entries")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)

                                Text("Remove damaged food entries")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if isCleaning {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isCleaning)

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
            .scrollContentBackground(.hidden)
            .background(AppAnimatedBackground().ignoresSafeArea())
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
        .navigationViewStyle(.stack)
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
        .alert("Clean Up Corrupt Entries", isPresented: $showingCleanupConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clean Up") {
                cleanupCorruptEntries()
            }
        } message: {
            Text("This will scan all your food entries and delete any that are corrupted. Valid entries will remain untouched.")
        }
        .fullScreenCover(isPresented: $showingReauthPrompt) {
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppAnimatedBackground().ignoresSafeArea())
                .navigationTitle("Confirm Deletion")
                .navigationBarTitleDisplayMode(.inline)
            }
            .navigationViewStyle(.stack)
        }
    }

    private func exportUserData() {
        errorMessage = "Data export feature is coming soon!"
        showingError = true
    }

    private func cleanupCorruptEntries() {
        isCleaning = true
        Task {
            do {
                let count = try await firebaseManager.cleanupCorruptFoodEntries()
                await MainActor.run {
                    cleanupCount = count
                    if count == 0 {
                        successMessage = "No corrupt entries found. Your data is healthy!"
                    } else if count == 1 {
                        successMessage = "Successfully deleted 1 corrupt entry."
                    } else {
                        successMessage = "Successfully deleted \(count) corrupt entries."
                    }
                    showingSuccess = true
                    isCleaning = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to cleanup entries: \(error.localizedDescription)"
                    showingError = true
                    isCleaning = false
                }
            }
        }
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

                    // Get a fresh reference to the current user after reauthentication
                    // This is critical - the user object must be fresh after reauthentication
                    guard let freshUser = Auth.auth().currentUser else {
                        await MainActor.run {
                            errorMessage = "Unable to get current user for deletion."
                            showingError = true
                            isDeleting = false
                        }
                        return
                    }

                    // Delete the Auth user account
                    await MainActor.run {
                        freshUser.delete { err in
                            if let err = err {
                                                                errorMessage = "Account deletion failed: \(err.localizedDescription)"
                                showingError = true
                                isDeleting = false
                            } else {
                                                                // Account successfully deleted - now sign out and reset onboarding
                                do {
                                    try Auth.auth().signOut()
                                                                        // Reset onboarding so they see it again if they create a new account
                                    OnboardingManager.shared.resetOnboarding()
                                    // Clear any local data
                                    UserDefaults.standard.removeObject(forKey: "preselectedDestination")
                                    UserDefaults.standard.removeObject(forKey: "preselectedMealType")
                                    UserDefaults.standard.removeObject(forKey: "preselectedDate")
                                } catch {
                                                                    }

                                successMessage = "Your account has been permanently deleted."
                                showingSuccess = true
                                isDeleting = false
                                // Dismiss after a delay to show the success message
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    dismiss()
                                }
                            }
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
            .scrollContentBackground(.hidden)
            .background(AppAnimatedBackground().ignoresSafeArea())
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
        .navigationViewStyle(.stack)
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
        .background(Color.adaptiveCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

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

// Legacy wrapper for backwards compatibility
struct AllergenManagementView: View {
    var body: some View {
        SensitivitiesManagementView()
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
            .scrollContentBackground(.hidden)
            .background(AppAnimatedBackground().ignoresSafeArea())
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
        .navigationViewStyle(.stack)
        .onAppear {
            Task {
                await loadReactions()
            }
        }
        .fullScreenCover(item: $selectedReaction) { reaction in
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
            .scrollContentBackground(.hidden)
            .background(AppAnimatedBackground().ignoresSafeArea())
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
        .navigationViewStyle(.stack)
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
            .scrollContentBackground(.hidden)
            .background(AppAnimatedBackground().ignoresSafeArea())
            .navigationTitle("Vitamins & Minerals Display")
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
        .navigationViewStyle(.stack)
    }
}

// MARK: - Notification Settings View

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var useByNotificationsEnabled: Bool

    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var showingPermissionAlert = false
    @State private var isCheckingPermissions = true

    // Fasting notification settings
    @State private var fastingSettings = FastingNotificationSettings.load()

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
                            .foregroundColor(AppPalette.standard.accent)
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
                    .onChange(of: useByNotificationsEnabled) { _, newValue in
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
                                                                    } catch {
                                                                    }
                            }
                        } else {
                            // Cancel all notifications when disabled
                            UseByNotificationManager.shared.cancelAllNotifications()
                                                    }
                    }

                }

                // Fasting Notifications Section
                Section(header: Text("Fasting Notifications")) {
                    // Start Notifications
                    Toggle(isOn: $fastingSettings.startNotificationEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Image(systemName: "play.circle.fill")
                                    .foregroundColor(.green)
                                Text("Start Notifications")
                                    .font(.system(size: 16))
                            }

                            Text("Notify when it's time to start your fast")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(permissionStatus != .authorized && permissionStatus != .provisional)
                    .onChange(of: fastingSettings.startNotificationEnabled) {
                        saveFastingSettings()
                    }

                    // End Notifications
                    Toggle(isOn: $fastingSettings.endNotificationEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Image(systemName: "stop.circle.fill")
                                    .foregroundColor(.red)
                                Text("End Notifications")
                                    .font(.system(size: 16))
                            }

                            Text("Notify when your fast is complete")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(permissionStatus != .authorized && permissionStatus != .provisional)
                    .onChange(of: fastingSettings.endNotificationEnabled) {
                        saveFastingSettings()
                    }

                    // Stage Notifications (Master Toggle)
                    Toggle(isOn: $fastingSettings.stageNotificationsEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .foregroundColor(.purple)
                                Text("Stage Notifications")
                                    .font(.system(size: 16))
                            }

                            Text("Notify at key fasting milestones")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(permissionStatus != .authorized && permissionStatus != .provisional)
                    .onChange(of: fastingSettings.stageNotificationsEnabled) {
                        saveFastingSettings()
                    }

                    // Individual Stage Toggles (shown when stage notifications enabled)
                    if fastingSettings.stageNotificationsEnabled {
                        Toggle(isOn: $fastingSettings.stage4hEnabled) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("4 Hours")
                                    .font(.system(size: 15))
                                Text("Post-meal processing complete")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .disabled(permissionStatus != .authorized && permissionStatus != .provisional)
                        .onChange(of: fastingSettings.stage4hEnabled) {
                            saveFastingSettings()
                        }

                        Toggle(isOn: $fastingSettings.stage8hEnabled) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("8 Hours")
                                    .font(.system(size: 15))
                                Text("Fuel switching activated")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .disabled(permissionStatus != .authorized && permissionStatus != .provisional)
                        .onChange(of: fastingSettings.stage8hEnabled) {
                            saveFastingSettings()
                        }

                        Toggle(isOn: $fastingSettings.stage12hEnabled) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("12 Hours")
                                    .font(.system(size: 15))
                                Text("Fat mobilisation underway")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .disabled(permissionStatus != .authorized && permissionStatus != .provisional)
                        .onChange(of: fastingSettings.stage12hEnabled) {
                            saveFastingSettings()
                        }

                        Toggle(isOn: $fastingSettings.stage16hEnabled) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("16 Hours")
                                    .font(.system(size: 15))
                                Text("Mild ketosis reached")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .disabled(permissionStatus != .authorized && permissionStatus != .provisional)
                        .onChange(of: fastingSettings.stage16hEnabled) {
                            saveFastingSettings()
                        }

                        Toggle(isOn: $fastingSettings.stage20hEnabled) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("20 Hours")
                                    .font(.system(size: 15))
                                Text("Autophagy potential")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .disabled(permissionStatus != .authorized && permissionStatus != .provisional)
                        .onChange(of: fastingSettings.stage20hEnabled) {
                            saveFastingSettings()
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppAnimatedBackground().ignoresSafeArea())
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
        .navigationViewStyle(.stack)
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
            }
            await checkNotificationPermission()
        }
    }

    private func openSystemSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    private func saveFastingSettings() {
        fastingSettings.save()
        FastingNotificationManager.shared.settings = fastingSettings

            }
}

// MARK: - Apple Health Settings View

struct AppleHealthSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("healthKitRingsEnabled") private var healthKitRingsEnabled = false
    @State private var isConnected = false
    @State private var isRequestingPermission = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView {
                VStack(spacing: 20) {
                    // Apple Health Logo & Header
                    VStack(spacing: 14) {
                        // Apple Health styled icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color(.secondarySystemBackground))
                                .frame(width: 88, height: 88)
                                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 10, y: 3)

                            Image(systemName: "heart.fill")
                                .font(.system(size: 42))
                                .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19))
                        }

                        Text("Apple Health")
                            .font(.system(size: 26, weight: .bold))

                        Text("By linking NutraSafe to Apple Health, you can allow NutraSafe to read your activity, steps, and body measurements, and update your calories.")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 56)

                    // Connect Button
                    Button(action: {
                        Task {
                            isRequestingPermission = true
                            await requestHealthKitPermission()
                            isRequestingPermission = false
                        }
                    }) {
                        HStack(spacing: 10) {
                            if isRequestingPermission {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "plus.app.fill")
                                    .font(.system(size: 18))
                            }
                            Text(isRequestingPermission ? "Connecting..." : "Connect to Apple Health")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppPalette.standard.accent)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .disabled(isRequestingPermission)
                    .padding(.horizontal, 24)

                    // What We Read Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What We Read")
                            .font(.system(size: 20, weight: .bold))
                            .padding(.horizontal, 24)

                        VStack(spacing: 0) {
                            HealthDataRow(
                                icon: "flame.fill",
                                iconColor: Color(red: 1.0, green: 0.23, blue: 0.19),
                                title: "Active Energy",
                                description: "Calories burned from physical activity"
                            )

                            Divider()
                                .padding(.leading, 56)

                            HealthDataRow(
                                icon: "figure.walk",
                                iconColor: .orange,
                                title: "Steps",
                                description: "Daily step count from your activity"
                            )

                            Divider()
                                .padding(.leading, 56)

                            HealthDataRow(
                                icon: "scalemass.fill",
                                iconColor: Color(red: 1.0, green: 0.23, blue: 0.19),
                                title: "Body Weight",
                                description: "Your current weight measurements"
                            )
                        }
                        .background(Color.nutraSafeCard)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 10, y: 4)
                        .padding(.horizontal, 24)
                    }

                    // What We Update Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What We Update")
                            .font(.system(size: 20, weight: .bold))
                            .padding(.horizontal, 24)

                        VStack(spacing: 0) {
                            HealthDataRow(
                                icon: "fork.knife",
                                iconColor: Color(red: 1.0, green: 0.23, blue: 0.19),
                                title: "Calories Consumed",
                                description: "Nutrition data from meals you log"
                            )

                            Divider()
                                .padding(.leading, 56)

                            HealthDataRow(
                                icon: "scalemass.fill",
                                iconColor: Color(red: 1.0, green: 0.23, blue: 0.19),
                                title: "Body Weight",
                                description: "Weight measurements you track"
                            )
                        }
                        .background(Color.nutraSafeCard)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 10, y: 4)
                        .padding(.horizontal, 24)
                    }

                    // Privacy Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Privacy")
                            .font(.system(size: 20, weight: .bold))
                            .padding(.horizontal, 24)

                        Text("NutraSafe respects your privacy. You control exactly what data is shared. We never share your health information with third parties.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 8)

                    Spacer().frame(height: 24)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppAnimatedBackground().ignoresSafeArea())
            .onAppear {
                checkConnectionStatus()
            }

            // Close button overlay (top-left for consistency)
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.06))
                    )
            }
            .padding(.top, 16)
            .padding(.leading, 20)
        }
    }

    private func requestHealthKitPermission() async {
        await healthKitManager.requestAuthorization()
        healthKitRingsEnabled = true
        await healthKitManager.updateExerciseCalories()
        checkConnectionStatus()
    }

    private func checkConnectionStatus() {
        let healthStore = HKHealthStore()
        let exerciseType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!

        let authStatus = healthStore.authorizationStatus(for: exerciseType)
        isConnected = (authStatus == .sharingAuthorized) && healthKitRingsEnabled
    }
}

// MARK: - Health Data Row

private struct HealthDataRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Data Sources & Citations

struct SourcesAndCitationsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Data Sources & Citations")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("All nutrition data, daily values, and ingredient information in this app is sourced from official government databases and health organizations.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // FDA Daily Values
                    CitationCard(
                        organization: "U.S. Food & Drug Administration (FDA)",
                        title: "Daily Value on Nutrition and Supplement Facts Labels",
                        description: "Official FDA reference for recommended daily values of nutrients, vitamins, and minerals used throughout this app.",
                        url: "https://www.fda.gov/food/nutrition-facts-label/daily-value-nutrition-and-supplement-facts-labels",
                        category: "Daily Values & RDAs"
                    )

                    // USDA FoodData
                    CitationCard(
                        organization: "U.S. Department of Agriculture (USDA)",
                        title: "FoodData Central",
                        description: "Primary source for comprehensive nutrition data including micronutrients, macronutrients, and serving sizes.",
                        url: "https://fdc.nal.usda.gov/",
                        category: "Nutrition Data"
                    )

                    // NIH DRIs
                    CitationCard(
                        organization: "National Institutes of Health (NIH)",
                        title: "Dietary Reference Intakes (DRIs)",
                        description: "Reference intakes for vitamins and minerals based on age, sex, and life stage.",
                        url: "https://ods.od.nih.gov/HealthInformation/nutrientrecommendations.aspx",
                        category: "Daily Values & RDAs"
                    )

                    // UK NHS Eatwell Guide
                    CitationCard(
                        organization: "UK National Health Service (NHS)",
                        title: "The Eatwell Guide",
                        description: "UK government guidance on healthy eating and balanced nutrition.",
                        url: "https://www.nhs.uk/live-well/eat-well/food-guidelines-and-food-labels/the-eatwell-guide/",
                        category: "General Guidelines"
                    )

                    // FDA Additives
                    CitationCard(
                        organization: "U.S. Food & Drug Administration (FDA)",
                        title: "Food Additive Status List",
                        description: "Official FDA database of approved food additives and their safety status.",
                        url: "https://www.fda.gov/food/food-additives-petitions/food-additive-status-list",
                        category: "Food Additives"
                    )

                    // FDA Allergens
                    CitationCard(
                        organization: "U.S. Food & Drug Administration (FDA)",
                        title: "Food Allergies",
                        description: "Official FDA guidance on major food allergens and labeling requirements.",
                        url: "https://www.fda.gov/food/food-labeling-nutrition/food-allergies",
                        category: "Allergen Information"
                    )

                    // Disclaimer
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Important Note")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("While we source data from official databases, individual food products may vary. Always verify nutrition labels on actual food packaging, especially if you have allergies or medical dietary requirements.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct CitationCard: View {
    let organization: String
    let title: String
    let description: String
    let url: String
    let category: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category
            Text(category)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            // Organization
            Text(organization)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppPalette.standard.accent)

            // Title
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)

            // Description
            Text(description)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Link button
            Button(action: {
                if let urlObj = URL(string: url) {
                    UIApplication.shared.open(urlObj)
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "link")
                        .font(.system(size: 12, weight: .medium))

                    Text("View Source")
                        .font(.system(size: 13, weight: .medium))

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppPalette.standard.accent)
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.adaptiveCard)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

// MARK: - Email Marketing Consent View
struct EmailMarketingConsentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseManager: FirebaseManager

    @State private var hasConsented = false
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 20)

                    // Email icon
                    ZStack {
                        Circle()
                            .fill(AppPalette.standard.accent.opacity(0.15))
                            .frame(width: 100, height: 100)

                        Image(systemName: "envelope.fill")
                            .font(.system(size: 50))
                            .foregroundColor(AppPalette.standard.accent)
                    }

                    VStack(spacing: 16) {
                        Text("Email Preferences")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Manage your email communication settings")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    if isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        VStack(alignment: .leading, spacing: 24) {
                            // What you'll receive
                            VStack(alignment: .leading, spacing: 12) {
                                Text("What you'll receive:")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)

                                BulletPoint(text: "New feature announcements")
                                BulletPoint(text: "Nutrition tips and health insights")
                                BulletPoint(text: "Exclusive offers and early access")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                            // Privacy info
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "lock.shield.fill")
                                        .foregroundColor(.green)
                                    Text("Your Privacy")
                                        .font(.system(size: 16, weight: .semibold))
                                }

                                Text("We respect your privacy and will never share your email with third parties. You can unsubscribe at any time from Settings or from any email we send.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)

                            // Consent toggle
                            Toggle(isOn: $hasConsented) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Send me emails")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)

                                    Text(hasConsented ? "You'll receive updates, tips and offers" : "You'll only receive essential account emails")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tint(AppPalette.standard.accent)
                            .padding(20)
                            .background(Color.adaptiveCard)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

                            // Save button
                            Button(action: saveConsent) {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                } else {
                                    Text("Save Preferences")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                }
                            }
                            .background(AppPalette.standard.accent)
                            .cornerRadius(12)
                            .disabled(isSaving)
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer()
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppAnimatedBackground().ignoresSafeArea())
            .navigationTitle("Email Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Success", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your email preferences have been saved")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .task {
                await loadConsent()
            }
        }
        .navigationViewStyle(.stack)
    }

    private func loadConsent() async {
        do {
            hasConsented = try await firebaseManager.getEmailMarketingConsent()
            isLoading = false
        } catch {
            errorMessage = "Failed to load email preferences: \(error.localizedDescription)"
            showingError = true
            isLoading = false
        }
    }

    private func saveConsent() {
        isSaving = true

        Task {
            do {
                try await firebaseManager.updateEmailMarketingConsent(hasConsented: hasConsented)
                await MainActor.run {
                    isSaving = false
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to save preferences: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}

struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(AppPalette.standard.accent)
                .font(.system(size: 16))

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.primary)
        }
    }
}
