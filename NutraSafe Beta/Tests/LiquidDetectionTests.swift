#!/usr/bin/env swift
//
// LiquidDetectionTests.swift
// Standalone quick checks for liquid vs solid detection
//
// Run with: swift Tests/LiquidDetectionTests.swift
//

import Foundation

struct FoodSample {
    let name: String
    let brand: String?
    let servingDescription: String?
    let servingSizeG: Double?
    let ingredients: [String]?
}

private func isLiquidCategory(_ food: FoodSample) -> Bool {
    let nameLower = food.name.lowercased()
    let brandLower = (food.brand ?? "").lowercased()
    let servingLower = (food.servingDescription ?? "").lowercased()

    // Powder indicators override liquids
    let powderIndicators = ["powder", "mix", "granules", "instant", "sachet", "packet", "dry mix", "concentrate"]
    if powderIndicators.contains(where: { nameLower.contains($0) }) {
        return false
    }

    // Tiny serving for drink-ish powders (e.g., hot chocolate) -> solid
    let couldBePowderDrink = nameLower.contains("hot chocolate") || nameLower.contains("cocoa") ||
                             nameLower.contains("milkshake") || nameLower.contains("drinking chocolate")
    if couldBePowderDrink, let servingG = food.servingSizeG, servingG > 0 && servingG < 50 {
        return false
    }

    // Explicit per-100 labels
    if servingLower.contains("per 100ml") { return true }
    if servingLower.contains("per 100g") { return false }

    // Bar/snack form factors with realistic bar sizes
    let barKeywords = ["bar", "flapjack", "brownie", "cookie", "biscuit", "slice", "protein bar", "cereal bar", "snack bar", "square"]
    if barKeywords.contains(where: { nameLower.contains($0) || servingLower.contains($0) }) {
        if let servingG = food.servingSizeG, servingG > 0 && servingG < 80 { return false }
        return false
    }

    // Ingredient-first token signals
    if let firstIngredient = food.ingredients?.first?.lowercased() {
        let liquidFirst = ["water", "spring water", "carbonated water", "filtered water", "fruit juice", "orange juice", "apple juice", "skimmed milk", "semi-skimmed milk", "whole milk"]
        if liquidFirst.contains(where: { firstIngredient.hasPrefix($0) }) { return true }
        let solidFirst = ["oats", "wheat", "flour", "sugar", "cocoa", "cocoa butter", "vegetable oil", "rapeseed", "palm", "sunflower", "butter", "corn", "rice"]
        if solidFirst.contains(where: { firstIngredient.hasPrefix($0) }) { return false }
    }

    // Package-size liquid cues with powder guard
    let liquidPackageSizes = ["200ml", "250ml", "330ml", "500ml", "750ml", "1000ml", "1l", "1 l", "1 litre", "1 liter"]
    if liquidPackageSizes.contains(where: { nameLower.contains($0) || servingLower.contains($0) }) &&
        !powderIndicators.contains(where: { nameLower.contains($0) }) {
        return true
    }

    // Word-boundary helper
    func containsWholeWord(_ text: String, _ word: String) -> Bool {
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
        return text.range(of: pattern, options: .regularExpression) != nil
    }

    // Ready-to-drink phrases
    let safeDrinkIndicators = ["milkshake", "milk shake", "smoothie", "lemonade",
                               "cappuccino", "espresso", "frappuccino", "hot chocolate",
                               "drinking chocolate", "flat white", "americano", "macchiato",
                               "iced coffee", "cold brew"]
    if safeDrinkIndicators.contains(where: { nameLower.contains($0) }) { return true }

    // Coffee shop brands default to drink unless food exception
    let coffeeShopBrands = ["starbucks", "costa", "caffe nero", "pret a manger", "pret"]
    if coffeeShopBrands.contains(where: { brandLower.contains($0) || nameLower.contains($0) }) {
        let foodExceptions = ["sandwich", "wrap", "panini", "cake", "muffin", "cookie", "brownie", "croissant", "pastry", "bagel", "toast", "bar"]
        if !foodExceptions.contains(where: { nameLower.contains($0) }) { return true }
    }

    // Short drink words with boundaries
    let shortDrinkWords = ["tea", "coffee", "water", "cola", "juice", "drink", "shake",
                           "squash", "cordial", "latte", "mocha", "cocoa", "pepsi", "fanta", "sprite"]
    if shortDrinkWords.contains(where: { containsWholeWord(nameLower, $0) }) { return true }

    // Chocolate snacks are solids
    let chocolateSnackIndicators = ["chocolate bar", "mars bar", "snickers", "twix", "bounty",
                                    "kitkat", "kit kat", "milky way bar", "aero bar", "yorkie",
                                    "wispa", "flake", "crunchie", "double decker", "boost",
                                    "picnic", "dairy milk", "freddo", "timeout", "lion bar"]
    if chocolateSnackIndicators.contains(where: { nameLower.contains($0) }) { return false }
    if nameLower.contains("chocolate") && !nameLower.contains("milk") { return false }

    // Fallback: category keywords
    return false
}

func assertEqual(_ value: Bool, _ expected: Bool, _ message: String) {
    if value != expected {
        print("❌ \(message) expected \(expected) got \(value)")
        exit(1)
    } else {
        print("✅ \(message)")
    }
}

// Test cases
let tests: [(FoodSample, Bool, String)] = [
    (
        FoodSample(
            name: "Graze Cocoa Vanilla Protein Bar",
            brand: "Graze",
            servingDescription: "35g bar",
            servingSizeG: 35,
            ingredients: [
                "Oats (38%)",
                "Chicory root fibre",
                "Vegetable oils (Rapeseed, Palm)",
                "Golden syrup",
                "Fat-reduced cocoa powder (3.6%)"
            ]
        ),
        false,
        "Graze bar should be solid (g)"
    ),
    (
        FoodSample(
            name: "Coca-Cola 330ml Can",
            brand: "Coca-Cola",
            servingDescription: "330ml can",
            servingSizeG: 330,
            ingredients: ["Carbonated water", "Sugar", "Colour (Caramel E150d)"]
        ),
        true,
        "330ml cola should be liquid (ml)"
    ),
    (
        FoodSample(
            name: "Hot Chocolate Powder",
            brand: "Generic",
            servingDescription: "Per 100g",
            servingSizeG: 25,
            ingredients: ["Sugar", "Fat-reduced cocoa powder", "Dried skimmed milk"]
        ),
        false,
        "Hot chocolate powder (small serving) should be solid/powder"
    ),
    (
        FoodSample(
            name: "Chocolate Milkshake Drink",
            brand: "Generic",
            servingDescription: "Serving size 330ml",
            servingSizeG: 330,
            ingredients: ["Skimmed milk", "Sugar", "Cocoa powder"]
        ),
        true,
        "Chocolate milkshake ready-to-drink should be liquid"
    ),
    (
        FoodSample(
            name: "Protein Bar 45g",
            brand: "Generic",
            servingDescription: "45g bar",
            servingSizeG: 45,
            ingredients: ["Milk protein", "Soy protein", "Oligofructose", "Cocoa butter"]
        ),
        false,
        "Protein bar should be solid (g)"
    )
]

for (sample, expected, message) in tests {
    let result = isLiquidCategory(sample)
    assertEqual(result, expected, message)
}

print("All liquid detection tests passed.")
