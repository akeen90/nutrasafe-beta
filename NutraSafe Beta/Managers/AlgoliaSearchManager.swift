//
//  AlgoliaSearchManager.swift
//  NutraSafe Beta
//
//  Direct Algolia REST API integration for instant search
//  Uses URLSession instead of SDK for reliability and ~300ms faster than Cloud Functions
//

import Foundation

// MARK: - Brand Synonym Groups & Processed Food Detection

/// Groups of brand synonyms - first item is the canonical name
/// When searching for any synonym, results for all synonyms in the group are returned
let brandSynonymGroups: [[String]] = [
    // Coca-Cola variants
    ["coca-cola", "coca cola", "cocacola", "coke", "diet coke", "coke zero", "cherry coke", "coca-cola zero", "coke classic"],
    // Pepsi variants
    ["pepsi", "pepsico", "pepsi-cola", "pepsi cola", "diet pepsi", "pepsi max", "pepsi zero"],
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
    // Dr Pepper variants
    ["dr pepper", "dr. pepper", "drpepper", "doctor pepper"],
    // Mountain Dew variants
    ["mountain dew", "mtn dew", "mountaindew"],
    // Red Bull variants
    ["red bull", "redbull"],
    // Monster Energy variants
    ["monster", "monster energy", "monster drink"],
    // Sprite variants
    ["sprite", "sprite zero"],
    // Fanta variants
    ["fanta", "fanta orange"],
    // 7UP variants
    ["7up", "7-up", "seven up", "sevenup"],
    // Lucozade variants
    ["lucozade", "lucozade energy", "lucozade sport"],
    // Irn-Bru variants
    ["irn-bru", "irn bru", "irnbru", "iron brew"],
    // Cadbury variants
    ["cadbury", "cadbury's", "cadburys"],
    // Nestle variants
    ["nestle", "nestlé", "nestle's"],
    // Mars variants
    ["mars", "mars bar"],
    // Kit Kat variants
    ["kit kat", "kitkat", "kit-kat"],
    // M&Ms variants
    ["m&m's", "m&ms", "mms", "m and ms"],
    // Haribo variants
    ["haribo", "haribo sweets"],
    // Walkers variants
    ["walkers", "walkers crisps", "walker's"],
    // Lays variants
    ["lays", "lay's"],
    // Pringles variants
    ["pringles", "pringle's"],
    // Doritos variants
    ["doritos", "dorito"],
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
    // Gatorade variants
    ["gatorade", "gator aid"],
    // Powerade variants
    ["powerade", "power ade"],
    // Prime variants
    ["prime", "prime hydration", "prime drink"],
    // Tropicana variants
    ["tropicana", "tropicana juice"],
    // Innocent variants
    ["innocent", "innocent smoothies", "innocent drinks"],
    // Subway
    ["subway"],
    // Chipotle
    ["chipotle"],
]

/// All recognised fast food and processed food brands - NutraSafe grade hidden for these
let processedFoodBrands: Set<String> = {
    var brands = Set<String>()

    // Add all synonyms from synonym groups
    for group in brandSynonymGroups {
        for brand in group {
            brands.insert(brand)
        }
    }

    // Add additional brands not in synonym groups
    let additionalBrands = [
        // Fast food chains
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
        // Energy drinks
        "rockstar", "rockstar energy",
        // Confectionery
        "snickers", "twix", "milky way", "bounty", "maltesers",
        "galaxy", "dairy milk",
        "hershey", "hershey's", "hersheys",
        "reese's", "reeses",
        "skittles", "starburst", "swizzels",
        "rowntree's", "rowntrees",
        "fruit pastilles", "fruit gums", "wine gums", "jelly babies",
        "smarties", "aero", "crunchie", "flake", "twirl", "wispa",
        "double decker", "boost", "picnic", "curly wurly", "fudge",
        "timeout", "yorkie", "lion bar", "toffee crisp", "drifter",
        // Crisps/snacks
        "cheetos", "wotsits", "quavers", "monster munch",
        "hula hoops", "skips", "frazzles", "squares", "nik naks",
        "kettle chips", "kettle", "tyrells", "tyrrells",
        "sensations", "mccoys", "mccoy's",
        // Other drinks
        "ribena", "vimto", "tango", "oasis", "robinsons",
        "snapple", "lipton", "lipton ice tea",
        "arizona", "arizona iced tea", "vita coco",
        "naked juice", "naked",
    ]

    for brand in additionalBrands {
        brands.insert(brand)
    }

    return brands
}()

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

/// Check if a brand/name is a recognised processed food brand
func isProcessedFoodBrand(brand: String?, name: String) -> Bool {
    let brandLower = brand?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let nameLower = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

    let textsToCheck = [brandLower, nameLower].filter { !$0.isEmpty }

    for text in textsToCheck {
        if processedFoodBrands.contains(text) {
            return true
        }
        for brand in processedFoodBrands {
            if text.contains(brand) {
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

    // Algolia credentials - search-only key is safe for client-side use
    private let appId = "WK0TIF84M2"
    private let searchKey = "577cc4ee3fed660318917bbb54abfb2e"

    // Base URL for Algolia API
    private var baseURL: String { "https://\(appId)-dsn.algolia.net/1/indexes" }

    // Index names - foods is main database, user_added for custom items
    private let indices = [
        ("foods", 0),            // Main database - highest priority
        ("user_added", 1),       // User's custom foods
        ("ai_enhanced", 2),
        ("ai_manually_added", 3),
    ]

    // Cache for search results
    private let searchCache = NSCache<NSString, SearchCacheEntry>()
    private let cacheExpirationSeconds: TimeInterval = 300 // 5 minutes

    // Shared URLSession for all requests
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10 // 10 second timeout
        config.timeoutIntervalForResource = 30
        config.waitsForConnectivity = true
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
                #if DEBUG
                print("⚡️ Algolia Cache HIT for '\(query)' (\(Int(age))s old)")
                #endif
                return cached.results
            } else {
                searchCache.removeObject(forKey: cacheKey)
            }
        }

        #if DEBUG
        let startTime = Date()
        print("🔍 Algolia Direct REST: Searching '\(query)'...")
        #endif

        // Expand query with brand synonyms (e.g., "coke" -> also search "coca-cola")
        let expandedQueries = expandSearchQuery(trimmedQuery)

        #if DEBUG
        if expandedQueries.count > 1 {
            print("🔀 Brand synonym expansion: \(expandedQueries)")
        }
        #endif

        // Add word order variants for 2-word queries
        var allSearchQueries: [String] = []
        for query in expandedQueries {
            if shouldUseFlexibleWordOrder(query) {
                let variants = generateWordOrderVariants(query)
                allSearchQueries.append(contentsOf: variants)
                #if DEBUG
                if variants.count > 1 {
                    print("🔄 Word order variants for '\(query)': \(variants)")
                }
                #endif
            } else {
                allSearchQueries.append(query)
            }
        }

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
                        #if DEBUG
                        print("⚠️ Search failed for query '\(searchQuery)': \(error)")
                        #endif
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

        #if DEBUG
        let elapsed = Date().timeIntervalSince(startTime) * 1000
        print("⚡️ Algolia Direct REST: Found \(rankedResults.count) results in \(Int(elapsed))ms")
        #endif

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
            // All query words appear in name (e.g., "boiled egg" finds "Egg Boiled")
            else if queryWords.allSatisfy({ queryWord in
                nameWords.contains { $0.hasPrefix(queryWord) || $0 == queryWord }
            }) {
                score += 4500

                // BONUS: If name has ONLY the query words (reversed match)
                if nameWords.count == queryWords.count {
                    score += 2000
                }
            }
            // Name/brand contains original query as substring
            else if nameLower.contains(queryLower) || brandLower.contains(queryLower) {
                score += 3000
            }
            // Matches via synonym (still good, but lower priority)
            else {
                score += 1000
            }

            // Strong bonus if brand matches original query (for brand searches like "mcdonalds")
            if let brand = result.brand?.lowercased() {
                let normalizedBrand = brand.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "'", with: "")
                let normalizedQuery = queryLower.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "'", with: "")

                // Exact brand match
                if normalizedBrand == normalizedQuery {
                    score += 8000
                }
                // Brand starts with query
                else if normalizedBrand.hasPrefix(normalizedQuery) {
                    score += 6000
                }
                // Query is a known brand synonym
                else if let canonical = synonymToCanonical[normalizedQuery],
                        normalizedBrand.contains(canonical.replacingOccurrences(of: "'", with: "")) {
                    score += 5500
                }
                // Brand contains query
                else if normalizedBrand.contains(normalizedQuery) {
                    score += 3000
                }
            }

            // Bonus for shorter names (more specific)
            score += max(0, 500 - result.name.count * 10)

            // Bonus for verified items
            if result.isVerified {
                score += 200
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
                        #if DEBUG
                        print("⚠️ Algolia: Failed to search \(indexName): \(error.localizedDescription)")
                        #endif
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

        #if DEBUG
        if let first = rankedResults.first {
            print("🎯 Top result for '\(query)': \(first.name) (score-based ranking)")
        }
        #endif

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
            // All query words appear in name
            else if queryWords.allSatisfy({ queryWord in
                nameWords.contains { $0.hasPrefix(queryWord) || $0 == queryWord }
            }) {
                // Higher score for all words present
                score += 4500

                // BONUS: If name has ONLY the query words (e.g., "Egg Boiled" for "boiled egg")
                // This catches reversed word order matches
                if nameWords.count == queryWords.count {
                    score += 2000  // Big bonus for exact word set match
                }
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

            // Small bonus for source priority (user_added gets slight boost)
            // But this is now secondary to relevance
            score += (4 - item.sourcePriority) * 50

            // Strong bonus if brand matches query (e.g., searching "mcdonalds")
            if let brand = item.result.brand?.lowercased() {
                let normalizedBrand = brand.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "'", with: "")
                let normalizedQuery = queryLower.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "'", with: "")

                // Exact brand match (highest brand priority)
                if normalizedBrand == normalizedQuery {
                    score += 8000
                }
                // Brand starts with query
                else if normalizedBrand.hasPrefix(normalizedQuery) {
                    score += 6000
                }
                // Query is a known brand synonym that matches this brand
                else if let canonical = synonymToCanonical[normalizedQuery],
                        normalizedBrand.contains(canonical.replacingOccurrences(of: "'", with: "")) {
                    score += 5500
                }
                // Brand contains query as substring
                else if normalizedBrand.contains(normalizedQuery) || normalizedQuery.contains(normalizedBrand) {
                    score += 3000
                }
            }

            return (result: item.result, score: score)
        }

        // Sort by score (highest first)
        return scored.sorted { $0.score > $1.score }.map { $0.result }
    }

    /// Search a single Algolia index using REST API
    private func searchIndex(indexName: String, query: String, hitsPerPage: Int) async throws -> [FoodSearchResult] {
        let url = URL(string: "\(baseURL)/\(indexName)/query")!

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
            "removeWordsIfNoResults": "allOptional"  // Try different word combinations if no results
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

            // Extract nutrition values with defaults
            let calories = (hit["calories"] as? Double) ?? (hit["calories"] as? Int).map { Double($0) } ?? 0
            let protein = (hit["protein"] as? Double) ?? (hit["protein"] as? Int).map { Double($0) } ?? 0
            let carbs = (hit["carbs"] as? Double) ?? (hit["carbs"] as? Int).map { Double($0) } ?? 0
            let fat = (hit["fat"] as? Double) ?? (hit["fat"] as? Int).map { Double($0) } ?? 0
            let fiber = (hit["fiber"] as? Double) ?? (hit["fiber"] as? Int).map { Double($0) } ?? 0
            let sugar = (hit["sugar"] as? Double) ?? (hit["sugar"] as? Int).map { Double($0) } ?? 0
            let sodium = (hit["sodium"] as? Double) ?? (hit["sodium"] as? Int).map { Double($0) } ?? 0

            // Extract optional fields
            let brand = hit["brandName"] as? String
            let servingDescription = hit["servingSize"] as? String
            let servingSizeG = (hit["servingSizeG"] as? Double) ?? (hit["servingSizeG"] as? Int).map { Double($0) }
            let isPerUnit = hit["per_unit_nutrition"] as? Bool
            // Check both isVerified and verified fields for compatibility
            let verified = (hit["isVerified"] as? Bool) ?? (hit["verified"] as? Bool) ?? false
            let barcode = hit["barcode"] as? String

            // Extract ingredients array
            var ingredients: [String]? = nil
            if let ingredientsArray = hit["ingredients"] as? [String] {
                ingredients = ingredientsArray
            }

            // Extract micronutrient profile if available
            var micronutrientProfile: MicronutrientProfile? = nil
            if let profileData = hit["micronutrientProfile"] as? [String: Any] {
                micronutrientProfile = parseMicronutrientProfile(profileData)
            }

            return FoodSearchResult(
                id: objectID,
                name: name,
                brand: brand,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                fiber: fiber,
                sugar: sugar,
                sodium: sodium,
                servingDescription: servingDescription,
                servingSizeG: servingSizeG,
                isPerUnit: isPerUnit,
                ingredients: ingredients,
                isVerified: verified,
                barcode: barcode,
                micronutrientProfile: micronutrientProfile
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
        // Search all indices in priority order; return first exact match
        for (indexName, _) in indices {
            if let result = try await searchIndexByBarcode(indexName: indexName, barcode: barcode) {
                return result
            }
        }
        return nil
    }

    private func searchIndexByBarcode(indexName: String, barcode: String) async throws -> FoodSearchResult? {
        let url = URL(string: "\(baseURL)/\(indexName)/query")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(appId, forHTTPHeaderField: "X-Algolia-Application-Id")
        request.setValue(searchKey, forHTTPHeaderField: "X-Algolia-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let params: [String: Any] = [
            "filters": "barcode:\(barcode)",
            "hitsPerPage": 1,
            "getRankingInfo": false
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: params)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AlgoliaError.invalidResponse
        }

        let results = try parseResponse(data, source: indexName)
        return results.first
    }

    /// Clear the search cache
    func clearCache() {
        searchCache.removeAllObjects()
        #if DEBUG
        print("🗑️ Algolia cache cleared")
        #endif
    }

    /// Pre-warm cache with popular searches
    func prewarmCache() async {
        let popularSearches = ["chicken", "milk", "bread", "cheese", "apple", "banana", "rice", "egg"]

        #if DEBUG
        print("🔥 Pre-warming Algolia cache...")
        #endif

        for search in popularSearches {
            do {
                _ = try await self.search(query: search)
            } catch {
                #if DEBUG
                print("⚠️ Failed to prewarm '\(search)': \(error)")
                #endif
            }
        }

        #if DEBUG
        print("✅ Algolia cache pre-warming complete")
        #endif
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
