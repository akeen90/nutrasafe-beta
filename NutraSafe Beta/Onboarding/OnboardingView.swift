//
//  OnboardingView.swift
//  NutraSafe Beta
//
//  Updated onboarding container with 4-screen flow
//  Created on 2025-10-27
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
                    CoreFeaturesScreen(currentPage: $currentPage)
                case 2:
                    AdvancedFeaturesScreen(currentPage: $currentPage)
                default:
                    GetStartedScreen(currentPage: $currentPage, onComplete: onComplete)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: currentPage)
        }
    }
}

// MARK: - Page Indicator (Optional - can add if desired)

struct PageIndicator: View {
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: currentPage == index ? 10 : 8, height: currentPage == index ? 10 : 8)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }
}
