//
//  FoodDetailViewFromSearch.swift
//  NutraSafe Beta
//
//  Extracted from ContentView.swift as part of Phase 10 modularization
//  This is a comprehensive food detail view component with:
//  - Nutrition facts display with serving size controls
//  - Ingredient verification system with photo submission
//  - Additive/allergen/micronutrient analysis tabs
//  - Food scoring system (processing and sugar scores)
//  - User-verified ingredient management
//

import SwiftUI
import Foundation
import Vision
import AVFoundation

// MARK: - Fraction Model

struct Fraction: Identifiable, Hashable {
    let id = UUID()
    let whole: Int
    let numerator: Int
    let denominator: Int

    var decimalValue: Double {
        return Double(whole) + (Double(numerator) / Double(denominator))
    }

    var displayString: String {
        if numerator == 0 {
            return "\(whole)"
        } else if whole == 0 {
            return "\(numerator)/\(denominator)"
        } else {
            return "\(whole) \(numerator)/\(denominator)"
        }
    }

    static let commonFractions: [Fraction] = [
        Fraction(whole: 0, numerator: 1, denominator: 4),  // 1/4
        Fraction(whole: 0, numerator: 1, denominator: 3),  // 1/3
        Fraction(whole: 0, numerator: 1, denominator: 2),  // 1/2
        Fraction(whole: 0, numerator: 2, denominator: 3),  // 2/3
        Fraction(whole: 0, numerator: 3, denominator: 4),  // 3/4
        Fraction(whole: 1, numerator: 0, denominator: 1),  // 1
        Fraction(whole: 1, numerator: 1, denominator: 4),  // 1 1/4
        Fraction(whole: 1, numerator: 1, denominator: 3),  // 1 1/3
        Fraction(whole: 1, numerator: 1, denominator: 2),  // 1 1/2
        Fraction(whole: 1, numerator: 2, denominator: 3),  // 1 2/3
        Fraction(whole: 1, numerator: 3, denominator: 4),  // 1 3/4
        Fraction(whole: 2, numerator: 0, denominator: 1),  // 2
        Fraction(whole: 2, numerator: 1, denominator: 4),  // 2 1/4
        Fraction(whole: 2, numerator: 1, denominator: 3),  // 2 1/3
        Fraction(whole: 2, numerator: 1, denominator: 2),  // 2 1/2
        Fraction(whole: 2, numerator: 2, denominator: 3),  // 2 2/3
        Fraction(whole: 2, numerator: 3, denominator: 4),  // 2 3/4
        Fraction(whole: 3, numerator: 0, denominator: 1),  // 3
        Fraction(whole: 3, numerator: 1, denominator: 2),  // 3 1/2
        Fraction(whole: 4, numerator: 0, denominator: 1),  // 4
        Fraction(whole: 5, numerator: 0, denominator: 1),  // 5
    ]

    // Find the closest fraction from common fractions
    static func closestFraction(to decimal: Double) -> Fraction {
        return commonFractions.min(by: { abs($0.decimalValue - decimal) < abs($1.decimalValue - decimal) }) ?? Fraction(whole: 1, numerator: 0, denominator: 1)
    }
}

// MARK: - Food Detail View From Search (DIARY-ONLY)
struct FoodDetailViewFromSearch: View {
    let food: FoodSearchResult
    let sourceType: FoodSourceType
    @Binding var selectedTab: TabItem
    var onComplete: ((TabItem) -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var diaryDataManager: DiaryDataManager

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showingDiaryLimitError = false
    @State private var showingPaywall = false
    @State private var gramsAmount: String
    @State private var servings: String = "1"
    @State private var quantity: Double = 1.0
    @State private var selectedMeal = "Breakfast"
    @State private var isNotifyingTeam = false
    @State private var showingNotificationSuccess = false
    @State private var showingNotificationError = false
    @State private var notificationErrorMessage = ""

    // AI Enhancement states
    @State private var isEnhancing = false
    @State private var showingEnhancementSuccess = false
    @State private var showingEnhancementError = false
    @State private var enhancementErrorMessage = ""
    @State private var enhancedIngredientsText: String?
    @State private var enhancedNutrition: NutritionPer100g?
    @State private var enhancedProductName: String?
    @State private var enhancedBrand: String?

    // Barcode Enhancement states
    @State private var showingBarcodeScannerForEnhancement = false
    @State private var showingManualSearchForEnhancement = false
    @State private var manualSearchText = ""

    // AI-Inferred Ingredients states
    @State private var showingInferredIngredientsSheet = false
    @State private var inferredIngredients: [InferredIngredient] = []
    @State private var isEstimatingIngredients = false

    // MARK: - Fasting Integration
    var fastingViewModel: FastingViewModel?
    @State private var showingFastingPrompt = false
    @State private var isStartingFastAfterLog = false

    // MARK: - Diary replacement support
    let diaryEntryId: UUID?
    let diaryMealType: String?
    let diaryQuantity: Double?
    let diaryDate: Date?

    init(food: FoodSearchResult, sourceType: FoodSourceType = .search, selectedTab: Binding<TabItem>, diaryEntryId: UUID? = nil, diaryMealType: String? = nil, diaryQuantity: Double? = nil, diaryDate: Date? = nil, fastingViewModel: FastingViewModel? = nil, onComplete: ((TabItem) -> Void)? = nil) {
        self.food = food
        self.sourceType = sourceType
        self._selectedTab = selectedTab
        self.diaryEntryId = diaryEntryId
        self.diaryMealType = diaryMealType
        self.diaryQuantity = diaryQuantity
        self.diaryDate = diaryDate
        self.fastingViewModel = fastingViewModel
        self.onComplete = onComplete

        // CRITICAL FIX: Initialize serving size from food data immediately
        var initialServingSize = "100"  // Default fallback
        var initialUnit = "g"

        // Check if this is a per-unit food first
        if food.isPerUnit == true {
            // Per-unit food: use serving description as unit name
            initialServingSize = "1"
            if let servingDesc = food.servingDescription, !servingDesc.isEmpty {
                // Use the full serving description as the unit (e.g., "Large (take-out)", "Medium (drink-in)")
                initialUnit = servingDesc
            } else {
                // No serving description - try to extract from food name
                let nameWords = food.name.lowercased().components(separatedBy: " ")
                if let foodType = nameWords.first(where: { ["burger", "pizza", "sandwich", "wrap", "taco", "burrito"].contains($0) }) {
                    initialUnit = foodType
                } else {
                    initialUnit = "unit"
                }
            }
        } else {
            // Per-100g food: Use standard logic
            // Priority 1: Use servingSizeG if available (most reliable)
            if let sizeG = food.servingSizeG, sizeG > 0 {
                initialServingSize = String(format: "%.0f", sizeG)
            } else if let servingDesc = food.servingDescription, !servingDesc.isEmpty {
                // Priority 2: Extract from serving description
                // More flexible patterns to handle various formats including UK supermarket styles

                // Patterns to match numbers followed by g, ml, or gram/ml
                // IMPORTANT: Order matters - more specific patterns first (parenthetical grams highest priority)
                // to correctly handle "1 portion (150g)" -> 150, not 1
                // Each tuple is (pattern, unit) so we set the correct unit when matching
                let patternsWithUnits: [(pattern: String, unit: String)] = [
                    (#"\((\d+(?:\.\d+)?)\s*g\)"#, "g"),           // "(150g)", "(30 g)" - parenthetical grams (HIGHEST PRIORITY)
                    (#"(\d+(?:\.\d+)?)\s*g\s*\)"#, "g"),          // "150g)" at end of parenthetical
                    (#"\((\d+(?:\.\d+)?)\s*ml\)"#, "ml"),         // "(330ml)" - parenthetical ml
                    (#"(\d+(?:\.\d+)?)\s*ml\s*\)"#, "ml"),        // "330ml)" at end of parenthetical
                    (#"(\d+(?:\.\d+)?)\s*g\s+serving"#, "g"),     // "150g serving", "30 g serving"
                    (#"(\d+(?:\.\d+)?)\s*ml\s+serving"#, "ml"),   // "330ml serving"
                    (#"serving[:\s]+(\d+(?:\.\d+)?)\s*g\b"#, "g"),// "serving: 30g", "serving 30g"
                    (#"serving[:\s]+(\d+(?:\.\d+)?)\s*ml\b"#, "ml"),// "serving: 330ml"
                    (#"=\s*(\d+(?:\.\d+)?)\s*g\b"#, "g"),         // "= 225g", "1 pack = 450g"
                    (#"=\s*(\d+(?:\.\d+)?)\s*ml\b"#, "ml"),       // "= 330ml"
                    (#"(\d+(?:\.\d+)?)\s*g\s+pack"#, "g"),        // "225g pack"
                    (#"(\d+(?:\.\d+)?)\s*ml\s+pack"#, "ml"),      // "330ml pack"
                    (#"pack\s*[=:]\s*(\d+(?:\.\d+)?)\s*g"#, "g"), // "pack = 450g", "pack: 450g"
                    (#"pack\s*[=:]\s*(\d+(?:\.\d+)?)\s*ml"#, "ml"),// "pack = 330ml"
                    (#"(\d+(?:\.\d+)?)\s*grams?\b"#, "g"),        // "225 grams", "30gram"
                    (#"(\d+(?:\.\d+)?)\s*ml\b"#, "ml"),           // "330ml" for drinks
                    (#"(\d+(?:\.\d+)?)\s*millilitres?\b"#, "ml"), // "330 millilitres"
                    (#"^(\d+(?:\.\d+)?)\s*g$"#, "g"),             // "30g" exactly
                    (#"^(\d+(?:\.\d+)?)\s*ml$"#, "ml"),           // "330ml" exactly
                    (#"(\d+(?:\.\d+)?)\s*g\b"#, "g"),             // "30g" with word boundary (avoids "1 portion")
                ]

                for (pattern, unit) in patternsWithUnits {
                    if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                       let match = regex.firstMatch(in: servingDesc, options: [], range: NSRange(location: 0, length: servingDesc.count)),
                       let range = Range(match.range(at: 1), in: servingDesc),
                       let extractedValue = Double(servingDesc[range]) {
                        // Sanity check: serving size should be reasonable (5-2000 for ml, 5-500 for g)
                        // Skip values that are exactly 100 as that's likely "per 100g" reference
                        let maxValue = unit == "ml" ? 2000.0 : 500.0
                        if extractedValue >= 5 && extractedValue <= maxValue && extractedValue != 100 {
                            initialServingSize = String(format: "%.0f", extractedValue)
                            initialUnit = unit
                            break
                        }
                    }
                }
                // Fallback for specific per-unit foods only (NOT generic "serving" mentions)
                // Only treat as per-unit if description explicitly describes a countable food item
                if initialServingSize == "100" {
                    let lower = servingDesc.lowercased()

                    // Only convert to per-unit for SPECIFIC countable food items, NOT generic "serving"
                    // These are foods that are naturally counted (1 burger, 1 slice, 1 piece)
                    let perUnitFoodWords = ["burger", "pizza", "sandwich", "wrap", "taco", "burrito", "slice", "piece", "bar", "biscuit", "cookie"]

                    if lower.hasPrefix("1 ") {
                        let unitCandidate = lower.split(separator: " ").dropFirst().joined(separator: " ")
                        // Only use per-unit if it's a specific countable food, not generic "serving"/"portion"
                        if !unitCandidate.isEmpty && perUnitFoodWords.contains(where: { unitCandidate.contains($0) }) {
                            initialServingSize = "1"
                            initialUnit = String(unitCandidate)
                        }
                        // Otherwise keep default 100g - don't convert "1 serving" to per-unit
                    }
                    // Don't do the generic "contains serving/portion" fallback anymore
                    // Regular per-100g foods should stay as 100g default
                }
            }

            // If unit is still default "g" but food is a liquid category, use "ml"
            if initialUnit == "g" && food.isLiquidCategory {
                initialUnit = "ml"
            }
        }

        // Initialize all serving size state variables with the determined value
        self._servingAmount = State(initialValue: initialServingSize)
        self._gramsAmount = State(initialValue: initialServingSize)
        self._servingUnit = State(initialValue: initialUnit)

        // Initialize selected meal from diary meal type if provided
        self._selectedMeal = State(initialValue: diaryMealType ?? "Breakfast")
        self._isEditingMode = State(initialValue: diaryEntryId != nil)
        self._originalMealType = State(initialValue: diaryMealType ?? "")

        // Initialize quantity multiplier from diary entry if editing
        self._quantityMultiplier = State(initialValue: diaryQuantity ?? 1.0)

        // Initialize with custom row selected by default (editable serving size field)
        // This allows immediate editing of portion size when entering the food page
        self._selectedPortionName = State(initialValue: "__custom__")

        // If portions are available, still use first portion values for the custom row
        if let portions = food.portions, !portions.isEmpty {
            self._servingAmount = State(initialValue: String(format: "%.0f", portions[0].serving_g))
            self._gramsAmount = State(initialValue: String(format: "%.0f", portions[0].serving_g))
            // Set appropriate unit based on food category (ml for drinks, g for food)
            self._servingUnit = State(initialValue: food.isLiquidCategory ? "ml" : "g")
        }
    }

    // OPTIMIZED: Use food directly - search already returns complete data
    // Enhanced with AI nutrition and ingredients if available
    private var displayFood: FoodSearchResult {
        // Check if we have ANY enhanced data (nutrition OR ingredients)
        let hasEnhancedData = enhancedNutrition != nil || enhancedIngredientsText != nil

        if hasEnhancedData {
            // Convert enhanced ingredients text to array if available
            let enhancedIngredientsArray: [String]? = {
                if let text = enhancedIngredientsText, !text.isEmpty {
                    return text.components(separatedBy: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                }
                return nil
            }()

            return FoodSearchResult(
                id: food.id,
                name: enhancedProductName ?? food.name,
                brand: enhancedBrand ?? food.brand,
                calories: enhancedNutrition?.calories ?? food.calories,
                protein: enhancedNutrition?.protein ?? food.protein,
                carbs: enhancedNutrition?.carbs ?? food.carbs,
                fat: enhancedNutrition?.fat ?? food.fat,
                fiber: enhancedNutrition?.fiber ?? food.fiber,
                sugar: enhancedNutrition?.sugar ?? food.sugar,
                sodium: enhancedNutrition?.salt ?? food.sodium,  // Convert salt to sodium
                servingDescription: food.servingDescription,
                servingSizeG: food.servingSizeG,
                ingredients: enhancedIngredientsArray ?? food.ingredients,  // Use enhanced ingredients if available
                confidence: food.confidence,
                isVerified: food.isVerified,
                additives: food.additives,
                additivesDatabaseVersion: food.additivesDatabaseVersion,
                processingScore: food.processingScore,
                processingGrade: food.processingGrade,
                processingLabel: food.processingLabel,
                barcode: food.barcode,
                micronutrientProfile: food.micronutrientProfile
            )
        }
        return food
    }
    
    // Enhanced photo system for database building
    @State private var showingNutritionCamera = false
    @State private var showingBarcodeCamera = false
    @State private var nutritionImage: UIImage?
    @State private var barcodeImage: UIImage?
    @State private var showingPhotoPrompts = false
    @State private var isSubmittingCompleteProfile = false
    @State private var showingAdditives = false
    @State private var selectedAmount: Double = 100
    @State private var selectedUnit: String = "g"
    @State private var selectedServings: Double = 1
    @State private var refreshTrigger: UUID = UUID()
    @State private var isEditingMode = false
    @State private var originalMealType = ""
    @State private var quantityMultiplier: Double = 1.0 // New quantity multiplier

    // Quantity input mode
    enum QuantityInputMode: String, CaseIterable {
        case decimal = "Decimal"
        case fraction = "Fraction"
    }
    @State private var quantityInputMode: QuantityInputMode = .decimal
    @State private var quantityDecimalText: String = "1.0"
    @State private var quantityFraction: Fraction = Fraction(whole: 1, numerator: 0, denominator: 1)

    @State private var servingSizeText: String = "" // Editable serving size (legacy)
    @State private var servingAmount: String // Split serving size - amount only
    @State private var servingUnit: String // Split serving size - unit only
    @State private var selectedPortionName: String = "" // For portion picker (e.g., McNuggets 6pc, 9pc, 20pc)
    @State private var showingMultiplierPicker: Bool = false // Shows grid popup for quantity multiplier

    // Favorites
    @State private var isFavorite: Bool = false
    @State private var isTogglingFavorite: Bool = false
    private var isPerUnit: Bool {
        if let flag = food.isPerUnit { return flag }
        let u = servingUnit.lowercased()
        return !(u == "g" || u == "ml" || u == "oz" || u == "kg" || u == "lb")
    }
    @State private var showingUseByAddSheet: Bool = false
    @State private var showingNutraSafeInfo: Bool = false
    @State private var showingSugarInfo: Bool = false

    // Allergen warning
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var userAllergens: [Allergen] = []
    @State private var detectedUserAllergens: [Allergen] = []

    // PERFORMANCE: Cache additive analysis result to prevent re-computation on every render
    @State private var cachedAdditives: [DetailedAdditive]? = nil

    // PERFORMANCE: Cache ingredients list to prevent re-computation on every render
    @State private var cachedIngredients: [String]? = nil

    // PERFORMANCE: Cache ingredients status to prevent re-computation on every render
    @State private var cachedIngredientsStatus: IngredientsStatus? = nil

    // PERFORMANCE: Cache nutrition score to prevent 40+ calls to analyseAdditives on every render
    @State private var cachedNutritionScore: NutritionProcessingScore? = nil

    // PERFORMANCE: Cache NutraSafe processing grade to avoid recompute
    @State private var cachedNutraSafeGrade: ProcessingScorer.NutraSafeProcessingGradeResult? = nil

    // PERFORMANCE: Flag to ensure initialization only happens once
    @State private var hasInitialized = false

    // Watch tabs (Additive Analysis, Allergy Watch, Vitamins & Minerals)
    @State private var selectedWatchTab: WatchTab = .additives
    @State private var showingVitaminCitations = false
    @State private var showingAllergenCitations = false
    @State private var cachedDetectedNutrients: [String] = []

    private var buttonText: String {
        if diaryEntryId != nil || isEditingMode {
            return "Update"
        } else {
            return "Add to Diary"
        }
    }

    // MARK: - Fasting State Helpers
    /// Whether user is currently in an active fasting session
    @MainActor private var isCurrentlyFasting: Bool {
        guard let vm = fastingViewModel else { return false }
        // Check if there's an active session that hasn't ended
        if let session = vm.activeSession, session.endTime == nil {
            return true
        }
        // Also check if regime state is fasting
        if case .fasting = vm.currentRegimeState {
            return true
        }
        return false
    }

    /// Whether user has an active fasting plan
    @MainActor private var hasActiveFastingPlan: Bool {
        guard let vm = fastingViewModel else { return false }
        return vm.activePlan != nil
    }

    /// Whether to show the "Log & Start Fast" button
    /// Show when: user has a fasting plan, is in eating window, and not already fasting
    @MainActor private var shouldShowStartFastOption: Bool {
        guard let vm = fastingViewModel, hasActiveFastingPlan else { return false }
        // Don't show if user is currently fasting (has active session)
        if isCurrentlyFasting { return false }
        // Only show if in eating window
        if case .eating = vm.currentRegimeState {
            return true
        }
        return false
    }

    enum WatchTab: String, CaseIterable {
        case additives = "Additive Analysis"
        case allergies = "Allergy Watch"
        case vitamins = "Vitamins & Minerals"

        var icon: String {
            switch self {
            case .additives: return "flask.fill"
            case .allergies: return "exclamationmark.triangle.fill"
            case .vitamins: return "leaf.fill"
            }
        }

        var color: Color {
            switch self {
            case .additives: return SemanticColors.additive
            case .allergies: return SemanticColors.caution
            case .vitamins: return SemanticColors.nutrient
            }
        }
    }
    
    private let mealOptions = ["Breakfast", "Lunch", "Dinner", "Snacks"]
    private let quantityOptions: [Double] = [0.5, 1.0, 2.0, 3.0, 4.0, 5.0]
    private let servingUnitOptions = ["g", "ml", "oz", "fl oz"]
    private let quantityMultiplierOptions = ["¼x", "½x", "¾x", "1x", "2x", "3x", "4x", "5x", "6x", "7x", "8x", "9x"]

    // Helper to format multiplier text
    private func multiplierText(_ mult: Double) -> String {
        if mult == 1 { return "1x" }
        if mult < 1 { return String(format: "%.2gx", mult) }
        return String(format: "%.0fx", mult)
    }

    // Toggle favorite status
    private func toggleFavorite() {
        isTogglingFavorite = true
        Task {
            do {
                if isFavorite {
                    try await firebaseManager.removeFavoriteFood(foodId: food.id)
                } else {
                    try await firebaseManager.saveFavoriteFood(food)
                }
                await MainActor.run {
                    isFavorite.toggle()
                    isTogglingFavorite = false
                    // Haptic feedback
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    // Notify other views that favorites changed
                    NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
                }
            } catch {
                await MainActor.run {
                    isTogglingFavorite = false
                                    }
            }
        }
    }

    // Convert between units (all conversions to/from grams)
    private func convertUnit(value: Double, from: String, to: String) -> Double {
        // First convert to grams
        let grams: Double
        switch from.lowercased() {
        case "g": grams = value
        case "ml": grams = value // 1ml water = 1g (approximation)
        case "cup": grams = value * 240 // 1 cup = 240g (water/milk)
        case "tbsp": grams = value * 15 // 1 tbsp = 15g
        case "tsp": grams = value * 5 // 1 tsp = 5g
        case "oz": grams = value * 28.35 // 1 oz = 28.35g
        default: grams = value
        }

        // Then convert from grams to target unit
        switch to.lowercased() {
        case "g": return grams
        case "ml": return grams // 1g water = 1ml (approximation)
        case "cup": return grams / 240
        case "tbsp": return grams / 15
        case "tsp": return grams / 5
        case "oz": return grams / 28.35
        default: return grams
        }
    }
    
    private var currentWeight: Double {
        let grams = Double(gramsAmount) ?? 100.0
        return grams * quantity
    }
    
    private var multiplier: Double {
        currentWeight / 100
    }
    
    // Extract the actual serving size from split serving amount and unit
    private var actualServingSize: Double {
        // For per-unit foods, don't convert - just return 1.0
        if food.isPerUnit == true {
            return 1.0
        }

        // For custom grams entry, use gramsAmount directly
        if selectedPortionName == "__custom__" {
            let amount = Double(gramsAmount) ?? 100.0
            // gramsAmount is already in g or ml (treated as g for liquids)
            return amount
        }

        // For per-100g foods, convert to grams
        let amount = Double(servingAmount) ?? 1.0
        let unit = servingUnit

        // Convert the amount in the current unit to grams
        return convertUnit(value: amount, from: unit, to: "g")
    }

    // Parse serving description into amount and unit
    private func parseServingDescription(_ description: String) -> (amount: String, unit: String) {
        let text = description.trimmingCharacters(in: .whitespacesAndNewlines)

        // Common patterns:
        // "1 portion (345 g)" -> amount: "1", unit: "portion (345 g)"
        // "345g" -> amount: "345", unit: "g"
        // "1 slice" -> amount: "1", unit: "slice"
        // "100ml" -> amount: "100", unit: "ml"

        // Try to match number at the start
        if let regex = try? NSRegularExpression(pattern: #"^(\d+(?:\.\d+)?)\s*(.+)$"#, options: []) {
            if let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                if let amountRange = Range(match.range(at: 1), in: text),
                   let unitRange = Range(match.range(at: 2), in: text) {
                    let amount = String(text[amountRange])
                    let unit = String(text[unitRange])
                    return (amount, unit)
                }
            }
        }

        // Fallback: treat entire text as amount "1" and unit
        return ("1", text)
    }

    /// Parse serving size string from AI finder (e.g., "330ml", "1 can (330ml)", "250g")
    private func parseServingSizeString(_ servingSizeStr: String) -> (amount: String, unit: String) {
        let cleaned = servingSizeStr.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Try to find parentheses pattern like "1 can (330ml)"
        if let match = cleaned.range(of: #"\((\d+(?:\.\d+)?)\s*(ml|g|oz|kg|lb|cup|tbsp|tsp|piece|slice|serving|grams|milliliters|ounces|kilograms|pounds)\)"#, options: .regularExpression) {
            let extracted = String(cleaned[match])
            let withoutParens = extracted.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
            return extractAmountAndUnit(from: withoutParens)
        }

        // Otherwise try direct pattern like "330ml" or "30 g"
        return extractAmountAndUnit(from: cleaned)
    }

    /// Extract amount and unit from a string like "330ml" or "30 g"
    private func extractAmountAndUnit(from text: String) -> (amount: String, unit: String) {
        // Match pattern: number followed by optional space and unit
        if let match = text.range(of: #"(\d+(?:\.\d+)?)\s*(ml|g|oz|kg|lb|cup|tbsp|tsp|piece|slice|serving|grams|milliliters|ounces|kilograms|pounds)"#, options: .regularExpression) {
            let extracted = String(text[match])

            // Split into number and unit
            if let numMatch = extracted.range(of: #"\d+(?:\.\d+)?"#, options: .regularExpression) {
                let amount = String(extracted[numMatch])
                let unit = extracted.replacingOccurrences(of: amount, with: "").trimmingCharacters(in: .whitespaces)

                // Normalize unit names
                let normalizedUnit = normalizeUnitName(unit)

                return (amount, normalizedUnit)
            }
        }

        // Fallback: return default
        return ("100", "g")
    }

    /// Normalize unit names to match the app's standard units
    private func normalizeUnitName(_ unit: String) -> String {
        let lowercase = unit.lowercased()

        // Map variations to standard units
        switch lowercase {
        case "milliliters", "milliliter", "mls":
            return "ml"
        case "grams", "gram", "gr":
            return "g"
        case "ounces", "ounce":
            return "oz"
        case "kilograms", "kilogram", "kgs", "kg":
            return "g" // Keep as g for now, could convert amount later
        case "pounds", "pound", "lbs", "lb":
            return "oz" // Convert to oz as closest match
        case "tablespoons", "tablespoon":
            return "tbsp"
        case "teaspoons", "teaspoon":
            return "tsp"
        case "pieces":
            return "piece"
        case "slices":
            return "slice"
        case "servings":
            return "serving"
        case "cups":
            return "cup"
        default:
            // Return as-is if it's already a standard unit, or default to "g"
            let validUnits = ["g", "ml", "oz", "cup", "tbsp", "tsp", "piece", "slice", "serving"]
            return validUnits.contains(lowercase) ? lowercase : "g"
        }
    }

    private var perServingMultiplier: Double {
        if isPerUnit { return 1.0 }
        return actualServingSize / 100
    }
    
    private var adjustedCalories: Double {
        displayFood.calories * perServingMultiplier * quantityMultiplier
    }

    private var adjustedProtein: Double {
        displayFood.protein * perServingMultiplier * quantityMultiplier
    }

    private var adjustedCarbs: Double {
        displayFood.carbs * perServingMultiplier * quantityMultiplier
    }

    private var adjustedFat: Double {
        displayFood.fat * perServingMultiplier * quantityMultiplier
    }

    private var adjustedSatFat: Double {
        (displayFood.saturatedFat ?? 0) * perServingMultiplier * quantityMultiplier
    }

    private var adjustedFiber: Double {
        displayFood.fiber * perServingMultiplier * quantityMultiplier
    }

    private var adjustedSugar: Double {
        displayFood.sugar * perServingMultiplier * quantityMultiplier
    }

    private var adjustedSalt: Double {
        // Convert sodium (mg) to salt (g): salt = sodium * 2.5 / 1000
        (displayFood.sodium * perServingMultiplier * quantityMultiplier * 2.5) / 1000
    }

    private var saltPer100g: Double {
        // Convert sodium (mg) to salt (g): salt = sodium * 2.5 / 1000
        (displayFood.sodium * 2.5) / 1000
    }
    
    private var glycemicIndex: Int? {
        glycemicData?.value
    }
    
    private var glycemicCategory: String? {
        guard let gi = glycemicIndex else { return nil }
        if gi <= 55 { return "Low" }
        else if gi <= 70 { return "Medium" }
        else { return "High" }
    }
    
    private var glycemicData: GlycemicIndexData? {
        return nil
    }
    
    private var glycemicLoad: Double? {
        guard let gi = glycemicIndex else { return nil }
        return (Double(gi) * adjustedCarbs) / 100
    }
    
    private var glycemicLoadCategory: String? {
        guard let gl = glycemicLoad else { return nil }
        if gl <= 10 { return "Low" }
        else if gl <= 20 { return "Medium" }
        else { return "High" }
    }
    
    private var nutritionScore: NutritionProcessingScore {
        // PERFORMANCE: Return cached score if available to prevent 40+ analyseAdditives calls
        if let cached = cachedNutritionScore {
            return cached
        }

        let submittedFoods = UserDefaults.standard.array(forKey: "submittedFoodsForReview") as? [String] ?? []
        let foodKey = "\(food.name)|\(food.brand ?? "")"

        // First check if we have user-verified ingredients (PERFORMANCE: use cached ingredients)
        if let userIngredients = cachedIngredients, !userIngredients.isEmpty {
            // Calculate score using user-verified ingredients
            let ingredientsString = userIngredients.joined(separator: ", ")
            return ProcessingScorer.shared.calculateProcessingScore(for: displayFood.name, ingredients: ingredientsString, sugarPer100g: displayFood.sugar)
        }

        // Fallback to official ingredients if available
        if let ingredients = displayFood.ingredients, !ingredients.isEmpty {
            // Remove from pending list if it was there
            if submittedFoods.contains(foodKey) {
                var updatedSubmittedFoods = submittedFoods
                updatedSubmittedFoods.removeAll { $0 == foodKey }
                UserDefaults.standard.set(updatedSubmittedFoods, forKey: "submittedFoodsForReview")
            }

            // Calculate score using ingredients (convert array to string)
            let ingredientsString = ingredients.joined(separator: ", ")
            return ProcessingScorer.shared.calculateProcessingScore(for: displayFood.name, ingredients: ingredientsString, sugarPer100g: displayFood.sugar)
        }

        // Only show "In Review" if the food was submitted AND has no ingredients
        if submittedFoods.contains(foodKey) {
            return NutritionProcessingScore(
                grade: .unknown,
                score: 0,
                explanation: "Awaiting Verification - Ingredients submitted for review",
                factors: ["Submitted for verification"],
                processingLevel: .unprocessed,
                additiveCount: 0,
                eNumberCount: 0,
                naturalScore: 0
            )
        }

        // Default score for foods without ingredients
        return ProcessingScorer.shared.calculateProcessingScore(for: displayFood.name, sugarPer100g: displayFood.sugar)
    }

    private var sugarScore: SugarContentScore {
        // Calculate sugar per serving (accounting for serving size and quantity)
        let sugarPerServing = displayFood.sugar * perServingMultiplier * quantityMultiplier

        // Pass both density and serving information for smart scoring
        return SugarContentScorer.shared.calculateSugarScore(
            sugarPer100g: displayFood.sugar,
            sugarPerServing: sugarPerServing,
            servingSizeG: actualServingSize * quantityMultiplier
        )
    }

    private var nutraSafeGrade: ProcessingScorer.NutraSafeProcessingGradeResult {
        // PERFORMANCE: Return cached grade if available
        if let cached = cachedNutraSafeGrade {
            return cached
        }

        // Compute the NutraSafe processing grade
        let result = ProcessingScorer.shared.computeNutraSafeProcessingGrade(for: displayFood)

        // Cache the result for performance
        DispatchQueue.main.async {
            cachedNutraSafeGrade = result
        }

        return result
    }
    
    enum IngredientsStatus {
        case verified, pending, unverified, clientVerified, userVerified, none
    }
    
    // Standardize ingredients to UK spelling and grammar
    private func standardizeToUKSpelling(_ ingredient: String) -> String {
        var standardized = ingredient.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove multiple consecutive spaces
        while standardized.contains("  ") {
            standardized = standardized.replacingOccurrences(of: "  ", with: " ")
        }

        // Fix common punctuation issues
        standardized = standardized.replacingOccurrences(of: " ,", with: ",")
        standardized = standardized.replacingOccurrences(of: " .", with: ".")
        standardized = standardized.replacingOccurrences(of: "( ", with: "(")
        standardized = standardized.replacingOccurrences(of: " )", with: ")")
        standardized = standardized.replacingOccurrences(of: " :", with: ":")

        // Ensure space after commas (for proper ingredient separation)
        standardized = standardized.replacingOccurrences(of: ",", with: ", ")
        // Then remove double spaces that might have been created
        while standardized.contains("  ") {
            standardized = standardized.replacingOccurrences(of: "  ", with: " ")
        }

        // US to UK spelling conversions (food-specific)
        let spellingMap: [String: String] = [
            // Common food spellings
            "flavor": "flavour",
            "flavoring": "flavouring",
            "flavored": "flavoured",
            "flavorings": "flavourings",
            "color": "colour",
            "coloring": "colouring",
            "colored": "coloured",
            "colorings": "colourings",
            "favorite": "favourite",
            "favorites": "favourites",
            "honor": "honour",
            "labor": "labour",

            // Chemical/additive spellings
            "sulfur": "sulphur",
            "sulfate": "sulphate",
            "sulfates": "sulphates",
            "sulfite": "sulphite",
            "sulfites": "sulphites",
            "aluminum": "aluminium",
            "fiber": "fibre",
            "fibers": "fibres",

            // Food terms
            "center": "centre",
            "liter": "litre",
            "liters": "litres",
            "meter": "metre",
            "meters": "metres",
            "milliliter": "millilitre",
            "milliliters": "millilitres",

            // -ize to -ise (common food industry terms)
            "stabilizer": "stabiliser",
            "stabilizers": "stabilisers",
            "stabilized": "stabilised",
            "crystallize": "crystallise",
            "crystallized": "crystallised",
            "caramelize": "caramelise",
            "caramelized": "caramelised",
            "pasteurize": "pasteurise",
            "pasteurized": "pasteurised",
            "homogenize": "homogenise",
            "homogenized": "homogenised",
            "optimize": "optimise",
            "optimized": "optimised",

            // -or to -our
            "vapor": "vapour",
            "vapors": "vapours",

            // Additional food-specific UK spellings
            "yogurt": "yoghurt",
            "yogurts": "yoghurts",
            "donut": "doughnut",
            "donuts": "doughnuts",
            "licorice": "liquorice",
            "gray": "grey",
            "aging": "ageing",
            "mold": "mould",
            "molds": "moulds",
            "moldy": "mouldy",
            "analog": "analogue",
            "catalog": "catalogue",
            "dialog": "dialogue",
            "defense": "defence",
            "offense": "offence",
            "pretense": "pretence",
            "license": "licence",
            "practice": "practise",
            "savory": "savoury",
            "savor": "savour"
        ]

        // Apply all spelling conversions (case-insensitive word boundary matching)
        for (us, uk) in spellingMap {
            // Match whole words only
            let pattern = "\\b\(us)\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(standardized.startIndex..., in: standardized)
                standardized = regex.stringByReplacingMatches(
                    in: standardized,
                    range: range,
                    withTemplate: uk
                )
            }
        }

        // Fix common grammar issues
        // Convert all-caps words to proper case (except known abbreviations)
        let knownAbbreviations = ["E", "B", "C", "D", "K", "GMO", "BHA", "BHT", "TBHQ", "MSG", "DNA", "RNA", "USA", "UK", "EU"]
        let words = standardized.components(separatedBy: " ")
        var correctedWords: [String] = []

        for word in words {
            // Check if word is all uppercase and longer than 2 characters
            if word.count > 2 && word.uppercased() == word && !word.contains("(") && !word.contains(")") {
                // Check if it's not a known abbreviation
                let isAbbreviation = knownAbbreviations.contains { abbr in
                    guard word.hasPrefix(abbr) else { return false }
                    if word.count == abbr.count {
                        return true
                    }
                    // Safely check if the next character after abbreviation is not a letter
                    let remainingPart = word.dropFirst(abbr.count)
                    guard let firstChar = remainingPart.first else { return false }
                    return !firstChar.isLetter
                }

                if !isAbbreviation {
                    // Convert to lowercase, will be properly capitalized later
                    correctedWords.append(word.lowercased())
                } else {
                    correctedWords.append(word)
                }
            } else {
                correctedWords.append(word)
            }
        }
        standardized = correctedWords.joined(separator: " ")

        // Proper capitalization rules for ingredients
        // Capitalize first letter only
        if !standardized.isEmpty {
            standardized = standardized.prefix(1).uppercased() + standardized.dropFirst().lowercased()
        }

        // Re-capitalize words that should always be capitalized (E-numbers, vitamins)
        // E-numbers (e.g., E100, E330)
        let eNumberPattern = "\\be\\d+"
        if let eRegex = try? NSRegularExpression(pattern: eNumberPattern, options: [.caseInsensitive]) {
            let matches = eRegex.matches(in: standardized, range: NSRange(standardized.startIndex..., in: standardized))
            for match in matches.reversed() {
                if let range = Range(match.range, in: standardized) {
                    let eNumber = String(standardized[range]).uppercased()
                    standardized.replaceSubrange(range, with: eNumber)
                }
            }
        }

        // Vitamins (e.g., vitamin B12, vitamin C)
        let vitaminPattern = "vitamin\\s+([a-z]\\d*)"
        if let vitRegex = try? NSRegularExpression(pattern: vitaminPattern, options: [.caseInsensitive]) {
            let matches = vitRegex.matches(in: standardized, range: NSRange(standardized.startIndex..., in: standardized))
            for match in matches.reversed() {
                if let range = Range(match.range, in: standardized),
                   let vitRange = Range(match.range(at: 1), in: standardized) {
                    let vitamin = String(standardized[vitRange]).uppercased()
                    let replacement = "vitamin " + vitamin
                    standardized.replaceSubrange(range, with: replacement)
                }
            }
        }

        // Capitalize proper nouns (common food ingredients)
        let properNouns = ["riboflavin", "thiamin", "niacin", "ribonucleotide", "ribonucleotides"]
        for noun in properNouns {
            let pattern = "\\b\(noun)\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(standardized.startIndex..., in: standardized)
                standardized = regex.stringByReplacingMatches(
                    in: standardized,
                    range: range,
                    withTemplate: noun.lowercased()
                )
            }
        }

        return standardized.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func getIngredientsStatus() -> IngredientsStatus {
        let submittedFoods = UserDefaults.standard.array(forKey: "submittedFoodsForReview") as? [String] ?? []
        let clientVerifiedFoods = UserDefaults.standard.array(forKey: "clientVerifiedFoods") as? [String] ?? []
        let userVerifiedFoods = UserDefaults.standard.array(forKey: "userVerifiedFoods") as? [String] ?? []
        let foodKey = "\(food.name)|\(food.brand ?? "")"

        // PRIORITY 1: Check if food is verified in the database (server-side verification)
        if displayFood.isVerified == true {
            return .verified
        }

        // Check if food is user-verified (photo taken by user on this device)
        if userVerifiedFoods.contains(foodKey) {
            return .userVerified
        }

        // Check if food is pending verification (user submitted for review)
        if submittedFoods.contains(foodKey) {
            return .pending
        }

        // Check if food was client verified by another user
        if clientVerifiedFoods.contains(foodKey) {
            return .clientVerified
        }

        // Check if food has ingredients/nutrition data but is unverified
        if let ingredients = displayFood.ingredients, !ingredients.isEmpty {
            let hasRealIngredients = ingredients.contains { ingredient in
                !ingredient.contains("Processing ingredient image...") && !ingredient.isEmpty
            }
            if hasRealIngredients {
                return .unverified
            }
        }

        // Food has nutrition data but no ingredients - still unverified
        if displayFood.calories > 0 || displayFood.protein > 0 || displayFood.carbs > 0 || displayFood.fat > 0 {
            return .unverified
        }

        return .none
    }
    
    private func getIngredientsList() -> [String]? {
        if let enhancedText = enhancedIngredientsText, !enhancedText.isEmpty {
            // Split enhanced ingredients text into array
            let enhancedIngredients = enhancedText
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if !enhancedIngredients.isEmpty {
                return enhancedIngredients.map { standardizeToUKSpelling($0) }
            }
        }

        // PRIORITY 2: Try to get ingredients from displayFood (uses enriched or original)
        if let ingredients = displayFood.ingredients, !ingredients.isEmpty {
            let realIngredients = ingredients.filter { ingredient in
                !ingredient.contains("Processing ingredient image...") && !ingredient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            if !realIngredients.isEmpty {
                return realIngredients.map { standardizeToUKSpelling($0) }
            }
        }

        // Check for user-verified ingredients first (from photo verification)
        let foodKey = "\(food.name)|\(food.brand ?? "")"
        let userVerifiedFoods = UserDefaults.standard.array(forKey: "userVerifiedFoods") as? [String] ?? []

        if userVerifiedFoods.contains(foodKey) {
            // Try to get the clean ingredients array first (from Gemini AI extraction)
            if let userIngredientsArray = UserDefaults.standard.array(forKey: "userIngredientsArray_\(foodKey)") as? [String] {
                return userIngredientsArray.map { standardizeToUKSpelling($0) }
            }
            // Fallback to clean ingredients text, split by comma
            else if let userIngredientsText = UserDefaults.standard.string(forKey: "userIngredients_\(foodKey)") {
                return userIngredientsText.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }.map { standardizeToUKSpelling($0) }
            }
        }

        // If no user-verified ingredients, check for submitted pending ingredients
        let submittedFoods = UserDefaults.standard.array(forKey: "submittedFoodsForReview") as? [String] ?? []

        if submittedFoods.contains(foodKey) {
            // Get submitted ingredients from local storage
            if let submittedData = UserDefaults.standard.data(forKey: "submittedIngredients_\(foodKey)"),
               let ingredients = try? JSONDecoder().decode([String].self, from: submittedData) {
                return ingredients.map { standardizeToUKSpelling($0) }
            }
        }

        // If no ingredients found, return nil
        return nil
    }

    private var hasIngredients: Bool {
        // PERFORMANCE: Use cached ingredients status
        let status = cachedIngredientsStatus ?? .none
        return status == .verified || status == .unverified || status == .clientVerified || status == .pending || status == .userVerified
    }
    
    private func getPotentialAllergens() -> [String] {
        // First check if we have AI-detected allergens from Gemini
        let foodKey = "\(food.id)_\(food.name)"
        if let aiDetectedAllergens = UserDefaults.standard.array(forKey: "userDetectedAllergens_\(foodKey)") as? [String],
           !aiDetectedAllergens.isEmpty {
            return aiDetectedAllergens.map { $0.capitalized }
        }

        // Fallback to manual detection from user ingredients (PERFORMANCE: use cached ingredients)
        guard let ingredients = cachedIngredients else { return [] }
        
        let commonAllergens = [
            ("Gluten", ["wheat", "barley", "rye", "oats", "spelt", "kamut", "gluten", "flour", "bran", "semolina", "durum", "triticale", "farro", "freekeh", "seitan", "malt", "beer", "lager", "ale", "stout"]),
            ("Dairy", ["milk", "cream", "butter", "cheese", "yogurt", "lactose", "casein", "whey", "skimmed milk powder", "milk powder"]),  // Specific cheeses handled by AllergenDetector.containsDairyMilk()
            ("Eggs", ["egg", "eggs", "albumin", "lecithin", "egg white", "egg yolk", "ovomucin", "mayonnaise", "meringue", "quiche", "frittata", "omelette", "brioche", "hollandaise", "aioli", "carbonara", "pavlova", "custard", "eggnog", "scotch egg"]),
            ("Nuts", ["almond", "hazelnut", "walnut", "cashew", "pistachio", "brazil nut", "macadamia", "pecan", "pine nut", "chestnut", "praline", "marzipan", "frangipane", "nougat", "nutella", "gianduja", "filbert"]),
            ("Peanuts", ["peanut", "groundnut", "arachis oil", "peanut oil", "peanut butter", "satay", "monkey nuts"]),
            ("Soy", ["soya", "soy", "soybean", "tofu", "tempeh", "miso", "soy lecithin", "soy protein", "shoyu", "tamari", "edamame", "natto", "tvp"]),
            ("Fish", ["fish", "anchovy", "tuna", "salmon", "cod", "haddock", "fish oil", "worcestershire", "mackerel", "sardine", "trout", "bass", "plaice", "pollock", "hake", "halibut", "herring", "kipper", "fish finger", "fish cake", "fish pie"]),
            ("Shellfish", ["shellfish", "crab", "lobster", "prawn", "shrimp", "crayfish", "langoustine", "king prawn", "tiger prawn", "crab stick"]),
            ("Sesame", ["sesame", "tahini", "sesame oil", "sesame seed", "hummus", "houmous", "halvah", "halva", "za'atar"]),
            ("Sulphites", ["sulphite", "sulfite", "sulphur dioxide", "sulfur dioxide", "e220", "e221", "e222", "e223", "e224", "e225", "e226", "e227", "e228", "metabisulphite", "metabisulfite"]),
            ("Celery", ["celery", "celeriac", "celery salt", "celery extract"]),
            ("Mustard", ["mustard", "mustard seed", "dijon", "wholegrain mustard"]),
            ("Lupin", ["lupin", "lupine", "lupin flour"]),
            ("Molluscs", ["mollusc", "mussel", "oyster", "clam", "scallop", "squid", "octopus", "snail", "calamari", "cockle", "winkle", "whelk", "cuttlefish", "abalone", "escargot"])
        ]
        
        var detectedAllergens: [String] = []
        let ingredientsText = ingredients.joined(separator: " ").lowercased()
        
        for (allergen, keywords) in commonAllergens {
            if allergen == "Dairy" {
                // Use refined dairy helper to avoid false positives like "coconut milk"
                if AllergenDetector.shared.containsDairyMilk(in: ingredientsText) {
                    detectedAllergens.append(allergen)
                }
            } else if keywords.contains(where: { ingredientsText.contains($0) }) {
                detectedAllergens.append(allergen)
            }
        }
        
        return detectedAllergens
    }

    // Load user's allergens from Firebase and detect which ones are in this food
    private func loadAndDetectUserAllergensOptimized() async {
        let savedAllergens = await firebaseManager.getUserAllergensWithCache()

        await MainActor.run {
            userAllergens = savedAllergens
            detectedUserAllergens = detectUserAllergensInFood(userAllergens: savedAllergens)
        }
    }

    // Check if food contains any of the user's allergens
    private func detectUserAllergensInFood(userAllergens: [Allergen]) -> [Allergen] {
        // Get food name and ingredients (PERFORMANCE: use cached ingredients)
        let foodName = displayFood.name.lowercased()
        let brand = displayFood.brand?.lowercased() ?? ""
        let ingredients = cachedIngredients?.map { $0.lowercased() } ?? []

        let searchText = ([foodName, brand] + ingredients).joined(separator: " ")

        var detected: [Allergen] = []

        for allergen in userAllergens {
            let found: Bool
            if allergen == .dairy {
                // Centralized dairy detection – excludes plant-based milks
                found = AllergenDetector.shared.containsDairyMilk(in: searchText)
            } else {
                // Keyword match for other allergens
                found = allergen.keywords.contains { keyword in
                    searchText.contains(keyword.lowercased())
                }
            }

            if found {
                detected.append(allergen)
            }
        }

        return detected
    }

    // MARK: - Allergen Warning Banner View (subtle Apple-style)
    private var allergenWarningBanner: some View {
        VStack(spacing: 6) {
            // Small red allergen pills
            HStack(spacing: 6) {
                ForEach(detectedUserAllergens, id: \.rawValue) { allergen in
                    HStack(spacing: 4) {
                        Text(allergen.icon)
                            .font(.system(size: 12))
                        Text(allergen.displayName)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(SemanticColors.caution)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
            }

            // Allergen disclaimer
            Text("Allergens may still be present if not shown. Ingredients may be outdated or incomplete. Always check the label.")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }


    private func getDetectedAdditives() -> [DetailedAdditive] {
                let currentDBVersion = ProcessingScorer.shared.databaseVersion
        let savedDBVersion = displayFood.additivesDatabaseVersion


        // Re-analyze if:
        // 1. No saved version (legacy data)
        // 2. Saved version is different from current version
        // 3. We have ingredients to analyze
        guard let ingredients = displayFood.ingredients, !ingredients.isEmpty else {
            // No ingredients to analyze - return empty list
            return []
        }

        let needsReAnalysis = savedDBVersion == nil || savedDBVersion != currentDBVersion

        if needsReAnalysis {
            let ingredientsText = ingredients.joined(separator: ", ")
            let freshAdditives = ProcessingScorer.shared.analyzeAdditives(in: ingredientsText)


            // Convert fresh analysis to DetailedAdditive format
            return freshAdditives.map { additive in
                let riskLevel: String
                if additive.effectsVerdict == .avoid {
                    riskLevel = "High"
                } else if additive.effectsVerdict == .caution {
                    riskLevel = "Moderate"
                } else {
                    riskLevel = "Low"
                }

                let overview = additive.overview.trimmingCharacters(in: .whitespacesAndNewlines)
                let uses = additive.typicalUses.trimmingCharacters(in: .whitespacesAndNewlines)

                let override = AdditiveOverrides.override(for: additive)

                let displayName = override?.displayName ?? additive.name
                var whatItIs = override?.whatItIs ?? (!overview.isEmpty ? overview : displayName)
                if !uses.isEmpty && override?.whatItIs == nil {
                    let cleanedUses = uses.trimmingCharacters(in: .punctuationCharacters)
                    if !whatItIs.lowercased().contains(cleanedUses.lowercased()) {
                        whatItIs += (whatItIs.isEmpty ? "" : ". ") + "Commonly used in \(cleanedUses)"
                    }
                }
                if !whatItIs.isEmpty && !whatItIs.hasSuffix(".") { whatItIs += "." }

                let originSummary = override?.originSummary ?? (additive.whereItComesFrom ?? additive.origin.rawValue.capitalized)
                let riskSummary = override?.riskSummary ?? (!additive.effectsSummary.isEmpty ? additive.effectsSummary : "No detailed information available for this additive.")

                return DetailedAdditive(
                    name: displayName,
                    code: additive.eNumber,
                    whatItIs: whatItIs,
                    origin: additive.origin.rawValue,
                    originSummary: originSummary,
                    childWarning: additive.hasChildWarning,
                    riskLevel: riskLevel,
                    riskSummary: riskSummary,
                    sources: additive.sources
                )
            }
        }

        // Use saved Firebase additive data if version is current
        if let firebaseAdditives = displayFood.additives, !firebaseAdditives.isEmpty {
                        return firebaseAdditives.map { additive in
                let riskLevel: String
                if additive.effectsVerdict == "avoid" {
                    riskLevel = "High"
                } else if additive.effectsVerdict == "caution" {
                    riskLevel = "Moderate"
                } else {
                    riskLevel = "Low"
                }

                // Use consumer guide if available, otherwise use a default message
                let displayName = additive.name
                let whatItIs = additive.consumerGuide ?? displayName
                let originSummary = additive.origin ?? "Origin not specified"
                let riskSummary = additive.consumerGuide ?? "No detailed information available for this additive."

                return DetailedAdditive(
                    name: displayName,
                    code: additive.code,
                    whatItIs: whatItIs,
                    origin: additive.origin ?? "Unknown",
                    originSummary: originSummary,
                    childWarning: additive.childWarning,
                    riskLevel: riskLevel,
                    riskSummary: riskSummary,
                    sources: []
                )
            }
        }

        // Fallback to local ingredient analysis if no Firebase data (PERFORMANCE: use cached ingredients)
        guard let ingredients = cachedIngredients else { return [] }
        let ingredientsText = ingredients.joined(separator: " ").lowercased()
        
        var detectedAdditives: [DetailedAdditive] = []
        
        // Comprehensive additive database with consumer-friendly descriptions
        let additiveDatabase = [
            // Artificial Colors - Common in candy like Nerds
            ("brilliant blue fcf", "E133", "Artificial Color", "Synthetic", true, "Moderate", "Bright blue synthetic dye used to make foods look appealing. Made in laboratories from petroleum-based chemicals."),
            ("sunset yellow fcf", "E110", "Artificial Color", "Synthetic", true, "High", "Orange-yellow synthetic dye linked to behavioral issues in children. Created from petroleum-based chemicals."),
            ("allura red", "E129", "Artificial Color", "Synthetic", true, "High", "Bright red synthetic dye that may cause hyperactivity. Common in candies and processed foods."),
            ("quinoline yellow", "E104", "Artificial Color", "Synthetic", true, "High", "Yellow synthetic dye that requires warning labels about potential effects on children's behavior."),
            ("patent blue", "E131", "Artificial Color", "Synthetic", false, "Moderate", "Blue synthetic dye used for coloring. Less commonly associated with behavioral issues."),
            
            // Sugars and Syrups
            ("corn syrup", nil, "Sweetener", "Processed", false, "Moderate", "Highly processed liquid sweetener made from corn starch. Provides sweetness and texture but offers no nutritional value."),
            ("glucose syrup", nil, "Sweetener", "Processed", false, "Moderate", "Concentrated sugar syrup used for sweetness and to prevent crystallization. Highly processed with minimal nutrition."),
            ("high fructose corn syrup", nil, "Sweetener", "Processed", false, "High", "Ultra-processed liquid sweetener linked to obesity and metabolic issues when consumed regularly."),
            ("invert sugar", nil, "Sweetener", "Processed", false, "Moderate", "Processed sugar syrup that prevents crystallization. Used to maintain texture in candies and baked goods."),
            ("dextrose", nil, "Sweetener", "Processed", false, "Low", "Simple sugar (glucose) that provides quick energy. Less processed than corn syrup but still adds empty calories."),
            
            // Preservatives and Acids
            ("citric acid", "E330", "Preservative/Flavor", "Natural/Synthetic", false, "Low", "Adds tartness and preserves freshness. Can be natural (from citrus) or synthetic (from fermentation)."),
            ("ascorbic acid", "E300", "Preservative/Antioxidant", "Natural/Synthetic", false, "Low", "Vitamin C used to prevent spoilage and maintain color. Generally safe and can provide nutritional benefits."),
            ("malic acid", "E296", "Flavor Enhancer", "Natural/Synthetic", false, "Low", "Provides tart, sour taste. Naturally found in apples but often made synthetically for food use."),
            ("sodium benzoate", "E211", "Preservative", "Synthetic", false, "Moderate", "Prevents mold and bacteria growth. Can form benzene (a carcinogen) when combined with vitamin C under certain conditions."),
            
            // Flavorings
            ("natural flavoring", nil, "Flavoring", "Natural/Processed", false, "Low", "Flavor compounds derived from natural sources but often heavily processed. 'Natural' doesn't always mean healthier."),
            ("artificial flavoring", nil, "Flavoring", "Synthetic", false, "Moderate", "Lab-created flavor compounds designed to mimic natural tastes. Safe in small amounts but adds no nutritional value."),
            ("natural flavour", nil, "Flavoring", "Natural/Processed", false, "Low", "Flavor compounds derived from natural sources but often heavily processed. 'Natural' doesn't always mean healthier."),
            ("artificial flavour", nil, "Flavoring", "Synthetic", false, "Moderate", "Lab-created flavor compounds designed to mimic natural tastes. Safe in small amounts but adds no nutritional value."),
            
            // Other Common Additives
            ("carnauba wax", "E903", "Glazing Agent", "Natural", false, "Low", "Natural wax from palm leaves used to make candies shiny. Generally safe but provides no nutritional value."),
            ("lecithin", "E322", "Emulsifier", "Natural", false, "Low", "Helps mix oil and water-based ingredients. Usually derived from soy or sunflower - generally considered safe."),
            ("modified starch", nil, "Thickener", "Processed", false, "Low", "Chemically altered starch used to improve texture. Heavily processed but generally safe in food amounts.")
        ]
        
        // Check each additive in the database against ingredients
        for (additiveName, code, _, origin, childWarning, riskLevel, description) in additiveDatabase {
            if ingredientsText.contains(additiveName.lowercased()) {
                detectedAdditives.append(DetailedAdditive(
                    name: additiveName.capitalized,
                    code: code,
                    whatItIs: description,
                    origin: origin,
                    originSummary: origin,
                    childWarning: childWarning,
                    riskLevel: riskLevel,
                    riskSummary: description,
                    sources: []
                ))
            }
        }
        
        return detectedAdditives
    }
    
    private func getAmountOptions() -> [Double] {
        var options: [Double] = []
        
        // Generate logical amounts based on unit
        if selectedUnit == "g" {
            // For grams: 10, 25, 50, 75, 100, 125, 150, 200, 250, 300, 500
            for amount in stride(from: 10, through: 100, by: 10) {
                options.append(Double(amount))
            }
            options.append(contentsOf: [125, 150, 200, 250, 300, 500])
        } else if selectedUnit == "cups" {
            // For cups: 0.25, 0.5, 0.75, 1, 1.25, 1.5, 2, 2.5, 3
            options = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 2, 2.5, 3]
        } else if selectedUnit == "tbsp" {
            // For tablespoons: 1, 2, 3, 4, 5, 6, 8, 10, 12
            options = [1, 2, 3, 4, 5, 6, 8, 10, 12]
        } else if selectedUnit == "ml" {
            // For ml: 50, 100, 150, 200, 250, 300, 400, 500
            options = [50, 100, 150, 200, 250, 300, 400, 500]
        }
        
        return options.sorted()
    }
    
    private func getUnitOptions() -> [String] {
        return ["g", "cups", "tbsp", "ml", "oz"]
    }
    
    private func getServingsOptions() -> [Double] {
        var options: [Double] = []
        
        // Generate servings from 0.1 to 5 in increments
        for i in 1...10 {
            options.append(Double(i) * 0.1) // 0.1, 0.2, 0.3, ... 1.0
        }
        for i in 2...10 {
            options.append(Double(i) * 0.5) // 1.0, 1.5, 2.0, ... 5.0
        }
        
        return Array(Set(options)).sorted()
    }
    
    private func formatServings(_ servings: Double) -> String {
        if servings == 1.0 {
            return "1x serving"
        } else if servings.truncatingRemainder(dividingBy: 1) == 0 {
            // Whole number
            return "\(Int(servings))x servings"
        } else if servings.truncatingRemainder(dividingBy: 0.5) == 0 {
            // Half increment (like 1.5, 2.5, etc.)
            return String(format: "%.1fx servings", servings)
        } else {
            // Other decimal
            return String(format: "%.1fx servings", servings)
        }
    }
    
    private var foodHeaderView: some View {
        VStack(spacing: 4) {
            // Small verification status at top
            verificationStatusView

            Text(displayFood.name)
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)

            if let brand = displayFood.brand {
                Text(brand)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }

            // Allergen Warning - Show below brand as subtle red pills
            if !detectedUserAllergens.isEmpty {
                allergenWarningBanner
                    .padding(.top, 4)
            }
        }
    }

    private var verificationStatusView: some View {
        // Hidden - no longer showing verified/unverified status
        EmptyView()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // REDESIGN: Soft gradient background matching onboarding - NOT pure white
                foodDetailBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 20) {
                        // REDESIGN: Floating header with soft integration
                        redesignedHeaderSection

                        // REDESIGN: Primary action buttons - prominent and inviting
                        redesignedActionButtons

                        // REDESIGN: Serving selection - human and interactive
                        redesignedServingSection
                            .onAppear {
                            // Determine the appropriate unit based on food category
                            let appropriateUnit = food.isLiquidCategory ? "ml" : "g"

                            // Only auto-detect serving size for non per-unit foods
                            if !isPerUnit, servingAmount == "1" && (servingUnit == "g" || servingUnit == "ml") {
                                // PRIORITY 1: Use servingSizeG if available (most reliable)
                                if let sizeG = food.servingSizeG, sizeG > 0 {
                                    servingAmount = String(format: "%.0f", sizeG)
                                    servingUnit = appropriateUnit
                                    gramsAmount = String(format: "%.0f", sizeG)  // Also update gramsAmount
                                } else {
                                    // PRIORITY 2: Extract from serving description
                                    let description = food.servingDescription ?? "100g"

                                    // Try to extract amount from multiple patterns (g or ml)
                                    let patterns = [
                                        #"(\d+(?:\.\d+)?)\s*(?:g|ml)\s+serving"#,  // Match "150g serving" or "330ml serving"
                                        #"\((\d+(?:\.\d+)?)\s*(?:g|ml)\)"#,         // Match "(345 g)" or "(330ml)" in parentheses
                                        #"^(\d+(?:\.\d+)?)\s*(?:g|ml)$"#,           // Match "345g" or "330ml" at start
                                        #"^(\d+(?:\.\d+)?)\s+(?:g|ml)$"#            // Match "345 g" or "330 ml" at start with space
                                    ]

                                    var found = false
                                    for pattern in patterns {
                                        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                                           let match = regex.firstMatch(in: description, options: [], range: NSRange(location: 0, length: description.count)),
                                           let range = Range(match.range(at: 1), in: description) {
                                            let extractedValue = String(description[range])
                                            servingAmount = extractedValue
                                            servingUnit = appropriateUnit
                                            gramsAmount = extractedValue  // Also update gramsAmount
                                            found = true
                                            break
                                        }
                                    }

                                    // PRIORITY 3: If nothing found, attempt per-unit detection before defaulting
                                    if !found {
                                        let lower = description.lowercased()
                                        let unitWords = ["serving","piece","slice","burger","wrap","taco","burrito","sandwich","portion"]
                                        var setUnit = false
                                        if lower.hasPrefix("1 ") {
                                            let unitCandidate = lower.split(separator: " ").dropFirst().joined(separator: " ")
                                            if !unitCandidate.isEmpty {
                                                servingAmount = "1"
                                                servingUnit = String(unitCandidate)
                                                gramsAmount = ""
                                                setUnit = true
                                            }
                                        }
                                        if !setUnit, let foundWord = unitWords.first(where: { lower.contains($0) }) {
                                            servingAmount = "1"
                                            servingUnit = foundWord
                                            gramsAmount = ""
                                            setUnit = true
                                        }
                                        if !setUnit {
                                            let nameLower = food.name.lowercased()
                                            if let fromName = unitWords.first(where: { nameLower.contains($0) }) {
                                                servingAmount = "1"
                                                servingUnit = fromName
                                                gramsAmount = ""
                                                setUnit = true
                                            }
                                        }
                                        if !setUnit {
                                            servingAmount = "100"
                                            servingUnit = appropriateUnit
                                            gramsAmount = "100"
                                        }
                                    }
                                }
                            }

                            // Check for preselected meal type from diary (only if not editing existing entry)
                            if diaryMealType == nil, let preselectedMeal = UserDefaults.standard.string(forKey: "preselectedMealType") {
                                selectedMeal = preselectedMeal
                                // Clear the stored value after using it
                                UserDefaults.standard.removeObject(forKey: "preselectedMealType")
                            }
                        }
                    
                        // REDESIGN: Glanceable nutrition card
                        redesignedNutritionCard

                        // REDESIGN: Calm insight scores (not warnings)
                        redesignedScoresSection

                        // REDESIGN: Pill-style insight tabs
                        redesignedWatchTabs

                        // REDESIGN: Clean, readable ingredients
                        redesignedIngredientsSection

                        // REDESIGN: Supportive verification section
                        let ingredientsStatus = cachedIngredientsStatus ?? .none
                        if ingredientsStatus == .pending {
                            ingredientInReviewSection
                        } else {
                            redesignedVerificationSection
                        }

                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, DesignTokens.Spacing.screenEdge)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // REDESIGN: Floating close button
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(palette.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                            )
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    // REDESIGN: Floating favorite button
                    Button(action: toggleFavorite) {
                        if isTogglingFavorite {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 32, height: 32)
                        } else {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(isFavorite ? SemanticColors.caution : palette.textSecondary)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                )
                        }
                    }
                    .disabled(isTogglingFavorite)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .presentationBackground(colorScheme == .dark ? Color.midnightBackground : palette.background)
        .onAppear {
            // Only initialize once per view instance, even if .onAppear is called multiple times
            guard !hasInitialized else { return }
            hasInitialized = true

            cachedIngredients = food.ingredients
            cachedIngredientsStatus = getIngredientsStatus()
            recomputeDetectedNutrients()

            // Load user allergens from cache (instant) and detect if present in this food
            Task {
                await loadAndDetectUserAllergensOptimized()
            }

            // Check if food is in favorites
            Task {
                if let isFav = try? await firebaseManager.isFavoriteFood(foodId: food.id) {
                    await MainActor.run {
                        isFavorite = isFav
                    }
                }
            }

            // Check for editing mode
            if let mode = UserDefaults.standard.string(forKey: "foodSearchMode"), mode == "editing" {
                isEditingMode = true
                originalMealType = UserDefaults.standard.string(forKey: "editingMealType") ?? ""
                selectedMeal = originalMealType

                // Load saved quantity and serving size for editing
                if let savedQuantity = UserDefaults.standard.object(forKey: "editingQuantity") as? Double {
                    quantityMultiplier = savedQuantity
                }
                if let savedServingDesc = UserDefaults.standard.string(forKey: "editingServingDescription") {
                    servingSizeText = savedServingDesc
                }

                // Clear editing context after loading
                UserDefaults.standard.removeObject(forKey: "foodSearchMode")
                UserDefaults.standard.removeObject(forKey: "editingMealType")
                UserDefaults.standard.removeObject(forKey: "editingFoodId")
                UserDefaults.standard.removeObject(forKey: "editingQuantity")
                UserDefaults.standard.removeObject(forKey: "editingServingDescription")
            } else if diaryMealType == nil, let preselectedMeal = UserDefaults.standard.string(forKey: "preselectedMealType") {
                // Only use preselected meal if not editing an existing diary entry
                selectedMeal = preselectedMeal
                // Clear the stored value after using it
                UserDefaults.standard.removeObject(forKey: "preselectedMealType")
            }

            // Initialize picker values based on current food serving data
            selectedAmount = Double(gramsAmount) ?? 100
            selectedServings = Double(servings) ?? 1.0
            selectedUnit = "g"

            // If there's a serving description, try to extract unit information
            if let servingDesc = displayFood.servingDescription?.lowercased() {
                if servingDesc.contains("cup") {
                    selectedUnit = "cups"
                } else if servingDesc.contains("tbsp") || servingDesc.contains("tablespoon") {
                    selectedUnit = "tbsp"
                } else if servingDesc.contains("ml") || servingDesc.contains("milliliter") {
                    selectedUnit = "ml"
                } else if servingDesc.contains("oz") || servingDesc.contains("ounce") {
                    selectedUnit = "oz"
                }
            }
        }
        .trackScreen("Food Detail")
        .onChange(of: food.id) {
            // Invalidate all caches when food changes (e.g., switching between search and diary)
            cachedIngredients = nil
            cachedIngredientsStatus = nil
            cachedAdditives = nil
            cachedNutritionScore = nil
            cachedNutraSafeGrade = nil
            hasInitialized = false
            cachedDetectedNutrients = []
        }
        .onChange(of: enhancedIngredientsText) {
            // Invalidate caches when enhanced ingredients data changes
            cachedIngredients = nil
            cachedIngredientsStatus = nil
            cachedAdditives = nil
            cachedNutraSafeGrade = nil  // Grade depends on ingredients
            cachedDetectedNutrients = []
        }
        .onChange(of: cachedIngredients) {
            recomputeDetectedNutrients()
        }
        .onChange(of: enhancedNutrition?.calories) {
            // Invalidate caches when enhanced nutrition data changes
            cachedNutritionScore = nil
            cachedNutraSafeGrade = nil  // Grade may depend on nutrition completeness
        }
        .alert("Team Notified", isPresented: $showingNotificationSuccess) {
            Button("OK") { }
        } message: {
            Text("Thank you! Our team has been notified about the incomplete information for this food. We'll work on adding the missing details.")
        }
        .alert("Notification Failed", isPresented: $showingNotificationError) {
            Button("OK") { }
        } message: {
            Text(notificationErrorMessage)
        }
        // MARK: - Fasting Integration Alert
        .alert("Food Logged During Fast", isPresented: $showingFastingPrompt) {
            Button("End Fast Now") {
                performFoodLog(endFast: true)
            }
            Button("Just Log Food", role: .cancel) {
                performFoodLog(endFast: false)
            }
        } message: {
            Text("You're currently fasting. Would you like to end your fast since you've eaten?")
        }
        .diaryLimitAlert(
            isPresented: $showingDiaryLimitError,
            showingPaywall: $showingPaywall
        )
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView()
        }
        .fullScreenCover(isPresented: $showingNutritionCamera) {
            IngredientCameraView(
                foodName: food.name,
                onImageCaptured: { image in
                    nutritionImage = image
                    showingNutritionCamera = false
                },
                onDismiss: {
                    showingNutritionCamera = false
                },
                photoType: .nutrition
            )
        }
        .fullScreenCover(isPresented: $showingBarcodeCamera) {
            IngredientCameraView(
                foodName: food.name,
                onImageCaptured: { image in
                    barcodeImage = image
                    showingBarcodeCamera = false
                },
                onDismiss: {
                    showingBarcodeCamera = false
                },
                photoType: .barcode
            )
        }
        // UseBy add flow
        .fullScreenCover(isPresented: Binding(
            get: { showingUseByAddSheet },
            set: { newValue in
                if !newValue {
                    // Disable animation when dismissing
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        showingUseByAddSheet = false
                    }
                } else {
                    showingUseByAddSheet = newValue
                }
            }
        )) {
            // Reuse UseBy add sheet for details like expiry/location
            AddFoundFoodToUseBySheet(food: food) { tab in
                selectedTab = tab
                // Dismiss parent sheet without animation
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    dismiss()
                }
            }
        }
        .fullScreenCover(isPresented: $showingNutraSafeInfo) {
            NutraSafeGradeInfoView(result: nutraSafeGrade, food: displayFood)
        }
        .fullScreenCover(isPresented: $showingSugarInfo) {
            SugarScoreInfoView(
                score: sugarScore,
                food: displayFood,
                perServingSugar: displayFood.sugar * perServingMultiplier * quantityMultiplier
            )
        }
        .fullScreenCover(isPresented: $showingVitaminCitations) {
            NavigationView {
                List {
                    Section(header: Text("Vitamin & Mineral Health Claims")) {
                        Text("Health benefits shown are based on official EFSA-approved health claims and NHS nutritional guidance.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    }

                    ForEach(CitationManager.shared.citations(for: .dailyValues).filter {
                        $0.title.contains("Vitamin") || $0.title.contains("Iron") || $0.title.contains("Calcium")
                    }) { citation in
                        Button(action: {
                            if let url = URL(string: citation.url) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .foregroundColor(AppPalette.standard.accent)
                                    Text(citation.organization)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.caption)
                                        .foregroundColor(AppPalette.standard.accent)
                                }
                                Text(citation.title)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
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
                            showingVitaminCitations = false
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingAllergenCitations) {
            NavigationView {
                List {
                    Section(header: Text("Allergen Detection")) {
                        Text("Allergen warnings are based on UK FSA and EU food safety regulations.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    }

                    ForEach(CitationManager.shared.citations(for: .allergens)) { citation in
                        Button(action: {
                            if let url = URL(string: citation.url) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .foregroundColor(AppPalette.standard.accent)
                                    Text(citation.organization)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.caption)
                                        .foregroundColor(AppPalette.standard.accent)
                                }
                                Text(citation.title)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                Text(citation.description)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(3)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .navigationTitle("Allergen Sources")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingAllergenCitations = false
                        }
                    }
                }
            }
        }
        // Barcode scanner for enhancement
        .fullScreenCover(isPresented: $showingBarcodeScannerForEnhancement) {
            BarcodeScannerForEnhancement(
                onBarcodeScanned: { barcode in
                    showingBarcodeScannerForEnhancement = false
                    enhanceWithBarcode(barcode)
                },
                onDismiss: {
                    showingBarcodeScannerForEnhancement = false
                }
            )
        }
        // Manual search for enhancement
        .fullScreenCover(isPresented: $showingManualSearchForEnhancement) {
            NavigationView {
                VStack(spacing: 20) {
                    Text("Search for Product")
                        .font(.title2.weight(.bold))
                        .padding(.top)

                    Text("Enter the product name or description to search UK supermarket databases.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14))
                                .foregroundColor(AppPalette.standard.accent)
                            Text("Enter the food and brand name to search")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppPalette.standard.accent)
                        }
                        .padding(.horizontal)

                        TextField("e.g., Cadbury Dairy Milk 200g", text: $manualSearchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)

                    Button(action: {
                        if !manualSearchText.isEmpty {
                            showingManualSearchForEnhancement = false
                            enhanceWithManualSearch(manualSearchText)
                        }
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Search")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(manualSearchText.isEmpty ? palette.tertiary : AppPalette.standard.accent)
                        .cornerRadius(10)
                    }
                    .disabled(manualSearchText.isEmpty)
                    .padding(.horizontal)

                    Spacer()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            showingManualSearchForEnhancement = false
                        }
                    }
                }
            }
        }
        // AI-Inferred Ingredients Sheet
        .sheet(isPresented: $showingInferredIngredientsSheet) {
            InferredIngredientsSheet(
                foodName: displayFood.name,
                inferredIngredients: $inferredIngredients
            )
        }
    }


private var nutritionFactsSection: some View {
    NutritionFactsSectionView(
        adjustedCalories: adjustedCalories,
        quantityMultiplier: quantityMultiplier,
        servingSizeText: isPerUnit ? servingUnit : "\(servingAmount)\(servingUnit)",
        per100Calories: displayFood.calories,
        adjustedProtein: adjustedProtein,
        adjustedCarbs: adjustedCarbs,
        adjustedFat: adjustedFat,
        adjustedSatFat: adjustedSatFat,
        adjustedFiber: adjustedFiber,
        adjustedSugar: adjustedSugar,
        adjustedSalt: adjustedSalt,
        per100Protein: displayFood.protein,
        per100Carbs: displayFood.carbs,
        per100Fat: displayFood.fat,
        per100SatFat: displayFood.saturatedFat ?? 0,
        per100Fiber: displayFood.fiber,
        per100Sugar: displayFood.sugar,
        per100Salt: saltPer100g,
        isPerUnit: isPerUnit,
        servingUnitLabel: servingUnit
    )
}
    
    private func nutritionRowModern(_ label: String, perServing: Double, per100g: Double, unit: String) -> some View {
        HStack(spacing: 8) {
            // Label
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 60, alignment: .leading)
            
            // Per serving number (right aligned)
            Text(String(format: unit == "mg" ? "%.0f" : "%.1f", perServing))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .frame(width: 55, alignment: .trailing)
            
            // Unit column (left aligned, consistent position)
            Text(unit)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 15, alignment: .leading)
            
            // Separator
            Text("•")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Right section: Per 100g or per unit (dynamic)
            HStack(spacing: 2) {
                let rightValue = isPerUnit ? perServing : per100g
                Text(String(format: unit == "mg" ? "%.0f" : "%.1f", rightValue))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                Text(isPerUnit ? unit + "/\(servingUnit)" : unit + "/100g")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.adaptiveCard)
        )
    }
    
    private func nutritionRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Add to Food Log Functionality
    private func addToFoodLog() {
        // Check if user is currently fasting - if so, check drinks philosophy
        if isCurrentlyFasting {
            // Check if this food is allowed during the fast based on user's drinks philosophy
            if let plan = fastingViewModel?.activePlan {
                if food.isAllowedDuringFast(philosophy: plan.allowedDrinks) {
                    // Food is allowed during fast (e.g., sugar-free drink in practical mode)
                    // Log without prompting to end fast
                    performFoodLog(endFast: false)
                    return
                }
            }
            // Not allowed during fast - prompt user
            showingFastingPrompt = true
            return  // Don't log yet - wait for user decision in the alert
        }

        // Not fasting - proceed with normal logging
        performFoodLog(endFast: false)
    }

    /// Log food and optionally start a new fast
    private func addToFoodLogAndStartFast() {
                isStartingFastAfterLog = true
        performFoodLog(endFast: false, startFast: true)
    }

    /// Core food logging logic - extracted for reuse
    private func performFoodLog(endFast: Bool, startFast: Bool = false) {
        let servingSize = actualServingSize
        
        // Calculate totals based on whether values are per-unit or per-100g
        let totalCalories: Double
        let totalProtein: Double
        let totalCarbs: Double
        let totalFat: Double
        let totalFiber: Double
        let totalSugar: Double
        let totalSodium: Double

        if food.isPerUnit == true {
            // Per-unit mode: values are already per unit, just multiply by quantity
            totalCalories = displayFood.calories * quantityMultiplier
            totalProtein = displayFood.protein * quantityMultiplier
            totalCarbs = displayFood.carbs * quantityMultiplier
            totalFat = displayFood.fat * quantityMultiplier
            totalFiber = displayFood.fiber * quantityMultiplier
            totalSugar = displayFood.sugar * quantityMultiplier
            totalSodium = displayFood.sodium * quantityMultiplier
        } else {
            // Per-100g mode: convert to serving size first, then multiply by quantity
            totalCalories = displayFood.calories * (servingSize / 100) * quantityMultiplier
            totalProtein = displayFood.protein * (servingSize / 100) * quantityMultiplier
            totalCarbs = displayFood.carbs * (servingSize / 100) * quantityMultiplier
            totalFat = displayFood.fat * (servingSize / 100) * quantityMultiplier
            totalFiber = displayFood.fiber * (servingSize / 100) * quantityMultiplier
            totalSugar = displayFood.sugar * (servingSize / 100) * quantityMultiplier
            totalSodium = displayFood.sodium * (servingSize / 100) * quantityMultiplier
        }

        // FIX: Do NOT generate micronutrient profile from macros
        // The old system multiplied macros by arbitrary factors to create fake vitamin data
        // (e.g., protein × 2.5 = Vitamin A, carbs × 0.8 = Vitamin C - completely fictitious)
        // The dashboard now uses ingredient-based analysis with position weighting instead
        // This ensures only REAL nutrients from actual ingredients are shown

        // Create diary entry
                // Create appropriate serving description based on food type
        let servingDesc: String
        if food.isPerUnit == true {
            // Per-unit food: show unit name (e.g., "medium drink", "burger")
            // The quantity is stored separately in the DiaryFoodItem.quantity field
            servingDesc = servingUnit
        } else {
            // Per-100g food: show "Xg serving"
            servingDesc = "\(String(format: "%.0f", servingSize))g serving"
        }

        // CRITICAL FIX: Analyze additives fresh from ingredients and save to diary
        // displayFood.additives is often nil/empty - fresh detection happens in getDetectedAdditives() for display only
        // This ensures detected additives are actually saved with the food entry
        let additivesToSave: [NutritionAdditiveInfo]?
        if let ingredients = displayFood.ingredients, !ingredients.isEmpty {
            let ingredientsText = ingredients.joined(separator: ", ")
            let freshAdditives = ProcessingScorer.shared.analyzeAdditives(in: ingredientsText)

            // Convert AdditiveInfo to NutritionAdditiveInfo for diary storage
            additivesToSave = freshAdditives.map { additive in
                // Calculate health score based on verdict and warnings
                var healthScore = 70 // Base score
                if additive.hasChildWarning { healthScore -= 20 }
                if additive.hasPKUWarning { healthScore -= 15 }
                if additive.hasPolyolsWarning { healthScore -= 10 }
                if additive.effectsVerdict == .caution { healthScore -= 15 }
                if additive.effectsVerdict == .avoid { healthScore -= 25 }
                healthScore = max(0, min(100, healthScore))

                return NutritionAdditiveInfo(
                    code: additive.eNumber,
                    name: additive.name,
                    category: additive.group.displayName,
                    healthScore: healthScore,
                    childWarning: additive.hasChildWarning,
                    effectsVerdict: additive.effectsVerdict.rawValue,
                    consumerGuide: additive.consumerInfo,
                    origin: additive.origin.rawValue
                )
            }
        } else {
            // Fallback to displayFood.additives if no ingredients to analyze
            additivesToSave = displayFood.additives
        }

        let diaryEntry = DiaryFoodItem(
            id: diaryEntryId ?? UUID(),
            name: displayFood.name,
            brand: displayFood.brand,
            calories: Int(totalCalories),
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat,
            fiber: totalFiber,
            sugar: totalSugar,
            sodium: totalSodium,
            servingDescription: servingDesc,
            quantity: quantityMultiplier,
            time: selectedMeal,
            processedScore: nutraSafeGrade.grade,
            sugarLevel: getSugarLevel(),
            ingredients: displayFood.ingredients,
            additives: additivesToSave,  // Use fresh analyzed additives instead of displayFood.additives
            barcode: displayFood.barcode,
            micronutrientProfile: nil,  // FIX: Don't save fake macro-based estimates
            isPerUnit: food.isPerUnit
        )

        // Add to diary using DiaryDataManager
        // Determine target date based on context
        let targetDate: Date
        if diaryEntryId != nil {
            // Editing an existing diary entry: use explicit diary date when provided
            targetDate = diaryDate ?? Date()
        } else {
            // Adding new item: use preselected date if available, otherwise today
            if let preselectedTimestamp = UserDefaults.standard.object(forKey: "preselectedDate") as? Double {
                targetDate = Date(timeIntervalSince1970: preselectedTimestamp)
                UserDefaults.standard.removeObject(forKey: "preselectedDate")
            } else {
                targetDate = Date()
            }
        }

        // Check if we're replacing an existing diary entry or adding a new one
        if let _ = diaryEntryId {

            let hasAccess = subscriptionManager.hasAccess
            let isMovingMeal = originalMealType.lowercased() != selectedMeal.lowercased()

            // Dismiss immediately for instant UX
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                dismiss()
            }
            onComplete?(.diary)

            // Save in background
            let entry = diaryEntry
            let meal = selectedMeal
            let originalMeal = originalMealType
            let date = targetDate
            let manager = diaryDataManager
            let vm = fastingViewModel
            let shouldEndFast = endFast
            let shouldStartFast = startFast

            Task.detached(priority: .userInitiated) {
                do {
                    if isMovingMeal {
                        try await manager.moveFoodItem(entry, from: originalMeal, to: meal, for: date, hasProAccess: hasAccess)
                    } else {
                        try await manager.replaceFoodItem(entry, to: meal, for: date, hasProAccess: hasAccess)
                    }

                    // Handle fasting actions (same as new entry path)
                    if shouldEndFast, let fastingVM = vm {
                        let endedSession = await fastingVM.endFastingSession()
                        if endedSession == nil {
                            let isInFastingWindow = await MainActor.run {
                                if case .fasting = fastingVM.currentRegimeState {
                                    return true
                                }
                                return false
                            }
                            if isInFastingWindow {
                                await fastingVM.skipCurrentRegimeFast()
                            }
                        }
                    }

                    if shouldStartFast, let fastingVM = vm {
                        await fastingVM.startFastingSession()
                        await MainActor.run {
                            NotificationCenter.default.post(name: .navigateToFasting, object: nil)
                        }
                    }
                } catch is FirebaseManager.DiaryLimitError {
                    // Diary limit reached - silently fail as we're in background
                } catch {
                    // Other errors - silently fail as we're in background
                }
            }
        } else {
            // Adding new food item

            let hasAccess = subscriptionManager.hasAccess

            // Dismiss immediately for instant UX
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                dismiss()
            }
            onComplete?(.diary)

            // Save in background
            let entry = diaryEntry
            let meal = selectedMeal
            let date = targetDate
            let manager = diaryDataManager
            let vm = fastingViewModel
            let shouldEndFast = endFast
            let shouldStartFast = startFast

            Task.detached(priority: .userInitiated) {
                do {
                    try await manager.addFoodItem(entry, to: meal, for: date, hasProAccess: hasAccess)

                    // Handle fasting actions
                    if shouldEndFast, let fastingVM = vm {
                        // Try ending standalone session first
                        let endedSession = await fastingVM.endFastingSession()
                        if endedSession != nil {
                            // Session ended successfully
                        } else {
                            // No active session - check if in regime mode fasting window
                            // Use MainActor.run to access @MainActor-isolated property (Swift 6 fix)
                            let isInFastingWindow = await MainActor.run {
                                if case .fasting = fastingVM.currentRegimeState {
                                    return true
                                }
                                return false
                            }
                            if isInFastingWindow {
                                await fastingVM.skipCurrentRegimeFast()
                            }
                        }
                    }

                    if shouldStartFast, let fastingVM = vm {
                        await fastingVM.startFastingSession()
                        // Navigate to fasting tab to show the normal timer view
                        await MainActor.run {
                            NotificationCenter.default.post(name: .navigateToFasting, object: nil)
                        }
                    }
                } catch is FirebaseManager.DiaryLimitError {
                    // For free users hitting limit - they'll see on diary tab
                } catch {
                    // Other errors - silently fail as we're in background
                }
            }
        }
    }
    
    private func formatQuantityMultiplier(_ quantity: Double) -> String {
        if quantity == 0.5 {
            return "½"
        } else if quantity == floor(quantity) {
            return "\(Int(quantity))"
        } else {
            return String(format: "%.1f", quantity)
        }
    }

    private var ingredientsSection: some View {
        IngredientsSectionView(
            status: cachedIngredientsStatus,
            ingredients: cachedIngredients,
            userAllergens: userAllergens,
            foodName: displayFood.name,
            showingInferredIngredientsSheet: $showingInferredIngredientsSheet,
            isEstimatingIngredients: isEstimatingIngredients,
            onEstimateIngredients: estimateIngredientsWithAI
        )
    }

    struct NutritionFactsSectionView: View {
        let adjustedCalories: Double
        let quantityMultiplier: Double
        let servingSizeText: String
        let per100Calories: Double
        let adjustedProtein: Double
        let adjustedCarbs: Double
        let adjustedFat: Double
        let adjustedSatFat: Double
        let adjustedFiber: Double
        let adjustedSugar: Double
        let adjustedSalt: Double
        let per100Protein: Double
        let per100Carbs: Double
        let per100Fat: Double
        let per100SatFat: Double
        let per100Fiber: Double
        let per100Sugar: Double
        let per100Salt: Double
        let isPerUnit: Bool
        let servingUnitLabel: String
        @Environment(\.colorScheme) private var colorScheme

        private var palette: AppPalette {
            AppPalette.forCurrentUser(colorScheme: colorScheme)
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("CALORIES")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                        .padding(.horizontal, 20)
                    HStack(alignment: .bottom, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Per Serving")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            HStack(alignment: .bottom, spacing: 4) {
                                Text(String(format: "%.0f", adjustedCalories))
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                Text("kcal")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 2)
                            }
                            Text("\(quantityMultiplier == 0.5 ? "½" : String(format: "%.0f", quantityMultiplier))× \(servingSizeText)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(isPerUnit ? "Per \(servingUnitLabel)" : "Per 100g")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            HStack(alignment: .bottom, spacing: 4) {
                                let rightCalories = isPerUnit ? adjustedCalories : per100Calories
                                Text(String(format: "%.0f", rightCalories))
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.secondary)
                                Text("kcal")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 2)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.adaptiveCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(palette.tertiary.opacity(0.3), lineWidth: 1.5)
                            )
                            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                    )
                }
                VStack(alignment: .leading, spacing: 16) {
                    Text("NUTRITION PER SERVING")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                        .padding(.horizontal, 4)
                    VStack(spacing: 8) {
                        row("Protein", adjustedProtein, per100Protein, "g")
                        row("Carbs", adjustedCarbs, per100Carbs, "g")
                        row("Fat", adjustedFat, per100Fat, "g")
                        row("Sat Fat", adjustedSatFat, per100SatFat, "g")
                        row("Fibre", adjustedFiber, per100Fiber, "g")
                        row("Sugar", adjustedSugar, per100Sugar, "g")
                        row("Salt", adjustedSalt, per100Salt, "g")
                    }
                    .padding(.bottom, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(palette.tertiary.opacity(0.15))
            .cornerRadius(16)
        }

        private func row(_ label: String, _ perServing: Double, _ per100: Double, _ unit: String) -> some View {
            HStack(spacing: 10) {
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 80, alignment: .leading)
                HStack(spacing: 4) {
                    Text(String(format: unit == "mg" ? "%.0f" : "%.1f", perServing))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.primary)
                    Text(unit)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Text("·")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                Spacer()
                Text(String(format: unit == "mg" ? "%.0f" : "%.1f", isPerUnit ? perServing : per100) + " \(unit)/" + (isPerUnit ? servingUnitLabel : "100g"))
                    .font(.system(size: 13, weight: .medium))
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color.adaptiveCard)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    struct IngredientsSectionView: View {
        @Environment(\.colorScheme) var colorScheme
        let status: IngredientsStatus?
        let ingredients: [String]?
        let userAllergens: [Allergen]
        let foodName: String
        @Binding var showingInferredIngredientsSheet: Bool
        let isEstimatingIngredients: Bool
        let onEstimateIngredients: () -> Void

        private var palette: AppPalette {
            AppPalette.forCurrentUser(colorScheme: colorScheme)
        }

        // Common additive/processed ingredient patterns to highlight
        private let concerningPatterns = [
            "e1", "e2", "e3", "e4", "e5", "e6", "e9",
            "modified", "hydrogenated", "maltodextrin", "dextrose",
            "high fructose", "artificial", "aspartame", "sucralose",
            "msg", "monosodium glutamate", "sodium nitrite", "sodium nitrate",
            "bha", "bht", "tbhq", "carrageenan", "polysorbate"
        ]

        // Check if ingredient matches any user allergen
        private func isAllergenIngredient(_ ingredient: String) -> Bool {
            let lowercased = ingredient.lowercased()
            for allergen in userAllergens {
                if allergen == .dairy {
                    // Use centralized dairy detection
                    if AllergenDetector.shared.containsDairyMilk(in: lowercased) {
                        return true
                    }
                } else {
                    for keyword in allergen.keywords {
                        if lowercased.contains(keyword.lowercased()) {
                            return true
                        }
                    }
                }
            }
            return false
        }

        private var processedIngredients: [(ingredient: String, isConcerning: Bool, isAllergen: Bool)] {
            guard let list = ingredients else { return [] }

            // Clean, deduplicate, and format ingredients
            var seen = Set<String>()
            return list
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .compactMap { ingredient -> (String, Bool, Bool)? in
                    let normalized = ingredient.lowercased()
                    if seen.contains(normalized) { return nil }
                    seen.insert(normalized)

                    // Format: capitalize first letter, check if concerning
                    let formatted = formatIngredient(ingredient)
                    let isConcerning = concerningPatterns.contains { normalized.contains($0) }
                    let isAllergen = isAllergenIngredient(ingredient)
                    return (formatted, isConcerning, isAllergen)
                }
        }

        private func formatIngredient(_ ingredient: String) -> String {
            var text = ingredient.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return text }

            // Capitalize first letter, lowercase rest (with exceptions)
            text = text.prefix(1).uppercased() + text.dropFirst().lowercased()

            // Re-capitalize E-numbers (e.g., e621 -> E621)
            let eNumberPattern = try? NSRegularExpression(pattern: "\\be(\\d+)", options: [])
            if let regex = eNumberPattern {
                let range = NSRange(text.startIndex..., in: text)
                text = regex.stringByReplacingMatches(in: text, range: range, withTemplate: "E$1")
            }

            // Re-capitalize vitamin letters (e.g., vitamin b12 -> vitamin B12)
            let vitaminPattern = try? NSRegularExpression(pattern: "vitamin\\s+([a-z])", options: [])
            if let regex = vitaminPattern {
                let range = NSRange(text.startIndex..., in: text)
                let matches = regex.matches(in: text, range: range)
                for match in matches.reversed() {
                    if let letterRange = Range(match.range(at: 1), in: text) {
                        text.replaceSubrange(letterRange, with: text[letterRange].uppercased())
                    }
                }
            }

            return text
        }

        private var concerningCount: Int {
            processedIngredients.filter { $0.isConcerning }.count
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(alignment: .center, spacing: 10) {
                    if status == .pending {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                            Text("Pending")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(SemanticColors.neutral)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(SemanticColors.neutral.opacity(0.12))
                        .clipShape(Capsule())
                    }

                    if status == .verified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 16))
                            .foregroundColor(SemanticColors.positive)
                    }

                    Text("Ingredients")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Spacer()
                }
                .padding(16)
                .background(colorScheme == .dark ? Color.midnightCard : Color.adaptiveCard)

                // Ingredients content
                if !processedIngredients.isEmpty {
                    // Use Text concatenation for natural text wrapping
                    FlowingIngredientsView(ingredients: processedIngredients, colorScheme: colorScheme, userAllergens: userAllergens)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .background(colorScheme == .dark ? Color.midnightCard : Color.adaptiveCard)

                    // Summary footer
                    if concerningCount > 0 {
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(SemanticColors.neutral)
                                Text("\(concerningCount) additive\(concerningCount == 1 ? "" : "s") to review")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(colorScheme == .dark ? Color.midnightCardSecondary.opacity(0.5) : palette.tertiary.opacity(0.15))
                    }
                } else if ingredients == nil {
                    VStack(alignment: .center, spacing: 8) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 24))
                        Text("Ingredients not available")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(colorScheme == .dark ? Color.midnightCard : Color.adaptiveCard)
                } else {
                    // No ingredients - offer AI estimation for generic foods
                    VStack(spacing: 12) {
                        Text("No ingredients found")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)

                        // AI Estimate Ingredients button
                        Button(action: {
                            onEstimateIngredients()
                        }) {
                            HStack(spacing: 8) {
                                if isEstimatingIngredients {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text(isEstimatingIngredients ? "Estimating..." : "Estimate Ingredients")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: isEstimatingIngredients ? [.gray, .gray] : [AppPalette.standard.accent, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                        }
                        .disabled(isEstimatingIngredients)

                        Text("Uses AI to estimate likely ingredients")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(colorScheme == .dark ? Color.midnightCard : Color.adaptiveCard)
                }
            }
            .background(colorScheme == .dark ? Color.midnightCard : Color.adaptiveCard)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(colorScheme == .dark ? palette.tertiary.opacity(0.2) : palette.tertiary.opacity(0.3), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Flowing Ingredients View (Text-based for proper wrapping)
    struct FlowingIngredientsView: View {
        let ingredients: [(ingredient: String, isConcerning: Bool, isAllergen: Bool)]
        let colorScheme: ColorScheme
        let userAllergens: [Allergen]

        // Patterns to highlight as additives (orange)
        private let additivePatterns = [
            "e1\\d+", "e2\\d+", "e3\\d+", "e4\\d+", "e5\\d+", "e6\\d+", "e9\\d+",  // E-numbers
            "modified", "hydrogenated", "maltodextrin", "dextrose",
            "high fructose", "artificial", "aspartame", "sucralose",
            "msg", "monosodium glutamate", "sodium nitrite", "sodium nitrate",
            "bha", "bht", "tbhq", "carrageenan", "polysorbate"
        ]

        var body: some View {
            // Build attributed text with proper wrapping
            let attributedIngredients = ingredients.enumerated().map { index, item -> Text in
                let suffix = index == ingredients.count - 1 ? "" : ", "

                // Build text with inline highlighting for additives/allergens only
                let highlightedText = buildHighlightedText(
                    ingredient: item.ingredient,
                    isConcerning: item.isConcerning,
                    isAllergen: item.isAllergen
                )

                return highlightedText + Text(suffix)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
            }

            return attributedIngredients.reduce(Text(""), +)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        /// Build text with only the matching additive/allergen keywords highlighted
        private func buildHighlightedText(ingredient: String, isConcerning: Bool, isAllergen: Bool) -> Text {
            // If not concerning or allergen, just return plain text
            if !isConcerning && !isAllergen {
                return Text(ingredient)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
            }

            let lowercased = ingredient.lowercased()
            var result = Text("")
            var processedRanges: [(Range<String.Index>, Color, Bool)] = [] // range, color, isBold

            // Find allergen matches first (red, higher priority)
            if isAllergen {
                let allergenKeywords = userAllergens.flatMap { $0.keywords }
                for keyword in allergenKeywords {
                    let keywordLower = keyword.lowercased()
                    var searchStart = lowercased.startIndex
                    while let range = lowercased.range(of: keywordLower, range: searchStart..<lowercased.endIndex) {
                        // Convert to original string range
                        let originalRange = ingredient.index(ingredient.startIndex, offsetBy: lowercased.distance(from: lowercased.startIndex, to: range.lowerBound))..<ingredient.index(ingredient.startIndex, offsetBy: lowercased.distance(from: lowercased.startIndex, to: range.upperBound))
                        processedRanges.append((originalRange, .red, true))
                        searchStart = range.upperBound
                    }
                }
            }

            // Find additive matches (orange)
            if isConcerning {
                for pattern in additivePatterns {
                    if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                        let nsRange = NSRange(lowercased.startIndex..., in: lowercased)
                        for match in regex.matches(in: lowercased, range: nsRange) {
                            if let range = Range(match.range, in: ingredient) {
                                // Don't add if already covered by an allergen match
                                let alreadyCovered = processedRanges.contains { existing in
                                    existing.0.overlaps(range)
                                }
                                if !alreadyCovered {
                                    processedRanges.append((range, .orange, false))
                                }
                            }
                        }
                    }
                }
            }

            // Sort ranges by start position
            processedRanges.sort { $0.0.lowerBound < $1.0.lowerBound }

            // Build the text with highlights
            var currentIndex = ingredient.startIndex
            for (range, color, isBold) in processedRanges {
                // Add unhighlighted text before this range
                if currentIndex < range.lowerBound {
                    let prefix = String(ingredient[currentIndex..<range.lowerBound])
                    result = result + Text(prefix)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                }

                // Add highlighted text
                let highlighted = String(ingredient[range])
                if isBold {
                    result = result + Text(highlighted)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(color)
                } else {
                    result = result + Text(highlighted)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(color)
                }

                currentIndex = range.upperBound
            }

            // Add any remaining text after the last highlight
            if currentIndex < ingredient.endIndex {
                let suffix = String(ingredient[currentIndex...])
                result = result + Text(suffix)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
            }

            // If no ranges were found but it was marked as concerning/allergen,
            // just show it normally (the pattern matching above should catch it)
            if processedRanges.isEmpty {
                return Text(ingredient)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
            }

            return result
        }
    }
    
    @ViewBuilder
    private var additiveWatchSection: some View {
        if let ingredientsList = cachedIngredients {
            let clean = ingredientsList
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if !clean.isEmpty {
                AdditiveWatchView(ingredients: ingredientsList)
            }
        }
    }
    
    private var allergensSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Allergen & Safety Information")
                .font(.system(size: 18, weight: .semibold))

            // Check if ingredients exist and contain meaningful data
            if let ingredients = food.ingredients {
                let clean = ingredients
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if !clean.isEmpty {
                // PERFORMANCE: Pre-sort allergens once, not on every ForEach iteration
                let detectedAllergens = detectAllergens(in: ingredients).sorted { $0.displayName < $1.displayName }
                let additiveAnalysis: AdditiveDetectionResult? = nil // Placeholder for now

                VStack(alignment: .leading, spacing: 12) {
                    // Show child warnings from additives first
                    if additiveAnalysis != nil {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(SemanticColors.neutral)
                                .font(.system(size: 14))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Child Activity Warning")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(SemanticColors.neutral)
                                Text("Contains additives that may affect activity and attention in children")
                                    .font(.system(size: 12))
                                    .foregroundColor(SemanticColors.neutral)
                                    .lineLimit(nil)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(SemanticColors.neutral.opacity(0.05))
                        .cornerRadius(8)
                    }

                    // Show allergen warnings (already pre-sorted above)
                    if !detectedAllergens.isEmpty {
                        ForEach(detectedAllergens, id: \.rawValue) { allergen in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(SemanticColors.caution)
                                Text("Contains \(allergen.displayName)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(SemanticColors.caution)
                                Spacer()
                            }
                        }
                    } else {
                        if additiveAnalysis?.hasChildConcernAdditives != true {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(SemanticColors.positive)
                                Text("No allergens or child-concern additives detected")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(SemanticColors.positive)
                                Spacer()
                            }
                        } else {
                            Text("No common allergens detected")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }

                    // Allergen disclaimer
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("Allergens may still be present if not shown. Ingredients may be outdated or incomplete. Always check the label if you have an allergy or intolerance.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 4)
                }
                }
            } else {
                // No ingredients available
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                        Text("No ingredient data available - unable to analyze additives and allergens")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                    }
                }
                .padding(12)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .background(palette.tertiary.opacity(0.15))
        .cornerRadius(12)
    }

    private func detectAllergens(in ingredients: [String]) -> [Allergen] {
        let combinedIngredients = ingredients.joined(separator: " ").lowercased()
        var detectedAllergens: [Allergen] = []

        // Use centralized keyword lists from Allergen.keywords
        for allergen in [Allergen.dairy, .eggs, .fish, .shellfish, .treeNuts, .peanuts, .wheat, .gluten, .soy, .sesame] {
            if allergen == .dairy {
                // Use refined dairy detection (handles plant milks correctly)
                if AllergenDetector.shared.containsDairyMilk(in: combinedIngredients) {
                    detectedAllergens.append(allergen)
                }
            } else if allergen.keywords.contains(where: { combinedIngredients.contains($0) }) {
                detectedAllergens.append(allergen)
            }
        }

        return detectedAllergens
    }
    
    
    private var ingredientVerificationSection: some View {
        VStack(alignment: .center, spacing: 16) {
            VStack(alignment: .center, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(SemanticColors.neutral)

                Text("Something not looking right?")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Notify our team to review this product and add more accurate nutritional data.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    // Notify Team Button
                    Button(action: {
                        notifyTeamAboutIncompleteFood()
                    }) {
                        HStack(spacing: 6) {
                            if isNotifyingTeam {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 16))
                                Text("Notify Team")
                                    .font(.system(size: 14, weight: .semibold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isNotifyingTeam ? palette.tertiary : SemanticColors.neutral)
                        .cornerRadius(10)
                    }
                    .disabled(isNotifyingTeam)
                }
            }
            .padding(16)
            .background(SemanticColors.neutral.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(SemanticColors.neutral.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var ingredientInReviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(SemanticColors.positive)
                    Text("Ingredients Submitted for Review")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Text("Thank you! We've received your ingredient photo and it's currently being reviewed by our team. Once approved, this food will have an accurate nutrition score based on the actual ingredients.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
            
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppPalette.standard.accent)
                Text("Review typically takes 24-48 hours")
                    .font(.system(size: 14))
                    .foregroundColor(AppPalette.standard.accent)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(AppPalette.standard.accent.opacity(0.05))
            .cornerRadius(8)
        }
        .padding(.horizontal, 16)
        .background(.green.opacity(0.05))
        .cornerRadius(12)
    }
    
    // Notify team about incomplete food information
    private func notifyTeamAboutIncompleteFood() {
        isNotifyingTeam = true

        Task {
            do {
                // Send complete food object to FirebaseManager
                // This will save to Firestore and send email to contact@nutrasafe.co.uk
                try await firebaseManager.notifyIncompleteFood(food: food)

                await MainActor.run {
                    isNotifyingTeam = false
                    showingNotificationSuccess = true
                }

            } catch {
                await MainActor.run {
                    isNotifyingTeam = false
                    notificationErrorMessage = "Unable to send notification. Please try again later."
                    showingNotificationError = true
                }
            }
        }
    }

    // Estimate ingredients using AI and flag for review
    private func estimateIngredientsWithAI() {
        isEstimatingIngredients = true

        Task {
            do {
                // 1. Call AI inference to get estimated ingredients
                let analysis = try await InferredIngredientManager.shared.inferIngredients(for: food.name)
                let estimatedIngredients = analysis.allInferredIngredients

                // 2. Convert to ingredient names string
                let ingredientNames = estimatedIngredients.map { $0.name }
                let ingredientsText = ingredientNames.joined(separator: ", ")

                // 3. Update the UI to show estimated ingredients
                await MainActor.run {
                    inferredIngredients = estimatedIngredients
                    enhancedIngredientsText = ingredientsText
                }

                // 4. Flag for review with estimated ingredients
                try await notifyTeamWithEstimatedIngredients(ingredientNames)

                await MainActor.run {
                    isEstimatingIngredients = false
                    // Show success feedback briefly
                    showingNotificationSuccess = true
                }

            } catch {
                await MainActor.run {
                    isEstimatingIngredients = false
                    // Silently fail or show error
                    notificationErrorMessage = "Unable to estimate ingredients. Please try again."
                    showingNotificationError = true
                }
            }
        }
    }

    // Notify team with AI-estimated ingredients for review
    private func notifyTeamWithEstimatedIngredients(_ estimatedIngredients: [String]) async throws {
        guard let url = URL(string: "https://us-central1-nutrasafe-705c7.cloudfunctions.net/notifyIncompleteFood") else {
            throw NSError(domain: "Invalid URL", code: -1)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build food data with estimated ingredients
        var foodData: [String: Any] = [
            "id": food.id,
            "name": food.name,
            "calories": food.calories,
            "protein": food.protein,
            "carbs": food.carbs,
            "fat": food.fat,
            "fiber": food.fiber,
            "sugar": food.sugar,
            "sodium": food.sodium,
            "isVerified": food.isVerified,
            "ingredients": estimatedIngredients,
            "processingLabel": "AI-Estimated Ingredients (Pending Review)"
        ]

        // Add optional fields if present
        if let brand = food.brand { foodData["brand"] = brand }
        if let barcode = food.barcode { foodData["barcode"] = barcode }
        if let servingDescription = food.servingDescription { foodData["servingDescription"] = servingDescription }
        if let servingSizeG = food.servingSizeG { foodData["servingSizeG"] = servingSizeG }

        let requestBody: [String: Any] = [
            "data": [
                "foodName": food.name,
                "brandName": food.brand ?? "",
                "foodId": food.id,
                "barcode": food.barcode ?? "",
                "userId": firebaseManager.currentUser?.uid ?? "anonymous",
                "userEmail": firebaseManager.currentUser?.email ?? "anonymous",
                "recipientEmail": "contact@nutrasafe.co.uk",
                "fullFoodData": foodData,
                "estimatedIngredients": estimatedIngredients,
                "isAIEstimated": true
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "Failed to notify team", code: -1)
        }
    }

    // Enhance food data using barcode scan
    private func enhanceWithBarcode(_ barcode: String) {
        isEnhancing = true
        Task {
            do {
                // Call the AI ingredient finder service with barcode
                let result = try await IngredientFinderService.shared.findIngredients(
                    productName: food.name,
                    brand: food.brand,
                    barcode: barcode
                )

                                if result.ingredients_found {
                    var enhancedData: [String: Any] = [:]

                    if let ingredientsText = result.ingredients_text {
                        enhancedData["ingredientsText"] = ingredientsText
                    }

                    if let nutrition = result.nutrition_per_100g {
                        enhancedData["calories"] = nutrition.calories ?? 0
                        enhancedData["protein"] = nutrition.protein ?? 0
                        enhancedData["carbs"] = nutrition.carbs ?? 0
                        enhancedData["fat"] = nutrition.fat ?? 0
                        enhancedData["fiber"] = nutrition.fiber ?? 0
                        enhancedData["sugar"] = nutrition.sugar ?? 0
                        enhancedData["salt"] = nutrition.salt ?? 0
                    }

                    if let productName = result.product_name {
                        enhancedData["productName"] = productName
                    }

                    if let brand = result.brand {
                        enhancedData["brand"] = brand
                    }

                    if let servingSizeG = result.serving_size_g {
                        enhancedData["servingSizeG"] = servingSizeG
                    }

                    if let sourceUrl = result.source_url {
                        enhancedData["sourceUrl"] = sourceUrl
                    }

                    // Save to Firebase
                    do {
                        _ = try await firebaseManager.saveAIImprovedFood(
                            originalFood: food,
                            enhancedData: enhancedData
                        )
                    } catch {
                        // Silently handle save errors
                    }
                }

                await MainActor.run {
                    isEnhancing = false

                    if result.ingredients_found {
                        // Store enhanced ingredients
                        if let ingredientsText = result.ingredients_text {
                                                        enhancedIngredientsText = ingredientsText
                        } else {
                                                    }

                        // Store enhanced nutrition data
                        if let nutrition = result.nutrition_per_100g {
                                                        enhancedNutrition = nutrition
                        } else {
                                                    }

                        // Store enhanced product details
                        enhancedProductName = result.product_name
                        enhancedBrand = result.brand
                                                if let servingSizeGrams = result.serving_size_g {
                            // Validate that serving size is reasonable (not product size)
                            if servingSizeGrams > 0 && servingSizeGrams <= 500 {
                                servingAmount = String(format: "%.0f", servingSizeGrams)
                                servingUnit = "g"
                                gramsAmount = String(format: "%.0f", servingSizeGrams)
                                                            } else {
                                // Unreasonable serving size, default to 100g
                                servingAmount = "100"
                                servingUnit = "g"
                                gramsAmount = "100"
                                                            }
                        } else {
                            // No serving size from AI, keep existing or default to 100g
                                                    }

                        // Trigger UI refresh
                        refreshTrigger = UUID()

                                                showingEnhancementSuccess = true
                    } else {
                                                enhancementErrorMessage = "Could not find enhanced ingredient information. The product might not be in our UK supermarket database."
                        showingEnhancementError = true
                    }
                }

            } catch {
                                await MainActor.run {
                    isEnhancing = false
                    enhancementErrorMessage = "Unable to enhance with AI. Please try again later."
                    showingEnhancementError = true
                }
            }
        }
    }

    // Enhance food data using manual search
    private func enhanceWithManualSearch(_ searchTerm: String) {
        isEnhancing = true
                Task {
            do {
                // Call the AI ingredient finder service with custom search term
                let result = try await IngredientFinderService.shared.findIngredients(
                    productName: searchTerm,
                    brand: nil, // User provides the full search term
                    barcode: nil
                )

                                if result.ingredients_found {
                                        var enhancedData: [String: Any] = [:]

                    if let ingredientsText = result.ingredients_text {
                        enhancedData["ingredientsText"] = ingredientsText
                    }

                    if let nutrition = result.nutrition_per_100g {
                        enhancedData["calories"] = nutrition.calories ?? 0
                        enhancedData["protein"] = nutrition.protein ?? 0
                        enhancedData["carbs"] = nutrition.carbs ?? 0
                        enhancedData["fat"] = nutrition.fat ?? 0
                        enhancedData["fiber"] = nutrition.fiber ?? 0
                        enhancedData["sugar"] = nutrition.sugar ?? 0
                        enhancedData["salt"] = nutrition.salt ?? 0
                    }

                    if let productName = result.product_name {
                        enhancedData["productName"] = productName
                    }

                    if let brand = result.brand {
                        enhancedData["brand"] = brand
                    }

                    if let servingSizeG = result.serving_size_g {
                        enhancedData["servingSizeG"] = servingSizeG
                    }

                    if let sourceUrl = result.source_url {
                        enhancedData["sourceUrl"] = sourceUrl
                    }

                    // Save to Firebase
                    do {
                        _ = try await firebaseManager.saveAIImprovedFood(
                            originalFood: food,
                            enhancedData: enhancedData
                        )
                    } catch {
                        // Silently handle save errors
                    }
                }

                await MainActor.run {
                    isEnhancing = false

                    if result.ingredients_found {
                        // Store enhanced ingredients
                        if let ingredientsText = result.ingredients_text {
                                                        enhancedIngredientsText = ingredientsText
                        }

                        // Store enhanced nutrition data
                        if let nutrition = result.nutrition_per_100g {
                                                        enhancedNutrition = nutrition
                        }

                        // Store enhanced product details
                        enhancedProductName = result.product_name
                        enhancedBrand = result.brand

                        // Trigger UI refresh
                        refreshTrigger = UUID()

                                                showingEnhancementSuccess = true
                    } else {
                                                enhancementErrorMessage = "Could not find product with this search term. Try different keywords."
                        showingEnhancementError = true
                    }
                }

            } catch {
                                await MainActor.run {
                    isEnhancing = false
                    enhancementErrorMessage = "Unable to search. Please try again later."
                    showingEnhancementError = true
                }
            }
        }
    }

    private func submitCompleteFoodProfile(ingredientsImage: UIImage?, nutritionImage: UIImage?, barcodeImage: UIImage?) {
        isSubmittingCompleteProfile = true
        
        Task {
            do {
                var requestBody: [String: Any] = [
                    "foodName": food.name,
                    "brandName": food.brand ?? "",
                    "nutritionData": [
                        "calories": displayFood.calories,
                        "protein": displayFood.protein,
                        "carbs": displayFood.carbs,
                        "fat": displayFood.fat,
                        "fiber": displayFood.fiber,
                        "sugar": displayFood.sugar,
                        "sodium": displayFood.sodium
                    ]
                ]
                
                // Add ingredient image if available
                if let ingredientsImage = ingredientsImage,
                   let imageData = ingredientsImage.jpegData(compressionQuality: 0.8) {
                    requestBody["ingredientsImageData"] = imageData.base64EncodedString()
                }
                
                // Add nutrition image if available
                if let nutritionImage = nutritionImage,
                   let imageData = nutritionImage.jpegData(compressionQuality: 0.8) {
                    requestBody["nutritionImageData"] = imageData.base64EncodedString()
                }
                
                // Add barcode image if available
                if let barcodeImage = barcodeImage,
                   let imageData = barcodeImage.jpegData(compressionQuality: 0.8) {
                    requestBody["barcodeImageData"] = imageData.base64EncodedString()
                }
                
                // Submit to Firebase function for complete processing
                let urlString = "https://us-central1-nutrasafe-705c7.cloudfunctions.net/processCompleteFoodProfile"
                guard let url = URL(string: urlString) else {
                                        throw NSError(domain: "FoodDetailView", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid processing URL"])
                }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    // Parse the response to get extracted ingredients
                    var extractedIngredients: [String] = []
                    if let responseJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        if let ingredientsText = responseJson["extractedIngredients"] as? String,
                           !ingredientsText.isEmpty {
                            // Split ingredients by common separators and clean them up
                            extractedIngredients = ingredientsText.split(separator: ",")
                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                .filter { !$0.isEmpty }
                        }
                    }
                    
                    await MainActor.run {
                        // Add food to submitted foods list
                        let foodKey = "\(food.name)|\(food.brand ?? "")"
                        var submittedFoods = UserDefaults.standard.array(forKey: "submittedFoodsForReview") as? [String] ?? []
                        if !submittedFoods.contains(foodKey) {
                            submittedFoods.append(foodKey)
                            UserDefaults.standard.set(submittedFoods, forKey: "submittedFoodsForReview")
                        }
                        
                        // Store extracted ingredients locally for immediate display
                        if !extractedIngredients.isEmpty {
                            do {
                                let ingredientsData = try JSONEncoder().encode(extractedIngredients)
                                UserDefaults.standard.set(ingredientsData, forKey: "submittedIngredients_\(foodKey)")
                            } catch {
                                                            }
                        }
                        
                        isSubmittingCompleteProfile = false
                        // Show success and dismiss
                        dismiss()
                    }
                } else {
                    throw URLError(.badServerResponse)
                }
                
            } catch {
                                await MainActor.run {
                    isSubmittingCompleteProfile = false
                }
            }
        }
    }
    
    // Extract ingredients using intelligent Gemini AI and update app immediately
    private func extractAndAnalyzeIngredients(from image: UIImage, for food: FoodSearchResult) async {
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                        return
        }
        
        let base64String = imageData.base64EncodedString()
        
        // Call our intelligent extraction Firebase function via URLSession
        guard let url = URL(string: "https://us-central1-nutrasafe-705c7.cloudfunctions.net/extractIngredientsWithAI") else {
                        return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestData: [String: Any] = [
            "data": [
                "imageBase64": base64String,
                "foodName": food.name,
                "brandName": food.brand ?? ""
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let resultData = json["result"] as? [String: Any],
               let success = resultData["success"] as? Bool,
               success,
               let cleanIngredientsText = resultData["cleanIngredientsText"] as? String,
               let extractedIngredients = resultData["extractedIngredients"] as? [String],
               let detectedAllergens = resultData["detectedAllergens"] as? [String] {
                
                // Update UI on main thread
                await MainActor.run {
                    // Store user-verified ingredients locally
                    let foodKey = "\(food.name)|\(food.brand ?? "")"
                    UserDefaults.standard.set(cleanIngredientsText, forKey: "userIngredients_\(foodKey)")
                    UserDefaults.standard.set(extractedIngredients, forKey: "userIngredientsArray_\(foodKey)")
                    UserDefaults.standard.set(detectedAllergens, forKey: "userDetectedAllergens_\(foodKey)")
                    
                                        Task {
                        await recalculateNutritionScore(with: extractedIngredients)
                    }
                }
            }
            
        } catch {
                        await fallbackVisionExtraction(from: image, for: food)
        }
    }
    
    // Fallback Vision OCR method (simplified version)
    private func fallbackVisionExtraction(from image: UIImage, for food: FoodSearchResult) async {
                guard let cgImage = image.cgImage else { return }
        
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil else { return }
            
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let extractedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: " ")
            
            DispatchQueue.main.async {
                if !extractedText.isEmpty {
                    let foodKey = "\(food.name)|\(food.brand ?? "")"
                    UserDefaults.standard.set(extractedText, forKey: "userIngredients_\(foodKey)")
                                    }
            }
        }
        
        request.recognitionLevel = VNRequestTextRecognitionLevel.accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
    
    // Recalculate nutrition score with new user-verified ingredients
    private func recalculateNutritionScore(with ingredients: [String]) async {

        // PERFORMANCE: Invalidate caches and reset initialization flag to allow re-initialization
        await MainActor.run {
            cachedIngredients = nil
            cachedIngredientsStatus = nil
            cachedAdditives = nil
            cachedNutritionScore = nil
            cachedNutraSafeGrade = nil
            hasInitialized = false
        }

        // The nutrition score will automatically recalculate since the nutritionScore
        // computed property now prioritizes user-verified ingredients
                await MainActor.run {
            refreshTrigger = UUID()
        }
    }
    
    // MARK: - Helper Views for Serving Controls

    @ViewBuilder
    private func multiplierButton(isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(isActive ? multiplierText(quantityMultiplier) : "1x")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isActive ? .accentColor : .secondary)
                .frame(width: 36, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isActive ? Color.accentColor.opacity(0.5) : palette.tertiary.opacity(0.3), lineWidth: 1)
                        .background(RoundedRectangle(cornerRadius: 6).fill(isActive ? Color.accentColor.opacity(0.08) : palette.tertiary.opacity(0.15)))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func selectionIndicator(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(isSelected ? Color.accentColor : palette.tertiary.opacity(0.3), lineWidth: 1.5)
                .frame(width: 22, height: 22)
            if isSelected {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 22, height: 22)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 22)
    }

    @ViewBuilder
    private func nutritionValues(calories: Double, protein: Double, carbs: Double) -> some View {
        HStack(spacing: 10) {
            Text("\(Int(calories))")
                .frame(width: 38, alignment: .trailing)
            Text(String(format: "%.1f", protein))
                .frame(width: 34, alignment: .trailing)
            Text(String(format: "%.1f", carbs))
                .frame(width: 34, alignment: .trailing)
        }
        .font(.system(size: 13))
        .foregroundColor(.secondary)
    }

    private var perUnitServingRow: some View {
        let isSelected = selectedPortionName != "__custom__"
        let mult = isSelected ? quantityMultiplier : 1.0
        return Button {
            selectedPortionName = servingUnit
        } label: {
            HStack(spacing: 6) {
                // 1x button - left edge
                multiplierButton(isActive: isSelected) {
                    if isSelected {
                        showingMultiplierPicker = true
                    } else {
                        selectedPortionName = servingUnit
                    }
                }

                // Serving name - allow wrapping for long names
                Text(servingUnit.capitalized)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Nutrition block - matches header widths exactly
                HStack(spacing: 0) {
                    Text("\(Int(food.calories * mult))")
                        .frame(width: 38, alignment: .trailing)
                    Text(String(format: "%.0f", food.protein * mult))
                        .frame(width: 32, alignment: .trailing)
                    Text(String(format: "%.0f", food.carbs * mult))
                        .frame(width: 34, alignment: .trailing)
                    Text(String(format: "%.0f", food.fat * mult))
                        .frame(width: 28, alignment: .trailing)
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary)

                // Checkbox - right edge
                selectionIndicator(isSelected: isSelected)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .frame(minHeight: 48)
            .background(isSelected ? Color.accentColor.opacity(0.06) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Serving Controls Section
    private var servingControlsSection: some View {
        // Pre-compute colors to help Swift type-checker
        let tertiaryBg = palette.tertiary.opacity(0.15)
        let tertiaryBgLight = palette.tertiary.opacity(0.2)

        return VStack(spacing: 16) {
            // MARK: - Serving Sizes Section (shown for ALL foods)
            VStack(spacing: 0) {
                // Header row - aligned with content rows
                HStack(spacing: 6) {
                    Text("SERVING SIZES")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                    Spacer()
                    if !isPerUnit {
                        // Nutrition headers - exact same structure as content
                        HStack(spacing: 0) {
                            Text("KCAL")
                                .frame(width: 38, alignment: .trailing)
                            Text("PROT")
                                .frame(width: 32, alignment: .trailing)
                            Text("CARB")
                                .frame(width: 34, alignment: .trailing)
                            Text("FAT")
                                .frame(width: 28, alignment: .trailing)
                        }
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                        // Checkbox column space (22 width + 6 spacing from parent HStack accounted for)
                        Spacer().frame(width: 22)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 6)

                // Per-unit foods: show single row with unit name
                if isPerUnit {
                    perUnitServingRow
                } else {
                    // Per-100g foods: show preset portions if available
                    // Use query-aware method to properly handle composite dishes and ambiguous items
                    // This prevents "salmon en croute" from getting "small fillet" suggestions
                    let effectiveQuery = food.name // Use food name as query for classification
                    if food.hasAnyPortionOptions(forQuery: effectiveQuery) {
                        let portions = food.portionsForQuery(effectiveQuery)
                        ForEach(portions) { portion in
                            let isSelected = selectedPortionName == portion.name
                            let multiplier = portion.serving_g / 100.0
                            let rowMult = isSelected ? quantityMultiplier : 1.0
                            let portionCalories = food.calories * multiplier * rowMult
                            let portionProtein = food.protein * multiplier * rowMult
                            let portionCarbs = food.carbs * multiplier * rowMult
                            let portionFat = food.fat * multiplier * rowMult

                            Button {
                                selectedPortionName = portion.name
                                servingAmount = String(format: "%.0f", portion.serving_g)
                                servingUnit = food.isLiquidCategory ? "ml" : "g"
                            } label: {
                                HStack(spacing: 6) {
                                    // 1x button - left edge
                                    Button {
                                        if isSelected {
                                            showingMultiplierPicker = true
                                        } else {
                                            selectedPortionName = portion.name
                                            servingAmount = String(format: "%.0f", portion.serving_g)
                                        }
                                    } label: {
                                        Text(isSelected ? multiplierText(quantityMultiplier) : "1x")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(isSelected ? .accentColor : .secondary)
                                            .frame(width: 36, height: 28)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(isSelected ? Color.accentColor.opacity(0.5) : palette.tertiary.opacity(0.3), lineWidth: 1)
                                                    .background(RoundedRectangle(cornerRadius: 6).fill(isSelected ? Color.accentColor.opacity(0.08) : tertiaryBg))
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    // Serving name - allow wrapping for long names
                                    Text(portion.name)
                                        .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                                        .foregroundColor(.primary)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.85)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    // Nutrition block - matches header widths exactly
                                    HStack(spacing: 0) {
                                        Text("\(Int(portionCalories))")
                                            .frame(width: 38, alignment: .trailing)
                                        Text(String(format: "%.0f", portionProtein))
                                            .frame(width: 32, alignment: .trailing)
                                        Text(String(format: "%.0f", portionCarbs))
                                            .frame(width: 34, alignment: .trailing)
                                        Text(String(format: "%.0f", portionFat))
                                            .frame(width: 28, alignment: .trailing)
                                    }
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)

                                    // Checkbox - right edge
                                    ZStack {
                                        Circle()
                                            .stroke(isSelected ? Color.accentColor : palette.tertiary.opacity(0.3), lineWidth: 1.5)
                                            .frame(width: 22, height: 22)
                                        if isSelected {
                                            Circle()
                                                .fill(Color.accentColor)
                                                .frame(width: 22, height: 22)
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 8)
                                .frame(minHeight: 48)
                                .background(isSelected ? Color.accentColor.opacity(0.06) : Color.clear)
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    // Custom weight row - INDEPENDENT (values based on typed weight only)
                    let isCustomSelected = selectedPortionName == "__custom__" || !food.hasAnyPortionOptions(forQuery: effectiveQuery)
                    let customMultiplier = (Double(servingAmount) ?? 100) / 100.0
                    HStack(spacing: 6) {
                        // 1x label - left edge
                        Text("1x")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 36, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(palette.tertiary.opacity(0.3), lineWidth: 1)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(tertiaryBg))
                            )

                        // Weight input fields - flexible
                        HStack(spacing: 4) {
                            TextField("100", text: $servingAmount)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 13, weight: .medium))
                                .frame(width: 44)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 5)
                                .background(Color.white)
                                .cornerRadius(6)
                                .onTapGesture {
                                    selectedPortionName = "__custom__"
                                }

                            Menu {
                                ForEach(servingUnitOptions, id: \.self) { unit in
                                    Button(unit) {
                                        servingUnit = unit
                                        selectedPortionName = "__custom__"
                                    }
                                }
                            } label: {
                                HStack(spacing: 2) {
                                    Text(servingUnit)
                                        .font(.system(size: 12, weight: .medium))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 7, weight: .semibold))
                                }
                                .foregroundColor(.primary)
                                .frame(minWidth: 40, maxWidth: 80, alignment: .leading)
                                .frame(height: 28)
                                .padding(.horizontal, 6)
                                .background(Color.white)
                                .cornerRadius(6)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Nutrition block - matches header widths exactly
                        HStack(spacing: 0) {
                            Text("\(Int(food.calories * customMultiplier))")
                                .frame(width: 38, alignment: .trailing)
                            Text(String(format: "%.0f", food.protein * customMultiplier))
                                .frame(width: 32, alignment: .trailing)
                            Text(String(format: "%.0f", food.carbs * customMultiplier))
                                .frame(width: 34, alignment: .trailing)
                            Text(String(format: "%.0f", food.fat * customMultiplier))
                                .frame(width: 28, alignment: .trailing)
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                        // Checkbox - right edge
                        ZStack {
                            Circle()
                                .stroke(isCustomSelected ? Color.accentColor : palette.tertiary.opacity(0.3), lineWidth: 1.5)
                                .frame(width: 22, height: 22)
                            if isCustomSelected {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 22, height: 22)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 8)
                    .frame(height: 48)
                    .background(isCustomSelected ? Color.accentColor.opacity(0.06) : Color.clear)
                    .cornerRadius(8)
                    .onTapGesture {
                        selectedPortionName = "__custom__"
                    }
                }
            }

            if sourceType != .useBy {
                VStack(spacing: 8) {
                    Text("MEAL TIME")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                        .frame(maxWidth: .infinity, alignment: .center)
                    HStack(spacing: 8) {
                        ForEach(mealOptions, id: \.self) { meal in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedMeal = meal
                                }
                            }) {
                                Text(meal)
                                    .font(.system(size: 13, weight: selectedMeal == meal ? .semibold : .medium))
                                    .foregroundColor(selectedMeal == meal ? .white : .primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16).fill(selectedMeal == meal ? AppPalette.standard.accent : palette.tertiary.opacity(0.15))
                                    )
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            // MARK: - Add to Diary Buttons (with optional fasting integration)
            if shouldShowStartFastOption {
                // User has fasting plan and is in eating window - show both options stacked
                VStack(spacing: 10) {
                    // Standard add button
                    Button(action: { addToFoodLog() }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text(buttonText)
                                .font(.headline.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.green)
                        .cornerRadius(12)
                    }

                    // Log Last Meal & Start Fast button
                    Button(action: { addToFoodLogAndStartFast() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "timer")
                            Text("Log Last Meal & Start Fast")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.orange, .red.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
                .padding(.top, 8)
            } else {
                // Standard single button
                Button(action: { addToFoodLog() }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(buttonText).font(.headline.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(.green)
                    .cornerRadius(12)
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(tertiaryBg))
        .overlay(
            // Multiplier picker popup overlay
            Group {
                if showingMultiplierPicker {
                    ZStack {
                        // Dimmed background
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showingMultiplierPicker = false
                            }

                        // Popup grid
                        VStack(spacing: 12) {
                            // Grid of multiplier buttons (4 columns x 3 rows like screenshot)
                            let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(quantityMultiplierOptions, id: \.self) { mult in
                                    let isCurrentValue = {
                                        let multValue = Double(mult.replacingOccurrences(of: "x", with: "").replacingOccurrences(of: "½", with: "0.5").replacingOccurrences(of: "¼", with: "0.25").replacingOccurrences(of: "¾", with: "0.75")) ?? 1.0
                                        return abs(quantityMultiplier - multValue) < 0.01
                                    }()
                                    Button {
                                        quantityMultiplier = Double(mult.replacingOccurrences(of: "x", with: "").replacingOccurrences(of: "½", with: "0.5").replacingOccurrences(of: "¼", with: "0.25").replacingOccurrences(of: "¾", with: "0.75")) ?? 1.0
                                        showingMultiplierPicker = false
                                    } label: {
                                        Text(mult)
                                            .font(.system(size: 17, weight: .medium))
                                            .foregroundColor(isCurrentValue ? .white : .primary)
                                            .frame(width: 52, height: 44)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(isCurrentValue ? Color.accentColor : tertiaryBgLight)
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }

                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.adaptiveCard)
                                .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
                        )
                        .padding(.horizontal, 32)
                    }
                }
            }
        )
    }

    // MARK: - Fast Food Brand Detection

    /// Check if the current food is from a recognised fast food/processed food brand
    /// Uses shared brand detection from AlgoliaSearchManager for consistency
    private var isFastFoodBrand: Bool {
        return isProcessedFoodBrand(
            brand: displayFood.brand,
            name: displayFood.name
        )
    }

    // MARK: - Food Scores Section
    private var foodScoresSection: some View {
        // Only show NutraSafe grade if ingredients exist and contain meaningful data
        let hasIngredients: Bool = {
            guard let ingredients = cachedIngredients else { return false }
            let clean = ingredients
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return !clean.isEmpty
        }()

        // Hide NutraSafe Processing Grade when user has selected per-unit mode
        // Per-unit nutrition is for individual items (candy, burger, etc.) where overall processing grade isn't meaningful
        let isPerUnitMode = displayFood.isPerUnit == true

        // Hide NutraSafe Processing Grade for fast food items - these are inherently ultra-processed
        // and showing a grade could be misleading
        let isFastFood = isFastFoodBrand

        // Show grade only if has ingredients AND not in per-unit mode AND not fast food
        let gradeToShow = (hasIngredients && !isPerUnitMode && !isFastFood) ? nutraSafeGrade : nil

        return FoodScoresSectionView(ns: gradeToShow, sugarScore: sugarScore, showingInfo: $showingNutraSafeInfo, showingSugarInfo: $showingSugarInfo)
    }
    
    private func getSimplifiedProcessingLevel() -> String {
        switch nutritionScore.grade {
        case .aPlus, .a:
            return "Natural"
        case .b:
            return "Mildly Processed"
        case .c, .d:
            return "Processed"
        case .f:
            return "Ultra Processed"
        case .unknown:
            return "Unknown"
        }
    }
    
    private func getSugarLevelDescription() -> String {
        // Use the smart explanation that considers both density and serving size
        if let servingGrade = sugarScore.servingGrade, servingGrade.numericValue < sugarScore.densityGrade.numericValue {
            // Large serving is the issue
            return "⚠️ High Per Serving"
        }

        // Use standard descriptions based on grade
        switch sugarScore.grade {
        case .excellent, .veryGood:
            return "Low Sugar"
        case .good:
            return "Moderate Sugar"
        case .moderate:
            return "High Sugar"
        case .high, .veryHigh:
            return "Very High Sugar"
        case .unknown:
            return "Unknown"
        }
    }
    
    private func getNutraSafeColor(_ grade: String) -> Color {
        switch grade.uppercased() {
        case "A", "A+":
            return .green
        case "B":
            return .mint
        case "C":
            return .orange
        case "D", "E", "F":
            return .red
        default:
            return .gray
        }
    }

    struct FoodScoresSectionView: View {
        let ns: ProcessingScorer.NutraSafeProcessingGradeResult?
        let sugarScore: SugarContentScore?
        @Binding var showingInfo: Bool
        @Binding var showingSugarInfo: Bool
        @Environment(\.colorScheme) private var colorScheme

        private var palette: AppPalette {
            AppPalette.forCurrentUser(colorScheme: colorScheme)
        }

        // Onboarding-style soft colors for grades
        private func gradeColor(for grade: String) -> Color {
            switch grade {
            case "A+", "A": return SemanticColors.positive
            case "B": return SemanticColors.nutrient
            case "C", "D": return SemanticColors.neutral
            case "F": return SemanticColors.caution
            default: return Color.secondary
            }
        }

        private func sugarDescription(for grade: SugarGrade) -> String {
            switch grade {
            case .excellent, .veryGood: return "Low Sugar"
            case .good: return "Moderate Sugar"
            case .moderate: return "High Sugar"
            case .high, .veryHigh: return "Very High Sugar"
            case .unknown: return "Unknown"
            }
        }

        var body: some View {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    if let ns = ns {
                        // Onboarding-style grade card - calm and informational
                        Button(action: { showingInfo = true }) {
                            VStack(spacing: 8) {
                                Text("PROCESSING")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .tracking(0.5)

                                Text(ns.grade)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(gradeColor(for: ns.grade))

                                Text(ns.label)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)

                                Text("Tap to learn more")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(gradeColor(for: ns.grade).opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(gradeColor(for: ns.grade).opacity(0.15), lineWidth: 1)
                                )
                        )
                    }

                    if let s = sugarScore, s.grade != .unknown {
                        // Onboarding-style sugar card - calm and informational
                        Button(action: { showingSugarInfo = true }) {
                            VStack(spacing: 8) {
                                Text("SUGAR")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .tracking(0.5)

                                Text(s.grade.rawValue)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(s.color)

                                Text(sugarDescription(for: s.grade))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)

                                Text("Tap to learn more")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(s.color.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(s.color.opacity(0.15), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contentShape(Rectangle())
                    }
                }

                // Onboarding-style info card for explanation
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(palette.accent)

                    Text("A = closest to natural, F = heavily processed. Based on ingredients, additives, and nutritional balance.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(palette.accent.opacity(0.06))
                )
            }
        }
    }
    
    
    // MARK: - Combined Watch Tabs Section
    private var watchTabsSection: some View {
        VStack(spacing: 0) {
            // Onboarding-style tab selector - simpler, calmer design
            HStack(spacing: 0) {
                ForEach(WatchTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedWatchTab = tab
                        }
                    }) {
                        HStack(spacing: 8) {
                            // Smaller icon in colored circle
                            ZStack {
                                Circle()
                                    .fill(selectedWatchTab == tab ? tab.color : palette.tertiary.opacity(0.15))
                                    .frame(width: 32, height: 32)

                                Image(systemName: tab.icon)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(selectedWatchTab == tab ? .white : .secondary)
                            }

                            Text(tab.rawValue.replacingOccurrences(of: " & ", with: "\n& "))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(selectedWatchTab == tab ? .primary : .secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedWatchTab == tab ? tab.color.opacity(0.08) : Color.clear)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(Color.adaptiveCard)

            Divider()
                .padding(.horizontal, 16)

            // Tab Content - Wrapped in ScrollView to prevent overflow
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        switch selectedWatchTab {
                        case .additives:
                            additivesContent
                        case .allergies:
                            allergensContent
                        case .vitamins:
                            vitaminsContent(scrollProxy: proxy)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
                .frame(maxHeight: 400) // Limit height to prevent tab overlap
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.adaptiveCard)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
    
    // MARK: - Additive Analysis Content
    private var additivesContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if subscriptionManager.hasAccess {
                // Premium users see full additive analysis
                if let ingredientsList = cachedIngredients, !ingredientsList.isEmpty {
                    AdditiveWatchView(ingredients: ingredientsList)
                } else {
                    noIngredientDataView
                }
            } else {
                // Free users see locked preview
                additivesLockedView
            }
        }
        .padding(16)
    }

    private var noIngredientDataView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))
                Text("No ingredient data available - unable to analyse additives and allergens")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
        }
        .padding(12)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }

    private var additivesLockedView: some View {
        ZStack {
            // Blurred placeholder
            VStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(palette.tertiary.opacity(0.2))
                            .frame(width: 50, height: 24)
                        VStack(alignment: .leading, spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(palette.tertiary.opacity(0.15))
                                .frame(height: 14)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(palette.tertiary.opacity(0.1))
                                .frame(width: 120, height: 10)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(palette.tertiary.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            .blur(radius: 4)
            .allowsHitTesting(false)

            // Lock overlay on top
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(SemanticColors.additive.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(SemanticColors.additive)
                }

                Text("Additive Analysis")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Text("See E-numbers and hidden additives")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                Button(action: { showingPaywall = true }) {
                    Text("Unlock")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(SemanticColors.additive))
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
    }

    // MARK: - Allergens Watch Content
    private var allergensContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Check if ingredients exist and contain meaningful data
            if let ingredients = cachedIngredients {
                let clean = ingredients
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if !clean.isEmpty {
                // PERFORMANCE: Pre-sort allergens once, not on every ForEach iteration
                let potentialAllergens = getPotentialAllergens().sorted()

                if !potentialAllergens.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(potentialAllergens, id: \.self) { allergen in
                            AllergenWarningCard(allergenName: allergen)
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 40))
                            .foregroundColor(SemanticColors.positive)

                        Text("No Common Allergens Detected")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        Text("Based on the ingredient list, no common allergens were found")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }

                // Allergen disclaimer
                Divider()
                    .padding(.vertical, 8)

                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.neutral)
                    Text("Allergens may still be present if not shown. Ingredients may be outdated or incomplete. Always check the label if you have an allergy or intolerance.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Citations for allergen detection
                if !potentialAllergens.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("Based on UK FSA and EU food safety regulations")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Button(action: {
                            showingAllergenCitations = true
                        }) {
                            Text("Sources")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppPalette.standard.accent)
                        }
                    }
                    .padding(.top, 4)
                }
                }
            } else {
                // No ingredients available
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                        Text("No ingredient data available - unable to analyse additives and allergens")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                    }
                }
                .padding(12)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(16)
    }

    // MARK: - Vitamins & Minerals Content (NEW SYSTEM)
    private func vitaminsContent(scrollProxy: ScrollViewProxy) -> some View {
        let detectedNutrients = cachedDetectedNutrients
        let micronutrientDB = MicronutrientDatabase.shared
        let ordering = NutrientDatabase.allNutrients.map { $0.id }
        let sortedDetected = detectedNutrients.sorted { a, b in
            let ia = ordering.firstIndex(of: a) ?? Int.max
            let ib = ordering.firstIndex(of: b) ?? Int.max
            if ia != ib { return ia < ib }
            return a < b
        }

                return VStack(alignment: .leading, spacing: 12) {
            // Estimation disclaimer
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppPalette.standard.accent)
                Text("Estimated from food composition")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppPalette.standard.accent.opacity(0.08))
            )

            if !sortedDetected.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(sortedDetected, id: \.self) { nutrientId in
                        if let nutrientInfo = micronutrientDB.getNutrientInfo(nutrientId) {
                            NutrientInfoCard(nutrientInfo: nutrientInfo, scrollProxy: scrollProxy, cardId: nutrientId)
                                .id(nutrientId)
                        } else {
                            Text("⚠️ Could not load info for: \(nutrientId)")
                                .foregroundColor(SemanticColors.caution)
                        }
                    }
                }
                .transaction { t in t.disablesAnimations = true }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppPalette.standard.accent.opacity(0.5))

                    Text("No Micronutrient Data")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("Micronutrient information not available for this food")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }

            // Citations Section
            Divider()
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppPalette.standard.accent)
                    Text("Health Benefits Based On")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }

                Text("EFSA-approved health claims and NHS nutritional guidance")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)

                Button(action: {
                    // Show full citations in a sheet
                    showingVitaminCitations = true
                }) {
                    HStack {
                        Text("View Official Sources")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(AppPalette.standard.accent)
                }
            }
            .padding(.top, 8)
        }
        .padding(16)
    }
    
    private func recomputeDetectedNutrients() {
        // PERFORMANCE: Run nutrient detection in background to avoid blocking main thread
        Task.detached(priority: .userInitiated) {
            let ids = await MainActor.run { self.getDetectedNutrients() }
            let ordering = NutrientDatabase.allNutrients.map { $0.id }
            let sorted = ids.sorted { a, b in
                let ia = ordering.firstIndex(of: a) ?? Int.max
                let ib = ordering.firstIndex(of: b) ?? Int.max
                if ia != ib { return ia < ib }
                return a < b
            }
            await MainActor.run {
                self.cachedDetectedNutrients = sorted
            }
        }
    }

    // NEW: Detect nutrients from ingredients and micronutrient profile
    private func getDetectedNutrients() -> [String] {
        
        // Create a temporary DiaryFoodItem for nutrient detection
        // Include both ingredients AND micronutrient profile for accurate detection
        let tempFood = DiaryFoodItem(
            name: food.name,
            brand: food.brand,
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            servingDescription: "",
            quantity: 1,
            ingredients: food.ingredients,
            barcode: food.barcode,
            micronutrientProfile: food.micronutrientProfile  // Pass actual profile!
        )

        // Use NutrientDetector to detect nutrients from ingredients AND micronutrient profile
        // Use non-strict thresholds for display (show any nutrients present, not just 10%+ DV)
        let detectedNutrients = NutrientDetector.detectNutrients(in: tempFood, strictThresholds: false)

        
        return detectedNutrients
    }

    // MARK: - Edit Functions
    private func updateExistingFoodItem() {
        let diaryManager = DiaryDataManager.shared
        let currentDate = getEditingDate()
        
        let (breakfast, lunch, dinner, snacks) = diaryManager.getFoodData(for: currentDate)
        var updatedBreakfast = breakfast
        var updatedLunch = lunch
        var updatedDinner = dinner
        var updatedSnacks = snacks
        
        let foodId = food.id
        let updatedFoodItem = DiaryFoodItem(
            name: food.name,
            brand: food.brand,
            calories: Int(adjustedCalories),
            protein: adjustedProtein,
            carbs: adjustedCarbs,
            fat: adjustedFat,
            fiber: adjustedFiber,
            sugar: adjustedSugar,
            sodium: adjustedSalt,
            servingDescription: "\(String(format: "%.0f", actualServingSize))g serving",
            quantity: quantityMultiplier,
            time: getCurrentTimeString(),
            processedScore: nutraSafeGrade.grade,
            sugarLevel: getSugarLevel(),
            ingredients: food.ingredients,
            additives: food.additives,
            barcode: food.barcode
        )
        
        switch originalMealType {
        case "Breakfast":
            if let index = updatedBreakfast.firstIndex(where: { $0.id.uuidString == foodId }) {
                updatedBreakfast[index] = updatedFoodItem
            }
        case "Lunch":
            if let index = updatedLunch.firstIndex(where: { $0.id.uuidString == foodId }) {
                updatedLunch[index] = updatedFoodItem
            }
        case "Dinner":
            if let index = updatedDinner.firstIndex(where: { $0.id.uuidString == foodId }) {
                updatedDinner[index] = updatedFoodItem
            }
        case "Snacks":
            if let index = updatedSnacks.firstIndex(where: { $0.id.uuidString == foodId }) {
                updatedSnacks[index] = updatedFoodItem
            }
        default:
            break
        }
        
        diaryManager.saveFoodData(
            for: currentDate,
            breakfast: updatedBreakfast,
            lunch: updatedLunch,
            dinner: updatedDinner,
            snacks: updatedSnacks
        )
        
            }
    
    private func moveExistingFoodItem() {
        let diaryManager = DiaryDataManager.shared
        let currentDate = getEditingDate()
        
        let (breakfast, lunch, dinner, snacks) = diaryManager.getFoodData(for: currentDate)
        var updatedBreakfast = breakfast
        var updatedLunch = lunch
        var updatedDinner = dinner
        var updatedSnacks = snacks
        
        let foodId = food.id
        switch originalMealType {
        case "Breakfast":
            updatedBreakfast.removeAll { $0.id.uuidString == foodId }
        case "Lunch":
            updatedLunch.removeAll { $0.id.uuidString == foodId }
        case "Dinner":
            updatedDinner.removeAll { $0.id.uuidString == foodId }
        case "Snacks":
            updatedSnacks.removeAll { $0.id.uuidString == foodId }
        default:
            break
        }
        
        let updatedFoodItem = DiaryFoodItem(
            name: food.name,
            calories: Int(adjustedCalories),
            protein: adjustedProtein,
            carbs: adjustedCarbs,
            fat: adjustedFat,
            time: getCurrentTimeString(),
            processedScore: nutraSafeGrade.grade,
            sugarLevel: getSugarLevel(),
            ingredients: food.ingredients,
            additives: food.additives
        )
        
        switch selectedMeal {
        case "Breakfast":
            updatedBreakfast.append(updatedFoodItem)
        case "Lunch":
            updatedLunch.append(updatedFoodItem)
        case "Dinner":
            updatedDinner.append(updatedFoodItem)
        case "Snacks":
            updatedSnacks.append(updatedFoodItem)
        default:
            break
        }
        
        diaryManager.saveFoodData(
            for: currentDate,
            breakfast: updatedBreakfast,
            lunch: updatedLunch,
            dinner: updatedDinner,
            snacks: updatedSnacks
        )
        
            }
    
    private func addNewFoodItem() {
        let diaryManager = DiaryDataManager.shared
        let currentDate = isEditingMode ? getEditingDate() : Date()
        
        let newFoodItem = DiaryFoodItem(
            name: food.name,
            calories: Int(adjustedCalories),
            protein: adjustedProtein,
            carbs: adjustedCarbs,
            fat: adjustedFat,
            time: getCurrentTimeString(),
            processedScore: nutraSafeGrade.grade,
            sugarLevel: getSugarLevel(),
            ingredients: food.ingredients,
            additives: food.additives
        )
        
        let (breakfast, lunch, dinner, snacks) = diaryManager.getFoodData(for: currentDate)
        var updatedBreakfast = breakfast
        var updatedLunch = lunch
        var updatedDinner = dinner
        var updatedSnacks = snacks
        
        switch selectedMeal {
        case "Breakfast":
            updatedBreakfast.append(newFoodItem)
        case "Lunch":
            updatedLunch.append(newFoodItem)
        case "Dinner":
            updatedDinner.append(newFoodItem)
        case "Snacks":
            updatedSnacks.append(newFoodItem)
        default:
            break
        }
        
        diaryManager.saveFoodData(
            for: currentDate,
            breakfast: updatedBreakfast,
            lunch: updatedLunch,
            dinner: updatedDinner,
            snacks: updatedSnacks
        )
        
            }
    
    private func getCurrentTimeString() -> String {
        // PERFORMANCE: Use cached static formatter
        DateHelper.shortTimeFormatter.string(from: Date())
    }
    
    private func getSugarLevel() -> String {
        let perServingSugar = displayFood.sugar * perServingMultiplier * quantityMultiplier
        let unit = servingUnit.lowercased()
        let isLiquid = unit == "ml" || unit == "oz"
        if isLiquid {
            if perServingSugar < 6 { return "Low" }
            else if perServingSugar < 16 { return "Med" }
            else { return "High" }
        } else {
            if perServingSugar < 5 { return "Low" }
            else if perServingSugar < 15 { return "Med" }
            else { return "High" }
        }
    }
    
    private func getEditingDate() -> Date {
        if let dateString = UserDefaults.standard.string(forKey: "editingDate") {
            // PERFORMANCE: Use cached static formatter
            return DateHelper.isoDateFormatter.date(from: dateString) ?? Date()
        }
        return Date()
    }
}

// MARK: - Supporting Components (also extracted from ContentView.swift)

// MARK: - Modern Card Components

struct AllergenWarningCard: View {
    let allergenName: String
    @Environment(\.colorScheme) var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Soft amber indicator line (consistent with additive cards)
            RoundedRectangle(cornerRadius: 2)
                .fill(SemanticColors.neutral)
                .frame(width: 3, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(allergenName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(palette.textPrimary)

                Text("Found in this product")
                    .font(.system(size: 11))
                    .foregroundColor(palette.textTertiary)
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.midnightCard.opacity(0.5) : palette.tertiary.opacity(0.06))
        )
    }
}

struct AllergenInfoRow: View {
    let icon: String
    let title: String
    let content: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)

                Text(content)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct NutrientCard: View {
    let nutrientName: String
    let micronutrients: MicronutrientProfile
    @State private var showDetail = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: { showDetail = true }) {
            HStack(alignment: .center, spacing: 12) {
                // Nutrient icon with soft background
                ZStack {
                    Circle()
                        .fill(getNutrientColor().opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: getNutrientIcon())
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(getNutrientColor())
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(nutrientName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(getNutrientCategory())
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .sheet(isPresented: $showDetail) {
            NutrientDetailSheet(nutrientName: nutrientName, category: getNutrientCategory(), function: getNutrientFunction(), benefits: getNutrientBenefits(), color: getNutrientColor(), icon: getNutrientIcon())
        }
    }

    private func getNutrientIcon() -> String {
        let lower = nutrientName.lowercased()

        if lower.contains("vitamin") {
            return "pills.fill"
        } else {
            return "cube.fill"
        }
    }

    private func getNutrientColor() -> Color {
        let lower = nutrientName.lowercased()

        if lower.contains("vitamin") {
            return .orange
        } else if lower.contains("calcium") || lower.contains("magnesium") || lower.contains("phosphorus") {
            return AppPalette.standard.accent
        } else if lower.contains("iron") || lower.contains("zinc") || lower.contains("copper") {
            return .red
        } else if lower.contains("potassium") || lower.contains("sodium") {
            return .purple
        } else {
            return .green
        }
    }

    private func getNutrientCategory() -> String {
        let lower = nutrientName.lowercased()

        if lower.contains("vitamin") {
            return "Essential vitamin"
        } else {
            return "Essential mineral"
        }
    }

    private func getNutrientFunction() -> String {
        let lower = nutrientName.lowercased()

        if lower.contains("vitamin a") {
            return "Supports vision, immune function, and skin health"
        } else if lower.contains("vitamin c") {
            return "Powerful antioxidant that supports immune system and collagen production"
        } else if lower.contains("vitamin d") {
            return "Helps absorb calcium and supports bone health and immune function"
        } else if lower.contains("vitamin e") {
            return "Acts as an antioxidant protecting cells from damage"
        } else if lower.contains("vitamin k") {
            return "Essential for blood clotting and bone health"
        } else if lower.contains("thiamine") || lower.contains("b1") {
            return "Helps convert food into energy and supports nerve function"
        } else if lower.contains("riboflavin") || lower.contains("b2") {
            return "Important for energy production and cellular function"
        } else if lower.contains("niacin") || lower.contains("b3") {
            return "Supports metabolism, skin health, and nervous system"
        } else if lower.contains("vitamin b6") {
            return "Aids in protein metabolism and red blood cell formation"
        } else if lower.contains("folate") {
            return "Crucial for DNA synthesis and cell division"
        } else if lower.contains("vitamin b12") {
            return "Essential for nerve function and red blood cell formation"
        } else if lower.contains("biotin") || lower.contains("b7") {
            return "Supports hair, skin, and nail health"
        } else if lower.contains("pantothenic") || lower.contains("b5") {
            return "Important for energy production and hormone synthesis"
        } else if lower.contains("calcium") {
            return "Builds and maintains strong bones and teeth"
        } else if lower.contains("iron") {
            return "Essential for oxygen transport in blood"
        } else if lower.contains("potassium") {
            return "Regulates fluid balance and supports heart function"
        } else if lower.contains("magnesium") {
            return "Supports muscle and nerve function, energy production"
        } else if lower.contains("zinc") {
            return "Supports immune function and wound healing"
        } else if lower.contains("phosphorus") {
            return "Essential for bone health and energy production"
        } else if lower.contains("selenium") {
            return "Acts as an antioxidant and supports thyroid function"
        } else if lower.contains("copper") {
            return "Helps form red blood cells and maintains nerve cells"
        } else if lower.contains("manganese") {
            return "Supports bone formation and nutrient metabolism"
        } else if lower.contains("chromium") {
            return "Helps regulate blood sugar levels"
        } else if lower.contains("iodine") {
            return "Essential for thyroid hormone production"
        } else if lower.contains("molybdenum") {
            return "Helps break down certain amino acids"
        } else {
            return "Plays an important role in bodily functions"
        }
    }

    private func getNutrientBenefits() -> String {
        let lower = nutrientName.lowercased()

        if lower.contains("vitamin a") {
            return "Supports healthy vision, especially in low light, and maintains healthy skin"
        } else if lower.contains("vitamin c") {
            return "Boosts immune system, aids wound healing, and helps maintain healthy skin"
        } else if lower.contains("vitamin d") {
            return "Strengthens bones, supports muscle function, and boosts mood"
        } else if lower.contains("vitamin e") {
            return "Protects cells from oxidative stress and supports skin health"
        } else if lower.contains("vitamin k") {
            return "Helps prevent excessive bleeding and supports bone strength"
        } else if lower.contains("thiamine") || lower.contains("b1") {
            return "Maintains healthy nervous system and supports heart function"
        } else if lower.contains("riboflavin") || lower.contains("b2") {
            return "Promotes healthy skin, eyes, and nervous system"
        } else if lower.contains("niacin") || lower.contains("b3") {
            return "Improves cholesterol levels and brain function"
        } else if lower.contains("vitamin b6") {
            return "Supports brain development and immune function"
        } else if lower.contains("folate") {
            return "Prevents birth defects and supports healthy cell growth"
        } else if lower.contains("vitamin b12") {
            return "Prevents anemia and supports energy levels"
        } else if lower.contains("biotin") || lower.contains("b7") {
            return "Promotes healthy hair growth and strong nails"
        } else if lower.contains("pantothenic") || lower.contains("b5") {
            return "Supports adrenal function and reduces stress"
        } else if lower.contains("calcium") {
            return "Prevents osteoporosis and supports muscle contraction"
        } else if lower.contains("iron") {
            return "Prevents anemia and supports energy levels"
        } else if lower.contains("potassium") {
            return "Helps maintain healthy blood pressure and reduces stroke risk"
        } else if lower.contains("magnesium") {
            return "Supports heart health, bone strength, and reduces migraine frequency"
        } else if lower.contains("zinc") {
            return "Boosts immune system and accelerates wound healing"
        } else if lower.contains("phosphorus") {
            return "Supports kidney function and muscle recovery"
        } else if lower.contains("selenium") {
            return "Protects against oxidative stress and supports reproduction"
        } else if lower.contains("copper") {
            return "Supports brain health and immune function"
        } else if lower.contains("manganese") {
            return "Supports bone health and wound healing"
        } else if lower.contains("chromium") {
            return "May improve insulin sensitivity and blood sugar control"
        } else if lower.contains("iodine") {
            return "Supports healthy metabolism and brain development"
        } else if lower.contains("molybdenum") {
            return "Supports liver detoxification processes"
        } else {
            return "Contributes to overall health and wellbeing"
        }
    }
}

// MARK: - Nutrient Detail Sheet
struct NutrientDetailSheet: View {
    let nutrientName: String
    let category: String
    let function: String
    let benefits: String
    let color: Color
    let icon: String
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with icon
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(color.opacity(0.15))
                                .frame(width: 60, height: 60)

                            Image(systemName: icon)
                                .font(.system(size: 26, weight: .medium))
                                .foregroundColor(color)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(nutrientName)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)

                            Text(category)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 8)

                    // Function section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What it does")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)

                        Text(function)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(colorScheme == .dark ? Color.midnightCard : Color(.systemGray6))
                    )

                    // Benefits section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Benefits")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)

                        Text(benefits)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(colorScheme == .dark ? Color.midnightCard : Color(.systemGray6))
                    )

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(colorScheme == .dark ? Color.midnightBackground : Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
            }
        }
    }
}

struct NutrientInfoRow: View {
    let icon: String
    let title: String
    let content: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)

                Text(content)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct VitaminMineralRow: View {
    let name: String
    let confidence: MicronutrientConfidence

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(SemanticColors.positive)

            Text(name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)

            Spacer()

            // Confidence badge only
            Circle()
                .fill(confidence.color.opacity(0.9))
                .frame(width: 6, height: 6)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.green.opacity(0.05))
        .cornerRadius(8)
    }
}

// Expandable section component
struct ExpandableSection<Content: View>: View {
    let title: String
    let systemImage: String
    let content: () -> Content
    @State private var isExpanded = false
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppPalette.standard.accent)
                        .frame(width: 24)
                    
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 16)
                .background(palette.tertiary.opacity(0.15))
                .cornerRadius(isExpanded ? 12 : 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                content()
                    .background(Color.adaptiveCard)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.adaptiveCard)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// Vitamin row component
struct VitaminRow: View {
    let name: String
    let amount: String
    let dailyValue: String
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        HStack {
            Text(name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(amount)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppPalette.standard.accent)
                Text(dailyValue)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(palette.tertiary.opacity(0.15))
        .cornerRadius(8)
    }
}

struct MacroRow: View {
    let name: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(name)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
            Text("\(String(format: "%.1f", value))\(unit)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
        }
    }
}

// MARK: - Nutrient Info Card (NEW SYSTEM)
struct NutrientInfoCard: View {
    let nutrientInfo: NutrientInfo
    let scrollProxy: ScrollViewProxy
    let cardId: String
    @State private var isExpanded = false
    @State private var showingCitations = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main header - always visible
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }

                // Scroll to this card when expanded to ensure it's fully visible
                if !isExpanded {
                    // Collapsing - no scroll needed
                } else {
                    // Expanding - scroll after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            scrollProxy.scrollTo(cardId, anchor: .center)
                        }
                    }
                }
            }) {
                HStack(spacing: 12) {
                    // Nutrient name and category
                    VStack(alignment: .leading, spacing: 4) {
                        Text(nutrientInfo.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        // Show formatted category
                        if let category = nutrientInfo.category, !category.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 10))
                                Text(formatCategory(category))
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Expand/collapse chevron
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(SemanticColors.positive)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.3), value: isExpanded)
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                        .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 12) {
                        // Functions section
                        if let benefits = nutrientInfo.benefits, !benefits.isEmpty {
                            benefitRow(icon: "sparkles", title: "Functions in body", content: formatBenefits(benefits))
                        }

                        // Daily intake
                        if let dailyIntake = nutrientInfo.recommendedDailyIntake, !dailyIntake.isEmpty {
                            benefitRow(icon: "calendar.badge.clock", title: "Recommended daily", content: dailyIntake)
                        }

                        // Common sources
                        if let sources = nutrientInfo.commonSources, !sources.isEmpty {
                            benefitRow(icon: "leaf.fill", title: "Also found in", content: formatSources(sources))
                        }

                        // Official Health Claims Section (EFSA/NHS Verbatim)
                        if let officialClaims = getOfficialHealthClaims(for: nutrientInfo.name) {
                            Divider()
                                .padding(.vertical, 8)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppPalette.standard.accent)
                                    Text("Official Health Claims")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.primary)
                                }

                                ForEach(Array(officialClaims.enumerated()), id: \.offset) { index, claim in
                                    HStack(alignment: .top, spacing: 6) {
                                        Text("•")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(claim.text)
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                            Text(claim.source)
                                                .font(.system(size: 10))
                                                .foregroundColor(AppPalette.standard.accent)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        // Citation note for health benefits - Clickable button
                        Divider()
                            .padding(.vertical, 4)

                        Button(action: {
                            showingCitations = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppPalette.standard.accent)
                                Text("Health benefits based on EFSA-approved claims and NHS guidance")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppPalette.standard.accent)
                                    .lineLimit(2)
                                Image(systemName: "arrow.up.right.square")
                                    .font(.system(size: 9))
                                    .foregroundColor(AppPalette.standard.accent)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .transition(.opacity)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(SemanticColors.positive.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(SemanticColors.positive.opacity(0.3), lineWidth: 1.5)
                )
        )
        .fullScreenCover(isPresented: $showingCitations) {
            NavigationView {
                List {
                    Section(header: Text("Vitamin & Mineral Health Claims")) {
                        Text("Health benefits shown are based on official EFSA-approved health claims and NHS nutritional guidance.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    ForEach(CitationManager.shared.citations(for: .dailyValues).filter {
                        $0.title.contains("Vitamin") || $0.title.contains("Iron") || $0.title.contains("Calcium") || $0.title.contains("Magnesium") || $0.title.contains("Zinc")
                    }) { citation in
                        Button(action: {
                            if let url = URL(string: citation.url) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .foregroundColor(AppPalette.standard.accent)
                                        .font(.system(size: 14))
                                    Text(citation.organization)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.caption)
                                        .foregroundColor(AppPalette.standard.accent)
                                }
                                Text(citation.title)
                                    .font(.caption)
                                    .foregroundColor(AppPalette.standard.accent)
                                Text(citation.description)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(5)
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

    // Helper view for each benefit row
    private func benefitRow(icon: String, title: String, content: String, iconColor: Color = .green) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
            }

            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // Helper function to format category text
    private func formatCategory(_ category: String) -> String {
        let cleaned = category
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "\"", with: "")

        let items = cleaned.components(separatedBy: ",")
        if let first = items.first?.trimmingCharacters(in: .whitespaces) {
            return first.capitalized
        }

        return cleaned
    }

    // Helper function to format benefits (remove brackets and quotes)
    private func formatBenefits(_ benefits: String) -> String {
        let formatted = benefits
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "\"", with: "")

        // Replace commas with bullets for better readability
        let items = formatted.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if items.count > 1 {
            return items.joined(separator: " • ")
        }

        return formatted
    }

    // Helper function to format sources (remove brackets and quotes)
    private func formatSources(_ sources: String) -> String {
        var formatted = sources
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "\"", with: "")

        // Clean up any extra spaces
        formatted = formatted.trimmingCharacters(in: .whitespaces)

        return formatted
    }

    // Helper function to get official EFSA/NHS health claims for a nutrient
    private func getOfficialHealthClaims(for nutrientName: String) -> [HealthClaim]? {
        let name = nutrientName.lowercased()

        // Return verbatim EFSA/NHS approved claims
        if name.contains("vitamin a") {
            return [
                HealthClaim(text: "Vitamin A contributes to the maintenance of normal vision", source: "EFSA"),
                HealthClaim(text: "Vitamin A contributes to normal function of the immune system", source: "EFSA"),
                HealthClaim(text: "Vitamin A contributes to the maintenance of normal skin", source: "EFSA"),
                HealthClaim(text: "Vitamin A contributes to normal iron metabolism", source: "EFSA")
            ]
        } else if name.contains("vitamin c") || name.contains("ascorbic acid") {
            return [
                HealthClaim(text: "Vitamin C contributes to normal collagen formation for the normal function of blood vessels, bones, cartilage, gums, skin and teeth", source: "EFSA"),
                HealthClaim(text: "Vitamin C contributes to normal function of the immune system", source: "EFSA"),
                HealthClaim(text: "Vitamin C increases iron absorption", source: "EFSA"),
                HealthClaim(text: "Helps protect cells and keep them healthy", source: "NHS")
            ]
        } else if name.contains("vitamin d") {
            return [
                HealthClaim(text: "Vitamin D contributes to normal absorption/utilisation of calcium and phosphorus", source: "EFSA"),
                HealthClaim(text: "Vitamin D contributes to the maintenance of normal bones", source: "EFSA"),
                HealthClaim(text: "Vitamin D contributes to normal function of the immune system", source: "EFSA"),
                HealthClaim(text: "Helps regulate the amount of calcium and phosphate in the body", source: "NHS")
            ]
        } else if name.contains("vitamin e") {
            return [
                HealthClaim(text: "Vitamin E contributes to the protection of cells from oxidative stress", source: "EFSA"),
                HealthClaim(text: "Helps protect skin and eyes", source: "NHS")
            ]
        } else if name.contains("vitamin b6") || name.contains("pyridoxine") {
            return [
                HealthClaim(text: "Vitamin B6 contributes to normal protein and glycogen metabolism", source: "EFSA"),
                HealthClaim(text: "Vitamin B6 contributes to normal functioning of the nervous system", source: "EFSA"),
                HealthClaim(text: "Vitamin B6 contributes to normal function of the immune system", source: "EFSA")
            ]
        } else if name.contains("vitamin b12") || name.contains("cobalamin") {
            return [
                HealthClaim(text: "Vitamin B12 contributes to normal function of the immune system", source: "EFSA"),
                HealthClaim(text: "Vitamin B12 contributes to normal red blood cell formation", source: "EFSA"),
                HealthClaim(text: "Vitamin B12 contributes to normal functioning of the nervous system", source: "EFSA")
            ]
        } else if name.contains("vitamin k") {
            return [
                HealthClaim(text: "Vitamin K contributes to normal blood clotting", source: "EFSA"),
                HealthClaim(text: "Vitamin K contributes to the maintenance of normal bones", source: "EFSA")
            ]
        } else if name.contains("iron") {
            return [
                HealthClaim(text: "Iron contributes to normal formation of red blood cells and haemoglobin", source: "EFSA"),
                HealthClaim(text: "Iron contributes to normal oxygen transport in the body", source: "EFSA"),
                HealthClaim(text: "Iron contributes to normal function of the immune system", source: "EFSA")
            ]
        } else if name.contains("calcium") {
            return [
                HealthClaim(text: "Calcium is needed for the maintenance of normal bones", source: "EFSA"),
                HealthClaim(text: "Calcium is needed for the maintenance of normal teeth", source: "EFSA"),
                HealthClaim(text: "Calcium contributes to normal muscle function", source: "EFSA"),
                HealthClaim(text: "Helps build strong bones and teeth", source: "NHS")
            ]
        } else if name.contains("magnesium") {
            return [
                HealthClaim(text: "Magnesium contributes to normal muscle function", source: "EFSA"),
                HealthClaim(text: "Magnesium contributes to normal functioning of the nervous system", source: "EFSA"),
                HealthClaim(text: "Magnesium contributes to the maintenance of normal bones", source: "EFSA")
            ]
        } else if name.contains("zinc") {
            return [
                HealthClaim(text: "Zinc contributes to normal function of the immune system", source: "EFSA"),
                HealthClaim(text: "Zinc contributes to the maintenance of normal skin", source: "EFSA"),
                HealthClaim(text: "Zinc contributes to the maintenance of normal vision", source: "EFSA")
            ]
        } else if name.contains("selenium") {
            return [
                HealthClaim(text: "Selenium contributes to normal function of the immune system", source: "EFSA"),
                HealthClaim(text: "Selenium contributes to the protection of cells from oxidative stress", source: "EFSA")
            ]
        } else if name.contains("folate") || name.contains("folic acid") {
            return [
                HealthClaim(text: "Folate contributes to normal blood formation", source: "EFSA"),
                HealthClaim(text: "Folate contributes to normal function of the immune system", source: "EFSA"),
                HealthClaim(text: "Forms healthy red blood cells", source: "NHS")
            ]
        } else if name.contains("niacin") || name.contains("vitamin b3") {
            return [
                HealthClaim(text: "Niacin contributes to normal functioning of the nervous system", source: "EFSA"),
                HealthClaim(text: "Niacin contributes to the maintenance of normal skin", source: "EFSA")
            ]
        } else if name.contains("thiamin") || name.contains("vitamin b1") {
            return [
                HealthClaim(text: "Thiamin contributes to normal functioning of the nervous system", source: "EFSA"),
                HealthClaim(text: "Thiamin contributes to normal heart function", source: "EFSA")
            ]
        } else if name.contains("riboflavin") || name.contains("vitamin b2") {
            return [
                HealthClaim(text: "Riboflavin contributes to the maintenance of normal vision", source: "EFSA"),
                HealthClaim(text: "Riboflavin contributes to the maintenance of normal skin", source: "EFSA"),
                HealthClaim(text: "Riboflavin contributes to normal function of the nervous system", source: "EFSA")
            ]
        } else if name.contains("pantothenic acid") || name.contains("vitamin b5") {
            return [
                HealthClaim(text: "Pantothenic acid contributes to normal mental performance", source: "EFSA"),
                HealthClaim(text: "Pantothenic acid contributes to normal synthesis and metabolism of steroid hormones, vitamin D and some neurotransmitters", source: "EFSA")
            ]
        } else if name.contains("biotin") || name.contains("vitamin b7") {
            return [
                HealthClaim(text: "Biotin contributes to the maintenance of normal hair", source: "EFSA"),
                HealthClaim(text: "Biotin contributes to the maintenance of normal skin", source: "EFSA"),
                HealthClaim(text: "Biotin contributes to normal functioning of the nervous system", source: "EFSA")
            ]
        } else if name.contains("potassium") {
            return [
                HealthClaim(text: "Potassium contributes to normal functioning of the nervous system", source: "EFSA"),
                HealthClaim(text: "Potassium contributes to normal muscle function", source: "EFSA"),
                HealthClaim(text: "Potassium contributes to the maintenance of normal blood pressure", source: "EFSA")
            ]
        } else if name.contains("phosphorus") {
            return [
                HealthClaim(text: "Phosphorus contributes to normal function of cell membranes", source: "EFSA"),
                HealthClaim(text: "Phosphorus contributes to the maintenance of normal bones", source: "EFSA"),
                HealthClaim(text: "Phosphorus contributes to the maintenance of normal teeth", source: "EFSA")
            ]
        }

        return nil
    }
}

// MARK: - ═══════════════════════════════════════════════════════════════════════
// MARK: - REDESIGNED COMPONENTS (Onboarding Design Language)
// MARK: - ═══════════════════════════════════════════════════════════════════════

extension FoodDetailViewFromSearch {
    // MARK: - Soft Gradient Background
    var foodDetailBackground: some View {
        ZStack {
            // Base: soft tinted background (NOT pure white)
            if colorScheme == .dark {
                Color.midnightBackground
            } else {
                // Soft teal/mint wash matching onboarding
                LinearGradient(
                    colors: [
                        Color(red: 0.94, green: 0.98, blue: 0.98),  // Soft mint
                        Color(red: 0.96, green: 0.97, blue: 0.95),  // Warm off-white
                        palette.background
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            // Subtle radial accent in corner
            RadialGradient(
                colors: [
                    palette.accent.opacity(colorScheme == .dark ? 0.08 : 0.04),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 350
            )
        }
    }

    // MARK: - Redesigned Header Section
    private var redesignedHeaderSection: some View {
        VStack(spacing: 4) {
            // Product name - prominent
            Text(displayFood.name)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(palette.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            // Brand - subtle secondary
            if let brand = displayFood.brand, !brand.isEmpty {
                Text(brand)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(palette.textSecondary)
            }

            // Inline calorie display - compact and prominent
            HStack(spacing: 4) {
                Text(String(format: "%.0f", adjustedCalories))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(palette.accent)
                Text("kcal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(palette.textSecondary)
            }
            .padding(.top, 2)

            // Allergen warning - calm, not aggressive
            if !detectedUserAllergens.isEmpty {
                redesignedAllergenBanner
            }
        }
        .padding(.top, 4)
        .padding(.horizontal, DesignTokens.Spacing.sm)
    }

    // MARK: - Redesigned Allergen Banner (Calm, Not Alarming)
    private var redesignedAllergenBanner: some View {
        VStack(spacing: 8) {
            // Allergen pills - softer styling
            HStack(spacing: 8) {
                ForEach(detectedUserAllergens, id: \.rawValue) { allergen in
                    HStack(spacing: 4) {
                        Text(allergen.icon)
                            .font(.system(size: 11))
                        Text(allergen.displayName)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(SemanticColors.caution.opacity(0.12))
                    )
                    .overlay(
                        Capsule()
                            .stroke(SemanticColors.caution.opacity(0.3), lineWidth: 1)
                    )
                    .foregroundColor(SemanticColors.caution)
                }
            }

            // Disclaimer - subtle
            Text("Always check the label for allergens")
                .font(.system(size: 10))
                .foregroundColor(palette.textTertiary)
        }
        .padding(.top, 4)
    }

    // MARK: - Redesigned Action Buttons (Compact)
    private var redesignedActionButtons: some View {
        VStack(spacing: 8) {
            // Primary: Add to Diary
            Button(action: addToFoodLog) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text(diaryEntryId != nil ? "Update Diary Entry" : "Add to Diary")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [palette.accent, palette.primary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: palette.accent.opacity(0.25), radius: 8, y: 3)
                )
            }

            // Secondary: Log & Start Fast
            if !isCurrentlyFasting && diaryEntryId == nil {
                Button(action: addToFoodLogAndStartFast) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 14, weight: .medium))
                        Text("Log Last Meal & Start Fast")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(palette.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(palette.accent.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(palette.accent.opacity(0.2), lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - Redesigned Serving Section (Compact)
    private var redesignedServingSection: some View {
        VStack(spacing: 12) {
            // Section header
            HStack {
                Text("How much?")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(palette.textPrimary)
                Spacer()
            }

            // Meal selector - pill style
            redesignedMealSelector

            // Portion cards - interactive, not spreadsheet
            redesignedPortionCards
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                .shadow(
                    color: DesignTokens.Shadow.subtle.color,
                    radius: DesignTokens.Shadow.subtle.radius,
                    y: DesignTokens.Shadow.subtle.y
                )
        )
    }

    // MARK: - Redesigned Meal Selector (Pill Style)
    private var redesignedMealSelector: some View {
        HStack(spacing: 8) {
            ForEach(["Breakfast", "Lunch", "Dinner", "Snack"], id: \.self) { meal in
                let isSelected = selectedMeal.lowercased() == meal.lowercased()
                Button(action: { selectedMeal = meal }) {
                    Text(meal)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? .white : palette.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isSelected ? palette.accent : palette.tertiary.opacity(0.15))
                        )
                }
            }
        }
    }

    // MARK: - Redesigned Portion Cards (Compact)
    private var redesignedPortionCards: some View {
        VStack(spacing: 8) {
            if isPerUnit {
                // Per-unit foods: single intuitive card
                redesignedPerUnitCard
            } else {
                // Per-100g foods: portion options as cards
                let effectiveQuery = food.name
                if food.hasAnyPortionOptions(forQuery: effectiveQuery) {
                    let portions = food.portionsForQuery(effectiveQuery)
                    ForEach(portions) { portion in
                        redesignedPortionCard(portion: portion)
                    }
                }
                // Custom grams option
                redesignedCustomGramsCard
            }

            // Quantity stepper - always visible
            redesignedQuantityStepper
        }
    }

    // MARK: - Redesigned Per-Unit Card (Compact)
    private var redesignedPerUnitCard: some View {
        let isSelected = selectedPortionName != "__custom__"
        return Button(action: { selectedPortionName = servingUnit }) {
            HStack(spacing: 10) {
                // Icon - smaller
                ZStack {
                    Circle()
                        .fill(isSelected ? palette.accent.opacity(0.12) : palette.tertiary.opacity(0.1))
                        .frame(width: 36, height: 36)
                    Image(systemName: "fork.knife")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? palette.accent : palette.textSecondary)
                }

                // Description
                VStack(alignment: .leading, spacing: 1) {
                    Text(servingUnit.capitalized)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(palette.textPrimary)
                    Text("\(Int(food.calories)) kcal")
                        .font(.system(size: 12))
                        .foregroundColor(palette.textSecondary)
                }

                Spacer()

                // Selection indicator - smaller
                ZStack {
                    Circle()
                        .stroke(isSelected ? palette.accent : palette.tertiary.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle()
                            .fill(palette.accent)
                            .frame(width: 20, height: 20)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? palette.accent.opacity(0.06) : (colorScheme == .dark ? Color.midnightCardSecondary : palette.tertiary.opacity(0.08)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? palette.accent.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Redesigned Portion Card (Compact)
    private func redesignedPortionCard(portion: PortionOption) -> some View {
        let isSelected = selectedPortionName == portion.name
        let multiplier = portion.serving_g / 100.0
        let portionCalories = food.calories * multiplier

        return Button(action: {
            selectedPortionName = portion.name
            servingAmount = String(format: "%.0f", portion.serving_g)
            servingUnit = food.isLiquidCategory ? "ml" : "g"
        }) {
            HStack(spacing: 10) {
                // Icon - smaller
                ZStack {
                    Circle()
                        .fill(isSelected ? palette.accent.opacity(0.12) : palette.tertiary.opacity(0.1))
                        .frame(width: 36, height: 36)
                    Image(systemName: portionIcon(for: portion.name))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? palette.accent : palette.textSecondary)
                }

                // Description
                VStack(alignment: .leading, spacing: 1) {
                    Text(portion.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(palette.textPrimary)
                    Text("\(Int(portion.serving_g))\(food.isLiquidCategory ? "ml" : "g") • \(Int(portionCalories)) kcal")
                        .font(.system(size: 12))
                        .foregroundColor(palette.textSecondary)
                }

                Spacer()

                // Selection indicator - smaller
                ZStack {
                    Circle()
                        .stroke(isSelected ? palette.accent : palette.tertiary.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle()
                            .fill(palette.accent)
                            .frame(width: 20, height: 20)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? palette.accent.opacity(0.06) : (colorScheme == .dark ? Color.midnightCardSecondary : palette.tertiary.opacity(0.08)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? palette.accent.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Portion Icon Helper
    private func portionIcon(for name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("small") { return "s.circle" }
        if lower.contains("medium") { return "m.circle" }
        if lower.contains("large") { return "l.circle" }
        if lower.contains("cup") { return "cup.and.saucer" }
        if lower.contains("slice") { return "square.split.1x2" }
        if lower.contains("piece") { return "square.on.square" }
        return "fork.knife"
    }

    // MARK: - Redesigned Custom Grams Card (Compact)
    private var redesignedCustomGramsCard: some View {
        let isSelected = selectedPortionName == "__custom__"
        return Button(action: { selectedPortionName = "__custom__" }) {
            HStack(spacing: 10) {
                // Icon - smaller
                ZStack {
                    Circle()
                        .fill(isSelected ? palette.accent.opacity(0.12) : palette.tertiary.opacity(0.1))
                        .frame(width: 36, height: 36)
                    Image(systemName: "pencil.and.ruler")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? palette.accent : palette.textSecondary)
                }

                // Input field
                VStack(alignment: .leading, spacing: 1) {
                    Text("Custom amount")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(palette.textPrimary)

                    if isSelected {
                        HStack(spacing: 6) {
                            TextField("100", text: $gramsAmount)
                                .keyboardType(.numberPad)
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 50)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(palette.tertiary.opacity(0.1))
                                )
                            Text(food.isLiquidCategory ? "ml" : "g")
                                .font(.system(size: 12))
                                .foregroundColor(palette.textSecondary)
                        }
                    } else {
                        Text("Enter specific amount")
                            .font(.system(size: 12))
                            .foregroundColor(palette.textSecondary)
                    }
                }

                Spacer()

                // Selection indicator - smaller
                ZStack {
                    Circle()
                        .stroke(isSelected ? palette.accent : palette.tertiary.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle()
                            .fill(palette.accent)
                            .frame(width: 20, height: 20)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? palette.accent.opacity(0.06) : (colorScheme == .dark ? Color.midnightCardSecondary : palette.tertiary.opacity(0.08)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? palette.accent.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Redesigned Quantity Stepper
    private var redesignedQuantityStepper: some View {
        HStack(spacing: 16) {
            Text("Quantity")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(palette.textSecondary)

            Spacer()

            HStack(spacing: 0) {
                // Minus button
                Button(action: {
                    if quantityMultiplier > 0.5 {
                        withAnimation(.easeOut(duration: 0.15)) {
                            quantityMultiplier = quantityMultiplier == 1 ? 0.5 : quantityMultiplier - 1
                        }
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(quantityMultiplier > 0.5 ? palette.accent : palette.textTertiary)
                        .frame(width: 36, height: 36)
                }
                .disabled(quantityMultiplier <= 0.5)

                // Current value
                Text(formatQuantityMultiplier(quantityMultiplier))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(palette.textPrimary)
                    .frame(width: 44)

                // Plus button
                Button(action: {
                    withAnimation(.easeOut(duration: 0.15)) {
                        quantityMultiplier = quantityMultiplier < 1 ? 1 : quantityMultiplier + 1
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(palette.accent)
                        .frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, 4)
            .background(
                Capsule()
                    .fill(palette.tertiary.opacity(0.1))
            )
        }
        .padding(.top, 8)
    }

    // MARK: - Redesigned Nutrition Card (Glanceable)
    private var redesignedNutritionCard: some View {
        VStack(spacing: 20) {
            // Hero: Calories
            VStack(spacing: 6) {
                HStack(alignment: .bottom, spacing: 6) {
                    Text(String(format: "%.0f", adjustedCalories))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(palette.textPrimary)
                    Text("kcal")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(palette.textSecondary)
                        .padding(.bottom, 8)
                }
                Text("per serving")
                    .font(.system(size: 13))
                    .foregroundColor(palette.textTertiary)
            }

            // Macro summary - clean cards
            HStack(spacing: 12) {
                redesignedMacroCard(label: "Protein", value: adjustedProtein, color: SemanticColors.nutrient)
                redesignedMacroCard(label: "Carbs", value: adjustedCarbs, color: palette.accent)
                redesignedMacroCard(label: "Fat", value: adjustedFat, color: SemanticColors.neutral)
            }

            // Detailed nutrition - collapsible
            DisclosureGroup {
                VStack(spacing: 8) {
                    redesignedNutritionRow("Saturated Fat", value: adjustedSatFat)
                    redesignedNutritionRow("Fibre", value: adjustedFiber)
                    redesignedNutritionRow("Sugar", value: adjustedSugar)
                    redesignedNutritionRow("Salt", value: adjustedSalt)
                }
                .padding(.top, 12)
            } label: {
                Text("More nutrition details")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(palette.textSecondary)
            }
            .tint(palette.accent)

            // Per 100g values - collapsible
            DisclosureGroup {
                VStack(spacing: 8) {
                    per100gNutritionRow("Calories", value: displayFood.calories, unit: "kcal")
                    per100gNutritionRow("Protein", value: displayFood.protein, unit: "g")
                    per100gNutritionRow("Carbohydrates", value: displayFood.carbs, unit: "g")
                    per100gNutritionRow("Fat", value: displayFood.fat, unit: "g")
                    if let satFat = displayFood.saturatedFat {
                        per100gNutritionRow("Saturated Fat", value: satFat, unit: "g")
                    }
                    per100gNutritionRow("Fibre", value: displayFood.fiber, unit: "g")
                    per100gNutritionRow("Sugar", value: displayFood.sugar, unit: "g")
                    per100gNutritionRow("Salt", value: displayFood.sodium / 1000, unit: "g") // Convert mg to g
                }
                .padding(.top, 12)
            } label: {
                HStack {
                    Text("Per 100g values")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(palette.textSecondary)
                    Spacer()
                    Text("(base values)")
                        .font(.system(size: 12))
                        .foregroundColor(palette.textTertiary)
                }
            }
            .tint(palette.accent)
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                .shadow(
                    color: DesignTokens.Shadow.subtle.color,
                    radius: DesignTokens.Shadow.subtle.radius,
                    y: DesignTokens.Shadow.subtle.y
                )
        )
    }

    // MARK: - Macro Card Helper
    private func redesignedMacroCard(label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(alignment: .bottom, spacing: 2) {
                Text(String(format: "%.0f", value))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(palette.textPrimary)
                Text("g")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(palette.textSecondary)
                    .padding(.bottom, 3)
            }
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(color.opacity(0.08))
        )
    }

    // MARK: - Nutrition Row Helper
    private func redesignedNutritionRow(_ label: String, value: Double) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(palette.textSecondary)
            Spacer()
            Text(String(format: "%.1fg", value))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(palette.textPrimary)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Per 100g Nutrition Row Helper
    private func per100gNutritionRow(_ label: String, value: Double, unit: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(palette.textSecondary)
            Spacer()
            Text(String(format: unit == "kcal" ? "%.0f" : "%.1f", value) + unit)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(palette.textTertiary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Redesigned Scores Section (Calm Insights)
    private var redesignedScoresSection: some View {
        let hasIngredients: Bool = {
            guard let ingredients = cachedIngredients else { return false }
            let clean = ingredients.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            return !clean.isEmpty
        }()
        let isPerUnitMode = displayFood.isPerUnit == true
        let isFastFood = isFastFoodBrand
        let gradeToShow = (hasIngredients && !isPerUnitMode && !isFastFood) ? nutraSafeGrade : nil

        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Processing score card
                if let ns = gradeToShow {
                    Button(action: { showingNutraSafeInfo = true }) {
                        redesignedScoreCard(
                            title: "Processing",
                            grade: ns.grade,
                            label: ns.label,
                            color: scoreColor(for: ns.grade)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Sugar score card
                if sugarScore.grade != .unknown {
                    Button(action: { showingSugarInfo = true }) {
                        redesignedScoreCard(
                            title: "Sugar",
                            grade: sugarScore.grade.rawValue,
                            label: sugarLabel(for: sugarScore.grade),
                            color: sugarScore.color
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            // Info tip
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb")
                    .font(.system(size: 14))
                    .foregroundColor(palette.accent)
                Text("A = closest to natural, F = heavily processed. Tap cards to learn more.")
                    .font(.system(size: 13))
                    .foregroundColor(palette.textSecondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(palette.accent.opacity(0.05))
            )
        }
    }

    // MARK: - Score Card Helper
    private func redesignedScoreCard(title: String, grade: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(palette.textTertiary)
                .tracking(0.5)

            Text(grade)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(palette.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(color.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .stroke(color.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Score Color Helper
    private func scoreColor(for grade: String) -> Color {
        switch grade.uppercased() {
        case "A+", "A": return SemanticColors.positive
        case "B": return SemanticColors.nutrient
        case "C", "D": return SemanticColors.neutral
        case "F": return SemanticColors.caution
        default: return palette.textTertiary
        }
    }

    // MARK: - Sugar Label Helper
    private func sugarLabel(for grade: SugarGrade) -> String {
        switch grade {
        case .excellent, .veryGood: return "Low Sugar"
        case .good: return "Moderate"
        case .moderate: return "High Sugar"
        case .high, .veryHigh: return "Very High"
        case .unknown: return "Unknown"
        }
    }

    // MARK: - Redesigned Watch Tabs (Pill Style)
    private var redesignedWatchTabs: some View {
        VStack(spacing: 0) {
            // Tab pills
            HStack(spacing: 8) {
                ForEach(WatchTab.allCases, id: \.self) { tab in
                    let isSelected = selectedWatchTab == tab
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedWatchTab = tab
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 12, weight: .semibold))
                            Text(tab.shortName)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(isSelected ? .white : palette.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(isSelected ? tab.color : palette.tertiary.opacity(0.1))
                        )
                    }
                }
            }
            .padding(.vertical, 14)

            // Tab content
            Group {
                switch selectedWatchTab {
                case .additives:
                    additivesContent
                case .allergies:
                    allergensContent
                case .vitamins:
                    redesignedVitaminsContent
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                .shadow(
                    color: DesignTokens.Shadow.subtle.color,
                    radius: DesignTokens.Shadow.subtle.radius,
                    y: DesignTokens.Shadow.subtle.y
                )
        )
    }

    // MARK: - Redesigned Vitamins Content
    private var redesignedVitaminsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if subscriptionManager.hasAccess {
                if !cachedDetectedNutrients.isEmpty {
                    ForEach(Array(cachedDetectedNutrients.prefix(8)), id: \.self) { nutrientName in
                        HStack {
                            Text(nutrientName)
                                .font(.system(size: 14))
                                .foregroundColor(palette.textPrimary)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(SemanticColors.nutrient)
                        }
                        .padding(.vertical, 6)
                    }

                    Button(action: { showingVitaminCitations = true }) {
                        HStack {
                            Image(systemName: "book.closed")
                                .font(.system(size: 12))
                            Text("View sources")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(palette.accent)
                    }
                    .padding(.top, 8)
                } else {
                    noIngredientDataView
                }
            } else {
                vitaminsLockedView
            }
        }
    }

    // MARK: - Vitamins Locked View
    var vitaminsLockedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 28))
                .foregroundColor(palette.textTertiary)
            Text("Unlock vitamin details")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(palette.textSecondary)
            Text("Subscribe to view detailed vitamin and mineral information")
                .font(.system(size: 13))
                .foregroundColor(palette.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 24)
    }

    // MARK: - Redesigned Ingredients Section
    var redesignedIngredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                if cachedIngredientsStatus == .verified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16))
                        .foregroundColor(SemanticColors.positive)
                }
                Text("Ingredients")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(palette.textPrimary)
                Spacer()
            }

            // Ingredients content
            if let ingredients = cachedIngredients, !ingredients.isEmpty {
                FlowingIngredientsView(
                    ingredients: ingredients.map { ingredient in
                        let formatted = ingredient.trimmingCharacters(in: .whitespacesAndNewlines)
                        let lowercased = formatted.lowercased()
                        let isConcerning = ["e1", "e2", "e3", "e4", "e5", "e6", "modified", "hydrogenated"].contains { lowercased.contains($0) }
                        let isAllergen = userAllergens.contains { allergen in
                            allergen.keywords.contains { lowercased.contains($0.lowercased()) }
                        }
                        return (formatted, isConcerning, isAllergen)
                    },
                    colorScheme: colorScheme,
                    userAllergens: userAllergens
                )
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 28))
                        .foregroundColor(palette.textTertiary)
                    Text("No ingredients available")
                        .font(.system(size: 14))
                        .foregroundColor(palette.textSecondary)

                    // AI estimate button
                    Button(action: estimateIngredientsWithAI) {
                        HStack(spacing: 6) {
                            if isEstimatingIngredients {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(isEstimatingIngredients ? "Estimating..." : "Estimate with AI")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [palette.accent, palette.primary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                    .disabled(isEstimatingIngredients)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                .shadow(
                    color: DesignTokens.Shadow.subtle.color,
                    radius: DesignTokens.Shadow.subtle.radius,
                    y: DesignTokens.Shadow.subtle.y
                )
        )
    }

    // MARK: - Redesigned Verification Section (Supportive Tone)
    private var redesignedVerificationSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "hand.raised.circle")
                    .font(.system(size: 28))
                    .foregroundColor(palette.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Something not right?")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(palette.textPrimary)
                    Text("Help us improve by reporting incorrect information")
                        .font(.system(size: 13))
                        .foregroundColor(palette.textSecondary)
                }

                Spacer()
            }

            Button(action: notifyTeamAboutIncompleteFood) {
                HStack(spacing: 6) {
                    if isNotifyingTeam {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "flag")
                    }
                    Text(isNotifyingTeam ? "Sending..." : "Report Issue")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(palette.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(palette.accent.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .stroke(palette.accent.opacity(0.2), lineWidth: 1)
                )
            }
            .disabled(isNotifyingTeam)
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                .shadow(
                    color: DesignTokens.Shadow.subtle.color,
                    radius: DesignTokens.Shadow.subtle.radius,
                    y: DesignTokens.Shadow.subtle.y
                )
        )
    }
}

// MARK: - WatchTab Extension for Short Names
extension FoodDetailViewFromSearch.WatchTab {
    var shortName: String {
        switch self {
        case .additives: return "Additives"
        case .allergies: return "Allergies"
        case .vitamins: return "Vitamins"
        }
    }
}

// MARK: - Health Claim Model
struct HealthClaim {
    let text: String
    let source: String
}

// MARK: - Scroll Dismiss Modifier for iOS Compatibility
struct ScrollDismissModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollDismissesKeyboard(.interactively)
        } else {
            content
        }
    }
}

// MARK: - NutraSafe Grade Info View (inline fallback)
struct NutraSafeGradeInfoView: View {
    let result: ProcessingScorer.NutraSafeProcessingGradeResult
    let food: FoodSearchResult
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    private func color(for grade: String) -> Color {
        switch grade.uppercased() {
        case "A", "A+": return .green
        case "B": return .mint
        case "C": return .orange
        case "D", "E", "F": return .red
        default: return .gray
        }
    }

    private var tips: [String] {
        var out: [String] = []
        if food.protein < 7 { out.append("Boost protein: add eggs, yogurt, lean meat, or legumes.") }
        if food.fiber < 3 { out.append("Add fiber: include whole grains, fruit, veg, or nuts.") }
        if food.sugar > 10 { out.append("Choose lower-sugar options or reduce sweet add-ons.") }
        if (food.ingredients?.count ?? 0) > 15 { out.append("Simplify: shorter ingredient lists often mean gentler processing.") }
        if (food.additives?.count ?? 0) > 0 { out.append("Prefer versions with fewer additives when possible.") }
        return out.isEmpty ? ["Enjoy in balanced portions and pair with whole foods."] : out
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center, spacing: 12) {
                        Text(result.grade)
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundColor(color(for: result.grade))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.label)
                                .font(.headline)
                            Text("NutraSafe Processing Grade")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(color(for: result.grade).opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(color(for: result.grade).opacity(0.2), lineWidth: 1)
                            )
                    )

                    Group {
                        Text("What this means")
                            .font(.headline)
                        Text(result.label)
                            .font(.callout)
                            .foregroundColor(.primary)
                    }

                    Group {
                        Text("How we calculate it")
                            .font(.headline)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Processing intensity: additives, industrial processes, and ingredient complexity.")
                            Text("• Nutrient integrity: balance of protein, fiber, sugar, and micronutrients.")
                            Text("• We combine these into a simple A–F grade for clarity.")
                        }
                        .font(.callout)
                        .foregroundColor(.secondary)
                    }

                    Group {
                        Text("Tips to improve similar foods")
                            .font(.headline)
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(tips, id: \.self) { tip in
                                Text("• \(tip)")
                            }
                        }
                        .font(.callout)
                        .foregroundColor(.secondary)
                    }

                    Group {
                        Text("Details")
                            .font(.headline)
                        Text(result.explanation)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }

                    // Citations Section
                    Group {
                        Text("Research Sources")
                            .font(.headline)
                            .padding(.top, 8)

                        Text("Food processing classification based on the NOVA system and nutritional science research:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)

                        ForEach(CitationManager.shared.citations(for: .foodProcessing)) { citation in
                            Button(action: {
                                if let url = URL(string: citation.url) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppPalette.standard.accent)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(citation.organization)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.primary)
                                        Text(citation.title)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppPalette.standard.accent)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(palette.tertiary.opacity(0.15))
                                .cornerRadius(10)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct SugarScoreInfoView: View {
    let score: SugarContentScore
    let food: FoodSearchResult
    let perServingSugar: Double
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    private func description(for grade: SugarGrade) -> String {
        switch grade {
        case .excellent, .veryGood:
            return "Low Sugar"
        case .good:
            return "Moderate Sugar"
        case .moderate:
            return "High Sugar"
        case .high, .veryHigh:
            return "Very High Sugar"
        case .unknown:
            return "Unknown"
        }
    }

    /// Check if this food is likely a whole fruit (not juice, dried fruit, or processed)
    private var isWholeFruit: Bool {
        let name = food.name.lowercased()
        let wholeFruits = ["apple", "banana", "orange", "pear", "peach", "plum", "grape", "grapes",
                          "strawberry", "strawberries", "blueberry", "blueberries", "raspberry", "raspberries",
                          "mango", "kiwi", "melon", "watermelon", "honeydew", "cantaloupe",
                          "cherry", "cherries", "apricot", "nectarine", "grapefruit", "tangerine",
                          "clementine", "satsuma", "papaya", "pineapple", "pomegranate", "passion fruit",
                          "lychee", "fig", "persimmon", "guava", "dragon fruit"]

        // Check if it's a whole fruit
        let isFruit = wholeFruits.contains { name.contains($0) }

        // Exclude processed versions
        let isProcessed = name.contains("juice") || name.contains("dried") || name.contains("jam") ||
                         name.contains("jelly") || name.contains("syrup") || name.contains("canned") ||
                         name.contains("yogurt") || name.contains("yoghurt") || name.contains("smoothie") ||
                         name.contains("ice cream") || name.contains("pie") || name.contains("tart") ||
                         name.contains("crumble") || name.contains("compote") || name.contains("preserve")

        return isFruit && !isProcessed
    }

    private var tips: [String] {
        var out: [String] = []

        if isWholeFruit {
            // Tips specific to whole fruits
            out.append("Whole fruit is a healthy choice - the fibre slows sugar absorption.")
            out.append("Eating fruit helps you get essential vitamins and antioxidants.")
            if food.sugar > 15 {
                out.append("Pair with protein (like nuts or yoghurt) if watching blood sugar.")
            }
        } else {
            // Standard tips for processed foods
            if food.sugar > 15 { out.append("Choose unsweetened versions or smaller portions.") }
            if food.sugar > 10 { out.append("Pair with protein or fibre to slow absorption.") }
            out.append("Watch added sugars like syrups and sweeteners.")
            out.append("Prefer whole foods: fruit, yoghurt, nuts, seeds.")
        }
        return out
    }

    /// Helper to create a section card
    @ViewBuilder
    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(palette.tertiary.opacity(0.15))
        )
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Header card - centered grade display
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(score.color.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Text(score.grade.rawValue)
                                .font(.system(size: 38, weight: .black, design: .rounded))
                                .foregroundColor(score.color)
                        }

                        Text(description(for: score.grade))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("Sugar Score")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(score.color.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(score.color.opacity(0.2), lineWidth: 1)
                            )
                    )

                    // Fruit context banner (if applicable)
                    if isWholeFruit {
                        HStack(spacing: 12) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 20))
                                .foregroundColor(SemanticColors.positive)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Natural Fruit Sugar")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
                                Text("Whole fruit contains natural sugars along with fibre, vitamins, and minerals. The fibre helps slow sugar absorption, making it a healthy choice.")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(SemanticColors.positive.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(SemanticColors.positive.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }

                    // What this means
                    sectionCard(title: "What This Means") {
                        Text(score.explanation)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Health impact & recommendation combined
                    sectionCard(title: "Health Impact") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(score.healthImpact)
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.secondary)

                            if !score.recommendation.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppPalette.standard.accent)
                                    Text(score.recommendation)
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundColor(.primary)
                                }
                                .padding(.top, 4)
                            }
                        }
                    }

                    // Show breakdown if both density and serving grades exist
                    if let servingGrade = score.servingGrade {
                        sectionCard(title: "Score Breakdown") {
                            VStack(spacing: 10) {
                                HStack {
                                    Text("Density (per 100g)")
                                        .font(.system(size: 14, design: .rounded))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(score.densityGrade.rawValue)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(score.densityGrade.color)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(score.densityGrade.color.opacity(0.15))
                                        )
                                }

                                Divider()

                                HStack {
                                    Text("Per serving")
                                        .font(.system(size: 14, design: .rounded))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(servingGrade.rawValue)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(servingGrade.color)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(servingGrade.color.opacity(0.15))
                                        )
                                }

                                Text("Final grade uses the worse of the two to account for large servings.")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                        }
                    }

                    // Tips section
                    sectionCard(title: isWholeFruit ? "About Fruit & Sugar" : "Tips for Similar Foods") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(tips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: isWholeFruit ? "checkmark.circle.fill" : "lightbulb.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(isWholeFruit ? .green : .orange)
                                        .frame(width: 18)
                                    Text(tip)
                                        .font(.system(size: 14, design: .rounded))
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    // How we calculate it
                    sectionCard(title: "How We Calculate It") {
                        VStack(alignment: .leading, spacing: 8) {
                            bulletPoint("Score based on both sugar density (per 100g) and actual serving size")
                            bulletPoint("Uses the worse of the two scores to warn about large servings")
                            bulletPoint("Thresholds align with NHS and WHO public health guidance")
                            bulletPoint("Helps you spot foods that pack a lot of sugar per serving")
                        }
                    }

                    // Details card
                    sectionCard(title: "Nutrition Details") {
                        VStack(spacing: 8) {
                            detailRow(label: "Sugar per 100g", value: "\(String(format: "%.1f", food.sugar))g")
                            if let servingSize = score.servingSizeG {
                                detailRow(label: "Serving size", value: "\(String(format: "%.0f", servingSize))g")
                            }
                            detailRow(label: "Sugar per serving", value: "\(String(format: "%.1f", perServingSugar))g")
                        }
                    }

                    // Citations section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Research Sources")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 4)

                        ForEach(CitationManager.shared.citations(for: .sugarSalt)) { citation in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(citation.organization)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppPalette.standard.accent)

                                Text(citation.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)

                                Text(citation.description)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Button(action: {
                                    if let url = URL(string: citation.url) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "link")
                                            .font(.system(size: 11, weight: .medium))
                                        Text("View Source")
                                            .font(.system(size: 12, weight: .medium))
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 10))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(AppPalette.standard.accent)
                                    )
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(palette.tertiary.opacity(0.15))
                            )
                        }

                        Text("Our sugar scoring is based on WHO and NHS dietary guidelines for sugar intake.")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(20)
            }
            .background(AppAnimatedBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.secondary)
            Text(text)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Barcode Scanner for Enhancement
struct BarcodeScannerForEnhancement: View {
    let onBarcodeScanned: (String) -> Void
    let onDismiss: () -> Void

    @State private var scannedCode: String?
    @State private var showingError = false

    var body: some View {
        NavigationView {
            VStack {
                if let code = scannedCode {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(SemanticColors.positive)

                        Text("Barcode Scanned")
                            .font(.title2.weight(.bold))

                        Text(code)
                            .font(.system(.title3, design: .monospaced))
                            .padding()
                            .background(AppPalette.standard.tertiary.opacity(0.1))
                            .cornerRadius(8)

                        Button(action: {
                            onBarcodeScanned(code)
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Search with this barcode")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppPalette.standard.accent)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                } else {
                    BarcodeScannerViewControllerRepresentable(
                        onBarcodeScanned: { code in
                            scannedCode = code
                        }
                    )
                    .edgesIgnoringSafeArea(.all)
                }
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
            }
            .alert("Scanner Error", isPresented: $showingError) {
                Button("OK") {
                    onDismiss()
                }
            } message: {
                Text("Unable to access camera. Please check permissions in Settings.")
            }
        }
    }
}

// MARK: - Barcode Scanner UIKit Wrapper (Reuses existing BarcodeScannerViewController from BarcodeScanningViews.swift)
struct BarcodeScannerViewControllerRepresentable: UIViewControllerRepresentable {
    let onBarcodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let scanner = BarcodeScannerViewController()
        scanner.onBarcodeScanned = onBarcodeScanned
        return scanner
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {
        // No updates needed
    }
}
