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
            return "We'll flag potential allergens and sensitivities in everything you scan. Warnings will be clear and immediate—helping you make informed decisions faster."
        case .lighter:
            return "We'll surface what matters: energy, balance, how foods make you feel. No calorie obsession. Just clarity about what nourishes you."
        case .control:
            return "With your preferences mapped, you'll see exactly what works for you—and what doesn't—before it's on your plate. Knowledge is power."
        }
    }

    var personalizedMessageWithSensitivities: String {
        switch self {
        case .safer:
            return "We'll flag your specific sensitivities in everything you scan. Warnings will be clear and immediate—helping you make informed decisions faster. Always check labels for your safety."
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

// MARK: - Goals & Lifestyle Enums

enum OnboardingGoal: String, CaseIterable, Identifiable {
    case loseWeight = "Lose weight"
    case buildMuscle = "Build muscle"
    case eatHealthier = "Eat healthier"
    case trackNutrition = "Track nutrition"
    case foodSafety = "Food safety"
    case manageAllergies = "Manage allergies"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .loseWeight: return "flame"
        case .buildMuscle: return "dumbbell"
        case .eatHealthier: return "leaf"
        case .trackNutrition: return "chart.bar"
        case .foodSafety: return "shield.checkered"
        case .manageAllergies: return "exclamationmark.triangle"
        }
    }

    var description: String {
        switch self {
        case .loseWeight: return "Reach your target weight"
        case .buildMuscle: return "Gain strength and mass"
        case .eatHealthier: return "Make better food choices"
        case .trackNutrition: return "Understand what you eat"
        case .foodSafety: return "Know what's in your food"
        case .manageAllergies: return "Avoid reactions"
        }
    }
}

enum ActivityLevelOption: String, CaseIterable, Identifiable {
    case sedentary = "Sedentary"
    case lightlyActive = "Lightly active"
    case moderatelyActive = "Moderately active"
    case veryActive = "Very active"
    case extraActive = "Extra active"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .sedentary: return "figure.stand"
        case .lightlyActive: return "figure.walk"
        case .moderatelyActive: return "figure.run"
        case .veryActive: return "figure.highintensity.intervaltraining"
        case .extraActive: return "figure.strengthtraining.traditional"
        }
    }

    var description: String {
        switch self {
        case .sedentary: return "Little or no exercise"
        case .lightlyActive: return "Light exercise 1-3 days/week"
        case .moderatelyActive: return "Moderate exercise 3-5 days/week"
        case .veryActive: return "Hard exercise 6-7 days/week"
        case .extraActive: return "Very hard exercise or physical job"
        }
    }

    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .lightlyActive: return 1.375
        case .moderatelyActive: return 1.55
        case .veryActive: return 1.725
        case .extraActive: return 1.9
        }
    }
}

enum EatingHabitOption: String, CaseIterable, Identifiable {
    case homeCooking = "Home cooking"
    case mealPrep = "Meal prep"
    case eatOut = "Eat out often"
    case fastFood = "Fast food"
    case snacker = "Frequent snacker"
    case lateDinner = "Late dinners"
    case skipBreakfast = "Skip breakfast"
    case bigLunches = "Big lunches"
    case healthyTrying = "Trying to be healthier"
    case busySchedule = "Busy schedule"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .homeCooking: return "frying.pan"
        case .mealPrep: return "takeoutbag.and.cup.and.straw"
        case .eatOut: return "fork.knife"
        case .fastFood: return "bag"
        case .snacker: return "carrot"
        case .lateDinner: return "moon"
        case .skipBreakfast: return "sunrise"
        case .bigLunches: return "sun.max"
        case .healthyTrying: return "heart"
        case .busySchedule: return "clock"
        }
    }
}

enum DietExperienceOption: String, CaseIterable, Identifiable {
    case never = "No, this is new"
    case tried = "I've tried before"
    case onAndOff = "On and off"
    case regularly = "I track regularly"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .never: return "sparkles"
        case .tried: return "arrow.counterclockwise"
        case .onAndOff: return "arrow.triangle.2.circlepath"
        case .regularly: return "checkmark.circle"
        }
    }

    var description: String {
        switch self {
        case .never: return "Fresh start, let's go!"
        case .tried: return "Ready for something better"
        case .onAndOff: return "Looking for consistency"
        case .regularly: return "Levelling up"
        }
    }
}

// MARK: - Onboarding State

class PremiumOnboardingState: ObservableObject {
    @Published var selectedIntent: UserIntent?
    @Published var selectedSensitivities: Set<FoodSensitivity> = []
    @Published var hasAcceptedDisclaimer: Bool = false
    @Published var emailConsent: Bool = false

    // Goals and lifestyle
    @Published var selectedGoals: Set<OnboardingGoal> = []
    @Published var activityLevel: ActivityLevelOption = .moderatelyActive
    @Published var eatingHabits: Set<EatingHabitOption> = []
    @Published var dietExperience: DietExperienceOption = .tried

    // Diet setup
    @Published var selectedDietType: DietType = .flexible
    @Published var targetCalories: Int = 2000
    @Published var wantsDietSetup: Bool = true

    // Personal details (for BMR calculation)
    @Published var heightCm: Double = 170
    @Published var weightKg: Double = 70
    @Published var birthDate: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
    @Published var gender: UserGender = .notSet

    var age: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 30
    }

    // Mifflin-St Jeor BMR calculation
    var bmr: Double {
        let weight = weightKg
        let height = heightCm
        let ageYears = Double(age)

        switch gender {
        case .male:
            return (10 * weight) + (6.25 * height) - (5 * ageYears) + 5
        case .female:
            return (10 * weight) + (6.25 * height) - (5 * ageYears) - 161
        case .other, .notSet:
            // Average of male and female formulas
            let male = (10 * weight) + (6.25 * height) - (5 * ageYears) + 5
            let female = (10 * weight) + (6.25 * height) - (5 * ageYears) - 161
            return (male + female) / 2
        }
    }

    // TDEE (Total Daily Energy Expenditure) = BMR × Activity Multiplier
    var tdee: Int {
        Int(bmr * activityLevel.multiplier)
    }

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

    var hasWeightGoal: Bool {
        selectedGoals.contains(.loseWeight) || selectedGoals.contains(.buildMuscle)
    }

    // Save to OnboardingManager for persistence
    func saveToManager() {
        if let intent = selectedIntent {
            UserDefaults.standard.set(intent.rawValue, forKey: "userIntent")
        }
        let sensitivitiesArray = selectedSensitivities.map { $0.rawValue }
        UserDefaults.standard.set(sensitivitiesArray, forKey: "userSensitivities")

        // Save goals and lifestyle
        let goalsArray = selectedGoals.map { $0.rawValue }
        UserDefaults.standard.set(goalsArray, forKey: "userGoals")
        UserDefaults.standard.set(activityLevel.rawValue, forKey: "userActivityLevel")
        let habitsArray = eatingHabits.map { $0.rawValue }
        UserDefaults.standard.set(habitsArray, forKey: "userEatingHabits")
        UserDefaults.standard.set(dietExperience.rawValue, forKey: "userDietExperience")

        // Save diet setup - use the SAME keys that DietManagementRedesigned reads from
        UserDefaults.standard.set(selectedDietType.rawValue, forKey: "cachedDietType")
        UserDefaults.standard.set(targetCalories, forKey: "cachedCaloricGoal") // Main key used by diet management
        UserDefaults.standard.set(targetCalories, forKey: "userTargetCalories") // Legacy backup

        // Also save the macro goals based on diet type and target calories
        let calories = Double(targetCalories)
        var proteinGrams: Int
        var carbsGrams: Int
        var fatGrams: Int

        switch selectedDietType {
        case .keto:
            // 5% carbs, 20% protein, 75% fat
            proteinGrams = Int(calories * 0.20 / 4)
            carbsGrams = Int(calories * 0.05 / 4)
            fatGrams = Int(calories * 0.75 / 9)
        case .lowCarb:
            // 20% carbs, 30% protein, 50% fat
            proteinGrams = Int(calories * 0.30 / 4)
            carbsGrams = Int(calories * 0.20 / 4)
            fatGrams = Int(calories * 0.50 / 9)
        case .highProtein:
            // 40% carbs, 35% protein, 25% fat
            proteinGrams = Int(calories * 0.35 / 4)
            carbsGrams = Int(calories * 0.40 / 4)
            fatGrams = Int(calories * 0.25 / 9)
        case .highProteinMax:
            // 25% carbs, 50% protein, 25% fat
            proteinGrams = Int(calories * 0.50 / 4)
            carbsGrams = Int(calories * 0.25 / 4)
            fatGrams = Int(calories * 0.25 / 9)
        case .mediterranean, .paleo, .flexible:
            // 45% carbs, 25% protein, 30% fat
            proteinGrams = Int(calories * 0.25 / 4)
            carbsGrams = Int(calories * 0.45 / 4)
            fatGrams = Int(calories * 0.30 / 9)
        }

        // Save calculated macro goals
        UserDefaults.standard.set(proteinGrams, forKey: "cachedProteinGoal")
        UserDefaults.standard.set(carbsGrams, forKey: "cachedCarbsGoal")
        UserDefaults.standard.set(fatGrams, forKey: "cachedFatGoal")

        // Save personal details
        UserDefaults.standard.set(heightCm, forKey: "userHeightCm")
        UserDefaults.standard.set(weightKg, forKey: "userWeightKg")
        UserDefaults.standard.set(birthDate.timeIntervalSince1970, forKey: "userBirthDate")
        UserDefaults.standard.set(gender.rawValue, forKey: "userGender")

        // Also save to Firebase if user is signed in (fire-and-forget)
        // This ensures Firebase doesn't override onboarding settings on next load
        saveToFirebase()
    }

    /// Save diet settings to Firebase (async, fire-and-forget)
    private func saveToFirebase() {
        let dietType = selectedDietType
        let calorieTarget = targetCalories
        let userHeight = heightCm
        let userWeight = weightKg

        // Calculate macro percentages based on diet type
        var proteinPercent: Int
        var carbsPercent: Int
        var fatPercent: Int

        switch dietType {
        case .keto:
            proteinPercent = 20
            carbsPercent = 5
            fatPercent = 75
        case .lowCarb:
            proteinPercent = 30
            carbsPercent = 20
            fatPercent = 50
        case .highProtein:
            proteinPercent = 35
            carbsPercent = 40
            fatPercent = 25
        case .highProteinMax:
            proteinPercent = 50
            carbsPercent = 25
            fatPercent = 25
        case .mediterranean, .paleo, .flexible:
            proteinPercent = 25
            carbsPercent = 45
            fatPercent = 30
        }

        Task {
            let firebaseManager = FirebaseManager.shared

            // Save user settings including height and calorie goal
            try? await firebaseManager.saveUserSettings(
                height: userHeight,
                goalWeight: nil,
                caloricGoal: calorieTarget,
                exerciseGoal: nil,
                stepGoal: nil
            )

            // Save initial weight entry to weight history
            let weightEntry = WeightEntry(
                id: UUID(),
                weight: userWeight,
                date: Date(),
                note: "Starting weight from onboarding",
                photoURLs: []
            )
            try? await firebaseManager.saveWeightEntry(weightEntry)

            // Save diet type and macro goals to Firebase (include Fiber as 4th macro)
            let macroGoals = [
                MacroGoal(macroType: .protein, percentage: proteinPercent),
                MacroGoal(macroType: .carbs, percentage: carbsPercent),
                MacroGoal(macroType: .fat, percentage: fatPercent),
                MacroGoal(macroType: .fiber, directTarget: 30.0) // Default 30g fiber goal
            ]
            try? await firebaseManager.saveMacroGoals(macroGoals, dietType: dietType)
        }
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
        if let goalsArray = UserDefaults.standard.stringArray(forKey: "userGoals") {
            selectedGoals = Set(goalsArray.compactMap { OnboardingGoal(rawValue: $0) })
        }
        if let activityRaw = UserDefaults.standard.string(forKey: "userActivityLevel"),
           let activity = ActivityLevelOption(rawValue: activityRaw) {
            activityLevel = activity
        }
        if let habitsArray = UserDefaults.standard.stringArray(forKey: "userEatingHabits") {
            eatingHabits = Set(habitsArray.compactMap { EatingHabitOption(rawValue: $0) })
        }
        if let experienceRaw = UserDefaults.standard.string(forKey: "userDietExperience"),
           let experience = DietExperienceOption(rawValue: experienceRaw) {
            dietExperience = experience
        }

        // Load personal details
        if UserDefaults.standard.object(forKey: "userHeightCm") != nil {
            heightCm = UserDefaults.standard.double(forKey: "userHeightCm")
        }
        if UserDefaults.standard.object(forKey: "userWeightKg") != nil {
            weightKg = UserDefaults.standard.double(forKey: "userWeightKg")
        }
        if UserDefaults.standard.object(forKey: "userBirthDate") != nil {
            let timestamp = UserDefaults.standard.double(forKey: "userBirthDate")
            birthDate = Date(timeIntervalSince1970: timestamp)
        }
        if let genderRaw = UserDefaults.standard.string(forKey: "userGender"),
           let loadedGender = UserGender(rawValue: genderRaw) {
            gender = loadedGender
        }
    }
}
