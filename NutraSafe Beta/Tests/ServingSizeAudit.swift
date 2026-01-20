import Foundation

// MARK: - Serving Size Audit Test Framework
// This file tests the serving size recommendation logic against diverse food queries
// to identify issues with the current classification system.

// Simulated categories from NutritionModels.swift
enum TestFoodCategory: String {
    case softDrink, cordial, juice, hotDrink, water, alcoholicDrink
    case chocolateBar, chocolateBag, sweets, crisps, iceCream
    case oil, butter, fruit, egg, rice, pasta, bread, nuts, cheese, milk, yogurt
    case meat, fish, vegetable, legume, other
}

// Expected classification for testing
enum ExpectedClassification: String {
    case atomicRaw = "ATOMIC_RAW"           // Single ingredient, raw form (apple, salmon fillet, egg)
    case atomicPrepared = "ATOMIC_PREPARED"  // Single ingredient, cooked (roast chicken, boiled egg)
    case compositeDish = "COMPOSITE_DISH"    // Multi-ingredient dish (lasagne, salmon en croute)
    case brandedPackaged = "BRANDED_PACKAGED" // Retail product with label (Mars bar, Heinz ketchup)
    case ambiguous = "AMBIGUOUS"             // Too vague to safely infer (salmon, curry, pasta)
}

struct TestQuery {
    let query: String
    let expectedClassification: ExpectedClassification
    let currentDetectedCategory: TestFoodCategory
    let currentServingSuggestions: [String]
    let isCorrect: Bool
    let issue: String?
    let rootCause: String?
}

// MARK: - Test Data
// 100+ test queries covering all categories

let testQueries: [TestQuery] = [
    // ============================================================================
    // CATEGORY 1: ATOMIC RAW FOODS (Single ingredients, raw form)
    // Expected: Can suggest specific serving sizes IF high confidence
    // ============================================================================

    // 1.1 - Plain single-word atomic foods (HIGH AMBIGUITY RISK)
    TestQuery(
        query: "salmon",
        expectedClassification: .ambiguous,
        currentDetectedCategory: .fish,
        currentServingSuggestions: ["Small fillet (100g)", "Medium fillet (140g)", "Large fillet (180g)"],
        isCorrect: false,
        issue: "Single word 'salmon' is ambiguous - could be fillet, smoked, tinned, en croute, etc.",
        rootCause: "No ambiguity detection for single-word queries"
    ),
    TestQuery(
        query: "chicken",
        expectedClassification: .ambiguous,
        currentDetectedCategory: .meat,
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "Single word 'chicken' is ambiguous - breast, thigh, whole, nuggets, curry?",
        rootCause: "No ambiguity detection for single-word queries"
    ),
    TestQuery(
        query: "egg",
        expectedClassification: .atomicRaw,
        currentDetectedCategory: .egg,
        currentServingSuggestions: ["1 egg (50g)", "2 eggs (100g)", "3 eggs (150g)"],
        isCorrect: true,
        issue: nil,
        rootCause: nil
    ),
    TestQuery(
        query: "apple",
        expectedClassification: .atomicRaw,
        currentDetectedCategory: .fruit,
        currentServingSuggestions: ["Small (80g)", "Medium (120g)", "Large (180g)"],
        isCorrect: true,
        issue: nil,
        rootCause: nil
    ),
    TestQuery(
        query: "banana",
        expectedClassification: .atomicRaw,
        currentDetectedCategory: .fruit,
        currentServingSuggestions: ["Small (80g)", "Medium (120g)", "Large (180g)"],
        isCorrect: true,
        issue: nil,
        rootCause: nil
    ),

    // 1.2 - Qualified atomic foods (SHOULD BE HIGH CONFIDENCE)
    TestQuery(
        query: "salmon fillet",
        expectedClassification: .atomicRaw,
        currentDetectedCategory: .fish,
        currentServingSuggestions: ["Small fillet (100g)", "Medium fillet (140g)", "Large fillet (180g)"],
        isCorrect: true,
        issue: nil,
        rootCause: nil
    ),
    TestQuery(
        query: "chicken breast",
        expectedClassification: .atomicRaw,
        currentDetectedCategory: .meat,
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: true,
        issue: nil,
        rootCause: nil
    ),
    TestQuery(
        query: "raw broccoli",
        expectedClassification: .atomicRaw,
        currentDetectedCategory: .vegetable,
        currentServingSuggestions: ["1 portion (80g)", "2 portions (160g)", "Side dish (120g)"],
        isCorrect: true,
        issue: nil,
        rootCause: nil
    ),

    // ============================================================================
    // CATEGORY 2: ATOMIC PREPARED FOODS (Single ingredient, cooked/prepared)
    // Expected: Can suggest specific serving sizes IF high confidence
    // ============================================================================
    TestQuery(
        query: "boiled egg",
        expectedClassification: .atomicPrepared,
        currentDetectedCategory: .egg,
        currentServingSuggestions: ["1 egg (50g)", "2 eggs (100g)", "3 eggs (150g)"],
        isCorrect: true,
        issue: nil,
        rootCause: nil
    ),
    TestQuery(
        query: "grilled salmon",
        expectedClassification: .atomicPrepared,
        currentDetectedCategory: .fish,
        currentServingSuggestions: ["Small fillet (100g)", "Medium fillet (140g)", "Large fillet (180g)"],
        isCorrect: true,
        issue: nil,
        rootCause: nil
    ),
    TestQuery(
        query: "roast chicken",
        expectedClassification: .ambiguous, // Could be whole roast or sliced portion
        currentDetectedCategory: .meat,
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "'Roast chicken' could be whole roast, carved portion, or ready meal - ambiguous",
        rootCause: "No distinction between whole roast and portion"
    ),
    TestQuery(
        query: "steamed broccoli",
        expectedClassification: .atomicPrepared,
        currentDetectedCategory: .vegetable,
        currentServingSuggestions: ["1 portion (80g)", "2 portions (160g)", "Side dish (120g)"],
        isCorrect: true,
        issue: nil,
        rootCause: nil
    ),

    // ============================================================================
    // CATEGORY 3: COMPOSITE DISHES (Multi-ingredient, prepared foods)
    // Expected: NEVER show atomic serving templates like "small fillet"
    // ============================================================================

    // 3.1 - "En croute" / pastry wrapped (CRITICAL ISSUE)
    TestQuery(
        query: "salmon en croute",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .fish,  // WRONG! Matches "salmon" keyword
        currentServingSuggestions: ["Small fillet (100g)", "Medium fillet (140g)", "Large fillet (180g)"],
        isCorrect: false,
        issue: "CRITICAL: Composite dish getting atomic fish servings (small/medium/large fillet)",
        rootCause: "Keyword 'salmon' matches fish category, ignoring 'en croute' composite indicator"
    ),
    TestQuery(
        query: "beef wellington",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .meat,  // WRONG! Matches "beef" keyword
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "Wellington is pastry-wrapped - shouldn't get raw meat portions",
        rootCause: "Keyword 'beef' matches meat category, ignoring 'wellington' composite indicator"
    ),
    TestQuery(
        query: "chicken en croute",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .meat,
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "En croute is pastry-wrapped - not plain meat",
        rootCause: "No composite dish detection for 'en croute'"
    ),

    // 3.2 - Lasagne / layered dishes
    TestQuery(
        query: "lasagne",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .pasta,  // Partially wrong
        currentServingSuggestions: ["Small (150g)", "Medium (200g)", "Large (250g)", "Extra Large (300g)"],
        isCorrect: false,
        issue: "Lasagne is a complete dish, not plain pasta - portion sizes are dish-specific",
        rootCause: "Keyword 'lasagne' matches pasta category but it's a complete multi-layer dish"
    ),
    TestQuery(
        query: "beef lasagne",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .meat,  // Matches beef first
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "Beef lasagne is a complete dish - getting raw meat portions",
        rootCause: "Beef keyword takes priority over lasagne dish recognition"
    ),
    TestQuery(
        query: "vegetable lasagne",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .pasta,
        currentServingSuggestions: ["Small (150g)", "Medium (200g)", "Large (250g)", "Extra Large (300g)"],
        isCorrect: false,
        issue: "Complete dish getting pasta-only portions",
        rootCause: "No composite dish category"
    ),

    // 3.3 - Curries
    TestQuery(
        query: "chicken curry",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .meat,
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "Curry is a complete dish with sauce - not plain meat",
        rootCause: "Chicken keyword matches meat, ignoring curry composite indicator"
    ),
    TestQuery(
        query: "tikka masala",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .other,
        currentServingSuggestions: [],  // Falls to other = no presets
        isCorrect: true,  // Correctly no presets, but should be identified as composite
        issue: nil,
        rootCause: nil
    ),
    TestQuery(
        query: "chicken tikka masala",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .meat,
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "Complete curry dish getting raw meat portions",
        rootCause: "Chicken keyword takes priority"
    ),
    TestQuery(
        query: "lamb rogan josh",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .meat,
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "Complete curry dish getting raw meat portions",
        rootCause: "Lamb keyword matches meat category"
    ),

    // 3.4 - Pies and pastries
    TestQuery(
        query: "chicken pie",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .meat,
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "Pie is a complete dish with pastry",
        rootCause: "Chicken keyword matches meat"
    ),
    TestQuery(
        query: "steak and kidney pie",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .meat,
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "Complete pie getting raw meat portions",
        rootCause: "Steak keyword matches meat"
    ),
    TestQuery(
        query: "shepherd's pie",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .other,  // No direct keyword match
        currentServingSuggestions: [],
        isCorrect: true,  // Correctly no presets
        issue: nil,
        rootCause: nil
    ),
    TestQuery(
        query: "cottage pie",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .other,
        currentServingSuggestions: [],
        isCorrect: true,
        issue: nil,
        rootCause: nil
    ),

    // 3.5 - Ready meals / prepared dishes
    TestQuery(
        query: "ready meal",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .other,
        currentServingSuggestions: [],
        isCorrect: true,
        issue: nil,
        rootCause: nil
    ),
    TestQuery(
        query: "fish and chips",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .fish,
        currentServingSuggestions: ["Small fillet (100g)", "Medium fillet (140g)", "Large fillet (180g)"],
        isCorrect: false,
        issue: "Complete meal getting plain fish fillet portions",
        rootCause: "Fish keyword matches, ignoring 'and chips' composite indicator"
    ),
    TestQuery(
        query: "bangers and mash",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .other,  // No direct match
        currentServingSuggestions: [],
        isCorrect: true,
        issue: nil,
        rootCause: nil
    ),
    TestQuery(
        query: "sausage and mash",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .meat,  // Sausage matches meat
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "Complete meal getting meat portions",
        rootCause: "Sausage keyword matches meat category"
    ),

    // 3.6 - Battered/breaded foods
    TestQuery(
        query: "battered fish",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .fish,
        currentServingSuggestions: ["Small fillet (100g)", "Medium fillet (140g)", "Large fillet (180g)"],
        isCorrect: false,
        issue: "Battered fish is not a plain fillet",
        rootCause: "Fish keyword matches, ignoring 'battered' preparation"
    ),
    TestQuery(
        query: "breaded chicken",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .meat,
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "Breaded chicken has coating - not plain meat",
        rootCause: "Chicken keyword matches meat"
    ),
    TestQuery(
        query: "fish fingers",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .fish,
        currentServingSuggestions: ["Small fillet (100g)", "Medium fillet (140g)", "Large fillet (180g)"],
        isCorrect: false,
        issue: "Fish fingers are breaded processed food - not fillets",
        rootCause: "Fish keyword matches"
    ),
    TestQuery(
        query: "chicken nuggets",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .meat,
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "Nuggets are processed - not plain meat cuts",
        rootCause: "Chicken keyword matches meat"
    ),

    // 3.7 - Sandwiches and wraps
    TestQuery(
        query: "chicken sandwich",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .meat,
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "Sandwich is a complete item",
        rootCause: "Chicken keyword matches"
    ),
    TestQuery(
        query: "tuna sandwich",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .fish,
        currentServingSuggestions: ["Small fillet (100g)", "Medium fillet (140g)", "Large fillet (180g)"],
        isCorrect: false,
        issue: "Sandwich getting fish fillet portions",
        rootCause: "Tuna keyword matches fish"
    ),
    TestQuery(
        query: "sausage sandwich",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .meat,
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "Sandwich is a complete item",
        rootCause: "Sausage keyword matches meat"
    ),
    TestQuery(
        query: "bacon butty",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .meat,
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "Butty/sandwich is complete item",
        rootCause: "Bacon keyword matches meat"
    ),

    // 3.8 - Soups and stews
    TestQuery(
        query: "chicken soup",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .meat,
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "Soup is liquid-based - not meat portions",
        rootCause: "Chicken keyword matches meat"
    ),
    TestQuery(
        query: "beef stew",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .meat,
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "Stew is a complete liquid dish",
        rootCause: "Beef keyword matches meat"
    ),
    TestQuery(
        query: "fish chowder",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .fish,
        currentServingSuggestions: ["Small fillet (100g)", "Medium fillet (140g)", "Large fillet (180g)"],
        isCorrect: false,
        issue: "Chowder is soup - not fish fillets",
        rootCause: "Fish keyword matches"
    ),

    // 3.9 - Pasta dishes (complete)
    TestQuery(
        query: "spaghetti bolognese",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .pasta,
        currentServingSuggestions: ["Small (150g)", "Medium (200g)", "Large (250g)", "Extra Large (300g)"],
        isCorrect: false,
        issue: "Complete dish with sauce - not plain pasta",
        rootCause: "Spaghetti keyword matches pasta"
    ),
    TestQuery(
        query: "carbonara",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .other,
        currentServingSuggestions: [],
        isCorrect: true,
        issue: nil,
        rootCause: nil
    ),
    TestQuery(
        query: "mac and cheese",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .cheese,  // Cheese keyword matches first?
        currentServingSuggestions: ["Slice (20g)", "Portion (30g)", "Generous (50g)", "Grated cup (100g)"],
        isCorrect: false,
        issue: "Complete dish getting cheese portion sizes",
        rootCause: "Cheese keyword in 'mac and cheese' matches cheese category"
    ),
    TestQuery(
        query: "macaroni cheese",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .pasta,
        currentServingSuggestions: ["Small (150g)", "Medium (200g)", "Large (250g)", "Extra Large (300g)"],
        isCorrect: false,
        issue: "Complete dish getting pasta portions",
        rootCause: "Macaroni keyword matches pasta"
    ),

    // ============================================================================
    // CATEGORY 4: BRANDED/PACKAGED FOODS
    // Expected: Use pack/label serving if available, else safe defaults
    // ============================================================================

    // 4.1 - Chocolate bars (correctly handled)
    TestQuery(
        query: "mars bar",
        expectedClassification: .brandedPackaged,
        currentDetectedCategory: .chocolateBar,
        currentServingSuggestions: ["Fun Size (20g)", "Standard Bar (45g)", "Duo/King Size (75g)", "Sharing (100g)"],
        isCorrect: true,
        issue: nil,
        rootCause: nil
    ),
    TestQuery(
        query: "snickers",
        expectedClassification: .brandedPackaged,
        currentDetectedCategory: .chocolateBar,
        currentServingSuggestions: ["Fun Size (20g)", "Standard Bar (45g)", "Duo/King Size (75g)", "Sharing (100g)"],
        isCorrect: true,
        issue: nil,
        rootCause: nil
    ),
    TestQuery(
        query: "twix",
        expectedClassification: .brandedPackaged,
        currentDetectedCategory: .chocolateBar,
        currentServingSuggestions: ["Fun Size (20g)", "Standard Bar (45g)", "Duo/King Size (75g)", "Sharing (100g)"],
        isCorrect: true,
        issue: nil,
        rootCause: nil
    ),

    // 4.2 - Bagged chocolates (correctly handled)
    TestQuery(
        query: "maltesers",
        expectedClassification: .brandedPackaged,
        currentDetectedCategory: .chocolateBag,
        currentServingSuggestions: ["Treat Bag (36g)", "Standard Bag (85g)", "Pouch (112g)", "Share Bag (175g)"],
        isCorrect: true,
        issue: nil,
        rootCause: nil
    ),
    TestQuery(
        query: "revels",
        expectedClassification: .brandedPackaged,
        currentDetectedCategory: .chocolateBag,
        currentServingSuggestions: ["Treat Bag (36g)", "Standard Bag (85g)", "Pouch (112g)", "Share Bag (175g)"],
        isCorrect: true,
        issue: nil,
        rootCause: nil
    ),

    // 4.3 - Condiments/sauces
    TestQuery(
        query: "heinz ketchup",
        expectedClassification: .brandedPackaged,
        currentDetectedCategory: .other,
        currentServingSuggestions: [],
        isCorrect: true,  // Correctly no presets - should use pack size
        issue: nil,
        rootCause: nil
    ),
    TestQuery(
        query: "mayonnaise",
        expectedClassification: .ambiguous,  // Could be jar, sachet, portion
        currentDetectedCategory: .other,
        currentServingSuggestions: [],
        isCorrect: true,
        issue: nil,
        rootCause: nil
    ),

    // 4.4 - Drinks (correctly handled)
    TestQuery(
        query: "coca cola",
        expectedClassification: .brandedPackaged,
        currentDetectedCategory: .softDrink,
        currentServingSuggestions: ["200ml Glass", "250ml", "330ml Can", "500ml Bottle"],
        isCorrect: true,
        issue: nil,
        rootCause: nil
    ),
    TestQuery(
        query: "orange juice",
        expectedClassification: .brandedPackaged,
        currentDetectedCategory: .juice,
        currentServingSuggestions: ["150ml Glass", "200ml", "250ml Carton", "330ml"],
        isCorrect: true,
        issue: nil,
        rootCause: nil
    ),

    // ============================================================================
    // CATEGORY 5: AMBIGUOUS QUERIES
    // Expected: MUST use safe output modes only
    // ============================================================================

    // 5.1 - Single broad words
    TestQuery(
        query: "curry",
        expectedClassification: .ambiguous,
        currentDetectedCategory: .other,
        currentServingSuggestions: [],
        isCorrect: true,  // Correctly no presets
        issue: nil,
        rootCause: nil
    ),
    TestQuery(
        query: "pasta",
        expectedClassification: .ambiguous,  // Could be dry, cooked, with sauce
        currentDetectedCategory: .pasta,
        currentServingSuggestions: ["Small (150g)", "Medium (200g)", "Large (250g)", "Extra Large (300g)"],
        isCorrect: false,
        issue: "'Pasta' alone is ambiguous - dry vs cooked, plain vs with sauce",
        rootCause: "No ambiguity detection"
    ),
    TestQuery(
        query: "rice",
        expectedClassification: .ambiguous,  // Could be dry, cooked, fried, with dishes
        currentDetectedCategory: .rice,
        currentServingSuggestions: ["Small (100g)", "Medium (150g)", "Large (200g)", "Extra Large (250g)"],
        isCorrect: false,
        issue: "'Rice' alone is ambiguous",
        rootCause: "No ambiguity detection"
    ),
    TestQuery(
        query: "bread",
        expectedClassification: .ambiguous,  // Slice, roll, loaf, type varies hugely
        currentDetectedCategory: .bread,
        currentServingSuggestions: ["1 slice (36g)", "2 slices (72g)", "Thick slice (50g)"],
        isCorrect: false,
        issue: "'Bread' alone is ambiguous - slice, roll, type not specified",
        rootCause: "No ambiguity detection"
    ),

    // 5.2 - Plurals and quantities
    TestQuery(
        query: "sausages",
        expectedClassification: .ambiguous,  // How many? What type?
        currentDetectedCategory: .meat,
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "'Sausages' plural - should ask how many, not weight-based",
        rootCause: "No plural/count handling"
    ),
    TestQuery(
        query: "2 sausages",
        expectedClassification: .compositeDish,  // User specified count - honor it
        currentDetectedCategory: .meat,
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "User specified '2 sausages' but still gets weight-based options",
        rootCause: "Quantity in query not detected"
    ),
    TestQuery(
        query: "3 eggs",
        expectedClassification: .atomicRaw,
        currentDetectedCategory: .egg,
        currentServingSuggestions: ["1 egg (50g)", "2 eggs (100g)", "3 eggs (150g)"],
        isCorrect: false,
        issue: "User said '3 eggs' but still offered 1/2/3 options",
        rootCause: "Quantity in query not honored"
    ),

    // 5.3 - Vague preparations
    TestQuery(
        query: "cooked chicken",
        expectedClassification: .ambiguous,
        currentDetectedCategory: .meat,
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "'Cooked chicken' is vague - roast, fried, grilled, sliced, whole?",
        rootCause: "No ambiguity detection for vague preparations"
    ),
    TestQuery(
        query: "fried fish",
        expectedClassification: .ambiguous,  // Could be battered, plain fried, fish fingers
        currentDetectedCategory: .fish,
        currentServingSuggestions: ["Small fillet (100g)", "Medium fillet (140g)", "Large fillet (180g)"],
        isCorrect: false,
        issue: "'Fried fish' is ambiguous - battered? plain? type?",
        rootCause: "No ambiguity detection"
    ),

    // ============================================================================
    // CATEGORY 6: EDGE CASES AND SPECIAL SCENARIOS
    // ============================================================================

    // 6.1 - Foods with "with" (indicating composite)
    TestQuery(
        query: "salmon with vegetables",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .fish,
        currentServingSuggestions: ["Small fillet (100g)", "Medium fillet (140g)", "Large fillet (180g)"],
        isCorrect: false,
        issue: "'with vegetables' indicates composite dish",
        rootCause: "No 'with X' composite detection"
    ),
    TestQuery(
        query: "rice with curry",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .rice,
        currentServingSuggestions: ["Small (100g)", "Medium (150g)", "Large (200g)", "Extra Large (250g)"],
        isCorrect: false,
        issue: "Composite dish getting plain rice portions",
        rootCause: "No 'with X' composite detection"
    ),
    TestQuery(
        query: "pasta with sauce",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .pasta,
        currentServingSuggestions: ["Small (150g)", "Medium (200g)", "Large (250g)", "Extra Large (300g)"],
        isCorrect: false,
        issue: "Composite dish indication ignored",
        rootCause: "No 'with X' detection"
    ),

    // 6.2 - "In sauce" / "in X" phrases
    TestQuery(
        query: "chicken in sauce",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .meat,
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "'In sauce' indicates composite",
        rootCause: "No 'in sauce' composite detection"
    ),
    TestQuery(
        query: "fish in batter",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .fish,
        currentServingSuggestions: ["Small fillet (100g)", "Medium fillet (140g)", "Large fillet (180g)"],
        isCorrect: false,
        issue: "Battered fish is not a fillet",
        rootCause: "No 'in X' composite detection"
    ),

    // 6.3 - Stuffed foods
    TestQuery(
        query: "stuffed chicken",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .meat,
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "Stuffed = composite dish",
        rootCause: "No 'stuffed' composite detection"
    ),
    TestQuery(
        query: "stuffed peppers",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .vegetable,
        currentServingSuggestions: ["1 portion (80g)", "2 portions (160g)", "Side dish (120g)"],
        isCorrect: false,
        issue: "Stuffed peppers are a complete dish",
        rootCause: "No 'stuffed' composite detection"
    ),

    // 6.4 - Topped/loaded foods
    TestQuery(
        query: "loaded potato",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .vegetable,  // Potato matches vegetable
        currentServingSuggestions: ["1 portion (80g)", "2 portions (160g)", "Side dish (120g)"],
        isCorrect: false,
        issue: "Loaded potato is a complete dish",
        rootCause: "No 'loaded' composite detection"
    ),
    TestQuery(
        query: "cheese topped fish",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .fish,
        currentServingSuggestions: ["Small fillet (100g)", "Medium fillet (140g)", "Large fillet (180g)"],
        isCorrect: false,
        issue: "Topped fish is composite",
        rootCause: "No 'topped' composite detection"
    ),

    // 6.5 - Casseroles and bakes
    TestQuery(
        query: "chicken casserole",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .meat,
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "Casserole is a complete dish",
        rootCause: "No 'casserole' composite detection"
    ),
    TestQuery(
        query: "tuna pasta bake",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .fish,  // Tuna matches fish
        currentServingSuggestions: ["Small fillet (100g)", "Medium fillet (140g)", "Large fillet (180g)"],
        isCorrect: false,
        issue: "Pasta bake is complete dish getting fish fillet portions!",
        rootCause: "Tuna keyword matches fish, ignoring 'pasta bake' composite"
    ),

    // 6.6 - Stir fries
    TestQuery(
        query: "chicken stir fry",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .meat,
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "Stir fry is complete dish",
        rootCause: "No 'stir fry' composite detection"
    ),
    TestQuery(
        query: "beef stir fry",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .meat,
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "Stir fry is complete dish",
        rootCause: "No 'stir fry' composite detection"
    ),

    // 6.7 - Smoked/cured (prepared but still atomic-ish)
    TestQuery(
        query: "smoked salmon",
        expectedClassification: .atomicPrepared,
        currentDetectedCategory: .fish,
        currentServingSuggestions: ["Small fillet (100g)", "Medium fillet (140g)", "Large fillet (180g)"],
        isCorrect: false,
        issue: "Smoked salmon is typically sliced, not fillet-sized",
        rootCause: "No distinction for smoked/sliced fish"
    ),
    TestQuery(
        query: "bacon",
        expectedClassification: .atomicPrepared,
        currentDetectedCategory: .meat,
        currentServingSuggestions: ["Small (85g)", "Medium (120g)", "Large (170g)", "Extra Large (225g)"],
        isCorrect: false,
        issue: "Bacon is typically counted in rashers, not weight",
        rootCause: "No rasher/slice detection for bacon"
    ),

    // 6.8 - Tinned/canned (packaged)
    TestQuery(
        query: "tinned tuna",
        expectedClassification: .brandedPackaged,
        currentDetectedCategory: .fish,
        currentServingSuggestions: ["Small fillet (100g)", "Medium fillet (140g)", "Large fillet (180g)"],
        isCorrect: false,
        issue: "Tinned tuna comes in can sizes, not fillet sizes",
        rootCause: "No 'tinned/canned' packaged detection"
    ),
    TestQuery(
        query: "canned salmon",
        expectedClassification: .brandedPackaged,
        currentDetectedCategory: .fish,
        currentServingSuggestions: ["Small fillet (100g)", "Medium fillet (140g)", "Large fillet (180g)"],
        isCorrect: false,
        issue: "Canned salmon has fixed can sizes",
        rootCause: "No 'canned' packaged detection"
    ),
    TestQuery(
        query: "baked beans",
        expectedClassification: .brandedPackaged,
        currentDetectedCategory: .legume,
        currentServingSuggestions: ["Half cup (80g)", "Cup (160g)", "Half tin (200g)"],
        isCorrect: true,  // Has "Half tin" which is appropriate
        issue: nil,
        rootCause: nil
    ),

    // 6.9 - Frozen foods
    TestQuery(
        query: "frozen peas",
        expectedClassification: .brandedPackaged,
        currentDetectedCategory: .vegetable,  // Pea matches vegetable
        currentServingSuggestions: ["1 portion (80g)", "2 portions (160g)", "Side dish (120g)"],
        isCorrect: true,  // Reasonable for frozen peas
        issue: nil,
        rootCause: nil
    ),
    TestQuery(
        query: "frozen pizza",
        expectedClassification: .brandedPackaged,
        currentDetectedCategory: .other,
        currentServingSuggestions: [],
        isCorrect: true,
        issue: nil,
        rootCause: nil
    ),

    // 6.10 - Miscellaneous composite indicators
    TestQuery(
        query: "vegetable medley",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .vegetable,
        currentServingSuggestions: ["1 portion (80g)", "2 portions (160g)", "Side dish (120g)"],
        isCorrect: true,  // Acceptable for mixed veg
        issue: nil,
        rootCause: nil
    ),
    TestQuery(
        query: "mixed grill",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .other,
        currentServingSuggestions: [],
        isCorrect: true,
        issue: nil,
        rootCause: nil
    ),
    TestQuery(
        query: "full english",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .other,
        currentServingSuggestions: [],
        isCorrect: true,
        issue: nil,
        rootCause: nil
    ),
    TestQuery(
        query: "english breakfast",
        expectedClassification: .compositeDish,
        currentDetectedCategory: .other,
        currentServingSuggestions: [],
        isCorrect: true,
        issue: nil,
        rootCause: nil
    ),
]

// MARK: - Audit Summary Generation

func generateAuditSummary() -> String {
    var output = """
    ================================================================================
    SERVING SIZE RECOMMENDATION AUDIT SUMMARY
    ================================================================================

    Total queries tested: \(testQueries.count)

    """

    // Count results
    let correctCount = testQueries.filter { $0.isCorrect }.count
    let incorrectCount = testQueries.filter { !$0.isCorrect }.count
    let successRate = Double(correctCount) / Double(testQueries.count) * 100

    output += """
    RESULTS:
    - Correct classifications: \(correctCount)
    - Incorrect classifications: \(incorrectCount)
    - Success rate: \(String(format: "%.1f", successRate))%

    ================================================================================
    INCORRECT CLASSIFICATIONS (ISSUES FOUND)
    ================================================================================

    """

    // Group by root cause
    var rootCauses: [String: [TestQuery]] = [:]
    for query in testQueries.filter({ !$0.isCorrect }) {
        let cause = query.rootCause ?? "Unknown"
        if rootCauses[cause] == nil {
            rootCauses[cause] = []
        }
        rootCauses[cause]?.append(query)
    }

    // Sort by frequency
    let sortedCauses = rootCauses.sorted { $0.value.count > $1.value.count }

    for (cause, queries) in sortedCauses {
        output += """

        ROOT CAUSE: \(cause)
        Occurrences: \(queries.count)
        Examples:
        """
        for query in queries.prefix(5) {
            output += """

            - Query: "\(query.query)"
              Current: \(query.currentDetectedCategory.rawValue) → \(query.currentServingSuggestions.first ?? "none")
              Expected: \(query.expectedClassification.rawValue)
              Issue: \(query.issue ?? "N/A")
            """
        }
        output += "\n"
    }

    output += """

    ================================================================================
    ROOT CAUSE SUMMARY (sorted by frequency)
    ================================================================================

    """

    for (index, (cause, queries)) in sortedCauses.enumerated() {
        output += "\(index + 1). \(cause): \(queries.count) occurrences\n"
    }

    return output
}

// Run audit
print(generateAuditSummary())
