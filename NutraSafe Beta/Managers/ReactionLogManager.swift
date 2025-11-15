//
//  ReactionLogManager.swift
//  NutraSafe Beta
//
//  Manages reaction logging and weighted trigger analysis
//

import Foundation
import SwiftUI

@MainActor
class ReactionLogManager: ObservableObject {
    static let shared = ReactionLogManager()

    @Published var reactionLogs: [ReactionLogEntry] = []
    @Published var isLoading: Bool = false

    private init() {}

    // MARK: - Load Reaction Logs

    func loadReactionLogs() async {
        guard let userId = FirebaseManager.shared.currentUser?.uid else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            reactionLogs = try await FirebaseManager.shared.getReactionLogs(userId: userId)
        } catch {
            print("Error loading reaction logs: \(error.localizedDescription)")
        }
    }

    // MARK: - Save New Reaction Log

    func saveReactionLog(reactionType: String, reactionDate: Date, notes: String?, dayRange: Int = 3) async throws -> ReactionLogEntry {
        guard let userId = FirebaseManager.shared.currentUser?.uid else {
            throw NSError(domain: "ReactionLog", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }

        // Create the log entry
        var entry = ReactionLogEntry(
            userId: userId,
            reactionType: reactionType,
            reactionDate: reactionDate,
            notes: notes
        )

        // Perform analysis with configurable day range
        let analysis = try await analyzeReactionTriggers(
            reactionDate: reactionDate,
            reactionType: reactionType,
            userId: userId,
            dayRange: dayRange
        )
        entry.triggerAnalysis = analysis

        // Save to Firebase
        let savedEntry = try await FirebaseManager.shared.saveReactionLog(entry)

        // Add to local array
        reactionLogs.append(savedEntry)
        reactionLogs.sort { $0.reactionDate > $1.reactionDate }

        return savedEntry
    }

    // MARK: - Weighted Trigger Analysis

    func analyzeReactionTriggers(reactionDate: Date, reactionType: String, userId: String, dayRange: Int = 3) async throws -> TriggerAnalysis {
        // Define configurable day window
        let timeRangeEnd = reactionDate
        let timeRangeStart = reactionDate.addingTimeInterval(-Double(dayRange * 24 * 3600))  // dayRange days before

        // Fetch diary meals in this window
        let meals = try await DiaryDataManager.shared.getMealsInTimeRange(from: timeRangeStart, to: timeRangeEnd)

        guard !meals.isEmpty else {
            // No meals found - return empty analysis
            return TriggerAnalysis(
                timeRangeStart: timeRangeStart,
                timeRangeEnd: timeRangeEnd,
                topFoods: [],
                topIngredients: [],
                mealCount: 0,
                totalFoodsAnalyzed: 0
            )
        }

        // Get meal IDs that were already analyzed in previous reactions (duplicate prevention)
        let previouslyAnalyzedMealIds = getPreviouslyAnalyzedMealIds(userId: userId, beforeDate: reactionDate)

        // Filter out meals that were already analyzed in previous reactions
        let newMeals = meals.filter { !previouslyAnalyzedMealIds.contains($0.id) }

        // Use new meals only (not previously analyzed)
        var allFoods: [(food: FoodEntry, mealId: String, mealDate: Date)] = []
        for meal in newMeals {
            allFoods.append((food: meal, mealId: meal.id, mealDate: meal.date))
        }

        // If all meals were already analyzed, still return basic info but mark it
        guard !allFoods.isEmpty else {
            return TriggerAnalysis(
                timeRangeStart: timeRangeStart,
                timeRangeEnd: timeRangeEnd,
                topFoods: [],
                topIngredients: [],
                mealCount: newMeals.count,
                totalFoodsAnalyzed: 0
            )
        }

        // Get total reaction count for cross-reaction frequency calculation
        let totalReactions = reactionLogs.filter { $0.userId == userId }.count

        // Calculate food scores
        let foodScores = calculateWeightedFoodScores(
            foods: allFoods,
            reactionDate: reactionDate,
            userId: userId,
            reactionType: reactionType,
            totalReactions: totalReactions
        )

        // Calculate ingredient scores
        let ingredientScores = await calculateWeightedIngredientScores(
            foods: allFoods,
            reactionDate: reactionDate,
            userId: userId,
            reactionType: reactionType,
            totalReactions: totalReactions
        )

        // Sort and take top results
        let topFoods = Array(foodScores.sorted { $0.totalScore > $1.totalScore }.prefix(20))
        let topIngredients = Array(ingredientScores.sorted { $0.totalScore > $1.totalScore }.prefix(20))

        return TriggerAnalysis(
            timeRangeStart: timeRangeStart,
            timeRangeEnd: timeRangeEnd,
            topFoods: topFoods,
            topIngredients: topIngredients,
            mealCount: meals.count,
            totalFoodsAnalyzed: allFoods.count
        )
    }

    // MARK: - Calculate Weighted Food Scores

    private func calculateWeightedFoodScores(
        foods: [(food: FoodEntry, mealId: String, mealDate: Date)],
        reactionDate: Date,
        userId: String,
        reactionType: String,
        totalReactions: Int
    ) -> [WeightedFoodScore] {
        var foodData: [String: (
            occurrences: Int,
            mealIds: [String],
            lastSeenHours: Double,
            within24h: Int,
            between24_48h: Int,
            between48_72h: Int
        )] = [:]

        // Aggregate food occurrences
        for item in foods {
            let foodName = item.food.foodName
            let hoursBeforeReaction = reactionDate.timeIntervalSince(item.mealDate) / 3600

            if foodData[foodName] == nil {
                foodData[foodName] = (0, [], hoursBeforeReaction, 0, 0, 0)
            }

            foodData[foodName]!.occurrences += 1
            foodData[foodName]!.mealIds.append(item.mealId)

            // Update last seen
            if hoursBeforeReaction < foodData[foodName]!.lastSeenHours {
                foodData[foodName]!.lastSeenHours = hoursBeforeReaction
            }

            // Count by time window
            if hoursBeforeReaction < 24 {
                foodData[foodName]!.within24h += 1
            } else if hoursBeforeReaction < 48 {
                foodData[foodName]!.between24_48h += 1
            } else {
                foodData[foodName]!.between48_72h += 1
            }
        }

        // Get cross-reaction frequencies for foods
        let foodCrossReactionCounts = getFoodCrossReactionCounts(userId: userId)

        // Calculate scores
        var scores: [WeightedFoodScore] = []

        for (foodName, data) in foodData {
            // Recency score: 70% for <24h, 20% for 24-48h, 10% for 48-72h
            let recencyScore = Double(data.within24h) * 70.0 +
                               Double(data.between24_48h) * 20.0 +
                               Double(data.between48_72h) * 10.0

            // Frequency score: More occurrences = higher score
            let frequencyScore = Double(data.occurrences) * 10.0

            // Total score
            let totalScore = recencyScore + frequencyScore

            // Cross-reaction frequency: (reactions with this food / total reactions) × 100
            let reactionsWithThisFood = foodCrossReactionCounts[foodName] ?? 0
            let crossReactionFrequency = totalReactions > 0 ? (Double(reactionsWithThisFood) / Double(totalReactions)) * 100.0 : 0.0

            let score = WeightedFoodScore(
                foodName: foodName,
                totalScore: totalScore,
                recencyScore: recencyScore,
                frequencyScore: frequencyScore,
                occurrences: data.occurrences,
                lastSeenHoursBeforeReaction: data.lastSeenHours,
                contributingMealIds: Array(Set(data.mealIds)),  // Remove duplicates
                crossReactionFrequency: crossReactionFrequency,
                occurrencesWithin24h: data.within24h,
                occurrencesBetween24_48h: data.between24_48h,
                occurrencesBetween48_72h: data.between48_72h
            )

            scores.append(score)
        }

        return scores
    }

    // MARK: - Calculate Weighted Ingredient Scores

    private func calculateWeightedIngredientScores(
        foods: [(food: FoodEntry, mealId: String, mealDate: Date)],
        reactionDate: Date,
        userId: String,
        reactionType: String,
        totalReactions: Int
    ) async -> [WeightedIngredientScore] {
        var ingredientData: [String: (
            occurrences: Int,
            foodNames: Set<String>,
            mealIds: [String],
            lastSeenHours: Double,
            within24h: Int,
            between24_48h: Int,
            between48_72h: Int,
            displayName: String
        )] = [:]

        // Aggregate ingredient occurrences from all foods (case-insensitive)
        for item in foods {
            let hoursBeforeReaction = reactionDate.timeIntervalSince(item.mealDate) / 3600

            // Parse ingredients from the food
            let ingredients = extractIngredients(from: item.food)

            for ingredient in ingredients {
                // Normalize ingredient name (lowercase, trimmed) for matching
                let normalizedIngredient = ingredient.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

                if ingredientData[normalizedIngredient] == nil {
                    ingredientData[normalizedIngredient] = (0, [], [], hoursBeforeReaction, 0, 0, 0, ingredient)
                }

                ingredientData[normalizedIngredient]!.occurrences += 1
                ingredientData[normalizedIngredient]!.foodNames.insert(item.food.foodName)
                ingredientData[normalizedIngredient]!.mealIds.append(item.mealId)

                // Update last seen
                if hoursBeforeReaction < ingredientData[normalizedIngredient]!.lastSeenHours {
                    ingredientData[normalizedIngredient]!.lastSeenHours = hoursBeforeReaction
                }

                // Count by time window
                if hoursBeforeReaction < 24 {
                    ingredientData[normalizedIngredient]!.within24h += 1
                } else if hoursBeforeReaction < 48 {
                    ingredientData[normalizedIngredient]!.between24_48h += 1
                } else {
                    ingredientData[normalizedIngredient]!.between48_72h += 1
                }
            }
        }

        // Get historical symptom associations
        let symptomAssociations = await getSymptomAssociations(userId: userId, reactionType: reactionType)

        // Calculate scores
        var scores: [WeightedIngredientScore] = []

        for (normalizedName, data) in ingredientData {
            // Recency score: 70% for <24h, 20% for 24-48h, 10% for 48-72h
            let recencyScore = Double(data.within24h) * 70.0 +
                               Double(data.between24_48h) * 20.0 +
                               Double(data.between48_72h) * 10.0

            // Frequency score
            let frequencyScore = Double(data.occurrences) * 10.0

            // Symptom association score (use normalized name for lookup)
            let association = symptomAssociations[normalizedName] ?? (total: 0, sameSymptom: 0)
            let symptomBoost = association.sameSymptom >= 2 ? 25.0 : 0.0  // Boost if appears in 2+ reactions of same type

            // Total score
            let totalScore = recencyScore + frequencyScore + symptomBoost

            // Cross-reaction frequency: (reactions with this ingredient / total reactions) × 100
            let reactionsWithThisIngredient = association.total
            let crossReactionFrequency = totalReactions > 0 ? (Double(reactionsWithThisIngredient) / Double(totalReactions)) * 100.0 : 0.0

            let score = WeightedIngredientScore(
                ingredientName: data.displayName,  // Use original display name
                totalScore: totalScore,
                recencyScore: recencyScore,
                frequencyScore: frequencyScore,
                symptomAssociationScore: symptomBoost,
                occurrences: data.occurrences,
                lastSeenHoursBeforeReaction: data.lastSeenHours,
                contributingFoodNames: Array(data.foodNames),
                contributingMealIds: Array(Set(data.mealIds)),
                crossReactionFrequency: crossReactionFrequency,
                occurrencesWithin24h: data.within24h,
                occurrencesBetween24_48h: data.between24_48h,
                occurrencesBetween48_72h: data.between48_72h,
                appearedInReactionCount: association.total,
                appearedInSameSymptomCount: association.sameSymptom
            )

            scores.append(score)
        }

        return scores
    }

    // MARK: - Helper: Extract Ingredients

    private func extractIngredients(from food: FoodEntry) -> [String] {
        // FoodEntry stores ingredients as [String]? array
        if let ingredients = food.ingredients, !ingredients.isEmpty {
            return ingredients.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }

        return []
    }

    // MARK: - Helper: Get Symptom Associations

    private func getSymptomAssociations(userId: String, reactionType: String) async -> [String: (total: Int, sameSymptom: Int)] {
        // Get all past reaction logs for this user
        let pastReactions = reactionLogs.filter { $0.userId == userId }

        var associations: [String: (total: Int, sameSymptom: Int)] = [:]

        for reaction in pastReactions {
            guard let analysis = reaction.triggerAnalysis else { continue }

            let isSameSymptom = reaction.reactionType == reactionType

            // Count ingredient appearances (case-insensitive)
            for ingredient in analysis.topIngredients {
                let normalizedName = ingredient.ingredientName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

                if associations[normalizedName] == nil {
                    associations[normalizedName] = (0, 0)
                }

                associations[normalizedName]!.total += 1

                if isSameSymptom {
                    associations[normalizedName]!.sameSymptom += 1
                }
            }
        }

        return associations
    }

    // MARK: - Helper: Get Food Cross-Reaction Counts

    private func getFoodCrossReactionCounts(userId: String) -> [String: Int] {
        // Get all past reaction logs for this user
        let pastReactions = reactionLogs.filter { $0.userId == userId }

        var counts: [String: Int] = [:]

        for reaction in pastReactions {
            guard let analysis = reaction.triggerAnalysis else { continue }

            // Count food appearances
            for food in analysis.topFoods {
                counts[food.foodName, default: 0] += 1
            }
        }

        return counts
    }

    // MARK: - Helper: Get Previously Analyzed Meal IDs (Duplicate Prevention)

    private func getPreviouslyAnalyzedMealIds(userId: String, beforeDate: Date) -> Set<String> {
        // Get all past reaction logs for this user that occurred before this date
        let pastReactions = reactionLogs.filter { $0.userId == userId && $0.reactionDate < beforeDate }

        var mealIds: Set<String> = []

        for reaction in pastReactions {
            guard let analysis = reaction.triggerAnalysis else { continue }

            // Collect all meal IDs from all foods analyzed in this reaction
            for food in analysis.topFoods {
                mealIds.formUnion(food.contributingMealIds)
            }

            // Also collect from ingredients (they have meal IDs too)
            for ingredient in analysis.topIngredients {
                mealIds.formUnion(ingredient.contributingMealIds)
            }
        }

        return mealIds
    }

    // MARK: - Delete Reaction Log

    func deleteReactionLog(_ entry: ReactionLogEntry) async throws {
        guard let entryId = entry.id else { return }

        try await FirebaseManager.shared.deleteReactionLog(entryId: entryId)

        if let index = reactionLogs.firstIndex(where: { $0.id == entryId }) {
            reactionLogs.remove(at: index)
        }
    }
}
