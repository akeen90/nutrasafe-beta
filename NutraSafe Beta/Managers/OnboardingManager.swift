//
//  OnboardingManager.swift
//  NutraSafe Beta
//
//  Manages onboarding completion status and user disclaimer acceptance
//  Created by Claude on 2025-10-22.
//

import Foundation

class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()

    private let hasCompletedKey = "hasCompletedOnboarding"
    private let hasAcceptedDisclaimerKey = "hasAcceptedDisclaimer"

    private init() {}

    /// Check if user has completed onboarding
    var hasCompletedOnboarding: Bool {
        UserDefaults.standard.bool(forKey: hasCompletedKey)
    }

    /// Check if user has accepted health disclaimer
    var hasAcceptedDisclaimer: Bool {
        UserDefaults.standard.bool(forKey: hasAcceptedDisclaimerKey)
    }

    /// Mark onboarding as completed
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: hasCompletedKey)
        #if DEBUG
        print("✅ Onboarding completed")
        #endif
    }

    /// Mark disclaimer as accepted
    func acceptDisclaimer() {
        UserDefaults.standard.set(true, forKey: hasAcceptedDisclaimerKey)
        #if DEBUG
        print("✅ Health disclaimer accepted")
        #endif
    }

    /// Reset onboarding (for restart from Settings)
    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: hasCompletedKey)
        // Note: We don't reset disclaimer acceptance - user has already agreed
    }
}
