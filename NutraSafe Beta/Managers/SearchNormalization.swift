//
//  SearchNormalization.swift
//  NutraSafe Beta
//
//  Multi-stage search normalization and ranking for UK food database
//  Handles: input normalization, fuzzy matching, canonical detection, UK defaults
//

import Foundation

// MARK: - Search Query Normalizer

/// Normalizes user input for optimal search matching
struct SearchQueryNormalizer {

    // MARK: - Compound Word Expansions

    /// Known compound words that users might type without spaces
    /// Maps "marsbar" → "mars bar", "kitkat" → "kit kat", etc.
    private static let compoundWordExpansions: [String: String] = [
        // Chocolate bars
        "marsbar": "mars bar",
        "snickersbar": "snickers bar",
        "twixbar": "twix bar",
        "kitkat": "kit kat",
        "kitkats": "kit kat",
        "milkyway": "milky way",
        "milkybar": "milkybar",  // Note: Milkybar is actually one word (Nestlé product)
        "dairymilk": "dairy milk",
        "doubedecker": "double decker",
        "doubledecker": "double decker",
        "curlywurly": "curly wurly",
        "kinderbueno": "kinder bueno",
        "ferrerorocher": "ferrero rocher",

        // Drinks
        "cocacola": "coca cola",
        "dietcoke": "diet coke",
        "cokezero": "coke zero",
        "pepsimax": "pepsi max",
        "drpepper": "dr pepper",
        "irnbru": "irn bru",
        "redbull": "red bull",
        "lucozade": "lucozade",  // Already one word

        // Crisps
        "walkerscrisps": "walkers crisps",
        "hulahoops": "hula hoops",
        "monstermunch": "monster munch",
        "kettlechips": "kettle chips",

        // Food items
        "semiskimmed": "semi skimmed",
        "semi-skimmed": "semi skimmed",
        "fullfat": "full fat",
        "lowfat": "low fat",
        "nonfat": "non fat",
        "wholemilk": "whole milk",
        "skimmedmilk": "skimmed milk",
        "bakedbeans": "baked beans",
        "scrambledegg": "scrambled egg",
        "scrambledeggs": "scrambled eggs",
        "boiledegg": "boiled egg",
        "poachedegg": "poached egg",
        "friedegg": "fried egg",
        "fishfingers": "fish fingers",
        "chickennuggets": "chicken nuggets",
        "jacketpotato": "jacket potato",
        "fishandchips": "fish and chips",
        "chipshop": "chip shop",
        "fullenglish": "full english",
        "englishbreakfast": "english breakfast",
        "sausageroll": "sausage roll",
        "cornishpasty": "cornish pasty",
        "porkpie": "pork pie",
        "scotchegg": "scotch egg",

        // Supermarkets/Brands
        "heinzketchup": "heinz ketchup",
        "heinzbeans": "heinz beans",
        "birdseye": "birds eye",
        "mcvities": "mcvitie's",
        "warburtons": "warburtons",
    ]

    // MARK: - UK Spelling Normalization

    /// Maps American spellings to British spellings
    private static let ukSpellingMap: [String: String] = [
        "fiber": "fibre",
        "yogurt": "yoghurt",
        "flavor": "flavour",
        "flavored": "flavoured",
        "color": "colour",
        "colored": "coloured",
        "favorite": "favourite",
        "center": "centre",
        "liter": "litre",
        "meter": "metre",
        "defense": "defence",
        "offense": "offence",
        "license": "licence",
        "practice": "practise",
        "analyze": "analyse",
        "organize": "organise",
        "recognize": "recognise",
        "realize": "realise",
        "donut": "doughnut",
        "catalog": "catalogue",
        "dialog": "dialogue",
        "program": "programme",
        "check": "cheque",  // Only for financial context, but include
    ]

    // MARK: - Hyphen/Space Variants

    /// Words that can appear with or without hyphens
    private static let hyphenVariants: [String: [String]] = [
        "semi skimmed": ["semi-skimmed", "semiskimmed"],
        "semi-skimmed": ["semi skimmed", "semiskimmed"],
        "full fat": ["full-fat", "fullfat"],
        "full-fat": ["full fat", "fullfat"],
        "low fat": ["low-fat", "lowfat"],
        "low-fat": ["low fat", "lowfat"],
        "non fat": ["non-fat", "nonfat", "fat free", "fat-free"],
        "fat free": ["fat-free", "non fat", "non-fat", "nonfat"],
        "sugar free": ["sugar-free", "sugarfree", "no sugar"],
        "sugar-free": ["sugar free", "sugarfree", "no sugar"],
        "gluten free": ["gluten-free", "glutenfree"],
        "gluten-free": ["gluten free", "glutenfree"],
        "dairy free": ["dairy-free", "dairyfree"],
        "dairy-free": ["dairy free", "dairyfree"],
        "kit kat": ["kit-kat", "kitkat"],
        "kit-kat": ["kit kat", "kitkat"],
        "coca cola": ["coca-cola", "cocacola"],
        "coca-cola": ["coca cola", "cocacola"],
        "dr pepper": ["dr. pepper", "drpepper"],
        "dr. pepper": ["dr pepper", "drpepper"],
        "irn bru": ["irn-bru", "irnbru"],
        "irn-bru": ["irn bru", "irnbru"],
        "red bull": ["redbull"],
        "diet coke": ["diet-coke", "dietcoke"],
        "coke zero": ["coke-zero", "cokezero"],
        "pepsi max": ["pepsi-max", "pepsimax"],
    ]

    // MARK: - Normalization Pipeline

    /// Main normalization function - applies all transformations
    /// Returns the normalized query plus any variant queries to search
    static func normalize(_ query: String) -> NormalizedQuery {
        var normalized = query
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Step 1: Strip punctuation (except hyphens which are meaningful)
        normalized = normalized.replacingOccurrences(
            of: "[^a-z0-9\\s\\-']",
            with: "",
            options: .regularExpression
        )

        // Step 2: Collapse multiple spaces
        normalized = normalized.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )

        // Step 3: Expand compound words
        var variants: Set<String> = [normalized]
        if let expanded = compoundWordExpansions[normalized.replacingOccurrences(of: " ", with: "")] {
            variants.insert(expanded)
        }
        // Also try expanding each word
        let words = normalized.split(separator: " ").map(String.init)
        for (i, word) in words.enumerated() {
            if let expanded = compoundWordExpansions[word] {
                var newWords = words
                newWords[i] = expanded
                variants.insert(newWords.joined(separator: " "))
            }
        }

        // Step 4: UK spelling normalization
        for (american, british) in ukSpellingMap {
            if normalized.contains(american) {
                variants.insert(normalized.replacingOccurrences(of: american, with: british))
            }
        }

        // Step 5: Hyphen/space variants
        for (original, alts) in hyphenVariants {
            if normalized.contains(original) {
                for alt in alts {
                    variants.insert(normalized.replacingOccurrences(of: original, with: alt))
                }
            }
        }

        // Step 6: Detect search intent
        let intent = detectSearchIntent(normalized)

        return NormalizedQuery(
            primary: normalized,
            variants: Array(variants),
            intent: intent
        )
    }

    // MARK: - Search Intent Detection

    /// Detects what type of search the user is performing
    private static func detectSearchIntent(_ query: String) -> SearchIntent {
        let words = query.split(separator: " ").map { String($0).lowercased() }

        // Check if it's a barcode (all digits, 8-14 characters)
        if query.allSatisfy({ $0.isNumber }) && (8...14).contains(query.count) {
            return .barcode(query)
        }

        // Check if it's a pure brand search
        let knownBrands = Set([
            "mars", "snickers", "twix", "kitkat", "cadbury", "nestle", "kelloggs",
            "heinz", "tesco", "sainsburys", "asda", "morrisons", "aldi", "lidl",
            "walkers", "mccoys", "pringles", "doritos", "mcdonalds", "kfc",
            "coca-cola", "pepsi", "fanta", "sprite", "lucozade", "ribena",
            "warburtons", "hovis", "kingsmill", "mcvities", "birdseye", "quorn"
        ])

        if words.count == 1 && knownBrands.contains(words[0]) {
            return .brandOnly(words[0])
        }

        // Check if query contains brand + product
        for brand in knownBrands {
            if words.contains(brand) && words.count > 1 {
                let productWords = words.filter { $0 != brand }
                return .brandAndProduct(brand: brand, product: productWords.joined(separator: " "))
            }
        }

        // Check if it's a generic food search
        let genericFoods = Set([
            "milk", "bread", "cheese", "butter", "eggs", "egg", "chicken", "beef",
            "pork", "lamb", "fish", "rice", "pasta", "potato", "potatoes", "apple",
            "banana", "orange", "tomato", "onion", "carrot", "broccoli", "water",
            "juice", "yoghurt", "cream", "flour", "sugar", "salt", "oil"
        ])

        if words.count == 1 && genericFoods.contains(words[0]) {
            return .genericFood(words[0])
        }

        // Default: product search
        return .productSearch(query)
    }
}

// MARK: - Normalized Query Result

struct NormalizedQuery {
    let primary: String           // Main normalized query
    let variants: [String]        // All query variants to search
    let intent: SearchIntent      // Detected search intent
}

// MARK: - Search Intent

enum SearchIntent {
    case barcode(String)                          // Pure barcode search
    case brandOnly(String)                        // Just a brand name ("mars")
    case brandAndProduct(brand: String, product: String)  // Brand + product ("mars bar")
    case genericFood(String)                      // Generic food ("milk")
    case productSearch(String)                    // General product search

    var description: String {
        switch self {
        case .barcode(let code): return "barcode:\(code)"
        case .brandOnly(let brand): return "brand:\(brand)"
        case .brandAndProduct(let brand, let product): return "brand+product:\(brand)+\(product)"
        case .genericFood(let food): return "generic:\(food)"
        case .productSearch(let query): return "product:\(query)"
        }
    }
}

// MARK: - Fuzzy Matching

struct FuzzyMatcher {

    /// Calculates Levenshtein distance between two strings
    static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1 = Array(s1)
        let s2 = Array(s2)
        let m = s1.count
        let n = s2.count

        // Quick returns for empty strings
        if m == 0 { return n }
        if n == 0 { return m }

        // Create distance matrix
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)

        // Initialize first column
        for i in 0...m { matrix[i][0] = i }
        // Initialize first row
        for j in 0...n { matrix[0][j] = j }

        // Fill in the rest
        for i in 1...m {
            for j in 1...n {
                let cost = s1[i-1] == s2[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,      // deletion
                    matrix[i][j-1] + 1,      // insertion
                    matrix[i-1][j-1] + cost  // substitution
                )
            }
        }

        return matrix[m][n]
    }

    /// Checks if two strings are fuzzy matches (within edit distance threshold)
    static func isFuzzyMatch(_ s1: String, _ s2: String, maxDistance: Int = 2) -> Bool {
        let s1Lower = s1.lowercased()
        let s2Lower = s2.lowercased()

        // Quick length check - if lengths differ too much, can't be close match
        if abs(s1Lower.count - s2Lower.count) > maxDistance {
            return false
        }

        return levenshteinDistance(s1Lower, s2Lower) <= maxDistance
    }

    /// Calculates fuzzy match score (0-100, higher is better match)
    static func fuzzyScore(_ query: String, _ target: String) -> Int {
        let queryLower = query.lowercased()
        let targetLower = target.lowercased()

        // Exact match
        if queryLower == targetLower { return 100 }

        // Calculate distance
        let distance = levenshteinDistance(queryLower, targetLower)
        let maxLen = max(queryLower.count, targetLower.count)

        // Convert distance to score (0-100)
        let score = max(0, 100 - (distance * 100 / maxLen))
        return score
    }

    /// Generate common misspelling variants for a query
    static func generateMisspellingVariants(_ query: String) -> [String] {
        var variants: Set<String> = []
        let chars = Array(query.lowercased())

        // Common letter swaps (single characters only)
        let commonSwaps: [(Character, Character)] = [
            ("a", "e"), ("e", "a"), ("i", "y"), ("y", "i"),
            ("o", "u"), ("u", "o"), ("c", "k"), ("k", "c"),
            ("s", "z"), ("z", "s"),
        ]
        // Note: Multi-character swaps like f/ph handled separately below

        // Adjacent key typos (QWERTY layout)
        let adjacentKeys: [Character: [Character]] = [
            "a": ["s", "q", "z"],
            "b": ["v", "n", "g", "h"],
            "c": ["x", "v", "d", "f"],
            "d": ["s", "f", "e", "r", "c", "x"],
            "e": ["w", "r", "d", "s"],
            "f": ["d", "g", "r", "t", "c", "v"],
            "g": ["f", "h", "t", "y", "v", "b"],
            "h": ["g", "j", "y", "u", "b", "n"],
            "i": ["u", "o", "k", "j"],
            "j": ["h", "k", "u", "i", "n", "m"],
            "k": ["j", "l", "i", "o", "m"],
            "l": ["k", "o", "p"],
            "m": ["n", "j", "k"],
            "n": ["b", "m", "h", "j"],
            "o": ["i", "p", "k", "l"],
            "p": ["o", "l"],
            "q": ["w", "a"],
            "r": ["e", "t", "d", "f"],
            "s": ["a", "d", "w", "e", "x", "z"],
            "t": ["r", "y", "f", "g"],
            "u": ["y", "i", "h", "j"],
            "v": ["c", "b", "f", "g"],
            "w": ["q", "e", "a", "s"],
            "x": ["z", "c", "s", "d"],
            "y": ["t", "u", "g", "h"],
            "z": ["a", "x", "s"],
        ]

        // Generate single-character typo variants (limit to first 3 to avoid explosion)
        for (i, char) in chars.prefix(5).enumerated() {
            if let adjacent = adjacentKeys[char] {
                for adj in adjacent.prefix(2) {
                    var newChars = chars
                    newChars[i] = adj
                    variants.insert(String(newChars))
                }
            }
        }

        // Generate double-letter removal (e.g., "barr" -> "bar")
        for i in 0..<(chars.count - 1) {
            if chars[i] == chars[i + 1] {
                var newChars = chars
                newChars.remove(at: i)
                variants.insert(String(newChars))
            }
        }

        // Add missing double letters (e.g., "bar" -> "barr")
        for (i, char) in chars.enumerated() {
            var newChars = chars
            newChars.insert(char, at: i)
            variants.insert(String(newChars))
        }

        // Handle common endings
        let commonEndings = [
            ("s", ""),     // plural removal
            ("es", ""),    // plural removal
            ("", "s"),     // plural addition
            ("", "es"),    // plural addition
        ]

        for (suffix, replacement) in commonEndings {
            if query.hasSuffix(suffix) && !suffix.isEmpty {
                variants.insert(String(query.dropLast(suffix.count)) + replacement)
            } else if suffix.isEmpty {
                variants.insert(query + replacement)
            }
        }

        // Remove original query from variants
        variants.remove(query.lowercased())

        return Array(variants).prefix(10).map { $0 }
    }
}

// MARK: - Canonical Product Detection

struct CanonicalProductDetector {

    /// Canonical product patterns for common UK brands
    /// These are the "default" products users likely want when searching
    static let canonicalProducts: [String: CanonicalProduct] = [
        // Chocolate bars - single standard bars
        "mars": CanonicalProduct(
            brand: "Mars",
            canonicalName: "Mars Bar",
            canonicalPatterns: ["mars bar", "mars 51g", "mars single"],
            excludePatterns: ["multipack", "pack", "mini", "minis", "ice cream", "drink", "protein", "funsize", "fun size", "bite", "pods", "celebrations"]
        ),
        "snickers": CanonicalProduct(
            brand: "Snickers",
            canonicalName: "Snickers Bar",
            canonicalPatterns: ["snickers bar", "snickers 48g", "snickers single"],
            excludePatterns: ["multipack", "pack", "mini", "minis", "ice cream", "protein", "funsize", "fun size", "bite", "crisp", "duo"]
        ),
        "twix": CanonicalProduct(
            brand: "Twix",
            canonicalName: "Twix",
            canonicalPatterns: ["twix", "twix bar", "twix 50g", "twix single"],
            excludePatterns: ["multipack", "pack", "mini", "minis", "top", "white", "spread", "pods"]
        ),
        "kitkat": CanonicalProduct(
            brand: "KitKat",
            canonicalName: "Kit Kat 4 Finger",
            canonicalPatterns: ["kit kat 4 finger", "kit kat", "kitkat 4 finger", "kit kat 41.5g"],
            excludePatterns: ["multipack", "pack", "chunky", "2 finger", "mini", "minis", "bites"]
        ),
        "dairy milk": CanonicalProduct(
            brand: "Cadbury",
            canonicalName: "Cadbury Dairy Milk",
            canonicalPatterns: ["cadbury dairy milk", "dairy milk", "dairy milk bar"],
            excludePatterns: ["multipack", "pack", "buttons", "giant", "freddo", "caramel", "fruit", "oreo", "winter", "share"]
        ),

        // Crisps - single bags
        "walkers": CanonicalProduct(
            brand: "Walkers",
            canonicalName: "Walkers Ready Salted",
            canonicalPatterns: ["walkers ready salted", "walkers crisps", "walkers 25g", "walkers 32.5g"],
            excludePatterns: ["multipack", "pack", "grab bag", "sharing", "baked", "max", "sensations"]
        ),

        // Drinks - single cans/bottles
        "coke": CanonicalProduct(
            brand: "Coca-Cola",
            canonicalName: "Coca-Cola 330ml Can",
            canonicalPatterns: ["coca-cola 330ml", "coca cola can", "coke can", "coke 330ml"],
            excludePatterns: ["multipack", "pack", "2l", "1.5l", "1l", "bottle", "diet", "zero", "cherry", "vanilla"]
        ),
        "pepsi": CanonicalProduct(
            brand: "Pepsi",
            canonicalName: "Pepsi 330ml Can",
            canonicalPatterns: ["pepsi 330ml", "pepsi can"],
            excludePatterns: ["multipack", "pack", "2l", "1.5l", "1l", "bottle", "max", "diet"]
        ),

        // Condiments
        "heinz ketchup": CanonicalProduct(
            brand: "Heinz",
            canonicalName: "Heinz Tomato Ketchup",
            canonicalPatterns: ["heinz tomato ketchup", "heinz ketchup"],
            excludePatterns: ["reduced", "no added sugar", "organic", "sriracha", "sachet", "portion"]
        ),

        // Beans
        "heinz beans": CanonicalProduct(
            brand: "Heinz",
            canonicalName: "Heinz Baked Beans",
            canonicalPatterns: ["heinz baked beans", "heinz beans"],
            excludePatterns: ["reduced", "no added sugar", "sausages", "toast", "multipacks"]
        ),
    ]

    /// Checks if a product name matches canonical patterns
    static func isCanonicalMatch(productName: String, forQuery query: String) -> Bool {
        let queryLower = query.lowercased()
        let nameLower = productName.lowercased()

        // Find matching canonical product
        for (key, canonical) in canonicalProducts {
            if queryLower.contains(key) || key.contains(queryLower) {
                // Check exclude patterns first
                for excludePattern in canonical.excludePatterns {
                    if nameLower.contains(excludePattern) {
                        return false
                    }
                }

                // Check if name matches canonical patterns
                for pattern in canonical.canonicalPatterns {
                    if nameLower.contains(pattern) || pattern.contains(nameLower) {
                        return true
                    }
                }
            }
        }

        return false
    }

    /// Returns canonical score bonus for a product
    static func canonicalScore(productName: String, forQuery query: String) -> Int {
        let queryLower = query.lowercased()
        let nameLower = productName.lowercased()

        for (key, canonical) in canonicalProducts {
            if queryLower.contains(key) || key.contains(queryLower) {
                // Heavy penalty for exclude patterns
                for excludePattern in canonical.excludePatterns {
                    if nameLower.contains(excludePattern) {
                        return -3000
                    }
                }

                // High bonus for canonical patterns
                for pattern in canonical.canonicalPatterns {
                    if nameLower.hasPrefix(pattern) {
                        return 5000  // Exact canonical prefix = highest
                    }
                    if nameLower.contains(pattern) {
                        return 3000  // Contains canonical pattern
                    }
                }

                // Moderate bonus for simple name matching brand
                if nameLower.hasPrefix(canonical.brand.lowercased()) {
                    return 1500
                }
            }
        }

        return 0
    }
}

// MARK: - Canonical Product Definition

struct CanonicalProduct {
    let brand: String
    let canonicalName: String
    let canonicalPatterns: [String]
    let excludePatterns: [String]
}

// MARK: - Generic Food Defaults (UK)

struct UKFoodDefaults {

    /// Default products for generic food searches in UK context
    /// When user searches "milk", they likely want semi-skimmed
    static let genericDefaults: [String: GenericFoodDefault] = [
        "milk": GenericFoodDefault(
            defaultProduct: "Semi-Skimmed Milk",
            preferencePatterns: ["semi-skimmed", "semi skimmed", "1.7% fat", "1.8% fat"],
            neutralPatterns: ["fresh milk", "whole milk", "skimmed milk"],
            demotePatterns: ["lactose free", "lactose-free", "organic", "filtered", "flavoured", "chocolate", "strawberry", "banana", "oat", "almond", "soy", "soya", "coconut", "long life", "uht", "goat", "jersey"]
        ),
        "bread": GenericFoodDefault(
            defaultProduct: "White Bread",
            preferencePatterns: ["white bread", "medium sliced", "thick sliced", "sliced white"],
            neutralPatterns: ["wholemeal", "whole wheat", "brown bread", "50/50"],
            demotePatterns: ["sourdough", "ciabatta", "baguette", "focaccia", "brioche", "tiger", "rye", "seeded", "gluten free", "bagel", "roll", "bun", "pitta", "naan", "wrap", "crumpet"]
        ),
        "cheese": GenericFoodDefault(
            defaultProduct: "Cheddar Cheese",
            preferencePatterns: ["cheddar", "mild cheddar", "mature cheddar", "cathedral city", "seriously strong"],
            neutralPatterns: ["red leicester", "double gloucester", "edam"],
            demotePatterns: ["cream cheese", "cottage cheese", "feta", "mozzarella", "parmesan", "brie", "camembert", "stilton", "blue cheese", "goat cheese", "vegan", "dairy free"]
        ),
        "butter": GenericFoodDefault(
            defaultProduct: "Salted Butter",
            preferencePatterns: ["salted butter", "british butter", "butter"],
            neutralPatterns: ["unsalted", "spreadable"],
            demotePatterns: ["margarine", "spread", "flora", "lurpak spreadable", "olive spread", "dairy free", "vegan", "i can't believe"]
        ),
        "egg": GenericFoodDefault(
            defaultProduct: "Large Egg",
            preferencePatterns: ["large egg", "free range egg", "hen egg"],
            neutralPatterns: ["medium egg", "egg white", "egg yolk"],
            demotePatterns: ["quail", "duck", "goose", "scotch egg", "egg mayo", "pickled", "fried egg", "scrambled", "poached", "boiled"]
        ),
        "eggs": GenericFoodDefault(
            defaultProduct: "Large Eggs",
            preferencePatterns: ["large eggs", "free range eggs", "hen eggs"],
            neutralPatterns: ["medium eggs", "egg whites"],
            demotePatterns: ["quail", "duck", "goose", "scotch eggs", "pickled"]
        ),
        "chicken": GenericFoodDefault(
            defaultProduct: "Chicken Breast",
            preferencePatterns: ["chicken breast", "skinless chicken", "chicken fillet"],
            neutralPatterns: ["chicken thigh", "chicken leg", "chicken drumstick", "whole chicken"],
            demotePatterns: ["chicken nuggets", "chicken kiev", "chicken pie", "fried chicken", "rotisserie", "breaded", "southern fried", "tikka", "korma", "curry"]
        ),
        "rice": GenericFoodDefault(
            defaultProduct: "White Rice",
            preferencePatterns: ["white rice", "long grain", "basmati", "jasmine"],
            neutralPatterns: ["brown rice", "wholegrain rice"],
            demotePatterns: ["rice pudding", "rice cake", "wild rice", "risotto", "fried rice", "egg fried", "microwave rice", "pilau"]
        ),
        "pasta": GenericFoodDefault(
            defaultProduct: "Spaghetti",
            preferencePatterns: ["spaghetti", "penne", "fusilli", "dried pasta"],
            neutralPatterns: ["tagliatelle", "linguine", "rigatoni", "macaroni"],
            demotePatterns: ["fresh pasta", "stuffed pasta", "ravioli", "tortellini", "lasagne sheets", "pasta bake", "ready meal", "pot noodle"]
        ),
        "yoghurt": GenericFoodDefault(
            defaultProduct: "Natural Yoghurt",
            preferencePatterns: ["natural yoghurt", "greek yoghurt", "plain yoghurt"],
            neutralPatterns: ["greek style", "low fat yoghurt"],
            demotePatterns: ["fruit yoghurt", "strawberry", "raspberry", "muller corner", "activia", "actimel", "yakult", "skyr", "fromage frais", "flavoured"]
        ),
        "yogurt": GenericFoodDefault(  // American spelling redirect
            defaultProduct: "Natural Yoghurt",
            preferencePatterns: ["natural yoghurt", "greek yoghurt", "plain yoghurt"],
            neutralPatterns: ["greek style", "low fat yoghurt"],
            demotePatterns: ["fruit yoghurt", "strawberry", "raspberry", "muller corner", "activia", "flavoured"]
        ),
        "water": GenericFoodDefault(
            defaultProduct: "Still Water",
            preferencePatterns: ["still water", "mineral water", "spring water", "tap water"],
            neutralPatterns: ["sparkling water", "soda water"],
            demotePatterns: ["flavoured water", "vitamin water", "coconut water", "tonic water"]
        ),
        "juice": GenericFoodDefault(
            defaultProduct: "Orange Juice",
            preferencePatterns: ["orange juice", "pure orange juice", "fresh orange juice", "tropicana"],
            neutralPatterns: ["apple juice", "cranberry juice"],
            demotePatterns: ["from concentrate", "juice drink", "squash", "cordial", "smoothie", "fruit shoot"]
        ),
        "coffee": GenericFoodDefault(
            defaultProduct: "Black Coffee",
            preferencePatterns: ["black coffee", "americano", "filter coffee", "instant coffee"],
            neutralPatterns: ["latte", "cappuccino", "flat white"],
            demotePatterns: ["iced coffee", "frappuccino", "mocha", "flavoured coffee", "syrup", "decaf"]
        ),
        "tea": GenericFoodDefault(
            defaultProduct: "Black Tea",
            preferencePatterns: ["black tea", "english breakfast", "tea with milk", "builders tea"],
            neutralPatterns: ["earl grey", "green tea"],
            demotePatterns: ["herbal tea", "fruit tea", "chai", "iced tea", "bubble tea", "matcha"]
        ),
    ]

    /// Returns score modifier for generic food defaults
    static func defaultScore(productName: String, forQuery query: String) -> Int {
        let queryLower = query.lowercased()
        let nameLower = productName.lowercased()

        guard let defaults = genericDefaults[queryLower] else {
            return 0
        }

        // Check demote patterns first (heavy penalty)
        for pattern in defaults.demotePatterns {
            if nameLower.contains(pattern) {
                return -2000
            }
        }

        // Check preference patterns (strong bonus)
        for pattern in defaults.preferencePatterns {
            if nameLower.contains(pattern) {
                return 4000
            }
        }

        // Check neutral patterns (slight bonus)
        for pattern in defaults.neutralPatterns {
            if nameLower.contains(pattern) {
                return 1000
            }
        }

        return 0
    }
}

// MARK: - Generic Food Default Definition

struct GenericFoodDefault {
    let defaultProduct: String
    let preferencePatterns: [String]
    let neutralPatterns: [String]
    let demotePatterns: [String]
}

// MARK: - Search Score Explainer

/// Provides human-readable explanations for why items ranked as they did
struct SearchScoreExplainer {

    /// Generates explanation for a search result's ranking
    static func explain(
        result: (name: String, brand: String?, score: Int),
        query: String
    ) -> String {
        var reasons: [String] = []
        let nameLower = result.name.lowercased()
        let queryLower = query.lowercased()
        let brandLower = result.brand?.lowercased() ?? ""

        // Exact match
        if nameLower == queryLower {
            reasons.append("+10000: Exact name match")
        }

        // Starts with query
        if nameLower.hasPrefix(queryLower) {
            reasons.append("+5000: Name starts with query")
        }

        // Brand match
        if !brandLower.isEmpty && brandLower.contains(queryLower) {
            reasons.append("+2000-8000: Brand match")
        }

        // Canonical product bonus
        let canonical = CanonicalProductDetector.canonicalScore(productName: result.name, forQuery: query)
        if canonical != 0 {
            reasons.append("\(canonical > 0 ? "+" : "")\(canonical): Canonical product \(canonical > 0 ? "match" : "exclusion")")
        }

        // Generic default bonus
        let defaultScore = UKFoodDefaults.defaultScore(productName: result.name, forQuery: query)
        if defaultScore != 0 {
            reasons.append("\(defaultScore > 0 ? "+" : "")\(defaultScore): UK default preference")
        }

        // Multipack penalty
        if nameLower.contains("multipack") || nameLower.contains("pack") {
            reasons.append("-2500: Multipack penalty")
        }

        // Single-serve bonus
        if nameLower.contains("330ml") || nameLower.contains("can") || nameLower.contains("bar") {
            reasons.append("+1200: Single-serve bonus")
        }

        return """
        Score: \(result.score)
        Reasons:
        \(reasons.map { "  • \($0)" }.joined(separator: "\n"))
        """
    }
}
