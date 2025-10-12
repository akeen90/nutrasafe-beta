//
//  FatSecretService.swift
//  NutraSafe Beta
//
//  Service for FatSecret API integration
//

import Foundation

class FatSecretService: ObservableObject {
    static let shared = FatSecretService()

    @Published var searchResults: [FoodSearchResult] = []
    @Published var isLoading = false

    private init() {}

    func searchFood(query: String) {
        // Placeholder implementation
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
            self.searchResults = []
        }
    }
}

struct FoodSearchResult: Identifiable {
    let id = UUID()
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
}