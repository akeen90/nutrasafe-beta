//
//  NutritionValidator.swift
//  NutraSafe Beta
//
//  Created by Claude Code
//  Input validation layer to prevent corrupt data from entering Firebase
//

import Foundation

/// Errors that can occur during nutrition data validation
enum ValidationError: Error, LocalizedError {
    case invalidCalories(value: Double)
    case invalidProtein(value: Double)
    case invalidCarbohydrates(value: Double)
    case invalidFat(value: Double)
    case invalidSugar(value: Double)
    case invalidFiber(value: Double)
    case invalidSodium(value: Double)
    case invalidServingSize(value: Double)
    case invalidMicronutrient(name: String, value: Double)
    case invalidWeight(value: Double)
    case invalidDate(date: Date)
    case invalidQuantity(value: Double)

    var errorDescription: String? {
        switch self {
        case .invalidCalories(let value):
            return "Invalid calories: \(value). Must be between 0 and 10,000 kcal."
        case .invalidProtein(let value):
            return "Invalid protein: \(value)g. Must be between 0 and 500g."
        case .invalidCarbohydrates(let value):
            return "Invalid carbohydrates: \(value)g. Must be between 0 and 1,000g."
        case .invalidFat(let value):
            return "Invalid fat: \(value)g. Must be between 0 and 500g."
        case .invalidSugar(let value):
            return "Invalid sugar: \(value)g. Must be between 0 and 500g."
        case .invalidFiber(let value):
            return "Invalid fiber: \(value)g. Must be between 0 and 200g."
        case .invalidSodium(let value):
            return "Invalid sodium: \(value)mg. Must be between 0 and 50,000mg."
        case .invalidServingSize(let value):
            return "Invalid serving size: \(value)g. Must be between 0.1 and 10,000g."
        case .invalidMicronutrient(let name, let value):
            return "Invalid \(name): \(value). Must be non-negative and reasonable."
        case .invalidWeight(let value):
            return "Invalid weight: \(value)kg. Must be between 20 and 500kg."
        case .invalidDate(let date):
            return "Invalid date: \(date). Must be between 1900 and current date + 1 year."
        case .invalidQuantity(let value):
            return "Invalid quantity: \(value). Must be between 0.01 and 1,000."
        }
    }
}

/// Validation rules for nutrition and health data
struct NutritionValidator {

    // MARK: - Macronutrient Validation

    /// Validates calories value
    /// - Parameter calories: Calories in kcal
    /// - Throws: ValidationError.invalidCalories if out of bounds
    static func validateCalories(_ calories: Double) throws {
        guard calories >= 0 && calories <= 10_000 else {
            throw ValidationError.invalidCalories(value: calories)
        }
    }

    /// Validates protein value
    /// - Parameter protein: Protein in grams
    /// - Throws: ValidationError.invalidProtein if out of bounds
    static func validateProtein(_ protein: Double) throws {
        guard protein >= 0 && protein <= 500 else {
            throw ValidationError.invalidProtein(value: protein)
        }
    }

    /// Validates carbohydrates value
    /// - Parameter carbs: Carbohydrates in grams
    /// - Throws: ValidationError.invalidCarbohydrates if out of bounds
    static func validateCarbohydrates(_ carbs: Double) throws {
        guard carbs >= 0 && carbs <= 1_000 else {
            throw ValidationError.invalidCarbohydrates(value: carbs)
        }
    }

    /// Validates fat value
    /// - Parameter fat: Fat in grams
    /// - Throws: ValidationError.invalidFat if out of bounds
    static func validateFat(_ fat: Double) throws {
        guard fat >= 0 && fat <= 500 else {
            throw ValidationError.invalidFat(value: fat)
        }
    }

    /// Validates sugar value
    /// - Parameter sugar: Sugar in grams
    /// - Throws: ValidationError.invalidSugar if out of bounds
    static func validateSugar(_ sugar: Double) throws {
        guard sugar >= 0 && sugar <= 500 else {
            throw ValidationError.invalidSugar(value: sugar)
        }
    }

    /// Validates fiber value
    /// - Parameter fiber: Fiber in grams
    /// - Throws: ValidationError.invalidFiber if out of bounds
    static func validateFiber(_ fiber: Double) throws {
        guard fiber >= 0 && fiber <= 200 else {
            throw ValidationError.invalidFiber(value: fiber)
        }
    }

    /// Validates sodium value
    /// - Parameter sodium: Sodium in milligrams
    /// - Throws: ValidationError.invalidSodium if out of bounds
    static func validateSodium(_ sodium: Double) throws {
        guard sodium >= 0 && sodium <= 50_000 else {
            throw ValidationError.invalidSodium(value: sodium)
        }
    }

    /// Validates serving size value
    /// - Parameter servingSize: Serving size in grams
    /// - Throws: ValidationError.invalidServingSize if out of bounds
    static func validateServingSize(_ servingSize: Double) throws {
        guard servingSize >= 0.1 && servingSize <= 10_000 else {
            throw ValidationError.invalidServingSize(value: servingSize)
        }
    }

    // MARK: - Micronutrient Validation

    /// Validates micronutrient value (vitamins, minerals)
    /// - Parameters:
    ///   - name: Nutrient name for error messaging
    ///   - value: Nutrient value (can be in mg, mcg, IU, etc.)
    ///   - maxValue: Maximum reasonable value (default 100,000)
    /// - Throws: ValidationError.invalidMicronutrient if out of bounds
    static func validateMicronutrient(name: String, value: Double, maxValue: Double = 100_000) throws {
        guard value >= 0 && value <= maxValue else {
            throw ValidationError.invalidMicronutrient(name: name, value: value)
        }
    }

    // MARK: - Health Data Validation

    /// Validates body weight value
    /// - Parameter weight: Weight in kilograms
    /// - Throws: ValidationError.invalidWeight if out of bounds
    static func validateWeight(_ weight: Double) throws {
        guard weight >= 20 && weight <= 500 else {
            throw ValidationError.invalidWeight(value: weight)
        }
    }

    /// Validates date value
    /// - Parameter date: Date to validate
    /// - Throws: ValidationError.invalidDate if out of reasonable range
    static func validateDate(_ date: Date) throws {
        // Safely unwrap calendar date calculations with fallback behavior
        guard let year1900 = Calendar.current.date(from: DateComponents(year: 1900, month: 1, day: 1)),
              let oneYearFromNow = Calendar.current.date(byAdding: .year, value: 1, to: Date()) else {
            // If calendar calculations fail, treat as invalid date
            throw ValidationError.invalidDate(date: date)
        }

        guard date >= year1900 && date <= oneYearFromNow else {
            throw ValidationError.invalidDate(date: date)
        }
    }

    /// Validates quantity value (for food entries)
    /// - Parameter quantity: Quantity multiplier
    /// - Throws: ValidationError.invalidQuantity if out of bounds
    static func validateQuantity(_ quantity: Double) throws {
        guard quantity >= 0.01 && quantity <= 1_000 else {
            throw ValidationError.invalidQuantity(value: quantity)
        }
    }

    // MARK: - Composite Validation

    /// Validates a complete food entry before saving to Firebase
    /// - Parameter entry: FoodEntry to validate
    /// - Throws: ValidationError if any field is invalid
    static func validateFoodEntry(_ entry: FoodEntry) throws {
        // Validate macronutrients
        try validateCalories(entry.calories)
        try validateProtein(entry.protein)
        try validateCarbohydrates(entry.carbohydrates)
        try validateFat(entry.fat)
        try validateSugar(entry.sugar ?? 0)
        try validateFiber(entry.fiber ?? 0)
        try validateSodium(entry.sodium ?? 0)

        // Validate serving size
        try validateServingSize(entry.servingSize)

        // Validate date
        try validateDate(entry.date)
    }

    /// Validates weight entry before saving to Firebase
    /// - Parameters:
    ///   - weight: Weight value in kg
    ///   - date: Date of weight measurement
    /// - Throws: ValidationError if any field is invalid
    static func validateWeightEntry(weight: Double, date: Date) throws {
        try validateWeight(weight)
        try validateDate(date)
    }

}

// MARK: - Validation Mode Preference

/// Global validation configuration
struct ValidationConfig {
    /// When true, throws errors on invalid data
    /// When false, auto-sanitizes invalid data
    static var strictMode: Bool = true

    /// Enables detailed validation logging for debugging
    static var debugLogging: Bool = false
}

// MARK: - Extension for Validation Helpers

extension FoodEntry {
    /// Validates this food entry and returns true if valid
    /// - Returns: True if entry passes all validation checks
    func isValid() -> Bool {
        do {
            try NutritionValidator.validateFoodEntry(self)
            return true
        } catch {
            if ValidationConfig.debugLogging {
            }
            return false
        }
    }
}
