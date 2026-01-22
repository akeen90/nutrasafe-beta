//
//  NutraSafeComponents.swift
//  NutraSafe Beta
//
//  Reusable UI components following the unified design language.
//  These components extend onboarding patterns to the entire app.
//

import SwiftUI

// MARK: - NutraSafe Card

struct NutraSafeCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat
    var padding: CGFloat
    var shadow: ShadowStyle

    init(
        cornerRadius: CGFloat = DesignTokens.Radius.lg,
        padding: CGFloat = DesignTokens.Spacing.cardInternal,
        shadow: ShadowStyle = DesignTokens.Shadow.subtle,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.shadow = shadow
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.nutraSafeCard)
                    .shadow(color: shadow.color, radius: shadow.radius, y: shadow.y)
            )
    }
}

// MARK: - NutraSafe Section Card (with header)

struct NutraSafeSectionCard<Content: View>: View {
    let title: String
    let content: Content
    var icon: String?
    var iconColor: Color

    init(
        title: String,
        icon: String? = nil,
        iconColor: Color = AppPalette.standard.accent,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // Section header
            HStack(spacing: DesignTokens.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                Text(title)
                    .font(DesignTokens.Typography.sectionTitle(20))
                    .foregroundColor(Color(white: 0.2))
            }
            .padding(.horizontal, DesignTokens.Spacing.cardInternal)
            .padding(.top, DesignTokens.Spacing.cardInternal)

            content
                .padding(.horizontal, DesignTokens.Spacing.cardInternal)
                .padding(.bottom, DesignTokens.Spacing.cardInternal)
        }
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(Color.nutraSafeCard)
                .shadow(color: DesignTokens.Shadow.subtle.color,
                        radius: DesignTokens.Shadow.subtle.radius,
                        y: DesignTokens.Shadow.subtle.y)
        )
    }
}

// NutraSafePrimaryButton and NutraSafeSecondaryButton are defined in AppDesignSystem.swift

// MARK: - NutraSafe Info Card (from onboarding InfoCard)

struct NutraSafeInfoCard: View {
    let icon: String
    let text: String
    var iconColor: Color
    var backgroundColor: Color

    init(
        icon: String,
        text: String,
        iconColor: Color = AppPalette.standard.accent,
        backgroundColor: Color? = nil
    ) {
        self.icon = icon
        self.text = text
        self.iconColor = iconColor
        self.backgroundColor = backgroundColor ?? iconColor.opacity(0.08)
    }

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(white: 0.3))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(DesignTokens.Spacing.lineSpacing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(backgroundColor)
        )
    }
}

// MARK: - NutraSafe Warning Card (Palette-Aware)

struct NutraSafeWarningCard: View {
    let text: String
    var usePaletteColor: Bool

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    private var accentColor: Color {
        usePaletteColor ? palette.accent : .orange
    }

    init(_ text: String, usePaletteColor: Bool = false) {
        self.text = text
        self.usePaletteColor = usePaletteColor
    }

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundColor(accentColor)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(DesignTokens.Spacing.lineSpacing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(accentColor.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - NutraSafe Feature Row (from onboarding InfoBullet)

struct NutraSafeFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    var iconColor: Color

    init(
        icon: String,
        title: String,
        description: String,
        iconColor: Color = AppPalette.standard.accent
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.iconColor = iconColor
    }

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            // Icon with gradient background
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(
                        colors: [iconColor, iconColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(DesignTokens.Radius.md)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(white: 0.2))

                Text(description)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(white: 0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(Color.nutraSafeCard)
                .shadow(color: DesignTokens.Shadow.subtle.color,
                        radius: DesignTokens.Shadow.subtle.radius,
                        y: DesignTokens.Shadow.subtle.y)
        )
    }
}

// MARK: - NutraSafe Empty State

struct NutraSafeEmptyState: View {
    let icon: String
    let title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Abstract icon
            Image(systemName: icon)
                .font(.system(size: 60, weight: .light))
                .foregroundColor(Color(white: 0.3).opacity(0.4))

            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(title)
                    .font(DesignTokens.Typography.sectionTitle(20))
                    .foregroundColor(Color(white: 0.3))

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(Color(white: 0.5))
                        .multilineTextAlignment(.center)
                }
            }

            if let actionTitle = actionTitle, let action = action {
                NutraSafePrimaryButton(actionTitle, action: action)
                    .frame(width: 200)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.section)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - NutraSafe Section Header

struct NutraSafeSectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(title)
                .font(DesignTokens.Typography.sectionTitle(22))
                .foregroundColor(Color(white: 0.2))

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(Color(white: 0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - NutraSafe Headline

struct NutraSafeHeadline: View {
    let text: String
    var size: CGFloat

    init(_ text: String, size: CGFloat = 28) {
        self.text = text
        self.size = size
    }

    var body: some View {
        Text(text)
            .font(DesignTokens.Typography.headline(size))
            .foregroundColor(Color(white: 0.2))
            .tracking(-0.5)
    }
}

// MARK: - NutraSafe Insight Card (Palette-Aware with Breathing)

struct NutraSafeInsightCard: View {
    let icon: String
    let title: String
    let value: String
    var trend: InsightTrend?
    var usePaletteColor: Bool
    var enableBreathing: Bool

    @Environment(\.colorScheme) private var colorScheme
    @State private var isBreathing = false

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    enum InsightTrend {
        case up, down, neutral

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "arrow.right"
            }
        }

        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
    }

    init(
        icon: String,
        title: String,
        value: String,
        trend: InsightTrend? = nil,
        usePaletteColor: Bool = true,
        enableBreathing: Bool = false
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.trend = trend
        self.usePaletteColor = usePaletteColor
        self.enableBreathing = enableBreathing
    }

    private var accentColor: Color {
        usePaletteColor ? palette.accent : AppPalette.standard.accent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(accentColor)

                Spacer()

                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(trend.color)
                }
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(palette.textPrimary)
                    .scaleEffect(enableBreathing && isBreathing ? 1.02 : 1.0)

                Text(title)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(palette.textTertiary)
            }
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.06),
                            Color.nutraSafeCard
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .fill(Color.nutraSafeCard.opacity(0.85))
                )
                .shadow(color: DesignTokens.Shadow.subtle.color,
                        radius: DesignTokens.Shadow.subtle.radius,
                        y: DesignTokens.Shadow.subtle.y)
        )
        .onAppear {
            if enableBreathing {
                withAnimation(DesignTokens.Animation.breathing) {
                    isBreathing = true
                }
            }
        }
    }
}

// MARK: - NutraSafe Tag / Chip

struct NutraSafeTag: View {
    let text: String
    var isSelected: Bool
    var color: Color
    var action: (() -> Void)?

    init(
        _ text: String,
        isSelected: Bool = false,
        color: Color = AppPalette.standard.accent,
        action: (() -> Void)? = nil
    ) {
        self.text = text
        self.isSelected = isSelected
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: { action?() }) {
            Text(text)
                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : Color(white: 0.4))
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm + 2)
                .background(
                    Capsule()
                        .fill(isSelected ? color : Color.white.opacity(0.7))
                        .shadow(
                            color: isSelected ? color.opacity(0.3) : Color.black.opacity(0.05),
                            radius: isSelected ? 8 : 3,
                            y: 2
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(action == nil)
    }
}

// MARK: - NutraSafe Divider

struct NutraSafeDivider: View {
    var inset: CGFloat

    init(inset: CGFloat = 0) {
        self.inset = inset
    }

    var body: some View {
        Rectangle()
            .fill(Color(white: 0.9))
            .frame(height: 1)
            .padding(.leading, inset)
    }
}

// MARK: - NutraSafe List Row

struct NutraSafeListRow<Content: View>: View {
    let icon: String
    let iconColor: Color
    let content: Content
    var showChevron: Bool
    var action: (() -> Void)?

    init(
        icon: String,
        iconColor: Color = AppPalette.standard.accent,
        showChevron: Bool = true,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.showChevron = showChevron
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: DesignTokens.Spacing.md) {
                // Icon with subtle background
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor)
                }

                content

                Spacer()

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(white: 0.7))
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.md - 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(action == nil)
    }
}

// MARK: - NutraSafe Signal Icon (Unified Insight/Warning Icon)

/// A neutral, flexible signal icon for insights, warnings, and notifications.
/// This replaces generic box icons and alert triangles with a calm, observational symbol.
/// Use this instead of exclamationmark.triangle or other alarm-like icons.
struct NutraSafeSignalIcon: View {
    let color: Color
    var size: CGFloat = 18

    var body: some View {
        ZStack {
            // Inner dot (core signal)
            Circle()
                .fill(color)
                .frame(width: size * 0.33, height: size * 0.33)

            // Middle arc (signal wave)
            Circle()
                .trim(from: 0.0, to: 0.25)
                .stroke(color, style: StrokeStyle(lineWidth: size * 0.11, lineCap: .round))
                .frame(width: size * 0.72, height: size * 0.72)
                .rotationEffect(.degrees(-45))

            // Outer arc (signal wave, faded)
            Circle()
                .trim(from: 0.0, to: 0.25)
                .stroke(color.opacity(0.6), style: StrokeStyle(lineWidth: size * 0.11, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-45))
        }
        .frame(width: size, height: size)
    }
}

/// Rounded container for signal icon with background
struct SignalIconContainer: View {
    let color: Color
    var size: CGFloat = 32
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(colorScheme == .dark ? 0.2 : 0.12))
                .frame(width: size, height: size)

            NutraSafeSignalIcon(color: color, size: size * 0.55)
        }
    }
}

// MARK: - NutraSafe Insight Banner

/// Insight banner for nutrition tips, warnings, and achievements.
/// Uses the signal icon for a calm, observational tone.
struct NutraSafeInsightBanner: View {
    let message: String
    var level: InsightLevel = .neutral
    var showIcon: Bool = true

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    enum InsightLevel {
        case positive   // Good news, achievement, success
        case neutral    // Information, suggestion, tip
        case caution    // Warning, concern, attention needed

        var color: Color {
            switch self {
            case .positive: return SemanticColors.positive
            case .neutral: return SemanticColors.neutral
            case .caution: return SemanticColors.caution
            }
        }
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            if showIcon {
                NutraSafeSignalIcon(color: level.color, size: 20)
            }

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(DesignTokens.Spacing.lineSpacing)

            Spacer(minLength: 0)
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(level.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .stroke(level.color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Scroll To Top on Appear

/// A ScrollView wrapper that automatically scrolls to top when the view appears.
/// Use this to ensure users always start at the top when returning to a tab/page.
struct ScrollViewWithTopReset<Content: View>: View {
    let axes: Axis.Set
    let showsIndicators: Bool
    let content: Content

    @State private var scrollID = UUID()

    init(
        _ axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.content = content()
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(axes, showsIndicators: showsIndicators) {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 0)
                        .id("scrollTop")

                    content
                }
            }
            .onAppear {
                // Small delay to ensure view is rendered before scrolling
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.none) {
                        proxy.scrollTo("scrollTop", anchor: .top)
                    }
                }
            }
        }
    }
}

/// View modifier to add scroll-to-top behavior to any view containing a ScrollView.
/// Apply to parent views that should reset scroll position on appear.
struct ScrollToTopOnAppearModifier: ViewModifier {
    let scrollViewID: String
    @State private var shouldScrollToTop = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                shouldScrollToTop = true
            }
            .onDisappear {
                shouldScrollToTop = false
            }
            .environment(\.scrollToTopTrigger, shouldScrollToTop)
    }
}

/// Environment key for scroll-to-top trigger
private struct ScrollToTopTriggerKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var scrollToTopTrigger: Bool {
        get { self[ScrollToTopTriggerKey.self] }
        set { self[ScrollToTopTriggerKey.self] = newValue }
    }
}

extension View {
    /// Modifier that resets scroll position to top when view appears
    func scrollsToTopOnAppear(id: String = "scrollTop") -> some View {
        modifier(ScrollToTopOnAppearModifier(scrollViewID: id))
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            NutraSafeHeadline("Design System Preview")
                .padding(.top, 40)

            NutraSafeSectionHeader(
                title: "Cards & Containers",
                subtitle: "Unified card styling"
            )

            NutraSafeCard {
                Text("Basic card content")
                    .foregroundColor(Color(white: 0.3))
            }

            NutraSafeFeatureRow(
                icon: "sparkles",
                title: "Smart Detection",
                description: "Automatically identifies patterns in your data",
                iconColor: .purple
            )

            NutraSafeInfoCard(
                icon: "info.circle.fill",
                text: "This is an informational message with a calming blue accent."
            )

            NutraSafeWarningCard(
                "Important notice that requires attention but isn't alarming."
            )

            NutraSafeSectionHeader(title: "Buttons")

            NutraSafePrimaryButton("Continue", showShimmer: true) {}
                .padding(.horizontal)

            NutraSafeSecondaryButton("Skip for now", icon: "arrow.right") {}

            NutraSafeSectionHeader(title: "Empty State")

            NutraSafeEmptyState(
                icon: "doc.text",
                title: "No entries yet",
                subtitle: "Start tracking to see your data here",
                actionTitle: "Add Entry"
            ) {}
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
    .background(AmbientGradientBackground())
}
