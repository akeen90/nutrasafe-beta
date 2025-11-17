//
//  FastingManager.swift
//  NutraSafe Beta
//
//  Updated for new session-based fasting system
//

import Foundation
import FirebaseFirestore

class FastingManager {
    struct ValidationError: Error {
        let reason: String
    }
    
    // MARK: - Session Management
    
    static func createSession(
        userId: String,
        plan: FastingPlan? = nil,
        targetDurationHours: Int,
        startTime: Date = Date()
    ) -> FastingSession {
        return FastingSession(
            userId: userId,
            planId: plan?.id,
            startTime: startTime,
            endTime: nil,
            manuallyEdited: false,
            skipped: false,
            completionStatus: .active,
            targetDurationHours: targetDurationHours,
            notes: nil,
            createdAt: Date()
        )
    }
    
    static func endSession(
        _ session: FastingSession,
        endTime: Date = Date()
    ) -> FastingSession {
        var updatedSession = session
        updatedSession.endTime = endTime

        let actualDuration = endTime.timeIntervalSince(session.startTime) / 3600
        let targetDuration = Double(session.targetDurationHours)
        let completionPercentage = actualDuration / targetDuration

        // Automatically determine completion status based on actual vs target duration
        if actualDuration >= targetDuration * 1.1 {
            // Exceeded target by 10% or more
            updatedSession.completionStatus = .overGoal
        } else if actualDuration >= targetDuration {
            // Met or slightly exceeded target (within 10%)
            updatedSession.completionStatus = .completed
        } else if completionPercentage < 0.25 {
            // Less than 25% of target - very early end (warm-up attempt)
            updatedSession.completionStatus = .earlyEnd
            updatedSession.attemptType = .warmup
            updatedSession.lastEarlyEndTime = endTime
        } else if actualDuration < 1 {
            // Less than 1 hour - considered failed
            updatedSession.completionStatus = .failed
        } else {
            // Between 25% and target - ended early but significant progress
            updatedSession.completionStatus = .earlyEnd
        }

        return updatedSession
    }
    
    static func skipSession(_ session: FastingSession) -> FastingSession {
        var updatedSession = session
        updatedSession.skipped = true
        updatedSession.completionStatus = .skipped
        updatedSession.endTime = Date()
        return updatedSession
    }
    
    // MARK: - Plan Validation
    
    static func validatePlan(
        name: String,
        durationHours: Int,
        daysOfWeek: [String]
    ) -> Result<Void, ValidationError> {
        // Plan name is now optional - will be auto-generated if empty

        guard durationHours >= 12 && durationHours <= 168 else {
            return .failure(ValidationError(reason: "Fast duration must be between 12 and 168 hours"))
        }
        
        guard !daysOfWeek.isEmpty else {
            return .failure(ValidationError(reason: "At least one day of week must be selected"))
        }
        
        let validDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let invalidDays = daysOfWeek.filter { !validDays.contains($0) }
        guard invalidDays.isEmpty else {
            return .failure(ValidationError(reason: "Invalid days of week: \(invalidDays.joined(separator: ", "))"))
        }
        
        return .success(())
    }
    
    // MARK: - Analytics
    
    static func calculateAnalytics(from sessions: [FastingSession]) -> FastingAnalytics {
        let completedSessions = sessions.filter { $0.completionStatus == .completed }
        let totalSessions = sessions.count
        let completedCount = completedSessions.count

        let completionRate = totalSessions > 0 ? Double(completedCount) / Double(totalSessions) * 100 : 0

        let averageDuration = completedSessions.isEmpty ? 0 : completedSessions.map { $0.actualDurationHours }.reduce(0, +) / Double(completedSessions.count)

        let longestFast = sessions.map { $0.actualDurationHours }.max() ?? 0

        let currentStreak = calculateCurrentStreak(from: sessions)
        let longestStreak = calculateLongestStreak(from: sessions)

        // Weekly and monthly completion rates
        _ = calculateWeeklyCompletionRate(from: sessions)
        _ = calculateMonthlyCompletionRate(from: sessions)

        return FastingAnalytics(
            totalFastsCompleted: completedCount,
            averageCompletionPercentage: completionRate,
            averageDurationVsGoal: averageDuration,
            longestFastHours: longestFast,
            mostConsistentDay: calculateMostConsistentDay(from: sessions),
            phaseDistribution: calculatePhaseDistribution(from: sessions),
            last7DaysSessions: sessions.filter { $0.startTime >= Calendar.current.date(byAdding: .day, value: -7, to: Date())! },
            last30DaysSessions: sessions.filter { $0.startTime >= Calendar.current.date(byAdding: .day, value: -30, to: Date())! },
            currentWeeklyStreak: currentStreak,
            bestWeeklyStreak: longestStreak
        )
    }
    
    // MARK: - Streak Calculations
    
    private static func calculateCurrentStreak(from sessions: [FastingSession]) -> Int {
        let completedSessions = sessions
            .filter { $0.completionStatus == .completed }
            .sorted { $0.startTime > $1.startTime }
        
        guard let latest = completedSessions.first else { return 0 }
        
        var streak = 1
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: latest.startTime)
        
        for session in completedSessions.dropFirst() {
            let sessionDate = calendar.startOfDay(for: session.startTime)
            let daysBetween = calendar.dateComponents([.day], from: sessionDate, to: currentDate).day ?? 0
            
            if daysBetween <= 1 {
                streak += 1
                currentDate = sessionDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    private static func calculateLongestStreak(from sessions: [FastingSession]) -> Int {
        let completedSessions = sessions
            .filter { $0.completionStatus == .completed }
            .sorted { $0.startTime < $1.startTime }
        
        guard !completedSessions.isEmpty else { return 0 }
        
        var longestStreak = 1
        var currentStreak = 1
        let calendar = Calendar.current
        
        for i in 1..<completedSessions.count {
            let previousDate = calendar.startOfDay(for: completedSessions[i-1].startTime)
            let currentDate = calendar.startOfDay(for: completedSessions[i].startTime)
            let daysBetween = calendar.dateComponents([.day], from: previousDate, to: currentDate).day ?? 0
            
            if daysBetween <= 1 {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }
        
        return longestStreak
    }
    
    // MARK: - Weekly/Monthly Completion Rates
    
    private static func calculateWeeklyCompletionRate(from sessions: [FastingSession]) -> Double {
        let calendar = Calendar.current
        let groupedByWeek = Dictionary(grouping: sessions) { session -> String in
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: session.startTime)
            return "\(components.yearForWeekOfYear ?? 0)-W\(components.weekOfYear ?? 0)"
        }
        
        let weeklyRates = groupedByWeek.values.map { weekSessions -> Double in
            let completed = weekSessions.filter { $0.completionStatus == .completed }.count
            return weekSessions.isEmpty ? 0 : Double(completed) / Double(weekSessions.count) * 100
        }
        
        return weeklyRates.isEmpty ? 0 : weeklyRates.reduce(0, +) / Double(weeklyRates.count)
    }
    
    private static func calculateMonthlyCompletionRate(from sessions: [FastingSession]) -> Double {
        let calendar = Calendar.current
        let groupedByMonth = Dictionary(grouping: sessions) { session -> String in
            let components = calendar.dateComponents([.year, .month], from: session.startTime)
            return "\(components.year ?? 0)-\(components.month ?? 0)"
        }
        
        let monthlyRates = groupedByMonth.values.map { monthSessions -> Double in
            let completed = monthSessions.filter { $0.completionStatus == .completed }.count
            return monthSessions.isEmpty ? 0 : Double(completed) / Double(monthSessions.count) * 100
        }
        
        return monthlyRates.isEmpty ? 0 : monthlyRates.reduce(0, +) / Double(monthlyRates.count)
    }
    
    private static func calculateMostConsistentDay(from sessions: [FastingSession]) -> String? {
        guard !sessions.isEmpty else { return nil }
        
        let weekdayCounts = Dictionary(grouping: sessions) { session in
            Calendar.current.component(.weekday, from: session.startTime)
        }.mapValues { $0.count }
        
        guard let mostConsistentWeekday = weekdayCounts.max(by: { $0.value < $1.value })?.key else {
            return nil
        }
        
        let weekdaySymbols = Calendar.current.weekdaySymbols
        return weekdaySymbols[mostConsistentWeekday - 1] // Adjust for 0-based index
    }
    
    private static func calculatePhaseDistribution(from sessions: [FastingSession]) -> [FastingPhase: Int] {
        var distribution: [FastingPhase: Int] = [:]
        
        for session in sessions {
            let phase = determinePhase(for: session.actualDurationHours)
            distribution[phase, default: 0] += 1
        }
        
        return distribution
    }
    
    private static func determinePhase(for durationHours: Double) -> FastingPhase {
        switch durationHours {
        case 0..<4:
            return .postMeal
        case 4..<8:
            return .fuelSwitching
        case 8..<12:
            return .fatMobilization
        case 12..<16:
            return .mildKetosis
        case 16..<20:
            return .autophagyPotential
        default:
            return .deepAdaptive
        }
    }
    
    // MARK: - Plan Suggestions
    
    static func suggestPlanAdjustment(from sessions: [FastingSession], currentPlan: FastingPlan) -> String? {
        let analytics = calculateAnalytics(from: sessions)
        
        // If completion rate is low, suggest shorter fasts
        if analytics.completionRate < 50 {
            let suggestedDuration = max(12, currentPlan.durationHours - 6)
            return "Consider trying shorter \(suggestedDuration)-hour fasts to build consistency"
        }
        
        // If completion rate is high and average duration is close to target, suggest longer fasts
        if analytics.completionRate > 80 && analytics.averageDurationVsGoal < Double(currentPlan.durationHours) * 0.9 {
            let suggestedDuration = min(168, currentPlan.durationHours + 6)
            return "You're ready for longer \(suggestedDuration)-hour fasts!"
        }
        
        // If user is consistently going over target, they might be ready for longer fasts
        let overGoalSessions = sessions.filter { $0.completionStatus == .overGoal }
        if Double(overGoalSessions.count) / Double(sessions.count) > 0.3 {
            let suggestedDuration = min(168, currentPlan.durationHours + 12)
            return "You're consistently exceeding your target. Try \(suggestedDuration)-hour fasts!"
        }
        
        return nil
    }
    
    // MARK: - Helper Extensions
    
    static func formatDuration(_ hours: Double) -> String {
        if hours < 24 {
            return String(format: "%.1fh", hours)
        } else {
            let days = hours / 24
            return String(format: "%.1f days", days)
        }
    }
    
    static func formatStreak(_ days: Int) -> String {
        if days == 0 {
            return "No streak yet"
        } else if days == 1 {
            return "1 day"
        } else {
            return "\(days) days"
        }
    }
}