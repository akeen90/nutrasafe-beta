//
//  CreateMealView.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-01-16.
//  View for creating and editing meals in the Meal Builder feature
//

import SwiftUI

struct CreateMealView: View {
    @Binding var selectedTab: TabItem
    var editingMeal: Meal?
    var onComplete: ((TabItem) -> Void)?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var diaryDataManager: DiaryDataManager

    // State
    @State private var mealName: String = ""
    @State private var selectedIcon: String = "fork.knife"
    @State private var mealItems: [MealItem] = []
    @State private var showingAddFood = false
    @State private var showingIconPicker = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showingError = false

    @StateObject private var mealManager = MealManager.shared

    private var isEditing: Bool {
        editingMeal != nil
    }

    private var canSave: Bool {
        !mealName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !mealItems.isEmpty
    }

    // Computed totals
    private var totalCalories: Int {
        mealItems.reduce(0) { $0 + Int(Double($1.calories) * $1.quantity) }
    }

    private var totalProtein: Double {
        mealItems.reduce(0) { $0 + ($1.protein * $1.quantity) }
    }

    private var totalCarbs: Double {
        mealItems.reduce(0) { $0 + ($1.carbs * $1.quantity) }
    }

    private var totalFat: Double {
        mealItems.reduce(0) { $0 + ($1.fat * $1.quantity) }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Meal Name & Icon Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Meal Details")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)

                        HStack(spacing: 14) {
                            // Icon selector button
                            Button(action: { showingIconPicker = true }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.12))
                                        .frame(width: 56, height: 56)

                                    Image(systemName: selectedIcon)
                                        .font(.system(size: 26, weight: .medium))
                                        .foregroundColor(.blue)
                                }
                            }

                            // Name text field
                            TextField("Meal name", text: $mealName)
                                .font(.system(size: 18, weight: .medium))
                                .padding(14)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Nutrition Summary
                    if !mealItems.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Nutrition Total")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)

                            HStack(spacing: 0) {
                                // Calories
                                VStack(spacing: 4) {
                                    Text("\(totalCalories)")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    Text("kcal")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)

                                // Divider
                                Rectangle()
                                    .fill(Color(.systemGray4))
                                    .frame(width: 1, height: 40)

                                // Protein
                                VStack(spacing: 4) {
                                    Text("\(Int(totalProtein))g")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.red)
                                    Text("Protein")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)

                                // Carbs
                                VStack(spacing: 4) {
                                    Text("\(Int(totalCarbs))g")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.orange)
                                    Text("Carbs")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)

                                // Fat
                                VStack(spacing: 4) {
                                    Text("\(Int(totalFat))g")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.purple)
                                    Text("Fat")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.vertical, 16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                    }

                    // Items Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Items")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)

                            Spacer()

                            if !mealItems.isEmpty {
                                Text("\(mealItems.count) item\(mealItems.count == 1 ? "" : "s")")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }

                        if mealItems.isEmpty {
                            // Empty state
                            VStack(spacing: 16) {
                                Image(systemName: "plus.circle.dashed")
                                    .font(.system(size: 44))
                                    .foregroundColor(.secondary.opacity(0.5))

                                Text("No items yet")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)

                                Button(action: { showingAddFood = true }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text("Add Food")
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(20)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        } else {
                            // Items list
                            VStack(spacing: 8) {
                                ForEach(mealItems) { item in
                                    MealItemRow(
                                        item: item,
                                        onUpdateQuantity: { newQuantity in
                                            if let index = mealItems.firstIndex(where: { $0.id == item.id }) {
                                                mealItems[index].quantity = newQuantity
                                            }
                                        },
                                        onDelete: {
                                            mealItems.removeAll { $0.id == item.id }
                                        }
                                    )
                                }

                                // Add more button
                                Button(action: { showingAddFood = true }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 18))
                                        Text("Add More")
                                            .font(.system(size: 15, weight: .medium))
                                    }
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Bottom spacing
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 100)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(isEditing ? "Edit Meal" : "Create Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveMeal) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!canSave || isSaving)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerSheet(selectedIcon: $selectedIcon)
            }
            .fullScreenCover(isPresented: $showingAddFood) {
                AddFoodToMealView(onFoodSelected: { item in
                    mealItems.append(item)
                }, selectedTab: $selectedTab)
                .environmentObject(diaryDataManager)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
            .onAppear {
                if let meal = editingMeal {
                    mealName = meal.name
                    selectedIcon = meal.iconName
                    mealItems = meal.items
                }
            }
        }
    }

    private func saveMeal() {
        let trimmedName = mealName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !mealItems.isEmpty else { return }

        // Check for duplicate name
        if mealManager.mealNameExists(trimmedName, excludingMealId: editingMeal?.id) {
            errorMessage = "A meal with this name already exists"
            showingError = true
            return
        }

        isSaving = true

        Task {
            do {
                if let existingMeal = editingMeal {
                    // Update existing meal
                    var updatedMeal = existingMeal
                    updatedMeal.name = trimmedName
                    updatedMeal.iconName = selectedIcon
                    updatedMeal.items = mealItems
                    try await mealManager.updateMeal(updatedMeal)
                } else {
                    // Create new meal
                    _ = try await mealManager.createMeal(
                        name: trimmedName,
                        items: mealItems,
                        iconName: selectedIcon
                    )
                }

                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Meal Item Row
struct MealItemRow: View {
    let item: MealItem
    let onUpdateQuantity: (Double) -> Void
    let onDelete: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            // Food info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(item.servingDescription)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Quantity stepper
            HStack(spacing: 8) {
                Button(action: {
                    if item.quantity > 0.5 {
                        onUpdateQuantity(item.quantity - 0.5)
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                }

                Text(item.quantity.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(item.quantity))" : String(format: "%.1f", item.quantity))
                    .font(.system(size: 15, weight: .semibold))
                    .frame(minWidth: 24)

                Button(action: {
                    onUpdateQuantity(item.quantity + 0.5)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }
            }

            // Calories
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(Double(item.calories) * item.quantity))")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                Text("kcal")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red.opacity(0.7))
            }
        }
        .padding(14)
        .background(colorScheme == .dark ? Color.midnightCard : Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(.systemGray5), lineWidth: 1)
        )
    }
}

// MARK: - Icon Picker Sheet
struct IconPickerSheet: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss

    private let icons = MealIcon.allCases

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(icons, id: \.rawValue) { icon in
                        Button(action: {
                            selectedIcon = icon.rawValue
                            dismiss()
                        }) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(selectedIcon == icon.rawValue ? Color.blue : Color.blue.opacity(0.1))
                                        .frame(width: 60, height: 60)

                                    Image(systemName: icon.rawValue)
                                        .font(.system(size: 26))
                                        .foregroundColor(selectedIcon == icon.rawValue ? .white : .blue)
                                }

                                Text(icon.displayName)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Add Food to Meal View
struct AddFoodToMealView: View {
    let onFoodSelected: (MealItem) -> Void
    @Binding var selectedTab: TabItem
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var diaryDataManager: DiaryDataManager

    @State private var searchText = ""
    @State private var searchResults: [FoodSearchResult] = []
    @State private var isSearching = false
    @State private var selectedFood: FoodSearchResult?
    @State private var searchTask: Task<Void, Never>?

    @StateObject private var searchDebouncer = Debouncer(milliseconds: 300)

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search foods...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .onChange(of: searchText) { _, newValue in
                            searchDebouncer.debounce {
                                performSearch(query: newValue)
                            }
                        }

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(14)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Results or recent foods
                if isSearching {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No results found")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            // Show recent foods when search is empty
                            if searchText.isEmpty {
                                let recentFoods = diaryDataManager.getRecentFoods()
                                if !recentFoods.isEmpty {
                                    Text("Recent Foods")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 16)
                                        .padding(.top, 16)

                                    ForEach(recentFoods, id: \.id) { food in
                                        AddFoodRow(food: food.toFoodSearchResult()) {
                                            selectedFood = food.toFoodSearchResult()
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                }
                            }

                            // Show search results
                            ForEach(searchResults, id: \.id) { food in
                                AddFoodRow(food: food) {
                                    selectedFood = food
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, 80)
                    }
                }
            }
            .background(Color.adaptiveBackground)
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedFood) { food in
                AddFoodToMealDetailSheet(
                    food: food,
                    onAdd: { item in
                        onFoodSelected(item)
                        dismiss()
                    }
                )
            }
        }
    }

    private func performSearch(query: String) {
        searchTask?.cancel()

        guard !query.isEmpty, query.count >= 2 else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true

        searchTask = Task {
            if Task.isCancelled { return }

            do {
                let results = try await FirebaseManager.shared.searchFoods(query: query)

                if Task.isCancelled { return }

                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                }
            }
        }
    }
}

// MARK: - Add Food Row
private struct AddFoodRow: View {
    let food: FoodSearchResult
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if let brand = food.brand {
                        Text(brand)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text("\(Int(food.calories)) kcal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
            }
            .padding(14)
            .background(colorScheme == .dark ? Color.midnightCard : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color(.systemGray5), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Add Food to Meal Detail Sheet
struct AddFoodToMealDetailSheet: View {
    let food: FoodSearchResult
    let onAdd: (MealItem) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var servingSize: String = "100"
    @State private var servingUnit: String = "g"

    private var servingAmount: Double {
        Double(servingSize) ?? 100.0
    }

    private var multiplier: Double {
        if food.isPerUnit == true {
            return servingAmount
        } else {
            return servingAmount / 100.0
        }
    }

    private var calculatedCalories: Int {
        Int(food.calories * multiplier)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Food info
                VStack(spacing: 8) {
                    Text(food.name)
                        .font(.system(size: 20, weight: .bold))
                        .multilineTextAlignment(.center)

                    if let brand = food.brand {
                        Text(brand)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 20)

                // Serving size input
                VStack(alignment: .leading, spacing: 12) {
                    Text("Serving Size")
                        .font(.system(size: 16, weight: .semibold))

                    HStack(spacing: 12) {
                        TextField("Amount", text: $servingSize)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 18, weight: .medium))
                            .padding(14)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                            .frame(width: 100)

                        Text(food.isPerUnit == true ? "servings" : "g")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                }
                .padding(.horizontal, 24)

                // Nutrition preview
                VStack(spacing: 16) {
                    Text("\(calculatedCalories)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("calories")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)

                    HStack(spacing: 24) {
                        VStack {
                            Text("\(Int(food.protein * multiplier))g")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.red)
                            Text("Protein")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        VStack {
                            Text("\(Int(food.carbs * multiplier))g")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.orange)
                            Text("Carbs")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        VStack {
                            Text("\(Int(food.fat * multiplier))g")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.purple)
                            Text("Fat")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(24)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .padding(.horizontal, 24)

                Spacer()

                // Add button
                Button(action: {
                    let servingDesc = food.isPerUnit == true ? "\(Int(servingAmount)) serving\(servingAmount > 1 ? "s" : "")" : "\(Int(servingAmount))g"
                    let item = MealItem(from: food, servingSize: servingAmount, servingDescription: servingDesc)
                    onAdd(item)
                    dismiss()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("Add to Meal")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    CreateMealView(selectedTab: .constant(.diary))
        .environmentObject(DiaryDataManager.shared)
}
