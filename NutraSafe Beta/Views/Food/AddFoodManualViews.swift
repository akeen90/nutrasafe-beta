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

/// Response model from Cloud Function
struct IngredientFinderResponse: Codable {
    let ingredients_found: Bool
    let product_name: String?
    let brand: String?
    let barcode: String?
    let serving_size: String?
    let ingredients_text: String?
    let nutrition_per_100g: NutritionPer100g?
    let source_url: String?
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

    /// Search for ingredients using AI (checks cache first)
    func findIngredients(productName: String, brand: String?) async throws -> IngredientFinderResponse {
        // Check rate limit
        try checkRateLimit()

        // Check cache first
        if let cached = try? await FirebaseManager.shared.getIngredientCache(productName: productName, brand: brand) {
            print("✅ Found ingredients in cache for \(productName)")
            return IngredientFinderResponse(
                ingredients_found: cached.ingredients_found,
                product_name: nil,  // Cache doesn't store product name yet
                brand: nil,  // Cache doesn't store brand yet
                barcode: nil,  // Cache doesn't store barcode yet
                serving_size: nil,  // Cache doesn't store serving size yet
                ingredients_text: cached.ingredients_text,
                nutrition_per_100g: nil,  // Cache doesn't store nutrition yet
                source_url: cached.source_url
            )
        }

        // Call Cloud Function
        isSearching = true
        defer { isSearching = false }

        let response = try await callCloudFunction(productName: productName, brand: brand)

        // Cache the result if ingredients were found
        if response.ingredients_found, let ingredientsText = response.ingredients_text {
            try? await FirebaseManager.shared.setIngredientCache(
                productName: productName,
                brand: brand,
                ingredientsText: ingredientsText,
                sourceUrl: response.source_url
            )
        }

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

    private func callCloudFunction(productName: String, brand: String?) async throws -> IngredientFinderResponse {
        // Get endpoint URL from AppConfig
        let endpointURLString = AppConfig.Firebase.Functions.findIngredients
        print("🔍 Debug: Endpoint URL from AppConfig: \(endpointURLString)")

        guard let url = URL(string: endpointURLString) else {
            print("❌ Debug: Invalid URL: \(endpointURLString)")
            throw IngredientFinderError.notConfigured
        }

        // Prepare request body
        var requestBody: [String: Any] = ["productName": productName]
        if let brand = brand, !brand.isEmpty {
            requestBody["brand"] = brand
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
    @Binding var destination: AddFoodMainView.AddDestination
    var prefilledBarcode: String? = nil
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
            Text("Manual Entry")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)

            // Description
            Text(destination == .useBy
                 ? "Add item with use-by date tracking"
                 : "Add item to your diary with complete nutrition data")
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
        .sheet(isPresented: $showingDetailEntry) {
            ManualFoodDetailEntryView(selectedTab: $selectedTab, destination: destination, prefilledBarcode: prefilledBarcode)
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

/// Comprehensive manual food entry form with all nutrition fields
struct ManualFoodDetailEntryView: View {
    @Binding var selectedTab: TabItem
    let destination: AddFoodMainView.AddDestination
    var prefilledBarcode: String? = nil
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var diaryDataManager: DiaryDataManager

    // Basic Info
    @State private var foodName = ""
    @State private var brand = ""
    @State private var barcode = ""

    // Serving
    @State private var servingSize = "100"
    @State private var servingUnit = "g"

    // Core Macros (per 100g)
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

    // Use By-specific fields
    @State private var expiryDate = Date()
    @State private var quantity = "1"
    @State private var location = "General"
    @State private var expiryAmount = 7
    @State private var expiryUnit: ExpiryUnit = .days

    enum ExpiryUnit: String, CaseIterable {
        case days = "Days"
        case weeks = "Weeks"
    }

    // UI State
    @State private var showingIngredients = false
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingBarcodeScanner = false

    let servingUnits = ["g", "ml", "oz", "cup", "tbsp", "tsp", "piece", "slice", "serving"]
    let useByLocations = ["General", "UseBy", "Freezer", "Pantry", "Cupboard"]
    let mealTimes = ["Breakfast", "Lunch", "Dinner", "Snacks"]

    var isFormValid: Bool {
        if destination == .useBy {
            // For useBy: need food name and brand only
            return !foodName.isEmpty && !brand.isEmpty
        } else {
            // For diary: need food name, brand, calories, carbs, protein, and fat
            return !foodName.isEmpty && !brand.isEmpty && !calories.isEmpty && !carbs.isEmpty && !protein.isEmpty && !fat.isEmpty
        }
    }

    // Helper to check if a required field is empty and should show error
    private func shouldShowError(for field: String) -> Bool {
        // Only show error if user has tried to save (isSaving was true at some point)
        guard showingError || isSaving else { return false }

        switch field {
        case "foodName":
            return foodName.isEmpty
        case "brand":
            return brand.isEmpty
        case "calories":
            return destination == .diary && calories.isEmpty
        case "carbs":
            return destination == .diary && carbs.isEmpty
        case "protein":
            return destination == .diary && protein.isEmpty
        case "fat":
            return destination == .diary && fat.isEmpty
        default:
            return false
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // AI Helper Banner - only for Diary destination
                    if destination == .diary {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 20))
                                .foregroundColor(.purple)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("AI-Powered Search")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text("Enter what you know, then use 'Find with AI' to auto-complete ingredients & nutrition")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()
                        }
                        .padding(12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }

                    // Basic Information Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Basic Information")

                        FormField(label: "Food Name", isRequired: true) {
                            TextField("Enter food name...", text: $foodName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(shouldShowError(for: "foodName") ? Color.red : Color.clear, lineWidth: 2)
                                )
                        }

                        FormField(label: "Brand Name", isRequired: destination != .diary) {
                            TextField("Enter brand name...", text: $brand)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(shouldShowError(for: "brand") ? Color.red : Color.clear, lineWidth: 2)
                                )
                        }

                        // AI Search Button
                        if destination == .diary {
                            Button(action: {
                                searchIngredientsWithAI()
                            }) {
                                HStack(spacing: 6) {
                                    if isSearchingIngredients {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 14))
                                    }
                                    Text(isSearchingIngredients ? "Searching..." : "Find with AI")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.purple.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(8)
                            }
                            .disabled(isSearchingIngredients || foodName.isEmpty)
                            .opacity(foodName.isEmpty ? 0.5 : 1.0)
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
                    }

                    // Show full nutrition form for diary, simplified form for useBy
                    if destination == .diary {
                        Divider()

                        // Serving Size Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Serving Size")

                            Text("Enter nutrition values per 100g/100ml below")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)

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

                        Divider()

                        // Core Nutrition Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Core Nutrition (per 100g)")

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
                                    Text("Enter ingredients separated by commas")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)

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
                                            // Searching overlay
                                            Group {
                                                if isSearchingIngredients {
                                                    ZStack {
                                                        Color.black.opacity(0.3)
                                                            .cornerRadius(8)

                                                        VStack(spacing: 12) {
                                                            ProgressView()
                                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                                .scaleEffect(1.2)

                                                            Text("NutraSafe Ingredient Finder™")
                                                                .font(.system(size: 14, weight: .semibold))
                                                                .foregroundColor(.white)

                                                            Text("Searching trusted sources...")
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

                        } // end diary section

                    // Use By-specific fields (simplified form)
                    if destination == .useBy {
                        Divider()

                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Use By Details")

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Expires In")
                                    .font(.system(size: 14, weight: .medium))

                                HStack(spacing: 12) {
                                    // Counter for days/weeks
                                    HStack(spacing: 0) {
                                        Button(action: { if expiryAmount > 1 { expiryAmount -= 1; updateExpiryDate() } }) {
                                            Image(systemName: "minus")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .frame(width: 40, height: 36)

                                        Divider().frame(height: 20)

                                        Text("\(expiryAmount)")
                                            .frame(minWidth: 44)
                                            .font(.system(size: 16, weight: .semibold))

                                        Divider().frame(height: 20)

                                        Button(action: { if expiryAmount < 365 { expiryAmount += 1; updateExpiryDate() } }) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .frame(width: 40, height: 36)
                                    }
                                    .foregroundColor(.primary)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )

                                    // Days/Weeks picker
                                    Picker("Unit", selection: $expiryUnit) {
                                        ForEach(ExpiryUnit.allCases, id: \.self) { unit in
                                            Text(unit.rawValue).tag(unit)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .onChange(of: expiryUnit) { _ in updateExpiryDate() }
                                }
                            }

                            FormField(label: "Calculated Expiry Date") {
                                Text(expiryDate, style: .date)
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            }

                            FormField(label: "Notes (Optional)") {
                                TextEditor(text: $ingredientsText)
                                    .frame(height: 80)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                            }
                        }
                    }

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
                            Text(isSaving ? "Saving..." : (destination == .useBy ? "Add to Use By" : "Add to Diary"))
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isFormValid && !isSaving ? Color.blue : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isSaving)
                    .padding(.top, 8)

                    // Bottom spacing for keyboard
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .navigationTitle(destination == .useBy ? "Add to Use By" : "Add to Diary")
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
            .sheet(isPresented: $showingBarcodeScanner) {
                BarcodeScannerSheetView(barcode: $barcode, isPresented: $showingBarcodeScanner)
            }
            .sheet(isPresented: $showIngredientConfirmation) {
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
                        // Apply serving size if found
                        if let servingSizeStr = foundIngredients?.serving_size, !servingSizeStr.isEmpty {
                            let parsed = parseServingSize(servingSizeStr)
                            servingSize = parsed.amount
                            servingUnit = parsed.unit
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
                        // Apply serving size if found
                        if let servingSizeStr = foundIngredients?.serving_size, !servingSizeStr.isEmpty {
                            let parsed = parseServingSize(servingSizeStr)
                            servingSize = parsed.amount
                            servingUnit = parsed.unit
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
                    },
                    onCancel: {
                        showIngredientConfirmation = false
                    }
                )
            }
            .onAppear {
                // Initialize barcode from prefilledBarcode if provided
                if let prefilledBarcode = prefilledBarcode {
                    barcode = prefilledBarcode
                }
                // Initialize expiry date for Use By
                if destination == .useBy {
                    updateExpiryDate()
                }
            }
        }
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
                    brand: brand.isEmpty ? nil : brand
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

    private func updateExpiryDate() {
        let daysToAdd = expiryUnit == .weeks ? expiryAmount * 7 : expiryAmount
        expiryDate = Date().addingTimeInterval(TimeInterval(daysToAdd * 24 * 60 * 60))
    }

    private func saveFood() {
        // First check if form is valid
        if !isFormValid {
            // Show error state for invalid fields
            isSaving = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSaving = false
            }
            return
        }

        isSaving = true

        Task {
            do {
                if destination == .useBy {
                    try await saveFoodToUseBy()
                } else {
                    try await saveFoodToDiary()
                }

                // Only dismiss if save was successful
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }

                // After sheet dismisses, switch to appropriate tab
                if destination == .diary {
                    await MainActor.run {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            selectedTab = .diary
                        }
                    }
                }
            } catch {
                // Don't dismiss on error - show error message instead
                await MainActor.run {
                    isSaving = false
                    // Error will be shown by the saveFoodToDiary/saveFoodToUseBy functions
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

        // Parse nutrition values (all per 100g as entered)
        let caloriesValue = Double(calories) ?? 0
        let proteinValue = Double(protein) ?? 0
        let carbsValue = Double(carbs) ?? 0
        let fatValue = Double(fat) ?? 0
        let fiberValue = Double(fiber) ?? 0
        let sugarValue = Double(sugar) ?? 0
        let sodiumValue = Double(sodium) ?? 0
        let servingSizeValue = Double(servingSize) ?? 100

        do {
            // Prepare food data for userAdded collection with capitalized names
            var foodData: [String: Any] = [
                "foodName": capitalizedFoodName,
                "servingSize": servingSizeValue,
                "servingUnit": servingUnit,
                "calories": caloriesValue,
                "protein": proteinValue,
                "carbohydrates": carbsValue,
                "fat": fatValue
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

            // Check if AI was used to find ingredients
            let usedAI = foundIngredients != nil
            let foodId: String

            if usedAI {
                // Save to aiEnhancedFoods collection with AI metadata
                foodId = try await FirebaseManager.shared.saveAIEnhancedFood(
                    foodData,
                    sourceURL: foundIngredients?.source_url,
                    aiProductName: foundIngredients?.product_name
                )
                print("✅ AI-enhanced food saved to aiEnhancedFoods collection: \(foodId)")
            } else {
                // Save to userAdded collection (manual entry with profanity check)
                foodId = try await FirebaseManager.shared.saveUserAddedFood(foodData)
                print("✅ Manual food saved to userAdded collection: \(foodId)")
            }

            // Now add to user's diary with capitalized values
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
                servingDescription: "\(servingSizeValue)\(servingUnit) serving",
                quantity: 1.0,
                time: nil,
                processedScore: nil,
                sugarLevel: nil,
                ingredients: ingredients,
                additives: nil,
                barcode: barcode.isEmpty ? nil : barcode,
                micronutrientProfile: nil
            )

            // Add to diary via DiaryDataManager using selected meal time
            await MainActor.run {
                let mealType = selectedMealTime.lowercased() // Convert to lowercase for storage
                diaryDataManager.addFoodItem(diaryEntry, to: mealType, for: Date())
                print("✅ Food added to user's diary (\(selectedMealTime))")
            }

            // Switch to diary tab to show the added food
            // REMOVED: tab switch here to avoid race with sheet dismissal
            // selectedTab = .diary

        } catch {
            // Show error to user and re-throw to prevent dismissal
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
                print("❌ Error saving manual food: \(error.localizedDescription)")
            }
            throw error
        }
    }


    private func saveFoodToUseBy() async throws {
        // Create use-by item from manual data using UseByInventoryItem structure
        guard FirebaseManager.shared.currentUser?.uid != nil else {
            let error = NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to add items"])
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
            throw error
        }

        // AUTO-CAPITALIZE: Food name and brand
        let capitalizedFoodName = foodName.capitalized
        let capitalizedBrand = brand.capitalized

        // Build UseByInventoryItem to align with Use By views and Firebase storage
        let item = UseByInventoryItem(
            name: capitalizedFoodName,
            brand: capitalizedBrand.isEmpty ? nil : capitalizedBrand,
            quantity: quantity.isEmpty ? "1" : quantity,
            expiryDate: expiryDate,
            addedDate: Date(),
            barcode: barcode.isEmpty ? nil : barcode,
            category: nil,
            imageURL: nil,
            notes: ingredientsText.isEmpty ? nil : ingredientsText
        )

        // Save to Firebase (users/{uid}/useByInventory)
        do {
            try await FirebaseManager.shared.addUseByItem(item)
            print("✅ Successfully saved item to use-by inventory")

            // Switch to Use By tab and trigger refresh
            await MainActor.run {
                selectedTab = .useBy
            }

            // Give time for tab switch, then notify to refresh
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

            await MainActor.run {
                NotificationCenter.default.post(name: .useByInventoryUpdated, object: nil)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
                print("❌ Error saving to use-by: \(error)")
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

                // Serving Size (if available)
                if let servingSize = response?.serving_size {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "gauge.with.dots.needle.67percent")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            Text("Serving Size:")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }

                        Text(servingSize)
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
                                NutritionRow(label: "Fiber", value: String(format: "%.1fg", fiber))
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
            .navigationTitle("AI Search Result")
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

// MARK: - Preview

#Preview {
    ManualFoodDetailEntryView(
        selectedTab: .constant(.add),
        destination: .diary
    )
    .environmentObject(DiaryDataManager.shared)
}
