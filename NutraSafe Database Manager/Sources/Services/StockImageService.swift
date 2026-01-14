//
//  StockImageService.swift
//  NutraSafe Database Manager
//
//  Service for fetching product images using SerpAPI Google Images
//  Can find actual branded products like "Heinz Ketchup white background"
//

import Foundation

@MainActor
class StockImageService: ObservableObject {
    static let shared = StockImageService()

    @Published var isLoading = false
    @Published var lastError: String?
    @Published var searchResults: [ProductImage] = []
    @Published var remainingSearches: Int?

    // API Key - stored in UserDefaults
    private var serpApiKey: String {
        UserDefaults.standard.string(forKey: "serpapi_key") ?? ""
    }

    var hasApiKey: Bool { !serpApiKey.isEmpty }

    private init() {}

    // MARK: - API Key Management

    func setApiKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "serpapi_key")
    }

    // MARK: - Search for Product Images

    /// Search Google Images for product photos via SerpAPI
    /// This can find actual branded products like "Heinz Ketchup"
    func searchProductImages(query: String, whiteBackground: Bool = true) async -> [ProductImage] {
        guard hasApiKey else {
            lastError = "SerpAPI key not configured"
            return []
        }

        isLoading = true
        lastError = nil
        searchResults = []

        defer { isLoading = false }

        // Build search query optimised for product shots
        var searchQuery = query
        if whiteBackground {
            searchQuery += " product white background"
        }

        // Build URL with parameters
        var components = URLComponents(string: "https://serpapi.com/search.json")!
        components.queryItems = [
            URLQueryItem(name: "engine", value: "google_images"),
            URLQueryItem(name: "q", value: searchQuery),
            URLQueryItem(name: "google_domain", value: "google.co.uk"),
            URLQueryItem(name: "gl", value: "uk"),
            URLQueryItem(name: "hl", value: "en"),
            URLQueryItem(name: "safe", value: "active"),
            URLQueryItem(name: "api_key", value: serpApiKey)
        ]

        guard let url = components.url else {
            lastError = "Invalid search query"
            return []
        }

        do {
            var request = URLRequest(url: url)
            request.setValue("NutraSafe Database Manager/1.0", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                lastError = "Invalid response"
                return []
            }

            if httpResponse.statusCode == 401 {
                lastError = "Invalid API key"
                return []
            }

            if httpResponse.statusCode == 429 {
                lastError = "Rate limit exceeded - try again later"
                return []
            }

            guard httpResponse.statusCode == 200 else {
                lastError = "API error: \(httpResponse.statusCode)"
                return []
            }

            let decoder = JSONDecoder()
            let result = try decoder.decode(SerpApiResponse.self, from: data)

            // Track remaining searches
            if let accountInfo = result.search_metadata?.serpapi_account_info {
                remainingSearches = accountInfo.searches_remaining
            }

            // Convert to ProductImage
            let images = (result.images_results ?? []).compactMap { img -> ProductImage? in
                guard let thumbnail = img.thumbnail, let original = img.original else {
                    return nil
                }

                return ProductImage(
                    id: img.position.map { String($0) } ?? UUID().uuidString,
                    thumbnailURL: thumbnail,
                    originalURL: original,
                    title: img.title ?? "Product Image",
                    source: img.source ?? "Unknown",
                    sourceURL: img.link,
                    width: img.original_width,
                    height: img.original_height
                )
            }

            searchResults = images
            return images

        } catch {
            lastError = "Search failed: \(error.localizedDescription)"
            return []
        }
    }

    /// Search for a specific branded product
    func searchBrandedProduct(name: String, brand: String?) async -> [ProductImage] {
        var query = name
        if let brand = brand, !brand.isEmpty {
            query = "\(brand) \(name)"
        }
        return await searchProductImages(query: query, whiteBackground: true)
    }

    /// Search for product by barcode (tries to find product name first)
    func searchByBarcode(_ barcode: String) async -> [ProductImage] {
        // First try searching the barcode directly (sometimes works)
        let results = await searchProductImages(query: barcode, whiteBackground: false)
        if !results.isEmpty {
            return results
        }

        // If no results, try "barcode [number]" as some databases index this way
        return await searchProductImages(query: "barcode \(barcode)", whiteBackground: false)
    }

    // MARK: - Download Image

    /// Download an image and return its data
    func downloadImage(from urlString: String) async -> Data? {
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            return data
        } catch {
            lastError = "Failed to download: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - Account Info

    /// Check remaining searches on account
    func checkAccountStatus() async -> AccountStatus? {
        guard hasApiKey else { return nil }

        var components = URLComponents(string: "https://serpapi.com/account.json")!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: serpApiKey)
        ]

        guard let url = components.url else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            return try decoder.decode(AccountStatus.self, from: data)
        } catch {
            return nil
        }
    }
}

// MARK: - Models

struct ProductImage: Identifiable {
    let id: String
    let thumbnailURL: String
    let originalURL: String
    let title: String
    let source: String
    let sourceURL: String?
    let width: Int?
    let height: Int?

    var dimensions: String? {
        guard let w = width, let h = height else { return nil }
        return "\(w) × \(h)"
    }
}

struct AccountStatus: Codable {
    let account_email: String?
    let api_key: String?
    let plan_name: String?
    let plan_searches_left: Int?
    let searches_per_month: Int?
    let this_month_usage: Int?
    let this_hour_searches: Int?
    let account_rate_limit_per_hour: Int?
}

// MARK: - SerpAPI Response Models

struct SerpApiResponse: Codable {
    let search_metadata: SearchMetadata?
    let search_parameters: SearchParameters?
    let images_results: [ImageResult]?
    let suggested_searches: [SuggestedSearch]?
    let error: String?
}

struct SearchMetadata: Codable {
    let id: String?
    let status: String?
    let json_endpoint: String?
    let created_at: String?
    let processed_at: String?
    let google_images_url: String?
    let raw_html_file: String?
    let total_time_taken: Double?
    let serpapi_account_info: SerpApiAccountInfo?
}

struct SerpApiAccountInfo: Codable {
    let searches_remaining: Int?
}

struct SearchParameters: Codable {
    let engine: String?
    let q: String?
    let google_domain: String?
    let hl: String?
    let gl: String?
}

struct ImageResult: Codable {
    let position: Int?
    let thumbnail: String?
    let original: String?
    let original_width: Int?
    let original_height: Int?
    let is_product: Bool?
    let source: String?
    let title: String?
    let link: String?
}

struct SuggestedSearch: Codable {
    let name: String?
    let link: String?
    let chips: String?
    let thumbnail: String?
}
