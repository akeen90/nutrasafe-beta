//
//  AppDesignSystem.swift
//  NutraSafe Beta
//
//  Unified design system extending onboarding patterns across the entire app.
//  This file provides the foundation for visual consistency.
//

import SwiftUI
import UIKit

// MARK: - Adaptive Card Color Extension

extension Color {
    /// Card background that adapts to color scheme (if not already defined)
    static var nutraSafeCard: Color {
        Color(uiColor: .init { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.14, green: 0.18, blue: 0.28, alpha: 1.0)
                : UIColor.white
        })
    }
}

// MARK: - App-Wide Palette (Extends Onboarding)

struct AppPalette {
    let primary: Color
    let secondary: Color
    let tertiary: Color
    let accent: Color
    let background: Color
    let backgroundDeep: Color
    let cardBackground: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color

    // Default app palette (neutral, works before user selects intent)
    static let standard = AppPalette(
        primary: Color(red: 0.20, green: 0.45, blue: 0.50),      // Deep teal
        secondary: Color(red: 0.15, green: 0.35, blue: 0.42),    // Darker teal
        tertiary: Color(red: 0.45, green: 0.52, blue: 0.55),     // Cool slate
        accent: Color(red: 0.00, green: 0.60, blue: 0.55),       // Bright teal
        background: Color(red: 0.98, green: 0.97, blue: 0.95),   // Off-white
        backgroundDeep: Color(red: 0.94, green: 0.93, blue: 0.90),
        cardBackground: Color.white,
        textPrimary: Color(white: 0.2),
        textSecondary: Color(white: 0.4),
        textTertiary: Color(white: 0.5)
    )

    // Dark mode variant
    static let dark = AppPalette(
        primary: Color(red: 0.00, green: 0.60, blue: 0.55),      // Bright teal
        secondary: Color(red: 0.20, green: 0.45, blue: 0.50),    // Deep teal
        tertiary: Color(red: 0.60, green: 0.65, blue: 0.68),     // Light slate
        accent: Color(red: 0.00, green: 0.70, blue: 0.65),       // Vibrant teal
        background: Color(red: 0.10, green: 0.14, blue: 0.24),   // Midnight
        backgroundDeep: Color(red: 0.08, green: 0.11, blue: 0.20),
        cardBackground: Color(red: 0.14, green: 0.18, blue: 0.28),
        textPrimary: Color(white: 0.95),
        textSecondary: Color(white: 0.7),
        textTertiary: Color(white: 0.5)
    )

    // Intent-based palettes (matching onboarding)
    static let safer = AppPalette(
        primary: Color(red: 0.12, green: 0.40, blue: 0.45),
        secondary: Color(red: 0.15, green: 0.22, blue: 0.35),
        tertiary: Color(red: 0.70, green: 0.75, blue: 0.78),
        accent: Color(red: 0.00, green: 0.60, blue: 0.55),
        background: Color(red: 0.95, green: 0.97, blue: 0.97),
        backgroundDeep: Color(red: 0.12, green: 0.40, blue: 0.45),
        cardBackground: Color.white.opacity(0.9),
        textPrimary: Color(white: 0.2),
        textSecondary: Color(white: 0.4),
        textTertiary: Color(white: 0.5)
    )

    static let lighter = AppPalette(
        primary: Color(red: 0.95, green: 0.70, blue: 0.55),
        secondary: Color(red: 0.90, green: 0.55, blue: 0.50),
        tertiary: Color(red: 0.98, green: 0.92, blue: 0.85),
        accent: Color(red: 0.95, green: 0.50, blue: 0.40),
        background: Color(red: 0.99, green: 0.96, blue: 0.94),
        backgroundDeep: Color(red: 0.95, green: 0.70, blue: 0.55),
        cardBackground: Color.white.opacity(0.9),
        textPrimary: Color(white: 0.2),
        textSecondary: Color(white: 0.4),
        textTertiary: Color(white: 0.5)
    )

    static let control = AppPalette(
        primary: Color(red: 0.55, green: 0.65, blue: 0.50),
        secondary: Color(red: 0.60, green: 0.55, blue: 0.48),
        tertiary: Color(red: 0.45, green: 0.40, blue: 0.35),
        accent: Color(red: 0.45, green: 0.60, blue: 0.40),
        background: Color(red: 0.97, green: 0.96, blue: 0.94),
        backgroundDeep: Color(red: 0.55, green: 0.65, blue: 0.50),
        cardBackground: Color.white.opacity(0.9),
        textPrimary: Color(white: 0.2),
        textSecondary: Color(white: 0.4),
        textTertiary: Color(white: 0.5)
    )

    // Load user's selected palette from onboarding
    static func forCurrentUser(colorScheme: ColorScheme) -> AppPalette {
        if colorScheme == .dark {
            return .dark
        }

        if let intentRaw = UserDefaults.standard.string(forKey: "userIntent") {
            switch intentRaw {
            case "safer": return .safer
            case "lighter": return .lighter
            case "control": return .control
            default: return .standard
            }
        }
        return .standard
    }
}

// MARK: - Design Tokens

struct DesignTokens {
    // Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 40
        static let section: CGFloat = 60

        static let screenEdge: CGFloat = 24
        static let cardInternal: CGFloat = 20
        static let betweenCards: CGFloat = 16
        static let lineSpacing: CGFloat = 6
    }

    // Corner Radius
    struct Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let pill: CGFloat = 28
    }

    // Shadows
    struct Shadow {
        static let subtle = ShadowStyle(color: .black.opacity(0.05), radius: 10, y: 4)
        static let elevated = ShadowStyle(color: .black.opacity(0.08), radius: 15, y: 6)
        static let prominent = ShadowStyle(color: .black.opacity(0.12), radius: 20, y: 8)

        static func accent(_ color: Color) -> ShadowStyle {
            ShadowStyle(color: color.opacity(0.3), radius: 15, y: 5)
        }
    }

    // Animation
    struct Animation {
        static let quick: SwiftUI.Animation = .easeOut(duration: 0.1)
        static let standard: SwiftUI.Animation = .easeOut(duration: 0.3)
        static let slow: SwiftUI.Animation = .easeInOut(duration: 0.5)
        static let breathing: SwiftUI.Animation = .easeInOut(duration: 2.5).repeatForever(autoreverses: true)
        static let ambient: SwiftUI.Animation = .easeInOut(duration: 8).repeatForever(autoreverses: true)
    }

    // Typography
    struct Typography {
        // Editorial headline - serif, impactful
        static func headline(_ size: CGFloat = 28) -> Font {
            .system(size: size, weight: .bold, design: .serif)
        }

        // Section headline
        static func sectionTitle(_ size: CGFloat = 24) -> Font {
            .system(size: size, weight: .semibold, design: .serif)
        }

        // Body text
        static let body: Font = .system(size: 17, weight: .regular)

        // Caption
        static let caption: Font = .system(size: 14, weight: .regular)

        // Button label
        static let button: Font = .system(size: 17, weight: .semibold)

        // Small label
        static let label: Font = .system(size: 13, weight: .medium)
    }
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let y: CGFloat
}

// MARK: - Environment Key for Palette

struct AppPaletteKey: EnvironmentKey {
    static let defaultValue: AppPalette = .standard
}

extension EnvironmentValues {
    var appPalette: AppPalette {
        get { self[AppPaletteKey.self] }
        set { self[AppPaletteKey.self] = newValue }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply the app's standard card styling
    func nutraSafeCard(
        cornerRadius: CGFloat = DesignTokens.Radius.lg,
        shadow: ShadowStyle = DesignTokens.Shadow.subtle
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.nutraSafeCard)
                    .shadow(color: shadow.color, radius: shadow.radius, y: shadow.y)
            )
    }

    /// Apply glassmorphic card styling
    func glassCard(
        cornerRadius: CGFloat = DesignTokens.Radius.xl,
        isSelected: Bool = false,
        accentColor: Color = .blue
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                isSelected ? accentColor : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? accentColor.opacity(0.3) : Color.black.opacity(0.1),
                        radius: isSelected ? 20 : 10,
                        y: isSelected ? 8 : 4
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(DesignTokens.Animation.standard, value: isSelected)
    }

    /// Apply the app's animated background
    func appBackground() -> some View {
        self.background(AppAnimatedBackground())
    }
}

// MARK: - App Animated Background

struct AppAnimatedBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateGradient = false

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    palette.background,
                    palette.tertiary.opacity(0.15),
                    palette.background
                ],
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )

            // Subtle accent in corner
            RadialGradient(
                colors: [palette.primary.opacity(0.08), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 300
            )

            // Secondary accent
            RadialGradient(
                colors: [palette.accent.opacity(0.05), Color.clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 280
            )
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(DesignTokens.Animation.ambient) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Ambient Gradient Background (Simpler variant)

struct AmbientGradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    let accentColor: Color

    init(accent: Color = .blue) {
        self.accentColor = accent
    }

    var body: some View {
        ZStack {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.14, blue: 0.24),
                        Color(red: 0.14, green: 0.18, blue: 0.28)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [accentColor.opacity(0.08), Color.clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 260
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.97, blue: 0.95),
                        Color(red: 0.95, green: 0.94, blue: 0.92)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [accentColor.opacity(0.06), Color.clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 300
                )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Breathing Ring Component

/// A circular progress ring with breathing animation - matches onboarding visual language
struct BreathingRing: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let enableBreathing: Bool

    @Environment(\.colorScheme) private var colorScheme
    @State private var isBreathing = false

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    init(
        progress: Double,
        size: CGFloat = 130,
        lineWidth: CGFloat = 14,
        enableBreathing: Bool = true
    ) {
        self.progress = min(max(progress, 0), 1)
        self.size = size
        self.lineWidth = lineWidth
        self.enableBreathing = enableBreathing
    }

    var body: some View {
        ZStack {
            // Background ring with subtle glow
            Circle()
                .stroke(palette.tertiary.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)

            // Progress ring with palette accent
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [palette.accent, palette.primary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .shadow(color: palette.accent.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .scaleEffect(enableBreathing && isBreathing ? 1.03 : 1.0)
        .onAppear {
            if enableBreathing {
                withAnimation(DesignTokens.Animation.breathing) {
                    isBreathing = true
                }
            }
        }
    }
}

// MARK: - Glassmorphic Search Field

/// Premium search field with glassmorphic styling - matches onboarding cards
struct GlassmorphicSearchField: View {
    @Binding var text: String
    let placeholder: String
    var onSubmit: (() -> Void)?
    var trailingIcon: String?
    var trailingAction: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    init(
        text: Binding<String>,
        placeholder: String = "Search...",
        onSubmit: (() -> Void)? = nil,
        trailingIcon: String? = nil,
        trailingAction: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSubmit = onSubmit
        self.trailingIcon = trailingIcon
        self.trailingAction = trailingAction
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isFocused ? palette.accent : palette.textTertiary)

            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .font(.system(size: 16, weight: .regular))
                .focused($isFocused)
                .onSubmit { onSubmit?() }

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(palette.textTertiary)
                }
            }

            if let icon = trailingIcon {
                Button(action: { trailingAction?() }) {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(palette.accent)
                }
            }
        }
        .frame(height: 48)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .stroke(
                            isFocused ? palette.accent.opacity(0.6) : Color.white.opacity(0.2),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
                .shadow(
                    color: isFocused ? palette.accent.opacity(0.2) : Color.black.opacity(0.05),
                    radius: isFocused ? 15 : 8,
                    y: isFocused ? 6 : 3
                )
        )
        .scaleEffect(isFocused ? 1.01 : 1.0)
        .animation(DesignTokens.Animation.standard, value: isFocused)
    }
}

// MARK: - Premium Date Capsule

/// Palette-aware date picker capsule - replaces system blue pills
struct PremiumDateCapsule: View {
    let text: String
    let isSelected: Bool
    var showCalendarIcon: Bool
    var action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    init(
        _ text: String,
        isSelected: Bool,
        showCalendarIcon: Bool = false,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.isSelected = isSelected
        self.showCalendarIcon = showCalendarIcon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(text)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)

                if showCalendarIcon {
                    Image(systemName: "calendar")
                        .font(.system(size: 11, weight: .semibold))
                }
            }
            .foregroundColor(isSelected ? .white : palette.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(
                        isSelected
                            ? LinearGradient(
                                colors: [palette.accent, palette.primary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                    )
                    .shadow(
                        color: isSelected ? palette.accent.opacity(0.3) : Color.clear,
                        radius: isSelected ? 8 : 0,
                        y: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Palette-Aware Tab Picker

/// Segment control with onboarding glassmorphic styling
struct PaletteTabPicker<T: Hashable & CaseIterable & RawRepresentable>: View where T.RawValue == String {
    @Binding var selection: T

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(T.allCases), id: \.rawValue) { tab in
                Button(action: {
                    withAnimation(DesignTokens.Animation.standard) {
                        selection = tab
                    }
                }) {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: selection == tab ? .semibold : .medium))
                        .foregroundColor(selection == tab ? .white : palette.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selection == tab
                                ? RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                                    .fill(
                                        LinearGradient(
                                            colors: [palette.accent, palette.primary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: palette.accent.opacity(0.3), radius: 6, y: 2)
                                : nil
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Palette-Aware Gradient Card

/// Card with gradient fill based on user's palette
struct PaletteGradientCard<Content: View>: View {
    let content: Content
    var intensity: Double
    var cornerRadius: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    init(
        intensity: Double = 0.08,
        cornerRadius: CGFloat = DesignTokens.Radius.lg,
        @ViewBuilder content: () -> Content
    ) {
        self.intensity = intensity
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(DesignTokens.Spacing.cardInternal)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                palette.primary.opacity(intensity),
                                palette.secondary.opacity(intensity * 0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.nutraSafeCard.opacity(0.85))
                    )
                    .shadow(color: DesignTokens.Shadow.subtle.color,
                            radius: DesignTokens.Shadow.subtle.radius,
                            y: DesignTokens.Shadow.subtle.y)
            )
    }
}

// MARK: - View Extension for Palette-Aware Backgrounds

extension View {
    /// Apply palette-aware gradient tint to background
    func paletteTintedBackground(intensity: Double = 0.06) -> some View {
        modifier(PaletteTintedBackgroundModifier(intensity: intensity))
    }

    /// Apply premium card styling with palette gradient
    func premiumCard(
        cornerRadius: CGFloat = DesignTokens.Radius.lg,
        intensity: Double = 0.08
    ) -> some View {
        modifier(PremiumCardModifier(cornerRadius: cornerRadius, intensity: intensity))
    }
}

struct PaletteTintedBackgroundModifier: ViewModifier {
    let intensity: Double
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [
                        palette.primary.opacity(intensity),
                        palette.accent.opacity(intensity * 0.5),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

struct PremiumCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let intensity: Double
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    func body(content: Content) -> some View {
        content
            .padding(DesignTokens.Spacing.cardInternal)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                palette.primary.opacity(intensity),
                                palette.secondary.opacity(intensity * 0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.nutraSafeCard.opacity(0.9))
                    )
                    .shadow(color: DesignTokens.Shadow.subtle.color,
                            radius: DesignTokens.Shadow.subtle.radius,
                            y: DesignTokens.Shadow.subtle.y)
            )
    }
}
