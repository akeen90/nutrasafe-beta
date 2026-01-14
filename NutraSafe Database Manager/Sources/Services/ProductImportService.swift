//
//  ProductImportService.swift
//  NutraSafe Database Manager
//
//  Service for importing new food products from external sources
//  to populate the database automatically
//

import Foundation

@MainActor
class ProductImportService: ObservableObject {
    static let shared = ProductImportService()

    // MARK: - Published State

    @Published var isImporting = false
    @Published var importProgress: ImportProgress?
    @Published var lastImportResults: ImportResults?
    @Published var lastError: String?
    @Published var previewProducts: [ImportableProduct] = []

    // Dependencies
    private let offService = OpenFoodFactsService.shared
    private let ukService = UKRetailerService.shared

    private var isCancelled = false

    private init() {}

    // MARK: - Import Progress

    struct ImportProgress {
        var phase: ImportPhase
        var currentProduct: String
        var processedCount: Int
        var totalCount: Int
        var importedCount: Int
        var skippedCount: Int
        var errorCount: Int

        var percentComplete: Double {
            guard totalCount > 0 else { return 0 }
            return Double(processedCount) / Double(totalCount) * 100
        }

        enum ImportPhase: String {
            case searching = "Searching for products..."
            case fetching = "Fetching product details..."
            case importing = "Importing to database..."
            case complete = "Import complete"
            case cancelled = "Import cancelled"
        }
    }

    // MARK: - Import Results

    struct ImportResults {
        var totalFound: Int
        var importedCount: Int
        var skippedCount: Int
        var errorCount: Int
        var duration: TimeInterval
        var importedProducts: [ImportableProduct]
        var errors: [ImportError]

        struct ImportError {
            let productName: String
            let reason: String
        }
    }

    // MARK: - Importable Product

    struct ImportableProduct: Identifiable {
        let id = UUID()
        var barcode: String
        var name: String
        var brand: String?
        var calories: Double
        var protein: Double
        var carbs: Double
        var fat: Double
        var fiber: Double
        var sugar: Double
        var sodium: Double
        var ingredients: [String]?
        var ingredientsText: String?
        var imageURL: String?
        var servingSize: String?
        var servingSizeG: Double?
        var source: String
        var categories: [String]?
        var novaGroup: Int?
        var nutriScore: String?
        var isSelected: Bool = true

        /// Convert to FoodItem for database import
        func toFoodItem() -> FoodItem {
            var food = FoodItem()
            food.objectID = barcode.isEmpty ? UUID().uuidString : barcode
            food.barcode = barcode.isEmpty ? nil : barcode
            food.name = name
            food.brand = brand
            food.calories = calories
            food.protein = protein
            food.carbs = carbs
            food.fat = fat
            food.fiber = fiber
            food.sugar = sugar
            food.sodium = sodium
            food.ingredients = ingredients
            food.ingredientsText = ingredientsText
            food.imageURL = imageURL
            food.servingDescription = servingSize
            food.servingSizeG = servingSizeG
            food.source = source
            food.categories = categories
            food.processingScore = novaGroup
            food.isVerified = false
            food.lastUpdated = ISO8601DateFormatter().string(from: Date())
            return food
        }
    }

    // MARK: - Import Configuration

    struct ImportConfig {
        var searchQuery: String = ""
        var categories: [ProductCategory] = []
        var minProducts: Int = 20
        var maxProducts: Int = 100
        var sources: Set<ImportSource> = [.openFoodFacts]
        var requireBarcode: Bool = true
        var requireNutrition: Bool = true
        var requireImage: Bool = false
        var skipExisting: Bool = true
        var countryFilter: String = "united-kingdom" // OFF country tag

        enum ImportSource: String, CaseIterable {
            case openFoodFacts = "Open Food Facts"
            case ukRetailers = "UK Retailers"

            var icon: String {
                switch self {
                case .openFoodFacts: return "globe"
                case .ukRetailers: return "bag.fill"
                }
            }
        }

        enum ProductCategory: String, CaseIterable {
            case beverages = "beverages"
            case dairy = "dairy"
            case snacks = "snacks"
            case cereals = "cereals"
            case meats = "meats"
            case vegetables = "vegetables"
            case fruits = "fruits"
            case bakery = "bakery"
            case frozen = "frozen"
            case condiments = "condiments"
            case confectionery = "confectionery"
            case readyMeals = "ready-meals"

            var displayName: String {
                switch self {
                case .beverages: return "Beverages"
                case .dairy: return "Dairy"
                case .snacks: return "Snacks"
                case .cereals: return "Cereals & Breakfast"
                case .meats: return "Meat & Fish"
                case .vegetables: return "Vegetables"
                case .fruits: return "Fruits"
                case .bakery: return "Bakery"
                case .frozen: return "Frozen Foods"
                case .condiments: return "Condiments & Sauces"
                case .confectionery: return "Confectionery"
                case .readyMeals: return "Ready Meals"
                }
            }

            var offTag: String {
                switch self {
                case .beverages: return "en:beverages"
                case .dairy: return "en:dairies"
                case .snacks: return "en:snacks"
                case .cereals: return "en:breakfasts"
                case .meats: return "en:meats"
                case .vegetables: return "en:vegetables"
                case .fruits: return "en:fruits"
                case .bakery: return "en:breads"
                case .frozen: return "en:frozen-foods"
                case .condiments: return "en:condiments"
                case .confectionery: return "en:sugary-snacks"
                case .readyMeals: return "en:meals"
                }
            }
        }
    }

    // MARK: - Search for Products to Import

    /// Search Open Food Facts for products matching the query
    func searchProductsToImport(config: ImportConfig, existingBarcodes: Set<String>) async -> [ImportableProduct] {
        isImporting = true
        isCancelled = false
        previewProducts = []

        defer { isImporting = false }

        importProgress = ImportProgress(
            phase: .searching,
            currentProduct: "",
            processedCount: 0,
            totalCount: 0,
            importedCount: 0,
            skippedCount: 0,
            errorCount: 0
        )

        var products: [ImportableProduct] = []

        // Search Open Food Facts
        if config.sources.contains(.openFoodFacts) {
            let offProducts = await searchOpenFoodFacts(config: config, existingBarcodes: existingBarcodes)
            products.append(contentsOf: offProducts)
        }

        // Filter and sort results
        products = products.filter { product in
            if config.requireBarcode && product.barcode.isEmpty { return false }
            if config.requireNutrition && product.calories == 0 && product.protein == 0 { return false }
            if config.requireImage && (product.imageURL == nil || product.imageURL!.isEmpty) { return false }
            if config.skipExisting && existingBarcodes.contains(product.barcode) { return false }
            return true
        }

        // Limit results
        let limitedProducts = Array(products.prefix(config.maxProducts))
        previewProducts = limitedProducts

        importProgress?.phase = .complete
        importProgress?.totalCount = limitedProducts.count

        return limitedProducts
    }

    /// Search Open Food Facts API
    private func searchOpenFoodFacts(config: ImportConfig, existingBarcodes: Set<String>) async -> [ImportableProduct] {
        var products: [ImportableProduct] = []
        var page = 1
        let pageSize = 50

        while products.count < config.maxProducts && !isCancelled {
            importProgress?.phase = .searching
            importProgress?.currentProduct = "Page \(page)..."

            // Build search URL
            var urlComponents = URLComponents(string: "https://uk.openfoodfacts.org/cgi/search.pl")!
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "action", value: "process"),
                URLQueryItem(name: "json", value: "1"),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "page_size", value: String(pageSize)),
                URLQueryItem(name: "fields", value: "code,product_name,product_name_en,brands,nutriments,ingredients_text,ingredients_text_en,image_url,image_front_url,serving_size,categories_tags,nova_group,nutrition_grades")
            ]

            // Add search query if provided
            if !config.searchQuery.isEmpty {
                queryItems.append(URLQueryItem(name: "search_terms", value: config.searchQuery))
            }

            // Add category filter if provided
            if !config.categories.isEmpty {
                let categoryTags = config.categories.map { $0.offTag }.joined(separator: ",")
                queryItems.append(URLQueryItem(name: "tagtype_0", value: "categories"))
                queryItems.append(URLQueryItem(name: "tag_contains_0", value: "contains"))
                queryItems.append(URLQueryItem(name: "tag_0", value: categoryTags))
            }

            // Country filter for UK products
            queryItems.append(URLQueryItem(name: "tagtype_1", value: "countries"))
            queryItems.append(URLQueryItem(name: "tag_contains_1", value: "contains"))
            queryItems.append(URLQueryItem(name: "tag_1", value: config.countryFilter))

            urlComponents.queryItems = queryItems

            guard let url = urlComponents.url else { break }

            do {
                var request = URLRequest(url: url)
                request.setValue("NutraSafe Database Manager/1.0", forHTTPHeaderField: "User-Agent")

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    break
                }

                let searchResponse = try JSONDecoder().decode(OFFSearchResponse.self, from: data)

                guard let offProducts = searchResponse.products, !offProducts.isEmpty else {
                    break // No more results
                }

                // Convert to ImportableProduct
                for offProduct in offProducts {
                    guard let barcode = offProduct.code, !barcode.isEmpty else { continue }

                    // Skip if already in database
                    if config.skipExisting && existingBarcodes.contains(barcode) {
                        importProgress?.skippedCount += 1
                        continue
                    }

                    let name = offProduct.product_name_en ?? offProduct.product_name ?? "Unknown"
                    if name.isEmpty || name == "Unknown" { continue }

                    let nutriments = offProduct.nutriments
                    let calories = nutriments?.energy_kcal_100g ?? nutriments?.energy_kcal ?? 0
                    let protein = nutriments?.proteins_100g ?? nutriments?.proteins ?? 0
                    let carbs = nutriments?.carbohydrates_100g ?? nutriments?.carbohydrates ?? 0
                    let fat = nutriments?.fat_100g ?? nutriments?.fat ?? 0
                    let fiber = nutriments?.fiber_100g ?? nutriments?.fiber ?? 0
                    let sugar = nutriments?.sugars_100g ?? nutriments?.sugars ?? 0
                    let sodium = (nutriments?.sodium_100g ?? nutriments?.sodium ?? 0) * 1000 // Convert to mg

                    // Parse ingredients
                    let ingredientsText = offProduct.ingredients_text_en ?? offProduct.ingredients_text
                    var ingredients: [String]?
                    if let text = ingredientsText {
                        ingredients = text.components(separatedBy: CharacterSet(charactersIn: ",;"))
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                    }

                    // Parse serving size
                    var servingSizeG: Double?
                    if let serving = offProduct.serving_size {
                        // Try to extract grams from serving size string
                        let pattern = #"(\d+(?:\.\d+)?)\s*g"#
                        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                           let match = regex.firstMatch(in: serving, options: [], range: NSRange(serving.startIndex..., in: serving)),
                           let range = Range(match.range(at: 1), in: serving) {
                            servingSizeG = Double(serving[range])
                        }
                    }

                    let product = ImportableProduct(
                        barcode: barcode,
                        name: name,
                        brand: offProduct.brands,
                        calories: calories,
                        protein: protein,
                        carbs: carbs,
                        fat: fat,
                        fiber: fiber,
                        sugar: sugar,
                        sodium: sodium,
                        ingredients: ingredients,
                        ingredientsText: ingredientsText,
                        imageURL: offProduct.image_front_url ?? offProduct.image_url,
                        servingSize: offProduct.serving_size,
                        servingSizeG: servingSizeG,
                        source: "Open Food Facts",
                        categories: offProduct.categories_tags,
                        novaGroup: offProduct.nova_group,
                        nutriScore: offProduct.nutrition_grades
                    )

                    products.append(product)
                    importProgress?.processedCount = products.count
                }

                // Check if we've reached the end
                if offProducts.count < pageSize {
                    break
                }

                page += 1

                // Rate limiting
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay

            } catch {
                lastError = "Search failed: \(error.localizedDescription)"
                break
            }
        }

        return products
    }

    // MARK: - Import Selected Products

    /// Import selected products to the database
    func importProducts(_ products: [ImportableProduct], using algoliaService: AlgoliaService, database: DatabaseType) async -> ImportResults {
        isImporting = true
        isCancelled = false
        let startTime = Date()

        var importedProducts: [ImportableProduct] = []
        var errors: [ImportResults.ImportError] = []

        let selectedProducts = products.filter { $0.isSelected }

        importProgress = ImportProgress(
            phase: .importing,
            currentProduct: "",
            processedCount: 0,
            totalCount: selectedProducts.count,
            importedCount: 0,
            skippedCount: 0,
            errorCount: 0
        )

        for (index, product) in selectedProducts.enumerated() {
            if isCancelled {
                importProgress?.phase = .cancelled
                break
            }

            importProgress?.currentProduct = product.name
            importProgress?.processedCount = index + 1

            // Convert to FoodItem and save
            let foodItem = product.toFoodItem()

            let success = await algoliaService.saveFood(foodItem, database: database)

            if success {
                importedProducts.append(product)
                importProgress?.importedCount += 1
            } else {
                errors.append(ImportResults.ImportError(
                    productName: product.name,
                    reason: algoliaService.error ?? "Unknown error"
                ))
                importProgress?.errorCount += 1
            }

            // Small delay to avoid overwhelming the API
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }

        let duration = Date().timeIntervalSince(startTime)

        let results = ImportResults(
            totalFound: products.count,
            importedCount: importedProducts.count,
            skippedCount: products.count - selectedProducts.count,
            errorCount: errors.count,
            duration: duration,
            importedProducts: importedProducts,
            errors: errors
        )

        lastImportResults = results
        importProgress?.phase = .complete
        isImporting = false

        return results
    }

    /// Cancel the current import operation
    func cancelImport() {
        isCancelled = true
    }

    // MARK: - Popular UK Product Queries

    /// Get suggested search queries for popular UK products
    static var popularUKSearches: [String] {
        [
            "Tesco",
            "Sainsbury's",
            "ASDA",
            "Morrisons",
            "Waitrose",
            "M&S Food",
            "Aldi",
            "Lidl",
            "Co-op",
            "Heinz",
            "Cadbury",
            "Warburtons",
            "McVitie's",
            "Hovis",
            "Walkers",
            "Birds Eye",
            "Cathedral City",
            "Lurpak",
            "Müller",
            "Innocent"
        ]
    }

    /// Get suggested categories for UK products
    static var suggestedCategories: [(name: String, query: String)] {
        [
            ("Breakfast Cereals", "breakfast cereals"),
            ("Biscuits", "biscuits"),
            ("Crisps & Snacks", "crisps snacks"),
            ("Bread & Bakery", "bread bakery"),
            ("Dairy & Milk", "milk dairy"),
            ("Ready Meals", "ready meals"),
            ("Frozen Food", "frozen"),
            ("Soft Drinks", "soft drinks"),
            ("Chocolate & Sweets", "chocolate confectionery"),
            ("Pasta & Rice", "pasta rice"),
            ("Sauces & Condiments", "sauces condiments"),
            ("Soup", "soup"),
            ("Tea & Coffee", "tea coffee"),
            ("Baby Food", "baby food"),
            ("Pet Food", "pet food")
        ]
    }
}
