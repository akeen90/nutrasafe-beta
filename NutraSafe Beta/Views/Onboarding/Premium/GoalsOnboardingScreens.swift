//
//  GoalsOnboardingScreens.swift
//  NutraSafe Beta
//
//  Goals, activity, and lifestyle questionnaire screens for premium onboarding
//  Follows NutraSafe's brand design language with serif headlines and organic feel
//

import SwiftUI
import UIKit

// MARK: - Goals Screen (What brings you here?)

struct GoalsScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // Headline
            VStack(spacing: 8) {
                Text("What brings you")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))

                Text("to NutraSafe?")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))
            }
            .multilineTextAlignment(.center)

            Text("Select all that apply.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(white: 0.5))
                .padding(.top, 12)

            Spacer().frame(height: 32)

            // Goals grid
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(OnboardingGoal.allCases) { goal in
                        GoalCard(
                            goal: goal,
                            isSelected: state.selectedGoals.contains(goal),
                            palette: state.palette,
                            onToggle: {
                                withAnimation(.easeOut(duration: 0.2)) {
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
            }

            Spacer()

            // Continue/Skip buttons
            VStack(spacing: 14) {
                PremiumButton(
                    text: "Continue",
                    palette: state.palette,
                    action: onContinue,
                    isEnabled: !state.selectedGoals.isEmpty
                )

                if state.selectedGoals.isEmpty {
                    Button(action: onContinue) {
                        Text("Skip for now")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(white: 0.5))
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Activity Level Screen

struct ActivityLevelScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // Headline
            VStack(spacing: 8) {
                Text("How active")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))

                Text("are you?")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))
            }
            .multilineTextAlignment(.center)

            Text("This helps us personalise your experience.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(white: 0.5))
                .padding(.top, 12)

            Spacer().frame(height: 32)

            // Activity options
            VStack(spacing: 12) {
                ForEach(ActivityLevelOption.allCases) { level in
                    ActivityCard(
                        level: level,
                        isSelected: state.activityLevel == level,
                        palette: state.palette,
                        onSelect: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                state.activityLevel = level
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Continue button
            PremiumButton(
                text: "Continue",
                palette: state.palette,
                action: onContinue
            )
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Eating Habits Screen

struct EatingHabitsScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    let onContinue: () -> Void

    // Personalized insight based on selected habits
    private var personalizedInsight: (icon: String, text: String)? {
        let habits = state.eatingHabits

        // Priority-based insights
        if habits.contains(.fastFood) && habits.contains(.busySchedule) {
            return ("lightbulb.fill", "We'll help you find quick, healthier alternatives when you're short on time.")
        } else if habits.contains(.skipBreakfast) && habits.contains(.lateDinner) {
            return ("clock.fill", "Your eating window suggests intermittent fasting might work well for you.")
        } else if habits.contains(.snacker) {
            return ("chart.bar.fill", "We'll track snacks separately so you can see their real impact.")
        } else if habits.contains(.eatOut) || habits.contains(.fastFood) {
            return ("magnifyingglass", "Our barcode scanner makes logging restaurant meals quick and easy.")
        } else if habits.contains(.mealPrep) || habits.contains(.homeCooking) {
            return ("star.fill", "Great foundation! Home cooking gives you the most control over ingredients.")
        } else if habits.contains(.busySchedule) {
            return ("bolt.fill", "Quick-add and meal copying will save you time logging.")
        } else if habits.contains(.healthyTrying) {
            return ("heart.fill", "We'll show you which foods score highest for your health goals.")
        } else if habits.contains(.lateDinner) {
            return ("moon.fill", "We'll help you balance your daily intake even with late meals.")
        } else if habits.contains(.bigLunches) {
            return ("sun.max.fill", "Front-loading calories can actually support weight management.")
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 50)

            // Headline
            VStack(spacing: 8) {
                Text("Your eating")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))

                Text("habits")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))
            }
            .multilineTextAlignment(.center)

            Text("Help us personalise your experience.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(white: 0.5))
                .padding(.top, 12)

            Spacer().frame(height: 24)

            // Habits flow layout
            ScrollView(showsIndicators: false) {
                OnboardingFlowLayout(spacing: 10) {
                    ForEach(EatingHabitOption.allCases) { habit in
                        HabitTag(
                            habit: habit,
                            isSelected: state.eatingHabits.contains(habit),
                            palette: state.palette,
                            onToggle: {
                                withAnimation(.easeOut(duration: 0.2)) {
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
            }
            .frame(maxHeight: 260)

            // Personalized insight card - appears when relevant habits selected
            if let insight = personalizedInsight {
                HStack(spacing: 12) {
                    Image(systemName: insight.icon)
                        .font(.system(size: 18))
                        .foregroundColor(state.palette.primary)
                        .frame(width: 24)

                    Text(insight.text)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(white: 0.35))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(state.palette.primary.opacity(0.08))
                )
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .animation(.easeOut(duration: 0.3), value: insight.text)
            }

            Spacer()

            // Continue button (skip allowed)
            VStack(spacing: 16) {
                PremiumButton(
                    text: "Continue",
                    palette: state.palette,
                    action: onContinue
                )

                Button(action: onContinue) {
                    Text("Skip for now")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(white: 0.5))
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Diet Experience Screen

struct DietExperienceScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // Headline
            VStack(spacing: 8) {
                Text("Have you tracked")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))

                Text("food before?")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))
            }
            .multilineTextAlignment(.center)

            Text("This helps us tailor your experience.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(white: 0.5))
                .padding(.top, 12)

            Spacer().frame(height: 40)

            // Experience options
            VStack(spacing: 12) {
                ForEach(DietExperienceOption.allCases) { experience in
                    PremiumExperienceCard(
                        experience: experience,
                        isSelected: state.dietExperience == experience,
                        palette: state.palette,
                        onSelect: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                state.dietExperience = experience
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            // Auto-advance after selection
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                onContinue()
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

// MARK: - Feature Benefits Screen (shows how app helps with selected goals)

struct FeatureBenefitsScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var visibleFeatures: Set<Int> = []

    // Map goals to specific app features
    private var featureBenefits: [(icon: String, title: String, description: String)] {
        var benefits: [(icon: String, title: String, description: String)] = []

        // Food Safety / Additives
        if state.selectedGoals.contains(.foodSafety) {
            benefits.append((
                icon: "shield.checkered",
                title: "Additive Scanner",
                description: "Instantly identify E-numbers and additives. We flag preservatives, artificial colours, and controversial ingredients so you know exactly what's in your food."
            ))
        }

        // Manage Allergies
        if state.selectedGoals.contains(.manageAllergies) {
            benefits.append((
                icon: "exclamationmark.triangle.fill",
                title: "Allergen Alerts",
                description: "Set your allergens once and we'll warn you every time. Instant warnings for the 14 major allergens, cross-contamination risks, and hidden ingredients."
            ))
        }

        // Lose Weight
        if state.selectedGoals.contains(.loseWeight) {
            benefits.append((
                icon: "flame.fill",
                title: "Smart Calorie Tracking",
                description: "Log meals in seconds with barcode scanning and AI photo recognition. We calculate your deficit and show you exactly how you're progressing."
            ))
        }

        // Build Muscle
        if state.selectedGoals.contains(.buildMuscle) {
            benefits.append((
                icon: "dumbbell.fill",
                title: "Protein & Macro Tracking",
                description: "Hit your protein targets with detailed macro breakdowns. Track every gram and time your nutrition around workouts for maximum gains."
            ))
        }

        // Eat Healthier
        if state.selectedGoals.contains(.eatHealthier) {
            benefits.append((
                icon: "leaf.fill",
                title: "Nutrition Scoring",
                description: "Every food gets an A+ to F grade. See at a glance which choices support your health—and which ones to swap out."
            ))
        }

        // Track Nutrition
        if state.selectedGoals.contains(.trackNutrition) {
            benefits.append((
                icon: "chart.bar.fill",
                title: "Complete Nutrient Insights",
                description: "Track 30+ vitamins and minerals, not just calories. See your daily values and discover gaps in your nutrition before they become problems."
            ))
        }

        // Always add food reactions if any safety-related goal is selected
        if state.selectedGoals.contains(.foodSafety) || state.selectedGoals.contains(.manageAllergies) || state.selectedGoals.contains(.eatHealthier) {
            // Check if we haven't already added too many
            if benefits.count < 4 {
                benefits.append((
                    icon: "waveform.path.ecg",
                    title: "Food Reaction Tracking",
                    description: "Log how foods make you feel and spot patterns over time. Identify trigger foods and sensitivities—without the guesswork."
                ))
            }
        }

        // If no goals selected, show general benefits
        if benefits.isEmpty {
            benefits = [
                (icon: "camera.viewfinder", title: "Instant Food Scanning", description: "Scan any barcode or snap a photo. Get complete nutrition info in seconds."),
                (icon: "chart.bar.fill", title: "Smart Tracking", description: "Track calories, macros, and nutrients without the hassle."),
                (icon: "shield.checkered", title: "Know Your Ingredients", description: "See exactly what's in your food—additives, allergens, and all.")
            ]
        }

        // Limit to 3 features for clean display
        return Array(benefits.prefix(3))
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 50)

            // Headline
            VStack(spacing: 8) {
                Text("Here's how we'll")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))

                Text("help you succeed")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(state.palette.primary)
            }
            .multilineTextAlignment(.center)
            .opacity(showContent ? 1 : 0)

            Text("Based on your goals")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(white: 0.5))
                .padding(.top, 12)
                .opacity(showContent ? 1 : 0)

            Spacer().frame(height: 32)

            // Feature cards
            VStack(spacing: 16) {
                ForEach(Array(featureBenefits.enumerated()), id: \.offset) { index, feature in
                    FeatureBenefitCard(
                        icon: feature.icon,
                        title: feature.title,
                        description: feature.description,
                        palette: state.palette,
                        isVisible: visibleFeatures.contains(index)
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Continue button
            PremiumButton(
                text: "Continue",
                palette: state.palette,
                action: onContinue
            )
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            // Fade in header
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }

            // Stagger feature card appearances
            for i in 0..<featureBenefits.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i) * 0.2) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        _ = visibleFeatures.insert(i)
                    }
                }
            }
        }
    }
}

struct FeatureBenefitCard: View {
    let icon: String
    let title: String
    let description: String
    let palette: OnboardingPalette
    let isVisible: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(palette.primary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(palette.primary.opacity(0.12))
                )

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(white: 0.2))

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(Color(white: 0.5))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.85))
                .shadow(color: Color.black.opacity(0.06), radius: 8, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
    }
}

// MARK: - Calculating Screens (micro-processing moments after key choices)

struct GoalsProcessingScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    let onComplete: () -> Void

    @State private var showMessage = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack {
            Spacer()

            // Animated pulse
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(state.palette.primary.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                        .frame(width: 100 + CGFloat(i * 40), height: 100 + CGFloat(i * 40))
                        .scaleEffect(pulseScale)
                        .opacity(showMessage ? 1 : 0)
                }

                Image(systemName: "target")
                    .font(.system(size: 44))
                    .foregroundColor(state.palette.primary)
                    .scaleEffect(pulseScale)
            }

            Spacer().frame(height: 40)

            Text("Mapping your goals...")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(state.palette.primary)
                .opacity(showMessage ? 1 : 0)

            Text(goalsMessage)
                .font(.system(size: 15))
                .foregroundColor(Color(white: 0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 12)
                .opacity(showMessage ? 1 : 0)

            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showMessage = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onComplete()
            }
        }
    }

    private var goalsMessage: String {
        if state.selectedGoals.contains(.loseWeight) {
            return "We'll help you track progress towards your ideal weight."
        } else if state.selectedGoals.contains(.buildMuscle) {
            return "Protein and macro insights coming your way."
        } else if state.selectedGoals.contains(.foodSafety) || state.selectedGoals.contains(.manageAllergies) {
            return "Your safety is our priority."
        } else {
            return "Personalising your nutrition journey."
        }
    }
}

struct ActivityProcessingScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    let onComplete: () -> Void

    @State private var showMessage = false
    @State private var progress: CGFloat = 0

    var body: some View {
        VStack {
            Spacer()

            // Activity indicator
            ZStack {
                Circle()
                    .stroke(state.palette.primary.opacity(0.2), lineWidth: 6)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(state.palette.primary, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                Image(systemName: state.activityLevel.icon)
                    .font(.system(size: 36))
                    .foregroundColor(state.palette.primary)
            }

            Spacer().frame(height: 40)

            Text("Calculating your needs...")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(state.palette.primary)
                .opacity(showMessage ? 1 : 0)

            Text("Based on \(state.activityLevel.rawValue.lowercased()) lifestyle")
                .font(.system(size: 15))
                .foregroundColor(Color(white: 0.5))
                .padding(.top, 8)
                .opacity(showMessage ? 1 : 0)

            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                showMessage = true
            }
            withAnimation(.easeInOut(duration: 2.0)) {
                progress = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                onComplete()
            }
        }
    }
}

struct ProfileBuildingScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    let onComplete: () -> Void

    @State private var showElements = false
    @State private var currentPhrase = 0

    private let phrases = [
        "Understanding your lifestyle...",
        "Building your profile...",
        "Almost there..."
    ]

    var body: some View {
        VStack {
            Spacer()

            // Assembling animation
            ZStack {
                ForEach(0..<4, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(state.palette.primary.opacity(0.2 + Double(i) * 0.2))
                        .frame(width: 60, height: 60)
                        .offset(
                            x: showElements ? 0 : CGFloat([-30, 30, -30, 30][i]),
                            y: showElements ? 0 : CGFloat([-30, -30, 30, 30][i])
                        )
                        .rotationEffect(.degrees(showElements ? 0 : Double(i * 90)))
                }

                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .opacity(showElements ? 1 : 0)
            }
            .frame(width: 120, height: 120)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(state.palette.primary)
                    .opacity(showElements ? 1 : 0)
            )

            Spacer().frame(height: 40)

            Text(phrases[currentPhrase])
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(state.palette.primary)
                .animation(.easeInOut, value: currentPhrase)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                showElements = true
            }

            // Cycle through phrases
            for i in 1..<phrases.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.9) {
                    withAnimation {
                        currentPhrase = i
                    }
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                onComplete()
            }
        }
    }
}

// MARK: - Card Components

struct GoalCard: View {
    let goal: OnboardingGoal
    let isSelected: Bool
    let palette: OnboardingPalette
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: goal.icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .white : palette.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isSelected ? palette.primary : palette.primary.opacity(0.1))
                    )

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.rawValue)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(isSelected ? .white : Color(white: 0.2))

                    Text(goal.description)
                        .font(.system(size: 13))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : Color(white: 0.5))
                }

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? palette.primary : Color.white.opacity(0.8))
                    .shadow(color: isSelected ? palette.primary.opacity(0.3) : Color.black.opacity(0.05), radius: isSelected ? 12 : 4, y: isSelected ? 4 : 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActivityCard: View {
    let level: ActivityLevelOption
    let isSelected: Bool
    let palette: OnboardingPalette
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Icon
                Image(systemName: level.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : palette.primary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? palette.primary : palette.primary.opacity(0.1))
                    )

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : Color(white: 0.2))

                    Text(level.description)
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : Color(white: 0.5))
                }

                Spacer()

                // Selection indicator
                Circle()
                    .fill(isSelected ? Color.white : Color.clear)
                    .frame(width: 8, height: 8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? palette.primary : Color.white.opacity(0.8))
                    .shadow(color: isSelected ? palette.primary.opacity(0.3) : Color.black.opacity(0.05), radius: isSelected ? 10 : 4, y: isSelected ? 3 : 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HabitTag: View {
    let habit: EatingHabitOption
    let isSelected: Bool
    let palette: OnboardingPalette
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                Image(systemName: habit.icon)
                    .font(.system(size: 14))

                Text(habit.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? .white : Color(white: 0.4))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? palette.primary : Color.white.opacity(0.8))
                    .shadow(color: isSelected ? palette.primary.opacity(0.3) : Color.black.opacity(0.05), radius: isSelected ? 6 : 3, y: 2)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PremiumExperienceCard: View {
    let experience: DietExperienceOption
    let isSelected: Bool
    let palette: OnboardingPalette
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: experience.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : palette.primary)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(isSelected ? palette.primary : palette.primary.opacity(0.1))
                    )

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(experience.rawValue)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(isSelected ? .white : Color(white: 0.2))

                    Text(experience.description)
                        .font(.system(size: 13))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : Color(white: 0.5))
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected ? palette.primary : Color.white.opacity(0.8))
                    .shadow(color: isSelected ? palette.primary.opacity(0.3) : Color.black.opacity(0.05), radius: isSelected ? 12 : 5, y: isSelected ? 4 : 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Pro CTA Screen

struct ProUpgradeScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    let onUpgrade: () -> Void
    let onContinueFree: () -> Void

    @State private var showContent = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Pro badge with glow
            ZStack {
                // Glow effect
                Circle()
                    .fill(Color(red: 0.95, green: 0.65, blue: 0.30).opacity(0.3))
                    .frame(width: 100, height: 100)
                    .blur(radius: 30)

                Image(systemName: "crown.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.85, blue: 0.40), Color(red: 0.95, green: 0.60, blue: 0.25)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.8)

            Spacer().frame(height: 32)

            // Headline
            VStack(spacing: 8) {
                Text("Pro users achieve")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))

                Text("goals 2.3x faster")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(state.palette.primary)
            }
            .multilineTextAlignment(.center)
            .opacity(showContent ? 1 : 0)

            Spacer().frame(height: 12)

            Text("Unlock everything NutraSafe has to offer")
                .font(.system(size: 15))
                .foregroundColor(Color(white: 0.5))
                .opacity(showContent ? 1 : 0)

            Spacer().frame(height: 36)

            // Three key features only
            VStack(spacing: 16) {
                CompactProFeature(icon: "infinity", text: "Unlimited tracking")
                CompactProFeature(icon: "camera.viewfinder", text: "AI meal scanner")
                CompactProFeature(icon: "timer", text: "Fasting tracker")
            }
            .opacity(showContent ? 1 : 0)

            Spacer()

            // Buttons
            VStack(spacing: 16) {
                // Pro button
                Button(action: onUpgrade) {
                    HStack(spacing: 10) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16))

                        Text("Start 7-Day Free Trial")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.70, blue: 0.30), Color(red: 0.95, green: 0.55, blue: 0.25)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color(red: 0.95, green: 0.60, blue: 0.25).opacity(0.4), radius: 12, y: 4)
                }

                // Free continue
                Button(action: onContinueFree) {
                    Text("Maybe later")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(white: 0.5))
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }
}

struct CompactProFeature: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(red: 0.95, green: 0.60, blue: 0.30))
                .frame(width: 32)

            Text(text)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color(white: 0.25))

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(red: 0.95, green: 0.60, blue: 0.30).opacity(0.8))
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Diet Setup Screen

struct DietSetupScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    let onContinue: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // Headline
            VStack(spacing: 8) {
                Text("Choose your")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))

                Text("eating approach")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))
            }
            .multilineTextAlignment(.center)

            Text("This sets your default macro targets")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(white: 0.5))
                .padding(.top, 12)

            Spacer().frame(height: 24)

            // Diet options
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(DietType.allCases, id: \.rawValue) { diet in
                        DietTypeCard(
                            diet: diet,
                            isSelected: state.selectedDietType == diet,
                            palette: state.palette,
                            onSelect: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    state.selectedDietType = diet
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            // Buttons
            VStack(spacing: 14) {
                PremiumButton(
                    text: "Continue",
                    palette: state.palette,
                    action: onContinue
                )

                Button(action: onSkip) {
                    Text("Skip for now")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(white: 0.5))
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }
}

struct DietTypeCard: View {
    let diet: DietType
    let isSelected: Bool
    let palette: OnboardingPalette
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Icon
                Image(systemName: dietIcon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : palette.primary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? palette.primary : palette.primary.opacity(0.1))
                    )

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(diet.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : Color(white: 0.2))

                    Text(diet.shortDescription)
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : Color(white: 0.5))
                        .lineLimit(1)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? palette.primary : Color.white.opacity(0.8))
                    .shadow(color: isSelected ? palette.primary.opacity(0.3) : Color.black.opacity(0.05), radius: isSelected ? 10 : 4, y: isSelected ? 3 : 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var dietIcon: String {
        switch diet {
        case .flexible: return "checkmark.circle"
        case .keto: return "flame"
        case .lowCarb: return "leaf"
        case .highProtein, .highProteinMax: return "dumbbell"
        case .mediterranean: return "fish"
        case .paleo: return "hare"
        }
    }
}

// MARK: - Calorie Target Screen

struct CalorieTargetScreen: View {
    @ObservedObject var state: PremiumOnboardingState
    let onContinue: () -> Void
    let onSkip: () -> Void

    @State private var calorieOffset: Int = 0 // -500 to +500 from baseline

    // Use proper BMR-based TDEE calculation from state
    private var maintenanceCalories: Int {
        state.tdee
    }

    private var adjustedCalories: Int {
        // Adjust based on goals
        var calories = maintenanceCalories + calorieOffset

        if state.selectedGoals.contains(.loseWeight) {
            calories -= 300 // Default deficit
        } else if state.selectedGoals.contains(.buildMuscle) {
            calories += 200 // Default surplus
        }

        return max(1200, min(4000, calories))
    }

    // Calorie deficit/surplus based on goal
    private var goalAdjustment: Int {
        if state.selectedGoals.contains(.loseWeight) {
            return -300
        } else if state.selectedGoals.contains(.buildMuscle) {
            return 200
        }
        return 0
    }

    private var goalExplanation: (title: String, detail: String) {
        if state.selectedGoals.contains(.loseWeight) {
            let deficit = abs(goalAdjustment + calorieOffset)
            let weeklyLoss = Double(deficit * 7) / 3500.0 // ~3500 cal = 1 lb
            let lossText = weeklyLoss >= 0.5 ? String(format: "~%.1f lb/week", weeklyLoss) : "gradual loss"
            return (
                "300 cal deficit from maintenance",
                "This creates a sustainable deficit for \(lossText) fat loss without muscle loss."
            )
        } else if state.selectedGoals.contains(.buildMuscle) {
            return (
                "200 cal surplus for muscle growth",
                "A moderate surplus supports muscle building while minimising fat gain."
            )
        } else {
            return (
                "Maintenance calories",
                "This will help you maintain your current weight and body composition."
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 50)

            // Headline
            VStack(spacing: 8) {
                Text("Your daily")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))

                Text("calorie target")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Color(white: 0.2))
            }
            .multilineTextAlignment(.center)

            Spacer().frame(height: 24)

            // Maintenance calories explanation
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "flame")
                        .font(.system(size: 14))
                        .foregroundColor(state.palette.primary)
                    Text("Your maintenance: \(maintenanceCalories) cal/day")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(white: 0.35))
                }

                Text("Calculated from your BMR × \(state.activityLevel.rawValue.lowercased()) activity")
                    .font(.system(size: 13))
                    .foregroundColor(Color(white: 0.5))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(state.palette.primary.opacity(0.08))
            )
            .padding(.horizontal, 32)

            Spacer().frame(height: 28)

            // Big calorie display
            VStack(spacing: 8) {
                Text("\(adjustedCalories)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(state.palette.primary)

                Text("calories per day")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color(white: 0.4))
            }

            // Goal adjustment explanation
            if goalAdjustment != 0 || calorieOffset != 0 {
                VStack(spacing: 4) {
                    Text(goalExplanation.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(state.palette.primary)

                    Text(goalExplanation.detail)
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.5))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 12)
                .padding(.horizontal, 40)
            }

            Spacer().frame(height: 24)

            // Adjustment slider
            VStack(spacing: 12) {
                Text("Fine-tune your target")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(white: 0.5))

                HStack(spacing: 16) {
                    Text("Less")
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.5))

                    Slider(value: Binding(
                        get: { Double(calorieOffset) },
                        set: { calorieOffset = Int($0) }
                    ), in: -500...500, step: 50)
                    .accentColor(state.palette.primary)

                    Text("More")
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.5))
                }
                .padding(.horizontal, 32)

                if calorieOffset != 0 {
                    Text("\(calorieOffset > 0 ? "+" : "")\(calorieOffset) from recommended")
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.5))
                }
            }

            Spacer().frame(height: 24)

            // Macro preview
            HStack(spacing: 20) {
                MacroPreviewPill(
                    name: "Protein",
                    grams: macrosForDiet.protein,
                    color: Color.blue
                )
                MacroPreviewPill(
                    name: "Carbs",
                    grams: macrosForDiet.carbs,
                    color: Color.orange
                )
                MacroPreviewPill(
                    name: "Fat",
                    grams: macrosForDiet.fat,
                    color: Color.purple
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            // Buttons
            VStack(spacing: 14) {
                PremiumButton(
                    text: "Continue",
                    palette: state.palette,
                    action: {
                        state.targetCalories = adjustedCalories
                        onContinue()
                    }
                )

                Button(action: onSkip) {
                    Text("Skip for now")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(white: 0.5))
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }

    private var macrosForDiet: (protein: Int, carbs: Int, fat: Int) {
        let calories = Double(adjustedCalories)

        switch state.selectedDietType {
        case .keto:
            // 5% carbs, 20% protein, 75% fat
            return (
                protein: Int(calories * 0.20 / 4),
                carbs: Int(calories * 0.05 / 4),
                fat: Int(calories * 0.75 / 9)
            )
        case .lowCarb:
            // 20% carbs, 30% protein, 50% fat
            return (
                protein: Int(calories * 0.30 / 4),
                carbs: Int(calories * 0.20 / 4),
                fat: Int(calories * 0.50 / 9)
            )
        case .highProtein:
            // 40% carbs, 35% protein, 25% fat
            return (
                protein: Int(calories * 0.35 / 4),
                carbs: Int(calories * 0.40 / 4),
                fat: Int(calories * 0.25 / 9)
            )
        case .highProteinMax:
            // 25% carbs, 50% protein, 25% fat
            return (
                protein: Int(calories * 0.50 / 4),
                carbs: Int(calories * 0.25 / 4),
                fat: Int(calories * 0.25 / 9)
            )
        case .mediterranean, .paleo, .flexible:
            // 45% carbs, 25% protein, 30% fat
            return (
                protein: Int(calories * 0.25 / 4),
                carbs: Int(calories * 0.45 / 4),
                fat: Int(calories * 0.30 / 9)
            )
        }
    }
}

struct MacroPreviewPill: View {
    let name: String
    let grams: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(grams)g")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(white: 0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Preview

#Preview {
    GoalsScreen(state: PremiumOnboardingState()) { }
}
