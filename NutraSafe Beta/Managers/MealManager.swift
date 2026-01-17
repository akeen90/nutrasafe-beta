//
//  MealManager.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-01-16.
//  Manages saved meals - CRUD operations with Firebase and local storage
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class MealManager: ObservableObject {
    static let shared = MealManager()

    // MARK: - Published Properties
    @Published var meals: [Meal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let mealsKey = "savedMeals"

    private init() {
        // Load from local storage first for instant display
        loadFromLocalStorage()

        // Then sync with Firebase
        setupAuthStateListener()
    }

    // MARK: - Auth State Handling
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if user != nil {
                    self?.startListening()
                } else {
                    self?.stopListening()
                    self?.meals = []
                }
            }
        }
    }

    // MARK: - Firebase Listeners
    private func startListening() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        listenerRegistration = db.collection("users")
            .document(userId)
            .collection("meals")
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    if let error = error {
                        self?.errorMessage = "Failed to load meals: \(error.localizedDescription)"
                        return
                    }

                    guard let documents = snapshot?.documents else { return }

                    let meals = documents.compactMap { doc -> Meal? in
                        try? doc.data(as: Meal.self)
                    }

                    self?.meals = meals
                    self?.saveToLocalStorage()
                }
            }
    }

    private func stopListening() {
        listenerRegistration?.remove()
        listenerRegistration = nil
    }

    deinit {
        // Clean up Firebase listeners to prevent memory leaks
        listenerRegistration?.remove()
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - CRUD Operations

    /// Create a new meal
    func createMeal(name: String, items: [MealItem], iconName: String = "fork.knife") async throws -> Meal {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MealError.notAuthenticated
        }

        let meal = Meal(
            name: name,
            items: items,
            iconName: iconName
        )

        // Save to Firebase
        try db.collection("users")
            .document(userId)
            .collection("meals")
            .document(meal.id.uuidString)
            .setData(from: meal)

        return meal
    }

    /// Update an existing meal
    func updateMeal(_ meal: Meal) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MealError.notAuthenticated
        }

        var updatedMeal = meal
        updatedMeal.updatedAt = Date()

        try db.collection("users")
            .document(userId)
            .collection("meals")
            .document(meal.id.uuidString)
            .setData(from: updatedMeal)
    }

    /// Delete a meal
    func deleteMeal(_ meal: Meal) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MealError.notAuthenticated
        }

        try await db.collection("users")
            .document(userId)
            .collection("meals")
            .document(meal.id.uuidString)
            .delete()
    }

    /// Add item to existing meal
    func addItem(_ item: MealItem, to meal: Meal) async throws {
        var updatedMeal = meal
        updatedMeal.items.append(item)
        try await updateMeal(updatedMeal)
    }

    /// Remove item from meal
    func removeItem(_ item: MealItem, from meal: Meal) async throws {
        var updatedMeal = meal
        updatedMeal.items.removeAll { $0.id == item.id }
        try await updateMeal(updatedMeal)
    }

    /// Update item quantity in meal
    func updateItemQuantity(_ item: MealItem, quantity: Double, in meal: Meal) async throws {
        var updatedMeal = meal
        if let index = updatedMeal.items.firstIndex(where: { $0.id == item.id }) {
            updatedMeal.items[index].quantity = quantity
        }
        try await updateMeal(updatedMeal)
    }

    // MARK: - Local Storage

    private func loadFromLocalStorage() {
        guard let data = UserDefaults.standard.data(forKey: mealsKey),
              let savedMeals = try? JSONDecoder().decode([Meal].self, from: data) else {
            return
        }
        meals = savedMeals
    }

    private func saveToLocalStorage() {
        guard let data = try? JSONEncoder().encode(meals) else { return }
        UserDefaults.standard.set(data, forKey: mealsKey)
    }

    // MARK: - Utility Methods

    /// Check if a meal name already exists
    func mealNameExists(_ name: String, excludingMealId: UUID? = nil) -> Bool {
        meals.contains { meal in
            meal.name.lowercased() == name.lowercased() && meal.id != excludingMealId
        }
    }

    /// Get meal by ID
    func getMeal(byId id: UUID) -> Meal? {
        meals.first { $0.id == id }
    }

    /// Reload meals manually
    func reloadMeals() {
        guard Auth.auth().currentUser != nil else { return }
        stopListening()
        startListening()
    }
}

// MARK: - Error Types
enum MealError: LocalizedError {
    case notAuthenticated
    case mealNotFound
    case invalidData
    case firebaseError(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to save meals"
        case .mealNotFound:
            return "Meal not found"
        case .invalidData:
            return "Invalid meal data"
        case .firebaseError(let message):
            return "Database error: \(message)"
        }
    }
}
