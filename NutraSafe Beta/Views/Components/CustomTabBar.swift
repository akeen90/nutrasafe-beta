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

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                if tab == .add {
                    // Special Add button with circular design
                    Button(action: {
                        // Add tab is free for everyone
                        // When tapping the main plus, default destination based on current tab
                        // If currently on Use By, preselect destination to Use By
                        if selectedTab == .useBy {
                            UserDefaults.standard.set("Use By", forKey: "preselectedDestination")
                        } else {
                            // Clear any previous preselection to ensure Diary is default elsewhere
                            UserDefaults.standard.removeObject(forKey: "preselectedDestination")
                        }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
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
                                .rotationEffect(.degrees(selectedTab == tab ? 90 : 0))
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
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
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundColor(selectedTab == tab ? .blue : Color.gray)
                                .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)

                            if !tab.title.isEmpty {
                                Text(tab.title)
                                    .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .medium))
                                    .foregroundColor(selectedTab == tab ? .blue : Color.gray)
                            }
                        }
                        .frame(maxWidth: .infinity)
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
        .background(
            Color(.systemBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
        )
    }
}