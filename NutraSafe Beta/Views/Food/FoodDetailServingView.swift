//
//  FoodDetailServingView.swift
//  NutraSafe Beta
//
//  Extracted from FoodDetailViewFromSearch.swift to reduce type complexity
//  and prevent stack overflow in SwiftUI's type resolution.
//

import SwiftUI

// MARK: - Serving Section View

struct FoodDetailServingView: View {
    // Data
    let food: FoodSearchResult
    let isPerUnit: Bool
    let palette: AppPalette

    // Bindings
    @Binding var selectedMeal: String
    @Binding var selectedPortionName: String
    @Binding var servingAmount: String
    @Binding var servingUnit: String
    @Binding var quantityMultiplier: Double
    @Binding var gramsAmount: String

    @Environment(\.colorScheme) var colorScheme

    private var portionUnitLabel: String {
        food.isLiquidCategory ? "ml" : "g"
    }

    // Detect if this is an oil product
    private var isOilProduct: Bool {
        let nameLower = food.name.lowercased()

        // Exclude foods that have "oil" as an ingredient or preparation method, not the main product
        // E.g., "Mackerel in Olive Oil", "Sardines in Oil", "Tuna in Sunflower Oil"
        let excludedPatterns = [
            "fish oil", "cod liver",
            "in oil", "in olive oil", "in sunflower oil", "in vegetable oil",
            "mackerel", "sardine", "tuna", "salmon", "anchov", "herring",
            "fillet", "fish", "seafood"
        ]

        for pattern in excludedPatterns {
            if nameLower.contains(pattern) {
                return false
            }
        }

        // Only treat as oil if it's actually an oil product (olive oil, vegetable oil, etc.)
        return nameLower.contains("oil")
    }

    var body: some View {
        VStack(spacing: 12) {
            // Section header
            HStack {
                Text("How much?")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(palette.textPrimary)
                Spacer()
            }

            // Meal selector - pill style
            mealSelector

            // Portion cards - interactive, not spreadsheet
            portionCards
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

    // MARK: - Meal Selector (Pill Style)

    private var mealSelector: some View {
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

    // MARK: - Portion Cards

    private var portionCards: some View {
        VStack(spacing: 8) {
            if isPerUnit {
                // Per-unit foods: single intuitive card
                perUnitCard
            } else {
                // Special handling for oils: add tablespoon option first
                if isOilProduct {
                    tablespoonCard
                }

                // Per-100g foods: portion options as cards
                let effectiveQuery = food.name
                if food.hasAnyPortionOptions(forQuery: effectiveQuery) {
                    let portions = food.portionsForQuery(effectiveQuery)
                    ForEach(portions) { portion in
                        portionCard(portion: portion)
                    }
                }
                // Custom grams option
                customGramsCard
            }

            // Quantity stepper - always visible
            quantityStepper
        }
    }

    // MARK: - Per-Unit Card

    private var perUnitCard: some View {
        let isSelected = selectedPortionName != "__custom__"
        return Button(action: { selectedPortionName = servingUnit }) {
            HStack(spacing: 10) {
                // Icon
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

                // Selection indicator
                selectionIndicator(isSelected: isSelected)
            }
            .padding(10)
            .background(cardBackground(isSelected: isSelected))
            .overlay(cardBorder(isSelected: isSelected))
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Tablespoon Card (for oils)

    private var tablespoonCard: some View {
        let portionName = "1 tablespoon"
        let servingGrams = 15.0 // Standard tablespoon of oil is ~15g
        let isSelected = selectedPortionName == portionName
        let multiplier = servingGrams / 100.0
        let portionCalories = food.calories * multiplier

        return Button(action: {
            selectedPortionName = portionName
            servingAmount = String(format: "%.0f", servingGrams)
            servingUnit = "g"
            gramsAmount = String(format: "%.0f", servingGrams)
        }) {
            HStack(spacing: 10) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? palette.accent.opacity(0.12) : palette.tertiary.opacity(0.1))
                        .frame(width: 36, height: 36)
                    Image(systemName: "drop.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? palette.accent : palette.textSecondary)
                }

                // Description
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(Int(servingGrams))g (1 tablespoon)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(palette.textPrimary)
                    Text("\(Int(portionCalories)) kcal")
                        .font(.system(size: 12))
                        .foregroundColor(palette.textSecondary)
                }

                Spacer()

                // Selection indicator
                selectionIndicator(isSelected: isSelected)
            }
            .padding(10)
            .background(cardBackground(isSelected: isSelected))
            .overlay(cardBorder(isSelected: isSelected))
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Portion Card

    private func portionCard(portion: PortionOption) -> some View {
        let isSelected = selectedPortionName == portion.name
        let multiplier = portion.serving_g / 100.0
        let portionCalories = food.calories * multiplier

        return Button(action: {
            selectedPortionName = portion.name
            servingAmount = String(format: "%.0f", portion.serving_g)
            servingUnit = food.isLiquidCategory ? "ml" : "g"
        }) {
            HStack(spacing: 10) {
                // Icon
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
                    Text("\(Int(portion.serving_g))\(portionUnitLabel) • \(Int(portionCalories)) kcal")
                        .font(.system(size: 12))
                        .foregroundColor(palette.textSecondary)
                }

                Spacer()

                // Selection indicator
                selectionIndicator(isSelected: isSelected)
            }
            .padding(10)
            .background(cardBackground(isSelected: isSelected))
            .overlay(cardBorder(isSelected: isSelected))
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Custom Grams Card

    private var customGramsCard: some View {
        let isSelected = selectedPortionName == "__custom__"
        return Button(action: { selectedPortionName = "__custom__" }) {
            HStack(spacing: 10) {
                // Icon
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
                            Text(portionUnitLabel)
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

                // Selection indicator
                selectionIndicator(isSelected: isSelected)
            }
            .padding(10)
            .background(cardBackground(isSelected: isSelected))
            .overlay(cardBorder(isSelected: isSelected))
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Quantity Stepper

    private var quantityStepper: some View {
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

    // MARK: - Helper Views

    private func selectionIndicator(isSelected: Bool) -> some View {
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

    private func cardBackground(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isSelected ? palette.accent.opacity(0.06) : (colorScheme == .dark ? Color.midnightCardSecondary : palette.tertiary.opacity(0.08)))
    }

    private func cardBorder(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(isSelected ? palette.accent.opacity(0.3) : Color.clear, lineWidth: 1.5)
    }

    // MARK: - Helper Functions

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

    private func formatQuantityMultiplier(_ quantity: Double) -> String {
        if quantity == 0.5 {
            return "½"
        } else if quantity == floor(quantity) {
            return "\(Int(quantity))"
        } else {
            return String(format: "%.1f", quantity)
        }
    }
}
