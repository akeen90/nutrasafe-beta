//
//  UKRetailerService.swift
//  NutraSafe Database Manager
//
//  Service for fetching comprehensive product data from UK retailers
//  Includes: nutrition, ingredients, images, and product details
//  Sources: Tesco, Sainsbury's, Ocado, and manufacturer databases
//

import Foundation

@MainActor
class UKRetailerService: ObservableObject {
    static let shared = UKRetailerService()

    @Published var isLoading = false
    @Published var lastError: String?

    private init() {}

    // MARK: - Main Lookup Function

    /// Fetch comprehensive product data from UK retailers
    /// Tries multiple sources and returns the best/most complete data
    func lookupProduct(barcode: String) async -> UKProductData? {
        isLoading = true
        lastError = nil

        defer { isLoading = false }

        var bestResult: UKProductData?

        // Try each UK retailer API/source
        // Priority: Tesco > Sainsbury's > Ocado > Manufacturer DB

        // 1. Try Tesco (most comprehensive UK data)
        if let tescoData = await fetchFromTesco(barcode: barcode) {
            bestResult = tescoData
            // If we got complete data, return early
            if tescoData.isComplete {
                return tescoData
            }
        }

        // 2. Try Sainsbury's
        if let sainsburysData = await fetchFromSainsburys(barcode: barcode) {
            if bestResult == nil {
                bestResult = sainsburysData
            } else {
                bestResult = mergeProductData(existing: bestResult!, new: sainsburysData)
            }
            if bestResult?.isComplete == true {
                return bestResult
            }
        }

        // 3. Try UPC Database (international manufacturer data)
        if let upcData = await fetchFromUPCDatabase(barcode: barcode) {
            if bestResult == nil {
                bestResult = upcData
            } else {
                bestResult = mergeProductData(existing: bestResult!, new: upcData)
            }
        }

        // 4. Try Nutritionix (comprehensive US/UK nutrition database)
        if let nutritionixData = await fetchFromNutritionix(barcode: barcode) {
            if bestResult == nil {
                bestResult = nutritionixData
            } else {
                bestResult = mergeProductData(existing: bestResult!, new: nutritionixData)
            }
        }

        return bestResult
    }

    // MARK: - Tesco API

    private func fetchFromTesco(barcode: String) async -> UKProductData? {
        // Tesco Product API endpoint
        // Note: Requires API key from dev.tescolabs.com for production use
        // Using public grocery search as fallback

        // Try the Tesco Labs API first
        let apiURL = "https://dev.tescolabs.com/product/?gtin=\(barcode)"

        if let url = URL(string: apiURL) {
            do {
                var request = URLRequest(url: url)
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.setValue("NutraSafe/1.0", forHTTPHeaderField: "User-Agent")
                request.timeoutInterval = 10

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    return nil
                }

                return parseTescoResponse(data)
            } catch {
                // Try alternative source
            }
        }

        return nil
    }

    private func parseTescoResponse(_ data: Data) -> UKProductData? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let products = json["products"] as? [[String: Any]],
              let product = products.first else {
            return nil
        }

        var result = UKProductData(source: .tesco)

        result.name = product["description"] as? String
        result.brand = product["brand"] as? String
        result.barcode = product["gtin"] as? String
        result.imageURL = product["image"] as? String

        // Parse nutrition per 100g
        if let nutrition = product["calcNutrition"] as? [String: Any] {
            result.caloriesPer100g = nutrition["energyKcal"] as? Double
            result.proteinPer100g = nutrition["protein"] as? Double
            result.carbsPer100g = nutrition["carbohydrates"] as? Double
            result.fatPer100g = nutrition["fat"] as? Double
            result.fibrePer100g = nutrition["fibre"] as? Double
            result.sugarPer100g = nutrition["sugars"] as? Double
            result.saltPer100g = nutrition["salt"] as? Double
            result.saturatedFatPer100g = nutrition["saturatedFat"] as? Double
        }

        // Parse ingredients
        if let ingredients = product["ingredients"] as? [String] {
            result.ingredients = ingredients
            result.ingredientsText = ingredients.joined(separator: ", ")
        } else if let ingredientsText = product["ingredients"] as? String {
            result.ingredientsText = ingredientsText
            result.ingredients = parseIngredientsText(ingredientsText)
        }

        // Parse allergens
        if let allergens = product["allergens"] as? [String] {
            result.allergens = allergens
        }

        return result
    }

    // MARK: - Sainsbury's

    private func fetchFromSainsburys(barcode: String) async -> UKProductData? {
        // Sainsbury's product API
        // Their API provides detailed nutrition and ingredient data

        let apiURL = "https://www.sainsburys.co.uk/groceries-api/gol-services/product/v1/product?filter[product_sap_id]=\(barcode)"

        guard let url = URL(string: apiURL) else { return nil }

        do {
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("NutraSafe/1.0", forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 10

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            return parseSainsburysResponse(data)
        } catch {
            return nil
        }
    }

    private func parseSainsburysResponse(_ data: Data) -> UKProductData? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let products = json["products"] as? [[String: Any]],
              let product = products.first else {
            return nil
        }

        var result = UKProductData(source: .sainsburys)

        result.name = product["name"] as? String
        result.brand = product["brand"] as? String

        // Image URL
        if let image = product["image"] as? String {
            result.imageURL = image
        }

        // Nutrition
        if let nutrition = product["nutritionInfo"] as? [String: Any] {
            if let per100g = nutrition["per100g"] as? [String: Any] {
                result.caloriesPer100g = per100g["energy"] as? Double
                result.proteinPer100g = per100g["protein"] as? Double
                result.carbsPer100g = per100g["carbohydrate"] as? Double
                result.fatPer100g = per100g["fat"] as? Double
                result.fibrePer100g = per100g["fibre"] as? Double
                result.sugarPer100g = per100g["sugars"] as? Double
                result.saltPer100g = per100g["salt"] as? Double
            }
        }

        // Ingredients
        if let ingredientsText = product["ingredients"] as? String {
            result.ingredientsText = ingredientsText
            result.ingredients = parseIngredientsText(ingredientsText)
        }

        return result
    }

    // MARK: - UPC Database (International)

    private func fetchFromUPCDatabase(barcode: String) async -> UKProductData? {
        // UPC Item DB - free API for barcode lookups
        let apiURL = "https://api.upcitemdb.com/prod/trial/lookup?upc=\(barcode)"

        guard let url = URL(string: apiURL) else { return nil }

        do {
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("NutraSafe/1.0", forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 10

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            return parseUPCDatabaseResponse(data)
        } catch {
            return nil
        }
    }

    private func parseUPCDatabaseResponse(_ data: Data) -> UKProductData? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["items"] as? [[String: Any]],
              let item = items.first else {
            return nil
        }

        var result = UKProductData(source: .upcDatabase)

        result.name = item["title"] as? String
        result.brand = item["brand"] as? String
        result.barcode = item["upc"] as? String
        result.category = item["category"] as? String

        // Images - often includes professional manufacturer images
        if let images = item["images"] as? [String], let firstImage = images.first {
            result.imageURL = firstImage
        }

        // Description
        if let description = item["description"] as? String {
            // Sometimes ingredients are in description
            if description.lowercased().contains("ingredients:") {
                let parts = description.components(separatedBy: "ingredients:")
                if parts.count > 1 {
                    result.ingredientsText = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }

        return result
    }

    // MARK: - Nutritionix API

    private func fetchFromNutritionix(barcode: String) async -> UKProductData? {
        // Nutritionix has comprehensive nutrition data
        // Note: Requires API key for production use
        let apiURL = "https://trackapi.nutritionix.com/v2/search/item?upc=\(barcode)"

        guard let url = URL(string: apiURL) else { return nil }

        do {
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("NutraSafe/1.0", forHTTPHeaderField: "User-Agent")
            // Would need: request.setValue(apiKey, forHTTPHeaderField: "x-app-key")
            request.timeoutInterval = 10

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            return parseNutritionixResponse(data)
        } catch {
            return nil
        }
    }

    private func parseNutritionixResponse(_ data: Data) -> UKProductData? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let foods = json["foods"] as? [[String: Any]],
              let food = foods.first else {
            return nil
        }

        var result = UKProductData(source: .nutritionix)

        result.name = food["food_name"] as? String
        result.brand = food["brand_name"] as? String

        // Photo - Nutritionix has high quality images
        if let photo = food["photo"] as? [String: Any],
           let highres = photo["highres"] as? String {
            result.imageURL = highres
        }

        // Detailed nutrition (typically per serving, need to convert)
        let servingWeight = food["serving_weight_grams"] as? Double ?? 100

        if let calories = food["nf_calories"] as? Double {
            result.caloriesPer100g = (calories / servingWeight) * 100
        }
        if let protein = food["nf_protein"] as? Double {
            result.proteinPer100g = (protein / servingWeight) * 100
        }
        if let carbs = food["nf_total_carbohydrate"] as? Double {
            result.carbsPer100g = (carbs / servingWeight) * 100
        }
        if let fat = food["nf_total_fat"] as? Double {
            result.fatPer100g = (fat / servingWeight) * 100
        }
        if let fiber = food["nf_dietary_fiber"] as? Double {
            result.fibrePer100g = (fiber / servingWeight) * 100
        }
        if let sugar = food["nf_sugars"] as? Double {
            result.sugarPer100g = (sugar / servingWeight) * 100
        }
        if let satFat = food["nf_saturated_fat"] as? Double {
            result.saturatedFatPer100g = (satFat / servingWeight) * 100
        }
        if let sodium = food["nf_sodium"] as? Double {
            // Convert sodium mg to salt g (salt = sodium * 2.5 / 1000)
            result.saltPer100g = ((sodium / servingWeight) * 100) * 2.5 / 1000
        }

        // Ingredients
        if let ingredients = food["nf_ingredient_statement"] as? String {
            result.ingredientsText = ingredients
            result.ingredients = parseIngredientsText(ingredients)
        }

        return result
    }

    // MARK: - Helpers

    private func parseIngredientsText(_ text: String) -> [String] {
        // Parse ingredients list, handling nested brackets
        var ingredients: [String] = []
        var current = ""
        var bracketDepth = 0

        for char in text {
            if char == "(" || char == "[" {
                bracketDepth += 1
                current.append(char)
            } else if char == ")" || char == "]" {
                bracketDepth -= 1
                current.append(char)
            } else if char == "," && bracketDepth == 0 {
                let ingredient = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !ingredient.isEmpty {
                    ingredients.append(ingredient)
                }
                current = ""
            } else {
                current.append(char)
            }
        }

        // Don't forget the last ingredient
        let lastIngredient = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !lastIngredient.isEmpty {
            ingredients.append(lastIngredient)
        }

        return ingredients
    }

    private func mergeProductData(existing: UKProductData, new: UKProductData) -> UKProductData {
        var merged = existing

        // Fill in missing fields from new data
        if merged.name == nil || merged.name?.isEmpty == true {
            merged.name = new.name
        }
        if merged.brand == nil || merged.brand?.isEmpty == true {
            merged.brand = new.brand
        }
        if merged.imageURL == nil || merged.imageURL?.isEmpty == true {
            merged.imageURL = new.imageURL
        }
        if merged.ingredientsText == nil || merged.ingredientsText?.isEmpty == true {
            merged.ingredientsText = new.ingredientsText
            merged.ingredients = new.ingredients
        }
        if merged.allergens == nil || merged.allergens?.isEmpty == true {
            merged.allergens = new.allergens
        }

        // Prefer existing nutrition data unless missing
        if merged.caloriesPer100g == nil { merged.caloriesPer100g = new.caloriesPer100g }
        if merged.proteinPer100g == nil { merged.proteinPer100g = new.proteinPer100g }
        if merged.carbsPer100g == nil { merged.carbsPer100g = new.carbsPer100g }
        if merged.fatPer100g == nil { merged.fatPer100g = new.fatPer100g }
        if merged.fibrePer100g == nil { merged.fibrePer100g = new.fibrePer100g }
        if merged.sugarPer100g == nil { merged.sugarPer100g = new.sugarPer100g }
        if merged.saltPer100g == nil { merged.saltPer100g = new.saltPer100g }
        if merged.saturatedFatPer100g == nil { merged.saturatedFatPer100g = new.saturatedFatPer100g }

        return merged
    }

    // MARK: - Verification

    /// Compare our food data against UK retailer data
    func verifyAgainstUKData(food: FoodItem) async -> UKVerificationResult {
        guard let barcode = food.barcode, !barcode.isEmpty else {
            return UKVerificationResult(
                verified: false,
                message: "No barcode available",
                ukData: nil,
                discrepancies: []
            )
        }

        guard let ukData = await lookupProduct(barcode: barcode) else {
            return UKVerificationResult(
                verified: false,
                message: "Product not found in UK retailer databases",
                ukData: nil,
                discrepancies: []
            )
        }

        var discrepancies: [UKDiscrepancy] = []

        // Compare nutrition values
        if let ukCalories = ukData.caloriesPer100g {
            let diff = abs(food.calories - ukCalories)
            if diff > 10 {
                discrepancies.append(UKDiscrepancy(
                    field: "calories",
                    ourValue: "\(Int(food.calories)) kcal",
                    ukValue: "\(Int(ukCalories)) kcal",
                    difference: diff
                ))
            }
        }

        if let ukProtein = ukData.proteinPer100g {
            let diff = abs(food.protein - ukProtein)
            if diff > 2 {
                discrepancies.append(UKDiscrepancy(
                    field: "protein",
                    ourValue: String(format: "%.1fg", food.protein),
                    ukValue: String(format: "%.1fg", ukProtein),
                    difference: diff
                ))
            }
        }

        if let ukCarbs = ukData.carbsPer100g {
            let diff = abs(food.carbs - ukCarbs)
            if diff > 3 {
                discrepancies.append(UKDiscrepancy(
                    field: "carbs",
                    ourValue: String(format: "%.1fg", food.carbs),
                    ukValue: String(format: "%.1fg", ukCarbs),
                    difference: diff
                ))
            }
        }

        if let ukFat = ukData.fatPer100g {
            let diff = abs(food.fat - ukFat)
            if diff > 2 {
                discrepancies.append(UKDiscrepancy(
                    field: "fat",
                    ourValue: String(format: "%.1fg", food.fat),
                    ukValue: String(format: "%.1fg", ukFat),
                    difference: diff
                ))
            }
        }

        let verified = discrepancies.isEmpty
        let message = verified ? "Verified against \(ukData.source.rawValue)" : "\(discrepancies.count) discrepancies found"

        return UKVerificationResult(
            verified: verified,
            message: message,
            ukData: ukData,
            discrepancies: discrepancies
        )
    }
}

// MARK: - Data Models

struct UKProductData {
    var source: UKDataSource
    var name: String?
    var brand: String?
    var barcode: String?
    var category: String?

    // Images
    var imageURL: String?
    var thumbnailURL: String?

    // Nutrition per 100g
    var caloriesPer100g: Double?
    var proteinPer100g: Double?
    var carbsPer100g: Double?
    var fatPer100g: Double?
    var fibrePer100g: Double?
    var sugarPer100g: Double?
    var saltPer100g: Double?
    var saturatedFatPer100g: Double?

    // Ingredients
    var ingredientsText: String?
    var ingredients: [String]?
    var allergens: [String]?

    var isComplete: Bool {
        name != nil &&
        caloriesPer100g != nil &&
        proteinPer100g != nil &&
        carbsPer100g != nil &&
        fatPer100g != nil &&
        (ingredientsText != nil || ingredients != nil)
    }

    var hasNutrition: Bool {
        caloriesPer100g != nil || proteinPer100g != nil
    }

    var hasIngredients: Bool {
        ingredientsText != nil || (ingredients != nil && !ingredients!.isEmpty)
    }

    var hasImage: Bool {
        imageURL != nil && !imageURL!.isEmpty
    }
}

enum UKDataSource: String {
    // UK Supermarkets
    case tesco = "Tesco"
    case sainsburys = "Sainsbury's"
    case asda = "ASDA"
    case morrisons = "Morrisons"
    case waitrose = "Waitrose"
    case ocado = "Ocado"
    case coOp = "Co-op"
    case aldi = "Aldi"
    case lidl = "Lidl"
    case iceland = "Iceland"
    case booths = "Booths"
    case budgens = "Budgens"
    // Nutrition databases
    case nutracheck = "Nutracheck"
    case nutritionix = "Nutritionix"
    case upcDatabase = "UPC Database"
    // Other sources
    case google = "Google"
    case manufacturer = "Manufacturer"

    var isProfessionalSource: Bool {
        switch self {
        case .tesco, .sainsburys, .asda, .morrisons, .waitrose, .ocado, .aldi, .lidl, .iceland, .booths, .budgens:
            // UK supermarkets have professional product images with white backgrounds
            return true
        case .nutracheck, .manufacturer:
            // Nutracheck and manufacturer data is high quality
            return true
        case .google:
            // Google can have mixed quality but often good
            return true
        case .coOp, .upcDatabase, .nutritionix:
            // These may have user-submitted or lower quality images
            return false
        }
    }
}

struct UKVerificationResult {
    let verified: Bool
    let message: String
    let ukData: UKProductData?
    let discrepancies: [UKDiscrepancy]
}

struct UKDiscrepancy {
    let field: String
    let ourValue: String
    let ukValue: String
    let difference: Double
}

// MARK: - FoodItem Extension

extension FoodItem {
    /// Update this food item with UK retailer data
    /// Handles per-unit vs per-100g conversion intelligently
    mutating func applyUKData(_ ukData: UKProductData) {
        if let name = ukData.name, !name.isEmpty {
            self.name = name
        }
        if let brand = ukData.brand, !brand.isEmpty {
            self.brand = brand
        }
        if let imageURL = ukData.imageURL, !imageURL.isEmpty {
            self.imageURL = imageURL
            self.thumbnailURL = ukData.thumbnailURL ?? imageURL
        }

        // UK retailer data is always per 100g
        // If our food was per-unit, we have two options:
        // 1. If we have a serving size, we could keep per-unit and convert (complex)
        // 2. Or switch to per-100g format (simpler, more consistent)
        // We'll switch to per-100g for consistency with UK standards

        let wasPerUnit = self.isPerUnit == true

        if let calories = ukData.caloriesPer100g {
            self.calories = calories
        }
        if let protein = ukData.proteinPer100g {
            self.protein = protein
        }
        if let carbs = ukData.carbsPer100g {
            self.carbs = carbs
        }
        if let fat = ukData.fatPer100g {
            self.fat = fat
        }
        if let fibre = ukData.fibrePer100g {
            self.fiber = fibre
        }
        if let sugar = ukData.sugarPer100g {
            self.sugar = sugar
        }
        if let salt = ukData.saltPer100g {
            // Convert salt to sodium (sodium = salt / 2.5 * 1000 for mg)
            self.sodium = salt / 2.5 * 1000
        }
        if let ingredientsText = ukData.ingredientsText {
            self.ingredientsText = ingredientsText
        }
        if let ingredients = ukData.ingredients {
            self.ingredients = ingredients
        }

        // Update to per-100g format since UK data is always per-100g
        if wasPerUnit {
            self.isPerUnit = false
            // Preserve the serving size info for reference
            if self.servingDescription == nil && self.servingSizeG != nil {
                self.servingDescription = "Serving: \(Int(self.servingSizeG!))g"
            }
        }

        self.source = "UK Retailer (\(ukData.source.rawValue))"
        self.isVerified = true
        self.lastUpdated = ISO8601DateFormatter().string(from: Date())
    }

    /// Apply UK data while preserving per-unit format
    /// Converts per-100g UK data to per-unit values using the serving size
    mutating func applyUKDataPreservingPerUnit(_ ukData: UKProductData) {
        guard isPerUnit == true, let servingSize = servingSizeG, servingSize > 0 else {
            // If not per-unit or no serving size, use standard apply
            applyUKData(ukData)
            return
        }

        // Apply non-nutrition fields
        if let name = ukData.name, !name.isEmpty {
            self.name = name
        }
        if let brand = ukData.brand, !brand.isEmpty {
            self.brand = brand
        }
        if let imageURL = ukData.imageURL, !imageURL.isEmpty {
            self.imageURL = imageURL
            self.thumbnailURL = ukData.thumbnailURL ?? imageURL
        }
        if let ingredientsText = ukData.ingredientsText {
            self.ingredientsText = ingredientsText
        }
        if let ingredients = ukData.ingredients {
            self.ingredients = ingredients
        }

        // Convert per-100g to per-unit using serving size
        let multiplier = servingSize / 100.0

        if let calories = ukData.caloriesPer100g {
            self.calories = calories * multiplier
        }
        if let protein = ukData.proteinPer100g {
            self.protein = protein * multiplier
        }
        if let carbs = ukData.carbsPer100g {
            self.carbs = carbs * multiplier
        }
        if let fat = ukData.fatPer100g {
            self.fat = fat * multiplier
        }
        if let fibre = ukData.fibrePer100g {
            self.fiber = fibre * multiplier
        }
        if let sugar = ukData.sugarPer100g {
            self.sugar = sugar * multiplier
        }
        if let salt = ukData.saltPer100g {
            self.sodium = (salt / 2.5 * 1000) * multiplier
        }

        self.source = "UK Retailer (\(ukData.source.rawValue))"
        self.isVerified = true
        self.lastUpdated = ISO8601DateFormatter().string(from: Date())
    }
}
