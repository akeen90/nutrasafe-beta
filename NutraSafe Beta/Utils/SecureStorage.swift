//
//  SecureStorage.swift
//  NutraSafe Beta
//
//  Created by Claude Code
//  Encrypted storage for sensitive health data using iOS Keychain
//

import Foundation
import Security

/// Errors that can occur during secure storage operations
enum SecureStorageError: Error, LocalizedError {
    case encodingFailed
    case decodingFailed
    case keychainError(status: OSStatus)
    case itemNotFound
    case unexpectedData

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode data for storage"
        case .decodingFailed:
            return "Failed to decode stored data"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .itemNotFound:
            return "Item not found in secure storage"
        case .unexpectedData:
            return "Unexpected data format in secure storage"
        }
    }
}

/// Secure storage using iOS Keychain for sensitive health data
/// Data is encrypted by the system and protected by device passcode/biometrics
class SecureStorage {

    // MARK: - Keychain Access

    private static let serviceName = "com.nutrasafe.securestorage"

    /// Stores a Codable value in the Keychain
    /// - Parameters:
    ///   - value: The value to store
    ///   - key: Unique key for this value
    ///   - accessibility: When the data should be accessible (default: .whenUnlockedThisDeviceOnly)
    /// - Throws: SecureStorageError if storage fails
    static func set<T: Codable>(_ value: T, forKey key: String, accessibility: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly) throws {
        // Encode value to Data
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(value) else {
            throw SecureStorageError.encodingFailed
        }

        // Prepare keychain query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessibility
        ]

        // Delete existing item if present
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw SecureStorageError.keychainError(status: status)
        }
    }

    /// Retrieves a Codable value from the Keychain
    /// - Parameter key: The key of the value to retrieve
    /// - Throws: SecureStorageError if retrieval fails
    /// - Returns: The stored value
    static func get<T: Codable>(forKey key: String) throws -> T {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw SecureStorageError.itemNotFound
            }
            throw SecureStorageError.keychainError(status: status)
        }

        guard let data = result as? Data else {
            throw SecureStorageError.unexpectedData
        }

        let decoder = JSONDecoder()
        guard let value = try? decoder.decode(T.self, from: data) else {
            throw SecureStorageError.decodingFailed
        }

        return value
    }

    /// Retrieves an optional value from the Keychain (returns nil if not found)
    /// - Parameter key: The key of the value to retrieve
    /// - Returns: The stored value or nil if not found
    static func getOptional<T: Codable>(forKey key: String) -> T? {
        return try? get(forKey: key)
    }

    /// Deletes a value from the Keychain
    /// - Parameter key: The key of the value to delete
    /// - Returns: True if deleted, false if not found
    @discardableResult
    static func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// Checks if a value exists in secure storage
    /// - Parameter key: The key to check
    /// - Returns: True if exists, false otherwise
    static func exists(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Deletes all values from secure storage (use with caution!)
    /// - Returns: True if successful
    @discardableResult
    static func deleteAll() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

// MARK: - Convenience Extensions for Common Data Types

extension SecureStorage {
    /// Stores a String securely
    static func setString(_ value: String, forKey key: String) throws {
        try set(value, forKey: key)
    }

    /// Retrieves a String securely
    static func getString(forKey key: String) -> String? {
        return getOptional(forKey: key)
    }

    /// Stores an Int securely
    static func setInt(_ value: Int, forKey key: String) throws {
        try set(value, forKey: key)
    }

    /// Retrieves an Int securely
    static func getInt(forKey key: String) -> Int? {
        return getOptional(forKey: key)
    }

    /// Stores a Bool securely
    static func setBool(_ value: Bool, forKey key: String) throws {
        try set(value, forKey: key)
    }

    /// Retrieves a Bool securely
    static func getBool(forKey key: String) -> Bool? {
        return getOptional(forKey: key)
    }

    /// Stores a Double securely
    static func setDouble(_ value: Double, forKey key: String) throws {
        try set(value, forKey: key)
    }

    /// Retrieves a Double securely
    static func getDouble(forKey key: String) -> Double? {
        return getOptional(forKey: key)
    }

    /// Stores an array securely
    static func setArray<T: Codable>(_ value: [T], forKey key: String) throws {
        try set(value, forKey: key)
    }

    /// Retrieves an array securely
    static func getArray<T: Codable>(forKey key: String) -> [T]? {
        return getOptional(forKey: key)
    }
}

// MARK: - Key Management (Type-safe keys)

extension SecureStorage {
    /// Type-safe keys for secure storage
    enum Key: String {
        // User sensitive data
        case allergens = "user_allergens"
        case medicalConditions = "user_medical_conditions"
        case foodReactions = "user_food_reactions"

        // Health data
        case currentWeight = "user_current_weight"
        case goalWeight = "user_goal_weight"
        case height = "user_height"

        // Fasting data
        case fastingGoals = "user_fasting_goals"
        case fastingHistory = "user_fasting_history"

        // App preferences (sensitive)
        case userNotes = "user_private_notes"
        case dietaryPreferences = "user_dietary_preferences"
    }

    /// Stores a value using a type-safe key
    static func set<T: Codable>(_ value: T, forKey key: Key) throws {
        try set(value, forKey: key.rawValue)
    }

    /// Retrieves a value using a type-safe key
    static func get<T: Codable>(forKey key: Key) throws -> T {
        return try get(forKey: key.rawValue)
    }

    /// Retrieves an optional value using a type-safe key
    static func getOptional<T: Codable>(forKey key: Key) -> T? {
        return getOptional(forKey: key.rawValue)
    }

    /// Deletes a value using a type-safe key
    @discardableResult
    static func delete(forKey key: Key) -> Bool {
        return delete(forKey: key.rawValue)
    }

    /// Checks if a value exists using a type-safe key
    static func exists(forKey key: Key) -> Bool {
        return exists(forKey: key.rawValue)
    }
}

// MARK: - Migration Helper (UserDefaults → SecureStorage)

extension SecureStorage {
    /// Migrates sensitive data from UserDefaults to SecureStorage
    /// - Parameter keys: Dictionary mapping UserDefaults key to SecureStorage.Key
    static func migrateFromUserDefaults(mappings: [String: Key]) {
        let userDefaults = UserDefaults.standard

        for (oldKey, newKey) in mappings {
            // Check if data exists in UserDefaults
            if let value = userDefaults.object(forKey: oldKey) {
                do {
                    // Migrate based on type
                    if let stringValue = value as? String {
                        try setString(stringValue, forKey: newKey.rawValue)
                    } else if let intValue = value as? Int {
                        try setInt(intValue, forKey: newKey.rawValue)
                    } else if let boolValue = value as? Bool {
                        try setBool(boolValue, forKey: newKey.rawValue)
                    } else if let doubleValue = value as? Double {
                        try setDouble(doubleValue, forKey: newKey.rawValue)
                    } else if let data = value as? Data {
                        // Try to decode as JSON
                        try set(data, forKey: newKey.rawValue)
                    }

                    // Remove from UserDefaults after successful migration
                    userDefaults.removeObject(forKey: oldKey)

                    
                } catch {
                                    }
            }
        }

        userDefaults.synchronize()
    }
}
