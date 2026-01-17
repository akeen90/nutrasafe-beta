//
//  AddFoodManualViews.swift
//  NutraSafe Beta
//
//  Comprehensive manual food entry system with full nutrition data support
//  Supports both diary and use-by destinations with appropriate fields
//

import SwiftUI
import Foundation
import AVFoundation
import FirebaseFirestore
import FirebaseFunctions
import Vision

// MARK: - Ingredient Finder Models & Service

/// Nutrition data per 100g
struct NutritionPer100g: Codable {
    let calories: Double?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let fiber: Double?
    let sugar: Double?
    let salt: Double?
}

/// Product variant from Cloud Function
struct ProductVariant: Codable {
    let pack_size: String?              // Total product size (e.g., "51g", "400g", "6 pack")
    let serving_size_g: Double?         // Single serving weight in grams
    let servings_per_pack: Double?      // Number of servings in the pack
    let nutrition_basis: String?        // "per_100g", "per_serving", or "per_pack"
    let product_name: String?
    let brand: String?
    let barcode: String?
    let ingredients_text: String?
    let nutrition_per_100g: NutritionPer100g?
    let source_url: String?

    // Backwards compatibility - map old size_description to pack_size
    let size_description: String?

    // Computed property to get pack size from either new or old field
    var displayPackSize: String? {
        pack_size ?? size_description
    }
}

/// Response model from Cloud Function
struct IngredientFinderResponse: Codable {
    let ingredients_found: Bool
    let variants: [ProductVariant]

    // Convenience properties to get first variant data
    var product_name: String? { variants.first?.product_name }
    var brand: String? { variants.first?.brand }
    var barcode: String? { variants.first?.barcode }
    var pack_size: String? { variants.first?.displayPackSize }         // Total product size
    var serving_size_g: Double? { variants.first?.serving_size_g }     // Single serving weight
    var servings_per_pack: Double? { variants.first?.servings_per_pack }
    var nutrition_basis: String? { variants.first?.nutrition_basis }   // How nutrition is shown
    var ingredients_text: String? { variants.first?.ingredients_text }
    var nutrition_per_100g: NutritionPer100g? { variants.first?.nutrition_per_100g }
    var source_url: String? { variants.first?.source_url }

    // Backwards compatibility
    var size_description: String? { variants.first?.displayPackSize }
}

/// Service for finding ingredients using AI
@MainActor
class IngredientFinderService: ObservableObject {
    static let shared = IngredientFinderService()

    @Published var isSearching = false
    @Published var lastSearchTime: Date?
    @Published var searchCount = 0

    private let rateLimitWindow: TimeInterval = 60 // 1 minute
    private let maxSearchesPerWindow = 2

    private init() {}

    /// Search for ingredients using AI
    func findIngredients(productName: String, brand: String?, barcode: String? = nil) async throws -> IngredientFinderResponse {
        // Check rate limit
        try checkRateLimit()

        // Call Cloud Function
        isSearching = true
        defer { isSearching = false }

        let response = try await callCloudFunction(productName: productName, brand: brand, barcode: barcode)

        // Update rate limit tracking
        await MainActor.run {
            lastSearchTime = Date()
            searchCount += 1
        }

        return response
    }

    private func checkRateLimit() throws {
        guard let lastSearch = lastSearchTime else {
            return // First search, allow it
        }

        let timeSinceLastSearch = Date().timeIntervalSince(lastSearch)

        if timeSinceLastSearch < rateLimitWindow {
            if searchCount >= maxSearchesPerWindow {
                let waitTime = Int(rateLimitWindow - timeSinceLastSearch)
                throw IngredientFinderError.rateLimitExceeded(waitSeconds: waitTime)
            }
        } else {
            // Reset counter after window expires
            searchCount = 0
        }
    }

    private func callCloudFunction(productName: String, brand: String?, barcode: String?) async throws -> IngredientFinderResponse {
        // Get endpoint URL from AppConfig
        let endpointURLString = AppConfig.Firebase.Functions.findIngredients

        guard let url = URL(string: endpointURLString) else {
            throw IngredientFinderError.notConfigured
        }

        // Prepare request body
        var requestBody: [String: Any] = ["productName": productName]
        if let brand = brand, !brand.isEmpty {
            requestBody["brand"] = brand
        }
        if let barcode = barcode, !barcode.isEmpty {
            requestBody["barcode"] = barcode
        }

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 30

        // Execute request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check HTTP status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw IngredientFinderError.invalidResponse
        }

        if httpResponse.statusCode == 429 {
            throw IngredientFinderError.rateLimitExceeded(waitSeconds: 60)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw IngredientFinderError.serverError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        let decoder = JSONDecoder()
        let result = try decoder.decode(IngredientFinderResponse.self, from: data)

        return result
    }
}

enum IngredientFinderError: LocalizedError {
    case notConfigured
    case rateLimitExceeded(waitSeconds: Int)
    case invalidResponse
    case serverError(statusCode: Int)
    case noIngredientsFound

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Ingredient Finder is not configured. Please contact support."
        case .rateLimitExceeded(let seconds):
            return "Search limit reached. Please wait \(seconds) seconds before searching again."
        case .invalidResponse:
            return "Invalid response from server. Please try again."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .noIngredientsFound:
            return "No ingredients found from trusted sources. Try entering them manually."
        }
    }
}

// MARK: - Main Manual Add View

/// Main manual food addition view that navigates to detail entry page
struct AddFoodManualView: View {
    @Binding var selectedTab: TabItem
    var prefilledBarcode: String? = nil
    var onComplete: ((TabItem) -> Void)?
    @State private var showingDetailEntry = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "square.and.pencil")
                .font(.system(size: 72))
                .foregroundColor(.blue)
                .padding(.bottom, 16)

            // Title
            Text("Add Food Manually")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)

            // Description
            Text("Enter nutritional information to add a food to your diary")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)

            // Start Button
            Button(action: {
                showingDetailEntry = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("Start Manual Entry")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)

            Spacer()
        }
        .fullScreenCover(isPresented: $showingDetailEntry) {
            ManualFoodDetailEntryView(selectedTab: $selectedTab, prefilledBarcode: prefilledBarcode, onComplete: onComplete)
        }
        .onAppear {
            // If we have a prefilled barcode, automatically show the detail entry
            if prefilledBarcode != nil {
                showingDetailEntry = true
            }
        }
    }
}

// MARK: - Detail Entry View

/// Comprehensive manual food entry form with all nutrition fields (DIARY-ONLY)
struct ManualFoodDetailEntryView: View {
    @Binding var selectedTab: TabItem
    var prefilledBarcode: String? = nil
    var onComplete: ((TabItem) -> Void)?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var diaryDataManager: DiaryDataManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showingDiaryLimitError = false
    @State private var showingPaywall = false

    // Basic Info
    @State private var foodName = ""
    @State private var brand = ""
    @State private var barcode = ""

    // Serving
    @State private var servingSize = "100"
    @State private var servingUnit = "g"
    @State private var isPerUnit = false  // Toggle between per 100g and per unit (for restaurant foods)

    // Core Macros (per 100g or per unit based on isPerUnit)
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""

    // Additional Nutrients (per 100g)
    @State private var fiber = ""
    @State private var sugar = ""
    @State private var sodium = ""

    // Ingredients
    @State private var ingredientsText = ""
    @State private var isSearchingIngredients = false
    @State private var showIngredientConfirmation = false
    @State private var foundIngredients: IngredientFinderResponse?
    @StateObject private var ingredientFinder = IngredientFinderService.shared

    // Diary-specific fields
    @State private var selectedMealTime = "Breakfast"

    enum EntryMode {
        case manual
        case aiSearch
    }

    // UI State
    @State private var entryMode: EntryMode = .manual
    @State private var aiSearchQuery = ""
    @State private var hasAttemptedSave = false // Track if user has tried to save (for persistent error highlighting)
    @State private var showingIngredients = false
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingBarcodeScanner = false

    // Ingredients OCR state
    @State private var showingIngredientCamera = false
    @State private var isProcessingOCR = false

    // Nutrition OCR state
    @State private var showingNutritionCamera = false
    @State private var isProcessingNutritionOCR = false

    // Unified product scanner state
    @State private var showingUnifiedScanner = false

    let servingUnits = ["g", "ml", "oz", "cup", "tbsp", "tsp", "piece", "slice", "serving"]
    let mealTimes = ["Breakfast", "Lunch", "Dinner", "Snacks"]

    var isFormValid: Bool {
        // For diary: need food name, brand, and main macros (calories, protein, carbs, fat)
        return !foodName.isEmpty && !brand.isEmpty &&
               !calories.isEmpty && !protein.isEmpty && !carbs.isEmpty && !fat.isEmpty
    }

    // Get list of missing required fields for error message (with bullet points)
    private var missingFieldsMessage: String? {
        var missing: [String] = []
        if foodName.isEmpty { missing.append("Food Name") }
        if brand.isEmpty { missing.append("Brand") }
        if calories.isEmpty { missing.append("Calories") }
        if protein.isEmpty { missing.append("Protein") }
        if carbs.isEmpty { missing.append("Carbs") }
        if fat.isEmpty { missing.append("Fat") }

        if missing.isEmpty { return nil }

        // Format with bullet points for clarity
        let bulletList = missing.map { "• \($0)" }.joined(separator: "\n")
        return "Please fill in the following required fields:\n\n\(bulletList)"
    }

    // Helper to check if a required field is empty and should show error
    private func shouldShowError(for field: String) -> Bool {
        // Only show error if user has tried to save
        guard hasAttemptedSave else { return false }

        switch field {
        case "foodName":
            return foodName.isEmpty
        case "brand":
            return brand.isEmpty
        case "calories":
            return calories.isEmpty
        case "protein":
            return protein.isEmpty
        case "carbs":
            return carbs.isEmpty
        case "fat":
            return fat.isEmpty
        default:
            return false
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Manual Entry Interface
                        // Basic Information Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Basic Information")

                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 4) {
                                    Text("Food Name")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("*")
                                        .foregroundColor(.red)
                                }

                                TextField("Enter food name...", text: $foodName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(shouldShowError(for: "foodName") ? Color.red : Color.clear, lineWidth: 2)
                                    )
                            }

                        FormField(label: "Brand Name", isRequired: false) {
                            TextField("Enter brand name...", text: $brand)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(shouldShowError(for: "brand") ? Color.red : Color.clear, lineWidth: 2)
                                )
                        }

                        FormField(label: "Barcode (Optional)", isRequired: false) {
                            HStack(spacing: 8) {
                                TextField("Enter barcode...", text: $barcode)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)

                                Button(action: {
                                    showingBarcodeScanner = true
                                }) {
                                    Image(systemName: "barcode.viewfinder")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                }
                            }
                        }

                    // Scan to Add Button - Auto-fill all fields from photos
                    Button(action: {
                        showingUnifiedScanner = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 20))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Scan Product to Auto-Fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Take photos of the front, ingredients, and nutrition label")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .padding(.top, 8)

                    // Diary nutrition form
                    Divider()

                    // Serving Size Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: isPerUnit ? "Unit Name" : "Serving Size")

                            Text(isPerUnit ? "Enter nutrition values for 1 complete unit below" : "Enter nutrition values per 100g/100ml below")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)

                            if isPerUnit {
                                // Per-unit mode: just enter the unit name (e.g., "burger", "pizza")
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("What is this unit called?")
                                        .font(.system(size: 14, weight: .medium))
                                    TextField("e.g., burger, pizza, sandwich", text: $servingUnit)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .autocapitalization(.none)
                                }
                            } else {
                                // Per-100g mode: standard serving size picker
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Default Serving")
                                            .font(.system(size: 14, weight: .medium))
                                        TextField("Amount", text: $servingSize)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .keyboardType(.decimalPad)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Unit")
                                            .font(.system(size: 14, weight: .medium))
                                        Picker("Unit", selection: $servingUnit) {
                                            ForEach(servingUnits, id: \.self) { unit in
                                                Text(unit).tag(unit)
                                            }
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                        .frame(maxWidth: .infinity)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }

                        Divider()

                        // Nutrition Mode Toggle
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $isPerUnit) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Per Unit Nutrition")
                                        .font(.system(size: 15, weight: .medium))
                                    Text(isPerUnit ? "Values are for 1 complete item (e.g., 1 burger)" : "Values are per 100g/100ml (standard)")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tint(.purple)
                            .onChange(of: isPerUnit) { _, newValue in
                                if newValue {
                                    // Switching to per-unit: set serving size to 1
                                    servingSize = "1"
                                    servingUnit = "" // Clear unit so user can enter custom name
                                } else {
                                    // Switching to per-100g: reset to default
                                    servingSize = "100"
                                    servingUnit = "g"
                                }
                            }
                        }
                        .padding(.vertical, 8)

                        Divider()

                        // Core Nutrition Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                SectionHeader(title: isPerUnit ? "Core Nutrition (per unit)" : "Core Nutrition (per 100g)")

                                Spacer()

                                Button(action: {
                                    showingNutritionCamera = true
                                }) {
                                    HStack(spacing: 6) {
                                        if isProcessingNutritionOCR {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 14))
                                        }
                                        Text("Scan")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                                }
                                .disabled(isProcessingNutritionOCR)
                            }

                            VStack(spacing: 12) {
                                ManualNutritionInputRow(label: "Energy", value: $calories, unit: "kcal", isRequired: true, showError: shouldShowError(for: "calories"))
                                ManualNutritionInputRow(label: "Carbs", value: $carbs, unit: "g", isRequired: true, showError: shouldShowError(for: "carbs"))
                                ManualNutritionInputRow(label: "Protein", value: $protein, unit: "g", isRequired: true, showError: shouldShowError(for: "protein"))
                                ManualNutritionInputRow(label: "Fat", value: $fat, unit: "g", isRequired: true, showError: shouldShowError(for: "fat"))
                            }
                        }

                        Divider()

                        // Additional Nutrients Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Additional Nutrients (Optional)")

                            VStack(spacing: 12) {
                                ManualNutritionInputRow(label: "Fibre", value: $fiber, unit: "g")
                                ManualNutritionInputRow(label: "Sugar", value: $sugar, unit: "g")
                                ManualNutritionInputRow(label: "Salt", value: $sodium, unit: "g")
                            }
                        }

                        Divider()

                        // Meal Time Selection for Diary
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Meal Time")

                            Picker("Meal Time", selection: $selectedMealTime) {
                                ForEach(mealTimes, id: \.self) { meal in
                                    Text(meal).tag(meal)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }

                        Divider()

                        // Ingredients Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Ingredients")

                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Enter ingredients or scan from a photo")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    Button(action: {
                                        showingIngredientCamera = true
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 14))
                                            Text("Scan")
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                    }
                                    .disabled(isProcessingOCR)
                                }

                                    TextEditor(text: $ingredientsText)
                                        .frame(height: 100)
                                        .padding(8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color(.systemGray4), lineWidth: 1)
                                        )
                                        .overlay(
                                            // Searching/OCR overlay
                                            Group {
                                                if isSearchingIngredients || isProcessingOCR {
                                                    ZStack {
                                                        Color.black.opacity(0.3)
                                                            .cornerRadius(8)

                                                        VStack(spacing: 12) {
                                                            ProgressView()
                                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                                .scaleEffect(1.2)

                                                            Text(isProcessingOCR ? "Reading Ingredients..." : "NutraSafe Ingredient Finder™")
                                                                .font(.system(size: 14, weight: .semibold))
                                                                .foregroundColor(.white)

                                                            Text(isProcessingOCR ? "Extracting text from photo" : "Searching trusted sources...")
                                                                .font(.system(size: 12))
                                                                .foregroundColor(.white.opacity(0.9))
                                                        }
                                                        .padding()
                                                    }
                                                }
                                            }
                                        )
                            }
                        }

                    } // end manual entry mode

                    // Save Button
                    Button(action: saveFood) {
                        HStack(spacing: 8) {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                            }
                            Text(isSaving ? "Saving..." : "Add to Diary")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isSaving ? Color.gray : Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(isSaving)
                    .padding(.top, 8)

                    // Bottom spacing for keyboard
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .navigationTitle("Add to Diary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .diaryLimitAlert(
                isPresented: $showingDiaryLimitError,
                showingPaywall: $showingPaywall
            )
            .fullScreenCover(isPresented: $showingPaywall) {
                PaywallView()
            }
            .fullScreenCover(isPresented: $showingBarcodeScanner) {
                BarcodeScannerSheetView(barcode: $barcode, isPresented: $showingBarcodeScanner)
            }
            .fullScreenCover(isPresented: $showIngredientConfirmation) {
                IngredientConfirmationModal(
                    response: foundIngredients,
                    onUse: {
                        // Apply product name and brand if found
                        if let productName = foundIngredients?.product_name, !productName.isEmpty {
                            foodName = productName
                        }
                        if let brandName = foundIngredients?.brand, !brandName.isEmpty {
                            brand = brandName
                        }
                        if let barcodeValue = foundIngredients?.barcode, !barcodeValue.isEmpty {
                            barcode = barcodeValue
                        }
                        // Apply serving size if found (use numeric field, not pack size string)
                        if let servingSizeGrams = foundIngredients?.serving_size_g {
                            // Validate that serving size is reasonable (not product size)
                            if servingSizeGrams > 0 && servingSizeGrams <= 500 {
                                servingSize = String(format: "%.0f", servingSizeGrams)
                                servingUnit = "g"
                                                            } else {
                                // Unreasonable serving size, default to 100g
                                servingSize = "100"
                                servingUnit = "g"
                                                            }
                        } else {
                            // No serving size from AI, default to 100g (matches nutrition per 100g)
                            servingSize = "100"
                            servingUnit = "g"
                                                    }
                        // Apply ingredients
                        if let ingredients = foundIngredients?.ingredients_text {
                            ingredientsText = ingredients
                        }
                        // Apply nutrition per 100g
                        if let nutrition = foundIngredients?.nutrition_per_100g {
                            if let cal = nutrition.calories { calories = String(format: "%.0f", cal) }
                            if let prot = nutrition.protein { protein = String(format: "%.1f", prot) }
                            if let carb = nutrition.carbs { carbs = String(format: "%.1f", carb) }
                            if let f = nutrition.fat { fat = String(format: "%.1f", f) }
                            if let fib = nutrition.fiber { fiber = String(format: "%.1f", fib) }
                            if let sug = nutrition.sugar { sugar = String(format: "%.1f", sug) }
                            if let saltValue = nutrition.salt { sodium = String(format: "%.1f", saltValue) }
                        }
                        showIngredientConfirmation = false
                        // Switch to manual mode so user can see and edit the populated data
                        entryMode = .manual
                    },
                    onEdit: {
                        // Apply product name and brand if found
                        if let productName = foundIngredients?.product_name, !productName.isEmpty {
                            foodName = productName
                        }
                        if let brandName = foundIngredients?.brand, !brandName.isEmpty {
                            brand = brandName
                        }
                        if let barcodeValue = foundIngredients?.barcode, !barcodeValue.isEmpty {
                            barcode = barcodeValue
                        }
                        // Apply serving size if found (use numeric field, not pack size string)
                        if let servingSizeGrams = foundIngredients?.serving_size_g {
                            // Validate that serving size is reasonable (not product size)
                            if servingSizeGrams > 0 && servingSizeGrams <= 500 {
                                servingSize = String(format: "%.0f", servingSizeGrams)
                                servingUnit = "g"
                                                            } else {
                                // Unreasonable serving size, default to 100g
                                servingSize = "100"
                                servingUnit = "g"
                                                            }
                        } else {
                            // No serving size from AI, default to 100g (matches nutrition per 100g)
                            servingSize = "100"
                            servingUnit = "g"
                                                    }
                        // Apply ingredients and nutrition for editing
                        if let ingredients = foundIngredients?.ingredients_text {
                            ingredientsText = ingredients
                        }
                        if let nutrition = foundIngredients?.nutrition_per_100g {
                            if let cal = nutrition.calories { calories = String(format: "%.0f", cal) }
                            if let prot = nutrition.protein { protein = String(format: "%.1f", prot) }
                            if let carb = nutrition.carbs { carbs = String(format: "%.1f", carb) }
                            if let f = nutrition.fat { fat = String(format: "%.1f", f) }
                            if let fib = nutrition.fiber { fiber = String(format: "%.1f", fib) }
                            if let sug = nutrition.sugar { sugar = String(format: "%.1f", sug) }
                            if let saltValue = nutrition.salt { sodium = String(format: "%.1f", saltValue) }
                        }
                        showIngredientConfirmation = false
                        // Switch to manual mode so user can see and edit the populated data
                        entryMode = .manual
                    },
                    onCancel: {
                        showIngredientConfirmation = false
                    }
                )
            }
            .fullScreenCover(isPresented: $showingIngredientCamera) {
                IngredientOCRCameraView(
                    onImageCaptured: { image in
                        showingIngredientCamera = false
                        processIngredientImage(image)
                    },
                    onDismiss: {
                        showingIngredientCamera = false
                    }
                )
            }
            .fullScreenCover(isPresented: $showingNutritionCamera) {
                NutritionOCRCameraView(
                    onImageCaptured: { image in
                        showingNutritionCamera = false
                        processNutritionImage(image)
                    },
                    onDismiss: {
                        showingNutritionCamera = false
                    }
                )
            }
            .fullScreenCover(isPresented: $showingUnifiedScanner) {
                UnifiedProductScannerView(
                    onScanComplete: { response in
                        showingUnifiedScanner = false
                        processUnifiedScan(response)
                    },
                    onDismiss: {
                        showingUnifiedScanner = false
                    }
                )
            }
            .onAppear {
                // Initialize barcode from prefilledBarcode if provided
                if let prefilledBarcode = prefilledBarcode {
                    barcode = prefilledBarcode
                }
            }
        }
    }

    /// Process unified scan response and auto-fill all form fields
    private func processUnifiedScan(_ response: ScanProductResponse) {
        // Product name and brand
        if let name = response.productName, !name.isEmpty {
            foodName = name
        }
        if let brandName = response.brand, !brandName.isEmpty {
            brand = brandName
        }

        // Barcode
        if let barcodeValue = response.barcode, !barcodeValue.isEmpty {
            barcode = barcodeValue
        }

        // Serving size
        if let size = response.servingSize, size > 0 && size <= 500 {
            servingSize = String(format: "%.0f", size)
        }
        if let unit = response.servingUnit, servingUnits.contains(unit) {
            servingUnit = unit
        }

        // Ingredients
        if let ingredients = response.ingredientsText, !ingredients.isEmpty {
            ingredientsText = ingredients
        }

        // Nutrition values (per 100g)
        if let nutrition = response.nutrition {
            if let cal = nutrition.calories {
                calories = String(format: "%.0f", cal)
            }
            if let prot = nutrition.protein {
                protein = String(format: "%.1f", prot)
            }
            if let carb = nutrition.carbohydrates {
                carbs = String(format: "%.1f", carb)
            }
            if let f = nutrition.fat {
                fat = String(format: "%.1f", f)
            }
            if let fib = nutrition.fiber {
                fiber = String(format: "%.1f", fib)
            }
            if let sug = nutrition.sugar {
                sugar = String(format: "%.1f", sug)
            }
            if let salt = nutrition.salt {
                sodium = String(format: "%.2f", salt)
            }
        }

        // Show feedback about what was detected
        let detectedItems = response.detectedContent.map { content -> String in
            switch content {
            case "front": return "product info"
            case "ingredients": return "ingredients"
            case "nutrition": return "nutrition"
            case "barcode": return "barcode"
            default: return content
            }
        }

        if !detectedItems.isEmpty {
            // Provide subtle feedback about what was detected
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }

    /// Process an image to extract ingredients text using Vision OCR + AI comprehension
    private func processIngredientImage(_ image: UIImage) {
        isProcessingOCR = true

        Task {
            do {
                // Step 1: Extract text using Vision OCR
                let extractedText = try await extractTextFromImage(image)

                guard !extractedText.isEmpty else {
                    await MainActor.run {
                        isProcessingOCR = false
                        errorMessage = "Could not read text from the image. Please try again with a clearer photo."
                        showingError = true
                    }
                    return
                }

                
                // Step 2: Send to AI for intelligent parsing
                let ingredientsData = try await parseIngredientsWithAI(
                    ocrText: extractedText,
                    productName: foodName.isEmpty ? nil : foodName,
                    brand: brand.isEmpty ? nil : brand
                )

                await MainActor.run {
                    isProcessingOCR = false

                    if !ingredientsData.ingredientsText.isEmpty {
                        ingredientsText = ingredientsData.ingredientsText

                        } else {
                        // Fallback to local cleaning if AI returns empty
                        ingredientsText = cleanIngredientText(extractedText)
                    }
                }
            } catch {
                // AI failed - fallback to local regex-based cleaning
                
                do {
                    let extractedText = try await extractTextFromImage(image)
                    await MainActor.run {
                        isProcessingOCR = false
                        if !extractedText.isEmpty {
                            ingredientsText = cleanIngredientText(extractedText)
                        } else {
                            errorMessage = "Could not read text from the image. Please try again with a clearer photo."
                            showingError = true
                        }
                    }
                } catch {
                    await MainActor.run {
                        isProcessingOCR = false
                        errorMessage = "Failed to process image: \(error.localizedDescription)"
                        showingError = true
                    }
                }
            }
        }
    }

    /// AI-powered ingredients parsing response model
    struct AIIngredientsData {
        var ingredients: [String] = []
        var ingredientsText: String = ""
        var allergens: [String] = []
        var containsStatement: String?
        var confidence: Double = 0
        var warnings: [String]?
    }

    /// Call Firebase Cloud Function for AI-powered ingredients parsing
    private func parseIngredientsWithAI(ocrText: String, productName: String?, brand: String?) async throws -> AIIngredientsData {
        let functions = Functions.functions()
        let callable = functions.httpsCallable("parseIngredientsOCRCached")

        var requestData: [String: Any] = ["ocrText": ocrText]
        if let name = productName {
            requestData["productName"] = name
        }
        if let brandName = brand {
            requestData["brand"] = brandName
        }

        let result = try await callable.call(requestData)

        guard let data = result.data as? [String: Any] else {
            throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from AI"])
        }

        // Parse the response
        var ingredientsData = AIIngredientsData()

        if let ingredients = data["ingredients"] as? [String] {
            ingredientsData.ingredients = ingredients
        }
        if let ingredientsText = data["ingredientsText"] as? String {
            ingredientsData.ingredientsText = ingredientsText
        }
        if let allergens = data["allergens"] as? [String] {
            ingredientsData.allergens = allergens
        }
        if let containsStatement = data["containsStatement"] as? String {
            ingredientsData.containsStatement = containsStatement
        }
        if let confidence = data["confidence"] as? Double {
            ingredientsData.confidence = confidence
        }
        if let warnings = data["warnings"] as? [String] {
            ingredientsData.warnings = warnings
        }

        return ingredientsData
    }

    /// Extract text from image using Vision framework
    private func extractTextFromImage(_ image: UIImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: "")
                return
            }

            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: " ")

                continuation.resume(returning: recognizedText)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Clean up OCR text to format as ingredient list - intelligently extracts ingredients from mixed text
    private func cleanIngredientText(_ text: String) -> String {
        // Try to extract just the ingredients section from mixed OCR text
        let extracted = extractIngredientsSection(from: text)

        var cleaned = extracted

        // Remove common headers/labels (case insensitive)
        let headersToRemove = [
            "INGREDIENTS:", "INGREDIENTS", "Ingredients:", "Ingredients",
            "INGREDIENSER:", "INGREDIENSER", "INGRÉDIENTS:", "INGRÉDIENTS",
            "Zutaten:", "ZUTATEN:", "Ingredienti:", "INGREDIENTI:",
            "Contains:", "CONTAINS:", "May contain:", "MAY CONTAIN:",
            "Allergens:", "ALLERGENS:", "For allergens see ingredients in bold",
            "FOR ALLERGENS SEE INGREDIENTS IN BOLD", "See ingredients in bold",
            "Made in a facility", "MADE IN A FACILITY", "Produced in"
        ]
        for header in headersToRemove {
            cleaned = cleaned.replacingOccurrences(of: header, with: "", options: .caseInsensitive)
        }

        // Remove nutrition-related text that might be captured
        let nutritionPatterns = [
            "per 100g", "per 100ml", "per serving", "per portion",
            "energy", "kj", "kcal", "protein", "carbohydrate", "fat",
            "saturates", "sugars", "salt", "fibre", "of which",
            "typical values", "nutrition information", "nutritional information"
        ]
        for pattern in nutritionPatterns {
            if let range = cleaned.range(of: pattern, options: .caseInsensitive) {
                // Find the start of this nutrition section and truncate
                let beforeNutrition = String(cleaned[..<range.lowerBound])
                if beforeNutrition.count > 50 { // Only truncate if we have substantial ingredients before
                    cleaned = beforeNutrition
                    break
                }
            }
        }

        // Remove common non-ingredient text patterns
        let patternsToRemove = [
            #"best before[:\s].*"#,
            #"use by[:\s].*"#,
            #"store in.*"#,
            #"storage[:\s].*"#,
            #"keep refrigerated.*"#,
            #"once opened.*"#,
            #"net weight[:\s].*"#,
            #"net wt[:\s].*"#,
            #"\d+\s*[gG]\s*[eE]?"#, // Weight like "400g" or "400g e"
            #"www\..*"#, // Website URLs
            #"http[s]?://.*"#, // Full URLs
            #"tel[:\s].*"#, // Phone numbers
            #"phone[:\s].*"#, // Phone numbers
            #"fax[:\s].*"#, // Fax numbers
            #"\+\d{2}[\s\-]?\d+"#, // International phone numbers
            #"[A-Z]{2}\d{3,}"#, // Batch codes
            // UK postcodes (e.g., SW1A 1AA, M1 1AA, B1 1AA)
            #"[A-Z]{1,2}\d{1,2}[A-Z]?\s*\d[A-Z]{2}"#,
            // Street addresses - common UK patterns
            #"\d+[\-\s]?\d*\s+(street|road|avenue|lane|drive|way|close|court|place|crescent|grove|park|terrace|gardens)\b"#,
            // Company/address keywords with following text
            #"(distributed by|manufactured by|produced by|packed by|imported by|made by)[:\s].*"#,
            #"(address|registered office|head office)[:\s].*"#,
            // City/Town names followed by postcodes or country
            #"(ltd|limited|plc|inc|corp)[,\.\s].*"#,
            // Remove lines that look like full addresses (multiple commas with location words)
            #"[A-Z][a-z]+,\s*[A-Z][a-z]+,?\s*[A-Z]{1,2}\d"#,
            // Country names at end of addresses
            #",?\s*(united kingdom|uk|england|scotland|wales|ireland)\b"#,
            // Email addresses
            #"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"#,
        ]
        for pattern in patternsToRemove {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                cleaned = regex.stringByReplacingMatches(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned), withTemplate: "")
            }
        }

        // Normalize whitespace
        cleaned = cleaned.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        // Clean up punctuation - fix double commas, spaces before commas
        cleaned = cleaned.replacingOccurrences(of: " ,", with: ",")
        cleaned = cleaned.replacingOccurrences(of: ",,", with: ",")
        cleaned = cleaned.replacingOccurrences(of: ", ,", with: ",")

        // Remove trailing/leading punctuation
        cleaned = cleaned.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ",;.")))

        return cleaned
    }

    /// Extract the ingredients section from OCR text that may contain other product information
    private func extractIngredientsSection(from text: String) -> String {
        let lowercased = text.lowercased()

        // Look for "ingredients" marker and extract from there
        let ingredientMarkers = ["ingredients:", "ingredients", "ingredienser:", "ingrédients:", "zutaten:", "ingredienti:"]

        var startIndex: String.Index? = nil
        var markerLength = 0

        for marker in ingredientMarkers {
            if let range = lowercased.range(of: marker) {
                if startIndex == nil || range.lowerBound < startIndex! {
                    startIndex = range.lowerBound
                    markerLength = marker.count
                }
            }
        }

        // If we found an ingredients marker, extract from there
        if let start = startIndex {
            let afterMarker = text.index(start, offsetBy: markerLength, limitedBy: text.endIndex) ?? start
            var extracted = String(text[afterMarker...])

            // Look for end markers that indicate ingredients section is over
            let endMarkers = [
                "nutrition", "nutritional", "typical values", "energy",
                "allergens:", "may contain", "storage", "store in",
                "best before", "use by", "produced by", "manufactured",
                "for more information", "customer services",
                // Address-related end markers
                "distributed by", "packed by", "imported by", "made by",
                "registered office", "head office", "address:",
                "ltd,", "limited,", "plc,", "inc,",
                "united kingdom", "england", "scotland", "wales"
            ]

            for endMarker in endMarkers {
                if let endRange = extracted.lowercased().range(of: endMarker) {
                    // Only truncate if we have substantial content before this marker
                    let contentBefore = String(extracted[..<endRange.lowerBound])
                    if contentBefore.count > 30 {
                        extracted = contentBefore
                        break
                    }
                }
            }

            return extracted
        }

        // No marker found - try to detect ingredients by pattern
        // Ingredients typically: comma-separated, contain parentheses, E-numbers, percentages
        let lines = text.components(separatedBy: .newlines)
        var ingredientLines: [String] = []
        var foundIngredientPattern = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            // Check if line looks like ingredients
            let hasCommas = trimmed.contains(",")
            let hasParentheses = trimmed.contains("(") && trimmed.contains(")")
            let hasENumbers = trimmed.range(of: #"[Ee]\s?\d{3}"#, options: .regularExpression) != nil
            let hasPercentages = trimmed.contains("%")
            let looksLikeIngredients = (hasCommas && (hasParentheses || hasENumbers || hasPercentages)) ||
                                       (hasCommas && trimmed.count > 50)

            if looksLikeIngredients {
                foundIngredientPattern = true
                ingredientLines.append(trimmed)
            } else if foundIngredientPattern && hasCommas {
                // Continue capturing comma-separated content after we found ingredients
                ingredientLines.append(trimmed)
            } else if foundIngredientPattern && !hasCommas {
                // Stop when we hit non-ingredient content
                break
            }
        }

        if !ingredientLines.isEmpty {
            return ingredientLines.joined(separator: " ")
        }

        // Fallback: return original text
        return text
    }

    // MARK: - Nutrition OCR Processing (AI-Powered)

    /// Process an image to extract nutrition values using Vision OCR + AI comprehension
    private func processNutritionImage(_ image: UIImage) {
        isProcessingNutritionOCR = true

        Task {
            do {
                // Step 1: Extract text using Vision OCR
                let extractedText = try await extractTextFromImage(image)

                guard !extractedText.isEmpty else {
                    await MainActor.run {
                        isProcessingNutritionOCR = false
                        errorMessage = "Could not read text from the image. Please try again with a clearer photo."
                        showingError = true
                    }
                    return
                }

                
                // Step 2: Send to AI for intelligent parsing
                let nutritionData = try await parseNutritionWithAI(ocrText: extractedText)

                await MainActor.run {
                    isProcessingNutritionOCR = false

                    // Fill in the form fields with extracted values
                    if let cal = nutritionData.calories {
                        calories = String(format: "%.0f", cal)
                    }
                    if let carb = nutritionData.carbohydrates {
                        carbs = String(format: "%.1f", carb)
                    }
                    if let prot = nutritionData.protein {
                        protein = String(format: "%.1f", prot)
                    }
                    if let f = nutritionData.fat {
                        fat = String(format: "%.1f", f)
                    }
                    if let fib = nutritionData.fiber {
                        fiber = String(format: "%.1f", fib)
                    }
                    if let sug = nutritionData.sugar {
                        sugar = String(format: "%.1f", sug)
                    }
                    if let salt = nutritionData.salt {
                        sodium = String(format: "%.2f", salt)
                    }

                    // Update serving size if extracted
                    if let size = nutritionData.servingSize {
                        servingSize = String(format: "%.0f", size)
                    }
                    if let unit = nutritionData.servingUnit {
                        if servingUnits.contains(unit) {
                            servingUnit = unit
                        }
                    }

                    // Show warning if confidence is low or no calories found
                    if nutritionData.calories == nil {
                        errorMessage = "Could not extract nutrition values. Please try with a clearer photo of the nutrition label."
                        showingError = true
                    } else if nutritionData.confidence < 0.7 {
                        // Low confidence - show a warning but still use the values
                        }

                                    }
            } catch {
                await MainActor.run {
                    isProcessingNutritionOCR = false
                    // Fall back to local parsing if AI fails
                                        errorMessage = "Failed to process nutrition label. Please enter values manually or try another photo."
                    showingError = true
                }
            }
        }
    }

    /// AI-powered nutrition parsing response model
    struct AINutritionData {
        var calories: Double?
        var protein: Double?
        var carbohydrates: Double?
        var fat: Double?
        var fiber: Double?
        var sugar: Double?
        var salt: Double?
        var saturatedFat: Double?
        var servingSize: Double?
        var servingUnit: String?
        var servingsPerContainer: Double?
        var isPerServing: Bool = false
        var confidence: Double = 0
        var warnings: [String]?
    }

    /// Call Firebase Cloud Function for AI-powered nutrition parsing
    private func parseNutritionWithAI(ocrText: String) async throws -> AINutritionData {
        let functions = Functions.functions()
        let callable = functions.httpsCallable("parseNutritionOCRCached")

        let result = try await callable.call([
            "ocrText": ocrText,
            "preferPer100g": !isPerUnit  // Use per 100g unless user is in per-unit mode
        ])

        guard let data = result.data as? [String: Any] else {
            throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from AI"])
        }

        // Parse the response
        var nutritionData = AINutritionData()

        if let calories = data["calories"] as? Double {
            nutritionData.calories = calories
        }
        if let protein = data["protein"] as? Double {
            nutritionData.protein = protein
        }
        if let carbs = data["carbohydrates"] as? Double {
            nutritionData.carbohydrates = carbs
        }
        if let fat = data["fat"] as? Double {
            nutritionData.fat = fat
        }
        if let fiber = data["fiber"] as? Double {
            nutritionData.fiber = fiber
        }
        if let sugar = data["sugar"] as? Double {
            nutritionData.sugar = sugar
        }
        if let salt = data["salt"] as? Double {
            nutritionData.salt = salt
        }
        if let saturatedFat = data["saturatedFat"] as? Double {
            nutritionData.saturatedFat = saturatedFat
        }
        if let servingSize = data["servingSize"] as? Double {
            nutritionData.servingSize = servingSize
        }
        if let servingUnit = data["servingUnit"] as? String {
            nutritionData.servingUnit = servingUnit
        }
        if let servingsPerContainer = data["servingsPerContainer"] as? Double {
            nutritionData.servingsPerContainer = servingsPerContainer
        }
        if let isPerServing = data["isPerServing"] as? Bool {
            nutritionData.isPerServing = isPerServing
        }
        if let confidence = data["confidence"] as? Double {
            nutritionData.confidence = confidence
        }
        if let warnings = data["warnings"] as? [String] {
            nutritionData.warnings = warnings
        }

        return nutritionData
    }

    private func searchIngredientsWithAI() {
        // Require food name
        guard !foodName.isEmpty else {
            errorMessage = "Please enter a food name first"
            showingError = true
            return
        }

        isSearchingIngredients = true

        Task {
            do {
                let response = try await ingredientFinder.findIngredients(
                    productName: foodName,
                    brand: brand.isEmpty ? nil : brand,
                    barcode: barcode.isEmpty ? nil : barcode
                )

                
                await MainActor.run {
                    isSearchingIngredients = false

                    if response.ingredients_found, let _ = response.ingredients_text {
                        // Show confirmation modal
                        foundIngredients = response
                        showIngredientConfirmation = true
                    } else {
                        // No ingredients found
                        errorMessage = "No ingredients found from trusted sources. Try entering them manually or check the product name."
                        showingError = true
                    }
                }
            } catch let error as IngredientFinderError {
                await MainActor.run {
                    isSearchingIngredients = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            } catch {
                await MainActor.run {
                    isSearchingIngredients = false
                    errorMessage = "Network error. Please check your connection and try again."
                    showingError = true
                }
            }
        }
    }

    private func performAISearch() {
        // Require search query
        guard !aiSearchQuery.isEmpty else {
            errorMessage = "Please enter a product name"
            showingError = true
            return
        }

        isSearchingIngredients = true

        Task {
            do {
                let response = try await ingredientFinder.findIngredients(
                    productName: aiSearchQuery,
                    brand: nil
                )

                                                
                await MainActor.run {
                    isSearchingIngredients = false

                    if response.ingredients_found, !response.variants.isEmpty {
                        // Show confirmation modal
                        foundIngredients = response
                        showIngredientConfirmation = true
                    } else {
                        // No ingredients found
                        errorMessage = "No product data found from UK supermarkets. Try refining your search or switch to manual entry."
                        showingError = true
                    }
                }
            } catch let error as IngredientFinderError {
                await MainActor.run {
                    isSearchingIngredients = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            } catch {
                await MainActor.run {
                    isSearchingIngredients = false
                    errorMessage = "Network error. Please check your connection and try again."
                    showingError = true
                }
            }
        }
    }

    private func saveFood() {
        // Mark that user has attempted to save (for persistent error highlighting)
        hasAttemptedSave = true

        // Check if form is valid (food name, brand, and main macros required)
        if let missingMessage = missingFieldsMessage {
            // Show specific error about which fields are missing
            showingError = true
            errorMessage = missingMessage
            return
        }

        // Auto-fill optional nutrition fields with "0" if empty (main macros already validated)
        if fiber.isEmpty { fiber = "0" }
        if sugar.isEmpty { sugar = "0" }
        if sodium.isEmpty { sodium = "0" }

        isSaving = true

        Task {
            do {
                try await saveFoodToDiary()

                // Use the onComplete callback to dismiss entire sheet stack and navigate
                await MainActor.run {
                    isSaving = false
                    // Always dismiss keyboard first
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

                    if let callback = onComplete {
                        // Use callback if available (proper dismissal)
                        callback(.diary)
                    } else {
                        // Fallback: manually dismiss and switch tabs
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            selectedTab = .diary
                        }
                    }
                }
            } catch {
                // Don't dismiss on error - show error message instead
                await MainActor.run {
                    isSaving = false
                    // Error will be shown by the saveFoodToDiary function
                }
            }
        }
    }

    private func saveFoodToDiary() async throws {
        // AUTO-CAPITALIZE: Food name and brand (first letter of each word)
        let capitalizedFoodName = foodName.capitalized
        let capitalizedBrand = brand.isEmpty ? nil : brand.capitalized

        // Create ingredients list from text with auto-capitalization
        let ingredients = ingredientsText.isEmpty ? nil : ingredientsText.components(separatedBy: ",").map {
            $0.trimmingCharacters(in: .whitespaces).capitalized
        }

        // Parse nutrition values
        let caloriesInput = Double(calories) ?? 0
        let proteinInput = Double(protein) ?? 0
        let carbsInput = Double(carbs) ?? 0
        let fatInput = Double(fat) ?? 0
        let fiberInput = Double(fiber) ?? 0
        let sugarInput = Double(sugar) ?? 0
        let sodiumInput = Double(sodium) ?? 0
        let servingSizeValue = Double(servingSize) ?? 100

        // Calculate actual values based on mode
        let caloriesValue: Double
        let proteinValue: Double
        let carbsValue: Double
        let fatValue: Double
        let fiberValue: Double
        let sugarValue: Double
        let sodiumValue: Double

        if isPerUnit {
            // Per unit mode: values are already per unit, use as-is
            caloriesValue = caloriesInput
            proteinValue = proteinInput
            carbsValue = carbsInput
            fatValue = fatInput
            fiberValue = fiberInput
            sugarValue = sugarInput
            sodiumValue = sodiumInput
        } else {
            // Per 100g mode: convert per-100g values to per-serving values
            let ratio = servingSizeValue / 100.0
            caloriesValue = caloriesInput * ratio
            proteinValue = proteinInput * ratio
            carbsValue = carbsInput * ratio
            fatValue = fatInput * ratio
            fiberValue = fiberInput * ratio
            sugarValue = sugarInput * ratio
            sodiumValue = sodiumInput * ratio
        }

        do {
            // Prepare food data for userAdded collection with capitalized names
            var foodData: [String: Any] = [
                "foodName": capitalizedFoodName,
                "servingSize": servingSizeValue,
                "servingUnit": servingUnit,
                "calories": caloriesValue,
                "protein": proteinValue,
                "carbohydrates": carbsValue,
                "fat": fatValue,
                "isPerUnit": isPerUnit  // Flag to indicate per-unit vs per-100g values
            ]

            // Add optional fields
            if let brandValue = capitalizedBrand {
                foodData["brandName"] = brandValue
            }
            if fiberValue > 0 {
                foodData["fiber"] = fiberValue
            }
            if sugarValue > 0 {
                foodData["sugars"] = sugarValue
            }
            if sodiumValue > 0 {
                foodData["sodium"] = sodiumValue
            }
            if let ingredients = ingredients {
                foodData["ingredients"] = ingredients.joined(separator: ", ")
            }
            if !barcode.isEmpty {
                foodData["barcode"] = barcode
            }

            // Add serving description based on mode
            if isPerUnit {
                // Per-unit: show "1 burger", "1 pizza", etc.
                let unitName = servingUnit.isEmpty ? "unit" : servingUnit
                foodData["servingDescription"] = "1 \(unitName)"
            } else {
                // Per-100g: show standard serving description
                foodData["servingDescription"] = "\(servingSizeValue)\(servingUnit)"
            }

            // Check if AI was used to find ingredients
            let usedAI = foundIngredients != nil

            if usedAI {
                // Save to aiManuallyAdded collection with AI metadata
                _ = try await FirebaseManager.shared.saveAIEnhancedFood(
                    foodData,
                    sourceURL: foundIngredients?.source_url,
                    aiProductName: foundIngredients?.product_name
                )
            } else {
                // Save to userAdded collection (manual entry with profanity check)
                _ = try await FirebaseManager.shared.saveUserAddedFood(foodData)
            }

            // Now add to user's diary with capitalized values
            // Create appropriate serving description based on mode
            let servingDesc: String
            if isPerUnit {
                // Per-unit: show "1 burger serving", "1 pizza serving", etc.
                let unitName = servingUnit.isEmpty ? "unit" : servingUnit
                servingDesc = "1 \(unitName) serving"
            } else {
                // Per-100g: show standard format
                servingDesc = "\(servingSizeValue)\(servingUnit) serving"
            }

            
            let diaryEntry = DiaryFoodItem(
                id: UUID(),
                name: capitalizedFoodName,
                brand: capitalizedBrand,
                calories: Int(caloriesValue),
                protein: proteinValue,
                carbs: carbsValue,
                fat: fatValue,
                fiber: fiberValue,
                sugar: sugarValue,
                sodium: sodiumValue,
                calcium: 0,
                servingDescription: servingDesc,
                quantity: 1.0,
                time: nil,
                processedScore: nil,
                sugarLevel: nil,
                ingredients: ingredients,
                additives: nil,
                barcode: barcode.isEmpty ? nil : barcode,
                micronutrientProfile: nil,
                isPerUnit: isPerUnit
            )

            // Add to diary via DiaryDataManager using selected meal time
            let mealType = selectedMealTime.lowercased() // Convert to lowercase for storage
            let hasAccess = subscriptionManager.hasAccess
            try await diaryDataManager.addFoodItem(diaryEntry, to: mealType, for: Date(), hasProAccess: hasAccess)
            
            // Dismiss the sheet after successful save
            await MainActor.run {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                dismiss()

                // Switch to diary tab after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    selectedTab = .diary
                }
            }

        } catch is FirebaseManager.DiaryLimitError {
            await MainActor.run {
                showingDiaryLimitError = true
            }
        } catch {
            // Show error to user and re-throw to prevent dismissal
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
                            }
            throw error
        }
    }

    /// Parse serving size string like "330ml" or "1 can (330ml)" into amount and unit
    private func parseServingSize(_ servingSizeStr: String) -> (amount: String, unit: String) {
        // Clean the string
        let cleaned = servingSizeStr.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Try to extract numbers and units from patterns like:
        // "330ml", "250g", "1 can (330ml)", "30 g", "100 grams"

        // First, try to find parentheses pattern like "1 can (330ml)"
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
                let normalizedUnit = normalizeUnit(unit)

                return (amount, normalizedUnit)
            }
        }

        // Fallback: return default
        return ("100", "g")
    }

    /// Normalize unit names to match the app's standard units
    private func normalizeUnit(_ unit: String) -> String {
        let lowercase = unit.lowercased()

        // Map variations to standard units
        switch lowercase {
        case "milliliters", "milliliter", "mls":
            return "ml"
        case "grams", "gram", "gr":
            return "g"
        case "ounces", "ounce":
            return "oz"
        case "kilograms", "kilogram", "kgs":
            return "g" // Convert kg to g (will need amount conversion too)
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
}

// MARK: - Supporting Components

/// Section header for form sections
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.primary)
    }
}

/// Form field wrapper with label
struct FormField<Content: View>: View {
    let label: String
    var isRequired: Bool = false
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.system(size: 14, weight: .bold))
                }
            }
            content()
        }
    }
}

/// Enhanced nutrition input row with optional indicator
struct ManualNutritionInputRow: View {
    let label: String
    @Binding var value: String
    let unit: String
    var isRequired: Bool = false
    var showError: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 80, alignment: .leading)
                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.system(size: 12, weight: .bold))
                }
            }

            TextField("0", text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(showError ? Color.red : Color.clear, lineWidth: 2)
                )

            Text(unit)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)
        }
    }
}

// MARK: - Barcode Scanner Sheet View

/// Simple barcode scanner sheet that populates the barcode field without searching
struct BarcodeScannerSheetView: View {
    @Binding var barcode: String
    @Binding var isPresented: Bool
    @State private var isSearching = false

    var body: some View {
        NavigationView {
            ZStack {
                ModernBarcodeScanner(
                    onBarcodeScanned: { scannedBarcode in
                        barcode = scannedBarcode
                        isPresented = false
                    },
                    isSearching: $isSearching
                )
                .ignoresSafeArea()

                VStack {
                    Spacer()

                    Text("Scan barcode to auto-fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .padding(.bottom, 40)
                }
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Serving Size Warning Banner

/// Warning banner for serving size detection issues
struct ServingSizeWarningBanner: View {
    let response: IngredientFinderResponse?

    var body: some View {
        Group {
            // Case 1: No serving size detected, but have pack size
            if (response?.serving_size_g == nil || response?.serving_size_g == 0),
               let packSize = response?.pack_size, !packSize.isEmpty {

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                        Text("No Serving Size Detected")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                    }

                    Text("The product size is **\(packSize)**. If this is a single-serve item, you can use this as the serving size. Otherwise, please check the packet for the recommended serving.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
            // Case 2: Serving size seems unrealistically large (>100g)
            else if let servingSize = response?.serving_size_g, servingSize > 100 {

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                        Text("Please Verify Serving Size")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                    }

                    Text("The detected serving size is **\(String(format: "%.0f", servingSize))g**, which seems large. Please check the packet to confirm this is the correct serving size, not the product size.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
            // Case 3: Good serving size detected (1-100g)
            else if let servingSize = response?.serving_size_g, servingSize > 0 {

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                        Text("Serving Size Detected")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                    }

                    Text("Found a serving size of **\(String(format: "%.0f", servingSize))g**. This will be used for your food diary entry.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Ingredient Confirmation Modal

/// Modal to confirm AI-found ingredients
struct IngredientConfirmationModal: View {
    let response: IngredientFinderResponse?
    let onUse: () -> Void
    let onEdit: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Success Icon
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                    }
                    .padding(.top, 32)

                    // Title
                    VStack(spacing: 8) {
                        Text("Product Information Found!")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)

                        Text("NutraSafe Ingredient Finder™")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                // Product Name & Brand
                if let productName = response?.product_name, !productName.isEmpty {
                    VStack(spacing: 4) {
                        Text(productName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)

                        if let brand = response?.brand, !brand.isEmpty {
                            Text(brand)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // Serving Size Warning Banner
                ServingSizeWarningBanner(response: response)

                // Serving Size (if available from AI)
                if let servingSizeG = response?.serving_size_g, servingSizeG > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                            Text("Recommended Serving:")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }

                        Text(String(format: "%.0fg", servingSizeG))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 20)
                }

                // Product Size (if available)
                if let sizeDesc = response?.size_description {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "gauge.with.dots.needle.67percent")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            Text("Product Size:")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }

                        Text(sizeDesc)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 20)
                }

                // Nutrition Preview (if available)
                if let nutrition = response?.nutrition_per_100g, hasAnyNutrition(nutrition) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                            Text("Nutrition per 100g:")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }

                        Text("The values below are standardized to 100g for easy comparison")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .italic()

                        VStack(spacing: 6) {
                            if let cal = nutrition.calories {
                                NutritionRow(label: "Calories", value: "\(Int(cal)) kcal")
                            }
                            if let prot = nutrition.protein {
                                NutritionRow(label: "Protein", value: String(format: "%.1fg", prot))
                            }
                            if let carbs = nutrition.carbs {
                                NutritionRow(label: "Carbs", value: String(format: "%.1fg", carbs))
                            }
                            if let fat = nutrition.fat {
                                NutritionRow(label: "Fat", value: String(format: "%.1fg", fat))
                            }
                            if let fiber = nutrition.fiber {
                                NutritionRow(label: "Fibre", value: String(format: "%.1fg", fiber))
                            }
                            if let sugar = nutrition.sugar {
                                NutritionRow(label: "Sugar", value: String(format: "%.1fg", sugar))
                            }
                            if let salt = nutrition.salt {
                                NutritionRow(label: "Salt", value: String(format: "%.1fg", salt))
                            }
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 20)
                }

                // Ingredients Preview
                if let ingredientsText = response?.ingredients_text {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Found ingredients from verified sites:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        ScrollView {
                            Text(ingredientsText)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 200)

                        if let sourceUrl = response?.source_url {
                            HStack(spacing: 4) {
                                Image(systemName: "link.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)

                                Text("Source: \(extractDomain(from: sourceUrl))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // Action Buttons
                VStack(spacing: 12) {
                    // Use Button
                    Button(action: onUse) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                            Text("Use This Information")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }

                    // Edit Button
                    Button(action: onEdit) {
                        HStack {
                            Image(systemName: "pencil.circle")
                                .font(.system(size: 18))
                            Text("Use & Edit")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }

                    // Cancel Button
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
            .navigationTitle("Search Result")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func extractDomain(from urlString: String) -> String {
        guard let url = URL(string: urlString),
              let host = url.host else {
            return "Unknown"
        }
        return host.replacingOccurrences(of: "www.", with: "")
    }

    private func hasAnyNutrition(_ nutrition: NutritionPer100g) -> Bool {
        return nutrition.calories != nil || nutrition.protein != nil || nutrition.carbs != nil ||
               nutrition.fat != nil || nutrition.fiber != nil || nutrition.sugar != nil
    }
}

// MARK: - Nutrition Row Component
struct NutritionRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Ingredient OCR Camera View

/// Camera view for scanning ingredient labels with OCR - supports multiple photos
struct IngredientOCRCameraView: View {
    let onImageCaptured: (UIImage) -> Void
    let onDismiss: () -> Void

    @State private var showingCamera = false
    @State private var capturedImages: [UIImage] = []
    @State private var currentImage: UIImage?
    @State private var isProcessing = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "text.viewfinder")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)

                        Text("Scan Ingredients")
                            .font(.title2.bold())

                        if capturedImages.isEmpty && currentImage == nil {
                            Text("Take a photo of the ingredients list")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(capturedImages.count + (currentImage != nil ? 1 : 0)) photo\(capturedImages.count + (currentImage != nil ? 1 : 0) == 1 ? "" : "s") ready")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top, 20)

                    // Show captured images
                    if !capturedImages.isEmpty || currentImage != nil {
                        VStack(spacing: 12) {
                            // Previous images
                            ForEach(Array(capturedImages.enumerated()), id: \.offset) { index, image in
                                HStack(spacing: 12) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 100)
                                        .cornerRadius(8)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Photo \(index + 1)")
                                            .font(.caption.bold())
                                        Button(action: { capturedImages.remove(at: index) }) {
                                            Label("Remove", systemImage: "trash")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }

                            // Current image
                            if let current = currentImage {
                                HStack(spacing: 12) {
                                    Image(uiImage: current)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 100)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.blue, lineWidth: 2)
                                        )

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("New Photo")
                                            .font(.caption.bold())
                                            .foregroundColor(.blue)
                                        Button(action: { currentImage = nil }) {
                                            Label("Remove", systemImage: "trash")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Tips (only show if no photos yet)
                    if capturedImages.isEmpty && currentImage == nil {
                        VStack(alignment: .leading, spacing: 10) {
                            OCRTipRow(icon: "lightbulb.fill", color: .yellow, text: "Ensure good lighting")
                            OCRTipRow(icon: "hand.raised.fill", color: .orange, text: "Hold steady to avoid blur")
                            OCRTipRow(icon: "text.magnifyingglass", color: .blue, text: "Focus on the ingredients text")
                            OCRTipRow(icon: "rectangle.stack.fill", color: .purple, text: "Take multiple photos for long lists")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Action buttons
                    VStack(spacing: 12) {
                        // Add & Take Another (if we have a current image)
                        if currentImage != nil {
                            Button(action: {
                                if let img = currentImage {
                                    capturedImages.append(img)
                                    currentImage = nil
                                }
                                showingCamera = true
                            }) {
                                Label("Add & Take Another", systemImage: "plus.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange)
                                    .cornerRadius(12)
                            }
                        }

                        // Extract button (if we have any images)
                        if !capturedImages.isEmpty || currentImage != nil {
                            Button(action: { processAllImages() }) {
                                HStack {
                                    if isProcessing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "text.viewfinder")
                                    }
                                    Text(isProcessing ? "Processing..." : "Extract Ingredients")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isProcessing ? Color.gray : Color.blue)
                                .cornerRadius(12)
                            }
                            .disabled(isProcessing)
                        }

                        // Take Photo button
                        if !isProcessing {
                            Button(action: { showingCamera = true }) {
                                Label(
                                    capturedImages.isEmpty && currentImage == nil ? "Take Photo" : "Take Another Photo",
                                    systemImage: "camera.fill"
                                )
                                .font(.headline)
                                .foregroundColor(capturedImages.isEmpty && currentImage == nil ? .white : .blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(capturedImages.isEmpty && currentImage == nil ? Color.blue : Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onDismiss() }
                }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePickerView(image: $currentImage, sourceType: .camera)
            }
        }
    }

    private func processAllImages() {
        var allImages = capturedImages
        if let current = currentImage { allImages.append(current) }
        guard !allImages.isEmpty else { return }

        if allImages.count == 1 {
            onImageCaptured(allImages[0])
        } else {
            isProcessing = true
            DispatchQueue.global(qos: .userInitiated).async {
                let combined = combineImagesVertically(allImages)
                DispatchQueue.main.async {
                    isProcessing = false
                    onImageCaptured(combined)
                }
            }
        }
    }

    private func combineImagesVertically(_ images: [UIImage]) -> UIImage {
        guard !images.isEmpty else { return UIImage() }
        if images.count == 1 { return images[0] }

        let maxWidth = images.map { $0.size.width }.max() ?? 0
        var totalHeight: CGFloat = 0
        let padding: CGFloat = 20

        for image in images {
            totalHeight += image.size.height * (maxWidth / image.size.width)
        }
        totalHeight += padding * CGFloat(images.count - 1)

        UIGraphicsBeginImageContextWithOptions(CGSize(width: maxWidth, height: totalHeight), false, 1.0)
        var yOffset: CGFloat = 0
        for image in images {
            let scale = maxWidth / image.size.width
            let scaledHeight = image.size.height * scale
            image.draw(in: CGRect(x: 0, y: yOffset, width: maxWidth, height: scaledHeight))
            yOffset += scaledHeight + padding
        }
        let combined = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return combined
    }
}

/// Helper view for OCR tips
private struct OCRTipRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Nutrition OCR Camera View

/// Camera view for scanning nutrition labels with OCR - supports multiple photos
struct NutritionOCRCameraView: View {
    let onImageCaptured: (UIImage) -> Void
    let onDismiss: () -> Void

    @State private var showingCamera = false
    @State private var capturedImages: [UIImage] = []
    @State private var currentImage: UIImage?
    @State private var isProcessing = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "tablecells")
                            .font(.system(size: 50))
                            .foregroundColor(.green)

                        Text("Scan Nutrition Label")
                            .font(.title2.bold())

                        if capturedImages.isEmpty && currentImage == nil {
                            Text("Take a photo of the nutrition table")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(capturedImages.count + (currentImage != nil ? 1 : 0)) photo\(capturedImages.count + (currentImage != nil ? 1 : 0) == 1 ? "" : "s") ready")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.top, 20)

                    // Show captured images
                    if !capturedImages.isEmpty || currentImage != nil {
                        VStack(spacing: 12) {
                            // Previous images
                            ForEach(Array(capturedImages.enumerated()), id: \.offset) { index, image in
                                HStack(spacing: 12) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 100)
                                        .cornerRadius(8)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Photo \(index + 1)")
                                            .font(.caption.bold())
                                        Button(action: { capturedImages.remove(at: index) }) {
                                            Label("Remove", systemImage: "trash")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }

                            // Current image
                            if let current = currentImage {
                                HStack(spacing: 12) {
                                    Image(uiImage: current)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 100)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.green, lineWidth: 2)
                                        )

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("New Photo")
                                            .font(.caption.bold())
                                            .foregroundColor(.green)
                                        Button(action: { currentImage = nil }) {
                                            Label("Remove", systemImage: "trash")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Tips (only show if no photos yet)
                    if capturedImages.isEmpty && currentImage == nil {
                        VStack(alignment: .leading, spacing: 10) {
                            OCRTipRow(icon: "lightbulb.fill", color: .yellow, text: "Ensure good lighting")
                            OCRTipRow(icon: "hand.raised.fill", color: .orange, text: "Hold steady to avoid blur")
                            OCRTipRow(icon: "tablecells", color: .green, text: "Include the full nutrition table")
                            OCRTipRow(icon: "textformat.123", color: .blue, text: "Focus on the 'per 100g' column")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Action buttons
                    VStack(spacing: 12) {
                        // Add & Take Another (if we have a current image)
                        if currentImage != nil {
                            Button(action: {
                                if let img = currentImage {
                                    capturedImages.append(img)
                                    currentImage = nil
                                }
                                showingCamera = true
                            }) {
                                Label("Add & Take Another", systemImage: "plus.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange)
                                    .cornerRadius(12)
                            }
                        }

                        // Extract button (if we have any images)
                        if !capturedImages.isEmpty || currentImage != nil {
                            Button(action: { processAllImages() }) {
                                HStack {
                                    if isProcessing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "tablecells")
                                    }
                                    Text(isProcessing ? "Processing..." : "Extract Nutrition")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isProcessing ? Color.gray : Color.green)
                                .cornerRadius(12)
                            }
                            .disabled(isProcessing)
                        }

                        // Take Photo button
                        if !isProcessing {
                            Button(action: { showingCamera = true }) {
                                Label(
                                    capturedImages.isEmpty && currentImage == nil ? "Take Photo" : "Take Another Photo",
                                    systemImage: "camera.fill"
                                )
                                .font(.headline)
                                .foregroundColor(capturedImages.isEmpty && currentImage == nil ? .white : .green)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(capturedImages.isEmpty && currentImage == nil ? Color.green : Color.green.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onDismiss() }
                }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePickerView(image: $currentImage, sourceType: .camera)
            }
        }
    }

    private func processAllImages() {
        var allImages = capturedImages
        if let current = currentImage { allImages.append(current) }
        guard !allImages.isEmpty else { return }

        if allImages.count == 1 {
            onImageCaptured(allImages[0])
        } else {
            isProcessing = true
            DispatchQueue.global(qos: .userInitiated).async {
                let combined = combineImagesVertically(allImages)
                DispatchQueue.main.async {
                    isProcessing = false
                    onImageCaptured(combined)
                }
            }
        }
    }

    private func combineImagesVertically(_ images: [UIImage]) -> UIImage {
        guard !images.isEmpty else { return UIImage() }
        if images.count == 1 { return images[0] }

        let maxWidth = images.map { $0.size.width }.max() ?? 0
        var totalHeight: CGFloat = 0
        let padding: CGFloat = 20

        for image in images {
            totalHeight += image.size.height * (maxWidth / image.size.width)
        }
        totalHeight += padding * CGFloat(images.count - 1)

        UIGraphicsBeginImageContextWithOptions(CGSize(width: maxWidth, height: totalHeight), false, 1.0)
        var yOffset: CGFloat = 0
        for image in images {
            let scale = maxWidth / image.size.width
            let scaledHeight = image.size.height * scale
            image.draw(in: CGRect(x: 0, y: yOffset, width: maxWidth, height: scaledHeight))
            yOffset += scaledHeight + padding
        }
        let combined = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return combined
    }
}

/// UIImagePickerController wrapper for camera (single photo)
struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView

        init(_ parent: ImagePickerView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            // Do NOT call picker.dismiss() - let SwiftUI handle dismissal via the binding
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            // Do NOT call picker.dismiss() - let SwiftUI handle dismissal via the binding
        }
    }
}

/// Multi-photo camera view that stays open for continuous capture
struct MultiPhotoCameraView: UIViewControllerRepresentable {
    @Binding var capturedImages: [UIImage]
    let onDone: () -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator

        // Add custom overlay with photo count and done button
        let overlayView = createOverlayView(context: context)
        picker.cameraOverlayView = overlayView

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // Update the photo count label when images change
        if let overlay = uiViewController.cameraOverlayView,
           let countLabel = overlay.viewWithTag(100) as? UILabel {
            countLabel.text = capturedImages.isEmpty ? "" : "\(capturedImages.count) photo\(capturedImages.count == 1 ? "" : "s")"
        }
    }

    private func createOverlayView(context: Context) -> UIView {
        let screenBounds = UIScreen.main.bounds
        let overlay = UIView(frame: screenBounds)
        overlay.backgroundColor = .clear
        overlay.isUserInteractionEnabled = true

        // Bottom bar background
        let bottomBar = UIView()
        bottomBar.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(bottomBar)

        // Photo count label
        let countLabel = UILabel()
        countLabel.tag = 100
        countLabel.text = ""
        countLabel.textColor = .white
        countLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        countLabel.textAlignment = .center
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(countLabel)

        // Done button
        let doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.backgroundColor = UIColor.systemGreen
        doneButton.layer.cornerRadius = 8
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.addTarget(context.coordinator, action: #selector(Coordinator.doneTapped), for: .touchUpInside)
        bottomBar.addSubview(doneButton)

        // Tip label at top
        let tipLabel = UILabel()
        tipLabel.text = "Take multiple photos if needed"
        tipLabel.textColor = .white
        tipLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        tipLabel.textAlignment = .center
        tipLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        tipLabel.layer.cornerRadius = 8
        tipLabel.clipsToBounds = true
        tipLabel.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(tipLabel)

        NSLayoutConstraint.activate([
            // Bottom bar
            bottomBar.leadingAnchor.constraint(equalTo: overlay.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: overlay.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: overlay.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 100),

            // Count label
            countLabel.centerXAnchor.constraint(equalTo: bottomBar.centerXAnchor),
            countLabel.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 12),

            // Done button
            doneButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -20),
            doneButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor, constant: 10),
            doneButton.widthAnchor.constraint(equalToConstant: 80),
            doneButton.heightAnchor.constraint(equalToConstant: 40),

            // Tip label
            tipLabel.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            tipLabel.topAnchor.constraint(equalTo: overlay.safeAreaLayoutGuide.topAnchor, constant: 60),
            tipLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 300),
            tipLabel.heightAnchor.constraint(equalToConstant: 30),
        ])

        return overlay
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: MultiPhotoCameraView

        init(_ parent: MultiPhotoCameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                // Add to collection and stay in camera
                parent.capturedImages.append(uiImage)

                // Update the count label
                if let overlay = picker.cameraOverlayView,
                   let countLabel = overlay.viewWithTag(100) as? UILabel {
                    let count = parent.capturedImages.count
                    countLabel.text = "\(count) photo\(count == 1 ? "" : "s")"
                }

                // Brief flash feedback
                if let overlay = picker.cameraOverlayView {
                    let flashView = UIView(frame: overlay.bounds)
                    flashView.backgroundColor = .white
                    flashView.alpha = 0.8
                    overlay.addSubview(flashView)
                    UIView.animate(withDuration: 0.3) {
                        flashView.alpha = 0
                    } completion: { _ in
                        flashView.removeFromSuperview()
                    }
                }
            }
            // Don't dismiss - stay in camera for more photos
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }

        @objc func doneTapped() {
            parent.onDone()
        }
    }
}

// MARK: - Unified Product Scanner View

/// Response model from scanProductComplete Cloud Function
struct ScanProductResponse: Codable {
    var productName: String?
    var brand: String?
    var barcode: String?
    var ingredientsText: String?
    var allergens: [String]?
    var containsStatement: String?
    var nutrition: ScanProductNutrition?
    var servingSize: Double?
    var servingUnit: String?
    var servingsPerContainer: Double?
    var confidence: Double
    var detectedContent: [String]
    var warnings: [String]?
}

struct ScanProductNutrition: Codable {
    var calories: Double?
    var protein: Double?
    var carbohydrates: Double?
    var fat: Double?
    var fiber: Double?
    var sugar: Double?
    var salt: Double?
    var saturatedFat: Double?
}

/// Unified product scanner that captures multiple photos and uses AI to auto-detect content
struct UnifiedProductScannerView: View {
    let onScanComplete: (ScanProductResponse) -> Void
    let onDismiss: () -> Void

    @State private var showingCamera = false
    @State private var capturedImages: [UIImage] = []
    @State private var currentImage: UIImage?
    @State private var isProcessing = false
    @State private var processingStage = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    // Checklist state
    @State private var hasFrontPhoto = false
    @State private var hasIngredientsPhoto = false
    @State private var hasNutritionPhoto = false

    private var totalPhotos: Int {
        capturedImages.count + (currentImage != nil ? 1 : 0)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)

                        Text("Scan Product")
                            .font(.title2.bold())

                        Text(totalPhotos == 0 ? "Take photos to auto-fill all fields" : "\(totalPhotos) photo\(totalPhotos == 1 ? "" : "s") ready")
                            .font(.subheadline)
                            .foregroundColor(totalPhotos > 0 ? .blue : .secondary)
                    }
                    .padding(.top, 20)

                    // Checklist
                    VStack(alignment: .leading, spacing: 12) {
                        Text("For best results, capture:")
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)

                        ScanChecklistItem(
                            title: "Front of Package",
                            subtitle: "Product name, brand, barcode",
                            isChecked: hasFrontPhoto,
                            icon: "rectangle.portrait"
                        )

                        ScanChecklistItem(
                            title: "Ingredients List",
                            subtitle: "Full ingredients text",
                            isChecked: hasIngredientsPhoto,
                            icon: "list.bullet.rectangle"
                        )

                        ScanChecklistItem(
                            title: "Nutrition Table",
                            subtitle: "Calories, protein, carbs, fat",
                            isChecked: hasNutritionPhoto,
                            icon: "tablecells"
                        )
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Captured photos gallery
                    if totalPhotos > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Captured Photos")
                                .font(.subheadline.bold())
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    // Previous images
                                    ForEach(Array(capturedImages.enumerated()), id: \.offset) { index, image in
                                        CapturedPhotoThumbnail(
                                            image: image,
                                            index: index + 1,
                                            onRemove: { capturedImages.remove(at: index) }
                                        )
                                    }

                                    // Current image
                                    if let current = currentImage {
                                        CapturedPhotoThumbnail(
                                            image: current,
                                            index: totalPhotos,
                                            isNew: true,
                                            onRemove: { currentImage = nil }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Tips (only show if no photos yet)
                    if totalPhotos == 0 {
                        VStack(alignment: .leading, spacing: 10) {
                            OCRTipRow(icon: "lightbulb.fill", color: .yellow, text: "Ensure good lighting")
                            OCRTipRow(icon: "hand.raised.fill", color: .orange, text: "Hold steady to avoid blur")
                            OCRTipRow(icon: "text.magnifyingglass", color: .blue, text: "Focus on the text areas")
                            OCRTipRow(icon: "barcode", color: .purple, text: "Include barcode if visible")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Processing overlay
                    if isProcessing {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .scaleEffect(1.5)

                            Text("Analyzing Photos...")
                                .font(.headline)

                            Text(processingStage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Action buttons
                    if !isProcessing {
                        VStack(spacing: 12) {
                            // Add & Take Another (if we have a current image)
                            if currentImage != nil {
                                Button(action: {
                                    if let img = currentImage {
                                        capturedImages.append(img)
                                        currentImage = nil
                                    }
                                    showingCamera = true
                                }) {
                                    Label("Add & Take Another", systemImage: "plus.circle.fill")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.orange)
                                        .cornerRadius(12)
                                }
                            }

                            // Process button (if we have any images)
                            if totalPhotos > 0 {
                                Button(action: { processAllImages() }) {
                                    HStack {
                                        Image(systemName: "wand.and.stars")
                                        Text("Auto-Fill from Photos")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(12)
                                }
                            }

                            // Take Photo button
                            Button(action: { showingCamera = true }) {
                                Label(
                                    totalPhotos == 0 ? "Take Photo" : "Take Another Photo",
                                    systemImage: "camera.fill"
                                )
                                .font(.headline)
                                .foregroundColor(totalPhotos == 0 ? .white : .blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(totalPhotos == 0 ? Color.blue : Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onDismiss() }
                }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePickerView(image: $currentImage, sourceType: .camera)
            }
            .alert("Scan Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: totalPhotos) { _, newCount in
                // Update checklist based on photo count (simple heuristic)
                hasFrontPhoto = newCount >= 1
                hasIngredientsPhoto = newCount >= 2
                hasNutritionPhoto = newCount >= 3
            }
        }
    }

    private func processAllImages() {
        var allImages = capturedImages
        if let current = currentImage { allImages.append(current) }
        guard !allImages.isEmpty else { return }

        isProcessing = true
        processingStage = "Preparing images..."

        Task {
            do {
                // Convert images to base64
                processingStage = "Uploading to AI..."
                var imagePayloads: [[String: String]] = []

                for image in allImages {
                    guard let imageData = image.jpegData(compressionQuality: 0.8) else { continue }
                    let base64String = imageData.base64EncodedString()
                    imagePayloads.append([
                        "base64": base64String,
                        "mimeType": "image/jpeg"
                    ])
                }

                processingStage = "AI analyzing photos..."

                // Call the Cloud Function
                let functions = Functions.functions()
                let callable = functions.httpsCallable("scanProductComplete")
                let result = try await callable.call(["images": imagePayloads])

                processingStage = "Processing results..."

                guard let data = result.data as? [String: Any] else {
                    throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from AI"])
                }

                // Parse the response
                let response = parseScanResponse(data)

                await MainActor.run {
                    isProcessing = false
                    onScanComplete(response)
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "Failed to scan product: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }

    private func parseScanResponse(_ data: [String: Any]) -> ScanProductResponse {
        var response = ScanProductResponse(
            confidence: data["confidence"] as? Double ?? 0.5,
            detectedContent: data["detectedContent"] as? [String] ?? []
        )

        response.productName = data["productName"] as? String
        response.brand = data["brand"] as? String
        response.barcode = data["barcode"] as? String
        response.ingredientsText = data["ingredientsText"] as? String
        response.allergens = data["allergens"] as? [String]
        response.containsStatement = data["containsStatement"] as? String
        response.servingSize = data["servingSize"] as? Double
        response.servingUnit = data["servingUnit"] as? String
        response.servingsPerContainer = data["servingsPerContainer"] as? Double
        response.warnings = data["warnings"] as? [String]

        // Parse nutrition sub-object
        if let nutritionData = data["nutrition"] as? [String: Any] {
            var nutrition = ScanProductNutrition()
            nutrition.calories = nutritionData["calories"] as? Double
            nutrition.protein = nutritionData["protein"] as? Double
            nutrition.carbohydrates = nutritionData["carbohydrates"] as? Double
            nutrition.fat = nutritionData["fat"] as? Double
            nutrition.fiber = nutritionData["fiber"] as? Double
            nutrition.sugar = nutritionData["sugar"] as? Double
            nutrition.salt = nutritionData["salt"] as? Double
            nutrition.saturatedFat = nutritionData["saturatedFat"] as? Double
            response.nutrition = nutrition
        }

        return response
    }
}

/// Checklist item for scan progress
private struct ScanChecklistItem: View {
    let title: String
    let subtitle: String
    let isChecked: Bool
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundColor(isChecked ? .green : Color(.systemGray3))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(isChecked ? .primary : .secondary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isChecked ? .blue : Color(.systemGray4))
        }
    }
}

/// Thumbnail for captured photo in gallery
private struct CapturedPhotoThumbnail: View {
    let image: UIImage
    let index: Int
    var isNew: Bool = false
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isNew ? Color.blue : Color(.systemGray4), lineWidth: isNew ? 2 : 1)
                )
                .overlay(alignment: .topTrailing) {
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.red))
                    }
                    .offset(x: 8, y: -8)
                }

            Text("Photo \(index)")
                .font(.caption2)
                .foregroundColor(isNew ? .blue : .secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    ManualFoodDetailEntryView(
        selectedTab: .constant(.add)
    )
    .environmentObject(DiaryDataManager.shared)
}
