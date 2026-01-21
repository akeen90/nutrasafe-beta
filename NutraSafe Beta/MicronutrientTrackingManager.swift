//
//  MicronutrientTrackingManager.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-10-21.
//  Manager for tracking micronutrient intake and generating insights
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

@MainActor
class MicronutrientTrackingManager: ObservableObject {
    static let shared = MicronutrientTrackingManager()

    @Published private(set) var dailyScores: [String: [DailyNutrientScore]] = [:] // nutrient → scores
    @Published private(set) var balanceHistory: [NutrientBalanceScore] = []
    @Published private(set) var isLoading = false
    private var hasLoadedData = false // Track if we've loaded data to avoid duplicate loads

    // MEMORY CACHE: Session-based cache to avoid redundant Firebase queries
    private var firebaseCache: (scores: [String: [DailyNutrientScore]], balance: [NutrientBalanceScore])? = nil
    private var cacheTimestamp: Date? = nil
    private let cacheExpirationSeconds: TimeInterval = 300 // 5 minutes

    private let database = MicronutrientDatabase.shared
    private let db = Firestore.firestore()

    private init() {
        // Don't load on init - use lazy loading instead
    }

    // MARK: - Food Analysis

    /// Analyze a food item and return micronutrient contributions
    func analyzeFoodItem(name: String, ingredients: [String] = []) -> FoodMicronutrientAnalysis {
        let nutrients = database.analyzeFoodItem(name: name, ingredients: ingredients)
        return FoodMicronutrientAnalysis(foodName: name, nutrients: nutrients)
    }

    /// Process a logged food and update daily scores
    func processFoodLog(name: String, ingredients: [String] = [], date: Date = Date()) async {
        let analysis = analyzeFoodItem(name: name, ingredients: ingredients)

        // Update scores for each nutrient found
        for (nutrient, strength) in analysis.nutrients {
            await updateDailyScore(
                nutrient: nutrient,
                date: date,
                points: strength.points,
                source: name
            )
        }

        // Recalculate balance for the day
        await updateBalanceScore(for: date)

    }

    /// Convert camelCase nutrient keys to database format (underscore separated)
    private func normalizeNutrientKey(_ key: String) -> String {
        // Map common camelCase formats to database keys
        let mappings: [String: String] = [
            // Vitamins
            "vitaminA": "Vitamin_A",
            "vitaminC": "Vitamin_C",
            "vitaminD": "Vitamin_D",
            "vitaminE": "Vitamin_E",
            "vitaminK": "Vitamin_K",
            "thiamine": "Thiamin_B1",
            "riboflavin": "Riboflavin_B2",
            "niacin": "Niacin_B3",
            "pantothenicAcid": "Pantothenic_B5",
            "vitaminB6": "Vitamin_B6",
            "biotin": "Biotin_B7",
            "folate": "Folate_B9",
            "vitaminB12": "Vitamin_B12",
            "choline": "Choline",

            // Minerals
            "calcium": "Calcium",
            "iron": "Iron",
            "magnesium": "Magnesium",
            "phosphorus": "Phosphorus",
            "potassium": "Potassium",
            "sodium": "Sodium",
            "zinc": "Zinc",
            "copper": "Copper",
            "manganese": "Manganese",
            "selenium": "Selenium",
            "chromium": "Chromium",
            "molybdenum": "Molybdenum",
            "iodine": "Iodine",

            // Other nutrients (carotenoids, etc.)
            "betaCarotene": "Beta_Carotene",
            "lutein": "Lutein_Zeaxanthin",
            "lycopene": "Lycopene"
        ]

        return mappings[key] ?? key
    }

    /// Process actual micronutrient data from a food's nutrient profile
    func processNutrientProfile(_ profile: MicronutrientProfile, foodName: String, servingSize: Double = 1.0, date: Date = Date()) async {
        
        var processedCount = 0

        // Process vitamins
        for (nutrientKey, amount) in profile.vitamins {
            guard amount > 0 else {
                continue
            }

            // Get the recommended daily value for this nutrient
            let dailyValue = profile.recommendedIntakes.getDailyValue(for: nutrientKey)
            if dailyValue == 0 {
                continue
            }

            // Calculate percentage of daily value (accounting for serving size)
            let percentage = Int((amount * servingSize / dailyValue) * 100)

            // Convert percentage to points (capped at 100 to avoid over-counting)
            let points = min(percentage, 100)

            if points > 0 {
                // Normalize the key to match database format
                let normalizedKey = normalizeNutrientKey(nutrientKey)

                await updateDailyScore(
                    nutrient: normalizedKey,
                    date: date,
                    points: points,
                    source: foodName
                )
                processedCount += 1
                            }
        }

        // Process minerals
        for (nutrientKey, amount) in profile.minerals {
            guard amount > 0 else {
                continue
            }

            // Get the recommended daily value for this nutrient
            let dailyValue = profile.recommendedIntakes.getDailyValue(for: nutrientKey)
            if dailyValue == 0 {
                continue
            }

            // Calculate percentage of daily value (accounting for serving size)
            let percentage = Int((amount * servingSize / dailyValue) * 100)

            // Convert percentage to points (capped at 100 to avoid over-counting)
            let points = min(percentage, 100)

            if points > 0 {
                // Normalize the key to match database format
                let normalizedKey = normalizeNutrientKey(nutrientKey)

                await updateDailyScore(
                    nutrient: normalizedKey,
                    date: date,
                    points: points,
                    source: foodName
                )
                processedCount += 1
                            }
        }

        // Recalculate balance for the day
        await updateBalanceScore(for: date)


            }

    // MARK: - Daily Score Management

    private func updateDailyScore(nutrient: String, date: Date, points: Int, source: String) async {
        let dateKey = formatDate(date)
        let scoreId = "\(nutrient)_\(dateKey)"

        // Get existing score or create new one
        var existingScores = dailyScores[nutrient] ?? []
        if let index = existingScores.firstIndex(where: { $0.id == scoreId }) {
            // Update existing
            let score = existingScores[index]
            let updatedPoints = score.totalPoints + points
            var updatedSources = score.sources
            if !updatedSources.contains(source) {
                updatedSources.append(source)
            }

            let updated = DailyNutrientScore(
                id: scoreId,
                nutrient: nutrient,
                date: date,
                totalPoints: updatedPoints,
                sources: updatedSources
            )
            existingScores[index] = updated
        } else {
            // Create new
            let newScore = DailyNutrientScore(
                id: scoreId,
                nutrient: nutrient,
                date: date,
                totalPoints: points,
                sources: [source]
            )
            existingScores.append(newScore)
        }

        dailyScores[nutrient] = existingScores
    }

    // MARK: - Balance Score Calculation

    private func updateBalanceScore(for date: Date) async {
        let dateKey = formatDate(date)

        // Get all nutrients tracked today
        var nutrientCounts: [MicronutrientStatus: Int] = [.low: 0, .adequate: 0, .strong: 0]
        var trackedNutrients = Set<String>()
        var totalPercentage = 0

        for (nutrient, scores) in dailyScores {
            if let score = scores.first(where: { formatDate($0.date) == dateKey }) {
                trackedNutrients.insert(nutrient)
                nutrientCounts[score.status, default: 0] += 1
                totalPercentage += score.percentage
            }
        }

        // Calculate average coverage across all tracked nutrients
        let averageCoverage = trackedNutrients.count > 0 ? totalPercentage / trackedNutrients.count : 0

        let balance = NutrientBalanceScore(
            date: date,
            totalNutrientsTracked: trackedNutrients.count,
            strongCount: nutrientCounts[.strong] ?? 0,
            adequateCount: nutrientCounts[.adequate] ?? 0,
            lowCount: nutrientCounts[.low] ?? 0,
            averageCoverage: averageCoverage
        )

        // Update or append to history
        if let index = balanceHistory.firstIndex(where: { formatDate($0.date) == dateKey }) {
            balanceHistory[index] = balance
        } else {
            balanceHistory.append(balance)
            balanceHistory.sort { $0.date > $1.date }
        }
    }

    // MARK: - Summary Generation

    /// Get summary for a specific nutrient
    func getNutrientSummary(for nutrient: String) -> MicronutrientSummary? {
        let today = Date()
        let todayKey = formatDate(today)

        // Get scores if they exist
        let scores = dailyScores[nutrient] ?? []

        // Today's data
        let todayScore = scores.first(where: { formatDate($0.date) == todayKey })
        let todayPercentage = todayScore?.percentage ?? 0
        let todayStatus = MicronutrientStatus.from(percentage: todayPercentage)

        // 7-day average
        let last7Days = getLast7Days()
        let last7DaysScores = scores.filter { score in
            last7Days.contains(where: { formatDate($0) == formatDate(score.date) })
        }
        let sevenDayAverage = last7DaysScores.isEmpty ? 0.0 : Double(last7DaysScores.reduce(0) { $0 + $1.percentage }) / Double(last7DaysScores.count)
        let sevenDayStatus = MicronutrientStatus.from(percentage: Int(sevenDayAverage))

        // Trend (compare last 3 days vs previous 4 days)
        let trend = calculateTrend(for: last7DaysScores)

        // Recent sources - FILTERED using strict validation rules
        // This prevents showing ultra-processed foods (like Revels) as sources of vitamins
        let rawSources = Array(Set(last7DaysScores.flatMap { $0.sources }))
        let validator = StrictMicronutrientValidator.shared
        let recentSources = rawSources.filter { foodName in
            // Check if this food should actually contribute this nutrient
            // Ultra-processed foods (chocolate, sweets, biscuits, crisps) are excluded
            // unless they have explicit fortification for this specific nutrient
            !validator.shouldRestrictMicronutrientInference(foodName: foodName, ingredients: [])
        }.sorted()

        // Get nutrient info
        let info = database.getNutrientInfo(nutrient)

        return MicronutrientSummary(
            id: nutrient,
            nutrient: nutrient,
            name: info?.name ?? nutrient,
            todayPercentage: todayPercentage,
            todayStatus: todayStatus,
            sevenDayAverage: sevenDayAverage,
            sevenDayStatus: sevenDayStatus,
            trend: trend.trend,
            trendPercentageChange: trend.change,
            recentSources: recentSources,
            info: info
        )
    }

    /// Get summaries for all tracked nutrients (lazy loads data if needed)
    func getAllNutrientSummaries() async -> [MicronutrientSummary] {
        // Lazy load data on first access
        await ensureDataLoaded()

        let allNutrients = database.getAllNutrients()
        return allNutrients
            .filter {
                $0.nutrient != "Fluoride" &&
                $0.nutrient != "Sodium" &&
                $0.nutrient != "Omega3_ALA" &&
                $0.nutrient != "Omega3_EPA_DHA" &&
                $0.nutrient != "Beta_Carotene" &&
                $0.nutrient != "Lutein_Zeaxanthin" &&
                $0.nutrient != "Lycopene"
            }
            .compactMap { info in
                getNutrientSummary(for: info.nutrient)
            }
            .sorted { $0.name < $1.name }
    }

    /// Ensure data is loaded before accessing (lazy loading)
    private func ensureDataLoaded() async {
        guard !hasLoadedData else {
            return
        }

        await loadFromFirestore()
        hasLoadedData = true
    }

    /// Get today's balance score
    func getTodayBalance() -> NutrientBalanceScore? {
        let todayKey = formatDate(Date())
        return balanceHistory.first(where: { formatDate($0.date) == todayKey })
    }

    /// Generate insights for today (async - lazy loads data if needed)
    func generateTodayInsights() async -> [String] {
        let summaries = await getAllNutrientSummaries()
        return NutrientInsightGenerator.generateInsights(for: summaries)
    }

    /// Save all daily scores to Firebase (call after batch processing foods)
    func saveAllScores() async {
        await saveDailyScores()
    }

    /// STRICT MODE: Clear cached scores to force reprocessing with new validation rules.
    /// Call this after updating to strict micronutrient detection to clear old incorrect data.
    func clearCachedScores() async {
        // Clear in-memory cache
        dailyScores = [:]
        balanceHistory = []
        hasLoadedData = false
        firebaseCache = nil
        cacheTimestamp = nil

        // Clear Firebase scores for this user
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        do {
            // Delete micronutrient_scores collection
            let scoresSnapshot = try await db.collection("users")
                .document(userId)
                .collection("micronutrient_scores")
                .getDocuments()

            for doc in scoresSnapshot.documents {
                try await doc.reference.delete()
            }

            // Delete nutrient_balance collection
            let balanceSnapshot = try await db.collection("users")
                .document(userId)
                .collection("nutrient_balance")
                .getDocuments()

            for doc in balanceSnapshot.documents {
                try await doc.reference.delete()
            }

            print("[MicronutrientTrackingManager] Cleared all cached scores - will reprocess with strict validation")
        } catch {
            print("[MicronutrientTrackingManager] Error clearing cached scores: \(error)")
        }
    }

    // MARK: - Trend Calculation

    private func calculateTrend(for scores: [DailyNutrientScore]) -> (trend: NutrientTrend, change: Double) {
        guard scores.count >= 4 else {
            return (.stable, 0.0)
        }

        let sortedScores = scores.sorted { $0.date < $1.date }

        // Last 3 days vs previous 4 days
        let recentScores = Array(sortedScores.suffix(3))
        let previousScores = Array(sortedScores.dropLast(3).suffix(4))

        guard !recentScores.isEmpty && !previousScores.isEmpty else {
            return (.stable, 0.0)
        }

        let recentAvg = Double(recentScores.reduce(0) { $0 + $1.percentage }) / Double(recentScores.count)
        let previousAvg = Double(previousScores.reduce(0) { $0 + $1.percentage }) / Double(previousScores.count)

        let percentageChange = ((recentAvg - previousAvg) / previousAvg) * 100.0

        return (NutrientTrend.from(change: percentageChange), percentageChange)
    }

    // MARK: - Helpers

    private func getLast7Days() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<7).compactMap { daysAgo in
            calendar.date(byAdding: .day, value: -daysAgo, to: today)
        }
    }

    // PERFORMANCE: Static DateFormatter to avoid recreation on every call
    // DateFormatter creation is expensive (~10ms per instance)
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = Calendar.current.timeZone
        return formatter
    }()

    private func formatDate(_ date: Date) -> String {
        return Self.dateFormatter.string(from: date)
    }

    // MARK: - Persistence

    private func saveDailyScores() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // MEMORY CACHE: Invalidate cache when saving new data
        firebaseCache = nil
        cacheTimestamp = nil

        // Save to Firestore
        for (_, scores) in dailyScores {
            for score in scores {
                let docRef = db.collection("users")
                    .document(userId)
                    .collection("micronutrient_scores")
                    .document(score.id)

                do {
                    try await docRef.setData([
                        "nutrient": score.nutrient,
                        "date": Timestamp(date: score.date),
                        "totalPoints": score.totalPoints,
                        "sources": score.sources,
                        "percentage": score.percentage
                    ])
                } catch {
                                    }
            }
        }

        // Save balance history
        for balance in balanceHistory {
            let dateKey = formatDate(balance.date)
            let docRef = db.collection("users")
                .document(userId)
                .collection("nutrient_balance")
                .document(dateKey)

            do {
                try await docRef.setData([
                    "date": Timestamp(date: balance.date),
                    "totalNutrientsTracked": balance.totalNutrientsTracked,
                    "strongCount": balance.strongCount,
                    "adequateCount": balance.adequateCount,
                    "lowCount": balance.lowCount,
                    "averageCoverage": balance.averageCoverage,
                    "balancePercentage": balance.balancePercentage
                ])
            } catch {
                            }
        }
    }

    private func loadFromFirestore() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // MEMORY CACHE: Check if we have fresh cached data
        if let cache = firebaseCache,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheExpirationSeconds {
            dailyScores = cache.scores
            balanceHistory = cache.balance
            return
        }

        isLoading = true
        defer { isLoading = false }

        // OPTIMIZED: Load only last 7 days instead of 30 for faster initial load
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        do {
            // Load nutrient scores
            let scoresSnapshot = try await db.collection("users")
                .document(userId)
                .collection("micronutrient_scores")
                .whereField("date", isGreaterThan: Timestamp(date: sevenDaysAgo))
                .getDocuments()

            var loadedScores: [String: [DailyNutrientScore]] = [:]

            for doc in scoresSnapshot.documents {
                let data = doc.data()
                guard let nutrient = data["nutrient"] as? String,
                      let timestamp = data["date"] as? Timestamp,
                      let totalPoints = data["totalPoints"] as? Int,
                      let sources = data["sources"] as? [String] else {
                    continue
                }

                let score = DailyNutrientScore(
                    id: doc.documentID,
                    nutrient: nutrient,
                    date: timestamp.dateValue(),
                    totalPoints: totalPoints,
                    sources: sources
                )

                loadedScores[nutrient, default: []].append(score)
            }

            dailyScores = loadedScores

            // Load balance history
            let balanceSnapshot = try await db.collection("users")
                .document(userId)
                .collection("nutrient_balance")
                .whereField("date", isGreaterThan: Timestamp(date: sevenDaysAgo))
                .getDocuments()

            var loadedBalance: [NutrientBalanceScore] = []

            for doc in balanceSnapshot.documents {
                let data = doc.data()
                guard let timestamp = data["date"] as? Timestamp,
                      let totalTracked = data["totalNutrientsTracked"] as? Int,
                      let strong = data["strongCount"] as? Int,
                      let adequate = data["adequateCount"] as? Int,
                      let low = data["lowCount"] as? Int else {
                    continue
                }

                // Get average coverage if available, otherwise calculate from counts
                let averageCoverage: Int
                if let storedAverage = data["averageCoverage"] as? Int {
                    averageCoverage = storedAverage
                } else {
                    // Fallback calculation for legacy data
                    let weighted = (strong * 100) + (adequate * 50)
                    averageCoverage = totalTracked > 0 ? (weighted * 100) / (totalTracked * 100) : 0
                }

                let balance = NutrientBalanceScore(
                    date: timestamp.dateValue(),
                    totalNutrientsTracked: totalTracked,
                    strongCount: strong,
                    adequateCount: adequate,
                    lowCount: low,
                    averageCoverage: averageCoverage
                )

                loadedBalance.append(balance)
            }

            balanceHistory = loadedBalance.sorted { $0.date > $1.date }

            
            // MEMORY CACHE: Cache the loaded data
            firebaseCache = (scores: dailyScores, balance: balanceHistory)
            cacheTimestamp = Date()

        } catch {
                    }
    }
}
