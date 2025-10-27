//
//  DiaryComponents.swift
//  NutraSafe Beta
//
//  Diary-related view components extracted from ContentView.swift
//

import SwiftUI

// MARK: - Diary Meal Card
struct DiaryMealCard: View {
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
    
    private var totalProtein: Double {
        foods.reduce(0) { $0 + $1.protein }
    }
    
    private var totalCarbs: Double {
        foods.reduce(0) { $0 + $1.carbs }
    }
    
    private var totalFat: Double {
        foods.reduce(0) { $0 + $1.fat }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column headers (only show once at the top)
            if mealType == "Breakfast" {
                HStack {
                    Text("ITEM")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

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
            }

            // Rounded pill-style meal header like MyFitnessPal
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)

                    Text(mealType.uppercased())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }

                Spacer()

                // Calories and macros in header like MyFitnessPal
                HStack(spacing: 0) {
                    Text("\(currentCalories)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 50, alignment: .trailing)

                    Text("\(String(format: "%.1f", totalProtein))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .trailing)

                    Text("\(String(format: "%.1f", totalCarbs))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .trailing)

                    Text("\(String(format: "%.1f", totalFat))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .trailing)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(8)

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

                    // Add more button
                    Button(action: {
                        // Store the selected meal type and date, then navigate to add tab
                        UserDefaults.standard.set(mealType, forKey: "preselectedMealType")
                        UserDefaults.standard.set(currentDate.timeIntervalSince1970, forKey: "preselectedDate")
                        selectedTab = .add
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)

                            Text("Add more")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(SpringyButtonStyle())
                }
            } else {
                // Empty state add button
                Button(action: {
                    // Store the selected meal type and date, then navigate to add tab
                    UserDefaults.standard.set(mealType, forKey: "preselectedMealType")
                    UserDefaults.standard.set(currentDate.timeIntervalSince1970, forKey: "preselectedDate")
                    selectedTab = .add
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)

                        Text("Add \(mealType.lowercased())")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.blue)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(SpringyButtonStyle())
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .fill(AppColors.cardBackgroundElevated)
        )
        .cardShadow()
    }
    
    private func deleteFood(at offsets: IndexSet) {
        withAnimation(.easeOut(duration: 0.3)) {
            foods.remove(atOffsets: offsets)
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

    var body: some View {
        Button(action: {
            // Tap always toggles selection
            onTap()
        }) {
            HStack(spacing: 8) {
                // Selection circle (show when any item is selected)
                if hasAnySelection {
                    Circle()
                        .fill(isSelected ? Color.blue : Color.clear)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                        )
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                                .opacity(isSelected ? 1 : 0)
                        )
                }

                // Food name and details
                VStack(alignment: .leading, spacing: 2) {
                    Text(food.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Serving size and quantity
                    HStack(spacing: 4) {
                        Text(food.servingDescription)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)

                        if food.quantity > 1 {
                            Text("× \(String(format: "%.0f", food.quantity))")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Macros aligned with headers like MyFitnessPal
                HStack(spacing: 0) {
                    Text("\(food.calories)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 50, alignment: .trailing)

                    Text("\(String(format: "%.1f", food.protein))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .trailing)

                    Text("\(String(format: "%.1f", food.carbs))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .trailing)

                    Text("\(String(format: "%.1f", food.fat))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .trailing)
                }
            }
            .animation(nil, value: hasAnySelection)  // Disable all implicit animations on layout changes
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture {
            // Long press to view food details
            print("DEBUG: Opening FoodDetailViewFromSearch from diary")
            print("DEBUG: DiaryFoodItem.ingredients = \(food.ingredients?.count ?? 0) items: \(food.ingredients ?? [])")
            let searchResult = food.toFoodSearchResult()
            print("DEBUG: FoodSearchResult.ingredients = \(searchResult.ingredients?.count ?? 0) items: \(searchResult.ingredients ?? [])")
            showingFoodDetail = true
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
        .sheet(isPresented: $showingFoodDetail) {
            FoodDetailViewFromSearch(
                food: food.toFoodSearchResult(),
                sourceType: .diary,
                selectedTab: .constant(.diary),
                destination: .diary,
                diaryEntryId: food.id,
                diaryMealType: mealType
            )
        }
    }
    
    private func processedScoreColor(_ score: String) -> Color {
        switch score.uppercased() {
        case "A+", "A", "A-":
            return Color.green
        case "B+", "B", "B-":
            return Color.blue
        case "C+", "C", "C-":
            return Color.orange
        case "D+", "D", "D-":
            return Color.red.opacity(0.8)
        case "F":
            return Color.red
        default:
            return Color.gray
        }
    }
    
    private func sugarLevelColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "low":
            return Color.green
        case "medium", "med":
            return Color.orange
        case "high":
            return Color.red
        default:
            return Color.gray
        }
    }

    private func containsCommonAllergens(_ ingredients: [String]) -> Bool {
        let commonAllergens = [
            "milk", "dairy", "lactose", "casein", "whey",
            "egg", "eggs", "albumin",
            "peanut", "peanuts", "groundnut",
            "tree nut", "almond", "walnut", "cashew", "pistachio", "pecan",
            "soy", "soya", "soybean",
            "wheat", "gluten", "barley", "rye", "oats",
            "fish", "salmon", "tuna", "cod", "sardine",
            "shellfish", "shrimp", "crab", "lobster", "clam", "oyster",
            "sesame", "sesame seed"
        ]

        let allIngredients = ingredients.joined(separator: " ").lowercased()
        return commonAllergens.contains { allergen in
            allIngredients.contains(allergen)
        }
    }
}