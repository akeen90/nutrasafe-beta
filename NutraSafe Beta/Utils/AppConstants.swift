import SwiftUI
import UIKit
import Combine

// MARK: - App Design Constants
// Unified design system extending onboarding patterns across the app

enum AppSpacing {
    static let xs: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 40
    static let section: CGFloat = 60

    // Semantic aliases
    static let screenEdge: CGFloat = 24
    static let cardInternal: CGFloat = 20
    static let betweenCards: CGFloat = 16
    static let lineSpacing: CGFloat = 6
}

enum AppRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xl: CGFloat = 20
    static let pill: CGFloat = 28
}

// MARK: - App Colors
enum AppColors {
    static let cardBackgroundInteractive = Color(.systemGray6)
    static let cardBackgroundElevated = Color(.systemGray5)
    static let borderLight = Color(.separator)
    static let border = Color(.separator)
    static let primary = Color.accentColor
}

// MARK: - App Typography (Extended with Onboarding Patterns)
enum AppTypography {
    static func largeTitle() -> Font {
        .largeTitle
    }

    static func title3(weight: Font.Weight = .regular) -> Font {
        .title3.weight(weight)
    }

    static func caption2(weight: Font.Weight = .regular) -> Font {
        .caption2.weight(weight)
    }

    // Editorial headline - serif, impactful (from onboarding)
    static func headline(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .serif)
    }

    // Section title - serif warmth
    static func sectionTitle(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }

    // Body with proper line height
    static let body: Font = .system(size: 17, weight: .regular)

    // Caption for subtle text
    static let caption: Font = .system(size: 14, weight: .regular)

    // Button label
    static let button: Font = .system(size: 17, weight: .semibold)

    // Small label
    static let label: Font = .system(size: 13, weight: .medium)
}

// MARK: - Adaptive Text Colors (Light/Dark Mode)
extension Color {
    static let textPrimary = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(white: 0.95, alpha: 1.0)
            : UIColor(white: 0.2, alpha: 1.0)
    })

    static let textSecondary = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(white: 0.75, alpha: 1.0)
            : UIColor(white: 0.4, alpha: 1.0)
    })

    static let textTertiary = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(white: 0.6, alpha: 1.0)
            : UIColor(white: 0.5, alpha: 1.0)
    })
}

// MARK: - App Animation
enum AppAnimation {
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let quick = Animation.easeInOut(duration: 0.2)
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Card Shadow Modifiers (Extended with Onboarding Patterns)
extension View {
    /// Standard card shadow - subtle lift
    func cardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    /// Elevated card shadow - more prominent
    func elevatedShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 6)
    }

    /// Accent shadow - colored glow for selected states
    func accentShadow(_ color: Color) -> some View {
        self.shadow(color: color.opacity(0.3), radius: 15, x: 0, y: 5)
    }
}

// MARK: - Consistent Card Background Modifier
/// Applies the standard white card background used throughout the app
/// Matches the Diet page's clean card styling for visual consistency
struct CardBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(colorScheme == .dark ? Color.midnightCard : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            )
    }
}

extension View {
    func cardBackground(cornerRadius: CGFloat = 16) -> some View {
        self.modifier(CardBackgroundModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Tab Gradient Backgrounds
/// Reusable gradient backgrounds for each tab with consistent premium styling
/// Light mode: Beautiful soft gradients matching Diary's design
/// Dark mode: Midnight blue trading-platform style
struct TabGradientBackground: View {
    @Environment(\.colorScheme) var colorScheme
    let theme: TabTheme

    enum TabTheme {
        case diary      // Blue-purple (existing)
        case progress   // Teal-green (weight/fitness)
        case health     // Purple-pink (reactions/fasting)
        case useBy      // Orange-amber (expiry tracking)
        case settings   // Settings pages
        case insights   // Insights tab

        var lightGradientColors: (primary: Color, secondary: Color) {
            // All tabs use the same blue-purple gradient as Diary for consistency
            return (
                Color(red: 0.92, green: 0.96, blue: 1.0),
                Color(red: 0.93, green: 0.88, blue: 1.0)
            )
        }

        var accentColor: Color {
            // All tabs use blue accent for consistency
            return .blue
        }

        var secondaryAccent: Color {
            // All tabs use purple secondary accent for consistency
            return .purple
        }
    }

    var body: some View {
        Group {
            if colorScheme == .dark {
                // Dark mode: Midnight blue trading-platform style
                Color.midnightBackground
                    .ignoresSafeArea()
            } else {
                // Light mode: Beautiful themed gradient
                ZStack {
                    LinearGradient(
                        colors: [
                            theme.lightGradientColors.primary,
                            theme.lightGradientColors.secondary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    RadialGradient(
                        colors: [theme.accentColor.opacity(0.10), Color.clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 300
                    )
                    RadialGradient(
                        colors: [theme.secondaryAccent.opacity(0.08), Color.clear],
                        center: .bottomTrailing,
                        startRadius: 0,
                        endRadius: 280
                    )
                }
                .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Modern Glass Card Style
/// Premium frosted glass card effect for content sections
struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color.midnightCard : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: colorScheme == .dark
                                        ? [Color.white.opacity(0.1), Color.white.opacity(0.05)]
                                        : [Color.white.opacity(0.8), Color.white.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 12, x: 0, y: 4)
            )
    }
}

// MARK: - View Extension for Tab Backgrounds
extension View {
    /// Apply a themed gradient background to a tab view
    func tabGradientBackground(_ theme: TabGradientBackground.TabTheme) -> some View {
        self.background(TabGradientBackground(theme: theme))
    }
}

// MARK: - Modern Tab Header View
/// Redesigned tab header with unified pill containing both tabs and settings cog
/// Now palette-aware - uses user's onboarding intent colors
struct TabHeaderView<Tab: Hashable & CaseIterable & RawRepresentable>: View where Tab.RawValue == String {
    @Environment(\.colorScheme) var colorScheme
    let tabs: [Tab]
    @Binding var selectedTab: Tab
    let onSettingsTapped: () -> Void
    var actionIcon: String = "gearshape.fill"
    @Namespace private var animation

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(tabs, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        Text(tab.rawValue)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(selectedTab == tab ? palette.accent : palette.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                ZStack {
                                    if selectedTab == tab {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                                            .shadow(color: palette.accent.opacity(0.15), radius: 4, x: 0, y: 2)
                                            .matchedGeometryEffect(id: "tabHeaderSelection", in: animation)
                                    }
                                }
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            Button(action: onSettingsTapped) {
                ZStack {
                    Circle()
                        .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                        .frame(width: 36, height: 36)
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    Image(systemName: actionIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(palette.textTertiary)
                }
                .padding(.trailing, 4)
                .padding(.leading, 8)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

// MARK: - Onboarding-Style Components

/// Premium Info Card (from onboarding InfoBullet pattern)
struct NSInfoCard: View {
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
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(AppSpacing.lineSpacing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .fill(backgroundColor)
        )
    }
}

/// Premium Warning Card (from onboarding pattern)
struct NSWarningCard: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundColor(.orange)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(AppSpacing.lineSpacing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .fill(Color.orange.opacity(0.08))
        )
    }
}

/// Premium Empty State (calm, not alarming)
struct EmptyStateView: View {
    let icon: String
    let title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            Image(systemName: icon)
                .font(.system(size: 60, weight: .light))
                .foregroundColor(Color.textTertiary.opacity(0.4))

            VStack(spacing: AppSpacing.small) {
                Text(title)
                    .font(AppTypography.sectionTitle(20))
                    .foregroundColor(Color.textSecondary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTypography.body)
                        .foregroundColor(Color.textTertiary)
                        .multilineTextAlignment(.center)
                }
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTypography.button)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppSpacing.large)
                        .padding(.vertical, AppSpacing.medium)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.large)
                                .fill(AppPalette.standard.accent)
                        )
                }
            }
        }
        .padding(.vertical, AppSpacing.section)
        .frame(maxWidth: .infinity)
    }
}

/// Section Header with serif typography (from onboarding)
struct NSSectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppTypography.sectionTitle())
                .foregroundColor(Color.textPrimary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundColor(Color.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Feature Row with icon (from onboarding InfoBullet)
struct NSFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    var iconColor: Color

    @Environment(\.colorScheme) private var colorScheme

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
        HStack(alignment: .top, spacing: AppSpacing.medium) {
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
                .cornerRadius(AppRadius.medium)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color.textPrimary)

                Text(description)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.large)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
        )
        .cardShadow()
    }
}

/// Insight Card with trend indicator
struct InsightCard: View {
    let icon: String
    let title: String
    let value: String
    var trend: InsightTrend?
    var iconColor: Color

    @Environment(\.colorScheme) private var colorScheme

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
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
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

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Color.textPrimary)

                Text(title)
                    .font(AppTypography.caption)
                    .foregroundColor(Color.textTertiary)
            }
        }
        .padding(AppSpacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.large)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
        )
        .cardShadow()
    }
}

/// Breathing animation modifier (from onboarding)
struct BreathingModifier: ViewModifier {
    let intensity: CGFloat
    @State private var isBreathing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isBreathing ? 1 + intensity : 1 - intensity * 0.5)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    isBreathing = true
                }
            }
    }
}

extension View {
    /// Apply breathing animation (from onboarding)
    func breathing(intensity: CGFloat = 0.05) -> some View {
        modifier(BreathingModifier(intensity: intensity))
    }
}

/// Premium list row (from onboarding patterns)
struct ListRow<Content: View>: View {
    let icon: String
    let iconColor: Color
    let content: Content
    var showChevron: Bool
    var action: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

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
            HStack(spacing: AppSpacing.medium) {
                // Icon with subtle circular background
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
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.medium - 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(action == nil)
    }
}

/// Tag / Chip component (from onboarding patterns)
struct TagView: View {
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
                .foregroundColor(isSelected ? .white : Color.textSecondary)
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.small + 2)
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

/// Primary button matching onboarding style
struct PrimaryButton: View {
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
                RoundedRectangle(cornerRadius: AppRadius.large)
                    .fill(
                        isEnabled
                            ? LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                    )

                if showShimmer && isEnabled {
                    RoundedRectangle(cornerRadius: AppRadius.large)
                        .fill(
                            LinearGradient(
                                colors: [Color.clear, Color.white.opacity(0.3), Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerOffset)
                        .mask(RoundedRectangle(cornerRadius: AppRadius.large))
                }

                Text(text)
                    .font(AppTypography.button)
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

// MARK: - UIApplication Keyboard Extension

extension UIApplication {
    /// Dismiss the keyboard by ending editing on the active window
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Global Keyboard Dismissal Helper

/// Programmatically dismiss the keyboard from anywhere
func dismissKeyboard() {
    UIApplication.shared.endEditing()
}

// MARK: - Keyboard Observer

/// Global keyboard observer for tracking keyboard visibility across the app
class KeyboardObserver: ObservableObject {
    static let shared = KeyboardObserver()

    @Published var keyboardHeight: CGFloat = 0
    @Published var isKeyboardVisible: Bool = false

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        // Filter out floating/split keyboards on iPad (they're too small to position against)
        guard keyboardFrame.height > 100 else { return }

        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.keyboardHeight = keyboardFrame.height
                self.isKeyboardVisible = true
            }
        }
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        // Filter out floating/split keyboards on iPad
        guard keyboardFrame.height > 100 else { return }

        // Update keyboard height when it changes (e.g., switching between email and password fields)
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.25)) {
                self.keyboardHeight = keyboardFrame.height
                self.isKeyboardVisible = true
            }
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.keyboardHeight = 0
                self.isKeyboardVisible = false
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
