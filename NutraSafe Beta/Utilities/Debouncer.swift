//
//  Debouncer.swift
//  NutraSafe Beta
//
//  Performance optimization utility for debouncing user input
//

import Foundation

/// Debounces function execution by delaying until user stops performing an action
/// Useful for search inputs to avoid running expensive operations on every keystroke
@MainActor
class Debouncer: ObservableObject {
    private var task: Task<Void, Never>?
    private let delayNanoseconds: UInt64

    /// Initialize debouncer with specified delay
    /// - Parameter milliseconds: Time to wait after last action before executing (default: 300ms)
    init(milliseconds: UInt64 = 300) {
        self.delayNanoseconds = milliseconds * 1_000_000 // Convert to nanoseconds
    }

    /// Debounce an async action - cancels previous pending action and schedules new one
    /// - Parameter action: The async action to execute after delay
    func debounce(action: @escaping () async -> Void) {
        // Cancel any existing pending task
        task?.cancel()

        // Schedule new task
        task = Task {
            do {
                try await Task.sleep(nanoseconds: delayNanoseconds)
                guard !Task.isCancelled else { return }
                await action()
            } catch {
                // Task was cancelled, ignore
            }
        }
    }

    /// Cancel any pending debounced action
    func cancel() {
        task?.cancel()
        task = nil
    }
}
