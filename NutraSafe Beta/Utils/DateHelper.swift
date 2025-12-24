//
//  DateHelper.swift
//  NutraSafe Beta
//
//  Centralized date/time handling with consistent timezone usage
//  This utility ensures all date operations use the correct timezone context
//

import Foundation

/// Centralized date utilities with timezone-safe operations
///
/// KEY PRINCIPLES:
/// 1. Local dates (user's timezone) - for UI display, diary grouping, use-by dates
/// 2. UTC dates - for server communication, timestamp storage
/// 3. Always use Calendar.current for local date operations
/// 4. Always document which timezone context each date uses
enum DateHelper {

    // MARK: - Static Cached DateFormatters (PERFORMANCE OPTIMIZATION)
    // DateFormatter creation is expensive (~10ms per instance)
    // These static formatters are created once and reused throughout the app

    /// Short time format (e.g., "2:30 PM")
    static let shortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    /// Short date format (e.g., "12/25/24")
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    /// Medium date format (e.g., "Dec 25, 2024")
    static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Medium date and short time (e.g., "Dec 25, 2024 at 2:30 PM")
    static let mediumDateShortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    /// Day of week format (e.g., "Mon", "Tue")
    static let dayOfWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    /// Full day of week format (e.g., "Monday", "Tuesday")
    static let fullDayOfWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    /// ISO date format for keys (e.g., "2024-12-25")
    static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Friendly date format (e.g., "Monday, Jan 15")
    static let friendlyDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }()

    /// Month and day format (e.g., "Jan 15")
    static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    /// Full date format (e.g., "Monday, January 15, 2024")
    static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter
    }()

    /// Time only format (e.g., "2:30 PM")
    static let timeOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    /// 24-hour time format (e.g., "14:30")
    static let time24HourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    /// Month day year format (e.g., "Jan 15, 2024")
    static let monthDayYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()

    /// Month year format (e.g., "January 2024")
    static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    /// Day number format (e.g., "15")
    static let dayNumberFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()

    /// Week key format for caching (e.g., "2024-W52")
    static let weekKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-'W'ww"
        formatter.timeZone = Calendar.current.timeZone
        return formatter
    }()

    /// Short date UK format (e.g., "25/12/24")
    static let shortDateUKFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter
    }()

    /// Full month year format (e.g., "December 2024")
    static let fullMonthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }()

    /// Single letter day format (e.g., "M", "T", "W")
    static let singleLetterDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()

    /// Day comma month day format (e.g., "Mon, Jan 15")
    static let dayCommaMonthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter
    }()

    /// Day date month format (e.g., "Mon 15 Jan")
    static let dayDateMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E d MMM"
        return formatter
    }()

    /// Short month format (e.g., "Jan", "Feb")
    static let shortMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()

    /// Long date short time format (e.g., "January 15, 2024 at 2:30 PM")
    static let longDateShortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()

    /// Relative date formatter (e.g., "Today", "Yesterday", "Dec 25")
    static let relativeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    /// Day month short format (e.g., "15 Jan")
    static let dayMonthShortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    /// Day month long format (e.g., "15 January")
    static let dayMonthLongFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        return formatter
    }()

    /// Compact day/month format (e.g., "15/1")
    static let compactDayMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d/M"
        return formatter
    }()

    // MARK: - Shared Calendar (User's Local Timezone)

    /// Shared calendar instance using user's current timezone
    /// Use this for all local date operations (diary, notifications, UI)
    static var calendar: Calendar {
        Calendar.current
    }

    // MARK: - Date Comparison (Local Timezone)

    /// Check if two dates are on the same day in the user's local timezone
    /// - Parameters:
    ///   - date1: First date to compare
    ///   - date2: Second date to compare
    /// - Returns: True if dates are on same calendar day in local timezone
    static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }

    /// Check if a date is today in the user's local timezone
    /// - Parameter date: Date to check
    /// - Returns: True if date is today in local timezone
    static func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    /// Check if a date is yesterday in the user's local timezone
    /// - Parameter date: Date to check
    /// - Returns: True if date is yesterday in local timezone
    static func isYesterday(_ date: Date) -> Bool {
        calendar.isDateInYesterday(date)
    }

    /// Check if a date is tomorrow in the user's local timezone
    /// - Parameter date: Date to check
    /// - Returns: True if date is tomorrow in local timezone
    static func isTomorrow(_ date: Date) -> Bool {
        calendar.isDateInTomorrow(date)
    }

    // MARK: - Start/End of Day (Local Timezone)

    /// Get the start of day (midnight) for a date in local timezone
    /// - Parameter date: Input date
    /// - Returns: Date at 00:00:00 in local timezone
    static func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    /// Get the end of day (23:59:59.999) for a date in local timezone
    /// - Parameter date: Input date
    /// - Returns: Date at 23:59:59.999 in local timezone
    static func endOfDay(for date: Date) -> Date {
        guard let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay(for: date)) else {
            // Fallback: if calendar math fails, return 23:59:59 by adding seconds
            return startOfDay(for: date).addingTimeInterval(86399.999)
        }
        return startOfNextDay.addingTimeInterval(-0.001) // 1 millisecond before next day
    }

    // MARK: - Date Arithmetic (Local Timezone)

    /// Add days to a date in local timezone
    /// - Parameters:
    ///   - days: Number of days to add (can be negative)
    ///   - date: Starting date
    /// - Returns: New date with days added, nil if calculation fails
    static func addDays(_ days: Int, to date: Date) -> Date? {
        calendar.date(byAdding: .day, value: days, to: date)
    }

    /// Calculate number of days between two dates in local timezone
    /// - Parameters:
    ///   - from: Start date
    ///   - to: End date
    /// - Returns: Number of days between dates (can be negative if 'to' is before 'from')
    static func daysBetween(from: Date, to: Date) -> Int {
        let fromDay = startOfDay(for: from)
        let toDay = startOfDay(for: to)
        let components = calendar.dateComponents([.day], from: fromDay, to: toDay)
        return components.day ?? 0
    }

    // MARK: - Date Formatting (Local Timezone)

    /// Create a DateFormatter for local timezone operations
    /// - Parameter format: Date format string (e.g., "yyyy-MM-dd")
    /// - Returns: Configured DateFormatter using local timezone
    static func localDateFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.timeZone = calendar.timeZone // Use calendar's timezone (user's local)
        formatter.locale = Locale.current
        return formatter
    }

    /// Create a DateFormatter for UTC operations
    /// - Parameter format: Date format string
    /// - Returns: Configured DateFormatter using UTC timezone
    static func utcDateFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        // UTC timezone should always be available, but provide fallback for safety
        formatter.timeZone = TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX") // Stable locale for UTC
        return formatter
    }

    /// Format a date as "yyyy-MM-dd" in local timezone
    /// Use this for diary keys, display dates, etc.
    /// - Parameter date: Date to format
    /// - Returns: Formatted date string in local timezone
    static func localDateKey(for date: Date) -> String {
        let formatter = localDateFormatter(format: "yyyy-MM-dd")
        return formatter.string(from: date)
    }

    /// Format a date as "yyyy-MM-dd" in UTC timezone
    /// Use this for server communication where UTC is required
    /// - Parameter date: Date to format
    /// - Returns: Formatted date string in UTC timezone
    static func utcDateKey(for date: Date) -> String {
        let formatter = utcDateFormatter(format: "yyyy-MM-dd")
        return formatter.string(from: date)
    }

    // MARK: - Firebase Date Handling

    /// Get start and end of day for Firebase queries (using local timezone)
    /// Firebase stores timestamps in UTC, but we query by local day boundaries
    /// - Parameter date: The local date
    /// - Returns: Tuple of (startOfDay, endOfDay) for Firebase queries
    static func firebaseDayBoundaries(for date: Date) -> (start: Date, end: Date) {
        let start = startOfDay(for: date)
        let end = endOfDay(for: date)
        return (start, end)
    }

    // MARK: - Notification Scheduling (Local Timezone)

    /// Create date components for notification scheduling at a specific time
    /// - Parameters:
    ///   - date: Target date
    ///   - hour: Hour (0-23)
    ///   - minute: Minute (0-59)
    /// - Returns: DateComponents configured for local timezone
    static func notificationDateComponents(for date: Date, hour: Int, minute: Int) -> DateComponents {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        components.second = 0
        components.timeZone = calendar.timeZone // Explicit local timezone
        return components
    }

    /// Calculate time interval from now to a future date at specific time
    /// - Parameters:
    ///   - date: Target date
    ///   - hour: Hour (0-23)
    ///   - minute: Minute (0-59)
    /// - Returns: Time interval in seconds, nil if in past or invalid
    static func timeIntervalUntil(date: Date, hour: Int, minute: Int) -> TimeInterval? {
        let components = notificationDateComponents(for: date, hour: hour, minute: minute)
        guard let targetDate = calendar.date(from: components) else { return nil }

        let now = Date()
        let interval = targetDate.timeIntervalSince(now)

        return interval > 0 ? interval : nil
    }

    // MARK: - Use-By Date Handling

    /// Calculate days until expiry (comparing dates, not timestamps)
    /// - Parameters:
    ///   - expiryDate: Expiry date
    ///   - fromDate: Reference date (defaults to today)
    /// - Returns: Number of days until expiry (negative if expired)
    static func daysUntilExpiry(expiryDate: Date, from fromDate: Date = Date()) -> Int {
        daysBetween(from: fromDate, to: expiryDate)
    }

    // MARK: - Debugging

    #if DEBUG
    /// Print debug info about a date showing both local and UTC representations
    /// - Parameter date: Date to debug
    static func debugDate(_ date: Date, label: String = "Date") {
        let localFormatter = localDateFormatter(format: "yyyy-MM-dd HH:mm:ss")
        let utcFormatter = utcDateFormatter(format: "yyyy-MM-dd HH:mm:ss")

        print("🕐 \(label):")
        print("   Local: \(localFormatter.string(from: date)) (\(calendar.timeZone.identifier))")
        print("   UTC:   \(utcFormatter.string(from: date))")
        print("   Timestamp: \(date.timeIntervalSince1970)")
    }
    #endif
}

// MARK: - Date Extension for Convenience

extension Date {
    /// Get start of day in local timezone
    var startOfDay: Date {
        DateHelper.startOfDay(for: self)
    }

    /// Get end of day in local timezone
    var endOfDay: Date {
        DateHelper.endOfDay(for: self)
    }

    /// Check if this date is today in local timezone
    var isToday: Bool {
        DateHelper.isToday(self)
    }

    /// Check if this date is yesterday in local timezone
    var isYesterday: Bool {
        DateHelper.isYesterday(self)
    }

    /// Check if this date is tomorrow in local timezone
    var isTomorrow: Bool {
        DateHelper.isTomorrow(self)
    }

    /// Get local date key (yyyy-MM-dd in local timezone)
    var localDateKey: String {
        DateHelper.localDateKey(for: self)
    }

    /// Get UTC date key (yyyy-MM-dd in UTC)
    var utcDateKey: String {
        DateHelper.utcDateKey(for: self)
    }
}
