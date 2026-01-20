import SwiftUI

// MARK: - App Design Constants
// Minimal constants extracted from deleted DesignSystem.swift

enum AppSpacing {
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
}

enum AppRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
}

// MARK: - App Colors
enum AppColors {
    static let cardBackgroundInteractive = Color(.systemGray6)
    static let cardBackgroundElevated = Color(.systemGray5)
    static let borderLight = Color(.separator)
    static let border = Color(.separator)
    static let primary = Color.accentColor
}

// MARK: - App Typography
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

// MARK: - Card Shadow Modifier
extension View {
    func cardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
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
/// Design: Single wide pill with tabs on left and cog integrated on right - creates balanced, centered appearance
struct TabHeaderView<Tab: Hashable & CaseIterable & RawRepresentable>: View where Tab.RawValue == String {
    @Environment(\.colorScheme) var colorScheme
    let tabs: [Tab]
    @Binding var selectedTab: Tab
    let onSettingsTapped: () -> Void
    var actionIcon: String = "gearshape.fill"  // Customizable: "xmark" for close button
    @Namespace private var animation

    var body: some View {
        // Single unified pill container spanning full width
        HStack(spacing: 0) {
            // Tab buttons section
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
                            .foregroundColor(selectedTab == tab ? .blue : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                ZStack {
                                    if selectedTab == tab {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                                            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                                            .matchedGeometryEffect(id: "tabHeaderSelection", in: animation)
                                    }
                                }
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            // Settings button integrated into the pill
            Button(action: onSettingsTapped) {
                ZStack {
                    Circle()
                        .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                        .frame(width: 36, height: 36)
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    Image(systemName: actionIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 4)
                .padding(.leading, 8)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}
