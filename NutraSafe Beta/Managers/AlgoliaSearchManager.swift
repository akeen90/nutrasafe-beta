//
//  AlgoliaSearchManager.swift
//  NutraSafe Beta
//
//  Direct Algolia REST API integration for instant search
//  Uses URLSession instead of SDK for reliability and ~300ms faster than Cloud Functions
//

import Foundation

// MARK: - Brand Synonym Groups & Fast Food Detection

/// Groups of brand synonyms - first item is the canonical name
/// When searching for any synonym, results for all synonyms in the group are returned
/// NOTE: This is for SEARCH functionality only - not all brands here hide the NutraSafe grade
// MARK: - UK Common Food Search Expansions
// When users search for these common terms, expand to include the typical UK interpretation

/// Maps common UK search terms to their typical meanings
/// e.g., "beans" in UK typically means "baked beans", not raw kidney beans
let ukCommonFoodExpansions: [String: [String]] = [
    // Everyday UK staples
    "beans": ["baked beans", "heinz beans", "beans in tomato sauce"],
    "toast": ["toast white", "toast wholemeal", "buttered toast"],
    "porridge": ["porridge oats", "oats porridge", "ready brek"],
    "crumpet": ["crumpet", "warburtons crumpet"],
    "crumpets": ["crumpets", "warburtons crumpets"],
    "muffin": ["english muffin", "warburtons muffin"],  // UK muffin ≠ American muffin

    // Common drinks - single cans/bottles
    "coke": ["coca-cola", "coca cola can", "coke 330ml"],
    "pepsi": ["pepsi", "pepsi can", "pepsi 330ml"],
    "fanta": ["fanta", "fanta can", "fanta orange"],
    "sprite": ["sprite", "sprite can", "sprite 330ml"],
    "lucozade": ["lucozade", "lucozade original", "lucozade energy"],
    "irn bru": ["irn-bru", "irn bru", "irn bru can"],
    "red bull": ["red bull", "red bull can", "red bull 250ml"],
    "monster": ["monster energy", "monster can"],
    "coffee": ["coffee black", "coffee with milk", "latte", "cappuccino"],
    "tea": ["tea with milk", "tea black", "cup of tea"],

    // Chocolate bars - single bars not multipacks
    "mars": ["mars bar", "mars"],
    "snickers": ["snickers", "snickers bar"],
    "twix": ["twix", "twix bar"],
    "kitkat": ["kit kat", "kitkat", "kit kat 4 finger"],
    "dairy milk": ["cadbury dairy milk", "dairy milk"],
    "galaxy": ["galaxy chocolate", "galaxy bar"],
    "maltesers": ["maltesers", "maltesers bag"],
    "aero": ["aero", "aero mint", "aero bar"],
    "crunchie": ["crunchie", "crunchie bar"],
    "yorkie": ["yorkie", "yorkie bar"],
    "bounty": ["bounty", "bounty bar"],
    "milky way": ["milky way", "milky way bar"],
    "wispa": ["wispa", "wispa bar"],
    "double decker": ["double decker", "double decker bar"],
    "boost": ["boost", "boost bar", "cadbury boost"],
    "picnic": ["picnic", "picnic bar"],
    "fudge": ["fudge bar", "cadbury fudge"],
    "curly wurly": ["curly wurly"],
    "freddo": ["freddo", "cadbury freddo"],
    "kinder bueno": ["kinder bueno", "bueno"],
    "ferrero rocher": ["ferrero rocher"],
    "lindt": ["lindt", "lindt lindor"],
    "toblerone": ["toblerone"],

    // Crisps - single bags
    "crisps": ["crisps", "walkers crisps", "ready salted crisps"],
    "walkers": ["walkers crisps", "walkers"],
    "pringles": ["pringles", "pringles original"],
    "doritos": ["doritos", "doritos cool original"],
    "quavers": ["quavers"],
    "wotsits": ["wotsits"],
    "hula hoops": ["hula hoops"],
    "monster munch": ["monster munch"],
    "skips": ["skips"],
    "frazzles": ["frazzles"],
    "squares": ["walkers squares"],
    "sensations": ["sensations crisps", "walkers sensations"],
    "kettle chips": ["kettle chips"],
    "mccoys": ["mccoys", "mccoy's"],

    // Biscuits
    "biscuit": ["biscuit", "digestive", "rich tea"],
    "digestive": ["digestive", "mcvities digestive"],
    "hobnob": ["hobnob", "hobnobs", "mcvities hobnob"],
    "bourbon": ["bourbon biscuit", "bourbon"],
    "custard cream": ["custard cream", "custard creams"],
    "rich tea": ["rich tea", "rich tea biscuit"],
    "jaffa cake": ["jaffa cake", "jaffa cakes", "mcvities jaffa"],
    "oreo": ["oreo", "oreo biscuit"],
    "shortbread": ["shortbread", "shortbread finger"],

    // UK composite meals
    "beans on toast": ["baked beans", "beans on toast"],
    "cheese on toast": ["cheese on toast", "welsh rarebit"],
    "egg on toast": ["egg on toast", "poached egg"],
    "full english": ["full english breakfast", "english breakfast", "fry up"],
    "fish and chips": ["fish and chips", "cod and chips", "fish chips"],
    "fish fingers": ["fish fingers", "birds eye fish fingers"],
    "chicken nuggets": ["chicken nuggets"],
    "fish cake": ["fish cake", "fishcake"],
    "sausage roll": ["sausage roll", "greggs sausage roll"],
    "pasty": ["cornish pasty", "pasty", "greggs pasty"],
    "pie": ["pie", "meat pie", "steak pie"],
    "jacket potato": ["jacket potato", "baked potato"],
    "chips": ["chips", "oven chips", "fries"],  // UK chips = fries
    "curry": ["chicken curry", "curry sauce", "tikka masala"],
    "sandwich": ["sandwich", "ham sandwich", "cheese sandwich"],
    "wrap": ["wrap", "chicken wrap", "tortilla wrap"],
    "salad": ["salad", "mixed salad", "side salad"],
    "soup": ["soup", "tomato soup", "heinz soup"],

    // Breakfast items
    "cereal": ["cereal", "cornflakes", "weetabix"],
    "weetabix": ["weetabix"],
    "cornflakes": ["cornflakes", "kelloggs corn flakes"],
    "shreddies": ["shreddies"],
    "coco pops": ["coco pops", "kelloggs coco pops"],
    "frosties": ["frosties", "kelloggs frosties"],
    "cheerios": ["cheerios"],
    "granola": ["granola"],
    "muesli": ["muesli"],

    // Yoghurts
    "yoghurt": ["yoghurt", "natural yoghurt", "greek yoghurt"],
    "muller": ["muller corner", "muller light", "muller yoghurt"],
    "activia": ["activia", "activia yoghurt"],
    "yeo valley": ["yeo valley", "yeo valley yoghurt"],

    // Ready meals / convenience
    "pot noodle": ["pot noodle"],
    "super noodles": ["super noodles", "batchelors super noodles"],
    "pizza": ["pizza", "margherita pizza", "pepperoni pizza"],
    "lasagne": ["lasagne"],
    "cottage pie": ["cottage pie"],
    "shepherds pie": ["shepherds pie", "shepherd's pie"],
]

/// Indicates single-serve products (cans, bars, single portions)
/// These should be boosted over multipacks for typical calorie logging
let singleServeIndicators: Set<String> = [
    // Size indicators for drinks
    "330ml", "250ml", "500ml", "can", "bottle", "carton",
    // Size indicators for chocolate/snacks
    "bar", "single", "standard", "regular",
    // Portion indicators
    "portion", "serving", "individual", "1x", "each",
    // Weight indicators for typical single items
    "25g", "30g", "32g", "35g", "40g", "45g", "50g", "51g", "52g", "58g"
]

/// Indicates multipacks/bulk items that should be demoted
/// Users logging calories want single items, not 24-packs
let bulkIndicators: Set<String> = [
    // Pack quantities
    "multipack", "multi-pack", "multi pack",
    "case", "cases", "tray", "box of",
    "24 pack", "24pk", "24x", "x24",
    "18 pack", "18pk", "18x", "x18",
    "12 pack", "12pk", "12x", "x12",
    "10 pack", "10pk", "10x", "x10",
    "8 pack", "8pk", "8x", "x8",
    "6 pack", "6pk", "6x", "x6",
    "4 pack", "4pk", "4x", "x4",
    "3 pack", "3pk", "3x", "x3",
    "2 pack", "2pk", "2x", "x2",
    // Bulk terms
    "bulk", "wholesale", "catering", "family pack", "sharing",
    "value pack", "bundle", "selection"
]

let brandSynonymGroups: [[String]] = [
    // === FAST FOOD RESTAURANTS (grade hidden) ===
    // McDonald's variants
    ["mcdonald's", "mcdonalds", "mcd", "maccies", "mickey d's", "mickey ds", "maccas", "maccy d's", "maccy ds"],
    // Burger King variants
    ["burger king", "bk", "burgerking"],
    // KFC variants
    ["kfc", "kentucky fried chicken", "kentucky"],
    // Domino's variants
    ["domino's", "dominos", "domino", "domino's pizza"],
    // Pizza Hut variants
    ["pizza hut", "pizzahut"],
    // Starbucks variants
    ["starbucks", "starbuck's", "sbux"],
    // Dunkin variants
    ["dunkin", "dunkin donuts", "dunkin'", "dunkin doughnuts"],
    // Krispy Kreme variants
    ["krispy kreme", "krispykreme", "krispy kream"],
    // Nando's variants
    ["nando's", "nandos", "nando"],
    // Greggs variants
    ["greggs", "gregg's"],
    // Costa variants
    ["costa", "costa coffee"],
    // Pret variants
    ["pret", "pret a manger"],
    // Wendy's variants
    ["wendy's", "wendys", "wendy"],
    // Taco Bell variants
    ["taco bell", "tacobell"],
    // Five Guys variants
    ["five guys", "fiveguys", "5 guys"],
    // Shake Shack variants
    ["shake shack", "shakeshack"],
    // Chick-fil-A variants
    ["chick-fil-a", "chickfila", "chick fil a"],
    // Popeyes variants
    ["popeyes", "popeye's", "popeye"],
    // Tim Hortons variants
    ["tim hortons", "tim horton's", "timhortons", "tims"],
    // Wetherspoon variants
    ["wetherspoon", "wetherspoons", "j d wetherspoon", "jd wetherspoon", "spoons"],
    // In-N-Out variants
    ["in-n-out", "in n out", "innout", "in and out"],
    // Subway
    ["subway"],
    // Chipotle
    ["chipotle"],

    // === PACKAGED FOOD BRANDS (synonyms for search, but grade IS shown) ===
    // Soft drinks
    ["coca-cola", "coca cola", "cocacola", "coke", "diet coke", "coke zero", "cherry coke", "coca-cola zero", "coke classic"],
    ["pepsi", "pepsico", "pepsi-cola", "pepsi cola", "diet pepsi", "pepsi max", "pepsi zero"],
    ["dr pepper", "dr. pepper", "drpepper", "doctor pepper"],
    ["mountain dew", "mtn dew", "mountaindew"],
    ["sprite", "sprite zero"],
    ["fanta", "fanta orange"],
    ["7up", "7-up", "seven up", "sevenup"],
    ["lucozade", "lucozade energy", "lucozade sport"],
    ["irn-bru", "irn bru", "irnbru", "iron brew"],
    ["gatorade", "gator aid"],
    ["powerade", "power ade"],
    ["prime", "prime hydration", "prime drink"],
    ["tropicana", "tropicana juice"],
    ["innocent", "innocent smoothies", "innocent drinks"],
    // Energy drinks
    ["red bull", "redbull"],
    ["monster", "monster energy", "monster drink"],
    // Confectionery
    ["cadbury", "cadbury's", "cadburys"],
    ["nestle", "nestlé", "nestle's"],
    ["mars", "mars bar"],
    ["kit kat", "kitkat", "kit-kat"],
    ["m&m's", "m&ms", "mms", "m and ms"],
    ["haribo", "haribo sweets"],
    // Crisps
    ["walkers", "walkers crisps", "walker's"],
    ["lays", "lay's"],
    ["pringles", "pringle's"],
    ["doritos", "dorito"],
]

/// Fast food restaurant brands - NutraSafe grade hidden for these
/// These are restaurants where grading is meaningless (inherently ultra-processed, variable recipes)
let fastFoodRestaurantBrands: Set<String> = {
    var brands = Set<String>()

    // Add fast food restaurant synonym groups
    let fastFoodGroups: [[String]] = [
        ["mcdonald's", "mcdonalds", "mcd", "maccies", "mickey d's", "mickey ds", "maccas", "maccy d's", "maccy ds"],
        ["burger king", "bk", "burgerking"],
        ["kfc", "kentucky fried chicken", "kentucky"],
        ["domino's", "dominos", "domino", "domino's pizza"],
        ["pizza hut", "pizzahut"],
        ["starbucks", "starbuck's", "sbux"],
        ["dunkin", "dunkin donuts", "dunkin'", "dunkin doughnuts"],
        ["krispy kreme", "krispykreme", "krispy kream"],
        ["nando's", "nandos", "nando"],
        ["greggs", "gregg's"],
        ["costa", "costa coffee"],
        ["pret", "pret a manger"],
        ["wendy's", "wendys", "wendy"],
        ["taco bell", "tacobell"],
        ["five guys", "fiveguys", "5 guys"],
        ["shake shack", "shakeshack"],
        ["chick-fil-a", "chickfila", "chick fil a"],
        ["popeyes", "popeye's", "popeye"],
        ["tim hortons", "tim horton's", "timhortons", "tims"],
        ["wetherspoon", "wetherspoons", "j d wetherspoon", "jd wetherspoon", "spoons"],
        ["in-n-out", "in n out", "innout", "in and out"],
        ["subway"],
        ["chipotle"],
    ]

    for group in fastFoodGroups {
        for brand in group {
            brands.insert(brand)
        }
    }

    // Additional fast food restaurants not in synonym groups
    let additionalRestaurants = [
        // UK chains
        "papa john's", "papa johns", "papa john",
        "little caesars", "little caesar's",
        "harvester", "toby carvery", "beefeater",
        "frankie & benny's", "frankie and bennys",
        "pizza express", "pizzaexpress",
        "wagamama", "wagamamas",
        "yo! sushi", "yo sushi", "yosushi",
        "itsu", "leon", "tortilla",
        "gourmet burger kitchen", "gbk",
        "byron", "honest burgers",
        // US chains
        "jack in the box", "sonic",
        "arby's", "arbys", "arby",
        "carl's jr", "carls jr", "carlsjr",
        "hardee's", "hardees", "hardee",
        "white castle", "whitecastle",
        "checkers", "rally's", "rallys",
        "whataburger", "culver's", "culvers",
        "del taco", "deltaco", "el pollo loco",
        "wingstop", "buffalo wild wings", "bdubs", "bww",
        "hooters", "raising cane's", "raising canes",
        "zaxby's", "zaxbys", "bojangles", "bojangle's",
        "church's chicken", "churchs chicken",
        "long john silver's", "long john silvers",
        "captain d's", "captain ds",
        "hungry jack's", "hungry jacks", "red rooster",
    ]

    for restaurant in additionalRestaurants {
        brands.insert(restaurant)
    }

    return brands
}()

/// Legacy alias for backward compatibility - now only contains fast food restaurants
let processedFoodBrands: Set<String> = fastFoodRestaurantBrands

/// Maps any brand synonym to its canonical (first) name in the group
private let synonymToCanonical: [String: String] = {
    var mapping: [String: String] = [:]
    for group in brandSynonymGroups {
        guard let canonical = group.first else { continue }
        for synonym in group {
            mapping[synonym] = canonical
        }
    }
    return mapping
}()

/// Maps canonical brand name to all its synonyms
private let canonicalToSynonyms: [String: [String]] = {
    var mapping: [String: [String]] = [:]
    for group in brandSynonymGroups {
        guard let canonical = group.first else { continue }
        mapping[canonical] = group
    }
    return mapping
}()

/// Check if a brand/name is a fast food restaurant (grade should be hidden)
/// NOTE: Packaged food brands (confectionery, crisps, drinks) now show grades
func isProcessedFoodBrand(brand: String?, name: String) -> Bool {
    let brandLower = brand?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let nameLower = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

    let textsToCheck = [brandLower, nameLower].filter { !$0.isEmpty }

    for text in textsToCheck {
        // Check exact match first
        if fastFoodRestaurantBrands.contains(text) {
            return true
        }
        // Check if text contains any fast food restaurant brand
        for restaurant in fastFoodRestaurantBrands {
            if text.contains(restaurant) {
                return true
            }
        }
    }
    return false
}

/// Expand a search query to include brand synonyms and UK common food expansions
func expandSearchQuery(_ query: String) -> [String] {
    let queryLower = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    var expandedQueries = [query]

    // First, check for UK common food expansions (e.g., "beans" -> "baked beans")
    if let ukExpansions = ukCommonFoodExpansions[queryLower] {
        for expansion in ukExpansions where !expandedQueries.contains(expansion) {
            expandedQueries.append(expansion)
        }
    }

    // Then check brand synonyms
    if let canonical = synonymToCanonical[queryLower],
       let synonyms = canonicalToSynonyms[canonical] {
        for synonym in synonyms where synonym != queryLower {
            expandedQueries.append(synonym)
        }
    } else {
        for (synonym, canonical) in synonymToCanonical {
            if queryLower.contains(synonym), let allSynonyms = canonicalToSynonyms[canonical] {
                for otherSynonym in allSynonyms where otherSynonym != synonym {
                    let expandedQuery = queryLower.replacingOccurrences(of: synonym, with: otherSynonym)
                    if !expandedQueries.contains(expandedQuery) {
                        expandedQueries.append(expandedQuery)
                    }
                }
                break
            }
        }
    }

    return expandedQueries
}

// MARK: - Algolia Search Manager

/// Manages direct Algolia search operations using REST API (no Cloud Function intermediary)
final class AlgoliaSearchManager {
    static let shared = AlgoliaSearchManager()

    // Algolia credentials - search-only API keys are designed for client-side use
    private let appId: String
    private let searchKey: String

    // Base URL for Algolia API
    private var baseURL: String {
        return "https://\(appId)-dsn.algolia.net/1/indexes"
    }

    // Index names with priority - lower number = higher priority
    // TIER 0: Generic foods (consumer_foods - broad ingredient coverage)
    // TIER 1: Branded/retail sources (Tesco, etc)
    // TIER 2: UK Foods Cleaned (master database)
    // TIER 3: AI-enhanced and verified sources
    // Results are deduplicated, so items from lower-priority indices only appear if not in higher-priority ones
    private var indices: [(String, Int)] {
        return [
            ("consumer_foods", 0),       // TIER 0: Generic foods (highest priority - broad coverage)
            ("tesco_products", 1),       // TIER 1: Tesco UK (official supermarket data)
            ("uk_foods_cleaned", 2),     // TIER 2: UK Foods Cleaned (master database - 72k records)
            ("verified_foods", 3),       // TIER 3: Admin-verified foods (human verified)
            ("ai_enhanced", 4),          // TIER 4: AI-enhanced foods (AI verified with human approval)
            ("ai_manually_added", 5),    // TIER 5: AI manually added foods (from AI scanner)
            ("user_added", 6),           // TIER 6: User's custom foods
            ("foods", 7),                // TIER 7: Original foods (fallback - fills gaps)
            ("fast_foods_database", 8),  // TIER 8: Fast Food restaurants
        ]
    }

    /// Returns indices with adjusted priorities for generic food searches
    /// When searching for generic foods (banana, apple, etc.), boost consumer_foods to top priority
    private func indicesForIntent(_ intent: SearchIntent) -> [(String, Int)] {
        switch intent {
        case .genericFood(_):
            // For generic food searches, prioritize consumer_foods alongside verified_foods
            return [
                ("consumer_foods", 0),       // BOOSTED: Consumer foods get top priority for generic searches
                ("verified_foods", 0),       // TIER 0: Admin-verified foods
                ("uk_foods_cleaned", 1),     // UK Foods often has raw ingredients
                ("foods", 2),                // Original foods database
                ("ai_enhanced", 3),          // AI-enhanced foods
                ("ai_manually_added", 3),    // AI manually added foods
                ("tesco_products", 4),       // Tesco UK - demoted for generic searches (mostly branded)
                ("fast_foods_database", 5),  // Fast Food restaurants
                ("user_added", 6),           // User's custom foods
            ]
        default:
            return indices
        }
    }

    // Cache for search results
    private let searchCache = NSCache<NSString, SearchCacheEntry>()
    private let cacheExpirationSeconds: TimeInterval = 300 // 5 minutes

    // Shared URLSession for all requests
    private let session: URLSession

    private init() {
        // Algolia search-only credentials - safe for client-side use (can only read, not write)
        self.appId = "WK0TIF84M2"
        self.searchKey = "577cc4ee3fed660318917bbb54abfb2e"

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10 // 10 second timeout
        config.timeoutIntervalForResource = 30
        // PERFORMANCE: Don't wait indefinitely for network - fail fast instead
        config.waitsForConnectivity = false
        session = URLSession(configuration: config)
        searchCache.countLimit = 100
    }

    // MARK: - Word Order Flexibility Helpers

    /// Detect if query is a simple 2-word phrase that should be searched with flexible word order
    private func shouldUseFlexibleWordOrder(_ query: String) -> Bool {
        let words = query.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        // Only enable for exactly 2 words, each at least 3 characters
        guard words.count == 2 else { return false }
        return words.allSatisfy { $0.count >= 3 }
    }

    /// Generate word order variants for 2-word queries
    private func generateWordOrderVariants(_ query: String) -> [String] {
        let words = query.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        guard words.count == 2 else { return [query] }

        let original = words.joined(separator: " ")
        let reversed = words.reversed().joined(separator: " ")

        // Return both orders (original first for better ranking)
        return [original, reversed]
    }

    // MARK: - Search Methods

    /// Multi-stage search pipeline for optimal UK food database results
    /// Stage 0: Local SQLite database (offline-first, instant results)
    /// Stage 1: Exact/canonical matches (Algolia)
    /// Stage 2: Strong partial matches (Algolia)
    /// Stage 3: Fuzzy matches (misspellings)
    /// Stage 4: Generic fallbacks
    /// Stage 5: Firebase fallback (when Algolia unavailable)
    ///
    /// - Parameters:
    ///   - query: Search query string
    ///   - hitsPerPage: Number of results per page (default 20)
    /// - Returns: Array of FoodSearchResult
    func search(query: String, hitsPerPage: Int = 20) async throws -> [FoodSearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        guard !trimmedQuery.isEmpty else { return [] }

        let cacheKey = trimmedQuery.lowercased() as NSString

        // Check cache first
        if let cached = searchCache.object(forKey: cacheKey) {
            let age = Date().timeIntervalSince(cached.timestamp)
            if age < cacheExpirationSeconds {
                // Check if cached results have ingredients - if not, invalidate cache
                // (handles migration from old cache entries without ingredients)
                let hasIngredients = cached.results.first?.ingredients?.isEmpty == false
                if hasIngredients {
                    return cached.results
                } else {
                    // Cache is stale (missing ingredients) - force refresh
                    searchCache.removeObject(forKey: cacheKey)
                }
            } else {
                searchCache.removeObject(forKey: cacheKey)
            }
        }

        // === STAGE 0: LOCAL DATABASE (PREFERRED - INSTANT RESULTS) ===
        // Always check local database first for instant results
        // Local DB is the primary source, Algolia supplements with newer items
        var localResults: [FoodSearchResult] = []
        if LocalDatabaseManager.shared.isAvailable {
            localResults = LocalDatabaseManager.shared.search(query: trimmedQuery, limit: hitsPerPage * 2)
            print("📱 LocalDB: Found \(localResults.count) results for '\(trimmedQuery)'")

            // If we have good local results (>= 10), we can skip Algolia for common queries
            // This dramatically reduces API costs and improves speed
            if localResults.count >= 10 && !trimmedQuery.contains("@") {
                // Cache local results
                searchCache.setObject(
                    SearchCacheEntry(results: Array(localResults.prefix(hitsPerPage)), timestamp: Date()),
                    forKey: cacheKey
                )
                return Array(localResults.prefix(hitsPerPage))
            }
        }

        // If offline, return local results immediately
        if !NetworkMonitor.shared.isConnected {
            print("📴 Offline mode: Returning \(localResults.count) local results")
            return localResults
        }

        var allResults: [FoodSearchResult] = []

        do {
        // === STAGE 0: NORMALIZE INPUT ===
        let normalized = SearchQueryNormalizer.normalize(trimmedQuery)

        // PERFORMANCE: Instead of searching ALL variants in parallel (slow),
        // use a cascading approach: try primary first, expand only if needed
        var seenIds = Set<String>()
        let searchIndices = indicesForIntent(normalized.intent)

        // === STAGE 1: PRIMARY SEARCH (FAST PATH) ===
        // Search with the normalized primary query first
        do {
            let primaryResults = try await searchMultipleIndices(
                query: normalized.primary,
                hitsPerPage: hitsPerPage * 2,
                usingIndices: searchIndices
            )
            for result in primaryResults where !seenIds.contains(result.id) {
                seenIds.insert(result.id)
                allResults.append(result)
            }
        } catch {
            // Continue to expansions if primary fails
        }

        // === STAGE 2: EXPAND IF SPARSE (ONLY IF NEEDED) ===
        // Only search additional variants if we got < 10 results
        if allResults.count < 10 {
            // Build SMALL query set: top 3 most relevant variants only
            var expandedQueries = Set<String>()

            // Add first 2 normalized variants (exclude primary - already searched)
            for variant in normalized.variants.prefix(3) where variant != normalized.primary {
                expandedQueries.insert(variant)
            }

            // Add top brand synonym if available
            let brandExpanded = expandSearchQuery(normalized.primary)
            if let topBrandVariant = brandExpanded.first, topBrandVariant != normalized.primary {
                expandedQueries.insert(topBrandVariant.lowercased())
            }

            // Search these limited variants in parallel
            if !expandedQueries.isEmpty {
                await withTaskGroup(of: [FoodSearchResult].self) { group in
                    for searchQuery in expandedQueries {
                        group.addTask {
                            do {
                                return try await self.searchMultipleIndices(
                                    query: searchQuery,
                                    hitsPerPage: 15,
                                    usingIndices: searchIndices
                                )
                            } catch {
                                return []
                            }
                        }
                    }

                    for await results in group {
                        for result in results where !seenIds.contains(result.id) {
                            seenIds.insert(result.id)
                            allResults.append(result)
                        }
                    }
                }
            }
        }

        // === STAGE 3: FUZZY MATCHING (ONLY IF VERY SPARSE) ===
        // Only try fuzzy if we still have < 5 results
        if allResults.count < 5 {
            let fuzzyVariants = FuzzyMatcher.generateMisspellingVariants(normalized.primary)
            await withTaskGroup(of: [FoodSearchResult].self) { group in
                for fuzzyQuery in fuzzyVariants.prefix(3) {  // Reduced from 5 to 3
                    group.addTask {
                        do {
                            return try await self.searchMultipleIndices(query: fuzzyQuery, hitsPerPage: 10, usingIndices: searchIndices)
                        } catch {
                            return []
                        }
                    }
                }

                for await results in group {
                    for result in results where !seenIds.contains(result.id) {
                        seenIds.insert(result.id)
                        allResults.append(result)
                    }
                }
            }
        }

        // === MERGE LOCAL + ALGOLIA RESULTS ===
        // Add local results that aren't already in Algolia results
        var mergedResults = allResults
        let algoliaIds = Set(allResults.map { $0.id })
        for localResult in localResults where !algoliaIds.contains(localResult.id) {
            mergedResults.append(localResult)
        }

        // === FINAL RANKING ===
        // Apply multi-stage ranking with intent awareness
        let rankedResults = rankResultsMultiStage(
            mergedResults,
            originalQuery: trimmedQuery,
            normalizedQuery: normalized,
            hitsPerPage: hitsPerPage
        )

        // Cache results
        searchCache.setObject(
            SearchCacheEntry(results: rankedResults, timestamp: Date()),
            forKey: cacheKey
        )

        return rankedResults
        }
    }

    // MARK: - Multi-Stage Ranking

    /// Advanced ranking that considers search intent, canonical products, and UK defaults
    private func rankResultsMultiStage(
        _ results: [FoodSearchResult],
        originalQuery: String,
        normalizedQuery: NormalizedQuery,
        hitsPerPage: Int
    ) -> [FoodSearchResult] {
        let queryLower = originalQuery.lowercased()
        let queryWords = Set(queryLower.split(separator: " ").map { String($0) })

        let scored = results.map { result -> (result: FoodSearchResult, score: Int, tier: Int) in
            let nameLower = result.name.lowercased()
            let nameWords = Set(nameLower.split(separator: " ").map { String($0) })
            let brandLower = result.brand?.lowercased() ?? ""

            var score = 0
            var tier = 4  // Default tier (lowest)

            // === TIER 0: BASE/RAW FOOD EXACT MATCHES (15000+ points) ===
            // This handles single-word queries like "banana", "apple", "rice"
            // where the user wants the raw/base food, not branded products

            if queryWords.count == 1 {
                // Check if this is a base/raw food exact match
                // Patterns that indicate base foods: just the food name, or food name + raw/fresh qualifiers
                let baseNamePatterns = [
                    queryLower,                           // "banana"
                    "\(queryLower) raw",                  // "banana raw"
                    "\(queryLower), raw",                 // "banana, raw"
                    "\(queryLower) (raw)",                // "banana (raw)"
                    "raw \(queryLower)",                  // "raw banana"
                    "\(queryLower) fresh",                // "banana fresh"
                    "fresh \(queryLower)",                // "fresh banana"
                    "\(queryLower)s",                     // "bananas" (plural)
                    "\(queryLower)s raw",                 // "bananas raw"
                    "\(queryLower)s, raw",                // "bananas, raw"
                    "\(queryLower), fresh",               // "banana, fresh"
                    "\(queryLower) whole",                // "banana whole"
                    "whole \(queryLower)",                // "whole banana"
                ]

                // Size qualifiers that indicate base foods (e.g., "Banana (Small)", "Apple Large")
                let sizeQualifiers = ["small", "medium", "large", "extra large", "xl", "mini",
                                     "(small)", "(medium)", "(large)", "(extra large)"]
                let hasSizeQualifier = sizeQualifiers.contains { nameLower.contains($0) }

                let isBaseFoodMatch = baseNamePatterns.contains { pattern in
                    nameLower == pattern || nameLower.hasPrefix(pattern + " ") && nameWords.count <= 3
                }

                // Check for size-qualified base foods like "Banana (Small)", "Banana Medium"
                let isSizeQualifiedBaseFood = hasSizeQualifier &&
                    (nameLower.hasPrefix(queryLower) || nameLower.hasPrefix("\(queryLower)s")) &&
                    nameWords.count <= 3 &&
                    !nameLower.contains("&") &&
                    !nameLower.contains(" and ") &&
                    !nameLower.contains(" with ") &&
                    brandLower.isEmpty

                // Composite/recipe food indicators - these are NOT base foods
                let compositeIndicators = ["&", " and ", " with ", " in ", "shallot", "shrimps", "chicken",
                                          "pork", "beef", "lamb", "fish", "prawn", "shrimp", "sauce",
                                          "curry", "stew", "soup", "salad", "sandwich", "wrap", "pie",
                                          "cake", "bread", "muffin", "pudding", "smoothie", "shake",
                                          "protein", "whey", "bar", "bars", "chip", "chips", "crisp",
                                          "daifuku", "ice cream", "yoghurt", "yogurt", "jam", "jelly",
                                          "juice", "drink", "flavour", "flavor", "dried", "freeze"]
                let isCompositeFood = compositeIndicators.contains { nameLower.contains($0) }

                // Also check if name is just the food with size/variety (e.g., "Banana Medium", "Apple Gala")
                let isSimpleVariety = nameWords.count <= 3 &&
                    nameWords.contains(queryLower) &&
                    !isCompositeFood &&
                    brandLower.isEmpty  // No brand = likely generic/base food

                if isBaseFoodMatch && !isCompositeFood {
                    score += 15000  // Highest priority for exact base food matches
                    tier = 0
                } else if isSizeQualifiedBaseFood {
                    score += 14000  // Very high priority for size-qualified base foods
                    tier = 0
                } else if isSimpleVariety && !isCompositeFood {
                    score += 12000  // High priority for simple variety names
                    tier = 0
                } else if isCompositeFood {
                    score -= 5000   // Heavy penalty for composite/recipe foods
                }
            }

            // === TIER 1: EXACT & CANONICAL MATCHES (10000+ points) ===

            // Exact name match (only if not already tier 0)
            if tier > 0 && nameLower == queryLower {
                score += 10000
                tier = 1
            }
            // Name starts with query AND query is a complete word
            else if tier > 0 && nameLower.hasPrefix(queryLower) && nameWords.contains(queryLower) {
                score += 9500
                tier = 1
                // Extra bonus for short product names (canonical products tend to be short)
                if nameWords.count <= 3 {
                    score += 1500
                }
            }
            // Brand + product exact match (e.g., "mars bar" matches "Mars Bar")
            else if tier > 0, let brand = result.brand?.lowercased(),
                    queryWords.contains(brand) || brand.hasPrefix(queryLower.split(separator: " ").first ?? "") {
                let productWords = queryWords.filter { $0 != brand }
                let allProductWordsMatch = productWords.allSatisfy { word in
                    nameWords.contains(word) || nameWords.contains { $0.hasPrefix(word) }
                }
                if allProductWordsMatch && !productWords.isEmpty {
                    score += 9000
                    tier = 1
                }
            }

            // === CANONICAL PRODUCT SCORING ===
            let canonicalBonus = CanonicalProductDetector.canonicalScore(productName: result.name, forQuery: queryLower)
            score += canonicalBonus
            if canonicalBonus >= 3000 {
                tier = min(tier, 1)
            }

            // === UK DEFAULT SCORING (for generic foods like "milk") ===
            if case .genericFood(_) = normalizedQuery.intent {
                let defaultBonus = UKFoodDefaults.defaultScore(productName: result.name, forQuery: queryLower)
                score += defaultBonus
                if defaultBonus >= 3000 {
                    tier = min(tier, 1)
                }
            }

            // === TIER 2: STRONG PARTIAL MATCHES (6000-8999 points) ===

            if tier > 2 {
                // Query is an exact word in name
                if queryWords.count == 1 && nameWords.contains(queryLower) {
                    score += 7500
                    tier = 2
                    if nameWords.count <= 3 {
                        score += 1500  // Short name bonus
                    }
                }
                // All query words present as exact words
                else if queryWords.allSatisfy({ nameWords.contains($0) }) {
                    score += 7000
                    tier = 2
                    if nameWords.count == queryWords.count {
                        score += 2000  // Exact word count match
                    }
                }
                // Name starts with query
                else if nameLower.hasPrefix(queryLower) {
                    score += 6500
                    tier = 2
                }
                // Brand exact match (pure brand search)
                else if brandLower == queryLower {
                    score += 6000
                    tier = 2
                }
            }

            // === TIER 3: PARTIAL MATCHES (3000-5999 points) ===

            if tier > 3 {
                // All query words as prefixes in name
                if queryWords.allSatisfy({ queryWord in
                    nameWords.contains { $0.hasPrefix(queryWord) }
                }) {
                    score += 5000
                    tier = 3
                }
                // Query as substring (not at word boundary)
                else if nameLower.contains(queryLower) {
                    score += 3500
                    tier = 3
                }
                // Brand contains query
                else if brandLower.contains(queryLower) {
                    score += 3000
                    tier = 3
                }
            }

            // === TIER 4: FUZZY/WEAK MATCHES (1000-2999 points) ===

            if tier > 3 {
                // Fuzzy match scoring
                let fuzzyScore = FuzzyMatcher.fuzzyScore(queryLower, nameLower)
                if fuzzyScore >= 80 {
                    score += 2000 + (fuzzyScore - 80) * 20
                    tier = 4
                } else if fuzzyScore >= 60 {
                    score += 1000 + (fuzzyScore - 60) * 20
                    tier = 4
                }
            }

            // === UNIVERSAL MODIFIERS ===

            // MULTIPACK PENALTY (applied regardless of tier)
            let multipackPatterns = [
                "\\d+pk\\b", "\\d+\\s*pack\\b", "\\bx\\d+\\b", "\\d+\\s*x\\s*\\d+",
                "\\bmultipack\\b", "\\bmulti-pack\\b", "\\bmulti pack\\b",
                "\\bfamily pack\\b", "\\bbulk\\b", "\\bsharing\\b",
                "\\bselection\\b", "\\bvariety\\b", "\\bcase\\b", "\\btray\\b",
                "\\bmini\\b", "\\bminis\\b", "\\bfunsize\\b", "\\bfun size\\b",
                "\\bbite\\b", "\\bbites\\b"
            ]
            let multipackRegex = try? NSRegularExpression(
                pattern: multipackPatterns.joined(separator: "|"),
                options: [.caseInsensitive]
            )
            if let regex = multipackRegex,
               regex.firstMatch(in: nameLower, options: [], range: NSRange(nameLower.startIndex..., in: nameLower)) != nil {
                score -= 3000  // Strong demotion for multipacks/minis
            }

            // SINGLE-SERVE BONUS
            if singleServeIndicators.contains(where: { nameLower.contains($0) }) {
                score += 1500
            }

            // BULK INDICATORS PENALTY
            if bulkIndicators.contains(where: { nameLower.contains($0) }) {
                score -= 2000
            }

            // SERVING SIZE SCORING
            if let servingGrams = result.servingSizeG, servingGrams > 0 {
                // Prefer single-serve portions
                if servingGrams <= 50 {
                    score += 1200  // Snack-sized (chocolate bar, single can appetizer)
                } else if servingGrams <= 100 {
                    score += 800   // Standard portion
                } else if servingGrams <= 200 {
                    score += 300   // Reasonable portion
                } else if servingGrams <= 500 {
                    // No bonus or penalty for medium portions
                    score += 0
                } else if servingGrams > 500 && servingGrams <= 1000 {
                    score -= 600   // Large portion (likely bulk)
                } else if servingGrams > 1000 {
                    score -= 1200  // Very large (definitely bulk like 2L bottles)
                }

                // BONUS: Prefer items with ACTUAL serving size over generic 100g
                // If servingGrams is NOT exactly 100, it's likely real data
                if servingGrams != 100 {
                    score += 1500  // Strong bonus for actual serving data
                }
            } else {
                // PENALTY: No serving size = generic 100g default
                score -= 800  // Demote items without serving data
            }

            // BONUS: Item has meaningful serving size (from name or description)
            if result.hasActualServingSize {
                score += 1000  // Reward items with concrete size info
            }

            // NAME LENGTH BONUS (shorter = more canonical)
            let lengthBonus = max(0, 600 - result.name.count * 12)
            score += lengthBonus

            // SOURCE TIER BONUS
            if let source = result.source {
                switch source {
                case "consumer_foods": score += 400     // Highest priority
                case "tesco_products": score += 350     // Second priority
                case "uk_foods_cleaned": score += 300   // Third priority
                case "foods": score += 200
                case "fast_foods_database": score += 150
                default: score += 50
                }
            }

            // VERIFIED BONUS
            if result.isVerified {
                score += 250
            }

            // SMART IMAGE BOOST/PENALTY: Context-aware prioritization
            // For branded product searches (1-2 words like "twix"), users want to see product photos
            // Solution: BOOST items WITH images, PENALIZE items WITHOUT images
            let hasImage = result.imageUrl != nil && !result.imageUrl!.isEmpty

            // Image boost is now a TIEBREAKER, not a dominant factor
            // Relevance comes first - if two "Mars Bar" results have similar relevance,
            // prefer the one with an image
            if hasImage {
                score += 500  // Small tiebreaker boost for items with images
            }
            // No penalty for missing images - relevance should dominate

            // === INTENT-SPECIFIC SCORING ===

            switch normalizedQuery.intent {
            case .brandOnly(let brand):
                // Pure brand search - boost items where brand matches exactly
                if brandLower == brand || brandLower.hasPrefix(brand) {
                    score += 2000
                }
                // Penalty for items where the brand is in the name but there's a different brand
                if !brandLower.isEmpty && brandLower != brand && nameLower.contains(brand) {
                    score -= 1000
                }

            case .brandAndProduct(let brand, let product):
                // Brand + product search - both must be present
                let hasBrand = brandLower.contains(brand) || nameLower.contains(brand)
                let productWords = Set(product.split(separator: " ").map { String($0) })
                let hasProduct = productWords.allSatisfy { nameWords.contains($0) || nameWords.contains(where: { $0.hasPrefix($0) }) }

                if hasBrand && hasProduct {
                    score += 3000
                } else if hasBrand {
                    score += 500
                }

            case .genericFood(let foodName):
                // Generic food search (e.g., "banana", "apple", "steak", "chicken")
                // HOLISTIC APPROACH: Prioritize raw/base foods over prepared/composite products

                // === HOLISTIC PREPARED FOOD DETECTION ===
                // This works for ANY food, not just items in UKFoodDefaults
                let preparedPenalty = PreparedFoodDetector.preparedFoodPenalty(productName: result.name, query: foodName)
                score += preparedPenalty

                // Extra penalty if query word is in "modifier position" (e.g., "Steak" in "Steak Bake")
                if PreparedFoodDetector.isModifierPosition(query: foodName, productName: result.name) {
                    score -= 5000  // "steak" in "Steak Bake" - user didn't want this
                }

                // Check if UKFoodDefaults has specific patterns for this food
                // (provides additional fine-tuning for common foods like milk, bread, etc.)
                let defaultBonus = UKFoodDefaults.defaultScore(productName: result.name, forQuery: foodName)
                if defaultBonus < 0 {
                    score += defaultBonus * 2  // Double the demotion effect
                } else if defaultBonus > 0 {
                    score += defaultBonus
                }

                // Penalty for branded items (user searching generic food doesn't want branded)
                if !brandLower.isEmpty {
                    score -= 3000
                }

                // Strong penalty for fast food restaurant sources
                if result.source == "fast_foods_database" {
                    score -= 6000  // User searching "steak" doesn't want Greggs Steak Bake
                }

                // Boost for simple, short names (likely the canonical raw food)
                if nameWords.count <= 3 && brandLower.isEmpty {
                    score += 3000  // Strong boost for simple unbranded names like "Beef Steak"
                } else if nameWords.count <= 3 {
                    score += 500
                }

                // Boost if the name is JUST the food (or food + size/variety)
                let sizeVarietyWords: Set<String> = ["raw", "fresh", "small", "medium", "large", "whole", "ripe",
                                                     "cooked", "boiled", "grilled", "roasted", "fried", "baked",
                                                     "lean", "skinless", "boneless", "fillet", "breast", "leg",
                                                     "sirloin", "ribeye", "rump", "mince", "minced", "diced"]
                let nonFoodWords = nameWords.filter { !$0.contains(foodName) && !sizeVarietyWords.contains($0) }
                if nonFoodWords.isEmpty && nameWords.count <= 4 {
                    score += 4000  // Name is basically just the food + qualifiers
                }

            default:
                break
            }

            return (result: result, score: score, tier: tier)
        }

        // Sort by final score only (tier value already included in score)
        // This allows image boost/penalty to override tier boundaries
        let sorted = scored.sorted { a, b in
            return a.score > b.score  // Higher score = higher priority
        }

        return Array(sorted.map { $0.result }.prefix(hitsPerPage))
    }

    /// Search multiple indices in parallel using TaskGroup
    /// - Parameters:
    ///   - query: Search query string
    ///   - hitsPerPage: Number of results per page
    ///   - usingIndices: Optional custom indices list (for intent-based priority adjustments)
    private func searchMultipleIndices(query: String, hitsPerPage: Int, usingIndices: [(String, Int)]? = nil) async throws -> [FoodSearchResult] {
        var allResults: [(result: FoodSearchResult, sourcePriority: Int)] = []
        var seenIds = Set<String>()
        let indicesToSearch = usingIndices ?? indices

        // Search all indices in parallel
        await withTaskGroup(of: (Int, [FoodSearchResult]).self) { group in
            for (indexName, priority) in indicesToSearch {
                group.addTask {
                    do {
                        let hits = try await self.searchIndex(
                            indexName: indexName,
                            query: query,
                            hitsPerPage: hitsPerPage
                        )
                        return (priority, hits)
                    } catch {
                                                return (priority, [])
                    }
                }
            }

            // Collect all results with their source priority
            for await (priority, hits) in group {
                for hit in hits where !seenIds.contains(hit.id) {
                    seenIds.insert(hit.id)
                    allResults.append((result: hit, sourcePriority: priority))
                }
            }
        }

        // Smart re-ranking: prioritize relevance over source
        let rankedResults = rankResults(allResults, query: query)

        // Return limited results
        return Array(rankedResults.prefix(hitsPerPage))
    }

    // MARK: - Smart Ranking

    /// Rank results based on relevance to query, not just source priority
    private func rankResults(_ results: [(result: FoodSearchResult, sourcePriority: Int)], query: String) -> [FoodSearchResult] {
        let queryLower = query.lowercased()
        let queryWords = Set(queryLower.split(separator: " ").map { String($0) })

        // Calculate relevance score for each result
        let scored = results.map { item -> (result: FoodSearchResult, score: Int) in
            let name = item.result.name
            let nameLower = name.lowercased()
            let nameWords = Set(nameLower.split(separator: " ").map { String($0) })

            var score = 0

            // Exact match (highest priority) - "Big Mac" == "big mac"
            if nameLower == queryLower {
                score += 10000
            }
            // Name starts with query AND query is a complete word (e.g., "Mars Bar" for "mars")
            // This should rank higher than generic "contains word" matches
            else if nameLower.hasPrefix(queryLower) && nameWords.contains(queryLower) {
                score += 8000  // High score: starts with query as complete word
                // Extra bonus for short product names (e.g., "Mars Bar" vs "Mars Bar Multipack 6x45g")
                if nameWords.count <= 3 {
                    score += 1500
                }
            }
            // Name starts with query - "Big Mac Meal" starts with "big mac"
            else if nameLower.hasPrefix(queryLower) {
                score += 5000
            }
            // Query is a complete word match at start - "Big" matches first word of "Big Mac"
            else if let firstWord = nameLower.split(separator: " ").first,
                    queryLower == String(firstWord) {
                score += 4000
            }
            // PRIORITY: Query word appears as EXACT COMPLETE WORD in name (not just prefix)
            // e.g., "milk" matches "Whole Milk", "Semi-Skimmed Milk", "Milk" etc.
            // This should score HIGHER than prefix matches like "Milkybar"
            else if queryWords.count == 1, nameWords.contains(queryLower) {
                score += 6000  // Higher than prefix match (5000) - exact word is better
                // Extra bonus if it's a short/generic name like "Whole Milk" (2 words)
                if nameWords.count <= 3 {
                    score += 1500
                }
            }
            // All query words appear in name as complete words or prefixes
            else if queryWords.allSatisfy({ queryWord in
                nameWords.contains { $0.hasPrefix(queryWord) || $0 == queryWord }
            }) {
                // Check if ALL query words are EXACT matches (not just prefixes)
                let allExactWordMatches = queryWords.allSatisfy({ queryWord in
                    nameWords.contains(queryWord)
                })

                if allExactWordMatches {
                    score += 5500  // Higher score for exact word matches
                } else {
                    score += 4500  // Prefix matches
                }

                // BONUS: If name has ONLY the query words (e.g., "Egg Boiled" for "boiled egg")
                // This catches reversed word order matches
                if nameWords.count == queryWords.count {
                    score += 2000  // Big bonus for exact word set match
                }
            }
            // Name contains query as substring but not as complete word
            // e.g., "milk" in "Milkybar" - should be LOWER priority
            else if nameLower.contains(queryLower) {
                score += 1500  // Lower than exact word match
            }
            // Any query word matches start of name
            else if queryWords.contains(where: { nameLower.hasPrefix($0) }) {
                score += 2000
            }

            // Bonus for shorter names (more specific matches)
            // "Big Mac" (7 chars) scores higher than "Big Mac with Large Fries" (25 chars)
            let lengthBonus = max(0, 500 - name.count * 10)
            score += lengthBonus

            // PENALTY for multipacks - demote items like "8pk", "6 pack", "multipack", "x4", etc.
            // These are bulk items, not individual portions that users typically want to log
            let multipackPatterns2 = [
                "\\d+pk\\b",           // 8pk, 6pk, 4pk
                "\\d+\\s*pack\\b",     // 8 pack, 6pack, 4 pack
                "\\bx\\d+\\b",         // x4, x6, x8
                "\\d+\\s*x\\s*\\d+",   // 6x4, 8 x 45g
                "\\bmultipack\\b",     // multipack
                "\\bmulti-pack\\b",    // multi-pack
                "\\bmulti pack\\b",    // multi pack
                "\\bfamily pack\\b",   // family pack
                "\\bbulk\\b",          // bulk
                "\\bsharing\\b",       // sharing bag/pack
                "\\bselection\\b",     // selection box
                "\\bvariety\\b",       // variety pack
                "\\bcase\\b",          // case of
                "\\btray\\b"           // tray of
            ]
            let multipackRegex2 = try? NSRegularExpression(
                pattern: multipackPatterns2.joined(separator: "|"),
                options: [.caseInsensitive]
            )
            if let regex = multipackRegex2,
               regex.firstMatch(in: nameLower, options: [], range: NSRange(nameLower.startIndex..., in: nameLower)) != nil {
                score -= 2500  // Stronger demotion for multipacks
            }

            // BONUS for single-serve indicators (cans, single bars, standard portions)
            let hasSingleServe = singleServeIndicators.contains { indicator in
                nameLower.contains(indicator)
            }
            if hasSingleServe {
                score += 1200  // Strong bonus for single-serve items
            }

            // Extra check for bulk indicators
            let hasBulk = bulkIndicators.contains { indicator in
                nameLower.contains(indicator)
            }
            if hasBulk {
                score -= 1500  // Additional penalty for bulk terms
            }

            // BONUS/PENALTY for serving size - prefer individual portions over bulk
            // Users typically want to log single items, not entire multipacks
            if let servingGrams = item.result.servingSizeG, servingGrams > 0 {
                if servingGrams <= 50 {
                    score += 1000  // Strong bonus for small portions (snacks, single items)
                } else if servingGrams <= 100 {
                    score += 600   // Good bonus for standard portions
                } else if servingGrams <= 200 {
                    score += 200   // Slight bonus for reasonable portions
                } else if servingGrams > 500 {
                    score -= 500   // Penalty for very large serving sizes (likely bulk)
                } else if servingGrams > 1000 {
                    score -= 1000  // Strong penalty for >1kg items
                }
            }

            // Bonus for verified items
            if item.result.isVerified {
                score += 200
            }

            // TIER 1 PRIORITY: Tesco products get significant boost (official UK supermarket data)
            // Priority 0 = Tesco = +300 boost
            // Priority 1 = UK Foods = +250 boost
            // Other sources get smaller bonuses
            if item.sourcePriority == 0 {
                score += 300  // Tesco tier 1 boost
            } else if item.sourcePriority == 1 {
                score += 250  // UK Foods tier 2 boost
            } else {
                score += (5 - item.sourcePriority) * 30  // Other sources get smaller bonus
            }

            // Brand bonus logic - only give high bonus when query is primarily a brand search
            // If query contains food-related words that match the name, prioritize name matches
            if let brand = item.result.brand?.lowercased() {
                let normalizedBrand = brand.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "'", with: "")
                let normalizedQuery = queryLower.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "'", with: "")

                // Check if query words primarily match the food NAME (not just brand)
                // e.g., "mars bar" - "mars" and "bar" both in name = name focused search
                let queryWordsInName = queryWords.filter { queryWord in
                    nameWords.contains(queryWord) || nameWords.contains(where: { $0.hasPrefix(queryWord) })
                }.count
                let queryWordsInBrand = queryWords.filter { normalizedBrand.contains($0) }.count
                let isNameFocusedSearch = queryWordsInName >= queryWordsInBrand && queryWordsInName > 0

                // Only give high brand bonus when query is a pure brand search (like "mcdonalds")
                if normalizedBrand == normalizedQuery && !isNameFocusedSearch {
                    // Pure brand search like "mars" when looking at Revels by Mars
                    score += 8000
                }
                else if normalizedBrand == normalizedQuery && isNameFocusedSearch {
                    // Brand matches but name also matches - reduce brand bonus
                    score += 2000
                }
                else if normalizedBrand.hasPrefix(normalizedQuery) && !isNameFocusedSearch {
                    // Brand starts with query - only if not a food name search
                    score += 4000
                }
                else if let canonical = synonymToCanonical[normalizedQuery],
                        normalizedBrand.contains(canonical.replacingOccurrences(of: "'", with: "")),
                        !isNameFocusedSearch {
                    // Known brand synonym - only if not a food name search
                    score += 3500
                }
                else if (normalizedBrand.contains(normalizedQuery) || normalizedQuery.contains(normalizedBrand)) && !isNameFocusedSearch {
                    // Brand contains query - only if not a food name search
                    score += 1000
                }
            }

            // SIMPLE PREPARED FOODS: Boost common UK preparations
            let simplePrepIndicators2: Set<String> = [
                "boiled", "poached", "scrambled", "fried", "grilled",
                "toasted", "steamed", "mashed", "baked", "roasted"
            ]
            if queryWords.count <= 2 {
                let hasSimplePrep = nameWords.contains { simplePrepIndicators2.contains($0) }
                if hasSimplePrep && nameWords.count <= 4 {
                    score += 1500  // Boost simple prepared foods
                }
            }

            return (result: item.result, score: score)
        }

        // Sort by score (highest first)
        return scored.sorted { $0.score > $1.score }.map { $0.result }
    }

    /// Search a single Algolia index using REST API
    private func searchIndex(indexName: String, query: String, hitsPerPage: Int) async throws -> [FoodSearchResult] {
        guard let url = URL(string: "\(baseURL)/\(indexName)/query") else {
            return []
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(appId, forHTTPHeaderField: "X-Algolia-Application-Id")
        request.setValue(searchKey, forHTTPHeaderField: "X-Algolia-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build search parameters
        // Split query into individual words for better multi-word matching
        let queryWords = query.split(separator: " ").map(String.init)
        let optionalWordsArray = queryWords.count > 1 ? queryWords : []

        var params: [String: Any] = [
            "query": query,
            "hitsPerPage": hitsPerPage,
            "typoTolerance": "min",  // More aggressive typo tolerance
            "getRankingInfo": true,
            "removeWordsIfNoResults": "lastWords",  // Remove words from end if no results
            "attributesToRetrieve": ["*"],  // Retrieve ALL fields including ingredients
            "advancedSyntax": false,  // Prevent AND/OR operators from being interpreted
            "ignorePlurals": true,  // Handle singular/plural variations
            "removeStopWords": true,  // Remove common words like "the", "a"
            "queryType": "prefixLast"  // Allow prefix matching on last word for partial typing
        ]

        // For multi-word queries, make all words optional (allows partial matches)
        if !optionalWordsArray.isEmpty {
            params["optionalWords"] = optionalWordsArray
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: params)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AlgoliaError.invalidResponse
        }

        return try parseResponse(data, source: indexName)
    }

    /// Parse Algolia JSON response into FoodSearchResult objects
    private func parseResponse(_ data: Data, source: String) throws -> [FoodSearchResult] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hits = json["hits"] as? [[String: Any]] else {
            throw AlgoliaError.parseError
        }

        return hits.compactMap { hit -> FoodSearchResult? in
            guard let objectID = hit["objectID"] as? String else {
                return nil
            }

            // Handle name with fallbacks - Tesco uses "title", others use "name" or "foodName"
            guard let name = (hit["name"] as? String) ?? (hit["foodName"] as? String) ?? (hit["title"] as? String),
                  !name.isEmpty else {
                return nil
            }

            // Helper to extract numeric value from multiple possible keys
            // JSONSerialization returns NSNumber which needs explicit handling
            func getNumber(_ hit: [String: Any], _ keys: String...) -> Double? {
                for key in keys {
                    guard let rawVal = hit[key] else { continue }
                    // NSNumber from JSONSerialization - use doubleValue
                    if let nsNum = rawVal as? NSNumber {
                        return nsNum.doubleValue
                    }
                    // Direct Swift types (less common from JSON)
                    if let val = rawVal as? Double { return val }
                    if let val = rawVal as? Int { return Double(val) }
                    if let val = rawVal as? String, let num = Double(val) { return num }
                }
                return nil
            }

            // Extract nutrition values with multiple fallback field names
            // (handles both camelCase from Firebase sync and snake_case from direct CSV upload)
            let calories = getNumber(hit, "calories", "energy_kcal", "energy") ?? 0
            let protein = getNumber(hit, "protein", "proteins") ?? 0
            let carbs = getNumber(hit, "carbs", "carbohydrates") ?? 0
            let fat = getNumber(hit, "fat", "fats") ?? 0
            let saturatedFat = getNumber(hit, "saturatedFat", "saturated_fat")
            let fiber = getNumber(hit, "fiber", "fibre") ?? 0
            let sugar = getNumber(hit, "sugar", "sugars") ?? 0
            let sodium = getNumber(hit, "sodium", "salt").map { $0 > 10 ? $0 : $0 * 1000 } ?? 0 // Convert g to mg if needed

            // Extract optional fields with fallback names
            let brand = (hit["brandName"] as? String) ?? (hit["brand"] as? String)

            // === SERVING SIZE PARSING - Multiple field name variants ===
            // Different Algolia indices use different field names for serving info
            // Priority: specific grams > description with grams > generic description

            // Try to get numeric serving size from various field names
            var servingSizeG = getNumber(hit,
                "servingSizeG",           // Our standard format
                "serving_size_g",         // Snake case variant
                "serving_size",           // Generic
                "servingWeight",          // Weight variant
                "serving_weight",         // Snake case weight
                "servingGrams",           // Explicit grams
                "serving_grams",          // Snake case grams
                "portionSize",            // Portion variant
                "portion_size",           // Snake case portion
                "portionWeight",          // Portion weight
                "portion_weight",         // Snake case portion weight
                "quantity_g",             // Quantity in grams
                "amount_g"                // Amount in grams
            )

            // Try to get serving description from various field names
            let servingDescription = (hit["servingSize"] as? String)
                ?? (hit["serving_description"] as? String)
                ?? (hit["servingDescription"] as? String)
                ?? (hit["serving_size_description"] as? String)
                ?? (hit["portionDescription"] as? String)
                ?? (hit["portion_description"] as? String)
                ?? (hit["serving"] as? String)
                ?? (hit["portion"] as? String)

            // If we have a description but no numeric size, try to extract grams from the description
            // e.g., "330ml can" -> 330, "1 bar (51g)" -> 51, "per 100g" -> 100
            if servingSizeG == nil, let desc = servingDescription {
                let descLower = desc.lowercased()

                // Pattern 1: "XXXml" for drinks (ml ≈ g for water-based drinks)
                if let mlMatch = descLower.range(of: "(\\d+)\\s*ml", options: .regularExpression) {
                    let mlString = String(descLower[mlMatch]).replacingOccurrences(of: "ml", with: "").trimmingCharacters(in: .whitespaces)
                    if let ml = Double(mlString) {
                        servingSizeG = ml  // ml ≈ g for drinks
                    }
                }
                // Pattern 2: "(XXXg)" - grams in parentheses
                else if let gMatch = descLower.range(of: "\\((\\d+\\.?\\d*)g\\)", options: .regularExpression) {
                    let gString = String(descLower[gMatch])
                        .replacingOccurrences(of: "(", with: "")
                        .replacingOccurrences(of: "g)", with: "")
                    if let g = Double(gString) {
                        servingSizeG = g
                    }
                }
                // Pattern 3: "XXXg" at end of string
                else if let gMatch = descLower.range(of: "(\\d+\\.?\\d*)g$", options: .regularExpression) {
                    let gString = String(descLower[gMatch]).replacingOccurrences(of: "g", with: "")
                    if let g = Double(gString) {
                        servingSizeG = g
                    }
                }
                // Pattern 4: "per 100g" - standard per 100g serving
                else if descLower.contains("per 100g") || descLower.contains("per 100 g") {
                    servingSizeG = 100
                }
            }

            // For drinks, also check for volume-based fields and convert to grams
            if servingSizeG == nil {
                if let ml = getNumber(hit, "serving_ml", "servingMl", "volume_ml", "volumeMl", "ml") {
                    servingSizeG = ml  // ml ≈ g for most drinks
                }
            }

            // NOTE: We do NOT extract serving sizes from product names (e.g., "Bread 800g")
            // as those are PACK sizes, not serving sizes. Valid serving size sources are:
            // 1. Database servingSizeG field (actual serving data from source)
            // 2. Default 100g (per-100g nutrition standard)
            // 3. Category-inferred sizes in the display layer (bread=38g, sauces=15g, etc.)
            // The display layer (FoodSearchViews.swift) handles category defaults.

            let isPerUnit = (hit["per_unit_nutrition"] as? Bool) ?? (hit["isPerUnit"] as? Bool)
            // Check multiple field name variants for verification status
            let verified = (hit["isVerified"] as? Bool) ?? (hit["verified"] as? Bool) ?? (hit["is_verified"] as? Bool) ?? false
            let barcode = hit["barcode"] as? String
            // Extract GTIN (used by Tesco products instead of barcode)
            // GTIN-14 format: 14 digits starting with 0 (e.g., "05000119018663")
            let gtin = hit["gtin"] as? String

            // Extract ingredients - VERY EXPLICIT type handling
            var ingredients: [String]? = nil

            // Get raw value and handle ALL possible types from JSONSerialization
            if let rawValue = hit["ingredients"] {
                // Try as Swift String first
                if let str = rawValue as? String, !str.isEmpty {
                    ingredients = str.components(separatedBy: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                }
                // Try as Swift Array of Strings
                else if let arr = rawValue as? [String], !arr.isEmpty {
                    ingredients = arr
                }
                // Try as NSString (explicit bridging)
                else if let nsStr = rawValue as? NSString {
                    let str = nsStr as String
                    if !str.isEmpty {
                        ingredients = str.components(separatedBy: ",")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }
                    }
                }
                // Try as NSArray of NSString
                else if let nsArr = rawValue as? NSArray {
                    ingredients = nsArr.compactMap { ($0 as? NSString) as String? }
                        .filter { !$0.isEmpty }
                }
                // Last resort - convert ANY to String via description
                else {
                    let desc = String(describing: rawValue)
                    if !desc.isEmpty && desc != "nil" && desc != "<null>" {
                                                ingredients = desc.components(separatedBy: ",")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }
                    }
                }

                            } else {
                            }

            // Extract micronutrient profile if available
            var micronutrientProfile: MicronutrientProfile? = nil
            if let profileData = hit["micronutrientProfile"] as? [String: Any] {
                micronutrientProfile = parseMicronutrientProfile(profileData)
            }

            // Extract portions array for multi-size items (e.g., McNuggets 6pc, 9pc, 20pc)
            var portions: [PortionOption]? = nil
            if let portionsString = hit["portions"] as? String,
               let portionsData = portionsString.data(using: .utf8) {
                portions = try? JSONDecoder().decode([PortionOption].self, from: portionsData)
            } else if let portionsArray = hit["portions"] as? [[String: Any]] {
                // Handle direct array format from Firestore
                portions = portionsArray.compactMap { dict -> PortionOption? in
                    guard let name = dict["name"] as? String,
                          let calories = (dict["calories"] as? Double) ?? (dict["calories"] as? Int).map({ Double($0) }),
                          let servingG = (dict["serving_g"] as? Double) ?? (dict["serving_g"] as? Int).map({ Double($0) }) else {
                        return nil
                    }
                    return PortionOption(name: name, calories: calories, serving_g: servingG)
                }
            }

            // Extract product image URL (filter out flagged images)
            let rawImageUrl = hit["imageUrl"] as? String
            let imageQuality = hit["imageQuality"] as? String
            let imageUrl: String? = {
                guard let url = rawImageUrl else { return nil }
                // Block images marked as flagged (overlay text, freshness labels, etc.)
                if imageQuality == "flagged" {
                    return nil
                }
                return url
            }()

            // Extract unit override fields (for admin panel Reports feature)
            let suggestedServingUnit = hit["suggestedServingUnit"] as? String
            let unitOverrideLocked = hit["unitOverrideLocked"] as? Bool

            // DEBUG: Log parsed values for troubleshooting Tesco data
            #if DEBUG
            let debugNameLower = name.lowercased()
            if debugNameLower.contains("jason") || debugNameLower.contains("sourdough") || (source == "tesco_products" && debugNameLower.contains("bread")) {
                print("🔍 DEBUG Algolia parse for '\(name)':")
                print("   source: \(source)")
                print("   calories: \(calories)")
                print("   servingSizeG: \(String(describing: servingSizeG))")
                print("   servingDescription: \(String(describing: servingDescription))")
                print("   isPerUnit: \(String(describing: isPerUnit))")
            }
            #endif

            // Construct full ID with source prefix to match local database/image mapping format
            // Format: "source:objectID" (e.g., "tesco_products:307760281")
            let fullId = "\(source):\(objectID)"

            return FoodSearchResult(
                id: fullId,
                name: name,
                brand: brand,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                saturatedFat: saturatedFat,
                fiber: fiber,
                sugar: sugar,
                sodium: sodium,
                servingDescription: servingDescription,
                servingSizeG: servingSizeG,
                isPerUnit: isPerUnit,
                ingredients: ingredients,
                isVerified: verified,
                barcode: barcode,
                gtin: gtin,
                micronutrientProfile: micronutrientProfile,
                portions: portions,
                source: source,
                imageUrl: imageUrl,
                suggestedServingUnit: suggestedServingUnit,
                unitOverrideLocked: unitOverrideLocked
            )
        }
    }

    /// Parse micronutrient profile from Algolia JSON
    private func parseMicronutrientProfile(_ data: [String: Any]) -> MicronutrientProfile? {
        // Extract vitamins dictionary
        var vitamins: [String: Double] = [:]
        if let vitaminsData = data["vitamins"] as? [String: Any] {
            for (key, value) in vitaminsData {
                if let doubleValue = value as? Double {
                    vitamins[key] = doubleValue
                } else if let intValue = value as? Int {
                    vitamins[key] = Double(intValue)
                }
            }
        }

        // Extract minerals dictionary
        var minerals: [String: Double] = [:]
        if let mineralsData = data["minerals"] as? [String: Any] {
            for (key, value) in mineralsData {
                if let doubleValue = value as? Double {
                    minerals[key] = doubleValue
                } else if let intValue = value as? Int {
                    minerals[key] = Double(intValue)
                }
            }
        }

        // If no vitamins or minerals, return nil
        guard !vitamins.isEmpty || !minerals.isEmpty else { return nil }

        // Build daily values dictionary with standard FDA values
        let dailyValues: [String: Double] = [
            "vitaminA": 900, "vitaminC": 90, "vitaminD": 20, "vitaminE": 15, "vitaminK": 120,
            "thiamine": 1.2, "riboflavin": 1.3, "niacin": 16, "pantothenicAcid": 5,
            "vitaminB6": 1.7, "biotin": 30, "folate": 400, "vitaminB12": 2.4, "choline": 550,
            "calcium": 1000, "iron": 18, "magnesium": 420, "phosphorus": 1250, "potassium": 4700,
            "sodium": 2300, "zinc": 11, "copper": 0.9, "manganese": 2.3, "selenium": 55,
            "chromium": 35, "molybdenum": 45, "iodine": 150
        ]

        // Create recommended intakes with default adult values
        let recommendedIntakes = RecommendedIntakes(
            age: 30,
            gender: .other,
            dailyValues: dailyValues
        )

        // Extract confidence score or default to medium
        let confidenceScore: MicronutrientConfidence
        if let confidenceString = data["confidenceScore"] as? String {
            switch confidenceString.lowercased() {
            case "high": confidenceScore = .high
            case "low": confidenceScore = .low
            case "estimated": confidenceScore = .estimated
            default: confidenceScore = .medium
            }
        } else {
            confidenceScore = .medium
        }

        return MicronutrientProfile(
            vitamins: vitamins,
            minerals: minerals,
            recommendedIntakes: recommendedIntakes,
            confidenceScore: confidenceScore
        )
    }

    // MARK: - Barcode Search
    /// Exact barcode lookup - prefers local database, falls back to Algolia
    func searchByBarcode(_ barcode: String) async throws -> FoodSearchResult? {
        let variations: [String] = {
            var v: [String] = []
            // GTIN-14 (14 digits starting with 0) → EAN-13 (remove leading 0)
            // Local database stores EAN-13 format, so check this FIRST
            if barcode.count == 14 && barcode.hasPrefix("0") {
                v.append(String(barcode.dropFirst()))  // EAN-13 (13 digits)
            }
            // EAN-13 (13 digits not starting with 0) → GTIN-14 (add leading 0)
            // Tesco's Algolia index uses GTIN-14, so add this for online search
            if barcode.count == 13 && !barcode.hasPrefix("0") { v.append("0" + barcode) }
            // Original barcode
            v.append(barcode)
            // EAN-13 with leading 0 → UPC-A (12 digits)
            if barcode.count == 13 && barcode.hasPrefix("0") { v.append(String(barcode.dropFirst())) }
            // UPC-A (12 digits) → EAN-13 and GTIN-14
            if barcode.count == 12 {
                v.append("0" + barcode)   // EAN-13
                v.append("00" + barcode)  // GTIN-14
            }
            return v
        }()

        // === PREFER LOCAL DATABASE (INSTANT) ===
        // Check local SQLite database first for instant barcode lookup
        if LocalDatabaseManager.shared.isAvailable {
            for variation in variations {
                if let localResult = LocalDatabaseManager.shared.searchByBarcode(variation) {
                    print("📱 LocalDB: Found barcode \(variation) locally")
                    return localResult
                }
            }
        }

        // If offline, no local result means no result
        if !NetworkMonitor.shared.isConnected {
            print("📴 Offline: Barcode \(barcode) not found in local database")
            return nil
        }

        // === FALL BACK TO ALGOLIA (ONLINE) ===
        // Only search online if local database didn't have the barcode
        // This handles newly added products not yet synced locally
        for variation in variations {
            if let hit = try await searchBarcodeInIndices(variation) {
                print("🌐 Algolia: Found barcode \(variation) online")
                return hit
            }
        }
        return nil
    }

    private func searchBarcodeInIndices(_ barcode: String) async throws -> FoodSearchResult? {
        // BARCODE → GTIN CONVERSION: Testing showed 26.7% match rate
        // Tesco uses GTIN-14 = "0" + EAN-13 barcode (just a leading zero!)
        // Example: Barcode 5000119018663 → GTIN 05000119018663
        let barcodeIndices: [(String, Int)] = [
            ("tesco_products", 0),       // TIER 0: Tesco UK (convert barcode → GTIN-14, official data + photos)
            ("uk_foods_cleaned", 1),     // TIER 1: UK Foods Cleaned (72k products, 100% barcode coverage)
            ("verified_foods", 2),       // TIER 2: Admin-verified foods
            ("ai_enhanced", 3),          // TIER 3: AI-enhanced foods
            ("ai_manually_added", 4),    // TIER 4: AI manually added
            ("user_added", 5),           // TIER 5: User's custom foods
            ("foods", 6),                // TIER 6: Original foods database
            ("fast_foods_database", 7)   // TIER 7: Fast foods
            // Note: consumer_foods excluded (raw ingredients don't have barcodes)
        ]

        // Search all indices in parallel but return the highest priority match
        return await withTaskGroup(of: (Int, FoodSearchResult?).self) { group in
            for (indexName, priority) in barcodeIndices {
                group.addTask {
                    let result = try? await self.searchIndexByBarcode(indexName: indexName, barcode: barcode)
                    return (priority, result)
                }
            }

            // Collect all results with their priorities
            var allResults: [(priority: Int, result: FoodSearchResult)] = []
            for await (priority, result) in group {
                if let result = result {
                    allResults.append((priority, result))
                }
            }

            // Return the result with lowest priority number (Tesco = 0, highest priority)
            if let best = allResults.min(by: { $0.priority < $1.priority }) {
                return best.result
            }
            return nil
        }
    }

    private func searchIndexByBarcode(indexName: String, barcode: String) async throws -> FoodSearchResult? {
        guard let url = URL(string: "\(baseURL)/\(indexName)/query") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(appId, forHTTPHeaderField: "X-Algolia-Application-Id")
        request.setValue(searchKey, forHTTPHeaderField: "X-Algolia-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // GTIN CONVERSION: Tesco uses GTIN-14 (0 + EAN-13)
        // Convert EAN-13 barcode to GTIN-14 for Tesco searches
        let searchQuery: String
        if indexName == "tesco_products" && barcode.count == 13 {
            // Add leading zero to convert EAN-13 → GTIN-14
            searchQuery = "0" + barcode
        } else if indexName == "tesco_products" && barcode.count == 12 {
            // UPC-A → GTIN-14 (add two leading zeros)
            searchQuery = "00" + barcode
        } else {
            searchQuery = barcode
        }

        // Use text query search instead of filters since barcode may not be a filterable attribute
        // Barcode is numeric so it will match exactly when searched as text
        let params: [String: Any] = [
            "query": searchQuery,
            "hitsPerPage": 5,  // Get a few results in case barcode appears in other fields
            "getRankingInfo": false,
            "attributesToRetrieve": ["*"]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: params)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AlgoliaError.invalidResponse
        }

        let results = try parseResponse(data, source: indexName)

        // Find exact match - check both barcode and gtin fields
        // Tesco products use "gtin" field (GTIN-14), other sources use "barcode" (EAN-13/UPC-A)
        // searchQuery is already converted to GTIN-14 for Tesco searches
        let exactMatch = results.first { result in
            result.barcode == searchQuery || result.gtin == searchQuery
        }

        return exactMatch
    }

    /// Clear the search cache
    func clearCache() {
        searchCache.removeAllObjects()
            }

    /// Pre-warm cache with popular searches
    func prewarmCache() async {
        let popularSearches = ["chicken", "milk", "bread", "cheese", "apple", "banana", "rice", "egg"]

        
        for search in popularSearches {
            do {
                _ = try await self.search(query: search)
            } catch {
                            }
        }

            }
}

// MARK: - Cache Entry

private class SearchCacheEntry {
    let results: [FoodSearchResult]
    let timestamp: Date

    init(results: [FoodSearchResult], timestamp: Date) {
        self.results = results
        self.timestamp = timestamp
    }
}

// MARK: - Error Types

enum AlgoliaError: Error, LocalizedError {
    case invalidResponse
    case parseError

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Algolia API"
        case .parseError:
            return "Failed to parse Algolia response"
        }
    }
}
