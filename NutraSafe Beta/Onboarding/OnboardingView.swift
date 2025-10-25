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
            Group {
                switch currentPage {
                case 0:
                    WelcomeScreen(currentPage: $currentPage)
                case 1:
                    DisclaimerScreen(currentPage: $currentPage)
                case 2:
                    AddingFoodScreen(currentPage: $currentPage)
                case 3:
                    FoodDetailScreen(currentPage: $currentPage)
                case 4:
                    TrackingNutrientsScreen(currentPage: $currentPage)
                case 5:
                    FoodReactionsScreen(currentPage: $currentPage)
                case 6:
                    FastingTimerScreen(currentPage: $currentPage)
                case 7:
                    UseByTrackerScreen(currentPage: $currentPage)
                case 8:
                    SettingsFeatureScreen(currentPage: $currentPage)
                default:
                    CompletionScreen(onComplete: onComplete)
                }
            }
        }

    }
}
