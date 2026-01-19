//
//  InferredIngredientManager.swift
//  NutraSafe Beta
//
//  Manager for AI-Inferred Meal Ingredient Analysis
//
//  IMPORTANT DISCLAIMERS:
//  - This system provides EDUCATED GUESSES only
//  - This is NOT medical advice
//  - AI-inferred ingredients may be INCOMPLETE or INCORRECT
//  - Some real ingredients may be completely MISSED
//  - Users can EDIT inferred ingredients
//

import Foundation

/// Manager for inferring ingredients from generic foods (takeaway, restaurant, unlabeled)
@MainActor
class InferredIngredientManager: ObservableObject {
    static let shared = InferredIngredientManager()

    @Published var isLoading = false
    @Published var errorMessage: String?

    // Firebase function endpoint
    private let functionURL = "https://us-central1-nutrasafe-705c7.cloudfunctions.net/inferMealIngredients"

    private init() {}

    // MARK: - Infer Ingredients

    /// Infer likely ingredients for a generic food item
    /// - Parameters:
    ///   - foodName: The name of the food (e.g., "Sausage", "Fish and chips")
    ///   - foodDescription: Optional context (e.g., "from chip shop", "restaurant curry")
    ///   - preparationMethod: Optional preparation info (e.g., "fried", "grilled")
    /// - Returns: InferredMealAnalysis with estimated ingredients
    func inferIngredients(
        for foodName: String,
        description: String? = nil,
        preparationMethod: String? = nil
    ) async throws -> InferredMealAnalysis {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Build request body
        var requestBody: [String: Any] = ["foodName": foodName]
        if let description = description, !description.isEmpty {
            requestBody["foodDescription"] = description
        }
        if let prep = preparationMethod, !prep.isEmpty {
            requestBody["preparationMethod"] = prep
        }

        guard let url = URL(string: functionURL) else {
            throw InferenceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw InferenceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["error"] as? String {
                throw InferenceError.serverError(errorMessage)
            }
            throw InferenceError.serverError("Status code: \(httpResponse.statusCode)")
        }

        // Parse response
        let analysis = try parseInferenceResponse(data: data, foodName: foodName)
        return analysis
    }

    // MARK: - Parse Response

    private func parseInferenceResponse(data: Data, foodName: String) throws -> InferredMealAnalysis {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw InferenceError.parseError("Invalid JSON response")
        }

        // Parse ingredients arrays
        let likelyIngredients = parseIngredientsArray(json["likelyIngredients"])
        let preparationExposures = parseIngredientsArray(json["preparationExposures"])
        let possibleCrossContamination = parseIngredientsArray(json["possibleCrossContamination"])

        return InferredMealAnalysis(
            foodName: foodName,
            isGenericFood: true,
            likelyIngredients: likelyIngredients,
            preparationExposures: preparationExposures,
            possibleCrossContamination: possibleCrossContamination
        )
    }

    private func parseIngredientsArray(_ value: Any?) -> [InferredIngredient] {
        guard let array = value as? [[String: Any]] else { return [] }

        return array.compactMap { item -> InferredIngredient? in
            guard let id = item["id"] as? String,
                  let name = item["name"] as? String,
                  !name.isEmpty else { return nil }

            let categoryString = item["category"] as? String ?? "base"
            let category = InferredIngredientCategory(rawValue: categoryString) ?? .base

            let confidenceString = item["confidence"] as? String ?? "medium"
            let confidence = InferredIngredientConfidence(rawValue: confidenceString) ?? .medium

            let explanation = item["explanation"] as? String

            return InferredIngredient(
                id: id,
                name: name,
                category: category,
                confidence: confidence,
                source: .estimated,
                explanation: explanation,
                isUserEdited: false
            )
        }
    }

    // MARK: - Check If Food Needs Inference

    /// Determines if a food item should have its ingredients inferred
    /// - Parameters:
    ///   - hasIngredients: Does the food have known ingredients?
    ///   - hasBrand: Does the food have a brand?
    ///   - hasBarcode: Does the food have a barcode?
    /// - Returns: True if inference is recommended
    func shouldInferIngredients(hasIngredients: Bool, hasBrand: Bool, hasBarcode: Bool) -> Bool {
        // If we already have ingredients, no inference needed
        if hasIngredients { return false }

        // Branded products with barcodes usually have ingredients in database
        if hasBarcode && hasBrand { return false }

        // Generic foods without ingredients need inference
        return true
    }

    // MARK: - Convert Exact Ingredients to Inferred Format

    /// Convert existing [String] ingredients to InferredIngredient format (all marked as exact)
    static func convertExactIngredients(_ ingredients: [String]?) -> [InferredIngredient]? {
        guard let ingredients = ingredients, !ingredients.isEmpty else { return nil }

        return ingredients.map { name in
            InferredIngredient.exact(name: name)
        }
    }

    // MARK: - Merge Inferred with User Edits

    /// Merge AI-inferred ingredients with user edits
    /// User edits take precedence - added items stay, removed items are gone
    static func mergeWithUserEdits(
        inferred: [InferredIngredient],
        userAdded: [InferredIngredient],
        userRemoved: Set<String>  // Set of ingredient IDs to remove
    ) -> [InferredIngredient] {
        // Start with inferred, remove user-deleted items
        var result = inferred.filter { !userRemoved.contains($0.id) }

        // Add user-added items (marked as user-edited)
        result.append(contentsOf: userAdded.map { ingredient in
            var edited = ingredient
            edited.source = .userEdited
            edited.isUserEdited = true
            return edited
        })

        return result
    }

    // MARK: - Contextual Questions

    /// Generate optional contextual questions to improve inference accuracy
    /// These are non-medical, data-quality questions
    static func contextualQuestions(for foodName: String) -> [ContextualQuestion] {
        let lowerName = foodName.lowercased()

        var questions: [ContextualQuestion] = []

        // Fried foods - ask about oil type
        if lowerName.contains("fried") || lowerName.contains("chips") || lowerName.contains("battered") {
            questions.append(ContextualQuestion(
                question: "Do you know what oil this was fried in?",
                options: ["Vegetable oil", "Sunflower oil", "Beef dripping", "Palm oil", "Don't know"],
                fieldKey: "oilType"
            ))
        }

        // Meat preparation
        if lowerName.contains("chicken") || lowerName.contains("beef") || lowerName.contains("fish") {
            questions.append(ContextualQuestion(
                question: "How was this prepared?",
                options: ["Grilled", "Fried", "Battered", "Roasted", "Don't know"],
                fieldKey: "preparationMethod"
            ))
        }

        // Curry dishes
        if lowerName.contains("curry") {
            questions.append(ContextualQuestion(
                question: "Was cream or coconut milk used?",
                options: ["Cream-based", "Coconut milk", "Tomato-based", "Don't know"],
                fieldKey: "sauceType"
            ))
        }

        return questions
    }
}

// MARK: - Supporting Types

enum InferenceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case parseError(String)
    case serverError(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .parseError(let message):
            return "Failed to parse response: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

/// Optional contextual question for improving inference accuracy
struct ContextualQuestion: Identifiable {
    let id = UUID()
    let question: String
    let options: [String]
    let fieldKey: String  // Key for storing the answer
}
