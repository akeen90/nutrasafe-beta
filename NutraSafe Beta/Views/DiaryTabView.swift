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
    @State private var showingMoveSheet = false
    @State private var moveToDate = Date()
    @State private var moveToMeal = "Breakfast"
    @State private var showingCopySheet = false
    @State private var copyToDate = Date()
    @State private var copyToMeal = "Breakfast"
    @State private var showingEditSheet = false
    @State private var editingFood: DiaryFoodItem?
    @State private var editingMealType = ""
    @Binding var selectedFoodItems: Set<String>
    @Binding var showingSettings: Bool
    @Binding var selectedTab: TabItem
    @Binding var editTrigger: Bool
    @Binding var moveTrigger: Bool
    @Binding var copyTrigger: Bool
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
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .frame(height: 44, alignment: .center)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.6, green: 0.3, blue: 0.8),
                                        Color(red: 0.4, green: 0.5, blue: 0.9)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Spacer()

                        // Date navigation arrows
                        HStack(spacing: 8) {
                            Button(action: {
                                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                    )
                            }

                            // Date Selector - now inline with Diary title
                            Button(action: {
                                showingDatePicker.toggle()
                            }) {
                                HStack(spacing: 6) {
                                    Text(formatDateShort(selectedDate))
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                        .fixedSize()
                                        .lineLimit(1)

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
                                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                        }

                        Button(action: {
                            showingSettings = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.5
                                            )
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .symbolRenderingMode(.hierarchical)
                            }
                        }
                        .buttonStyle(SpringyButtonStyle())
                    }

                    // Expanded date picker (when shown)
                    if showingDatePicker {
                        VStack(spacing: 0) {
                            // Today button
                            HStack {
                                Spacer()
                                Button(action: {
                                    selectedDate = Date()
                                    showingDatePicker = false
                                }) {
                                    Text("Today")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.blue.opacity(0.1))
                                        )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

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
                                currentDate: selectedDate,
                                onEditFood: onEditFood,
                                onSaveNeeded: saveFoodData
                            )

                            DiaryMealCard(
                                mealType: "Lunch",
                                targetCalories: 600,
                                currentCalories: lunchCalories,
                                foods: $lunchFoods,
                                color: Color(.systemGreen),
                                selectedTab: $selectedTab,
                                selectedFoodItems: $selectedFoodItems,
                                currentDate: selectedDate,
                                onEditFood: onEditFood,
                                onSaveNeeded: saveFoodData
                            )

                            DiaryMealCard(
                                mealType: "Dinner",
                                targetCalories: 600,
                                currentCalories: dinnerCalories,
                                foods: $dinnerFoods,
                                color: Color(.systemBlue),
                                selectedTab: $selectedTab,
                                selectedFoodItems: $selectedFoodItems,
                                currentDate: selectedDate,
                                onEditFood: onEditFood,
                                onSaveNeeded: saveFoodData
                            )

                            DiaryMealCard(
                                mealType: "Snacks",
                                targetCalories: 150,
                                currentCalories: snackCalories,
                                foods: $snackFoods,
                                color: Color(.systemPurple),
                                selectedTab: $selectedTab,
                                selectedFoodItems: $selectedFoodItems,
                                currentDate: selectedDate,
                                onEditFood: onEditFood,
                                onSaveNeeded: saveFoodData
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

                        // Bottom padding for tab bar
                        Spacer()
                            .frame(height: 100)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            // Check if there's a preselected date from adding food
            if let preselectedTimestamp = UserDefaults.standard.object(forKey: "preselectedDate") as? Double {
                selectedDate = Date(timeIntervalSince1970: preselectedTimestamp)
                // Clear it now that we've read and applied it
                UserDefaults.standard.removeObject(forKey: "preselectedDate")
            }
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
        .onChange(of: copyTrigger) { triggered in
            if triggered {
                showCopyOptions()
                DispatchQueue.main.async {
                    copyTrigger = false // Reset trigger
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
        .sheet(isPresented: $showingCopySheet) {
            CopyFoodBottomSheet(
                selectedCount: selectedFoodItems.count,
                currentDate: selectedDate,
                copyToDate: $copyToDate,
                copyToMeal: $copyToMeal,
                onCopy: performCopy,
                onCancel: {
                    showingCopySheet = false
                }
            )
        }
        .sheet(isPresented: $showingEditSheet) {
            if let food = editingFood {
                FoodDetailViewFromSearch(
                    food: food.toFoodSearchResult(),
                    sourceType: .diary,
                    selectedTab: $selectedTab,
                    destination: .diary
                )
            }
        }
    }

    // MARK: - Helper Methods
    private func loadFoodData() {
        print("DiaryTabView: Loading food data for date: \(selectedDate)")
        Task {
            do {
                let (breakfast, lunch, dinner, snacks) = try await diaryDataManager.getFoodDataAsync(for: selectedDate)
                await MainActor.run {
                    breakfastFoods = breakfast
                    lunchFoods = lunch
                    dinnerFoods = dinner
                    snackFoods = snacks
                    print("DiaryTabView: Loaded \(breakfast.count) breakfast, \(lunch.count) lunch, \(dinner.count) dinner, \(snacks.count) snack items from Firebase")
                }
            } catch {
                print("DiaryTabView: Error loading food data from Firebase: \(error.localizedDescription)")
                await MainActor.run {
                    breakfastFoods = []
                    lunchFoods = []
                    dinnerFoods = []
                    snackFoods = []
                }
            }
        }
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
        UserDefaults.standard.set(food.quantity, forKey: "editingQuantity")
        UserDefaults.standard.set(food.servingDescription, forKey: "editingServingDescription")

        // Set state variables and show edit sheet
        editingFood = food
        editingMealType = mealType
        selectedFoodItems.removeAll()
        showingEditSheet = true
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

    private func showCopyOptions() {
        print("DiaryTabView: Showing copy options for \(selectedFoodItems.count) items")
        // Initialize copy date to current diary date
        copyToDate = selectedDate
        copyToMeal = "Breakfast" // Default meal
        showingCopySheet = true
    }

    private func performCopy() {
        let itemCount = selectedFoodItems.count
        var itemsToCopy: [DiaryFoodItem] = []

        print("DiaryTabView: Starting copy of \(itemCount) items to \(copyToMeal) on \(copyToDate)")

        // Collect the selected food items from all meals
        for selectedId in selectedFoodItems {
            // Find and collect the items to copy
            if let food = breakfastFoods.first(where: { $0.id.uuidString == selectedId }) {
                itemsToCopy.append(food)
            } else if let food = lunchFoods.first(where: { $0.id.uuidString == selectedId }) {
                itemsToCopy.append(food)
            } else if let food = dinnerFoods.first(where: { $0.id.uuidString == selectedId }) {
                itemsToCopy.append(food)
            } else if let food = snackFoods.first(where: { $0.id.uuidString == selectedId }) {
                itemsToCopy.append(food)
            }
        }

        // Create new copies with new IDs
        let copiedItems = itemsToCopy.map { item in
            DiaryFoodItem(
                id: UUID(), // New ID for the copy
                name: item.name,
                brand: item.brand,
                calories: item.calories,
                protein: item.protein,
                carbs: item.carbs,
                fat: item.fat,
                fiber: item.fiber,
                sugar: item.sugar,
                sodium: item.sodium,
                servingDescription: item.servingDescription,
                quantity: item.quantity,
                time: item.time,
                processedScore: item.processedScore,
                sugarLevel: item.sugarLevel,
                ingredients: item.ingredients,
                additives: item.additives,
                barcode: item.barcode
            )
        }

        // Get target date data and add copied items
        let (targetBreakfast, targetLunch, targetDinner, targetSnacks) = diaryDataManager.getFoodData(for: copyToDate)

        // Add items to target meal
        switch copyToMeal.lowercased() {
        case "breakfast":
            let updatedBreakfast = targetBreakfast + copiedItems
            diaryDataManager.saveFoodData(for: copyToDate, breakfast: updatedBreakfast, lunch: targetLunch, dinner: targetDinner, snacks: targetSnacks)
        case "lunch":
            let updatedLunch = targetLunch + copiedItems
            diaryDataManager.saveFoodData(for: copyToDate, breakfast: targetBreakfast, lunch: updatedLunch, dinner: targetDinner, snacks: targetSnacks)
        case "dinner":
            let updatedDinner = targetDinner + copiedItems
            diaryDataManager.saveFoodData(for: copyToDate, breakfast: targetBreakfast, lunch: targetLunch, dinner: updatedDinner, snacks: targetSnacks)
        case "snacks":
            let updatedSnacks = targetSnacks + copiedItems
            diaryDataManager.saveFoodData(for: copyToDate, breakfast: targetBreakfast, lunch: targetLunch, dinner: targetDinner, snacks: updatedSnacks)
        default:
            print("DiaryTabView: Unknown target meal: \(copyToMeal)")
        }

        // If copying to current date, reload data to reflect changes
        if Calendar.current.isDate(copyToDate, inSameDayAs: selectedDate) {
            loadFoodData()
        }

        // Close sheet and clear selection
        showingCopySheet = false
        selectedFoodItems.removeAll()

        print("DiaryTabView: Copy completed - copied \(copiedItems.count) items")
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

    private func saveFoodData() {
        // Save all meals for the current selected date
        diaryDataManager.saveFoodData(for: selectedDate, breakfast: breakfastFoods, lunch: lunchFoods, dinner: dinnerFoods, snacks: snackFoods)
        print("DiaryTabView: Saved food data after swipe delete")
    }

    // MARK: - Date Formatting
    private func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter.string(from: date)
    }

    private func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}