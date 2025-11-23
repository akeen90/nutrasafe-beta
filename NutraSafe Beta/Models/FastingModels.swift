import Foundation
import FirebaseFirestore

// MARK: - Enums

enum FastingPlanDuration: Int, CaseIterable, Codable {
    case twelveHours = 12
    case sixteenHours = 16
    case eighteenHours = 18
    case twentyHours = 20
    case twentyFourHours = 24
    case custom = 0

    var displayName: String {
        switch self {
        case .twelveHours: return "12 Hours"
        case .sixteenHours: return "16 Hours"
        case .eighteenHours: return "18 Hours"
        case .twentyHours: return "20 Hours"
        case .twentyFourHours: return "24 Hours"
        case .custom: return "Custom"
        }
    }

    var description: String {
        switch self {
        case .twelveHours: return "Beginner-friendly daily fast"
        case .sixteenHours: return "Popular intermittent fasting (16:8)"
        case .eighteenHours: return "Extended intermittent fasting"
        case .twentyHours: return "Warrior diet (20:4)"
        case .twentyFourHours: return "OMAD (One Meal A Day)"
        case .custom: return "Set your own duration"
        }
    }

    var hours: Int {
        switch self {
        case .twelveHours: return 12
        case .sixteenHours: return 16
        case .eighteenHours: return 18
        case .twentyHours: return 20
        case .twentyFourHours: return 24
        case .custom: return 0
        }
    }
}

enum AllowedDrinksPhilosophy: String, CaseIterable, Codable {
    case strict = "strict"
    case practical = "practical"
    case lenient = "lenient"
    
    var displayName: String {
        switch self {
        case .strict: return "Strict Clean"
        case .practical: return "Practical"
        case .lenient: return "Lenient"
        }
    }
    
    var description: String {
        switch self {
        case .strict: return "Water, plain tea, black coffee, electrolytes only"
        case .practical: return "Sugar-free drinks allowed"
        case .lenient: return "<20–30 kcal tolerance"
        }
    }
    
    var tone: String {
        switch self {
        case .strict: return "scientific"
        case .practical: return "lifestyle"
        case .lenient: return "beginner friendly"
        }
    }
}

enum FastingCompletionStatus: String, CaseIterable, Codable {
    case active = "active"
    case completed = "completed"
    case earlyEnd = "earlyEnd"
    case overGoal = "overGoal"
    case failed = "failed"
    case skipped = "skipped"

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        case .earlyEnd: return "Ended Early"
        case .overGoal: return "Exceeded Target"
        case .failed: return "Not Completed"
        case .skipped: return "Skipped"
        }
    }
    
    var color: String {
        switch self {
        case .active: return "blue"
        case .completed: return "green"
        case .earlyEnd: return "orange"
        case .overGoal: return "purple"
        case .failed: return "red"
        case .skipped: return "gray"
        }
    }
}

enum FastingPhase: String, CaseIterable {
    case postMeal = "postMeal"
    case fuelSwitching = "fuelSwitching"
    case fatMobilization = "fatMobilization"
    case mildKetosis = "mildKetosis"
    case autophagyPotential = "autophagyPotential"
    case deepAdaptive = "deepAdaptive"
    
    var displayName: String {
        switch self {
        case .postMeal: return "Post-meal processing"
        case .fuelSwitching: return "Fuel switching"
        case .fatMobilization: return "Fat mobilisation"
        case .mildKetosis: return "Mild ketosis"
        case .autophagyPotential: return "Autophagy potential"
        case .deepAdaptive: return "Deep adaptive fasting"
        }
    }
    
    var timeRange: ClosedRange<Int> {
        switch self {
        case .postMeal: return 0...4
        case .fuelSwitching: return 4...8
        case .fatMobilization: return 8...12
        case .mildKetosis: return 12...16
        case .autophagyPotential: return 16...20
        case .deepAdaptive: return 20...Int.max
        }
    }
    
    var description: String {
        switch self {
        case .postMeal: return "Body processing recent meal"
        case .fuelSwitching: return "Transitioning to fat burning"
        case .fatMobilization: return "Fat stores being utilised"
        case .mildKetosis: return "Mild ketone production"
        case .autophagyPotential: return "Cellular cleanup may begin"
        case .deepAdaptive: return "Extended fasting benefits"
        }
    }
}

// MARK: - Data Models

struct FastingPlan: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var name: String
    var durationHours: Int
    var daysOfWeek: [String] // ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    var preferredStartTime: Date // Time when fasts should start (e.g., 8:00 PM)
    var allowedDrinks: AllowedDrinksPhilosophy
    var reminderEnabled: Bool
    var reminderMinutesBeforeEnd: Int
    var active: Bool
    var regimeActive: Bool // Whether the regime is currently running
    var regimeStartedAt: Date? // When the regime was activated
    var createdAt: Date

    var isActive: Bool {
        return active
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case durationHours = "duration_hours"
        case daysOfWeek = "days_of_week"
        case preferredStartTime = "preferred_start_time"
        case allowedDrinks = "allowed_drinks"
        case reminderEnabled = "reminder_enabled"
        case reminderMinutesBeforeEnd = "reminder_minutes_before_end"
        case active
        case regimeActive = "regime_active"
        case regimeStartedAt = "regime_started_at"
        case createdAt = "created_at"
    }
    
    var durationDisplay: String {
        if durationHours < 24 {
            return "\(durationHours)h"
        } else {
            let days = durationHours / 24
            let remainingHours = durationHours % 24
            if remainingHours == 0 {
                return "\(days) Day\(days == 1 ? "" : "s")"
            } else {
                return "\(days)d \(remainingHours)h"
            }
        }
    }

    /// Display name that dynamically updates based on current duration
    var displayName: String {
        // Auto-generate name based on duration
        if durationHours == 16 {
            return "16:8 Fasting Plan"
        } else if durationHours == 12 {
            return "12:12 Fasting Plan"
        } else if durationHours == 18 {
            return "18:6 Fasting Plan"
        } else if durationHours == 20 {
            return "20:4 Fasting Plan"
        } else if durationHours == 24 {
            return "OMAD Plan"
        } else {
            return "\(durationHours)-Hour Fast"
        }
    }
    
    var nextScheduledDate: Date? {
        let calendar = Calendar.current
        let today = Date()

        for dayOffset in 0...7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let weekday = calendar.component(.weekday, from: date)
            let weekdaySymbols = calendar.shortWeekdaySymbols
            let dayName = weekdaySymbols[weekday - 1]

            if daysOfWeek.contains(dayName) {
                return date
            }
        }
        return nil
    }

    var startTimeDisplay: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: preferredStartTime)
    }

    var endTimeDisplay: String {
        let endTime = preferredStartTime.addingTimeInterval(TimeInterval(durationHours * 3600))
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: endTime)
    }

    // MARK: - Regime State Calculation

    enum RegimeState {
        case inactive
        case fasting(windowStart: Date, windowEnd: Date)
        case eating(nextFastStart: Date)
    }

    var currentRegimeState: RegimeState {
        guard regimeActive else { return .inactive }

        let calendar = Calendar.current
        let now = Date()

        // Get current weekday
        let currentWeekday = calendar.component(.weekday, from: now)
        let weekdaySymbols = calendar.shortWeekdaySymbols
        let currentDayName = weekdaySymbols[currentWeekday - 1]

        // Check if today is a scheduled fasting day
        if daysOfWeek.contains(currentDayName) {
            // Calculate today's fasting window
            let startHour = calendar.component(.hour, from: preferredStartTime)
            let startMinute = calendar.component(.minute, from: preferredStartTime)

            if let todayWindowStart = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: now),
               let todayWindowEnd = calendar.date(byAdding: .hour, value: durationHours, to: todayWindowStart) {

                // Check if we're currently in the fasting window
                if now >= todayWindowStart && now < todayWindowEnd {
                    return .fasting(windowStart: todayWindowStart, windowEnd: todayWindowEnd)
                } else if now < todayWindowStart {
                    // Before today's window - in eating phase
                    return .eating(nextFastStart: todayWindowStart)
                }
            }
        }

        // Not in a fasting window - find the next scheduled fast
        if let nextFastDate = nextScheduledFastingWindow() {
            return .eating(nextFastStart: nextFastDate)
        }

        return .inactive
    }

    func nextScheduledFastingWindow() -> Date? {
        let calendar = Calendar.current
        let now = Date()

        // Check next 14 days to find the next scheduled fast
        for dayOffset in 0...14 {
            guard let checkDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }

            let weekday = calendar.component(.weekday, from: checkDate)
            let weekdaySymbols = calendar.shortWeekdaySymbols
            let dayName = weekdaySymbols[weekday - 1]

            if daysOfWeek.contains(dayName) {
                let startHour = calendar.component(.hour, from: preferredStartTime)
                let startMinute = calendar.component(.minute, from: preferredStartTime)

                if let windowStart = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: checkDate) {
                    // Only return if it's in the future
                    if windowStart > now {
                        return windowStart
                    }
                }
            }
        }

        return nil
    }
}

struct FastingSession: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var userId: String
    var planId: String? // Nullable for manual sessions
    var startTime: Date
    var endTime: Date? // Nullable while active
    var manuallyEdited: Bool
    var skipped: Bool
    var completionStatus: FastingCompletionStatus
    var targetDurationHours: Int
    var notes: String?
    var createdAt: Date
    var archived: Bool = false

    // Early-end and restart fields
    var attemptType: AttemptType = .normal
    var mergedFromEarlyEnd: Bool = false
    var earlyEndReason: String? = nil
    var lastEarlyEndTime: Date? = nil

    // Snooze and adjustment fields
    var snoozedUntil: Date? = nil
    var snoozeCount: Int = 0
    var originalScheduledStart: Date? = nil // For tracking when fast was originally scheduled
    var adjustedStartTime: Date? = nil // For tracking manual adjustments to start time

    // MARK: - Equatable conformance for SwiftUI's .onChange() modifier
    static func == (lhs: FastingSession, rhs: FastingSession) -> Bool {
        lhs.id == rhs.id
    }

    enum AttemptType: String, Codable {
        case normal = "normal"
        case warmup = "warmup"

        var displayName: String {
            switch self {
            case .normal: return "Normal"
            case .warmup: return "Warm-up attempt"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case planId = "plan_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case manuallyEdited = "manually_edited"
        case skipped
        case completionStatus = "completion_status"
        case targetDurationHours = "target_duration_hours"
        case notes
        case createdAt = "created_at"
        case archived
        case attemptType = "attempt_type"
        case mergedFromEarlyEnd = "merged_from_early_end"
        case earlyEndReason = "early_end_reason"
        case lastEarlyEndTime = "last_early_end_time"
        case snoozedUntil = "snoozed_until"
        case snoozeCount = "snooze_count"
        case originalScheduledStart = "original_scheduled_start"
        case adjustedStartTime = "adjusted_start_time"
    }
    
    var actualDurationHours: Double {
        let end = endTime ?? Date()
        let duration = end.timeIntervalSince(startTime) / 3600 // Convert to hours
        return max(0, duration)
    }
    
    var currentPhase: FastingPhase {
        let hoursElapsed = Int(actualDurationHours)
        
        switch hoursElapsed {
        case 0...4: return .postMeal
        case 4...8: return .fuelSwitching
        case 8...12: return .fatMobilization
        case 12...16: return .mildKetosis
        case 16...20: return .autophagyPotential
        default: return .deepAdaptive
        }
    }
    
    var phasesReached: [FastingPhase] {
        let hoursElapsed = Int(actualDurationHours)
        var phases: [FastingPhase] = []
        
        if hoursElapsed >= 4 { phases.append(.postMeal) }
        if hoursElapsed >= 8 { phases.append(.fuelSwitching) }
        if hoursElapsed >= 12 { phases.append(.fatMobilization) }
        if hoursElapsed >= 16 { phases.append(.mildKetosis) }
        if hoursElapsed >= 20 { phases.append(.autophagyPotential) }
        if hoursElapsed >= 48 { phases.append(.deepAdaptive) }
        
        return phases
    }
    
    var isActive: Bool {
        return endTime == nil && !skipped
    }
    
    var progressPercentage: Double {
        guard targetDurationHours > 0 else { return 0 }
        let progress = min(actualDurationHours / Double(targetDurationHours), 1.0)
        return max(0, progress)
    }
    
    var timeRemaining: TimeInterval {
        guard isActive else { return 0 }
        let targetEndTime = startTime.addingTimeInterval(TimeInterval(targetDurationHours) * 3600)
        return max(0, targetEndTime.timeIntervalSinceNow)
    }
}

// MARK: - Analytics Models

struct FastingAnalytics {
    let totalFastsCompleted: Int
    let averageCompletionPercentage: Double
    let averageDurationVsGoal: Double
    let longestFastHours: Double
    let mostConsistentDay: String?
    let phaseDistribution: [FastingPhase: Int]
    let last7DaysSessions: [FastingSession]
    let last30DaysSessions: [FastingSession]
    let currentWeeklyStreak: Int
    let bestWeeklyStreak: Int

    var completionRate: Double {
        guard totalFastsCompleted > 0 else { return 0 }
        return Double(totalFastsCompleted) / Double(totalFastsCompleted) * 100
    }

    var averageDurationHours: Double {
        return averageDurationVsGoal
    }

    var averageDurationFormatted: String {
        let hours = Int(averageDurationVsGoal)
        let minutes = Int((averageDurationVsGoal - Double(hours)) * 60)
        return "\(hours)h \(minutes)m"
    }

    var longestFastFormatted: String {
        let hours = Int(longestFastHours)
        let days = hours / 24
        let remainingHours = hours % 24

        if days > 0 {
            return "\(days)d \(remainingHours)h"
        } else {
            return "\(hours)h"
        }
    }
}

// MARK: - Notification Models

struct FastingNotification: Codable {
    let id: String
    let type: NotificationType
    let title: String
    let body: String
    let scheduledDate: Date
    let sessionId: String

    enum NotificationType: String, Codable {
        case fastStart = "fast_start"
        case midwayCheckIn = "midway_check_in"
        case phaseTransition = "phase_transition"
        case reminderBeforeEnd = "reminder_before_end"
        case targetReached = "target_reached"
        case exceededTargetEncouragement = "exceeded_target_encouragement"
    }
    
    static let supportiveMessages = [
        "You're doing great — stay steady.",
        "Hydration helps the journey.",
        "Progress compounds.",
        "Consistency > perfection.",
        "Breathe and stay present.",
        "Your body is adapting beautifully.",
        "Every hour counts.",
        "Trust the process."
    ]
}

// MARK: - Widget Models

struct FastingWidgetData {
    let sessionId: String?
    let status: WidgetStatus
    let elapsedTime: String?
    let remainingTime: String?
    let currentPhase: String?
    let nextMilestone: String?
    let motivationalText: String
    let progressPercentage: Double?
    
    enum WidgetStatus {
        case idle
        case active
        case nearEnd
        case overGoal
        case skipped
    }
}