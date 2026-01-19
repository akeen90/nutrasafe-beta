//
//  ReactionLogModels.swift
//  NutraSafe Beta
//
//  Created for Reaction Log Mode
//

import Foundation
import FirebaseFirestore

// MARK: - Reaction Log Entry

struct ReactionLogEntry: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let reactionType: String  // e.g., "Headache", "Bloating", "Fatigue", "Rash"
    let reactionDate: Date
    let notes: String?
    let createdAt: Date

    // Analysis results (computed and stored)
    var triggerAnalysis: TriggerAnalysis?

    init(userId: String, reactionType: String, reactionDate: Date, notes: String? = nil) {
        self.userId = userId
        self.reactionType = reactionType
        self.reactionDate = reactionDate
        self.notes = notes
        self.createdAt = Date()
        self.triggerAnalysis = nil
    }
}

// MARK: - Trigger Analysis Results

struct TriggerAnalysis: Codable {
    let analysisDate: Date
    let timeRangeStart: Date  // Start of analysis window (X days before reaction)
    let timeRangeEnd: Date    // Reaction time

    let topFoods: [WeightedFoodScore]
    let topIngredients: [WeightedIngredientScore]
    let mealCount: Int
    let totalFoodsAnalyzed: Int

    // Computed property to get the day range used for this analysis
    var dayRange: Int {
        let hours = timeRangeEnd.timeIntervalSince(timeRangeStart) / 3600
        return Int(hours / 24)
    }

    init(timeRangeStart: Date, timeRangeEnd: Date, topFoods: [WeightedFoodScore], topIngredients: [WeightedIngredientScore], mealCount: Int, totalFoodsAnalyzed: Int) {
        self.analysisDate = Date()
        self.timeRangeStart = timeRangeStart
        self.timeRangeEnd = timeRangeEnd
        self.topFoods = topFoods
        self.topIngredients = topIngredients
        self.mealCount = mealCount
        self.totalFoodsAnalyzed = totalFoodsAnalyzed
    }
}

// MARK: - Weighted Food Score

struct WeightedFoodScore: Identifiable, Codable {
    let id: String  // Food name as identifier
    let foodName: String
    let totalScore: Double  // Weighted likelihood score (0-100)
    let recencyScore: Double  // Score from recency weighting
    let frequencyScore: Double  // Score from frequency
    let occurrences: Int  // Number of times appeared in 72h window
    let lastSeenHoursBeforeReaction: Double
    let contributingMealIds: [String]  // Diary meal IDs that contributed

    // Cross-reaction analysis
    let crossReactionFrequency: Double  // Percentage: (reactions with this food / total reactions) × 100

    // Breakdown by time window
    let occurrencesWithin24h: Int
    let occurrencesBetween24_48h: Int
    let occurrencesBetween48_72h: Int

    init(foodName: String, totalScore: Double, recencyScore: Double, frequencyScore: Double, occurrences: Int, lastSeenHoursBeforeReaction: Double, contributingMealIds: [String], crossReactionFrequency: Double, occurrencesWithin24h: Int, occurrencesBetween24_48h: Int, occurrencesBetween48_72h: Int) {
        self.id = foodName
        self.foodName = foodName
        self.totalScore = totalScore
        self.recencyScore = recencyScore
        self.frequencyScore = frequencyScore
        self.occurrences = occurrences
        self.lastSeenHoursBeforeReaction = lastSeenHoursBeforeReaction
        self.contributingMealIds = contributingMealIds
        self.crossReactionFrequency = crossReactionFrequency
        self.occurrencesWithin24h = occurrencesWithin24h
        self.occurrencesBetween24_48h = occurrencesBetween24_48h
        self.occurrencesBetween48_72h = occurrencesBetween48_72h
    }
}

// MARK: - Weighted Ingredient Score

struct WeightedIngredientScore: Identifiable, Codable {
    let id: String  // Ingredient name as identifier
    let ingredientName: String
    let totalScore: Double
    let recencyScore: Double
    let frequencyScore: Double
    let symptomAssociationScore: Double  // Boost if appears in multiple reactions of same type
    let occurrences: Int
    let lastSeenHoursBeforeReaction: Double
    let contributingFoodNames: [String]  // Which foods contained this ingredient
    let contributingMealIds: [String]

    // Cross-reaction analysis
    let crossReactionFrequency: Double  // Percentage: (reactions with this ingredient / total reactions) × 100

    // Breakdown by time window
    let occurrencesWithin24h: Int
    let occurrencesBetween24_48h: Int
    let occurrencesBetween48_72h: Int

    // Symptom correlation data
    let appearedInReactionCount: Int  // How many total reactions this ingredient appeared before
    let appearedInSameSymptomCount: Int  // How many reactions of THIS symptom type

    // AI-Inferred Meal Analysis: Track estimated vs exact exposure sources
    // These fields track how many times this ingredient appeared from different sources
    let exactExposureCount: Int       // Times from exact ingredient labels
    let estimatedExposureCount: Int   // Times from AI-inferred generic foods

    /// Returns true if this ingredient was primarily from estimated (AI-inferred) sources
    /// Used to display "Estimated" badge in the UI
    var isPrimarilyEstimated: Bool {
        estimatedExposureCount > exactExposureCount
    }

    /// Percentage of exposures from exact (labeled) sources
    var exactExposurePercentage: Double {
        let total = exactExposureCount + estimatedExposureCount
        guard total > 0 else { return 100.0 }  // Default to 100% exact if no data
        return (Double(exactExposureCount) / Double(total)) * 100.0
    }

    /// Display label for source breakdown
    var sourceLabel: String {
        if estimatedExposureCount == 0 {
            return "From labels"
        } else if exactExposureCount == 0 {
            return "Estimated"
        } else {
            return "Mixed sources"
        }
    }

    init(ingredientName: String, totalScore: Double, recencyScore: Double, frequencyScore: Double, symptomAssociationScore: Double, occurrences: Int, lastSeenHoursBeforeReaction: Double, contributingFoodNames: [String], contributingMealIds: [String], crossReactionFrequency: Double, occurrencesWithin24h: Int, occurrencesBetween24_48h: Int, occurrencesBetween48_72h: Int, appearedInReactionCount: Int, appearedInSameSymptomCount: Int, exactExposureCount: Int = 0, estimatedExposureCount: Int = 0) {
        self.id = ingredientName
        self.ingredientName = ingredientName
        self.totalScore = totalScore
        self.recencyScore = recencyScore
        self.frequencyScore = frequencyScore
        self.symptomAssociationScore = symptomAssociationScore
        self.occurrences = occurrences
        self.lastSeenHoursBeforeReaction = lastSeenHoursBeforeReaction
        self.contributingFoodNames = contributingFoodNames
        self.contributingMealIds = contributingMealIds
        self.crossReactionFrequency = crossReactionFrequency
        self.occurrencesWithin24h = occurrencesWithin24h
        self.occurrencesBetween24_48h = occurrencesBetween24_48h
        self.occurrencesBetween48_72h = occurrencesBetween48_72h
        self.appearedInReactionCount = appearedInReactionCount
        self.appearedInSameSymptomCount = appearedInSameSymptomCount
        self.exactExposureCount = exactExposureCount
        self.estimatedExposureCount = estimatedExposureCount
    }
}

// MARK: - Predefined Reaction Types

enum ReactionType: String, CaseIterable {
    case headache = "Headache"
    case bloating = "Bloating"
    case fatigue = "Fatigue"
    case rash = "Rash"
    case nausea = "Nausea"
    case stomachPain = "Stomach Pain"
    case diarrhea = "Diarrhea"
    case constipation = "Constipation"
    case jointPain = "Joint Pain"
    case brainFog = "Brain Fog"
    case anxiety = "Anxiety"
    case insomnia = "Insomnia"
    case custom = "Other"

    var icon: String {
        switch self {
        case .headache: return "brain.head.profile"
        case .bloating: return "figure.stand.dress"
        case .fatigue: return "bed.double.fill"
        case .rash: return "allergens"
        case .nausea: return "cross.case.fill"
        case .stomachPain: return "figure.walk.motion"
        case .diarrhea: return "toilet.fill"
        case .constipation: return "toilet"
        case .jointPain: return "figure.flexibility"
        case .brainFog: return "cloud.fog.fill"
        case .anxiety: return "wind"
        case .insomnia: return "moon.zzz.fill"
        case .custom: return "ellipsis.circle"
        }
    }
}
