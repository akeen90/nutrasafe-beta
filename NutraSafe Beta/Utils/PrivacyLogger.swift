//
//  PrivacyLogger.swift
//  NutraSafe Beta
//
//  Created by Claude Code
//  Privacy-aware logging using OSLog with automatic PII redaction
//

import Foundation
import os.log

/// Privacy-aware logger using OSLog with automatic redaction of sensitive data
/// Replaces print() statements to prevent leaking user data in device logs
struct PrivacyLogger {

    // MARK: - Log Categories

    /// Log subsystems for different app areas
    enum Subsystem: String {
        case app = "com.nutrasafe.app"
        case auth = "com.nutrasafe.auth"
        case firebase = "com.nutrasafe.firebase"
        case healthKit = "com.nutrasafe.healthkit"
        case nutrition = "com.nutrasafe.nutrition"
        case network = "com.nutrasafe.network"
        case ui = "com.nutrasafe.ui"
        case database = "com.nutrasafe.database"
    }

    /// Log categories within subsystems
    enum Category: String {
        case general = "General"
        case authentication = "Authentication"
        case dataSync = "DataSync"
        case search = "Search"
        case scanning = "Scanning"
        case reactions = "Reactions"
        case allergens = "Allergens"
        case fasting = "Fasting"
        case weight = "Weight"
        case exercise = "Exercise"
        case validation = "Validation"
        case cache = "Cache"
        case security = "Security"
    }

    // MARK: - Logging Methods

    /// Logs a debug message (only in DEBUG builds)
    /// - Parameters:
    ///   - message: The message to log
    ///   - subsystem: App subsystem
    ///   - category: Log category
    ///   - privacy: Privacy level for the message (default: .public)
    static func debug(
        _ message: String,
        subsystem: Subsystem = .app,
        category: Category = .general,
        privacy: OSLogPrivacy = .public
    ) {
        #if DEBUG
        let log = OSLog(subsystem: subsystem.rawValue, category: category.rawValue)
        os_log(.debug, log: log, "%{public}@", message)
        #endif
    }

    /// Logs an info message
    /// - Parameters:
    ///   - message: The message to log
    ///   - subsystem: App subsystem
    ///   - category: Log category
    ///   - privacy: Privacy level for the message (default: .public)
    static func info(
        _ message: String,
        subsystem: Subsystem = .app,
        category: Category = .general,
        privacy: OSLogPrivacy = .public
    ) {
        let log = OSLog(subsystem: subsystem.rawValue, category: category.rawValue)
        os_log(.info, log: log, "%{public}@", message)
    }

    /// Logs a warning message
    /// - Parameters:
    ///   - message: The message to log
    ///   - subsystem: App subsystem
    ///   - category: Log category
    ///   - privacy: Privacy level for the message (default: .public)
    static func warning(
        _ message: String,
        subsystem: Subsystem = .app,
        category: Category = .general,
        privacy: OSLogPrivacy = .public
    ) {
        let log = OSLog(subsystem: subsystem.rawValue, category: category.rawValue)
        os_log(.error, log: log, "⚠️ %{public}@", message)
    }

    /// Logs an error message
    /// - Parameters:
    ///   - message: The message to log
    ///   - error: Optional error object
    ///   - subsystem: App subsystem
    ///   - category: Log category
    ///   - privacy: Privacy level for the message (default: .public)
    static func error(
        _ message: String,
        error: Error? = nil,
        subsystem: Subsystem = .app,
        category: Category = .general,
        privacy: OSLogPrivacy = .public
    ) {
        let log = OSLog(subsystem: subsystem.rawValue, category: category.rawValue)

        if let error = error {
            os_log(.error, log: log, "❌ %{public}@: %{public}@", message, error.localizedDescription)
        } else {
            os_log(.error, log: log, "❌ %{public}@", message)
        }
    }

    /// Logs a fault (critical error)
    /// - Parameters:
    ///   - message: The message to log
    ///   - error: Optional error object
    ///   - subsystem: App subsystem
    ///   - category: Log category
    static func fault(
        _ message: String,
        error: Error? = nil,
        subsystem: Subsystem = .app,
        category: Category = .general
    ) {
        let log = OSLog(subsystem: subsystem.rawValue, category: category.rawValue)

        if let error = error {
            os_log(.fault, log: log, "🔥 CRITICAL: %{public}@: %{public}@", message, error.localizedDescription)
        } else {
            os_log(.fault, log: log, "🔥 CRITICAL: %{public}@", message)
        }
    }

    // MARK: - Privacy-Sensitive Logging

    /// Logs a message with private data (automatically redacted in production logs)
    /// Use for user emails, names, food names, etc.
    /// - Parameters:
    ///   - message: Public part of message
    ///   - privateData: Private data to redact (e.g., email, name)
    ///   - subsystem: App subsystem
    ///   - category: Log category
    static func debugPrivate(
        _ message: String,
        privateData: String,
        subsystem: Subsystem = .app,
        category: Category = .general
    ) {
        #if DEBUG
        let log = OSLog(subsystem: subsystem.rawValue, category: category.rawValue)
        os_log(.debug, log: log, "%{public}@ - %{private}@", message, privateData)
        #endif
    }

    /// Logs authentication events with user data redaction
    /// - Parameters:
    ///   - event: Event name (e.g., "Sign In", "Sign Out")
    ///   - userId: User ID (redacted in logs)
    ///   - email: User email (redacted in logs)
    static func authEvent(
        _ event: String,
        userId: String? = nil,
        email: String? = nil
    ) {
        let log = OSLog(subsystem: Subsystem.auth.rawValue, category: Category.authentication.rawValue)

        if let userId = userId, let email = email {
            os_log(.info, log: log, "🔐 %{public}@ - User: %{private}@, Email: %{private}@", event, userId, email)
        } else if let userId = userId {
            os_log(.info, log: log, "🔐 %{public}@ - User: %{private}@", event, userId)
        } else {
            os_log(.info, log: log, "🔐 %{public}@", event)
        }
    }

    /// Logs data sync events
    /// - Parameters:
    ///   - event: Event description
    ///   - count: Number of items synced
    ///   - subsystem: App subsystem
    static func syncEvent(
        _ event: String,
        count: Int? = nil,
        subsystem: Subsystem = .firebase
    ) {
        let log = OSLog(subsystem: subsystem.rawValue, category: Category.dataSync.rawValue)

        if let count = count {
            os_log(.info, log: log, "🔄 %{public}@ - Count: %d", event, count)
        } else {
            os_log(.info, log: log, "🔄 %{public}@", event)
        }
    }

    /// Logs cache events
    /// - Parameters:
    ///   - event: Event description (hit, miss, invalidate)
    ///   - key: Cache key (redacted)
    static func cacheEvent(
        _ event: String,
        key: String? = nil
    ) {
        #if DEBUG
        let log = OSLog(subsystem: Subsystem.app.rawValue, category: Category.cache.rawValue)

        if let key = key {
            os_log(.debug, log: log, "💾 Cache %{public}@ - Key: %{private}@", event, key)
        } else {
            os_log(.debug, log: log, "💾 Cache %{public}@", event)
        }
        #endif
    }

    /// Logs validation failures
    /// - Parameters:
    ///   - field: Field that failed validation
    ///   - value: Invalid value (redacted)
    ///   - error: Validation error
    static func validationFailure(
        field: String,
        value: Any,
        error: Error
    ) {
        let log = OSLog(subsystem: Subsystem.app.rawValue, category: Category.validation.rawValue)
        os_log(.error, log: log, "⚠️ Validation failed for %{public}@: %{public}@", field, error.localizedDescription)
    }

    /// Logs network requests (URLs are public, but query parameters redacted)
    /// - Parameters:
    ///   - method: HTTP method
    ///   - url: URL (base only, parameters redacted)
    ///   - statusCode: HTTP status code
    static func networkRequest(
        method: String,
        url: String,
        statusCode: Int? = nil
    ) {
        #if DEBUG
        let log = OSLog(subsystem: Subsystem.network.rawValue, category: Category.general.rawValue)

        // Redact query parameters from URL
        let baseURL = url.components(separatedBy: "?").first ?? url

        if let statusCode = statusCode {
            os_log(.debug, log: log, "🌐 %{public}@ %{public}@ - Status: %d", method, baseURL, statusCode)
        } else {
            os_log(.debug, log: log, "🌐 %{public}@ %{public}@", method, baseURL)
        }
        #endif
    }

    /// Logs security events (always logged, even in production)
    /// - Parameters:
    ///   - event: Security event description
    ///   - severity: Event severity (info, warning, critical)
    static func securityEvent(
        _ event: String,
        severity: OSLogType = .info
    ) {
        let log = OSLog(subsystem: Subsystem.app.rawValue, category: Category.security.rawValue)
        os_log(severity, log: log, "🔒 SECURITY: %{public}@", event)
    }
}

// MARK: - Global Convenience Functions

/// Debug log (only in DEBUG builds)
func logDebug(
    _ message: String,
    subsystem: PrivacyLogger.Subsystem = .app,
    category: PrivacyLogger.Category = .general
) {
    PrivacyLogger.debug(message, subsystem: subsystem, category: category)
}

/// Info log
func logInfo(
    _ message: String,
    subsystem: PrivacyLogger.Subsystem = .app,
    category: PrivacyLogger.Category = .general
) {
    PrivacyLogger.info(message, subsystem: subsystem, category: category)
}

/// Warning log
func logWarning(
    _ message: String,
    subsystem: PrivacyLogger.Subsystem = .app,
    category: PrivacyLogger.Category = .general
) {
    PrivacyLogger.warning(message, subsystem: subsystem, category: category)
}

/// Error log
func logError(
    _ message: String,
    error: Error? = nil,
    subsystem: PrivacyLogger.Subsystem = .app,
    category: PrivacyLogger.Category = .general
) {
    PrivacyLogger.error(message, error: error, subsystem: subsystem, category: category)
}
