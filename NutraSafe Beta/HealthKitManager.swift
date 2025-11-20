import Foundation
import HealthKit

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

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    @Published var isAuthorized = false
    @Published var exerciseCalories: Double = 0
    @Published var stepCount: Double = 0
    @Published var userWeight: Double = 70.0 // Default weight in kg
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let healthStore = HKHealthStore()
    
    private init() {}
    
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            await MainActor.run {
                self.errorMessage = "HealthKit is not available on this device"
                self.showError = true
            }
            return
        }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!
        ]

        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!
        ]

        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            await MainActor.run {
                self.isAuthorized = true
                self.errorMessage = nil
                self.showError = false
            }
        } catch {
            #if DEBUG
            print("HealthKit authorization failed: \(error)")
            #endif

            await MainActor.run {
                self.errorMessage = "Unable to access HealthKit. Please enable access in Settings > Health > Data Access & Devices > NutraSafe"
                self.showError = true
            }
        }
    }
    
    func fetchTodayExerciseCalories() async throws -> Double {
        return try await fetchExerciseCalories(for: Date())
    }
    
    func fetchExerciseCalories(for date: Date) async throws -> Double {
        guard isAuthorized else { return 0 }
        
        // Fetch calories from all sources
        let activeEnergyCalories = try await fetchActiveEnergyBurned(for: date)
        let workoutCalories = try await fetchWorkoutCalories(for: date)
        let firebaseExerciseCalories = try await fetchFirebaseExerciseCalories(for: date)
        
        // Use the highest value to ensure all exercise is counted but avoid double counting
        return max(activeEnergyCalories, workoutCalories, firebaseExerciseCalories)
    }
    
    private func fetchFirebaseExerciseCalories(for date: Date) async throws -> Double {
        do {
            let exerciseEntries = try await FirebaseManager.shared.getExerciseEntries(for: date)

            // Sum calories from all logged exercises for the specified date
            let totalCalories = exerciseEntries.reduce(0.0) { total, entry in
                // Only count entries from the specified date
                if Calendar.current.isDate(entry.date, inSameDayAs: date) {
                    return total + Double(entry.caloriesBurned)
                }
                return total
            }

            #if DEBUG
            print("🔥 Firebase exercise calories for \(date.formatted(.dateTime.day().month())): \(Int(totalCalories))")
            #endif
            return totalCalories

        } catch {
            #if DEBUG
            print("⚠️ Error fetching Firebase exercise entries: \(error)")
            #endif
            return 0.0
        }
    }
    
    private func fetchActiveEnergyBurned(for date: Date = Date()) async throws -> Double {
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
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
                #if DEBUG
                print("Estimated \(estimatedCalories) calories for \(workout.workoutActivityType.name) workout")
                #endif
            }
        }
        
        return totalCalories
    }
    
    private func estimateCaloriesForWorkout(_ workout: HKWorkout) -> Double {
        let durationInMinutes = workout.duration / 60.0
        let userWeightKg = userWeight
        
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
        do {
            let calories = try await fetchExerciseCalories(for: date)
            await MainActor.run {
                self.exerciseCalories = calories
                self.errorMessage = nil
                self.showError = false
            }
        } catch {
            #if DEBUG
            print("Failed to fetch exercise energy: \(error)")
            #endif

            // Don't show error for "no data" case - just use 0
            let nsError = error as NSError
            if nsError.domain == "com.apple.healthkit" && nsError.code == 11 {
                // No data - this is normal, not an error
                return
            }

            await MainActor.run {
                self.errorMessage = "Unable to load exercise data from HealthKit"
                self.showError = true
            }
        }
    }

    // MARK: - Step Count Methods

    func fetchTodayStepCount() async throws -> Double {
        return try await fetchStepCount(for: Date())
    }

    func fetchStepCount(for date: Date) async throws -> Double {
        guard isAuthorized else { return 0 }

        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

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
        do {
            let steps = try await fetchStepCount(for: date)
            await MainActor.run {
                self.stepCount = steps
                self.errorMessage = nil
                self.showError = false
            }
        } catch {
            #if DEBUG
            print("Failed to fetch step count: \(error)")
            #endif

            // Don't show error for "no data" case - just use 0
            let nsError = error as NSError
            if nsError.domain == "com.apple.healthkit" && nsError.code == 11 {
                // No data - this is normal, not an error
                return
            }

            await MainActor.run {
                self.errorMessage = "Unable to load step count from HealthKit"
                self.showError = true
            }
        }
    }

    func fetchWorkouts(for date: Date) async throws -> [HKWorkout] {
        guard isAuthorized else { return [] }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
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
        
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        
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
            #if DEBUG
            print("Failed to fetch user weight: \(error)")
            #endif

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
            #if DEBUG
            print("HealthKit not authorized for writing dietary energy")
            #endif
            throw NSError(domain: "HealthKitManager", code: 403, userInfo: [NSLocalizedDescriptionKey: "HealthKit not authorized"])
        }

        let energyType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)

        let sample = HKQuantitySample(
            type: energyType,
            quantity: energyQuantity,
            start: date,
            end: date
        )

        do {
            try await healthStore.save(sample)
            #if DEBUG
            print("Successfully wrote \(calories) kcal to Apple Health")
            #endif
        } catch {
            #if DEBUG
            print("Failed to write to HealthKit: \(error)")
            #endif
            throw error
        }
    }

    func writeBodyWeight(weightKg: Double, date: Date = Date()) async throws {
        guard isAuthorized else {
            #if DEBUG
            print("HealthKit not authorized for writing body weight")
            #endif
            throw NSError(domain: "HealthKitManager", code: 403, userInfo: [NSLocalizedDescriptionKey: "HealthKit not authorized"])
        }

        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let weightQuantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightKg)

        let sample = HKQuantitySample(
            type: weightType,
            quantity: weightQuantity,
            start: date,
            end: date
        )

        do {
            try await healthStore.save(sample)
            #if DEBUG
            print("✅ Successfully wrote \(weightKg) kg to Apple Health")
            #endif
        } catch {
            #if DEBUG
            print("Failed to write weight to HealthKit: \(error)")
            #endif
            throw error
        }
    }
}