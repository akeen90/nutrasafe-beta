//
//  FeatureTipsManager.swift
//  NutraSafe Beta
//
//  Manages first-time feature tip display state
//

import Foundation
import SwiftUI

/// Manages which feature tips have been shown to the user
class FeatureTipsManager: ObservableObject {
    static let shared = FeatureTipsManager()

    /// Trigger to force-show the first tip after reset (incremented on reset)
    @Published var resetTrigger: Int = 0

    /// Keys for tracking which tips have been seen
    enum TipKey: String, CaseIterable {
        // Diary Tab
        case diaryOverview = "hasSeenTip_diaryOverview"
        case diarySearch = "hasSeenTip_diarySearch"

        // Health Tab
        case healthOverview = "hasSeenTip_healthOverview"
        case healthReactions = "hasSeenTip_healthReactions"
        case healthPatterns = "hasSeenTip_healthPatterns"
        case healthFasting = "hasSeenTip_healthFasting"

        // Progress Tab
        case progressOverview = "hasSeenTip_progressOverview"
        case progressWeight = "hasSeenTip_progressWeight"

        // Use By Tab
        case useByOverview = "hasSeenTip_useByOverview"

        // Nutrients Tab
        case nutrientsOverview = "hasSeenTip_nutrientsOverview"

        // Insights Tab
        case insightsOverview = "hasSeenTip_insightsOverview"
        case additivesTracker = "hasSeenTip_additivesTracker"
    }

    /// Tip content for display
    struct TipContent {
        let title: String
        let message: String
        let icon: String
        let accentColor: Color
        let bulletPoints: [String]?

        init(title: String, message: String, icon: String, accentColor: Color, bulletPoints: [String]? = nil) {
            self.title = title
            self.message = message
            self.icon = icon
            self.accentColor = accentColor
            self.bulletPoints = bulletPoints
        }
    }

    /// Content for each tip - with clear navigation guidance (UK-friendly language)
    static let tipContent: [TipKey: TipContent] = [
        .diaryOverview: TipContent(
            title: "Your Food Diary",
            message: "This is your daily food log. Hit the + button to add what you've eaten — it's quick and easy!",
            icon: "fork.knife.circle.fill",
            accentColor: .blue,
            bulletPoints: [
                "Tap + to search, scan a barcode, or add manually",
                "Track your calories and macros at a glance",
                "Tap any food to edit portions or see details",
                "Swipe left and right to browse different days"
            ]
        ),
        .diarySearch: TipContent(
            title: "Add Food",
            message: "Search our database of thousands of UK foods, or scan a product barcode for instant results.",
            icon: "magnifyingglass",
            accentColor: .blue
        ),
        .healthOverview: TipContent(
            title: "Health & Wellbeing",
            message: "Two powerful tools in one place — track how foods make you feel, or try intermittent fasting.",
            icon: "heart.circle.fill",
            accentColor: .pink,
            bulletPoints: [
                "Log reactions when food doesn't sit right",
                "Try fasting plans like 16:8 or 18:6",
                "We'll spot patterns in problem foods",
                "Great for finding what works for you"
            ]
        ),
        .healthReactions: TipContent(
            title: "Food Reactions",
            message: "Some foods just don't agree with us. Log how you feel and we'll help you spot the culprits.",
            icon: "exclamationmark.bubble.fill",
            accentColor: .orange,
            bulletPoints: [
                "Tap + then 'Log Reaction' after eating",
                "Pick the food and describe how you feel",
                "Ingredients are tracked automatically",
                "After a few logs, patterns will emerge"
            ]
        ),
        .healthPatterns: TipContent(
            title: "Spot the Patterns",
            message: "Once you've logged a few reactions, we'll show which ingredients keep popping up.",
            icon: "chart.bar.doc.horizontal.fill",
            accentColor: .purple,
            bulletPoints: [
                "See common ingredients across reactions",
                "Discover potential trigger foods",
                "Track how often issues occur"
            ]
        ),
        .healthFasting: TipContent(
            title: "Intermittent Fasting",
            message: "Give your body regular breaks from eating. Start with 16:8 — you'll be asleep for most of it!",
            icon: "timer",
            accentColor: .green,
            bulletPoints: [
                "Pick a plan: 16:8, 18:6, 20:4, and more",
                "Watch your progress with a live timer",
                "Sleep counts towards fasting time",
                "Build streaks and stay motivated"
            ]
        ),
        .progressOverview: TipContent(
            title: "Your Progress",
            message: "Keep track of your weight and see how far you've come. Small changes add up!",
            icon: "figure.run.circle.fill",
            accentColor: .teal,
            bulletPoints: [
                "Tap + then 'Weigh In' to log today",
                "Watch your progress on a chart",
                "Syncs with Apple Health if you like",
                "Set a goal to keep you on track"
            ]
        ),
        .progressWeight: TipContent(
            title: "Weight Tracking",
            message: "Regular weigh-ins help you see the bigger picture. Don't stress about daily fluctuations!",
            icon: "scalemass.fill",
            accentColor: .teal
        ),
        .useByOverview: TipContent(
            title: "Use-By Tracker",
            message: "No more forgotten leftovers! Add opened items and we'll nudge you before they expire.",
            icon: "calendar.circle.fill",
            accentColor: .orange,
            bulletPoints: [
                "Tap + then 'Use By' to add items",
                "Get a heads up before food goes off",
                "Urgent items bubble to the top",
                "Save money by wasting less"
            ]
        ),
        .nutrientsOverview: TipContent(
            title: "Vitamins & Minerals",
            message: "See which vitamins and minerals you're getting from the foods in your diary. Great for spotting gaps in your diet.",
            icon: "leaf.circle.fill",
            accentColor: .green,
            bulletPoints: [
                "Nutrients grouped by how often you eat them",
                "Tap any nutrient for more details",
                "See your intake over the last 7 days",
                "Get food suggestions to fill gaps"
            ]
        ),
        .insightsOverview: TipContent(
            title: "Food Insights",
            message: "Dig deeper into your diet with detailed analysis. Switch between Additives and Vitamins & Minerals using the tabs.",
            icon: "chart.bar.xaxis",
            accentColor: .indigo,
            bulletPoints: [
                "Track your exposure to food additives",
                "Monitor vitamin and mineral intake",
                "Understand what's really in your food",
                "Make more informed food choices"
            ]
        ),
        .additivesTracker: TipContent(
            title: "Additive Exposure Tracker",
            message: "See which food additives (E-numbers) you've consumed. Track your exposure over time to make healthier choices.",
            icon: "flask.fill",
            accentColor: .purple,
            bulletPoints: [
                "View additives from your food diary",
                "See safety ratings for each additive",
                "Track how often you consume each one",
                "Identify foods with the most additives"
            ]
        )
    ]

    private init() {}

    /// Check if a tip has been seen
    func hasSeenTip(_ key: TipKey) -> Bool {
        UserDefaults.standard.bool(forKey: key.rawValue)
    }

    /// Mark a tip as seen
    func markTipAsSeen(_ key: TipKey) {
        UserDefaults.standard.set(true, forKey: key.rawValue)
        objectWillChange.send()
    }

    /// Reset all tips (for testing or settings)
    /// Increments resetTrigger to notify observers to show the first tip
    func resetAllTips() {
        TipKey.allCases.forEach {
            UserDefaults.standard.set(false, forKey: $0.rawValue)
        }
        resetTrigger += 1
        objectWillChange.send()
    }

    /// Mark multiple tips as seen (for migration)
    func markTipsAsSeen(_ keys: [TipKey]) {
        keys.forEach { key in
            UserDefaults.standard.set(true, forKey: key.rawValue)
        }
        objectWillChange.send()
    }

    /// Get the content for a tip
    func getContent(for key: TipKey) -> TipContent? {
        Self.tipContent[key]
    }
}
