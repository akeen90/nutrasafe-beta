import SwiftUI

struct FastingEducationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingSources = false
    @State private var showContent = false
    @State private var visibleSections: Set<Int> = []

    // Use a calming sage/teal palette for fasting education
    private let palette = OnboardingPalette.control

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Editorial header
                    VStack(spacing: 20) {
                        // Subtle icon with gradient
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [palette.primary.opacity(0.2), palette.accent.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)

                            Image(systemName: "leaf.fill")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [palette.primary, palette.accent],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.8)

                        // Serif editorial headline
                        Text("Understanding\nYour Fast")
                            .font(.system(size: 34, weight: .bold, design: .serif))
                            .tracking(-0.5)
                            .multilineTextAlignment(.center)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)

                        Text("A gentle guide to what happens in your body—and how to support it.")
                            .font(.system(size: 17, weight: .regular))
                            .tracking(0.2)
                            .lineSpacing(4)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 15)
                    }
                    .padding(.top, 20)

                    // Philosophy section
                    FastingPhilosophySection(palette: palette, isVisible: visibleSections.contains(0))
                        .onAppear { animateSection(0) }

                    // Phase Timeline
                    FastingTimelineSection(palette: palette, isVisible: visibleSections.contains(1))
                        .onAppear { animateSection(1) }

                    // Scientific sources card
                    FastingSourcesCard(palette: palette, showingSources: $showingSources, isVisible: visibleSections.contains(2))
                        .onAppear { animateSection(2) }

                    // Tips section
                    FastingTipsSection(palette: palette, isVisible: visibleSections.contains(3))
                        .onAppear { animateSection(3) }

                    // Getting started section
                    FastingGettingStartedSection(palette: palette, isVisible: visibleSections.contains(4))
                        .onAppear { animateSection(4) }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
            .background {
                FastingEducationBackground(palette: palette)
                    .ignoresSafeArea()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .fullScreenCover(isPresented: $showingSources) {
                FastingCitationsView()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    showContent = true
                }
            }
        }
    }

    private func animateSection(_ index: Int) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1 + Double(index) * 0.15)) {
            _ = visibleSections.insert(index)
        }
    }
}

// MARK: - Background

struct FastingEducationBackground: View {
    let palette: OnboardingPalette
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Base
            (colorScheme == .dark ? Color.black : palette.background)

            // Soft gradient orbs
            Circle()
                .fill(
                    RadialGradient(
                        colors: [palette.primary.opacity(colorScheme == .dark ? 0.15 : 0.08), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: -100, y: -200)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [palette.accent.opacity(colorScheme == .dark ? 0.1 : 0.05), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 250
                    )
                )
                .frame(width: 500, height: 500)
                .offset(x: 150, y: 400)
        }
    }
}

// MARK: - Philosophy Section

struct FastingPhilosophySection: View {
    let palette: OnboardingPalette
    let isVisible: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 10) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [palette.primary, palette.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Allowed Drinks")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
            }

            Text("Choose your approach when creating a fasting plan")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            ForEach(Array(AllowedDrinksPhilosophy.allCases.enumerated()), id: \.element) { index, mode in
                PhilosophyInfoCardRedesigned(mode: mode, palette: palette, delay: Double(index) * 0.1)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 15, x: 0, y: 6)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 30)
    }
}

struct PhilosophyInfoCardRedesigned: View {
    let mode: AllowedDrinksPhilosophy
    let palette: OnboardingPalette
    var delay: Double = 0
    @Environment(\.colorScheme) private var colorScheme
    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(colorForMode.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: iconForMode)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(colorForMode)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .primary)

                    Text(mode.tone)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }

                Spacer()
            }

            Text(mode.description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineSpacing(3)

            // Allowed items
            VStack(alignment: .leading, spacing: 6) {
                ForEach(allowedItems, id: \.self) { item in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(colorForMode)

                        Text(item)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.white.opacity(0.03) : colorForMode.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(colorForMode.opacity(0.15), lineWidth: 1)
                )
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 15)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay + 0.2)) {
                isVisible = true
            }
        }
    }

    private var iconForMode: String {
        switch mode {
        case .strict: return "drop.fill"
        case .practical: return "leaf.fill"
        }
    }

    private var colorForMode: Color {
        switch mode {
        case .strict: return .blue
        case .practical: return palette.accent
        }
    }

    private var allowedItems: [String] {
        switch mode {
        case .strict:
            return ["Water (still or sparkling)", "Plain black coffee", "Plain tea", "Electrolytes"]
        case .practical:
            return ["All strict items", "Sugar-free drinks", "Zero-calorie flavoured water"]
        }
    }
}

// MARK: - Timeline Section

struct FastingTimelineSection: View {
    let palette: OnboardingPalette
    let isVisible: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "timeline.selection")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .purple.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Your Fasting Timeline")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
            }

            Text("What happens in your body at each stage")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            VStack(spacing: 0) {
                ForEach(Array(FastingPhase.allCases.enumerated()), id: \.element) { index, phase in
                    PhaseTimelineRow(phase: phase, isLast: index == FastingPhase.allCases.count - 1, index: index)
                }
            }

            // Disclaimer
            Text("Everyone's body is different. These are general guidelines.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .italic()
                .padding(.top, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 15, x: 0, y: 6)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 30)
    }
}

struct PhaseTimelineRow: View {
    let phase: FastingPhase
    let isLast: Bool
    let index: Int
    @Environment(\.colorScheme) private var colorScheme
    @State private var isVisible = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline indicator
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.2), .purple.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 44, height: 44)

                    VStack(spacing: 0) {
                        Text("\(phase.timeRange.lowerBound)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.purple)
                        Text("hrs")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.purple.opacity(0.7))
                    }
                }

                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .purple.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2, height: 40)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(phase.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)

                Text(phase.description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
            .padding(.vertical, 8)

            Spacer()
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -20)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3 + Double(index) * 0.08)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Sources Card

struct FastingSourcesCard: View {
    let palette: OnboardingPalette
    @Binding var showingSources: Bool
    let isVisible: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            showingSources = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [palette.accent.opacity(0.2), palette.primary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(palette.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Scientific Sources")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .primary)

                    Text("All claims backed by peer-reviewed research")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 12, x: 0, y: 4)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 30)
    }
}

// MARK: - Tips Section

struct FastingTipsSection: View {
    let palette: OnboardingPalette
    let isVisible: Bool
    @Environment(\.colorScheme) private var colorScheme

    private let tips: [(icon: String, title: String, description: String)] = [
        ("drop.fill", "Stay Hydrated", "Drink plenty of water throughout your fast to reduce hunger and support your body."),
        ("timer", "Start Slow", "Begin with 12-14 hour fasts and gradually increase as your body adapts."),
        ("heart.fill", "Listen to Your Body", "If you feel unwell, break your fast. Your wellbeing comes first."),
        ("calendar.badge.clock", "Be Consistent", "Regular fasting is more beneficial than occasional long fasts."),
        ("leaf.fill", "Break Gently", "End your fast with small, easily digestible foods.")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Helpful Tips")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                    FastingTipRow(icon: tip.icon, title: tip.title, description: tip.description, index: index)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 15, x: 0, y: 6)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 30)
    }
}

struct FastingTipRow: View {
    let icon: String
    let title: String
    let description: String
    let index: Int
    @Environment(\.colorScheme) private var colorScheme
    @State private var isVisible = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.2), Color.yellow.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 12)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.3 + Double(index) * 0.08)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Getting Started Section

struct FastingGettingStartedSection: View {
    let palette: OnboardingPalette
    let isVisible: Bool
    @Environment(\.colorScheme) private var colorScheme

    private let affirmations = ["Every hour counts", "Trust the process", "Your body adapts"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [palette.accent, palette.primary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Ready to Begin")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Fasting is a personal journey. Start with what feels manageable, and adjust as you learn what your body needs.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineSpacing(3)

                // Motivational quote
                Text("Progress compounds.\nConsistency over perfection.")
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundColor(palette.accent)
                    .italic()
                    .padding(.vertical, 8)
            }

            // Affirmation chips - use wrapping HStack
            HStack(spacing: 8) {
                ForEach(affirmations, id: \.self) { message in
                    Text(message)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(palette.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(palette.accent.opacity(0.1))
                        )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 15, x: 0, y: 6)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 30)
    }
}

// Display-only info card for education view
struct PhilosophyInfoCard: View {
    let mode: AllowedDrinksPhilosophy

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Icon based on mode
                Image(systemName: iconForMode)
                    .font(.title2)
                    .foregroundColor(colorForMode)
                    .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(mode.tone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }

                Spacer()
            }

            // Description
            Text(mode.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Allowed items
            VStack(alignment: .leading, spacing: 6) {
                Text("Allowed:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                ForEach(allowedItems, id: \.self) { item in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundColor(.green)
                            .frame(width: 12)

                        Text(item)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorForMode.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorForMode.opacity(0.2), lineWidth: 1)
        )
    }

    private var iconForMode: String {
        switch mode {
        case .strict:
            return "drop.fill"
        case .practical:
            return "leaf.fill"
        }
    }

    private var colorForMode: Color {
        switch mode {
        case .strict:
            return .blue
        case .practical:
            return .green
        }
    }

    private var allowedItems: [String] {
        switch mode {
        case .strict:
            return [
                "Water (still or sparkling)",
                "Plain black coffee",
                "Plain tea (black, green, herbal)",
                "Electrolyte supplements",
                "Salt water"
            ]
        case .practical:
            return [
                "All strict items",
                "Sugar-free drinks",
                "Diet sodas (occasionally)",
                "Zero-calorie flavoured water",
                "Black coffee with zero-cal sweeteners"
            ]
        }
    }
}

// Selectable card for plan creation/editing
struct PhilosophyCard: View {
    let mode: AllowedDrinksPhilosophy
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    // Icon based on mode
                    Image(systemName: iconForMode)
                        .font(.title2)
                        .foregroundColor(colorForMode)
                        .frame(width: 30, height: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text(mode.tone)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                    }

                    Spacer()

                    // Selection indicator
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(colorForMode)
                    }
                }

                // Description
                Text(mode.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Allowed items
                VStack(alignment: .leading, spacing: 6) {
                    Text("Allowed:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    ForEach(allowedItems, id: \.self) { item in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundColor(.green)
                                .frame(width: 12)

                            Text(item)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var iconForMode: String {
        switch mode {
        case .strict:
            return "drop.fill"
        case .practical:
            return "leaf.fill"
        }
    }

    private var colorForMode: Color {
        switch mode {
        case .strict:
            return .blue
        case .practical:
            return .green
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return colorForMode.opacity(0.1)
        } else {
            return Color.gray.opacity(0.05)
        }
    }

    private var borderColor: Color {
        if isSelected {
            return colorForMode.opacity(0.5)
        } else {
            return Color.gray.opacity(0.2)
        }
    }

    private var allowedItems: [String] {
        switch mode {
        case .strict:
            return [
                "Water (still or sparkling)",
                "Plain black coffee",
                "Plain tea (black, green, herbal)",
                "Electrolyte supplements",
                "Salt water"
            ]
        case .practical:
            return [
                "All strict items",
                "Sugar-free drinks",
                "Diet sodas (occasionally)",
                "Zero-calorie flavored water",
                "Black coffee with zero-cal sweeteners"
            ]
        }
    }
}

struct PhaseTimelineEducation: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "timeline.selection")
                    .foregroundColor(.purple)
                Text("Fasting Timeline")
                    .font(.headline)
            }
            
            Text("Your body goes through different phases during fasting. These are approximate timelines:")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            LazyVStack(spacing: 12) {
                ForEach(FastingPhase.allCases, id: \.self) { phase in
                    PhaseEducationRow(phase: phase)
                }
            }
            
            Text("Remember: Everyone's body is different. These timelines are general guidelines, not strict rules.")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
                .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground(cornerRadius: 16)
    }
}

struct PhaseEducationRow: View {
    let phase: FastingPhase
    
    var body: some View {
        HStack(spacing: 12) {
            // Time indicator
            VStack(spacing: 2) {
                Text("\(phase.timeRange.lowerBound)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("hours")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 40)
            .padding(8)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(phase.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(phase.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct TipsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                Text("Helpful Tips")
                    .font(.headline)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(tips.enumerated()), id: \.element) { index, tip in
                    TipRow(tip: tip, index: index)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground(cornerRadius: 16)
    }

    private var tips: [Tip] {
        [
            Tip(
                icon: "drop.fill",
                title: "Stay Hydrated",
                description: "Drink plenty of water throughout your fast. Hydration helps reduce hunger and supports your body's natural processes."
            ),
            Tip(
                icon: "timer",
                title: "Start Slow",
                description: "If you're new to fasting, begin with shorter durations (12-14 hours) and gradually increase as your body adapts."
            ),
            Tip(
                icon: "heart.fill",
                title: "Listen to Your Body",
                description: "Pay attention to how you feel. If you experience severe discomfort, dizziness, or other concerning symptoms, break your fast."
            ),
            Tip(
                icon: "calendar.badge.clock",
                title: "Be Consistent",
                description: "Regular fasting is more beneficial than occasional long fasts. Aim for consistency rather than perfection."
            ),
            Tip(
                icon: "leaf.fill",
                title: "Break Gently",
                description: "When ending your fast, start with small, easily digestible foods. Avoid heavy meals immediately after fasting."
            )
        ]
    }
}

struct TipRow: View {
    let tip: Tip
    var index: Int = 0

    @State private var isVisible = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Gradient icon in soft container
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.2), Color.yellow.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: tip.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(tip.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)

                Text(tip.description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 6)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 12)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.3 + Double(index) * 0.1)) {
                isVisible = true
            }
        }
    }
}

struct GettingStartedSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flag.checkered")
                    .foregroundColor(.green)
                Text("Ready to Start?")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Remember: Fasting is a personal journey. What works for others may not work for you.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Start with a plan that feels manageable, and adjust as you learn what your body needs.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Progress compounds. Consistency > perfection.")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .italic()
            }
            
            HStack(spacing: 16) {
                ForEach(motivationalMessages, id: \.self) { message in
                    Text("\(message)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(12)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground(cornerRadius: 16)
    }

    private var motivationalMessages: [String] {
        [
            "Every hour counts",
            "Trust the process",
            "Breathe and stay present",
            "Your body is adapting beautifully"
        ]
    }
}

struct Tip: Hashable {
    let icon: String
    let title: String
    let description: String
}

struct FirstUseEducationOverlay: View {
    @Binding var isPresented: Bool
    @State private var selectedMode: AllowedDrinksPhilosophy = .practical
    
    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPresented = false
                    }
                
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 50))
                            .foregroundColor(AppPalette.standard.accent)
                        
                        Text("Welcome to Fasting!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Let's set up your preferred approach to drinks during fasting.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(spacing: 12) {
                        ForEach(AllowedDrinksPhilosophy.allCases, id: \.self) { mode in
                            PhilosophyCard(
                                mode: mode,
                                isSelected: selectedMode == mode,
                                action: {
                                    selectedMode = mode
                                }
                            )
                        }
                    }
                    
                    Button {
                        isPresented = false
                    } label: {
                        Text("Get Started")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppPalette.standard.accent)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(Color.adaptiveCard)
                .cornerRadius(20)
                .padding()
                .shadow(radius: 20)
            }
        }
    }
}

#Preview {
    NavigationStack {
        FastingEducationView()
    }
}

#Preview {
    FirstUseEducationOverlay(isPresented: .constant(true))
}