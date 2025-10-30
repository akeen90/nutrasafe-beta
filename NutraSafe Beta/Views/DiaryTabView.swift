import SwiftUI
import Foundation
import UIKit

struct DiaryTabView: View {
    @EnvironmentObject var diaryDataManager: DiaryDataManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    let firebaseManager: FirebaseManager = .shared

    @State private var selectedDate: Date = Date()
    @State private var showingDatePicker: Bool = false
    @State private var showingCalendarHistory: Bool = false
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
    var onBlockedNutrientsAttempt: (() -> Void)? = nil

    enum DiarySubTab: String, CaseIterable {
        case overview = "Overview"
        case nutrients = "Nutrients"
    }

    @State private var cachedNutrition: NutritionTotals = NutritionTotals()
    @State private var hasLoadedOnce = false

    private struct NutritionTotals {
        var totalCalories: Int = 0
        var totalProtein: Double = 0
        var totalCarbs: Double = 0
        var totalFat: Double = 0
        var breakfastCalories: Int = 0
        var lunchCalories: Int = 0
        var dinnerCalories: Int = 0
        var snackCalories: Int = 0
    }

    private var totalCalories: Int { cachedNutrition.totalCalories }
    private var totalProtein: Double { cachedNutrition.totalProtein }
    private var totalCarbs: Double { cachedNutrition.totalCarbs }
    private var totalFat: Double { cachedNutrition.totalFat }
    private var breakfastCalories: Int { cachedNutrition.breakfastCalories }
    private var lunchCalories: Int { cachedNutrition.lunchCalories }
    private var dinnerCalories: Int { cachedNutrition.dinnerCalories }
    private var snackCalories: Int { cachedNutrition.snackCalories }

    private func recalculateNutrition() {
        let breakfast = calculateMealNutrition(breakfastFoods)
        let lunch = calculateMealNutrition(lunchFoods)
        let dinner = calculateMealNutrition(dinnerFoods)
        let snacks = calculateMealNutrition(snackFoods)

        cachedNutrition = NutritionTotals(
            totalCalories: breakfast.calories + lunch.calories + dinner.calories + snacks.calories,
            totalProtein: breakfast.protein + lunch.protein + dinner.protein + snacks.protein,
            totalCarbs: breakfast.carbs + lunch.carbs + dinner.carbs + snacks.carbs,
            totalFat: breakfast.fat + lunch.fat + dinner.fat + snacks.fat,
            breakfastCalories: breakfast.calories,
            lunchCalories: lunch.calories,
            dinnerCalories: dinner.calories,
            snackCalories: snacks.calories
        )
    }

    private func calculateMealNutrition(_ foods: [DiaryFoodItem]) -> (calories: Int, protein: Double, carbs: Double, fat: Double) {
        var calories = 0
        var protein = 0.0
        var carbs = 0.0
        var fat = 0.0

        for food in foods {
            calories += food.calories
            protein += food.protein
            carbs += food.carbs
            fat += food.fat
        }

        return (calories, protein, carbs, fat)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact header with integrated tabs
            HStack(spacing: 12) {
                Text("Diary")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()
                
                // Modern tab pills
                HStack(spacing: 4) {
                    ForEach(DiarySubTab.allCases, id: \.self) { tab in
                        Button(action: {
                            let generator = UISelectionFeedbackGenerator()
                            generator.selectionChanged()
                            
                            if tab == .nutrients && !(subscriptionManager.isSubscribed || subscriptionManager.isInTrial || subscriptionManager.isPremiumOverride) {
                                onBlockedNutrientsAttempt?()
                            } else {
                                diarySubTab = tab
                            }
                        }) {
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(diarySubTab == tab ? .white : .secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(diarySubTab == tab ? Color.blue : Color.clear)
                                )
                        }
                    }
                }
                .padding(3)
                .background(
                    Capsule()
                        .fill(Color(.secondarySystemBackground))
                )

                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color(.secondarySystemBackground))
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)

            // Expanded date picker (when shown)
            if showingDatePicker {
                ZStack(alignment: .top) {
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 8)

                    VStack(spacing: 0) {
                        Color(UIColor.systemBackground)
                            .frame(height: 50)
                        Spacer()
                    }
                    .allowsHitTesting(false)

                    HStack {
                        Text(formatMonthYear(selectedDate))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)

                        Button(action: {
                            selectedDate = Date()
                            showingDatePicker = false
                        }) {
                            Text("Today")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(Color.blue)
                                )
                        }

                        Spacer()

                        HStack(spacing: 8) {
                            Button(action: {
                                selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.blue)
                            }

                            Button(action: {
                                selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
            }

            // Modern compact date navigation bar
            HStack(spacing: 0) {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.tertiarySystemBackground))
                        )
                }

                Spacer()

                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    showingDatePicker.toggle()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.blue)
                        
                        Text(formatDateShort(selectedDate))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)

                        Image(systemName: showingDatePicker ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(.secondarySystemBackground))
                    )
                }

                Spacer()

                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.tertiarySystemBackground))
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))

            ScrollView {
                VStack(spacing: 12) {
                    if diarySubTab == .overview {
                        overviewTabContent
                    } else {
                        nutrientsTabContent
                    }
                }
            }
            .id(diarySubTab)
            .background(Color.adaptiveBackground)
            .navigationBarHidden(true)
        }
        .onChange(of: selectedDate) { _ in
            loadFoodData()
        }
        .onAppear {
            guard !hasLoadedOnce else { return }
            hasLoadedOnce = true
            loadFoodData()
        }
        .onChange(of: diarySubTab) { newTab in
            if newTab == .nutrients && !(subscriptionManager.isSubscribed || subscriptionManager.isInTrial || subscriptionManager.isPremiumOverride) {
                diarySubTab = .overview
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
                onBlockedNutrientsAttempt?()
            }
        }
        .onChange(of: refreshTrigger) { _ in
            loadFoodData()
        }
        .onChange(of: diaryDataManager.dataReloadTrigger) { _ in
            loadFoodData()
        }
        .onChange(of: editTrigger) { newValue in
            guard newValue else { return }
            if let foodId = selectedFoodItems.first {
                if let itemToEdit = findFood(byId: foodId) {
                    editingFood = itemToEdit
                } else {
                    print("❌ Could not find food with ID: \(foodId)")
                }
            } else {
                print("❌ No food ID in selectedFoodItems")
            }
            editTrigger = false
        }
        .onChange(of: moveTrigger) { newValue in
            if newValue {
                showMoveOptions()
                moveTrigger = false
            }
        }
        .onChange(of: copyTrigger) { newValue in
            if newValue {
                showCopyOptions()
                copyTrigger = false
            }
        }
        .onChange(of: deleteTrigger) { newValue in
            guard newValue else { return }
            deleteSelectedFoods()
            deleteTrigger = false
        }
        .sheet(isPresented: $showingMoveSheet) {
            moveFoodSheet
        }
        .sheet(isPresented: $showingCopySheet) {
            copyFoodSheet
        }
        .sheet(isPresented: $showingCalendarHistory) {
            NutrientHistoryCalendarView(selectedDate: $selectedDate, firebaseManager: firebaseManager)
        }
        .sheet(item: $editingFood, onDismiss: {
            editingFood = nil
        }) { food in
            FoodDetailViewFromSearch(
                food: food.toFoodSearchResult(),
                sourceType: .diary,
                selectedTab: $selectedTab,
                destination: .diary,
                diaryEntryId: food.id,
                diaryMealType: food.time
            )
        }
    }

    @ViewBuilder
    private var overviewTabContent: some View {
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
        .padding(.top, 8)

        DailyNutrientNudgeCard(date: selectedDate, firebaseManager: firebaseManager)
            .padding(.horizontal, 16)

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
                onSaveNeeded: saveFoodData,
                onDelete: deleteSingleFood
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
                onSaveNeeded: saveFoodData,
                onDelete: deleteSingleFood
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
                onSaveNeeded: saveFoodData,
                onDelete: deleteSingleFood
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
                onSaveNeeded: saveFoodData,
                onDelete: deleteSingleFood
            )
        }
        .padding(.horizontal, 16)

        Spacer()
            .frame(height: 100)
    }

    @ViewBuilder
    private var nutrientsTabContent: some View {
        if #available(iOS 16.0, *) {
            CategoricalNutrientTrackingView(selectedDate: selectedDate, firebaseManager: firebaseManager)
        } else {
            Text("Nutrient tracking requires iOS 16.0 or later")
                .foregroundColor(.secondary)
                .padding()
        }

        Spacer()
            .frame(height: 100)
    }

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

    private func showMoveOptions() {
        guard !selectedFoodItems.isEmpty else { return }
        moveToDate = selectedDate
        moveToMeal = "Breakfast"
        showingMoveSheet = true
    }

    private func showCopyOptions() {
        guard !selectedFoodItems.isEmpty else { return }
        copyToDate = selectedDate
        copyToMeal = "Breakfast"
        showingCopySheet = true
    }

    private func performMove() {
        let destinationMeal = moveToMeal.lowercased()
        for id in selectedFoodItems {
            if let food = findFood(byId: id) {
                diaryDataManager.deleteFoodItems([food], for: selectedDate)
                var moved = food
                moved.id = UUID()
                diaryDataManager.addFoodItem(moved, to: destinationMeal, for: moveToDate)
            }
        }
        selectedFoodItems.removeAll()
        showingMoveSheet = false
    }

    private func performCopy() {
        let destinationMeal = copyToMeal.lowercased()
        for id in selectedFoodItems {
            if let food = findFood(byId: id) {
                var copied = food
                copied.id = UUID()
                diaryDataManager.addFoodItem(copied, to: destinationMeal, for: copyToDate)
            }
        }
        selectedFoodItems.removeAll()
        showingCopySheet = false
    }

    private func findFood(byId id: String) -> DiaryFoodItem? {
        for food in breakfastFoods + lunchFoods + dinnerFoods + snackFoods {
            if food.id.uuidString == id { return food }
        }
        return nil
    }

    private func loadFoodData() {
        Task { @MainActor in
            do {
                let (breakfast, lunch, dinner, snacks) = try await diaryDataManager.getFoodDataAsync(for: selectedDate)
                breakfastFoods = breakfast
                lunchFoods = lunch
                dinnerFoods = dinner
                snackFoods = snacks
                recalculateNutrition()
            } catch {
                print("❌ Failed to load food data: \(error)")
            }
        }
    }

    private func editSelectedFood() {
        if let foodId = selectedFoodItems.first, let itemToEdit = findFood(byId: foodId) {
            editingFood = itemToEdit
        }
    }

    private func deleteSingleFood(_ food: DiaryFoodItem) {
        diaryDataManager.deleteFoodItems([food], for: selectedDate)
        recalculateNutrition()
    }

    private func deleteSelectedFoods() {
        var itemsToDelete: [DiaryFoodItem] = []
        for id in selectedFoodItems {
            if let food = findFood(byId: id) {
                itemsToDelete.append(food)
            }
        }
        if !itemsToDelete.isEmpty {
            diaryDataManager.deleteFoodItems(itemsToDelete, for: selectedDate)
        }
        selectedFoodItems.removeAll()
        recalculateNutrition()
    }

    private func saveFoodData() {
        diaryDataManager.saveFoodData(
            for: selectedDate,
            breakfast: breakfastFoods,
            lunch: lunchFoods,
            dinner: dinnerFoods,
            snacks: snackFoods
        )
    }

    private func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }

    private func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
}
