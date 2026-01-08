//
//  OnboardingScreens.swift
//  NutraSafe Beta
//
//  Modern onboarding pages with integrated screenshots
//

import SwiftUI

// MARK: - Scroll Detection Helper
struct ScrollDetector: View {
    let onScrolledToBottom: () -> Void
    @State private var hasTriggered = false

    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: ViewOffsetKey.self, value: geometry.frame(in: .named("scroll")).minY)
                .onPreferenceChange(ViewOffsetKey.self) { offset in
                    // Trigger when this view is visible in the scroll view (offset < screen height)
                    if offset < UIScreen.main.bounds.height && !hasTriggered {
                        hasTriggered = true
                        onScrolledToBottom()
                    }
                }
        }
        .frame(height: 1)
    }
}

struct ViewOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Navigation Buttons Component
struct OnboardingNavigationButtons: View {
    let currentPage: Int
    let totalPages: Int
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            if currentPage > 0 {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
                }
            }

            Button(action: onContinue) {
                HStack {
                    Text(currentPage == 10 ? "Continue to Disclaimer" : "Continue")
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.blue.opacity(0.3), radius: 15, y: 8)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
}

// MARK: - Diary Page with Screenshot
struct DiaryPage: View {
    let currentPage: Int
    let onScrolledToBottom: () -> Void
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                // Title
                VStack(spacing: 8) {
                    Text("Your Food Diary")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Where everything starts")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                }

                // Screenshot mockup
                ScreenshotContainer(imageName: "onboarding-diary")

                // Content
                VStack(alignment: .leading, spacing: 16) {
                    InfoBullet(
                        icon: "magnifyingglass",
                        color: .blue,
                        title: "Add food easily",
                        description: "Search, scan barcodes, or add manually"
                    )

                    InfoBullet(
                        icon: "slider.horizontal.3",
                        color: .green,
                        title: "Choose your serving",
                        description: "Select portion size, pick mealtime, and add instantly"
                    )

                    InfoBullet(
                        icon: "chart.pie.fill",
                        color: .orange,
                        title: "Track automatically",
                        description: "Calories, carbs, fat, protein & one extra macro update live"
                    )

                    WarningCard(
                        text: "Always double-check serving sizes. Different products use different measures, and accurate tracking depends on choosing the right portion."
                    )

                    InfoCard(
                        icon: "gift.fill",
                        text: "The Diary is completely free and built to be fast, simple and reliable."
                    )
                }
                .padding(.horizontal, 24)

                // Navigation buttons
                OnboardingNavigationButtons(
                    currentPage: currentPage,
                    totalPages: 11,
                    onBack: onBack,
                    onContinue: onContinue
                )

                // Scroll detector - triggers when navigation buttons are visible
                ScrollDetector(onScrolledToBottom: onScrolledToBottom)
            }
        }
        .coordinateSpace(name: "scroll")
    }
}

// MARK: - Food Detail Page
struct FoodDetailPage: View {
    let currentPage: Int
    let onScrolledToBottom: () -> Void
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                VStack(spacing: 8) {
                    Text("Food Detail Page")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)

                    Text("See everything about what you eat")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                }

                // Screenshot mockup
                ScreenshotContainer(imageName: "onboarding-food-detail")

                VStack(alignment: .leading, spacing: 16) {
                    InfoBullet(
                        icon: "info.circle.fill",
                        color: .blue,
                        title: "Complete nutrition",
                        description: "Tap any food to see calories, macros and full ingredients"
                    )

                    InfoBullet(
                        icon: "sparkles",
                        color: .purple,
                        title: "Additive information",
                        description: "We highlight additives and explain what they are and why they're used"
                    )

                    InfoBullet(
                        icon: "exclamationmark.triangle.fill",
                        color: .red,
                        title: "Allergen alerts",
                        description: "Clear warnings if we detect your allergens (set in Settings)"
                    )

                    InfoBullet(
                        icon: "leaf.fill",
                        color: .green,
                        title: "Vitamins & minerals",
                        description: "View natural vitamins and minerals in each food"
                    )

                    WarningCard(
                        text: "Important: This is an additional tool only. Always read packaging yourself, especially if you have allergies or medical conditions. Technology is never 100% reliable."
                    )
                }
                .padding(.horizontal, 24)

                // Navigation buttons
                OnboardingNavigationButtons(
                    currentPage: currentPage,
                    totalPages: 11,
                    onBack: onBack,
                    onContinue: onContinue
                )

                // Scroll detector - triggers when navigation buttons are visible
                ScrollDetector(onScrolledToBottom: onScrolledToBottom)
            }
        }
        .coordinateSpace(name: "scroll")
    }
}

// MARK: - Nutrients Page
struct NutrientsPage: View {
    let currentPage: Int
    let onScrolledToBottom: () -> Void
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                VStack(spacing: 8) {
                    Text("Nutrients")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)

                    Text("7-day overview of your nutrition")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                }

                // Screenshot mockup
                ScreenshotContainer(imageName: "onboarding-nutrients")

                VStack(alignment: .leading, spacing: 16) {
                    InfoBullet(
                        icon: "chart.bar.fill",
                        color: .green,
                        title: "Weekly tracking",
                        description: "See which vitamins and minerals regularly appear in your diet over 7 days"
                    )

                    InfoBullet(
                        icon: "circle.fill",
                        color: .blue,
                        title: "Visual indicators",
                        description: "Low, moderate or strong presence shown with clear color coding"
                    )

                    InfoCard(
                        icon: "info.circle.fill",
                        text: "This is a helpful awareness tool, not a medical assessment. Most foods don't publish exact vitamin/mineral amounts, so this feature focuses on presence and patterns rather than precise quantities."
                    )
                }
                .padding(.horizontal, 24)

                // Navigation buttons
                OnboardingNavigationButtons(
                    currentPage: currentPage,
                    totalPages: 11,
                    onBack: onBack,
                    onContinue: onContinue
                )

                // Scroll detector - triggers when navigation buttons are visible
                ScrollDetector(onScrolledToBottom: onScrolledToBottom)
            }
        }
        .coordinateSpace(name: "scroll")
    }
}

// MARK: - Reactions Page
struct ReactionsPage: View {
    let currentPage: Int
    let onScrolledToBottom: () -> Void
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                VStack(spacing: 8) {
                    Text("Track Reactions")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Monitor how foods affect you")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                }

                // Screenshot mockup
                ScreenshotContainer(imageName: "onboarding-reactions")

                VStack(alignment: .leading, spacing: 16) {
                    InfoBullet(
                        icon: "note.text",
                        color: .orange,
                        title: "Log symptoms",
                        description: "Record the food, symptoms, severity and any notes"
                    )

                    InfoBullet(
                        icon: "list.bullet",
                        color: .blue,
                        title: "Automatic ingredient tracking",
                        description: "We pull the food's ingredients to help identify potential links"
                    )

                    WarningCard(
                        text: "Warning: This feature can guide you toward possible patterns but cannot diagnose allergies or intolerances. If you experience serious or ongoing symptoms, always speak to a healthcare professional."
                    )
                }
                .padding(.horizontal, 24)

                // Navigation buttons
                OnboardingNavigationButtons(
                    currentPage: currentPage,
                    totalPages: 11,
                    onBack: onBack,
                    onContinue: onContinue
                )

                // Scroll detector - triggers when navigation buttons are visible
                ScrollDetector(onScrolledToBottom: onScrolledToBottom)
            }
        }
        .coordinateSpace(name: "scroll")
    }
}

// MARK: - Patterns Page
struct PatternsPage: View {
    let currentPage: Int
    let onScrolledToBottom: () -> Void
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                VStack(spacing: 8) {
                    Text("Pattern Analysis")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Identify problem ingredients")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                }

                // Screenshot mockup
                ScreenshotContainer(imageName: "onboarding-patterns")

                VStack(alignment: .leading, spacing: 16) {
                    InfoBullet(
                        icon: "sparkles",
                        color: .purple,
                        title: "Smart detection",
                        description: "After 3+ reactions, we highlight ingredients that repeatedly appear"
                    )

                    InfoBullet(
                        icon: "doc.text.fill",
                        color: .blue,
                        title: "Reaction Report",
                        description: "Generate PDF with recent reaction, 7-day diary, last 5 reactions & patterns"
                    )

                    InfoBullet(
                        icon: "person.2.fill",
                        color: .green,
                        title: "Share with professionals",
                        description: "Useful to show GP, dietitian or allergy specialist"
                    )

                    InfoCard(
                        icon: "info.circle.fill",
                        text: "This can be useful to share with healthcare professionals — but it should never replace professional medical advice or testing."
                    )
                }
                .padding(.horizontal, 24)

                // Navigation buttons
                OnboardingNavigationButtons(
                    currentPage: currentPage,
                    totalPages: 11,
                    onBack: onBack,
                    onContinue: onContinue
                )

                // Scroll detector - triggers when navigation buttons are visible
                ScrollDetector(onScrolledToBottom: onScrolledToBottom)
            }
        }
        .coordinateSpace(name: "scroll")
    }
}

// MARK: - Fasting Page with Screenshot
struct FastingPage: View {
    let currentPage: Int
    let onScrolledToBottom: () -> Void
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                VStack(spacing: 8) {
                    Text("Fasting")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Structured fasting support")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                }

                // Screenshot mockup
                ScreenshotContainer(imageName: "onboarding-fasting")

                VStack(alignment: .leading, spacing: 16) {
                    InfoBullet(
                        icon: "calendar",
                        color: .blue,
                        title: "Set your plan",
                        description: "Choose fasting days, start time and reminder preferences"
                    )

                    InfoBullet(
                        icon: "bell.fill",
                        color: .orange,
                        title: "Auto-start & notifications",
                        description: "Your fast starts automatically and you'll get stage updates"
                    )

                    WarningCard(
                        text: "NutraSafe is here to support structured fasting, but if you have health conditions or concerns, check with a professional before starting any fasting routine."
                    )
                }
                .padding(.horizontal, 24)

                // Navigation buttons
                OnboardingNavigationButtons(
                    currentPage: currentPage,
                    totalPages: 11,
                    onBack: onBack,
                    onContinue: onContinue
                )

                // Scroll detector - triggers when navigation buttons are visible
                ScrollDetector(onScrolledToBottom: onScrolledToBottom)
            }
        }
        .coordinateSpace(name: "scroll")
    }
}

// MARK: - Progress Page
struct ProgressPage: View {
    let currentPage: Int
    let onScrolledToBottom: () -> Void
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                VStack(spacing: 8) {
                    Text("Progress")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Track real change over time")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                }

                // Screenshot mockup
                ScreenshotContainer(imageName: "onboarding-progress")

                VStack(alignment: .leading, spacing: 16) {
                    InfoBullet(
                        icon: "scalemass.fill",
                        color: .blue,
                        title: "Weight tracking",
                        description: "Log your weight regularly to see trends"
                    )

                    InfoBullet(
                        icon: "ruler.fill",
                        color: .purple,
                        title: "Body measurements",
                        description: "Record measurements for complete tracking"
                    )

                    InfoBullet(
                        icon: "camera.fill",
                        color: .green,
                        title: "Progress photos",
                        description: "Build a visual timeline of your transformation"
                    )

                    InfoCard(
                        icon: "heart.fill",
                        text: "This is your personal space to understand your journey at your own pace."
                    )
                }
                .padding(.horizontal, 24)

                // Navigation buttons
                OnboardingNavigationButtons(
                    currentPage: currentPage,
                    totalPages: 11,
                    onBack: onBack,
                    onContinue: onContinue
                )

                // Scroll detector - triggers when navigation buttons are visible
                ScrollDetector(onScrolledToBottom: onScrolledToBottom)
            }
        }
        .coordinateSpace(name: "scroll")
    }
}

// MARK: - Apple Health Permissions Page
struct HealthPermissionsPage: View {
    let currentPage: Int
    let onScrolledToBottom: () -> Void
    let onBack: () -> Void
    let onContinue: () -> Void
    @State private var userAction: HealthPermissionAction = .none
    @EnvironmentObject var healthKitManager: HealthKitManager

    enum HealthPermissionAction {
        case none, requested, skipped
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                VStack(spacing: 8) {
                    Text("Apple Health")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Connect for better tracking")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                }

                // Apple Health icon
                ZStack {
                    Circle()
                        .fill(Color.pink.opacity(0.15))
                        .frame(width: 120, height: 120)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.pink)
                }
                .padding(.vertical, 20)

                VStack(alignment: .leading, spacing: 16) {
                    InfoBullet(
                        icon: "scalemass.fill",
                        color: .blue,
                        title: "Sync your weight",
                        description: "Automatically pull weight data from Apple Health"
                    )

                    InfoBullet(
                        icon: "flame.fill",
                        color: .orange,
                        title: "Track calories burned",
                        description: "See exercise calories in your daily nutrition totals"
                    )

                    InfoBullet(
                        icon: "arrow.triangle.2.circlepath",
                        color: .green,
                        title: "Two-way sync",
                        description: "Weight you log in NutraSafe can also save to Apple Health"
                    )

                    InfoCard(
                        icon: "hand.raised.fill",
                        text: "You can skip this step and enable Apple Health later in Settings. Permissions are optional and you control what data is shared."
                    )
                }
                .padding(.horizontal, 24)

                // Request permissions button or confirmation
                if userAction == .none {
                    VStack(spacing: 12) {
                        Button(action: {
                            Task {
                                await healthKitManager.requestAuthorization()
                                userAction = .requested
                                onScrolledToBottom()
                            }
                        }) {
                            HStack {
                                Image(systemName: "heart.fill")
                                Text("Connect Apple Health")
                            }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: [.pink, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.pink.opacity(0.3), radius: 15, y: 8)
                        }

                        // Skip button
                        Button(action: {
                            userAction = .skipped
                            onScrolledToBottom()
                        }) {
                            Text("Skip for now")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                } else {
                    HStack(spacing: 12) {
                        Image(systemName: userAction == .requested ? "checkmark.circle.fill" : "arrow.forward.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(userAction == .requested ? .green : .secondary)
                        Text(userAction == .requested ? "Permissions requested" : "Skipped - can enable later in Settings")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }

                // Navigation buttons
                OnboardingNavigationButtons(
                    currentPage: currentPage,
                    totalPages: 11,
                    onBack: onBack,
                    onContinue: onContinue
                )

                // Invisible scroll detector (auto-triggered if action taken)
                Color.clear
                    .frame(height: 1)
                    .onAppear {
                        if userAction != .none {
                            onScrolledToBottom()
                        }
                    }
            }
        }
        .coordinateSpace(name: "scroll")
    }
}

// MARK: - Use By Page
struct UseByPage: View {
    let currentPage: Int
    let onScrolledToBottom: () -> Void
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                VStack(spacing: 8) {
                    Text("Use By")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Never waste food again")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                }

                // Screenshot mockup
                ScreenshotContainer(imageName: "onboarding-useby")

                VStack(alignment: .leading, spacing: 16) {
                    InfoBullet(
                        icon: "calendar.badge.clock",
                        color: .orange,
                        title: "Track opened items",
                        description: "Add items when you open them with their \"use within\" timeframe"
                    )

                    InfoBullet(
                        icon: "bell.fill",
                        color: .red,
                        title: "Smart reminders",
                        description: "Get notified before food becomes unsafe"
                    )

                    InfoBullet(
                        icon: "camera.fill",
                        color: .blue,
                        title: "Photo identification",
                        description: "Add photos for quick visual reference"
                    )

                    WarningCard(
                        text: "Important: Always follow packaging instructions and food safety guidelines. This feature supports you, but it is not a replacement for proper storage or common-sense checks."
                    )
                }
                .padding(.horizontal, 24)

                // Navigation buttons
                OnboardingNavigationButtons(
                    currentPage: currentPage,
                    totalPages: 11,
                    onBack: onBack,
                    onContinue: onContinue
                )

                // Scroll detector - triggers when navigation buttons are visible
                ScrollDetector(onScrolledToBottom: onScrolledToBottom)
            }
        }
        .coordinateSpace(name: "scroll")
    }
}

// MARK: - Final Message Page
struct FinalMessagePage: View {
    let currentPage: Int
    let onScrolledToBottom: () -> Void
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer().frame(height: 40)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 16) {
                    Text("You're Ready!")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("You now know how NutraSafe works")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 16) {
                    CheckItem(text: "Log food with multiple methods")
                    CheckItem(text: "View detailed nutrition & allergen info")
                    CheckItem(text: "Track vitamins and minerals automatically")
                    CheckItem(text: "Monitor food reactions & patterns")
                    CheckItem(text: "Time fasts & track progress")
                    CheckItem(text: "Manage food expiry dates")
                }
                .padding(.horizontal, 32)

                InfoCard(
                    icon: "exclamationmark.triangle.fill",
                    text: "Before you start, there's one important health disclaimer you need to review and accept."
                )
                .padding(.horizontal, 24)

                // Navigation buttons
                OnboardingNavigationButtons(
                    currentPage: currentPage,
                    totalPages: 11,
                    onBack: onBack,
                    onContinue: onContinue
                )

                // Invisible scroll detector
                Color.clear
                    .frame(height: 1)
                    .onAppear { onScrolledToBottom() }
            }
        }
    }
}

// MARK: - Email Consent Page (GDPR-compliant)
struct EmailConsentPage: View {
    @Binding var hasConsented: Bool
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer().frame(height: 40)

                // Email icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 120, height: 120)

                    Image(systemName: "envelope.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                }

                VStack(spacing: 16) {
                    Text("Stay Updated")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    Text("Get the latest features and tips")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                }

                // Info about what they'll receive
                VStack(alignment: .leading, spacing: 16) {
                    InfoBullet(
                        icon: "sparkles",
                        color: .blue,
                        title: "New features",
                        description: "Be first to know about app updates and improvements"
                    )

                    InfoBullet(
                        icon: "lightbulb.fill",
                        color: .orange,
                        title: "Health tips",
                        description: "Occasional nutrition insights and guidance"
                    )

                    InfoBullet(
                        icon: "gift.fill",
                        color: .purple,
                        title: "Special offers",
                        description: "Exclusive deals and early access to premium features"
                    )
                }
                .padding(.horizontal, 24)

                // Privacy info card
                InfoCard(
                    icon: "lock.shield.fill",
                    text: "We respect your privacy. You can unsubscribe anytime from Settings or from any email we send. We'll never share your email with third parties."
                )
                .padding(.horizontal, 24)

                // GDPR-compliant consent checkbox (NOT pre-checked)
                Button(action: { hasConsented.toggle() }) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(hasConsented ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                                .frame(width: 32, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(hasConsented ? Color.blue : Color.clear)
                                )

                            if hasConsented {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }

                        Text("I'd like to receive emails about updates and offers")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
                .padding(.horizontal, 24)

                // Continue button (always enabled - consent is optional)
                Button(action: onContinue) {
                    HStack {
                        Text(hasConsented ? "Continue with emails" : "Continue without emails")
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.blue.opacity(0.3), radius: 15, y: 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Disclaimer Page (Dedicated Final Page)
struct DisclaimerPage: View {
    @State private var hasAccepted = false
    let onAccept: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer().frame(height: 40)

                // Warning icon
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 120, height: 120)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                }

                VStack(spacing: 16) {
                    Text("Important Health Information")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    Text("Please read carefully")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                }

                // Disclaimer points
                VStack(alignment: .leading, spacing: 20) {
                    DisclaimerBullet(
                        number: "1",
                        text: "NutraSafe is designed to help you track nutrition and identify potential food safety concerns."
                    )

                    DisclaimerBullet(
                        number: "2",
                        text: "This app is NOT a substitute for professional medical advice, diagnosis, or treatment.",
                        isImportant: true
                    )

                    DisclaimerBullet(
                        number: "3",
                        text: "Always verify food labels yourself and consult healthcare professionals for medical decisions."
                    )

                    DisclaimerBullet(
                        number: "4",
                        text: "Results cannot be guaranteed to be 100% accurate."
                    )
                }
                .padding(.horizontal, 24)

                // Acceptance checkbox
                Button(action: { hasAccepted.toggle() }) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(hasAccepted ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                                .frame(width: 32, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(hasAccepted ? Color.blue : Color.clear)
                                )

                            if hasAccepted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }

                        Text("I understand and agree to use this app as an informational tool only")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
                .padding(.horizontal, 24)

                // Get Started button
                Button(action: {
                    if hasAccepted {
                        onAccept()
                    }
                }) {
                    HStack {
                        Text("Get Started")
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(hasAccepted ? .white : .gray)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Group {
                            if hasAccepted {
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            } else {
                                Color.gray.opacity(0.2)
                            }
                        }
                    )
                    .cornerRadius(16)
                    .shadow(color: hasAccepted ? Color.blue.opacity(0.3) : Color.clear, radius: 15, y: 8)
                }
                .disabled(!hasAccepted)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Reusable Components

struct InfoBullet: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }
}

struct InfoCard: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.blue.opacity(0.08))
        .cornerRadius(12)
    }
}

struct WarningCard: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundColor(.orange)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.orange.opacity(0.08))
        .cornerRadius(12)
    }
}

struct CheckItem: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.green)

            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DisclaimerBullet: View {
    let number: String
    let text: String
    var isImportant: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(number)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isImportant ? [.red, .orange] : [.blue, .blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

            Text(text)
                .font(.system(size: 16, weight: isImportant ? .semibold : .regular))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }
}

struct ScreenshotContainer: View {
    let imageName: String

    var body: some View {
        Group {
            // Try to load image, show placeholder if not found
            if UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(28)
                    .shadow(color: Color.black.opacity(0.15), radius: 30, y: 15)
            } else {
                // Placeholder when image not yet added
                VStack(spacing: 12) {
                    Image(systemName: "photo")
                        .font(.system(size: 70))
                        .foregroundColor(.gray.opacity(0.3))
                    Text("Add '\(imageName)' to Assets")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(height: 520)
            }
        }
        .padding(.horizontal, 20)
    }
}
