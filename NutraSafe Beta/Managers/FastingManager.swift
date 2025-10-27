//
//  FastingManager.swift
//  NutraSafe Beta
//
//  Logic for NutraSafe Fasting History & Streak System™
//

import Foundation

struct FastingManager {
    struct ValidationError: Error {
        let reason: String
    }

    static func buildRecord(startTime: Date,
                            endTime: Date,
                            settings: FastingStreakSettings,
                            goalHours: Int,
                            notes: String? = nil,
                            tags: [String]? = nil) -> Result<FastRecord, ValidationError> {
        let durationMinutes = Int(endTime.timeIntervalSince(startTime) / 60)
        let hours = Double(durationMinutes) / 60.0

        let safety = settings.safetyValidation(for: hours)
        if !safety.allowed {
            return .failure(ValidationError(reason: safety.reason ?? "Fast exceeds safety limits"))
        }

        let withinTarget = settings.isValidDuration(hours)
        let dateString = Self.formatDateString(from: startTime)
        let record = FastRecord(
            id: UUID().uuidString,
            startTime: startTime,
            endTime: endTime,
            durationMinutes: max(durationMinutes, 0),
            dateString: dateString,
            withinTarget: withinTarget,
            notes: notes,
            tags: tags
        )
        return .success(record)
    }

    private static func formatDateString(from date: Date) -> String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 0
        let m = comps.month ?? 0
        let d = comps.day ?? 0
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    // MARK: - Analytics & Streaks

    static func analytics(from history: [FastRecord], settings: FastingStreakSettings) -> FastingAnalyticsSummary {
        guard !history.isEmpty else {
            return FastingAnalyticsSummary(
                averageDurationHours: 0,
                longestFastHours: 0,
                completionRatePercent: 0,
                currentWeeklyStreak: 0,
                currentMonthlyStreak: 0,
                currentYearlyStreak: 0,
                bestWeeklyStreak: 0,
                bestMonthlyStreak: 0,
                bestYearlyStreak: 0
            )
        }

        let durations = history.map { $0.durationHours }
        let avg = durations.reduce(0, +) / Double(durations.count)
        let longest = durations.max() ?? 0
        let completedDays = Set(history.filter { $0.withinTarget }.map { $0.dateString })
        let allDays = Set(history.map { $0.dateString })
        let completionRate = allDays.isEmpty ? 0 : (Double(completedDays.count) / Double(allDays.count)) * 100.0

        // Weekly grouping
        let weekly = groupByWeek(history: history)
        let weeklyWins = weekly.map { $0.completedDays >= settings.daysPerWeekGoal }
        let currentWeekly = consecutiveFromEnd(weeklyWins)
        let bestWeekly = bestConsecutive(weeklyWins)

        // Monthly grouping: a month is a win if it contains >=4 weekly wins
        let monthlyWins = groupMonthlyWins(weeklyGroups: weekly, wins: weeklyWins)
        let currentMonthly = consecutiveFromEnd(monthlyWins)
        let bestMonthly = bestConsecutive(monthlyWins)

        // Yearly grouping: a year is a win if it contains >=10 monthly wins
        let yearlyWins = groupYearlyWins(monthlyWins: monthlyWins, weeklyGroups: weekly)
        let currentYearly = consecutiveFromEnd(yearlyWins)
        let bestYearly = bestConsecutive(yearlyWins)

        return FastingAnalyticsSummary(
            averageDurationHours: avg,
            longestFastHours: longest,
            completionRatePercent: completionRate,
            currentWeeklyStreak: currentWeekly,
            currentMonthlyStreak: currentMonthly,
            currentYearlyStreak: currentYearly,
            bestWeeklyStreak: bestWeekly,
            bestMonthlyStreak: bestMonthly,
            bestYearlyStreak: bestYearly
        )
    }

    private struct WeekGroup {
        let id: String // e.g., "2025-W42"
        let weekOfYear: Int
        let year: Int
        let completedDays: Int
        let goalDays: Int
        let metGoal: Bool
    }

    private static func groupByWeek(history: [FastRecord]) -> [WeekGroup] {
        let cal = Calendar.current
        // Unique days per week
        var perWeek: [String: Set<String>] = [:] // key: "yyyy-Www", value: set of dateString that are withinTarget
        var allDaysPerWeek: [String: Set<String>] = [:]
        var weekMeta: [String: (week: Int, year: Int)] = [:]

        for r in history {
            let comps = cal.dateComponents([.weekOfYear, .yearForWeekOfYear], from: r.startTime)
            let w = comps.weekOfYear ?? cal.component(.weekOfYear, from: r.startTime)
            let y = comps.yearForWeekOfYear ?? cal.component(.yearForWeekOfYear, from: r.startTime)
            let key = String(format: "%04d-W%02d", y, w)
            weekMeta[key] = (w, y)
            allDaysPerWeek[key, default: []].insert(r.dateString)
            if r.withinTarget {
                perWeek[key, default: []].insert(r.dateString)
            }
        }

        var groups: [WeekGroup] = []
        for (key, _) in allDaysPerWeek {
            let completed = perWeek[key]?.count ?? 0
            let meta = weekMeta[key] ?? (0, 0)
            let metGoal = completed >= 1 // baseline; actual goal applied below via goalDays
            groups.append(WeekGroup(id: key,
                                    weekOfYear: meta.week,
                                    year: meta.year,
                                    completedDays: completed,
                                    goalDays: 0,
                                    metGoal: metGoal))
        }
        // Sort by year/week ascending
        groups.sort { ($0.year, $0.weekOfYear) < ($1.year, $1.weekOfYear) }
        return groups
    }

    private static func groupMonthlyWins(weeklyGroups: [WeekGroup], wins: [Bool]) -> [Bool] {
        guard weeklyGroups.count == wins.count else { return [] }
        // Count weekly wins per (year, month) based on week start date approximations
        // We’ll approximate month by using the Thursday of the ISO week, which falls within the week’s month more consistently
        let cal = Calendar.current
        var monthlyCounts: [String: Int] = [:]
        for (idx, g) in weeklyGroups.enumerated() {
            let week = g.weekOfYear
            let year = g.year
            // Get a date for Thursday of ISO week
            var comps = DateComponents()
            comps.weekOfYear = week
            comps.yearForWeekOfYear = year
            comps.weekday = 5 // Thursday
            if let date = cal.date(from: comps) {
                let m = cal.component(.month, from: date)
                let key = String(format: "%04d-%02d", year, m)
                if wins[idx] { monthlyCounts[key, default: 0] += 1 }
            }
        }
        // Build monthly wins in chronological order
        let sortedKeys = monthlyCounts.keys.sorted()
        return sortedKeys.map { monthlyCounts[$0, default: 0] >= 4 }
    }

    private static func groupYearlyWins(monthlyWins: [Bool], weeklyGroups: [WeekGroup]) -> [Bool] {
        // Approximate year list order from weekly groups
        let years = Array(Set(weeklyGroups.map { $0.year })).sorted()
        // Split monthly wins across years roughly evenly (best-effort without month keys)
        if years.isEmpty { return [] }
        // Fallback: treat total monthly wins sequence as chronological and divide into chunks by year count
        let chunkSize = max(1, monthlyWins.count / max(1, years.count))
        var result: [Bool] = []
        var idx = 0
        for _ in years {
            let end = min(idx + chunkSize, monthlyWins.count)
            let slice = monthlyWins[idx..<end]
            result.append(slice.filter { $0 }.count >= 10)
            idx = end
        }
        return result
    }

    private static func consecutiveFromEnd(_ wins: [Bool]) -> Int {
        var count = 0
        for w in wins.reversed() {
            if w { count += 1 } else { break }
        }
        return count
    }

    private static func bestConsecutive(_ wins: [Bool]) -> Int {
        var best = 0
        var current = 0
        for w in wins {
            if w { current += 1; best = max(best, current) } else { current = 0 }
        }
        return best
    }
}