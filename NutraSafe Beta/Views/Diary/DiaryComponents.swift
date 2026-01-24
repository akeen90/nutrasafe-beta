//
//  DiaryComponents.swift
//  NutraSafe Beta
//
//  Diary-related view components extracted from ContentView.swift
//

import SwiftUI

// MARK: - Diary Meal Card
struct DiaryMealCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var fastingViewModelWrapper: FastingViewModelWrapper

    let mealType: String
    let targetCalories: Int
    let currentCalories: Int
    @Binding var foods: [DiaryFoodItem]
    let color: Color
    @Binding var selectedTab: TabItem
    @Binding var selectedFoodItems: Set<String>
    let currentDate: Date
    let onEditFood: () -> Void
    let onSaveNeeded: () -> Void
    let onDelete: (DiaryFoodItem) -> Void
    let onAdd: () -> Void

    @State private var calorieGoal: Double = 1800
    @State private var macroGoals: [MacroGoal] = MacroGoal.defaultMacros

    // PERFORMANCE: Cache macro totals to prevent redundant calculations on every render
    // Pattern from Clay's production app: move expensive operations to cached state
    @State private var cachedProtein: Double = 0
    @State private var cachedCarbs: Double = 0
    @State private var cachedFat: Double = 0

    private var totalProtein: Double { cachedProtein }
    private var totalCarbs: Double { cachedCarbs }
    private var totalFat: Double { cachedFat }

    private func getMacroGoal(for macroType: MacroType) -> Double {
        if let goal = macroGoals.first(where: { $0.macroType == macroType }) {
            return goal.calculateGramGoal(from: calorieGoal)
        }
        return 0
    }

    private func getMacroProgress(current: Double, goal: Double) -> Double {
        guard goal > 0 else { return 0 }
        return min(1.0, current / goal)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Rounded pill-style meal header - refined with onboarding patterns
            HStack {
                HStack(spacing: 10) {
                    // Add button with subtle background
                    Button(action: onAdd) {
                        ZStack {
                            Circle()
                                .fill(color.opacity(0.12))
                                .frame(width: 32, height: 32)
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(color)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Meal name with serif styling
                    Text(mealType)
                        .font(AppTypography.sectionTitle(16))
                        .foregroundColor(Color.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer()

                // Calories and macros in header
                HStack(spacing: 0) {
                    Text("\(currentCalories)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.textSecondary)
                        .frame(width: 50, alignment: .trailing)

                    Text("\(String(format: "%.1f", totalProtein))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.textTertiary)
                        .frame(width: 50, alignment: .trailing)

                    Text("\(String(format: "%.1f", totalCarbs))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.textTertiary)
                        .frame(width: 50, alignment: .trailing)

                    Text("\(String(format: "%.1f", totalFat))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.textTertiary)
                        .frame(width: 50, alignment: .trailing)
                }
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, 12)
            .background(colorScheme == .dark ? Color.midnightCard : Color(.secondarySystemBackground).opacity(0.8))
            .cornerRadius(AppRadius.medium)

            // Food items section - directly under header
            if !foods.isEmpty {
                VStack(spacing: 0) {
                    ForEach(foods) { food in
                        DiaryFoodRow(
                            food: food,
                            mealType: mealType,
                            isSelected: selectedFoodItems.contains(food.id.uuidString),
                            hasAnySelection: !selectedFoodItems.isEmpty,
                            onTap: {
                                // Toggle selection instantly - no animation on state change
                                // The circle will still animate via its .transition modifier
                                if selectedFoodItems.contains(food.id.uuidString) {
                                    selectedFoodItems.remove(food.id.uuidString)
                                } else {
                                    selectedFoodItems.insert(food.id.uuidString)
                                }
                            },
                            onDelete: {
                                // Delete food from list
                                if let index = foods.firstIndex(of: food) {
                                    _ = withAnimation(.easeOut(duration: 0.3)) {
                                        foods.remove(at: index)
                                    }
                                    // Delete from Firebase
                                    onDelete(food)
                                    // Save after deletion
                                    onSaveNeeded()
                                }
                            }
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                        if food.id != foods.last?.id {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.large)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
        )
        .cardShadow()
        .onChange(of: foods) { _, newFoods in
            // PERFORMANCE: Update cached totals only when foods array changes
            // Prevents recalculation on every render cycle
            cachedProtein = newFoods.reduce(0) { $0 + $1.protein }
            cachedCarbs = newFoods.reduce(0) { $0 + $1.carbs }
            cachedFat = newFoods.reduce(0) { $0 + $1.fat }
        }
        .onAppear {
            // Initialize cached values on first appearance
            cachedProtein = foods.reduce(0) { $0 + $1.protein }
            cachedCarbs = foods.reduce(0) { $0 + $1.carbs }
            cachedFat = foods.reduce(0) { $0 + $1.fat }
        }
    }

}

// MARK: - Diary Food Row
struct DiaryFoodRow: View {
    let food: DiaryFoodItem
    let mealType: String
    let isSelected: Bool
    let hasAnySelection: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    @State private var showingFoodDetail = false
    @EnvironmentObject var fastingViewModelWrapper: FastingViewModelWrapper
    @EnvironmentObject var diaryDataManager: DiaryDataManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var firebaseManager: FirebaseManager

    // Check for watched additives
    private var watchedAdditives: Set<String> {
        if let saved = UserDefaults.standard.array(forKey: "watchedAdditives") as? [String] {
            return Set(saved)
        }
        return []
    }

    private var containsWatchedAdditives: [NutritionAdditiveInfo] {
        guard let additives = food.additives else { return [] }
        return additives.filter { additive in
            watchedAdditives.contains(additive.code)
        }
    }

    private var watchedAdditivesText: String {
        let count = containsWatchedAdditives.count
        if count == 1 {
            return containsWatchedAdditives[0].name
        } else {
            return "\(count) watched additives"
        }
    }

    var body: some View {
        Button(action: {
            // Tap always toggles selection
            onTap()
        }) {
            HStack(spacing: 10) {
                // Selection circle (show when any item is selected)
                if hasAnySelection {
                    ZStack {
                        Circle()
                            .fill(isSelected ? AppPalette.standard.accent : Color.clear)
                            .frame(width: 22, height: 22)
                        Circle()
                            .stroke(isSelected ? AppPalette.standard.accent : Color.gray.opacity(0.3), lineWidth: 1.5)
                            .frame(width: 22, height: 22)
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }

                // Food name and details
                VStack(alignment: .leading, spacing: 3) {
                    Text(food.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Serving size and quantity
                    HStack(spacing: 4) {
                        Text(food.servingDescription)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color.textTertiary)

                        if food.quantity > 1 {
                            Text("× \(String(format: "%.0f", food.quantity))")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppPalette.standard.accent)
                        }
                    }

                    // Watched additive warning badge
                    if !containsWatchedAdditives.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)

                            Text(watchedAdditivesText)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.15))
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Macros aligned with headers - refined typography
                HStack(spacing: 0) {
                    Text("\(food.calories)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                        .frame(width: 50, alignment: .trailing)

                    Text("\(String(format: "%.1f", food.protein))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.textSecondary)
                        .frame(width: 50, alignment: .trailing)

                    Text("\(String(format: "%.1f", food.carbs))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.textSecondary)
                        .frame(width: 50, alignment: .trailing)

                    Text("\(String(format: "%.1f", food.fat))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.textSecondary)
                        .frame(width: 50, alignment: .trailing)
                }
            }
            .animation(nil, value: hasAnySelection)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture {
            // Long press to view food details
            _ = food.toFoodSearchResult()
            showingFoodDetail = true
            NotificationCenter.default.post(name: .diaryFoodDetailOpened, object: nil)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
        .fullScreenCover(isPresented: $showingFoodDetail) {
            FoodDetailViewFromSearch(
                food: food.toFoodSearchResult(),
                sourceType: .diary,
                selectedTab: .constant(.diary),
                diaryEntryId: food.id,
                diaryMealType: mealType,
                diaryQuantity: food.quantity,
                fastingViewModel: fastingViewModelWrapper.viewModel
            )
            .environmentObject(diaryDataManager)
            .environmentObject(subscriptionManager)
            .environmentObject(firebaseManager)
        }
    }
}
