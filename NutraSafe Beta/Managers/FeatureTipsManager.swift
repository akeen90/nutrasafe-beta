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

    /// Content for each tip - with clear navigation guidance
    static let tipContent: [TipKey: TipContent] = [
        .diaryOverview: TipContent(
            title: "Welcome to Your Food Diary",
            message: "This is your home base for tracking what you eat. The + button in the middle of the tab bar is your quickest way to add food.",
            icon: "fork.knife.circle.fill",
            accentColor: .blue,
            bulletPoints: [
                "Tap + to search or scan barcodes",
                "See daily calories, macros & nutrients here",
                "Tap any food to edit, copy, or delete",
                "Tap 'Health' tab for reactions & fasting"
            ]
        ),
        .diarySearch: TipContent(
            title: "Add Food",
            message: "Search our database or scan barcodes to add food to your diary.",
            icon: "magnifyingglass",
            accentColor: .blue
        ),
        .healthOverview: TipContent(
            title: "Health: Reactions & Fasting",
            message: "This tab has two sections. Use the toggle at the top to switch between them.",
            icon: "heart.circle.fill",
            accentColor: .pink,
            bulletPoints: [
                "Reactions tab: Log food reactions & symptoms",
                "Fasting tab: Track intermittent fasting",
                "Tap + then 'Log Reaction' to add a reaction",
                "We'll analyze patterns after 3+ reactions"
            ]
        ),
        .healthReactions: TipContent(
            title: "Track Food Reactions",
            message: "When food doesn't agree with you, log it here. We save the ingredients to find patterns.",
            icon: "exclamationmark.bubble.fill",
            accentColor: .orange,
            bulletPoints: [
                "Tap + then 'Log Reaction' to add one",
                "Select the food and symptoms you felt",
                "Ingredients are saved automatically",
                "After 3+ reactions, we'll show patterns"
            ]
        ),
        .healthPatterns: TipContent(
            title: "Pattern Analysis",
            message: "After logging 3 or more reactions, we analyze which ingredients appear most frequently.",
            icon: "chart.bar.doc.horizontal.fill",
            accentColor: .purple,
            bulletPoints: [
                "See ingredients that appear in multiple reactions",
                "Identify potential trigger foods",
                "Track reaction frequency over time"
            ]
        ),
        .healthFasting: TipContent(
            title: "Intermittent Fasting",
            message: "Tap 'Fasting' at the top of the Health tab to access fasting features.",
            icon: "timer",
            accentColor: .green,
            bulletPoints: [
                "Choose from 16:8, 18:6, 20:4, and more",
                "Live timer shows your current stage",
                "Get notifications at key milestones",
                "Track your fasting history and streaks"
            ]
        ),
        .progressOverview: TipContent(
            title: "Track Your Progress",
            message: "Log your weight to see trends over time. Tap + then 'Weigh In' to record today's weight.",
            icon: "figure.run.circle.fill",
            accentColor: .teal,
            bulletPoints: [
                "Tap + then 'Weigh In' to log weight",
                "See your progress on a visual chart",
                "Syncs with Apple Health if connected",
                "Set a goal weight to track progress"
            ]
        ),
        .progressWeight: TipContent(
            title: "Weight Tracking",
            message: "Tap + then 'Weigh In' to log your weight. See trends over time to stay motivated.",
            icon: "scalemass.fill",
            accentColor: .teal
        ),
        .useByOverview: TipContent(
            title: "Track Expiry Dates",
            message: "Never waste opened food again. Tap + then 'Use By' to add items you've opened.",
            icon: "calendar.circle.fill",
            accentColor: .orange,
            bulletPoints: [
                "Tap + then 'Use By' to add opened items",
                "Get notifications before food expires",
                "Items sorted by expiry date",
                "Reduce food waste and save money"
            ]
        ),
        .nutrientsOverview: TipContent(
            title: "Micronutrient Dashboard",
            message: "See your vitamin and mineral intake over the past 7 days based on what you've logged.",
            icon: "leaf.circle.fill",
            accentColor: .green,
            bulletPoints: [
                "Track vitamins A, C, D, E, K, B-complex",
                "Monitor minerals like iron, calcium, zinc",
                "See which nutrients need attention",
                "Log more foods to improve accuracy"
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
    func resetAllTips() {
        TipKey.allCases.forEach {
            UserDefaults.standard.set(false, forKey: $0.rawValue)
        }
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
