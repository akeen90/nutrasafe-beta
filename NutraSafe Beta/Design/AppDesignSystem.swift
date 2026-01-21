//
//  AppDesignSystem.swift
//  NutraSafe Beta
//
//  UNIFIED DESIGN SYSTEM - The single source of truth for NutraSafe visual identity.
//  All tokens, components, and styles derive directly from the onboarding experience.
//
//  NO PLATFORM BLUE. NO LEGACY GRADIENTS. NO EXCEPTIONS.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - DEPRECATED COLORS (NEVER USE)
// The following are FORBIDDEN throughout the app:
// - Color.blue (platform default)
// - Any purple/violet gradients (old auth screens)
// - Color(red: 0.6, green: 0.3, blue: 0.8) and similar
// - System tint colors without palette override

// MARK: - App-Wide Palette (Derived from Onboarding)

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

    // MARK: - Standard Palette (Default/Neutral - Before Intent Selection)
    // Derived from OnboardingPalette.neutral
    static let standard = AppPalette(
        primary: Color(red: 0.20, green: 0.45, blue: 0.50),      // Deep teal (onboarding accent)
        secondary: Color(red: 0.15, green: 0.35, blue: 0.42),    // Darker teal
        tertiary: Color(red: 0.45, green: 0.52, blue: 0.55),     // Cool slate
        accent: Color(red: 0.00, green: 0.60, blue: 0.55),       // Bright teal (primary action)
        background: Color(red: 0.98, green: 0.97, blue: 0.95),   // Off-white (onboarding bg)
        backgroundDeep: Color(red: 0.94, green: 0.93, blue: 0.90),
        cardBackground: Color.white,
        textPrimary: Color(white: 0.2),
        textSecondary: Color(white: 0.4),
        textTertiary: Color(white: 0.5)
    )

    // MARK: - Dark Mode Palette
    static let dark = AppPalette(
        primary: Color(red: 0.00, green: 0.60, blue: 0.55),      // Bright teal
        secondary: Color(red: 0.20, green: 0.45, blue: 0.50),    // Deep teal
        tertiary: Color(red: 0.60, green: 0.65, blue: 0.68),     // Light slate
        accent: Color(red: 0.00, green: 0.70, blue: 0.65),       // Vibrant teal
        background: Color(red: 0.10, green: 0.14, blue: 0.24),   // Midnight
        backgroundDeep: Color(red: 0.08, green: 0.11, blue: 0.20),
        cardBackground: Color(red: 0.14, green: 0.18, blue: 0.28),
        textPrimary: Color(white: 0.95),
        textSecondary: Color(white: 0.75),                       // Increased from 0.7 for better visibility
        textTertiary: Color(white: 0.6)                          // Increased from 0.5 for better visibility
    )

    // MARK: - Intent-Based Palettes (From Onboarding)

    // "Safer" - Deep teal, midnight blue, silver
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

    // "Lighter" - Sunrise peach, soft coral, warm cream
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

    // "In Control" - Sage green, warm stone, grounded earth
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

    // MARK: - Palette Selection
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

// MARK: - Semantic Colors (Feature-Specific, Palette-Independent)
// These colors have semantic meaning tied to specific features.
// Use these instead of hardcoded Color.orange, Color.green, etc.

struct SemanticColors {
    // MARK: - Feature Accents

    /// Nutrient/vitamin green - replaces Color(hex: "#3FD17C") and .green
    static let nutrient = Color(red: 0.25, green: 0.82, blue: 0.49)

    /// Additive/ingredient orange - replaces hardcoded Color.orange
    static let additive = Color(red: 0.95, green: 0.55, blue: 0.2)

    /// Water/hydration blue - replaces hardcoded .cyan
    static let hydration = Color(red: 0.2, green: 0.7, blue: 0.9)

    /// Exercise/activity orange-red - for burned calories, steps
    static let activity = Color(red: 1.0, green: 0.5, blue: 0.3)

    // MARK: - Insight States (for warnings, tips, achievements)

    /// Positive insight (success, achievement, good news)
    static let positive = Color(red: 0.3, green: 0.75, blue: 0.4)

    /// Neutral insight (information, suggestion, tip)
    static let neutral = Color(red: 0.95, green: 0.6, blue: 0.2)

    /// Caution insight (warning, concern, attention needed)
    static let caution = Color(red: 0.9, green: 0.35, blue: 0.35)

    // MARK: - Streak/Achievement
    static let streak = Color(red: 0.95, green: 0.55, blue: 0.2)
}

// MARK: - Design Tokens (Strict Onboarding Alignment)

struct DesignTokens {

    // MARK: - Spacing (From Onboarding Layout)
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 40
        static let section: CGFloat = 60

        static let screenEdge: CGFloat = 24     // Onboarding: padding(.horizontal, 24)
        static let cardInternal: CGFloat = 20   // Onboarding: padding(20)
        static let betweenCards: CGFloat = 16
        static let lineSpacing: CGFloat = 6     // Onboarding: lineSpacing(6)
    }

    // MARK: - Corner Radius (From Onboarding Cards/Buttons)
    struct Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16             // Onboarding buttons
        static let xl: CGFloat = 20             // Onboarding cards
        static let pill: CGFloat = 28
    }

    // MARK: - Shadows (From Onboarding Visual Language)
    struct Shadow {
        // Subtle - resting cards
        static let subtle = ShadowStyle(color: .black.opacity(0.05), radius: 10, y: 4)
        // Elevated - hovering/selected
        static let elevated = ShadowStyle(color: .black.opacity(0.08), radius: 15, y: 6)
        // Prominent - modals/sheets
        static let prominent = ShadowStyle(color: .black.opacity(0.12), radius: 20, y: 8)

        // Accent glow - selected state (onboarding IntentCard)
        static func accent(_ color: Color) -> ShadowStyle {
            ShadowStyle(color: color.opacity(0.3), radius: 15, y: 5)
        }
    }

    // MARK: - Animation (From Onboarding Timings)
    struct Animation {
        static let quick: SwiftUI.Animation = .easeOut(duration: 0.1)
        static let standard: SwiftUI.Animation = .easeOut(duration: 0.3)
        static let slow: SwiftUI.Animation = .easeInOut(duration: 0.5)
        static let breathing: SwiftUI.Animation = .easeInOut(duration: 2.5).repeatForever(autoreverses: true)
        static let ambient: SwiftUI.Animation = .easeInOut(duration: 8).repeatForever(autoreverses: true)
    }

    // MARK: - Typography (From Onboarding)
    struct Typography {
        // Editorial headline - serif, impactful (onboarding titles)
        static func headline(_ size: CGFloat = 28) -> Font {
            .system(size: size, weight: .bold, design: .serif)
        }

        // Section headline
        static func sectionTitle(_ size: CGFloat = 24) -> Font {
            .system(size: size, weight: .semibold, design: .serif)
        }

        // Body text - 17pt regular (onboarding body)
        static let body: Font = .system(size: 17, weight: .regular)

        // Caption - 14pt regular
        static let caption: Font = .system(size: 14, weight: .regular)

        // Button label - 17pt semibold (onboarding buttons)
        static let button: Font = .system(size: 17, weight: .semibold)

        // Small label - 13pt medium
        static let label: Font = .system(size: 13, weight: .medium)

        // Tab label - 10pt semibold
        static let tab: Font = .system(size: 10, weight: .semibold)
    }

    // MARK: - Component Sizes (From Onboarding)
    struct Size {
        static let buttonHeight: CGFloat = 56       // Onboarding: frame(height: 56)
        static let tabBarHeight: CGFloat = 70
        static let addButtonSize: CGFloat = 56
        static let iconSmall: CGFloat = 18
        static let iconMedium: CGFloat = 22
        static let iconLarge: CGFloat = 28
    }
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let y: CGFloat
}

// MARK: - Adaptive Color Extensions

extension Color {
    /// Card background that adapts to color scheme (palette-aware)
    static var nutraSafeCard: Color {
        Color(uiColor: .init { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.14, green: 0.18, blue: 0.28, alpha: 1.0)
                : UIColor.white
        })
    }

    /// Midnight background for dark mode selections
    static var midnightBackground: Color {
        Color(red: 0.10, green: 0.14, blue: 0.24) // #192338
    }

    /// Slightly lighter midnight blue for cards
    static var midnightCard: Color {
        Color(red: 0.14, green: 0.18, blue: 0.28) // #242D47
    }

    /// Even lighter for secondary cards
    static var midnightCardSecondary: Color {
        Color(red: 0.18, green: 0.22, blue: 0.32) // #2E3851
    }

    /// Adaptive background that switches between light and midnight blue
    static var adaptiveBackground: Color {
        Color(uiColor: .init { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.10, green: 0.14, blue: 0.24, alpha: 1.0)
                : UIColor(red: 0.82, green: 0.95, blue: 0.99, alpha: 1.0)
        })
    }

    /// Adaptive card background
    static var adaptiveCard: Color {
        Color(uiColor: .init { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.14, green: 0.18, blue: 0.28, alpha: 1.0)
                : UIColor.white
        })
    }
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

// MARK: - UNIFIED BUTTON SYSTEM

/// Primary action button - derived directly from onboarding PremiumButton
/// Height: 56pt, Radius: 16pt, Gradient fill from palette
struct NutraSafePrimaryButton: View {
    let text: String
    let action: () -> Void
    var isEnabled: Bool = true
    var showShimmer: Bool = false

    init(_ text: String, isEnabled: Bool = true, showShimmer: Bool = false, action: @escaping () -> Void) {
        self.text = text
        self.action = action
        self.isEnabled = isEnabled
        self.showShimmer = showShimmer
    }

    @Environment(\.colorScheme) private var colorScheme
    @State private var shimmerOffset: CGFloat = -200

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                // Base gradient fill
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(
                        isEnabled
                            ? LinearGradient(
                                colors: [palette.accent, palette.primary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .shadow(
                        color: isEnabled ? palette.accent.opacity(0.3) : Color.clear,
                        radius: 15,
                        y: 5
                    )

                // Shimmer overlay
                if showShimmer && isEnabled {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerOffset)
                        .mask(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
                }

                // Text
                Text(text)
                    .font(DesignTokens.Typography.button)
                    .foregroundColor(isEnabled ? .white : .gray)
            }
            .frame(height: DesignTokens.Size.buttonHeight)
        }
        .disabled(!isEnabled)
        .onAppear {
            if showShimmer {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    shimmerOffset = 400
                }
            }
        }
    }
}

/// Secondary action button - subtle styling for secondary actions
struct NutraSafeSecondaryButton: View {
    let text: String
    let action: () -> Void
    var icon: String? = nil

    init(_ text: String, icon: String? = nil, action: @escaping () -> Void) {
        self.text = text
        self.icon = icon
        self.action = action
    }

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                Text(text)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(palette.accent)
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(palette.accent.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .stroke(palette.accent.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

/// Tertiary button - text-only for less prominent actions
struct NutraSafeTertiaryButton: View {
    let text: String
    let action: () -> Void
    var isDestructive: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isDestructive ? .red : palette.textSecondary)
        }
    }
}

/// Icon action button - for toolbar/inline actions
struct NutraSafeIconButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 44
    var isDestructive: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isDestructive ? .red : palette.accent)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(isDestructive ? Color.red.opacity(0.1) : palette.accent.opacity(0.1))
                )
        }
    }
}

/// Unified icon wrapper - consistent weight, size, and palette awareness
/// Use this for standalone icons that need consistent styling
struct NutraSafeIcon: View {
    let name: String
    var size: CGFloat = 20
    var weight: Font.Weight = .medium
    var color: Color? = nil
    var filled: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    private var iconName: String {
        if filled && !name.hasSuffix(".fill") {
            return "\(name).fill"
        }
        return name
    }

    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: size, weight: weight))
            .foregroundColor(color ?? palette.textSecondary)
    }
}

// MARK: - UNIFIED CARD SYSTEM

extension View {
    /// Apply the app's standard card styling (derived from onboarding GlassmorphicCard)
    func nutraSafeCard(
        cornerRadius: CGFloat = DesignTokens.Radius.xl,
        shadow: ShadowStyle = DesignTokens.Shadow.subtle
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.nutraSafeCard)
                    .shadow(color: shadow.color, radius: shadow.radius, y: shadow.y)
            )
    }

    /// Apply glassmorphic card styling (direct from onboarding)
    func glassCard(
        cornerRadius: CGFloat = DesignTokens.Radius.xl,
        isSelected: Bool = false,
        accentColor: Color? = nil
    ) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, isSelected: isSelected, accentColor: accentColor))
    }

    /// Apply the app's animated background (onboarding-derived)
    func appBackground() -> some View {
        self.background(AppAnimatedBackground())
    }

    /// Apply premium card styling with palette gradient
    func premiumCard(
        cornerRadius: CGFloat = DesignTokens.Radius.xl,
        intensity: Double = 0.08
    ) -> some View {
        modifier(PremiumCardModifier(cornerRadius: cornerRadius, intensity: intensity))
    }

    /// Apply palette-aware gradient tint to background
    func paletteTintedBackground(intensity: Double = 0.06) -> some View {
        modifier(PaletteTintedBackgroundModifier(intensity: intensity))
    }
}

struct GlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let isSelected: Bool
    let accentColor: Color?

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    private var effectiveAccent: Color {
        accentColor ?? palette.accent
    }

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                isSelected ? effectiveAccent : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? effectiveAccent.opacity(0.3) : Color.black.opacity(0.1),
                        radius: isSelected ? 20 : 10,
                        y: isSelected ? 8 : 4
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(DesignTokens.Animation.standard, value: isSelected)
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

// MARK: - App Animated Background (From Onboarding)

struct AppAnimatedBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateGradient = false

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            // Base gradient (onboarding-derived)
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

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    palette.background,
                    palette.tertiary.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [palette.accent.opacity(0.06), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 300
            )
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
            // Background ring
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
        cornerRadius: CGFloat = DesignTokens.Radius.xl,
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

// MARK: - Unified Header View

/// Standard header for all main screens - palette-aware, onboarding-derived
struct NutraSafeHeader: View {
    let title: String
    var subtitle: String? = nil
    var showSettings: Bool = false
    var settingsAction: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignTokens.Typography.sectionTitle(22))
                    .foregroundColor(palette.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(palette.textSecondary)
                }
            }

            Spacer()

            if showSettings, let action = settingsAction {
                Button(action: action) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(palette.textSecondary)
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.screenEdge)
        .padding(.vertical, DesignTokens.Spacing.md)
    }
}

// MARK: - DEPRECATED LEGACY STYLES
// The following patterns are FORBIDDEN and must be replaced:
//
// 1. Color.blue - Use palette.accent instead
// 2. Color(red: 0.6, green: 0.3, blue: 0.8) - Purple auth gradient - Use AppAnimatedBackground
// 3. Color(red: 0.4, green: 0.5, blue: 0.9) - Blue auth gradient - Use AppAnimatedBackground
// 4. .foregroundColor(.blue) - Use palette.accent
// 5. .background(Color.blue) - Use NutraSafePrimaryButton or palette.accent
// 6. .tint(.blue) - Use .tint(palette.accent)
// 7. LinearGradient with blue/purple - Use palette-based gradients
//
// ALWAYS use:
// - AppPalette.forCurrentUser(colorScheme:) for colors
// - NutraSafePrimaryButton for primary actions
// - NutraSafeSecondaryButton for secondary actions
// - .glassCard() for cards
// - AppAnimatedBackground for screen backgrounds
