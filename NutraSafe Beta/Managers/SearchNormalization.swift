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
            "warburtons", "hovis", "kingsmill", "mcvities", "birdseye", "quorn",
            "greggs", "subway", "nandos", "costa", "starbucks", "burger king"
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

        // HOLISTIC APPROACH: Treat ALL single-word queries as potential generic food searches
        // UNLESS they're a known brand or look like a product code
        // The ranking logic will handle demoting composite/prepared foods
        if words.count == 1 {
            let word = words[0]
            // Must be at least 3 chars, not all digits, not a known brand
            if word.count >= 3 && !word.allSatisfy({ $0.isNumber }) && !knownBrands.contains(word) {
                return .genericFood(word)
            }
        }

        // Default: product search
        return .productSearch(query)
    }
}

// MARK: - Prepared Food Detection (Holistic)

/// Universal detection of prepared/composite foods vs raw ingredients
/// This works for ANY food, not just items in a hardcoded list
struct PreparedFoodDetector {

    /// Suffixes that indicate a prepared/composite food product
    /// If a product name ENDS with these, it's likely prepared food
    /// e.g., "Steak Bake", "Banana Bread", "Chicken Curry"
    static let preparedFoodSuffixes: Set<String> = [
        // Baked goods
        "bake", "pie", "pies", "tart", "tarts", "cake", "cakes", "bread", "loaf",
        "muffin", "muffins", "scone", "scones", "croissant", "pastry", "pasty",
        "roll", "rolls", "bun", "buns", "wrap", "wraps", "bagel", "bagels",
        "crumble", "pudding", "strudel", "turnover", "flapjack", "brownie",

        // Sandwiches & meals
        "sandwich", "sandwiches", "burger", "burgers", "sub", "panini",
        "toastie", "kebab", "kebabs", "hotdog", "burrito", "taco", "tacos",

        // Prepared dishes
        "curry", "curries", "stew", "stews", "soup", "soups", "casserole",
        "lasagne", "lasagna", "risotto", "paella", "biryani", "korma", "masala",
        "tikka", "vindaloo", "madras", "balti", "jalfrezi", "bhuna", "dopiaza",

        // Processed snacks
        "bar", "bars", "crisp", "crisps", "chip", "chips", "nugget", "nuggets",
        "finger", "fingers", "bite", "bites", "pop", "pops", "ball", "balls",
        "stick", "sticks", "ring", "rings", "puff", "puffs", "cracker", "crackers",

        // Dairy products (prepared)
        "shake", "shakes", "milkshake", "smoothie", "smoothies", "yoghurt", "yogurt",
        "icecream", "ice cream", "mousse", "custard", "parfait",

        // Preserves & sauces
        "jam", "jelly", "marmalade", "chutney", "sauce", "sauces", "dip", "dips",
        "spread", "paste", "puree", "ketchup", "mayo", "mayonnaise", "relish",

        // Other prepared foods
        "salad", "salads", "slaw", "coleslaw", "hummus", "guacamole", "salsa",
        "quiche", "frittata", "omelette", "omelet", "scramble",
        "kiev", "kievs", "schnitzel", "goujons", "escalope",

        // Drinks
        "juice", "juices", "squash", "cordial", "lemonade", "cola", "soda",
        "drink", "drinks", "cocktail", "smoothie"
    ]

    /// Words that indicate the query itself is for a prepared food (user wants it)
    static let preparedFoodQueryIndicators: Set<String> = [
        "bake", "pie", "cake", "bread", "muffin", "wrap", "sandwich", "burger",
        "curry", "soup", "stew", "bar", "chips", "crisps", "nuggets", "fingers",
        "shake", "smoothie", "juice", "salad", "jam", "sauce"
    ]

    /// Check if a product name indicates a prepared/composite food
    /// Returns true if the product is likely a prepared food containing an ingredient
    static func isPreparedFood(_ productName: String) -> Bool {
        let nameLower = productName.lowercased()
        let words = nameLower.split(separator: " ").map(String.init)

        guard words.count >= 2 else { return false }

        // Check if name ends with a prepared food suffix
        if let lastWord = words.last, preparedFoodSuffixes.contains(lastWord) {
            return true
        }

        // Check second-to-last word for compound endings like "ice cream"
        if words.count >= 2 {
            let lastTwo = words.suffix(2).joined(separator: " ")
            if preparedFoodSuffixes.contains(lastTwo) {
                return true
            }
        }

        return false
    }

    /// Check if the user's query indicates they WANT a prepared food
    static func queryWantsPreparedFood(_ query: String) -> Bool {
        let queryWords = Set(query.lowercased().split(separator: " ").map(String.init))
        return !queryWords.isDisjoint(with: preparedFoodQueryIndicators)
    }

    /// Calculate penalty score for prepared foods when user searched for raw ingredient
    /// Returns negative score (penalty) if product is prepared but query was for raw
    static func preparedFoodPenalty(productName: String, query: String) -> Int {
        let queryWords = query.lowercased().split(separator: " ").map(String.init)

        // Only apply for single-word queries (likely raw ingredient searches)
        guard queryWords.count == 1 else { return 0 }

        // If user explicitly wants prepared food, no penalty
        if queryWantsPreparedFood(query) { return 0 }

        // If product is a prepared food, apply penalty
        if isPreparedFood(productName) {
            return -8000  // Heavy penalty - user searched "steak", got "steak bake"
        }

        return 0
    }

    /// Check if query word is in "modifier position" (first word of multi-word product)
    /// e.g., "steak" in "Steak Bake" is a modifier; "steak" in "Beef Steak" is the head noun
    static func isModifierPosition(query: String, productName: String) -> Bool {
        let queryLower = query.lowercased()
        let nameWords = productName.lowercased().split(separator: " ").map(String.init)

        guard nameWords.count >= 2 else { return false }

        // Query word is first AND there's a prepared food suffix at end
        if nameWords.first == queryLower || nameWords.first?.hasPrefix(queryLower) == true {
            if let lastWord = nameWords.last, preparedFoodSuffixes.contains(lastWord) {
                return true  // "Steak" in "Steak Bake" - modifier position
            }
        }

        return false
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

        // MARK: - Fruits (Base/Raw Foods)
        "banana": GenericFoodDefault(
            defaultProduct: "Banana",
            preferencePatterns: ["banana raw", "banana fresh", "banana medium", "banana large", "banana small", "banana ripe"],
            neutralPatterns: ["banana", "bananas"],
            demotePatterns: ["banana bread", "banana chip", "banana chips", "banana cake", "banana muffin", "banana smoothie", "banana milkshake", "banana ice cream", "banana pudding", "banana split", "banana bar", "banana bars", "banana flavour", "banana flavor", "dried banana", "banana loaf", "banana pancake", "freeze dried", "getbuzzing", "creative nature", "oatsnack", "bon appetit", "h&b", "shallot", "shrimps", "& shrimps", "protein", "whey", "daifuku", "core power", "power"]
        ),
        "apple": GenericFoodDefault(
            defaultProduct: "Apple",
            preferencePatterns: ["apple raw", "apple fresh", "apple medium", "apple large", "gala apple", "braeburn apple", "granny smith", "pink lady", "royal gala", "cox apple", "fuji apple"],
            neutralPatterns: ["apple", "apples"],
            demotePatterns: ["apple pie", "apple crumble", "apple juice", "apple sauce", "apple cider", "apple turnover", "apple strudel", "toffee apple", "apple cake", "dried apple", "apple flavour", "apple flavor", "apple chips"]
        ),
        "orange": GenericFoodDefault(
            defaultProduct: "Orange",
            preferencePatterns: ["orange raw", "orange fresh", "orange medium", "orange large", "navel orange", "blood orange", "satsuma", "clementine", "tangerine", "mandarin"],
            neutralPatterns: ["orange", "oranges"],
            demotePatterns: ["orange juice", "orange squash", "orange marmalade", "orange cake", "orange chocolate", "orange flavour", "orange flavor", "terry's chocolate orange", "jaffa"]
        ),
        "grape": GenericFoodDefault(
            defaultProduct: "Grapes",
            preferencePatterns: ["grape raw", "grapes raw", "grape fresh", "grapes fresh", "red grapes", "green grapes", "black grapes", "seedless grapes"],
            neutralPatterns: ["grape", "grapes"],
            demotePatterns: ["grape juice", "grape flavour", "grape flavor", "raisin", "sultana", "wine", "grape jelly"]
        ),
        "grapes": GenericFoodDefault(
            defaultProduct: "Grapes",
            preferencePatterns: ["grapes raw", "grapes fresh", "red grapes", "green grapes", "black grapes", "seedless grapes"],
            neutralPatterns: ["grapes"],
            demotePatterns: ["grape juice", "grape flavour", "raisin", "sultana", "wine"]
        ),
        "strawberry": GenericFoodDefault(
            defaultProduct: "Strawberries",
            preferencePatterns: ["strawberry raw", "strawberries raw", "strawberry fresh", "strawberries fresh"],
            neutralPatterns: ["strawberry", "strawberries"],
            demotePatterns: ["strawberry jam", "strawberry yoghurt", "strawberry ice cream", "strawberry cake", "strawberry milkshake", "strawberry flavour", "strawberry flavor", "dried strawberry", "freeze dried"]
        ),
        "strawberries": GenericFoodDefault(
            defaultProduct: "Strawberries",
            preferencePatterns: ["strawberries raw", "strawberries fresh"],
            neutralPatterns: ["strawberries"],
            demotePatterns: ["strawberry jam", "strawberry yoghurt", "strawberry ice cream", "strawberry cake", "dried strawberry", "freeze dried"]
        ),
        "blueberry": GenericFoodDefault(
            defaultProduct: "Blueberries",
            preferencePatterns: ["blueberry raw", "blueberries raw", "blueberry fresh", "blueberries fresh"],
            neutralPatterns: ["blueberry", "blueberries"],
            demotePatterns: ["blueberry muffin", "blueberry pancake", "blueberry jam", "blueberry pie", "dried blueberry", "blueberry flavour"]
        ),
        "blueberries": GenericFoodDefault(
            defaultProduct: "Blueberries",
            preferencePatterns: ["blueberries raw", "blueberries fresh"],
            neutralPatterns: ["blueberries"],
            demotePatterns: ["blueberry muffin", "blueberry pancake", "dried blueberry"]
        ),
        "raspberry": GenericFoodDefault(
            defaultProduct: "Raspberries",
            preferencePatterns: ["raspberry raw", "raspberries raw", "raspberry fresh", "raspberries fresh"],
            neutralPatterns: ["raspberry", "raspberries"],
            demotePatterns: ["raspberry jam", "raspberry ripple", "raspberry flavour", "dried raspberry"]
        ),
        "raspberries": GenericFoodDefault(
            defaultProduct: "Raspberries",
            preferencePatterns: ["raspberries raw", "raspberries fresh"],
            neutralPatterns: ["raspberries"],
            demotePatterns: ["raspberry jam", "raspberry ripple", "dried raspberry"]
        ),
        "mango": GenericFoodDefault(
            defaultProduct: "Mango",
            preferencePatterns: ["mango raw", "mango fresh", "mango ripe"],
            neutralPatterns: ["mango", "mangoes"],
            demotePatterns: ["mango juice", "mango chutney", "dried mango", "mango lassi", "mango sorbet", "mango flavour"]
        ),
        "pear": GenericFoodDefault(
            defaultProduct: "Pear",
            preferencePatterns: ["pear raw", "pear fresh", "conference pear", "williams pear", "comice pear"],
            neutralPatterns: ["pear", "pears"],
            demotePatterns: ["pear cider", "pear drops", "tinned pear", "canned pear", "pear in syrup"]
        ),
        "peach": GenericFoodDefault(
            defaultProduct: "Peach",
            preferencePatterns: ["peach raw", "peach fresh", "peach ripe"],
            neutralPatterns: ["peach", "peaches"],
            demotePatterns: ["peach melba", "tinned peach", "canned peach", "peach in syrup", "peach flavour", "peach schnapps"]
        ),
        "plum": GenericFoodDefault(
            defaultProduct: "Plum",
            preferencePatterns: ["plum raw", "plum fresh", "plum ripe", "victoria plum"],
            neutralPatterns: ["plum", "plums"],
            demotePatterns: ["plum jam", "plum pudding", "dried plum", "prune", "plum sauce"]
        ),
        "melon": GenericFoodDefault(
            defaultProduct: "Melon",
            preferencePatterns: ["melon raw", "melon fresh", "honeydew melon", "cantaloupe", "galia melon", "watermelon"],
            neutralPatterns: ["melon"],
            demotePatterns: ["melon flavour", "melon juice"]
        ),
        "watermelon": GenericFoodDefault(
            defaultProduct: "Watermelon",
            preferencePatterns: ["watermelon raw", "watermelon fresh"],
            neutralPatterns: ["watermelon"],
            demotePatterns: ["watermelon flavour", "watermelon juice", "watermelon candy"]
        ),
        "pineapple": GenericFoodDefault(
            defaultProduct: "Pineapple",
            preferencePatterns: ["pineapple raw", "pineapple fresh"],
            neutralPatterns: ["pineapple"],
            demotePatterns: ["tinned pineapple", "canned pineapple", "pineapple juice", "pineapple rings", "dried pineapple", "pina colada"]
        ),
        "kiwi": GenericFoodDefault(
            defaultProduct: "Kiwi Fruit",
            preferencePatterns: ["kiwi raw", "kiwi fresh", "kiwi fruit", "kiwifruit"],
            neutralPatterns: ["kiwi"],
            demotePatterns: ["kiwi juice", "dried kiwi"]
        ),
        "lemon": GenericFoodDefault(
            defaultProduct: "Lemon",
            preferencePatterns: ["lemon raw", "lemon fresh", "lemon whole"],
            neutralPatterns: ["lemon"],
            demotePatterns: ["lemon juice", "lemon curd", "lemon cake", "lemon drizzle", "lemon meringue", "lemon squash", "lemonade"]
        ),
        "lime": GenericFoodDefault(
            defaultProduct: "Lime",
            preferencePatterns: ["lime raw", "lime fresh", "lime whole"],
            neutralPatterns: ["lime"],
            demotePatterns: ["lime juice", "lime cordial", "lime flavour"]
        ),
        "cherry": GenericFoodDefault(
            defaultProduct: "Cherries",
            preferencePatterns: ["cherry raw", "cherries raw", "cherry fresh", "cherries fresh"],
            neutralPatterns: ["cherry", "cherries"],
            demotePatterns: ["cherry pie", "cherry jam", "glacé cherry", "maraschino", "cherry flavour", "cherry coke", "dried cherry"]
        ),
        "cherries": GenericFoodDefault(
            defaultProduct: "Cherries",
            preferencePatterns: ["cherries raw", "cherries fresh"],
            neutralPatterns: ["cherries"],
            demotePatterns: ["cherry pie", "glacé cherry", "dried cherry"]
        ),
        "avocado": GenericFoodDefault(
            defaultProduct: "Avocado",
            preferencePatterns: ["avocado raw", "avocado fresh", "avocado ripe", "hass avocado"],
            neutralPatterns: ["avocado"],
            demotePatterns: ["avocado toast", "guacamole", "avocado oil", "avocado dip"]
        ),

        // MARK: - Vegetables (Base/Raw Foods)
        "tomato": GenericFoodDefault(
            defaultProduct: "Tomato",
            preferencePatterns: ["tomato raw", "tomato fresh", "tomato medium", "vine tomato", "cherry tomato", "plum tomato", "beef tomato"],
            neutralPatterns: ["tomato", "tomatoes"],
            demotePatterns: ["tomato sauce", "tomato ketchup", "tomato soup", "tinned tomato", "canned tomato", "chopped tomato", "tomato puree", "tomato paste", "sun dried", "sundried"]
        ),
        "potato": GenericFoodDefault(
            defaultProduct: "Potato",
            preferencePatterns: ["potato raw", "potato fresh", "potato medium", "potato large", "baking potato", "new potato", "maris piper", "king edward"],
            neutralPatterns: ["potato", "potatoes"],
            demotePatterns: ["potato chips", "potato crisps", "chips", "french fries", "mashed potato", "roast potato", "jacket potato", "potato salad", "potato waffle", "hash brown", "wedges"]
        ),
        "potatoes": GenericFoodDefault(
            defaultProduct: "Potatoes",
            preferencePatterns: ["potatoes raw", "potatoes fresh", "new potatoes", "baby potatoes"],
            neutralPatterns: ["potatoes"],
            demotePatterns: ["chips", "crisps", "mashed", "roast potatoes", "potato salad"]
        ),
        "onion": GenericFoodDefault(
            defaultProduct: "Onion",
            preferencePatterns: ["onion raw", "onion fresh", "onion medium", "brown onion", "white onion", "red onion", "spring onion"],
            neutralPatterns: ["onion", "onions"],
            demotePatterns: ["onion rings", "fried onion", "crispy onion", "onion bhaji", "pickled onion", "onion gravy", "french onion"]
        ),
        "carrot": GenericFoodDefault(
            defaultProduct: "Carrot",
            preferencePatterns: ["carrot raw", "carrot fresh", "carrot medium", "baby carrot", "carrot stick"],
            neutralPatterns: ["carrot", "carrots"],
            demotePatterns: ["carrot cake", "carrot juice", "carrot and coriander", "glazed carrot"]
        ),
        "broccoli": GenericFoodDefault(
            defaultProduct: "Broccoli",
            preferencePatterns: ["broccoli raw", "broccoli fresh", "broccoli floret"],
            neutralPatterns: ["broccoli"],
            demotePatterns: ["broccoli cheese", "broccoli soup", "tenderstem"]
        ),
        "spinach": GenericFoodDefault(
            defaultProduct: "Spinach",
            preferencePatterns: ["spinach raw", "spinach fresh", "baby spinach", "spinach leaves"],
            neutralPatterns: ["spinach"],
            demotePatterns: ["creamed spinach", "spinach and ricotta", "spinach pasta", "frozen spinach"]
        ),
        "lettuce": GenericFoodDefault(
            defaultProduct: "Lettuce",
            preferencePatterns: ["lettuce raw", "lettuce fresh", "iceberg lettuce", "romaine lettuce", "cos lettuce", "little gem"],
            neutralPatterns: ["lettuce"],
            demotePatterns: ["lettuce wrap"]
        ),
        "cucumber": GenericFoodDefault(
            defaultProduct: "Cucumber",
            preferencePatterns: ["cucumber raw", "cucumber fresh", "cucumber whole"],
            neutralPatterns: ["cucumber"],
            demotePatterns: ["pickled cucumber", "cucumber sandwich", "tzatziki"]
        ),
        "pepper": GenericFoodDefault(
            defaultProduct: "Bell Pepper",
            preferencePatterns: ["pepper raw", "bell pepper", "red pepper", "green pepper", "yellow pepper", "sweet pepper"],
            neutralPatterns: ["pepper", "peppers"],
            demotePatterns: ["black pepper", "pepper sauce", "stuffed pepper", "roasted pepper", "jalapeño", "chilli"]
        ),
        "mushroom": GenericFoodDefault(
            defaultProduct: "Mushrooms",
            preferencePatterns: ["mushroom raw", "mushrooms raw", "mushroom fresh", "button mushroom", "chestnut mushroom", "portobello"],
            neutralPatterns: ["mushroom", "mushrooms"],
            demotePatterns: ["mushroom soup", "garlic mushroom", "stuffed mushroom", "mushroom sauce", "dried mushroom"]
        ),
        "mushrooms": GenericFoodDefault(
            defaultProduct: "Mushrooms",
            preferencePatterns: ["mushrooms raw", "mushrooms fresh", "button mushrooms", "chestnut mushrooms"],
            neutralPatterns: ["mushrooms"],
            demotePatterns: ["mushroom soup", "garlic mushrooms", "stuffed mushrooms"]
        ),
        "sweetcorn": GenericFoodDefault(
            defaultProduct: "Sweetcorn",
            preferencePatterns: ["sweetcorn raw", "sweetcorn fresh", "corn on the cob"],
            neutralPatterns: ["sweetcorn", "corn"],
            demotePatterns: ["tinned sweetcorn", "canned sweetcorn", "baby corn", "popcorn", "cornflakes"]
        ),
        "corn": GenericFoodDefault(
            defaultProduct: "Sweetcorn",
            preferencePatterns: ["corn raw", "corn fresh", "corn on the cob", "sweetcorn"],
            neutralPatterns: ["corn"],
            demotePatterns: ["corn chips", "corn flakes", "popcorn", "cornmeal", "corn syrup", "baby corn"]
        ),
        "courgette": GenericFoodDefault(
            defaultProduct: "Courgette",
            preferencePatterns: ["courgette raw", "courgette fresh", "zucchini"],
            neutralPatterns: ["courgette", "courgettes"],
            demotePatterns: ["courgette pasta", "courgette fries", "spiralized"]
        ),
        "aubergine": GenericFoodDefault(
            defaultProduct: "Aubergine",
            preferencePatterns: ["aubergine raw", "aubergine fresh", "eggplant"],
            neutralPatterns: ["aubergine"],
            demotePatterns: ["aubergine parmigiana", "baba ganoush", "moussaka"]
        ),
        "cabbage": GenericFoodDefault(
            defaultProduct: "Cabbage",
            preferencePatterns: ["cabbage raw", "cabbage fresh", "white cabbage", "red cabbage", "savoy cabbage"],
            neutralPatterns: ["cabbage"],
            demotePatterns: ["coleslaw", "sauerkraut", "bubble and squeak"]
        ),
        "cauliflower": GenericFoodDefault(
            defaultProduct: "Cauliflower",
            preferencePatterns: ["cauliflower raw", "cauliflower fresh", "cauliflower floret"],
            neutralPatterns: ["cauliflower"],
            demotePatterns: ["cauliflower cheese", "cauliflower rice", "cauliflower pizza"]
        ),
        "celery": GenericFoodDefault(
            defaultProduct: "Celery",
            preferencePatterns: ["celery raw", "celery fresh", "celery stick", "celery stalk"],
            neutralPatterns: ["celery"],
            demotePatterns: ["celery soup", "celery salt"]
        ),
        "asparagus": GenericFoodDefault(
            defaultProduct: "Asparagus",
            preferencePatterns: ["asparagus raw", "asparagus fresh", "asparagus spear"],
            neutralPatterns: ["asparagus"],
            demotePatterns: ["asparagus soup", "tinned asparagus"]
        ),
        "beetroot": GenericFoodDefault(
            defaultProduct: "Beetroot",
            preferencePatterns: ["beetroot raw", "beetroot fresh"],
            neutralPatterns: ["beetroot"],
            demotePatterns: ["pickled beetroot", "beetroot juice", "beetroot hummus"]
        ),
        "leek": GenericFoodDefault(
            defaultProduct: "Leek",
            preferencePatterns: ["leek raw", "leek fresh"],
            neutralPatterns: ["leek", "leeks"],
            demotePatterns: ["leek and potato soup", "leek pie"]
        ),
        "parsnip": GenericFoodDefault(
            defaultProduct: "Parsnip",
            preferencePatterns: ["parsnip raw", "parsnip fresh"],
            neutralPatterns: ["parsnip", "parsnips"],
            demotePatterns: ["roast parsnip", "parsnip soup", "parsnip chips"]
        ),
        "swede": GenericFoodDefault(
            defaultProduct: "Swede",
            preferencePatterns: ["swede raw", "swede fresh", "rutabaga"],
            neutralPatterns: ["swede"],
            demotePatterns: ["mashed swede"]
        ),
        "turnip": GenericFoodDefault(
            defaultProduct: "Turnip",
            preferencePatterns: ["turnip raw", "turnip fresh"],
            neutralPatterns: ["turnip", "turnips"],
            demotePatterns: ["mashed turnip", "turnip soup"]
        ),

        // MARK: - Proteins (Base/Raw Foods)
        "beef": GenericFoodDefault(
            defaultProduct: "Beef",
            preferencePatterns: ["beef raw", "beef fresh", "beef mince", "minced beef", "beef steak", "stewing beef"],
            neutralPatterns: ["beef"],
            demotePatterns: ["beef burger", "roast beef", "corned beef", "beef pie", "beef stew", "beef curry", "beef jerky"]
        ),
        "pork": GenericFoodDefault(
            defaultProduct: "Pork",
            preferencePatterns: ["pork raw", "pork fresh", "pork chop", "pork loin", "pork mince"],
            neutralPatterns: ["pork"],
            demotePatterns: ["pork pie", "pulled pork", "pork belly", "pork scratchings", "gammon", "bacon", "ham", "sausage"]
        ),
        "lamb": GenericFoodDefault(
            defaultProduct: "Lamb",
            preferencePatterns: ["lamb raw", "lamb fresh", "lamb chop", "lamb leg", "lamb mince", "minced lamb"],
            neutralPatterns: ["lamb"],
            demotePatterns: ["lamb curry", "lamb kebab", "roast lamb", "lamb shank", "lamb stew"]
        ),
        "fish": GenericFoodDefault(
            defaultProduct: "Fish",
            preferencePatterns: ["fish raw", "fish fresh", "white fish", "cod", "haddock", "salmon", "sea bass"],
            neutralPatterns: ["fish"],
            demotePatterns: ["fish fingers", "fish and chips", "fish pie", "fish cake", "battered fish", "breaded fish", "smoked fish", "fish paste"]
        ),
        "salmon": GenericFoodDefault(
            defaultProduct: "Salmon",
            preferencePatterns: ["salmon raw", "salmon fresh", "salmon fillet"],
            neutralPatterns: ["salmon"],
            demotePatterns: ["smoked salmon", "salmon teriyaki", "salmon en croute", "tinned salmon", "salmon sushi"]
        ),
        "tuna": GenericFoodDefault(
            defaultProduct: "Tuna",
            preferencePatterns: ["tuna raw", "tuna fresh", "tuna steak"],
            neutralPatterns: ["tuna"],
            demotePatterns: ["tinned tuna", "canned tuna", "tuna mayo", "tuna sandwich", "tuna pasta", "tuna melt"]
        ),
        "prawns": GenericFoodDefault(
            defaultProduct: "Prawns",
            preferencePatterns: ["prawns raw", "prawns fresh", "king prawns", "tiger prawns"],
            neutralPatterns: ["prawns", "shrimp"],
            demotePatterns: ["prawn cocktail", "prawn crackers", "prawn toast", "tempura prawns"]
        ),
        "turkey": GenericFoodDefault(
            defaultProduct: "Turkey",
            preferencePatterns: ["turkey raw", "turkey fresh", "turkey breast", "turkey mince"],
            neutralPatterns: ["turkey"],
            demotePatterns: ["turkey sandwich", "roast turkey", "turkey dinosaurs", "turkey twizzlers", "turkey bacon"]
        ),

        // MARK: - Specific Cuts (Raw Meat)
        "steak": GenericFoodDefault(
            defaultProduct: "Beef Steak",
            preferencePatterns: ["beef steak", "sirloin steak", "ribeye steak", "rump steak", "fillet steak",
                               "steak raw", "steak fresh", "stewing steak", "braising steak", "frying steak",
                               "minute steak", "flash fry steak", "grilling steak"],
            neutralPatterns: ["steak"],
            demotePatterns: ["steak bake", "steak pie", "steak slice", "steak pasty", "steak sandwich",
                           "steak and kidney", "steak burger", "steak wrap", "steak sub", "steak roll",
                           "philly steak", "cheese steak", "cheesesteak", "steak pudding", "steak house",
                           "greggs", "ginsters", "pukka", "fray bentos", "hollands"]
        ),
        "mince": GenericFoodDefault(
            defaultProduct: "Beef Mince",
            preferencePatterns: ["beef mince", "minced beef", "lean mince", "extra lean mince", "5% fat mince",
                               "mince fresh", "mince raw", "steak mince"],
            neutralPatterns: ["mince", "minced"],
            demotePatterns: ["mince pie", "mincemeat", "mince and onion", "shepherds pie", "cottage pie",
                           "bolognese", "lasagne", "chilli con carne", "meatballs", "burger"]
        ),
        "bacon": GenericFoodDefault(
            defaultProduct: "Back Bacon",
            preferencePatterns: ["back bacon", "streaky bacon", "smoked bacon", "unsmoked bacon", "bacon rashers",
                               "bacon raw", "bacon fresh", "dry cured bacon", "bacon medallions"],
            neutralPatterns: ["bacon"],
            demotePatterns: ["bacon sandwich", "bacon roll", "bacon bap", "bacon butty", "bacon and eggs",
                           "bacon bits", "bacon flavour", "turkey bacon", "bacon jam", "bacon wrap"]
        ),
        "sausage": GenericFoodDefault(
            defaultProduct: "Pork Sausage",
            preferencePatterns: ["pork sausage", "sausage raw", "sausage fresh", "cumberland sausage",
                               "lincolnshire sausage", "chipolata", "breakfast sausage", "thick sausage"],
            neutralPatterns: ["sausage", "sausages"],
            demotePatterns: ["sausage roll", "sausage sandwich", "sausage bap", "sausage casserole",
                           "sausage and mash", "toad in the hole", "hot dog", "frankfurt", "bratwurst",
                           "sausage meat", "sausage stuffing"]
        ),
        "ham": GenericFoodDefault(
            defaultProduct: "Cooked Ham",
            preferencePatterns: ["ham sliced", "cooked ham", "honey roast ham", "smoked ham", "gammon",
                               "ham fresh", "ham joint", "parma ham", "serrano ham"],
            neutralPatterns: ["ham"],
            demotePatterns: ["ham sandwich", "ham and cheese", "ham roll", "ham salad", "ham hock",
                           "ham and pineapple", "ham pizza", "ham croquette", "spam"]
        ),

        // MARK: - Nuts & Seeds (Base/Raw Foods)
        "almonds": GenericFoodDefault(
            defaultProduct: "Almonds",
            preferencePatterns: ["almonds raw", "almonds whole", "almonds natural", "almond whole"],
            neutralPatterns: ["almonds", "almond"],
            demotePatterns: ["almond milk", "almond butter", "roasted almonds", "salted almonds", "chocolate almonds", "almond flour"]
        ),
        "walnuts": GenericFoodDefault(
            defaultProduct: "Walnuts",
            preferencePatterns: ["walnuts raw", "walnuts whole", "walnut halves"],
            neutralPatterns: ["walnuts", "walnut"],
            demotePatterns: ["walnut cake", "candied walnuts", "pickled walnuts"]
        ),
        "cashews": GenericFoodDefault(
            defaultProduct: "Cashews",
            preferencePatterns: ["cashews raw", "cashews whole", "cashew nuts"],
            neutralPatterns: ["cashews", "cashew"],
            demotePatterns: ["cashew butter", "roasted cashews", "salted cashews", "honey cashews"]
        ),
        "peanuts": GenericFoodDefault(
            defaultProduct: "Peanuts",
            preferencePatterns: ["peanuts raw", "peanuts whole", "monkey nuts"],
            neutralPatterns: ["peanuts", "peanut"],
            demotePatterns: ["peanut butter", "roasted peanuts", "salted peanuts", "honey roasted", "dry roasted"]
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
