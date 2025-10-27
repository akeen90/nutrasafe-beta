import SwiftUI
import Foundation
import UIKit

struct DiaryTabView: View {
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
        // Removed nested NavigationView to rely on root navigation
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                // Header with inline date picker
                HStack {
                    Text("Diary")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
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

                        VStack(spacing: 0) {
                            Color(UIColor.systemBackground)
                                .frame(height: 50)
                            Spacer()
                        }
                        .allowsHitTesting(false)

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
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

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
            .background(Color.adaptiveBackground)
            .navigationBarHidden(true)
        }
        .onChange(of: selectedDate) { _ in
            loadFoodData()
        }
        .onAppear {
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
            print("📝 Edit trigger fired. Selected items: \(selectedFoodItems)")

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
            CategoricalNutrientTrackingView()
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
                // Remove from current date
                diaryDataManager.deleteFoodItems([food], for: selectedDate)
                // Add to destination date (new id to avoid collisions)
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
        Task {
            do {
                let (breakfast, lunch, dinner, snacks) = try await diaryDataManager.getFoodDataAsync(for: selectedDate)
                await MainActor.run {
                    breakfastFoods = breakfast
                    lunchFoods = lunch
                    dinnerFoods = dinner
                    snackFoods = snacks
                    recalculateNutrition()
                }
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

    var body: some View {
        VStack(spacing: 20) {
            // Nutrient Rhythm Bar + Insight Line
            rhythmSection

            // Nutrient Coverage Map
            coverageMapSection
        }
        .task {
            vm.setDiaryManager(diaryDataManager)
            await vm.loadLast7Days()
        }
        .onChange(of: diaryDataManager.dataReloadTrigger) { _ in
            Task {
                print("📊 CategoricalNutrientTrackingView: Data changed, reloading...")
                await vm.loadLast7Days()
            }
        }
        .onAppear {
            Task {
                print("📊 CategoricalNutrientTrackingView: View appeared, force reloading...")
                await vm.loadLast7Days()
            }
        }
        .refreshable {
            await vm.loadLast7Days()
        }
        .onReceive(NotificationCenter.default.publisher(for: .foodDiaryUpdated)) { _ in
            Task {
                print("🔄 Food diary updated, refreshing Nutrient Rhythm Bar...")
                await vm.loadLast7Days()
            }
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

                    Text("Your Nutrient Rhythm")
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
                    legendItem(color: Color(hex: "#57A5FF"), label: "Trace")
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

            // Premium insight card
            if let insight = vm.generateAdaptiveInsight() {
                premiumInsightCard(text: insight)
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
            }
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

    private func premiumInsightCard(text: String) -> some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showingGaps = true
            }
        } label: {
            HStack(alignment: .top, spacing: 14) {
                // Warning icon with prominent orange colour
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.orange)

                // Insight text with full visibility
                VStack(alignment: .leading, spacing: 6) {
                    Text("Areas That Need Attention")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.secondary)

                    Text(text)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.4))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.orange.opacity(0.25), lineWidth: 1.5)
            )
            .shadow(color: Color.orange.opacity(0.1), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
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
}

// MARK: - View Model

@available(iOS 16.0, *)
@MainActor
final class CategoricalNutrientViewModel: ObservableObject {
    @Published var rhythmDays: [RhythmDay] = []
    @Published var nutrientCoverageRows: [CoverageRow] = []

    weak var diaryManager: DiaryDataManager?

    func setDiaryManager(_ manager: DiaryDataManager) {
        self.diaryManager = manager
    }

    // Load last 7 days of rhythm and coverage data
    func loadLast7Days() async {
        print("🔄 CategoricalNutrientViewModel: Starting loadLast7Days...")

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var days: [RhythmDay] = []
        var rows: [CoverageRow] = []

        // Generate last 7 days
        let dates = (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }.reversed()

        do {
            // Fetch food entries for last 7 days
            let entries = try await FirebaseManager.shared.getFoodEntriesForPeriod(days: 7)
            print("📥 Fetched \(entries.count) food entries for last 7 days")

            let grouped = Dictionary(grouping: entries, by: { calendar.startOfDay(for: $0.date) })

            // Build rhythm days
            for date in dates {
                let dayEntries = grouped[date] ?? []
                let level = calculateDominantLevel(for: dayEntries)
                days.append(RhythmDay(date: date, level: level))
            }

            // Build coverage rows
            let nutrients = nutrientList()
            print("📊 Processing \(nutrients.count) nutrients...")

            for nutrient in nutrients {
                var segments: [Segment] = []
                var strongCount = 0
                var loggedDays = 0

                for date in dates {
                    let dayEntries = grouped[date] ?? []
                    if !dayEntries.isEmpty {
                        loggedDays += 1
                        let level = highestLevel(for: nutrient.id, entries: dayEntries)
                        if level == .strong { strongCount += 1 }
                        let foods = contributingFoods(for: nutrient.id, entries: dayEntries)
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

            await MainActor.run {
                self.rhythmDays = days
                self.nutrientCoverageRows = rows
                print("✅ Loaded \(days.count) rhythm days and \(rows.count) nutrient rows")
            }

        } catch {
            print("❌ Failed to load 7-day data: \(error)")
            await MainActor.run {
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

    private func calculateDominantLevel(for entries: [FoodEntry]) -> SourceLevel {
        guard !entries.isEmpty else { return .none }

        var strongCount = 0
        var moderateCount = 0
        var traceCount = 0

        let nutrients = nutrientList()
        for nutrient in nutrients {
            let level = highestLevel(for: nutrient.id, entries: entries)
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

    private func highestLevel(for nutrientId: String, entries: [FoodEntry]) -> SourceLevel {
        var best: SourceLevel = .none
        // Convert nutrient ID to MicronutrientProfile key format
        let profileKey = nutrientIdToProfileKey(nutrientId)

        // Debug logging for Vitamin C only
        let isVitC = nutrientId.lowercased().contains("vitamin_c") || nutrientId.lowercased().contains("vitaminc")

        for entry in entries {
            // IMPORTANT: Recalculate micronutrient profile with improved estimation
            // This ensures old entries get the new, more accurate multipliers
            let freshProfile = recalculateMicronutrientProfile(for: entry)

            // Try to find the nutrient in vitamins or minerals using the converted key
            if let amt = freshProfile.vitamins[profileKey] ?? freshProfile.minerals[profileKey] {
                let level = classify(amount: amt, key: profileKey, profile: freshProfile)
                best = max(best, level)

                if isVitC {
                    print("   🔍 \(entry.foodName): amt=\(String(format: "%.1f", amt))mg, level=\(level)")
                }
            } else {
                // Fallback: use keyword detection
                let food = DiaryFoodItem.fromFoodEntry(entry)
                let present = NutrientDetector.detectNutrients(in: food).contains(nutrientId)
                best = max(best, present ? .trace : .none)

                if isVitC {
                    print("   ⚠️ \(entry.foodName): NO AMOUNT in profile (profileKey=\(profileKey))")
                }
            }
        }

        return best
    }

    private func contributingFoods(for nutrientId: String, entries: [FoodEntry]) -> [String] {
        var names: [String] = []
        // Convert nutrient ID to MicronutrientProfile key format
        let profileKey = nutrientIdToProfileKey(nutrientId)

        for entry in entries {
            // IMPORTANT: Recalculate micronutrient profile with improved estimation
            let freshProfile = recalculateMicronutrientProfile(for: entry)

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

    private func classify(amount: Double, key: String, profile: MicronutrientProfile) -> SourceLevel {
        if amount <= 0 { return .none }
        let dvKey = dvKey(for: key)

        // Debug logging for Vitamin C only
        let isVitC = key.lowercased().contains("vitaminc")

        if let percent = profile.getDailyValuePercentage(for: dvKey, amount: amount) {
            if isVitC {
                print("      📊 classify: amount=\(String(format: "%.1f", amount))mg, percent=\(String(format: "%.1f", percent))%")
            }

            if percent >= 70 { return .strong }
            if percent >= 30 { return .moderate }
            return .trace
        }

        if isVitC {
            print("      ❌ classify: NO DAILY VALUE found for dvKey=\(dvKey)")
        }

        return .trace
    }

    /// Converts NutrientDatabase ID format to MicronutrientProfile key format
    /// e.g., "vitamin_c" -> "vitaminC", "vitamin_b1" -> "thiamine"
    private func nutrientIdToProfileKey(_ nutrientId: String) -> String {
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
    private func dvKey(for key: String) -> String {
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

    private func nutrientList() -> [NutrientItem] {
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
    private func recalculateMicronutrientProfile(for entry: FoodEntry) -> MicronutrientProfile {
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
            micronutrientProfile: nil  // Force recalculation
        )

        // Now apply the quantity multiplier to get the actual nutrients consumed
        return MicronutrientManager.shared.getMicronutrientProfile(for: foodSearchResult, quantity: multiplier)
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
    case trace = "Trace"
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

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Status card
                    statusCard

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
