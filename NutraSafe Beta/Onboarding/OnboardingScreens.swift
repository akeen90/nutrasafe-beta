//
//  OnboardingScreens.swift
//  NutraSafe Beta
//
//  All 9 onboarding screens with UK English
//  Created by Claude on 2025-10-22.
//

import SwiftUI

// MARK: - Screen 1: Welcome

struct WelcomeScreen: View {
    @Binding var currentPage: Int

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 100))
                .foregroundColor(.blue)

            VStack(spacing: 16) {
                Text("Welcome to NutraSafe")
                    .font(.system(size: 34, weight: .bold))
                    .multilineTextAlignment(.center)

                Text("Your Complete Nutrition &\nFood Safety Companion")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            ContinueButton(currentPage: $currentPage)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Screen 2: Health Disclaimer

struct DisclaimerScreen: View {
    @Binding var currentPage: Int
    @State private var hasAccepted = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)

                    Text("Important Health Information")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)

                VStack(alignment: .leading, spacing: 16) {
                    DisclaimerPoint(text: "NutraSafe is designed to help you track nutrition and identify potential food safety concerns.")
                    DisclaimerPoint(text: "This app is NOT a substitute for professional medical advice, diagnosis, or treatment.")
                    DisclaimerPoint(text: "Always verify food labels yourself and consult healthcare professionals for medical decisions.")
                    DisclaimerPoint(text: "Results cannot be guaranteed to be 100% accurate.")
                }
                .padding(.horizontal, 24)

                Button(action: { hasAccepted.toggle() }) {
                    HStack(spacing: 12) {
                        Image(systemName: hasAccepted ? "checkmark.square.fill" : "square")
                            .font(.system(size: 24))
                            .foregroundColor(hasAccepted ? .blue : .gray)

                        Text("I understand and agree to use this app as an informational tool only")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(.horizontal, 24)

                Button(action: {
                    OnboardingManager.shared.acceptDisclaimer()
                    currentPage += 1
                }) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(hasAccepted ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(hasAccepted ? Color.blue : Color.gray.opacity(0.3))
                        .cornerRadius(16)
                }
                .disabled(!hasAccepted)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct DisclaimerPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "circle.fill")
                .font(.system(size: 8))
                .foregroundColor(.orange)
                .padding(.top, 6)

            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Screen 3: Adding Food

struct AddingFoodScreen: View {
    @Binding var currentPage: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("3 Ways to Add Food")
                    .font(.system(size: 32, weight: .bold))
                    .padding(.horizontal, 24)
                    .padding(.top, 40)

                VStack(spacing: 16) {
                    FeatureCard(
                        icon: "barcode.viewfinder",
                        title: "Barcode Scanner",
                        description: "Scan product barcodes for instant lookup"
                    )

                    FeatureCard(
                        icon: "magnifyingglass",
                        title: "Search Database",
                        description: "Search 29,000+ foods and generic items"
                    )

                    FeatureCard(
                        icon: "pencil",
                        title: "Manual Entry",
                        description: "Create custom foods from scratch"
                    )
                }
                .padding(.horizontal, 20)

                InfoBox(text: "Every food shows nutrition score, allergens, and full ingredient analysis")
                    .padding(.horizontal, 24)

                HStack(spacing: 12) {
                    SkipButton(currentPage: $currentPage)
                    ContinueButton(currentPage: $currentPage)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Screen 4: Food Detail Page

struct FoodDetailScreen: View {
    @Binding var currentPage: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Complete Food Information")
                    .font(.system(size: 32, weight: .bold))
                    .padding(.horizontal, 24)
                    .padding(.top, 40)

                Text("On every food detail page, you'll see:")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)

                VStack(spacing: 16) {
                    DetailFeature(
                        icon: "chart.bar.fill",
                        colour: .green,
                        title: "Nutrition Score (A+ to F)",
                        description: "Instant health rating based on nutrients"
                    )

                    DetailFeature(
                        icon: "exclamationmark.triangle.fill",
                        colour: .red,
                        title: "Allergen Warnings",
                        description: "Big red banner if your 14 allergens are detected"
                    )

                    DetailFeature(
                        icon: "flask.fill",
                        colour: .orange,
                        title: "Ingredient Analysis",
                        description: "Every ingredient rated with safety levels"
                    )

                    DetailFeature(
                        icon: "chart.pie.fill",
                        colour: .purple,
                        title: "Micronutrient Breakdown",
                        description: "20+ vitamins & minerals with daily % values"
                    )
                }
                .padding(.horizontal, 20)

                HStack(spacing: 12) {
                    SkipButton(currentPage: $currentPage)
                    ContinueButton(currentPage: $currentPage)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Screen 5: Tracking Nutrients

struct TrackingNutrientsScreen: View {
    @Binding var currentPage: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Track Your Micronutrients")
                    .font(.system(size: 32, weight: .bold))
                    .padding(.horizontal, 24)
                    .padding(.top, 40)

                Text("Diary Tab → Nutrients")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 24)

                VStack(spacing: 16) {
                    NutrientFeature(
                        title: "Nutrient Coverage",
                        description: "Visual status of each vitamin & mineral",
                        details: [
                            "Green: Good coverage (70-100%)",
                            "Orange: Moderate (40-69%)",
                            "Red: Low coverage (0-39%)"
                        ]
                    )

                    NutrientFeature(
                        title: "7-Day Timeline",
                        description: "Tap any nutrient to see:",
                        details: [
                            "Which foods provided it",
                            "How often it appears",
                            "Trend indicators"
                        ]
                    )
                }
                .padding(.horizontal, 20)

                InfoBox(text: "All nutrients are tracked automatically as you log meals!")
                    .padding(.horizontal, 24)

                HStack(spacing: 12) {
                    SkipButton(currentPage: $currentPage)
                    ContinueButton(currentPage: $currentPage)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Screen 6: Food Reactions

struct FoodReactionsScreen: View {
    @Binding var currentPage: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Track Food Reactions")
                    .font(.system(size: 32, weight: .bold))
                    .padding(.horizontal, 24)
                    .padding(.top, 40)

                Text("Food Tab → Reactions")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 16) {
                    Text("How to Log:")
                        .font(.system(size: 20, weight: .semibold))

                    StepItem(number: "1", text: "Tap 'Log Reaction'")
                    StepItem(number: "2", text: "Select food from your recent meals")
                    StepItem(number: "3", text: "Pick symptoms and severity level")
                    StepItem(number: "4", text: "Save to track patterns over time")
                }
                .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Pattern Analysis")
                        .font(.system(size: 20, weight: .semibold))

                    Text("The app helps you spot patterns:")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)

                    BulletPoint(text: "Ingredients that appear frequently")
                    BulletPoint(text: "Time-based trends")
                    BulletPoint(text: "Severity tracking")
                }
                .padding(.horizontal, 24)

                WarningBox(text: "For personal tracking only - not medical advice. Consult a doctor for allergies.")
                    .padding(.horizontal, 24)

                HStack(spacing: 12) {
                    SkipButton(currentPage: $currentPage)
                    ContinueButton(currentPage: $currentPage)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Screen 7: Fasting Timer

struct FastingTimerScreen: View {
    @Binding var currentPage: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Intermittent Fasting Timer")
                    .font(.system(size: 32, weight: .bold))
                    .padding(.horizontal, 24)
                    .padding(.top, 40)

                Text("Food Tab → Fasting Sub-tab")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 16) {
                    Text("How to Use:")
                        .font(.system(size: 20, weight: .semibold))

                    StepItem(number: "1", text: "Choose preset: 16h, 18h, 20h, or 24h")
                    StepItem(number: "2", text: "Tap 'Start Fasting'")
                    StepItem(number: "3", text: "Watch circular progress ring")
                    StepItem(number: "4", text: "Track fasting stages with benefits")
                }
                .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 12) {
                    Text("8 Fasting Stages:")
                        .font(.system(size: 20, weight: .semibold))

                    FastingStage(hours: "0-4h", name: "Digestion", icon: "fork.knife")
                    FastingStage(hours: "4-8h", name: "Glucose Depletion", icon: "bolt.fill")
                    FastingStage(hours: "8-12h", name: "Fat Burning Begins", icon: "flame.fill")
                    FastingStage(hours: "12-16h", name: "Ketosis Initiation", icon: "sparkles")
                    FastingStage(hours: "16-24h", name: "Deep Ketosis", icon: "star.fill")
                    FastingStage(hours: "24-48h", name: "Autophagy Peaks", icon: "wand.and.stars")
                }
                .padding(.horizontal, 24)

                InfoBox(text: "Fasting timer appears in Dynamic Island - check progress anytime!")
                    .padding(.horizontal, 24)

                HStack(spacing: 12) {
                    SkipButton(currentPage: $currentPage)
                    ContinueButton(currentPage: $currentPage)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Screen 8: Use By Tracker

struct UseByTrackerScreen: View {
    @Binding var currentPage: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Use By")
                    .font(.system(size: 32, weight: .bold))
                    .padding(.horizontal, 24)
                    .padding(.top, 40)

                Text("Track open foods and know when they expire")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 16) {
                    Text("How to Use:")
                        .font(.system(size: 20, weight: .semibold))

                    StepItem(number: "1", text: "Tap + to add food item")
                    StepItem(number: "2", text: "Set expiry date")
                    StepItem(number: "3", text: "Add storage notes (optional)")
                    StepItem(number: "4", text: "Get reminders before it spoils")
                }
                .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Smart Countdown:")
                        .font(.system(size: 20, weight: .semibold))

                    // Removed 'Unopened' indicator (deprecated)
                    OnboardingStatusIndicator(colour: .green, label: "Fresh", description: "7+ days remaining")
                    OnboardingStatusIndicator(colour: .yellow, label: "This Week", description: "4-7 days")
                    OnboardingStatusIndicator(colour: .orange, label: "Soon", description: "1-3 days")
                    OnboardingStatusIndicator(colour: .red, label: "Today", description: "Last day!")
                }
                .padding(.horizontal, 24)

                InfoBox(text: "Never forget about food again - get notified before it expires!")
                    .padding(.horizontal, 24)

                HStack(spacing: 12) {
                    SkipButton(currentPage: $currentPage)
                    ContinueButton(currentPage: $currentPage)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Screen 9: Settings & Permissions

struct SettingsFeatureScreen: View {
    @Binding var currentPage: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Optional Features")
                    .font(.system(size: 32, weight: .bold))
                    .padding(.horizontal, 24)
                    .padding(.top, 40)

                Text("Settings Tab → Preferences")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 24)

                VStack(spacing: 16) {
                    NutrientFeature(
                        title: "Apple Health Integration",
                        description: "Sync exercise calories to your diary",
                        details: [
                            "Enable in Settings → Apple Health",
                            "Shows activity calories in diary header",
                            "Updates automatically throughout the day"
                        ]
                    )

                    NutrientFeature(
                        title: "Use By Notifications",
                        description: "Get reminders for expiring items",
                        details: [
                            "Enable in Settings → Notifications",
                            "Choose notification time",
                            "Never miss an expiration date"
                        ]
                    )
                }
                .padding(.horizontal, 20)

                InfoBox(text: "Both features are optional and can be enabled anytime in Settings!")
                    .padding(.horizontal, 24)

                HStack(spacing: 12) {
                    SkipButton(currentPage: $currentPage)
                    ContinueButton(currentPage: $currentPage)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Screen 10: Completion

struct CompletionScreen: View {
    let onComplete: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.green)

                Text("You're All Set!")
                    .font(.system(size: 34, weight: .bold))

                VStack(alignment: .leading, spacing: 16) {
                    Text("You're Ready To:")
                        .font(.system(size: 20, weight: .semibold))

                    CheckmarkItem(text: "Add food 3 ways: Scan, Search, or Manual")
                    CheckmarkItem(text: "See nutrition scores & allergen warnings")
                    CheckmarkItem(text: "Track 20+ vitamins & minerals automatically")
                    CheckmarkItem(text: "Log reactions and identify patterns")
                    CheckmarkItem(text: "Track intermittent fasts with 8 stages")
                    CheckmarkItem(text: "Track expiry dates and never waste food")
                }
                .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Start Guide:")
                        .font(.system(size: 20, weight: .semibold))

                    QuickTip(number: "1", text: "Set up your allergens first: Settings → Health & Safety")
                    QuickTip(number: "2", text: "Add your first meal: Tap + → Search or Scan")
                    QuickTip(number: "3", text: "Check your nutrients: Diary → Nutrients tab")
                }
                .padding(.horizontal, 24)

                Text("Restart this guide anytime:\nSettings → About → Restart Onboarding")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()

                Button(action: {
                    OnboardingManager.shared.completeOnboarding()
                    onComplete()
                }) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Reusable Components

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.blue)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}

struct DetailFeature: View {
    let icon: String
    let colour: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(colour)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

struct NutrientFeature: View {
    let title: String
    let description: String
    let details: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            ForEach(details, id: \.self) { detail in
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                    Text(detail)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}

struct StepItem: View {
    let number: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color.blue)
                .clipShape(Circle())

            Text(text)
                .font(.system(size: 16))
        }
    }
}

struct FastingStage: View {
    let hours: String
    let name: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.orange)
                .frame(width: 24)

            Text(hours)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.blue)
                .frame(width: 60, alignment: .leading)

            Text(name)
                .font(.system(size: 14))
                .foregroundColor(.primary)
        }
    }
}

struct OnboardingStatusIndicator: View {
    let colour: Color
    let label: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(colour)
                .frame(width: 12, height: 12)

            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 80, alignment: .leading)

            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
}

struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 16, weight: .bold))
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
}

struct CheckmarkItem: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(text)
                .font(.system(size: 16))
        }
    }
}

struct QuickTip: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.primary)
        }
    }
}

struct InfoBox: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
            Text(text)
                .font(.system(size: 14))
        }
        .padding(12)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

struct WarningBox: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(text)
                .font(.system(size: 14))
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
}

struct SkipButton: View {
    @Binding var currentPage: Int

    var body: some View {
        Button(action: { if currentPage > 0 { currentPage -= 1 } }) {
            Text("Back")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(.ultraThinMaterial)
                .cornerRadius(28)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                )
        }
        .disabled(currentPage == 0)
    }
}

struct ContinueButton: View {
    @Binding var currentPage: Int

    var body: some View {
        Button(action: { currentPage += 1 }) {
            Text("Continue")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .cornerRadius(28)
                .shadow(color: Color.purple.opacity(0.25), radius: 14, x: 0, y: 8)
        }
    }
}
