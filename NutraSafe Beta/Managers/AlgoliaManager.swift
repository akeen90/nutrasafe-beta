import Foundation
import AlgoliaSearchClient

/// Manager for Algolia search integration
/// Provides fast, instant search across all food databases
class AlgoliaManager: ObservableObject {

    // MARK: - Configuration
    // These values are safe to expose in the iOS app
    private let applicationID = "WK0TIF84M2"
    private let searchAPIKey = "577cc4ee3fed660318917bbb54abfb2e" // Search-Only API Key

    // MARK: - Properties
    private let client: SearchClient

    // Index names
    private let verifiedFoodsIndex = "verified_foods"
    private let foodsIndex = "foods"
    private let manualFoodsIndex = "manual_foods"

    // MARK: - Initialization
    init() {
        self.client = SearchClient(appID: applicationID, apiKey: searchAPIKey)
    }

    // MARK: - Search Methods

    /// Search for foods across all indices
    /// - Parameters:
    ///   - query: Search query string
    ///   - hitsPerPage: Number of results to return (default: 20)
    ///   - filters: Optional Algolia filters for refined search
    /// - Returns: Array of food search results
    func searchFoods(query: String, hitsPerPage: Int = 20, filters: String? = nil) async throws -> [AlgoliaFood] {
        guard !query.isEmpty else {
            return []
        }

        // Search across all indices
        let searchQuery = SearchMethodParams.SearchQueriesParams(
            requests: [
                SearchMethodParams.SearchQueriesParams.SearchQuery(
                    indexName: verifiedFoodsIndex,
                    query: Query(query: query, hitsPerPage: hitsPerPage, filters: filters)
                ),
                SearchMethodParams.SearchQueriesParams.SearchQuery(
                    indexName: foodsIndex,
                    query: Query(query: query, hitsPerPage: hitsPerPage, filters: filters)
                ),
                SearchMethodParams.SearchQueriesParams.SearchQuery(
                    indexName: manualFoodsIndex,
                    query: Query(query: query, hitsPerPage: hitsPerPage, filters: filters)
                )
            ]
        )

        let response = try await client.search(searchMethodParams: searchQuery)

        // Parse and combine results
        var foods: [AlgoliaFood] = []

        if let results = response.results as? [SearchResponse] {
            for searchResponse in results {
                if let hits = searchResponse.hits {
                    for hit in hits {
                        if let foodDict = hit as? [String: Any],
                           let food = AlgoliaFood(dictionary: foodDict) {
                            foods.append(food)
                        }
                    }
                }
            }
        }

        // Remove duplicates (same objectID)
        var seen = Set<String>()
        return foods.filter { food in
            guard !seen.contains(food.id) else { return false }
            seen.insert(food.id)
            return true
        }.prefix(hitsPerPage).map { $0 }
    }

    /// Search with autocomplete (for search-as-you-type)
    /// - Parameter query: Partial query string
    /// - Returns: Quick search results (limited to 5 items)
    func autocomplete(query: String) async throws -> [AlgoliaFood] {
        return try await searchFoods(query: query, hitsPerPage: 5)
    }

    /// Search by barcode
    /// - Parameter barcode: Product barcode
    /// - Returns: Food matching the barcode, if found
    func searchByBarcode(_ barcode: String) async throws -> AlgoliaFood? {
        let foods = try await searchFoods(
            query: barcode,
            hitsPerPage: 1,
            filters: "barcode:\(barcode)"
        )
        return foods.first
    }

    /// Search with filters (e.g., high protein, low carb)
    /// - Parameters:
    ///   - query: Search query
    ///   - minProtein: Minimum protein in grams
    ///   - maxCarbs: Maximum carbs in grams
    ///   - verified: Only show verified foods
    /// - Returns: Filtered search results
    func searchWithFilters(
        query: String,
        minProtein: Double? = nil,
        maxCarbs: Double? = nil,
        verified: Bool? = nil
    ) async throws -> [AlgoliaFood] {
        var filterParts: [String] = []

        if let minProtein = minProtein {
            filterParts.append("protein >= \(minProtein)")
        }
        if let maxCarbs = maxCarbs {
            filterParts.append("carbs <= \(maxCarbs)")
        }
        if let verified = verified {
            filterParts.append("verified:\(verified)")
        }

        let filters = filterParts.isEmpty ? nil : filterParts.joined(separator: " AND ")

        return try await searchFoods(query: query, filters: filters)
    }
}

// MARK: - AlgoliaFood Model

/// Represents a food item from Algolia search results
struct AlgoliaFood: Identifiable, Codable {
    let id: String // objectID
    let name: String
    let brandName: String?
    let ingredients: String?
    let barcode: String?

    // Nutrition
    let calories: Double?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let fiber: Double?
    let sugar: Double?
    let sodium: Double?

    // Metadata
    let servingSize: String?
    let servingSizeG: Double?
    let category: String?
    let source: String?
    let verified: Bool?

    // Allergens
    let allergens: [String]?
    let additives: [String]?

    // Scores
    let nutritionGrade: String?
    let score: Double?

    enum CodingKeys: String, CodingKey {
        case id = "objectID"
        case name, brandName, ingredients, barcode
        case calories, protein, carbs, fat, fiber, sugar, sodium
        case servingSize, servingSizeG, category, source, verified
        case allergens, additives
        case nutritionGrade, score
    }

    /// Initialize from dictionary (Algolia response)
    init?(dictionary: [String: Any]) {
        guard let objectID = dictionary["objectID"] as? String,
              let name = dictionary["name"] as? String else {
            return nil
        }

        self.id = objectID
        self.name = name
        self.brandName = dictionary["brandName"] as? String
        self.ingredients = dictionary["ingredients"] as? String
        self.barcode = dictionary["barcode"] as? String

        self.calories = dictionary["calories"] as? Double
        self.protein = dictionary["protein"] as? Double
        self.carbs = dictionary["carbs"] as? Double
        self.fat = dictionary["fat"] as? Double
        self.fiber = dictionary["fiber"] as? Double
        self.sugar = dictionary["sugar"] as? Double
        self.sodium = dictionary["sodium"] as? Double

        self.servingSize = dictionary["servingSize"] as? String
        self.servingSizeG = dictionary["servingSizeG"] as? Double
        self.category = dictionary["category"] as? String
        self.source = dictionary["source"] as? String
        self.verified = dictionary["verified"] as? Bool

        self.allergens = dictionary["allergens"] as? [String]
        self.additives = dictionary["additives"] as? [String]

        self.nutritionGrade = dictionary["nutritionGrade"] as? String
        self.score = dictionary["score"] as? Double
    }
}
