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

    private let database = MicronutrientDatabase.shared
    private let db = Firestore.firestore()

    private init() {
        // Don't load on init - use lazy loading instead
        print("🚀 MicronutrientTrackingManager initialized (lazy loading enabled)")
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

        // Save to Firebase
        await saveDailyScores()
    }

    /// Convert camelCase nutrient keys to database format (underscore separated)
    private func normalizeNutrientKey(_ key: String) -> String {
        // Map common camelCase formats to database keys
        let mappings: [String: String] = [
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
            "iodine": "Iodine"
        ]

        return mappings[key] ?? key
    }

    /// Process actual micronutrient data from a food's nutrient profile
    func processNutrientProfile(_ profile: MicronutrientProfile, foodName: String, servingSize: Double = 1.0, date: Date = Date()) async {
        print("🔬 Processing nutrient profile for: \(foodName) (serving: \(servingSize)x)")
        print("  📊 Profile has \(profile.vitamins.count) vitamins, \(profile.minerals.count) minerals")

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
                print("  ✅ \(nutrientKey) -> \(normalizedKey): \(points)% DV")
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
                print("  ✅ \(nutrientKey) -> \(normalizedKey): \(points)% DV")
            }
        }

        // Recalculate balance for the day
        await updateBalanceScore(for: date)

        // Save to Firebase
        await saveDailyScores()

        print("✅ Successfully processed \(processedCount) nutrients for: \(foodName)")
    }

    // MARK: - Daily Score Management

    private func updateDailyScore(nutrient: String, date: Date, points: Int, source: String) async {
        let dateKey = formatDate(date)
        let scoreId = "\(nutrient)_\(dateKey)"

        // Get existing score or create new one
        var existingScores = dailyScores[nutrient] ?? []
        if let index = existingScores.firstIndex(where: { $0.id == scoreId }) {
            // Update existing
            var score = existingScores[index]
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

        // Recent sources
        let recentSources = Array(Set(last7DaysScores.flatMap { $0.sources })).sorted()

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
        return allNutrients.compactMap { info in
            getNutrientSummary(for: info.nutrient)
        }.sorted { $0.name < $1.name }
    }

    /// Ensure data is loaded before accessing (lazy loading)
    private func ensureDataLoaded() async {
        guard !hasLoadedData else {
            print("⚡️ Micronutrient data already loaded - using cache")
            return
        }

        print("🔄 Lazy loading micronutrient data on first access...")
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // MARK: - Persistence

    private func saveDailyScores() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // Save to Firestore
        for (nutrient, scores) in dailyScores {
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
                    print("❌ Error saving nutrient score: \(error)")
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
                print("❌ Error saving balance score: \(error)")
            }
        }
    }

    private func loadFromFirestore() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        isLoading = true
        defer { isLoading = false }

        // OPTIMIZED: Load only last 7 days instead of 30 for faster initial load
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        print("📊 Loading micronutrient data for last 7 days (optimized)")

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

            print("✅ Loaded \(dailyScores.count) nutrients with scores and \(balanceHistory.count) balance records")

            // Recalculate all balance scores with new formula (fixes old weighted data)
            print("🔄 Recalculating balance scores with new average coverage formula...")
            let uniqueDates = Set(dailyScores.values.flatMap { $0.map { formatDate($0.date) } })
            for dateKey in uniqueDates {
                // Parse date from dateKey
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                if let date = formatter.date(from: dateKey) {
                    await updateBalanceScore(for: date)
                }
            }
            await saveDailyScores()
            print("✅ Recalculated \(uniqueDates.count) balance scores")

        } catch {
            print("❌ Error loading micronutrient data: \(error)")
        }
    }
}
