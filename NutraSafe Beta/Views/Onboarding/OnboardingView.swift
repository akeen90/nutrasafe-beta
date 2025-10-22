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

                // Screen 9: All Set!
                CompletionScreen(onComplete: onComplete)
                    .tag(8)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }
}
