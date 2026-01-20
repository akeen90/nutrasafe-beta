import SwiftUI
import Foundation
import UIKit

struct DiaryTabView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var diaryDataManager: DiaryDataManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var fastingViewModelWrapper: FastingViewModelWrapper
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
        case insights = "Insights"
    }

    enum InsightsSubTab: String, CaseIterable {
        case additives = "Additives"
        case nutrients = "Vitamins & Minerals"
    }

    // MARK: - Unified Reload Trigger (Performance Optimization)
    // Consolidates multiple onChange handlers into single coordinated reload
    // Prevents cascading updates when multiple triggers fire simultaneously
    @State private var pendingReloadTask: Task<Void, Never>?
    private let reloadDebounceInterval: UInt64 = 100_000_000 // 100ms in nanoseconds

    // MARK: - Cached Nutrition Totals (Performance Optimization)
    @State private var cachedNutrition: NutritionTotals = NutritionTotals()
    @State private var hasLoadedOnce = false // PERFORMANCE: Guard flag to prevent redundant loads
    @State private var isLoadingData = false // Loading state for UI feedback

    // NOTE: HealthKit refresh is now handled by HealthKitManager's live updates
    // (HKObserverQuery + 30-second timer). Removed redundant DiaryTabView timer.

    // MARK: - Feature Tips
    @State private var showingDiaryTip = false
    @State private var showingNutrientsTip = false
    @State private var showingInsightsTip = false
    @State private var showingAdditivesTip = false
    @ObservedObject private var featureTipsManager = FeatureTipsManager.shared

    // MARK: - Diary Limit
    @State private var showingDiaryLimitError = false
    @State private var showingPaywall = false

    // MARK: - Food Lookup Cache (O(1) instead of O(n))
    @State private var foodLookupCache: [String: (food: DiaryFoodItem, meal: String)] = [:]

    // MARK: - Calendar Entry Indicators
    @State private var datesWithEntries: Set<Date> = []
    @State private var displayedMonth: Date = Date()
    @State private var isLoadingCalendarEntries = false

    // MARK: - Additive Tracker
    @StateObject private var additiveTrackerVM = AdditiveTrackerViewModel()
    @State private var insightsSubTab: InsightsSubTab = .additives

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

    // MARK: - Debounced Reload (Performance Optimization)
    // Consolidates multiple rapid reload triggers into single load operation
    // Prevents N sequential Firebase calls when changing date/tab/refreshing simultaneously
    private func triggerDebouncedReload() {
        // Cancel any pending reload
        pendingReloadTask?.cancel()

        // Schedule new reload with debounce
        pendingReloadTask = Task {
            do {
                // Wait for debounce interval
                try await Task.sleep(nanoseconds: reloadDebounceInterval)

                // Check if cancelled during sleep
                try Task.checkCancellation()

                // Perform the actual load
                await MainActor.run {
                    loadFoodData()
                }
            } catch {
                // Task was cancelled - another reload is pending
            }
        }
    }

    // MARK: - Top Navigation Row (Tab Picker + Settings on same line)
    private var topNavigationRow: some View {
        TabHeaderView(
            tabs: DiarySubTab.allCases,
            selectedTab: $diarySubTab,
            onSettingsTapped: { showingSettings = true }
        )
    }

    // MARK: - Horizontal Week Picker (Palette-Aware, Onboarding Style)
    // Selected day stays in center, days shift when navigating
    private var dateNavigationRow: some View {
        let calendar = Calendar.current
        // Get 7 days centered around selected date (3 before, selected, 3 after)
        let surroundingDays = getSurroundingDays(for: selectedDate, count: 7)

        return HStack(spacing: 0) {
            // Left arrow - navigate day (closed) or month (open)
            Button(action: {
                if showingDatePicker {
                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                } else {
                    selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(palette.accent)
                    .frame(width: 36, height: 36)
            }

            // Days - selected is always in center (index 3)
            HStack(spacing: 0) {
                ForEach(Array(surroundingDays.enumerated()), id: \.offset) { index, date in
                    let isCenter = index == 3 // Center position
                    let dayName = formatDayName(date)

                    Button(action: {
                        if isCenter {
                            // Tap center day to toggle calendar
                            showingDatePicker.toggle()
                        } else {
                            // Tap other day to select it (shifts days)
                            selectedDate = date
                        }
                    }) {
                        ZStack {
                            if isCenter {
                                // Palette-colored pill background with gradient
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [palette.accent, palette.primary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 76, height: 32)
                                    .shadow(color: palette.accent.opacity(0.3), radius: 6, y: 2)

                                // Content centered inside pill
                                HStack(spacing: 4) {
                                    Text(dayName)
                                        .font(.system(size: 12, weight: .semibold))
                                        .lineLimit(1)
                                    Image(systemName: "calendar")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundColor(.white)
                            } else {
                                // Other days - just text
                                Text(dayName)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(palette.textSecondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(height: 36)
                    .buttonStyle(.plain)
                }
            }

            // Right arrow - navigate day (closed) or month (open)
            Button(action: {
                if showingDatePicker {
                    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                } else {
                    selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(palette.accent)
                    .frame(width: 36, height: 36)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal, DesignTokens.Spacing.md)
    }

    // Get days centered around the selected date
    private func getSurroundingDays(for date: Date, count: Int) -> [Date] {
        let calendar = Calendar.current
        let halfCount = count / 2 // 3 days before and after
        return (-halfCount...halfCount).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: date)
        }
    }

    // Format day name (Mon, Tue, etc.) - shows "Today" for current date
    private func formatDayName(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    // Helper to format full date (e.g., "Tuesday, 14 Jan")
    private func formatDateFull(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM"
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        }
        return formatter.string(from: date)
    }

    // MARK: - Date Picker Section (Custom Calendar with Entry Indicators)
    @ViewBuilder
    private var datePickerSection: some View {
        if showingDatePicker {
            VStack(spacing: 0) {
                // Header
                datePickerHeader

                // Day of week headers
                HStack(spacing: 0) {
                    ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { _, day in
                        Text(day)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

                // Calendar grid
                calendarGrid
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        palette.primary.opacity(0.05),
                                        palette.accent.opacity(0.03)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .onAppear {
                displayedMonth = selectedDate
                loadDatesWithEntries()
            }
            .onChange(of: displayedMonth) {
                loadDatesWithEntries()
            }
        }
    }

    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!

        // Get first day of week offset
        // .weekday returns 1 for Sunday, 2 for Monday, etc.
        // For a Sunday-first calendar (as displayed), we need: offset = weekday - 1
        // This gives us 0 empty cells if day 1 is Sunday, 6 if day 1 is Saturday
        let weekdayOfFirst = calendar.component(.weekday, from: monthStart)
        let firstWeekdayOffset = weekdayOfFirst - 1  // 0-indexed for Sunday-first display
        let daysInMonth = calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30

        // Build all items for the grid
        let totalCells = firstWeekdayOffset + daysInMonth

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
            ForEach(0..<totalCells, id: \.self) { index in
                if index < firstWeekdayOffset {
                    // Empty cell before first day of month
                    Color.clear
                        .frame(height: 44)
                } else {
                    // Actual day cell
                    let day = index - firstWeekdayOffset + 1
                    if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                        calendarDayCell(date: date, day: day)
                    }
                }
            }
        }
    }

    // MARK: - Calendar Day Cell (Palette-Aware)
    private func calendarDayCell(date: Date, day: Int) -> some View {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let hasEntries = datesWithEntries.contains(where: { calendar.isDate($0, inSameDayAs: date) })
        let isFuture = date > Date()

        return Button(action: {
            selectedDate = date
            // Close calendar after selection
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                showingDatePicker = false
            }
        }) {
            VStack(spacing: 2) {
                // Day number
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [palette.accent, palette.primary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                            .shadow(color: palette.accent.opacity(0.3), radius: 4, y: 2)
                    } else if isToday {
                        Circle()
                            .stroke(palette.accent, lineWidth: 2)
                            .frame(width: 32, height: 32)
                    }

                    Text("\(day)")
                        .font(.system(size: 16, weight: isToday || isSelected ? .bold : .regular))
                        .foregroundColor(
                            isSelected ? .white :
                            isFuture ? .secondary.opacity(0.5) :
                            .primary
                        )
                }

                // Entry indicator dot
                if hasEntries && !isFuture {
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.8) : palette.accent)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isFuture)
    }

    // MARK: - Load Dates With Entries
    private func loadDatesWithEntries() {
        guard !isLoadingCalendarEntries else { return }
        isLoadingCalendarEntries = true

        Task {
            let calendar = Calendar.current
            // Get start of month
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
            // Get end of month
            let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
            let monthEndWithTime = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: monthEnd)!

            do {
                let entries = try await FirebaseManager.shared.getFoodEntriesInRange(from: monthStart, to: monthEndWithTime)

                // Extract unique dates
                var dates = Set<Date>()
                for entry in entries {
                    let startOfDay = calendar.startOfDay(for: entry.date)
                    dates.insert(startOfDay)
                }

                await MainActor.run {
                    datesWithEntries = dates
                    isLoadingCalendarEntries = false
                }
            } catch {
                await MainActor.run {
                    isLoadingCalendarEntries = false
                }
                            }
        }
    }

    private var datePickerHeader: some View {
        HStack {
            Text(formatMonthYear(displayedMonth))
                .font(DesignTokens.Typography.sectionTitle(20))
                .foregroundColor(palette.textPrimary)

            Spacer()

            Button(action: {
                selectedDate = Date()
                displayedMonth = Date()
                showingDatePicker = false
            }) {
                Text("Today")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(palette.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(palette.accent.opacity(0.12))
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Date Section (navigation + expanded calendar)
    @ViewBuilder
    private var dateSectionView: some View {
        VStack(spacing: 8) {
            dateNavigationRow
            datePickerSection
        }
        .padding(.top, 4)
        .padding(.bottom, 8)
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
            ZStack {
                // Overview tab - show/hide with opacity (no animation)
                ScrollView {
                    LazyVStack(spacing: 16) {
                        overviewTabContent
                    }
                }
                .opacity(diarySubTab == .overview ? 1 : 0)
                .allowsHitTesting(diarySubTab == .overview)

                // Nutrients tab - show/hide with opacity (no animation)
                ScrollView {
                    LazyVStack(spacing: 16) {
                        nutrientsTabContent
                    }
                }
                .opacity(diarySubTab == .insights ? 1 : 0)
                .allowsHitTesting(diarySubTab == .insights)
            }
            .background(diaryBlueBackground)
            .navigationBarHidden(true)
        }
    }

    var body: some View {
        contentWithLifecycleModifiers
            .fullScreenCover(isPresented: $showingMoveSheet) {
                moveFoodSheet
            }
            .fullScreenCover(isPresented: $showingCopySheet) {
                copyFoodSheet
            }
            .fullScreenCover(item: $editingFood, onDismiss: {
                editingFood = nil
                editingMealType = ""
            }) { food in
                FoodDetailViewFromSearch(
                    food: food.toFoodSearchResult(),
                    sourceType: .diary,
                    selectedTab: $selectedTab,
                    diaryEntryId: food.id,
                    diaryMealType: editingMealType.isEmpty ? food.time : editingMealType,
                    diaryQuantity: food.quantity,
                    diaryDate: selectedDate,
                    fastingViewModel: fastingViewModelWrapper.viewModel
                )
            }
            .diaryLimitAlert(
                isPresented: $showingDiaryLimitError,
                showingPaywall: $showingPaywall
            )
            .fullScreenCover(isPresented: $showingPaywall) {
                PaywallView()
            }
            .background(Color.adaptiveBackground)
            .trackScreen("Diary")
            .featureTip(isPresented: $showingDiaryTip, tipKey: .diaryOverview)
            .featureTip(isPresented: $showingNutrientsTip, tipKey: .nutrientsOverview)
            .featureTip(isPresented: $showingInsightsTip, tipKey: .insightsOverview)
            .featureTip(isPresented: $showingAdditivesTip, tipKey: .additivesTracker)
    }

    // MARK: - Content with Lifecycle Modifiers
    // PERFORMANCE: Consolidated onChange handlers use debounced reload
    // Multiple triggers (date change, refresh, data reload) are batched into single load
    private var contentWithLifecycleModifiers: some View {
        mainContent
            // PERFORMANCE: Use debounced reload to prevent cascading updates
            .onChange(of: selectedDate) {
                triggerDebouncedReload()
            }
            .onAppear {
                // PERFORMANCE: Skip if already loaded - prevents redundant Firebase calls on tab switches
                guard !hasLoadedOnce else { return }
                hasLoadedOnce = true
                loadFoodData() // Initial load doesn't need debounce

                // Show feature tip on first visit
                // Use longer delay if user just completed onboarding to avoid immediate tip after permissions
                if !FeatureTipsManager.shared.hasSeenTip(.diaryOverview) {
                    let delay: Double = OnboardingManager.shared.justCompletedOnboarding ? 2.0 : 0.5
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        showingDiaryTip = true
                        // Reset the flag after showing the first tip
                        OnboardingManager.shared.justCompletedOnboarding = false
                    }
                }
            }
            .onChange(of: selectedTab) { _, newTab in
                handleSelectedTabChange(newTab)
            }
            .onChange(of: diarySubTab) { _, newTab in
                handleDiarySubTabChange(newTab)
            }
            .onChange(of: insightsSubTab) { _, newSubTab in
                handleInsightsSubTabChange(newSubTab)
            }
            // PERFORMANCE: Consolidated - these 3 triggers now use debounced reload
            .onChange(of: refreshTrigger) {
                triggerDebouncedReload()
            }
            .onChange(of: diaryDataManager.dataReloadTrigger) {
                triggerDebouncedReload()
            }
            .onChange(of: editTrigger) { _, newValue in
                handleEditTrigger(newValue)
            }
            .onReceive(NotificationCenter.default.publisher(for: .diaryFoodDetailOpened)) { _ in
                selectedFoodItems.removeAll()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshDiaryData"))) { _ in
                // Refresh diary when foods are added from AI scanner
                loadFoodData()
            }
            .onReceive(NotificationCenter.default.publisher(for: .foodEntryAdded)) { _ in
                // Switch to overview tab when food is added (even from Insights tab)
                diarySubTab = .overview
            }
            // NOTE: HealthKit refresh now handled automatically by HealthKitManager
            .onChange(of: moveTrigger) { _, newValue in
                guard newValue else { return }
                showMoveOptions()
                moveTrigger = false
            }
            .onChange(of: copyTrigger) { _, newValue in
                guard newValue else { return }
                showCopyOptions()
                copyTrigger = false
            }
            .onChange(of: deleteTrigger) { _, newValue in
                guard newValue else { return }
                deleteSelectedFoods()
                deleteTrigger = false
            }
            .onChange(of: featureTipsManager.resetTrigger) { _, _ in
                // When tips are reset, switch to overview sub-tab and show the diary tip
                diarySubTab = .overview
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingDiaryTip = true
                }
            }
    }

    // MARK: - Main Content
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Top row: Tab picker + Settings icon on same line
            topNavigationRow

            // Date navigation - only show on Overview tab (Nutrients has its own)
            if diarySubTab == .overview {
                dateSectionView
            }

            // Loading state or content
            ZStack {
                loadingStateView
                mainContentSection
            }
        }
        .background(diaryBlueBackground)
    }

    // MARK: - Palette for Intent-Aware Colors
    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    // MARK: - Adaptive Background (Intent-aware animated gradient)
    private var diaryBlueBackground: some View {
        AppAnimatedBackground()
    }

    // MARK: - Helper Methods for onChange Handlers
    private func handleSelectedTabChange(_ newTab: TabItem) {
        // NOTE: HealthKit refresh now handled automatically by HealthKitManager

        // Unselect when leaving diary; reset overview when returning
        if newTab == .diary {
            diarySubTab = .overview
        } else {
            selectedFoodItems.removeAll()
        }
    }

    private func handleDiarySubTabChange(_ newTab: DiarySubTab) {
        // SOFT PAYWALL: Allow navigation to nutrients tab (premium features are blurred within)
        // Show feature tips on first visit to insights tab
        if newTab == .insights {
            // First show the Insights overview tip, then additives or nutrients tips based on sub-tab
            if !FeatureTipsManager.shared.hasSeenTip(.insightsOverview) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showingInsightsTip = true
                }
            } else if insightsSubTab == .additives && !FeatureTipsManager.shared.hasSeenTip(.additivesTracker) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showingAdditivesTip = true
                }
            } else if insightsSubTab == .nutrients && !FeatureTipsManager.shared.hasSeenTip(.nutrientsOverview) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showingNutrientsTip = true
                }
            }
        }
    }

    private func handleInsightsSubTabChange(_ newSubTab: InsightsSubTab) {
        // Only show tips if we're on the insights tab and haven't seen the overview yet
        guard diarySubTab == .insights else { return }
        guard FeatureTipsManager.shared.hasSeenTip(.insightsOverview) else { return }

        // Show tip for the specific sub-tab if not seen
        if newSubTab == .additives && !FeatureTipsManager.shared.hasSeenTip(.additivesTracker) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showingAdditivesTip = true
            }
        } else if newSubTab == .nutrients && !FeatureTipsManager.shared.hasSeenTip(.nutrientsOverview) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showingNutrientsTip = true
            }
        }
    }

    private func handleEditTrigger(_ newValue: Bool) {
        guard newValue else { return }

        if let foodId = selectedFoodItems.first {
            if let result = findFoodWithMeal(byId: foodId) {
                editingFood = result.food
                editingMealType = result.meal
                // Clear selection once user enters edit flow
                selectedFoodItems.removeAll()
            } else {
                            }
        } else {
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
                .fill(colorScheme == .dark ? Color.midnightCard : Color(.secondarySystemBackground))
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
        // Check premium access for Insights tab
        if subscriptionManager.hasAccess {
            // Premium users see full content
            // Insights sub-tab picker
            insightsSubTabPicker
                .padding(.top, 8)
                .padding(.horizontal, 16)

            // Content based on selected sub-tab
            switch insightsSubTab {
            case .additives:
                AdditiveTrackerSection(viewModel: additiveTrackerVM)

            case .nutrients:
                if #available(iOS 16.0, *) {
                    CategoricalNutrientTrackingView(selectedDate: $selectedDate)
                } else {
                    Text("Nutrient tracking requires iOS 16.0 or later")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }

            Spacer()
                .frame(height: 150)
        } else {
            // Free users see unlock card
            PremiumUnlockCard(
                icon: "chart.bar.doc.horizontal",
                iconColor: .orange,
                title: "Food Insights",
                subtitle: "Understand what's really in your food with detailed additive tracking and vitamin & mineral analysis",
                benefits: [
                    "Track food additives and E-numbers in your diet",
                    "Monitor daily vitamin & mineral intake",
                    "See how your nutrition stacks up against targets",
                    "Identify nutritional gaps and improvements"
                ],
                onUnlockTapped: { showingPaywall = true }
            )
        }
    }

    private var insightsSubTabPicker: some View {
        HStack(spacing: 0) {
            ForEach(InsightsSubTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        insightsSubTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(insightsSubTab == tab ? .white : .secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            insightsSubTab == tab
                                ? Capsule().fill(Color.orange)
                                : Capsule().fill(Color(.systemGray6))
                        )
                        .contentShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())

                if tab != InsightsSubTab.allCases.last {
                    Spacer(minLength: 8)
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6).opacity(0.5))
        )
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
            let hasAccess = subscriptionManager.hasAccess
            for food in itemsToMove {
                // Remove from current date
                diaryDataManager.deleteFoodItems([food], for: selectedDate)
                // Add to destination date (new id to avoid collisions)
                var moved = food
                moved.id = UUID()
                do {
                    try await diaryDataManager.addFoodItem(moved, to: destinationMeal, for: moveToDate, hasProAccess: hasAccess)
                } catch is FirebaseManager.DiaryLimitError {
                    await MainActor.run { showingDiaryLimitError = true }
                    break
                } catch {
                                    }
            }
        }
    }

    private func performCopy() {
        let destinationMeal = copyToMeal.lowercased()
        let itemsToCopy = selectedFoodItems.compactMap { findFood(byId: $0) }
        selectedFoodItems.removeAll()
        showingCopySheet = false

        Task {
            let hasAccess = subscriptionManager.hasAccess
            for food in itemsToCopy {
                var copied = food
                copied.id = UUID()
                do {
                    try await diaryDataManager.addFoodItem(copied, to: destinationMeal, for: copyToDate, hasProAccess: hasAccess)
                } catch is FirebaseManager.DiaryLimitError {
                    await MainActor.run { showingDiaryLimitError = true }
                    break
                } catch {
                                    }
            }
        }
    }

    // PERFORMANCE: O(1) lookup using cached dictionary
    private func findFood(byId id: String) -> DiaryFoodItem? {
        foodLookupCache[id]?.food
    }

    // PERFORMANCE: O(1) lookup using cached dictionary
    private func findFoodWithMeal(byId id: String) -> (food: DiaryFoodItem, meal: String)? {
        foodLookupCache[id]
    }

    // PERFORMANCE: Rebuild lookup cache when food arrays change
    private func rebuildFoodLookupCache() {
        var cache: [String: (food: DiaryFoodItem, meal: String)] = [:]
        cache.reserveCapacity(breakfastFoods.count + lunchFoods.count + dinnerFoods.count + snackFoods.count)
        for food in breakfastFoods { cache[food.id.uuidString] = (food, "Breakfast") }
        for food in lunchFoods { cache[food.id.uuidString] = (food, "Lunch") }
        for food in dinnerFoods { cache[food.id.uuidString] = (food, "Dinner") }
        for food in snackFoods { cache[food.id.uuidString] = (food, "Snacks") }
        foodLookupCache = cache
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

                // Update ALL HealthKit data for the selected date IN PARALLEL
                // NOTE: This is the ONLY place that should fetch HealthKit data for the diary
                // DiaryDailySummaryCard observes these values but does NOT fetch
                // PERFORMANCE: Parallelized - saves ~400-600ms vs sequential calls
                async let exerciseTask: () = healthKitManager.updateExerciseCalories(for: selectedDate)
                async let stepsTask: () = healthKitManager.updateStepCount(for: selectedDate)
                async let activeTask: () = healthKitManager.updateActiveEnergy(for: selectedDate)
                _ = await (exerciseTask, stepsTask, activeTask)

                await MainActor.run {
                    breakfastFoods = breakfast
                    lunchFoods = lunch
                    dinnerFoods = dinner
                    snackFoods = snacks
                    rebuildFoodLookupCache() // PERFORMANCE: O(1) lookups
                    recalculateNutrition()
                    isLoadingData = false
                }
            } catch {
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
        // PERFORMANCE: Use cached static formatter instead of creating new one
        DateHelper.shortDateUKFormatter.string(from: date)
    }

    private func formatMonthYear(_ date: Date) -> String {
        // PERFORMANCE: Use cached static formatter
        DateHelper.fullMonthYearFormatter.string(from: date)
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
    @State private var weekNavigationTask: Task<Void, Never>? // Debounce task for rapid navigation

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
            // Guard against duplicate initial loads
            guard !hasInitiallyLoaded else { return }
            hasInitiallyLoaded = true

            vm.setDiaryManager(diaryDataManager)

            // Initialize with the week containing selectedDate
            let (weekStart, _) = getWeekRange(for: selectedDate)
            selectedWeekStart = weekStart

            // Calculate week offset from today
            let (currentWeekStart, _) = getWeekRange(for: Date())
            let calendar = Calendar.current
            let components = calendar.dateComponents([.weekOfYear], from: currentWeekStart, to: weekStart)
            weekOffset = components.weekOfYear ?? 0

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
            // Cancel any in-flight tasks - but KEEP data in memory for instant re-display
            vm.cancelLoading()
        }
        .fullScreenCover(isPresented: $showingGaps) {
            if #available(iOS 16.0, *) {
                NutrientGapsView(rows: vm.nutrientCoverageRows)
            } else {
                Text("Nutrient gaps requires iOS 16.0 or later")
            }
        }
        .fullScreenCover(item: $selectedNutrientRow) { row in
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
                    .background(Color(hex: "#5856D6").opacity(vm.isLoading ? 0.6 : 1.0))
                    .cornerRadius(10)
                }

                // This week button (always visible)
                Button(action: {
                    weekOffset = 0
                    loadWeekData()
                    selectedDate = Date()  // Set calendar to today AFTER loading week data
                }) {
                    HStack(spacing: 6) {
                        if vm.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(vm.isLoading ? "Loading..." : "This Week")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#3FD17C"), Color(hex: "#57A5FF")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .opacity(vm.isLoading ? 0.6 : 1.0)
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
                    .background(Color(hex: "#5856D6").opacity(vm.isLoading ? 0.6 : 1.0))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 20)
            .animation(.easeInOut(duration: 0.2), value: vm.isLoading)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Rhythm Section

    @ViewBuilder
    private var rhythmSection: some View {
        VStack(spacing: 0) {
            // Enhanced rhythm visualization - now shows nutrients per day
            VStack(spacing: 16) {
                // Header inside the card
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: "leaf.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "#3FD17C"), Color(hex: "#57A5FF")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Your Daily Nutrients")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)

                        Spacer()
                    }

                    Text("Vitamins & minerals from your food")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)

                // Day summary cards - fixed layout, no scrolling
                HStack(spacing: 4) {
                    ForEach(vm.rhythmDays, id: \.date) { day in
                        let isToday = Calendar.current.isDateInToday(day.date)
                        let nutrientCount = countNutrientsForDay(day.date)
                        compactDaySummaryCard(day: day, nutrientCount: nutrientCount, isToday: isToday)
                    }
                }
                .padding(.horizontal, 16)

                // Intelligent summary instead of stats
                intelligentNutrientSummary
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

    /// Intelligent summary text based on nutrient status
    private var intelligentNutrientSummary: some View {
        let summary = generateNutrientSummaryText()

        return HStack(spacing: 10) {
            Image(systemName: summary.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(summary.color)

            Text(summary.text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(summary.color.opacity(0.08))
        )
        .padding(.horizontal, 16)
    }

    /// Generate intelligent summary text based on nutrient coverage
    /// Only provides actionable feedback based on days with actual logged food
    /// Also checks recency - stale data (>3 days old) gets different messaging
    /// Now also checks if viewing past week vs current week
    private func generateNutrientSummaryText() -> (text: String, icon: String, color: Color) {
        let loggedDays = vm.rhythmDays.filter { $0.level != .none }
        let daysLogged = loggedDays.count
        let totalNutrients = vm.nutrientCoverageRows.count
        let nutrientsFound = vm.nutrientCoverageRows.filter { row in
            row.segments.contains { $0.foods != nil && !($0.foods?.isEmpty ?? true) }
        }.count

        let consistent = vm.nutrientCoverageRows.filter { $0.status == .consistent }

        // Check if viewing a past week (weekOffset < 0 means past, 0 means current week)
        let isViewingPastWeek = weekOffset < 0

        // Check how recent the data is
        let mostRecentLoggedDay = loggedDays.map { $0.date }.max()
        let daysSinceLastLog: Int
        if let lastDate = mostRecentLoggedDay {
            daysSinceLastLog = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        } else {
            daysSinceLastLog = Int.max
        }

        // No data logged for this week
        if daysLogged == 0 {
            if isViewingPastWeek {
                return (
                    text: "No meals were logged during this week.",
                    icon: "calendar.badge.exclamationmark",
                    color: .secondary
                )
            }
            return (
                text: "Log meals to see which vitamins and minerals you're getting.",
                icon: "plus.circle.fill",
                color: AppPalette.standard.accent
            )
        }

        // When viewing past weeks, don't prompt to add meals - just summarise what was logged
        if isViewingPastWeek {
            if nutrientsFound > 0 {
                if daysLogged == 1 {
                    return (
                        text: "Found \(nutrientsFound) nutrients from \(daysLogged) day logged this week.",
                        icon: "leaf.fill",
                        color: Color(hex: "#3FD17C")
                    )
                } else {
                    return (
                        text: "Found \(nutrientsFound) nutrients across \(daysLogged) days logged this week.",
                        icon: "leaf.fill",
                        color: Color(hex: "#3FD17C")
                    )
                }
            } else {
                return (
                    text: "Meals were logged but no nutrient data was captured this week.",
                    icon: "exclamationmark.triangle",
                    color: .orange
                )
            }
        }

        // Below: Only for current week (weekOffset == 0)

        // Data is stale (nothing logged in 4+ days) - encourage fresh logging
        if daysSinceLastLog >= 4 {
            return (
                text: "Last logged \(daysSinceLastLog) days ago. Add today's meals for current insights.",
                icon: "clock.arrow.circlepath",
                color: .secondary
            )
        }

        // Data is getting old (3 days since last log) - gentle nudge
        if daysSinceLastLog == 3 {
            return (
                text: "Haven't logged in a few days. Add meals to keep your profile current.",
                icon: "calendar.badge.clock",
                color: .orange
            )
        }

        // Fresh data (logged within last 2 days) - provide meaningful insights

        // Only 1 day logged - celebrate what they found
        if daysLogged == 1 {
            if nutrientsFound > 0 {
                return (
                    text: "Great start! Found \(nutrientsFound) nutrients in your meals.",
                    icon: "leaf.fill",
                    color: Color(hex: "#3FD17C")
                )
            } else {
                return (
                    text: "Keep logging to build your nutrient profile.",
                    icon: "chart.line.uptrend.xyaxis",
                    color: AppPalette.standard.accent
                )
            }
        }

        // 2 days logged - still building data, no gap suggestions
        if daysLogged == 2 {
            return (
                text: "\(nutrientsFound) nutrients found so far. Log more days to see patterns.",
                icon: "chart.line.uptrend.xyaxis",
                color: AppPalette.standard.accent
            )
        }

        // 3+ days logged with recent data - now we can make meaningful observations

        // Excellent coverage (90%+ consistent)
        if totalNutrients > 0 && consistent.count >= totalNutrients * 9 / 10 {
            return (
                text: "Excellent variety! \(consistent.count) nutrients appearing consistently.",
                icon: "star.fill",
                color: Color(hex: "#3FD17C")
            )
        }

        // Good coverage (70%+ consistent)
        if totalNutrients > 0 && consistent.count >= totalNutrients * 7 / 10 {
            return (
                text: "Good balance with \(consistent.count) nutrients this week.",
                icon: "checkmark.circle.fill",
                color: Color(hex: "#3FD17C")
            )
        }

        // With 3+ days of recent data, we can suggest improvements
        // Only suggest gaps if user has found some nutrients (so we know they're logging properly)
        if nutrientsFound >= 3 {
            let inconsistent = vm.nutrientCoverageRows.filter { $0.status == .occasional || $0.status == .missing }
            if !inconsistent.isEmpty {
                let gapNames = inconsistent.prefix(2).map { $0.name }.joined(separator: " and ")
                return (
                    text: "Good coverage! Try adding variety for \(gapNames).",
                    icon: "lightbulb.fill",
                    color: .orange
                )
            }
        }

        // Default - show positive summary of what we found
        if nutrientsFound > 0 {
            return (
                text: "\(nutrientsFound) nutrients found across \(daysLogged) days of logging.",
                icon: "leaf.fill",
                color: Color(hex: "#57A5FF")
            )
        }

        // Fallback
        return (
            text: "Add more foods to see your nutrient breakdown.",
            icon: "plus.circle.fill",
            color: AppPalette.standard.accent
        )
    }

    /// Count how many unique nutrients were consumed on a given day
    private func countNutrientsForDay(_ date: Date) -> Int {
        var count = 0
        for row in vm.nutrientCoverageRows {
            if let segment = row.segments.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }),
               let foods = segment.foods, !foods.isEmpty {
                count += 1
            }
        }
        return count
    }

    /// Count food sources for a nutrient on a specific day
    private func countFoodsForNutrientOnDay(_ row: CoverageRow, date: Date) -> Int {
        if let segment = row.segments.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }),
           let foods = segment.foods {
            return foods.count
        }
        return 0
    }

    /// Compact day summary card that fits 7 days without scrolling
    private func compactDaySummaryCard(day: RhythmDay, nutrientCount: Int, isToday: Bool) -> some View {
        VStack(spacing: 4) {
            // Day label (single letter)
            Text(String(vm.shortDateLabel(day.date).prefix(1)))
                .font(.system(size: 11, weight: isToday ? .bold : .medium))
                .foregroundColor(isToday ? .primary : .secondary)

            // Nutrient count in circle
            ZStack {
                Circle()
                    .fill(
                        nutrientCount > 0
                            ? Color(hex: "#3FD17C")
                            : Color(.systemGray5)
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(isToday ? Color(hex: "#3FD17C") : Color.clear, lineWidth: 2)
                            .padding(-2)
                    )

                Text("\(nutrientCount)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(nutrientCount > 0 ? .white : .secondary)
            }
        }
        .frame(maxWidth: .infinity)
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
                        // Show total food sources this week
                        foodCountBadge(row)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }

                // 7-day view showing food count per day
                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        ForEach(row.segments, id: \.date) { seg in
                            let foodCount = seg.foods?.count ?? 0
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        foodCount > 0
                                            ? LinearGradient(
                                                colors: [Color(hex: "#3FD17C").opacity(0.8), Color(hex: "#3FD17C")],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                            : LinearGradient(
                                                colors: [Color(.systemGray5), Color(.systemGray5)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                    )
                                    .frame(height: 28)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )

                                if foodCount > 0 {
                                    Text("\(foodCount)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
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
        // PERFORMANCE: Use cached static formatter
        let full = DateHelper.singleLetterDayFormatter.string(from: date)
        return String(full.prefix(1))
    }

    /// Badge showing total food sources for a nutrient this week
    private func foodCountBadge(_ row: CoverageRow) -> some View {
        let totalFoods = row.segments.compactMap { $0.foods?.count }.reduce(0, +)

        return HStack(spacing: 4) {
            Image(systemName: "fork.knife")
                .font(.system(size: 10, weight: .semibold))

            Text("From \(totalFoods) \(totalFoods == 1 ? "food" : "foods")")
                .font(.system(size: 12, weight: .bold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(totalFoods > 0 ? Color(hex: "#3FD17C").opacity(0.12) : Color(.systemGray5).opacity(0.3))
        )
        .overlay(
            Capsule()
                .stroke(totalFoods > 0 ? Color(hex: "#3FD17C").opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .foregroundColor(totalFoods > 0 ? Color(hex: "#3FD17C") : .secondary)
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
    /// Uses debouncing to handle rapid week navigation without stalling
    private func requestDataLoad(for targetDate: Date? = nil, reason: String) {
        // Cancel any pending navigation task (debouncing)
        weekNavigationTask?.cancel()

        weekNavigationTask = Task {
            // Brief debounce delay for rapid tapping (150ms)
            try? await Task.sleep(nanoseconds: 150_000_000)

            // Check if cancelled during sleep (user tapped again)
            if Task.isCancelled { return }

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

        // PERFORMANCE: Use cached static formatters
        let startStr = DateHelper.monthDayFormatter.string(from: weekStart)

        let startMonth = calendar.component(.month, from: weekStart)
        let endMonth = calendar.component(.month, from: weekEnd)

        if startMonth == endMonth {
            return "\(startStr) - \(DateHelper.dayNumberFormatter.string(from: weekEnd))"
        } else {
            let endStr = DateHelper.monthDayFormatter.string(from: weekEnd)
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
                        return
        }
        let mondayStart = calendar.startOfDay(for: monday)

        // Prevent duplicate loads for the same week (only if already loading THIS week)
        if let currentDate = currentLoadingDate, calendar.isDate(currentDate, equalTo: mondayStart, toGranularity: .day) {
                        return
        }

        // Cancel any existing load task and wait for it to complete
        if let existingTask = loadTask {
            existingTask.cancel()
            // Wait briefly for the task to acknowledge cancellation
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        loadTask = nil

        // Reset loading state if a previous task was cancelled
        isLoading = false

        // Verify manager exists before proceeding
        guard diaryManager != nil else {
                        self.rhythmDays = []
            self.nutrientCoverageRows = []
            return
        }

        isLoading = true
        currentLoadingDate = mondayStart

                loadTask = Task { @MainActor in
            defer {
                self.isLoading = false
                self.currentLoadingDate = nil
            }

            // CACHE CHECK: Try week cache first
            if let cachedWeekData = await self.weekCache.getData(for: mondayStart) {
                                self.rhythmDays = self.convertFromCache(rhythmDays: cachedWeekData.rhythmDays)
                self.nutrientCoverageRows = self.convertFromCache(coverageRows: cachedWeekData.coverageRows)
                return
            }
                        let result: (days: [RhythmDay], rows: [CoverageRow])? = await Task {
                // Generate 7 days starting from Monday
                let dates = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: mondayStart) }

                // PERFORMANCE FIX: Use single batch Firebase query instead of 7 individual calls
                var allEntries: [FoodEntry] = []

                // Check for task cancellation
                if Task.isCancelled {
                                        return nil
                }

                // Calculate week end date (Sunday 23:59:59)
                guard let weekEndDate = calendar.date(byAdding: .day, value: 6, to: mondayStart),
                      let weekEndWithTime = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: weekEndDate) else {
                    return nil
                }

                // BATCH QUERY: Single Firebase call for entire week
                do {
                                        allEntries = try await FirebaseManager.shared.getFoodEntriesInRange(from: mondayStart, to: weekEndWithTime)
                                    } catch {
                                        allEntries = []
                }

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
                                    }

                return (days, rows)
            }.value

            // Update UI on main thread (we're already on MainActor due to @MainActor annotation)
            if Task.isCancelled {
                                return
            }

            if let result = result {
                self.rhythmDays = result.days
                self.nutrientCoverageRows = result.rows
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

    /// Generate adaptive insight text based on nutrient data
    /// - Parameter weekOffset: 0 = current week, negative = past weeks
    /// - Returns: Insight string or nil
    func generateAdaptiveInsight(weekOffset: Int = 0) -> String? {
        // Calculate data sufficiency metrics
        let totalMeals = calculateTotalMealsLogged()
        let daysWithData = rhythmDays.filter { $0.level != .none }.count

        // Determine if we have sufficient data (minimum 5 meals across 3+ days)
        let hasSufficientData = totalMeals >= 5 && daysWithData >= 3

        // Analyze coverage
        let missing = nutrientCoverageRows.filter { $0.status == .missing }
        let occasional = nutrientCoverageRows.filter { $0.status == .occasional }
        let consistent = nutrientCoverageRows.filter { $0.status == .consistent }

        // Check if viewing a past week
        let isViewingPastWeek = weekOffset < 0

        // TIER 1: No data at all
        if totalMeals == 0 {
            if isViewingPastWeek {
                return "No meals were logged during this week."
            }
            return "As you log more meals, your nutrient trends will start to appear here."
        }

        // TIER 2: Some data but below threshold (1-4 meals or fewer than 3 days)
        if !hasSufficientData {
            // Check if we can detect any weak nutrients even with limited data
            if !missing.isEmpty || !occasional.isEmpty {
                let weakNutrients = (missing + occasional).prefix(2).map { $0.name }.joined(separator: " and ")
                if isViewingPastWeek {
                    return "This week's meals showed lower \(weakNutrients) compared to other nutrients."
                }
                return "Based on your recent meals, \(weakNutrients) appear lower than others — keep logging to confirm."
            } else if totalMeals >= 2 {
                // Has some data but looking good so far
                if isViewingPastWeek {
                    return "Limited data logged this week — \(totalMeals) meals tracked."
                }
                return "Good start — log \(5 - totalMeals) more meals to reveal your full nutrient rhythm."
            } else {
                // Very minimal data (1 meal)
                if isViewingPastWeek {
                    return "Only 1 meal was logged this week."
                }
                return "As you log more meals, your nutrient trends will start to appear here."
            }
        }

        // TIER 3: Sufficient data — use standard contextual insight logic

        // Priority 1: Multiple missing nutrients (3+)
        if missing.count >= 3 {
            let names = missing.prefix(3).map { $0.name }.joined(separator: ", ")
            if isViewingPastWeek {
                return "This week showed consistently low \(names)."
            }
            return "Your entries show consistently low \(names) — tap to uncover all lows."
        }

        // Priority 2: 1-2 missing nutrients
        if missing.count >= 1 {
            let names = missing.prefix(2).map { $0.name }
            if missing.count == 1, let firstName = names.first {
                if isViewingPastWeek {
                    return "This week was missing \(firstName) from logged foods."
                }
                return "Your entries are missing \(firstName) this week — see what's causing it."
            } else {
                if isViewingPastWeek {
                    return "This week was missing \(names.joined(separator: " and ")) from logged foods."
                }
                return "Your entries are missing \(names.joined(separator: " and ")) — tap to see contributing foods."
            }
        }

        // Priority 3: Several occasional nutrients (day-to-day variation)
        if occasional.count >= 3 {
            let names = occasional.prefix(3).map { $0.name }.joined(separator: ", ")
            if isViewingPastWeek {
                return "These varied day-to-day: \(names)."
            }
            return "These vary day-to-day: \(names) — tap for daily breakdown."
        }

        // Priority 4: Mostly good coverage
        if consistent.count >= nutrientCoverageRows.count * 70 / 100 {
            let percentage = (consistent.count * 100) / max(1, nutrientCoverageRows.count)
            if percentage >= 90 {
                if isViewingPastWeek {
                    return "Excellent variety that week — \(consistent.count) of \(nutrientCoverageRows.count) nutrients found in your foods."
                }
                return "Excellent variety this week — \(consistent.count) of \(nutrientCoverageRows.count) nutrients found in your foods."
            } else {
                if isViewingPastWeek {
                    return "Good variety across most nutrients that week."
                }
                return "Good variety across most nutrients — great consistency this week."
            }
        }

        // Priority 5: Mixed results
        if occasional.count >= 2 {
            if isViewingPastWeek {
                return "Some nutrients fluctuated that week."
            }
            return "Some nutrients fluctuate — tap to see which ones need more consistency."
        }

        // Default: Encouraging message
        if daysWithData >= 5 {
            if isViewingPastWeek {
                return "Solid nutrient rhythm that week with \(daysWithData) days logged."
            }
            return "You're building a solid nutrient rhythm — keep it up this week."
        } else {
            if isViewingPastWeek {
                return "\(daysWithData) days logged that week."
            }
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
        // PERFORMANCE: Use cached static formatter
        DateHelper.singleLetterDayFormatter.string(from: date)
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
                                    }
            } else {
                // Fallback: use keyword detection
                let food = DiaryFoodItem.fromFoodEntry(entry)
                let present = NutrientDetector.detectNutrients(in: food).contains(nutrientId)
                best = max(best, present ? .trace : .none)

                if isVitC {
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
                            }

            // Require at least 10% DV to count as a meaningful contribution
            // This prevents trace amounts from inflating nutrient counts
            if percent >= 70 { return .strong }
            if percent >= 30 { return .moderate }
            if percent >= 10 { return .trace }
            return .none // Less than 10% DV - not a meaningful source
        }

        if isVitC {
                    }

        // Can't determine percentage - don't count as a source
        return .none
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

// Supporting types and components extracted to separate files:
// - NutrientTrackingTypes.swift (RhythmDay, NutrientItem, CoverageRow, Segment, SourceLevel, CoverageStatus)
// - NutrientDetailModal.swift (NutrientDetailModal, HealthClaim)
// - NutrientGapsView.swift (NutrientGapsView)
// - DiarySegmentedControl.swift (DiarySegmentedControl)
