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
            message: "Track everything you eat here. The + button at the bottom is your quickest way to add food — search, scan a barcode, or enter it manually.",
            icon: "fork.knife.circle.fill",
            accentColor: .blue,
            bulletPoints: [
                "Tap + to search foods or scan product barcodes",
                "See your daily calories and macros (protein, carbs, fat)",
                "Tap any food to view details, edit portions, or delete",
                "Swipe to quickly navigate between days"
            ]
        ),
        .diarySearch: TipContent(
            title: "Add Food",
            message: "Search our database of thousands of UK foods, or scan a product barcode for instant results.",
            icon: "magnifyingglass",
            accentColor: .blue
        ),
        .healthOverview: TipContent(
            title: "Health: Reactions & Fasting",
            message: "This section has two parts — use the toggle at the top to switch between tracking food reactions and intermittent fasting.",
            icon: "heart.circle.fill",
            accentColor: .pink,
            bulletPoints: [
                "Reactions: Log when food doesn't agree with you",
                "Fasting: Track eating windows like 16:8",
                "We'll spot patterns in foods that upset you",
                "Perfect for identifying food intolerances"
            ]
        ),
        .healthReactions: TipContent(
            title: "Track Food Reactions",
            message: "If certain foods don't agree with you (bloating, tiredness, etc.), log them here. We'll save the ingredients and look for patterns.",
            icon: "exclamationmark.bubble.fill",
            accentColor: .orange,
            bulletPoints: [
                "Tap + then 'Log Reaction' after eating",
                "Choose the food and your symptoms",
                "Ingredients are saved automatically",
                "After 3+ reactions, we'll show what's common"
            ]
        ),
        .healthPatterns: TipContent(
            title: "Pattern Analysis",
            message: "Once you've logged 3 or more reactions, we analyse which ingredients keep appearing. This can help identify potential trigger foods.",
            icon: "chart.bar.doc.horizontal.fill",
            accentColor: .purple,
            bulletPoints: [
                "See ingredients that appear in multiple reactions",
                "Identify potential foods to avoid",
                "Track reaction frequency over time"
            ]
        ),
        .healthFasting: TipContent(
            title: "Intermittent Fasting",
            message: "Intermittent fasting means taking regular breaks from eating. The 16:8 plan (fast 16 hours, eat in an 8-hour window) is a popular choice.",
            icon: "timer",
            accentColor: .green,
            bulletPoints: [
                "Choose from 16:8, 18:6, 20:4, and more",
                "Live timer tracks your fasting stages",
                "Most of your fasting happens whilst sleeping",
                "Build streaks and track your history"
            ]
        ),
        .progressOverview: TipContent(
            title: "Track Your Weight",
            message: "Log your weight regularly to see trends over time. Tap + then 'Weigh In' to record today's weight.",
            icon: "figure.run.circle.fill",
            accentColor: .teal,
            bulletPoints: [
                "Tap + then 'Weigh In' to log your weight",
                "See your progress on a visual chart",
                "Syncs with Apple Health if enabled",
                "Set a goal weight to stay motivated"
            ]
        ),
        .progressWeight: TipContent(
            title: "Weight Tracking",
            message: "Tap + then 'Weigh In' to record your weight. Regular tracking helps you see trends and stay motivated.",
            icon: "scalemass.fill",
            accentColor: .teal
        ),
        .useByOverview: TipContent(
            title: "Track Use-By Dates",
            message: "Never waste opened food again. Add items you've opened and we'll remind you before they go off.",
            icon: "calendar.circle.fill",
            accentColor: .orange,
            bulletPoints: [
                "Tap + then 'Use By' to add opened items",
                "Get notifications before food expires",
                "Items sorted by how soon they expire",
                "Reduce food waste and save money"
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
