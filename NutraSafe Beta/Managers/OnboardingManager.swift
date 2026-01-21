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
    private let hasSeenWelcomeKey = "hasSeenWelcomeScreen"
    private let userGenderKey = "userGender"
    private let userBirthdayKey = "userBirthday"
    private let userIntentKey = "userIntent"
    private let userSensitivitiesKey = "userSensitivities"
    private let userHeightCmKey = "userHeightCm"
    private let userWeightKgKey = "userWeightKg"
    private let userAllergensKey = "userAllergens"
    private let userOtherSensitivitiesKey = "userOtherSensitivities"

    /// Tracks if onboarding was just completed in this session (for tip delay)
    @Published var justCompletedOnboarding = false

    /// Tracks if welcome screen was just completed in this session
    @Published var justCompletedWelcome = false

    /// Published user profile data
    @Published var userGender: UserGender = .notSet
    @Published var userBirthday: Date?
    @Published var userHeightCm: Double?
    @Published var userWeightKg: Double?

    /// User's selected intent from premium onboarding
    @Published var userIntent: String?

    /// User's selected food sensitivities from premium onboarding (legacy)
    @Published var userSensitivities: [String] = []

    /// User's allergens (maps to Allergen enum for detection)
    @Published var userAllergens: [String] = []

    /// User's other sensitivities/preferences (caffeine, high sugar, etc.)
    @Published var userOtherSensitivities: [String] = []

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

        // Load height and weight
        if UserDefaults.standard.object(forKey: userHeightCmKey) != nil {
            userHeightCm = UserDefaults.standard.double(forKey: userHeightCmKey)
        }
        if UserDefaults.standard.object(forKey: userWeightKgKey) != nil {
            userWeightKg = UserDefaults.standard.double(forKey: userWeightKgKey)
        }

        // Load intent (from premium onboarding)
        if let savedIntent = UserDefaults.standard.string(forKey: userIntentKey) {
            userIntent = savedIntent
        }

        // Load sensitivities (from premium onboarding - legacy)
        if let savedSensitivities = UserDefaults.standard.stringArray(forKey: userSensitivitiesKey) {
            userSensitivities = savedSensitivities
        }

        // Load allergens
        if let savedAllergens = UserDefaults.standard.stringArray(forKey: userAllergensKey) {
            userAllergens = savedAllergens
        }

        // Load other sensitivities/preferences
        if let savedOtherSensitivities = UserDefaults.standard.stringArray(forKey: userOtherSensitivitiesKey) {
            userOtherSensitivities = savedOtherSensitivities
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

    /// Check if user has seen the welcome screen
    var hasSeenWelcome: Bool {
        UserDefaults.standard.bool(forKey: hasSeenWelcomeKey)
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

    /// Mark welcome screen as seen
    func completeWelcome() {
        UserDefaults.standard.set(true, forKey: hasSeenWelcomeKey)
        justCompletedWelcome = true
    }

    /// Reset onboarding (for restart from Settings)
    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: hasCompletedKey)
        UserDefaults.standard.set(false, forKey: hasSeenWelcomeKey)
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

    /// Save user intent (from premium onboarding)
    func saveIntent(_ intent: String?) {
        userIntent = intent
        if let intent = intent {
            UserDefaults.standard.set(intent, forKey: userIntentKey)
        } else {
            UserDefaults.standard.removeObject(forKey: userIntentKey)
        }
    }

    /// Save user sensitivities (from premium onboarding - legacy)
    func saveSensitivities(_ sensitivities: [String]) {
        userSensitivities = sensitivities
        UserDefaults.standard.set(sensitivities, forKey: userSensitivitiesKey)
    }

    /// Save user height in centimeters
    func saveHeight(_ heightCm: Double?) {
        userHeightCm = heightCm
        if let heightCm = heightCm {
            UserDefaults.standard.set(heightCm, forKey: userHeightCmKey)
        } else {
            UserDefaults.standard.removeObject(forKey: userHeightCmKey)
        }
    }

    /// Save user weight in kilograms
    func saveWeight(_ weightKg: Double?) {
        userWeightKg = weightKg
        if let weightKg = weightKg {
            UserDefaults.standard.set(weightKg, forKey: userWeightKgKey)
        } else {
            UserDefaults.standard.removeObject(forKey: userWeightKgKey)
        }
    }

    /// Save user allergens
    func saveAllergens(_ allergens: [String]) {
        userAllergens = allergens
        UserDefaults.standard.set(allergens, forKey: userAllergensKey)
    }

    /// Save user other sensitivities/preferences
    func saveOtherSensitivities(_ sensitivities: [String]) {
        userOtherSensitivities = sensitivities
        UserDefaults.standard.set(sensitivities, forKey: userOtherSensitivitiesKey)
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
