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
        iconColor: Color = .blue,
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

// MARK: - NutraSafe Primary Button

struct NutraSafePrimaryButton: View {
    let text: String
    let action: () -> Void
    var isEnabled: Bool
    var showShimmer: Bool
    var gradient: [Color]

    @State private var shimmerOffset: CGFloat = -200

    init(
        _ text: String,
        isEnabled: Bool = true,
        showShimmer: Bool = false,
        gradient: [Color]? = nil,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.isEnabled = isEnabled
        self.showShimmer = showShimmer
        self.gradient = gradient ?? [
            Color(red: 0.20, green: 0.45, blue: 0.50),
            Color(red: 0.15, green: 0.35, blue: 0.42)
        ]
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                // Base gradient
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(
                        isEnabled
                            ? LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                    )

                // Shimmer overlay
                if showShimmer && isEnabled {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .fill(
                            LinearGradient(
                                colors: [Color.clear, Color.white.opacity(0.3), Color.clear],
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
            .frame(height: 56)
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

// MARK: - NutraSafe Secondary Button

struct NutraSafeSecondaryButton: View {
    let text: String
    let action: () -> Void
    var icon: String?

    init(_ text: String, icon: String? = nil, action: @escaping () -> Void) {
        self.text = text
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                Text(text)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(Color(white: 0.4))
            .frame(height: 44)
        }
    }
}

// MARK: - NutraSafe Info Card (from onboarding InfoCard)

struct NutraSafeInfoCard: View {
    let icon: String
    let text: String
    var iconColor: Color
    var backgroundColor: Color

    init(
        icon: String,
        text: String,
        iconColor: Color = .blue,
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

// MARK: - NutraSafe Warning Card (from onboarding WarningCard)

struct NutraSafeWarningCard: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundColor(.orange)

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
                .fill(Color.orange.opacity(0.08))
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
        iconColor: Color = .blue
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

// MARK: - NutraSafe Insight Card

struct NutraSafeInsightCard: View {
    let icon: String
    let title: String
    let value: String
    var trend: InsightTrend?
    var iconColor: Color

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
        iconColor: Color = .blue
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.trend = trend
        self.iconColor = iconColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)

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
                    .foregroundColor(Color(white: 0.2))

                Text(title)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(Color(white: 0.5))
            }
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(Color.nutraSafeCard)
                .shadow(color: DesignTokens.Shadow.subtle.color,
                        radius: DesignTokens.Shadow.subtle.radius,
                        y: DesignTokens.Shadow.subtle.y)
        )
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
        color: Color = .blue,
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
        iconColor: Color = .blue,
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
                text: "Important notice that requires attention but isn't alarming."
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
