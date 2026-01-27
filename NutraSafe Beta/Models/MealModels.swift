//
//  MealModels.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-01-16.
//  Models for the Meal Builder feature - allows users to save and reuse meal combinations
//

import Foundation

// MARK: - Meal Item Model
/// Represents a single food item within a meal with its serving information
struct MealItem: Identifiable, Codable, Equatable {
    var id: UUID
    let name: String
    let brand: String?
    let calories: Int // Per serving (as stored)
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let servingDescription: String
    var quantity: Double
    let ingredients: [String]?
    let barcode: String?
    let isPerUnit: Bool?

    init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        calories: Int,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double = 0,
        sugar: Double = 0,
        sodium: Double = 0,
        servingDescription: String,
        quantity: Double = 1.0,
        ingredients: [String]? = nil,
        barcode: String? = nil,
        isPerUnit: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.servingDescription = servingDescription
        self.quantity = quantity
        self.ingredients = ingredients
        self.barcode = barcode
        self.isPerUnit = isPerUnit
    }

    // Create from FoodSearchResult
    init(from food: FoodSearchResult, servingSize: Double, servingDescription: String) {
        self.id = UUID()
        self.name = food.name
        self.brand = food.brand
        self.servingDescription = servingDescription
        self.quantity = 1.0
        self.ingredients = food.ingredients
        self.barcode = food.barcode
        self.isPerUnit = food.isPerUnit

        // Calculate values for this serving size
        let multiplier: Double
        if food.isPerUnit == true {
            multiplier = servingSize // For per-unit, servingSize is quantity
        } else {
            multiplier = servingSize / 100.0 // For per-100g foods
        }

        self.calories = Int(food.calories * multiplier)
        self.protein = food.protein * multiplier
        self.carbs = food.carbs * multiplier
        self.fat = food.fat * multiplier
        self.fiber = food.fiber * multiplier
        self.sugar = food.sugar * multiplier
        self.sodium = food.sodium * multiplier
    }

    // Create from DiaryFoodItem
    init(from diaryItem: DiaryFoodItem) {
        self.id = UUID()
        self.name = diaryItem.name
        self.brand = diaryItem.brand
        self.calories = diaryItem.calories
        self.protein = diaryItem.protein
        self.carbs = diaryItem.carbs
        self.fat = diaryItem.fat
        self.fiber = diaryItem.fiber
        self.sugar = diaryItem.sugar
        self.sodium = diaryItem.sodium
        self.servingDescription = diaryItem.servingDescription
        self.quantity = diaryItem.quantity
        self.ingredients = diaryItem.ingredients
        self.barcode = diaryItem.barcode
        self.isPerUnit = diaryItem.isPerUnit
    }

    // Convert to DiaryFoodItem for adding to diary
    func toDiaryFoodItem(mealType: String) -> DiaryFoodItem {
        DiaryFoodItem(
            id: UUID(),
            name: name,
            brand: brand,
            calories: Int(Double(calories) * quantity),
            protein: protein * quantity,
            carbs: carbs * quantity,
            fat: fat * quantity,
            fiber: fiber * quantity,
            sugar: sugar * quantity,
            sodium: sodium * quantity,
            servingDescription: servingDescription,
            quantity: quantity,
            time: mealType,
            ingredients: ingredients,
            barcode: barcode,
            isPerUnit: isPerUnit,
            imageUrl: nil,
            portions: nil
        )
    }

    static func == (lhs: MealItem, rhs: MealItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Meal Model
/// Represents a saved meal containing multiple food items
struct Meal: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var items: [MealItem]
    var createdAt: Date
    var updatedAt: Date
    var iconName: String // SF Symbol name for the meal icon

    // Computed nutrition totals
    var totalCalories: Int {
        items.reduce(0) { $0 + Int(Double($1.calories) * $1.quantity) }
    }

    var totalProtein: Double {
        items.reduce(0) { $0 + ($1.protein * $1.quantity) }
    }

    var totalCarbs: Double {
        items.reduce(0) { $0 + ($1.carbs * $1.quantity) }
    }

    var totalFat: Double {
        items.reduce(0) { $0 + ($1.fat * $1.quantity) }
    }

    var totalFiber: Double {
        items.reduce(0) { $0 + ($1.fiber * $1.quantity) }
    }

    var totalSugar: Double {
        items.reduce(0) { $0 + ($1.sugar * $1.quantity) }
    }

    var totalSodium: Double {
        items.reduce(0) { $0 + ($1.sodium * $1.quantity) }
    }

    var itemCount: Int {
        items.count
    }

    init(
        id: UUID = UUID(),
        name: String,
        items: [MealItem] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        iconName: String = "fork.knife"
    ) {
        self.id = id
        self.name = name
        self.items = items
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.iconName = iconName
    }

    // Convert all items to DiaryFoodItems for adding to diary
    func toDiaryFoodItems(mealType: String) -> [DiaryFoodItem] {
        items.map { $0.toDiaryFoodItem(mealType: mealType) }
    }

    static func == (lhs: Meal, rhs: Meal) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Meal Icon Options
/// Available icons for meals
enum MealIcon: String, CaseIterable {
    case forkKnife = "fork.knife"
    case cupAndSaucer = "cup.and.saucer.fill"
    case leaf = "leaf.fill"
    case flame = "flame.fill"
    case heart = "heart.fill"
    case star = "star.fill"
    case bolt = "bolt.fill"
    case moon = "moon.fill"
    case sun = "sun.max.fill"
    case drop = "drop.fill"

    var displayName: String {
        switch self {
        case .forkKnife: return "Meal"
        case .cupAndSaucer: return "Drink"
        case .leaf: return "Healthy"
        case .flame: return "Spicy"
        case .heart: return "Favourite"
        case .star: return "Special"
        case .bolt: return "Energy"
        case .moon: return "Evening"
        case .sun: return "Morning"
        case .drop: return "Hydration"
        }
    }
}
