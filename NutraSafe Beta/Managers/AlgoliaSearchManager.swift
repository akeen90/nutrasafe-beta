//
//  AlgoliaSearchManager.swift
//  NutraSafe Beta
//
//  Direct Algolia REST API integration for instant search
//  Uses URLSession instead of SDK for reliability and ~300ms faster than Cloud Functions
//

import Foundation

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

        // Search all indices in parallel
        let results = try await searchMultipleIndices(query: trimmedQuery, hitsPerPage: hitsPerPage)

        #if DEBUG
        let elapsed = Date().timeIntervalSince(startTime) * 1000
        print("⚡️ Algolia Direct REST: Found \(results.count) results in \(Int(elapsed))ms")
        #endif

        // Cache results
        searchCache.setObject(
            SearchCacheEntry(results: results, timestamp: Date()),
            forKey: cacheKey
        )

        return results
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
                score += 3000
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

            // Bonus if brand contains query (e.g., searching "mcdonalds")
            if let brand = item.result.brand?.lowercased(),
               brand.contains(queryLower) || queryLower.contains(brand.replacingOccurrences(of: "'", with: "")) {
                score += 1000
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
            "getRankingInfo": true
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
            let verified = (hit["verified"] as? Bool) ?? false
            let barcode = hit["barcode"] as? String

            // Extract ingredients array
            var ingredients: [String]? = nil
            if let ingredientsArray = hit["ingredients"] as? [String] {
                ingredients = ingredientsArray
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
                barcode: barcode
            )
        }
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
