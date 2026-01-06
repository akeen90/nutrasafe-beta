//
//  CustomTabBar.swift
//  NutraSafe Beta
//
//  Custom tab bar component extracted from ContentView.swift
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: TabItem
    @Binding var showingAddMenu: Bool
    // Note: onBlockedTabAttempt removed - soft paywall now allows all tab access

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                if tab == .add {
                    // Special Add button with circular design - shows menu instead of switching tabs
                    Button(action: {
                        showingAddMenu = true
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 56, height: 56)
                                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)

                            Image(systemName: tab.icon)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(showingAddMenu ? 45 : 0))
                                .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.8), value: showingAddMenu)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .offset(y: -10) // Lift the add button slightly
                    .buttonStyle(PlainButtonStyle())
                } else {
                    // Regular tab buttons with large tap targets
                    // SOFT PAYWALL: All tabs are now accessible - premium features are blurred within each tab
                    Button(action: {
                        selectedTab = tab
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }) {
                        VStack(alignment: .center, spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundColor(selectedTab == tab ? .blue : Color.gray)

                            if !tab.title.isEmpty {
                                Text(tab.title)
                                    .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .medium))
                                    .foregroundColor(selectedTab == tab ? .blue : Color.gray)
                                    .lineLimit(1)
                                    .fixedSize()
                                    .offset(y: tab == .useBy ? -3 : 0)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 52) // Increased from 44 for better tap target
                        .padding(.vertical, 6)
                        .padding(.horizontal, 2)
                        .contentShape(Rectangle()) // Ensure entire frame is tappable
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
    }
}