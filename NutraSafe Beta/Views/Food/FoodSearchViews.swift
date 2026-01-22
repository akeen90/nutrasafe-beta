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
// Using lazy closures with explicit error handling for safety
private enum ServingSizePatterns {
    static let gramPattern: NSRegularExpression = {
        do {
            return try NSRegularExpression(pattern: #"(\d+(?:\.\d+)?)\s*g"#, options: [])
        } catch {
            // Pattern is compile-time verified - failure is impossible
            fatalError("Invalid regex pattern gramPattern - this is a programming error")
        }
    }()
    static let parenthesesGramPattern: NSRegularExpression = {
        do {
            return try NSRegularExpression(pattern: #"\((\d+(?:\.\d+)?)\s*g\)"#, options: [])
        } catch {
            fatalError("Invalid regex pattern parenthesesGramPattern - this is a programming error")
        }
    }()
    static let allPatterns: [NSRegularExpression] = [gramPattern, parenthesesGramPattern]
}

// MARK: - Search UI Helper Components

/// Section header for search results - matches diary styling
private struct SearchSectionHeader: View {
    let icon: String
    let title: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.top, DesignTokens.Spacing.md)
        .padding(.bottom, 8)
    }
}

// MARK: - Food Search Result Components

/// Simplified food search result row for basic display
struct FoodSearchResultRow: View {
    let food: FoodSearchResult
    let onAdd: () -> Void
    
    // Calculate per-serving calories from per-100g values
    // PERFORMANCE: Uses pre-parsed servingSizeG instead of regex on every render
    private var perServingCalories: Double {
        let servingSize = food.servingSizeG ?? 100.0
        return food.calories * (servingSize / 100.0)
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
                    .foregroundColor(AppPalette.standard.accent)
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
    @State private var showingQuickAddConfirmation = false
    @State private var quickAddMealType = ""
    @EnvironmentObject var diaryDataManager: DiaryDataManager
    @EnvironmentObject var fastingViewModelWrapper: FastingViewModelWrapper

    init(food: FoodSearchResult, sourceType: FoodSourceType = .search, selectedTab: Binding<TabItem>, onComplete: ((TabItem) -> Void)? = nil) {
        self.food = food
        self.sourceType = sourceType
        self._selectedTab = selectedTab
        self.onComplete = onComplete
    }

    // Calculate standard serving calories for display
    private var standardServingCalories: Int {
        if food.isPerUnit == true {
            return Int(food.calories)
        } else if let servingG = food.servingSizeG, servingG > 0 {
            return Int(food.calories * servingG / 100.0)
        } else {
            // Default to 100g if no serving size
            return Int(food.calories)
        }
    }

    // Get standard serving size description - use first preset portion if available
    // Uses query-aware method to properly handle composite dishes
    private var standardServingDesc: String {
        if food.isPerUnit == true {
            return "1 serving"
        } else if let servingG = food.servingSizeG, servingG > 0 {
            // Use ml for drinks instead of g
            return food.formattedServingSize(servingG)
        } else if let desc = food.servingDescription, !desc.isEmpty {
            return desc
        } else {
            // Use query-aware portions to prevent inappropriate serving descriptions
            // for composite dishes like "salmon en croute"
            let effectiveQuery = food.name
            let portions = food.portionsForQuery(effectiveQuery)
            if let firstPortion = portions.first {
                return firstPortion.name
            }
            return "100g"
        }
    }

    // Get the actual serving weight for nutrition calculation
    // Uses query-aware method to properly handle composite dishes
    private var standardServingWeight: Double {
        if food.isPerUnit == true {
            return 100.0 // Per-unit foods use full values
        } else if let servingG = food.servingSizeG, servingG > 0 {
            return servingG
        } else {
            // Use query-aware portions for composite dish handling
            let effectiveQuery = food.name
            let portions = food.portionsForQuery(effectiveQuery)
            if let firstPortion = portions.first {
                return firstPortion.serving_g
            }
            return 100.0
        }
    }

    @Environment(\.colorScheme) private var colorScheme

    // Food category icon based on name
    private var foodIcon: (name: String, color: Color) {
        let lowercaseName = food.name.lowercased()

        // Protein/meat - check first as these are common searches
        if lowercaseName.contains("chicken") || lowercaseName.contains("beef") || lowercaseName.contains("steak") ||
           lowercaseName.contains("meat") || lowercaseName.contains("pork") || lowercaseName.contains("bacon") ||
           lowercaseName.contains("fish") || lowercaseName.contains("salmon") || lowercaseName.contains("tuna") ||
           lowercaseName.contains("turkey") || lowercaseName.contains("lamb") || lowercaseName.contains("sausage") ||
           lowercaseName.contains("ham") || lowercaseName.contains("prawn") || lowercaseName.contains("shrimp") ||
           lowercaseName.contains("cod") || lowercaseName.contains("haddock") || lowercaseName.contains("mince") ||
           lowercaseName.contains("burger") || lowercaseName.contains("fillet") || lowercaseName.contains("roast") ||
           lowercaseName.contains("ostrich") || lowercaseName.contains("venison") || lowercaseName.contains("duck") {
            return ("flame.fill", Color(red: 0.9, green: 0.5, blue: 0.4))
        }
        // Fruits
        else if lowercaseName.contains("apple") || lowercaseName.contains("fruit") || lowercaseName.contains("banana") ||
                lowercaseName.contains("orange") || lowercaseName.contains("berry") || lowercaseName.contains("grape") ||
                lowercaseName.contains("mango") || lowercaseName.contains("melon") || lowercaseName.contains("peach") ||
                lowercaseName.contains("pear") || lowercaseName.contains("plum") || lowercaseName.contains("kiwi") {
            return ("leaf.fill", Color(red: 0.4, green: 0.75, blue: 0.4))
        }
        // Grains/carbs
        else if lowercaseName.contains("bread") || lowercaseName.contains("rice") || lowercaseName.contains("pasta") ||
                lowercaseName.contains("cereal") || lowercaseName.contains("oat") || lowercaseName.contains("noodle") ||
                lowercaseName.contains("wrap") || lowercaseName.contains("tortilla") || lowercaseName.contains("bagel") ||
                lowercaseName.contains("croissant") || lowercaseName.contains("muffin") || lowercaseName.contains("roll") {
            return ("leaf.circle.fill", Color(red: 0.85, green: 0.7, blue: 0.4))
        }
        // Dairy
        else if lowercaseName.contains("milk") || lowercaseName.contains("cheese") || lowercaseName.contains("yogurt") ||
                lowercaseName.contains("yoghurt") || lowercaseName.contains("dairy") || lowercaseName.contains("cream") ||
                lowercaseName.contains("butter") {
            return ("drop.fill", Color(red: 0.6, green: 0.75, blue: 0.9))
        }
        // Eggs
        else if lowercaseName.contains("egg") {
            return ("oval.fill", Color(red: 0.95, green: 0.85, blue: 0.5))
        }
        // Vegetables
        else if lowercaseName.contains("vegetable") || lowercaseName.contains("carrot") || lowercaseName.contains("broccoli") ||
                lowercaseName.contains("salad") || lowercaseName.contains("spinach") || lowercaseName.contains("lettuce") ||
                lowercaseName.contains("tomato") || lowercaseName.contains("pepper") || lowercaseName.contains("onion") ||
                lowercaseName.contains("potato") || lowercaseName.contains("beans") || lowercaseName.contains("peas") ||
                lowercaseName.contains("corn") || lowercaseName.contains("cabbage") || lowercaseName.contains("celery") {
            return ("carrot.fill", Color(red: 0.4, green: 0.7, blue: 0.5))
        }
        // Beverages - check last to avoid false positives
        else if lowercaseName.contains("coffee") || lowercaseName.contains("tea ") || lowercaseName.hasSuffix("tea") ||
                lowercaseName.contains("drink") || lowercaseName.contains("juice") || lowercaseName.contains("smoothie") ||
                lowercaseName.contains("soda") || lowercaseName.contains("water") || lowercaseName.contains("latte") ||
                lowercaseName.contains("cappuccino") {
            return ("cup.and.saucer.fill", Color(red: 0.6, green: 0.5, blue: 0.4))
        }
        // Snacks/sweets
        else if lowercaseName.contains("chocolate") || lowercaseName.contains("candy") || lowercaseName.contains("sweet") ||
                lowercaseName.contains("cookie") || lowercaseName.contains("biscuit") || lowercaseName.contains("cake") ||
                lowercaseName.contains("ice cream") || lowercaseName.contains("crisp") || lowercaseName.contains("chip") {
            return ("star.fill", Color(red: 0.95, green: 0.6, blue: 0.7))
        }
        // Default - generic food icon
        else {
            return ("fork.knife", AppPalette.standard.accent)
        }
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
            VStack(spacing: 0) {
                // Product image (only when available)
                if let imageUrl = food.imageUrl, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 120)
                                .clipped()
                        case .failure(_):
                            // Hide on failure - don't show anything
                            EmptyView()
                        case .empty:
                            // Loading state
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 120)
                                .overlay(
                                    ProgressView()
                                        .tint(.secondary)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                HStack(spacing: 14) {
                    // Food category icon in soft container (only when no image)
                    if food.imageUrl == nil || food.imageUrl?.isEmpty == true {
                        ZStack {
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                .fill(foodIcon.color.opacity(colorScheme == .dark ? 0.25 : 0.15))
                                .frame(width: 48, height: 48)

                            Image(systemName: foodIcon.name)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(foodIcon.color)
                        }
                    }

                // Product name and serving info
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        if let brand = food.brand, !brand.isEmpty {
                            Text(brand)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        if food.brand != nil && !standardServingDesc.isEmpty {
                            Text("•")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.5))
                        }

                        Text(standardServingDesc)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary.opacity(0.8))
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                // Calories display
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(standardServingCalories)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    Text("kcal")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }

                // Quick add button with meal menu
                Menu {
                    Button {
                        quickAddFood(to: "breakfast")
                    } label: {
                        Label("Breakfast", systemImage: "sunrise.fill")
                    }

                    Button {
                        quickAddFood(to: "lunch")
                    } label: {
                        Label("Lunch", systemImage: "sun.max.fill")
                    }

                    Button {
                        quickAddFood(to: "dinner")
                    } label: {
                        Label("Dinner", systemImage: "moon.fill")
                    }

                    Button {
                        quickAddFood(to: "snacks")
                    } label: {
                        Label("Snacks", systemImage: "leaf.fill")
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppPalette.standard.accent.opacity(0.2), AppPalette.standard.primary.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 38, height: 38)

                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AppPalette.standard.accent)
                    }
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.4))
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 14)
            } // VStack
        }
        .buttonStyle(PlainButtonStyle())
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color.midnightCard, Color.midnightCard.opacity(0.9)]
                            : [Color.white, Color.white.opacity(0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .stroke(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color.white.opacity(0.1), Color.white.opacity(0.05)]
                            : [Color.black.opacity(0.06), Color.black.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 8, y: 3)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onChange(of: showingFoodDetail) { oldValue, newValue in
            print("[FoodSearchResultRowEnhanced] showingFoodDetail changed: \(oldValue) -> \(newValue)")
        }
        .fullScreenCover(isPresented: $showingFoodDetail) {
            FoodDetailViewFromSearch(food: food, sourceType: sourceType, selectedTab: $selectedTab, fastingViewModel: fastingViewModelWrapper.viewModel) { tab in
                print("[FoodSearchResultRowEnhanced] FoodDetail onComplete called with tab: \(tab)")
                onComplete?(tab)
            }
            .environmentObject(diaryDataManager)
            .interactiveDismissDisabled(false)
            .presentationBackground(Color.adaptiveBackground)
            .onAppear {
                print("[FoodDetailViewFromSearch] onAppear - fullScreenCover presented")
            }
            .onDisappear {
                print("[FoodDetailViewFromSearch] onDisappear - fullScreenCover dismissed")
            }
        }
        .overlay(
            Group {
                if showingQuickAddConfirmation {
                    quickAddConfirmationToast
                }
            }
        )
    }

    // Quick add confirmation toast
    private var quickAddConfirmationToast: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                Text("Added to \(quickAddMealType.capitalized)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.green)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .zIndex(100)
    }

    // Quick add food to diary at standard serving size
    private func quickAddFood(to mealType: String) {
        // Dismiss keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        // Calculate nutrition at standard serving size using the computed serving weight
        let servingMultiplier: Double
        if food.isPerUnit == true {
            servingMultiplier = 1.0
        } else {
            servingMultiplier = standardServingWeight / 100.0
        }

        // Create diary entry at standard serving
        let diaryEntry = DiaryFoodItem(
            id: UUID(),
            name: food.name,
            brand: food.brand,
            calories: Int(food.calories * servingMultiplier),
            protein: food.protein * servingMultiplier,
            carbs: food.carbs * servingMultiplier,
            fat: food.fat * servingMultiplier,
            fiber: food.fiber * servingMultiplier,
            sugar: food.sugar * servingMultiplier,
            sodium: food.sodium * servingMultiplier,
            servingDescription: standardServingDesc,
            quantity: 1.0,
            time: mealType.capitalized,
            processedScore: food.processingGrade,
            sugarLevel: nil,
            ingredients: food.ingredients,
            additives: food.additives,
            barcode: food.barcode,
            micronutrientProfile: food.micronutrientProfile,
            isPerUnit: food.isPerUnit
        )

        // Get the date (use preselected date if available, otherwise today)
        let targetDate: Date
        if let savedTimestamp = UserDefaults.standard.object(forKey: "preselectedDate") as? TimeInterval {
            targetDate = Date(timeIntervalSince1970: savedTimestamp)
        } else {
            targetDate = Date()
        }

        // Add to diary
        Task {
            do {
                try await diaryDataManager.addFoodItem(diaryEntry, to: mealType, for: targetDate, hasProAccess: true)

                await MainActor.run {
                    quickAddMealType = mealType
                    withAnimation(.spring(response: 0.3)) {
                        showingQuickAddConfirmation = true
                    }

                    // Hide confirmation after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showingQuickAddConfirmation = false
                        }
                    }
                }

                            } catch {
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
    case search, barcode, ai, manual, diary, useBy
}

// MARK: - Main Food Search View

/// Comprehensive food search interface with live search, recent foods, and keyboard handling (DIARY-ONLY)
struct AddFoodSearchView: View {
    @Binding var selectedTab: TabItem
    var onComplete: ((TabItem) -> Void)?
    var onSwitchToManual: (() -> Void)? = nil
    var onSwitchToBarcode: (() -> Void)? = nil
    @State private var searchText = ""
    @State private var searchResults: [FoodSearchResult] = []
    @State private var isSearching = false
    @EnvironmentObject var diaryDataManager: DiaryDataManager
    @EnvironmentObject var firebaseManager: FirebaseManager
    @EnvironmentObject var fastingViewModelWrapper: FastingViewModelWrapper
    @State private var recentFoods: [DiaryFoodItem] = []
    @State private var favoriteFoods: [FoodSearchResult] = []
    @State private var searchTask: Task<Void, Never>?
    @State private var keyboardHeight: CGFloat = 0
    @State private var isEditingMode = false
    @State private var hasScrolledToResults = false  // Prevents repeated auto-scrolling

    // PERFORMANCE: Debouncer to prevent search from running on every keystroke
    @StateObject private var searchDebouncer = Debouncer(milliseconds: 300)
    @State private var editingFoodName = ""
    @State private var originalMealType = ""

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar with Barcode Button - redesigned with glassmorphic styling
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    // Barcode scan button to LEFT of search bar - gradient style
                    if let barcodeAction = onSwitchToBarcode {
                        Button(action: barcodeAction) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                                .background(
                                    LinearGradient(
                                        colors: [AppPalette.standard.accent, AppPalette.standard.primary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(DesignTokens.Radius.md)
                                .shadow(color: AppPalette.standard.accent.opacity(0.25), radius: 6, y: 2)
                        }
                    }

                    // Search field - glassmorphic style matching onboarding
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppPalette.standard.accent)

                        TextField("Search foods...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 16))
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
                            // Clear button with proper tap target
                            Button(action: {
                                // Dismiss keyboard first
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                // Cancel any pending search and reset all state immediately
                                searchTask?.cancel()
                                searchTask = nil
                                searchText = ""
                                searchResults = []
                                isSearching = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                        }
                    }
                    .frame(height: 48)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.top, 12)
            }
            .zIndex(1) // Keep search bar on top

            // Results - redesigned with NutraSafe visual language
            if isSearching {
                VStack {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(AppPalette.standard.accent)
                        Text("Searching...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .frame(maxHeight: .infinity)
            } else if searchResults.isEmpty && !searchText.isEmpty {
                // No results empty state - redesigned with card panel
                VStack {
                    Spacer()

                    VStack(spacing: 24) {
                        // Icon with soft container
                        ZStack {
                            Circle()
                                .fill(AppPalette.standard.accent.opacity(0.1))
                                .frame(width: 88, height: 88)

                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundColor(AppPalette.standard.accent.opacity(0.6))
                        }

                        VStack(spacing: 8) {
                            Text("No foods found")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)

                            Text("We couldn't find '\(searchText)'")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        // Helpful tips with delayed reveal
                        NutraSafeTipCard(tips: [
                            (icon: "sparkles", text: "Try a simpler search term", tint: SemanticColors.neutral),
                            (icon: "barcode.viewfinder", text: "Got a barcode? Scan it for instant results", tint: AppPalette.standard.accent),
                            (icon: "square.and.pencil", text: "Can't find it? You can add it yourself", tint: AppPalette.standard.primary)
                        ])
                        .padding(.horizontal, 24)

                        // Manual Entry CTA - primary button style
                        if onSwitchToManual != nil {
                            Button(action: {
                                onSwitchToManual?()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "square.and.pencil")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Add Manually")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: DesignTokens.Size.buttonHeight)
                                .background(
                                    LinearGradient(
                                        colors: [AppPalette.standard.accent, AppPalette.standard.primary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(DesignTokens.Radius.lg)
                                .shadow(color: AppPalette.standard.accent.opacity(0.3), radius: 15, y: 5)
                            }
                            .padding(.horizontal, 24)
                        }
                    }

                    Spacer()
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            // Show favorites when search is empty
                            if searchText.isEmpty && !favoriteFoods.isEmpty {
                                // Favorites Section - redesigned header
                                VStack(alignment: .leading, spacing: 12) {
                                    SearchSectionHeader(icon: "heart.fill", title: "Favourites", iconColor: .red)

                                    ForEach(favoriteFoods, id: \.id) { food in
                                        FoodSearchResultRowEnhanced(food: food, selectedTab: $selectedTab, onComplete: onComplete)
                                            .padding(.horizontal, DesignTokens.Spacing.md)
                                    }
                                }
                            }

                            // Show recent foods when search is empty
                            if searchText.isEmpty && !recentFoods.isEmpty {
                                // Recent Foods Section - redesigned header
                                VStack(alignment: .leading, spacing: 12) {
                                    SearchSectionHeader(icon: "clock.arrow.circlepath", title: "Recent Foods", iconColor: AppPalette.standard.accent)

                                    ForEach(recentFoods, id: \.id) { recentFood in
                                        let searchResult = convertToSearchResult(recentFood)
                                        FoodSearchResultRowEnhanced(food: searchResult, selectedTab: $selectedTab, onComplete: onComplete)
                                            .padding(.horizontal, DesignTokens.Spacing.md)
                                    }
                                }
                            }

                            // Show search results when searching
                            if !searchText.isEmpty && !searchResults.isEmpty {
                                // Search Results header
                                SearchSectionHeader(icon: "magnifyingglass", title: "Results", iconColor: AppPalette.standard.accent)
                            }

                            ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, food in
                                FoodSearchResultRowEnhanced(food: food, selectedTab: $selectedTab, onComplete: onComplete)
                                    .id("result_\(index)")
                                    .padding(.horizontal, DesignTokens.Spacing.md)
                            }

                            // Spacer for keyboard
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: keyboardHeight > 0 ? keyboardHeight + 20 : 80)
                                .id("bottom_spacer")
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxHeight: .infinity)
                    .scrollDismissesKeyboard(.interactively) // Dismiss keyboard on scroll, not tap (avoids gesture conflicts)
                    .onChange(of: searchResults.count) { oldCount, newCount in
                        // Auto-scroll to show first result only when results first appear (not repeatedly)
                        if newCount > 0 && oldCount == 0 && !hasScrolledToResults {
                            hasScrolledToResults = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    scrollProxy.scrollTo("result_0", anchor: .top)
                                }
                            }
                        } else if newCount == 0 {
                            // Reset flag when results are cleared (new search)
                            hasScrolledToResults = false
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            // Opaque base layer to prevent underlying content showing through
            Color.adaptiveBackground
                .ignoresSafeArea()
            // Then the animated gradient on top
            AppAnimatedBackground()
        }
        .onAppear {
            print("[AddFoodSearchView] onAppear called")
            setupKeyboardObservers()
            checkForEditingMode()
            loadRecentFoods()
            loadFavorites()
        }
        .onDisappear {
            print("[AddFoodSearchView] onDisappear called")
            removeKeyboardObservers()
        }
        .onReceive(NotificationCenter.default.publisher(for: .favoritesDidChange)) { _ in
            loadFavorites()
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

        
        isSearching = true

        // Instant search - no debounce for immediate feedback
        searchTask = Task {
            if Task.isCancelled {
                                return
            }

            // Try search (Firebase searchFoods already includes Algolia via backend)
            var results: [FoodSearchResult] = []

            do {
                results = try await FirebaseManager.shared.searchFoods(query: normalizedQuery)

                } catch {
                            }

            if Task.isCancelled { return }

            // Show results immediately for instant feedback
            await MainActor.run {
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
                                                        self.searchResults = finalResults
                        }
                    }
                } catch {
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

    private func loadFavorites() {
        Task {
            do {
                let favorites = try await firebaseManager.getFavoriteFoods()
                await MainActor.run {
                    favoriteFoods = favorites
                }
            } catch {
                            }
        }
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
                                            .foregroundColor(AppPalette.standard.accent)
                                    }
                                    
                                    Text(String(format: "%.2g", quantity))
                                        .font(.system(size: 18, weight: .medium))
                                        .frame(minWidth: 60)
                                    
                                    Button(action: {
                                        quantity += 0.25
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(AppPalette.standard.accent)
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
            .background(Color.adaptiveCard)
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
        // Use centralized detection for dairy (handles plant milks correctly)
        if allergen == .dairy {
            return AllergenDetector.shared.containsDairyMilk(in: text)
        }
        // Use the comprehensive keyword lists defined in Allergen.keywords
        return allergen.keywords.contains { text.contains($0) }
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
