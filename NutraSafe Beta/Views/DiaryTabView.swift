import SwiftUI
import Foundation
import UIKit

struct DiaryTabView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var diaryDataManager: DiaryDataManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
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
    var onBlockedNutrientsAttempt: (() -> Void)? = nil

    enum DiarySubTab: String, CaseIterable {
        case overview = "Overview"
        case nutrients = "Nutrients"
    }

    // MARK: - Cached Nutrition Totals (Performance Optimization)
    @State private var cachedNutrition: NutritionTotals = NutritionTotals()
    @State private var hasLoadedOnce = false // PERFORMANCE: Guard flag to prevent redundant loads
    @State private var isLoadingData = false // Loading state for UI feedback

    // MARK: - HealthKit Auto-Refresh Timer (60 seconds)
    private let healthKitRefreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private struct NutritionTotals {
        var totalCalories: Int = 0
        var totalProtein: Double = 0
        var totalCarbs: Double = 0
        var totalFat: Double = 0
        var totalFiber: Double = 0
        var breakfastCalories: Int = 0
        var lunchCalories: Int = 0
        var dinnerCalories: Int = 0
        var snackCalories: Int = 0
    }

    // MARK: - Computed Properties (Using Cached Values)
    private var totalCalories: Int {
        cachedNutrition.totalCalories
    }

    private var totalProtein: Double {
        cachedNutrition.totalProtein
    }

    private var totalCarbs: Double {
        cachedNutrition.totalCarbs
    }

    private var totalFat: Double {
        cachedNutrition.totalFat
    }

    private var totalFiber: Double {
        cachedNutrition.totalFiber
    }

    private var breakfastCalories: Int {
        cachedNutrition.breakfastCalories
    }

    private var lunchCalories: Int {
        cachedNutrition.lunchCalories
    }

    private var dinnerCalories: Int {
        cachedNutrition.dinnerCalories
    }

    private var snackCalories: Int {
        cachedNutrition.snackCalories
    }

    // MARK: - Nutrition Calculation (Called Only When Data Changes)
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
            totalFiber: breakfast.fiber + lunch.fiber + dinner.fiber + snacks.fiber,
            breakfastCalories: breakfast.calories,
            lunchCalories: lunch.calories,
            dinnerCalories: dinner.calories,
            snackCalories: snacks.calories
        )
    }

    private func calculateMealNutrition(_ foods: [DiaryFoodItem]) -> (calories: Int, protein: Double, carbs: Double, fat: Double, fiber: Double) {
        var calories = 0
        var protein = 0.0
        var carbs = 0.0
        var fat = 0.0
        var fiber = 0.0

        for food in foods {
            calories += food.calories
            protein += food.protein
            carbs += food.carbs
            fat += food.fat
            fiber += food.fiber
        }

        return (calories, protein, carbs, fat, fiber)
    }

    // Extracted to reduce compiler complexity
    private var diaryHeaderView: some View {
        HStack(alignment: .center) {
            Text("Diary")
                .font(AppTypography.largeTitle())
                .frame(height: 44, alignment: .center)
                .foregroundColor(.primary)

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
                        .background(Circle().fill(.ultraThinMaterial))
                }

                // Date Selector
                Button(action: {
                    showingDatePicker.toggle()
                }) {
                    HStack(spacing: 6) {
                        Text(showingDatePicker ? "Close" : formatDateShort(selectedDate))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .fixedSize()
                            .lineLimit(1)
                            .animation(nil, value: showingDatePicker)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(showingDatePicker ? 180 : 0))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(AppColors.cardBackgroundInteractive))
                }

                Button(action: {
                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(.ultraThinMaterial))
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
    }

    // MARK: - Date Picker Section
    @ViewBuilder
    private var datePickerSection: some View {
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

                VStack(spacing: 0) {
                    // Match the diary's background
                    // Height covers native DatePicker header + navigation arrows
                    Group {
                        if colorScheme == .dark {
                            Color.midnightBackground
                        } else {
                            LinearGradient(
                                colors: [
                                    Color(red: 0.92, green: 0.96, blue: 1.0),
                                    Color(red: 0.93, green: 0.90, blue: 1.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                    }
                    .frame(height: 58)
                    Spacer()
                }
                .allowsHitTesting(false)

                datePickerHeader
            }
            .background(
                Group {
                    if colorScheme == .dark {
                        Color.midnightBackground
                    } else {
                        LinearGradient(
                            colors: [
                                Color(red: 0.92, green: 0.96, blue: 1.0),
                                Color(red: 0.93, green: 0.88, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var datePickerHeader: some View {
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
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Calendar Header Section
    @ViewBuilder
    private var calendarHeaderSection: some View {
        if diarySubTab == .overview {
            VStack(spacing: 8) {
                diaryHeaderView
                datePickerSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Tab Picker Section
    private var tabPickerSection: some View {
        Picker("", selection: $diarySubTab) {
            ForEach(DiarySubTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .backgroundStyle(.ultraThinMaterial)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .padding(.bottom, 12)
    }

    // MARK: - Loading State View
    @ViewBuilder
    private var loadingStateView: some View {
        if isLoadingData && !hasLoadedOnce {
            VStack(spacing: 16) {
                Spacer()
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(.circular)
                Text("Loading your diary...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(diaryBlueBackground)
        }
    }

    // MARK: - Main Content Section
    @ViewBuilder
    private var mainContentSection: some View {
        if !(isLoadingData && !hasLoadedOnce) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if diarySubTab == .overview {
                        overviewTabContent
                    } else {
                        nutrientsTabContent
                    }
                }
            }
            .id(diarySubTab)
            .background(diaryBlueBackground)
            .navigationBarHidden(true)
        }
    }

    var body: some View {
        contentWithLifecycleModifiers
            .sheet(isPresented: $showingMoveSheet) {
                moveFoodSheet
            }
            .sheet(isPresented: $showingCopySheet) {
                copyFoodSheet
            }
            .sheet(item: $editingFood, onDismiss: {
                // DEBUG LOG: print("📝 Edit sheet dismissed, resetting editingFood")
                editingFood = nil
                editingMealType = ""
            }) { food in
                let _ = print("📝 Presenting edit sheet for: \(food.name) in meal: \(editingMealType), quantity: \(food.quantity)")
                FoodDetailViewFromSearch(
                    food: food.toFoodSearchResult(),
                    sourceType: .diary,
                    selectedTab: $selectedTab,
                    diaryEntryId: food.id,
                    diaryMealType: editingMealType.isEmpty ? food.time : editingMealType,
                    diaryQuantity: food.quantity,
                    diaryDate: selectedDate
                )
            }
            .background(Color.adaptiveBackground)
    }

    // MARK: - Content with Lifecycle Modifiers
    private var contentWithLifecycleModifiers: some View {
        mainContent
            .onChange(of: selectedDate) {
                loadFoodData()
            }
            .onAppear {
                // PERFORMANCE: Skip if already loaded - prevents redundant Firebase calls on tab switches
                guard !hasLoadedOnce else {
                    // DEBUG LOG: print("⚡️ DiaryTabView: Skipping load - data already loaded")
                    return
                }
                hasLoadedOnce = true
                loadFoodData()
            }
            .onChange(of: selectedTab) { _, newTab in
                handleSelectedTabChange(newTab)
            }
            .onChange(of: diarySubTab) { _, newTab in
                handleDiarySubTabChange(newTab)
            }
            .onChange(of: refreshTrigger) {
                loadFoodData()
            }
            .onChange(of: diaryDataManager.dataReloadTrigger) {
                loadFoodData()
            }
            .onChange(of: editTrigger) { _, newValue in
                handleEditTrigger(newValue)
            }
            .onReceive(NotificationCenter.default.publisher(for: .diaryFoodDetailOpened)) { _ in
                selectedFoodItems.removeAll()
            }
            .onReceive(healthKitRefreshTimer) { _ in
                // Only refresh HealthKit data if viewing today's date
                if Calendar.current.isDateInToday(selectedDate) {
                    Task {
                        await healthKitManager.updateStepCount(for: selectedDate)
                        await healthKitManager.updateActiveEnergy(for: selectedDate)
                    }
                }
            }
            .onChange(of: moveTrigger) { _, newValue in
                if newValue {
                    showMoveOptions()
                    moveTrigger = false
                }
            }
            .onChange(of: copyTrigger) { _, newValue in
                if newValue {
                    showCopyOptions()
                    copyTrigger = false
                }
            }
            .onChange(of: deleteTrigger) { _, newValue in
                guard newValue else { return }
                deleteSelectedFoods()
                deleteTrigger = false
            }
    }

    // MARK: - Main Content
    private var mainContent: some View {
        VStack(spacing: 0) {
            calendarHeaderSection
            tabPickerSection

            // Loading state or content
            ZStack {
                loadingStateView
                mainContentSection
            }
        }
        .background(diaryBlueBackground)
    }

    // MARK: - Adaptive Background (gradient in light mode, midnight blue in dark mode)
    private var diaryBlueBackground: some View {
        Group {
            if colorScheme == .dark {
                // Dark mode: Use midnight blue
                Color.midnightBackground
                    .ignoresSafeArea()
            } else {
                // Light mode: Use beautiful gradient
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.92, green: 0.96, blue: 1.0),
                            Color(red: 0.93, green: 0.88, blue: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    RadialGradient(
                        colors: [Color.blue.opacity(0.10), Color.clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 300
                    )
                    RadialGradient(
                        colors: [Color.purple.opacity(0.08), Color.clear],
                        center: .bottomTrailing,
                        startRadius: 0,
                        endRadius: 280
                    )
                }
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - Helper Methods for onChange Handlers
    private func handleSelectedTabChange(_ newTab: TabItem) {
        // Unselect when leaving diary; reset overview when returning
        if newTab == .diary {
            diarySubTab = .overview
        } else {
            selectedFoodItems.removeAll()
        }
    }

    private func handleDiarySubTabChange(_ newTab: DiarySubTab) {
        let hasAccess = subscriptionManager.isSubscribed ||
                        subscriptionManager.isInTrial ||
                        subscriptionManager.isPremiumOverride

        if newTab == .nutrients && !hasAccess {
            diarySubTab = .overview
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            onBlockedNutrientsAttempt?()
        }
    }

    private func handleEditTrigger(_ newValue: Bool) {
        guard newValue else { return }
        // DEBUG LOG: print("📝 Edit trigger fired. Selected items: \(selectedFoodItems)")

        if let foodId = selectedFoodItems.first {
            // DEBUG LOG: print("📝 Looking for food with ID: \(foodId)")
            if let result = findFoodWithMeal(byId: foodId) {
                // DEBUG LOG: print("📝 Found food to edit: \(result.food.name) in \(result.meal)")
                // DEBUG LOG: print("📝 Setting editingFood to trigger sheet...")
                editingFood = result.food
                editingMealType = result.meal
                // Clear selection once user enters edit flow
                selectedFoodItems.removeAll()
            } else {
                #if DEBUG
                print("❌ Could not find food with ID: \(foodId)")
                #endif
            }
        } else {
            #if DEBUG
            print("❌ No food ID in selectedFoodItems")
            #endif
        }

        editTrigger = false
    }

    @ViewBuilder
    private var overviewTabContent: some View {
        DiaryDailySummaryCard(
            totalCalories: totalCalories,
            totalProtein: totalProtein,
            totalCarbs: totalCarbs,
            totalFat: totalFat,
            totalFiber: totalFiber,
            currentDate: selectedDate,
            breakfastFoods: breakfastFoods,
            lunchFoods: lunchFoods,
            dinnerFoods: dinnerFoods,
            snackFoods: snackFoods,
            fetchWeeklySummary: fetchWeeklySummary,
            setSelectedDate: { date in
                selectedDate = date
            }
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)

        // Standalone column headers in glass card
        HStack {
            HStack(spacing: 8) {
                // Spacer for alignment with food items
                Spacer()
                    .frame(width: 12)

                Text("FOOD/DRINK")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 0) {
                Text("KCAL")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
                Text("PROT")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
                Text("CARB")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
                Text("FAT")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .fill(.ultraThinMaterial)
        )
        .cardShadow()
        .padding(.horizontal, 16)
        .padding(.bottom, -8)

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
                onDelete: deleteSingleFood,
                onAdd: { addFoodToMeal("Breakfast") }
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
                onDelete: deleteSingleFood,
                onAdd: { addFoodToMeal("Lunch") }
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
                onDelete: deleteSingleFood,
                onAdd: { addFoodToMeal("Dinner") }
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
                onDelete: deleteSingleFood,
                onAdd: { addFoodToMeal("Snacks") }
            )
        }
        .padding(.horizontal, 16)

        Spacer()
            .frame(height: 150)
    }

    @ViewBuilder
    private var nutrientsTabContent: some View {
        if #available(iOS 16.0, *) {
            CategoricalNutrientTrackingView(selectedDate: $selectedDate)
        } else {
            Text("Nutrient tracking requires iOS 16.0 or later")
                .foregroundColor(.secondary)
                .padding()
        }

        Spacer()
            .frame(height: 150)
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
        let itemsToMove = selectedFoodItems.compactMap { findFood(byId: $0) }
        selectedFoodItems.removeAll()
        showingMoveSheet = false

        Task {
            for food in itemsToMove {
                // Remove from current date
                diaryDataManager.deleteFoodItems([food], for: selectedDate)
                // Add to destination date (new id to avoid collisions)
                var moved = food
                moved.id = UUID()
                await diaryDataManager.addFoodItem(moved, to: destinationMeal, for: moveToDate)
            }
        }
    }

    private func performCopy() {
        let destinationMeal = copyToMeal.lowercased()
        let itemsToCopy = selectedFoodItems.compactMap { findFood(byId: $0) }
        selectedFoodItems.removeAll()
        showingCopySheet = false

        Task {
            for food in itemsToCopy {
                var copied = food
                copied.id = UUID()
                await diaryDataManager.addFoodItem(copied, to: destinationMeal, for: copyToDate)
            }
        }
    }

    private func findFood(byId id: String) -> DiaryFoodItem? {
        for food in breakfastFoods + lunchFoods + dinnerFoods + snackFoods {
            if food.id.uuidString == id { return food }
        }
        return nil
    }

    /// Find food and determine which meal it belongs to based on which array contains it
    private func findFoodWithMeal(byId id: String) -> (food: DiaryFoodItem, meal: String)? {
        for food in breakfastFoods {
            if food.id.uuidString == id { return (food, "Breakfast") }
        }
        for food in lunchFoods {
            if food.id.uuidString == id { return (food, "Lunch") }
        }
        for food in dinnerFoods {
            if food.id.uuidString == id { return (food, "Dinner") }
        }
        for food in snackFoods {
            if food.id.uuidString == id { return (food, "Snacks") }
        }
        return nil
    }

    private func loadFoodData() {
        Task {
            await MainActor.run {
                isLoadingData = true
            }

            do {
                let (breakfast, lunch, dinner, snacks) = try await diaryDataManager.getFoodDataAsync(for: selectedDate)

                // Set current display date before fetching (prevents race condition when rapidly navigating)
                healthKitManager.setCurrentDisplayDate(selectedDate)

                // Update ALL HealthKit data for the selected date
                // NOTE: This is the ONLY place that should fetch HealthKit data for the diary
                // DiaryDailySummaryCard observes these values but does NOT fetch
                await healthKitManager.updateExerciseCalories(for: selectedDate)
                await healthKitManager.updateStepCount(for: selectedDate)
                await healthKitManager.updateActiveEnergy(for: selectedDate)

                await MainActor.run {
                    breakfastFoods = breakfast
                    lunchFoods = lunch
                    dinnerFoods = dinner
                    snackFoods = snacks
                    recalculateNutrition()
                    isLoadingData = false
                }
            } catch {
                #if DEBUG
                print("❌ Failed to load food data: \(error)")
                #endif
                await MainActor.run {
                    isLoadingData = false
                }
            }
        }
    }

    // MARK: - Weekly Summary Data Fetching

    private func getWeekRange(for date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current

        // Get the day of the week (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
        let weekday = calendar.component(.weekday, from: date)

        // Calculate offset to Monday (weekday 2)
        // If Sunday (1), offset is -6; if Monday (2), offset is 0; if Tuesday (3), offset is -1, etc.
        let daysFromMonday = (weekday == 1) ? -6 : 2 - weekday

        // Get Monday of the week
        guard let monday = calendar.date(byAdding: .day, value: daysFromMonday, to: date) else {
            return (date, date)
        }

        // Get Sunday (6 days after Monday)
        guard let sunday = calendar.date(byAdding: .day, value: 6, to: monday) else {
            return (monday, monday)
        }

        // Set to start of day for Monday and end of day for Sunday
        let startOfMonday = calendar.startOfDay(for: monday)
        let endOfSunday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: sunday)) ?? sunday

        return (startOfMonday, endOfSunday)
    }

    func fetchWeeklySummary(_ date: Date, _ calorieGoal: Double, _ proteinGoal: Double, _ carbGoal: Double, _ fatGoal: Double) async -> WeeklySummary? {
        let (weekStart, weekEnd) = getWeekRange(for: date)

        do {
            // Fetch all food entries for the week
            let calendar = Calendar.current
            var currentDate = weekStart
            var dailyBreakdowns: [DailyBreakdown] = []

            var weekTotalCalories = 0
            var weekTotalProtein = 0.0
            var weekTotalCarbs = 0.0
            var weekTotalFat = 0.0

            // Iterate through each day of the week (Monday to Sunday)
            for _ in 0..<7 {
                let (breakfast, lunch, dinner, snacks) = try await diaryDataManager.getFoodDataAsync(for: currentDate)

                // Calculate daily totals
                let allFoods = breakfast + lunch + dinner + snacks
                let dayCalories = allFoods.reduce(0) { $0 + $1.calories }
                let dayProtein = allFoods.reduce(0.0) { $0 + $1.protein }
                let dayCarbs = allFoods.reduce(0.0) { $0 + $1.carbs }
                let dayFat = allFoods.reduce(0.0) { $0 + $1.fat }

                let isLogged = !allFoods.isEmpty

                // Create daily breakdown
                let breakdown = DailyBreakdown(
                    date: currentDate,
                    calories: dayCalories,
                    protein: dayProtein,
                    carbs: dayCarbs,
                    fat: dayFat,
                    isLogged: isLogged
                )
                dailyBreakdowns.append(breakdown)

                // Add to weekly totals
                weekTotalCalories += dayCalories
                weekTotalProtein += dayProtein
                weekTotalCarbs += dayCarbs
                weekTotalFat += dayFat

                // Move to next day
                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                    break
                }
                currentDate = nextDay
            }

            // Create and return weekly summary
            return WeeklySummary(
                weekStartDate: weekStart,
                weekEndDate: calendar.date(byAdding: .day, value: -1, to: weekEnd) ?? weekStart,
                totalCalories: weekTotalCalories,
                totalProtein: weekTotalProtein,
                totalCarbs: weekTotalCarbs,
                totalFat: weekTotalFat,
                dailyBreakdowns: dailyBreakdowns
            )

        } catch {
            #if DEBUG
            print("❌ Failed to fetch weekly summary: \(error)")
            #endif
            return nil
        }
    }

    private func editSelectedFood() {
        if let foodId = selectedFoodItems.first, let result = findFoodWithMeal(byId: foodId) {
            editingFood = result.food
            editingMealType = result.meal
        }
    }

    private func deleteSingleFood(_ food: DiaryFoodItem) {
        diaryDataManager.deleteFoodItems([food], for: selectedDate)
    }

    private func addFoodToMeal(_ mealType: String) {
        // Dismiss keyboard before switching tabs
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        // Store the selected meal type and date for the add flow
        UserDefaults.standard.set(mealType, forKey: "preselectedMealType")
        UserDefaults.standard.set(selectedDate.timeIntervalSince1970, forKey: "preselectedDate")
        UserDefaults.standard.set("diary", forKey: "preselectedDestination")

        // Switch to the Add tab
        selectedTab = .add
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
        formatter.dateFormat = "dd/MM/yy"
        return formatter.string(from: date)
    }

    private func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Categorical Nutrient Tracking with Rhythm Bar

@available(iOS 16.0, *)
struct CategoricalNutrientTrackingView: View {
    @EnvironmentObject var diaryDataManager: DiaryDataManager
    @StateObject private var vm = CategoricalNutrientViewModel()
    @State private var showingGaps: Bool = false
    @State private var selectedNutrientRow: CoverageRow?

    @Binding var selectedDate: Date

    // Week navigation state
    @State private var weekOffset: Int = 0 // 0 = current week, -1 = last week, etc.
    @State private var selectedWeekStart: Date = Date()
    @State private var showCalendar: Bool = false
    @State private var hasInitiallyLoaded: Bool = false // Prevent duplicate initial loads

    var body: some View {
        VStack(spacing: 20) {
            // Week Navigation Header
            weekNavigationHeader

            // Nutrient Rhythm Bar + Insight Line
            rhythmSection

            // Nutrient Coverage Map
            coverageMapSection
        }
        .task {
            // Small debounce to prevent race conditions
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

            // Guard against duplicate initial loads
            guard !hasInitiallyLoaded else {
                #if DEBUG
                print("⚡️ Skipping duplicate initial load")
                #endif
                return
            }
            hasInitiallyLoaded = true

            #if DEBUG
            print("🎬 CategoricalNutrientTrackingView: Starting task...")
            #endif
            vm.setDiaryManager(diaryDataManager)

            // Initialize with the week containing selectedDate
            let (weekStart, _) = getWeekRange(for: selectedDate)
            selectedWeekStart = weekStart

            // Calculate week offset from today
            let (currentWeekStart, _) = getWeekRange(for: Date())
            let calendar = Calendar.current
            let components = calendar.dateComponents([.weekOfYear], from: currentWeekStart, to: weekStart)
            weekOffset = components.weekOfYear ?? 0

            #if DEBUG
            print("📍 Initial week: \(weekStart), offset: \(weekOffset)")
            #endif
            requestDataLoad(for: weekStart, reason: "initial-load")
        }
        .onChange(of: diaryDataManager.dataReloadTrigger) {
            // Only reload if we've already done initial load
            guard hasInitiallyLoaded else { return }
            // CACHE INVALIDATION: Clear cache for changed date
            Task {
                await vm.invalidateCache(for: selectedDate)
            }
            requestDataLoad(for: selectedWeekStart, reason: "data-change")
        }
        .refreshable {
            requestDataLoad(for: selectedWeekStart, reason: "pull-to-refresh")
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { gesture in
                    let horizontalMovement = gesture.translation.width
                    if abs(horizontalMovement) > abs(gesture.translation.height) {
                        // Horizontal swipe detected
                        if horizontalMovement < 0 {
                            // Swipe left - next week
                            weekOffset += 1
                            requestDataLoad(reason: "swipe-left")
                        } else {
                            // Swipe right - previous week
                            weekOffset -= 1
                            requestDataLoad(reason: "swipe-right")
                        }
                    }
                }
        )
        .onReceive(NotificationCenter.default.publisher(for: .foodDiaryUpdated)) { _ in
            // Only reload if we've already done initial load
            guard hasInitiallyLoaded else { return }
            // CACHE INVALIDATION: Clear cache for changed date, then reload
            Task {
                await vm.invalidateCache(for: selectedDate)
                // Now request data reload after cache is invalidated
                await MainActor.run {
                    requestDataLoad(for: selectedWeekStart, reason: "diary-updated-notification")
                }
            }
        }
        .onDisappear {
            // Cancel any in-flight tasks FIRST
            vm.cancelLoading()

            // Clear large data structures to free memory
            // Note: We clear arrays immediately, but cache cleanup is async
            vm.rhythmDays = []
            vm.nutrientCoverageRows = []

            // Clear cache asynchronously (safe because it's actor-isolated)
            Task {
                await vm.clearCache()
            }

            // Reset flag for next appearance
            hasInitiallyLoaded = false

            #if DEBUG
            print("🧹 Nutrients tab cleanup: cancelled tasks, cleared data and scheduled cache cleanup")
            #endif
        }
        .sheet(isPresented: $showingGaps) {
            if #available(iOS 16.0, *) {
                NutrientGapsView(rows: vm.nutrientCoverageRows)
            } else {
                Text("Nutrient gaps requires iOS 16.0 or later")
            }
        }
        .sheet(item: $selectedNutrientRow) { row in
            if #available(iOS 16.0, *) {
                NutrientDetailModal(row: row)
            } else {
                Text(row.name)
            }
        }
    }

    // MARK: - Week Navigation Header

    @ViewBuilder
    private var weekNavigationHeader: some View {
        VStack(spacing: 12) {
            // Week range display - stretched across the top
            Button(action: {
                showCalendar.toggle()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .medium))
                    Text(formatWeekRange())
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding(.horizontal, 20)

            // Calendar picker (when expanded)
            if showCalendar {
                DatePicker(
                    "Select Date",
                    selection: Binding(
                        get: { selectedWeekStart },
                        set: { newDate in
                            selectedWeekStart = newDate
                            selectedDate = newDate // Update main diary date
                            updateWeekOffsetFromDate(newDate)
                            showCalendar = false
                            requestDataLoad(for: newDate, reason: "calendar-selection")
                        }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .labelsHidden()
                .padding(.horizontal, 20)
                .transition(.opacity)
            }

            // Week navigation buttons
            HStack(spacing: 12) {
                // Previous week button
                Button(action: {
                    weekOffset -= 1
                    loadWeekData()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Previous")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#5856D6"))
                    .cornerRadius(10)
                }

                // This week button (always visible)
                Button(action: {
                    weekOffset = 0
                    loadWeekData()
                    selectedDate = Date()  // Set calendar to today AFTER loading week data
                }) {
                    Text("This Week")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#3FD17C"), Color(hex: "#57A5FF")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(10)
                }

                // Next week button
                Button(action: {
                    weekOffset += 1
                    loadWeekData()
                }) {
                    HStack(spacing: 4) {
                        Text("Next")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#5856D6"))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Rhythm Section

    @ViewBuilder
    private var rhythmSection: some View {
        VStack(spacing: 0) {
            // Premium header with context
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#3FD17C"), Color(hex: "#57A5FF")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Your Nutrient Overview")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()
                }

                Text("Last 7 days of nutrient coverage")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)

                // Clear legend with labels
                HStack(spacing: 16) {
                    legendItem(color: Color(hex: "#3FD17C"), label: "Strong")
                    legendItem(color: Color(hex: "#FFA93A"), label: "Moderate")
                    legendItem(color: Color(hex: "#57A5FF"), label: "Low")
                    legendItem(color: Color(hex: "#CFCFCF"), label: "None")
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            // Enhanced rhythm visualization
            VStack(spacing: 16) {
                // Rhythm bar with enhanced context
                HStack(spacing: 0) {
                    ForEach(vm.rhythmDays, id: \.date) { day in
                        let isToday = Calendar.current.isDateInToday(day.date)
                        rhythmColumn(day: day, isToday: isToday)
                    }
                }
                .padding(.horizontal, 20)
                .frame(height: 100)

                // Week summary stats
                weekSummaryStats
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 24)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                )

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    private var weekSummaryStats: some View {
        HStack(spacing: 20) {
            let daysLogged = vm.rhythmDays.filter { $0.level != .none }.count
            let strongDays = vm.rhythmDays.filter { $0.level == .strong }.count

            statPill(icon: "calendar", value: "\(daysLogged)", label: "Days logged", color: Color(hex: "#57A5FF"))
            statPill(icon: "checkmark.circle.fill", value: "\(strongDays)", label: "Strong days", color: Color(hex: "#3FD17C"))

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private func statPill(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
        )
    }

    private func rhythmColumn(day: RhythmDay, isToday: Bool) -> some View {
        VStack(spacing: 6) {
            // Date label on top
            Text(vm.shortDateLabel(day.date))
                .font(.system(size: 11, weight: isToday ? .bold : .medium))
                .foregroundColor(isToday ? .primary : .secondary)
                .frame(height: 16)

            Spacer()

            // Enhanced column with gradient
            ZStack(alignment: .bottom) {
                // Background track
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(height: 56)

                // Colored bar
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [day.level.color.opacity(0.8), day.level.color],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: heightForLevel(day.level))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(
                        color: isToday ? day.level.color.opacity(0.4) : Color.clear,
                        radius: isToday ? 10 : 0,
                        x: 0,
                        y: isToday ? 4 : 0
                    )

                // Today indicator
                if isToday {
                    VStack {
                        Image(systemName: "circlebadge.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.white)
                            .padding(4)
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: day.level)
        }
    }

    private func heightForLevel(_ level: SourceLevel) -> CGFloat {
        switch level {
        case .strong: return 56
        case .moderate: return 40
        case .trace: return 24
        case .none: return 8
        }
    }

    struct ScaleButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
        }
    }

    // MARK: - Coverage Map Section

    @ViewBuilder
    private var coverageMapSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#3FD17C"), Color(hex: "#FFA93A")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Nutrient Details")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                Text("\(vm.nutrientCoverageRows.count)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(.secondarySystemBackground))
                    )
            }
            .padding(.horizontal, 20)

            if vm.nutrientCoverageRows.isEmpty {
                emptyState
            } else {
                VStack(spacing: 12) {
                    ForEach(vm.nutrientCoverageRows, id: \.id) { row in
                        coverageRow(row)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func coverageRow(_ row: CoverageRow) -> some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            selectedNutrientRow = row
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(row.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Spacer()

                    HStack(spacing: 8) {
                        statusBadge(row.status)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }

                // Enhanced 7-day bar with labels
                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        ForEach(row.segments, id: \.date) { seg in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            (seg.level?.color ?? Color(.systemGray5)).opacity(0.8),
                                            seg.level?.color ?? Color(.systemGray5)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }

                    // Day labels
                    HStack(spacing: 4) {
                        ForEach(row.segments, id: \.date) { seg in
                            Text(shortDayLabel(seg.date))
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func shortDayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        let full = formatter.string(from: date)
        return String(full.prefix(1))
    }

    private func statusBadge(_ status: CoverageStatus) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 6, height: 6)

            Text(status.rawValue)
                .font(.system(size: 12, weight: .bold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(status.color.opacity(0.12))
        )
        .overlay(
            Capsule()
                .stroke(status.color.opacity(0.3), lineWidth: 1)
        )
        .foregroundColor(status.color)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No logged foods this week")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            Text("Add entries to reveal your rhythm")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Helper Functions

    /// Single entry point for all data load requests
    /// Consolidates all triggers to prevent duplicate loads and provide unified logging
    private func requestDataLoad(for targetDate: Date? = nil, reason: String) {
        Task {
            let calendar = Calendar.current

            // If no target date provided, use week offset to calculate it
            let dateToLoad: Date
            if let targetDate = targetDate {
                dateToLoad = targetDate
            } else {
                // Calculate based on week offset
                dateToLoad = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: Date()) ?? Date()
            }

            // Get the Monday of that week
            let (weekStart, _) = getWeekRange(for: dateToLoad)
            selectedWeekStart = weekStart
            // DON'T modify parent selectedDate - let user control calendar independently

            #if DEBUG
            print("🔄 requestDataLoad - reason: \(reason), weekStart: \(weekStart)")

            // Load data for that week
            #endif
            await vm.loadWeekData(for: weekStart)
        }
    }

    /// Legacy wrapper for backward compatibility
    private func loadWeekData() {
        requestDataLoad(reason: "offset-based-navigation")
    }

    private func formatWeekRange() -> String {
        let calendar = Calendar.current
        let (weekStart, weekEnd) = getWeekRange(for: selectedWeekStart)

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let startStr = formatter.string(from: weekStart)

        let startMonth = calendar.component(.month, from: weekStart)
        let endMonth = calendar.component(.month, from: weekEnd)

        if startMonth == endMonth {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "d"
            return "\(startStr) - \(dayFormatter.string(from: weekEnd))"
        } else {
            let endStr = formatter.string(from: weekEnd)
            return "\(startStr) - \(endStr)"
        }
    }

    private func updateWeekOffsetFromDate(_ date: Date) {
        let calendar = Calendar.current
        let today = Date()

        let (currentWeekStart, _) = getWeekRange(for: today)
        let (selectedWeek, _) = getWeekRange(for: date)

        // Calculate weeks difference
        let components = calendar.dateComponents([.weekOfYear], from: currentWeekStart, to: selectedWeek)
        weekOffset = components.weekOfYear ?? 0
    }

    private func getWeekRange(for date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current

        // Get the day of the week (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
        let weekday = calendar.component(.weekday, from: date)

        // Calculate offset to Monday (weekday 2)
        let daysFromMonday = (weekday == 1) ? -6 : 2 - weekday

        // Get Monday of the week
        guard let monday = calendar.date(byAdding: .day, value: daysFromMonday, to: date) else {
            return (date, date)
        }

        // Get Sunday (6 days after Monday)
        guard let sunday = calendar.date(byAdding: .day, value: 6, to: monday) else {
            return (monday, monday)
        }

        return (calendar.startOfDay(for: monday), calendar.startOfDay(for: sunday))
    }
}

// MARK: - View Model

@available(iOS 16.0, *)
@MainActor
final class CategoricalNutrientViewModel: ObservableObject {
    @Published var rhythmDays: [RhythmDay] = []
    @Published var nutrientCoverageRows: [CoverageRow] = []
    @Published var isLoading: Bool = false

    private var loadTask: Task<Void, Never>?
    private let profileCache = NutrientCacheActor()
    private let diaryCache = DiaryCacheActor() // NEW: Cache for diary food data per day
    private let weekCache = WeekDataCache() // NEW: Cache for processed week data
    private var currentLoadingDate: Date?
    weak var diaryManager: DiaryDataManager?
    private var versionChangeObserver: NSObjectProtocol?

    init() {
        // Listen for app version changes to clear caches
        versionChangeObserver = NotificationCenter.default.addObserver(
            forName: .appVersionDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.clearCache()
                #if DEBUG
                print("🗑️ CategoricalNutrientViewModel: Cleared caches due to app version change")
                #endif
            }
        }
    }

    deinit {
        if let observer = versionChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func setDiaryManager(_ manager: DiaryDataManager) {
        self.diaryManager = manager
    }

    func cancelLoading() {
        loadTask?.cancel()
        loadTask = nil
        currentLoadingDate = nil
        isLoading = false
    }

    func clearCache() async {
        await profileCache.clear()
        await diaryCache.clear()
        await weekCache.clear()
    }

    // NEW: Invalidate cache for a specific date
    func invalidateCache(for date: Date) async {
        await diaryCache.invalidate(date: date)
        await weekCache.invalidate(containingDate: date)
        #if DEBUG
        print("🗑️ Invalidated cache for date: \(date)")
        #endif
    }

    // MARK: - Cache Conversion Helpers

    private func convertToCache(_ level: SourceLevel) -> CachedSourceLevel {
        switch level {
        case .none: return .none
        case .trace: return .trace
        case .moderate: return .moderate
        case .strong: return .strong
        }
    }

    private func convertFromCache(_ level: CachedSourceLevel) -> SourceLevel {
        switch level {
        case .none: return .none
        case .trace: return .trace
        case .moderate: return .moderate
        case .strong: return .strong
        }
    }

    private func convertToCache(rhythmDays: [RhythmDay]) -> [CachedRhythmDay] {
        rhythmDays.map { CachedRhythmDay(date: $0.date, level: convertToCache($0.level)) }
    }

    private func convertFromCache(rhythmDays: [CachedRhythmDay]) -> [RhythmDay] {
        rhythmDays.map { RhythmDay(date: $0.date, level: convertFromCache($0.level)) }
    }

    private func convertToCache(coverageRows: [CoverageRow]) -> [CachedCoverageRow] {
        coverageRows.map { row in
            let cachedSegments = row.segments.map { segment in
                CachedSegment(
                    date: segment.date,
                    level: segment.level.map { convertToCache($0) },
                    foods: segment.foods
                )
            }
            return CachedCoverageRow(
                id: row.id,
                name: row.name,
                status: String(describing: row.status),
                segments: cachedSegments
            )
        }
    }

    private func convertFromCache(coverageRows: [CachedCoverageRow]) -> [CoverageRow] {
        coverageRows.map { cachedRow in
            let segments = cachedRow.segments.map { cachedSegment in
                Segment(
                    date: cachedSegment.date,
                    level: cachedSegment.level.map { convertFromCache($0) },
                    foods: cachedSegment.foods
                )
            }
            let status: CoverageStatus = {
                switch cachedRow.status {
                case "consistent": return .consistent
                case "occasional": return .occasional
                default: return .missing
                }
            }()
            return CoverageRow(
                id: cachedRow.id,
                name: cachedRow.name,
                status: status,
                segments: segments
            )
        }
    }

    // Load last 7 days of rhythm and coverage data
    func loadLast7Days() async {
        // Calls the new loadWeekData with today's date for backward compatibility
        await loadWeekData(for: Date())
    }

    // Load specific week's data starting from the given Monday
    func loadWeekData(for weekStartDate: Date) async {
        let calendar = Calendar.current

        // Calculate the Monday of the week to normalize date comparison
        let weekday = calendar.component(.weekday, from: weekStartDate)
        let daysFromMonday = (weekday == 1) ? -6 : 2 - weekday
        guard let monday = calendar.date(byAdding: .day, value: daysFromMonday, to: weekStartDate) else {
            #if DEBUG
            print("❌ Failed to calculate Monday")
            #endif
            return
        }
        let mondayStart = calendar.startOfDay(for: monday)

        // Prevent duplicate loads for the same week
        if let currentDate = currentLoadingDate, calendar.isDate(currentDate, equalTo: mondayStart, toGranularity: .day) {
            #if DEBUG
            print("⚠️ Already loading data for this week, skipping duplicate request")
            #endif
            return
        }

        // Cancel any existing load task and wait for it to complete
        loadTask?.cancel()
        loadTask = nil

        // Guard against concurrent loads
        guard !isLoading else {
            #if DEBUG
            print("⚠️ Already loading data, skipping duplicate request")
            #endif
            return
        }

        // Verify manager exists before proceeding
        guard diaryManager != nil else {
            #if DEBUG
            print("❌ DiaryManager not set")
            #endif
            self.rhythmDays = []
            self.nutrientCoverageRows = []
            return
        }

        isLoading = true
        currentLoadingDate = mondayStart

        #if DEBUG
        print("🔄 CategoricalNutrientViewModel: Starting loadWeekData for \(mondayStart)...")

        // Create properly cancellable task (NOT detached)
        #endif
        loadTask = Task { @MainActor in
            defer {
                self.isLoading = false
                self.currentLoadingDate = nil
            }

            // CACHE CHECK: Try week cache first
            if let cachedWeekData = await self.weekCache.getData(for: mondayStart) {
                #if DEBUG
                print("✅ [WeekCache] HIT - Using cached week data")
                #endif
                self.rhythmDays = self.convertFromCache(rhythmDays: cachedWeekData.rhythmDays)
                self.nutrientCoverageRows = self.convertFromCache(coverageRows: cachedWeekData.coverageRows)
                return
            }
            #if DEBUG
            print("⚠️ [WeekCache] MISS - Fetching fresh data")

            // Perform heavy processing on background thread but maintain cancellation context
            #endif
            let result: (days: [RhythmDay], rows: [CoverageRow])? = await Task {
                // Generate 7 days starting from Monday
                let dates = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: mondayStart) }

                // PERFORMANCE FIX: Use single batch Firebase query instead of 7 individual calls
                var allEntries: [FoodEntry] = []

                // Check for task cancellation
                if Task.isCancelled {
                    #if DEBUG
                    print("⚠️ Task cancelled during data fetch")
                    #endif
                    return nil
                }

                // Calculate week end date (Sunday 23:59:59)
                guard let weekEndDate = calendar.date(byAdding: .day, value: 6, to: mondayStart),
                      let weekEndWithTime = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: weekEndDate) else {
                    return nil
                }

                // BATCH QUERY: Single Firebase call for entire week
                do {
                    #if DEBUG
                    print("🚀 [BatchQuery] Fetching week \(mondayStart) to \(weekEndWithTime) in single query")
                    #endif
                    allEntries = try await FirebaseManager.shared.getFoodEntriesInRange(from: mondayStart, to: weekEndWithTime)
                    #if DEBUG
                    print("✅ [BatchQuery] Fetched \(allEntries.count) entries in 1 Firebase call (vs 7 calls before)")
                    #endif
                } catch {
                    #if DEBUG
                    print("⚠️ Error fetching week data: \(error)")
                    #endif
                    allEntries = []
                }

                #if DEBUG
                print("📥 Total entries fetched: \(allEntries.count) for week starting \(mondayStart)")

                #endif
                let entries = allEntries
                let grouped = Dictionary(grouping: entries, by: { calendar.startOfDay(for: $0.date) })

                // Get all food IDs that need profiles
                let allFoodIds = entries.map { $0.foodName }

                // Fetch cached profiles from actor
                let cachedProfiles = await self.profileCache.getProfiles(forFoodIds: allFoodIds)

                // Track new profiles to cache
                var newProfiles: [String: MicronutrientProfile] = [:]

                // Build rhythm days
                var days: [RhythmDay] = []
                for date in dates {
                    if Task.isCancelled { return nil }

                    let dayEntries = grouped[date] ?? []
                    let level = self.calculateDominantLevel(for: dayEntries, existingCache: cachedProfiles, newCache: &newProfiles)
                    days.append(RhythmDay(date: date, level: level))
                }

                // Check for cancellation before expensive nutrient processing
                if Task.isCancelled {
                    #if DEBUG
                    print("⚠️ Task cancelled before nutrient processing")
                    #endif
                    return nil
                }

                // Build coverage rows
                let nutrients = self.nutrientList()
                var rows: [CoverageRow] = []

                for nutrient in nutrients {
                    if Task.isCancelled { return nil }

                    var segments: [Segment] = []
                    var strongCount = 0
                    var loggedDays = 0

                    for date in dates {
                        let dayEntries = grouped[date] ?? []
                        if !dayEntries.isEmpty {
                            loggedDays += 1
                            let level = self.highestLevel(for: nutrient.id, entries: dayEntries, existingCache: cachedProfiles, newCache: &newProfiles)
                            if level == .strong { strongCount += 1 }
                            let foods = self.contributingFoods(for: nutrient.id, entries: dayEntries, existingCache: cachedProfiles, newCache: &newProfiles)
                            segments.append(Segment(date: date, level: level == .none ? nil : level, foods: foods.isEmpty ? nil : foods))
                        } else {
                            segments.append(Segment(date: date, level: nil, foods: nil))
                        }
                    }

                    // Calculate status
                    let ratioStrong = loggedDays > 0 ? Double(strongCount) / Double(loggedDays) : 0
                    let status: CoverageStatus = ratioStrong >= 0.7 ? .consistent : (ratioStrong >= 0.3 ? .occasional : .missing)

                    rows.append(CoverageRow(id: nutrient.id, name: nutrient.name, status: status, segments: segments))
                }

                // Save new profiles to cache
                if !newProfiles.isEmpty {
                    await self.profileCache.setProfiles(newProfiles)
                    #if DEBUG
                    print("💾 Cached \(newProfiles.count) new profiles (total cache size: \(await self.profileCache.size()))")
                    #endif
                }

                return (days, rows)
            }.value

            // Update UI on main thread (we're already on MainActor due to @MainActor annotation)
            if Task.isCancelled {
                #if DEBUG
                print("⚠️ Task cancelled before UI update")
                #endif
                return
            }

            if let result = result {
                self.rhythmDays = result.days
                self.nutrientCoverageRows = result.rows
                #if DEBUG
                print("✅ Loaded \(result.days.count) rhythm days and \(result.rows.count) nutrient rows")

                // CACHE STORE: Save processed week data to cache for future loads
                #endif
                await self.weekCache.setData(
                    rhythmDays: self.convertToCache(rhythmDays: result.days),
                    coverageRows: self.convertToCache(coverageRows: result.rows),
                    for: mondayStart
                )
            } else {
                self.rhythmDays = []
                self.nutrientCoverageRows = []
            }
        }
    }

    // MARK: - Adaptive Insight Generation

    func generateAdaptiveInsight() -> String? {
        // Calculate data sufficiency metrics
        let totalMeals = calculateTotalMealsLogged()
        let daysWithData = rhythmDays.filter { $0.level != .none }.count

        // Determine if we have sufficient data (minimum 5 meals across 3+ days)
        let hasSufficientData = totalMeals >= 5 && daysWithData >= 3

        // Analyze coverage
        let missing = nutrientCoverageRows.filter { $0.status == .missing }
        let occasional = nutrientCoverageRows.filter { $0.status == .occasional }
        let consistent = nutrientCoverageRows.filter { $0.status == .consistent }

        // TIER 1: No data at all
        if totalMeals == 0 {
            return "As you log more meals, your nutrient trends will start to appear here."
        }

        // TIER 2: Some data but below threshold (1-4 meals or fewer than 3 days)
        if !hasSufficientData {
            // Check if we can detect any weak nutrients even with limited data
            if !missing.isEmpty || !occasional.isEmpty {
                let weakNutrients = (missing + occasional).prefix(2).map { $0.name }.joined(separator: " and ")
                return "Based on your recent meals, \(weakNutrients) appear lower than others — keep logging to confirm."
            } else if totalMeals >= 2 {
                // Has some data but looking good so far
                return "Good start — log \(5 - totalMeals) more meals to reveal your full nutrient rhythm."
            } else {
                // Very minimal data (1 meal)
                return "As you log more meals, your nutrient trends will start to appear here."
            }
        }

        // TIER 3: Sufficient data — use standard contextual insight logic

        // Priority 1: Multiple missing nutrients (3+)
        if missing.count >= 3 {
            let names = missing.prefix(3).map { $0.name }.joined(separator: ", ")
            return "Your entries show consistently low \(names) — tap to uncover all lows."
        }

        // Priority 2: 1-2 missing nutrients
        if missing.count >= 1 {
            let names = missing.prefix(2).map { $0.name }
            if missing.count == 1 {
                return "Your entries are missing \(names[0]) this week — see what's causing it."
            } else {
                return "Your entries are missing \(names.joined(separator: " and ")) — tap to see contributing foods."
            }
        }

        // Priority 3: Several occasional nutrients (day-to-day variation)
        if occasional.count >= 3 {
            let names = occasional.prefix(3).map { $0.name }.joined(separator: ", ")
            return "These vary day-to-day: \(names) — tap for daily breakdown."
        }

        // Priority 4: Mostly strong coverage
        if consistent.count >= nutrientCoverageRows.count * 70 / 100 {
            let percentage = (consistent.count * 100) / max(1, nutrientCoverageRows.count)
            if percentage >= 90 {
                return "Excellent nutrient coverage this week — \(consistent.count) of \(nutrientCoverageRows.count) nutrients strong."
            } else {
                return "Strong coverage across most nutrients — great consistency this week."
            }
        }

        // Priority 5: Mixed results
        if occasional.count >= 2 {
            return "Some nutrients fluctuate — tap to see which ones need more consistency."
        }

        // Default: Encouraging message
        if daysWithData >= 5 {
            return "You're building a solid nutrient rhythm — keep it up this week."
        } else {
            return "Off to a good start — continue logging to strengthen your rhythm."
        }
    }

    // MARK: - Data Sufficiency Calculation

    private func calculateTotalMealsLogged() -> Int {
        var mealCount = 0

        for day in rhythmDays {
            if day.level != .none {
                // Count how many meals this day has by checking coverage rows
                // Each row segment represents foods logged that day
                // We'll estimate meals by checking if there's food data for this day
                let hasData = nutrientCoverageRows.contains { row in
                    row.segments.contains { segment in
                        Calendar.current.isDate(segment.date, inSameDayAs: day.date) && segment.level != nil
                    }
                }
                if hasData {
                    // Estimate: if a day has nutrient data, count it as having at least 1 meal
                    // For more accuracy, we could count unique food entries
                    mealCount += 1
                }
            }
        }

        // More accurate: count unique food entries across all segments
        var uniqueFoods = Set<String>()
        for row in nutrientCoverageRows {
            for segment in row.segments {
                if let foods = segment.foods {
                    uniqueFoods.formUnion(foods)
                }
            }
        }

        // Use the higher of the two estimates (foods count is more accurate)
        return max(mealCount, min(uniqueFoods.count, 30)) // Cap at 30 to prevent over-counting
    }

    // MARK: - Helper Functions

    func shortDateLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    nonisolated private func calculateDominantLevel(for entries: [FoodEntry], existingCache: [String: MicronutrientProfile], newCache: inout [String: MicronutrientProfile]) -> SourceLevel {
        guard !entries.isEmpty else { return .none }

        var strongCount = 0
        var moderateCount = 0
        var traceCount = 0

        let nutrients = nutrientList()
        for nutrient in nutrients {
            let level = highestLevel(for: nutrient.id, entries: entries, existingCache: existingCache, newCache: &newCache)
            switch level {
            case .strong: strongCount += 1
            case .moderate: moderateCount += 1
            case .trace: traceCount += 1
            case .none: break
            }
        }

        // Return dominant level
        if strongCount >= moderateCount && strongCount >= traceCount && strongCount > 0 {
            return .strong
        } else if moderateCount >= traceCount && moderateCount > 0 {
            return .moderate
        } else if traceCount > 0 {
            return .trace
        }
        return .none
    }

    nonisolated private func highestLevel(for nutrientId: String, entries: [FoodEntry], existingCache: [String: MicronutrientProfile], newCache: inout [String: MicronutrientProfile]) -> SourceLevel {
        var best: SourceLevel = .none
        // Convert nutrient ID to MicronutrientProfile key format
        let profileKey = nutrientIdToProfileKey(nutrientId)

        // Debug logging for Vitamin C only
        let isVitC = nutrientId.lowercased().contains("vitamin_c") || nutrientId.lowercased().contains("vitaminc")

        for entry in entries {
            // IMPORTANT: Recalculate micronutrient profile with improved estimation
            // This ensures old entries get the new, more accurate multipliers
            let freshProfile = recalculateMicronutrientProfile(for: entry, existingCache: existingCache, newCache: &newCache)

            // Try to find the nutrient in vitamins or minerals using the converted key
            if let amt = freshProfile.vitamins[profileKey] ?? freshProfile.minerals[profileKey] {
                let level = classify(amount: amt, key: profileKey, profile: freshProfile)
                best = max(best, level)

                if isVitC {
                    #if DEBUG
                    print("   🔍 \(entry.foodName): amt=\(String(format: "%.1f", amt))mg, level=\(level)")
                    #endif
                }
            } else {
                // Fallback: use keyword detection
                let food = DiaryFoodItem.fromFoodEntry(entry)
                let present = NutrientDetector.detectNutrients(in: food).contains(nutrientId)
                best = max(best, present ? .trace : .none)

                if isVitC {
                    #if DEBUG
                    print("   ⚠️ \(entry.foodName): NO AMOUNT in profile (profileKey=\(profileKey))")
                    #endif
                }
            }
        }

        return best
    }

    nonisolated private func contributingFoods(for nutrientId: String, entries: [FoodEntry], existingCache: [String: MicronutrientProfile], newCache: inout [String: MicronutrientProfile]) -> [String] {
        var names: [String] = []
        // Convert nutrient ID to MicronutrientProfile key format
        let profileKey = nutrientIdToProfileKey(nutrientId)

        for entry in entries {
            // IMPORTANT: Recalculate micronutrient profile with improved estimation
            let freshProfile = recalculateMicronutrientProfile(for: entry, existingCache: existingCache, newCache: &newCache)

            // Try to find the nutrient in vitamins or minerals using the converted key
            if let amt = freshProfile.vitamins[profileKey] ?? freshProfile.minerals[profileKey],
               classify(amount: amt, key: profileKey, profile: freshProfile) != .none {
                names.append(entry.foodName)
            } else {
                // Fallback: use keyword detection
                let food = DiaryFoodItem.fromFoodEntry(entry)
                if NutrientDetector.detectNutrients(in: food).contains(nutrientId) {
                    names.append(entry.foodName)
                }
            }
        }
        return names
    }

    nonisolated private func classify(amount: Double, key: String, profile: MicronutrientProfile) -> SourceLevel {
        if amount <= 0 { return .none }
        let dvKey = dvKey(for: key)

        // Debug logging for Vitamin C only
        let isVitC = key.lowercased().contains("vitaminc")

        if let percent = profile.getDailyValuePercentage(for: dvKey, amount: amount) {
            if isVitC {
                #if DEBUG
                print("      📊 classify: amount=\(String(format: "%.1f", amount))mg, percent=\(String(format: "%.1f", percent))%")
                #endif
            }

            if percent >= 70 { return .strong }
            if percent >= 30 { return .moderate }
            return .trace
        }

        if isVitC {
            #if DEBUG
            print("      ❌ classify: NO DAILY VALUE found for dvKey=\(dvKey)")
            #endif
        }

        return .trace
    }

    /// Converts NutrientDatabase ID format to MicronutrientProfile key format
    /// e.g., "vitamin_c" -> "vitaminC", "vitamin_b1" -> "thiamine"
    nonisolated private func nutrientIdToProfileKey(_ nutrientId: String) -> String {
        switch nutrientId.lowercased() {
        // Vitamins - convert underscore format to camelCase
        case "vitamin_c": return "vitaminC"
        case "vitamin_d": return "vitaminD"
        case "vitamin_a": return "vitaminA"
        case "vitamin_e": return "vitaminE"
        case "vitamin_k": return "vitaminK"
        case "vitamin_b1": return "thiamine"
        case "vitamin_b2": return "riboflavin"
        case "vitamin_b3": return "niacin"
        case "vitamin_b5": return "pantothenicAcid"
        case "vitamin_b6": return "vitaminB6"
        case "vitamin_b7", "biotin": return "biotin"
        case "vitamin_b9", "folate": return "folate"
        case "vitamin_b12": return "vitaminB12"
        case "choline": return "choline"

        // Minerals - already lowercase in both places
        case "calcium": return "calcium"
        case "iron": return "iron"
        case "magnesium": return "magnesium"
        case "phosphorus": return "phosphorus"
        case "potassium": return "potassium"
        case "sodium": return "sodium"
        case "zinc": return "zinc"
        case "copper": return "copper"
        case "manganese": return "manganese"
        case "selenium": return "selenium"
        case "chromium": return "chromium"
        case "molybdenum": return "molybdenum"
        case "iodine": return "iodine"

        default: return nutrientId.lowercased()
        }
    }

    /// Gets daily value key for RecommendedIntakes lookup
    nonisolated private func dvKey(for key: String) -> String {
        // MicronutrientProfile keys use camelCase for vitamins
        // But RecommendedIntakes.getDailyValue uses both camelCase and underscore
        // Let's check what the profile key is and return the appropriate DV key
        switch key.lowercased() {
        case "vitaminc": return "vitaminC"
        case "vitamina": return "vitaminA"
        case "vitamind": return "vitaminD"
        case "vitamine": return "vitaminE"
        case "vitamink": return "vitaminK"
        case "thiamine": return "thiamine"
        case "riboflavin": return "riboflavin"
        case "niacin": return "niacin"
        case "pantothenicacid": return "pantothenicAcid"
        case "vitaminb6": return "vitaminB6"
        case "biotin": return "biotin"
        case "folate": return "folate"
        case "vitaminb12": return "vitaminB12"
        case "choline": return "choline"
        default: return key.lowercased()
        }
    }

    nonisolated private func nutrientList() -> [NutrientItem] {
        NutrientDatabase.allNutrients
            .filter { nut in
                let id = nut.id.lowercased()
                let name = nut.name.lowercased()
                return !(id.contains("omega3") || id.contains("omega_3") || name.contains("omega-3") || name.contains("omega 3"))
            }
            .map { NutrientItem(id: $0.id, name: $0.name) }
    }

    /// Recalculates micronutrient profile for an entry using improved estimation
    /// This fixes old entries that were saved with inaccurate estimates
    /// IMPORTANT: Only estimates for foods WITH actual data (ingredients or micronutrient profile)
    nonisolated private func recalculateMicronutrientProfile(for entry: FoodEntry, existingCache: [String: MicronutrientProfile], newCache: inout [String: MicronutrientProfile]) -> MicronutrientProfile {
        // Check cache first (existing cache from actor, then new cache from this session)
        let cacheKey = "\(entry.id)_\(entry.servingSize)"

        if let cached = existingCache[cacheKey] {
            return cached
        }

        if let cached = newCache[cacheKey] {
            return cached
        }

        // CRITICAL FIX: If food has no actual micronutrient data AND no ingredients,
        // return an empty profile instead of estimating from macros (which creates false positives)
        let hasActualMicronutrientData = entry.micronutrientProfile != nil
        let hasIngredients = entry.ingredients != nil && !entry.ingredients!.isEmpty

        if !hasActualMicronutrientData && !hasIngredients {
            // Return empty profile - don't estimate from macros alone
            let emptyProfile = MicronutrientProfile(
                vitamins: [:],
                minerals: [:],
                recommendedIntakes: RecommendedIntakes(age: 30, gender: .other, dailyValues: [:]),
                confidenceScore: .low
            )
            newCache[cacheKey] = emptyProfile
            return emptyProfile
        }

        // If the food already has a micronutrient profile, use it (scaled by serving size)
        if let existingProfile = entry.micronutrientProfile {
            // The profile is already for the logged serving size, use as-is
            newCache[cacheKey] = existingProfile
            return existingProfile
        }

        // FoodEntry stores TOTAL values for the serving, but FoodSearchResult expects per-100g values
        // Need to convert back to per-100g baseline
        let servingSize = entry.servingSize
        let multiplier = servingSize / 100.0

        // Convert total values back to per-100g
        let per100gCalories = multiplier > 0 ? entry.calories / multiplier : entry.calories
        let per100gProtein = multiplier > 0 ? entry.protein / multiplier : entry.protein
        let per100gCarbs = multiplier > 0 ? entry.carbohydrates / multiplier : entry.carbohydrates
        let per100gFat = multiplier > 0 ? entry.fat / multiplier : entry.fat
        let per100gFiber = multiplier > 0 ? (entry.fiber ?? 0) / multiplier : (entry.fiber ?? 0)
        let per100gSugar = multiplier > 0 ? (entry.sugar ?? 0) / multiplier : (entry.sugar ?? 0)
        let per100gSodium = multiplier > 0 ? (entry.sodium ?? 0) / multiplier : (entry.sodium ?? 0)

        // Create a FoodSearchResult with per-100g values
        let foodSearchResult = FoodSearchResult(
            id: entry.id,
            name: entry.foodName,
            brand: entry.brandName,
            calories: per100gCalories,
            protein: per100gProtein,
            carbs: per100gCarbs,
            fat: per100gFat,
            fiber: per100gFiber,
            sugar: per100gSugar,
            sodium: per100gSodium,
            servingDescription: "100g",
            servingSizeG: 100.0,
            ingredients: entry.ingredients,
            isVerified: true,
            micronutrientProfile: nil  // Will estimate based on ingredients
        )

        // Now apply the quantity multiplier to get the actual nutrients consumed
        let profile = MicronutrientManager.shared.getMicronutrientProfile(for: foodSearchResult, quantity: multiplier)

        // Cache the result in new cache (will be merged to actor later)
        newCache[cacheKey] = profile
        return profile
    }
}

// MARK: - Supporting Types

struct RhythmDay {
    let date: Date
    let level: SourceLevel
}

struct NutrientItem {
    let id: String
    let name: String
}

struct CoverageRow: Identifiable, Hashable {
    let id: String
    let name: String
    let status: CoverageStatus
    let segments: [Segment]

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CoverageRow, rhs: CoverageRow) -> Bool {
        lhs.id == rhs.id
    }
}

struct Segment: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let level: SourceLevel?
    let foods: [String]?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Segment, rhs: Segment) -> Bool {
        lhs.id == rhs.id
    }
}

enum SourceLevel: String, Comparable {
    case none = "None"
    case trace = "Low"
    case moderate = "Moderate"
    case strong = "Strong"

    static func < (lhs: SourceLevel, rhs: SourceLevel) -> Bool {
        rank(lhs) < rank(rhs)
    }

    private static func rank(_ level: SourceLevel) -> Int {
        switch level {
        case .none: return 0
        case .trace: return 1
        case .moderate: return 2
        case .strong: return 3
        }
    }

    var color: Color {
        switch self {
        case .strong: return Color(hex: "#3FD17C")
        case .moderate: return Color(hex: "#FFA93A")
        case .trace: return Color(hex: "#57A5FF")
        case .none: return Color(hex: "#CFCFCF")
        }
    }
}

enum CoverageStatus: String {
    case consistent = "Good"
    case occasional = "Variable"
    case missing = "Low"

    var color: Color {
        switch self {
        case .consistent: return Color(hex: "#3FD17C")
        case .occasional: return Color(hex: "#FFA93A")
        case .missing: return Color(hex: "#57A5FF")
        }
    }

    var description: String {
        switch self {
        case .consistent: return "Good coverage this week"
        case .occasional: return "Varies day to day"
        case .missing: return "Could be improved"
        }
    }
}

// MARK: - Nutrient Detail Modal

@available(iOS 16.0, *)
struct NutrientDetailModal: View {
    let row: CoverageRow
    @Environment(\.dismiss) private var dismiss
    @State private var nutrientInfo: NutrientInfo?
    @State private var showingCitations = false

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    // Status card
                    statusCard

                    // Good food sources (from database)
                    if nutrientInfo != nil {
                        goodFoodSourcesSection
                    }

                    // 7-day breakdown
                    weekBreakdown

                    // Contributing foods
                    if !allFoods.isEmpty {
                        foodsSection
                    }
                }
                .padding(20)
            }
            .background(Color.adaptiveBackground)
            .navigationTitle(row.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await loadNutrientInfo()
            }
            .sheet(isPresented: $showingCitations) {
                NavigationView {
                    List {
                        Section(header: Text("Food Sources Data")) {
                            Text("Food sources listed in this app are based on official nutrition databases.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        ForEach([
                            CitationManager.Citation(
                                title: "FoodData Central",
                                organization: "U.S. Department of Agriculture (USDA)",
                                url: "https://fdc.nal.usda.gov/",
                                description: "Official USDA nutrient database providing comprehensive food composition data including vitamins, minerals, and other nutrients.",
                                category: .nutritionData
                            ),
                            CitationManager.Citation(
                                title: "UK Composition of Foods Integrated Dataset (CoFID)",
                                organization: "UK Food Standards Agency & Public Health England",
                                url: "https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid",
                                description: "UK's official database of nutrient content in foods, providing comprehensive nutrition data for British food products.",
                                category: .nutritionData
                            )
                        ]) { citation in
                            Button(action: {
                                if let url = URL(string: citation.url) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "doc.text.fill")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 14))
                                        Text(citation.organization)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "arrow.up.right.square")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                    Text(citation.title)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Text(citation.description)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(3)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .navigationTitle("Official Sources")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingCitations = false
                            }
                        }
                    }
                }
            }
        }
    }

    private var statusCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("This Week's Status")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    HStack(spacing: 12) {
                        statusBadge(row.status)
                        Text(row.status.description)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    private var weekBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("7-Day Breakdown")
                .font(.system(size: 18, weight: .bold))

            VStack(spacing: 12) {
                ForEach(row.segments, id: \.date) { segment in
                    HStack {
                        Text(fullDateLabel(segment.date))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 100, alignment: .leading)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(segment.level?.color ?? Color(.systemGray5))
                            .frame(height: 28)
                            .overlay(
                                Text(segment.level?.rawValue ?? "None")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                            )

                        Spacer()

                        if let foods = segment.foods, !foods.isEmpty {
                            Text("\(foods.count)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.secondary)
                                .frame(width: 30)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    private var foodsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contributing Foods")
                .font(.system(size: 18, weight: .bold))

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(allFoods.prefix(10)), id: \.self) { food in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 8, height: 8)

                        Text(food)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }

                if allFoods.count > 10 {
                    Text("+ \(allFoods.count - 10) more")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    private var allFoods: [String] {
        var foods = Set<String>()
        for segment in row.segments {
            if let segmentFoods = segment.foods {
                foods.formUnion(segmentFoods)
            }
        }
        return Array(foods).sorted()
    }

    private func statusBadge(_ status: CoverageStatus) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 6, height: 6)

            Text(status.rawValue)
                .font(.system(size: 12, weight: .bold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(status.color.opacity(0.12))
        )
        .overlay(
            Capsule()
                .stroke(status.color.opacity(0.3), lineWidth: 1)
        )
        .foregroundColor(status.color)
    }

    private func fullDateLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: date)
    }

    // MARK: - Good Food Sources Section

    private var goodFoodSourcesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Good Food Sources")
                .font(.system(size: 18, weight: .bold))

            if let info = nutrientInfo {
                VStack(alignment: .leading, spacing: 12) {
                    let sources = parseArrayContent(info.commonSources)
                    if !sources.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(sources, id: \.self) { source in
                                Text(source)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.blue.opacity(0.1))
                                    )
                            }
                        }
                    } else {
                        Text("No food source information available")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )

                // Citations for food sources - Clickable button
                Button(action: {
                    showingCitations = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.blue)
                        Text("Food sources from USDA FoodData Central and UK CoFID database")
                            .font(.system(size: 11))
                            .foregroundColor(.blue)
                            .lineLimit(2)
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.top, 8)

                // Official Health Claims Section (EFSA/NHS Verbatim)
                if let officialClaims = getOfficialHealthClaims(for: row.name) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                            Text("Official Health Claims")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 24)

                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(officialClaims.enumerated()), id: \.offset) { index, claim in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("•")
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(claim.text)
                                            .font(.system(size: 15))
                                            .foregroundColor(.primary)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Text(claim.source)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.05))
                        )
                    }
                }
            }
        }
    }

    private func loadNutrientInfo() async {
        // Map display name to database ID
        let nutrientId = row.id
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")

        let info = MicronutrientDatabase.shared.getNutrientInfo(nutrientId)
        self.nutrientInfo = info
    }

    private func parseArrayContent(_ content: String?) -> [String] {
        guard let content = content else { return [] }

        // Try to decode as JSON array first
        if let data = content.data(using: .utf8),
           let array = try? JSONDecoder().decode([String].self, from: data) {
            return array.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }

        // Fallback: manually parse array format
        let trimmed = content.trimmingCharacters(in: CharacterSet(charactersIn: "[]\""))
        if trimmed.contains(",") {
            return trimmed
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: " \"")) }
                .filter { !$0.isEmpty }
        }

        // Return as single item if not parseable and not empty
        return trimmed.isEmpty ? [] : [trimmed]
    }

    /// Get official health claims (EFSA/NHS verbatim wording) for a nutrient
    private func getOfficialHealthClaims(for nutrientName: String) -> [HealthClaim]? {
        let name = nutrientName.lowercased()

        if name.contains("vitamin c") || name.contains("ascorbic acid") {
            return [
                HealthClaim(text: "Vitamin C contributes to normal collagen formation for the normal function of blood vessels, bones, cartilage, gums, skin and teeth", source: "EFSA"),
                HealthClaim(text: "Vitamin C contributes to normal function of the immune system", source: "EFSA"),
                HealthClaim(text: "Vitamin C increases iron absorption", source: "EFSA"),
                HealthClaim(text: "Helps protect cells and keep them healthy", source: "NHS")
            ]
        }

        if name.contains("vitamin a") || name.contains("retinol") {
            return [
                HealthClaim(text: "Vitamin A contributes to the maintenance of normal vision", source: "EFSA"),
                HealthClaim(text: "Vitamin A contributes to normal function of the immune system", source: "EFSA"),
                HealthClaim(text: "Vitamin A contributes to the maintenance of normal skin", source: "EFSA"),
                HealthClaim(text: "Important for healthy skin and eyes", source: "NHS")
            ]
        }

        if name.contains("vitamin d") || name.contains("cholecalciferol") {
            return [
                HealthClaim(text: "Vitamin D contributes to normal absorption/utilisation of calcium and phosphorus", source: "EFSA"),
                HealthClaim(text: "Vitamin D contributes to the maintenance of normal bones and teeth", source: "EFSA"),
                HealthClaim(text: "Vitamin D contributes to normal function of the immune system", source: "EFSA"),
                HealthClaim(text: "Helps regulate calcium and phosphate in the body", source: "NHS")
            ]
        }

        if name.contains("vitamin e") || name.contains("tocopherol") {
            return [
                HealthClaim(text: "Vitamin E contributes to the protection of cells from oxidative stress", source: "EFSA"),
                HealthClaim(text: "Helps protect cell membranes", source: "NHS")
            ]
        }

        if name.contains("vitamin k") || name.contains("phylloquinone") {
            return [
                HealthClaim(text: "Vitamin K contributes to normal blood clotting", source: "EFSA"),
                HealthClaim(text: "Vitamin K contributes to the maintenance of normal bones", source: "EFSA"),
                HealthClaim(text: "Needed for blood clotting and wound healing", source: "NHS")
            ]
        }

        if name.contains("vitamin b1") || name.contains("thiamin") {
            return [
                HealthClaim(text: "Thiamin contributes to normal energy-yielding metabolism", source: "EFSA"),
                HealthClaim(text: "Thiamin contributes to normal function of the nervous system", source: "EFSA"),
                HealthClaim(text: "Thiamin contributes to normal psychological function", source: "EFSA"),
                HealthClaim(text: "Helps the body break down and release energy from food", source: "NHS")
            ]
        }

        if name.contains("vitamin b2") || name.contains("riboflavin") {
            return [
                HealthClaim(text: "Riboflavin contributes to normal energy-yielding metabolism", source: "EFSA"),
                HealthClaim(text: "Riboflavin contributes to the maintenance of normal vision", source: "EFSA"),
                HealthClaim(text: "Riboflavin contributes to the reduction of tiredness and fatigue", source: "EFSA"),
                HealthClaim(text: "Helps keep skin, eyes and the nervous system healthy", source: "NHS")
            ]
        }

        if name.contains("vitamin b3") || name.contains("niacin") {
            return [
                HealthClaim(text: "Niacin contributes to normal energy-yielding metabolism", source: "EFSA"),
                HealthClaim(text: "Niacin contributes to normal function of the nervous system", source: "EFSA"),
                HealthClaim(text: "Niacin contributes to the reduction of tiredness and fatigue", source: "EFSA"),
                HealthClaim(text: "Helps the body release energy from food", source: "NHS")
            ]
        }

        if name.contains("vitamin b6") || name.contains("pyridoxine") {
            return [
                HealthClaim(text: "Vitamin B6 contributes to normal protein and glycogen metabolism", source: "EFSA"),
                HealthClaim(text: "Vitamin B6 contributes to normal function of the immune system", source: "EFSA"),
                HealthClaim(text: "Vitamin B6 contributes to the reduction of tiredness and fatigue", source: "EFSA"),
                HealthClaim(text: "Helps the body use and store energy from food", source: "NHS")
            ]
        }

        if name.contains("vitamin b12") || name.contains("cobalamin") {
            return [
                HealthClaim(text: "Vitamin B12 contributes to normal energy-yielding metabolism", source: "EFSA"),
                HealthClaim(text: "Vitamin B12 contributes to normal function of the immune system", source: "EFSA"),
                HealthClaim(text: "Vitamin B12 contributes to the reduction of tiredness and fatigue", source: "EFSA"),
                HealthClaim(text: "Helps make red blood cells and keeps the nervous system healthy", source: "NHS")
            ]
        }

        if name.contains("folate") || name.contains("folic acid") || name.contains("vitamin b9") {
            return [
                HealthClaim(text: "Folate contributes to normal blood formation", source: "EFSA"),
                HealthClaim(text: "Folate contributes to normal function of the immune system", source: "EFSA"),
                HealthClaim(text: "Folate contributes to the reduction of tiredness and fatigue", source: "EFSA"),
                HealthClaim(text: "Helps the body form healthy red blood cells", source: "NHS")
            ]
        }

        if name.contains("calcium") {
            return [
                HealthClaim(text: "Calcium is needed for the maintenance of normal bones and teeth", source: "EFSA"),
                HealthClaim(text: "Calcium contributes to normal blood clotting", source: "EFSA"),
                HealthClaim(text: "Calcium contributes to normal muscle function", source: "EFSA"),
                HealthClaim(text: "Needed for normal growth and development of bone in children", source: "NHS")
            ]
        }

        if name.contains("iron") {
            return [
                HealthClaim(text: "Iron contributes to normal formation of red blood cells and haemoglobin", source: "EFSA"),
                HealthClaim(text: "Iron contributes to normal oxygen transport in the body", source: "EFSA"),
                HealthClaim(text: "Iron contributes to the reduction of tiredness and fatigue", source: "EFSA"),
                HealthClaim(text: "Essential for making red blood cells which carry oxygen around the body", source: "NHS")
            ]
        }

        if name.contains("magnesium") {
            return [
                HealthClaim(text: "Magnesium contributes to normal muscle function", source: "EFSA"),
                HealthClaim(text: "Magnesium contributes to the maintenance of normal bones and teeth", source: "EFSA"),
                HealthClaim(text: "Magnesium contributes to the reduction of tiredness and fatigue", source: "EFSA"),
                HealthClaim(text: "Helps turn food into energy and supports normal muscle function", source: "NHS")
            ]
        }

        if name.contains("zinc") {
            return [
                HealthClaim(text: "Zinc contributes to normal function of the immune system", source: "EFSA"),
                HealthClaim(text: "Zinc contributes to the maintenance of normal skin, hair and nails", source: "EFSA"),
                HealthClaim(text: "Zinc contributes to the protection of cells from oxidative stress", source: "EFSA"),
                HealthClaim(text: "Helps with wound healing and supports the immune system", source: "NHS")
            ]
        }

        if name.contains("potassium") {
            return [
                HealthClaim(text: "Potassium contributes to normal functioning of the nervous system", source: "EFSA"),
                HealthClaim(text: "Potassium contributes to normal muscle function", source: "EFSA"),
                HealthClaim(text: "Potassium contributes to the maintenance of normal blood pressure", source: "EFSA"),
                HealthClaim(text: "Helps control the balance of fluids in the body", source: "NHS")
            ]
        }

        if name.contains("selenium") {
            return [
                HealthClaim(text: "Selenium contributes to normal function of the immune system", source: "EFSA"),
                HealthClaim(text: "Selenium contributes to the protection of cells from oxidative stress", source: "EFSA"),
                HealthClaim(text: "Selenium contributes to the maintenance of normal hair and nails", source: "EFSA"),
                HealthClaim(text: "Helps the immune system work properly", source: "NHS")
            ]
        }

        if name.contains("iodine") {
            return [
                HealthClaim(text: "Iodine contributes to normal production of thyroid hormones and normal thyroid function", source: "EFSA"),
                HealthClaim(text: "Iodine contributes to normal cognitive function", source: "EFSA"),
                HealthClaim(text: "Iodine contributes to normal energy-yielding metabolism", source: "EFSA"),
                HealthClaim(text: "Helps make thyroid hormones which keep cells and metabolic rate healthy", source: "NHS")
            ]
        }

        if name.contains("phosphorus") {
            return [
                HealthClaim(text: "Phosphorus contributes to normal energy-yielding metabolism", source: "EFSA"),
                HealthClaim(text: "Phosphorus contributes to the maintenance of normal bones and teeth", source: "EFSA"),
                HealthClaim(text: "Phosphorus contributes to normal function of cell membranes", source: "EFSA"),
                HealthClaim(text: "Helps build strong bones and teeth", source: "NHS")
            ]
        }

        if name.contains("copper") {
            return [
                HealthClaim(text: "Copper contributes to normal function of the immune system", source: "EFSA"),
                HealthClaim(text: "Copper contributes to the protection of cells from oxidative stress", source: "EFSA"),
                HealthClaim(text: "Copper contributes to normal energy-yielding metabolism", source: "EFSA"),
                HealthClaim(text: "Helps produce red and white blood cells", source: "NHS")
            ]
        }

        if name.contains("manganese") {
            return [
                HealthClaim(text: "Manganese contributes to normal energy-yielding metabolism", source: "EFSA"),
                HealthClaim(text: "Manganese contributes to the maintenance of normal bones", source: "EFSA"),
                HealthClaim(text: "Manganese contributes to the protection of cells from oxidative stress", source: "EFSA"),
                HealthClaim(text: "Helps make and activate some enzymes in the body", source: "NHS")
            ]
        }

        return nil
    }
}

// MARK: - Nutrient Gaps View

@available(iOS 16.0, *)
struct NutrientGapsView: View {
    let rows: [CoverageRow]
    @Environment(\.dismiss) private var dismiss
    @State private var expanded: Set<String> = []

    private var lowRows: [CoverageRow] {
        rows.filter { $0.status == .missing }
    }
    private var variableRows: [CoverageRow] {
        rows.filter { $0.status == .occasional }
    }

    var body: some View {
        NavigationView {
            List {
                if !lowRows.isEmpty {
                    Section(header: sectionHeader(title: "Low This Week", color: Color(hex: "#57A5FF"))) {
                        ForEach(lowRows) { row in
                            nutrientRow(row)
                        }
                    }
                    .transition(.opacity.animation(.easeInOut(duration: 0.25)))
                }

                if !variableRows.isEmpty {
                    Section(header: sectionHeader(title: "Variable Coverage", color: Color(hex: "#FFA93A"))) {
                        ForEach(variableRows) { row in
                            nutrientRow(row)
                        }
                    }
                    .transition(.opacity.animation(.easeInOut(duration: 0.25)))
                }

                if lowRows.isEmpty && variableRows.isEmpty {
                    Text("Great coverage this week — all nutrients looking good!")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                        .listRowSeparator(.hidden)
                }

                // Citations Section
                Section(header: Text("Research Sources").font(.system(size: 14, weight: .semibold))) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nutrient recommendations and health benefits based on:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)

                        ForEach(CitationManager.shared.citations(for: .dailyValues).prefix(3)) { citation in
                            Button(action: {
                                if let url = URL(string: citation.url) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.blue)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(citation.organization)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Text(citation.title)
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.system(size: 12))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Nutrient Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Components

    private func sectionHeader(title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color.opacity(0.9))
                .frame(width: 8, height: 8)
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func nutrientRow(_ row: CoverageRow) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(row.name)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text(row.status.rawValue)
                    .font(.caption).bold()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(row.status.color.opacity(0.15))
                    .foregroundColor(row.status.color)
                    .clipShape(Capsule())
            }

            if expanded.contains(row.id) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(row.segments, id: \.date) { seg in
                        HStack(alignment: .top, spacing: 8) {
                            Text(shortDate(seg.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 68, alignment: .leading)
                            if let foods = seg.foods, !foods.isEmpty {
                                Text(foods.prefix(5).joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("—")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.25)))
            }

            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
                withAnimation(.easeInOut(duration: 0.25)) {
                    if expanded.contains(row.id) { expanded.remove(row.id) } else { expanded.insert(row.id) }
                }
            }) {
                HStack(spacing: 6) {
                    Text(expanded.contains(row.id) ? "Hide days & foods" : "Show days & foods")
                    Image(systemName: expanded.contains(row.id) ? "chevron.up" : "chevron.down")
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
    }

    // MARK: - Helpers

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "E d MMM"
        return f.string(from: date)
    }
}
