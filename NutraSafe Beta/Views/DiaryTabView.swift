import SwiftUI
import Foundation

struct DiaryTabView: View {
    @EnvironmentObject var diaryDataManager: DiaryDataManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var selectedDate: Date = Date()
    @State private var showingDatePicker: Bool = false
    @State private var refreshTrigger: Bool = false
    @State private var breakfastFoods: [DiaryFoodItem] = []
    @State private var lunchFoods: [DiaryFoodItem] = []
    @State private var dinnerFoods: [DiaryFoodItem] = []
    @State private var snackFoods: [DiaryFoodItem] = []
    @State private var isSelectionMode: Bool = false
    @State private var showingMoveSheet = false
    @State private var moveToDate = Date()
    @State private var moveToMeal = "Breakfast"
    @Binding var selectedFoodItems: Set<String>
    @Binding var showingSettings: Bool
    @Binding var selectedTab: TabItem
    @Binding var editTrigger: Bool
    @Binding var moveTrigger: Bool
    @Binding var deleteTrigger: Bool
    let onEditFood: () -> Void
    let onDeleteFoods: () -> Void

    // MARK: - Computed Properties
    private var totalCalories: Int {
        breakfastCalories + lunchCalories + dinnerCalories + snackCalories
    }

    private var totalProtein: Double {
        breakfastFoods.reduce(0) { $0 + $1.protein } +
        lunchFoods.reduce(0) { $0 + $1.protein } +
        dinnerFoods.reduce(0) { $0 + $1.protein } +
        snackFoods.reduce(0) { $0 + $1.protein }
    }

    private var totalCarbs: Double {
        breakfastFoods.reduce(0) { $0 + $1.carbs } +
        lunchFoods.reduce(0) { $0 + $1.carbs } +
        dinnerFoods.reduce(0) { $0 + $1.carbs } +
        snackFoods.reduce(0) { $0 + $1.carbs }
    }

    private var totalFat: Double {
        breakfastFoods.reduce(0) { $0 + $1.fat } +
        lunchFoods.reduce(0) { $0 + $1.fat } +
        dinnerFoods.reduce(0) { $0 + $1.fat } +
        snackFoods.reduce(0) { $0 + $1.fat }
    }

    private var breakfastCalories: Int {
        breakfastFoods.reduce(0) { $0 + $1.calories }
    }

    private var lunchCalories: Int {
        lunchFoods.reduce(0) { $0 + $1.calories }
    }

    private var dinnerCalories: Int {
        dinnerFoods.reduce(0) { $0 + $1.calories }
    }

    private var snackCalories: Int {
        snackFoods.reduce(0) { $0 + $1.calories }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    // Header with inline date picker
                    HStack {
                        Text("Diary")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)

                        Spacer()

                        // Date Selector - now inline with Diary title
                        Button(action: {
                            showingDatePicker.toggle()
                        }) {
                            HStack {
                                Text(selectedDate, style: .date)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)

                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.ultraThinMaterial)
                            )
                        }

                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12 + 2)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                )
                        }
                        .buttonStyle(SpringyButtonStyle())
                    }

                    // Expanded date picker (when shown)
                    if showingDatePicker {
                        DatePicker(
                            "Select Date",
                            selection: $selectedDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Daily Summary Card
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

                        // Meal Cards
                        VStack(spacing: 8) {
                            DiaryMealCard(
                                mealType: "Breakfast",
                                targetCalories: 450,
                                currentCalories: breakfastCalories,
                                foods: $breakfastFoods,
                                color: Color(.systemOrange),
                                selectedTab: $selectedTab,
                                selectedFoodItems: $selectedFoodItems,
                                isSelectionMode: $isSelectionMode,
                                onEditFood: onEditFood
                            )

                            DiaryMealCard(
                                mealType: "Lunch",
                                targetCalories: 600,
                                currentCalories: lunchCalories,
                                foods: $lunchFoods,
                                color: Color(.systemGreen),
                                selectedTab: $selectedTab,
                                selectedFoodItems: $selectedFoodItems,
                                isSelectionMode: $isSelectionMode,
                                onEditFood: onEditFood
                            )

                            DiaryMealCard(
                                mealType: "Dinner",
                                targetCalories: 600,
                                currentCalories: dinnerCalories,
                                foods: $dinnerFoods,
                                color: Color(.systemBlue),
                                selectedTab: $selectedTab,
                                selectedFoodItems: $selectedFoodItems,
                                isSelectionMode: $isSelectionMode,
                                onEditFood: onEditFood
                            )

                            DiaryMealCard(
                                mealType: "Snacks",
                                targetCalories: 150,
                                currentCalories: snackCalories,
                                foods: $snackFoods,
                                color: Color(.systemPurple),
                                selectedTab: $selectedTab,
                                selectedFoodItems: $selectedFoodItems,
                                isSelectionMode: $isSelectionMode,
                                onEditFood: onEditFood
                            )
                        }
                        .padding(.horizontal, 16)

                        // Micronutrient Analysis
                        ImprovedMicronutrientView(
                            breakfast: breakfastFoods,
                            lunch: lunchFoods,
                            dinner: dinnerFoods,
                            snacks: snackFoods
                        )
                        .padding(.horizontal, 16)

                        // Hydration Tracking
                        DiaryHydrationView()
                            .padding(.horizontal, 16)

                        // Bottom padding for tab bar
                        Spacer()
                            .frame(height: 100)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadFoodData()
        }
        .onChange(of: selectedDate) { _ in
            loadFoodData()
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
        }
    }

    // MARK: - Helper Methods
    private func loadFoodData() {
        print("DiaryTabView: Loading food data for date: \(selectedDate)")
        let (breakfast, lunch, dinner, snacks) = diaryDataManager.getFoodData(for: selectedDate)
        breakfastFoods = breakfast
        lunchFoods = lunch
        dinnerFoods = dinner
        snackFoods = snacks
        print("DiaryTabView: Loaded \(breakfast.count) breakfast, \(lunch.count) lunch, \(dinner.count) dinner, \(snacks.count) snack items")
    }

    private func editSelectedFood() {
        guard selectedFoodItems.count == 1,
              let selectedId = selectedFoodItems.first else {
            print("DiaryTabView: Cannot edit - need exactly 1 item selected")
            return
        }

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

        guard let food = foundFood else {
            print("DiaryTabView: Could not find selected food item")
            return
        }

        print("DiaryTabView: Editing \(food.name) from \(mealType)")

        // Store editing context in UserDefaults for FoodDetailView
        UserDefaults.standard.set("editing", forKey: "foodSearchMode")
        UserDefaults.standard.set(mealType, forKey: "editingMealType")
        UserDefaults.standard.set(selectedId, forKey: "editingFoodId")

        // Clear selection and navigate to Food tab
        selectedFoodItems.removeAll()
        selectedTab = .food
    }

    private func showMoveOptions() {
        print("DiaryTabView: Showing move options for \(selectedFoodItems.count) items")
        // Initialize move date to current diary date
        moveToDate = selectedDate
        moveToMeal = "Breakfast" // Default meal
        showingMoveSheet = true
    }

    private func performMove() {
        let itemCount = selectedFoodItems.count
        var itemsToMove: [DiaryFoodItem] = []

        print("DiaryTabView: Starting move of \(itemCount) items to \(moveToMeal) on \(moveToDate)")

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

        // Remove selected items from current meals
        breakfastFoods = breakfastFoods.filter { !selectedFoodItems.contains($0.id.uuidString) }
        lunchFoods = lunchFoods.filter { !selectedFoodItems.contains($0.id.uuidString) }
        dinnerFoods = dinnerFoods.filter { !selectedFoodItems.contains($0.id.uuidString) }
        snackFoods = snackFoods.filter { !selectedFoodItems.contains($0.id.uuidString) }

        // Save current date changes
        diaryDataManager.saveFoodData(for: selectedDate, breakfast: breakfastFoods, lunch: lunchFoods, dinner: dinnerFoods, snacks: snackFoods)

        // Get target date data and add moved items
        let (targetBreakfast, targetLunch, targetDinner, targetSnacks) = diaryDataManager.getFoodData(for: moveToDate)

        // Add items to target meal
        switch moveToMeal.lowercased() {
        case "breakfast":
            let updatedBreakfast = targetBreakfast + itemsToMove
            diaryDataManager.saveFoodData(for: moveToDate, breakfast: updatedBreakfast, lunch: targetLunch, dinner: targetDinner, snacks: targetSnacks)
        case "lunch":
            let updatedLunch = targetLunch + itemsToMove
            diaryDataManager.saveFoodData(for: moveToDate, breakfast: targetBreakfast, lunch: updatedLunch, dinner: targetDinner, snacks: targetSnacks)
        case "dinner":
            let updatedDinner = targetDinner + itemsToMove
            diaryDataManager.saveFoodData(for: moveToDate, breakfast: targetBreakfast, lunch: targetLunch, dinner: updatedDinner, snacks: targetSnacks)
        case "snacks":
            let updatedSnacks = targetSnacks + itemsToMove
            diaryDataManager.saveFoodData(for: moveToDate, breakfast: targetBreakfast, lunch: targetLunch, dinner: targetDinner, snacks: updatedSnacks)
        default:
            print("DiaryTabView: Unknown target meal: \(moveToMeal)")
        }

        // If moving to current date, reload data to reflect changes
        if Calendar.current.isDate(moveToDate, inSameDayAs: selectedDate) {
            loadFoodData()
        }

        // Close sheet and clear selection
        showingMoveSheet = false
        selectedFoodItems.removeAll()

        print("DiaryTabView: Move completed - moved \(itemsToMove.count) items")
    }

    private func deleteSelectedFoods() {
        let itemCount = selectedFoodItems.count
        print("DiaryTabView: Starting delete of \(itemCount) items")

        // Create new filtered arrays to force SwiftUI state update detection
        breakfastFoods = breakfastFoods.filter { !selectedFoodItems.contains($0.id.uuidString) }
        lunchFoods = lunchFoods.filter { !selectedFoodItems.contains($0.id.uuidString) }
        dinnerFoods = dinnerFoods.filter { !selectedFoodItems.contains($0.id.uuidString) }
        snackFoods = snackFoods.filter { !selectedFoodItems.contains($0.id.uuidString) }

        // Save the updated data using DiaryDataManager
        diaryDataManager.saveFoodData(for: selectedDate, breakfast: breakfastFoods, lunch: lunchFoods, dinner: dinnerFoods, snacks: snackFoods)

        // Clear selection
        selectedFoodItems.removeAll()

        print("DiaryTabView: Successfully deleted \(itemCount) items")
    }
}