//
//  ViewTaskManager.swift
//  NutraSafe Beta
//
//  Manages async Task lifecycle for SwiftUI views
//  Ensures tasks are cancelled when views disappear to prevent resource leaks
//

import Foundation
import SwiftUI

/// Thread-safe manager for tracking and cancelling async Tasks
/// Use this in views that launch async work to ensure proper cleanup
@MainActor
final class ViewTaskManager: ObservableObject {
    private var tasks: [String: Task<Void, Never>] = [:]

    /// Launch a named task that will be cancelled on deinit or when cancelled manually
    /// - Parameters:
    ///   - name: Unique identifier for the task (duplicate names cancel previous task)
    ///   - priority: Task priority (default: .userInitiated)
    ///   - operation: The async work to perform
    func launch(
        _ name: String,
        priority: TaskPriority = .userInitiated,
        operation: @escaping @Sendable () async -> Void
    ) {
        // Cancel existing task with same name
        tasks[name]?.cancel()

        // Create and track new task
        let task = Task(priority: priority) {
            await operation()
        }
        tasks[name] = task
    }

    /// Launch a task that automatically removes itself when complete
    /// - Parameters:
    ///   - name: Unique identifier for the task
    ///   - priority: Task priority
    ///   - operation: The async work to perform
    func launchAndForget(
        _ name: String,
        priority: TaskPriority = .userInitiated,
        operation: @escaping @Sendable () async -> Void
    ) {
        // Cancel existing task with same name
        tasks[name]?.cancel()

        let task = Task(priority: priority) { [weak self] in
            await operation()
            // Remove self from tracking when complete
            await MainActor.run {
                self?.tasks.removeValue(forKey: name)
            }
        }
        tasks[name] = task
    }

    /// Cancel a specific task by name
    func cancel(_ name: String) {
        tasks[name]?.cancel()
        tasks.removeValue(forKey: name)
    }

    /// Cancel all tracked tasks
    func cancelAll() {
        for task in tasks.values {
            task.cancel()
        }
        tasks.removeAll()
    }

    /// Check if a specific task is currently running
    func isRunning(_ name: String) -> Bool {
        guard let task = tasks[name] else { return false }
        return !task.isCancelled
    }

    /// Number of active tasks
    var activeTaskCount: Int {
        tasks.values.filter { !$0.isCancelled }.count
    }

    deinit {
        // Cancel all tasks when manager is deallocated
        for task in tasks.values {
            task.cancel()
        }
    }
}

// MARK: - SwiftUI View Extension

extension View {
    /// Modifier that provides a task manager for the view's lifecycle
    /// Tasks are automatically cancelled when the view disappears
    func withTaskManager(
        _ manager: ViewTaskManager,
        cancelOnDisappear: Bool = true
    ) -> some View {
        self.onDisappear {
            if cancelOnDisappear {
                manager.cancelAll()
            }
        }
    }
}

// MARK: - Common Task Names

/// Predefined task names for consistency across the app
enum CommonTaskNames {
    static let loadData = "loadData"
    static let refresh = "refresh"
    static let search = "search"
    static let save = "save"
    static let sync = "sync"
    static let loadImage = "loadImage"
    static let calculateNutrients = "calculateNutrients"
    static let processFood = "processFood"
}
