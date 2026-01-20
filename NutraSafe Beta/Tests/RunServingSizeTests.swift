#!/usr/bin/env swift
//
// RunServingSizeTests.swift
// Standalone test runner for serving size classification logic
//
// Run with: swift Tests/RunServingSizeTests.swift
//

import Foundation

// ============================================================================
// MOCK IMPLEMENTATION (copies logic from NutritionModels.swift for testing)
// ============================================================================

enum ServingClassification: String {
    case atomicRaw = "ATOMIC_RAW"
    case atomicPrepared = "ATOMIC_PREPARED"
    case compositeDish = "COMPOSITE_DISH"
    case brandedPackaged = "BRANDED_PACKAGED"
    case ambiguous = "AMBIGUOUS"
}

struct ServingConfidence {
    let score: Double
    let classification: ServingClassification
    let usesSafeOutput: Bool
    let reasons: [String]

    static let highConfidenceThreshold: Double = 0.7
}

// Composite dish indicators
let compositeDishIndicators: Set<String> = [
    "en croute", "encroute", "wellington", "pie", "pies", "pasty", "pasties",
    "pastry", "puff pastry", "shortcrust", "filo", "phyllo", "strudel",
    "samosa", "samosas", "spring roll", "spring rolls", "egg roll",
    "dumpling", "dumplings", "gyoza", "wonton", "wontons",
    "calzone", "empanada", "empanadas", "cornish pasty", "sausage roll",
    "curry", "curries", "korma", "masala", "tikka masala", "tikka",
    "madras", "vindaloo", "jalfrezi", "rogan josh", "bhuna", "balti",
    "dopiaza", "pathia", "biryani", "dhansak", "saag",
    "satay", "rendang", "massaman", "panang", "green curry", "red curry",
    "katsu", "teriyaki", "sweet and sour", "kung pao", "szechuan",
    "chow mein", "chop suey",
    "bolognese", "bolognaise", "carbonara", "arrabiata", "arrabbiata",
    "alfredo", "puttanesca", "amatriciana", "cacio e pepe",
    "lasagne", "lasagna", "cannelloni", "manicotti",
    "spaghetti and meatballs", "pasta bake", "mac and cheese", "mac n cheese",
    "macaroni cheese", "tuna pasta bake",
    "sandwich", "sandwiches", "butty", "buttie", "sarnie",
    "wrap", "wraps", "burrito", "burritos", "taco", "tacos",
    "quesadilla", "enchilada", "fajita", "fajitas",
    "panini", "paninis", "baguette filled",
    "sub", "hoagie", "hero", "grinder",
    "club sandwich", "toastie", "toasted sandwich",
    "soup", "soups", "broth", "consomme",
    "chowder", "bisque", "gazpacho", "minestrone",
    "stew", "stews", "casserole", "casseroles",
    "hotpot", "hot pot", "goulash", "bourguignon",
    "tagine", "ragu", "ragout",
    "bake", "bakes", "gratin", "au gratin", "dauphinoise",
    "crumble", "cobbler", "crisp",
    "quiche", "frittata",
    "stir fry", "stir-fry", "stirfry", "stir fried", "stir-fried",
    "pad thai", "fried rice",
    "battered", "in batter", "beer battered",
    "breaded", "crumbed", "coated", "crispy coated",
    "tempura", "panko", "southern fried",
    "nuggets", "nugget", "fingers", "finger",
    "goujons", "goujon", "bites", "popcorn chicken", "popcorn shrimp",
    "kiev", "kyiv", "cordon bleu", "schnitzel", "escalope",
    "stuffed", "filled", "loaded", "topped", "covered",
    "meal", "ready meal", "microwave meal",
    "dinner", "platter", "combo", "meal deal",
    "roast dinner", "sunday roast", "sunday lunch",
    "full english", "full breakfast", "fry up", "fry-up",
    "mixed grill",
    "fish and chips", "fish n chips", "fish & chips",
    "bangers and mash", "sausage and mash",
    "shepherd's pie", "shepherds pie", "cottage pie",
    "toad in the hole", "bubble and squeak",
    "ploughman's", "ploughmans",
    "beans on toast", "cheese on toast",
    "moussaka", "paella", "risotto",
    "ramen", "pho", "laksa",
    "falafel wrap", "shawarma", "kebab", "doner",
    "burrito bowl", "poke bowl", "buddha bowl",
]

let compositePatterns: [String] = [
    " with ", " and ", " in sauce", " in gravy", " in cream",
    " on toast", " on a bed of", " on rice", " on chips",
    " with sauce", " with gravy", " with vegetables", " with rice",
    " with noodles", " with salad", " with chips", " with fries",
    " with mash", " with coleslaw",
]

let ambiguousSingleWords: Set<String> = [
    "salmon", "chicken", "beef", "pork", "lamb", "turkey", "duck",
    "fish", "tuna", "cod", "haddock", "mackerel", "trout",
    "pasta", "rice", "bread", "noodles", "couscous",
    "curry", "pizza", "steak", "mince", "mincemeat",
    "sausage", "sausages", "bacon",
]

let vaguePreparations: Set<String> = [
    "cooked", "fried", "roast", "roasted", "baked", "grilled",
    "steamed", "boiled", "poached",
]

let chocolateBarProducts: Set<String> = [
    "mars bar", "snickers", "twix", "bounty", "milky way bar", "kitkat", "kit kat",
    "aero bar", "yorkie", "wispa bar", "flake", "crunchie", "double decker",
    "boost", "picnic", "dairy milk bar", "fruit & nut", "whole nut", "caramel",
    "turkish delight", "fudge", "curly wurly", "chomp", "freddo", "timeout",
    "toffee crisp", "drifter", "lion bar", "star bar", "topic"
]

let baggedChocolateProducts: Set<String> = [
    "revels", "maltesers", "celebrations", "minstrels", "m&m", "m&ms",
    "buttons", "giant buttons", "heroes", "roses", "quality street",
    "after eight", "matchmakers", "galaxy counters", "milkybar buttons",
    "smarties", "aero bubbles", "bitsa wispa", "lindor", "lindt lindor",
    "ferrero rocher", "ferrero", "thorntons", "godiva", "guylian", "toblerone"
]

let softDrinkBrands: Set<String> = [
    "coca-cola", "coca cola", "coke", "diet coke", "coke zero", "pepsi",
    "pepsi max", "fanta", "sprite", "7up", "7-up", "dr pepper", "irn-bru",
    "irn bru", "lucozade", "red bull", "monster", "relentless", "rockstar",
    "tango", "oasis", "schweppes", "san pellegrino", "fever-tree"
]

let packagedFormatIndicators: Set<String> = [
    "tinned", "canned", "jarred", "bottled",
    "frozen", "packet", "sachet", "pouch",
    "smoked", "cured", "dried",
]

func containsCompositeDishIndicator(_ text: String) -> Bool {
    let textLower = text.lowercased()

    for indicator in compositeDishIndicators {
        if textLower.contains(indicator) {
            return true
        }
    }

    for pattern in compositePatterns {
        if textLower.contains(pattern) {
            return true
        }
    }

    return false
}

func hasPackagedFormatIndicator(_ text: String) -> Bool {
    let textLower = text.lowercased()
    return packagedFormatIndicators.contains(where: { textLower.contains($0) })
}

func servingConfidence(foodName: String, query: String) -> ServingConfidence {
    var score: Double = 0.5
    var reasons: [String] = []
    var classification: ServingClassification = .ambiguous

    let queryLower = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    let nameLower = foodName.lowercased()
    let queryWords = queryLower.split(separator: " ").map { String($0) }

    // STEP 1: Check for COMPOSITE DISH
    if containsCompositeDishIndicator(nameLower) || containsCompositeDishIndicator(queryLower) {
        classification = .compositeDish
        score = 0.9
        reasons.append("Contains composite dish indicator")
        return ServingConfidence(score: score, classification: classification, usesSafeOutput: true, reasons: reasons)
    }

    // STEP 2: Check for BRANDED/PACKAGED
    if hasPackagedFormatIndicator(nameLower) || hasPackagedFormatIndicator(queryLower) {
        classification = .brandedPackaged
        score = 0.4
        reasons.append("Packaged item")
        return ServingConfidence(score: score, classification: classification, usesSafeOutput: true, reasons: reasons)
    }

    let isBrandedSnack = chocolateBarProducts.contains(where: { nameLower.contains($0) }) ||
                         baggedChocolateProducts.contains(where: { nameLower.contains($0) }) ||
                         softDrinkBrands.contains(where: { nameLower.contains($0) })
    if isBrandedSnack {
        classification = .brandedPackaged
        score = 0.85
        reasons.append("Known branded product")
        return ServingConfidence(score: score, classification: classification, usesSafeOutput: false, reasons: reasons)
    }

    // STEP 3: Check for AMBIGUOUS
    if queryWords.count == 1 && ambiguousSingleWords.contains(queryLower) {
        classification = .ambiguous
        score = 0.2
        reasons.append("Single-word generic ingredient")
        return ServingConfidence(score: score, classification: classification, usesSafeOutput: true, reasons: reasons)
    }

    if queryWords.count == 2 {
        let firstWord = queryWords[0]
        let secondWord = queryWords[1]
        if vaguePreparations.contains(firstWord) && ambiguousSingleWords.contains(secondWord) {
            classification = .ambiguous
            score = 0.3
            reasons.append("Vague preparation with generic ingredient")
            return ServingConfidence(score: score, classification: classification, usesSafeOutput: true, reasons: reasons)
        }
    }

    // STEP 4: ATOMIC classification
    let preparedIndicators = ["grilled", "roasted", "baked", "fried", "steamed", "boiled", "poached", "smoked", "cured"]
    let isPrepared = preparedIndicators.contains(where: { nameLower.contains($0) || queryLower.contains($0) })
    classification = isPrepared ? .atomicPrepared : .atomicRaw
    score = 0.5

    let usesSafeOutput = score < ServingConfidence.highConfidenceThreshold
    return ServingConfidence(score: score, classification: classification, usesSafeOutput: usesSafeOutput, reasons: reasons)
}

// ============================================================================
// TEST RUNNER
// ============================================================================

struct TestCase {
    let name: String
    let foodName: String
    let query: String
    let expectedClassification: ServingClassification
    let expectSafeOutput: Bool
}

let tests: [TestCase] = [
    // Composite dishes - MUST use safe output
    TestCase(name: "salmon en croute → COMPOSITE", foodName: "Salmon en croute", query: "salmon en croute", expectedClassification: .compositeDish, expectSafeOutput: true),
    TestCase(name: "beef wellington → COMPOSITE", foodName: "Beef Wellington", query: "beef wellington", expectedClassification: .compositeDish, expectSafeOutput: true),
    TestCase(name: "chicken curry → COMPOSITE", foodName: "Chicken Curry", query: "chicken curry", expectedClassification: .compositeDish, expectSafeOutput: true),
    TestCase(name: "fish and chips → COMPOSITE", foodName: "Fish and Chips", query: "fish and chips", expectedClassification: .compositeDish, expectSafeOutput: true),
    TestCase(name: "lasagne → COMPOSITE", foodName: "Beef Lasagne", query: "lasagne", expectedClassification: .compositeDish, expectSafeOutput: true),
    TestCase(name: "chicken sandwich → COMPOSITE", foodName: "Chicken Sandwich", query: "chicken sandwich", expectedClassification: .compositeDish, expectSafeOutput: true),
    TestCase(name: "battered fish → COMPOSITE", foodName: "Battered Fish", query: "battered fish", expectedClassification: .compositeDish, expectSafeOutput: true),
    TestCase(name: "chicken nuggets → COMPOSITE", foodName: "Chicken Nuggets", query: "chicken nuggets", expectedClassification: .compositeDish, expectSafeOutput: true),
    TestCase(name: "shepherd's pie → COMPOSITE", foodName: "Shepherd's Pie", query: "shepherd's pie", expectedClassification: .compositeDish, expectSafeOutput: true),
    TestCase(name: "spaghetti bolognese → COMPOSITE", foodName: "Spaghetti Bolognese", query: "spaghetti bolognese", expectedClassification: .compositeDish, expectSafeOutput: true),
    TestCase(name: "chicken stir fry → COMPOSITE", foodName: "Chicken Stir Fry", query: "chicken stir fry", expectedClassification: .compositeDish, expectSafeOutput: true),
    TestCase(name: "tuna pasta bake → COMPOSITE", foodName: "Tuna Pasta Bake", query: "tuna pasta bake", expectedClassification: .compositeDish, expectSafeOutput: true),
    TestCase(name: "mac and cheese → COMPOSITE", foodName: "Mac and Cheese", query: "mac and cheese", expectedClassification: .compositeDish, expectSafeOutput: true),
    TestCase(name: "fish fingers → COMPOSITE", foodName: "Fish Fingers", query: "fish fingers", expectedClassification: .compositeDish, expectSafeOutput: true),
    TestCase(name: "chicken kiev → COMPOSITE", foodName: "Chicken Kiev", query: "chicken kiev", expectedClassification: .compositeDish, expectSafeOutput: true),

    // Ambiguous queries - MUST use safe output
    TestCase(name: "salmon (single word) → AMBIGUOUS", foodName: "Salmon", query: "salmon", expectedClassification: .ambiguous, expectSafeOutput: true),
    TestCase(name: "chicken (single word) → AMBIGUOUS", foodName: "Chicken", query: "chicken", expectedClassification: .ambiguous, expectSafeOutput: true),
    TestCase(name: "pasta (single word) → AMBIGUOUS", foodName: "Pasta", query: "pasta", expectedClassification: .ambiguous, expectSafeOutput: true),
    TestCase(name: "rice (single word) → AMBIGUOUS", foodName: "Rice", query: "rice", expectedClassification: .ambiguous, expectSafeOutput: true),
    TestCase(name: "cooked chicken → AMBIGUOUS", foodName: "Cooked Chicken", query: "cooked chicken", expectedClassification: .ambiguous, expectSafeOutput: true),
    TestCase(name: "fried fish → AMBIGUOUS", foodName: "Fried Fish", query: "fried fish", expectedClassification: .ambiguous, expectSafeOutput: true),

    // Edge cases with "with", "in sauce", "stuffed"
    TestCase(name: "salmon with vegetables → COMPOSITE", foodName: "Salmon with vegetables", query: "salmon with vegetables", expectedClassification: .compositeDish, expectSafeOutput: true),
    TestCase(name: "chicken in sauce → COMPOSITE", foodName: "Chicken in Sauce", query: "chicken in sauce", expectedClassification: .compositeDish, expectSafeOutput: true),
    TestCase(name: "stuffed peppers → COMPOSITE", foodName: "Stuffed Peppers", query: "stuffed peppers", expectedClassification: .compositeDish, expectSafeOutput: true),
    TestCase(name: "loaded potato → COMPOSITE", foodName: "Loaded Potato", query: "loaded potato", expectedClassification: .compositeDish, expectSafeOutput: true),

    // Branded products - can use specific presets
    TestCase(name: "mars bar → BRANDED", foodName: "Mars Bar", query: "mars bar", expectedClassification: .brandedPackaged, expectSafeOutput: false),
    TestCase(name: "maltesers → BRANDED", foodName: "Maltesers", query: "maltesers", expectedClassification: .brandedPackaged, expectSafeOutput: false),
    TestCase(name: "coca cola → BRANDED", foodName: "Coca Cola", query: "coca cola", expectedClassification: .brandedPackaged, expectSafeOutput: false),

    // Packaged items - use safe output
    TestCase(name: "tinned tuna → BRANDED", foodName: "Tinned Tuna", query: "tinned tuna", expectedClassification: .brandedPackaged, expectSafeOutput: true),
    TestCase(name: "canned salmon → BRANDED", foodName: "Canned Salmon", query: "canned salmon", expectedClassification: .brandedPackaged, expectSafeOutput: true),
]

// Run tests
print("================================================================================")
print("SERVING SIZE CLASSIFICATION REGRESSION TESTS")
print("================================================================================\n")

var passed = 0
var failed = 0
var failures: [(name: String, reason: String)] = []

for test in tests {
    let confidence = servingConfidence(foodName: test.foodName, query: test.query)

    var testPassed = true
    var reasons: [String] = []

    if confidence.classification != test.expectedClassification {
        testPassed = false
        reasons.append("Expected \(test.expectedClassification.rawValue), got \(confidence.classification.rawValue)")
    }

    if confidence.usesSafeOutput != test.expectSafeOutput {
        testPassed = false
        reasons.append("Expected usesSafeOutput=\(test.expectSafeOutput), got \(confidence.usesSafeOutput)")
    }

    if testPassed {
        passed += 1
        print("✅ PASS: \(test.name)")
    } else {
        failed += 1
        let reason = reasons.joined(separator: "; ")
        failures.append((name: test.name, reason: reason))
        print("❌ FAIL: \(test.name)")
        print("   Reason: \(reason)")
    }
}

// Summary
print("\n================================================================================")
print("RESULTS: \(passed) passed, \(failed) failed")
print("================================================================================")

if !failures.isEmpty {
    print("\nFAILURES:")
    for (name, reason) in failures {
        print("  • \(name): \(reason)")
    }
}

let successRate = Double(passed) / Double(passed + failed) * 100
print("\nSuccess rate: \(String(format: "%.1f", successRate))%")

if failed == 0 {
    print("\n🎉 All regression tests passed!")
} else {
    print("\n⚠️  Some tests failed. Please review the classification logic.")
}
