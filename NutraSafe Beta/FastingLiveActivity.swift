//
//  FastingLiveActivity.swift
//  NutraSafe Beta
//
//  Shared ActivityAttributes for Live Activity
//  The Widget UI is in the NutraSafeWidgets extension
//

import ActivityKit
import SwiftUI

// MARK: - Live Activity Attributes (Shared with Widget Extension)
@available(iOS 16.1, *)
struct FastingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var fastingStartTime: Date
        var currentHours: Int
        var currentMinutes: Int
        var remainingHours: Int
        var remainingMinutes: Int
        var currentPhase: String
        var phaseEmoji: String
    }

    var fastingGoalHours: Int
}

// MARK: - Fasting Phase Helper
@available(iOS 16.1, *)
struct FastingPhaseInfo {
    let name: String
    let emoji: String

    static func forHours(_ hours: Int) -> FastingPhaseInfo {
        switch hours {
        case 0..<4:
            return FastingPhaseInfo(name: "Post-meal processing", emoji: "🍽️")
        case 4..<8:
            return FastingPhaseInfo(name: "Fuel switching", emoji: "🔄")
        case 8..<12:
            return FastingPhaseInfo(name: "Fat mobilisation", emoji: "💪")
        case 12..<16:
            return FastingPhaseInfo(name: "Mild ketosis", emoji: "🔥")
        case 16..<20:
            return FastingPhaseInfo(name: "Autophagy potential", emoji: "✨")
        default:
            return FastingPhaseInfo(name: "Deep adaptive fasting", emoji: "🧘")
        }
    }
}
