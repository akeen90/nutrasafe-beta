//
//  AIMicronutrientParser.swift
//  NutraSafe Beta
//
//  AI-powered micronutrient extraction using Firebase Cloud Functions
//  Part of Phase 2 of the Hybrid Micronutrient Detection System
//

import Foundation
import FirebaseFunctions
import CryptoKit

// MARK: - AI Micronutrient Parser

class AIMicronutrientParser {
    static let shared = AIMicronutrientParser()

    private let functions = Functions.functions()
    private let cache = NSCache<NSString, CachedMicronutrientResult>()

    private init() {
        // Configure cache limits
        cache.countLimit = 500  // Cache up to 500 ingredient lists
    }

    // MARK: - Main Parsing Methods

    /// Parse ingredients using AI (with automatic fallback to local patterns)
    func parseIngredients(_ ingredientsText: String, useCached: Bool = true) async -> [DetectedMicronutrient] {
        // Check local cache first
        if useCached {
            let cacheKey = ingredientsText.md5Hash() as NSString
            if let cached = cache.object(forKey: cacheKey) {
                #if DEBUG
                print("✅ Using locally cached AI result (\(cached.nutrients.count) nutrients)")
                #endif
                return cached.nutrients
            }
        }

        do {
            // Try AI parsing first
            let nutrients = try await callAIParser(ingredientsText: ingredientsText)

            // Cache the result locally
            let cacheKey = ingredientsText.md5Hash() as NSString
            cache.setObject(CachedMicronutrientResult(nutrients: nutrients), forKey: cacheKey)

            #if DEBUG
            print("✅ AI parser found \(nutrients.count) micronutrients")
            #endif
            return nutrients

        } catch {
            // Fallback to local pattern-based parser
            #if DEBUG
            print("⚠️ AI parsing failed, falling back to local pattern parser")
            #endif
            #if DEBUG
            print("   Error: \(error.localizedDescription)")
            #endif
            return fallbackToLocalParser(ingredientsText)
        }
    }

    /// Parse ingredients array using AI
    func parseIngredientsArray(_ ingredients: [String], useCached: Bool = true) async -> [DetectedMicronutrient] {
        let ingredientsText = ingredients.joined(separator: ", ")
        return await parseIngredients(ingredientsText, useCached: useCached)
    }

    // MARK: - Private Methods

    /// Call Firebase Cloud Function for AI parsing
    private func callAIParser(ingredientsText: String) async throws -> [DetectedMicronutrient] {
        // Use the cached version of the Cloud Function (server-side caching)
        let callable = functions.httpsCallable("parseMicronutrientsWithAICached")

        let result = try await callable.call([
            "ingredientsText": ingredientsText
        ])

        guard let data = result.data as? [String: Any],
              let nutrientsData = data["nutrients"] as? [[String: Any]] else {
            throw ParsingError.invalidResponse
        }

        // Parse the response
        var nutrients: [DetectedMicronutrient] = []

        for nutrientDict in nutrientsData {
            guard let nutrient = nutrientDict["nutrient"] as? String,
                  let strengthStr = nutrientDict["strength"] as? String,
                  let source = nutrientDict["source"] as? String,
                  let confidence = nutrientDict["confidence"] as? Double else {
                continue
            }

            let strength: NutrientStrength.Strength
            switch strengthStr {
            case "strong":
                strength = .strong
            case "moderate":
                strength = .moderate
            default:
                strength = .trace
            }

            nutrients.append(DetectedMicronutrient(
                nutrient: nutrient,
                strength: strength,
                source: .ai(source),
                rawText: source,
                confidence: confidence
            ))
        }

        return nutrients
    }

    /// Fallback to local pattern-based parser when AI fails
    private func fallbackToLocalParser(_ ingredientsText: String) -> [DetectedMicronutrient] {
        return IngredientMicronutrientParser.shared.parseIngredients(ingredientsText)
    }

    // MARK: - Errors

    enum ParsingError: Error {
        case invalidResponse
        case networkError
        case aiError(String)
    }
}

// MARK: - Cache Wrapper

private class CachedMicronutrientResult {
    let nutrients: [DetectedMicronutrient]
    let timestamp: Date

    init(nutrients: [DetectedMicronutrient]) {
        self.nutrients = nutrients
        self.timestamp = Date()
    }
}

// MARK: - MD5 Hashing Extension

extension String {
    func md5Hash() -> String {
        guard let data = self.data(using: .utf8) else { return self }

        let hash = Insecure.MD5.hash(data: data)
        return hash.map { String(format: "%02hhx", $0) }.joined()
    }
}
