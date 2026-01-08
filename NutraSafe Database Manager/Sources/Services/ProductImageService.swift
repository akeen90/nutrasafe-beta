//
//  ProductImageService.swift
//  NutraSafe Database Manager
//
//  Service for fetching professional product images from UK retailers
//  Prioritises clean, white background product shots
//

import Foundation

@MainActor
class ProductImageService: ObservableObject {
    static let shared = ProductImageService()

    @Published var isLoading = false
    @Published var lastError: String?

    private init() {}

    // MARK: - Image Source Priority
    // 1. Tesco (clean white backgrounds, manufacturer images)
    // 2. Sainsbury's (professional product shots)
    // 3. Ocado (high quality images)
    // 4. Open Food Facts (fallback, user-submitted)

    /// Fetch the best professional product image for a barcode
    /// Searches UK retailers in priority order for clean, white-background images
    func fetchBestProductImage(barcode: String, productName: String? = nil, brand: String? = nil) async -> ProductImageResult? {
        isLoading = true
        lastError = nil

        defer { isLoading = false }

        // Try each source in priority order
        // 1. Tesco - best quality, official manufacturer images
        if let result = await fetchFromTesco(barcode: barcode) {
            return result
        }

        // 2. Sainsbury's
        if let result = await fetchFromSainsburys(barcode: barcode) {
            return result
        }

        // 3. Ocado
        if let result = await fetchFromOcado(barcode: barcode) {
            return result
        }

        // 4. Try searching by product name if we have it
        if let name = productName {
            if let result = await searchRetailerByName(name: name, brand: brand) {
                return result
            }
        }

        return nil
    }

    // MARK: - Tesco API

    private func fetchFromTesco(barcode: String) async -> ProductImageResult? {
        // Tesco Product API - uses GTIN/EAN barcode
        // Their images are typically professional white-background shots
        let urlString = "https://dev.tescolabs.com/product/?gtin=\(barcode)"

        guard let url = URL(string: urlString) else { return nil }

        do {
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("NutraSafe/1.0", forHTTPHeaderField: "User-Agent")
            // Note: Tesco API requires subscription key - this is a fallback check
            // In production, you'd add: request.setValue(tescoApiKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let products = json["products"] as? [[String: Any]],
               let firstProduct = products.first,
               let imageURL = firstProduct["image"] as? String,
               !imageURL.isEmpty {
                return ProductImageResult(
                    imageURL: imageURL,
                    thumbnailURL: imageURL,
                    source: .tesco,
                    isProfessional: true
                )
            }
        } catch {
            // Silently fail and try next source
        }

        return nil
    }

    // MARK: - Sainsbury's

    private func fetchFromSainsburys(barcode: String) async -> ProductImageResult? {
        // Sainsbury's product images follow a predictable URL pattern
        // Their images are professional product shots with white backgrounds

        // Try the standard Sainsbury's CDN pattern
        let imagePatterns = [
            "https://assets.sainsburys-groceries.co.uk/gol/\(barcode)/1/640x640.jpg",
            "https://assets.sainsburys-groceries.co.uk/gol/\(barcode)/image.jpg"
        ]

        for pattern in imagePatterns {
            if let url = URL(string: pattern) {
                if await checkImageExists(url: url) {
                    return ProductImageResult(
                        imageURL: pattern,
                        thumbnailURL: pattern.replacingOccurrences(of: "640x640", with: "200x200"),
                        source: .sainsburys,
                        isProfessional: true
                    )
                }
            }
        }

        return nil
    }

    // MARK: - Ocado

    private func fetchFromOcado(barcode: String) async -> ProductImageResult? {
        // Ocado uses high-quality product images
        // Their CDN follows patterns based on product SKU

        // Try common Ocado image patterns
        let paddedBarcode = String(repeating: "0", count: max(0, 13 - barcode.count)) + barcode

        let imagePatterns = [
            "https://ocado.com/productImages/\(paddedBarcode)/\(paddedBarcode)_1_640x640.jpg",
            "https://www.ocado.com/productImages/\(barcode)/\(barcode)_0_640x640.jpg"
        ]

        for pattern in imagePatterns {
            if let url = URL(string: pattern) {
                if await checkImageExists(url: url) {
                    return ProductImageResult(
                        imageURL: pattern,
                        thumbnailURL: pattern.replacingOccurrences(of: "640x640", with: "200x200"),
                        source: .ocado,
                        isProfessional: true
                    )
                }
            }
        }

        return nil
    }

    // MARK: - Search by Name

    private func searchRetailerByName(name: String, brand: String?) async -> ProductImageResult? {
        // Build search query
        var searchQuery = name
        if let brand = brand, !brand.isEmpty {
            searchQuery = "\(brand) \(name)"
        }

        // Try searching via Google Custom Search for UK retailer product images
        // This requires API key setup - for now we'll use a simplified approach

        // Try Tesco grocery search page scraping (simplified)
        if let result = await searchTescoByName(query: searchQuery) {
            return result
        }

        return nil
    }

    private func searchTescoByName(query: String) async -> ProductImageResult? {
        // Tesco search - would require more complex scraping
        // For now, return nil and rely on barcode lookups
        return nil
    }

    // MARK: - Helpers

    private func checkImageExists(url: URL) async -> Bool {
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            request.setValue("NutraSafe/1.0", forHTTPHeaderField: "User-Agent")

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            // Image doesn't exist or can't be reached
        }

        return false
    }

    // MARK: - Batch Image Fetch

    /// Fetch images for multiple products, returning the best available for each
    func fetchImagesForProducts(_ foods: [FoodItem]) async -> [String: ProductImageResult] {
        var results: [String: ProductImageResult] = [:]

        for food in foods {
            guard let barcode = food.barcode, !barcode.isEmpty else { continue }

            if let result = await fetchBestProductImage(
                barcode: barcode,
                productName: food.name,
                brand: food.brand
            ) {
                results[food.objectID] = result
            }
        }

        return results
    }
}

// MARK: - Image Result Models

struct ProductImageResult {
    let imageURL: String
    let thumbnailURL: String?
    let source: ImageSource
    let isProfessional: Bool

    enum ImageSource: String {
        case tesco = "Tesco"
        case sainsburys = "Sainsbury's"
        case ocado = "Ocado"
        case asda = "ASDA"
        case morrisons = "Morrisons"
        case waitrose = "Waitrose"
        case openFoodFacts = "Open Food Facts"
        case manufacturer = "Manufacturer"

        var priority: Int {
            switch self {
            case .manufacturer: return 0
            case .tesco: return 1
            case .sainsburys: return 2
            case .ocado: return 3
            case .waitrose: return 4
            case .morrisons: return 5
            case .asda: return 6
            case .openFoodFacts: return 10
            }
        }
    }
}

// MARK: - Extension for OpenFoodFactsService

extension OpenFoodFactsService {
    /// Enhanced image fetching that tries UK retailers first, then falls back to OFF
    func fetchProfessionalImage(for food: FoodItem) async -> ProductImageResult? {
        guard let barcode = food.barcode, !barcode.isEmpty else { return nil }

        // First try UK retailers for professional images
        let imageService = ProductImageService.shared
        if let retailerImage = await imageService.fetchBestProductImage(
            barcode: barcode,
            productName: food.name,
            brand: food.brand
        ) {
            return retailerImage
        }

        // Fall back to Open Food Facts
        if let offProduct = await lookupProduct(barcode: barcode) {
            if let imageURL = getBestImageURL(for: offProduct) {
                return ProductImageResult(
                    imageURL: imageURL,
                    thumbnailURL: offProduct.image_front_small_url ?? offProduct.image_front_thumb_url,
                    source: .openFoodFacts,
                    isProfessional: false // OFF images are user-submitted
                )
            }
        }

        return nil
    }
}
