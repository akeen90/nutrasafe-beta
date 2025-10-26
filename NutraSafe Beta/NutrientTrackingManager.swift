//
//  NutrientTrackingManager.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-10-20.
//  Manages nutrient frequency tracking with Firebase sync and rolling 30-day windows
//

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import Combine

@MainActor
class NutrientTrackingManager: ObservableObject {
    static let shared = NutrientTrackingManager()

    @Published var nutrientFrequencies: [String: NutrientFrequency] = [:]
    @Published var dayActivities: [String: DayNutrientActivity] = [:] // Key: "YYYY-MM-DD"
    @Published var isLoading = false
    @Published var lastUpdated: Date?

    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []

    private init() {
        // Initialize with all tracked nutrients
        for nutrient in NutrientDatabase.allNutrients {
            nutrientFrequencies[nutrient.id] = NutrientFrequency(
                nutrientId: nutrient.id,
                nutrientName: nutrient.displayName
            )
        }
    }

    // MARK: - User Session

    func startTracking(for userId: String) {
        guard !userId.isEmpty else {
            print("⚠️ Cannot start tracking: userId is empty")
            return
        }
        print("🚀 Starting nutrient tracking for user: \(userId)")
        Task {
            await loadUserData(userId: userId)
            await performInitialDiaryProcessing(userId: userId)
            setupRealtimeListeners(userId: userId)
        }
    }

    func stopTracking() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }

    // MARK: - Data Loading

    private func loadUserData(userId: String) async {
        guard !userId.isEmpty else {
            print("⚠️ Cannot load user data: userId is empty")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Load nutrient frequencies
            let nutrientsSnapshot = try await db.collection("users").document(userId)
                .collection("nutrientTracking").getDocuments()

            for document in nutrientsSnapshot.documents {
                let data = document.data()
                if let frequency = parseNutrientFrequency(from: data, nutrientId: document.documentID) {
                    nutrientFrequencies[document.documentID] = frequency
                }
            }

            // Load recent day activities (last 60 days for rolling window calculation)
            let sixtyDaysAgo = Calendar.current.date(byAdding: .day, value: -60, to: Date())!
            let activitiesSnapshot = try await db.collection("users").document(userId)
                .collection("dayNutrientActivity")
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: sixtyDaysAgo))
                .getDocuments()

            for document in activitiesSnapshot.documents {
                let data = document.data()
                if let activity = parseDayActivity(from: data) {
                    dayActivities[activity.dateId] = activity
                }
            }

            lastUpdated = Date()

        } catch {
            print("❌ Error loading nutrient tracking data: \(error)")
        }
    }

    private func performInitialDiaryProcessing(userId: String) async {
        print("📋 Performing initial diary data processing...")
        do {
            // Load all diary entries
            let diarySnapshot = try await db.collection("users").document(userId)
                .collection("diary")
                .getDocuments()

            print("📋 Found \(diarySnapshot.documents.count) diary entries to process")

            // Process them
            await processDiaryChanges(userId: userId, snapshot: diarySnapshot)

        } catch {
            print("❌ Error performing initial diary processing: \(error)")
        }
    }

    private func parseNutrientFrequency(from data: [String: Any], nutrientId: String) -> NutrientFrequency? {
        guard let nutrientName = data["nutrientName"] as? String else { return nil }

        let last30Days = data["last30DaysAppearances"] as? Int ?? 0
        let totalLogged = data["totalLoggedDays"] as? Int ?? 0
        let currentStreak = data["currentStreak"] as? Int ?? 0
        let bestStreak = data["bestStreak"] as? Int ?? 0

        let lastAppearanceTimestamp = data["lastAppearance"] as? Timestamp
        let lastAppearance = lastAppearanceTimestamp?.dateValue()

        // Parse food sources
        var foodSources: [FoodSource] = []
        if let sourcesData = data["topFoodSources"] as? [[String: Any]] {
            foodSources = sourcesData.compactMap { sourceData in
                guard let foodName = sourceData["foodName"] as? String,
                      let timesConsumed = sourceData["timesConsumed"] as? Int,
                      let lastConsumedTimestamp = sourceData["lastConsumed"] as? Timestamp else {
                    return nil
                }
                return FoodSource(
                    foodName: foodName,
                    brand: sourceData["brand"] as? String,
                    timesConsumed: timesConsumed,
                    lastConsumed: lastConsumedTimestamp.dateValue()
                )
            }
        }

        // Parse monthly snapshots
        var monthlySnapshots: [MonthlySnapshot] = []
        if let monthsData = data["monthlySnapshots"] as? [[String: Any]] {
            monthlySnapshots = monthsData.compactMap { monthData in
                guard let month = monthData["month"] as? Int,
                      let year = monthData["year"] as? Int,
                      let appearanceDays = monthData["appearanceDays"] as? Int,
                      let totalLoggedDays = monthData["totalLoggedDays"] as? Int else {
                    return nil
                }
                return MonthlySnapshot(
                    month: month,
                    year: year,
                    appearanceDays: appearanceDays,
                    totalLoggedDays: totalLoggedDays
                )
            }
        }

        // Parse yearly snapshots
        var yearlySnapshots: [YearlySnapshot] = []
        if let yearsData = data["yearlySnapshots"] as? [[String: Any]] {
            yearlySnapshots = yearsData.compactMap { yearData in
                guard let year = yearData["year"] as? Int,
                      let avgConsistency = yearData["averageMonthlyConsistency"] as? Double,
                      let bestMonth = yearData["bestMonth"] as? Int,
                      let worstMonth = yearData["worstMonth"] as? Int,
                      let totalDays = yearData["totalAppearanceDays"] as? Int else {
                    return nil
                }
                return YearlySnapshot(
                    year: year,
                    averageMonthlyConsistency: avgConsistency,
                    bestMonth: bestMonth,
                    worstMonth: worstMonth,
                    totalAppearanceDays: totalDays
                )
            }
        }

        return NutrientFrequency(
            nutrientId: nutrientId,
            nutrientName: nutrientName,
            last30DaysAppearances: last30Days,
            totalLoggedDays: totalLogged,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            lastAppearance: lastAppearance,
            topFoodSources: foodSources,
            monthlySnapshots: monthlySnapshots,
            yearlySnapshots: yearlySnapshots
        )
    }

    private func parseDayActivity(from data: [String: Any]) -> DayNutrientActivity? {
        guard let timestamp = data["date"] as? Timestamp,
              let nutrientsPresent = data["nutrientsPresent"] as? [String],
              let mealCount = data["mealCount"] as? Int else {
            return nil
        }

        return DayNutrientActivity(
            date: timestamp.dateValue(),
            nutrientsPresent: nutrientsPresent,
            mealCount: mealCount
        )
    }

    // MARK: - Realtime Listeners

    private func setupRealtimeListeners(userId: String) {
        // Listen to diary changes to auto-update nutrients
        let diaryListener = db.collection("users").document(userId)
            .collection("diary")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                guard error == nil, let snapshot = snapshot else { return }

                // When diary changes, recalculate nutrients
                Task {
                    await self.processDiaryChanges(userId: userId, snapshot: snapshot)
                }
            }

        listeners.append(diaryListener)
    }

    // MARK: - Diary Processing

    private func processDiaryChanges(userId: String, snapshot: QuerySnapshot) async {
        // Process each day's meals to detect nutrients
        for document in snapshot.documents {
            let data = document.data()
            guard let dateTimestamp = data["date"] as? Timestamp else { continue }

            let date = dateTimestamp.dateValue()
            let dateId = formatDateId(date)

            // Extract all foods from this day's meals
            var allFoods: [DiaryFoodItem] = []

            for mealType in ["breakfast", "lunch", "dinner", "snacks"] {
                if let foods = parseDiaryFoods(from: data[mealType]) {
                    allFoods.append(contentsOf: foods)
                }
            }

            // Detect nutrients in all foods
            print("🍽️ Processing \(allFoods.count) foods for date \(dateId)")
            var nutrientsPresent: Set<String> = []
            for food in allFoods {
                let detectedNutrients = NutrientDetector.detectNutrients(in: food)
                nutrientsPresent.formUnion(detectedNutrients)
            }

            print("✅ Day \(dateId): Found \(nutrientsPresent.count) unique nutrients across \(allFoods.count) foods")
            print("   Nutrients: \(nutrientsPresent.sorted())")

            // Update day activity
            let activity = DayNutrientActivity(
                date: date,
                nutrientsPresent: Array(nutrientsPresent),
                mealCount: allFoods.count
            )
            dayActivities[dateId] = activity

            // Update top food sources for detected nutrients
            await updateTopFoodSources(userId: userId, date: date, foods: allFoods)

            // Save to Firebase
            await saveDayActivity(userId: userId, activity: activity)
        }

        // Recalculate all nutrient frequencies based on updated day activities
        await recalculateAllFrequencies(userId: userId)
    }

    private func parseDiaryFoods(from data: Any?) -> [DiaryFoodItem]? {
        guard let foodsData = data as? [[String: Any]] else { return nil }

        return foodsData.compactMap { foodData -> DiaryFoodItem? in
            // Parse DiaryFoodItem from dictionary
            guard let name = foodData["name"] as? String,
                  let calories = foodData["calories"] as? Int else {
                return nil
            }

            // Parse micronutrient profile if available
            var micronutrientProfile: MicronutrientProfile?
            if let profileData = foodData["micronutrientProfile"] as? [String: Any] {
                if let vitaminsData = profileData["vitamins"] as? [String: Double],
                   let mineralsData = profileData["minerals"] as? [String: Double] {

                    // Parse recommended intakes
                    var recommendedIntakes = RecommendedIntakes(age: 25, gender: .other, dailyValues: [:])
                    if let riData = profileData["recommendedIntakes"] as? [String: Any] {
                        let age = riData["age"] as? Int ?? 25
                        let genderStr = riData["gender"] as? String ?? "other"
                        let gender = Gender(rawValue: genderStr) ?? .other
                        let dailyValues = riData["dailyValues"] as? [String: Double] ?? [:]

                        recommendedIntakes = RecommendedIntakes(
                            age: age,
                            gender: gender,
                            dailyValues: dailyValues
                        )
                    }

                    // Parse confidence score
                    var confidenceScore = MicronutrientConfidence.low
                    if let confidenceStr = profileData["confidenceScore"] as? String {
                        switch confidenceStr {
                        case "high": confidenceScore = .high
                        case "medium": confidenceScore = .medium
                        default: confidenceScore = .low
                        }
                    }

                    micronutrientProfile = MicronutrientProfile(
                        vitamins: vitaminsData,
                        minerals: mineralsData,
                        recommendedIntakes: recommendedIntakes,
                        confidenceScore: confidenceScore
                    )
                }
            }

            return DiaryFoodItem(
                name: name,
                brand: foodData["brand"] as? String,
                calories: calories,
                protein: foodData["protein"] as? Double ?? 0,
                carbs: foodData["carbs"] as? Double ?? 0,
                fat: foodData["fat"] as? Double ?? 0,
                fiber: foodData["fiber"] as? Double ?? 0,
                sugar: foodData["sugar"] as? Double ?? 0,
                sodium: foodData["sodium"] as? Double ?? 0,
                calcium: foodData["calcium"] as? Double ?? 0,
                servingDescription: foodData["servingDescription"] as? String ?? "100g",
                quantity: foodData["quantity"] as? Double ?? 1.0,
                ingredients: foodData["ingredients"] as? [String],
                micronutrientProfile: micronutrientProfile
            )
        }
    }

    // MARK: - Frequency Calculation

    private func recalculateAllFrequencies(userId: String) async {
        // Get last 30 days of activity
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!

        // Filter activities to last 30 days
        let recentActivities = dayActivities.values.filter { activity in
            activity.date >= thirtyDaysAgo
        }.sorted { $0.date < $1.date }

        // Count total logged days (days with at least one meal)
        let totalLoggedDays = recentActivities.filter { $0.mealCount > 0 }.count

        // Calculate frequency for each nutrient
        for nutrient in NutrientDatabase.allNutrients {
            var appearanceDays = 0
            var currentStreak = 0
            var tempStreak = 0
            var lastAppearance: Date?
            // TODO: Implement food source tracking
            // var foodSourceCounts: [String: (count: Int, brand: String?, lastSeen: Date)] = [:]

            // Iterate through days in reverse (most recent first) for streak calculation
            for activity in recentActivities.reversed() {
                if activity.nutrientsPresent.contains(nutrient.id) {
                    appearanceDays += 1
                    lastAppearance = activity.date

                    // Update current streak
                    if currentStreak == 0 {
                        currentStreak = 1
                    } else {
                        tempStreak += 1
                    }
                } else {
                    // Streak broken
                    if tempStreak > 0 {
                        currentStreak = tempStreak
                        tempStreak = 0
                    }
                }
            }

            // Update nutrient frequency
            var frequency = nutrientFrequencies[nutrient.id] ?? NutrientFrequency(
                nutrientId: nutrient.id,
                nutrientName: nutrient.displayName
            )

            frequency.last30DaysAppearances = appearanceDays
            frequency.totalLoggedDays = totalLoggedDays
            frequency.currentStreak = currentStreak
            frequency.bestStreak = max(frequency.bestStreak, currentStreak)
            frequency.lastAppearance = lastAppearance

            nutrientFrequencies[nutrient.id] = frequency

            // Save to Firebase
            await saveNutrientFrequency(userId: userId, frequency: frequency)
        }

        // Update monthly and yearly snapshots
        await updateMonthlySnapshots(userId: userId)

        lastUpdated = Date()
    }

    private func updateMonthlySnapshots(userId: String) async {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())

        // Calculate current month's data
        let monthStart = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1))!
        let monthActivities = dayActivities.values.filter { activity in
            activity.date >= monthStart
        }

        let totalLoggedDays = monthActivities.filter { $0.mealCount > 0 }.count

        // Update each nutrient's monthly snapshot
        for (nutrientId, frequency) in nutrientFrequencies {
            let appearanceDays = monthActivities.filter { $0.nutrientsPresent.contains(nutrientId) }.count

            let snapshot = MonthlySnapshot(
                month: currentMonth,
                year: currentYear,
                appearanceDays: appearanceDays,
                totalLoggedDays: totalLoggedDays
            )

            // Update in memory
            var updatedFrequency = frequency
            if let index = updatedFrequency.monthlySnapshots.firstIndex(where: { $0.id == snapshot.id }) {
                updatedFrequency.monthlySnapshots[index] = snapshot
            } else {
                updatedFrequency.monthlySnapshots.append(snapshot)
            }

            nutrientFrequencies[nutrientId] = updatedFrequency

            // Save to Firebase
            await saveMonthlySnapshot(userId: userId, nutrientId: nutrientId, snapshot: snapshot)
        }
    }

    // MARK: - Food Source Tracking

    private func updateTopFoodSources(userId: String, date: Date, foods: [DiaryFoodItem]) async {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -60, to: date) ?? date

        var updatedNutrientIds: Set<String> = []

        for food in foods {
            let detected = NutrientDetector.detectNutrients(in: food)
            for nutrientId in detected {
                var frequency = nutrientFrequencies[nutrientId] ?? NutrientFrequency(
                    nutrientId: nutrientId,
                    nutrientName: NutrientDatabase.allNutrients.first(where: { $0.id == nutrientId })?.displayName ?? nutrientId
                )

                var sources = frequency.topFoodSources.filter { $0.lastConsumed >= cutoff }
                let matchIndex = sources.firstIndex { src in
                    src.foodName.caseInsensitiveCompare(food.name) == .orderedSame &&
                    (src.brand ?? "") == (food.brand ?? "")
                }

                if let idx = matchIndex {
                    let existing = sources[idx]
                    let updated = FoodSource(
                        id: existing.id,
                        foodName: existing.foodName,
                        brand: existing.brand,
                        timesConsumed: existing.timesConsumed + 1,
                        lastConsumed: date
                    )
                    sources[idx] = updated
                } else {
                    sources.append(FoodSource(foodName: food.name, brand: food.brand, timesConsumed: 1, lastConsumed: date))
                }

                sources.sort {
                    if $0.timesConsumed == $1.timesConsumed {
                        return $0.lastConsumed > $1.lastConsumed
                    }
                    return $0.timesConsumed > $1.timesConsumed
                }
                if sources.count > 50 {
                    sources = Array(sources.prefix(50))
                }

                frequency.topFoodSources = sources
                nutrientFrequencies[nutrientId] = frequency
                updatedNutrientIds.insert(nutrientId)
            }
        }

        for nutrientId in updatedNutrientIds {
            if let frequency = nutrientFrequencies[nutrientId] {
                await saveNutrientFrequency(userId: userId, frequency: frequency)
            }
        }
    }

    // MARK: - Firebase Sync

    private func saveDayActivity(userId: String, activity: DayNutrientActivity) async {
        do {
            let data: [String: Any] = [
                "date": Timestamp(date: activity.date),
                "nutrientsPresent": activity.nutrientsPresent,
                "mealCount": activity.mealCount,
                "lastUpdated": Timestamp(date: Date())
            ]

            try await db.collection("users").document(userId)
                .collection("dayNutrientActivity")
                .document(activity.dateId)
                .setData(data, merge: true)

        } catch {
            print("❌ Error saving day activity: \(error)")
        }
    }

    private func saveNutrientFrequency(userId: String, frequency: NutrientFrequency) async {
        do {
            var data: [String: Any] = [
                "nutrientName": frequency.nutrientName,
                "last30DaysAppearances": frequency.last30DaysAppearances,
                "totalLoggedDays": frequency.totalLoggedDays,
                "currentStreak": frequency.currentStreak,
                "bestStreak": frequency.bestStreak,
                "lastUpdated": Timestamp(date: Date())
            ]

            if let lastAppearance = frequency.lastAppearance {
                data["lastAppearance"] = Timestamp(date: lastAppearance)
            }

            // Save top food sources
            data["topFoodSources"] = frequency.topFoodSources.map { source in
                [
                    "foodName": source.foodName,
                    "brand": source.brand ?? "",
                    "timesConsumed": source.timesConsumed,
                    "lastConsumed": Timestamp(date: source.lastConsumed)
                ]
            }

            try await db.collection("users").document(userId)
                .collection("nutrientTracking")
                .document(frequency.nutrientId)
                .setData(data, merge: true)

        } catch {
            print("❌ Error saving nutrient frequency: \(error)")
        }
    }

    private func saveMonthlySnapshot(userId: String, nutrientId: String, snapshot: MonthlySnapshot) async {
        do {
            let data: [String: Any] = [
                "month": snapshot.month,
                "year": snapshot.year,
                "appearanceDays": snapshot.appearanceDays,
                "totalLoggedDays": snapshot.totalLoggedDays,
                "consistencyPercentage": snapshot.consistencyPercentage
            ]

            try await db.collection("users").document(userId)
                .collection("nutrientTracking")
                .document(nutrientId)
                .collection("monthlySnapshots")
                .document(snapshot.id)
                .setData(data, merge: true)

        } catch {
            print("❌ Error saving monthly snapshot: \(error)")
        }
    }

    // MARK: - Public API

    /// Get all active nutrients (70%+ consistency)
    func getActiveNutrients() -> [TrackedNutrient] {
        return NutrientDatabase.allNutrients.filter { nutrient in
            guard let frequency = nutrientFrequencies[nutrient.id] else { return false }
            return frequency.status == .active
        }
    }

    /// Get all dormant nutrients (not seen in 14+ days)
    func getDormantNutrients() -> [TrackedNutrient] {
        return NutrientDatabase.allNutrients.filter { nutrient in
            guard let frequency = nutrientFrequencies[nutrient.id] else { return false }
            return frequency.status == .dormant
        }
    }

    /// Get frequency data for a specific nutrient
    func getFrequency(for nutrientId: String) -> NutrientFrequency? {
        return nutrientFrequencies[nutrientId]
    }

    /// Manually trigger a full recalculation
    func forceRefresh(userId: String) async {
        guard !userId.isEmpty else {
            print("⚠️ Cannot refresh: userId is empty")
            return
        }
        await loadUserData(userId: userId)
        await recalculateAllFrequencies(userId: userId)
    }

    // Simple method to update nutrients for a specific date
    func updateNutrientsForDate(date: Date, nutrients: [String]) async {
        let dateId = formatDateId(date)

        // Update day activity
        dayActivities[dateId] = DayNutrientActivity(
            date: date,
            nutrientsPresent: nutrients,
            mealCount: 1
        )

        // Calculate stats for all nutrients based on last 30 days
        let calendar = Calendar.current
        let today = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today)!

        // Count total logged days in last 30 days
        let loggedDays = dayActivities.values.filter { activity in
            activity.date >= thirtyDaysAgo && activity.date <= today
        }.count

        // Update frequencies for all nutrients
        for nutrient in NutrientDatabase.allNutrients {
            let nutrientId = nutrient.id

            // Count appearances in last 30 days
            let appearances = dayActivities.values.filter { activity in
                activity.date >= thirtyDaysAgo &&
                activity.date <= today &&
                activity.nutrientsPresent.contains(nutrientId)
            }.count

            // Find most recent appearance
            let lastAppearance = dayActivities.values
                .filter { $0.nutrientsPresent.contains(nutrientId) }
                .sorted { $0.date > $1.date }
                .first?.date

            // Update or create frequency
            if var frequency = nutrientFrequencies[nutrientId] {
                frequency.last30DaysAppearances = appearances
                frequency.totalLoggedDays = loggedDays
                frequency.lastAppearance = lastAppearance
                nutrientFrequencies[nutrientId] = frequency
            } else {
                nutrientFrequencies[nutrientId] = NutrientFrequency(
                    nutrientId: nutrientId,
                    nutrientName: nutrient.displayName,
                    last30DaysAppearances: appearances,
                    totalLoggedDays: loggedDays,
                    lastAppearance: lastAppearance
                )
            }
        }

        lastUpdated = Date()
    }

    // MARK: - Helpers

    private func formatDateId(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
