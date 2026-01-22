//
//  FoodDetailNutritionCard.swift
//  NutraSafe Beta
//
//  Extracted from FoodDetailViewFromSearch.swift to reduce type complexity
//  and prevent stack overflow in SwiftUI's type resolution.
//

import SwiftUI

// MARK: - Nutrition Card View

struct FoodDetailNutritionCard: View {
    // Adjusted values (already multiplied by portion and quantity)
    let adjustedCalories: Double
    let adjustedProtein: Double
    let adjustedCarbs: Double
    let adjustedFat: Double
    let adjustedSatFat: Double
    let adjustedFiber: Double
    let adjustedSugar: Double
    let adjustedSalt: Double

    // Base food data for per-100g display
    let displayFood: FoodSearchResult
    let palette: AppPalette

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 20) {
            // Hero: Calories
            caloriesHero

            // Macro summary - clean cards
            macroSummary

            // Detailed nutrition - collapsible
            detailedNutritionSection

            // Per 100g values - collapsible
            per100gSection
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

    // MARK: - Calories Hero

    private var caloriesHero: some View {
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
    }

    // MARK: - Macro Summary

    private var macroSummary: some View {
        HStack(spacing: 12) {
            macroCard(label: "Protein", value: adjustedProtein, color: SemanticColors.nutrient)
            macroCard(label: "Carbs", value: adjustedCarbs, color: palette.accent)
            macroCard(label: "Fat", value: adjustedFat, color: SemanticColors.neutral)
        }
    }

    // MARK: - Macro Card

    private func macroCard(label: String, value: Double, color: Color) -> some View {
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

    // MARK: - Detailed Nutrition Section

    private var detailedNutritionSection: some View {
        DisclosureGroup {
            VStack(spacing: 8) {
                nutritionRow("Saturated Fat", value: adjustedSatFat)
                nutritionRow("Fibre", value: adjustedFiber)
                nutritionRow("Sugar", value: adjustedSugar)
                nutritionRow("Salt", value: adjustedSalt)
            }
            .padding(.top, 12)
        } label: {
            Text("More nutrition details")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(palette.textSecondary)
        }
        .tint(palette.accent)
    }

    // MARK: - Per 100g Section

    private var per100gSection: some View {
        DisclosureGroup {
            VStack(spacing: 8) {
                per100gRow("Calories", value: displayFood.calories, unit: "kcal")
                per100gRow("Protein", value: displayFood.protein, unit: "g")
                per100gRow("Carbohydrates", value: displayFood.carbs, unit: "g")
                per100gRow("Fat", value: displayFood.fat, unit: "g")
                if let satFat = displayFood.saturatedFat {
                    per100gRow("Saturated Fat", value: satFat, unit: "g")
                }
                per100gRow("Fibre", value: displayFood.fiber, unit: "g")
                per100gRow("Sugar", value: displayFood.sugar, unit: "g")
                per100gRow("Salt", value: displayFood.sodium / 1000, unit: "g") // Convert mg to g
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

    // MARK: - Nutrition Row

    private func nutritionRow(_ label: String, value: Double) -> some View {
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

    // MARK: - Per 100g Row

    private func per100gRow(_ label: String, value: Double, unit: String) -> some View {
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
}
