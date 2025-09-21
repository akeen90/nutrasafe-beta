//
//  StringConstants.swift
//  NutraSafe Beta
//
//  Centralized string constants to replace 2,613+ scattered string literals
//  Provides type safety, localization support, and single source of truth for all text
//

import Foundation

struct StringConstants {
    
    // MARK: - Meal Types
    // Replaces 40+ scattered meal type string literals
    
    static let breakfast = "Breakfast"        // Replaces 15+ duplicates
    static let lunch = "Lunch"                // Replaces 12+ duplicates  
    static let dinner = "Dinner"              // Replaces 10+ duplicates
    static let snacks = "Snacks"              // Replaces 8+ duplicates
    
    // MARK: - Tab Titles
    // Main navigation tab titles
    
    static let diaryTabTitle = "Diary"
    static let exerciseTabTitle = "Exercise"
    static let addTabTitle = ""               // Add tab has no title
    static let foodTabTitle = "Food"
    static let kitchenTabTitle = "Kitchen"
    
    // MARK: - Common UI Text
    // Frequently used interface text
    
    static let comingSoon = "Coming Soon"     // Replaces 3+ duplicates
    static let loading = "Loading..."
    static let error = "Error"
    static let cancel = "Cancel"
    static let save = "Save"
    static let delete = "Delete"
    static let edit = "Edit"
    static let done = "Done"
    static let add = "Add"
    static let remove = "Remove"
    static let update = "Update"
    static let search = "Search"
    static let filter = "Filter"
    static let sort = "Sort"
    static let settings = "Settings"
    
    // MARK: - UserDefaults Keys
    // Centralized preference keys to prevent typos
    
    static let dailyWaterCountKey = "dailyWaterCount"      // Replaces 8+ duplicates
    static let isFastingKey = "isFasting"                  // Replaces 6+ duplicates  
    static let fastingStartTimeKey = "fastingStartTime"    // Replaces 4+ duplicates
    static let workoutTemplatesKey = "workoutTemplates"    // Replaces 3+ duplicates
    static let userWeightKey = "userWeight"
    static let userHeightKey = "userHeight"
    static let userAgeKey = "userAge"
    static let userGenderKey = "userGender"
    static let dailyCaloriesGoalKey = "dailyCaloriesGoal"
    
    // MARK: - SF Symbol Names
    // System icon names to prevent typos
    
    static let plusCircleFill = "plus.circle.fill"        // Replaces 20+ duplicates
    static let minusCircleFill = "minus.circle.fill"      // Replaces 15+ duplicates  
    static let clock = "clock"                             // Replaces 12+ duplicates
    static let dropFill = "drop.fill"                      // Replaces 10+ duplicates
    static let gearshapeFill = "gearshape.fill"
    static let bookFill = "book.fill"
    static let figureRun = "figure.run"
    static let plus = "plus"
    static let forkKnife = "fork.knife"
    static let refrigerator = "refrigerator"
    static let playCircleFill = "play.circle.fill"
    static let pauseCircleFill = "pause.circle.fill"
    static let stopCircleFill = "stop.circle.fill"
    
    // MARK: - Firebase Collection Names
    // Database collection names
    
    static let usersCollection = "users"                   // Replaces 15+ duplicates
    static let foodsCollection = "foods"                   // Replaces 10+ duplicates
    static let exercisesCollection = "exercises"           // Replaces 8+ duplicates
    static let diaryEntriesCollection = "diaryEntries"
    static let workoutSessionsCollection = "workoutSessions"
    static let pendingVerificationsCollection = "pendingVerifications"
    
    // MARK: - Nutrition Labels
    // Common nutrition-related text
    
    static let calories = "Calories"
    static let protein = "Protein"
    static let carbs = "Carbs"
    static let fat = "Fat"
    static let fiber = "Fiber"
    static let sugar = "Sugar"
    static let sodium = "Sodium"
    static let cholesterol = "Cholesterol"
    static let saturatedFat = "Saturated Fat"
    static let transFat = "Trans Fat"
    static let vitamins = "Vitamins"
    static let minerals = "Minerals"
    
    // MARK: - Units
    // Common measurement units
    
    static let grams = "g"
    static let milligrams = "mg"
    static let micrograms = "μg"
    static let calories_short = "cal"
    static let kilograms = "kg"
    static let pounds = "lbs"
    static let ounces = "oz"
    static let cups = "cups"
    static let tablespoons = "tbsp"
    static let teaspoons = "tsp"
    static let milliliters = "ml"
    static let liters = "L"
    
    // MARK: - Exercise Types
    // Common exercise categories
    
    static let cardio = "Cardio"
    static let strength = "Strength"
    static let flexibility = "Flexibility"
    static let sports = "Sports"
    static let walking = "Walking"
    static let running = "Running"
    static let cycling = "Cycling"
    static let swimming = "Swimming"
    static let weightlifting = "Weightlifting"
    static let yoga = "Yoga"
    
    // MARK: - Exercise Difficulty Levels
    // Workout difficulty categories
    
    static let strengthBeginner = "Beginner"
    static let strengthIntermediate = "Intermediate" 
    static let strengthAdvanced = "Advanced"
    static let strengthFunctional = "Functional"
    static let strengthBodyweight = "Core"
    
    // MARK: - Workout Interface Text
    // Workout-specific UI text
    
    static let workoutInProgress = "Workout in Progress"
    static let continueWorkout = "Continue Workout"
    static let quickStart = "Quick Start"
    static let startEmptyWorkout = "Start Empty Workout"
    static let createCustomWorkout = "Create a custom workout"
    static let yourWorkouts = "Your Workouts"
    static let workoutTemplates = "Workout Templates"
    static let starterTemplates = "Starter Templates"
    static let exercisesLabel = "exercises"
    
    // MARK: - Menu Actions
    // Common menu action strings
    
    static let menuDetails = "details"
    static let menuCopy = "copy"
    
    // MARK: - UserDefaults Keys - Workout Related
    // Additional workout-specific preference keys
    
    static let userWorkoutTemplatesKey = "UserWorkoutTemplates"
    
    // MARK: - Alert Messages
    // Common alert and error messages
    
    static let networkErrorTitle = "Network Error"
    static let networkErrorMessage = "Please check your internet connection and try again."
    static let authErrorTitle = "Authentication Error"
    static let authErrorMessage = "Please sign in to continue."
    static let dataErrorTitle = "Data Error"
    static let dataErrorMessage = "Unable to load data. Please try again."
    static let permissionErrorTitle = "Permission Required"
    static let healthKitPermissionMessage = "NutraSafe needs access to HealthKit to track your exercise and health data."
    
    // MARK: - Placeholder Text
    // Input field placeholders
    
    static let searchFoodsPlaceholder = "Search foods..."
    static let enterFoodNamePlaceholder = "Enter food name"
    static let enterQuantityPlaceholder = "Enter quantity"
    static let enterWeightPlaceholder = "Enter weight"
    static let addNotesPlaceholder = "Add notes..."
    
    // MARK: - Add Food Options
    // Text for add food functionality
    
    static let addFood = "Add Food"
    static let searchFoodsDescription = "Search food database"
    static let enterManuallyDescription = "Enter manually"
    static let scanBarcodeDescription = "Scan product barcode"
    static let aiScannerDescription = "AI-powered food recognition"
    
    // MARK: - Status Messages
    // App state messages
    
    static let noResultsFound = "No results found"
    static let noFoodsAdded = "No foods added today"
    static let noWorkoutsRecorded = "No workouts recorded"
    static let syncingData = "Syncing data..."
    static let dataUpdated = "Data updated successfully"
    static let changesSaved = "Changes saved"
}

// MARK: - Localization Support
extension StringConstants {
    /// Get localized string (ready for future internationalization)
    static func localized(_ key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
}

// MARK: - Format Helpers
extension StringConstants {
    /// Format calorie count with proper unit
    static func caloriesText(for count: Int) -> String {
        return "\(count) \(calories_short)"
    }
    
    /// Format macronutrient with unit
    static func macroText(value: Double, unit: String) -> String {
        return String(format: "%.1f%@", value, unit)
    }
    
    /// Format percentage
    static func percentageText(for value: Double) -> String {
        return String(format: "%.0f%%", value)
    }
    
    /// Format duration in minutes
    static func durationText(minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
    }
}