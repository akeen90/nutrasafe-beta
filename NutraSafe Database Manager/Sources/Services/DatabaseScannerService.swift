//
//  DatabaseScannerService.swift
//  NutraSafe Database Manager
//
//  Service for batch scanning the database to verify nutrition data
//  against online sources (Open Food Facts, UK retailers)
//

import Foundation

@MainActor
class DatabaseScannerService: ObservableObject {
    static let shared = DatabaseScannerService()

    // MARK: - Published State

    @Published var isScanning = false
    @Published var scanProgress: ScanProgress?
    @Published var scanResults: ScanResults?
    @Published var lastError: String?

    // Dependencies
    private let offService = OpenFoodFactsService.shared
    private let ukService = UKRetailerService.shared

    private var isCancelled = false

    private init() {}

    // MARK: - Scan Configuration

    struct ScanConfig {
        var verifyNutrition: Bool = true
        var verifyServingSizes: Bool = true
        var verifyBrands: Bool = true
        var checkForUpdates: Bool = true
        var onlyFoodsWithBarcode: Bool = true
        var skipRecentlyVerified: Bool = true
        var recentlyVerifiedDays: Int = 30
        var sources: Set<VerificationSource> = [.openFoodFacts, .ukRetailers]
        var maxConcurrentRequests: Int = 3
        var delayBetweenRequests: Double = 0.5 // seconds

        enum VerificationSource: String, CaseIterable {
            case openFoodFacts = "Open Food Facts"
            case ukRetailers = "UK Retailers"
        }
    }

    // MARK: - Scan Progress

    struct ScanProgress {
        var phase: ScanPhase
        var currentFood: String
        var processedCount: Int
        var totalCount: Int
        var issuesFound: Int
        var skippedCount: Int

        var percentComplete: Double {
            guard totalCount > 0 else { return 0 }
            return Double(processedCount) / Double(totalCount) * 100
        }

        enum ScanPhase: String {
            case preparing = "Preparing scan..."
            case scanning = "Scanning database..."
            case verifying = "Verifying against online sources..."
            case analysing = "Analysing results..."
            case complete = "Scan complete"
            case cancelled = "Scan cancelled"
        }
    }

    // MARK: - Scan Results

    struct ScanResults {
        var scannedCount: Int
        var issuesFound: Int
        var skippedCount: Int
        var duration: TimeInterval
        var issues: [FoodIssue]
        var summary: ScanSummary

        struct ScanSummary {
            var nutritionDiscrepancies: Int
            var servingSizeIssues: Int
            var brandMismatches: Int
            var outdatedData: Int
            var missingOnlineData: Int
        }
    }

    struct FoodIssue: Identifiable {
        let id = UUID()
        let food: FoodItem
        let issueType: IssueType
        let severity: IssueSeverity
        let description: String
        let details: [IssueDetail]
        let suggestedFix: SuggestedFix?
        let onlineData: OnlineData?

        enum IssueType: String, CaseIterable {
            case nutritionMismatch = "Nutrition Mismatch"
            case servingSizeMismatch = "Serving Size Mismatch"
            case brandMismatch = "Brand Mismatch"
            case outdatedData = "Outdated Data"
            case notFoundOnline = "Not Found Online"
            case significantDifference = "Significant Difference"
        }

        enum IssueSeverity: String {
            case low = "Low"
            case medium = "Medium"
            case high = "High"
            case critical = "Critical"

            var color: String {
                switch self {
                case .low: return "blue"
                case .medium: return "yellow"
                case .high: return "orange"
                case .critical: return "red"
                }
            }
        }

        struct IssueDetail {
            let field: String
            let ourValue: String
            let onlineValue: String
            let difference: String?
        }

        struct SuggestedFix {
            let action: FixAction
            let updatedValues: [String: Any]

            enum FixAction: String {
                case updateNutrition = "Update Nutrition Values"
                case updateServingSize = "Update Serving Size"
                case updateBrand = "Update Brand"
                case markForReview = "Mark for Manual Review"
                case ignore = "Ignore (Values Within Tolerance)"
            }
        }

        struct OnlineData {
            let source: String
            let lastUpdated: Date?
            let confidence: Double
            // Store full online product data for comprehensive comparison
            let offProduct: OFFProduct?
            let ukProductData: UKProductData?
        }
    }

    // MARK: - Scan Database

    /// Scan the entire database and verify against online sources
    func scanDatabase(foods: [FoodItem], config: ScanConfig = ScanConfig()) async -> ScanResults {
        isScanning = true
        isCancelled = false
        lastError = nil

        let startTime = Date()
        var issues: [FoodIssue] = []
        var processedCount = 0
        var skippedCount = 0

        // Filter foods based on config
        var foodsToScan = foods

        if config.onlyFoodsWithBarcode {
            foodsToScan = foodsToScan.filter { food in
                guard let barcode = food.barcode, !barcode.isEmpty else { return false }
                return barcode.count >= 8 // Valid EAN/UPC barcodes are at least 8 digits
            }
        }

        if config.skipRecentlyVerified {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -config.recentlyVerifiedDays, to: Date())!
            foodsToScan = foodsToScan.filter { food in
                guard let lastUpdated = food.lastUpdated else { return true }
                // Parse ISO8601 date
                let formatter = ISO8601DateFormatter()
                if let date = formatter.date(from: lastUpdated) {
                    return date < cutoffDate
                }
                return true
            }
        }

        let totalCount = foodsToScan.count
        skippedCount = foods.count - totalCount

        // Update progress
        scanProgress = ScanProgress(
            phase: .preparing,
            currentFood: "",
            processedCount: 0,
            totalCount: totalCount,
            issuesFound: 0,
            skippedCount: skippedCount
        )

        // Process foods in batches to avoid overwhelming APIs
        let batchSize = config.maxConcurrentRequests

        for batchStart in stride(from: 0, to: foodsToScan.count, by: batchSize) {
            if isCancelled {
                scanProgress?.phase = .cancelled
                break
            }

            let batchEnd = min(batchStart + batchSize, foodsToScan.count)
            let batch = Array(foodsToScan[batchStart..<batchEnd])

            // Process batch concurrently
            await withTaskGroup(of: FoodIssue?.self) { group in
                for food in batch {
                    group.addTask {
                        await self.verifyFood(food, config: config)
                    }
                }

                for await result in group {
                    if let issue = result {
                        issues.append(issue)
                    }
                    processedCount += 1

                    await MainActor.run {
                        self.scanProgress?.processedCount = processedCount
                        self.scanProgress?.issuesFound = issues.count
                        self.scanProgress?.phase = .verifying
                        if let lastFood = batch.last {
                            self.scanProgress?.currentFood = lastFood.name
                        }
                    }
                }
            }

            // Delay between batches to respect rate limits
            if batchEnd < foodsToScan.count {
                try? await Task.sleep(nanoseconds: UInt64(config.delayBetweenRequests * 1_000_000_000))
            }
        }

        // Compile results
        scanProgress?.phase = .analysing

        let duration = Date().timeIntervalSince(startTime)

        let summary = ScanResults.ScanSummary(
            nutritionDiscrepancies: issues.filter { $0.issueType == .nutritionMismatch }.count,
            servingSizeIssues: issues.filter { $0.issueType == .servingSizeMismatch }.count,
            brandMismatches: issues.filter { $0.issueType == .brandMismatch }.count,
            outdatedData: issues.filter { $0.issueType == .outdatedData }.count,
            missingOnlineData: issues.filter { $0.issueType == .notFoundOnline }.count
        )

        let results = ScanResults(
            scannedCount: processedCount,
            issuesFound: issues.count,
            skippedCount: skippedCount,
            duration: duration,
            issues: issues,
            summary: summary
        )

        scanProgress?.phase = .complete
        scanResults = results
        isScanning = false

        return results
    }

    /// Cancel the current scan
    func cancelScan() {
        isCancelled = true
    }

    // MARK: - Verify Single Food

    private func verifyFood(_ food: FoodItem, config: ScanConfig) async -> FoodIssue? {
        guard let barcode = food.barcode, !barcode.isEmpty else { return nil }

        var details: [FoodIssue.IssueDetail] = []
        var severity: FoodIssue.IssueSeverity = .low
        var issueType: FoodIssue.IssueType = .nutritionMismatch
        var onlineSource = ""
        var confidence = 0.0
        var foundOffProduct: OFFProduct?
        var foundUKData: UKProductData?

        // Try Open Food Facts first
        if config.sources.contains(.openFoodFacts) {
            if let offProduct = await offService.lookupProduct(barcode: barcode) {
                foundOffProduct = offProduct
                onlineSource = "Open Food Facts"
                confidence = 0.8

                // Compare nutrition values
                if config.verifyNutrition, let nutriments = offProduct.nutriments {
                    let nutritionDetails = compareNutrition(food: food, offNutriments: nutriments)
                    details.append(contentsOf: nutritionDetails)

                    // Determine severity based on differences
                    let significantDiffs = nutritionDetails.filter { detail in
                        if let diff = detail.difference, let diffValue = Double(diff.replacingOccurrences(of: "%", with: "")) {
                            return abs(diffValue) > 20
                        }
                        return false
                    }

                    if significantDiffs.count >= 3 {
                        severity = .critical
                    } else if significantDiffs.count >= 2 {
                        severity = .high
                    } else if significantDiffs.count >= 1 {
                        severity = .medium
                    }
                }

                // Compare serving size
                if config.verifyServingSizes {
                    if let servingDetails = compareServingSize(food: food, offProduct: offProduct) {
                        details.append(servingDetails)
                        if severity == .low {
                            severity = .medium
                            issueType = .servingSizeMismatch
                        }
                    }
                }

                // Compare brand
                if config.verifyBrands {
                    if let brandDetails = compareBrand(food: food, offProduct: offProduct) {
                        details.append(brandDetails)
                        if issueType == .nutritionMismatch && details.count == 1 {
                            issueType = .brandMismatch
                        }
                    }
                }

            } else {
                // Not found in Open Food Facts, try UK retailers
                if config.sources.contains(.ukRetailers) {
                    if let ukData = await ukService.lookupProduct(barcode: barcode) {
                        foundUKData = ukData
                        onlineSource = ukData.source.rawValue
                        confidence = 0.9

                        // Compare with UK retailer data
                        let nutritionDetails = compareNutritionWithUK(food: food, ukData: ukData)
                        details.append(contentsOf: nutritionDetails)

                        let significantDiffs = nutritionDetails.filter { detail in
                            if let diff = detail.difference, let diffValue = Double(diff.replacingOccurrences(of: "%", with: "")) {
                                return abs(diffValue) > 15
                            }
                            return false
                        }

                        if significantDiffs.count >= 2 {
                            severity = .high
                        } else if significantDiffs.count >= 1 {
                            severity = .medium
                        }
                    } else {
                        // Not found online at all
                        issueType = .notFoundOnline
                        details.append(FoodIssue.IssueDetail(
                            field: "Online Lookup",
                            ourValue: food.name,
                            onlineValue: "Not found",
                            difference: nil
                        ))
                        return FoodIssue(
                            food: food,
                            issueType: issueType,
                            severity: .low,
                            description: "Product not found in online databases",
                            details: details,
                            suggestedFix: nil,
                            onlineData: nil
                        )
                    }
                }
            }
        }

        // Only return an issue if there are actual discrepancies
        guard !details.isEmpty else { return nil }

        // Build suggested fix with actual values
        var suggestedFix: FoodIssue.SuggestedFix?
        var updatedValues: [String: Any] = [:]

        if let offProduct = foundOffProduct, let nutriments = offProduct.nutriments {
            if let cal = nutriments.energy_kcal_100g ?? nutriments.energy_kcal { updatedValues["calories"] = cal }
            if let pro = nutriments.proteins_100g ?? nutriments.proteins { updatedValues["protein"] = pro }
            if let carb = nutriments.carbohydrates_100g ?? nutriments.carbohydrates { updatedValues["carbs"] = carb }
            if let fat = nutriments.fat_100g ?? nutriments.fat { updatedValues["fat"] = fat }
            if let fiber = nutriments.fiber_100g ?? nutriments.fiber { updatedValues["fiber"] = fiber }
            if let sugar = nutriments.sugars_100g ?? nutriments.sugars { updatedValues["sugar"] = sugar }
            if let salt = nutriments.salt_100g ?? nutriments.salt { updatedValues["sodium"] = salt / 2.5 * 1000 }
            if let satFat = nutriments.saturated_fat_100g ?? nutriments.saturated_fat { updatedValues["saturatedFat"] = satFat }
            if let brand = offProduct.brands { updatedValues["brand"] = brand }
            if let ingredients = offProduct.ingredients_text_en ?? offProduct.ingredients_text { updatedValues["ingredientsText"] = ingredients }
            if let servingSize = offProduct.serving_size { updatedValues["servingDescription"] = servingSize }
        } else if let ukData = foundUKData {
            if let cal = ukData.caloriesPer100g { updatedValues["calories"] = cal }
            if let pro = ukData.proteinPer100g { updatedValues["protein"] = pro }
            if let carb = ukData.carbsPer100g { updatedValues["carbs"] = carb }
            if let fat = ukData.fatPer100g { updatedValues["fat"] = fat }
            if let fiber = ukData.fibrePer100g { updatedValues["fiber"] = fiber }
            if let sugar = ukData.sugarPer100g { updatedValues["sugar"] = sugar }
            if let salt = ukData.saltPer100g { updatedValues["sodium"] = salt / 2.5 * 1000 }
            if let satFat = ukData.saturatedFatPer100g { updatedValues["saturatedFat"] = satFat }
            if let brand = ukData.brand { updatedValues["brand"] = brand }
            if let ingredients = ukData.ingredientsText { updatedValues["ingredientsText"] = ingredients }
        }

        if severity == .high || severity == .critical || !updatedValues.isEmpty {
            suggestedFix = FoodIssue.SuggestedFix(
                action: .updateNutrition,
                updatedValues: updatedValues
            )
        }

        let onlineData = FoodIssue.OnlineData(
            source: onlineSource,
            lastUpdated: nil,
            confidence: confidence,
            offProduct: foundOffProduct,
            ukProductData: foundUKData
        )

        let description = generateIssueDescription(issueType: issueType, detailsCount: details.count, severity: severity)

        return FoodIssue(
            food: food,
            issueType: issueType,
            severity: severity,
            description: description,
            details: details,
            suggestedFix: suggestedFix,
            onlineData: onlineData
        )
    }

    // MARK: - Comparison Helpers

    private func compareNutrition(food: FoodItem, offNutriments: OFFNutriments) -> [FoodIssue.IssueDetail] {
        var details: [FoodIssue.IssueDetail] = []

        // Calories
        if let offCalories = offNutriments.energy_kcal_100g ?? offNutriments.energy_kcal {
            let diff = food.calories - offCalories
            let percentDiff = food.calories > 0 ? (diff / food.calories) * 100 : 0

            if abs(diff) > 10 {
                details.append(FoodIssue.IssueDetail(
                    field: "Calories",
                    ourValue: "\(Int(food.calories)) kcal",
                    onlineValue: "\(Int(offCalories)) kcal",
                    difference: String(format: "%.1f%%", percentDiff)
                ))
            }
        }

        // Protein
        if let offProtein = offNutriments.proteins_100g ?? offNutriments.proteins {
            let diff = food.protein - offProtein
            let percentDiff = food.protein > 0 ? (diff / food.protein) * 100 : 0

            if abs(diff) > 2 {
                details.append(FoodIssue.IssueDetail(
                    field: "Protein",
                    ourValue: String(format: "%.1fg", food.protein),
                    onlineValue: String(format: "%.1fg", offProtein),
                    difference: String(format: "%.1f%%", percentDiff)
                ))
            }
        }

        // Carbs
        if let offCarbs = offNutriments.carbohydrates_100g ?? offNutriments.carbohydrates {
            let diff = food.carbs - offCarbs
            let percentDiff = food.carbs > 0 ? (diff / food.carbs) * 100 : 0

            if abs(diff) > 3 {
                details.append(FoodIssue.IssueDetail(
                    field: "Carbohydrates",
                    ourValue: String(format: "%.1fg", food.carbs),
                    onlineValue: String(format: "%.1fg", offCarbs),
                    difference: String(format: "%.1f%%", percentDiff)
                ))
            }
        }

        // Fat
        if let offFat = offNutriments.fat_100g ?? offNutriments.fat {
            let diff = food.fat - offFat
            let percentDiff = food.fat > 0 ? (diff / food.fat) * 100 : 0

            if abs(diff) > 2 {
                details.append(FoodIssue.IssueDetail(
                    field: "Fat",
                    ourValue: String(format: "%.1fg", food.fat),
                    onlineValue: String(format: "%.1fg", offFat),
                    difference: String(format: "%.1f%%", percentDiff)
                ))
            }
        }

        // Sugar
        if let offSugar = offNutriments.sugars_100g ?? offNutriments.sugars {
            let diff = food.sugar - offSugar
            let percentDiff = food.sugar > 0 ? (diff / food.sugar) * 100 : 0

            if abs(diff) > 2 {
                details.append(FoodIssue.IssueDetail(
                    field: "Sugar",
                    ourValue: String(format: "%.1fg", food.sugar),
                    onlineValue: String(format: "%.1fg", offSugar),
                    difference: String(format: "%.1f%%", percentDiff)
                ))
            }
        }

        // Fiber
        if let offFiber = offNutriments.fiber_100g ?? offNutriments.fiber {
            let diff = food.fiber - offFiber
            let percentDiff = food.fiber > 0 ? (diff / food.fiber) * 100 : 0

            if abs(diff) > 1 {
                details.append(FoodIssue.IssueDetail(
                    field: "Fibre",
                    ourValue: String(format: "%.1fg", food.fiber),
                    onlineValue: String(format: "%.1fg", offFiber),
                    difference: String(format: "%.1f%%", percentDiff)
                ))
            }
        }

        return details
    }

    private func compareNutritionWithUK(food: FoodItem, ukData: UKProductData) -> [FoodIssue.IssueDetail] {
        var details: [FoodIssue.IssueDetail] = []

        // Compare calories
        if let ukCalories = ukData.caloriesPer100g {
            let diff = food.calories - ukCalories
            let percentDiff = food.calories > 0 ? (diff / food.calories) * 100 : 0

            if abs(diff) > 10 {
                details.append(FoodIssue.IssueDetail(
                    field: "Calories",
                    ourValue: "\(Int(food.calories)) kcal",
                    onlineValue: "\(Int(ukCalories)) kcal",
                    difference: String(format: "%.1f%%", percentDiff)
                ))
            }
        }

        // Compare protein
        if let ukProtein = ukData.proteinPer100g {
            let diff = food.protein - ukProtein
            let percentDiff = food.protein > 0 ? (diff / food.protein) * 100 : 0

            if abs(diff) > 2 {
                details.append(FoodIssue.IssueDetail(
                    field: "Protein",
                    ourValue: String(format: "%.1fg", food.protein),
                    onlineValue: String(format: "%.1fg", ukProtein),
                    difference: String(format: "%.1f%%", percentDiff)
                ))
            }
        }

        // Compare carbs
        if let ukCarbs = ukData.carbsPer100g {
            let diff = food.carbs - ukCarbs
            let percentDiff = food.carbs > 0 ? (diff / food.carbs) * 100 : 0

            if abs(diff) > 3 {
                details.append(FoodIssue.IssueDetail(
                    field: "Carbohydrates",
                    ourValue: String(format: "%.1fg", food.carbs),
                    onlineValue: String(format: "%.1fg", ukCarbs),
                    difference: String(format: "%.1f%%", percentDiff)
                ))
            }
        }

        // Compare fat
        if let ukFat = ukData.fatPer100g {
            let diff = food.fat - ukFat
            let percentDiff = food.fat > 0 ? (diff / food.fat) * 100 : 0

            if abs(diff) > 2 {
                details.append(FoodIssue.IssueDetail(
                    field: "Fat",
                    ourValue: String(format: "%.1fg", food.fat),
                    onlineValue: String(format: "%.1fg", ukFat),
                    difference: String(format: "%.1f%%", percentDiff)
                ))
            }
        }

        return details
    }

    private func compareServingSize(food: FoodItem, offProduct: OFFProduct) -> FoodIssue.IssueDetail? {
        // IMPORTANT: Skip per-unit foods - serving size comparison only makes sense for per-100g foods
        if food.isPerUnit == true {
            return nil
        }

        guard let offServing = offProduct.serving_size, !offServing.isEmpty else { return nil }

        let ourServing = food.servingDescription ?? (food.servingSizeG != nil ? "\(Int(food.servingSizeG!))g" : "100g")

        // Extract numeric value from serving size strings
        let offServingGrams = extractServingSizeGrams(from: offServing)
        let ourServingGrams = food.servingSizeG ?? extractServingSizeGrams(from: ourServing)

        // CRITICAL: Check if the online "serving size" is actually a pack size
        // Pack sizes are typically > 200g for snacks/cereals, or match "quantity" field
        if let offGrams = offServingGrams {
            // Check if this looks like a pack size rather than a serving size
            if isLikelyPackSize(grams: offGrams, productName: food.name, offProduct: offProduct) {
                // The online source has pack size, not serving size - don't flag as mismatch
                // unless our serving size is also suspiciously large
                if let ourGrams = ourServingGrams, isLikelyPackSize(grams: ourGrams, productName: food.name, offProduct: nil) {
                    // Both look like pack sizes - still compare
                    return createServingSizeDetail(ourServing: ourServing, offServing: offServing)
                }
                // Online is pack size, ours is reasonable serving size - don't flag
                return nil
            }
        }

        // Both seem like reasonable serving sizes - compare them
        if let offGrams = offServingGrams, let ourGrams = ourServingGrams {
            let diff = abs(offGrams - ourGrams)
            let percentDiff = ourGrams > 0 ? (diff / ourGrams) * 100 : 0

            // Allow 20% tolerance for serving size differences
            if percentDiff > 20 && diff > 10 {
                return FoodIssue.IssueDetail(
                    field: "Serving Size",
                    ourValue: ourServing,
                    onlineValue: offServing,
                    difference: String(format: "%.0f%%", percentDiff)
                )
            }
            return nil
        }

        // Fallback to string comparison if we couldn't parse numbers
        if !ourServing.lowercased().contains(offServing.lowercased()) &&
           !offServing.lowercased().contains(ourServing.lowercased()) {
            return createServingSizeDetail(ourServing: ourServing, offServing: offServing)
        }

        return nil
    }

    private func createServingSizeDetail(ourServing: String, offServing: String) -> FoodIssue.IssueDetail {
        return FoodIssue.IssueDetail(
            field: "Serving Size",
            ourValue: ourServing,
            onlineValue: offServing,
            difference: nil
        )
    }

    /// Extract the numeric gram value from a serving size string
    /// Handles formats like "30g", "250ml", "1 portion (45g)", "100 g", etc.
    private func extractServingSizeGrams(from servingString: String) -> Double? {
        let lowercased = servingString.lowercased()

        // Pattern to match numbers followed by g, ml, or gram/ml
        let patterns = [
            #"(\d+(?:\.\d+)?)\s*g(?:rams?)?\b"#,     // 30g, 30 g, 30grams
            #"(\d+(?:\.\d+)?)\s*ml\b"#,              // 250ml (treat ml same as g for liquids)
            #"\((\d+(?:\.\d+)?)\s*g\)"#,             // (45g) in parentheses
            #"(\d+(?:\.\d+)?)\s*(?:gram|grams)"#     // 30 grams
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(lowercased.startIndex..<lowercased.endIndex, in: lowercased)
                if let match = regex.firstMatch(in: lowercased, options: [], range: range) {
                    if let valueRange = Range(match.range(at: 1), in: lowercased) {
                        if let value = Double(lowercased[valueRange]) {
                            return value
                        }
                    }
                }
            }
        }

        return nil
    }

    /// Determine if a gram value is likely a pack size rather than a serving size
    private func isLikelyPackSize(grams: Double, productName: String, offProduct: OFFProduct?) -> Bool {
        let nameLower = productName.lowercased()

        // Check against product quantity if available (e.g., "500g" pack)
        if let quantity = offProduct?.quantity {
            let quantityGrams = extractServingSizeGrams(from: quantity)
            if let qGrams = quantityGrams, abs(qGrams - grams) < 10 {
                // The "serving size" matches the pack quantity - it's pack size
                return true
            }
        }

        // Category-specific thresholds
        // Snacks, chocolate, biscuits - serving usually 15-60g
        let snackTerms = ["chocolate", "biscuit", "crisp", "chip", "sweet", "candy", "bar", "snack", "cookie"]
        if snackTerms.contains(where: { nameLower.contains($0) }) {
            return grams > 150 // Anything over 150g is likely pack size for snacks
        }

        // Cereals - serving usually 30-50g
        let cerealTerms = ["cereal", "muesli", "granola", "oat", "porridge", "flake"]
        if cerealTerms.contains(where: { nameLower.contains($0) }) {
            return grams > 100 // Anything over 100g is likely pack size for cereals
        }

        // Drinks - serving usually 200-330ml
        let drinkTerms = ["drink", "juice", "cola", "soda", "water", "milk", "smoothie"]
        if drinkTerms.contains(where: { nameLower.contains($0) }) {
            return grams > 500 // Large bottles are pack sizes
        }

        // Ready meals - serving usually 200-400g
        let mealTerms = ["meal", "ready", "dinner", "lunch", "pasta", "rice", "curry"]
        if mealTerms.contains(where: { nameLower.contains($0) }) {
            return grams > 600 // Very large is pack size
        }

        // Generic threshold - anything over 300g is suspicious for a single serving
        return grams > 300
    }

    private func compareBrand(food: FoodItem, offProduct: OFFProduct) -> FoodIssue.IssueDetail? {
        guard let offBrand = offProduct.brands, !offBrand.isEmpty else { return nil }
        guard let ourBrand = food.brand, !ourBrand.isEmpty else {
            // We're missing brand, but OFF has it
            return FoodIssue.IssueDetail(
                field: "Brand",
                ourValue: "Missing",
                onlineValue: offBrand,
                difference: nil
            )
        }

        // Case-insensitive comparison
        if !ourBrand.lowercased().contains(offBrand.lowercased()) &&
           !offBrand.lowercased().contains(ourBrand.lowercased()) {
            return FoodIssue.IssueDetail(
                field: "Brand",
                ourValue: ourBrand,
                onlineValue: offBrand,
                difference: nil
            )
        }

        return nil
    }

    private func generateIssueDescription(issueType: FoodIssue.IssueType, detailsCount: Int, severity: FoodIssue.IssueSeverity) -> String {
        switch issueType {
        case .nutritionMismatch:
            return "\(detailsCount) nutrition value(s) differ from online data"
        case .servingSizeMismatch:
            return "Serving size doesn't match online data"
        case .brandMismatch:
            return "Brand name differs from online data"
        case .outdatedData:
            return "Data may be outdated compared to online sources"
        case .notFoundOnline:
            return "Product not found in online databases"
        case .significantDifference:
            return "Significant differences found (\(severity.rawValue) severity)"
        }
    }

    // MARK: - Apply Fixes

    /// Apply suggested fixes to a food item
    func applyFix(to food: inout FoodItem, issue: FoodIssue) {
        guard let fix = issue.suggestedFix else { return }

        switch fix.action {
        case .updateNutrition:
            // Apply nutrition updates from suggestedFix.updatedValues
            for (key, value) in fix.updatedValues {
                switch key {
                case "calories":
                    if let cal = value as? Double { food.calories = cal }
                case "protein":
                    if let pro = value as? Double { food.protein = pro }
                case "carbs":
                    if let car = value as? Double { food.carbs = car }
                case "fat":
                    if let fat = value as? Double { food.fat = fat }
                case "sugar":
                    if let sug = value as? Double { food.sugar = sug }
                case "fiber":
                    if let fib = value as? Double { food.fiber = fib }
                default:
                    break
                }
            }
        case .updateServingSize:
            if let serving = fix.updatedValues["servingDescription"] as? String {
                food.servingDescription = serving
            }
            if let servingG = fix.updatedValues["servingSizeG"] as? Double {
                food.servingSizeG = servingG
            }
        case .updateBrand:
            if let brand = fix.updatedValues["brand"] as? String {
                food.brand = brand
            }
        case .markForReview, .ignore:
            break
        }

        // Update last updated date
        food.lastUpdated = ISO8601DateFormatter().string(from: Date())
    }
}
