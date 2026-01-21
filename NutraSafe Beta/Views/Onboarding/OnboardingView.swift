//
//  OnboardingView.swift
//  NutraSafe Beta
//
//  Comprehensive onboarding flow with goals and lifestyle questionnaire
//  Flow: Welcome → Profile → Goals → Activity → Habits → Experience → Measurements → Analysis → Setup Choice → Permissions → Disclaimer
//

import SwiftUI
import UserNotifications

// MARK: - Main Onboarding View

struct OnboardingView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var currentPage = 0
    @State private var emailMarketingConsent = false

    // Questionnaire state - shared across all pages
    @StateObject private var questionnaireState = OnboardingQuestionnaireState()

    // Diet setup sheet
    @State private var showingDietSetup = false

    // Total pages: Welcome(0) → Profile(1) → Goals(2) → Activity(3) → Habits(4) → Experience(5) → Measurements(6) → Analysis(7) → SetupChoice(8) → Permissions(9) → Disclaimer(10)
    let totalPages = 11
    let onComplete: (Bool) -> Void

    var body: some View {
        ZStack {
            // Clean adaptive background
            Color.adaptiveBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                Group {
                    switch currentPage {
                    case 0:
                        LeanWelcomePage(
                            onContinue: { goToPage(1) }
                        )
                    case 1:
                        LeanProfilePage(
                            onBack: { goToPage(0) },
                            onContinue: { goToPage(2) }
                        )
                    case 2:
                        OnboardingGoalsPage(
                            state: questionnaireState,
                            onBack: { goToPage(1) },
                            onContinue: { goToPage(3) }
                        )
                    case 3:
                        OnboardingActivityPage(
                            state: questionnaireState,
                            onBack: { goToPage(2) },
                            onContinue: { goToPage(4) }
                        )
                    case 4:
                        OnboardingHabitsPage(
                            state: questionnaireState,
                            onBack: { goToPage(3) },
                            onContinue: { goToPage(5) }
                        )
                    case 5:
                        OnboardingExperiencePage(
                            state: questionnaireState,
                            onBack: { goToPage(4) },
                            onContinue: { goToPage(6) }
                        )
                    case 6:
                        OnboardingMeasurementsPage(
                            state: questionnaireState,
                            onBack: { goToPage(5) },
                            onContinue: { goToPage(7) },
                            onSkip: { goToPage(7) }
                        )
                    case 7:
                        OnboardingAnalysisPage(
                            state: questionnaireState,
                            onComplete: { goToPage(8) }
                        )
                    case 8:
                        OnboardingSetupChoicePage(
                            state: questionnaireState,
                            onSetupNow: { showingDietSetup = true },
                            onSetupLater: { goToPage(9) }
                        )
                    case 9:
                        LeanPermissionsPage(
                            onBack: { goToPage(8) },
                            onContinue: { goToPage(10) }
                        )
                    case 10:
                        LeanDisclaimerPage(
                            emailMarketingConsent: $emailMarketingConsent,
                            onBack: { goToPage(9) },
                            onComplete: {
                                OnboardingManager.shared.acceptDisclaimer()
                                OnboardingManager.shared.completeOnboarding()
                                onComplete(emailMarketingConsent)
                            }
                        )
                    default:
                        LeanWelcomePage(
                            onContinue: { goToPage(1) }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Progress dots - grouped into phases for cleaner UI
                ProgressDotsView(currentPage: currentPage, totalPages: totalPages)
                    .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showingDietSetup) {
            DietManagementRedesigned(
                macroGoals: .constant(MacroGoal.defaultMacros),
                dietType: .constant(.flexible),
                customCarbLimit: .constant(50),
                onSave: { _ in
                    showingDietSetup = false
                    goToPage(9)
                }
            )
            .environmentObject(firebaseManager)
            .interactiveDismissDisabled()
        }
        .onAppear {
            AnalyticsManager.shared.trackOnboardingStep(step: currentPage, stepName: onboardingStepName(currentPage))
        }
        .onChange(of: currentPage) { _, newPage in
            AnalyticsManager.shared.trackOnboardingStep(step: newPage, stepName: onboardingStepName(newPage))
        }
    }

    private func goToPage(_ page: Int) {
        withAnimation(.easeInOut(duration: 0.25)) {
            currentPage = page
        }
    }

    private func onboardingStepName(_ page: Int) -> String {
        switch page {
        case 0: return "Welcome"
        case 1: return "Profile"
        case 2: return "Goals"
        case 3: return "Activity"
        case 4: return "Habits"
        case 5: return "Experience"
        case 6: return "Measurements"
        case 7: return "Analysis"
        case 8: return "SetupChoice"
        case 9: return "Permissions"
        case 10: return "Disclaimer"
        default: return "Unknown"
        }
    }
}

// MARK: - Progress Dots View

struct ProgressDotsView: View {
    let currentPage: Int
    let totalPages: Int

    // Group pages into phases for cleaner visualization
    private var currentPhase: Int {
        switch currentPage {
        case 0: return 0     // Welcome
        case 1: return 1     // Profile
        case 2...6: return 2 // Questionnaire (Goals, Activity, Habits, Experience, Measurements)
        case 7...8: return 3 // Analysis & Setup Choice
        case 9: return 4     // Permissions
        case 10: return 5    // Disclaimer
        default: return 0
        }
    }

    private let totalPhases = 6

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPhases, id: \.self) { phase in
                if phase == 2 && (currentPage >= 2 && currentPage <= 6) {
                    // Show sub-progress for questionnaire phase
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { subIndex in
                            Circle()
                                .fill((currentPage - 2) >= subIndex ? Color.accentColor : Color.accentColor.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                } else {
                    Circle()
                        .fill(phase <= currentPhase ? Color.accentColor : Color.primary.opacity(0.2))
                        .frame(width: phase == currentPhase ? 10 : 8, height: phase == currentPhase ? 10 : 8)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: currentPage)
    }
}

// MARK: - Page 1: Welcome

struct LeanWelcomePage: View {
    @Environment(\.colorScheme) var colorScheme
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Spacer().frame(height: 50)

                    // Real app icon from assets
                    Image("AppIconImage")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .shadow(color: Color.black.opacity(0.15), radius: 20, y: 10)

                    // Title
                    VStack(spacing: 8) {
                        Text("Welcome to")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.secondary)

                        Text("NutraSafe")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Your personal food safety companion")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }

                    // Feature list - clean and simple (icons match actual tab bar)
                    VStack(spacing: 12) {
                        FeatureRow(
                            icon: "fork.knife.circle.fill",
                            color: .orange,
                            title: "Diary & Insights",
                            description: "Log meals, track additives and monitor vitamins"
                        )
                        FeatureRow(
                            icon: "figure.run.treadmill.circle.fill",
                            color: .teal,
                            title: "Progress",
                            description: "Track weight, set goals and build healthy habits"
                        )
                        FeatureRow(
                            icon: "calendar.circle.fill",
                            color: .cyan,
                            title: "Use By",
                            description: "Get alerts before opened food goes off"
                        )
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 20)
                }
            }

            // Get Started button
            Button(action: onContinue) {
                Text("Get Started")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.accentColor)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(colorScheme == .dark ? 0.2 : 0.12))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(14)
    }
}

// MARK: - Page 2: Profile (Gender & Birthday)

struct LeanProfilePage: View {
    @Environment(\.colorScheme) var colorScheme
    let onBack: () -> Void
    let onContinue: () -> Void

    @State private var selectedGender: UserGender = OnboardingManager.shared.userGender
    @State private var selectedBirthday: Date = OnboardingManager.shared.userBirthday ?? Calendar.current.date(byAdding: .year, value: -30, to: Date())!
    @State private var hasBirthdayBeenSet = OnboardingManager.shared.userBirthday != nil

    // Date range for birthday picker (ages 13 to 120)
    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let minAge = calendar.date(byAdding: .year, value: -120, to: Date())!
        let maxAge = calendar.date(byAdding: .year, value: -13, to: Date())!
        return minAge...maxAge
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer().frame(height: 30)

                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.purple)
                            .padding(.bottom, 8)

                        Text("About You")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Help us personalise your experience")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    // Gender Selection
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "figure.stand.dress.line.vertical.figure")
                                .font(.system(size: 16))
                                .foregroundColor(.purple)
                            Text("Gender")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 4)

                        VStack(spacing: 8) {
                            ForEach([UserGender.male, .female, .other], id: \.self) { gender in
                                GenderSelectionButton(
                                    gender: gender,
                                    isSelected: selectedGender == gender,
                                    onSelect: { selectedGender = gender }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Birthday Selection
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "birthday.cake.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)
                            Text("Birthday")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 4)

                        VStack(spacing: 8) {
                            DatePicker(
                                "Select your birthday",
                                selection: $selectedBirthday,
                                in: dateRange,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                            .onChange(of: selectedBirthday) { _, _ in
                                hasBirthdayBeenSet = true
                            }

                            // Show calculated age
                            if hasBirthdayBeenSet {
                                let age = calculateAge(from: selectedBirthday)
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.green)
                                    Text("\(age) years old")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Why we need this info
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)

                        Text("Used for personalised nutrition recommendations. You can change this in Settings.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    Spacer().frame(height: 20)
                }
            }

            // Navigation
            HStack(spacing: 12) {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                }

                Button(action: {
                    // Save selections
                    OnboardingManager.shared.saveGender(selectedGender)
                    if hasBirthdayBeenSet {
                        OnboardingManager.shared.saveBirthday(selectedBirthday)
                    }
                    onContinue()
                }) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    private func calculateAge(from date: Date) -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: date, to: Date())
        return ageComponents.year ?? 0
    }
}

// MARK: - Gender Selection Button

struct GenderSelectionButton: View {
    @Environment(\.colorScheme) var colorScheme
    let gender: UserGender
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                Image(systemName: gender.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .purple)
                    .frame(width: 44, height: 44)
                    .background(
                        isSelected
                            ? Color.purple
                            : Color.purple.opacity(colorScheme == .dark ? 0.2 : 0.12)
                    )
                    .cornerRadius(12)

                Text(gender.displayName)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.purple)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Page: Permissions

struct LeanPermissionsPage: View {
    let onBack: () -> Void
    let onContinue: () -> Void

    @State private var notificationsRequested = false
    @State private var notificationsGranted = false
    @State private var healthKitRequested = false
    @State private var healthKitGranted = false
    @EnvironmentObject var healthKitManager: HealthKitManager

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Spacer().frame(height: 30)

                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "gearshape.2.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.accentColor)
                            .padding(.bottom, 8)

                        Text("Enhance Your Experience")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Optional permissions to get the most from NutraSafe")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    // Notifications - with more detail
                    PermissionCardDetailed(
                        icon: "bell.badge.fill",
                        iconColor: .orange,
                        title: "Notifications",
                        benefits: [
                            "Food expiry reminders before items go bad",
                            "Fasting stage updates & completion alerts",
                            "Weekly nutrition summaries"
                        ],
                        isRequested: notificationsRequested,
                        isGranted: notificationsGranted,
                        onEnable: { requestNotifications() },
                        onSkip: { notificationsRequested = true }
                    )
                    .padding(.horizontal, 24)

                    // Health - with more detail
                    PermissionCardDetailed(
                        icon: "heart.fill",
                        iconColor: .pink,
                        title: "Apple Health",
                        benefits: [
                            "Sync weight to track progress automatically",
                            "Import steps & active calories burned",
                            "See exercise data alongside nutrition"
                        ],
                        isRequested: healthKitRequested,
                        isGranted: healthKitGranted,
                        onEnable: {
                            Task {
                                await healthKitManager.requestAuthorization()
                                await MainActor.run {
                                    healthKitRequested = true
                                    healthKitGranted = healthKitManager.isAuthorized
                                }
                            }
                        },
                        onSkip: { healthKitRequested = true }
                    )
                    .padding(.horizontal, 24)

                    // Info
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)

                        Text("Both optional • Change anytime in Settings")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)

                    Spacer().frame(height: 20)
                }
            }

            // Navigation
            HStack(spacing: 12) {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                }

                Button(action: onContinue) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .onAppear {
            checkExistingNotificationStatus()
            checkExistingHealthKitStatus()
        }
    }

    private func checkExistingHealthKitStatus() {
        Task {
            await healthKitManager.checkExistingAuthorization()
            await MainActor.run {
                if healthKitManager.isAuthorized {
                    healthKitRequested = true
                    healthKitGranted = true
                }
            }
        }
    }

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                notificationsRequested = true
                notificationsGranted = granted
            }
        }
    }

    private func checkExistingNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .authorized {
                    notificationsRequested = true
                    notificationsGranted = true
                } else if settings.authorizationStatus == .denied {
                    notificationsRequested = true
                    notificationsGranted = false
                }
            }
        }
    }
}

// MARK: - Permission Card with Detailed Benefits

struct PermissionCardDetailed: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let iconColor: Color
    let title: String
    let benefits: [String]
    let isRequested: Bool
    let isGranted: Bool
    let onEnable: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
                    .frame(width: 48, height: 48)
                    .background(iconColor.opacity(colorScheme == .dark ? 0.2 : 0.12))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)

                        if isGranted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                        }
                    }
                }

                Spacer()
            }

            // Benefits list
            VStack(alignment: .leading, spacing: 8) {
                ForEach(benefits, id: \.self) { benefit in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(iconColor)
                            .frame(width: 16)
                            .offset(y: 2)

                        Text(benefit)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.leading, 4)

            // Action buttons
            if isRequested {
                HStack(spacing: 6) {
                    Image(systemName: isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isGranted ? .green : .secondary)
                    Text(isGranted ? "Enabled" : "Not enabled")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isGranted ? .green : .secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isGranted ? Color.green.opacity(0.12) : Color(UIColor.tertiarySystemBackground))
                .cornerRadius(10)
            } else {
                HStack(spacing: 10) {
                    Button(action: onEnable) {
                        Text("Enable")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(iconColor)
                            .cornerRadius(10)
                    }

                    Button(action: onSkip) {
                        Text("Skip")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 60)
                            .frame(height: 44)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Simple Permission Card (for compatibility)

struct PermissionCard: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let isRequested: Bool
    let isGranted: Bool
    let onEnable: () -> Void
    let onSkip: () -> Void

    var body: some View {
        PermissionCardDetailed(
            icon: icon,
            iconColor: iconColor,
            title: title,
            benefits: [description],
            isRequested: isRequested,
            isGranted: isGranted,
            onEnable: onEnable,
            onSkip: onSkip
        )
    }
}

// MARK: - Page: Disclaimer + Email Consent

struct LeanDisclaimerPage: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var emailMarketingConsent: Bool
    let onBack: () -> Void
    let onComplete: () -> Void

    @State private var hasAcceptedDisclaimer = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Spacer().frame(height: 40)

                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                            .padding(.bottom, 8)

                        Text("Before You Start")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Please read and acknowledge")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }

                    // Disclaimer points
                    VStack(spacing: 10) {
                        DisclaimerPoint(
                            icon: "info.circle.fill",
                            text: "NutraSafe helps track nutrition and food safety",
                            color: .accentColor
                        )
                        DisclaimerPoint(
                            icon: "cross.circle.fill",
                            text: "This is NOT medical advice",
                            color: .red,
                            isBold: true
                        )
                        DisclaimerPoint(
                            icon: "eye.fill",
                            text: "Always verify food labels yourself",
                            color: .orange
                        )
                        DisclaimerPoint(
                            icon: "exclamationmark.circle.fill",
                            text: "Nutrition data may vary from actual products",
                            color: .yellow
                        )
                    }
                    .padding(.horizontal, 24)

                    // Required checkbox
                    Button(action: { hasAcceptedDisclaimer.toggle() }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(hasAcceptedDisclaimer ? Color.accentColor : Color.secondary.opacity(0.4), lineWidth: 2)
                                    .frame(width: 24, height: 24)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(hasAcceptedDisclaimer ? Color.accentColor : Color.clear)
                                    )

                                if hasAcceptedDisclaimer {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }

                            Text("I understand this app is for informational purposes only")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)

                            Spacer()
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(hasAcceptedDisclaimer ? Color.accentColor.opacity(0.1) : Color(UIColor.secondarySystemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(hasAcceptedDisclaimer ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1.5)
                            )
                    )
                    .padding(.horizontal, 24)

                    // Divider
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 1)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 4)

                    // Email consent (optional)
                    Button(action: { emailMarketingConsent.toggle() }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(emailMarketingConsent ? Color.accentColor : Color.secondary.opacity(0.4), lineWidth: 2)
                                    .frame(width: 24, height: 24)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(emailMarketingConsent ? Color.accentColor : Color.clear)
                                    )

                                if emailMarketingConsent {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Send me updates & tips")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("Optional • Unsubscribe anytime")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                    }
                    .padding(16)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(14)
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 20)
                }
            }

            // Navigation
            HStack(spacing: 12) {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                }

                Button(action: {
                    if hasAcceptedDisclaimer {
                        onComplete()
                    }
                }) {
                    Text("Let's Go!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(hasAcceptedDisclaimer ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(hasAcceptedDisclaimer ? Color.accentColor : Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(12)
                }
                .disabled(!hasAcceptedDisclaimer)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Disclaimer Point

struct DisclaimerPoint: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let text: String
    let color: Color
    var isBold: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 14, weight: isBold ? .semibold : .regular))
                .foregroundColor(isBold ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(isBold ? color.opacity(colorScheme == .dark ? 0.15 : 0.08) : Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Legacy Components (for compatibility)

struct WelcomeFeatureRow: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        FeatureRow(icon: icon, color: color, title: title, description: description)
    }
}

struct EnhancedPermissionCard: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let iconColor: Color
    let title: String
    let benefits: [String]
    let buttonText: String
    let isRequested: Bool
    let isGranted: Bool
    let onRequest: () -> Void
    let onSkip: () -> Void

    var body: some View {
        PermissionCardDetailed(
            icon: icon,
            iconColor: iconColor,
            title: title,
            benefits: benefits,
            isRequested: isRequested,
            isGranted: isGranted,
            onEnable: onRequest,
            onSkip: onSkip
        )
    }
}

struct DisclaimerRow: View {
    let icon: String
    let text: String
    let color: Color
    var isImportant: Bool = false

    var body: some View {
        DisclaimerPoint(icon: icon, text: text, color: color, isBold: isImportant)
    }
}

struct OnboardingBackground: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Color.adaptiveBackground
    }
}

// MARK: - Preview

#Preview {
    OnboardingView { consent in
    }
    .environmentObject(HealthKitManager.shared)
    .environmentObject(FirebaseManager.shared)
}
