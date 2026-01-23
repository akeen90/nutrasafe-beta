//
//  PremiumOnboardingView.swift
//  NutraSafe Beta
//
//  Premium onboarding flow with emotional journey and extended setup
//  Flow: Breath → Mirror → Processing → Synthesis → Promise →
//        Goals → GoalsProcessing → Activity → ActivityProcessing →
//        Habits → Experience → ProfileBuilding →
//        PersonalDetails → DietSetup → CalorieTarget →
//        Sensitivities → Camera → Health → Notifications →
//        ProUpgrade → Honesty → Completion
//  Note: PersonalDetails comes BEFORE CalorieTarget for proper BMR calculation
//

import SwiftUI
import UserNotifications
import AVFoundation

// MARK: - Main Premium Onboarding View

struct PremiumOnboardingView: View {
    @StateObject private var state = PremiumOnboardingState()
    @State private var currentScreen = 0
    @State private var transitionOpacity: Double = 1
    @State private var showingPaywall = false
    @EnvironmentObject var healthKitManager: HealthKitManager

    let onComplete: (Bool) -> Void

    // Total screens (0-22) - added FeatureBenefits after GoalsProcessing
    private let totalScreens = 23

    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground(palette: state.palette)

            // Screen content
            Group {
                switch currentScreen {
                case 0:
                    BreathScreen(palette: state.palette, onContinue: { advanceScreen() })
                case 1:
                    MirrorScreen(state: state, onContinue: { advanceScreen() })
                case 2:
                    ProcessingScreen(state: state, onComplete: { advanceScreen() })
                case 3:
                    SynthesisScreen(state: state, onComplete: { advanceScreen() })
                case 4:
                    PromiseScreen(state: state, onContinue: { advanceScreen() })
                case 5:
                    // Goals - What brings you to NutraSafe?
                    GoalsScreen(state: state, onContinue: { advanceScreen() })
                case 6:
                    // Goals Processing - "Mapping your goals..."
                    GoalsProcessingScreen(state: state, onComplete: { advanceScreen() })
                case 7:
                    // Feature Benefits - Show how app helps with selected goals
                    FeatureBenefitsScreen(state: state, onContinue: { advanceScreen() })
                case 8:
                    // Activity Level
                    ActivityLevelScreen(state: state, onContinue: { advanceScreen() })
                case 9:
                    // Activity Processing - "Calculating your needs..."
                    ActivityProcessingScreen(state: state, onComplete: { advanceScreen() })
                case 10:
                    // Eating Habits
                    EatingHabitsScreen(state: state, onContinue: { advanceScreen() })
                case 11:
                    // Diet Experience
                    DietExperienceScreen(state: state, onContinue: { advanceScreen() })
                case 12:
                    // Profile Building - "Building your profile..."
                    ProfileBuildingScreen(state: state, onComplete: { advanceScreen() })
                case 13:
                    // Personal Details (DOB, height, weight, gender) - BEFORE calorie target for BMR calculation
                    PersonalDetailsScreen(state: state, onContinue: { advanceScreen() }, onBack: { goBackScreen() })
                case 14:
                    // Diet Setup - Choose eating approach
                    DietSetupScreen(
                        state: state,
                        onContinue: { advanceScreen() },
                        onSkip: { advanceScreen() },
                        onBack: { goBackScreen() }
                    )
                case 15:
                    // Calorie Target - Daily calorie goal (now has height/weight/age from step 13)
                    CalorieTargetScreen(
                        state: state,
                        onContinue: { advanceScreen() },
                        onSkip: { advanceScreen() },
                        onBack: { goBackScreen() }
                    )
                case 16:
                    // Sensitivities (UK/EU Allergens + Preferences)
                    SensitivitiesScreen(state: state, onContinue: { advanceScreen() })
                case 17:
                    // Camera Permission
                    CameraPermissionScreen(state: state, onContinue: { advanceScreen() })
                case 18:
                    // Apple Health Permission
                    HealthPermissionScreen(state: state, onContinue: { advanceScreen() })
                        .environmentObject(healthKitManager)
                case 19:
                    // Notifications Permission
                    NotificationsPermissionScreen(state: state, onContinue: { advanceScreen() })
                case 20:
                    // Pro Upgrade CTA
                    ProUpgradeScreen(
                        state: state,
                        onUpgrade: { showingPaywall = true },
                        onContinueFree: { advanceScreen() }
                    )
                case 21:
                    // Honesty/Disclaimer screen
                    HonestyScreen(state: state, onContinue: { advanceScreen() })
                case 22:
                    // Completion screen
                    OnboardingCompletionScreen(state: state, onComplete: {
                        state.saveToManager()
                        OnboardingManager.shared.acceptDisclaimer()
                        OnboardingManager.shared.completeOnboarding()
                        onComplete(state.emailConsent)
                    })
                default:
                    BreathScreen(palette: state.palette, onContinue: { advanceScreen() })
                }
            }
            .opacity(transitionOpacity)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
                .onDisappear {
                    // Continue to next screen after paywall closes
                    advanceScreen()
                }
        }
        .onAppear {
            AnalyticsManager.shared.trackOnboardingStep(step: currentScreen, stepName: screenName(currentScreen))
        }
        .onChange(of: currentScreen) { _, newScreen in
            AnalyticsManager.shared.trackOnboardingStep(step: newScreen, stepName: screenName(newScreen))
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

    private func goBackScreen() {
        guard currentScreen > 0 else { return }

        withAnimation(.easeOut(duration: 0.3)) {
            transitionOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentScreen -= 1
            withAnimation(.easeIn(duration: 0.4)) {
                transitionOpacity = 1
            }
        }
    }

    private func screenName(_ screen: Int) -> String {
        switch screen {
        case 0: return "Breath"
        case 1: return "Mirror"
        case 2: return "Processing"
        case 3: return "Synthesis"
        case 4: return "Promise"
        case 5: return "Goals"
        case 6: return "GoalsProcessing"
        case 7: return "FeatureBenefits"
        case 8: return "ActivityLevel"
        case 9: return "ActivityProcessing"
        case 10: return "EatingHabits"
        case 11: return "DietExperience"
        case 12: return "ProfileBuilding"
        case 13: return "PersonalDetails"
        case 14: return "DietSetup"
        case 15: return "CalorieTarget"
        case 16: return "Sensitivities"
        case 17: return "CameraPermission"
        case 18: return "HealthPermission"
        case 19: return "NotificationPermission"
        case 20: return "ProUpgrade"
        case 21: return "Honesty"
        case 22: return "Completion"
        default: return "Unknown"
        }
    }
}

// MARK: - Screen 1: The Breath (Opening)

struct BreathScreen: View {
    let palette: OnboardingPalette
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Headline
            VStack(spacing: 12) {
                Text("Your body")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))

                Text("already knows.")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))
            }
            .padding(.bottom, 40)

            // Breathing blob
            BreathingBlob(palette: palette)
                .frame(height: 280)

            // Subtext
            Text("We're here to help you listen.")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(Color(white: 0.4))
                .italic()
                .padding(.top, 40)

            Spacer()

            // Begin button
            Button(action: onContinue) {
                Text("Begin")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(palette.accent)
                    )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Screen 2: The Mirror (Intent Selection)

struct MirrorScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // Headline
            VStack(spacing: 8) {
                Text("What would change")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))

                Text("if you truly understood")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))

                Text("what you eat?")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)

            // Subtext
            Text("Choose what resonates most.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(white: 0.5))
                .padding(.top, 12)

            Spacer().frame(height: 40)

            // Intent cards
            VStack(spacing: 16) {
                ForEach(UserIntent.allCases, id: \.rawValue) { intent in
                    IntentCard(
                        intent: intent,
                        isSelected: state.selectedIntent == intent,
                        palette: OnboardingPalette.forIntent(intent),
                        onSelect: {
                            withAnimation(.easeOut(duration: 0.3)) {
                                state.selectedIntent = intent
                            }
                            // Auto-advance after selection
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                onContinue()
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

struct IntentCard: View {
    let intent: UserIntent
    let isSelected: Bool
    let palette: OnboardingPalette
    let onSelect: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Abstract mark
                IntentMark(intent: intent, size: 44, palette: palette)
                    .frame(width: 44, height: 44)

                // Text
                Text(intent.headline)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(white: 0.3))

                Spacer()

                // Selection indicator
                if isSelected {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isSelected
                            ? LinearGradient(colors: [palette.primary, palette.secondary], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color.white.opacity(0.8), Color.white.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: isSelected ? palette.primary.opacity(0.3) : Color.black.opacity(0.05), radius: isSelected ? 15 : 5, y: isSelected ? 5 : 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeOut(duration: 0.1), value: isPressed)
    }
}

// MARK: - Screen 3: The Processing (First Understanding Moment)

struct ProcessingScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    let onComplete: () -> Void

    @State private var showRipples = false

    var body: some View {
        VStack {
            Spacer()

            // "Listening..." text
            Text("Listening...")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(state.palette.primary)
                .opacity(showRipples ? 1 : 0)

            Spacer().frame(height: 60)

            // Animated mark with ripples
            ZStack {
                if showRipples {
                    RippleEffect(palette: state.palette)
                }

                if let intent = state.selectedIntent {
                    IntentMark(intent: intent, size: 80, palette: state.palette)
                        .scaleEffect(showRipples ? 1 : 0.5)
                        .opacity(showRipples ? 1 : 0)
                }
            }
            .frame(height: 300)

            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showRipples = true
            }

            // Auto-advance after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onComplete()
            }
        }
    }
}

// MARK: - Screen 4: The Depth (Sensitivities Selection)

struct DepthScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    let onContinue: () -> Void

    let sensitivities = FoodSensitivity.allCases

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // Headline
            VStack(spacing: 8) {
                Text("Is there anything")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))

                Text("your body reacts to?")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))
            }

            Text("Tap anything that applies.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(white: 0.5))
                .padding(.top, 12)

            Spacer().frame(height: 30)

            // Floating sensitivity tags
            ScrollView(showsIndicators: false) {
                OnboardingFlowLayout(spacing: 10) {
                    ForEach(sensitivities) { sensitivity in
                        SensitivityTag(
                            sensitivity: sensitivity,
                            isSelected: state.selectedSensitivities.contains(sensitivity),
                            palette: state.palette,
                            onToggle: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    if sensitivity.isNone {
                                        // Clear all and select "Nothing specific"
                                        state.selectedSensitivities.removeAll()
                                        state.selectedSensitivities.insert(sensitivity)
                                    } else {
                                        // Remove "Nothing specific" if selecting something else
                                        state.selectedSensitivities.remove(.nothingSpecific)

                                        if state.selectedSensitivities.contains(sensitivity) {
                                            state.selectedSensitivities.remove(sensitivity)
                                        } else {
                                            state.selectedSensitivities.insert(sensitivity)
                                        }
                                    }
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(maxHeight: 350)

            Spacer()

            // Continue button
            PremiumButton(
                text: "Continue",
                palette: state.palette,
                action: onContinue,
                isEnabled: !state.selectedSensitivities.isEmpty
            )
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }
}

struct SensitivityTag: View {
    let sensitivity: FoodSensitivity
    let isSelected: Bool
    let palette: OnboardingPalette
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            Text(sensitivity.rawValue)
                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : Color(white: 0.4))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? palette.primary : Color.white.opacity(0.7))
                        .shadow(color: isSelected ? palette.primary.opacity(0.3) : Color.black.opacity(0.05), radius: isSelected ? 8 : 3, y: 2)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Flow Layout for scattered tags
struct OnboardingFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Screen 5: The Synthesis (Second Understanding Moment)

struct SynthesisScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    let onComplete: () -> Void

    @State private var mergeProgress: CGFloat = 0
    @State private var showLens = false

    var body: some View {
        VStack {
            Spacer()

            // Headline
            Text("Building your lens...")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(state.palette.primary)
                .opacity(mergeProgress > 0 ? 1 : 0)

            Text("Every choice shapes how we see food for you.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(white: 0.5))
                .padding(.top, 8)
                .opacity(mergeProgress > 0.5 ? 1 : 0)

            Spacer().frame(height: 60)

            // Merging animation
            ZStack {
                if !showLens {
                    // Intent mark
                    if let intent = state.selectedIntent {
                        IntentMark(intent: intent, size: 60, palette: state.palette)
                            .offset(x: -50 + mergeProgress * 50, y: -30 + mergeProgress * 30)
                            .opacity(1 - mergeProgress)
                    }

                    // Sensitivity cluster
                    Circle()
                        .fill(state.palette.accent.opacity(0.5))
                        .frame(width: 40, height: 40)
                        .offset(x: 50 - mergeProgress * 50, y: 30 - mergeProgress * 30)
                        .opacity(1 - mergeProgress)
                } else {
                    // Personal lens emerges
                    PersonalLens(
                        intent: state.selectedIntent,
                        sensitivities: state.selectedSensitivities,
                        size: 120
                    )
                    .scaleEffect(showLens ? 1 : 0.5)
                    .opacity(showLens ? 1 : 0)
                }

                // Bloom effect at merge point
                Circle()
                    .fill(state.palette.primary.opacity(0.3))
                    .frame(width: 100 * mergeProgress, height: 100 * mergeProgress)
                    .blur(radius: 20)
                    .opacity(mergeProgress > 0.8 && !showLens ? 1 : 0)
            }
            .frame(height: 200)

            Spacer()
        }
        .onAppear {
            // Merge animation
            withAnimation(.easeInOut(duration: 2)) {
                mergeProgress = 1
            }

            // Show lens after merge
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showLens = true
                }
            }

            // Auto-advance
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                onComplete()
            }
        }
    }
}

// MARK: - Screen 6: The Promise (Personalized Reveal)

struct PromiseScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    let onContinue: () -> Void

    @State private var showMessage = false
    @State private var showButton = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)

            // Personal lens (small, top-right)
            HStack {
                Spacer()
                PersonalLens(
                    intent: state.selectedIntent,
                    sensitivities: state.selectedSensitivities,
                    size: 50
                )
                .padding(.trailing, 24)
            }

            Spacer().frame(height: 40)

            // Headline
            VStack(spacing: 8) {
                Text("Here's how NutraSafe")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))

                Text("will work for you.")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

            Spacer().frame(height: 40)

            // Personalized message with typewriter effect
            if showMessage {
                TypewriterText(text: state.personalizedMessage, palette: state.palette)
                    .padding(.horizontal, 32)
                    .frame(minHeight: 120)
            }

            Spacer()

            // Continue button (appears after message)
            if showButton {
                PremiumButton(
                    text: "Continue",
                    palette: state.palette,
                    action: onContinue
                )
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            // Start typewriter after brief pause
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showMessage = true
            }

            // Show button after message completes
            let messageLength = state.personalizedMessage.count
            let delay = 0.5 + Double(messageLength) * 0.03 + 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showButton = true
                }
            }
        }
    }
}

// MARK: - Screen 7: The Access (Camera Permission) - LEGACY (replaced by CameraPermissionScreen)
// Kept for reference but no longer used in the main flow

// MARK: - Screen 8: The Honesty (Disclaimer)

struct HonestyScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 80)

            // Headline
            Text("We're here to inform,")
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundColor(Color(white: 0.2))

            Text("not diagnose.")
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundColor(Color(white: 0.2))

            Spacer().frame(height: 40)

            // Disclaimer text with vertical accent line
            HStack(alignment: .top, spacing: 16) {
                // Vertical accent line
                Rectangle()
                    .fill(state.palette.primary.opacity(0.5))
                    .frame(width: 3)

                // Text
                VStack(alignment: .leading, spacing: 16) {
                    Text("NutraSafe is a quick reference to help you explore food—ingredients, allergens, nutrition.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color(white: 0.4))
                        .lineSpacing(4)

                    Text("We're a companion to your choices, not a replacement for medical advice.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color(white: 0.4))
                        .lineSpacing(4)

                    Text("Ingredient data may be incomplete, outdated, or vary by region—always check the label before you eat, especially with allergies.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color(white: 0.4))
                        .lineSpacing(4)

                    Text("If you have serious allergies or health conditions, always consult your doctor.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(white: 0.3))
                        .lineSpacing(4)
                }
            }
            .padding(.horizontal, 32)

            Spacer().frame(height: 40)

            // Acknowledgment checkbox
            Button(action: {
                withAnimation(.easeOut(duration: 0.2)) {
                    state.hasAcceptedDisclaimer.toggle()
                }
            }) {
                HStack(spacing: 14) {
                    // Custom checkbox
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(state.hasAcceptedDisclaimer ? state.palette.primary : Color(white: 0.7), lineWidth: 2)
                            .frame(width: 26, height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(state.hasAcceptedDisclaimer ? state.palette.primary : Color.clear)
                            )

                        if state.hasAcceptedDisclaimer {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }

                    Text("I understand")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(white: 0.3))
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 32)

            Spacer()

            // Continue button
            PremiumButton(
                text: "Continue",
                palette: state.palette,
                action: onContinue,
                isEnabled: state.hasAcceptedDisclaimer
            )
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Screen 9: The Threshold (Final Launch) - LEGACY (replaced by OnboardingCompletionScreen)
// Kept for reference but no longer used in the main flow

// MARK: - Pre-Auth Premium Onboarding View
// This version runs BEFORE sign-up and SKIPS permission screens
// Permissions are requested after the user creates an account

struct PreAuthPremiumOnboardingView: View {
    @StateObject private var state = PremiumOnboardingState()
    @State private var currentScreen = 0
    @State private var transitionOpacity: Double = 1
    @EnvironmentObject var healthKitManager: HealthKitManager

    let onComplete: (Bool) -> Void

    // Pre-auth flow: Skip permission screens AND paywall (paywall shown post-auth after permissions)
    // Flow: Breath(0) → Mirror(1) → Processing(2) → Synthesis(3) → Promise(4) →
    //       Goals(5) → GoalsProcessing(6) → FeatureBenefits(7) → Activity(8) → ActivityProcessing(9) →
    //       Habits(10) → Experience(11) → ProfileBuilding(12) →
    //       PersonalDetails(13) → DietSetup(14) → CalorieTarget(15) →
    //       Sensitivities(16) → Honesty(17) → Completion(18)
    // Note: PersonalDetails moved BEFORE CalorieTarget for proper BMR calculation
    // Note: ProUpgrade/Paywall moved to PostAuthPermissionsView (after permissions, before entering app)
    private let totalScreens = 19

    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground(palette: state.palette)

            // Screen content
            Group {
                switch currentScreen {
                case 0:
                    BreathScreen(palette: state.palette, onContinue: { advanceScreen() })
                case 1:
                    MirrorScreen(state: state, onContinue: { advanceScreen() })
                case 2:
                    ProcessingScreen(state: state, onComplete: { advanceScreen() })
                case 3:
                    SynthesisScreen(state: state, onComplete: { advanceScreen() })
                case 4:
                    PromiseScreen(state: state, onContinue: { advanceScreen() })
                case 5:
                    GoalsScreen(state: state, onContinue: { advanceScreen() })
                case 6:
                    GoalsProcessingScreen(state: state, onComplete: { advanceScreen() })
                case 7:
                    // Feature Benefits - Show how app helps with selected goals
                    FeatureBenefitsScreen(state: state, onContinue: { advanceScreen() })
                case 8:
                    ActivityLevelScreen(state: state, onContinue: { advanceScreen() })
                case 9:
                    ActivityProcessingScreen(state: state, onComplete: { advanceScreen() })
                case 10:
                    EatingHabitsScreen(state: state, onContinue: { advanceScreen() })
                case 11:
                    DietExperienceScreen(state: state, onContinue: { advanceScreen() })
                case 12:
                    ProfileBuildingScreen(state: state, onComplete: { advanceScreen() })
                case 13:
                    // PersonalDetails BEFORE CalorieTarget so we have height/weight/age for BMR
                    PersonalDetailsScreen(state: state, onContinue: { advanceScreen() })
                case 14:
                    DietSetupScreen(
                        state: state,
                        onContinue: { advanceScreen() },
                        onSkip: { advanceScreen() }
                    )
                case 15:
                    CalorieTargetScreen(
                        state: state,
                        onContinue: { advanceScreen() },
                        onSkip: { advanceScreen() }
                    )
                case 16:
                    SensitivitiesScreen(state: state, onContinue: { advanceScreen() })
                // SKIP: Camera, Health, Notifications (permissions) - these come after sign-up
                // SKIP: ProUpgrade/Paywall - now shown after permissions in PostAuthPermissionsView
                case 17:
                    HonestyScreen(state: state, onContinue: { advanceScreen() })
                case 18:
                    // Pre-auth completion - save preferences but don't mark as fully complete
                    // (user still needs to create account and grant permissions)
                    PreAuthCompletionScreen(state: state, onComplete: {
                        state.saveToManager()
                        OnboardingManager.shared.acceptDisclaimer()
                        OnboardingManager.shared.completePreAuthOnboarding()
                        // DON'T call completeOnboarding() yet - permissions still needed after sign-up
                        onComplete(state.emailConsent)
                    })
                default:
                    BreathScreen(palette: state.palette, onContinue: { advanceScreen() })
                }
            }
            .opacity(transitionOpacity)
        }
        // Note: Paywall removed from pre-auth flow - now shown in PostAuthPermissionsView after permissions
        .onAppear {
            AnalyticsManager.shared.trackOnboardingStep(step: currentScreen, stepName: "PreAuth_" + preAuthScreenName(currentScreen))
        }
        .onChange(of: currentScreen) { _, newScreen in
            AnalyticsManager.shared.trackOnboardingStep(step: newScreen, stepName: "PreAuth_" + preAuthScreenName(newScreen))
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

    private func preAuthScreenName(_ screen: Int) -> String {
        switch screen {
        case 0: return "Breath"
        case 1: return "Mirror"
        case 2: return "Processing"
        case 3: return "Synthesis"
        case 4: return "Promise"
        case 5: return "Goals"
        case 6: return "GoalsProcessing"
        case 7: return "FeatureBenefits"
        case 8: return "ActivityLevel"
        case 9: return "ActivityProcessing"
        case 10: return "EatingHabits"
        case 11: return "DietExperience"
        case 12: return "ProfileBuilding"
        case 13: return "PersonalDetails"
        case 14: return "DietSetup"
        case 15: return "CalorieTarget"
        case 16: return "Sensitivities"
        case 17: return "Honesty"
        case 18: return "Completion"
        default: return "Unknown"
        }
    }
}

// MARK: - Pre-Auth Completion Screen
// Shows after onboarding but before sign-up
// Prompts user to create account to save their preferences

struct PreAuthCompletionScreen: View {
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
                Text("You're almost there")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))
                    .opacity(showText ? 1 : 0)

                Text("Create your account to save your preferences")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(Color(white: 0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(showText ? 1 : 0)
            }
            .padding(.bottom, 40)

            // Summary points
            VStack(alignment: .leading, spacing: 16) {
                CompletionPoint(
                    icon: "person.crop.circle",
                    text: "Your preferences are ready",
                    palette: state.palette,
                    show: showText
                )

                CompletionPoint(
                    icon: "icloud",
                    text: "Sync across all your devices",
                    palette: state.palette,
                    show: showText
                )

                CompletionPoint(
                    icon: "lock.shield",
                    text: "Keep your data safe and private",
                    palette: state.palette,
                    show: showText
                )
            }
            .padding(.horizontal, 40)
            .opacity(showText ? 1 : 0)

            Spacer()

            // Create Account button
            if showButton {
                PremiumButton(
                    text: "Create Account",
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

// MARK: - Preview

#Preview {
    PremiumOnboardingView { _ in }
        .environmentObject(HealthKitManager.shared)
}
