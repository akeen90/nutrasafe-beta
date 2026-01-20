//
//  OnboardingTheme.swift
//  NutraSafe Beta
//
//  Premium onboarding color system with user-adaptive palettes
//

import SwiftUI

// MARK: - User Intent (drives color palette)

enum UserIntent: String, CaseIterable {
    case safer = "safer"
    case lighter = "lighter"
    case control = "control"

    var headline: String {
        switch self {
        case .safer: return "I'd feel safer"
        case .lighter: return "I'd feel lighter"
        case .control: return "I'd feel in control"
        }
    }

    var personalizedMessage: String {
        switch self {
        case .safer:
            return "We'll watch for allergens and sensitivities in everything you scan. Warnings will be clear, immediate, and impossible to miss. You'll never have to squint at a label again."
        case .lighter:
            return "We'll surface what matters: energy, balance, how foods make you feel. No calorie obsession. Just clarity about what nourishes you."
        case .control:
            return "With your preferences mapped, you'll see exactly what works for you—and what doesn't—before it's on your plate. Knowledge is power."
        }
    }

    var personalizedMessageWithSensitivities: String {
        switch self {
        case .safer:
            return "We'll watch for your specific sensitivities in everything you scan. Warnings will be clear, immediate, and impossible to miss. You'll never have to squint at a label again."
        case .lighter:
            return "We'll surface what matters while keeping an eye on your sensitivities. No calorie obsession. Just clarity about what nourishes you."
        case .control:
            return "With your sensitivities mapped, you'll see exactly what's safe—and what isn't—before it's on your plate. Knowledge is power."
        }
    }
}

// MARK: - Onboarding Palette

struct OnboardingPalette {
    let primary: Color
    let secondary: Color
    let tertiary: Color
    let accent: Color
    let background: Color
    let backgroundDeep: Color

    // Default neutral palette (before intent selection)
    static let neutral = OnboardingPalette(
        primary: Color(red: 0.92, green: 0.90, blue: 0.87),    // Warm cream
        secondary: Color(red: 0.78, green: 0.75, blue: 0.71),  // Warm gray
        tertiary: Color(red: 0.45, green: 0.52, blue: 0.55),   // Cool slate
        accent: Color(red: 0.20, green: 0.45, blue: 0.50),     // Deep teal
        background: Color(red: 0.98, green: 0.97, blue: 0.95), // Off-white
        backgroundDeep: Color(red: 0.94, green: 0.93, blue: 0.90)
    )

    // "Safer" - Deep teal, midnight blue, silver
    static let safer = OnboardingPalette(
        primary: Color(red: 0.12, green: 0.40, blue: 0.45),    // Deep teal
        secondary: Color(red: 0.15, green: 0.22, blue: 0.35),  // Midnight blue
        tertiary: Color(red: 0.70, green: 0.75, blue: 0.78),   // Silver
        accent: Color(red: 0.00, green: 0.60, blue: 0.55),     // Bright teal
        background: Color(red: 0.95, green: 0.97, blue: 0.97), // Cool white
        backgroundDeep: Color(red: 0.12, green: 0.40, blue: 0.45)
    )

    // "Lighter" - Sunrise peach, soft coral, warm cream
    static let lighter = OnboardingPalette(
        primary: Color(red: 0.95, green: 0.70, blue: 0.55),    // Sunrise peach
        secondary: Color(red: 0.90, green: 0.55, blue: 0.50),  // Soft coral
        tertiary: Color(red: 0.98, green: 0.92, blue: 0.85),   // Warm cream
        accent: Color(red: 0.95, green: 0.50, blue: 0.40),     // Bright coral
        background: Color(red: 0.99, green: 0.96, blue: 0.94), // Warm white
        backgroundDeep: Color(red: 0.95, green: 0.70, blue: 0.55)
    )

    // "In control" - Sage green, warm stone, grounded earth
    static let control = OnboardingPalette(
        primary: Color(red: 0.55, green: 0.65, blue: 0.50),    // Sage green
        secondary: Color(red: 0.60, green: 0.55, blue: 0.48),  // Warm stone
        tertiary: Color(red: 0.45, green: 0.40, blue: 0.35),   // Grounded earth
        accent: Color(red: 0.45, green: 0.60, blue: 0.40),     // Fresh green
        background: Color(red: 0.97, green: 0.96, blue: 0.94), // Natural white
        backgroundDeep: Color(red: 0.55, green: 0.65, blue: 0.50)
    )

    static func forIntent(_ intent: UserIntent?) -> OnboardingPalette {
        guard let intent = intent else { return .neutral }
        switch intent {
        case .safer: return .safer
        case .lighter: return .lighter
        case .control: return .control
        }
    }
}

// MARK: - Typography Styles

struct OnboardingTypography {
    // Large editorial headline - serif feel
    static func headline(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 32, weight: .bold, design: .serif))
            .tracking(-0.5)
    }

    // Medium headline
    static func subheadline(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 24, weight: .semibold, design: .serif))
            .tracking(-0.3)
    }

    // Body text - light, generous spacing
    static func body(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 17, weight: .regular, design: .default))
            .tracking(0.2)
            .lineSpacing(6)
    }

    // Subtle caption
    static func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .regular, design: .default))
            .tracking(0.4)
    }

    // Button text
    static func button(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 17, weight: .semibold, design: .default))
            .tracking(0.3)
    }

    // Single word emphasis
    static func singleWord(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 28, weight: .medium, design: .default))
            .tracking(1.5)
    }
}

// MARK: - Sensitivities

enum FoodSensitivity: String, CaseIterable, Identifiable {
    case gluten = "Gluten"
    case dairy = "Dairy"
    case nuts = "Nuts"
    case soy = "Soy"
    case eggs = "Eggs"
    case shellfish = "Shellfish"
    case sulphites = "Sulphites"
    case nightshades = "Nightshades"
    case histamines = "Histamines"
    case caffeine = "Caffeine"
    case alcohol = "Alcohol"
    case nothingSpecific = "Nothing specific"

    var id: String { rawValue }

    var isNone: Bool { self == .nothingSpecific }
}

// MARK: - Onboarding State

class PremiumOnboardingState: ObservableObject {
    @Published var selectedIntent: UserIntent?
    @Published var selectedSensitivities: Set<FoodSensitivity> = []
    @Published var hasAcceptedDisclaimer: Bool = false
    @Published var emailConsent: Bool = false

    var palette: OnboardingPalette {
        OnboardingPalette.forIntent(selectedIntent)
    }

    var hasSensitivities: Bool {
        !selectedSensitivities.isEmpty && !selectedSensitivities.contains(.nothingSpecific)
    }

    var personalizedMessage: String {
        guard let intent = selectedIntent else { return "" }
        return hasSensitivities ? intent.personalizedMessageWithSensitivities : intent.personalizedMessage
    }

    // Save to OnboardingManager for persistence
    func saveToManager() {
        if let intent = selectedIntent {
            UserDefaults.standard.set(intent.rawValue, forKey: "userIntent")
        }
        let sensitivitiesArray = selectedSensitivities.map { $0.rawValue }
        UserDefaults.standard.set(sensitivitiesArray, forKey: "userSensitivities")
    }

    // Load from UserDefaults
    func loadFromDefaults() {
        if let intentRaw = UserDefaults.standard.string(forKey: "userIntent"),
           let intent = UserIntent(rawValue: intentRaw) {
            selectedIntent = intent
        }
        if let sensitivitiesArray = UserDefaults.standard.stringArray(forKey: "userSensitivities") {
            selectedSensitivities = Set(sensitivitiesArray.compactMap { FoodSensitivity(rawValue: $0) })
        }
    }
}
