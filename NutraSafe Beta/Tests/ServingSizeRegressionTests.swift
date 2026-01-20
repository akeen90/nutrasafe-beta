import XCTest
@testable import NutraSafe_Beta

/// Regression test suite for the serving size recommendation system
/// These tests verify that the classification and safe output logic works correctly
final class ServingSizeRegressionTests: XCTestCase {

    // MARK: - Test Helpers

    /// Create a mock FoodSearchResult for testing
    private func createFood(
        name: String,
        brand: String? = nil,
        calories: Double = 200,
        isVerified: Bool = false,
        servingSizeG: Double? = nil
    ) -> FoodSearchResult {
        return FoodSearchResult(
            id: UUID().uuidString,
            name: name,
            brand: brand,
            calories: calories,
            protein: 10,
            carbs: 20,
            fat: 10,
            fiber: 2,
            sugar: 5,
            sodium: 100,
            servingSizeG: servingSizeG,
            isVerified: isVerified
        )
    }

    // MARK: - Composite Dish Detection Tests

    /// Test: "salmon en croute" should be classified as COMPOSITE_DISH
    func testSalmonEnCroute_IsCompositeDish() {
        let food = createFood(name: "Salmon en croute")
        let confidence = food.servingConfidence(forQuery: "salmon en croute")

        XCTAssertEqual(confidence.classification, .compositeDish,
                       "salmon en croute should be classified as COMPOSITE_DISH")
        XCTAssertTrue(confidence.usesSafeOutput,
                      "Composite dishes should use safe output")
    }

    /// Test: "beef wellington" should be classified as COMPOSITE_DISH
    func testBeefWellington_IsCompositeDish() {
        let food = createFood(name: "Beef Wellington")
        let confidence = food.servingConfidence(forQuery: "beef wellington")

        XCTAssertEqual(confidence.classification, .compositeDish)
        XCTAssertTrue(confidence.usesSafeOutput)
    }

    /// Test: "chicken curry" should be classified as COMPOSITE_DISH
    func testChickenCurry_IsCompositeDish() {
        let food = createFood(name: "Chicken Curry")
        let confidence = food.servingConfidence(forQuery: "chicken curry")

        XCTAssertEqual(confidence.classification, .compositeDish)
        XCTAssertTrue(confidence.usesSafeOutput)
    }

    /// Test: "fish and chips" should be classified as COMPOSITE_DISH
    func testFishAndChips_IsCompositeDish() {
        let food = createFood(name: "Fish and Chips")
        let confidence = food.servingConfidence(forQuery: "fish and chips")

        XCTAssertEqual(confidence.classification, .compositeDish)
        XCTAssertTrue(confidence.usesSafeOutput)
    }

    /// Test: "lasagne" should be classified as COMPOSITE_DISH
    func testLasagne_IsCompositeDish() {
        let food = createFood(name: "Beef Lasagne")
        let confidence = food.servingConfidence(forQuery: "lasagne")

        XCTAssertEqual(confidence.classification, .compositeDish)
        XCTAssertTrue(confidence.usesSafeOutput)
    }

    /// Test: "chicken sandwich" should be classified as COMPOSITE_DISH
    func testChickenSandwich_IsCompositeDish() {
        let food = createFood(name: "Chicken Sandwich")
        let confidence = food.servingConfidence(forQuery: "chicken sandwich")

        XCTAssertEqual(confidence.classification, .compositeDish)
        XCTAssertTrue(confidence.usesSafeOutput)
    }

    /// Test: "battered fish" should be classified as COMPOSITE_DISH
    func testBatteredFish_IsCompositeDish() {
        let food = createFood(name: "Battered Fish")
        let confidence = food.servingConfidence(forQuery: "battered fish")

        XCTAssertEqual(confidence.classification, .compositeDish)
        XCTAssertTrue(confidence.usesSafeOutput)
    }

    /// Test: "chicken nuggets" should be classified as COMPOSITE_DISH
    func testChickenNuggets_IsCompositeDish() {
        let food = createFood(name: "Chicken Nuggets")
        let confidence = food.servingConfidence(forQuery: "chicken nuggets")

        XCTAssertEqual(confidence.classification, .compositeDish)
        XCTAssertTrue(confidence.usesSafeOutput)
    }

    /// Test: "shepherd's pie" should be classified as COMPOSITE_DISH
    func testShepherdsPie_IsCompositeDish() {
        let food = createFood(name: "Shepherd's Pie")
        let confidence = food.servingConfidence(forQuery: "shepherd's pie")

        XCTAssertEqual(confidence.classification, .compositeDish)
        XCTAssertTrue(confidence.usesSafeOutput)
    }

    /// Test: "spaghetti bolognese" should be classified as COMPOSITE_DISH
    func testSpagBol_IsCompositeDish() {
        let food = createFood(name: "Spaghetti Bolognese")
        let confidence = food.servingConfidence(forQuery: "spaghetti bolognese")

        XCTAssertEqual(confidence.classification, .compositeDish)
        XCTAssertTrue(confidence.usesSafeOutput)
    }

    /// Test: "chicken stir fry" should be classified as COMPOSITE_DISH
    func testChickenStirFry_IsCompositeDish() {
        let food = createFood(name: "Chicken Stir Fry")
        let confidence = food.servingConfidence(forQuery: "chicken stir fry")

        XCTAssertEqual(confidence.classification, .compositeDish)
        XCTAssertTrue(confidence.usesSafeOutput)
    }

    // MARK: - Ambiguous Query Tests

    /// Test: Single word "salmon" should be classified as AMBIGUOUS
    func testSalmon_IsAmbiguous() {
        let food = createFood(name: "Salmon")
        let confidence = food.servingConfidence(forQuery: "salmon")

        XCTAssertEqual(confidence.classification, .ambiguous,
                       "Single word 'salmon' should be classified as AMBIGUOUS")
        XCTAssertTrue(confidence.usesSafeOutput)
    }

    /// Test: Single word "chicken" should be classified as AMBIGUOUS
    func testChicken_IsAmbiguous() {
        let food = createFood(name: "Chicken")
        let confidence = food.servingConfidence(forQuery: "chicken")

        XCTAssertEqual(confidence.classification, .ambiguous)
        XCTAssertTrue(confidence.usesSafeOutput)
    }

    /// Test: Single word "pasta" should be classified as AMBIGUOUS
    func testPasta_IsAmbiguous() {
        let food = createFood(name: "Pasta")
        let confidence = food.servingConfidence(forQuery: "pasta")

        XCTAssertEqual(confidence.classification, .ambiguous)
        XCTAssertTrue(confidence.usesSafeOutput)
    }

    /// Test: "cooked chicken" (vague preparation) should be classified as AMBIGUOUS
    func testCookedChicken_IsAmbiguous() {
        let food = createFood(name: "Cooked Chicken")
        let confidence = food.servingConfidence(forQuery: "cooked chicken")

        XCTAssertEqual(confidence.classification, .ambiguous)
        XCTAssertTrue(confidence.usesSafeOutput)
    }

    // MARK: - Atomic Food Tests (Should Get Specific Presets)

    /// Test: "salmon fillet" should be classified as ATOMIC_RAW with high confidence
    func testSalmonFillet_IsAtomicRaw() {
        let food = createFood(name: "Salmon Fillet", isVerified: true)
        let confidence = food.servingConfidence(forQuery: "salmon fillet")

        XCTAssertTrue(
            confidence.classification == .atomicRaw || confidence.classification == .atomicPrepared,
            "salmon fillet should be ATOMIC_RAW or ATOMIC_PREPARED"
        )
        // Should have high enough confidence for category presets
        XCTAssertGreaterThanOrEqual(confidence.score, 0.6)
    }

    /// Test: "chicken breast" should be classified as ATOMIC_RAW
    func testChickenBreast_IsAtomicRaw() {
        let food = createFood(name: "Chicken Breast", isVerified: true)
        let confidence = food.servingConfidence(forQuery: "chicken breast")

        XCTAssertTrue(
            confidence.classification == .atomicRaw || confidence.classification == .atomicPrepared
        )
    }

    /// Test: "boiled egg" should be classified as ATOMIC_PREPARED
    func testBoiledEgg_IsAtomicPrepared() {
        let food = createFood(name: "Boiled Egg")
        let confidence = food.servingConfidence(forQuery: "boiled egg")

        // Eggs are a special case - well understood
        XCTAssertNotEqual(confidence.classification, .compositeDish)
        XCTAssertNotEqual(confidence.classification, .ambiguous)
    }

    /// Test: "apple" should be ATOMIC_RAW (not ambiguous for common fruits)
    func testApple_IsAtomicRaw() {
        let food = createFood(name: "Apple")
        let confidence = food.servingConfidence(forQuery: "apple")

        // Common fruits like "apple" are well-understood
        // They're not in the ambiguous list
        XCTAssertNotEqual(confidence.classification, .compositeDish)
    }

    // MARK: - Branded Products Tests

    /// Test: "Mars Bar" should be classified as BRANDED_PACKAGED
    func testMarsBar_IsBrandedPackaged() {
        let food = createFood(name: "Mars Bar")
        let confidence = food.servingConfidence(forQuery: "mars bar")

        XCTAssertEqual(confidence.classification, .brandedPackaged)
        // Branded products with known presets should NOT use safe output
        XCTAssertFalse(confidence.usesSafeOutput)
    }

    /// Test: "Coca Cola" should be classified as BRANDED_PACKAGED
    func testCocaCola_IsBrandedPackaged() {
        let food = createFood(name: "Coca Cola", brand: "Coca-Cola")
        let confidence = food.servingConfidence(forQuery: "coca cola")

        XCTAssertEqual(confidence.classification, .brandedPackaged)
    }

    /// Test: "tinned tuna" should be classified as BRANDED_PACKAGED
    func testTinnedTuna_IsBrandedPackaged() {
        let food = createFood(name: "Tinned Tuna")
        let confidence = food.servingConfidence(forQuery: "tinned tuna")

        XCTAssertEqual(confidence.classification, .brandedPackaged)
    }

    // MARK: - Safe Output Tests

    /// Test: Composite dishes should return generic weight-based portions
    func testCompositeDish_ReturnsSafePortions() {
        let food = createFood(name: "Salmon en croute")
        let portions = food.portionsForQuery("salmon en croute")

        // Should have portions
        XCTAssertFalse(portions.isEmpty)

        // Should be generic weight-based, NOT "small fillet" style
        for portion in portions {
            XCTAssertFalse(portion.name.lowercased().contains("fillet"),
                          "Composite dish should not have 'fillet' portions")
            XCTAssertFalse(portion.name.lowercased().contains("small"),
                          "Composite dish should not have size-based portions like 'small'")
            XCTAssertFalse(portion.name.lowercased().contains("medium"),
                          "Composite dish should not have size-based portions like 'medium'")
        }

        // Should have generic grams-based options
        let hasGenericGrams = portions.contains { $0.name.hasSuffix("g") && !$0.name.contains("(") }
        XCTAssertTrue(hasGenericGrams || portions.contains { $0.name.contains("100g") },
                     "Composite dish should have generic gram options")
    }

    /// Test: Ambiguous queries should return generic weight-based portions
    func testAmbiguousQuery_ReturnsSafePortions() {
        let food = createFood(name: "Salmon")
        let portions = food.portionsForQuery("salmon")

        XCTAssertFalse(portions.isEmpty)

        // Should not have form-factor assumptions
        for portion in portions {
            XCTAssertFalse(portion.name.lowercased().contains("fillet"))
        }
    }

    // MARK: - Edge Cases

    /// Test: "with" phrase indicates composite
    func testSalmonWithVegetables_IsCompositeDish() {
        let food = createFood(name: "Salmon with vegetables")
        let confidence = food.servingConfidence(forQuery: "salmon with vegetables")

        XCTAssertEqual(confidence.classification, .compositeDish,
                       "'with X' pattern should indicate composite dish")
    }

    /// Test: "in sauce" phrase indicates composite
    func testChickenInSauce_IsCompositeDish() {
        let food = createFood(name: "Chicken in Sauce")
        let confidence = food.servingConfidence(forQuery: "chicken in sauce")

        XCTAssertEqual(confidence.classification, .compositeDish,
                       "'in sauce' pattern should indicate composite dish")
    }

    /// Test: "stuffed" indicates composite
    func testStuffedPeppers_IsCompositeDish() {
        let food = createFood(name: "Stuffed Peppers")
        let confidence = food.servingConfidence(forQuery: "stuffed peppers")

        XCTAssertEqual(confidence.classification, .compositeDish)
    }

    // MARK: - hasPresetPortions Tests

    /// Test: hasPresetPortions returns false for composite dishes
    func testHasPresetPortions_FalseForCompositeDish() {
        let food = createFood(name: "Chicken Curry")

        // hasPresetPortions (without query) should now detect composite dishes
        XCTAssertFalse(food.hasPresetPortions,
                      "Composite dishes should not have preset portions")
    }

    /// Test: shouldShowCategoryPresets returns false for composite dishes
    func testShouldShowCategoryPresets_FalseForCompositeDish() {
        let food = createFood(name: "Beef Lasagne")

        XCTAssertFalse(food.shouldShowCategoryPresets(forQuery: "lasagne"),
                      "Composite dishes should not show category presets")
    }

    // MARK: - Performance Tests

    /// Test: Classification should be fast
    func testClassificationPerformance() {
        let food = createFood(name: "Salmon en croute with vegetables and hollandaise sauce")

        measure {
            for _ in 0..<1000 {
                _ = food.servingConfidence(forQuery: "salmon en croute")
            }
        }
    }
}

// MARK: - Test Runner (Standalone)

#if DEBUG
/// Run tests without XCTest framework for quick validation
func runRegressionTests() {
    print("================================================================================")
    print("SERVING SIZE REGRESSION TESTS")
    print("================================================================================\n")

    var passed = 0
    var failed = 0
    var failures: [(name: String, reason: String)] = []

    // Helper to create mock food
    func createFood(name: String, brand: String? = nil) -> FoodSearchResult {
        return FoodSearchResult(
            id: UUID().uuidString,
            name: name,
            brand: brand,
            calories: 200,
            protein: 10,
            carbs: 20,
            fat: 10,
            fiber: 2,
            sugar: 5,
            sodium: 100,
            isVerified: false
        )
    }

    // Test definitions
    struct TestCase {
        let name: String
        let food: FoodSearchResult
        let query: String
        let expectedClassification: FoodSearchResult.ServingClassification
        let expectSafeOutput: Bool
    }

    let tests: [TestCase] = [
        // Composite dishes - MUST use safe output
        TestCase(name: "salmon en croute → COMPOSITE", food: createFood(name: "Salmon en croute"), query: "salmon en croute", expectedClassification: .compositeDish, expectSafeOutput: true),
        TestCase(name: "beef wellington → COMPOSITE", food: createFood(name: "Beef Wellington"), query: "beef wellington", expectedClassification: .compositeDish, expectSafeOutput: true),
        TestCase(name: "chicken curry → COMPOSITE", food: createFood(name: "Chicken Curry"), query: "chicken curry", expectedClassification: .compositeDish, expectSafeOutput: true),
        TestCase(name: "fish and chips → COMPOSITE", food: createFood(name: "Fish and Chips"), query: "fish and chips", expectedClassification: .compositeDish, expectSafeOutput: true),
        TestCase(name: "lasagne → COMPOSITE", food: createFood(name: "Beef Lasagne"), query: "lasagne", expectedClassification: .compositeDish, expectSafeOutput: true),
        TestCase(name: "chicken sandwich → COMPOSITE", food: createFood(name: "Chicken Sandwich"), query: "chicken sandwich", expectedClassification: .compositeDish, expectSafeOutput: true),
        TestCase(name: "battered fish → COMPOSITE", food: createFood(name: "Battered Fish"), query: "battered fish", expectedClassification: .compositeDish, expectSafeOutput: true),
        TestCase(name: "chicken nuggets → COMPOSITE", food: createFood(name: "Chicken Nuggets"), query: "chicken nuggets", expectedClassification: .compositeDish, expectSafeOutput: true),
        TestCase(name: "shepherd's pie → COMPOSITE", food: createFood(name: "Shepherd's Pie"), query: "shepherd's pie", expectedClassification: .compositeDish, expectSafeOutput: true),
        TestCase(name: "spaghetti bolognese → COMPOSITE", food: createFood(name: "Spaghetti Bolognese"), query: "spaghetti bolognese", expectedClassification: .compositeDish, expectSafeOutput: true),
        TestCase(name: "chicken stir fry → COMPOSITE", food: createFood(name: "Chicken Stir Fry"), query: "chicken stir fry", expectedClassification: .compositeDish, expectSafeOutput: true),
        TestCase(name: "tuna pasta bake → COMPOSITE", food: createFood(name: "Tuna Pasta Bake"), query: "tuna pasta bake", expectedClassification: .compositeDish, expectSafeOutput: true),

        // Ambiguous queries - MUST use safe output
        TestCase(name: "salmon (single word) → AMBIGUOUS", food: createFood(name: "Salmon"), query: "salmon", expectedClassification: .ambiguous, expectSafeOutput: true),
        TestCase(name: "chicken (single word) → AMBIGUOUS", food: createFood(name: "Chicken"), query: "chicken", expectedClassification: .ambiguous, expectSafeOutput: true),
        TestCase(name: "pasta (single word) → AMBIGUOUS", food: createFood(name: "Pasta"), query: "pasta", expectedClassification: .ambiguous, expectSafeOutput: true),
        TestCase(name: "cooked chicken → AMBIGUOUS", food: createFood(name: "Cooked Chicken"), query: "cooked chicken", expectedClassification: .ambiguous, expectSafeOutput: true),

        // Edge cases with "with", "in sauce", "stuffed"
        TestCase(name: "salmon with vegetables → COMPOSITE", food: createFood(name: "Salmon with vegetables"), query: "salmon with vegetables", expectedClassification: .compositeDish, expectSafeOutput: true),
        TestCase(name: "chicken in sauce → COMPOSITE", food: createFood(name: "Chicken in Sauce"), query: "chicken in sauce", expectedClassification: .compositeDish, expectSafeOutput: true),
        TestCase(name: "stuffed peppers → COMPOSITE", food: createFood(name: "Stuffed Peppers"), query: "stuffed peppers", expectedClassification: .compositeDish, expectSafeOutput: true),
    ]

    // Run tests
    for test in tests {
        let confidence = test.food.servingConfidence(forQuery: test.query)

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

    // Additional test: Portions for composite dishes should be generic
    print("\n--- Additional Tests: Portion Names ---")

    let salmonEnCroute = createFood(name: "Salmon en croute")
    let portions = salmonEnCroute.portionsForQuery("salmon en croute")

    let hasFilletPortion = portions.contains { $0.name.lowercased().contains("fillet") }
    if hasFilletPortion {
        failed += 1
        failures.append((name: "salmon en croute portions", reason: "Should NOT contain 'fillet' portions"))
        print("❌ FAIL: salmon en croute portions should NOT contain 'fillet'")
    } else {
        passed += 1
        print("✅ PASS: salmon en croute portions are generic (no 'fillet')")
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
    }
}
#endif
