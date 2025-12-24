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

final class LocalGradeCache {
    static let processing = NSCache<NSString, NSString>()
    static let sugar = NSCache<NSString, NSString>()
}

// MARK: - Pre-compiled Regex Patterns (Performance Optimization)
// Regex compilation is expensive (~100x slower than string ops)
// Pre-compile once at app launch instead of per-call
private enum ServingSizePatterns {
    static let gramPattern = try! NSRegularExpression(pattern: #"(\d+(?:\.\d+)?)\s*g"#, options: [])
    static let parenthesesGramPattern = try! NSRegularExpression(pattern: #"\((\d+(?:\.\d+)?)\s*g\)"#, options: [])
    static let allPatterns: [NSRegularExpression] = [gramPattern, parenthesesGramPattern]
}

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
    // Uses pre-compiled regexes for performance
    private func extractServingSize(from servingDesc: String?) -> Double {
        guard let servingDesc = servingDesc else { return 100.0 }

        // Use pre-compiled patterns instead of compiling on each call
        for regex in ServingSizePatterns.allPatterns {
            if let match = regex.firstMatch(in: servingDesc, options: [], range: NSRange(location: 0, length: servingDesc.count)),
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
        Button(action: onAdd) {
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

                Image(systemName: "arrow.right.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .padding(16)
    }
}

// MARK: - Enhanced Food Search Result Row

/// Enhanced food search result row with comprehensive nutrition display and grades (DIARY-ONLY)
struct FoodSearchResultRowEnhanced: View {
    let food: FoodSearchResult
    let sourceType: FoodSourceType
    @Binding var selectedTab: TabItem
    var onComplete: ((TabItem) -> Void)?
    @State private var showingFoodDetail = false
    @State private var isPressed = false
    @EnvironmentObject var diaryDataManager: DiaryDataManager

    // PERFORMANCE: Use @State for grades to enable async background computation
    // Prevents blocking main thread during scroll with expensive scoring calculations
    @State private var computedProcessingGrade: ProcessingGrade?
    @State private var computedSugarGrade: SugarGrade?

    init(food: FoodSearchResult, sourceType: FoodSourceType = .search, selectedTab: Binding<TabItem>, onComplete: ((TabItem) -> Void)? = nil) {
        self.food = food
        self.sourceType = sourceType
        self._selectedTab = selectedTab
        self.onComplete = onComplete
    }

    // Use cached/computed grade, or show placeholder during computation
    private var nutritionScore: ProcessingGrade {
        // First check if we already computed it
        if let computed = computedProcessingGrade {
            return computed
        }
        // Check precomputed from food data
        if let precomputedGrade = food.processingGrade,
           let grade = ProcessingGrade(rawValue: precomputedGrade) {
            return grade
        }
        // Check local cache
        let key = NSString(string: food.id)
        if let cached = LocalGradeCache.processing.object(forKey: key),
           let grade = ProcessingGrade(rawValue: cached as String) {
            return grade
        }
        // Return placeholder while computing in background
        return .unknown
    }

    private var sugarGrade: SugarGrade {
        if let computed = computedSugarGrade {
            return computed
        }
        let key = NSString(string: food.id)
        if let cached = LocalGradeCache.sugar.object(forKey: key),
           let grade = SugarGrade(rawValue: cached as String) {
            return grade
        }
        return .unknown
    }

    // Compute grades in background task
    private func computeGradesIfNeeded() {
        // Processing grade
        if computedProcessingGrade == nil {
            if let precomputedGrade = food.processingGrade,
               let grade = ProcessingGrade(rawValue: precomputedGrade) {
                computedProcessingGrade = grade
            } else {
                let key = NSString(string: food.id)
                if let cached = LocalGradeCache.processing.object(forKey: key),
                   let grade = ProcessingGrade(rawValue: cached as String) {
                    computedProcessingGrade = grade
                } else {
                    // Compute in background
                    let ingredientsString = food.ingredients?.joined(separator: ", ")
                    let foodName = food.name
                    Task.detached(priority: .utility) {
                        let computed = ProcessingScorer.shared.calculateProcessingScore(for: foodName, ingredients: ingredientsString).grade
                        LocalGradeCache.processing.setObject(NSString(string: computed.rawValue), forKey: key)
                        await MainActor.run {
                            self.computedProcessingGrade = computed
                        }
                    }
                }
            }
        }

        // Sugar grade
        if computedSugarGrade == nil {
            let key = NSString(string: food.id)
            if let cached = LocalGradeCache.sugar.object(forKey: key),
               let grade = SugarGrade(rawValue: cached as String) {
                computedSugarGrade = grade
            } else {
                let sugar = food.sugar
                Task.detached(priority: .utility) {
                    let computed = SugarContentScorer.shared.calculateSugarScore(sugarPer100g: sugar).grade
                    LocalGradeCache.sugar.setObject(NSString(string: computed.rawValue), forKey: key)
                    await MainActor.run {
                        self.computedSugarGrade = computed
                    }
                }
            }
        }
    }
    
    // Calculate per-serving calories from per-100g values
    private var perServingCalories: Double {
        let servingSize = extractServingSize(from: food.servingDescription)
        return food.calories * (servingSize / 100.0)
    }
    
    // Extract serving size in grams from serving description
    // Uses pre-compiled regexes for performance
    private func extractServingSize(from servingDesc: String?) -> Double {
        guard let servingDesc = servingDesc else { return 100.0 }

        // Use pre-compiled patterns instead of compiling on each call
        for regex in ServingSizePatterns.allPatterns {
            if let match = regex.firstMatch(in: servingDesc, options: [], range: NSRange(location: 0, length: servingDesc.count)),
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
            // Dismiss keyboard BEFORE showing sheet to prevent refocus when sheet dismisses
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
            showingFoodDetail = true
        }) {
            HStack(spacing: 12) {
                // Product name and brand
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if let brand = food.brand {
                        Text(brand)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }

                    if let servingDesc = food.servingDescription, !servingDesc.isEmpty {
                        Text(servingDesc)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.systemGray3))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(.systemGray5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingFoodDetail) {
            FoodDetailViewFromSearch(food: food, sourceType: sourceType, selectedTab: $selectedTab) { tab in
                onComplete?(tab)
            }
            .environmentObject(diaryDataManager)
        }
        .onAppear {
            // PERFORMANCE: Compute grades in background when row appears
            // This prevents blocking main thread during scroll
            computeGradesIfNeeded()
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
    case search, barcode, ai, manual, diary, useBy
}

// MARK: - Main Food Search View

/// Comprehensive food search interface with live search, recent foods, and keyboard handling (DIARY-ONLY)
struct AddFoodSearchView: View {
    @Binding var selectedTab: TabItem
    var onComplete: ((TabItem) -> Void)?
    var onSwitchToManual: (() -> Void)? = nil
    @State private var searchText = ""
    @State private var searchResults: [FoodSearchResult] = []
    @State private var isSearching = false
    @EnvironmentObject var diaryDataManager: DiaryDataManager
    @State private var recentFoods: [DiaryFoodItem] = []
    @State private var searchTask: Task<Void, Never>?
    @State private var keyboardHeight: CGFloat = 0
    @State private var isEditingMode = false

    // PERFORMANCE: Debouncer to prevent search from running on every keystroke
    @StateObject private var searchDebouncer = Debouncer(milliseconds: 300)
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
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .onChange(of: searchText) { _, newValue in
                            // PERFORMANCE: Debounce search to avoid running expensive operations on every keystroke
                            searchDebouncer.debounce {
                                performLiveSearch(query: newValue)
                            }
                        }
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
            .background(Color.adaptiveBackground)
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

                    VStack(spacing: 24) {
                        // Icon and message
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.4))

                        VStack(spacing: 8) {
                            Text("No foods found")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.primary)

                            Text("matching '\(searchText)'")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }

                        // Helpful tips
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)
                                    .frame(width: 20)

                                Text("Try a different search term")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                                    .frame(width: 20)

                                Text("Scan a barcode for instant results")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14))
                                    .foregroundColor(.purple)
                                    .frame(width: 20)

                                Text("Use our AI Finder for better accuracy")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal, 32)

                        // AI Finder CTA
                        if onSwitchToManual != nil {
                            Button(action: {
                                onSwitchToManual?()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Try AI Finder")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                    }

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
                                        FoodSearchResultRowEnhanced(food: searchResult, selectedTab: $selectedTab, onComplete: onComplete)
                                            .padding(.horizontal, 16)
                                    }
                                }
                            }

                            // Show search results when searching
                            ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, food in
                                FoodSearchResultRowEnhanced(food: food, selectedTab: $selectedTab, onComplete: onComplete)
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
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .onChange(of: searchResults.count) { _, newCount in
                        // Auto-scroll to show first result when results appear
                        if newCount > 0 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    scrollProxy.scrollTo("result_0", anchor: .top)
                                }
                            }
                        }
                    }
                    .onChange(of: keyboardHeight) { _, height in
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

        // Normalize query: remove apostrophes so "mcdonald's" and "mcdonalds" search the same
        let normalizedQuery = query.replacingOccurrences(of: "'", with: "")
                                   .replacingOccurrences(of: "'", with: "") // Also handle curly apostrophe

        #if DEBUG
        print("🔎 AddFoodSearchView: Starting search for '\(query)' → normalized: '\(normalizedQuery)' (length: \(normalizedQuery.count))")
        #endif

        isSearching = true

        // Instant search - no debounce for immediate feedback
        searchTask = Task {
            if Task.isCancelled {
                #if DEBUG
                print("⚠️ AddFoodSearchView: Search cancelled for '\(normalizedQuery)'")
                #endif
                return
            }

            // Try search (Firebase searchFoods already includes Algolia via backend)
            var results: [FoodSearchResult] = []

            do {
                results = try await FirebaseManager.shared.searchFoods(query: normalizedQuery)

                #if DEBUG
                print("✅ Search complete: Found \(results.count) results")
                #endif
            } catch {
                #if DEBUG
                print("❌ Search failed: \(error)")
                #endif
            }

            if Task.isCancelled { return }

            // Show results immediately for instant feedback
            await MainActor.run {
                #if DEBUG
                print("⚡️ Showing \(results.count) results immediately (instant feedback)")
                #endif
                self.searchResults = results
                self.isSearching = false
            }

            // OPTIONAL: Check for pending verifications in background (non-blocking)
            // This enriches results with pending ingredient data but doesn't delay the UI
            let capturedResults = results // Capture immutable copy for Swift 6 concurrency
            Task.detached(priority: .background) {
                do {
                    let pendingVerifications = try await FirebaseManager.shared.getPendingVerifications()

                    if Task.isCancelled { return }

                    var enrichedResults = capturedResults
                    var hasChanges = false

                    // Find matching foods and add pending ingredients
                    for i in 0..<enrichedResults.count {
                        let result = enrichedResults[i]

                        // Match strictly by name AND brand when both are present
                        let matchingVerifications = pendingVerifications.filter { pending in
                            let nameMatch = pending.foodName.lowercased() == result.name.lowercased()
                            guard let pendingBrand = pending.brandName?.trimmingCharacters(in: .whitespacesAndNewlines),
                                  !pendingBrand.isEmpty,
                                  let resultBrand = result.brand?.trimmingCharacters(in: .whitespacesAndNewlines),
                                  !resultBrand.isEmpty else {
                                return false
                            }
                            let brandMatch = pendingBrand.lowercased() == resultBrand.lowercased()
                            return nameMatch && brandMatch
                        }

                        // If we found a matching verification with ingredients, use those
                        if let pendingMatch = matchingVerifications.first,
                           let ingredients = pendingMatch.ingredients,
                           !ingredients.isEmpty,
                           ingredients != "Processing ingredient image..." {

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
                            hasChanges = true
                        }
                    }

                    // Only update UI if we actually found pending data
                    if hasChanges, !Task.isCancelled {
                        let finalResults = enrichedResults // Capture for Swift 6 concurrency
                        await MainActor.run {
                            #if DEBUG
                            print("✅ Updated results with pending verification data")
                            #endif
                            self.searchResults = finalResults
                        }
                    }
                } catch {
                    #if DEBUG
                    print("⚠️ Background pending verification check failed (non-critical): \(error)")
                    #endif
                    // Silently fail - results already showing
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
        // Use the canonical conversion to ensure nutrients are per-100g
        // and the actual serving size from the diary item is preserved.
        let base = diaryItem.toFoodSearchResult()
        let ns = ProcessingScorer.shared.computeNutraSafeProcessingGrade(for: base)
        return FoodSearchResult(
            id: base.id,
            name: base.name,
            brand: base.brand,
            calories: base.calories,
            protein: base.protein,
            carbs: base.carbs,
            fat: base.fat,
            fiber: base.fiber,
            sugar: base.sugar,
            sodium: base.sodium,
            servingDescription: base.servingDescription,
            servingSizeG: base.servingSizeG,
            isPerUnit: base.isPerUnit,
            ingredients: base.ingredients,
            confidence: base.confidence,
            isVerified: base.isVerified,
            additives: base.additives,
            additivesDatabaseVersion: base.additivesDatabaseVersion,
            processingScore: base.processingScore,
            processingGrade: ns.grade,
            processingLabel: ns.label,
            barcode: base.barcode,
            micronutrientProfile: base.micronutrientProfile
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
                        .onChange(of: selectedServingIndex) { _, newValue in
                            isCustomGrams = (newValue == servingOptions.count - 1)
                            if !isCustomGrams {
                                customGrams = ""
                            }
                        }
                        
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
                    
                    // NutraSafe Grade
                    VStack(alignment: .leading, spacing: 12) {
                        Text("NutraSafe Grade")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        HStack {
                            let ns = ProcessingScorer.shared.computeNutraSafeProcessingGrade(for: food.toFoodSearchResult())
                            let gColor: Color = {
                                switch ns.grade {
                                case "A": return .green
                                case "B": return .green
                                case "C": return .orange
                                case "D": return .orange
                                case "E": return .red
                                case "F": return .red
                                default: return .gray
                                }
                            }()
                            
                            ZStack {
                                Circle()
                                    .fill(gColor)
                                    .frame(width: 50, height: 50)
                                
                                Text(ns.grade)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ns.label)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Text(ns.explanation)
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
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
            // Use refined dairy detection to avoid false positives like "coconut milk"
            return AllergenDetector.shared.containsDairyMilk(in: text)
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
