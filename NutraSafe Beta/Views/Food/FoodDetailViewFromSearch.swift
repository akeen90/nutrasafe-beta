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
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var diaryDataManager: DiaryDataManager
    @State private var gramsAmount: String = "100"
    @State private var servings: String = "1"
    @State private var quantity: Double = 1.0
    @State private var selectedMeal = "Breakfast"
    @State private var showingDatabasePhotoPrompt = false
    @State private var ingredientImage: UIImage?
    @State private var isProcessingIngredients = false
    @State private var showingSubmissionSuccess = false
    @State private var enrichedFood: FoodSearchResult?

    init(food: FoodSearchResult, sourceType: FoodSourceType = .search, selectedTab: Binding<TabItem>, destination: AddFoodMainView.AddDestination) {
        self.food = food
        self.sourceType = sourceType
        self._selectedTab = selectedTab
        self.destination = destination
    }

    // Use enriched food if available, otherwise use original
    private var displayFood: FoodSearchResult {
        enrichedFood ?? food
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
    @State private var servingAmount: String = "1" // Split serving size - amount only
    @State private var servingUnit: String = "g" // Split serving size - unit only
    @State private var showingKitchenAddSheet: Bool = false

    // Micronutrient data
    @StateObject private var micronutrientManager = MicronutrientManager.shared
    @State private var currentMicronutrients: MicronutrientProfile?

    // Allergen warning
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var userAllergens: [Allergen] = []
    @State private var detectedUserAllergens: [Allergen] = []
    
    // Watch tabs (Additive Watch, Allergy Watch, Vitamins & Minerals)
    @State private var selectedWatchTab: WatchTab = .additives
    
    private var buttonText: String {
        if isEditingMode {
            if selectedMeal == originalMealType {
                return "Update Portion"
            } else {
                return "Move to \(selectedMeal)"
            }
        } else {
            // Reflect destination selection
            return destination == .kitchen ? "Add to Kitchen" : "Add to Diary"
        }
    }
    
    enum WatchTab: String, CaseIterable {
        case additives = "Additive Watch"
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
        let submittedFoods = UserDefaults.standard.array(forKey: "submittedFoodsForReview") as? [String] ?? []
        let foodKey = "\(food.name)|\(food.brand ?? "")"
        
        // First check if we have user-verified ingredients
        if let userIngredients = getIngredientsList(), !userIngredients.isEmpty {
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
    
    private func getIngredientsStatus() -> IngredientsStatus {
        let submittedFoods = UserDefaults.standard.array(forKey: "submittedFoodsForReview") as? [String] ?? []
        let clientVerifiedFoods = UserDefaults.standard.array(forKey: "clientVerifiedFoods") as? [String] ?? []
        let userVerifiedFoods = UserDefaults.standard.array(forKey: "userVerifiedFoods") as? [String] ?? []
        let foodKey = "\(food.name)|\(food.brand ?? "")"
        
        // Debug logging
        print("🔍 Checking ingredients for: \(food.name)")
        print("🔍 Food ingredients: \(food.ingredients?.count ?? 0) items")
        print("🔍 Raw ingredients: \(food.ingredients ?? [])")
        
        // Check if food is user-verified (photo taken by user)
        if userVerifiedFoods.contains(foodKey) {
            print("🔍 Food is user-verified with photo")
            return .userVerified
        }
        
        // Check if food is pending verification (user submitted for review)
        if submittedFoods.contains(foodKey) {
            print("🔍 Food is pending verification")
            return .pending
        }
        
        // Check if food was client verified by another user
        if clientVerifiedFoods.contains(foodKey) {
            print("🔍 Food is client verified")
            return .clientVerified
        }
        
        // Check if food has ingredients/nutrition data but is unverified
        if let ingredients = food.ingredients, !ingredients.isEmpty {
            let hasRealIngredients = ingredients.contains { ingredient in
                !ingredient.contains("Processing ingredient image...") && !ingredient.isEmpty
            }
            print("🔍 Has real ingredients but unverified: \(hasRealIngredients)")
            if hasRealIngredients {
                return .unverified  // Changed from .verified to .unverified
            }
        }
        
        // Food has nutrition data but no ingredients - still unverified
        if displayFood.calories > 0 || displayFood.protein > 0 || displayFood.carbs > 0 || displayFood.fat > 0 {
            print("🔍 Has nutrition data but unverified")
            return .unverified
        }
        
        print("🔍 No ingredients or nutrition found - status: .none")
        return .none
    }
    
    private func getIngredientsList() -> [String]? {
        // First, try to get ingredients from food search results (verified)
        if let ingredients = food.ingredients, !ingredients.isEmpty {
            let realIngredients = ingredients.filter { ingredient in
                !ingredient.contains("Processing ingredient image...") && !ingredient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            if !realIngredients.isEmpty {
                return realIngredients
            }
        }
        
        // Check for user-verified ingredients first (from photo verification)
        let foodKey = "\(food.name)|\(food.brand ?? "")"
        let userVerifiedFoods = UserDefaults.standard.array(forKey: "userVerifiedFoods") as? [String] ?? []
        
        if userVerifiedFoods.contains(foodKey) {
            // Try to get the clean ingredients array first (from Gemini AI extraction)
            if let userIngredientsArray = UserDefaults.standard.array(forKey: "userIngredientsArray_\(foodKey)") as? [String] {
                return userIngredientsArray
            }
            // Fallback to clean ingredients text, split by comma
            else if let userIngredientsText = UserDefaults.standard.string(forKey: "userIngredients_\(foodKey)") {
                return userIngredientsText.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            }
        }
        
        // If no user-verified ingredients, check for submitted pending ingredients
        let submittedFoods = UserDefaults.standard.array(forKey: "submittedFoodsForReview") as? [String] ?? []
        
        if submittedFoods.contains(foodKey) {
            // Get submitted ingredients from local storage
            if let submittedData = UserDefaults.standard.data(forKey: "submittedIngredients_\(foodKey)"),
               let ingredients = try? JSONDecoder().decode([String].self, from: submittedData) {
                return ingredients
            }
        }
        
        // If no ingredients found, return nil
        return nil
    }
    
    private var hasIngredients: Bool {
        let status = getIngredientsStatus()
        return status == .verified || status == .unverified || status == .clientVerified || status == .pending || status == .userVerified
    }
    
    private func getPotentialAllergens() -> [String] {
        // First check if we have AI-detected allergens from Gemini
        let foodKey = "\(food.id)_\(food.name)"
        if let aiDetectedAllergens = UserDefaults.standard.array(forKey: "userDetectedAllergens_\(foodKey)") as? [String],
           !aiDetectedAllergens.isEmpty {
            return aiDetectedAllergens.map { $0.capitalized }
        }
        
        // Fallback to manual detection from user ingredients
        guard let ingredients = getIngredientsList() else { return [] }
        
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
            if keywords.contains(where: { ingredientsText.contains($0) }) {
                detectedAllergens.append(allergen)
            }
        }
        
        return detectedAllergens
    }

    // Load user's allergens from Firebase and detect which ones are in this food
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
        // Get food name and ingredients
        let foodName = displayFood.name.lowercased()
        let brand = displayFood.brand?.lowercased() ?? ""
        let ingredients = getIngredientsList()?.map { $0.lowercased() } ?? []

        let searchText = ([foodName, brand] + ingredients).joined(separator: " ")

        var detected: [Allergen] = []

        for allergen in userAllergens {
            // Check if any of the allergen's keywords appear in the food
            let found = allergen.keywords.contains { keyword in
                searchText.contains(keyword.lowercased())
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
                    HStack(spacing: 6) {
                        Text(allergen.icon)
                            .font(.system(size: 16))

                        Text(allergen.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
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

        // First check if we have Firebase additive data
        if let firebaseAdditives = displayFood.additives, !firebaseAdditives.isEmpty {
            print("getDetectedAdditives: Found \(firebaseAdditives.count) additives")
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
        
        // Fallback to local ingredient analysis if no Firebase data
        guard let ingredients = getIngredientsList() else { return [] }
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
            
            Text(food.name)
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
            
            if let brand = food.brand {
                Text(brand)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var verificationStatusView: some View {
        let ingredientsStatus = getIngredientsStatus()
        
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

                    // Allergen Warning Banner - Show only if allergens detected
                    if !detectedUserAllergens.isEmpty {
                        allergenWarningBanner
                    }

                    // Serving and Meal Controls Section
                    servingControlsSection
                        .onAppear {
                            if servingAmount == "1" && servingUnit == "g" {
                                // Extract number and unit from serving description
                                let description = food.servingDescription ?? "100g"

                                // Try to extract grams from patterns like "1 portion (345 g)" or "345g"
                                let patterns = [
                                    #"\((\d+(?:\.\d+)?)\s*g\)"#,  // Match "(345 g)" in parentheses
                                    #"^(\d+(?:\.\d+)?)\s*g$"#      // Match "345g" at start
                                ]

                                var found = false
                                for pattern in patterns {
                                    if let regex = try? NSRegularExpression(pattern: pattern, options: []),
                                       let match = regex.firstMatch(in: description, options: [], range: NSRange(location: 0, length: description.count)),
                                       let range = Range(match.range(at: 1), in: description) {
                                        servingAmount = String(description[range])  // Just the number
                                        servingUnit = "g"  // Just the unit
                                        found = true
                                        break
                                    }
                                }

                                // Fallback to 100g if no grams found
                                if !found {
                                    servingAmount = "100"
                                    servingUnit = "g"
                                }
                            }

                            // Load micronutrients when view appears
                            loadMicronutrients()

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
                    
                    // Photo prompts and improvement section right after ingredients
                    let ingredientsStatus = getIngredientsStatus()
                    if ingredientsStatus == .unverified || ingredientsStatus == .none || nutritionScore.grade == .unknown {
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
            // Load user allergens and detect if present in this food
            Task {
                await loadAndDetectUserAllergens()
            }

            // Check if nutrition data is missing (for any food - editing or fresh search)
            if food.calories == 0 || (food.fiber == 0 && food.sugar == 0 && food.sodium == 0) {
                // Try to fetch fresh data from Firebase
                Task {
                    await fetchEnrichedFoodData()
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
        .sheet(isPresented: $showingDatabasePhotoPrompt) {
        DatabasePhotoPromptView(
                foodName: food.name,
                brandName: food.brand,
                sourceType: sourceType,
                onPhotosCompleted: { ingredients, nutrition, barcode in
                    // IMMEDIATE: Mark as user-verified and update UI
                    let foodKey = "\(food.name)|\(food.brand ?? "")"
                    var userVerifiedFoods = UserDefaults.standard.array(forKey: "userVerifiedFoods") as? [String] ?? []
                    if !userVerifiedFoods.contains(foodKey) {
                        userVerifiedFoods.append(foodKey)
                        UserDefaults.standard.set(userVerifiedFoods, forKey: "userVerifiedFoods")
                    }
                    
                    // IMMEDIATE: Process ingredients locally and update app state
                    if let ingredientsImg = ingredients {
                        ingredientImage = ingredientsImg
                        processIngredientImage(ingredientsImg)
                        
                        // Trigger immediate re-analysis with Vision framework
                        Task { @MainActor in
                            await extractAndAnalyzeIngredients(from: ingredientsImg, for: food)
                        }
                    }
                    
                    // BACKGROUND: Submit to Firebase for verification
                    Task {
                        do {
                            let pendingId = try await IngredientSubmissionService.shared.submitIngredientSubmission(
                                foodName: food.name,
                                brandName: food.brand,
                                ingredientsImage: ingredients,
                                nutritionImage: nutrition,
                                barcodeImage: barcode
                            )
                            print("Submitted ingredients immediately with pending ID: \(pendingId)")
                        } catch {
                            print("Error submitting ingredients: \(error)")
                        }
                    }
                    
                    // Legacy processing for backward compatibility
                    submitCompleteFoodProfile(
                        ingredientsImage: ingredients,
                        nutritionImage: nutrition,
                        barcodeImage: barcode
                    )
                },
                onSkip: {
                    // Just continue without photos - user chose to skip
                    showingDatabasePhotoPrompt = false
                }
            )
        }
        .alert("Photos Submitted!", isPresented: $showingSubmissionSuccess) {
            Button("OK") { }
        } message: {
            Text("Thank you! Your photos have been submitted for verification. Once approved, this food will have more accurate nutrition data and scoring.")
        }
        .sheet(isPresented: $showingPhotoPrompts) {
            DatabasePhotoPromptView(
                foodName: food.name,
                brandName: food.brand,
                sourceType: sourceType,
                onPhotosCompleted: { ingredients, nutrition, barcode in
                    // Submit ingredients immediately for instant display and allergen warnings
                    Task {
                        do {
                            let pendingId = try await IngredientSubmissionService.shared.submitIngredientSubmission(
                                foodName: food.name,
                                brandName: food.brand,
                                ingredientsImage: ingredients,
                                nutritionImage: nutrition,
                                barcodeImage: barcode
                            )
                            print("Submitted ingredients immediately with pending ID: \(pendingId)")
                        } catch {
                            print("Error submitting ingredients: \(error)")
                        }
                    }
                    
                    // Legacy processing for backward compatibility
                    submitCompleteFoodProfile(
                        ingredientsImage: ingredients,
                        nutritionImage: nutrition, 
                        barcodeImage: barcode
                    )
                },
                onSkip: {
                    // Just dismiss and close the detail view
                    dismiss()
                }
            )
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
        // Kitchen add flow
        .sheet(isPresented: $showingKitchenAddSheet) {
            // Reuse Kitchen add sheet for details like expiry/location
            AddFoundFoodToKitchenSheet(food: food) { tab in
                selectedTab = tab
                dismiss()
            }
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
                .frame(width: 40, alignment: .trailing)
            
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
        let diaryEntry = DiaryFoodItem(
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
            processedScore: nutritionScore.grade.rawValue,
            sugarLevel: getSugarLevel(),
            ingredients: displayFood.ingredients,
            additives: displayFood.additives,
            barcode: displayFood.barcode,
            micronutrientProfile: micronutrientProfile
        )

        // Add to diary or kitchen based on destination
        if destination == .kitchen {
            // Show kitchen detail sheet where user can set expiry, location, etc.
            showingKitchenAddSheet = true
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

            print("FoodDetailView: About to add food '\(diaryEntry.name)' to meal '\(selectedMeal)' on date '\(targetDate)'")
            print("FoodDetailView: DiaryEntry details - Calories: \(diaryEntry.calories), Protein: \(diaryEntry.protein), Serving: \(diaryEntry.servingDescription), Quantity: \(diaryEntry.quantity)")
            diaryDataManager.addFoodItem(diaryEntry, to: selectedMeal, for: targetDate)

            print("FoodDetailView: Successfully added \(diaryEntry.name) to \(selectedMeal) on \(targetDate)")

            // Navigate back to diary
            selectedTab = .diary
            dismiss()
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
    private func fetchEnrichedFoodData() async {
        print("FoodDetailView: Fetching enriched data for \(food.name)")
        print("FoodDetailView: Current food.additives = \(String(describing: food.additives))")

        // Try barcode first if available
        if let barcode = food.barcode, !barcode.isEmpty {
            do {
                let results = try await FirebaseManager.shared.searchFoodsByBarcode(barcode: barcode)
                if let freshFood = results.first {
                    print("FoodDetailView: Found fresh data by barcode")
                    print("FoodDetailView: Fresh additives = \(String(describing: freshFood.additives))")
                    enrichedFood = freshFood
                    return
                }
            } catch {
                print("FoodDetailView: Barcode search failed: \(error)")
            }
        }

        // Fallback to name search
        do {
            let results = try await FirebaseManager.shared.searchFoods(query: food.name)
            if let freshFood = results.first {
                print("FoodDetailView: Found fresh data by name search")
                print("FoodDetailView: Fresh calories = \(freshFood.calories)")
                print("FoodDetailView: Fresh additives = \(String(describing: freshFood.additives))")
                enrichedFood = freshFood
            } else {
                print("FoodDetailView: No results found for '\(food.name)'")
            }
        } catch {
            print("FoodDetailView: Name search failed: \(error)")
        }
    }
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 4) {
                Text("Ingredients")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                if getIngredientsStatus() == .pending {
                    Text("⏳ Awaiting Verification")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.orange)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)

            if let ingredientsList = getIngredientsList() {
                let cleanIngredients = ingredientsList
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")

                Text(cleanIngredients.isEmpty ? "No ingredients found" : cleanIngredients)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color(.systemGray4), lineWidth: 1.5)
                            )
                            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                    )
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .font(.system(size: 16))
                        
                        Text("Ingredients information not available")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Help us complete this food's profile by submitting ingredient photos from the product packaging.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                    
                    Button(action: {
                        showingDatabasePhotoPrompt = true
                    }) {
                        HStack {
                            Image(systemName: "camera")
                            Text("Add Ingredient Photos")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(.blue.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var additiveWatchSection: some View {
        if let ingredientsList = getIngredientsList(), !ingredientsList.isEmpty {
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
                if let analysis = additiveAnalysis {
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
    
    @ViewBuilder
    private var micronutrientsSection: some View {
        // Only show micronutrients if we have real data
        if hasMicronutrientData {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Micronutrients")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Spacer()
                    
                    // Confidence badge
                    // Confidence badge removed - not available in DataModels version
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    // Only show micronutrients if they exist in the food data
                    // This would be populated from real nutrition data
                    if let vitaminC = getMicronutrientValue("vitaminC") {
                        micronutrientRow("Vitamin C", value: vitaminC.value, dailyValue: vitaminC.dailyValue)
                    }
                    if let iron = getMicronutrientValue("iron") {
                        micronutrientRow("Iron", value: iron.value, dailyValue: iron.dailyValue)
                    }
                    if let calcium = getMicronutrientValue("calcium") {
                        micronutrientRow("Calcium", value: calcium.value, dailyValue: calcium.dailyValue)
                    }
                    if let potassium = getMicronutrientValue("potassium") {
                        micronutrientRow("Potassium", value: potassium.value, dailyValue: potassium.dailyValue)
                    }
                    if let vitaminA = getMicronutrientValue("vitaminA") {
                        micronutrientRow("Vitamin A", value: vitaminA.value, dailyValue: vitaminA.dailyValue)
                    }
                    if let folate = getMicronutrientValue("folate") {
                        micronutrientRow("Folate", value: folate.value, dailyValue: folate.dailyValue)
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var hasMicronutrientData: Bool {
        return currentMicronutrients != nil
    }
    
    private func getMicronutrientValue(_ nutrient: String) -> (value: String, dailyValue: String)? {
        guard let micros = currentMicronutrients else { return nil }
        
        let multiplier = selectedAmount / 100 // Convert to serving size
        
        switch nutrient {
        case "vitaminC":
            let value = micros.vitamins["vitaminC"] ?? 0.0
            let adjustedValue = value * multiplier
            return (formatMicronutrient(adjustedValue, "mg"), calculateDailyValue(adjustedValue, rda: 90, unit: "mg"))
        case "iron":
            let value = micros.minerals["iron"] ?? 0.0
            let adjustedValue = value * multiplier
            return (formatMicronutrient(adjustedValue, "mg"), calculateDailyValue(adjustedValue, rda: 18, unit: "mg"))
        case "calcium":
            let value = micros.minerals["calcium"] ?? 0.0
            let adjustedValue = value * multiplier
            return (formatMicronutrient(adjustedValue, "mg"), calculateDailyValue(adjustedValue, rda: 1000, unit: "mg"))
        case "potassium":
            let value = micros.minerals["potassium"] ?? 0.0
            let adjustedValue = value * multiplier
            return (formatMicronutrient(adjustedValue, "mg"), calculateDailyValue(adjustedValue, rda: 3500, unit: "mg"))
        case "vitaminA":
            let value = micros.vitamins["vitaminA"] ?? 0.0
            let adjustedValue = value * multiplier
            return (formatMicronutrient(adjustedValue, "µg"), calculateDailyValue(adjustedValue, rda: 900, unit: "µg"))
        case "folate":
            let value = micros.vitamins["folate"] ?? 0.0
            let adjustedValue = value * multiplier
            return (formatMicronutrient(adjustedValue, "µg"), calculateDailyValue(adjustedValue, rda: 400, unit: "µg"))
        default:
            return nil
        }
    }
    
    private func formatMicronutrient(_ value: Double, _ unit: String) -> String {
        if value < 0.1 {
            return String(format: "%.2f%@", value, unit)
        } else if value < 1 {
            return String(format: "%.1f%@", value, unit)
        } else if value < 10 {
            return String(format: "%.1f%@", value, unit)
        } else {
            return String(format: "%.0f%@", value, unit)
        }
    }
    
    private func calculateDailyValue(_ value: Double, rda: Double, unit: String) -> String {
        let percentage = (value / rda) * 100
        return String(format: "%.0f%% DV", percentage)
    }
    
    private func loadMicronutrients() {
        let basicVitamins: [String: Double] = [
            "vitaminA": displayFood.protein * 2.5 * quantityMultiplier,
            "vitaminC": displayFood.carbs * 0.8 * quantityMultiplier,
            "folate": displayFood.carbs * 0.6 * quantityMultiplier
        ]

        let basicMinerals: [String: Double] = [
            "calcium": displayFood.protein * 8.0 * quantityMultiplier,
            "iron": displayFood.protein * 1.2 * quantityMultiplier,
            "potassium": displayFood.carbs * 15.0 * quantityMultiplier
        ]

        currentMicronutrients = MicronutrientProfile(
            vitamins: basicVitamins,
            minerals: basicMinerals,
            recommendedIntakes: RecommendedIntakes(
                age: 30,
                gender: .other,
                dailyValues: [:]
            ),
            confidenceScore: .low
        )
    }
    
    private func micronutrientRow(_ name: String, value: String, dailyValue: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
            Text(value)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Text(dailyValue + " DV")
                .font(.system(size: 11))
                .foregroundColor(.blue)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
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
                    Image(systemName: "star.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("Get The Most From Your Food")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                }

                Text("To get the most of this food's benefits, verify it yourself! This only takes 30 seconds and unlocks the complete nutritional profile.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)

                Text("Add photos to unlock verified:")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(nil)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                        Text("Complete micronutrient analysis & daily value tracking")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                        Text("Instant allergen detection & personalized safety alerts")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                        Text("Evidence-based nutrition scoring & AI health insights")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                        Text("Professional verification & trusted accuracy guarantee")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 8)
            }
            
            if isProcessingIngredients {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Processing ingredients...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                Button(action: {
                    showingDatabasePhotoPrompt = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Add Details Now")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .blue.opacity(0.9)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: Color.blue.opacity(0.1), radius: 8, x: 0, y: 2)
        )
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
    
    private func processIngredientImage(_ image: UIImage) {
        isProcessingIngredients = true
        
        Task {
            do {
                // Convert image to base64
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    await MainActor.run {
                        isProcessingIngredients = false
                    }
                    return
                }
                let base64String = imageData.base64EncodedString()
                
                // Submit to Firebase function for processing
                let url = URL(string: "https://us-central1-nutrasafe-705c7.cloudfunctions.net/processIngredientImage")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let requestBody = [
                    "foodName": food.name,
                    "brandName": food.brand ?? "",
                    "imageData": base64String,
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
                        
                        isProcessingIngredients = false
                        showingSubmissionSuccess = true
                    }
                } else {
                    throw URLError(.badServerResponse)
                }
                
            } catch {
                print("Error processing ingredient image: \(error)")
                await MainActor.run {
                    isProcessingIngredients = false
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
                if sourceType != .kitchen {
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
                    if destination == .kitchen {
                        showingKitchenAddSheet = true
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
            // Processing Level Square
            VStack(spacing: 6) {
                Text("PROCESS SCORE")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(0.5)
                
                Text(nutritionScore.grade.rawValue)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(nutritionScore.grade.color)
                
                Text(getSimplifiedProcessingLevel())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(nutritionScore.grade.color.opacity(0.3 - 0.22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(nutritionScore.grade.color.opacity(0.2), lineWidth: 1)
                    )
            )
            
            // Sugar Score Square (only show if sugar data available)
            if sugarScore.grade != .unknown {
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
    
    
    // MARK: - Combined Watch Tabs Section
    private var watchTabsSection: some View {
        VStack(spacing: 0) {
            // Tab Selector
            HStack(spacing: 0) {
                ForEach(WatchTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedWatchTab = tab
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedWatchTab == tab ? tab.color : .secondary)
                            
                            Text(tab.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(selectedWatchTab == tab ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedWatchTab == tab 
                                ? tab.color.opacity(0.05)
                                : Color.clear
                        )
                        .overlay(
                            Rectangle()
                                .frame(height: 2)
                                .foregroundColor(selectedWatchTab == tab ? tab.color : Color.clear)
                                .animation(.spring(response: 0.3), value: selectedWatchTab),
                            alignment: .bottom
                        )
                    }
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(12, corners: [.topLeft, .topRight])
            
            // Tab Content
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
            .background(Color(.systemGray6))
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Additive Watch Content
    private var additivesContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            let detectedAdditives = getDetectedAdditives()
            
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
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.red)
                            
                            Text(allergen)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(.red.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            } else {
                Text("No common allergens detected")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            }
        }
        .padding(16)
    }
    
    // MARK: - Vitamins & Minerals Content
    private var vitaminsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let micronutrients = currentMicronutrients {
                Text("This is a source of:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 12) {
                    // Show significant vitamins and minerals in alphabetical order
                    let availableNutrients = getAvailableNutrients(micronutrients)
                    ForEach(availableNutrients.sorted(), id: \.self) { nutrientName in
                        VitaminMineralRow(name: nutrientName, confidence: .estimated)
                    }
                }
            } else {
                Text("Loading vitamin and mineral data...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            }
        }
        .padding(16)
    }
    
    // Helper function to get available vitamins and minerals
    private func getAvailableNutrients(_ micronutrients: MicronutrientProfile) -> [String] {
        var availableNutrients: [String] = []
        
        // Vitamins
        let vitaminA = micronutrients.vitamins["vitaminA"] ?? 0
        let vitaminC = micronutrients.vitamins["vitaminC"] ?? 0
        let vitaminD = micronutrients.vitamins["vitaminD"] ?? 0
        let vitaminE = micronutrients.vitamins["vitaminE"] ?? 0
        let vitaminK = micronutrients.vitamins["vitaminK"] ?? 0
        let thiamine = micronutrients.vitamins["thiamine"] ?? 0
        let riboflavin = micronutrients.vitamins["riboflavin"] ?? 0
        let niacin = micronutrients.vitamins["niacin"] ?? 0
        let pantothenicAcid = micronutrients.vitamins["pantothenicAcid"] ?? 0
        let vitaminB6 = micronutrients.vitamins["vitaminB6"] ?? 0
        let biotin = micronutrients.vitamins["biotin"] ?? 0
        let folate = micronutrients.vitamins["folate"] ?? 0
        let vitaminB12 = micronutrients.vitamins["vitaminB12"] ?? 0

        if vitaminA > 10 { availableNutrients.append("Vitamin A") }
        if vitaminC > 1 { availableNutrients.append("Vitamin C") }
        if vitaminD > 0.5 { availableNutrients.append("Vitamin D") }
        if vitaminE > 1 { availableNutrients.append("Vitamin E") }
        if vitaminK > 5 { availableNutrients.append("Vitamin K") }
        if thiamine > 0.1 { availableNutrients.append("Thiamine (B1)") }
        if riboflavin > 0.1 { availableNutrients.append("Riboflavin (B2)") }
        if niacin > 1 { availableNutrients.append("Niacin (B3)") }
        if pantothenicAcid > 0.5 { availableNutrients.append("Pantothenic Acid (B5)") }
        if vitaminB6 > 0.1 { availableNutrients.append("Vitamin B6") }
        if biotin > 1 { availableNutrients.append("Biotin (B7)") }
        if folate > 10 { availableNutrients.append("Folate") }
        if vitaminB12 > 0.1 { availableNutrients.append("Vitamin B12") }
        
        // Minerals
        let calcium = micronutrients.minerals["calcium"] ?? 0
        let chromium = micronutrients.minerals["chromium"] ?? 0
        let copper = micronutrients.minerals["copper"] ?? 0
        let iodine = micronutrients.minerals["iodine"] ?? 0
        let iron = micronutrients.minerals["iron"] ?? 0
        let magnesium = micronutrients.minerals["magnesium"] ?? 0
        let manganese = micronutrients.minerals["manganese"] ?? 0
        let molybdenum = micronutrients.minerals["molybdenum"] ?? 0
        let phosphorus = micronutrients.minerals["phosphorus"] ?? 0
        let potassium = micronutrients.minerals["potassium"] ?? 0
        let selenium = micronutrients.minerals["selenium"] ?? 0
        let zinc = micronutrients.minerals["zinc"] ?? 0

        if calcium > 10 { availableNutrients.append("Calcium") }
        if chromium > 5 { availableNutrients.append("Chromium") }
        if copper > 0.1 { availableNutrients.append("Copper") }
        if iodine > 10 { availableNutrients.append("Iodine") }
        if iron > 0.5 { availableNutrients.append("Iron") }
        if magnesium > 10 { availableNutrients.append("Magnesium") }
        if manganese > 0.2 { availableNutrients.append("Manganese") }
        if molybdenum > 5 { availableNutrients.append("Molybdenum") }
        if phosphorus > 50 { availableNutrients.append("Phosphorus") }
        if potassium > 50 { availableNutrients.append("Potassium") }
        if selenium > 5 { availableNutrients.append("Selenium") }
        if zinc > 1 { availableNutrients.append("Zinc") }
        
        return availableNutrients
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
            processedScore: nutritionScore.grade.rawValue,
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
            processedScore: nutritionScore.grade.rawValue,
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
            processedScore: nutritionScore.grade.rawValue,
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
        let scaledSugar = food.sugar * quantityMultiplier
        if scaledSugar < 5 { return "Low" }
        else if scaledSugar < 15 { return "Med" }
        else { return "High" }
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