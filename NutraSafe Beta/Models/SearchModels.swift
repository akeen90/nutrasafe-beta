//
//  SearchModels.swift
//  NutraSafe Beta
//
//  Domain models for Search
//

import Foundation
import SwiftUI

// These types are defined in FoodSafetyModels.swift
// Commenting out duplicates to avoid redeclaration errors

// MARK: - AI Food Recognition Models

struct FoodRecognitionResponse: Codable {
    let foods: [FoodRecognitionItem]
}

struct FoodRecognitionItem: Codable {
    let name: String
    let brand: String?
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let confidence: Double?
}

