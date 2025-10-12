//
//  SimpleDiaryTabView.swift
//  NutraSafe Beta
//
//  Simplified diary view for basic functionality
//

import SwiftUI

struct SimpleDiaryTabView: View {
    @Binding var selectedTab: TabItem
    @EnvironmentObject var diaryDataManager: DiaryDataManager
    @State private var selectedDate = Date()
    @State private var showingAddFood = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Header
                HStack {
                    Text("Food Diary")
                        .font(.largeTitle)
                        .bold()
                    
                    Spacer()
                    
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .labelsHidden()
                }
                .padding()
                
                // Daily Summary
                VStack(spacing: 16) {
                    HStack {
                        Text("Today's Summary")
                            .font(.headline)
                        Spacer()
                        Text("\(getTotalCalories()) kcal")
                            .font(.title2)
                            .bold()
                    }
                    
                    // Add Food Button
                    Button("Add Food") {
                        selectedTab = .food
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Meal Sections
                List {
                    MealSection(title: "Breakfast", foods: getBreakfastFoods())
                    MealSection(title: "Lunch", foods: getLunchFoods())
                    MealSection(title: "Dinner", foods: getDinnerFoods())
                    MealSection(title: "Snacks", foods: getSnackFoods())
                }
                
                Spacer()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func getTotalCalories() -> Int {
        let (breakfast, lunch, dinner, snacks) = diaryDataManager.getFoodData(for: selectedDate)
        return Int(breakfast.reduce(0) { $0 + $1.adjustedCalories } +
                  lunch.reduce(0) { $0 + $1.adjustedCalories } +
                  dinner.reduce(0) { $0 + $1.adjustedCalories } +
                  snacks.reduce(0) { $0 + $1.adjustedCalories })
    }
    
    private func getBreakfastFoods() -> [DiaryFoodItem] {
        diaryDataManager.getFoodData(for: selectedDate).0
    }
    
    private func getLunchFoods() -> [DiaryFoodItem] {
        diaryDataManager.getFoodData(for: selectedDate).1
    }
    
    private func getDinnerFoods() -> [DiaryFoodItem] {
        diaryDataManager.getFoodData(for: selectedDate).2
    }
    
    private func getSnackFoods() -> [DiaryFoodItem] {
        diaryDataManager.getFoodData(for: selectedDate).3
    }
}

struct MealSection: View {
    let title: String
    let foods: [DiaryFoodItem]
    
    var body: some View {
        Section(title) {
            if foods.isEmpty {
                Text("No foods added")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(foods) { food in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(food.name)
                                .font(.headline)
                            if let brand = food.brand {
                                Text(brand)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Text("\(Int(food.adjustedCalories)) kcal")
                            .font(.subheadline)
                            .bold()
                    }
                }
            }
        }
    }
}

#Preview {
    SimpleDiaryTabView(selectedTab: .constant(.diary))
        .environmentObject(DiaryDataManager.shared)
}