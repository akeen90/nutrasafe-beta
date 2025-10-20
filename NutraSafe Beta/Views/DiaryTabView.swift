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
    @State private var editingFood: DiaryFoodItem?
    @State private var editingMealType = ""
    @State private var diarySubTab: DiarySubTab = .overview
    @Binding var selectedFoodItems: Set<String>
    @Binding var showingSettings: Bool
    @Binding var selectedTab: TabItem
    @Binding var editTrigger: Bool
    @Binding var moveTrigger: Bool
    @Binding var copyTrigger: Bool
    @Binding var deleteTrigger: Bool
    let onEditFood: () -> Void
    let onDeleteFoods: () -> Void

    enum DiarySubTab: String, CaseIterable {
        case overview = "Overview"
        case nutrients = "Nutrients"
    }

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
                                        Color(red: 0.95, green: 0.68, blue: 0.38), // Brighter golden orange
                                        Color(red: 0.85, green: 0.55, blue: 0.35)  // Brighter bronze
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
                        ZStack(alignment: .top) {
                            // Native iOS calendar (with its header hidden by overlay)
                            DatePicker(
                                "Select Date",
                                selection: $selectedDate,
                                displayedComponents: .date
                            )
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 8)

                            // White overlay to hide native calendar header
                            VStack(spacing: 0) {
                                Color(UIColor.systemBackground)
                                    .frame(height: 50)
                                Spacer()
                            }
                            .allowsHitTesting(false)

                            // Custom calendar header with Today button
                            HStack {
                                Text(formatMonthYear(selectedDate))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)

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

                                Spacer()

                                // Month navigation buttons
                                HStack(spacing: 12) {
                                    Button(action: {
                                        selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                                    }) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.blue)
                                    }

                                    Button(action: {
                                        selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                                    }) {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Sub-tab picker
                Picker("", selection: $diarySubTab) {
                    ForEach(DiarySubTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                ScrollView {
                    LazyVStack(spacing: 16) {
                        if diarySubTab == .overview {
                            overviewTabContent
                        } else {
                            nutrientsTabContent
                        }
                    }
                }
                .id(diarySubTab) // Force new scroll view when tab changes
                .background(Color(.systemGroupedBackground))
                .navigationBarHidden(true)
            }
        }
        .navigationViewStyle(.stack)
        .onChange(of: selectedDate) { _ in
            loadFoodData()
        }
        .onAppear {
            loadFoodData()
        }
        .onChange(of: refreshTrigger) { _ in
            loadFoodData()
        }
        .onChange(of: editTrigger) { _ in
            print("📝 Edit trigger fired. Selected items: \(selectedFoodItems)")

            // Clear editingFood first to ensure state change
            editingFood = nil

            // Small delay to ensure state is cleared before setting new value
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let foodId = selectedFoodItems.first {
                    print("📝 Looking for food with ID: \(foodId)")
                    if let itemToEdit = findFood(byId: foodId) {
                        print("📝 Found food to edit: \(itemToEdit.name)")
                        print("📝 Setting editingFood to trigger sheet...")
                        editingFood = itemToEdit
                    } else {
                        print("❌ Could not find food with ID: \(foodId)")
                    }
                } else {
                    print("❌ No food ID in selectedFoodItems")
                }
            }
        }
        .onChange(of: moveTrigger) { _ in
            showingMoveSheet = true
        }
        .onChange(of: copyTrigger) { _ in
            showingCopySheet = true
        }
        .onChange(of: deleteTrigger) { _ in
            onDeleteFoods()
        }
        .sheet(isPresented: $showingMoveSheet) {
            moveFoodSheet
        }
        .sheet(isPresented: $showingCopySheet) {
            copyFoodSheet
        }
        .sheet(item: $editingFood, onDismiss: {
            print("📝 Edit sheet dismissed, resetting editingFood")
            editingFood = nil
        }) { food in
            let _ = print("📝 Presenting edit sheet for: \(food.name)")
            FoodDetailViewFromSearch(
                food: food.toFoodSearchResult(),
                sourceType: .diary,
                selectedTab: $selectedTab,
                destination: .diary
            )
        }
    }

    // MARK: - Tab Content Views

    @ViewBuilder
    private var overviewTabContent: some View {
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

                        // Bottom padding for tab bar
                        Spacer()
                            .frame(height: 100)
    }

    @ViewBuilder
    private var nutrientsTabContent: some View {
        if #available(iOS 16.0, *) {
            NutrientActivityDashboard()
                .padding(.horizontal, 16)
        } else {
            ImprovedMicronutrientView(
                breakfast: breakfastFoods,
                lunch: lunchFoods,
                dinner: dinnerFoods,
                snacks: snackFoods
            )
            .padding(.horizontal, 16)
        }

        // Bottom padding for tab bar
        Spacer()
            .frame(height: 100)
    }

    // MARK: - Sheet Views

    @ViewBuilder
    private var moveFoodSheet: some View {
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

    @ViewBuilder
    private var copyFoodSheet: some View {
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

    // MARK: - Helper Methods

    private func findFood(byId id: String) -> DiaryFoodItem? {
        if let food = breakfastFoods.first(where: { $0.id.uuidString == id }) {
            return food
        } else if let food = lunchFoods.first(where: { $0.id.uuidString == id }) {
            return food
        } else if let food = dinnerFoods.first(where: { $0.id.uuidString == id }) {
            return food
        } else if let food = snackFoods.first(where: { $0.id.uuidString == id }) {
            return food
        }
        return nil
    }

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

        // Set state variables - setting editingFood will trigger the sheet
        editingFood = food
        editingMealType = mealType
        selectedFoodItems.removeAll()
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

        // Collect items to delete
        var itemsToDelete: [DiaryFoodItem] = []
        for selectedId in selectedFoodItems {
            if let food = breakfastFoods.first(where: { $0.id.uuidString == selectedId }) {
                itemsToDelete.append(food)
            } else if let food = lunchFoods.first(where: { $0.id.uuidString == selectedId }) {
                itemsToDelete.append(food)
            } else if let food = dinnerFoods.first(where: { $0.id.uuidString == selectedId }) {
                itemsToDelete.append(food)
            } else if let food = snackFoods.first(where: { $0.id.uuidString == selectedId }) {
                itemsToDelete.append(food)
            }
        }

        // Create new filtered arrays to force SwiftUI state update detection
        breakfastFoods = breakfastFoods.filter { !selectedFoodItems.contains($0.id.uuidString) }
        lunchFoods = lunchFoods.filter { !selectedFoodItems.contains($0.id.uuidString) }
        dinnerFoods = dinnerFoods.filter { !selectedFoodItems.contains($0.id.uuidString) }
        snackFoods = snackFoods.filter { !selectedFoodItems.contains($0.id.uuidString) }

        // Save the updated data to UserDefaults
        diaryDataManager.saveFoodData(for: selectedDate, breakfast: breakfastFoods, lunch: lunchFoods, dinner: dinnerFoods, snacks: snackFoods)

        // Delete from Firebase
        diaryDataManager.deleteFoodItems(itemsToDelete, for: selectedDate)

        // Clear selection
        selectedFoodItems.removeAll()

        print("DiaryTabView: Successfully deleted \(itemCount) items from UI and Firebase")
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