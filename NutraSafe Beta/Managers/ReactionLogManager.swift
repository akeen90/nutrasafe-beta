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

    func saveReactionLog(reactionType: String, reactionDate: Date, notes: String?) async throws -> ReactionLogEntry {
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

        // Perform analysis
        let analysis = try await analyzeReactionTriggers(reactionDate: reactionDate, reactionType: reactionType, userId: userId)
        entry.triggerAnalysis = analysis

        // Save to Firebase
        let savedEntry = try await FirebaseManager.shared.saveReactionLog(entry)

        // Add to local array
        reactionLogs.append(savedEntry)
        reactionLogs.sort { $0.reactionDate > $1.reactionDate }

        return savedEntry
    }

    // MARK: - Weighted Trigger Analysis

    func analyzeReactionTriggers(reactionDate: Date, reactionType: String, userId: String) async throws -> TriggerAnalysis {
        // Define 72-hour window
        let timeRangeEnd = reactionDate
        let timeRangeStart = reactionDate.addingTimeInterval(-72 * 3600)  // 72 hours before

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

        // Use meals directly (FoodEntry objects already have dates and IDs)
        var allFoods: [(food: FoodEntry, mealId: String, mealDate: Date)] = []
        for meal in meals {
            allFoods.append((food: meal, mealId: meal.id, mealDate: meal.date))
        }

        // Calculate food scores
        let foodScores = calculateWeightedFoodScores(
            foods: allFoods,
            reactionDate: reactionDate,
            userId: userId,
            reactionType: reactionType
        )

        // Calculate ingredient scores
        let ingredientScores = await calculateWeightedIngredientScores(
            foods: allFoods,
            reactionDate: reactionDate,
            userId: userId,
            reactionType: reactionType
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
        reactionType: String
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

            let score = WeightedFoodScore(
                foodName: foodName,
                totalScore: totalScore,
                recencyScore: recencyScore,
                frequencyScore: frequencyScore,
                occurrences: data.occurrences,
                lastSeenHoursBeforeReaction: data.lastSeenHours,
                contributingMealIds: Array(Set(data.mealIds)),  // Remove duplicates
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
        reactionType: String
    ) async -> [WeightedIngredientScore] {
        var ingredientData: [String: (
            occurrences: Int,
            foodNames: Set<String>,
            mealIds: [String],
            lastSeenHours: Double,
            within24h: Int,
            between24_48h: Int,
            between48_72h: Int
        )] = [:]

        // Aggregate ingredient occurrences from all foods
        for item in foods {
            let hoursBeforeReaction = reactionDate.timeIntervalSince(item.mealDate) / 3600

            // Parse ingredients from the food
            let ingredients = extractIngredients(from: item.food)

            for ingredient in ingredients {
                if ingredientData[ingredient] == nil {
                    ingredientData[ingredient] = (0, [], [], hoursBeforeReaction, 0, 0, 0)
                }

                ingredientData[ingredient]!.occurrences += 1
                ingredientData[ingredient]!.foodNames.insert(item.food.foodName)
                ingredientData[ingredient]!.mealIds.append(item.mealId)

                // Update last seen
                if hoursBeforeReaction < ingredientData[ingredient]!.lastSeenHours {
                    ingredientData[ingredient]!.lastSeenHours = hoursBeforeReaction
                }

                // Count by time window
                if hoursBeforeReaction < 24 {
                    ingredientData[ingredient]!.within24h += 1
                } else if hoursBeforeReaction < 48 {
                    ingredientData[ingredient]!.between24_48h += 1
                } else {
                    ingredientData[ingredient]!.between48_72h += 1
                }
            }
        }

        // Get historical symptom associations
        let symptomAssociations = await getSymptomAssociations(userId: userId, reactionType: reactionType)

        // Calculate scores
        var scores: [WeightedIngredientScore] = []

        for (ingredientName, data) in ingredientData {
            // Recency score: 70% for <24h, 20% for 24-48h, 10% for 48-72h
            let recencyScore = Double(data.within24h) * 70.0 +
                               Double(data.between24_48h) * 20.0 +
                               Double(data.between48_72h) * 10.0

            // Frequency score
            let frequencyScore = Double(data.occurrences) * 10.0

            // Symptom association score
            let association = symptomAssociations[ingredientName] ?? (total: 0, sameSymptom: 0)
            let symptomBoost = association.sameSymptom >= 2 ? 25.0 : 0.0  // Boost if appears in 2+ reactions of same type

            // Total score
            let totalScore = recencyScore + frequencyScore + symptomBoost

            let score = WeightedIngredientScore(
                ingredientName: ingredientName,
                totalScore: totalScore,
                recencyScore: recencyScore,
                frequencyScore: frequencyScore,
                symptomAssociationScore: symptomBoost,
                occurrences: data.occurrences,
                lastSeenHoursBeforeReaction: data.lastSeenHours,
                contributingFoodNames: Array(data.foodNames),
                contributingMealIds: Array(Set(data.mealIds)),
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

            // Count ingredient appearances
            for ingredient in analysis.topIngredients {
                if associations[ingredient.ingredientName] == nil {
                    associations[ingredient.ingredientName] = (0, 0)
                }

                associations[ingredient.ingredientName]!.total += 1

                if isSameSymptom {
                    associations[ingredient.ingredientName]!.sameSymptom += 1
                }
            }
        }

        return associations
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
