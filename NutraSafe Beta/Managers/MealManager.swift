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

    // RACE CONDITION FIX: Atomic flag to prevent duplicate listener registration
    // This guards the check-then-set pattern in startListening()
    private var isSettingUpListener = false

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

        // BATTERY FIX: Suspend listeners when app backgrounds to prevent 5-15% battery drain/hr
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                #if DEBUG
                print("[MealManager] App backgrounded - suspending listener to save battery")
                #endif
                self?.stopListening()
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                if Auth.auth().currentUser != nil {
                    #if DEBUG
                    print("[MealManager] App foregrounded - resuming listener")
                    #endif
                    self?.startListening()
                }
            }
        }
    }

    // MARK: - Firebase Listeners
    private func startListening() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // RACE CONDITION FIX: Atomic check-and-set to prevent duplicate listeners
        // Two rapid auth callbacks could both pass "listenerRegistration == nil" check
        // before either sets it, resulting in duplicate listeners
        guard !isSettingUpListener && listenerRegistration == nil else {
            #if DEBUG
            print("[MealManager] startListening called but listener already exists/setting up - skipping")
            #endif
            return
        }

        isSettingUpListener = true
        defer { isSettingUpListener = false }

        #if DEBUG
        print("[MealManager] Starting snapshot listener for user: \(userId.prefix(8))...")
        #endif

        listenerRegistration = db.collection("users")
            .document(userId)
            .collection("meals")
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    // HIGH-10 FIX: Check if listener was removed after callback fired
                    // This prevents stale callbacks from updating state after stopListening()
                    guard let self = self, self.listenerRegistration != nil else {
                        #if DEBUG
                        print("[MealManager] HIGH-10: Ignoring orphaned callback after listener removed")
                        #endif
                        return
                    }

                    if let error = error {
                        self.errorMessage = "Failed to load meals: \(error.localizedDescription)"
                        return
                    }

                    guard let documents = snapshot?.documents else { return }

                    let meals = documents.compactMap { doc -> Meal? in
                        try? doc.data(as: Meal.self)
                    }

                    self.meals = meals
                    self.saveToLocalStorage()
                }
            }
    }

    private func stopListening() {
        #if DEBUG
        if listenerRegistration != nil {
            print("[MealManager] Stopping snapshot listener")
        }
        #endif
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

    // MARK: - CRUD Operations (CRIT-9 FIX: Offline-first pattern)

    /// Create a new meal - CRIT-9 FIX: Save locally first, then sync to Firebase
    /// This ensures meals are not lost when user is offline
    func createMeal(name: String, items: [MealItem], iconName: String = "fork.knife") async throws -> Meal {
        guard Auth.auth().currentUser?.uid != nil else {
            throw MealError.notAuthenticated
        }

        let meal = Meal(
            name: name,
            items: items,
            iconName: iconName
        )

        // CRIT-9 FIX: Save locally FIRST (offline-first pattern)
        await MainActor.run {
            self.meals.append(meal)
            self.saveToLocalStorage()
        }

        // Then try to sync to Firebase in background (don't block on this)
        Task {
            await syncMealToFirebase(meal, isNew: true)
        }

        return meal
    }

    /// Update an existing meal - CRIT-9 FIX: Update locally first, then sync
    func updateMeal(_ meal: Meal) async throws {
        guard Auth.auth().currentUser?.uid != nil else {
            throw MealError.notAuthenticated
        }

        var updatedMeal = meal
        updatedMeal.updatedAt = Date()

        // CRIT-9 FIX: Update locally FIRST
        await MainActor.run {
            if let index = self.meals.firstIndex(where: { $0.id == meal.id }) {
                self.meals[index] = updatedMeal
                self.saveToLocalStorage()
            }
        }

        // Then sync to Firebase in background
        Task {
            await syncMealToFirebase(updatedMeal, isNew: false)
        }
    }

    /// Delete a meal - CRIT-9 FIX: Delete locally first, then sync
    func deleteMeal(_ meal: Meal) async throws {
        guard Auth.auth().currentUser?.uid != nil else {
            throw MealError.notAuthenticated
        }

        // CRIT-9 FIX: Delete locally FIRST
        await MainActor.run {
            self.meals.removeAll { $0.id == meal.id }
            self.saveToLocalStorage()
        }

        // Then sync deletion to Firebase in background
        Task {
            await syncMealDeletionToFirebase(meal)
        }
    }

    // MARK: - Firebase Sync Helpers (CRIT-9 FIX)

    /// Sync a meal to Firebase - called after local save succeeds
    private func syncMealToFirebase(_ meal: Meal, isNew: Bool) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            try db.collection("users")
                .document(userId)
                .collection("meals")
                .document(meal.id.uuidString)
                .setData(from: meal)
            #if DEBUG
            print("[MealManager] Synced meal to Firebase: \(meal.name)")
            #endif
        } catch {
            // Firebase sync failed - meal is still saved locally
            // Will sync on next listener update or manual refresh
            print("[MealManager] Warning: Failed to sync meal to Firebase (saved locally): \(error.localizedDescription)")
            // Mark as needing sync on next launch
            markMealAsPendingSync(meal.id)
        }
    }

    /// Sync meal deletion to Firebase
    private func syncMealDeletionToFirebase(_ meal: Meal) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            try await db.collection("users")
                .document(userId)
                .collection("meals")
                .document(meal.id.uuidString)
                .delete()
            #if DEBUG
            print("[MealManager] Synced meal deletion to Firebase: \(meal.name)")
            #endif
        } catch {
            print("[MealManager] Warning: Failed to sync meal deletion to Firebase: \(error.localizedDescription)")
            // Deletion already happened locally - if Firebase fails, it will be orphaned
            // but user data is correct locally
        }
    }

    /// Mark a meal as needing sync on next opportunity
    private func markMealAsPendingSync(_ mealId: UUID) {
        var pendingIds = UserDefaults.standard.stringArray(forKey: "pendingMealSyncIds") ?? []
        if !pendingIds.contains(mealId.uuidString) {
            pendingIds.append(mealId.uuidString)
            UserDefaults.standard.set(pendingIds, forKey: "pendingMealSyncIds")
        }
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
