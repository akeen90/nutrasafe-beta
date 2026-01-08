//
//  OpenFoodFactsService.swift
//  NutraSafe Database Manager
//
//  Service for verifying food data against Open Food Facts database
//  and fetching product images
//

import Foundation

@MainActor
class OpenFoodFactsService: ObservableObject {
    static let shared = OpenFoodFactsService()

    @Published var isLoading = false
    @Published var lastError: String?

    private let baseURL = "https://world.openfoodfacts.org/api/v2"
    private let ukBaseURL = "https://uk.openfoodfacts.org/api/v2"

    private init() {}

    // MARK: - Product Lookup

    /// Look up a product by barcode from Open Food Facts
    func lookupProduct(barcode: String) async -> OFFProduct? {
        isLoading = true
        lastError = nil

        defer { isLoading = false }

        // Try UK first, then world database
        if let product = await fetchProduct(barcode: barcode, baseURL: ukBaseURL) {
            return product
        }

        return await fetchProduct(barcode: barcode, baseURL: baseURL)
    }

    private func fetchProduct(barcode: String, baseURL: String) async -> OFFProduct? {
        let urlString = "\(baseURL)/product/\(barcode).json"

        guard let url = URL(string: urlString) else {
            lastError = "Invalid barcode format"
            return nil
        }

        do {
            var request = URLRequest(url: url)
            request.setValue("NutraSafe Database Manager/1.0", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            let decoder = JSONDecoder()
            let result = try decoder.decode(OFFResponse.self, from: data)

            guard result.status == 1, let product = result.product else {
                return nil
            }

            return product
        } catch {
            lastError = "Failed to fetch product: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - Search Products

    /// Search for products by name
    func searchProducts(query: String, page: Int = 1, pageSize: Int = 20) async -> [OFFProduct] {
        isLoading = true
        lastError = nil

        defer { isLoading = false }

        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(ukBaseURL)/search?search_terms=\(encodedQuery)&page=\(page)&page_size=\(pageSize)&json=1"

        guard let url = URL(string: urlString) else {
            lastError = "Invalid search query"
            return []
        }

        do {
            var request = URLRequest(url: url)
            request.setValue("NutraSafe Database Manager/1.0", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                lastError = "Search failed"
                return []
            }

            let decoder = JSONDecoder()
            let result = try decoder.decode(OFFSearchResponse.self, from: data)

            return result.products ?? []
        } catch {
            lastError = "Search failed: \(error.localizedDescription)"
            return []
        }
    }

    // MARK: - Verification

    /// Verify a food item against Open Food Facts data
    func verifyFood(_ food: FoodItem) async -> VerificationResult {
        guard let barcode = food.barcode, !barcode.isEmpty else {
            return VerificationResult(
                verified: false,
                confidence: 0,
                message: "No barcode to verify against",
                offProduct: nil,
                discrepancies: []
            )
        }

        guard let offProduct = await lookupProduct(barcode: barcode) else {
            return VerificationResult(
                verified: false,
                confidence: 0,
                message: "Product not found in Open Food Facts database",
                offProduct: nil,
                discrepancies: []
            )
        }

        var discrepancies: [Discrepancy] = []
        var matchScore = 0
        var totalChecks = 0

        // Check name similarity
        if let offName = offProduct.product_name {
            totalChecks += 1
            if food.name.lowercased().contains(offName.lowercased()) ||
               offName.lowercased().contains(food.name.lowercased()) {
                matchScore += 1
            } else {
                discrepancies.append(Discrepancy(
                    field: "name",
                    ourValue: food.name,
                    offValue: offName,
                    severity: .warning
                ))
            }
        }

        // Check brand
        if let offBrand = offProduct.brands {
            totalChecks += 1
            if let ourBrand = food.brand, !ourBrand.isEmpty {
                if ourBrand.lowercased().contains(offBrand.lowercased()) ||
                   offBrand.lowercased().contains(ourBrand.lowercased()) {
                    matchScore += 1
                } else {
                    discrepancies.append(Discrepancy(
                        field: "brand",
                        ourValue: ourBrand,
                        offValue: offBrand,
                        severity: .info
                    ))
                }
            } else {
                discrepancies.append(Discrepancy(
                    field: "brand",
                    ourValue: "Missing",
                    offValue: offBrand,
                    severity: .info
                ))
            }
        }

        // Check nutrition values (per 100g)
        if let offNutriments = offProduct.nutriments {
            // Calories
            if let offCalories = offNutriments.energy_kcal_100g ?? offNutriments.energy_kcal {
                totalChecks += 1
                let diff = abs(food.calories - offCalories)
                if diff <= 10 {
                    matchScore += 1
                } else {
                    let severity: DiscrepancySeverity = diff > 50 ? .error : .warning
                    discrepancies.append(Discrepancy(
                        field: "calories",
                        ourValue: "\(Int(food.calories)) kcal",
                        offValue: "\(Int(offCalories)) kcal",
                        severity: severity
                    ))
                }
            }

            // Protein
            if let offProtein = offNutriments.proteins_100g ?? offNutriments.proteins {
                totalChecks += 1
                let diff = abs(food.protein - offProtein)
                if diff <= 2 {
                    matchScore += 1
                } else {
                    discrepancies.append(Discrepancy(
                        field: "protein",
                        ourValue: "\(food.protein)g",
                        offValue: "\(offProtein)g",
                        severity: diff > 5 ? .error : .warning
                    ))
                }
            }

            // Carbs
            if let offCarbs = offNutriments.carbohydrates_100g ?? offNutriments.carbohydrates {
                totalChecks += 1
                let diff = abs(food.carbs - offCarbs)
                if diff <= 3 {
                    matchScore += 1
                } else {
                    discrepancies.append(Discrepancy(
                        field: "carbs",
                        ourValue: "\(food.carbs)g",
                        offValue: "\(offCarbs)g",
                        severity: diff > 10 ? .error : .warning
                    ))
                }
            }

            // Fat
            if let offFat = offNutriments.fat_100g ?? offNutriments.fat {
                totalChecks += 1
                let diff = abs(food.fat - offFat)
                if diff <= 2 {
                    matchScore += 1
                } else {
                    discrepancies.append(Discrepancy(
                        field: "fat",
                        ourValue: "\(food.fat)g",
                        offValue: "\(offFat)g",
                        severity: diff > 5 ? .error : .warning
                    ))
                }
            }
        }

        // Check ingredients
        if let offIngredients = offProduct.ingredients_text_en ?? offProduct.ingredients_text {
            totalChecks += 1
            if let ourIngredients = food.ingredientsText, !ourIngredients.isEmpty {
                // Simple check - see if they share key words
                let ourWords = Set(ourIngredients.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 3 })
                let offWords = Set(offIngredients.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 3 })

                let intersection = ourWords.intersection(offWords)
                if Double(intersection.count) / Double(max(ourWords.count, 1)) > 0.5 {
                    matchScore += 1
                } else {
                    discrepancies.append(Discrepancy(
                        field: "ingredients",
                        ourValue: "Partial match",
                        offValue: offIngredients,
                        severity: .warning
                    ))
                }
            } else {
                discrepancies.append(Discrepancy(
                    field: "ingredients",
                    ourValue: "Missing",
                    offValue: offIngredients,
                    severity: .info
                ))
            }
        }

        let confidence = totalChecks > 0 ? Double(matchScore) / Double(totalChecks) * 100 : 0
        let verified = confidence >= 70 && discrepancies.filter({ $0.severity == .error }).isEmpty

        return VerificationResult(
            verified: verified,
            confidence: confidence,
            message: verified ? "Product verified against Open Food Facts" : "Discrepancies found",
            offProduct: offProduct,
            discrepancies: discrepancies
        )
    }

    // MARK: - Image Fetching

    /// Get the best available image URL for a product
    func getBestImageURL(for product: OFFProduct) -> String? {
        // Prefer front image with clean/white background
        // Priority: front > image > display

        if let frontURL = product.image_front_url, !frontURL.isEmpty {
            return frontURL
        }

        if let imageURL = product.image_url, !imageURL.isEmpty {
            return imageURL
        }

        return nil
    }

    /// Get all available image URLs for a product
    func getAllImageURLs(for product: OFFProduct) -> [String: String] {
        var images: [String: String] = [:]

        if let url = product.image_front_url {
            images["front"] = url
        }
        if let url = product.image_front_small_url {
            images["front_small"] = url
        }
        if let url = product.image_front_thumb_url {
            images["front_thumb"] = url
        }
        if let url = product.image_ingredients_url {
            images["ingredients"] = url
        }
        if let url = product.image_nutrition_url {
            images["nutrition"] = url
        }
        if let url = product.image_url {
            images["main"] = url
        }

        return images
    }
}

// MARK: - Response Models

struct OFFResponse: Codable {
    let status: Int
    let product: OFFProduct?
    let status_verbose: String?
}

struct OFFSearchResponse: Codable {
    let count: Int?
    let page: Int?
    let page_count: Int?
    let page_size: Int?
    let products: [OFFProduct]?
}

struct OFFProduct: Codable {
    let code: String?
    let product_name: String?
    let product_name_en: String?
    let brands: String?
    let categories: String?
    let categories_tags: [String]?

    // Nutrition
    let nutriments: OFFNutriments?
    let nutrition_grades: String?
    let nova_group: Int?

    // Ingredients
    let ingredients_text: String?
    let ingredients_text_en: String?
    let ingredients: [OFFIngredient]?
    let additives_tags: [String]?

    // Images
    let image_url: String?
    let image_front_url: String?
    let image_front_small_url: String?
    let image_front_thumb_url: String?
    let image_ingredients_url: String?
    let image_nutrition_url: String?

    // Other
    let quantity: String?
    let serving_size: String?
    let countries_tags: [String]?

    var displayName: String {
        product_name_en ?? product_name ?? "Unknown Product"
    }
}

struct OFFNutriments: Codable {
    let energy_kcal: Double?
    let energy_kcal_100g: Double?
    let proteins: Double?
    let proteins_100g: Double?
    let carbohydrates: Double?
    let carbohydrates_100g: Double?
    let sugars: Double?
    let sugars_100g: Double?
    let fat: Double?
    let fat_100g: Double?
    let saturated_fat: Double?
    let saturated_fat_100g: Double?
    let fiber: Double?
    let fiber_100g: Double?
    let salt: Double?
    let salt_100g: Double?
    let sodium: Double?
    let sodium_100g: Double?

    enum CodingKeys: String, CodingKey {
        case energy_kcal = "energy-kcal"
        case energy_kcal_100g = "energy-kcal_100g"
        case proteins
        case proteins_100g
        case carbohydrates
        case carbohydrates_100g
        case sugars
        case sugars_100g
        case fat
        case fat_100g
        case saturated_fat = "saturated-fat"
        case saturated_fat_100g = "saturated-fat_100g"
        case fiber
        case fiber_100g
        case salt
        case salt_100g
        case sodium
        case sodium_100g
    }
}

struct OFFIngredient: Codable {
    let id: String?
    let text: String?
    let percent: Double?
    let percent_estimate: Double?
}

// MARK: - Verification Result

struct VerificationResult {
    let verified: Bool
    let confidence: Double
    let message: String
    let offProduct: OFFProduct?
    let discrepancies: [Discrepancy]
}

struct Discrepancy {
    let field: String
    let ourValue: String
    let offValue: String
    let severity: DiscrepancySeverity
}

enum DiscrepancySeverity {
    case info
    case warning
    case error

    var color: String {
        switch self {
        case .info: return "blue"
        case .warning: return "orange"
        case .error: return "red"
        }
    }
}
