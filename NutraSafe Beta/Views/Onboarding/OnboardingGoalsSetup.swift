//
//  OnboardingGoalsSetup.swift
//  NutraSafe Beta
//
//  Comprehensive goals and lifestyle questionnaire for onboarding
//  Creates a personalized experience like top converting apps
//

import SwiftUI

// MARK: - User Goal Enum

enum UserGoal: String, CaseIterable, Identifiable, Codable {
    case loseWeight = "loseWeight"
    case buildMuscle = "buildMuscle"
    case eatHealthier = "eatHealthier"
    case trackNutrition = "trackNutrition"
    case foodSafety = "foodSafety"
    case manageAllergies = "manageAllergies"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .loseWeight: return "Lose weight"
        case .buildMuscle: return "Build muscle"
        case .eatHealthier: return "Eat healthier"
        case .trackNutrition: return "Track my nutrition"
        case .foodSafety: return "Food safety"
        case .manageAllergies: return "Manage allergies"
        }
    }

    var description: String {
        switch self {
        case .loseWeight: return "Create a sustainable calorie deficit"
        case .buildMuscle: return "Optimise protein and calories for gains"
        case .eatHealthier: return "Make better food choices"
        case .trackNutrition: return "Understand what I'm eating"
        case .foodSafety: return "Track expiry dates and storage"
        case .manageAllergies: return "Avoid triggers and track reactions"
        }
    }

    var icon: String {
        switch self {
        case .loseWeight: return "scalemass"
        case .buildMuscle: return "figure.strengthtraining.traditional"
        case .eatHealthier: return "leaf"
        case .trackNutrition: return "chart.pie"
        case .foodSafety: return "clock.badge.checkmark"
        case .manageAllergies: return "exclamationmark.shield"
        }
    }

    var color: Color {
        switch self {
        case .loseWeight: return .orange
        case .buildMuscle: return .purple
        case .eatHealthier: return .green
        case .trackNutrition: return Color.accentColor
        case .foodSafety: return .cyan
        case .manageAllergies: return .red
        }
    }

    /// Whether this goal benefits from diet/calorie setup
    var benefitsFromDietSetup: Bool {
        switch self {
        case .loseWeight, .buildMuscle, .trackNutrition, .eatHealthier:
            return true
        case .foodSafety, .manageAllergies:
            return false
        }
    }
}

// MARK: - Onboarding Activity Level Enum

enum OnboardingActivityLevel: String, CaseIterable, Identifiable, Codable {
    case sedentary = "sedentary"
    case lightlyActive = "lightlyActive"
    case moderatelyActive = "moderatelyActive"
    case veryActive = "veryActive"
    case extraActive = "extraActive"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sedentary: return "Mostly sitting"
        case .lightlyActive: return "Lightly active"
        case .moderatelyActive: return "Moderately active"
        case .veryActive: return "Very active"
        case .extraActive: return "Athlete level"
        }
    }

    var description: String {
        switch self {
        case .sedentary: return "Desk job, little to no exercise"
        case .lightlyActive: return "Light exercise 1-3 days/week"
        case .moderatelyActive: return "Moderate exercise 3-5 days/week"
        case .veryActive: return "Hard exercise 6-7 days/week"
        case .extraActive: return "Physical job + daily training"
        }
    }

    var icon: String {
        switch self {
        case .sedentary: return "chair.lounge"
        case .lightlyActive: return "figure.walk"
        case .moderatelyActive: return "figure.run"
        case .veryActive: return "figure.highintensity.intervaltraining"
        case .extraActive: return "figure.strengthtraining.traditional"
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

// MARK: - Eating Habits Enum

enum EatingHabit: String, CaseIterable, Identifiable, Codable {
    case regularMeals = "regularMeals"
    case irregularEating = "irregularEating"
    case frequentSnacking = "frequentSnacking"
    case mealSkipping = "mealSkipping"
    case latNightEating = "lateNightEating"
    case eatWhenBored = "eatWhenBored"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .regularMeals: return "Regular meals"
        case .irregularEating: return "Irregular eating times"
        case .frequentSnacking: return "Frequent snacking"
        case .mealSkipping: return "Often skip meals"
        case .latNightEating: return "Late night eating"
        case .eatWhenBored: return "Eat when bored/stressed"
        }
    }

    var icon: String {
        switch self {
        case .regularMeals: return "clock"
        case .irregularEating: return "clock.badge.questionmark"
        case .frequentSnacking: return "takeoutbag.and.cup.and.straw"
        case .mealSkipping: return "xmark.circle"
        case .latNightEating: return "moon"
        case .eatWhenBored: return "brain.head.profile"
        }
    }
}

// MARK: - Diet Experience Enum

enum DietExperience: String, CaseIterable, Identifiable, Codable {
    case never = "never"
    case tried = "tried"
    case experienced = "experienced"
    case expert = "expert"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .never: return "I'm new to this"
        case .tried: return "I've tried before"
        case .experienced: return "I track regularly"
        case .expert: return "I'm experienced"
        }
    }

    var description: String {
        switch self {
        case .never: return "Never tracked calories or macros"
        case .tried: return "Tried tracking but didn't stick with it"
        case .experienced: return "Track most of what I eat"
        case .expert: return "Know my macros, weigh my food"
        }
    }

    var icon: String {
        switch self {
        case .never: return "sparkles"
        case .tried: return "arrow.clockwise"
        case .experienced: return "checkmark.circle"
        case .expert: return "star.fill"
        }
    }
}

// MARK: - Onboarding Questionnaire State

class OnboardingQuestionnaireState: ObservableObject {
    @Published var selectedGoals: Set<UserGoal> = []
    @Published var activityLevel: OnboardingActivityLevel = .moderatelyActive
    @Published var eatingHabits: Set<EatingHabit> = []
    @Published var dietExperience: DietExperience = .tried
    @Published var heightCm: Double = 170
    @Published var weightKg: Double = 70
    @Published var targetWeightKg: Double?

    var hasDietGoal: Bool {
        selectedGoals.contains(where: { $0.benefitsFromDietSetup })
    }

    var hasWeightGoal: Bool {
        selectedGoals.contains(.loseWeight) || selectedGoals.contains(.buildMuscle)
    }

    func saveToManager() {
        // Save goals
        let goalStrings = selectedGoals.map { $0.rawValue }
        UserDefaults.standard.set(goalStrings, forKey: "userGoals")

        // Save activity level
        UserDefaults.standard.set(activityLevel.rawValue, forKey: "userActivityLevel")

        // Save eating habits
        let habitStrings = eatingHabits.map { $0.rawValue }
        UserDefaults.standard.set(habitStrings, forKey: "userEatingHabits")

        // Save diet experience
        UserDefaults.standard.set(dietExperience.rawValue, forKey: "userDietExperience")

        // Save measurements
        OnboardingManager.shared.saveHeight(heightCm)
        OnboardingManager.shared.saveWeight(weightKg)

        if let targetWeight = targetWeightKg {
            UserDefaults.standard.set(targetWeight, forKey: "userTargetWeight")
        }
    }
}

// MARK: - Goals Page (Step 1)

struct OnboardingGoalsPage: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var state: OnboardingQuestionnaireState
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer().frame(height: 30)

                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "target")
                            .font(.system(size: 40))
                            .foregroundColor(.accentColor)
                            .padding(.bottom, 8)

                        Text("What brings you here?")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Select all that apply")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }

                    // Goal selection
                    VStack(spacing: 12) {
                        ForEach(UserGoal.allCases) { goal in
                            GoalSelectionCard(
                                goal: goal,
                                isSelected: state.selectedGoals.contains(goal),
                                onTap: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        if state.selectedGoals.contains(goal) {
                                            state.selectedGoals.remove(goal)
                                        } else {
                                            state.selectedGoals.insert(goal)
                                        }
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    // Note
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        Text("You can change your goals anytime in Settings")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    Spacer().frame(height: 20)
                }
            }

            // Navigation
            HStack(spacing: 12) {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                }

                Button(action: onContinue) {
                    Text(state.selectedGoals.isEmpty ? "Skip" : "Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(state.selectedGoals.isEmpty ? Color.secondary : Color.accentColor)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Activity Level Page (Step 2)

struct OnboardingActivityPage: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var state: OnboardingQuestionnaireState
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer().frame(height: 30)

                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                            .padding(.bottom, 8)

                        Text("How active are you?")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Be honest - this helps us calculate your needs")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    // Activity options
                    VStack(spacing: 10) {
                        ForEach(OnboardingActivityLevel.allCases) { level in
                            OnboardingActivityLevelCard(
                                level: level,
                                isSelected: state.activityLevel == level,
                                onTap: {
                                    withAnimation(.spring(response: 0.3)) {
                                        state.activityLevel = level
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    // Tip
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.yellow)

                        Text("Most people slightly overestimate their activity level. When in doubt, choose one level lower.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(Color.yellow.opacity(colorScheme == .dark ? 0.15 : 0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 20)
                }
            }

            // Navigation
            OnboardingNavButtons(onBack: onBack, onContinue: onContinue)
        }
    }
}

// MARK: - Eating Habits Page (Step 3)

struct OnboardingHabitsPage: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var state: OnboardingQuestionnaireState
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer().frame(height: 30)

                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                            .padding(.bottom, 8)

                        Text("Your eating patterns")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Select any that apply to you")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }

                    // Habits grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(EatingHabit.allCases) { habit in
                            HabitCard(
                                habit: habit,
                                isSelected: state.eatingHabits.contains(habit),
                                onTap: {
                                    withAnimation(.spring(response: 0.3)) {
                                        if state.eatingHabits.contains(habit) {
                                            state.eatingHabits.remove(habit)
                                        } else {
                                            state.eatingHabits.insert(habit)
                                        }
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    // Reassurance
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.pink)

                        Text("No judgement here. Understanding your habits helps us support you better.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(Color.pink.opacity(colorScheme == .dark ? 0.15 : 0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 20)
                }
            }

            // Navigation
            OnboardingNavButtons(onBack: onBack, onContinue: onContinue)
        }
    }
}

// MARK: - Experience Page (Step 4)

struct OnboardingExperiencePage: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var state: OnboardingQuestionnaireState
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer().frame(height: 30)

                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.purple)
                            .padding(.bottom, 8)

                        Text("Your experience")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)

                        Text("How familiar are you with tracking nutrition?")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    // Experience options
                    VStack(spacing: 12) {
                        ForEach(DietExperience.allCases) { experience in
                            ExperienceCard(
                                experience: experience,
                                isSelected: state.dietExperience == experience,
                                onTap: {
                                    withAnimation(.spring(response: 0.3)) {
                                        state.dietExperience = experience
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    // Info
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.accentColor)

                        Text("We'll adjust how much guidance we give you based on your experience level.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(Color.accentColor.opacity(colorScheme == .dark ? 0.15 : 0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 20)
                }
            }

            // Navigation
            OnboardingNavButtons(onBack: onBack, onContinue: onContinue)
        }
    }
}

// MARK: - Measurements Page (Step 5 - Optional)

struct OnboardingMeasurementsPage: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var state: OnboardingQuestionnaireState
    let onBack: () -> Void
    let onContinue: () -> Void
    let onSkip: () -> Void

    @State private var heightText: String = "170"
    @State private var weightText: String = "70"
    @State private var targetWeightText: String = ""
    @FocusState private var focusedField: Field?

    enum Field { case height, weight, targetWeight }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer().frame(height: 30)

                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "ruler")
                            .font(.system(size: 40))
                            .foregroundColor(.cyan)
                            .padding(.bottom, 8)

                        Text("Your measurements")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)

                        Text("This helps us calculate your calorie needs")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }

                    // Measurement inputs
                    VStack(spacing: 16) {
                        // Height
                        MeasurementInputRow(
                            label: "Height",
                            value: $heightText,
                            unit: "cm",
                            icon: "arrow.up.and.down",
                            color: .cyan,
                            onValueChanged: { value in
                                if let h = Double(value) {
                                    state.heightCm = h
                                }
                            }
                        )
                        .focused($focusedField, equals: .height)

                        Divider()

                        // Current weight
                        MeasurementInputRow(
                            label: "Current weight",
                            value: $weightText,
                            unit: "kg",
                            icon: "scalemass",
                            color: .orange,
                            onValueChanged: { value in
                                if let w = Double(value) {
                                    state.weightKg = w
                                }
                            }
                        )
                        .focused($focusedField, equals: .weight)

                        // Target weight (only if weight goal selected)
                        if state.hasWeightGoal {
                            Divider()

                            MeasurementInputRow(
                                label: "Target weight",
                                value: $targetWeightText,
                                unit: "kg",
                                icon: "target",
                                color: .green,
                                placeholder: "Optional",
                                onValueChanged: { value in
                                    state.targetWeightKg = Double(value)
                                }
                            )
                            .focused($focusedField, equals: .targetWeight)
                        }
                    }
                    .padding(20)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 24)

                    // Privacy note
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)

                        Text("Your measurements stay on your device. We never share personal data.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(Color.green.opacity(colorScheme == .dark ? 0.15 : 0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 20)
                }
            }
            .scrollDismissesKeyboard(.interactively)

            // Navigation
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    }

                    Button(action: onContinue) {
                        Text("Continue")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.accentColor)
                            .cornerRadius(12)
                    }
                }

                Button(action: onSkip) {
                    Text("I'll add this later")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .onAppear {
            heightText = "\(Int(state.heightCm))"
            weightText = "\(Int(state.weightKg))"
        }
    }
}

// MARK: - Analysis Page (Calculating Screen)

struct OnboardingAnalysisPage: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var state: OnboardingQuestionnaireState
    let onComplete: () -> Void

    @State private var currentPhase = 0
    @State private var progress: Double = 0
    @State private var showStats = false
    @State private var currentStatIndex = 0
    @State private var isComplete = false

    // Science-backed statistics
    private let stats: [(icon: String, color: Color, text: String, source: String)] = [
        ("chart.line.uptrend.xyaxis", .green, "People who track food lose 2x more weight", "Journal of the Academy of Nutrition"),
        ("brain.head.profile", .purple, "Food logging increases nutritional awareness by 64%", "Obesity Research"),
        ("figure.run", .orange, "Consistent trackers are 3x more likely to reach goals", "American Journal of Preventive Medicine"),
        ("heart.fill", .pink, "Tracking helps identify food sensitivities faster", "Clinical & Experimental Allergy"),
        ("clock.fill", .cyan, "Just 2-3 minutes of logging daily makes a difference", "Health Psychology Review")
    ]

    private let phases = [
        "Analysing your goals...",
        "Calculating your needs...",
        "Personalising your experience...",
        "Almost ready..."
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                // Animated progress ring
                ZStack {
                    Circle()
                        .stroke(Color.accentColor.opacity(0.2), lineWidth: 4)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color.accentColor,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))

                    Image(systemName: isComplete ? "checkmark" : "sparkles")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.accentColor)
                        .scaleEffect(isComplete ? 1.2 : 1.0)
                }
                .animation(.spring(response: 0.5), value: isComplete)

                // Phase text
                VStack(spacing: 8) {
                    if isComplete {
                        Text("You're all set!")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)

                        Text("We've created your personalised plan")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    } else {
                        Text(phases[min(currentPhase, phases.count - 1)])
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut, value: currentPhase)

                // Stats carousel
                if showStats && !isComplete {
                    let stat = stats[currentStatIndex % stats.count]

                    HStack(spacing: 12) {
                        Image(systemName: stat.icon)
                            .font(.system(size: 24))
                            .foregroundColor(stat.color)
                            .frame(width: 44, height: 44)
                            .background(stat.color.opacity(colorScheme == .dark ? 0.2 : 0.12))
                            .cornerRadius(10)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(stat.text)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)

                            Text(stat.source)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(14)
                    .padding(.horizontal, 24)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(currentStatIndex)
                    .animation(.easeInOut(duration: 0.4), value: currentStatIndex)
                }

                // Summary when complete
                if isComplete && !state.selectedGoals.isEmpty {
                    VStack(spacing: 12) {
                        Text("Your focus areas")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            ForEach(Array(state.selectedGoals).prefix(3)) { goal in
                                HStack(spacing: 6) {
                                    Image(systemName: goal.icon)
                                        .font(.system(size: 12))
                                    Text(goal.displayName)
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(goal.color)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(goal.color.opacity(0.12))
                                .cornerRadius(16)
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }

            Spacer()

            // Continue button
            if isComplete {
                Button(action: {
                    state.saveToManager()
                    onComplete()
                }) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.accentColor)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .onAppear {
            startAnalysis()
        }
    }

    private func startAnalysis() {
        withAnimation(.linear(duration: 3.5)) {
            progress = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation { showStats = true }
        }

        for (index, _) in phases.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.8) {
                withAnimation { currentPhase = index }
            }
        }

        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            if isComplete { timer.invalidate(); return }
            withAnimation { currentStatIndex += 1 }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.spring(response: 0.5)) {
                showStats = false
                isComplete = true
            }
        }
    }
}

// MARK: - Setup Choice Page

struct OnboardingSetupChoicePage: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var state: OnboardingQuestionnaireState
    let onSetupNow: () -> Void
    let onSetupLater: () -> Void

    private var shouldRecommendSetup: Bool {
        state.hasDietGoal
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer().frame(height: 40)

                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 44))
                            .foregroundColor(.accentColor)

                        Text("Set your nutrition targets?")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)

                        Text("Personalised targets help you track more effectively")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    // Features
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick setup includes")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        SetupFeatureRow(
                            icon: "flame",
                            color: .orange,
                            title: "Daily calorie goal",
                            description: "Based on your activity and goals"
                        )

                        SetupFeatureRow(
                            icon: "chart.pie",
                            color: .purple,
                            title: "Macro balance",
                            description: "Protein, carbs, and fat percentages"
                        )

                        SetupFeatureRow(
                            icon: "leaf",
                            color: .green,
                            title: "Eating style",
                            description: "Keto, high protein, Mediterranean, and more"
                        )
                    }
                    .padding(20)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 20)
                }
            }

            // Actions
            VStack(spacing: 12) {
                Button(action: onSetupNow) {
                    HStack {
                        Text("Set up now")
                        if shouldRecommendSetup {
                            Text("(Recommended)")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.accentColor)
                    .cornerRadius(14)
                }

                Button(action: onSetupLater) {
                    Text("I'll do this later")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                }

                Text("You can always set this up in Settings")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Supporting Components

struct GoalSelectionCard: View {
    @Environment(\.colorScheme) var colorScheme
    let goal: UserGoal
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: goal.icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .white : goal.color)
                    .frame(width: 48, height: 48)
                    .background(
                        isSelected ? goal.color : goal.color.opacity(colorScheme == .dark ? 0.2 : 0.12)
                    )
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(goal.description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(goal.color)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? goal.color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct OnboardingActivityLevelCard: View {
    @Environment(\.colorScheme) var colorScheme
    let level: OnboardingActivityLevel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: level.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .orange)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color.orange : Color.orange.opacity(colorScheme == .dark ? 0.2 : 0.12))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(level.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(level.description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.orange)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HabitCard: View {
    @Environment(\.colorScheme) var colorScheme
    let habit: EatingHabit
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Image(systemName: habit.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .green)
                    .frame(width: 48, height: 48)
                    .background(isSelected ? Color.green : Color.green.opacity(colorScheme == .dark ? 0.2 : 0.12))
                    .cornerRadius(12)

                Text(habit.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ExperienceCard: View {
    @Environment(\.colorScheme) var colorScheme
    let experience: DietExperience
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: experience.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .purple)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color.purple : Color.purple.opacity(colorScheme == .dark ? 0.2 : 0.12))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(experience.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(experience.description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.purple)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MeasurementInputRow: View {
    let label: String
    @Binding var value: String
    let unit: String
    let icon: String
    let color: Color
    var placeholder: String = ""
    let onValueChanged: (String) -> Void

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 30)

            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.secondary)

            Spacer()

            TextField(placeholder, text: $value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .onChange(of: value) { _, newValue in
                    onValueChanged(newValue)
                }

            Text(unit)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .leading)
        }
    }
}

struct SetupFeatureRow: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(colorScheme == .dark ? 0.2 : 0.12))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

struct OnboardingNavButtons: View {
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }

            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
}

// MARK: - Previews

#Preview("Goals") {
    OnboardingGoalsPage(
        state: OnboardingQuestionnaireState(),
        onBack: {},
        onContinue: {}
    )
}

#Preview("Activity") {
    OnboardingActivityPage(
        state: OnboardingQuestionnaireState(),
        onBack: {},
        onContinue: {}
    )
}

#Preview("Habits") {
    OnboardingHabitsPage(
        state: OnboardingQuestionnaireState(),
        onBack: {},
        onContinue: {}
    )
}

#Preview("Experience") {
    OnboardingExperiencePage(
        state: OnboardingQuestionnaireState(),
        onBack: {},
        onContinue: {}
    )
}

#Preview("Measurements") {
    OnboardingMeasurementsPage(
        state: OnboardingQuestionnaireState(),
        onBack: {},
        onContinue: {},
        onSkip: {}
    )
}

#Preview("Analysis") {
    OnboardingAnalysisPage(
        state: OnboardingQuestionnaireState(),
        onComplete: {}
    )
}

#Preview("Setup Choice") {
    OnboardingSetupChoicePage(
        state: OnboardingQuestionnaireState(),
        onSetupNow: {},
        onSetupLater: {}
    )
}
