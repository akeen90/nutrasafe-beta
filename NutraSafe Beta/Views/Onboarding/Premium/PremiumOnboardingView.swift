//
//  PremiumOnboardingView.swift
//  NutraSafe Beta
//
//  Premium 9-screen onboarding flow with emotional journey
//  Screens: Breath → Mirror → Processing → Depth → Synthesis → Promise → Access → Honesty → Threshold
//

import SwiftUI
import UserNotifications
import AVFoundation

// MARK: - Main Premium Onboarding View

struct PremiumOnboardingView: View {
    @StateObject private var state = PremiumOnboardingState()
    @State private var currentScreen = 0
    @State private var transitionOpacity: Double = 1
    @EnvironmentObject var healthKitManager: HealthKitManager

    let onComplete: (Bool) -> Void

    // Total screens (0-8)
    private let totalScreens = 9

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
                    DepthScreen(state: state, onContinue: { advanceScreen() })
                case 4:
                    SynthesisScreen(state: state, onComplete: { advanceScreen() })
                case 5:
                    PromiseScreen(state: state, onContinue: { advanceScreen() })
                case 6:
                    AccessScreen(state: state, onContinue: { advanceScreen() })
                case 7:
                    HonestyScreen(state: state, onContinue: { advanceScreen() })
                case 8:
                    ThresholdScreen(state: state, onComplete: {
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

    private func screenName(_ screen: Int) -> String {
        switch screen {
        case 0: return "Breath"
        case 1: return "Mirror"
        case 2: return "Processing"
        case 3: return "Depth"
        case 4: return "Synthesis"
        case 5: return "Promise"
        case 6: return "Access"
        case 7: return "Honesty"
        case 8: return "Threshold"
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

// MARK: - Screen 7: The Access (Camera Permission)

struct AccessScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    let onContinue: () -> Void

    @State private var permissionRequested = false
    @State private var permissionGranted = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // Headline
            VStack(spacing: 8) {
                Text("To protect you,")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))

                Text("we need to see")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))

                Text("what you see.")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))
            }

            // Subtext
            Text("Camera access lets us read labels instantly.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(white: 0.5))
                .padding(.top, 12)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer().frame(height: 50)

            // Focus viewfinder animation
            FocusViewfinder(palette: state.palette)
                .frame(height: 200)

            // Privacy assurance
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(state.palette.primary)

                Text("Your photos never leave your device unless you choose.")
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
                        text: "Allow Camera",
                        palette: state.palette,
                        action: requestCameraPermission
                    )

                    Button(action: {
                        permissionRequested = true
                        onContinue()
                    }) {
                        Text("Maybe Later")
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
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                permissionRequested = true
                permissionGranted = granted

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onContinue()
                }
            }
        }
    }
}

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
                    Text("NutraSafe helps you understand food—ingredients, allergens, nutrition.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color(white: 0.4))
                        .lineSpacing(4)

                    Text("We're a companion to your choices, not a replacement for medical advice.")
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

// MARK: - Screen 9: The Threshold (Final Launch)

struct ThresholdScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    let onComplete: () -> Void

    @State private var showParticles = false
    @State private var lensScale: CGFloat = 0.8

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Headline
            Text("You're ready.")
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundColor(Color(white: 0.2))

            Text("Let's see what you're eating.")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(Color(white: 0.4))
                .italic()
                .padding(.top, 12)

            Spacer().frame(height: 60)

            // Personal lens with particles
            ZStack {
                if showParticles {
                    FloatingParticles(palette: state.palette, count: 12)
                }

                PersonalLens(
                    intent: state.selectedIntent,
                    sensitivities: state.selectedSensitivities,
                    size: 140
                )
                .scaleEffect(lensScale)
            }
            .frame(height: 300)

            Spacer()

            // Enter button with shimmer
            PremiumButton(
                text: "Enter NutraSafe",
                palette: state.palette,
                action: onComplete,
                showShimmer: true
            )
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
        .background(
            // Rich background for final screen
            LinearGradient(
                colors: [
                    state.palette.background,
                    state.palette.primary.opacity(0.1),
                    state.palette.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onAppear {
            withAnimation(.easeOut(duration: 1)) {
                showParticles = true
                lensScale = 1.0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PremiumOnboardingView { _ in }
        .environmentObject(HealthKitManager.shared)
}
