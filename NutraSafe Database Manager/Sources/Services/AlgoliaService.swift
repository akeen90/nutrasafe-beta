//
//  AlgoliaService.swift
//  NutraSafe Database Manager
//
//  Algolia integration for searching and managing food databases
//  Uses direct REST API for maximum compatibility
//

import Foundation

@MainActor
class AlgoliaService: ObservableObject {
    static let shared = AlgoliaService()

    // MARK: - Published State

    @Published var isLoading = false
    @Published var error: String?
    @Published var foods: [FoodItem] = []
    @Published var additives: [AdditiveItem] = []
    @Published var ultraProcessed: [UltraProcessedIngredient] = []
    @Published var totalHits: Int = 0
    @Published var currentPage: Int = 0
    @Published var hasMorePages: Bool = false

    // MARK: - Configuration

    private var appID: String = ""
    private var adminKey: String = ""

    private let hitsPerPage = 50

    private init() {
        loadCredentials()
    }

    // MARK: - Credentials Management

    func loadCredentials() {
        // Try to load from UserDefaults first (user-configured)
        if let savedAppID = UserDefaults.standard.string(forKey: "algolia_app_id"),
           let savedAdminKey = UserDefaults.standard.string(forKey: "algolia_admin_key"),
           !savedAppID.isEmpty, !savedAdminKey.isEmpty {
            appID = savedAppID
            adminKey = savedAdminKey
        } else {
            // Default NutraSafe credentials - pre-configured with admin access
            appID = "WK0TIF84M2"
            adminKey = "e54f75aae315af794ece385f3dc9c94b"
        }
    }

    func setCredentials(appID: String, adminKey: String) {
        self.appID = appID
        self.adminKey = adminKey
        UserDefaults.standard.set(appID, forKey: "algolia_app_id")
        UserDefaults.standard.set(adminKey, forKey: "algolia_admin_key")
    }

    var isConfigured: Bool {
        !appID.isEmpty && !adminKey.isEmpty
    }

    // MARK: - REST API Helpers

    private func makeRequest(method: String, path: String, body: [String: Any]? = nil) async throws -> Data {
        let urlString = "https://\(appID)-dsn.algolia.net\(path)"
        guard let url = URL(string: urlString) else {
            throw AlgoliaError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(appID, forHTTPHeaderField: "X-Algolia-Application-Id")
        request.setValue(adminKey, forHTTPHeaderField: "X-Algolia-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AlgoliaError.invalidResponse
        }

        if httpResponse.statusCode >= 400 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorJson["message"] as? String {
                throw AlgoliaError.apiError(message)
            }
            throw AlgoliaError.httpError(httpResponse.statusCode)
        }

        return data
    }

    // MARK: - Search Operations

    func searchFoods(query: String, database: DatabaseType, page: Int = 0) async {
        guard isConfigured else {
            error = "Algolia not configured. Please set your API keys in Settings."
            return
        }

        print("🔍 AlgoliaService.searchFoods: Starting search for '\(query)' in \(database.algoliaIndex), page \(page)")

        isLoading = true
        error = nil
        currentPage = page

        // Clear results for new searches to give visual feedback
        if page == 0 {
            print("🔍 Clearing existing \(foods.count) results for fresh search")
            foods = []
        }

        do {
            let body: [String: Any] = [
                "query": query,
                "hitsPerPage": hitsPerPage,
                "page": page,
                "attributesToRetrieve": ["*"]
            ]

            print("🔍 Making API request to Algolia...")
            let data = try await makeRequest(
                method: "POST",
                path: "/1/indexes/\(database.algoliaIndex)/query",
                body: body
            )

            let response = try JSONDecoder().decode(AlgoliaSearchResponse.self, from: data)
            print("🔍 Got \(response.hits.count) results, total: \(response.nbHits)")

            if page == 0 {
                foods = response.hits
            } else {
                foods.append(contentsOf: response.hits)
            }

            // Log first few results
            if !foods.isEmpty {
                let preview = foods.prefix(3).map { $0.name }.joined(separator: ", ")
                print("🔍 First results: \(preview)")
            }

            totalHits = response.nbHits
            hasMorePages = (page + 1) * hitsPerPage < totalHits

            isLoading = false
            print("🔍 Search complete. foods array now has \(foods.count) items")
        } catch {
            print("❌ Search failed: \(error)")
            self.error = "Search failed: \(error.localizedDescription)"
            isLoading = false
        }
    }

    func browseAllFoods(database: DatabaseType) async {
        guard isConfigured else {
            error = "Algolia not configured. Please set your API keys in Settings."
            return
        }

        isLoading = true
        error = nil
        foods = []

        do {
            var allFoods: [FoodItem] = []
            var cursor: String? = nil

            // Use Algolia's browse API which supports cursor-based pagination
            // This allows fetching ALL records without the 1000-page limit
            repeat {
                var body: [String: Any] = [
                    "attributesToRetrieve": ["*"],
                    "hitsPerPage": 1000
                ]

                if let cursor = cursor {
                    body["cursor"] = cursor
                }

                let data = try await makeRequest(
                    method: "POST",
                    path: "/1/indexes/\(database.algoliaIndex)/browse",
                    body: body
                )

                let response = try JSONDecoder().decode(AlgoliaBrowseResponse.self, from: data)
                allFoods.append(contentsOf: response.hits)

                // Update UI progressively
                foods = allFoods

                // Get next cursor for pagination
                cursor = response.cursor

            } while cursor != nil

            totalHits = allFoods.count
            hasMorePages = false
            isLoading = false
        } catch {
            self.error = "Browse failed: \(error.localizedDescription)"
            isLoading = false
        }
    }

    func loadMoreFoods(query: String, database: DatabaseType) async {
        guard hasMorePages else { return }
        await searchFoods(query: query, database: database, page: currentPage + 1)
    }

    /// Extended search that can fetch many more results (for Claude assistant)
    func extendedSearch(query: String, database: DatabaseType, maxResults: Int = 500) async {
        guard isConfigured else {
            error = "Algolia not configured."
            return
        }

        isLoading = true
        error = nil
        foods = []

        do {
            var allFoods: [FoodItem] = []
            var page = 0
            let perPage = min(maxResults, 1000)

            while allFoods.count < maxResults {
                let body: [String: Any] = [
                    "query": query,
                    "hitsPerPage": perPage,
                    "page": page,
                    "attributesToRetrieve": ["*"]
                ]

                let data = try await makeRequest(
                    method: "POST",
                    path: "/1/indexes/\(database.algoliaIndex)/query",
                    body: body
                )

                let response = try JSONDecoder().decode(AlgoliaSearchResponse.self, from: data)
                allFoods.append(contentsOf: response.hits)

                // Update UI progressively
                foods = allFoods
                totalHits = response.nbHits

                let totalPages = (response.nbHits / perPage) + 1
                page += 1

                // Stop if no more pages or we've hit our limit
                if page >= totalPages || allFoods.count >= maxResults {
                    break
                }
            }

            hasMorePages = allFoods.count < totalHits
            isLoading = false
        } catch {
            self.error = "Extended search failed: \(error.localizedDescription)"
            isLoading = false
        }
    }

    func refreshCurrentIndex() async {
        foods = []
        totalHits = 0
        currentPage = 0
    }

    func sortFoods(by comparators: [KeyPathComparator<FoodItem>]) {
        foods.sort { lhs, rhs in
            for comparator in comparators {
                let result = comparator.compare(lhs, rhs)
                if result != .orderedSame {
                    return result == .orderedAscending
                }
            }
            return false
        }
    }

    // MARK: - CRUD Operations

    func getFood(objectID: String, database: DatabaseType) async -> FoodItem? {
        guard isConfigured else {
            print("❌ AlgoliaService.getFood: Not configured")
            return nil
        }

        print("🔍 AlgoliaService.getFood: Fetching objectID='\(objectID)' from index='\(database.algoliaIndex)'")

        do {
            let data = try await makeRequest(
                method: "GET",
                path: "/1/indexes/\(database.algoliaIndex)/\(objectID)"
            )

            print("📦 AlgoliaService.getFood: Got response, decoding...")
            let food = try JSONDecoder().decode(FoodItem.self, from: data)
            print("✅ AlgoliaService.getFood: Successfully decoded food: \(food.name)")
            return food
        } catch {
            print("❌ AlgoliaService.getFood: Error - \(error)")
            self.error = "Failed to get food: \(error.localizedDescription)"
            return nil
        }
    }

    /// Fetch a food by ID from the default foods database (via Algolia)
    func getFoodById(_ foodId: String) async -> FoodItem? {
        return await getFood(objectID: foodId, database: .foods)
    }

    /// Fetch a food directly from Firestore via Cloud Function
    /// This gets the latest data immediately without waiting for Algolia sync
    func getFoodFromFirestore(_ foodId: String) async -> FoodItem? {
        do {
            guard let url = URL(string: "https://us-central1-nutrasafe-705c7.cloudfunctions.net/getFood?foodId=\(foodId)") else {
                print("❌ Invalid URL for getFood")
                return nil
            }

            print("🔥 Fetching food '\(foodId)' directly from Firestore...")

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 15

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("❌ getFood returned non-200 status")
                return nil
            }

            // Parse the response
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let success = json["success"] as? Bool, success,
                  let foodDict = json["food"] as? [String: Any] else {
                print("❌ Invalid response from getFood")
                return nil
            }

            // Convert to FoodItem
            let food = FoodItem(
                objectID: foodDict["objectID"] as? String ?? foodId,
                name: foodDict["name"] as? String ?? "",
                brand: foodDict["brandName"] as? String ?? foodDict["brand"] as? String,
                barcode: foodDict["barcode"] as? String,
                calories: (foodDict["calories"] as? NSNumber)?.doubleValue ?? 0,
                protein: (foodDict["protein"] as? NSNumber)?.doubleValue ?? 0,
                carbs: (foodDict["carbs"] as? NSNumber)?.doubleValue ?? 0,
                fat: (foodDict["fat"] as? NSNumber)?.doubleValue ?? 0,
                fiber: (foodDict["fiber"] as? NSNumber)?.doubleValue ?? 0,
                sugar: (foodDict["sugar"] as? NSNumber)?.doubleValue ?? 0,
                sodium: (foodDict["sodium"] as? NSNumber)?.doubleValue ?? 0,
                saturatedFat: (foodDict["saturatedFat"] as? NSNumber)?.doubleValue,
                servingDescription: foodDict["servingSize"] as? String ?? foodDict["servingDescription"] as? String,
                servingSizeG: (foodDict["servingSizeG"] as? NSNumber)?.doubleValue,
                isPerUnit: foodDict["isPerUnit"] as? Bool,
                ingredients: foodDict["ingredients"] as? [String],
                ingredientsText: foodDict["ingredientsText"] as? String,
                processingScore: (foodDict["processingScore"] as? NSNumber)?.intValue,
                processingGrade: foodDict["processingGrade"] as? String,
                processingLabel: foodDict["processingLabel"] as? String,
                isVerified: foodDict["isVerified"] as? Bool,
                verifiedBy: foodDict["verifiedBy"] as? String,
                verifiedAt: foodDict["verifiedAt"] as? String,
                source: foodDict["source"] as? String,
                imageURL: foodDict["imageURL"] as? String,
                thumbnailURL: foodDict["thumbnailURL"] as? String
            )

            print("✅ Got food '\(food.name)' from Firestore")
            return food

        } catch {
            print("❌ Error fetching food from Firestore: \(error)")
            return nil
        }
    }

    /// Save food to Firestore via Cloud Function (which triggers Algolia sync)
    /// This ensures the iOS app can find the food via search
    func saveFood(_ food: FoodItem, database: DatabaseType) async -> Bool {
        isLoading = true

        do {
            // Call the Cloud Function to save to Firestore
            // The Firestore trigger will automatically sync to Algolia
            guard let url = URL(string: "https://us-central1-nutrasafe-705c7.cloudfunctions.net/saveFood") else {
                throw AlgoliaError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30

            // Encode the food item
            let encoder = JSONEncoder()
            let foodData = try encoder.encode(food)
            guard var body = try JSONSerialization.jsonObject(with: foodData) as? [String: Any] else {
                throw AlgoliaError.encodingError
            }

            // Ensure objectID is set (critical for Firestore document ID)
            body["objectID"] = food.objectID

            // Map field names to match what Firestore/Algolia expect
            // Database Manager uses 'brand' but Firestore uses 'brandName'
            if let brand = body["brand"] as? String {
                body["brandName"] = brand
            }
            // servingDescription maps to servingSize
            if let servingDesc = body["servingDescription"] as? String {
                body["servingSize"] = servingDesc
            }

            let jsonData = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData

            print("📤 Saving food '\(food.name)' (ID: \(food.objectID), verified: \(food.isVerified ?? false)) via Cloud Function...")
            print("   Request URL: \(url)")
            print("   Request body size: \(jsonData.count) bytes")
            if let bodyString = String(data: jsonData, encoding: .utf8) {
                print("   Request body preview: \(String(bodyString.prefix(500)))")
            }

            let (data, response) = try await URLSession.shared.data(for: request)

            print("   Response received: \(data.count) bytes")

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AlgoliaError.invalidResponse
            }

            print("   HTTP Status: \(httpResponse.statusCode)")
            if let responseText = String(data: data, encoding: .utf8) {
                print("   Response body: \(responseText)")
            }

            if httpResponse.statusCode != 200 {
                if let errorText = String(data: data, encoding: .utf8) {
                    print("❌ Cloud Function error: \(errorText)")
                }
                throw AlgoliaError.apiError("Server returned \(httpResponse.statusCode)")
            }

            // Parse response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool, success {
                print("✅ Food saved to Firestore successfully (Algolia sync will follow)")
                isLoading = false
                error = nil
                return true
            } else {
                let responseStr = String(data: data, encoding: .utf8) ?? "no response"
                print("❌ Invalid response from server: \(responseStr)")
                throw AlgoliaError.apiError("Invalid response from server")
            }

        } catch {
            print("❌ Failed to save food: \(error)")
            self.error = "Failed to save food: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    func saveFoods(_ foods: [FoodItem], database: DatabaseType) async -> Bool {
        guard isConfigured else {
            error = "Algolia not configured"
            return false
        }

        isLoading = true

        do {
            let encoder = JSONEncoder()

            var requests: [[String: Any]] = []
            for food in foods {
                let foodData = try encoder.encode(food)
                guard var body = try JSONSerialization.jsonObject(with: foodData) as? [String: Any] else {
                    continue
                }
                body["objectID"] = food.objectID
                requests.append([
                    "action": "updateObject",
                    "body": body
                ])
            }

            let batchBody: [String: Any] = ["requests": requests]

            let _ = try await makeRequest(
                method: "POST",
                path: "/1/indexes/\(database.algoliaIndex)/batch",
                body: batchBody
            )

            isLoading = false
            return true
        } catch {
            self.error = "Failed to save foods: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    func deleteFood(objectID: String, database: DatabaseType) async -> Bool {
        guard isConfigured else {
            error = "Algolia not configured"
            return false
        }

        isLoading = true

        do {
            let _ = try await makeRequest(
                method: "DELETE",
                path: "/1/indexes/\(database.algoliaIndex)/\(objectID)"
            )

            // Remove from local array
            foods.removeAll { $0.objectID == objectID }
            totalHits -= 1

            isLoading = false
            return true
        } catch {
            self.error = "Failed to delete food: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    func deleteFoods(objectIDs: [String], database: DatabaseType) async -> Bool {
        guard isConfigured else {
            error = "Algolia not configured"
            return false
        }

        isLoading = true

        do {
            var requests: [[String: Any]] = []
            for id in objectIDs {
                requests.append([
                    "action": "deleteObject",
                    "body": ["objectID": id]
                ])
            }

            let batchBody: [String: Any] = ["requests": requests]

            let _ = try await makeRequest(
                method: "POST",
                path: "/1/indexes/\(database.algoliaIndex)/batch",
                body: batchBody
            )

            // Remove from local array
            foods.removeAll { objectIDs.contains($0.objectID) }
            totalHits -= objectIDs.count

            isLoading = false
            return true
        } catch {
            self.error = "Failed to delete foods: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Bulk Operations

    func bulkUpdateFoods(_ foodIDs: [String], operation: BulkEditOperation, database: DatabaseType) async -> Bool {
        guard isConfigured else {
            error = "Algolia not configured"
            return false
        }

        isLoading = true

        // Get all foods to update
        var foodsToUpdate: [FoodItem] = []
        for id in foodIDs {
            if let food = foods.first(where: { $0.objectID == id }) {
                var updatedFood = food
                switch operation.field {
                case .brand:
                    updatedFood.brand = operation.value
                case .source:
                    updatedFood.source = operation.value
                case .processingGrade:
                    updatedFood.processingGrade = operation.value
                case .isVerified:
                    updatedFood.isVerified = operation.value.lowercased() == "true"
                case .category:
                    if updatedFood.categories == nil {
                        updatedFood.categories = [operation.value]
                    } else {
                        updatedFood.categories?.append(operation.value)
                    }
                case .addTag:
                    if updatedFood.tags == nil {
                        updatedFood.tags = [operation.value]
                    } else if !(updatedFood.tags?.contains(operation.value) ?? false) {
                        updatedFood.tags?.append(operation.value)
                    }
                case .removeTag:
                    updatedFood.tags?.removeAll { $0 == operation.value }
                }
                foodsToUpdate.append(updatedFood)
            }
        }

        let success = await saveFoods(foodsToUpdate, database: database)

        if success {
            // Update local array
            for updatedFood in foodsToUpdate {
                if let idx = foods.firstIndex(where: { $0.objectID == updatedFood.objectID }) {
                    foods[idx] = updatedFood
                }
            }
        }

        isLoading = false
        return success
    }

    // MARK: - Import/Export

    func importFoods(from url: URL, database: DatabaseType) async -> ImportResult {
        guard isConfigured else {
            return ImportResult(successCount: 0, failureCount: 0, errors: ["Algolia not configured"])
        }

        isLoading = true

        do {
            let data = try Data(contentsOf: url)

            // Determine format from extension
            let importedFoods: [FoodItem]
            if url.pathExtension.lowercased() == "csv" {
                importedFoods = try parseCSV(data)
            } else {
                importedFoods = try JSONDecoder().decode([FoodItem].self, from: data)
            }

            // Save in batches of 1000
            var successCount = 0
            var errors: [String] = []

            for batch in importedFoods.chunked(into: 1000) {
                let success = await saveFoods(batch, database: database)
                if success {
                    successCount += batch.count
                } else {
                    errors.append("Batch failed: \(self.error ?? "Unknown error")")
                }
            }

            isLoading = false
            return ImportResult(successCount: successCount, failureCount: importedFoods.count - successCount, errors: errors)
        } catch {
            isLoading = false
            return ImportResult(successCount: 0, failureCount: 0, errors: ["Import failed: \(error.localizedDescription)"])
        }
    }

    func exportFoods(_ foods: [FoodItem], format: ExportFormat, to url: URL) throws {
        switch format {
        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(foods)
            try data.write(to: url)
        case .csv:
            let csv = generateCSV(from: foods)
            try csv.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    func downloadAllFoods(database: DatabaseType) async -> [FoodItem] {
        await browseAllFoods(database: database)
        return foods
    }

    // MARK: - Helpers

    private func parseCSV(_ data: Data) throws -> [FoodItem] {
        guard let content = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "CSV", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid CSV encoding"])
        }

        var parsedFoods: [FoodItem] = []
        let lines = content.components(separatedBy: .newlines)

        guard lines.count > 1 else { return [] }

        let headers = parseCSVLine(lines[0])

        for i in 1..<lines.count {
            let line = lines[i]
            guard !line.isEmpty else { continue }

            let values = parseCSVLine(line)
            var food = FoodItem()

            for (index, header) in headers.enumerated() {
                guard index < values.count else { continue }
                let value = values[index]

                switch header.lowercased() {
                case "objectid", "id": food.objectID = value
                case "name": food.name = value
                case "brand": food.brand = value.isEmpty ? nil : value
                case "barcode": food.barcode = value.isEmpty ? nil : value
                case "calories", "kcal": food.calories = Double(value) ?? 0
                case "protein": food.protein = Double(value) ?? 0
                case "carbs", "carbohydrates": food.carbs = Double(value) ?? 0
                case "fat": food.fat = Double(value) ?? 0
                case "fiber", "fibre": food.fiber = Double(value) ?? 0
                case "sugar": food.sugar = Double(value) ?? 0
                case "sodium": food.sodium = Double(value) ?? 0
                default: break
                }
            }

            if !food.name.isEmpty {
                if food.objectID.isEmpty {
                    food.objectID = UUID().uuidString
                }
                parsedFoods.append(food)
            }
        }

        return parsedFoods
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current.trimmingCharacters(in: .whitespaces))

        return result
    }

    private func generateCSV(from foods: [FoodItem]) -> String {
        var csv = "objectID,name,brand,barcode,calories,protein,carbs,fat,fiber,sugar,sodium,isVerified,processingGrade\n"

        for food in foods {
            let row = [
                food.objectID,
                escapeCSV(food.name),
                escapeCSV(food.brand ?? ""),
                food.barcode ?? "",
                String(food.calories),
                String(food.protein),
                String(food.carbs),
                String(food.fat),
                String(food.fiber),
                String(food.sugar),
                String(food.sodium),
                String(food.isVerified ?? false),
                food.processingGrade ?? ""
            ].joined(separator: ",")
            csv += row + "\n"
        }

        return csv
    }

    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}

// MARK: - Algolia Response Models

struct AlgoliaSearchResponse: Codable {
    let hits: [FoodItem]
    let nbHits: Int
    let page: Int
    let nbPages: Int
    let hitsPerPage: Int
}

struct AlgoliaBrowseResponse: Codable {
    let hits: [FoodItem]
    let cursor: String?
    let nbHits: Int?
}

// MARK: - Algolia Errors

enum AlgoliaError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case encodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return message
        case .encodingError:
            return "Failed to encode data"
        }
    }
}

// MARK: - Array Extension

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
