//
//  CustomTabBar.swift
//  NutraSafe Beta
//
//  Custom tab bar component - UNIFIED with onboarding design system.
//  NO platform blue. Palette-aware throughout.
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: TabItem
    @Binding var showingAddMenu: Bool
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    // FIX: Fixed height prevents layout recalculation when content changes
    private let tabBarHeight: CGFloat = 80

    // PERFORMANCE: Pre-created haptic generator to avoid allocation on tap
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                if tab == .add {
                    // Central Add button with palette accent - no platform blue
                    Button(action: {
                        showingAddMenu = true
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }) {
                        ZStack {
                            // Gradient circle with palette colors
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [palette.accent, palette.primary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                                .shadow(color: palette.accent.opacity(0.35), radius: 10, x: 0, y: 5)

                            Image(systemName: tab.icon)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(showingAddMenu ? 45 : 0))
                                .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.8), value: showingAddMenu)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    // FIX: Use fixed positioning within allocated space instead of offset
                    .alignmentGuide(.bottom) { d in d[.bottom] + 10 }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    // Regular tab buttons with palette-aware colors
                    Button(action: {
                        // PERFORMANCE: Wrap state change in transaction to disable animation
                        var transaction = Transaction()
                        transaction.animation = nil
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            selectedTab = tab
                        }
                        hapticGenerator.impactOccurred()
                    }) {
                        VStack(alignment: .center, spacing: 4) {
                            ZStack {
                                // Selected indicator glow
                                if selectedTab == tab {
                                    Circle()
                                        .fill(palette.accent.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                }

                                Image(systemName: tab.icon)
                                    .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .regular))
                                    .foregroundColor(selectedTab == tab ? palette.accent : palette.textTertiary)
                            }

                            if !tab.title.isEmpty {
                                Text(tab.title)
                                    .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .medium))
                                    .foregroundColor(selectedTab == tab ? palette.accent : palette.textTertiary)
                                    .lineLimit(1)
                                    .fixedSize()
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 2)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    // PERFORMANCE: Disable implicit animations on tab selection indicator
                    .animation(nil, value: selectedTab)
                }
            }
        }
        .frame(height: tabBarHeight) // FIX: Fixed height prevents layout shifts
        .padding(.horizontal, 16)
        .background(
            // Glassmorphic tab bar background
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)

                // Subtle palette gradient tint
                LinearGradient(
                    colors: [
                        palette.primary.opacity(0.03),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .overlay(
            // Top border
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 0.5),
            alignment: .top
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: -6)
    }
}
