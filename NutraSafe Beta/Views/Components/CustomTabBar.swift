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
                    .offset(y: -10)
                    .buttonStyle(PlainButtonStyle())
                } else {
                    // Regular tab buttons with palette-aware colors
                    Button(action: {
                        selectedTab = tab
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
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
                                    .offset(y: tab == .useBy ? -3 : 0)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 2)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
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
