//
//  DesignSystem.swift
//  NutraSafe Beta
//
//  AAA Quality Design System
//  Comprehensive design tokens for consistent, polished UI
//

import SwiftUI

// MARK: - Color System

/// Semantic color palette with depth and visual hierarchy
struct AppColors {

    // MARK: Primary Colors
    static let primary = Color(red: 0.0, green: 0.478, blue: 1.0)  // #007AFF - iOS Blue
    static let primaryLight = Color(red: 0.2, green: 0.584, blue: 1.0)  // Lighter variant
    static let primaryDark = Color(red: 0.0, green: 0.376, blue: 0.8)  // Darker variant

    // MARK: Success/Error/Warning
    static let success = Color(red: 0.204, green: 0.78, blue: 0.349)  // #34C759 - iOS Green
    static let successLight = Color(red: 0.304, green: 0.85, blue: 0.449)
    static let error = Color(red: 1.0, green: 0.231, blue: 0.188)  // #FF3B30 - iOS Red
    static let errorLight = Color(red: 1.0, green: 0.331, blue: 0.288)
    static let warning = Color(red: 1.0, green: 0.584, blue: 0.0)  // #FF9500 - iOS Orange
    static let warningLight = Color(red: 1.0, green: 0.684, blue: 0.2)

    // MARK: Nutritional Score Colors (Enhanced)
    static let scoreAPlus = Color(red: 0.0, green: 0.7, blue: 0.3)  // Rich green
    static let scoreA = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let scoreB = Color(red: 0.5, green: 0.85, blue: 0.3)  // Yellow-green
    static let scoreC = Color(red: 1.0, green: 0.8, blue: 0.0)  // Amber
    static let scoreD = Color(red: 1.0, green: 0.6, blue: 0.0)  // Orange
    static let scoreE = Color(red: 1.0, green: 0.4, blue: 0.2)  // Orange-red
    static let scoreF = Color(red: 0.9, green: 0.2, blue: 0.15)  // Deep red

    // MARK: Background & Surface Colors
    static let background = Color(.systemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    static let backgroundTertiary = Color(.tertiarySystemBackground)

    // Card surfaces with more noticeable distinction
    static let cardBackground = Color(.systemBackground)
    static let cardBackgroundElevated = Color(
        light: Color(white: 0.98),  // Slightly off-white for better depth
        dark: Color(red: 0.15, green: 0.15, blue: 0.16)  // Lighter in dark mode
    )
    static let cardBackgroundInteractive = Color(
        light: Color(red: 0.98, green: 0.98, blue: 0.99),
        dark: Color(red: 0.13, green: 0.13, blue: 0.14)
    )

    // MARK: Text Colors
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    static let textQuaternary = Color(.quaternaryLabel)

    // MARK: Separator & Border Colors
    static let separator = Color(.separator)
    static let separatorOpaque = Color(.opaqueSeparator)
    static let border = Color(.systemGray4)
    static let borderLight = Color(.systemGray5)

    // MARK: Overlay Colors
    static let overlay = Color.black.opacity(0.3)
    static let overlayLight = Color.black.opacity(0.15)
}

// MARK: - Typography System

/// Consistent typography scale with proper hierarchy
struct AppTypography {

    // MARK: Display Text (Hero sections)
    static func largeTitle(weight: Font.Weight = .bold) -> Font {
        .system(size: 34, weight: weight, design: .default)
    }

    static func title1(weight: Font.Weight = .bold) -> Font {
        .system(size: 28, weight: weight, design: .default)
    }

    static func title2(weight: Font.Weight = .bold) -> Font {
        .system(size: 22, weight: weight, design: .default)
    }

    static func title3(weight: Font.Weight = .semibold) -> Font {
        .system(size: 20, weight: weight, design: .default)
    }

    // MARK: Body Text
    static func headline(weight: Font.Weight = .semibold) -> Font {
        .system(size: 17, weight: weight, design: .default)
    }

    static func body(weight: Font.Weight = .regular) -> Font {
        .system(size: 17, weight: weight, design: .default)
    }

    static func callout(weight: Font.Weight = .regular) -> Font {
        .system(size: 16, weight: weight, design: .default)
    }

    static func subheadline(weight: Font.Weight = .regular) -> Font {
        .system(size: 15, weight: weight, design: .default)
    }

    // MARK: Supporting Text
    static func footnote(weight: Font.Weight = .regular) -> Font {
        .system(size: 13, weight: weight, design: .default)
    }

    static func caption1(weight: Font.Weight = .regular) -> Font {
        .system(size: 12, weight: weight, design: .default)
    }

    static func caption2(weight: Font.Weight = .regular) -> Font {
        .system(size: 11, weight: weight, design: .default)
    }

    // MARK: Specialized Typography
    static func nutritionValue(weight: Font.Weight = .semibold) -> Font {
        .system(size: 18, weight: weight, design: .rounded)
    }

    static func scoreGrade(weight: Font.Weight = .bold) -> Font {
        .system(size: 24, weight: weight, design: .rounded)
    }
}

// MARK: - Spacing System

/// 4pt/8pt grid spacing system for perfect alignment
struct AppSpacing {
    static let xxxSmall: CGFloat = 2    // 2pt
    static let xxSmall: CGFloat = 4     // 4pt
    static let xSmall: CGFloat = 8      // 8pt
    static let small: CGFloat = 12      // 12pt
    static let medium: CGFloat = 16     // 16pt
    static let large: CGFloat = 20      // 20pt
    static let xLarge: CGFloat = 24     // 24pt
    static let xxLarge: CGFloat = 32    // 32pt
    static let xxxLarge: CGFloat = 40   // 40pt
    static let huge: CGFloat = 48       // 48pt
}

// MARK: - Corner Radius System

/// Consistent corner radius scale
struct AppRadius {
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xLarge: CGFloat = 20
    static let xxLarge: CGFloat = 24
    static let circle: CGFloat = 999
}

// MARK: - Shadow System

/// Elevation-based shadow system for visual depth
struct AppShadow {

    // MARK: Shadow Definitions

    /// Subtle shadow for minimal elevation (cards at rest)
    static let small = ShadowStyle(
        color: Color.black.opacity(0.08),
        radius: 4,
        x: 0,
        y: 2
    )

    /// Medium shadow for interactive elements
    static let medium = ShadowStyle(
        color: Color.black.opacity(0.12),
        radius: 8,
        x: 0,
        y: 4
    )

    /// Large shadow for elevated surfaces (modals, dialogs)
    static let large = ShadowStyle(
        color: Color.black.opacity(0.16),
        radius: 16,
        x: 0,
        y: 8
    )

    /// Extra large shadow for maximum elevation (toasts, overlays)
    static let xLarge = ShadowStyle(
        color: Color.black.opacity(0.2),
        radius: 24,
        x: 0,
        y: 12
    )

    // MARK: Specialized Shadows

    /// Soft ambient shadow for cards (more noticeable for AAA quality)
    static let card = ShadowStyle(
        color: Color.black.opacity(0.15),
        radius: 12,
        x: 0,
        y: 4
    )

    /// Interactive element shadow (pressed state)
    static let pressed = ShadowStyle(
        color: Color.black.opacity(0.04),
        radius: 2,
        x: 0,
        y: 1
    )
}

/// Shadow style definition
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extensions

extension View {

    // MARK: Shadow Helpers

    /// Apply a shadow style to a view
    func shadow(_ style: ShadowStyle) -> some View {
        self.shadow(
            color: style.color,
            radius: style.radius,
            x: style.x,
            y: style.y
        )
    }

    /// Apply card shadow (most common use case)
    func cardShadow() -> some View {
        self.shadow(AppShadow.card)
    }

    /// Apply small shadow
    func smallShadow() -> some View {
        self.shadow(AppShadow.small)
    }

    /// Apply medium shadow
    func mediumShadow() -> some View {
        self.shadow(AppShadow.medium)
    }

    /// Apply large shadow
    func largeShadow() -> some View {
        self.shadow(AppShadow.large)
    }

    // MARK: Card Style Helpers

    /// Standard card styling with background and shadow
    func standardCard(
        padding: CGFloat = AppSpacing.medium,
        cornerRadius: CGFloat = AppRadius.medium,
        backgroundColor: Color = AppColors.cardBackground
    ) -> some View {
        self
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .cardShadow()
    }

    /// Elevated card styling (more prominent)
    func elevatedCard(
        padding: CGFloat = AppSpacing.medium,
        cornerRadius: CGFloat = AppRadius.medium
    ) -> some View {
        self
            .padding(padding)
            .background(AppColors.cardBackgroundElevated)
            .cornerRadius(cornerRadius)
            .mediumShadow()
    }

    /// Interactive card styling (pressable)
    func interactiveCard(
        padding: CGFloat = AppSpacing.medium,
        cornerRadius: CGFloat = AppRadius.medium
    ) -> some View {
        self
            .padding(padding)
            .background(AppColors.cardBackgroundInteractive)
            .cornerRadius(cornerRadius)
            .cardShadow()
    }
}

// MARK: - Animation Presets

/// Consistent animation timing for micro-interactions
struct AppAnimation {
    static let quick = Animation.easeInOut(duration: 0.2)
    static let standard = Animation.easeInOut(duration: 0.3)
    static let slow = Animation.easeInOut(duration: 0.45)
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.75)
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
}

// MARK: - Helper Extensions

extension Color {
    /// Create a color that adapts to light/dark mode
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}

// MARK: - Design System Preview

#if DEBUG
struct DesignSystemPreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xLarge) {
                // Color Palette
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    Text("Color Palette")
                        .font(AppTypography.title2())

                    HStack(spacing: AppSpacing.small) {
                        ColorSwatch(color: AppColors.primary, name: "Primary")
                        ColorSwatch(color: AppColors.success, name: "Success")
                        ColorSwatch(color: AppColors.error, name: "Error")
                        ColorSwatch(color: AppColors.warning, name: "Warning")
                    }
                }

                // Typography
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("Typography")
                        .font(AppTypography.title2())

                    Text("Large Title").font(AppTypography.largeTitle())
                    Text("Title 1").font(AppTypography.title1())
                    Text("Title 2").font(AppTypography.title2())
                    Text("Headline").font(AppTypography.headline())
                    Text("Body").font(AppTypography.body())
                    Text("Caption").font(AppTypography.caption1())
                }

                // Card Styles
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    Text("Card Styles")
                        .font(AppTypography.title2())

                    Text("Standard Card")
                        .standardCard()

                    Text("Elevated Card")
                        .elevatedCard()

                    Text("Interactive Card")
                        .interactiveCard()
                }
            }
            .padding(AppSpacing.medium)
        }
    }
}

struct ColorSwatch: View {
    let color: Color
    let name: String

    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: AppRadius.small)
                .fill(color)
                .frame(width: 60, height: 60)
            Text(name)
                .font(AppTypography.caption2())
        }
    }
}

#Preview {
    DesignSystemPreview()
}
#endif
