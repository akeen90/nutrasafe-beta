//
//  AsyncTimeoutHelper.swift
//  NutraSafe Beta
//
//  Created by Claude Code
//  Provides timeout wrappers for async operations to prevent UI hangs
//

import Foundation

// MARK: - Timeout Error

/// Error thrown when an async operation times out
enum TimeoutError: Error, LocalizedError {
    case timedOut(seconds: Double)

    var errorDescription: String? {
        switch self {
        case .timedOut(let seconds):
            return "Operation timed out after \(Int(seconds)) seconds"
        }
    }
}

// MARK: - Timeout Helper Functions

/// Execute an async operation with a timeout
/// - Parameters:
///   - seconds: Maximum time to wait for the operation
///   - operation: The async operation to execute
/// - Returns: The result of the operation
/// - Throws: TimeoutError.timedOut if the operation doesn't complete in time, or the operation's error
func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        // Add the main operation
        group.addTask {
            try await operation()
        }

        // Add timeout task
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError.timedOut(seconds: seconds)
        }

        // Wait for first to complete
        do {
            // Get first result - will be either success or timeout
            guard let result = try await group.next() else {
                throw TimeoutError.timedOut(seconds: seconds)
            }
            // Cancel the other task
            group.cancelAll()
            return result
        } catch {
            group.cancelAll()
            throw error
        }
    }
}

/// Execute an async operation with a timeout, returning an optional result instead of throwing
/// - Parameters:
///   - seconds: Maximum time to wait for the operation
///   - operation: The async operation to execute
/// - Returns: The result of the operation, or nil if it times out or fails
func withTimeoutOrNil<T>(seconds: Double, operation: @escaping () async throws -> T) async -> T? {
    do {
        return try await withTimeout(seconds: seconds, operation: operation)
    } catch {
        return nil
    }
}

/// Execute an async operation with a timeout, returning a default value on timeout/failure
/// - Parameters:
///   - seconds: Maximum time to wait for the operation
///   - defaultValue: Value to return if operation times out or fails
///   - operation: The async operation to execute
/// - Returns: The result of the operation, or the default value on timeout/failure
func withTimeoutOrDefault<T>(seconds: Double, defaultValue: T, operation: @escaping () async throws -> T) async -> T {
    do {
        return try await withTimeout(seconds: seconds, operation: operation)
    } catch {
        #if DEBUG
        if let timeoutError = error as? TimeoutError {
            print("[Timeout] \(timeoutError.localizedDescription), returning default value")
        } else {
            print("[Timeout] Operation failed: \(error.localizedDescription), returning default value")
        }
        #endif
        return defaultValue
    }
}

// MARK: - Retry Helper

/// Retry configuration for async operations
struct RetryConfig {
    let maxAttempts: Int
    let initialDelaySeconds: Double
    let maxDelaySeconds: Double
    let backoffMultiplier: Double

    static let `default` = RetryConfig(
        maxAttempts: 3,
        initialDelaySeconds: 1.0,
        maxDelaySeconds: 30.0,
        backoffMultiplier: 2.0
    )
}

/// Execute an async operation with retry logic and exponential backoff
/// - Parameters:
///   - config: Retry configuration
///   - operation: The async operation to execute
/// - Returns: The result of the operation
/// - Throws: The last error if all retries fail
func withRetry<T>(config: RetryConfig = .default, operation: @escaping () async throws -> T) async throws -> T {
    var lastError: Error?
    var currentDelay = config.initialDelaySeconds

    for attempt in 1...config.maxAttempts {
        do {
            return try await operation()
        } catch {
            lastError = error

            // Check if we've exhausted retries
            if attempt >= config.maxAttempts {
                break
            }

            #if DEBUG
            print("[Retry] Attempt \(attempt)/\(config.maxAttempts) failed: \(error.localizedDescription). Retrying in \(Int(currentDelay))s...")
            #endif

            // Wait before retry
            try? await Task.sleep(nanoseconds: UInt64(currentDelay * 1_000_000_000))

            // Increase delay for next attempt (exponential backoff)
            currentDelay = min(currentDelay * config.backoffMultiplier, config.maxDelaySeconds)
        }
    }

    throw lastError ?? TimeoutError.timedOut(seconds: 0)
}

/// Execute an async operation with both timeout and retry
/// - Parameters:
///   - timeoutSeconds: Maximum time for each attempt
///   - retryConfig: Retry configuration
///   - operation: The async operation to execute
/// - Returns: The result of the operation
/// - Throws: The last error if all retries fail or timeout
func withTimeoutAndRetry<T>(
    timeoutSeconds: Double,
    retryConfig: RetryConfig = .default,
    operation: @escaping () async throws -> T
) async throws -> T {
    try await withRetry(config: retryConfig) {
        try await withTimeout(seconds: timeoutSeconds) {
            try await operation()
        }
    }
}
