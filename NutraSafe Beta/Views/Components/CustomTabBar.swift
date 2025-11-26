//
//  CustomTabBar.swift
//  NutraSafe Beta
//
//  Custom tab bar component extracted from ContentView.swift
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: TabItem
    @ObservedObject var workoutManager: WorkoutManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    var onBlockedTabAttempt: (() -> Void)? = nil
    @Binding var showingAddMenu: Bool

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                if tab == .add {
                    // Special Add button with circular design - shows menu instead of switching tabs
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showingAddMenu = true
                        }
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 56, height: 56)
                                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)

                            Image(systemName: tab.icon)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(showingAddMenu ? 45 : 0))
                                .animation(.easeOut(duration: 0.25), value: showingAddMenu)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .offset(y: -10) // Lift the add button slightly
                    .buttonStyle(PlainButtonStyle())
                } else {
                    // Regular tab buttons
                    Button(action: {
                        let allowed = subscriptionManager.isSubscribed || subscriptionManager.isInTrial || subscriptionManager.isPremiumOverride || tab == .diary
                        if allowed {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = tab
                            }
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        } else {
                            onBlockedTabAttempt?()
                            let notif = UINotificationFeedbackGenerator()
                            notif.notificationOccurred(.warning)
                        }
                    }) {
                        VStack(alignment: .center, spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundColor(selectedTab == tab ? .blue : Color.gray)
                                .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)

                            if !tab.title.isEmpty {
                                Text(tab.title)
                                    .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .medium))
                                    .foregroundColor(selectedTab == tab ? .blue : Color.gray)
                                    .lineLimit(1)
                                    .fixedSize()
                                    .offset(y: tab == .useBy ? -3 : 0)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                        // No surrounding shade — highlight is icon + label tint only
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