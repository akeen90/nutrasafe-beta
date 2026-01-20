//
//  SafeExtensions.swift
//  NutraSafe Beta
//
//  Crash-safe extensions for common data structures
//

import Foundation

// MARK: - Array Safe Subscript

extension Array {
    /// Safe subscript that returns nil instead of crashing for out-of-bounds access
    /// Usage: array[safe: 5] returns Element? instead of crashing
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Collection Safe Access

extension Collection {
    /// Returns the element at the specified index if it exists, otherwise nil.
    /// Useful for any Collection type, not just Array.
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - String Safe Subscript

extension String {
    /// Safe subscript for string character access
    subscript(safe index: Int) -> Character? {
        guard index >= 0 && index < count else { return nil }
        return self[self.index(startIndex, offsetBy: index)]
    }
}

// MARK: - Dictionary Safe Access

extension Dictionary {
    /// Returns the value for the key, or the default value if key doesn't exist.
    /// Cleaner than ?? for chained operations.
    func value(for key: Key, default defaultValue: Value) -> Value {
        return self[key] ?? defaultValue
    }
}
