//
//  AddFoodManualViews.swift
//  NutraSafe Beta
//
//  Comprehensive manual food entry system with full nutrition data support
//  Supports both diary and use-by destinations with appropriate fields
//

import SwiftUI
import Foundation

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
            Text(destination == .fridge
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
    @EnvironmentObject var fastingManager: FastingManager

    // Basic Info
    @State private var foodName = ""
    @State private var brand = ""

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

    // Diary-specific fields
    @State private var selectedMealTime = "Breakfast"

    // Use By-specific fields
    @State private var expiryDate = Date()
    @State private var quantity = "1"
    @State private var location = "General"

    // UI State
    @State private var showingIngredients = false
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage = ""

    let servingUnits = ["g", "ml", "oz", "cup", "tbsp", "tsp", "piece", "slice", "serving"]
    let useByLocations = ["General", "Fridge", "Freezer", "Pantry", "Cupboard"]
    let mealTimes = ["Breakfast", "Lunch", "Dinner", "Snacks"]

    var isFormValid: Bool {
        if destination == .fridge {
            // For use by: need food name, brand, and quantity
            return !foodName.isEmpty && !brand.isEmpty && !quantity.isEmpty
        } else {
            // For diary: need food name, brand, and calories
            return !foodName.isEmpty && !brand.isEmpty && !calories.isEmpty
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
        case "quantity":
            return destination == .fridge && quantity.isEmpty
        default:
            return false
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
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

                        FormField(label: "Brand Name", isRequired: true) {
                            TextField("Enter brand name...", text: $brand)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(shouldShowError(for: "brand") ? Color.red : Color.clear, lineWidth: 2)
                                )
                        }
                    }

                    // Show full nutrition form for diary, simplified form for fridge
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
                                ManualNutritionInputRow(label: "Protein", value: $protein, unit: "g")
                                ManualNutritionInputRow(label: "Carbs", value: $carbs, unit: "g")
                                ManualNutritionInputRow(label: "Fat", value: $fat, unit: "g")
                            }
                        }

                        Divider()

                        // Additional Nutrients Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Additional Nutrients (Optional)")

                            VStack(spacing: 12) {
                                ManualNutritionInputRow(label: "Fibre", value: $fiber, unit: "g")
                                ManualNutritionInputRow(label: "Sugar", value: $sugar, unit: "g")
                                ManualNutritionInputRow(label: "Sodium", value: $sodium, unit: "mg")
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
                            Button(action: {
                                withAnimation {
                                    showingIngredients.toggle()
                                }
                            }) {
                                HStack {
                                    SectionHeader(title: "Ingredients (Optional)")
                                    Spacer()
                                    Image(systemName: showingIngredients ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 14, weight: .medium))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())

                            if showingIngredients {
                                VStack(alignment: .leading, spacing: 8) {
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
                                }
                            }
                        }
                    }

                    // Use By-specific fields (simplified form)
                    if destination == .fridge {
                        Divider()

                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Use By Details")

                            FormField(label: "Quantity", isRequired: true) {
                                TextField("1", text: $quantity)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }

                            FormField(label: "Unit") {
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

                            FormField(label: "Location") {
                                Picker("Location", selection: $location) {
                                    ForEach(useByLocations, id: \.self) { loc in
                                        Text(loc).tag(loc)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }

                            FormField(label: "Expiry Date", isRequired: true) {
                                DatePicker("", selection: $expiryDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .frame(maxWidth: .infinity, alignment: .leading)
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
                            Text(isSaving ? "Saving..." : (destination == .fridge ? "Add to Use By" : "Add to Diary"))
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
            .navigationTitle(destination == .fridge ? "Add to Use By" : "Add to Diary")
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
        }
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
                if destination == .fridge {
                    try await saveFoodToUseBy()
                } else {
                    try await saveFoodToDiary()
                }

                // Only dismiss if save was successful
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                // Don't dismiss on error - show error message instead
                await MainActor.run {
                    isSaving = false
                    // Error will be shown by the saveFoodToDiary/saveFoodToFridge functions
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
            if let barcode = prefilledBarcode {
                foodData["barcode"] = barcode
            }

            // Save to userAdded collection (with profanity check)
            let foodId = try await FirebaseManager.shared.saveUserAddedFood(foodData)
            print("✅ Manual food saved to userAdded collection: \(foodId)")

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
                barcode: prefilledBarcode,
                micronutrientProfile: nil
            )

            // Add to diary via DiaryDataManager using selected meal time
            await MainActor.run {
                let mealType = selectedMealTime.lowercased() // Convert to lowercase for storage
                diaryDataManager.addFoodItem(diaryEntry, to: mealType, for: Date())
                print("✅ Food added to user's diary (\(selectedMealTime))")

                // Track meal for fasting manager
                fastingManager.recordMeal()
            }

            // Switch to diary tab to show the added food
            await MainActor.run {
                selectedTab = .diary
            }

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
        // Create use-by item from manual data using existing FridgeItem structure
        guard let userId = FirebaseManager.shared.currentUser?.uid else {
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

        let fridgeItem = FridgeItem(
            userId: userId,
            name: "\(capitalizedFoodName) - \(capitalizedBrand)",
            quantity: Int(quantity) ?? 1,
            unit: servingUnit,
            expiryDate: expiryDate,
            category: location,
            notes: ingredientsText.isEmpty ? nil : ingredientsText,
            barcode: prefilledBarcode
        )

        // Save to Firebase
        do {
            try await FirebaseManager.shared.saveFridgeItem(fridgeItem)
            print("✅ Successfully saved item to use-by tracking")
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
                print("❌ Error saving to use-by: \(error)")
            }
            throw error
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

// MARK: - Preview

#Preview {
    ManualFoodDetailEntryView(
        selectedTab: .constant(.add),
        destination: .diary
    )
    .environmentObject(DiaryDataManager.shared)
}
