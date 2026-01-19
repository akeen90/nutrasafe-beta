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

/// Expand a search query to include brand synonyms
func expandSearchQuery(_ query: String) -> [String] {
    let queryLower = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    var expandedQueries = [query]

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
    // TIER 1: Tesco products (official UK supermarket data - highest quality)
    // TIER 2: Other UK/verified sources
    // Results are deduplicated, so items from lower-priority indices only appear if not in higher-priority ones
    private var indices: [(String, Int)] {
        return [
            ("tesco_products", 0),       // TIER 1: Tesco UK (official supermarket data)
            ("uk_foods_cleaned", 1),     // UK Foods Cleaned (59k records)
            ("foods", 2),                // Original foods (fallback - fills gaps)
            ("fast_foods_database", 3),  // Fast Food restaurants
            ("generic_database", 4),     // Generic food items
            ("user_added", 5),           // User's custom foods
        ]
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

    /// Search all food indices directly via Algolia REST API
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

        // Expand query with brand synonyms (e.g., "coke" -> also search "coca-cola")
        let expandedQueries = expandSearchQuery(trimmedQuery)

        // Add word order variants for 2-word queries
        // PERFORMANCE: Use Set to deduplicate queries before executing them
        var querySet = Set<String>()
        for query in expandedQueries {
            if shouldUseFlexibleWordOrder(query) {
                let variants = generateWordOrderVariants(query)
                for variant in variants {
                    querySet.insert(variant.lowercased())
                }
            } else {
                querySet.insert(query.lowercased())
            }
        }
        let allSearchQueries = Array(querySet)

        // PERFORMANCE: Search all queries in parallel instead of sequentially
        // This reduces search time from (N x 200ms) to ~200ms for N query variants
        var allResults: [FoodSearchResult] = []
        var seenIds = Set<String>()

        await withTaskGroup(of: [FoodSearchResult].self) { group in
            for searchQuery in allSearchQueries {
                group.addTask {
                    do {
                        return try await self.searchMultipleIndices(query: searchQuery, hitsPerPage: hitsPerPage)
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

        // Re-rank combined results
        let rankedResults = rankResultsForSynonymSearch(allResults, originalQuery: trimmedQuery, hitsPerPage: hitsPerPage)

        // Cache results
        searchCache.setObject(
            SearchCacheEntry(results: rankedResults, timestamp: Date()),
            forKey: cacheKey
        )

        return rankedResults
    }

    /// Re-rank results from synonym-expanded searches, prioritizing original query matches
    private func rankResultsForSynonymSearch(_ results: [FoodSearchResult], originalQuery: String, hitsPerPage: Int) -> [FoodSearchResult] {
        let queryLower = originalQuery.lowercased()
        let queryWords = Set(queryLower.split(separator: " ").map { String($0) })

        let scored = results.map { result -> (result: FoodSearchResult, score: Int) in
            let nameLower = result.name.lowercased()
            let nameWords = Set(nameLower.split(separator: " ").map { String($0) })
            let brandLower = result.brand?.lowercased() ?? ""

            var score = 0

            // Exact match with original query (highest priority)
            if nameLower == queryLower || brandLower == queryLower {
                score += 10000
            }
            // Name/brand starts with original query
            else if nameLower.hasPrefix(queryLower) || brandLower.hasPrefix(queryLower) {
                score += 5000
            }
            // PRIORITY: Query word appears as EXACT COMPLETE WORD in name
            // e.g., "milk" matches "Whole Milk", "Semi-Skimmed Milk" but NOT "Milkybar"
            else if queryWords.count == 1, nameWords.contains(queryLower) {
                score += 6000  // Higher than prefix match - exact word is better
                // Extra bonus if it's a short/generic name like "Whole Milk" (2-3 words)
                if nameWords.count <= 3 {
                    score += 1500
                }
            }
            // All query words appear in name (e.g., "boiled egg" finds "Egg Boiled")
            else if queryWords.allSatisfy({ queryWord in
                nameWords.contains { $0.hasPrefix(queryWord) || $0 == queryWord }
            }) {
                // Check if ALL query words are EXACT matches (not just prefixes)
                let allExactWordMatches = queryWords.allSatisfy({ queryWord in
                    nameWords.contains(queryWord)
                })

                if allExactWordMatches {
                    score += 5500  // Higher for exact word matches
                } else {
                    score += 4500  // Prefix matches
                }

                // BONUS: If name has ONLY the query words (reversed match)
                if nameWords.count == queryWords.count {
                    score += 2000
                }
            }
            // Name/brand contains original query as substring (but not as complete word)
            // e.g., "milk" in "Milkybar" - should be LOWER priority
            else if nameLower.contains(queryLower) || brandLower.contains(queryLower) {
                score += 1500  // Reduced from 3000 - substring matches are less relevant
            }
            // Matches via synonym (still good, but lower priority)
            else {
                score += 1000
            }

            // Brand bonus - only give high bonus when query is primarily a brand search
            // Prioritize name matches over brand-only matches
            if let brand = result.brand?.lowercased() {
                let normalizedBrand = brand.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "'", with: "")
                let normalizedQuery = queryLower.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "'", with: "")

                // Check if query words primarily match the food NAME (not just brand)
                // e.g., "mars bar" - "mars" and "bar" both in name = name focused search
                let queryWordsInName = queryWords.filter { queryWord in
                    nameWords.contains(queryWord) || nameWords.contains(where: { $0.hasPrefix(queryWord) })
                }.count
                let queryWordsInBrand = queryWords.filter { normalizedBrand.contains($0) }.count
                let isNameFocusedSearch = queryWordsInName >= queryWordsInBrand && queryWordsInName > 0

                // Only give high brand bonus when query is a pure brand search
                if normalizedBrand == normalizedQuery && !isNameFocusedSearch {
                    // Pure brand search like "mars" when looking at Revels by Mars
                    score += 8000
                }
                else if normalizedBrand == normalizedQuery && isNameFocusedSearch {
                    // Brand matches but name also matches - reduce brand bonus
                    score += 2000
                }
                else if normalizedBrand.hasPrefix(normalizedQuery) && !isNameFocusedSearch {
                    score += 4000
                }
                else if let canonical = synonymToCanonical[normalizedQuery],
                        normalizedBrand.contains(canonical.replacingOccurrences(of: "'", with: "")),
                        !isNameFocusedSearch {
                    score += 3500
                }
                else if normalizedBrand.contains(normalizedQuery) && !isNameFocusedSearch {
                    score += 1000
                }
            }

            // Bonus for shorter names (more specific)
            score += max(0, 500 - result.name.count * 10)

            // Bonus for verified items
            if result.isVerified {
                score += 200
            }

            // TIER 1 PRIORITY: Tesco products get significant boost (official UK supermarket data)
            if let source = result.source {
                if source == "tesco_products" {
                    score += 300  // Tesco tier 1 boost
                } else if source == "uk_foods_cleaned" {
                    score += 250  // UK Foods tier 2 boost
                }
            }

            // RAW/WHOLE FOOD PRIORITY: When searching single words like "apple", "banana",
            // prioritize raw/whole versions over processed (juice, pie, dried, etc.)
            if queryWords.count == 1 && queryLower.count >= 3 {
                let rawFoodIndicators: Set<String> = ["large", "medium", "small", "raw", "fresh", "whole", "ripe"]
                let processedIndicators: Set<String> = ["juice", "pie", "cake", "bread", "chips", "crisps", "dried",
                    "smoothie", "jam", "jelly", "sauce", "syrup", "yogurt", "yoghurt", "flavour", "flavor",
                    "candy", "sweet", "bar", "drink", "cordial", "squash", "concentrate", "puree", "purée",
                    "crumble", "tart", "turnover", "strudel", "compote", "preserve", "spread", "butter",
                    "ice", "cream", "sorbet", "frozen", "canned", "tinned", "cocktail", "wine", "cider", "vinegar"]

                let hasRawIndicator = nameWords.contains { rawFoodIndicators.contains($0) }
                let hasProcessedIndicator = nameWords.contains { processedIndicators.contains($0) }
                let startsWithQuery = nameLower.hasPrefix(queryLower)

                // Big boost for raw foods that start with the query (e.g., "Apple (Large)" for "apple")
                if startsWithQuery && hasRawIndicator && !hasProcessedIndicator {
                    score += 3000
                }
                // Boost for simple names starting with query (e.g., "Apple" or "Apple Raw")
                else if startsWithQuery && nameWords.count <= 3 && !hasProcessedIndicator {
                    score += 2500
                }
                // Penalty for processed foods
                else if hasProcessedIndicator {
                    score -= 1000
                }
            }

            return (result: result, score: score)
        }

        return Array(scored.sorted { $0.score > $1.score }.map { $0.result }.prefix(hitsPerPage))
    }

    /// Search multiple indices in parallel using TaskGroup
    private func searchMultipleIndices(query: String, hitsPerPage: Int) async throws -> [FoodSearchResult] {
        var allResults: [(result: FoodSearchResult, sourcePriority: Int)] = []
        var seenIds = Set<String>()

        // Search all indices in parallel
        await withTaskGroup(of: (Int, [FoodSearchResult]).self) { group in
            for (indexName, priority) in indices {
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
        let params: [String: Any] = [
            "query": query,
            "hitsPerPage": hitsPerPage,
            "typoTolerance": true,
            "getRankingInfo": true,
            "optionalWords": query,  // Makes word order more flexible for 3+ words
            "removeWordsIfNoResults": "allOptional",  // Try different word combinations if no results
            "attributesToRetrieve": ["*"]  // Retrieve ALL fields including ingredients
        ]

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
            guard let objectID = hit["objectID"] as? String,
                  let name = hit["name"] as? String else {
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
            let servingDescription = (hit["servingSize"] as? String) ?? (hit["serving_description"] as? String)
            let servingSizeG = getNumber(hit, "servingSizeG", "serving_size_g", "serving_size")
            let isPerUnit = (hit["per_unit_nutrition"] as? Bool) ?? (hit["isPerUnit"] as? Bool)
            // Check multiple field name variants for verification status
            let verified = (hit["isVerified"] as? Bool) ?? (hit["verified"] as? Bool) ?? (hit["is_verified"] as? Bool) ?? false
            let barcode = hit["barcode"] as? String

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

            return FoodSearchResult(
                id: objectID,
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
                micronutrientProfile: micronutrientProfile,
                portions: portions,
                source: source
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
    /// Exact barcode lookup across indices using Algolia filters
    func searchByBarcode(_ barcode: String) async throws -> FoodSearchResult? {
        let variations: [String] = {
            var v = [barcode]
            if barcode.count == 13 && barcode.hasPrefix("0") { v.append(String(barcode.dropFirst())) }
            if barcode.count == 12 { v.append("0" + barcode) }
            return v
        }()

        for variation in variations {
            if let hit = try await searchBarcodeInIndices(variation) {
                return hit
            }
        }
        return nil
    }

    private func searchBarcodeInIndices(_ barcode: String) async throws -> FoodSearchResult? {
        // TIER-BASED BARCODE SEARCH: Prioritize Tesco, then UK Foods, then others
        // Search all indices in parallel but return the highest priority match
        return await withTaskGroup(of: (Int, FoodSearchResult?).self) { group in
            for (indexName, priority) in indices {
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

        // Use text query search instead of filters since barcode may not be a filterable attribute
        // Barcode is numeric so it will match exactly when searched as text
        let params: [String: Any] = [
            "query": barcode,
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

        // Find exact barcode match (text query may return multiple results)
        let exactMatch = results.first { $0.barcode == barcode }

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
