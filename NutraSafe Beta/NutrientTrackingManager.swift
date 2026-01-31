//
//  NutrientTrackingManager.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-10-20.
//  Manages nutrient frequency tracking with Firebase sync and rolling 30-day windows
//

import Foundation
import SwiftUI
import UIKit
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
    @Published var hasCachedData = false

    private let db = Firestore.firestore()
    // P4-1 FIX: Removed unused listeners array - only diaryListener is used
    private var diaryListener: ListenerRegistration? // Deduplicated diary listener
    private var isSettingUpListeners = false // RACE CONDITION FIX: Guard against concurrent listener setup
    private var currentUserId: String = "" // User-specific cache isolation

    // File-based cache paths (UserDefaults inappropriate for large data - can cause launch delays)
    private let cacheKey_lastUpdated = "nutrient_cache_last_updated" // Small, stays in UserDefaults

    // Generate file path for user-scoped cache files
    private func cacheFilePath(for filename: String) -> URL? {
        guard !currentUserId.isEmpty else { return nil }
        let fileManager = FileManager.default
        guard let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let nutrientCacheDir = cacheDir.appendingPathComponent("NutrientCache", isDirectory: true)

        // Create directory if needed
        if !fileManager.fileExists(atPath: nutrientCacheDir.path) {
            try? fileManager.createDirectory(at: nutrientCacheDir, withIntermediateDirectories: true)
        }

        return nutrientCacheDir.appendingPathComponent("\(filename)_\(currentUserId).json")
    }

    // Generate user-scoped UserDefaults key (for small data only)
    private func cacheKey(for baseKey: String) -> String {
        guard !currentUserId.isEmpty else { return baseKey }
        return "\(baseKey)_\(currentUserId)"
    }

    // P3-2: Track paused state to avoid Firebase operations when backgrounded
    private var isPaused = false
    private var pausedUserId: String? = nil

    private init() {
        // Cache will be loaded in startTracking() once userId is known
        // Initialize with empty state

        // P3-2: Observe app lifecycle for pause/resume
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.pauseTracking()
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.resumeTracking()
            }
        }
    }

    // MARK: - Cleanup
    // Note: Since this is a singleton, deinit rarely runs. However, for Swift 6 concurrency safety,
    // we capture listener references before deinit to avoid MainActor isolation issues.
    // Call cleanupListeners() explicitly when user logs out.

    /// Explicitly clean up all listeners - call on logout or when manager is no longer needed
    func cleanupListeners() {
        diaryListener?.remove()
        diaryListener = nil
    }

    // MARK: - P3-2: Background Pause/Resume
    // Pauses Firebase listeners when app is backgrounded to reduce battery/network usage

    /// Pause tracking when app goes to background
    func pauseTracking() {
        guard !isPaused, !currentUserId.isEmpty else { return }

        print("[NutrientTrackingManager] P3-2: Pausing - removing Firebase listeners")
        isPaused = true
        pausedUserId = currentUserId

        // Remove listeners but keep cached data
        diaryListener?.remove()
        diaryListener = nil
    }

    /// Resume tracking when app returns to foreground
    func resumeTracking() {
        guard isPaused, let userId = pausedUserId, !userId.isEmpty else { return }

        print("[NutrientTrackingManager] P3-2: Resuming - re-establishing Firebase listeners")
        isPaused = false
        pausedUserId = nil

        // Re-setup listeners without full reload (we have cached data)
        setupRealtimeListeners(userId: userId)
    }

    deinit {
        // Capture listener references for safe cleanup from non-isolated context
        // This avoids Swift 6 strict concurrency warnings
        let diary = diaryListener
        diary?.remove()
    }

    // MARK: - Cache Management
    // PERFORMANCE: Uses file-based storage for large data (nutrient frequencies and day activities)
    // UserDefaults is inappropriate for MB-sized data and can cause app launch delays
    
    private func loadFromCache() async {
        guard !currentUserId.isEmpty else {
            return
        }

        // Load last updated date (small, stays in UserDefaults)
        let lastUpdatedKey = cacheKey(for: cacheKey_lastUpdated)
        if let lastUpdatedTimestamp = UserDefaults.standard.object(forKey: lastUpdatedKey) as? Double {
            lastUpdated = Date(timeIntervalSince1970: lastUpdatedTimestamp)
        }
        
        let frequenciesPath = cacheFilePath(for: "nutrient_frequencies")
        let activitiesPath = cacheFilePath(for: "day_activities")
        
        // Offload file I/O to background thread
        let (frequencies, activities) = await Task.detached(priority: .userInitiated) {
            var loadedFrequencies: [String: NutrientFrequency] = [:]
            var loadedActivities: [String: DayNutrientActivity] = [:]
            
            // Load nutrient frequencies from file cache
            if let path = frequenciesPath,
               let data = try? Data(contentsOf: path) {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .secondsSince1970
                    loadedFrequencies = try decoder.decode([String: NutrientFrequency].self, from: data)
                } catch {
                    print("⚠️ [NutrientTrackingManager] Failed to decode frequencies cache: \(error.localizedDescription)")
                }
            }
            
            // Load day activities from file cache
            if let path = activitiesPath,
               let data = try? Data(contentsOf: path) {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .secondsSince1970
                    loadedActivities = try decoder.decode([String: DayNutrientActivity].self, from: data)
                } catch {
                    print("⚠️ [NutrientTrackingManager] Failed to decode activities cache: \(error.localizedDescription)")
                }
            }
            
            return (loadedFrequencies, loadedActivities)
        }.value
        
        self.nutrientFrequencies = frequencies
        self.dayActivities = activities
        self.hasCachedData = !frequencies.isEmpty

        // Initialize with all tracked nutrients if no cache
        if nutrientFrequencies.isEmpty {
            for nutrient in NutrientDatabase.allNutrients {
                nutrientFrequencies[nutrient.id] = NutrientFrequency(
                    nutrientId: nutrient.id,
                    nutrientName: nutrient.displayName
                )
            }
        }
    }

    private func saveToCache() {
        guard !currentUserId.isEmpty else {
            return
        }

        // Save last updated date (small, stays in UserDefaults)
        let lastUpdatedKey = cacheKey(for: cacheKey_lastUpdated)
        if let lastUpdated = lastUpdated {
            UserDefaults.standard.set(lastUpdated.timeIntervalSince1970, forKey: lastUpdatedKey)
        }
        
        let frequenciesPath = cacheFilePath(for: "nutrient_frequencies")
        let activitiesPath = cacheFilePath(for: "day_activities")
        let frequencies = nutrientFrequencies
        let activities = dayActivities
        
        // Offload saving to background task
        Task.detached(priority: .background) {
            // Save nutrient frequencies to file (can be MB-sized)
            if let path = frequenciesPath {
                do {
                    let encoder = JSONEncoder()
                    encoder.dateEncodingStrategy = .secondsSince1970
                    let data = try encoder.encode(frequencies)
                    try data.write(to: path, options: .atomic)
                } catch {
                    print("⚠️ [NutrientTrackingManager] Failed to save frequencies cache: \(error.localizedDescription)")
                }
            }
            
            // Save day activities to file (can be MB-sized)
            if let path = activitiesPath {
                do {
                    let encoder = JSONEncoder()
                    encoder.dateEncodingStrategy = .secondsSince1970
                    let data = try encoder.encode(activities)
                    try data.write(to: path, options: .atomic)
                } catch {
                    print("⚠️ [NutrientTrackingManager] Failed to save activities cache: \(error.localizedDescription)")
                }
            }
        }

        hasCachedData = true
    }

    // MARK: - User Session

    func startTracking(for userId: String) {
        guard !userId.isEmpty else {
            return
        }

        
        // Set user ID and load their cached data immediately
        currentUserId = userId
        
        Task {
            await loadFromCache()

            // Then refresh from server in background
            await loadUserData(userId: userId)
            await performInitialDiaryProcessing(userId: userId)
            setupRealtimeListeners(userId: userId)
        }
    }

    func stopTracking() {
        // Remove deduplicated diary listener
        diaryListener?.remove()
        diaryListener = nil

        // Clear memory and reset state
        nutrientFrequencies.removeAll()
        dayActivities.removeAll()
        hasCachedData = false
        currentUserId = ""
        lastUpdated = nil

            }

    // MARK: - Data Loading

    private func loadUserData(userId: String) async {
        guard !userId.isEmpty else {
                        return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // PERFORMANCE: Fetch both collections in parallel with async let
            // This cuts network time roughly in half
            let sixtyDaysAgo = Calendar.current.date(byAdding: .day, value: -60, to: Date()) ?? Date()

            async let nutrientsTask = db.collection("users").document(userId)
                .collection("nutrientTracking").getDocuments()

            async let activitiesTask = db.collection("users").document(userId)
                .collection("dayNutrientActivity")
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: sixtyDaysAgo))
                .getDocuments()

            // Wait for both queries to complete
            let (nutrientsSnapshot, activitiesSnapshot) = try await (nutrientsTask, activitiesTask)

            // PERFORMANCE: Batch process into temp dictionaries to avoid
            // triggering @Published for each document (N+1 view updates)
            var tempFrequencies: [String: NutrientFrequency] = [:]
            var tempActivities: [String: DayNutrientActivity] = [:]

            for document in nutrientsSnapshot.documents {
                let data = document.data()
                if let frequency = parseNutrientFrequency(from: data, nutrientId: document.documentID) {
                    tempFrequencies[document.documentID] = frequency
                }
            }

            for document in activitiesSnapshot.documents {
                let data = document.data()
                if let activity = parseDayActivity(from: data) {
                    tempActivities[activity.dateId] = activity
                }
            }

            // Single batch update - triggers observers once instead of N times
            nutrientFrequencies = tempFrequencies
            dayActivities = tempActivities
            lastUpdated = Date()

            // Save to cache after successful load
            saveToCache()

        } catch {
                    }
    }

    private func performInitialDiaryProcessing(userId: String) async {
                do {
            // Load all diary entries
            let diarySnapshot = try await db.collection("users").document(userId)
                .collection("diary")
                .getDocuments()

            
            // Process them
            await processDiaryChanges(userId: userId, snapshot: diarySnapshot)

        } catch {
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
        // RACE CONDITION FIX: Guard against both duplicate listeners AND concurrent setup attempts
        // Multiple calls to startTracking could race and both pass the diaryListener == nil check
        guard diaryListener == nil, !isSettingUpListeners else {
            return
        }

        // Mark that we're setting up listeners to prevent concurrent attempts
        isSettingUpListeners = true
        defer { isSettingUpListeners = false }

        // Remove any existing listener before creating new one (defensive cleanup)
        diaryListener?.remove()
        diaryListener = nil

        // Listen to diary changes to auto-update nutrients
        // PERFORMANCE: Limit to last 90 days to prevent downloading entire history
        // This is a reasonable window for nutrient tracking analytics
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()

        diaryListener = db.collection("users").document(userId)
            .collection("diary")
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: ninetyDaysAgo))
            .order(by: "date", descending: true)
            .limit(to: 500)  // Safety limit to prevent memory issues
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                // STABILITY: Surface listener errors instead of silently failing
                if let error = error {
                    print("⚠️ [NutrientTrackingManager] Diary listener error: \(error.localizedDescription)")
                    // Don't return - may still have cached data to work with
                }

                guard let snapshot = snapshot else { return }

                // RACE CONDITION FIX: Route to MainActor for @Published property updates
                // Firebase listeners fire on background threads
                Task { @MainActor in
                    await self.processDiaryChanges(userId: userId, snapshot: snapshot)
                }
            }
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
                        var nutrientsPresent: Set<String> = []
            for food in allFoods {
                let detectedNutrients = NutrientDetector.detectNutrients(in: food)
                nutrientsPresent.formUnion(detectedNutrients)
            }

                        
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
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

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

        // Save updated data to cache
        saveToCache()
    }

    private func updateMonthlySnapshots(userId: String) async {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())

        // Calculate current month's data
        // CRASH FIX: Guard against calendar.date returning nil
        guard let monthStart = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1)) else {
            return
        }
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
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today) ?? today

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

        // Save updated data to cache
        saveToCache()
    }

    // MARK: - Helpers

    // PERFORMANCE: Static DateFormatter to avoid recreation on every call
    // DateFormatter creation is expensive (~10ms per instance)
    private static let dateIdFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = Calendar.current.timeZone
        return formatter
    }()

    private func formatDateId(_ date: Date) -> String {
        return Self.dateIdFormatter.string(from: date)
    }
}
