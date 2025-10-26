//
//  FastingModels.swift
//  NutraSafe Beta
//
//  Data models for NutraSafe Fasting History & Streak System™
//

import Foundation
import SwiftUI
import FirebaseFirestore

// MARK: - Fast Record

struct FastRecord: Identifiable, Codable, Equatable {
    let id: String
    let startTime: Date
    let endTime: Date
    let durationMinutes: Int
    /// Stored as YYYY-MM-DD for quick grouping
    let dateString: String
    let withinTarget: Bool
    var notes: String?
    var tags: [String]? // e.g., ["16:8", "18:6", "OMAD"]

    var durationHours: Double { Double(durationMinutes) / 60.0 }
}

// MARK: - Firestore Mapping

extension FastRecord {
    init?(id: String, data: [String: Any]) {
        guard
            let startTS = data["startTime"] as? FirebaseFirestore.Timestamp,
            let endTS = data["endTime"] as? FirebaseFirestore.Timestamp,
            let durationMinutes = data["durationMinutes"] as? Int,
            let dateString = data["dateString"] as? String,
            let withinTarget = data["withinTarget"] as? Bool
        else { return nil }

        self.id = id
        self.startTime = startTS.dateValue()
        self.endTime = endTS.dateValue()
        self.durationMinutes = durationMinutes
        self.dateString = dateString
        self.withinTarget = withinTarget
        self.notes = data["notes"] as? String
        self.tags = data["tags"] as? [String]
    }

    var firestoreData: [String: Any] {
        [
            "startTime": FirebaseFirestore.Timestamp(date: startTime),
            "endTime": FirebaseFirestore.Timestamp(date: endTime),
            "durationMinutes": durationMinutes,
            "dateString": dateString,
            "withinTarget": withinTarget,
            "notes": notes as Any,
            "tags": tags as Any
        ]
    }
}

// MARK: - Streak Settings

struct FastingStreakSettings: Codable, Equatable {
    var daysPerWeekGoal: Int // 1–7
    var targetMinHours: Int // minimum target window
    var targetMaxHours: Int // maximum target window

    static let `default` = FastingStreakSettings(daysPerWeekGoal: 4, targetMinHours: 16, targetMaxHours: 20)
}

extension FastingStreakSettings {
    func isValidDuration(_ hours: Double) -> Bool {
        hours >= Double(targetMinHours) && hours <= Double(targetMaxHours)
    }

    /// Safety validation based on spec
    func safetyValidation(for hours: Double) -> (allowed: Bool, reason: String?) {
        if hours > 48.0 { return (false, ">48 h total not allowed") }
        if daysPerWeekGoal == 7 {
            if hours > 20.0 { return (false, "Max 20 h/day when goal is 7 days/week") }
        } else {
            if hours > 36.0 { return (false, "Max 36 h allowed when goal < 7 days/week") }
        }
        return (true, nil)
    }
}

// MARK: - Streak Snapshots

struct WeeklyStreakSnapshot: Identifiable {
    let id: String // e.g., "2025-W42"
    let weekOfYear: Int
    let year: Int
    let completedDays: Int
    let goalDays: Int
    let metGoal: Bool
}

struct MonthlyStreakSnapshot: Identifiable {
    let id: String // e.g., "2025-10"
    let month: Int
    let year: Int
    let consecutiveWeeklyWins: Int // out of 4
    let metGoal: Bool
}

struct YearlyStreakSnapshot: Identifiable {
    let id: String // e.g., "2025"
    let year: Int
    let consecutiveMonthlyWins: Int // out of 12
    let metGoal: Bool
}

// MARK: - Analytics Summary

struct FastingAnalyticsSummary {
    let averageDurationHours: Double
    let longestFastHours: Double
    let completionRatePercent: Double // % of goal days hit over observed period
    let currentWeeklyStreak: Int
    let currentMonthlyStreak: Int
    let currentYearlyStreak: Int
    let bestWeeklyStreak: Int
    let bestMonthlyStreak: Int
    let bestYearlyStreak: Int
}