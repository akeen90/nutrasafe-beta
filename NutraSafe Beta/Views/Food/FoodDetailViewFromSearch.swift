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

// MARK: - Food Detail View From Search (2,305 lines extracted from ContentView.swift)
struct FoodDetailViewFromSearch: View {
    let food: FoodSearchResult
    let sourceType: FoodSourceType
    @Binding var selectedTab: TabItem
    let destination: AddFoodMainView.AddDestination
    var onComplete: ((TabItem) -> Void)?
    @Environment(\.dismiss) private var dismiss
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

    // MARK: - Diary replacement support
    let diaryEntryId: UUID?
    let diaryMealType: String?

    init(food: FoodSearchResult, sourceType: FoodSourceType = .search, selectedTab: Binding<TabItem>, destination: AddFoodMainView.AddDestination, diaryEntryId: UUID? = nil, diaryMealType: String? = nil, onComplete: ((TabItem) -> Void)? = nil) {
        self.food = food
        self.sourceType = sourceType
        self._selectedTab = selectedTab
        self.destination = destination
        self.diaryEntryId = diaryEntryId
        self.diaryMealType = diaryMealType
        self.onComplete = onComplete

        // CRITICAL FIX: Initialize serving size from food data immediately
        var initialServingSize = "100"  // Default fallback
        let initialUnit = "g"

        // Priority 1: Use servingSizeG if available (most reliable)
        if let sizeG = food.servingSizeG, sizeG > 0 {
            initialServingSize = String(format: "%.0f", sizeG)
            print("🔧 INIT: Using servingSizeG: \(sizeG)g for \(food.name)")
        } else if let servingDesc = food.servingDescription {
            // Priority 2: Extract from serving description
            print("🔧 INIT: Parsing serving description: '\(servingDesc)' for \(food.name)")

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
                    print("🔧 INIT: Extracted \(initialServingSize)g from '\(servingDesc)'")
                    break
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

        // Debug logging
        print("DEBUG FoodDetailViewFromSearch init:")
        print("  - diaryEntryId: \(String(describing: diaryEntryId))")
        print("  - diaryMealType: \(String(describing: diaryMealType))")
        print("  - isEditingMode will be: \(diaryEntryId != nil)")
        print("  - selectedMeal will be: \(diaryMealType ?? "Breakfast")")
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
    @State private var servingSizeText: String = "" // Editable serving size (legacy)
    @State private var servingAmount: String // Split serving size - amount only
    @State private var servingUnit: String // Split serving size - unit only
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
    
    private var buttonText: String {
        print("DEBUG buttonText calculation:")
        print("  - diaryEntryId: \(String(describing: diaryEntryId))")
        print("  - isEditingMode: \(isEditingMode)")
        print("  - selectedMeal: \(selectedMeal)")
        print("  - originalMealType: \(originalMealType)")
        print("  - destination: \(destination)")

        // Check if we're replacing a diary entry
        if let _ = diaryEntryId {
            print("  -> Has diaryEntryId, returning Replace/Move")
            if selectedMeal == originalMealType {
                return "Replace in Diary"
            } else {
                return "Move to \(selectedMeal)"
            }
        } else if isEditingMode {
            print("  -> isEditingMode true, returning Update/Move")
            if selectedMeal == originalMealType {
                return "Update Portion"
            } else {
                return "Move to \(selectedMeal)"
            }
        } else {
            print("  -> Default case, returning Add")
            // Reflect destination selection
            return destination == .useBy ? "Add to Use By" : "Add to Diary"
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
    private let servingUnitOptions = ["g", "ml", "cup", "tbsp", "tsp", "oz"]

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
        // Get the amount and unit
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

    private var perServingMultiplier: Double {
        actualServingSize / 100
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
        return SugarContentScorer.shared.calculateSugarScore(sugarPer100g: displayFood.sugar)
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
                    word.hasPrefix(abbr) && (word.count == abbr.count || !word.dropFirst(abbr.count).first!.isLetter)
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
        print("🔍 getIngredientsList() called")
        print("  - enhancedIngredientsText: \(enhancedIngredientsText?.prefix(50) ?? "nil")")
        print("  - displayFood.ingredients: \(displayFood.ingredients?.count ?? 0) items")

        // PRIORITY 1: Check for AI-enhanced ingredients
        if let enhancedText = enhancedIngredientsText, !enhancedText.isEmpty {
            // Split enhanced ingredients text into array
            let enhancedIngredients = enhancedText
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if !enhancedIngredients.isEmpty {
                print("✨ Using AI-enhanced ingredients (\(enhancedIngredients.count) items)")
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
            print("Failed to load user allergens: \(error.localizedDescription)")
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
        print("getDetectedAdditives: displayFood.additives = \(String(describing: displayFood.additives))")
        print("getDetectedAdditives: displayFood.name = \(displayFood.name)")
        print("getDetectedAdditives: displayFood.calories = \(displayFood.calories)")

        // Check if we need to re-analyze due to outdated database version
        let currentDBVersion = ProcessingScorer.shared.databaseVersion
        let savedDBVersion = displayFood.additivesDatabaseVersion

        print("📊 Database versions - Current: \(currentDBVersion), Saved: \(savedDBVersion ?? "nil (legacy)")")

        // Re-analyze if:
        // 1. No saved version (legacy data)
        // 2. Saved version is different from current version
        // 3. We have ingredients to analyze
        let hasIngredients = displayFood.ingredients != nil && !displayFood.ingredients!.isEmpty
        let needsReAnalysis = (savedDBVersion == nil || savedDBVersion != currentDBVersion) && hasIngredients

        if needsReAnalysis {
            print("🔄 RE-ANALYZING: Database version outdated or missing")
            print("   - Saved version: \(savedDBVersion ?? "none")")
            print("   - Current version: \(currentDBVersion)")
            print("   - Ingredients available: \(displayFood.ingredients?.count ?? 0)")

            // Perform fresh analysis with current database
            let ingredientsText = displayFood.ingredients!.joined(separator: ", ")
            let freshAdditives = ProcessingScorer.shared.analyzeAdditives(in: ingredientsText)

            print("🔄 Fresh analysis complete: Found \(freshAdditives.count) additives")

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

                let description = additive.consumerInfo ?? "No detailed information available for this additive."

                return DetailedAdditive(
                    name: additive.name,
                    code: additive.eNumber,
                    purpose: additive.group.rawValue.capitalized,
                    origin: additive.origin.rawValue.capitalized,
                    childWarning: additive.hasChildWarning,
                    riskLevel: riskLevel,
                    description: description
                )
            }
        }

        // Use saved Firebase additive data if version is current
        if let firebaseAdditives = displayFood.additives, !firebaseAdditives.isEmpty {
            print("getDetectedAdditives: Using saved data - \(firebaseAdditives.count) additives")
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
                let description = additive.consumerGuide ?? "No detailed information available for this additive."

                return DetailedAdditive(
                    name: additive.name,
                    code: additive.code,
                    purpose: additive.category.capitalized,
                    origin: additive.origin ?? "Unknown",
                    childWarning: additive.childWarning,
                    riskLevel: riskLevel,
                    description: description
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
        for (additiveName, code, purpose, origin, childWarning, riskLevel, description) in additiveDatabase {
            if ingredientsText.contains(additiveName.lowercased()) {
                detectedAdditives.append(DetailedAdditive(
                    name: additiveName.capitalized,
                    code: code,
                    purpose: purpose,
                    origin: origin,
                    childWarning: childWarning,
                    riskLevel: riskLevel,
                    description: description
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

        return HStack(spacing: 6) {
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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    foodHeaderView

                    // Serving and Meal Controls Section
                    servingControlsSection
                        .onAppear {
                            if servingAmount == "1" && servingUnit == "g" {
                                // PRIORITY 1: Use servingSizeG if available (most reliable)
                                if let sizeG = food.servingSizeG, sizeG > 0 {
                                    print("🔧 Using servingSizeG: \(sizeG)g")
                                    servingAmount = String(format: "%.0f", sizeG)
                                    servingUnit = "g"
                                    gramsAmount = String(format: "%.0f", sizeG)  // Also update gramsAmount
                                } else {
                                    // PRIORITY 2: Extract from serving description
                                    let description = food.servingDescription ?? "100g"
                                    print("🔧 Parsing serving description: '\(description)'")

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
                                            print("🔧 Extracted serving size: \(extractedValue)g")
                                            servingAmount = extractedValue
                                            servingUnit = "g"
                                            gramsAmount = extractedValue  // Also update gramsAmount
                                            found = true
                                            break
                                        }
                                    }

                                    // PRIORITY 3: Default to 100g only if nothing found
                                    if !found {
                                        print("⚠️ No serving size found, defaulting to 100g")
                                        servingAmount = "100"
                                        servingUnit = "g"
                                        gramsAmount = "100"
                                    }
                                }
                            }

                            // Check for preselected meal type from diary
                            if let preselectedMeal = UserDefaults.standard.string(forKey: "preselectedMealType") {
                                selectedMeal = preselectedMeal
                                // Clear the stored value after using it
                                UserDefaults.standard.removeObject(forKey: "preselectedMealType")
                            }
                        }
                    
                    // Nutrition information first
                    nutritionFactsSection
                    
                    // Food Scores Section (moved from header)
                    foodScoresSection
                    
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // PERFORMANCE: Only initialize once per view instance, even if .onAppear is called multiple times
            guard !hasInitialized else { return }
            hasInitialized = true

            // PERFORMANCE: Cache ingredients list ONCE on appear
            if cachedIngredients == nil {
                cachedIngredients = getIngredientsList()
            }

            // PERFORMANCE: Cache ingredients status ONCE on appear
            if cachedIngredientsStatus == nil {
                cachedIngredientsStatus = getIngredientsStatus()
            }

            // PERFORMANCE: Compute additives ONCE on appear and cache
            if cachedAdditives == nil {
                // Prefer saved additives if present (e.g., from Firebase)
                if let firebaseAdditives = displayFood.additives, !firebaseAdditives.isEmpty {
                    cachedAdditives = firebaseAdditives.map { additive in
                        let riskLevel: String
                        if additive.effectsVerdict == "avoid" {
                            riskLevel = "High"
                        } else if additive.effectsVerdict == "caution" {
                            riskLevel = "Moderate"
                        } else {
                            riskLevel = "Low"
                        }

                        let description = additive.consumerGuide ?? "No detailed information available for this additive."

                        return DetailedAdditive(
                            name: additive.name,
                            code: additive.code,
                            purpose: additive.category.capitalized,
                            origin: additive.origin ?? "Unknown",
                            childWarning: additive.childWarning,
                            riskLevel: riskLevel,
                            description: description
                        )
                    }
                } else {
                    // Use enhanced AdditiveWatchService which includes CSV fallback when comprehensive DB is missing
                    let ingredientsArray = cachedIngredients ?? displayFood.ingredients ?? []
                    AdditiveWatchService.shared.analyzeIngredients(ingredientsArray) { result in
                        let mapped: [DetailedAdditive] = result.detectedAdditives.map { additive in
                            let riskLevel: String
                            if additive.effectsVerdict == .avoid {
                                riskLevel = "High"
                            } else if additive.effectsVerdict == .caution {
                                riskLevel = "Moderate"
                            } else {
                                riskLevel = "Low"
                            }

                            let description = additive.consumerInfo ?? "No detailed information available for this additive."

                            return DetailedAdditive(
                                name: additive.name,
                                code: additive.eNumber,
                                purpose: additive.group.rawValue.capitalized,
                                origin: additive.origin.rawValue.capitalized,
                                childWarning: additive.hasChildWarning,
                                riskLevel: riskLevel,
                                description: description
                            )
                        }
                        DispatchQueue.main.async {
                            self.cachedAdditives = mapped
                        }
                    }
                }
            }

            // PERFORMANCE: Compute nutrition score ONCE on appear and cache (prevents 40+ analyseAdditives calls)
            if cachedNutritionScore == nil {
                let submittedFoods = UserDefaults.standard.array(forKey: "submittedFoodsForReview") as? [String] ?? []
                let foodKey = "\(food.name)|\(food.brand ?? "")"

                // First check if we have user-verified ingredients
                if let userIngredients = cachedIngredients, !userIngredients.isEmpty {
                    let ingredientsString = userIngredients.joined(separator: ", ")
                    cachedNutritionScore = ProcessingScorer.shared.calculateProcessingScore(for: displayFood.name, ingredients: ingredientsString, sugarPer100g: displayFood.sugar)
                }
                // Fallback to official ingredients if available
                else if let ingredients = displayFood.ingredients, !ingredients.isEmpty {
                    if submittedFoods.contains(foodKey) {
                        var updatedSubmittedFoods = submittedFoods
                        updatedSubmittedFoods.removeAll { $0 == foodKey }
                        UserDefaults.standard.set(updatedSubmittedFoods, forKey: "submittedFoodsForReview")
                    }
                    let ingredientsString = ingredients.joined(separator: ", ")
                    cachedNutritionScore = ProcessingScorer.shared.calculateProcessingScore(for: displayFood.name, ingredients: ingredientsString, sugarPer100g: displayFood.sugar)
                }
                // Only show "In Review" if the food was submitted AND has no ingredients
                else if submittedFoods.contains(foodKey) {
                    cachedNutritionScore = NutritionProcessingScore(
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
                else {
                    cachedNutritionScore = ProcessingScorer.shared.calculateProcessingScore(for: displayFood.name, sugarPer100g: displayFood.sugar)
                }
            }

            // PERFORMANCE: Compute NutraSafe grade ONCE on appear and cache
            if cachedNutraSafeGrade == nil {
                cachedNutraSafeGrade = ProcessingScorer.shared.computeNutraSafeProcessingGrade(for: displayFood)
            }

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
            } else if let preselectedMeal = UserDefaults.standard.string(forKey: "preselectedMealType") {
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
            if let result = cachedNutraSafeGrade {
                NutraSafeGradeInfoView(result: result, food: displayFood)
            } else {
                VStack(spacing: 16) {
                    Text("NutraSafe Grade")
                        .font(.title2.weight(.bold))
                    Text("Grade information isn't available for this food yet.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingSugarInfo) {
            SugarScoreInfoView(
                score: sugarScore,
                food: displayFood,
                perServingSugar: displayFood.sugar * perServingMultiplier * quantityMultiplier
            )
        }
    }
    
    
    private var nutritionFactsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Calories - most prominent
            VStack(alignment: .leading, spacing: 12) {
                Text("CALORIES")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(0.5)
                    .padding(.horizontal, 20)

                // Per serving first
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

                        Text("\(quantityMultiplier == 0.5 ? "½" : String(format: "%.0f", quantityMultiplier))× \(servingSizeText.isEmpty ? (food.servingDescription ?? "serving") : servingSizeText)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Per 100g second
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Per 100g")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)

                        HStack(alignment: .bottom, spacing: 4) {
                            Text(String(format: "%.0f", displayFood.calories))
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
            
            // Other nutrients in clean layout
            VStack(alignment: .leading, spacing: 16) {
                Text("NUTRITION PER SERVING")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(0.5)
                    .padding(.horizontal, 4)

                VStack(spacing: 8) {
                    nutritionRowModern("Protein", perServing: adjustedProtein, per100g: displayFood.protein, unit: "g")
                    nutritionRowModern("Carbs", perServing: adjustedCarbs, per100g: displayFood.carbs, unit: "g")
                    nutritionRowModern("Fat", perServing: adjustedFat, per100g: displayFood.fat, unit: "g")
                    nutritionRowModern("Fiber", perServing: adjustedFiber, per100g: displayFood.fiber, unit: "g")
                    nutritionRowModern("Sugar", perServing: adjustedSugar, per100g: displayFood.sugar, unit: "g")
                    nutritionRowModern("Salt", perServing: adjustedSalt, per100g: saltPer100g, unit: "g")
                }
                .padding(.bottom, 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color(.systemGray6))
        .cornerRadius(16)
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
            
            // Right section: Per 100g (completely separate)
            HStack(spacing: 2) {
                Text(String(format: unit == "mg" ? "%.0f" : "%.1f", per100g))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                Text(unit + "/100g")
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
        print("Adding \(food.name) to food log")
        
        // Calculate actual serving calories and macros based on user selections
        let servingSize = actualServingSize
        let totalCalories = displayFood.calories * (servingSize / 100) * quantityMultiplier
        let totalProtein = displayFood.protein * (servingSize / 100) * quantityMultiplier
        let totalCarbs = displayFood.carbs * (servingSize / 100) * quantityMultiplier
        let totalFat = displayFood.fat * (servingSize / 100) * quantityMultiplier
        let totalFiber = displayFood.fiber * (servingSize / 100) * quantityMultiplier
        let totalSugar = displayFood.sugar * (servingSize / 100) * quantityMultiplier
        let totalSodium = displayFood.sodium * (servingSize / 100) * quantityMultiplier

        // Generate micronutrient profile from food data
        let micronutrientProfile = MicronutrientManager.shared.getMicronutrientProfile(for: displayFood, quantity: (servingSize / 100) * quantityMultiplier)

        // Create diary entry
        print("📝 Creating DiaryFoodItem:")
        print("  - displayFood.ingredients: \(displayFood.ingredients?.count ?? 0) items")
        print("  - displayFood.ingredients: \(displayFood.ingredients ?? [])")
        print("  - displayFood.additives: \(displayFood.additives?.count ?? 0) items")
        print("  - displayFood.barcode: \(displayFood.barcode ?? "nil")")

        // Use existing diary entry ID if replacing, otherwise create new ID
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
            servingDescription: "\(String(format: "%.0f", servingSize))g serving",
            quantity: quantityMultiplier,
            time: selectedMeal,
            processedScore: cachedNutraSafeGrade?.grade ?? "",
            sugarLevel: getSugarLevel(),
            ingredients: displayFood.ingredients,
            additives: displayFood.additives,
            barcode: displayFood.barcode,
            micronutrientProfile: micronutrientProfile
        )

        print("📝 Created DiaryFoodItem:")
        print("  - diaryEntry.ingredients: \(diaryEntry.ingredients?.count ?? 0) items")
        print("  - diaryEntry.ingredients: \(diaryEntry.ingredients ?? [])")

        // Add to diary or useBy based on destination
        if destination == .useBy {
            // Show useBy detail sheet where user can set expiry, location, etc.
            showingUseByAddSheet = true
        } else {
            // Add to diary using DiaryDataManager
            // Get the preselected date from UserDefaults, or use today if not available
            let targetDate: Date
            if let preselectedTimestamp = UserDefaults.standard.object(forKey: "preselectedDate") as? Double {
                targetDate = Date(timeIntervalSince1970: preselectedTimestamp)
                // Don't clear yet - DiaryTabView needs to read it to navigate to the correct date
            } else {
                targetDate = Date()
            }

            // Check if we're replacing an existing diary entry or adding a new one
            if let _ = diaryEntryId {
                print("FoodDetailView: About to replace food '\(diaryEntry.name)' (ID: \(diaryEntry.id)) in meal '\(selectedMeal)' on date '\(targetDate)'")
                print("FoodDetailView: DiaryEntry details - Calories: \(diaryEntry.calories), Protein: \(diaryEntry.protein), Serving: \(diaryEntry.servingDescription), Quantity: \(diaryEntry.quantity)")
                diaryDataManager.replaceFoodItem(diaryEntry, to: selectedMeal, for: targetDate)
                print("FoodDetailView: Successfully replaced \(diaryEntry.name) in \(selectedMeal) on \(targetDate)")
            } else {
                print("FoodDetailView: About to add food '\(diaryEntry.name)' to meal '\(selectedMeal)' on date '\(targetDate)'")
                print("FoodDetailView: DiaryEntry details - Calories: \(diaryEntry.calories), Protein: \(diaryEntry.protein), Serving: \(diaryEntry.servingDescription), Quantity: \(diaryEntry.quantity)")
                diaryDataManager.addFoodItem(diaryEntry, to: selectedMeal, for: targetDate)
                print("FoodDetailView: Successfully added \(diaryEntry.name) to \(selectedMeal) on \(targetDate)")
            }

            // Dismiss and navigate to the destination tab
            dismiss()
            onComplete?(destination == .diary ? .diary : .useBy)
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
        VStack(alignment: .leading, spacing: 0) {
            // Header with border separator
            HStack {
                if cachedIngredientsStatus == .pending {
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

                if cachedIngredientsStatus == .pending {
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(.black),
                alignment: .bottom
            )

            // Ingredients content
            if let ingredientsList = cachedIngredients {
                let cleanIngredients = ingredientsList
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")

                Text(cleanIngredients.isEmpty ? "No ingredients found" : cleanIngredients)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
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
                .background(Color.white)
            }
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black, lineWidth: 2)
        )
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var additiveWatchSection: some View {
        if let ingredientsList = cachedIngredients, !ingredientsList.isEmpty {
            AdditiveWatchView(ingredients: ingredientsList)
        }
    }
    
    private var allergensSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Allergen & Safety Information")
                .font(.system(size: 18, weight: .semibold))
            
            let detectedAllergens = detectAllergens(in: food.ingredients)
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
                
                // Show allergen warnings
                if !detectedAllergens.isEmpty {
                    ForEach(detectedAllergens.sorted(by: { $0.displayName < $1.displayName }), id: \.rawValue) { allergen in
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
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // REMOVED: Old micronutrientsSection - replaced with vitaminsContent using NutrientDetector
    
    // REMOVED: Old fake micronutrient functions that relied on currentMicronutrients variable
    // Now we use NutrientDetector to detect from ingredients instead of fake math
    
    private func detectAllergens(in ingredients: [String]?) -> [Allergen] {
        guard let ingredients = ingredients else { return [] }

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
                HStack {
                    Image(systemName: "info.circle.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("Incomplete Food Data?")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                }

                Text("Food details not quite right? Try enhancing with AI or notify our team for manual review.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    // AI Enhancement Button
                    Button(action: {
                        enhanceWithAI()
                    }) {
                        HStack {
                            if isEnhancing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "sparkles")
                                Text("Enhance with AI")
                                    .font(.system(size: 14, weight: .medium))
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(isEnhancing ? Color.gray : Color.blue)
                        .cornerRadius(8)
                    }
                    .disabled(isEnhancing)

                    // Notify Team Button
                    Button(action: {
                        notifyTeamAboutIncompleteFood()
                    }) {
                        HStack {
                            if isNotifyingTeam {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "exclamationmark.triangle")
                                Text("Notify Team")
                                    .font(.system(size: 14, weight: .medium))
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(isNotifyingTeam ? Color.gray : Color.orange)
                        .cornerRadius(8)
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
                // This will save to Firestore database and notify team via email
                try await firebaseManager.notifyIncompleteFood(food: food)

                await MainActor.run {
                    isNotifyingTeam = false
                    showingNotificationSuccess = true
                }

            } catch {
                print("Error notifying team: \(error)")
                await MainActor.run {
                    isNotifyingTeam = false
                    notificationErrorMessage = "Unable to send notification. Please try again later."
                    showingNotificationError = true
                }
            }
        }
    }

    // Enhance food data using AI ingredient finder
    private func enhanceWithAI() {
        isEnhancing = true
        print("🤖 Starting AI enhancement for: \(food.name), brand: \(food.brand ?? "none")")

        Task {
            do {
                // Call the AI ingredient finder service
                let result = try await IngredientFinderService.shared.findIngredients(
                    productName: food.name,
                    brand: food.brand
                )

                print("🔍 AI Search Result:")
                print("  - ingredients_found: \(result.ingredients_found)")
                print("  - ingredients_text: \(result.ingredients_text?.prefix(50) ?? "nil")")
                print("  - nutrition: \(result.nutrition_per_100g != nil ? "YES" : "NO")")

                // Save to Firebase AI-improved foods collection (outside MainActor)
                if result.ingredients_found {
                    print("💾 Saving AI-improved food to Firebase")
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

                    if let servingSize = result.serving_size {
                        enhancedData["servingSize"] = servingSize
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
                        print("✅ AI-improved food saved with ID: \(savedId)")
                    } catch {
                        print("⚠️ Failed to save AI-improved food to Firebase: \(error)")
                        // Continue anyway - the UI enhancement still works
                    }
                }

                await MainActor.run {
                    isEnhancing = false

                    if result.ingredients_found {
                        // Store enhanced ingredients
                        if let ingredientsText = result.ingredients_text {
                            print("✅ AI found enhanced ingredients: \(ingredientsText.prefix(100))...")
                            enhancedIngredientsText = ingredientsText
                            print("📝 enhancedIngredientsText is now: \(enhancedIngredientsText?.prefix(50) ?? "nil")")
                        } else {
                            print("⚠️ No ingredients_text in result")
                        }

                        // Store enhanced nutrition data
                        if let nutrition = result.nutrition_per_100g {
                            print("✅ AI found enhanced nutrition data:")
                            print("  - calories: \(nutrition.calories ?? 0)")
                            print("  - protein: \(nutrition.protein ?? 0)")
                            print("  - carbs: \(nutrition.carbs ?? 0)")
                            enhancedNutrition = nutrition
                        } else {
                            print("⚠️ No nutrition_per_100g in result")
                        }

                        // Store enhanced product details
                        enhancedProductName = result.product_name
                        enhancedBrand = result.brand
                        print("📦 Product details: name=\(result.product_name ?? "nil"), brand=\(result.brand ?? "nil")")

                        // Clear and repopulate cached data with enhanced information
                        print("🗑️ Clearing all caches and repopulating with enhanced data")
                        cachedIngredients = nil
                        cachedAdditives = nil
                        cachedIngredientsStatus = nil
                        cachedNutritionScore = nil
                        cachedNutraSafeGrade = nil

                        // Immediately repopulate ingredients cache with enhanced data
                        print("🔄 Repopulating ingredients cache")
                        cachedIngredients = getIngredientsList()
                        cachedIngredientsStatus = getIngredientsStatus()

                        print("✅ Cache repopulated: \(cachedIngredients?.count ?? 0) ingredients")

                        // Recalculate NutraSafe grade with enhanced data
                        print("🔄 Recalculating NutraSafe grade with enhanced data")
                        cachedNutraSafeGrade = ProcessingScorer.shared.computeNutraSafeProcessingGrade(for: displayFood)
                        if let grade = cachedNutraSafeGrade {
                            print("✅ NutraSafe grade recalculated: \(grade.grade)")
                        }

                        // Trigger additive analysis with new ingredients
                        if let ingredientsArray = cachedIngredients, !ingredientsArray.isEmpty {
                            print("🔬 Analyzing additives in enhanced ingredients")
                            AdditiveWatchService.shared.analyzeIngredients(ingredientsArray) { result in
                                let mapped: [DetailedAdditive] = result.detectedAdditives.map { additive in
                                    let riskLevel: String
                                    if additive.effectsVerdict == .avoid {
                                        riskLevel = "High"
                                    } else if additive.effectsVerdict == .caution {
                                        riskLevel = "Moderate"
                                    } else {
                                        riskLevel = "Low"
                                    }
                                    let description = additive.consumerInfo ?? "No detailed information available for this additive."
                                    return DetailedAdditive(
                                        name: additive.name,
                                        code: additive.eNumber,
                                        purpose: additive.group.rawValue.capitalized,
                                        origin: additive.origin.rawValue.capitalized,
                                        childWarning: additive.hasChildWarning,
                                        riskLevel: riskLevel,
                                        description: description
                                    )
                                }
                                DispatchQueue.main.async {
                                    self.cachedAdditives = mapped
                                    print("✅ Additives analyzed: \(mapped.count) found")
                                }
                            }
                        }

                        // Trigger UI refresh
                        print("🔄 Triggering UI refresh")
                        refreshTrigger = UUID()

                        print("✨ Enhancement complete! Showing success alert")
                        showingEnhancementSuccess = true
                    } else {
                        print("⚠️ AI could not find enhanced ingredients")
                        enhancementErrorMessage = "Could not find enhanced ingredient information. The product might not be in our UK supermarket database."
                        showingEnhancementError = true
                    }
                }

            } catch {
                print("❌ Error enhancing with AI: \(error)")
                await MainActor.run {
                    isEnhancing = false
                    enhancementErrorMessage = "Unable to enhance with AI. Please try again later."
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
                let url = URL(string: "https://us-central1-nutrasafe-705c7.cloudfunctions.net/processCompleteFoodProfile")!
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
                                print("Error storing ingredients: \(error)")
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
                print("Error submitting complete food profile: \(error)")
                await MainActor.run {
                    isSubmittingCompleteProfile = false
                }
            }
        }
    }
    
    // Extract ingredients using intelligent Gemini AI and update app immediately
    private func extractAndAnalyzeIngredients(from image: UIImage, for food: FoodSearchResult) async {
        print("🧠 Starting intelligent ingredient extraction with Gemini AI...")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to convert image to JPEG data")
            return
        }
        
        let base64String = imageData.base64EncodedString()
        
        // Call our intelligent extraction Firebase function via URLSession
        guard let url = URL(string: "https://us-central1-nutrasafe-705c7.cloudfunctions.net/extractIngredientsWithAI") else {
            print("❌ Invalid URL for extractIngredientsWithAI")
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
                    
                    print("✅ Intelligent extraction completed:")
                    print("📝 Ingredients: \(cleanIngredientsText)")
                    print("⚠️ Detected allergens: \(detectedAllergens.joined(separator: ", "))")
                    
                    // Trigger nutrition score recalculation with new ingredients
                    Task {
                        await recalculateNutritionScore(with: extractedIngredients)
                    }
                }
            }
            
        } catch {
            print("❌ Error calling intelligent extraction function: \(error)")
            
            // Fallback to simple Vision OCR if Gemini fails
            await fallbackVisionExtraction(from: image, for: food)
        }
    }
    
    // Fallback Vision OCR method (simplified version)
    private func fallbackVisionExtraction(from image: UIImage, for food: FoodSearchResult) async {
        print("⚠️ Using fallback Vision OCR...")
        
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
                    print("✅ Fallback extraction: \(extractedText)")
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
        print("🔄 Recalculating nutrition score with user-verified ingredients...")

        // PERFORMANCE: Invalidate caches and reset initialization flag to allow re-initialization
        await MainActor.run {
            cachedIngredients = nil
            cachedIngredientsStatus = nil
            cachedAdditives = nil
            cachedNutritionScore = nil
            hasInitialized = false
        }

        // The nutrition score will automatically recalculate since the nutritionScore
        // computed property now prioritizes user-verified ingredients
        print("✅ Nutrition score recalculated successfully")

        // Force UI refresh immediately so user sees the updated nutrition score
        await MainActor.run {
            refreshTrigger = UUID()
            print("🔄 UI refresh triggered - nutrition score should now reflect user-verified ingredients")
        }
    }
    
    // MARK: - Serving Controls Section
    private var servingControlsSection: some View {
        VStack(spacing: 16) {
            // Editable Serving Size and Quantity Controls
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SERVING SIZE")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .tracking(0.5)

                        // Serving size: Number + Unit selector
                        HStack(spacing: 8) {
                            // Number input (just the number)
                            TextField("100", text: $servingAmount)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 14, weight: .medium))
                                .frame(maxWidth: 80)

                            // Unit picker
                            Menu {
                                ForEach(servingUnitOptions, id: \.self) { unit in
                                    Button(unit) {
                                        // Convert the current value to the new unit
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
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("QUANTITY")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                        
                        // Quantity Selector
                        HStack(spacing: 6) {
                            ForEach(quantityOptions, id: \.self) { option in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        quantityMultiplier = option
                                    }
                                }) {
                                    Text(option == 0.5 ? "½" : "\(Int(option))")
                                        .font(.system(size: 12, weight: quantityMultiplier == option ? .bold : .medium))
                                        .foregroundColor(quantityMultiplier == option ? .white : .primary)
                                        .frame(width: 24, height: 24)
                                        .background(
                                            Circle()
                                                .fill(quantityMultiplier == option ? .blue : Color.gray.opacity(0.15))
                                        )
                                }
                            }
                        }
                    }
                }
                
                // Meal Time Selector (Diary only)
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
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(selectedMeal == meal ? .blue : Color.gray.opacity(0.15))
                                        )
                                }
                            }
                            
                            Spacer()
                        }
                    }
                }
                
                // Add Button
                Button(action: {
                    if destination == .useBy {
                        showingUseByAddSheet = true
                    } else {
                        addToFoodLog()
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(buttonText)
                            .font(.headline.weight(.semibold))
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Food Scores Section
    private var foodScoresSection: some View {
        HStack(spacing: 12) {
            // NutraSafe Grade Square
            if let ns = cachedNutraSafeGrade {
                Button(action: { showingNutraSafeInfo = true }) {
                    VStack(spacing: 6) {
                        Text("NUTRASAFE GRADE")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                        Text(ns.grade)
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(getNutraSafeColor(ns.grade))
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
                        .fill(getNutraSafeColor(ns.grade).opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(getNutraSafeColor(ns.grade).opacity(0.2), lineWidth: 1)
                        )
                )
            }
            
            // Sugar Score Square (only show if sugar data available)
            if sugarScore.grade != .unknown {
                Button(action: { showingSugarInfo = true }) {
                    VStack(spacing: 6) {
                        Text("SUGAR SCORE")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                        
                        Text(sugarScore.grade.rawValue)
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(sugarScore.color)
                        
                        Text(getSugarLevelDescription())
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(sugarScore.color.opacity(0.3 - 0.22))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(sugarScore.color.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
            }
        }
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
                                .font(.system(size: 11, weight: selectedWatchTab == tab ? .semibold : .medium))
                                .foregroundColor(selectedWatchTab == tab ? tab.color : .secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity)
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
            ScrollView {
                VStack(spacing: 0) {
                    switch selectedWatchTab {
                    case .additives:
                        additivesContent
                    case .allergies:
                        allergensContent
                    case .vitamins:
                        vitaminsContent
                    }
                }
            }
            .frame(maxHeight: 400) // Limit height to prevent tab overlap
            .background(Color(.systemBackground))
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Additive Analysis Content
    private var additivesContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // PERFORMANCE: Use cached additives computed once on appear
            let detectedAdditives = cachedAdditives ?? []
            
            if !detectedAdditives.isEmpty {
                VStack(spacing: 12) {
                    ForEach(detectedAdditives, id: \.name) { additive in
                        AdditiveCardView(additive: additive)
                    }
                }
            } else {
                Text("No additives detected in this food")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            }
        }
        .padding(16)
    }
    
    // MARK: - Allergens Watch Content  
    private var allergensContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            let potentialAllergens = getPotentialAllergens()

            if !potentialAllergens.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(potentialAllergens.sorted(), id: \.self) { allergen in
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
        }
        .padding(16)
    }
    
    // MARK: - Vitamins & Minerals Content (NEW SYSTEM)
    private var vitaminsContent: some View {
        let detectedNutrients = getDetectedNutrients()
        let micronutrientDB = MicronutrientDatabase.shared

        print("🎨 vitaminsContent rendering: \(detectedNutrients.count) nutrients")

        return VStack(alignment: .leading, spacing: 12) {
            if !detectedNutrients.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(detectedNutrients.enumerated()), id: \.element) { index, nutrientId in
                        if let nutrientInfo = micronutrientDB.getNutrientInfo(nutrientId) {
                            NutrientInfoCard(nutrientInfo: nutrientInfo)
                                .onAppear {
                                    print("  🃏 Card #\(index + 1) appeared: \(nutrientInfo.name)")
                                }
                        } else {
                            Text("⚠️ Could not load info for: \(nutrientId)")
                                .foregroundColor(.red)
                        }
                    }
                }
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
        }
        .padding(16)
    }
    
    // NEW: Detect nutrients from ingredients using NutrientDetector and MicronutrientDatabase
    private func getDetectedNutrients() -> [String] {
        print("🔬 getDetectedNutrients() called for food: \(food.name)")
        print("  📝 Ingredients: \(food.ingredients ?? [])")

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
            print("  ✅ Detected \(detectedNutrients.count) nutrients from ingredients: \(detectedNutrients)")
        } else {
            print("  ⚠️ No ingredients found")
        }

        print("  ✅ Total nutrients to display: \(detectedNutrients.count)")
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
            processedScore: cachedNutraSafeGrade?.grade ?? "",
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
        
        print("Updated portion for food item in \(originalMealType)")
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
            processedScore: cachedNutraSafeGrade?.grade ?? "",
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
        
        print("Moved food item from \(originalMealType) to \(selectedMeal)")
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
            processedScore: cachedNutraSafeGrade?.grade ?? "",
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
        
        print("Added new food item to \(selectedMeal)")
    }
    
    private func getCurrentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
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
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.date(from: dateString) ?? Date()
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

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .padding(.horizontal, 12)

                    VStack(alignment: .leading, spacing: 10) {
                        NutrientInfoRow(
                            icon: "info.circle.fill",
                            title: "What does it do?",
                            content: getNutrientFunction(),
                            color: .blue
                        )

                        NutrientInfoRow(
                            icon: "heart.fill",
                            title: "Health benefits",
                            content: getNutrientBenefits(),
                            color: .pink
                        )
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
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
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main header - always visible
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    // Nutrient name and category
                    VStack(alignment: .leading, spacing: 4) {
                        Text(nutrientInfo.name)
                            .font(.system(size: 17, weight: .semibold))
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
                        // Benefits section
                        if let benefits = nutrientInfo.benefits, !benefits.isEmpty {
                            benefitRow(icon: "sparkles", title: "Good for", content: formatBenefits(benefits))
                        }

                        // Daily intake
                        if let dailyIntake = nutrientInfo.recommendedDailyIntake, !dailyIntake.isEmpty {
                            benefitRow(icon: "calendar.badge.clock", title: "Recommended daily", content: dailyIntake)
                        }

                        // Common sources
                        if let sources = nutrientInfo.commonSources, !sources.isEmpty {
                            benefitRow(icon: "leaf.fill", title: "Also found in", content: formatSources(sources))
                        }

                        // Deficiency signs
                        if let deficiency = nutrientInfo.deficiencySigns, !deficiency.isEmpty {
                            let formattedDeficiency = formatBenefits(deficiency)
                            let isRareDeficiency = formattedDeficiency.lowercased().contains("rare") || formattedDeficiency.lowercased().contains("uncommon")

                            if isRareDeficiency {
                                benefitRow(icon: "info.circle.fill", title: "Deficiency", content: formattedDeficiency.capitalized, iconColor: .blue)
                            } else {
                                benefitRow(icon: "exclamationmark.triangle.fill", title: "Low levels may cause", content: formattedDeficiency, iconColor: .orange)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
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
                VStack(alignment: .leading, spacing: 16) {
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
                VStack(alignment: .leading, spacing: 16) {
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
                        Text(description(for: score.grade))
                            .font(.callout)
                            .foregroundColor(.primary)
                    }

                    Group {
                        Text("How we estimate it")
                            .font(.headline)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Based on sugar per 100g as declared.")
                            Text("• Thresholds align with public health guidance.")
                            Text("• Helps you spot foods that are higher in sugar.")
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
                        Text("Estimated sugar: \(String(format: "%.1f", food.sugar))g per 100g")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("Per serving: \(String(format: "%.1f", perServingSugar))g")
                            .font(.footnote)
                            .foregroundColor(.secondary)
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
