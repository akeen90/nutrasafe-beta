//
//  AIAdditiveParser.swift
//  NutraSafe Beta
//
//  AI-powered additive extraction using Firebase Cloud Functions
//  Complements the pattern-based additive detection system
//

import Foundation
import FirebaseFunctions
import CryptoKit

// MARK: - AI Additive Parser

class AIAdditiveParser {
    static let shared = AIAdditiveParser()

    private let functions = Functions.functions()
    private let cache = NSCache<NSString, CachedAdditiveResult>()

    private init() {
        // Configure cache limits
        cache.countLimit = 500  // Cache up to 500 ingredient lists
    }

    // MARK: - Main Parsing Methods

    /// Parse ingredients using AI to detect additives (with automatic fallback to local patterns)
    func parseAdditives(_ ingredientsText: String, useCached: Bool = true) async -> [DetectedAdditive] {
        // Check local cache first
        if useCached {
            let cacheKey = ingredientsText.md5Hash() as NSString
            if let cached = cache.object(forKey: cacheKey) {
                                return cached.additives
            }
        }

        do {
            // Try AI parsing first
            let additives = try await callAIParser(ingredientsText: ingredientsText)

            // Cache the result locally
            let cacheKey = ingredientsText.md5Hash() as NSString
            cache.setObject(CachedAdditiveResult(additives: additives), forKey: cacheKey)

                        return additives

        } catch {
            // Fallback - return empty array (let the main database detection handle it)
                                    return []
        }
    }

    /// Parse ingredients array using AI
    func parseAdditivesArray(_ ingredients: [String], useCached: Bool = true) async -> [DetectedAdditive] {
        let ingredientsText = ingredients.joined(separator: ", ")
        return await parseAdditives(ingredientsText, useCached: useCached)
    }

    // MARK: - Private Methods

    /// Call Firebase Cloud Function for AI parsing
    private func callAIParser(ingredientsText: String) async throws -> [DetectedAdditive] {
        // Use the cached version of the Cloud Function (server-side caching)
        let callable = functions.httpsCallable("parseAdditivesWithAICached")

        let result = try await callable.call([
            "ingredientsText": ingredientsText
        ])

        guard let data = result.data as? [String: Any],
              let additivesData = data["additives"] as? [[String: Any]] else {
            throw ParsingError.invalidResponse
        }

        // Parse the response
        var additives: [DetectedAdditive] = []

        for additiveDict in additivesData {
            guard let name = additiveDict["name"] as? String,
                  let eNumber = additiveDict["eNumber"] as? String,
                  let category = additiveDict["category"] as? String,
                  let safetyStr = additiveDict["safety"] as? String,
                  let confidence = additiveDict["confidence"] as? Double else {
                continue
            }

            let safety: AdditiveSafety
            switch safetyStr.lowercased() {
            case "safe", "positive":
                safety = .safe
            case "caution":
                safety = .caution
            case "avoid":
                safety = .avoid
            default:
                safety = .neutral
            }

            additives.append(DetectedAdditive(
                name: name,
                eNumber: eNumber,
                category: category,
                safety: safety,
                confidence: confidence
            ))
        }

        return additives
    }

    // MARK: - Errors

    enum ParsingError: Error {
        case invalidResponse
        case networkError
        case aiError(String)
    }
}

// MARK: - Data Models

struct DetectedAdditive {
    let name: String
    let eNumber: String  // E-number or "MISC-XXX" for non-E additives
    let category: String
    let safety: AdditiveSafety
    let confidence: Double
}

enum AdditiveSafety {
    case safe
    case neutral
    case caution
    case avoid
}

// MARK: - Cache Wrapper

private class CachedAdditiveResult {
    let additives: [DetectedAdditive]
    let timestamp: Date

    init(additives: [DetectedAdditive]) {
        self.additives = additives
        self.timestamp = Date()
    }
}
