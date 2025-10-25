//
//  OnboardingView.swift
//  NutraSafe Beta
//
//  Main onboarding container with TabView pagination
//  Created by Claude on 2025-10-22.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            TabView(selection: $currentPage) {
                // Screen 1: Welcome
                WelcomeScreen(currentPage: $currentPage)
                    .tag(0)

                // Screen 2: Health Disclaimer (Required)
                DisclaimerScreen(currentPage: $currentPage)
                    .tag(1)

                // Screen 3: Adding Food
                AddingFoodScreen(currentPage: $currentPage)
                    .tag(2)

                // Screen 4: Food Detail Page
                FoodDetailScreen(currentPage: $currentPage)
                    .tag(3)

                // Screen 5: Tracking Nutrients
                TrackingNutrientsScreen(currentPage: $currentPage)
                    .tag(4)

                // Screen 6: Food Reactions
                FoodReactionsScreen(currentPage: $currentPage)
                    .tag(5)

                // Screen 7: Fasting Timer
                FastingTimerScreen(currentPage: $currentPage)
                    .tag(6)

                // Screen 8: Use By Tracker
                UseByTrackerScreen(currentPage: $currentPage)
                    .tag(7)

                // Screen 9: Optional Features (Notifications & Apple Health)
                OptionalFeaturesScreen(currentPage: $currentPage)
                    .tag(8)

                // Screen 10: All Set!
                CompletionScreen(onComplete: onComplete)
                    .tag(9)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .indexViewStyle(.page(backgroundDisplayMode: .never))
        }
        .overlay(alignment: .bottom) {
            ProgressCapsuleBar(current: currentPage, total: 10)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
        }
    }

    struct AnimatedGradientBackground: View {
        @State private var animate = false
        var body: some View {
            LinearGradient(colors: [Color.indigo, Color.blue, Color.purple, Color.cyan],
                           startPoint: animate ? .topLeading : .bottomTrailing,
                           endPoint: animate ? .bottomTrailing : .topLeading)
                .ignoresSafeArea()
                .animation(.linear(duration: 8).repeatForever(autoreverses: true), value: animate)
                .onAppear { animate.toggle() }
        }
    }

    struct ProgressCapsuleBar: View {
        let current: Int
        let total: Int
        var body: some View {
            GeometryReader { geo in
                let progress = CGFloat(current + 1) / CGFloat(total)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.25))
                        .frame(height: 8)
                    Capsule()
                        .fill(LinearGradient(colors: [Color.white, Color.white.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}
