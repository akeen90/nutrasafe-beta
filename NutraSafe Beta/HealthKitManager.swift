import Foundation
import HealthKit
import UIKit

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .traditionalStrengthTraining:
            return "Strength Training"
        case .functionalStrengthTraining:
            return "Functional Training"
        case .running:
            return "Running"
        case .cycling:
            return "Cycling"
        case .swimming:
            return "Swimming"
        case .walking:
            return "Walking"
        case .yoga:
            return "Yoga"
        case .pilates:
            return "Pilates"
        case .dance:
            return "Dance"
        case .boxing:
            return "Boxing"
        case .martialArts:
            return "Martial Arts"
        case .tennis:
            return "Tennis"
        case .badminton:
            return "Badminton"
        case .golf:
            return "Golf"
        case .basketball:
            return "Basketball"
        case .soccer:
            return "Soccer"
        case .volleyball:
            return "Volleyball"
        case .rowing:
            return "Rowing"
        case .elliptical:
            return "Elliptical"
        case .stairClimbing:
            return "Stair Climbing"
        case .hiking:
            return "Hiking"
        case .crossTraining:
            return "Cross Training"
        case .highIntensityIntervalTraining:
            return "HIIT"
        default:
            return "Exercise"
        }
    }
}

@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    @Published var isAuthorized = false
    @Published var exerciseCalories: Double = 0
    @Published var stepCount: Double = 0
    @Published var activeEnergyBurned: Double = 0
    @Published var userWeight: Double = 70.0 // Default weight in kg
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let healthStore = HKHealthStore()

    // Track which date the current HealthKit values represent (prevents race conditions)
    private var currentDisplayDate: Date = Date()

    // RACE CONDITION FIX: Use serial queue to synchronize task storage and cancellation
    private let taskQueue = DispatchQueue(label: "com.nutrasafe.healthkit.tasks")

    // Task cancellation for rapid date changes
    private var exerciseCaloriesTask: Task<Void, Never>?
    private var stepCountTask: Task<Void, Never>?
    private var activeEnergyTask: Task<Void, Never>?

    // MARK: - Live Refresh Properties
    // Observer queries for live HealthKit updates
    private var stepObserverQuery: HKObserverQuery?
    private var activeEnergyObserverQuery: HKObserverQuery?

    // Timer for periodic refresh (backup for observer queries)
    private var refreshTimer: Timer?
    private let refreshInterval: TimeInterval = 30 // Refresh every 30 seconds

    // Track app foreground state for smart refreshing
    private var isAppInForeground = true

    // Prevent timer task accumulation
    private var isRefreshing = false

    private init() {
        setupAppLifecycleObservers()
    }

    deinit {
        // Stop observer queries - they hold references and won't auto-cleanup
        // Note: healthStore.stop() is thread-safe and can be called from deinit
        if let query = stepObserverQuery {
            healthStore.stop(query)
        }
        if let query = activeEnergyObserverQuery {
            healthStore.stop(query)
        }
        refreshTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - App Lifecycle
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    @objc private func appDidBecomeActive() {
        isAppInForeground = true
        if isAuthorized {
            // Refresh immediately when app becomes active
            refreshHealthKitData()
            startRefreshTimer()
        }
    }

    @objc private func appWillResignActive() {
        isAppInForeground = false
        stopRefreshTimer()
    }

    /// Check if HealthKit authorization has already been granted
    /// This checks the authorization status without prompting the user
    func checkExistingAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            await MainActor.run {
                self.isAuthorized = false
            }
            return
        }

        // Check authorization status for a key type (bodyMass)
        // If we can read it, we have authorization
        guard let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return
        }

        let status = healthStore.authorizationStatus(for: bodyMassType)
        let wasAuthorized = (status == .sharingAuthorized)

        await MainActor.run {
            // sharingAuthorized means we have write permission (which implies read was also granted)
            self.isAuthorized = wasAuthorized
            // Start live updates if already authorized
            if wasAuthorized {
                self.startLiveUpdates()
            }
        }
    }

    /// Set the currently displayed date before fetching HealthKit data
    /// This cancels any in-flight requests and prevents stale async responses from overwriting current data
    func setCurrentDisplayDate(_ date: Date) {
        let newDate = Calendar.current.startOfDay(for: date)

        // Only cancel tasks if the date actually changed
        if newDate != currentDisplayDate {
            // RACE CONDITION FIX: Synchronize task cancellation to prevent race with task storage
            taskQueue.sync {
                exerciseCaloriesTask?.cancel()
                stepCountTask?.cancel()
                activeEnergyTask?.cancel()
                // Clear task references after cancellation
                exerciseCaloriesTask = nil
                stepCountTask = nil
                activeEnergyTask = nil
            }
        }

        currentDisplayDate = newDate

        // Restart timer based on whether we're viewing today
        // (we only want auto-refresh when viewing today's data)
        if isAuthorized {
            if Calendar.current.isDateInToday(newDate) {
                startRefreshTimer()
            } else {
                stopRefreshTimer()
            }
        }
    }
    
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            await MainActor.run {
                self.errorMessage = "HealthKit is not available on this device"
                self.showError = true
            }
            return
        }

        // Safe unwrapping of HKQuantityTypes - these should always exist on supported devices
        // but guard against future API changes
        var typesToRead = Set<HKObjectType>()
        typesToRead.insert(HKObjectType.workoutType())

        if let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            typesToRead.insert(bodyMassType)
        }
        if let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) {
            typesToRead.insert(stepCountType)
        }
        if let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            typesToRead.insert(activeEnergyType)
        }

        var typesToWrite = Set<HKSampleType>()
        if let dietaryEnergyType = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            typesToWrite.insert(dietaryEnergyType)
        }
        if let bodyMassWriteType = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            typesToWrite.insert(bodyMassWriteType)
        }

        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            await MainActor.run {
                self.isAuthorized = true
                self.errorMessage = nil
                self.showError = false
                // Start live updates after authorization
                self.startLiveUpdates()
            }
        } catch {

            await MainActor.run {
                self.errorMessage = "Unable to access HealthKit. Please enable access in Settings > Health > Data Access & Devices > NutraSafe"
                self.showError = true
            }
        }
    }

    // MARK: - Live Updates

    /// Start live updates for HealthKit data (observers + timer)
    /// Call this after authorization is granted
    func startLiveUpdates() {
        guard isAuthorized else { return }

        // Start observer queries for immediate notifications
        setupStepCountObserver()
        setupActiveEnergyObserver()

        // Start timer for periodic refresh (backup)
        startRefreshTimer()
    }

    /// Stop all live update mechanisms
    func stopLiveUpdates() {
        stopObserverQueries()
        stopRefreshTimer()
    }

    /// Refresh HealthKit data for the current display date
    func refreshHealthKitData() {
        Task {
            await updateStepCount(for: currentDisplayDate)
            await updateActiveEnergy(for: currentDisplayDate)
            await updateExerciseCalories(for: currentDisplayDate)
        }
    }

    // MARK: - Observer Queries

    private func setupStepCountObserver() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        // Stop existing observer if any
        if let existingQuery = stepObserverQuery {
            healthStore.stop(existingQuery)
        }

        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, completionHandler, error in
            guard error == nil else {
                completionHandler()
                return
            }

            // Route to MainActor to safely access @MainActor properties
            Task { @MainActor in
                guard let self = self else { return }
                // Only refresh if we're in foreground and observing today
                if self.isAppInForeground && Calendar.current.isDateInToday(self.currentDisplayDate) {
                    await self.updateStepCount(for: self.currentDisplayDate)
                }
            }

            completionHandler()
        }

        stepObserverQuery = query
        healthStore.execute(query)
    }

    private func setupActiveEnergyObserver() {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }

        // Stop existing observer if any
        if let existingQuery = activeEnergyObserverQuery {
            healthStore.stop(existingQuery)
        }

        let query = HKObserverQuery(sampleType: energyType, predicate: nil) { [weak self] _, completionHandler, error in
            guard error == nil else {
                completionHandler()
                return
            }

            // Route to MainActor to safely access @MainActor properties
            Task { @MainActor in
                guard let self = self else { return }
                // Only refresh if we're in foreground and observing today
                if self.isAppInForeground && Calendar.current.isDateInToday(self.currentDisplayDate) {
                    await self.updateActiveEnergy(for: self.currentDisplayDate)
                }
            }

            completionHandler()
        }

        activeEnergyObserverQuery = query
        healthStore.execute(query)
    }

    private func stopObserverQueries() {
        if let query = stepObserverQuery {
            healthStore.stop(query)
            stepObserverQuery = nil
        }
        if let query = activeEnergyObserverQuery {
            healthStore.stop(query)
            activeEnergyObserverQuery = nil
        }
    }

    // MARK: - Timer-based Refresh

    private func startRefreshTimer() {
        stopRefreshTimer() // Stop any existing timer

        // Only run timer when viewing today's data
        guard Calendar.current.isDateInToday(currentDisplayDate) else { return }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                // Prevent task accumulation if previous refresh is still running
                guard self.isAppInForeground, !self.isRefreshing else { return }
                self.isRefreshing = true
                defer { self.isRefreshing = false }
                self.refreshHealthKitData()
            }
        }
    }

    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func fetchTodayExerciseCalories() async throws -> Double {
        return try await fetchExerciseCalories(for: Date())
    }
    
    func fetchExerciseCalories(for date: Date) async throws -> Double {
        guard isAuthorized else { return 0 }

        // Fetch calories from HealthKit workouts
        return try await fetchWorkoutCalories(for: date)
    }

    private func fetchActiveEnergyBurned(for date: Date = Date()) async throws -> Double {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return 0
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return 0
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error as NSError? {
                    // Gracefully handle no-data error from HealthKit
                    if error.domain == "com.apple.healthkit" && error.code == 11 {
                        continuation.resume(returning: 0)
                        return
                    }
                    continuation.resume(throwing: error)
                    return
                }
                
                let calories = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: calories)
            }
            
            healthStore.execute(query)
        }
    }
    
    private func fetchWorkoutCalories(for date: Date = Date()) async throws -> Double {
        let workouts = try await fetchWorkouts(for: date)
        var totalCalories: Double = 0
        
        for workout in workouts {
            // Get calories from workout
            if let workoutCalories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
                totalCalories += workoutCalories
            } else {
                // Estimate calories for resistance training and other workouts without recorded calories
                let estimatedCalories = estimateCaloriesForWorkout(workout)
                totalCalories += estimatedCalories
                            }
        }
        
        return totalCalories
    }
    
    private func estimateCaloriesForWorkout(_ workout: HKWorkout) -> Double {
        let durationInMinutes = workout.duration / 60.0
        // Use minimum reasonable weight to prevent division issues or unrealistic estimates
        let userWeightKg = max(userWeight, 30.0)
        
        // Calories per minute based on workout type and user weight
        // These are research-based estimates for a 70kg person, scaled by actual weight
        let caloriesPerMinute: Double
        
        switch workout.workoutActivityType {
        case .traditionalStrengthTraining, .functionalStrengthTraining:
            caloriesPerMinute = 6.0 * (userWeightKg / 70.0) // Resistance training
        case .running:
            caloriesPerMinute = 10.0 * (userWeightKg / 70.0)
        case .cycling:
            caloriesPerMinute = 8.0 * (userWeightKg / 70.0)
        case .swimming:
            caloriesPerMinute = 11.0 * (userWeightKg / 70.0)
        case .walking:
            caloriesPerMinute = 4.0 * (userWeightKg / 70.0)
        case .yoga:
            caloriesPerMinute = 3.0 * (userWeightKg / 70.0)
        case .pilates:
            caloriesPerMinute = 4.0 * (userWeightKg / 70.0)
        case .dance:
            caloriesPerMinute = 5.0 * (userWeightKg / 70.0)
        case .boxing:
            caloriesPerMinute = 12.0 * (userWeightKg / 70.0)
        case .martialArts:
            caloriesPerMinute = 10.0 * (userWeightKg / 70.0)
        case .tennis:
            caloriesPerMinute = 8.0 * (userWeightKg / 70.0)
        case .badminton:
            caloriesPerMinute = 7.0 * (userWeightKg / 70.0)
        case .golf:
            caloriesPerMinute = 4.5 * (userWeightKg / 70.0)
        case .basketball:
            caloriesPerMinute = 8.0 * (userWeightKg / 70.0)
        case .soccer:
            caloriesPerMinute = 9.0 * (userWeightKg / 70.0)
        case .volleyball:
            caloriesPerMinute = 4.0 * (userWeightKg / 70.0)
        case .rowing:
            caloriesPerMinute = 12.0 * (userWeightKg / 70.0)
        case .elliptical:
            caloriesPerMinute = 9.0 * (userWeightKg / 70.0)
        case .stairClimbing:
            caloriesPerMinute = 11.0 * (userWeightKg / 70.0)
        case .hiking:
            caloriesPerMinute = 6.0 * (userWeightKg / 70.0)
        case .crossTraining:
            caloriesPerMinute = 8.0 * (userWeightKg / 70.0)
        case .highIntensityIntervalTraining:
            caloriesPerMinute = 14.0 * (userWeightKg / 70.0)
        default:
            caloriesPerMinute = 5.0 * (userWeightKg / 70.0) // General moderate activity
        }
        
        return caloriesPerMinute * durationInMinutes
    }
    
    func updateExerciseCalories(for date: Date = Date()) async {
        let normalizedDate = Calendar.current.startOfDay(for: date)

        // Store task reference for cancellation
        let task = Task { @MainActor in
            // Early exit if cancelled before starting
            guard !Task.isCancelled else { return }

            do {
                let calories = try await fetchExerciseCalories(for: date)

                // Check cancellation after async work completes
                guard !Task.isCancelled else { return }

                // Only update if this date is still the displayed date (prevents race condition)
                guard normalizedDate == self.currentDisplayDate else { return }
                self.exerciseCalories = calories
                self.errorMessage = nil
                self.showError = false
            } catch {
                guard !Task.isCancelled else { return }

                // Don't show error for "no data" case - set to 0
                let nsError = error as NSError
                if nsError.domain == "com.apple.healthkit" && nsError.code == 11 {
                    // No data - set to 0 (common for future dates)
                    guard normalizedDate == self.currentDisplayDate else { return }
                    self.exerciseCalories = 0
                    return
                }

                self.errorMessage = "Unable to load exercise data from HealthKit"
                self.showError = true
            }
        }

        // RACE CONDITION FIX: Synchronize task storage
        taskQueue.sync {
            exerciseCaloriesTask = task
        }
        await task.value
    }

    // MARK: - Step Count Methods

    func fetchTodayStepCount() async throws -> Double {
        return try await fetchStepCount(for: Date())
    }

    func fetchStepCount(for date: Date) async throws -> Double {
        guard isAuthorized else { return 0 }

        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return 0
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return 0
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let steps = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: steps)
            }

            healthStore.execute(query)
        }
    }

    func updateStepCount(for date: Date = Date()) async {
        let normalizedDate = Calendar.current.startOfDay(for: date)

        // Store task reference for cancellation
        let task = Task { @MainActor in
            guard !Task.isCancelled else { return }

            do {
                let steps = try await fetchStepCount(for: date)

                guard !Task.isCancelled else { return }

                // Only update if this date is still the displayed date (prevents race condition)
                guard normalizedDate == self.currentDisplayDate else { return }
                self.stepCount = steps
                self.errorMessage = nil
                self.showError = false
            } catch {
                guard !Task.isCancelled else { return }

                // Don't show error for "no data" case - set to 0
                let nsError = error as NSError
                if nsError.domain == "com.apple.healthkit" && nsError.code == 11 {
                    // No data - set to 0 (common for future dates)
                    guard normalizedDate == self.currentDisplayDate else { return }
                    self.stepCount = 0
                    return
                }

                self.errorMessage = "Unable to load step count from HealthKit"
                self.showError = true
            }
        }

        // RACE CONDITION FIX: Synchronize task storage
        taskQueue.sync {
            stepCountTask = task
        }
        await task.value
    }

    func updateActiveEnergy(for date: Date = Date()) async {
        let normalizedDate = Calendar.current.startOfDay(for: date)

        // Store task reference for cancellation
        let task = Task { @MainActor in
            guard !Task.isCancelled else { return }

            do {
                let energy = try await fetchActiveEnergyBurned(for: date)

                guard !Task.isCancelled else { return }

                // Only update if this date is still the displayed date (prevents race condition)
                guard normalizedDate == self.currentDisplayDate else { return }
                self.activeEnergyBurned = energy
                self.errorMessage = nil
                self.showError = false
            } catch {
                guard !Task.isCancelled else { return }

                // Don't show error for "no data" case - set to 0
                let nsError = error as NSError
                if nsError.domain == "com.apple.healthkit" && nsError.code == 11 {
                    // No data - set to 0 (common for future dates)
                    guard normalizedDate == self.currentDisplayDate else { return }
                    self.activeEnergyBurned = 0
                    return
                }

                self.errorMessage = "Unable to load active energy from HealthKit"
                self.showError = true
            }
        }

        // RACE CONDITION FIX: Synchronize task storage
        taskQueue.sync {
            activeEnergyTask = task
        }
        await task.value
    }

    func fetchWorkouts(for date: Date) async throws -> [HKWorkout] {
        guard isAuthorized else { return [] }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error as NSError? {
                    if error.domain == "com.apple.healthkit" && error.code == 11 {
                        // No workouts recorded for the day
                        continuation.resume(returning: [])
                        return
                    }
                    continuation.resume(throwing: error)
                    return
                }
                
                let workouts = samples as? [HKWorkout] ?? []
                continuation.resume(returning: workouts)
            }
            
            healthStore.execute(query)
        }
    }
    
    func fetchUserWeight() async throws -> Double {
        guard isAuthorized else { return 70.0 }

        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return 70.0
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error as NSError? {
                    if error.domain == "com.apple.healthkit" && error.code == 11 {
                        // No weight samples; fall back to default
                        continuation.resume(returning: 70.0)
                        return
                    }
                    continuation.resume(throwing: error)
                    return
                }
                
                if let weightSample = samples?.first as? HKQuantitySample {
                    let weightInKg = weightSample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                    continuation.resume(returning: weightInKg)
                } else {
                    continuation.resume(returning: 70.0) // Default weight
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    func updateUserWeight() async {
        do {
            let weight = try await fetchUserWeight()
            await MainActor.run {
                self.userWeight = weight
                self.errorMessage = nil
                self.showError = false
            }
        } catch {
            
            // Don't show error for "no data" case - use default
            let nsError = error as NSError
            if nsError.domain == "com.apple.healthkit" && nsError.code == 11 {
                // No data - use default weight
                return
            }

            await MainActor.run {
                self.errorMessage = "Unable to load weight data from HealthKit"
                self.showError = true
            }
        }
    }
    
    func writeDietaryEnergyConsumed(calories: Double, date: Date = Date()) async throws {
        guard isAuthorized else {
            throw NSError(domain: "HealthKitManager", code: 403, userInfo: [NSLocalizedDescriptionKey: "HealthKit not authorized"])
        }

        guard let energyType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) else {
            throw NSError(domain: "HealthKitManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Dietary energy type unavailable"])
        }
        let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)

        let sample = HKQuantitySample(
            type: energyType,
            quantity: energyQuantity,
            start: date,
            end: date
        )

        do {
            try await healthStore.save(sample)
                    } catch {
                        throw error
        }
    }

    func writeBodyWeight(weightKg: Double, date: Date = Date()) async throws {
        guard isAuthorized else {
            throw NSError(domain: "HealthKitManager", code: 403, userInfo: [NSLocalizedDescriptionKey: "HealthKit not authorized"])
        }

        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            throw NSError(domain: "HealthKitManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Body mass type unavailable"])
        }
        let weightQuantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightKg)

        let sample = HKQuantitySample(
            type: weightType,
            quantity: weightQuantity,
            start: date,
            end: date
        )

        do {
            try await healthStore.save(sample)
                    } catch {
                        throw error
        }
    }
}