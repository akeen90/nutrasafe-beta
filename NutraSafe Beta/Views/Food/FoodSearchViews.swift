//
//  FoodSearchViews.swift
//  NutraSafe Beta
//
//  Group A: Food Search & Detail System - Phase 12A Extraction
//  Contains comprehensive food search, detail, and result display components
//  Extracted from ContentView.swift to reduce complexity and improve maintainability
//

import SwiftUI
import Foundation
import UIKit

// MARK: - Food Search Result Components

/// Simplified food search result row for basic display
struct FoodSearchResultRow: View {
    let food: FoodSearchResult
    let onAdd: () -> Void
    
    // Calculate per-serving calories from per-100g values
    private var perServingCalories: Double {
        let servingSize = extractServingSize(from: food.servingDescription)
        return food.calories * (servingSize / 100.0)
    }
    
    // Extract serving size in grams from serving description
    private func extractServingSize(from servingDesc: String?) -> Double {
        guard let servingDesc = servingDesc else { return 100.0 }
        
        // Try to extract numbers from serving description like "39.4g", "1 container (150g)" or "1/2 cup (98g)"
        let patterns = [
            #"(\d+(?:\.\d+)?)\s*g"#,  // Match "39.4g" or "39.4 g"
            #"\((\d+(?:\.\d+)?)\s*g\)"#  // Match "(150g)" in parentheses
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: servingDesc, options: [], range: NSRange(location: 0, length: servingDesc.count)),
               let range = Range(match.range(at: 1), in: servingDesc) {
                return Double(String(servingDesc[range])) ?? 100.0
            }
        }
        
        // If just a number is found, assume it's grams
        if let number = Double(servingDesc.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return number
        }
        
        // Fallback to 100g if no weight found
        return 100.0
    }
    
    var body: some View {
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
            
            VStack {
                Text("\(Int(perServingCalories))")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("kcal")
                    .font(.caption)
            }
            
            Button(action: onAdd) {
                Image(systemName: "arrow.right.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(16)
    }
}

// MARK: - Enhanced Food Search Result Row

/// Enhanced food search result row with comprehensive nutrition display and grades
struct FoodSearchResultRowEnhanced: View {
    let food: FoodSearchResult
    let sourceType: FoodSourceType
    @Binding var selectedTab: TabItem
    @Binding var destination: AddFoodMainView.AddDestination
    @State private var showingFoodDetail = false
    @State private var showingFridgeSheet = false
    @State private var isPressed = false
    @EnvironmentObject var diaryDataManager: DiaryDataManager

    init(food: FoodSearchResult, sourceType: FoodSourceType = .search, selectedTab: Binding<TabItem>, destination: Binding<AddFoodMainView.AddDestination>) {
        self.food = food
        self.sourceType = sourceType
        self._selectedTab = selectedTab
        self._destination = destination
    }
    
    private var nutritionScore: ProcessingGrade {
        let ingredientsString = food.ingredients?.joined(separator: ", ")
        return ProcessingScorer.shared.calculateProcessingScore(for: food.name, ingredients: ingredientsString).grade
    }
    
    private var sugarGrade: SugarGrade {
        return SugarContentScorer.shared.calculateSugarScore(sugarPer100g: food.sugar).grade
    }
    
    // Calculate per-serving calories from per-100g values
    private var perServingCalories: Double {
        let servingSize = extractServingSize(from: food.servingDescription)
        return food.calories * (servingSize / 100.0)
    }
    
    // Extract serving size in grams from serving description
    private func extractServingSize(from servingDesc: String?) -> Double {
        guard let servingDesc = servingDesc else { return 100.0 }
        
        // Try to extract numbers from serving description like "39.4g", "1 container (150g)" or "1/2 cup (98g)"
        let patterns = [
            #"(\d+(?:\.\d+)?)\s*g"#,  // Match "39.4g" or "39.4 g"
            #"\((\d+(?:\.\d+)?)\s*g\)"#  // Match "(150g)" in parentheses
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: servingDesc, options: [], range: NSRange(location: 0, length: servingDesc.count)),
               let range = Range(match.range(at: 1), in: servingDesc) {
                return Double(String(servingDesc[range])) ?? 100.0
            }
        }
        
        // If just a number is found, assume it's grams
        if let number = Double(servingDesc.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return number
        }
        
        // Fallback to 100g if no weight found
        return 100.0
    }
    
    var body: some View {
        Button(action: {
            if destination == .fridge {
                showingFridgeSheet = true
            } else {
                showingFoodDetail = true
            }
        }) {
            HStack(spacing: 12) {
                // Product name and brand
                VStack(alignment: .leading, spacing: 2) {
                    Text(food.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    if let brand = food.brand {
                        Text(brand)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
        }
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
        .contentShape(Rectangle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {
            if destination == .fridge {
                showingFridgeSheet = true
            } else {
                showingFoodDetail = true
            }
        })
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    if destination == .fridge {
                        showingFridgeSheet = true
                    } else {
                        showingFoodDetail = true
                    }
                }
        )
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingFoodDetail) {
            FoodDetailViewFromSearch(food: food, sourceType: sourceType, selectedTab: $selectedTab, destination: destination)
                .environmentObject(diaryDataManager)
        }
        .sheet(isPresented: $showingFridgeSheet) {
            AddFoundFoodToFridgeSheet(food: food) { tab in
                selectedTab = tab
            }
        }
    }
}

// MARK: - Nutrient Tag Component

/// Small colored tag displaying nutrient value and label
struct NutrientTag: View {
    let value: Double
    let unit: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 1) {
            Text(String(format: "%.1f", value))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(color)
        .cornerRadius(8)
        .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Food Source Type Enum

/// Enumeration for different food search sources
enum FoodSourceType {
    case search, barcode, ai, manual, diary, fridge
}

// MARK: - Main Food Search View

/// Comprehensive food search interface with live search, recent foods, and keyboard handling
struct AddFoodSearchView: View {
    @Binding var selectedTab: TabItem
    @Binding var destination: AddFoodMainView.AddDestination
    @State private var searchText = ""
    @State private var searchResults: [FoodSearchResult] = []
    @State private var isSearching = false
    @EnvironmentObject var diaryDataManager: DiaryDataManager
    @State private var recentFoods: [DiaryFoodItem] = []
    @State private var searchTask: Task<Void, Never>?
    @State private var keyboardHeight: CGFloat = 0
    @State private var isEditingMode = false
    @State private var editingFoodName = ""
    @State private var originalMealType = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar - fixed at top
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search foods...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchText, perform: { newValue in
                            performLiveSearch(query: newValue)
                        })
                        .onSubmit {
                            performSearch()
                        }

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(Color(.systemBackground))
            .zIndex(1) // Keep search bar on top

            // Results
            if isSearching {
                VStack {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                }
                .frame(maxHeight: .infinity)
            } else if searchResults.isEmpty && !searchText.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No results found")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    Spacer()
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            // Show recent foods when search is empty
                            if searchText.isEmpty && !recentFoods.isEmpty {
                                // Recent Foods Section
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 16, weight: .medium))
                                        Text("Recent Foods")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.top, 16)

                                    ForEach(recentFoods, id: \.id) { recentFood in
                                        let searchResult = convertToSearchResult(recentFood)
                                        FoodSearchResultRowEnhanced(food: searchResult, selectedTab: $selectedTab, destination: $destination)
                                            .padding(.horizontal, 16)
                                    }
                                }
                            }

                            // Show search results when searching
                            ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, food in
                                FoodSearchResultRowEnhanced(food: food, selectedTab: $selectedTab, destination: $destination)
                                    .id("result_\(index)")
                            }

                            // Spacer for keyboard
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: keyboardHeight > 0 ? keyboardHeight + 20 : 80)
                                .id("bottom_spacer")
                        }
                        .padding(.horizontal, searchText.isEmpty ? 0 : 16)
                        .padding(.top, searchText.isEmpty ? 0 : 16)
                    }
                    .frame(maxHeight: .infinity)
                    .modifier(ScrollDismissModifier())
                    .onChange(of: searchResults.count) { newCount in
                        // Auto-scroll to show first result when results appear
                        if newCount > 0 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    scrollProxy.scrollTo("result_0", anchor: .top)
                                }
                            }
                        }
                    }
                    .onChange(of: keyboardHeight) { height in
                        // Also scroll when keyboard appears if we have results
                        if height > 0 && !searchResults.isEmpty {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    scrollProxy.scrollTo("result_0", anchor: .top)
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            setupKeyboardObservers()
            checkForEditingMode()
            loadRecentFoods()
        }
        .onDisappear {
            removeKeyboardObservers()
        }
    }
    
    private func checkForEditingMode() {
        if let mode = UserDefaults.standard.string(forKey: "foodSearchMode"), mode == "editing" {
            isEditingMode = true
            editingFoodName = UserDefaults.standard.string(forKey: "editingFoodName") ?? ""
            originalMealType = UserDefaults.standard.string(forKey: "editingMealType") ?? ""
            
            // Pre-populate search with the food being edited
            searchText = editingFoodName
            if !editingFoodName.isEmpty {
                performSearch()
            }
            
            // Clear the editing flags
            UserDefaults.standard.removeObject(forKey: "foodSearchMode")
            UserDefaults.standard.removeObject(forKey: "editingFoodName")
            UserDefaults.standard.removeObject(forKey: "editingMealType")
        } else {
            isEditingMode = false
            editingFoodName = ""
            originalMealType = ""
        }
    }
    
    private func performLiveSearch(query: String) {
        // Cancel previous search
        searchTask?.cancel()
        
        guard !query.isEmpty, query.count >= 2 else {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        
        // Debounce search by 0.5 seconds
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            if Task.isCancelled { return }
            
            do {
                let results = try await FirebaseManager.shared.searchFoods(query: query)
                
                if Task.isCancelled { return }
                
                // Check for pending verifications with extracted ingredients
                var enrichedResults = results
                
                // Get pending verifications for this user
                do {
                    let pendingVerifications = try await FirebaseManager.shared.getPendingVerifications()
                    
                    // Find matching foods and add pending ingredients
                    for i in 0..<enrichedResults.count {
                        let result = enrichedResults[i]
                        
                        // Look for matching pending verifications by name/brand
                        let matchingVerifications = pendingVerifications.filter { pending in
                            let nameMatch = pending.foodName.lowercased() == result.name.lowercased()
                            let brandMatch = (pending.brandName?.lowercased() ?? "") == (result.brand?.lowercased() ?? "")
                            return nameMatch && (brandMatch || (pending.brandName == nil && result.brand == nil))
                        }
                        
                        // If we found a matching verification with ingredients, use those
                        if let pendingMatch = matchingVerifications.first,
                           let ingredients = pendingMatch.ingredients,
                           !ingredients.isEmpty,
                           ingredients != "Processing ingredient image..." {
                            
                            // Create new search result with pending ingredients
                            enrichedResults[i] = FoodSearchResult(
                                id: result.id,
                                name: result.name,
                                brand: result.brand,
                                calories: result.calories,
                                protein: result.protein,
                                carbs: result.carbs,
                                fat: result.fat,
                                fiber: result.fiber,
                                sugar: result.sugar,
                                sodium: result.sodium,
                                servingDescription: result.servingDescription,
                                ingredients: [ingredients + " (⏳ Awaiting Verification)"]
                            )
                        }
                    }
                } catch {
                    print("Failed to check pending verifications: \(error)")
                    // Continue with original results if pending check fails
                }
                
                await MainActor.run {
                    print("🍎 Setting search results: \(enrichedResults.count) foods found")
                    print("🍎 First few results: \(enrichedResults.prefix(3).map { "\($0.name) (\($0.brand ?? "no brand"))" })")
                    self.searchResults = enrichedResults
                    self.isSearching = false
                }
            } catch {
                print("❌ Search failed with error: \(error)")
                
                if Task.isCancelled { return }
                
                await MainActor.run {
                    print("🍎 Search failed - setting empty results")
                    self.searchResults = []
                    self.isSearching = false
                }
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        performLiveSearch(query: searchText)
    }
    
    private func loadRecentFoods() {
        recentFoods = diaryDataManager.getRecentFoods()
    }
    
    private func convertToSearchResult(_ diaryItem: DiaryFoodItem) -> FoodSearchResult {
        return FoodSearchResult(
            id: diaryItem.id.uuidString,
            name: diaryItem.name,
            brand: nil,
            calories: Double(diaryItem.calories),
            protein: diaryItem.protein,
            carbs: diaryItem.carbs,
            fat: diaryItem.fat,
            fiber: 0.0, // Default value
            sugar: 0.0, // Default value
            sodium: 0.0, // Default value
            servingDescription: "100g",
            ingredients: diaryItem.ingredients,
            confidence: nil,
            isVerified: true, // Recent foods are already verified
            additives: nil,
            processingScore: nil,
            processingGrade: nil,
            processingLabel: diaryItem.processedScore
        )
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                keyboardHeight = 0
            }
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

// MARK: - Food Detail View (Diary Items)

/// Comprehensive food detail view for diary food items with serving size controls and nutrition analysis
struct FoodDetailView: View {
    let food: DiaryFoodItem
    @State private var selectedServingIndex = 0
    @State private var quantity: Double = 1.0
    @State private var customGrams: String = ""
    @State private var isCustomGrams = false
    @Environment(\.dismiss) private var dismiss
    
    // Mock serving options - in production these would come from the food data
    private var servingOptions: [FoodServingOption] {
        [
            FoodServingOption(name: "1 serving", unit: "serving", grams: 100.0, isCommon: true),
            FoodServingOption(name: "100g", unit: "g", grams: 100.0, isCommon: false),
            FoodServingOption(name: "1 cup", unit: "cup", grams: 150.0, isCommon: false),
            FoodServingOption(name: "Custom", unit: "g", grams: 100.0, isCommon: false)
        ]
    }
    
    private var selectedServing: FoodServingOption {
        servingOptions[selectedServingIndex]
    }
    
    private var actualGrams: Double {
        if isCustomGrams, let customValue = Double(customGrams), customValue > 0 {
            return customValue
        }
        return selectedServing.grams * quantity
    }
    
    private var scalingFactor: Double {
        actualGrams / 100.0 // Assuming nutrition is per 100g
    }
    
    private var scaledCalories: Int {
        Int(Double(food.calories) * scalingFactor)
    }
    
    private var scaledProtein: Double {
        food.protein * scalingFactor
    }
    
    private var scaledCarbs: Double {
        food.carbs * scalingFactor
    }
    
    private var scaledFat: Double {
        food.fat * scalingFactor
    }
    
    private var glycemicData: GlycemicIndexData? {
        // Calculate GI based on actual macro data - much more accurate!
        GlycemicIndexDatabase.shared.getGIData(
            for: food.name,
            carbs: scaledCarbs,
            sugar: 0.0, // DiaryFoodItem doesn't have sugar data
            fiber: 0.0, // DiaryFoodItem doesn't have fiber data  
            protein: scaledProtein,
            fat: scaledFat
        )
    }
    
    private var glycemicLoad: Double? {
        guard let giData = glycemicData, let giValue = giData.value else { return nil }
        let carbGrams = scaledCarbs
        return (Double(giValue) * carbGrams) / 100.0
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(food.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        if let brand = extractBrand(from: food.name) {
                            Text(brand)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Serving Size Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Serving Size")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        // Serving options picker
                        Picker("Serving Size", selection: $selectedServingIndex) {
                            ForEach(0..<servingOptions.count, id: \.self) { index in
                                Text(servingOptions[index].name)
                                    .tag(index)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedServingIndex, perform: { newValue in
                            isCustomGrams = (newValue == servingOptions.count - 1)
                            if !isCustomGrams {
                                customGrams = ""
                            }
                        })
                        
                        // Custom grams input
                        if isCustomGrams {
                            HStack {
                                TextField("Enter grams", text: $customGrams)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                Text("g")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Quantity selector
                        if !isCustomGrams {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Quantity")
                                    .font(.system(size: 16, weight: .medium))
                                
                                HStack(spacing: 12) {
                                    Button(action: {
                                        if quantity > 0.25 {
                                            quantity -= 0.25
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Text(String(format: "%.2g", quantity))
                                        .font(.system(size: 18, weight: .medium))
                                        .frame(minWidth: 60)
                                    
                                    Button(action: {
                                        quantity += 0.25
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                        
                        // Total weight display
                        Text("Total: \(String(format: "%.0f", actualGrams))g")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Nutrition Summary
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Nutrition")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        // Large calorie display
                        HStack {
                            Text("\(scaledCalories)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.primary)
                            Text("kcal")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)
                            Spacer()
                        }
                        
                        // Macronutrient breakdown
                        VStack(spacing: 12) {
                            MacroNutrientRow(label: "Protein", value: scaledProtein, unit: "g", color: .red)
                            MacroNutrientRow(label: "Carbohydrate", value: scaledCarbs, unit: "g", color: .orange)
                            MacroNutrientRow(label: "Fat", value: scaledFat, unit: "g", color: .purple)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Glycemic Index Information
                    if let giData = glycemicData {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Glycemic Information")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Glycemic Index:")
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(giData.value ?? 0)")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(giData.category.color)
                                    Text("(\(giData.category.rawValue.capitalized))")
                                        .font(.system(size: 14))
                                        .foregroundColor(giData.category.color)
                                }
                                
                                if let gl = glycemicLoad {
                                    HStack {
                                        Text("Glycemic Load:")
                                            .font(.system(size: 16))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text(String(format: "%.1f", gl))
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(glColor(for: gl))
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Processing Score
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Processing Score")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        HStack {
                            // DiaryFoodItem doesn't have ingredients, use food name only
                            let score = ProcessingScorer.shared.calculateProcessingScore(for: food.name)
                            
                            // Score circle
                            ZStack {
                                Circle()
                                    .fill(score.grade.color)
                                    .frame(width: 50, height: 50)
                                
                                Text(score.grade.rawValue)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(score.processingLevel.rawValue)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Text(score.explanation)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Ingredients Section
                    if let ingredientsArray = food.ingredients, !ingredientsArray.isEmpty {
                        ingredientsSection(ingredients: ingredientsArray)
                    }
                    
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func extractBrand(from name: String) -> String? {
        // Simple brand extraction - could be enhanced
        let components = name.components(separatedBy: " - ")
        return components.count > 1 ? components.last : nil
    }
    
    private func glColor(for gl: Double) -> Color {
        if gl < 10 { return .green }
        else if gl < 20 { return .orange }
        else { return .red }
    }
    
    @ViewBuilder
    private func ingredientsSection(ingredients: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(ingredients.enumerated()), id: \.offset) { index, ingredient in
                    ingredientRow(ingredient: ingredient, isLast: index == ingredients.count - 1)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            allergenSection(ingredients: ingredients)
            
            // Disclaimer
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    
                    Text("Always check the physical product label for the most current ingredients and allergen information, as formulations may change.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6).opacity(0.6))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func ingredientRow(ingredient: String, isLast: Bool) -> some View {
        HStack {
            Text("• \(ingredient)")
                .font(.system(size: 14))
                .foregroundColor(.primary)
            Spacer()
        }
        
        if !isLast {
            Divider()
                .padding(.leading, 12)
        }
    }
    
    @ViewBuilder
    private func allergenSection(ingredients: [String]) -> some View {
        let detectedAllergens = detectAllergens(in: ingredients)
        let userAllergens = getUserAllergens()
        
        if !detectedAllergens.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Allergen Information")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], alignment: .leading, spacing: 8) {
                    ForEach(detectedAllergens.sorted(by: { $0.displayName < $1.displayName }), id: \.rawValue) { allergen in
                        let isUserAllergen = userAllergens.contains(allergen)
                        
                        HStack(spacing: 6) {
                            Text(allergen.icon)
                                .font(.system(size: 14))
                            
                            Text(allergen.displayName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(isUserAllergen ? .white : .primary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isUserAllergen ? .red : .yellow.opacity(0.3))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isUserAllergen ? .red : .yellow, lineWidth: 1)
                        )
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
    
    private func getUserAllergens() -> [Allergen] {
        // For now, return a mock user allergen list
        // In a real app, this would be stored in UserDefaults or Core Data
        return [.dairy, .treeNuts] // Example: user is allergic to dairy and tree nuts
    }
    
    private func detectAllergens(in ingredients: [String]) -> [Allergen] {
        let combinedIngredients = ingredients.joined(separator: " ").lowercased()
        var detectedAllergens: [Allergen] = []
        
        for allergen in Allergen.allCases {
            if isAllergenPresent(allergen, in: combinedIngredients) {
                detectedAllergens.append(allergen)
            }
        }
        
        return detectedAllergens
    }
    
    private func isAllergenPresent(_ allergen: Allergen, in text: String) -> Bool {
        let keywords: [String]
        
        switch allergen {
        case .dairy:
            keywords = ["milk", "dairy", "cheese", "butter", "cream", "yogurt", "whey", "casein", "lactose"]
        case .eggs:
            keywords = ["egg", "albumin", "mayonnaise"]
        case .fish:
            keywords = ["fish", "salmon", "tuna", "cod", "anchovy"]
        case .shellfish:
            keywords = ["shrimp", "crab", "lobster", "shellfish", "prawns"]
        case .treeNuts:
            keywords = ["almond", "walnut", "pecan", "cashew", "pistachio", "hazelnut", "macadamia"]
        case .peanuts:
            keywords = ["peanut", "groundnut"]
        case .wheat:
            keywords = ["wheat", "flour", "gluten", "semolina", "durum"]
        case .soy:
            keywords = ["soy", "soya", "tofu", "tempeh", "miso", "edamame"]
        case .sesame:
            keywords = ["sesame", "tahini"]
        case .gluten:
            keywords = ["gluten", "wheat", "barley", "rye", "oats"]
        case .lactose:
            keywords = ["lactose", "milk", "dairy"]
        case .sulfites:
            keywords = ["sulfite", "sulphite", "preservative"]
        case .msg:
            keywords = ["msg", "monosodium glutamate"]
        case .corn:
            keywords = ["corn", "maize", "cornstarch"]
        }
        
        return keywords.contains { text.contains($0) }
    }
}

// MARK: - Supporting Components

/// Displays macro nutrient information in a formatted row
struct MacroNutrientRow: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(String(format: "%.1f", value))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            Text(unit)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

/// Compact macro value display for search result rows  
struct MacroValue: View {
    let value: Double
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
            Text(String(format: "%.0f", value))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
        }
        .frame(minWidth: 30)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.12))
        )
    }
}

// MARK: - Sample Data

/// Sample search results for testing and development
let sampleSearchResults: [FoodSearchResult] = [
    FoodSearchResult(id: "1", name: "Greek Yoghurt", brand: "Fage", calories: 100, protein: 18.0, carbs: 6.0, fat: 0.0, fiber: 0, sugar: 6.0, sodium: 50, servingDescription: "1 container (150g)", ingredients: nil),
    FoodSearchResult(id: "2", name: "Banana", brand: nil, calories: 89, protein: 1.1, carbs: 23.0, fat: 0.3, fiber: 2.6, sugar: 12.2, sodium: 1, servingDescription: "1 medium (118g)", ingredients: nil),
    FoodSearchResult(id: "3", name: "Chicken Breast", brand: nil, calories: 165, protein: 31.0, carbs: 0.0, fat: 3.6, fiber: 0, sugar: 0, sodium: 74, servingDescription: "per 100g", ingredients: nil),
    FoodSearchResult(id: "4", name: "Brown Rice", brand: nil, calories: 111, protein: 2.6, carbs: 23.0, fat: 0.9, fiber: 1.8, sugar: 0.4, sodium: 5, servingDescription: "1/2 cup cooked (98g)", ingredients: nil),
    FoodSearchResult(id: "5", name: "Avocado", brand: nil, calories: 160, protein: 2.0, carbs: 8.5, fat: 14.7, fiber: 6.7, sugar: 0.7, sodium: 7, servingDescription: "1/2 medium (100g)", ingredients: nil),
    FoodSearchResult(id: "6", name: "Spinach", brand: nil, calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4, fiber: 2.2, sugar: 0.4, sodium: 79, servingDescription: "1 cup fresh (30g)", ingredients: nil),
    FoodSearchResult(id: "7", name: "Salmon", brand: nil, calories: 208, protein: 22.0, carbs: 0.0, fat: 12.4, fiber: 0, sugar: 0, sodium: 59, servingDescription: "per 100g", ingredients: nil),
    FoodSearchResult(id: "8", name: "Oats", brand: "Quaker", calories: 150, protein: 5.0, carbs: 27.0, fat: 3.0, fiber: 4.0, sugar: 1.1, sodium: 2, servingDescription: "1/2 cup dry (40g)", ingredients: nil),
    // Additional foods to test allergen detection
    FoodSearchResult(id: "9", name: "Whole Milk", brand: "Organic Valley", calories: 150, protein: 8.0, carbs: 12.0, fat: 8.0, fiber: 0, sugar: 12.0, sodium: 105, servingDescription: "1 cup (240ml)", ingredients: nil),
    FoodSearchResult(id: "10", name: "Scrambled Eggs", brand: nil, calories: 155, protein: 13.0, carbs: 1.0, fat: 11.0, fiber: 0, sugar: 1.0, sodium: 124, servingDescription: "1 large egg (50g)", ingredients: nil),
    FoodSearchResult(id: "11", name: "Wheat Bread", brand: "Hovis", calories: 265, protein: 9.0, carbs: 49.0, fat: 3.2, fiber: 2.7, sugar: 3.0, sodium: 491, servingDescription: "2 slices (60g)", ingredients: nil),
    FoodSearchResult(id: "12", name: "Cheddar Cheese", brand: nil, calories: 403, protein: 25.0, carbs: 1.3, fat: 33.0, fiber: 0, sugar: 0.5, sodium: 621, servingDescription: "per 100g", ingredients: nil)
]