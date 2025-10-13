//
//  DiaryFoodView.swift
//  NutraSafe Beta
//
//  Modular diary food tracking view extracted from ContentView.swift
//  Handles meal logging, food item display, nutrition summaries, and selection management
//

import SwiftUI
import Foundation
import HealthKit

// MARK: - Diary Food View
struct DiaryFoodView: View {
    @Binding var selectedTab: TabItem
    @Binding var selectedDate: Date
    @Binding var selectedFoodItems: Set<String>
    @Binding var editTrigger: Bool
    @Binding var moveTrigger: Bool
    @Binding var deleteTrigger: Bool
    @Binding var refreshTrigger: Bool
    let onEditFood: () -> Void
    let onDeleteFoods: () -> Void
    @StateObject private var fatSecretService = FatSecretService.shared
    @EnvironmentObject var diaryDataManager: DiaryDataManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var breakfastFoods: [DiaryFoodItem] = []
    @State private var lunchFoods: [DiaryFoodItem] = []
    @State private var dinnerFoods: [DiaryFoodItem] = []
    @State private var snackFoods: [DiaryFoodItem] = []
    @State private var isLoading = true
    @State private var refreshCounter = 0
    @State private var editingFoodItem: DiaryFoodItem?
    @State private var originalMealType: String = ""
    @State private var showingEditFoodDetail = false
    @State private var editingFoodSearchResult: FoodSearchResult?
    @State private var showingMoveSheet = false
    @State private var moveToDate = Date()
    @State private var moveToMeal = "Breakfast"
    
    // Computed totals
    private var totalCalories: Int {
        let breakfast = breakfastFoods.reduce(0) { $0 + $1.calories }
        let lunch = lunchFoods.reduce(0) { $0 + $1.calories }
        let dinner = dinnerFoods.reduce(0) { $0 + $1.calories }
        let snacks = snackFoods.reduce(0) { $0 + $1.calories }
        return breakfast + lunch + dinner + snacks
    }
    
    private var totalProtein: Double {
        let breakfast = breakfastFoods.reduce(0.0) { $0 + $1.protein }
        let lunch = lunchFoods.reduce(0.0) { $0 + $1.protein }
        let dinner = dinnerFoods.reduce(0.0) { $0 + $1.protein }
        let snacks = snackFoods.reduce(0.0) { $0 + $1.protein }
        return breakfast + lunch + dinner + snacks
    }
    
    private var totalCarbs: Double {
        let breakfast = breakfastFoods.reduce(0.0) { $0 + $1.carbs }
        let lunch = lunchFoods.reduce(0.0) { $0 + $1.carbs }
        let dinner = dinnerFoods.reduce(0.0) { $0 + $1.carbs }
        let snacks = snackFoods.reduce(0.0) { $0 + $1.carbs }
        return breakfast + lunch + dinner + snacks
    }
    
    private var totalFat: Double {
        let breakfast = breakfastFoods.reduce(0.0) { $0 + $1.fat }
        let lunch = lunchFoods.reduce(0.0) { $0 + $1.fat }
        let dinner = dinnerFoods.reduce(0.0) { $0 + $1.fat }
        let snacks = snackFoods.reduce(0.0) { $0 + $1.fat }
        return breakfast + lunch + dinner + snacks
    }
    
    private func editSelectedFood() {
        guard selectedFoodItems.count == 1,
              let selectedId = selectedFoodItems.first else { return }
        
        // Find the selected food item across all meals
        var foundFood: DiaryFoodItem?
        var mealType = ""
        
        if let food = breakfastFoods.first(where: { $0.id.uuidString == selectedId }) {
            foundFood = food
            mealType = "Breakfast"
        } else if let food = lunchFoods.first(where: { $0.id.uuidString == selectedId }) {
            foundFood = food
            mealType = "Lunch"
        } else if let food = dinnerFoods.first(where: { $0.id.uuidString == selectedId }) {
            foundFood = food
            mealType = "Dinner"
        } else if let food = snackFoods.first(where: { $0.id.uuidString == selectedId }) {
            foundFood = food
            mealType = "Snacks"
        }
        
        if let food = foundFood {
            editingFoodItem = food
            originalMealType = mealType
            selectedFoodItems.removeAll()
            
            // Convert DiaryFoodItem to FoodSearchResult for editing
            let foodSearchResult = FoodSearchResult(
                id: food.id.uuidString,
                name: food.name,
                brand: nil, // DiaryFoodItem doesn't have brand
                calories: Double(food.calories),
                protein: food.protein,
                carbs: food.carbs,
                fat: food.fat,
                fiber: 0.0, // DiaryFoodItem doesn't have fiber
                sugar: 0.0, // DiaryFoodItem doesn't have sugar
                sodium: 0.0, // DiaryFoodItem doesn't have sodium
                servingDescription: "100g serving", // Default serving description
                ingredients: food.ingredients,
                confidence: 1.0,
                isVerified: true
            )
            
            // Set up editing context
            UserDefaults.standard.set("editing", forKey: "foodSearchMode")
            UserDefaults.standard.set(food.name, forKey: "editingFoodName")
            UserDefaults.standard.set(mealType, forKey: "editingMealType")
            
            // Store the selected date for the edit operation
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            UserDefaults.standard.set(dateFormatter.string(from: selectedDate), forKey: "editingDate")
            
            // Show the food detail sheet directly
            editingFoodSearchResult = foodSearchResult
            showingEditFoodDetail = true
        }
    }
    
    private func deleteSelectedFoods() {
        let itemCount = selectedFoodItems.count
        print("DiaryFoodView: Starting delete of \(itemCount) items")
        
        // Create new filtered arrays to force SwiftUI state update detection
        breakfastFoods = breakfastFoods.filter { !selectedFoodItems.contains($0.id.uuidString) }
        lunchFoods = lunchFoods.filter { !selectedFoodItems.contains($0.id.uuidString) }
        dinnerFoods = dinnerFoods.filter { !selectedFoodItems.contains($0.id.uuidString) }
        snackFoods = snackFoods.filter { !selectedFoodItems.contains($0.id.uuidString) }
        
        // Save the updated data
        saveFoodDataForCurrentDate()
        
        // Clear selection
        selectedFoodItems.removeAll()
        
        print("DiaryFoodView: Delete completed - UI should update now")
    }

    private func saveFoodData() {
        // Save all meals for the current selected date
        DiaryDataManager.shared.saveFoodData(for: selectedDate, breakfast: breakfastFoods, lunch: lunchFoods, dinner: dinnerFoods, snacks: snackFoods)
        print("DiaryFoodView: Saved food data after swipe delete")
    }

    private func showMoveOptions() {
        // Initialize move date to current diary date
        moveToDate = selectedDate
        moveToMeal = "Breakfast" // Default meal
        showingMoveSheet = true
    }
    
    private func performMove() {
        let itemCount = selectedFoodItems.count
        var itemsToMove: [DiaryFoodItem] = []
        
        print("DiaryFoodView: Starting move of \(itemCount) items to \(moveToMeal) on \(moveToDate)")
        
        // Collect the selected food items from all meals
        for selectedId in selectedFoodItems {
            // Find and collect the items to move
            if let food = breakfastFoods.first(where: { $0.id.uuidString == selectedId }) {
                itemsToMove.append(food)
            } else if let food = lunchFoods.first(where: { $0.id.uuidString == selectedId }) {
                itemsToMove.append(food)
            } else if let food = dinnerFoods.first(where: { $0.id.uuidString == selectedId }) {
                itemsToMove.append(food)
            } else if let food = snackFoods.first(where: { $0.id.uuidString == selectedId }) {
                itemsToMove.append(food)
            }
        }
        
        // Remove items from current date
        breakfastFoods = breakfastFoods.filter { !selectedFoodItems.contains($0.id.uuidString) }
        lunchFoods = lunchFoods.filter { !selectedFoodItems.contains($0.id.uuidString) }
        dinnerFoods = dinnerFoods.filter { !selectedFoodItems.contains($0.id.uuidString) }
        snackFoods = snackFoods.filter { !selectedFoodItems.contains($0.id.uuidString) }
        
        // Save current date after removing items
        saveFoodDataForCurrentDate()
        
        // If moving to a different date, load target date and add items there
        if !Calendar.current.isDate(moveToDate, inSameDayAs: selectedDate) {
            // Load target date data
            let targetData = diaryDataManager.getFoodData(for: moveToDate)
            var targetBreakfast = targetData.0
            var targetLunch = targetData.1
            var targetDinner = targetData.2
            var targetSnacks = targetData.3
            
            // Add items to target meal on target date
            for item in itemsToMove {
                switch moveToMeal {
                case "Breakfast":
                    targetBreakfast.append(item)
                case "Lunch":
                    targetLunch.append(item)
                case "Dinner":
                    targetDinner.append(item)
                case "Snacks":
                    targetSnacks.append(item)
                default:
                    targetBreakfast.append(item)
                }
            }
            
            // Save target date data
            diaryDataManager.saveFoodData(
                for: moveToDate,
                breakfast: targetBreakfast,
                lunch: targetLunch,
                dinner: targetDinner,
                snacks: targetSnacks
            )
        } else {
            // Same-date move - add items to current arrays
            for item in itemsToMove {
                switch moveToMeal {
                case "Breakfast":
                    breakfastFoods.append(item)
                case "Lunch":
                    lunchFoods.append(item)
                case "Dinner":
                    dinnerFoods.append(item)
                case "Snacks":
                    snackFoods.append(item)
                default:
                    breakfastFoods.append(item)
                }
            }
            
            // Save same-date changes
            saveFoodDataForCurrentDate()
        }
        
        // Close sheet and clear selection
        showingMoveSheet = false
        selectedFoodItems.removeAll()
        
        print("DiaryFoodView: Move completed - moved \(itemsToMove.count) items")
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    
                    // Daily Summary
                    DiaryDailySummaryCard(
                        totalCalories: totalCalories,
                        totalProtein: totalProtein,
                        totalCarbs: totalCarbs,
                        totalFat: totalFat,
                        currentDate: selectedDate,
                        breakfastFoods: breakfastFoods,
                        lunchFoods: lunchFoods,
                        dinnerFoods: dinnerFoods,
                        snackFoods: snackFoods
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                // Meal sections
                DiaryMealCard(
                    mealType: "Breakfast",
                    targetCalories: 400,
                    currentCalories: breakfastFoods.reduce(0) { $0 + $1.calories },
                    foods: $breakfastFoods,
                    color: .orange,
                    selectedTab: $selectedTab,
                    selectedFoodItems: $selectedFoodItems,
                    currentDate: selectedDate,
                    onEditFood: onEditFood,
                    onSaveNeeded: saveFoodData
                )
                .padding(.horizontal, 16)

                DiaryMealCard(
                    mealType: "Lunch",
                    targetCalories: 500,
                    currentCalories: lunchFoods.reduce(0) { $0 + $1.calories },
                    foods: $lunchFoods,
                    color: .green,
                    selectedTab: $selectedTab,
                    selectedFoodItems: $selectedFoodItems,
                    currentDate: selectedDate,
                    onEditFood: onEditFood,
                    onSaveNeeded: saveFoodData
                )
                .padding(.horizontal, 16)

                DiaryMealCard(
                    mealType: "Dinner",
                    targetCalories: 600,
                    currentCalories: dinnerFoods.reduce(0) { $0 + $1.calories },
                    foods: $dinnerFoods,
                    color: .purple,
                    selectedTab: $selectedTab,
                    selectedFoodItems: $selectedFoodItems,
                    currentDate: selectedDate,
                    onEditFood: onEditFood,
                    onSaveNeeded: saveFoodData
                )
                .padding(.horizontal, 16)

                DiaryMealCard(
                    mealType: "Snacks",
                    targetCalories: 200,
                    currentCalories: snackFoods.reduce(0) { $0 + $1.calories },
                    foods: $snackFoods,
                    color: .blue,
                    selectedTab: $selectedTab,
                    selectedFoodItems: $selectedFoodItems,
                    currentDate: selectedDate,
                    onEditFood: onEditFood,
                    onSaveNeeded: saveFoodData
                )
                .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
                }
            }
            
        }
        .onAppear {
            loadFoodDataForDate()
            // Update HealthKit exercise calories
            Task {
                await healthKitManager.updateExerciseCalories()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Refresh exercise calories when app comes to foreground
            Task {
                await healthKitManager.updateExerciseCalories()
            }
        }
        .onChange(of: selectedDate) { newDate in
            saveFoodDataForCurrentDate()
            loadFoodDataForDate()
            // Update exercise calories for the new date
            Task {
                await healthKitManager.updateExerciseCalories()
            }
        }
        .onChange(of: editTrigger) { triggered in
            if triggered {
                editSelectedFood()
                DispatchQueue.main.async {
                    editTrigger = false // Reset trigger
                }
            }
        }
        .onChange(of: moveTrigger) { triggered in
            if triggered {
                showMoveOptions()
                DispatchQueue.main.async {
                    moveTrigger = false // Reset trigger
                }
            }
        }
        .onChange(of: deleteTrigger) { triggered in
            if triggered {
                deleteSelectedFoods()
                DispatchQueue.main.async {
                    deleteTrigger = false // Reset trigger
                }
            }
        }
        .onChange(of: refreshTrigger) { triggered in
            if triggered {
                print("📱 Refresh trigger activated, calling loadFoodDataForDate")
                loadFoodDataForDate()
                DispatchQueue.main.async {
                    refreshTrigger = false // Reset trigger
                    print("📱 Refresh trigger reset")
                }
            }
        }
        .sheet(isPresented: $showingEditFoodDetail) {
            if let food = editingFoodSearchResult {
                NavigationView {
                    FoodDetailViewFromSearch(food: food, sourceType: .search, selectedTab: $selectedTab, destination: .diary)
                }
            }
        }
        .sheet(isPresented: $showingMoveSheet) {
            MoveFoodBottomSheet(
                selectedCount: selectedFoodItems.count,
                currentDate: selectedDate,
                moveToDate: $moveToDate,
                moveToMeal: $moveToMeal,
                onMove: performMove,
                onCancel: {
                    showingMoveSheet = false
                }
            )
            .modifier(
                PresentationModifier()
            )
        }
    }
    
    private func loadRealFoodData() {
        Task {
            isLoading = true
            
            do {
                // Search for real foods from your database using common packaged foods that likely have ingredients
                let breakfastSearches = ["Yogurt", "Cereal", "Granola", "Oats", "Muesli"]
                let lunchSearches = ["Bread", "Pasta", "Soup", "Sandwich", "Pizza"]  
                let dinnerSearches = ["Chicken", "Beef", "Fish", "Rice", "Noodles"]
                let snackSearches = ["Chocolate", "Biscuit", "Crisp", "Bar", "Cookie"]
                
                // Load breakfast foods
                let breakfastResults = await loadFoodsForMeal(searches: breakfastSearches, mealTime: "08:30")
                
                // Load lunch foods  
                let lunchResults = await loadFoodsForMeal(searches: lunchSearches, mealTime: "13:15")
                
                // Load dinner foods
                let dinnerResults = await loadFoodsForMeal(searches: dinnerSearches, mealTime: "19:30")
                
                // Load snack foods
                let snackResults = await loadFoodsForMeal(searches: snackSearches, mealTime: "15:45")
                
                await MainActor.run {
                    self.breakfastFoods = breakfastResults
                    self.lunchFoods = lunchResults  
                    self.dinnerFoods = dinnerResults
                    self.snackFoods = snackResults
                    self.isLoading = false
                }
                
            } catch {
                print("Error loading food data: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func loadFoodsForMeal(searches: [String], mealTime: String) async -> [DiaryFoodItem] {
        var mealFoods: [DiaryFoodItem] = []
        
        for searchTerm in searches {
            do {
                let results = try await fatSecretService.searchFoods(query: searchTerm)
                
                // Take the first result that has ingredients
                if let food = results.first(where: { 
                    $0.ingredients != nil && 
                    !($0.ingredients?.isEmpty ?? true) && 
                    !($0.ingredients?.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? true)
                }) {
                    let diaryItem = DiaryFoodItem(
                        name: food.name,
                        calories: Int(food.calories),
                        protein: food.protein,
                        carbs: food.carbs,
                        fat: food.fat,
                        time: mealTime,
                        processedScore: calculateProcessingScore(food),
                        sugarLevel: calculateSugarLevel(food),
                        ingredients: food.ingredients
                    )
                    mealFoods.append(diaryItem)
                }
                
                // Add a small delay to avoid hitting rate limits
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                
            } catch {
                print("Error searching for \(searchTerm): \(error)")
            }
        }
        
        return mealFoods
    }
    
    private func calculateProcessingScore(_ food: FoodSearchResult) -> String {
        // Use comprehensive nutrition scoring algorithm
        let nutritionResult = NutritionScorer.shared.calculateNutritionScore(
            calories: food.calories,
            protein: food.protein,
            carbs: food.carbs,
            fat: food.fat,
            fiber: food.fiber,
            sugar: food.sugar,
            sodium: food.sodium,
            saturatedFat: 0.0, // Not available in search results
            foodName: food.name
        )
        return nutritionResult.grade.rawValue
    }
    
    private func calculateSugarLevel(_ food: FoodSearchResult) -> String {
        if food.sugar < 5 { return "Low" }
        else if food.sugar < 15 { return "Med" }
        else { return "High" }
    }
    
    private func loadFoodDataForDate() {
        // Ensure UI updates happen on main thread
        DispatchQueue.main.async {
            let data = self.diaryDataManager.getFoodData(for: self.selectedDate)
            self.breakfastFoods = data.0
            self.lunchFoods = data.1
            self.dinnerFoods = data.2
            self.snackFoods = data.3
            self.isLoading = false
            
            // Force UI refresh by incrementing counter
            self.refreshCounter += 1
        }
        
        // Removed fake data loading - diary starts empty until user adds real foods
    }
    
    private func saveFoodDataForCurrentDate() {
        diaryDataManager.saveFoodData(
            for: selectedDate,
            breakfast: breakfastFoods,
            lunch: lunchFoods,
            dinner: dinnerFoods,
            snacks: snackFoods
        )
        
        // Sync total calories with Apple Health for today's entries only
        if Calendar.current.isDateInToday(selectedDate) {
            Task {
                do {
                    try await healthKitManager.writeDietaryEnergyConsumed(
                        calories: Double(totalCalories),
                        date: selectedDate
                    )
                } catch {
                    print("Failed to sync calories with Apple Health: \(error)")
                }
            }
        }
    }
    
    private func navigateToPreviousDay() {
        let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        selectedDate = previousDay
        loadFoodDataForDate()
    }
    
    private func navigateToNextDay() {
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        selectedDate = nextDay
        loadFoodDataForDate()
    }
}