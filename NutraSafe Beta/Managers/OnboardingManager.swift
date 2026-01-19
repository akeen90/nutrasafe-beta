//
//  OnboardingManager.swift
//  NutraSafe Beta
//
//  Manages onboarding completion status, user disclaimer acceptance,
//  and basic user profile (gender, birthday)
//  Created by Claude on 2025-10-22.
//

import Foundation
import SwiftUI

class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()

    private let hasCompletedKey = "hasCompletedOnboarding"
    private let hasAcceptedDisclaimerKey = "hasAcceptedDisclaimer"
    private let userGenderKey = "userGender"
    private let userBirthdayKey = "userBirthday"

    /// Tracks if onboarding was just completed in this session (for tip delay)
    @Published var justCompletedOnboarding = false

    /// Published user profile data
    @Published var userGender: UserGender = .notSet
    @Published var userBirthday: Date?

    private init() {
        // Load saved values
        loadUserProfile()
    }

    private func loadUserProfile() {
        // Load gender
        if let savedGender = UserDefaults.standard.string(forKey: userGenderKey),
           let gender = UserGender(rawValue: savedGender) {
            userGender = gender
        }

        // Load birthday
        if let savedBirthday = UserDefaults.standard.object(forKey: userBirthdayKey) as? Date {
            userBirthday = savedBirthday
        }
    }

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
        justCompletedOnboarding = true
            }

    /// Mark disclaimer as accepted
    func acceptDisclaimer() {
        UserDefaults.standard.set(true, forKey: hasAcceptedDisclaimerKey)
            }

    /// Reset onboarding (for restart from Settings)
    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: hasCompletedKey)
        // Note: We don't reset disclaimer acceptance - user has already agreed
        // Note: We don't reset gender/birthday - those are user profile data
    }

    // MARK: - User Profile

    /// Save user gender
    func saveGender(_ gender: UserGender) {
        userGender = gender
        UserDefaults.standard.set(gender.rawValue, forKey: userGenderKey)
    }

    /// Save user birthday
    func saveBirthday(_ birthday: Date?) {
        userBirthday = birthday
        if let birthday = birthday {
            UserDefaults.standard.set(birthday, forKey: userBirthdayKey)
        } else {
            UserDefaults.standard.removeObject(forKey: userBirthdayKey)
        }
    }

    /// Calculate user's age from birthday
    var userAge: Int? {
        guard let birthday = userBirthday else { return nil }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: Date())
        return ageComponents.year
    }

    /// Check if user has set their profile (gender and birthday)
    var hasSetProfile: Bool {
        userGender != .notSet && userBirthday != nil
    }
}

// MARK: - User Gender Enum

/// Gender options for user profile (separate from the nutrition model Gender enum)
enum UserGender: String, CaseIterable, Codable {
    case male = "male"
    case female = "female"
    case other = "other"
    case notSet = "notSet"

    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other / Prefer not to say"
        case .notSet: return "Not set"
        }
    }

    var icon: String {
        switch self {
        case .male: return "figure.stand"
        case .female: return "figure.stand.dress"
        case .other: return "person.fill"
        case .notSet: return "person.fill.questionmark"
        }
    }

    /// Convert to nutrition model Gender for calculations
    var toNutritionGender: Gender {
        switch self {
        case .male: return .male
        case .female: return .female
        case .other, .notSet: return .other
        }
    }
}
