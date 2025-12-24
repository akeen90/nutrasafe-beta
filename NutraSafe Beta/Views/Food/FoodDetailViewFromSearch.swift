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

    // MARK: - Diary replacement support
    let diaryEntryId: UUID?
    let diaryMealType: String?
    let diaryQuantity: Double?
    let diaryDate: Date?

    init(food: FoodSearchResult, sourceType: FoodSourceType = .search, selectedTab: Binding<TabItem>, diaryEntryId: UUID? = nil, diaryMealType: String? = nil, diaryQuantity: Double? = nil, diaryDate: Date? = nil, onComplete: ((TabItem) -> Void)? = nil) {
        self.food = food
        self.sourceType = sourceType
        self._selectedTab = selectedTab
        self.diaryEntryId = diaryEntryId
        self.diaryMealType = diaryMealType
        self.diaryQuantity = diaryQuantity
        self.diaryDate = diaryDate
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
            // DEBUG LOG: print("🔧 INIT: Using servingSizeG: \(sizeG)g for \(food.name)")
            } else if let servingDesc = food.servingDescription {
                // Priority 2: Extract from serving description
            // DEBUG LOG: print("🔧 INIT: Parsing serving description: '\(servingDesc)' for \(food.name)")

                let patterns = [
                    #"(\d+(?:\.\d+)?)\s*g\s+serving"#,  // Match "150g serving"
                    #"\((\d+(?:\.\d+)?)\s*g\)"#,         // Match "(345 g)"
                    #"^(\d+(?:\.\d+)?)\s*g$"#,           // Match "345g"
                    #"^(\d+(?:\.\d+)?)\s+g$"#            // Match "345 g"
                ]

                for pattern in patterns {
                    if let regex = try? NSRegularExpression(pattern: pattern, options: []),
                       let match = regex.firstMatch(in: servingDesc, options: [], range: NSRange(location: 0, length: servingDesc.count)),
                       let range = Range(match.range(at: 1), in: servingDesc) {
                        initialServingSize = String(servingDesc[range])
            // DEBUG LOG: print("🔧 INIT: Extracted \(initialServingSize)g from '\(servingDesc)'")
                        break
                    }
                }
                // Fallback: description like "1 burger" → treat as per-unit
                if initialServingSize == "100" {
                    let lower = servingDesc.lowercased()
                    if lower.hasPrefix("1 ") {
                        let unitCandidate = lower.split(separator: " ").dropFirst().joined(separator: " ")
                        if !unitCandidate.isEmpty {
                            initialServingSize = "1"
                            initialUnit = String(unitCandidate)
                        }
                    } else {
                        // If description mentions a unit keyword and no grams were found
                        let unitWords = ["serving","piece","slice","burger","wrap","taco","burrito","sandwich","portion"]
                        if let found = unitWords.first(where: { lower.contains($0) }) {
                            initialServingSize = "1"
                            initialUnit = found
                        }
                    }
                }
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
            case .additives: return .purple
            case .allergies: return .red
            case .vitamins: return .green
            }
        }
    }
    
    private let mealOptions = ["Breakfast", "Lunch", "Dinner", "Snacks"]
    private let quantityOptions: [Double] = [0.5, 1.0, 2.0, 3.0, 4.0, 5.0]
    private let servingUnitOptions = ["g", "ml", "cup", "tbsp", "tsp", "oz", "serving", "piece", "slice", "burger"]

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
        // TODO: Fix when GlycemicIndexDatabase is available
        return nil
        // // Calculate GI based on actual macro data - much more accurate!
        // GlycemicIndexDatabase.shared.getGIData(
        //     for: food.name,
        //     carbs: adjustedCarbs,
        //     sugar: food.sugar * multiplier,
        //     fiber: food.fiber * multiplier,
        //     protein: adjustedProtein,
        //     fat: adjustedFat
        // )
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
            "vapors": "vapours"
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

        // Check if food is user-verified (photo taken by user)
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
                return .unverified  // Changed from .verified to .unverified
            }
        }

        // Food has nutrition data but no ingredients - still unverified
        if displayFood.calories > 0 || displayFood.protein > 0 || displayFood.carbs > 0 || displayFood.fat > 0 {
            return .unverified
        }

        return .none
    }
    
    private func getIngredientsList() -> [String]? {
        // DEBUG LOG: print("🔍 getIngredientsList() called")
        #if DEBUG
        print("  - enhancedIngredientsText: \(enhancedIngredientsText?.prefix(50) ?? "nil")")
        print("  - displayFood.ingredients: \(displayFood.ingredients?.count ?? 0) items")

        // PRIORITY 1: Check for AI-enhanced ingredients
        #endif
        if let enhancedText = enhancedIngredientsText, !enhancedText.isEmpty {
            // Split enhanced ingredients text into array
            let enhancedIngredients = enhancedText
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if !enhancedIngredients.isEmpty {
                #if DEBUG
                print("✨ Using AI-enhanced ingredients (\(enhancedIngredients.count) items)")
                #endif
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
            ("Gluten", ["wheat", "barley", "rye", "oats", "spelt", "kamut", "gluten", "flour", "bran", "semolina", "durum"]),
            ("Dairy", ["milk", "cream", "butter", "cheese", "yogurt", "lactose", "casein", "whey", "skimmed milk powder", "milk powder"]),
            ("Eggs", ["egg", "eggs", "albumin", "lecithin", "egg white", "egg yolk", "ovomucin"]),
            ("Nuts", ["almond", "hazelnut", "walnut", "cashew", "pistachio", "brazil nut", "macadamia", "pecan", "pine nut"]),
            ("Peanuts", ["peanut", "groundnut", "arachis oil", "peanut oil"]),
            ("Soy", ["soya", "soy", "soybean", "tofu", "tempeh", "miso", "soy lecithin", "soy protein"]),
            ("Fish", ["fish", "anchovy", "tuna", "salmon", "cod", "haddock", "fish oil", "worcestershire sauce"]),
            ("Shellfish", ["shellfish", "crab", "lobster", "prawn", "shrimp", "crayfish", "langoustine"]),
            ("Sesame", ["sesame", "tahini", "sesame oil", "sesame seed"]),
            ("Sulphites", ["sulphite", "sulfite", "sulphur dioxide", "sulfur dioxide", "e220", "e221", "e222", "e223", "e224", "e225", "e226", "e227", "e228"]),
            ("Celery", ["celery", "celeriac", "celery salt", "celery extract"]),
            ("Mustard", ["mustard", "mustard seed", "dijon", "wholegrain mustard"]),
            ("Lupin", ["lupin", "lupine", "lupin flour"]),
            ("Molluscs", ["mollusc", "mussel", "oyster", "clam", "scallop", "squid", "octopus", "snail"])
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
    // OPTIMIZED: Use cached allergens for instant loading
    private func loadAndDetectUserAllergensOptimized() async {
        // Get allergens from cache (instant if available)
        let savedAllergens = await firebaseManager.getUserAllergensWithCache()

        await MainActor.run {
            userAllergens = savedAllergens
            detectedUserAllergens = detectUserAllergensInFood(userAllergens: savedAllergens)
        }
    }

    // DEPRECATED: Old slow method - kept for reference
    private func loadAndDetectUserAllergens() async {
        do {
            let settings = try await firebaseManager.getUserSettings()
            let savedAllergens = settings.allergens ?? []

            await MainActor.run {
                userAllergens = savedAllergens
                detectedUserAllergens = detectUserAllergensInFood(userAllergens: savedAllergens)
            }
        } catch {
            #if DEBUG
            print("Failed to load user allergens: \(error.localizedDescription)")
            #endif
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

    // MARK: - Allergen Warning Banner View
    private var allergenWarningBanner: some View {
        VStack(alignment: .center, spacing: 12) {
            // Header with warning icons on both sides
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Text("ALLERGEN WARNING")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }

            // Warning message
            Text("This food contains allergens you've marked:")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)

            // List of detected allergens in a centered wrapping layout
            HStack(spacing: 8) {
                Spacer(minLength: 0)
                ForEach(detectedUserAllergens, id: \.rawValue) { allergen in
                    Text(allergen.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(16)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.red, Color.orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
    }


    private func getDetectedAdditives() -> [DetailedAdditive] {
        #if DEBUG
        print("getDetectedAdditives: displayFood.additives = \(String(describing: displayFood.additives))")
        print("getDetectedAdditives: displayFood.name = \(displayFood.name)")
        print("getDetectedAdditives: displayFood.calories = \(displayFood.calories)")

        // Check if we need to re-analyze due to outdated database version
        #endif
        let currentDBVersion = ProcessingScorer.shared.databaseVersion
        let savedDBVersion = displayFood.additivesDatabaseVersion

        // DEBUG LOG: print("📊 Database versions - Current: \(currentDBVersion), Saved: \(savedDBVersion ?? "nil (legacy)")")

        // Re-analyze if:
        // 1. No saved version (legacy data)
        // 2. Saved version is different from current version
        // 3. We have ingredients to analyze
        let hasIngredients = displayFood.ingredients != nil && !displayFood.ingredients!.isEmpty
        let needsReAnalysis = (savedDBVersion == nil || savedDBVersion != currentDBVersion) && hasIngredients

        if needsReAnalysis {
        // DEBUG LOG: print("🔄 RE-ANALYZING: Database version outdated or missing")
            #if DEBUG
            print("   - Saved version: \(savedDBVersion ?? "none")")
            print("   - Current version: \(currentDBVersion)")
            print("   - Ingredients available: \(displayFood.ingredients?.count ?? 0)")

            // Perform fresh analysis with current database
            #endif
            let ingredientsText = displayFood.ingredients!.joined(separator: ", ")
            let freshAdditives = ProcessingScorer.shared.analyzeAdditives(in: ingredientsText)

        // DEBUG LOG: print("🔄 Fresh analysis complete: Found \(freshAdditives.count) additives")

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
            #if DEBUG
            print("getDetectedAdditives: Using saved data - \(firebaseAdditives.count) additives")
            #endif
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
        VStack(spacing: 12) {
            // Small verification status at top
            verificationStatusView

            // Allergen Warning - Show above product name if allergens detected
            if !detectedUserAllergens.isEmpty {
                allergenWarningBanner
            }

            Text(displayFood.name)
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)

            if let brand = displayFood.brand {
                Text(brand)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var verificationStatusView: some View {
        // PERFORMANCE: Use cached ingredients status
        let ingredientsStatus = cachedIngredientsStatus ?? .none

        // Check if food has been AI enhanced - hide badge if so
        let hasAIEnhancement = enhancedIngredientsText != nil || enhancedNutrition != nil

        return Group {
            if hasAIEnhancement {
                // AI-enhanced foods show no badge at all
                EmptyView()
            } else {
                HStack(spacing: 6) {
                    switch ingredientsStatus {
                    case .verified:
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        Text("Verified")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)

                    case .userVerified:
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                        Text("User Verified")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)

                    case .clientVerified:
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text("User Verified")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)

                    case .unverified, .none, .pending:
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                        Text("Unverified")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    foodHeaderView

                    // Serving and Meal Controls Section
                    servingControlsSection
                        .onAppear {
                            // Only auto-detect grams for non per-unit foods
                            if !isPerUnit, servingAmount == "1" && servingUnit == "g" {
                                // PRIORITY 1: Use servingSizeG if available (most reliable)
                                if let sizeG = food.servingSizeG, sizeG > 0 {
        // DEBUG LOG: print("🔧 Using servingSizeG: \(sizeG)g")
                                    servingAmount = String(format: "%.0f", sizeG)
                                    servingUnit = "g"
                                    gramsAmount = String(format: "%.0f", sizeG)  // Also update gramsAmount
                                } else {
                                    // PRIORITY 2: Extract from serving description
                                    let description = food.servingDescription ?? "100g"
        // DEBUG LOG: print("🔧 Parsing serving description: '\(description)'")

                                    // Try to extract grams from multiple patterns
                                    let patterns = [
                                        #"(\d+(?:\.\d+)?)\s*g\s+serving"#,  // Match "150g serving"
                                        #"\((\d+(?:\.\d+)?)\s*g\)"#,         // Match "(345 g)" in parentheses
                                        #"^(\d+(?:\.\d+)?)\s*g$"#,           // Match "345g" at start
                                        #"^(\d+(?:\.\d+)?)\s+g$"#            // Match "345 g" at start with space
                                    ]

                                    var found = false
                                    for pattern in patterns {
                                        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
                                           let match = regex.firstMatch(in: description, options: [], range: NSRange(location: 0, length: description.count)),
                                           let range = Range(match.range(at: 1), in: description) {
                                            let extractedValue = String(description[range])
        // DEBUG LOG: print("🔧 Extracted serving size: \(extractedValue)g")
                                            servingAmount = extractedValue
                                            servingUnit = "g"
                                            gramsAmount = extractedValue  // Also update gramsAmount
                                            found = true
                                            break
                                        }
                                    }

                                    // PRIORITY 3: If nothing found, attempt per-unit detection before defaulting to grams
                                    if !found {
                                        #if DEBUG
                                        print("⚠️ No serving size found in grams, attempting per-unit detection")
                                        #endif
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
                                            servingUnit = "g"
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
                    
                    // Nutrition information first
                    nutritionFactsSection
                    
                    // Food Scores Section (moved from header)
                    foodScoresSection
                        .id(servingAmount) // Force re-render when serving amount changes (for real-time sugar score updates)
                    
                    // Combined Watch Sections with Tabs
                    watchTabsSection
                    
                    // Ingredients section immediately after nutrition 
                    ingredientsSection

                    // Photo prompts and improvement section right after ingredients (PERFORMANCE: use cached status)
                    let ingredientsStatus = cachedIngredientsStatus ?? .none
                    if ingredientsStatus == .unverified || ingredientsStatus == .none {
                        ingredientVerificationSection
                    } else if ingredientsStatus == .pending {
                        ingredientInReviewSection
                    }
                    
                    
                }
                .padding(.horizontal, 16)
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
        .background(colorScheme == .dark ? Color.midnightBackground : Color(.systemBackground))
        .onAppear {
            // Only initialize once per view instance, even if .onAppear is called multiple times
            guard !hasInitialized else { return }
            hasInitialized = true

            cachedIngredients = food.ingredients
            recomputeDetectedNutrients()

            // Load user allergens from cache (instant) and detect if present in this food
            Task {
                await loadAndDetectUserAllergensOptimized()
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
        .id("\(enhancedIngredientsText ?? "")\(enhancedNutrition?.calories ?? 0)")
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
        .alert("Enhanced with AI", isPresented: $showingEnhancementSuccess) {
            Button("OK") { }
        } message: {
            Text("Successfully found enhanced ingredient information! The ingredients list and nutritional analysis have been updated with more detailed information from UK supermarket databases.")
        }
        .alert("Enhancement Failed", isPresented: $showingEnhancementError) {
            Button("OK") { }
        } message: {
            Text(enhancementErrorMessage)
        }
        .sheet(isPresented: $showingNutritionCamera) {
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
        .sheet(isPresented: $showingBarcodeCamera) {
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
        .sheet(isPresented: $showingUseByAddSheet) {
            // Reuse UseBy add sheet for details like expiry/location
            AddFoundFoodToUseBySheet(food: food) { tab in
                selectedTab = tab
                dismiss()
            }
        }
        .sheet(isPresented: $showingNutraSafeInfo) {
            NutraSafeGradeInfoView(result: nutraSafeGrade, food: displayFood)
        }
        .sheet(isPresented: $showingSugarInfo) {
            SugarScoreInfoView(
                score: sugarScore,
                food: displayFood,
                perServingSugar: displayFood.sugar * perServingMultiplier * quantityMultiplier
            )
        }
        .sheet(isPresented: $showingVitaminCitations) {
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
                                        .foregroundColor(.blue)
                                    Text(citation.organization)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.caption)
                                        .foregroundColor(.blue)
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
        .sheet(isPresented: $showingAllergenCitations) {
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
                                        .foregroundColor(.blue)
                                    Text(citation.organization)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.caption)
                                        .foregroundColor(.blue)
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
        .sheet(isPresented: $showingBarcodeScannerForEnhancement) {
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
        .sheet(isPresented: $showingManualSearchForEnhancement) {
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
                            Image(systemName: "sparkles")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            Text("Enter the food and brand name to search with AI")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.blue)
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
                        .background(manualSearchText.isEmpty ? Color.gray : Color.blue)
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
        adjustedFiber: adjustedFiber,
        adjustedSugar: adjustedSugar,
        adjustedSalt: adjustedSalt,
        per100Protein: displayFood.protein,
        per100Carbs: displayFood.carbs,
        per100Fat: displayFood.fat,
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
                .fill(Color(.systemBackground))
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
        #if DEBUG
        print("🍔 Adding \(food.name) to food log")

        // Calculate actual serving calories and macros based on user selections
        #endif
        let servingSize = actualServingSize
        #if DEBUG
        print("🍔 servingAmount: '\(servingAmount)', servingUnit: '\(servingUnit)'")
        print("🍔 actualServingSize: \(servingSize)g")
        print("🍔 quantityMultiplier: \(quantityMultiplier)")
        print("🍔 isPerUnit: \(food.isPerUnit ?? false)")
        #endif

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
        // DEBUG LOG: print("📝 Creating DiaryFoodItem:")
        #if DEBUG
        print("  - displayFood.ingredients: \(displayFood.ingredients?.count ?? 0) items")
        print("  - displayFood.ingredients: \(displayFood.ingredients ?? [])")
        print("  - displayFood.additives: \(displayFood.additives?.count ?? 0) items")
        print("  - displayFood.barcode: \(displayFood.barcode ?? "nil")")

        // Use existing diary entry ID if replacing, otherwise create new ID
        #endif
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
            additives: displayFood.additives,
            barcode: displayFood.barcode,
            micronutrientProfile: nil,  // FIX: Don't save fake macro-based estimates
            isPerUnit: food.isPerUnit
        )

        #if DEBUG
        print("📝 Created DiaryFoodItem:")
        print("  - diaryEntry.id: \(diaryEntry.id)")
        print("  - diaryEntry.servingDescription: '\(diaryEntry.servingDescription)'")
        print("  - diaryEntry.quantity: \(diaryEntry.quantity)")
        print("  - diaryEntry.calories: \(diaryEntry.calories)")
        print("  - diaryEntry.ingredients: \(diaryEntry.ingredients?.count ?? 0) items")

        // Add to diary (diary-only view)
        #endif
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
                #if DEBUG
                print("  - diaryEntryId exists (editing mode)")
                print("  - originalMealType: '\(originalMealType)'")
                print("  - selectedMeal: '\(selectedMeal)'")
                print("FoodDetailView: DiaryEntry details - Calories: \(diaryEntry.calories), Protein: \(diaryEntry.protein), Serving: \(diaryEntry.servingDescription), Quantity: \(diaryEntry.quantity)")

                #endif
                Task {
                    do {
                        // Decide: move across meals or replace within the same meal
                        if originalMealType.lowercased() != selectedMeal.lowercased() {
                            #if DEBUG
                            print("FoodDetailView: Moving food to new meal: \(selectedMeal)")
                            #endif
                            try await diaryDataManager.moveFoodItem(diaryEntry, from: originalMealType, to: selectedMeal, for: targetDate)
                            #if DEBUG
                            print("FoodDetailView: Successfully moved \(diaryEntry.name) to \(selectedMeal) on \(targetDate)")
                            #endif
                        } else {
                            #if DEBUG
                            print("FoodDetailView: Replacing within same meal: \(selectedMeal)")
                            #endif
                            try await diaryDataManager.replaceFoodItem(diaryEntry, to: selectedMeal, for: targetDate)
                            #if DEBUG
                            print("FoodDetailView: Successfully replaced \(diaryEntry.name) in \(selectedMeal) on \(targetDate)")
                            #endif
                        }

                        await MainActor.run {
                            // Dismiss keyboard before closing view
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            dismiss()
                            onComplete?(.diary)
                        }
                    } catch {
                        #if DEBUG
                        print("FoodDetailView: Error updating food: \(error.localizedDescription)")
                        #endif
                        await MainActor.run { dismiss() }
                    }
                }
            } else {
                // Adding new food item - await completion before dismissing
                #if DEBUG
                print("  - NO diaryEntryId (adding new)")
                print("  - selectedMeal: '\(selectedMeal)'")
                print("FoodDetailView: About to add food '\(diaryEntry.name)' to meal '\(selectedMeal)' on date '\(targetDate)'")
                print("FoodDetailView: DiaryEntry details - Calories: \(diaryEntry.calories), Protein: \(diaryEntry.protein), Serving: \(diaryEntry.servingDescription), Quantity: \(diaryEntry.quantity)")
                #endif

                Task {
                    await diaryDataManager.addFoodItem(diaryEntry, to: selectedMeal, for: targetDate)
                    #if DEBUG
                    print("FoodDetailView: Successfully added \(diaryEntry.name) to \(selectedMeal) on \(targetDate)")
                    #endif
                    await MainActor.run {
                        // Dismiss keyboard before closing view
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        dismiss()
                        onComplete?(.diary)
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

    // Fetch complete nutrition data from Firebase when editing old items with missing data
    // REMOVED: fetchEnrichedFoodData() - unnecessary since search already returns complete data
    // The food parameter already has all ingredients, additives, and nutrition data from Firebase search
    
    private var ingredientsSection: some View {
        IngredientsSectionView(status: cachedIngredientsStatus, ingredients: cachedIngredients)
    }

    struct NutritionFactsSectionView: View {
        let adjustedCalories: Double
        let quantityMultiplier: Double
        let servingSizeText: String
        let per100Calories: Double
        let adjustedProtein: Double
        let adjustedCarbs: Double
        let adjustedFat: Double
        let adjustedFiber: Double
        let adjustedSugar: Double
        let adjustedSalt: Double
        let per100Protein: Double
        let per100Carbs: Double
        let per100Fat: Double
        let per100Fiber: Double
        let per100Sugar: Double
        let per100Salt: Double
        let isPerUnit: Bool
        let servingUnitLabel: String

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
                            .fill(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color(.systemGray4), lineWidth: 1.5)
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
                        row("Fibre", adjustedFiber, per100Fiber, "g")
                        row("Sugar", adjustedSugar, per100Sugar, "g")
                        row("Salt", adjustedSalt, per100Salt, "g")
                    }
                    .padding(.bottom, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(Color(.systemGray6))
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
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    struct IngredientsSectionView: View {
        @Environment(\.colorScheme) var colorScheme
        let status: IngredientsStatus?
        let ingredients: [String]?

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    if status == .pending {
                        Text("⏳ Awaiting Verification")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(6)
                        Spacer()
                    }
                    Text("Ingredients")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    if status == .pending {
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(colorScheme == .dark ? Color.midnightCard : Color.white)
                .overlay(
                    Rectangle().frame(height: 2).foregroundColor(colorScheme == .dark ? Color.gray.opacity(0.3) : .black),
                    alignment: .bottom
                )
                if let ingredientsList = ingredients {
                    let clean = ingredientsList
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                        .joined(separator: ", ")
                    Text(clean.isEmpty ? "No ingredients found" : clean)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(colorScheme == .dark ? Color.midnightCard : Color.white)
                } else {
                    VStack(alignment: .center, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .font(.system(size: 18))
                        Text("Ingredients information not available")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(colorScheme == .dark ? Color.midnightCard : Color.white)
                }
            }
            .background(colorScheme == .dark ? Color.midnightCard : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.black, lineWidth: 2)
            )
            .padding(.horizontal, 16)
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
                                .foregroundColor(.orange)
                                .font(.system(size: 14))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Child Activity Warning")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.orange)
                                Text("Contains additives that may affect activity and attention in children")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                                    .lineLimit(nil)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(Color.orange.opacity(0.05))
                        .cornerRadius(8)
                    }

                    // Show allergen warnings (already pre-sorted above)
                    if !detectedAllergens.isEmpty {
                        ForEach(detectedAllergens, id: \.rawValue) { allergen in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("Contains \(allergen.displayName)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    } else {
                        if additiveAnalysis?.hasChildConcernAdditives != true {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("No allergens or child-concern additives detected")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.green)
                                Spacer()
                            }
                        } else {
                            Text("No common allergens detected")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
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
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // REMOVED: Old micronutrientsSection - replaced with vitaminsContent using NutrientDetector
    
    // REMOVED: Old fake micronutrient functions that relied on currentMicronutrients variable
    // Now we use NutrientDetector to detect from ingredients instead of fake math
    
    private func detectAllergens(in ingredients: [String]) -> [Allergen] {
        let combinedIngredients = ingredients.joined(separator: " ").lowercased()
        var detectedAllergens: [Allergen] = []

        // Check for common allergens using the enum cases
        let allergenChecks: [(Allergen, [String])] = [
            (.dairy, ["milk", "cheese", "butter", "cream", "yogurt", "whey", "casein", "lactose"]),
            (.eggs, ["egg", "albumin", "mayonnaise"]),
            (.fish, ["fish", "salmon", "tuna", "cod", "haddock", "anchovy"]),
            (.shellfish, ["shrimp", "crab", "lobster", "prawn", "crayfish"]),
            (.treeNuts, ["almond", "cashew", "walnut", "pecan", "pistachio", "hazelnut", "macadamia"]),
            (.peanuts, ["peanut", "groundnut"]),
            (.wheat, ["wheat", "flour", "bread"]),
            (.gluten, ["gluten"]),
            (.soy, ["soy", "soya", "tofu", "edamame"]),
            (.sesame, ["sesame", "tahini"])
        ]

        for (allergen, searchTerms) in allergenChecks {
            if searchTerms.contains(where: { combinedIngredients.contains($0) }) {
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
                    .foregroundColor(.orange)

                Text("Something not looking right?")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Enhance this product with AI to get more accurate nutritional data, or notify our team to review it.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    // Enhance with AI Button
                    Button(action: {
                        showingManualSearchForEnhancement = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16))
                            Text("Enhance with AI")
                                .font(.system(size: 14, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.purple)
                        .cornerRadius(10)
                    }
                    .disabled(isEnhancing)

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
                        .background(isNotifyingTeam ? Color.gray : Color.orange)
                        .cornerRadius(10)
                    }
                    .disabled(isNotifyingTeam)
                }
            }
            .padding(16)
            .background(Color.orange.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var ingredientInReviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
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
                    .foregroundColor(.blue)
                Text("Review typically takes 24-48 hours")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(.blue.opacity(0.05))
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
                #if DEBUG
                print("Error notifying team: \(error)")
                #endif
                await MainActor.run {
                    isNotifyingTeam = false
                    notificationErrorMessage = "Unable to send notification. Please try again later."
                    showingNotificationError = true
                }
            }
        }
    }

    // Enhance food data using barcode scan
    private func enhanceWithBarcode(_ barcode: String) {
        isEnhancing = true
        #if DEBUG
        print("📱 Starting barcode enhancement for: \(barcode)")

        #endif
        Task {
            do {
                // Call the AI ingredient finder service with barcode
                let result = try await IngredientFinderService.shared.findIngredients(
                    productName: food.name,
                    brand: food.brand,
                    barcode: barcode
                )

        // DEBUG LOG: print("🔍 AI Search Result:")
                #if DEBUG
                print("  - ingredients_found: \(result.ingredients_found)")
                print("  - ingredients_text: \(result.ingredients_text?.prefix(50) ?? "nil")")
                print("  - nutrition: \(result.nutrition_per_100g != nil ? "YES" : "NO")")
                print("  - serving_size_g: \(result.serving_size_g != nil ? "\(result.serving_size_g!)g" : "NIL")")
                print("  - size_description: \(result.size_description ?? "NIL")")
                print("  - product_name: \(result.product_name ?? "nil")")
                print("  - brand: \(result.brand ?? "nil")")
                print("  - source_url: \(result.source_url ?? "nil")")

                // Save to Firebase AI-improved foods collection (outside MainActor)
                #endif
                if result.ingredients_found {
        // DEBUG LOG: print("💾 Saving AI-improved food to Firebase")
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
                        let savedId = try await firebaseManager.saveAIImprovedFood(
                            originalFood: food,
                            enhancedData: enhancedData
                        )
                        #if DEBUG
                        print("✅ AI-improved food saved with ID: \(savedId)")
                        #endif
                    } catch {
                        #if DEBUG
                        print("⚠️ Failed to save AI-improved food to Firebase: \(error)")
                        // Continue anyway - the UI enhancement still works
                        #endif
                    }
                }

                await MainActor.run {
                    isEnhancing = false

                    if result.ingredients_found {
                        // Store enhanced ingredients
                        if let ingredientsText = result.ingredients_text {
                            #if DEBUG
                            print("✅ AI found enhanced ingredients: \(ingredientsText.prefix(100))...")
                            #endif
                            enhancedIngredientsText = ingredientsText
        // DEBUG LOG: print("📝 enhancedIngredientsText is now: \(enhancedIngredientsText?.prefix(50) ?? "nil")")
                        } else {
                            #if DEBUG
                            print("⚠️ No ingredients_text in result")
                            #endif
                        }

                        // Store enhanced nutrition data
                        if let nutrition = result.nutrition_per_100g {
                            #if DEBUG
                            print("✅ AI found enhanced nutrition data:")
                            print("  - calories: \(nutrition.calories ?? 0)")
                            print("  - protein: \(nutrition.protein ?? 0)")
                            print("  - carbs: \(nutrition.carbs ?? 0)")
                            #endif
                            enhancedNutrition = nutrition
                        } else {
                            #if DEBUG
                            print("⚠️ No nutrition_per_100g in result")
                            #endif
                        }

                        // Store enhanced product details
                        enhancedProductName = result.product_name
                        enhancedBrand = result.brand
                        #if DEBUG
                        print("📦 Product details: name=\(result.product_name ?? "nil"), brand=\(result.brand ?? "nil")")

                        // Update serving size if found (using numeric field with validation)
                        print("🔎 Checking serving size: result.serving_size_g = \(result.serving_size_g != nil ? "\(result.serving_size_g!)g" : "NIL")")
                        #endif
                        if let servingSizeGrams = result.serving_size_g {
                            // Validate that serving size is reasonable (not product size)
                            if servingSizeGrams > 0 && servingSizeGrams <= 500 {
                                servingAmount = String(format: "%.0f", servingSizeGrams)
                                servingUnit = "g"
                                gramsAmount = String(format: "%.0f", servingSizeGrams)
                                #if DEBUG
                                print("✅ Using AI serving size: \(servingSizeGrams)g")
                                #endif
                            } else {
                                // Unreasonable serving size, default to 100g
                                servingAmount = "100"
                                servingUnit = "g"
                                gramsAmount = "100"
                                #if DEBUG
                                print("⚠️ AI serving size (\(servingSizeGrams)g) seems unreasonable, defaulting to 100g")
                                #endif
                            }
                        } else {
                            // No serving size from AI, keep existing or default to 100g
                            #if DEBUG
                            print("ℹ️ No serving size from AI, keeping current: \(servingAmount)\(servingUnit)")
                            #endif
                        }

                        // Trigger UI refresh
        // DEBUG LOG: print("🔄 Triggering UI refresh")
                        refreshTrigger = UUID()

                        #if DEBUG
                        print("✨ Enhancement complete! Showing success alert")
                        #endif
                        showingEnhancementSuccess = true
                    } else {
                        #if DEBUG
                        print("⚠️ AI could not find enhanced ingredients")
                        #endif
                        enhancementErrorMessage = "Could not find enhanced ingredient information. The product might not be in our UK supermarket database."
                        showingEnhancementError = true
                    }
                }

            } catch {
                #if DEBUG
                print("❌ Error enhancing with AI: \(error)")
                #endif
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
        #if DEBUG
        print("🔍 Starting manual search enhancement for: \(searchTerm)")

        #endif
        Task {
            do {
                // Call the AI ingredient finder service with custom search term
                let result = try await IngredientFinderService.shared.findIngredients(
                    productName: searchTerm,
                    brand: nil, // User provides the full search term
                    barcode: nil
                )

                #if DEBUG
                print("🔍 Manual Search Result:")
                print("  - ingredients_found: \(result.ingredients_found)")
                print("  - ingredients_text: \(result.ingredients_text?.prefix(50) ?? "nil")")
                print("  - nutrition: \(result.nutrition_per_100g != nil ? "YES" : "NO")")

                // Save to Firebase AI-improved foods collection (outside MainActor)
                #endif
                if result.ingredients_found {
                    #if DEBUG
                    print("💾 Saving manually searched food to Firebase")
                    #endif
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
                        let savedId = try await firebaseManager.saveAIImprovedFood(
                            originalFood: food,
                            enhancedData: enhancedData
                        )
                        #if DEBUG
                        print("✅ Manually searched food saved with ID: \(savedId)")
                        #endif
                    } catch {
                        #if DEBUG
                        print("⚠️ Failed to save manually searched food to Firebase: \(error)")
                        #endif
                    }
                }

                await MainActor.run {
                    isEnhancing = false

                    if result.ingredients_found {
                        // Store enhanced ingredients
                        if let ingredientsText = result.ingredients_text {
                            #if DEBUG
                            print("✅ Manual search found enhanced ingredients: \(ingredientsText.prefix(100))...")
                            #endif
                            enhancedIngredientsText = ingredientsText
                        }

                        // Store enhanced nutrition data
                        if let nutrition = result.nutrition_per_100g {
                            #if DEBUG
                            print("✅ Manual search found enhanced nutrition data")
                            #endif
                            enhancedNutrition = nutrition
                        }

                        // Store enhanced product details
                        enhancedProductName = result.product_name
                        enhancedBrand = result.brand

                        // Trigger UI refresh
                        refreshTrigger = UUID()

                        #if DEBUG
                        print("✨ Manual search enhancement complete! Showing success alert")
                        #endif
                        showingEnhancementSuccess = true
                    } else {
                        #if DEBUG
                        print("⚠️ Manual search could not find enhanced ingredients")
                        #endif
                        enhancementErrorMessage = "Could not find product with this search term. Try different keywords."
                        showingEnhancementError = true
                    }
                }

            } catch {
                #if DEBUG
                print("❌ Error with manual search: \(error)")
                #endif
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
                    #if DEBUG
                    print("❌ Invalid URL for food profile processing: \(urlString)")
                    #endif
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
                                #if DEBUG
                                print("Error storing ingredients: \(error)")
                                #endif
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
                #if DEBUG
                print("Error submitting complete food profile: \(error)")
                #endif
                await MainActor.run {
                    isSubmittingCompleteProfile = false
                }
            }
        }
    }
    
    // Extract ingredients using intelligent Gemini AI and update app immediately
    private func extractAndAnalyzeIngredients(from image: UIImage, for food: FoodSearchResult) async {
        #if DEBUG
        print("🧠 Starting intelligent ingredient extraction with Gemini AI...")
        
        #endif
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            #if DEBUG
            print("❌ Failed to convert image to JPEG data")
            #endif
            return
        }
        
        let base64String = imageData.base64EncodedString()
        
        // Call our intelligent extraction Firebase function via URLSession
        guard let url = URL(string: "https://us-central1-nutrasafe-705c7.cloudfunctions.net/extractIngredientsWithAI") else {
            #if DEBUG
            print("❌ Invalid URL for extractIngredientsWithAI")
            #endif
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
                    
                    #if DEBUG
                    print("✅ Intelligent extraction completed:")
        // DEBUG LOG: print("📝 Ingredients: \(cleanIngredientsText)")
                    print("⚠️ Detected allergens: \(detectedAllergens.joined(separator: ", "))")
                    
                    // Trigger nutrition score recalculation with new ingredients
                    #endif
                    Task {
                        await recalculateNutritionScore(with: extractedIngredients)
                    }
                }
            }
            
        } catch {
            #if DEBUG
            print("❌ Error calling intelligent extraction function: \(error)")
            
            // Fallback to simple Vision OCR if Gemini fails
            #endif
            await fallbackVisionExtraction(from: image, for: food)
        }
    }
    
    // Fallback Vision OCR method (simplified version)
    private func fallbackVisionExtraction(from image: UIImage, for food: FoodSearchResult) async {
        #if DEBUG
        print("⚠️ Using fallback Vision OCR...")
        
        #endif
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
                    #if DEBUG
                    print("✅ Fallback extraction: \(extractedText)")
                    #endif
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
        // DEBUG LOG: print("🔄 Recalculating nutrition score with user-verified ingredients...")

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
        #if DEBUG
        print("✅ Nutrition score recalculated successfully")

        // Force UI refresh immediately so user sees the updated nutrition score
        #endif
        await MainActor.run {
            refreshTrigger = UUID()
        // DEBUG LOG: print("🔄 UI refresh triggered - nutrition score should now reflect user-verified ingredients")
        }
    }
    
    // MARK: - Serving Controls Section
    private var servingControlsSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("SERVING SIZE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(0.5)

                if isPerUnit {
                    // Per-unit food: show fixed unit name (no editing)
                    Text(servingUnit)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(8)
                } else {
                    // Per-100g food: show editable amount and unit picker
                    HStack(spacing: 8) {
                        TextField("100", text: $servingAmount)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 14, weight: .medium))
                            .frame(maxWidth: 80)
                        Menu {
                            ForEach(servingUnitOptions, id: \.self) { unit in
                                Button(unit) {
                                    if let currentValue = Double(servingAmount) {
                                        let convertedValue = convertUnit(value: currentValue, from: servingUnit, to: unit)
                                        servingAmount = String(format: "%.1f", convertedValue)
                                    }
                                    servingUnit = unit
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(servingUnit)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .fixedSize(horizontal: true, vertical: false)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                Text("QUANTITY")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(0.5)

                VStack(spacing: 12) {
                    // Mode picker
                    Picker("Input Mode", selection: $quantityInputMode) {
                        ForEach(QuantityInputMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: quantityInputMode) { _, newMode in
                        // Convert between modes
                        if newMode == .fraction {
                            // Converting from decimal to fraction
                            quantityFraction = Fraction.closestFraction(to: quantityMultiplier)
                            quantityMultiplier = quantityFraction.decimalValue
                        } else {
                            // Converting from fraction to decimal
                            quantityDecimalText = String(format: "%.2f", quantityMultiplier)
                        }
                    }

                    // Input controls based on mode
                    if quantityInputMode == .decimal {
                        // Decimal input with keypad
                        HStack(spacing: 8) {
                            TextField("1.0", text: $quantityDecimalText)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 16, weight: .medium))
                                .frame(maxWidth: 100)
                                .onChange(of: quantityDecimalText) { _, newValue in
                                    if let value = Double(newValue), value > 0 {
                                        quantityMultiplier = value
                                    }
                                }
                            Text("servings")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        // Fraction picker with roller
                        Picker("Quantity", selection: $quantityFraction) {
                            ForEach(Fraction.commonFractions) { fraction in
                                Text(fraction.displayString).tag(fraction)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 100)
                        .clipped()
                        .onChange(of: quantityFraction) { _, newFraction in
                            quantityMultiplier = newFraction.decimalValue
                            quantityDecimalText = String(format: "%.2f", newFraction.decimalValue)
                        }
                    }
                }
            }
            if sourceType != .useBy {
                VStack(alignment: .leading, spacing: 8) {
                    Text("MEAL TIME")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                        .tracking(0.5)
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
                                        RoundedRectangle(cornerRadius: 16).fill(selectedMeal == meal ? .blue : Color.gray.opacity(0.15))
                                    )
                            }
                        }
                        Spacer()
                    }
                }
            }
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
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
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

        private func color(for grade: String) -> Color {
            switch grade {
            case "A+", "A": return .green
            case "B": return .yellow
            case "C", "D": return .orange
            case "F": return .red
            default: return .gray
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
            HStack(spacing: 12) {
                if let ns = ns {
                    Button(action: { showingInfo = true }) {
                        VStack(spacing: 6) {
                            Text("NUTRASAFE GRADE")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                                .tracking(0.5)
                            Text(ns.grade)
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundColor(color(for: ns.grade))
                            Text(ns.label)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(color(for: ns.grade).opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(color(for: ns.grade).opacity(0.2), lineWidth: 1)
                            )
                    )
                }

                if let s = sugarScore, s.grade != .unknown {
                    Button(action: { showingSugarInfo = true }) {
                        VStack(spacing: 6) {
                            Text("SUGAR SCORE")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                                .tracking(0.5)
                            Text(s.grade.rawValue)
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundColor(s.color)
                            Text(sugarDescription(for: s.grade))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(s.color.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(s.color.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contentShape(Rectangle())
                }
            }
        }
    }
    
    
    // MARK: - Combined Watch Tabs Section
    private var watchTabsSection: some View {
        VStack(spacing: 0) {
            // Modern Tab Selector with pill design
            HStack(spacing: 8) {
                ForEach(WatchTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedWatchTab = tab
                        }
                    }) {
                        VStack(spacing: 6) {
                            ZStack {
                                // Background circle for icon
                                Circle()
                                    .fill(selectedWatchTab == tab ? tab.color : Color(.systemGray5))
                                    .frame(width: 44, height: 44)

                                Image(systemName: tab.icon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(selectedWatchTab == tab ? .white : .secondary)
                            }

                            Text(tab.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(selectedWatchTab == tab ? tab.color : .secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(height: 28)
                        }
                        .frame(maxWidth: .infinity, minHeight: 98)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedWatchTab == tab ? tab.color.opacity(0.08) : Color.clear)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(Color(.systemBackground))

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
                .fill(Color(.systemBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
    
    // MARK: - Additive Analysis Content
    private var additivesContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Use AdditiveWatchView for proper loading state and auto-expansion
            if let ingredientsList = cachedIngredients, !ingredientsList.isEmpty {
                AdditiveWatchView(ingredients: ingredientsList)
            } else {
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
                            .foregroundColor(.green)

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

                // Citations for allergen detection
                if !potentialAllergens.isEmpty {
                    Divider()
                        .padding(.vertical, 8)

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
                                .foregroundColor(.blue)
                        }
                    }
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

        #if DEBUG
        print("🎨 vitaminsContent rendering: \(detectedNutrients.count) nutrients")

        #endif
        return VStack(alignment: .leading, spacing: 12) {
            if !sortedDetected.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(sortedDetected, id: \.self) { nutrientId in
                        if let nutrientInfo = micronutrientDB.getNutrientInfo(nutrientId) {
                            NutrientInfoCard(nutrientInfo: nutrientInfo, scrollProxy: scrollProxy, cardId: nutrientId)
                                .id(nutrientId)
                        } else {
                            Text("⚠️ Could not load info for: \(nutrientId)")
                                .foregroundColor(.red)
                        }
                    }
                }
                .transaction { t in t.disablesAnimations = true }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue.opacity(0.5))

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
                        .foregroundColor(.blue)
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
                    .foregroundColor(.blue)
                }
            }
            .padding(.top, 8)
        }
        .padding(16)
    }
    
    private func recomputeDetectedNutrients() {
        let ids = getDetectedNutrients()
        let ordering = NutrientDatabase.allNutrients.map { $0.id }
        cachedDetectedNutrients = ids.sorted { a, b in
            let ia = ordering.firstIndex(of: a) ?? Int.max
            let ib = ordering.firstIndex(of: b) ?? Int.max
            if ia != ib { return ia < ib }
            return a < b
        }
    }

    // NEW: Detect nutrients from ingredients using NutrientDetector and MicronutrientDatabase
    private func getDetectedNutrients() -> [String] {
        // DEBUG LOG: print("🔬 getDetectedNutrients() called for food: \(food.name)")
        #if DEBUG
        print("  📝 Ingredients: \(food.ingredients ?? [])")

        #endif
        var detectedNutrients: [String] = []

        // Detect from ingredients if available
        if let ingredients = food.ingredients, !ingredients.isEmpty {
            // Create a temporary DiaryFoodItem for nutrient detection
            let tempFood = DiaryFoodItem(
                name: food.name,
                brand: food.brand,
                calories: 0,
                protein: 0,
                carbs: 0,
                fat: 0,
                servingDescription: "",
                quantity: 1,
                ingredients: ingredients,
                barcode: food.barcode,
                micronutrientProfile: nil
            )

            // Use NutrientDetector to detect nutrients from ingredients
            detectedNutrients = NutrientDetector.detectNutrients(in: tempFood)
            #if DEBUG
            print("  ✅ Detected \(detectedNutrients.count) nutrients from ingredients: \(detectedNutrients)")
            #endif
        } else {
            #if DEBUG
            print("  ⚠️ No ingredients found")
            #endif
        }

        #if DEBUG
        print("  ✅ Total nutrients to display: \(detectedNutrients.count)")
        #endif
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
        
        #if DEBUG
        print("Updated portion for food item in \(originalMealType)")
        #endif
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
        
        #if DEBUG
        print("Moved food item from \(originalMealType) to \(selectedMeal)")
        #endif
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
        
        #if DEBUG
        print("Added new food item to \(selectedMeal)")
        #endif
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

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Warning icon
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.red)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(allergenName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Detected in ingredients")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.red.opacity(0.2), lineWidth: 1.5)
                )
        )
        .shadow(color: Color.red.opacity(0.08), radius: 8, x: 0, y: 2)
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
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(nutrientName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        Text(getNutrientCategory())
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(12)
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded details removed - nutrient information is displayed in the main section above
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(getNutrientColor().opacity(0.2), lineWidth: 1.5)
                )
        )
        .shadow(color: getNutrientColor().opacity(0.08), radius: 8, x: 0, y: 2)
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
            return .blue
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
                .foregroundColor(.green)

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
                        .foregroundColor(.blue)
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
                .background(Color(.systemGray6))
                .cornerRadius(isExpanded ? 12 : 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                content()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// Vitamin row component
struct VitaminRow: View {
    let name: String
    let amount: String
    let dailyValue: String
    
    var body: some View {
        HStack {
            Text(name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(amount)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                Text(dailyValue)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
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
                        .foregroundColor(.green)
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
                                        .foregroundColor(.blue)
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
                                                .foregroundColor(.blue)
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
                                    .foregroundColor(.blue)
                                Text("Health benefits based on EFSA-approved claims and NHS guidance")
                                    .font(.system(size: 10))
                                    .foregroundColor(.blue)
                                    .lineLimit(2)
                                Image(systemName: "arrow.up.right.square")
                                    .font(.system(size: 9))
                                    .foregroundColor(.blue)
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
                .fill(Color.green.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.green.opacity(0.3), lineWidth: 1.5)
                )
        )
        .sheet(isPresented: $showingCitations) {
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
                                        .foregroundColor(.blue)
                                        .font(.system(size: 14))
                                    Text(citation.organization)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                Text(citation.title)
                                    .font(.caption)
                                    .foregroundColor(.blue)
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
                                        .foregroundColor(.blue)
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
                                        .foregroundColor(.blue)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color(.systemGray6))
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

    private var tips: [String] {
        var out: [String] = []
        if food.sugar > 15 { out.append("Choose unsweetened versions or smaller portions.") }
        if food.sugar > 10 { out.append("Pair with protein or fiber to slow absorption.") }
        out.append("Watch added sugars like syrups and sweeteners.")
        out.append("Prefer whole foods: fruit, yoghurt, nuts, seeds.")
        return out
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center, spacing: 12) {
                        Text(score.grade.rawValue)
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundColor(score.color)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(description(for: score.grade))
                                .font(.headline)
                            Text("Sugar Score")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(score.color.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(score.color.opacity(0.2), lineWidth: 1)
                            )
                    )

                    Group {
                        Text("What this means")
                            .font(.headline)
                        Text(score.explanation)
                            .font(.callout)
                            .foregroundColor(.primary)
                    }

                    Group {
                        Text("Health Impact")
                            .font(.headline)
                        Text(score.healthImpact)
                            .font(.callout)
                            .foregroundColor(.primary)
                    }

                    Group {
                        Text("Recommendation")
                            .font(.headline)
                        Text(score.recommendation)
                            .font(.callout)
                            .foregroundColor(.primary)
                    }

                    // Show breakdown if both density and serving grades exist
                    if let servingGrade = score.servingGrade {
                        Group {
                            Text("Score Breakdown")
                                .font(.headline)
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Density (per 100g):")
                                        .font(.callout)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(score.densityGrade.rawValue)
                                        .font(.callout.bold())
                                        .foregroundColor(score.densityGrade.color)
                                }
                                HStack {
                                    Text("Per serving:")
                                        .font(.callout)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(servingGrade.rawValue)
                                        .font(.callout.bold())
                                        .foregroundColor(servingGrade.color)
                                }
                                Text("Final grade uses the worse of the two to warn you about large servings.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                        }
                    }

                    Group {
                        Text("How we calculate it")
                            .font(.headline)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Score based on both sugar density (per 100g) and actual serving size")
                            Text("• Uses the worse of the two scores to warn about large servings")
                            Text("• Thresholds align with public health guidance")
                            Text("• Helps you spot foods that pack a lot of sugar per serving")
                        }
                        .font(.callout)
                        .foregroundColor(.secondary)
                    }

                    Group {
                        Text("Tips for similar foods")
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
                        Text("Sugar per 100g: \(String(format: "%.1f", food.sugar))g")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        if let servingSize = score.servingSizeG {
                            Text("Serving size: \(String(format: "%.0f", servingSize))g")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        Text("Sugar per serving: \(String(format: "%.1f", perServingSugar))g")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }

                    // Citations section
                    Group {
                        Text("Research Sources")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(CitationManager.shared.citations(for: .sugarSalt)) { citation in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(citation.organization)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.blue)

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
                                                .fill(Color.blue)
                                        )
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(.systemGray6))
                                )
                            }
                        }

                        Text("Our sugar scoring is based on WHO and NHS dietary guidelines for sugar intake.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
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
                            .foregroundColor(.green)

                        Text("Barcode Scanned")
                            .font(.title2.weight(.bold))

                        Text(code)
                            .font(.system(.title3, design: .monospaced))
                            .padding()
                            .background(Color.gray.opacity(0.1))
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
                            .background(Color.blue)
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
