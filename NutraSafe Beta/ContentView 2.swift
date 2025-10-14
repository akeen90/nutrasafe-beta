import SwiftUI
import Foundation
import HealthKit
import Vision
import UserNotifications
import ActivityKit

// MARK: - Workout Manager
class WorkoutManager: ObservableObject {
    static let shared = WorkoutManager()
    
    @Published var isWorkoutActive = false
    @Published var workoutName = ""
    @Published var exercises: [ExerciseSummary] = []
    @Published var startTime = Date()
    @Published var exerciseRestTimers: [UUID: RestTimer] = [:]
    @Published var currentWorkoutDuration = "0:00"
    @Published var isInWorkoutView = false  // Track if user is in workout view
    @Published var hasActiveRestTimer = false  // Track if there's an active rest timer
    @Published var workoutHistory: [WorkoutSessionSummary] = []  // Store workout history
    
    private var workoutTimer: Timer?
    
    private init() {}
    
    var workoutDuration: Int {
        isWorkoutActive ? Int(Date().timeIntervalSince(startTime) / 60) : 0
    }
    
    var workoutDurationFormatted: String {
        guard isWorkoutActive else { return "0:00" }
        let totalSeconds = Int(Date().timeIntervalSince(startTime))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
    
    var totalVolume: Double {
        var total: Double = 0
        for exercise in exercises {
            for set in exercise.sets {
                if set.completed {
                    total += set.weight * Double(set.reps)
                }
            }
        }
        return total
    }
    
    func startWorkout() {
        if workoutName.isEmpty {
            workoutName = generateWorkoutName()
        }
        startTime = Date()
        isWorkoutActive = true
        startWorkoutTimer()
    }
    
    private func startWorkoutTimer() {
        workoutTimer?.invalidate()
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateWorkoutDuration()
        }
    }
    
    private func updateWorkoutDuration() {
        guard isWorkoutActive else { return }
        let totalSeconds = Int(Date().timeIntervalSince(startTime))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        DispatchQueue.main.async { [weak self] in
            self?.currentWorkoutDuration = "\(minutes):\(String(format: "%02d", seconds))"
        }
    }
    
    func finishWorkout() -> WorkoutSessionSummary {
        let workout = WorkoutSessionSummary(
            name: workoutName,
            date: startTime,
            duration: workoutDuration,
            totalVolume: totalVolume,
            averageHeartRate: nil,
            exercises: exercises,
            status: .completed
        )
        
        // Save to workout history
        workoutHistory.append(workout)
        
        // Save exercise entries to Firebase
        Task {
            await saveWorkoutExerciseEntries()
        }
        
        clearWorkout()
        return workout
    }
    
    private func saveWorkoutExerciseEntries() async {
        guard let userId = FirebaseManager.shared.currentUser?.uid else { return }
        
        // Calculate total workout duration in seconds
        let totalDurationInSeconds = TimeInterval(workoutDuration * 60)
        
        // Create exercise entries for each exercise in the workout
        for exerciseSummary in exercises {
            let completedSets = exerciseSummary.sets.filter { $0.completed }.count
            let totalReps = exerciseSummary.sets.filter { $0.completed }.reduce(0) { $0 + $1.reps }
            let averageWeight = exerciseSummary.sets.filter { $0.completed }.reduce(0.0) { $0 + $1.weight } / max(1, Double(completedSets))
            
            // Estimate calories for this specific exercise
            let exerciseDurationInSeconds = totalDurationInSeconds / max(1, Double(exercises.count)) // Distribute time equally
            let estimatedCalories = estimateCaloriesForExercise(
                exerciseName: exerciseSummary.name,
                durationInMinutes: Int(exerciseDurationInSeconds / 60),
                sets: completedSets,
                reps: totalReps
            )
            
            let exerciseEntry = ExerciseEntry(
                id: UUID(),
                userId: userId,
                exerciseName: exerciseSummary.name,
                type: .resistance,
                duration: exerciseDurationInSeconds,
                caloriesBurned: Int(estimatedCalories),
                distance: nil,
                sets: completedSets,
                reps: totalReps,
                weight: averageWeight,
                notes: nil,
                date: startTime,
                dateLogged: Date()
            )
            
            do {
                try await FirebaseManager.shared.saveExerciseEntry(exerciseEntry)
                print("✅ Saved exercise entry: \(exerciseSummary.name) - \(Int(estimatedCalories)) calories")
            } catch {
                print("❌ Error saving exercise entry for \(exerciseSummary.name): \(error)")
            }
        }
    }
    
    private func estimateCaloriesForExercise(exerciseName: String, durationInMinutes: Int, sets: Int, reps: Int) -> Double {
        // Get user's weight from UserDefaults
        let weightKg = UserDefaults.standard.double(forKey: "userWeight")
        let weight = weightKg > 0 ? weightKg : 70.0 // default 70kg
        
        // MET values for different exercise types
        let metValue: Double
        switch exerciseName.lowercased() {
        case let ex where ex.contains("squat") || ex.contains("deadlift"):
            metValue = 6.0
        case let ex where ex.contains("bench press") || ex.contains("press"):
            metValue = 5.0
        case let ex where ex.contains("pull") || ex.contains("row"):
            metValue = 5.5
        case let ex where ex.contains("curl") || ex.contains("extension"):
            metValue = 4.5
        case let ex where ex.contains("push-up") || ex.contains("dip"):
            metValue = 4.5
        default:
            metValue = 5.0 // Default for resistance training
        }
        
        // For resistance training, factor in intensity based on sets and reps
        let intensityMultiplier = min(2.0, 1.0 + (Double(sets) * Double(reps)) / 100.0)
        let adjustedMetValue = metValue * intensityMultiplier
        
        // Calculate calories: MET * weight (kg) * time (hours)
        let hours = Double(durationInMinutes) / 60.0
        return adjustedMetValue * weight * hours
    }
    
    func discardWorkout() {
        clearWorkout()
    }
    
    private func clearWorkout() {
        isWorkoutActive = false
        workoutName = ""
        exercises = []
        startTime = Date()
        exerciseRestTimers.removeAll()
        currentWorkoutDuration = "0:00"
        workoutTimer?.invalidate()
        workoutTimer = nil
        isInWorkoutView = false
        hasActiveRestTimer = false
    }
    
    // Navigation state management
    func enterWorkoutView() {
        isInWorkoutView = true
    }
    
    func exitWorkoutView() {
        isInWorkoutView = false
    }
    
    func updateRestTimerState() {
        hasActiveRestTimer = !exerciseRestTimers.isEmpty
    }
    
    // Get the most recent active rest timer
    var activeRestTimer: RestTimer? {
        return exerciseRestTimers.values.first { $0.isRunning }
    }
    
    private func generateWorkoutName() -> String {
        let components = Calendar.current.dateComponents([.weekday], from: Date())
        let weekday = components.weekday ?? 1
        
        let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return "\(dayNames[weekday - 1]) Workout"
    }
}

// MARK: - Workout Models

// MARK: - Per-Exercise Rest Timer Manager
class ExerciseRestTimerManager: ObservableObject {
    @Published var activeTimers: [String: RestTimer] = [:] // exerciseId: RestTimer
    
    func startTimer(for exerciseId: String, exerciseName: String, duration: TimeInterval) {
        // Stop any existing timer for this exercise
        stopTimer(for: exerciseId)
        
        let timer = RestTimer(
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            duration: duration,
            onComplete: { [weak self] in
                self?.stopTimer(for: exerciseId)
            }
        )
        
        activeTimers[exerciseId] = timer
        timer.start()
    }
    
    func stopTimer(for exerciseId: String) {
        activeTimers[exerciseId]?.stop()
        activeTimers.removeValue(forKey: exerciseId)
    }
    
    func stopAllTimers() {
        for timer in activeTimers.values {
            timer.stop()
        }
        activeTimers.removeAll()
    }
    
    func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

class RestTimer: ObservableObject, Identifiable {
    let id = UUID()
    let exerciseId: String
    let exerciseName: String
    let totalDuration: TimeInterval
    let onComplete: () -> Void
    
    @Published var remainingTime: TimeInterval
    @Published var isRunning = false
    @Published var isPaused = false
    
    private var timer: Timer?
    private var liveActivityManager: Any? = {
        if #available(iOS 16.2, *) {
            return LiveActivityManager.shared
        } else {
            return nil
        }
    }()
    
    init(exerciseId: String, exerciseName: String, duration: TimeInterval, onComplete: @escaping () -> Void) {
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.totalDuration = duration
        self.remainingTime = duration
        self.onComplete = onComplete
    }
    
    func start() {
        isRunning = true
        isPaused = false
        
        // Start Live Activity for Dynamic Island
        if #available(iOS 16.2, *), let manager = liveActivityManager as? LiveActivityManager {
            manager.startRestTimerActivity(exerciseName: exerciseName, duration: totalDuration)
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                if self?.remainingTime ?? 0 > 0 {
                    self?.remainingTime -= 1
                    // Update Live Activity
                    if #available(iOS 16.1, *) {
                        if #available(iOS 16.2, *), let manager = self?.liveActivityManager as? LiveActivityManager {
                            manager.updateRestTimerActivity(remainingTime: self?.remainingTime ?? 0, isPaused: self?.isPaused ?? false)
                        }
                    }
                } else {
                    self?.complete()
                }
            }
        }
    }
    
    func pause() {
        timer?.invalidate()
        timer = nil
        isPaused = true
        isRunning = false
        
        // Update Live Activity to show paused state
        if #available(iOS 16.1, *) {
            if #available(iOS 16.2, *), let manager = liveActivityManager as? LiveActivityManager {
                manager.updateRestTimerActivity(remainingTime: remainingTime, isPaused: true)
            }
        }
    }
    
    func resume() {
        guard isPaused else { return }
        isRunning = true
        isPaused = false
        
        // Update Live Activity to show running state
        if #available(iOS 16.1, *) {
            if #available(iOS 16.2, *), let manager = liveActivityManager as? LiveActivityManager {
                manager.updateRestTimerActivity(remainingTime: remainingTime, isPaused: false)
            }
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                if self?.remainingTime ?? 0 > 0 {
                    self?.remainingTime -= 1
                    // Update Live Activity
                    if #available(iOS 16.1, *) {
                        if #available(iOS 16.2, *), let manager = self?.liveActivityManager as? LiveActivityManager {
                            manager.updateRestTimerActivity(remainingTime: self?.remainingTime ?? 0, isPaused: self?.isPaused ?? false)
                        }
                    }
                } else {
                    self?.complete()
                }
            }
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        
        // End Live Activity
        if #available(iOS 16.1, *) {
            if #available(iOS 16.2, *), let manager = liveActivityManager as? LiveActivityManager {
                manager.endRestTimerActivity()
            }
        }
    }
    
    private func complete() {
        stop()
        onComplete()
        // Could add notification, sound, or vibration here
    }
    
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return (totalDuration - remainingTime) / totalDuration
    }
    
    // Compatibility method for different interface usage
    var timeRemaining: Int {
        return Int(remainingTime)
    }
    
    func addTime(_ seconds: Int) {
        remainingTime += Double(seconds)
        // Update Live Activity with new time
        if #available(iOS 16.1, *) {
            if #available(iOS 16.2, *), let manager = liveActivityManager as? LiveActivityManager {
                manager.updateRestTimerActivity(remainingTime: remainingTime, isPaused: isPaused)
            }
        }
    }
    
    func skip() {
        complete()
    }
}

// MARK: - Dynamic Island Activity

@available(iOS 16.1, *)
struct RestTimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingTime: TimeInterval
        var exerciseName: String
        var isPaused: Bool
    }
    
    var exerciseName: String
    var totalDuration: TimeInterval
}

// Note: Live Activity UI views will be implemented in a Widget Extension target
// For now, we just need the ActivityAttributes and LiveActivityManager

@available(iOS 16.2, *)
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    private var currentActivity: Activity<RestTimerActivityAttributes>?
    
    private init() {}
    
    func startRestTimerActivity(exerciseName: String, duration: TimeInterval) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }
        
        let attributes = RestTimerActivityAttributes(
            exerciseName: exerciseName,
            totalDuration: duration
        )
        
        let contentState = RestTimerActivityAttributes.ContentState(
            remainingTime: duration,
            exerciseName: exerciseName,
            isPaused: false
        )
        
        do {
            let activity = try Activity<RestTimerActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil)
            )
            currentActivity = activity
            print("Started Live Activity for rest timer: \(activity.id)")
        } catch {
            print("Error starting Live Activity: \(error)")
        }
    }
    
    func updateRestTimerActivity(remainingTime: TimeInterval, isPaused: Bool) {
        guard let activity = currentActivity else { return }
        
        let contentState = RestTimerActivityAttributes.ContentState(
            remainingTime: remainingTime,
            exerciseName: activity.attributes.exerciseName,
            isPaused: isPaused
        )
        
        Task {
            await activity.update(.init(state: contentState, staleDate: nil))
        }
    }
    
    func endRestTimerActivity() {
        guard let activity = currentActivity else { return }
        
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
            print("Ended Live Activity for rest timer")
        }
    }
}

// MARK: - Ingredient Submission Service
class IngredientSubmissionService: ObservableObject {
    static let shared = IngredientSubmissionService()
    private let functionsBaseURL = "https://us-central1-nutrasafe-705c7.cloudfunctions.net"
    
    private init() {}
    
    // Submit ingredients immediately and create pending verification
    func submitIngredientSubmission(foodName: String, brandName: String?, 
                                  ingredientsImage: UIImage?, nutritionImage: UIImage?, 
                                  barcodeImage: UIImage?) async throws -> String {
        // First, process the ingredient image to extract text if available
        var extractedIngredients: String = ""
        
        if let ingredientsImage = ingredientsImage {
            extractedIngredients = try await processIngredientImage(ingredientsImage)
        }
        
        // Create immediate pending verification record
        guard let userId = FirebaseManager.shared.currentUser?.uid else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let pendingVerification = PendingFoodVerification(
            foodName: foodName,
            brandName: brandName,
            ingredients: extractedIngredients.isEmpty ? "Processing ingredient image..." : extractedIngredients,
            userId: userId
        )
        
        // Save immediately to local collection for instant display
        try await FirebaseManager.shared.savePendingVerification(pendingVerification)
        
        // Submit to backend for full processing (asynchronous)
        Task {
            try await submitToBackendForFullProcessing(
                foodName: foodName,
                brandName: brandName,
                ingredientsImage: ingredientsImage,
                nutritionImage: nutritionImage,
                barcodeImage: barcodeImage,
                pendingId: pendingVerification.id
            )
        }
        
        return pendingVerification.id
    }
    
    // Extract ingredients text from image using Vision framework
    private func processIngredientImage(_ image: UIImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: "")
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: " ")
                
                continuation.resume(returning: recognizedText)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // Submit to backend Firebase function for complete processing
    private func submitToBackendForFullProcessing(foodName: String, brandName: String?,
                                                ingredientsImage: UIImage?, nutritionImage: UIImage?,
                                                barcodeImage: UIImage?, pendingId: String) async throws {
        guard let userId = FirebaseManager.shared.currentUser?.uid else { 
            print("No user ID available for submission")
            return 
        }
        
        let url = URL(string: "\(functionsBaseURL)/submitFoodVerification")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var images: [String: String] = [:]
        
        // Convert images to base64 if available
        if let ingredientsImage = ingredientsImage,
           let imageData = ingredientsImage.jpegData(compressionQuality: 0.8) {
            images["ingredients"] = imageData.base64EncodedString()
        }
        
        if let nutritionImage = nutritionImage,
           let imageData = nutritionImage.jpegData(compressionQuality: 0.8) {
            images["nutrition"] = imageData.base64EncodedString()
        }
        
        if let barcodeImage = barcodeImage,
           let imageData = barcodeImage.jpegData(compressionQuality: 0.8) {
            images["barcode"] = imageData.base64EncodedString()
        }
        
        let requestData: [String: Any] = [
            "userId": userId,
            "verificationId": pendingId,
            "foodName": foodName,
            "brandName": brandName ?? "",
            "images": images
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("Backend processing failed, but local pending verification was saved")
            return
        }
    }
}

// MARK: - FatSecret API Service via Firebase Functions
class FatSecretService: ObservableObject {
    static let shared = FatSecretService()
    
    // Firebase Functions URL for NutraSafe project
    private let functionsBaseURL = "https://us-central1-nutrasafe-705c7.cloudfunctions.net"
    
    private init() {}
    
    func searchFoods(query: String) async throws -> [FoodSearchResult] {
        print("🔎 FatSecretService.searchFoods called with query: '\(query)'")
        let results = try await performFatSecretSearch(query: query)
        print("🔎 FatSecretService.searchFoods returning \(results.count) results")
        return results
    }
    
    private func performFatSecretSearch(query: String) async throws -> [FoodSearchResult] {
        let url = URL(string: "\(functionsBaseURL)/searchFoods")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["query": query, "maxResults": "50"]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        struct FirebaseFoodSearchResponse: Codable {
            let foods: [FirebaseFoodItem]
            
            struct FirebaseFoodItem: Codable {
                let id: String
                let name: String
                let brand: String?
                let calories: CalorieInfo?
                let protein: NutrientInfo?
                let carbs: NutrientInfo?
                let fat: NutrientInfo?
                let fiber: NutrientInfo?
                let sugar: NutrientInfo?
                let sodium: NutrientInfo?
                let servingDescription: String?
                let ingredients: String?
                let additives: [FirebaseAdditiveInfo]?
                let processingScore: Int?
                let processingGrade: String?
                let processingLabel: String?
                
                struct CalorieInfo: Codable {
                    let kcal: Double
                    
                    init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        if container.decodeNil() {
                            kcal = 0
                        } else if let directValue = try? container.decode(Double.self) {
                            // Handle direct number: "calories": 442
                            kcal = directValue
                        } else {
                            // Handle nested object: "calories": {"kcal": 442}
                            let calorieContainer = try decoder.container(keyedBy: CodingKeys.self)
                            kcal = try calorieContainer.decode(Double.self, forKey: .kcal)
                        }
                    }
                    
                    private enum CodingKeys: String, CodingKey {
                        case kcal
                    }
                }
                
                struct NutrientInfo: Codable {
                    let per100g: Double
                    
                    init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        if container.decodeNil() {
                            per100g = 0
                        } else if let directValue = try? container.decode(Double.self) {
                            // Handle direct number: "protein": 4.5
                            per100g = directValue
                        } else {
                            // Handle nested object: "protein": {"per100g": 4.5}
                            let nutrientContainer = try decoder.container(keyedBy: CodingKeys.self)
                            per100g = try nutrientContainer.decode(Double.self, forKey: .per100g)
                        }
                    }
                    
                    private enum CodingKeys: String, CodingKey {
                        case per100g
                    }
                }
                
                struct FirebaseAdditiveInfo: Codable {
                    let id: String
                    let code: String
                    let name: String
                    let category: String
                    let permittedGB: Bool
                    let permittedNI: Bool
                    let permittedEU: Bool
                    let statusNotes: String?
                    let childWarning: Bool
                    let pkuWarning: Bool
                    let polyolsWarning: Bool
                    let sulphitesAllergenLabel: Bool
                    let origin: String
                    let consumerGuide: String?
                    let effectsVerdict: String
                    let synonyms: [String]
                    let matches: [String]
                    let sources: [AdditiveSource]?
                    let consumerInfo: String?
                    
                    private enum CodingKeys: String, CodingKey {
                        case id, code, name, category, origin, synonyms, matches, sources
                        case permittedGB = "permitted_GB"
                        case permittedNI = "permitted_NI"
                        case permittedEU = "permitted_EU"
                        case statusNotes = "status_notes"
                        case childWarning = "child_warning"
                        case pkuWarning = "PKU_warning"
                        case polyolsWarning = "polyols_warning"
                        case sulphitesAllergenLabel = "sulphites_allergen_label"
                        case consumerGuide = "consumer_guide"
                        case effectsVerdict = "effects_verdict"
                        case consumerInfo
                    }
                }
            }
        }
        
        // Debug: Print raw JSON response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🔍 Raw API response: \(jsonString.prefix(500))")
        }
        
        let searchResponse: FirebaseFoodSearchResponse
        do {
            searchResponse = try JSONDecoder().decode(FirebaseFoodSearchResponse.self, from: data)
            print("✅ Successfully decoded \(searchResponse.foods.count) foods")
        } catch {
            print("❌ JSON decoding error: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("Key not found: \(key), context: \(context)")
                case .typeMismatch(let type, let context):
                    print("Type mismatch: \(type), context: \(context)")
                case .valueNotFound(let type, let context):
                    print("Value not found: \(type), context: \(context)")
                case .dataCorrupted(let context):
                    print("Data corrupted: \(context)")
                @unknown default:
                    print("Unknown decoding error")
                }
            }
            throw error
        }
        
        return searchResponse.foods.map { food in
            // Debug logging for ingredients
            if let rawIngredients = food.ingredients {
                print("🧪 Raw ingredients for \(food.name): '\(rawIngredients)'")
                let splitIngredients = rawIngredients.components(separatedBy: ", ")
                print("🧪 Split into \(splitIngredients.count) parts: \(splitIngredients)")
            } else {
                print("🧪 No ingredients for \(food.name)")
            }
            
            // Convert Firebase additives to NutritionAdditiveInfo format
            let convertedAdditives = food.additives?.map { firebaseAdditive in
                // Calculate health score based on warnings (simplified scoring)
                var healthScore = 70 // Base score
                if firebaseAdditive.childWarning { healthScore -= 20 }
                if firebaseAdditive.pkuWarning { healthScore -= 15 }
                if firebaseAdditive.polyolsWarning { healthScore -= 10 }
                if firebaseAdditive.effectsVerdict.lowercased().contains("caution") { healthScore -= 15 }
                healthScore = max(0, min(100, healthScore))

                return NutritionAdditiveInfo(
                    code: firebaseAdditive.code,
                    name: firebaseAdditive.name,
                    category: firebaseAdditive.category,
                    healthScore: healthScore,
                    childWarning: firebaseAdditive.childWarning,
                    effectsVerdict: firebaseAdditive.effectsVerdict
                )
            }
            
            return FoodSearchResult(
                id: food.id,
                name: food.name,
                brand: food.brand,
                calories: food.calories?.kcal ?? 0,
                protein: food.protein?.per100g ?? 0,
                carbs: food.carbs?.per100g ?? 0,
                fat: food.fat?.per100g ?? 0,
                fiber: food.fiber?.per100g ?? 0,
                sugar: food.sugar?.per100g ?? 0,
                sodium: food.sodium?.per100g ?? 0,
                servingDescription: food.servingDescription,
                ingredients: food.ingredients?.components(separatedBy: ", "),
                additives: convertedAdditives,
                processingScore: food.processingScore,
                processingGrade: food.processingGrade,
                processingLabel: food.processingLabel
            )
        }
    }
    
    func getFoodDetails(foodId: String) async throws -> FoodSearchResult? {
        let url = URL(string: "\(functionsBaseURL)/getFoodDetails")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["foodId": foodId]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        struct FirebaseFoodDetailsResponse: Codable {
            let id: String
            let name: String
            let brand: String?
            let calories: Double
            let protein: Double
            let carbs: Double
            let fat: Double
            let fiber: Double
            let sugar: Double
            let sodium: Double
            let servingDescription: String?
            let ingredients: String?
        }
        
        let detailResponse = try JSONDecoder().decode(FirebaseFoodDetailsResponse.self, from: data)
        
        return FoodSearchResult(
            id: detailResponse.id,
            name: detailResponse.name,
            brand: detailResponse.brand,
            calories: detailResponse.calories,
            protein: detailResponse.protein,
            carbs: detailResponse.carbs,
            fat: detailResponse.fat,
            fiber: detailResponse.fiber,
            sugar: detailResponse.sugar,
            sodium: detailResponse.sodium,
            servingDescription: detailResponse.servingDescription,
            ingredients: detailResponse.ingredients?.components(separatedBy: ", ")
        )
    }
    
}

// MARK: - Data Models for UI

struct NutritionValue {
    let current: Double
    let target: Double
    
    var percentage: Double {
        return min(current / target, 1.0)
    }
    
    var remaining: Double {
        return max(target - current, 0)
    }
}

struct DiaryExerciseItem: Identifiable, Codable {
    let id: UUID
    let name: String
    let duration: Int // minutes
    let intensity: ExerciseIntensity
    let calories: Double
    let time: String
    let exerciseType: ExerciseType
    
    init(name: String, duration: Int, intensity: ExerciseIntensity, calories: Double, time: String, exerciseType: ExerciseType) {
        self.id = UUID()
        self.name = name
        self.duration = duration
        self.intensity = intensity
        self.calories = calories
        self.time = time
        self.exerciseType = exerciseType
    }
    
    // Calculate calories based on bodyweight, exercise type, duration and intensity
    static func calculateCalories(exercise: String, exerciseType: ExerciseType, duration: Int, intensity: ExerciseIntensity, userWeight: Double = 70.0) -> Double {
        let baseMET = ExerciseDatabase.getExerciseMET(for: exercise, type: exerciseType)
        let adjustedMET = baseMET * intensity.multiplier
        // Calories = MET * weight(kg) * duration(hours)
        return adjustedMET * userWeight * (Double(duration) / 60.0)
    }
}

enum ExerciseType: String, CaseIterable, Codable {
    case cardio = "Cardio"
    case resistance = "Resistance Training"
    
    var displayName: String {
        return rawValue
    }
    
    var color: Color {
        switch self {
        case .cardio: return .red
        case .resistance: return .indigo
        }
    }
}

// MARK: - Exercise Database with MET Values
class ExerciseDatabase {
    static let exercisesByType: [String: [String]] = [
        "Cardio": [
            "Running", "Jogging", "Walking", "Cycling", "Swimming", "Rowing", "Elliptical",
            "Stair Climbing", "Dancing", "Jump Rope", "Boxing", "Kickboxing",
            "Spinning", "Treadmill", "Cross Training", "Aerobics", "Zumba", "Tennis",
            "Basketball", "Soccer", "Rugby", "Cricket", "Badminton", "Squash", "Marathon Training",
            "HIIT", "Interval Training", "Sprints", "Hill Training", "Circuit Training", "Sports"
        ],
        "Resistance Training": [
            "Bench Press", "Incline Bench Press", "Decline Bench Press", "Dumbbell Press",
            "Incline Dumbbell Press", "Dumbbell Flyes", "Pull-ups", "Chin-ups", 
            "Lat Pulldown", "Seated Cable Row", "Bent-over Row", "T-Bar Row", "Deadlift",
            "Overhead Press", "Military Press", "Arnold Press", "Lateral Raises",
            "Front Raises", "Rear Delt Flyes", "Barbell Curls", "Dumbbell Curls", 
            "Hammer Curls", "Tricep Dips", "Close-Grip Bench Press", "Squats", 
            "Front Squats", "Leg Press", "Lunges", "Bulgarian Split Squats",
            "Leg Curls", "Leg Extensions", "Calf Raises", "Hip Thrusts",
            "Push-ups", "Dips", "Plank", "Side Plank", "Box Jumps", "Jump Squats", 
            "Burpees", "Mountain Climbers", "Kettlebell Swings", "Medicine Ball Slams",
            "Battle Ropes", "Bodyweight Squats", "Wall Sit"
        ]
    ]
    
    // MET (Metabolic Equivalent of Task) values for calorie calculation
    private static let exerciseMET: [String: Double] = [
        // Cardio (MET 6-15)
        "Running": 11.0, "Jogging": 7.0, "Walking": 3.8, "Cycling": 8.0, "Swimming": 8.0,
        "Rowing": 12.0, "Elliptical": 5.0, "Stair Climbing": 8.8, "Dancing": 4.8,
        "Jump Rope": 12.3, "Boxing": 12.8, "Kickboxing": 10.3, "Spinning": 8.5,
        "Treadmill": 9.0, "Cross Training": 5.0, "Aerobics": 7.3, "Zumba": 8.8,
        "Tennis": 8.0, "Basketball": 8.0, "Soccer": 10.0, "Marathon Training": 13.3,
        
        // Strength Training (MET 5-8)
        "Bench Press": 6.0, "Pull-ups": 8.0, "Deadlift": 6.0, "Squats": 5.0,
        "Overhead Press": 6.0, "Barbell Curls": 3.0, "Leg Press": 5.0,
        
        // Plyometrics (MET 8-10)
        "Box Jumps": 8.0, "Jump Squats": 8.0, "Burpees": 8.0, "Mountain Climbers": 8.0,
        "Jumping Jacks": 8.0, "Plyo Push-ups": 8.0, "Medicine Ball Slams": 8.8,
        
        // Bodyweight (MET 4-8)
        "Push-ups": 8.0, "Plank": 5.0, "Bear Crawls": 7.0, "Wall Sit": 5.0,
        
        // HIIT (MET 8-15)
        "Tabata": 12.5, "Circuit Training": 8.0, "Battle Ropes": 10.3, "Kettlebell Swings": 9.8,
        "Sprints": 15.0, "Hill Sprints": 16.0, "Crossfit WOD": 12.0,
        
        // Flexibility (MET 2-4)
        "Yoga": 2.5, "Pilates": 3.0, "Static Stretching": 2.3, "Tai Chi": 3.0,
        "Meditation": 1.0, "Foam Rolling": 3.5,
        
        // Sports (MET 6-12)
        "Rock Climbing": 11.0, "Surfing": 5.0, "Skiing": 7.0, "Martial Arts": 10.3,
        "Volleyball": 4.0, "Golf": 4.8, "Hockey": 8.0,
        
        // Other (MET 2-6)
        "Hiking": 6.0, "Gardening": 4.0, "Housework": 3.3, "Active Recovery": 2.0
    ]
    
    static func getExerciseMET(for exercise: String, type: ExerciseType) -> Double {
        if let met = exerciseMET[exercise] {
            return met
        }
        
        // Default MET values by category
        switch type {
        case .cardio: return 8.0
        case .resistance: return 6.0
        }
    }
}

struct ExerciseSelectorView: View {
    @Binding var selectedExercise: String
    @Binding var searchText: String
    let filteredExercises: [String]
    let presetExercises: [String]
    @Binding var isCustomExercise: Bool
    
    @Environment(\.dismiss) private var dismiss
    @State private var customExerciseName = ""
    @State private var showingCustomInput = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Text("Select Exercise")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button("Done") {
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        
                        TextField("Search exercises...", text: $searchText)
                            .font(.system(size: 16))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    
                    // Add Custom Exercise Button
                    Button(action: {
                        showingCustomInput = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                            
                            Text("Add Custom Exercise")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 16)
                }
                .background(Color(.systemBackground))
                
                // Exercise List
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredExercises, id: \.self) { exercise in
                            Button(action: {
                                selectedExercise = exercise
                                isCustomExercise = false
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(exercise)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                        
                                        Text(exerciseCategory(for: exercise))
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedExercise == exercise {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(selectedExercise == exercise ? Color.blue.opacity(0.05) : Color.clear)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .padding(.leading, 16)
                        }
                        
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Add Custom Exercise", isPresented: $showingCustomInput) {
            TextField("Exercise name", text: $customExerciseName)
            
            Button("Add") {
                if !customExerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    selectedExercise = customExerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
                    isCustomExercise = true
                    dismiss()
                }
            }
            
            Button("Cancel", role: .cancel) {
                customExerciseName = ""
            }
        } message: {
            Text("Enter the name of your custom exercise")
        }
    }
    
    // Exercise category arrays - broken into smaller sub-expressions to avoid compiler timeout
    private static let chestExercises = [
        "Bench Press", "Incline Bench Press", "Decline Bench Press",
        "Dumbbell Press", "Incline Dumbbell Press"
    ] + [
        "Dumbbell Flyes", "Incline Dumbbell Flyes",
        "Chest Dips", "Push-ups", "Cable Flyes"
    ]

    private static let backExercises = [
        "Pull-ups", "Chin-ups", "Lat Pulldown",
        "Seated Cable Row", "Bent-over Row"
    ] + [
        "T-Bar Row", "Single-arm Dumbbell Row",
        "Deadlift", "Romanian Deadlift", "Hyperextensions"
    ]

    private static let shoulderExercises = [
        "Overhead Press", "Military Press", "Dumbbell Shoulder Press",
        "Arnold Press", "Lateral Raises"
    ] + [
        "Front Raises", "Rear Delt Flyes",
        "Upright Rows", "Shrugs", "Face Pulls"
    ]

    private static let armExercises = [
        "Barbell Curls", "Dumbbell Curls", "Hammer Curls",
        "Preacher Curls", "Cable Curls"
    ] + [
        "Tricep Dips", "Close-grip Bench Press",
        "Tricep Pushdowns", "Overhead Tricep Extension", "Diamond Push-ups"
    ]

    private static let legExercises = [
        "Squats", "Front Squats", "Leg Press",
        "Lunges", "Bulgarian Split Squats"
    ] + [
        "Romanian Deadlift", "Leg Curls",
        "Leg Extensions", "Calf Raises", "Hip Thrusts"
    ]

    private static let coreExercises = [
        "Plank", "Crunches", "Russian Twists",
        "Mountain Climbers", "Dead Bug"
    ] + [
        "Bicycle Crunches", "Leg Raises",
        "Hanging Leg Raises", "Ab Wheel Rollouts", "Wood Chops"
    ]

    private func exerciseCategory(for exercise: String) -> String {
        
        if Self.chestExercises.contains(exercise) { return "Chest" }
        if Self.backExercises.contains(exercise) { return "Back" }
        if Self.shoulderExercises.contains(exercise) { return "Shoulders" }
        if Self.armExercises.contains(exercise) { return "Arms" }
        if Self.legExercises.contains(exercise) { return "Legs" }
        if Self.coreExercises.contains(exercise) { return "Core" }
        
        return "Custom"
    }
}

struct WorkoutSetRow: View {
    let setNumber: Int
    @State var set: WorkoutSet
    let onUpdate: (WorkoutSet) -> Void
    
    @State private var repsText = ""
    @State private var weightText = ""
    
    var body: some View {
        HStack(spacing: 12) {
            // Set number
            Text("\(setNumber)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(set.isCompleted ? .white : .primary)
                .frame(width: 32, height: 32)
                .background(set.isCompleted ? Color.green : Color(.systemGray5))
                .clipShape(Circle())
            
            // Reps input
            VStack(alignment: .leading, spacing: 4) {
                Text("Reps")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("0", text: $repsText)
                    .font(.system(size: 16, weight: .medium))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .frame(width: 60)
                    .onChange(of: repsText) { newValue in
                        set.reps = Int(newValue) ?? 0
                        onUpdate(set)
                    }
            }
            
            // Weight input
            VStack(alignment: .leading, spacing: 4) {
                Text("Weight (kg)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("0", text: $weightText)
                    .font(.system(size: 16, weight: .medium))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
                    .onChange(of: weightText) { newValue in
                        set.weight = Double(newValue) ?? 0.0
                        onUpdate(set)
                    }
            }
            
            Spacer()
            
            // Complete set button
            Button(action: {
                toggleSetCompletion()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16))
                    
                    Text(set.isCompleted ? "Done" : "Mark Done")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(set.isCompleted ? .green : .blue)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(set.isCompleted ? Color.green : Color(.systemGray4), lineWidth: 1)
        )
        .onAppear {
            repsText = set.reps > 0 ? "\(set.reps)" : ""
            weightText = set.weight > 0 ? String(format: "%.1f", set.weight) : ""
        }
    }
    
    private func toggleSetCompletion() {
        set.isCompleted.toggle()
        onUpdate(set)

        // Set completed - could add other logic here in the future
    }
}

struct AddSetButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                
                Text("Add Set")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 1, dash: [5]))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Professional Nutrition App UI Following Research Standards
// Based on analysis of MyFitnessPal, Lose It!, Cronometer, and Lifesum

struct ContentView: View {
    @StateObject private var diaryDataManager = DiaryDataManager.shared
    @State private var selectedTab: TabItem = .diary
    @State private var showingSettings = false
    @State private var selectedFoodItems: Set<String> = []
    @State private var showingMoveMenu = false
    @State private var editTrigger = false
    @State private var moveTrigger = false
    @State private var deleteTrigger = false
    @StateObject private var workoutManager = WorkoutManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                // Main Content with padding for tab bar and potential workout progress bar
            VStack {
                switch selectedTab {
                case .diary:
                    DiaryTabView(
                        selectedFoodItems: $selectedFoodItems,
                        showingSettings: $showingSettings,
                        selectedTab: $selectedTab,
                        editTrigger: $editTrigger,
                        moveTrigger: $moveTrigger,
                        deleteTrigger: $deleteTrigger,
                        onEditFood: editSelectedFood,
                        onDeleteFoods: deleteSelectedFoods
                    )
                    .environmentObject(diaryDataManager)
                    .environmentObject(healthKitManager)
                case .exercise:
                    ExerciseTabView(
                        showingSettings: $showingSettings,
                        selectedTab: $selectedTab
                    )
                    .environmentObject(workoutManager)
                case .add:
                    AddTabView(selectedTab: $selectedTab)
                        .environmentObject(diaryDataManager)
                case .food:
                    FoodTabView(showingSettings: $showingSettings)
                case .fridge:
                    FridgeTabView(showingSettings: $showingSettings, selectedTab: $selectedTab)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar positioned at bottom - hidden when in workout view
            if !workoutManager.isInWorkoutView {
                VStack {
                    Spacer()
                    CustomTabBar(selectedTab: $selectedTab, workoutManager: workoutManager)
                        .offset(y: 34) // Lower the tab bar to bottom edge
                }
            }
            
            // Persistent bottom menu when food items are selected - properly overlays tab bar
            if selectedTab == .diary && !selectedFoodItems.isEmpty {
                VStack {
                    Spacer()
                    PersistentBottomMenu(
                        selectedCount: selectedFoodItems.count,
                        onEdit: editSelectedFood,
                        onMove: {
                            moveTrigger = true
                        },
                        onStar: {
                            // TODO: Implement star
                        },
                        onDelete: deleteSelectedFoods,
                        onCancel: {
                            selectedFoodItems.removeAll() // Clear selection
                        }
                    )
                    .offset(y: 34) // Same offset as tab bar to replace it
                }
                .transition(.move(edge: .bottom))
                .animation(.easeInOut(duration: 0.3), value: selectedFoodItems.isEmpty)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToFridge)) { _ in
            selectedTab = .fridge
        }
        }
    }
    
    private func editSelectedFood() {
        guard selectedTab == .diary && !selectedFoodItems.isEmpty else { return }
        editTrigger = true
    }
    
    private func deleteSelectedFoods() {
        guard selectedTab == .diary && !selectedFoodItems.isEmpty else { return }
        deleteTrigger = true
    }
}

// MARK: - Tab Items
enum TabItem: String, CaseIterable {
    case diary = "diary"  
    case exercise = "exercise"
    case add = "add"
    case food = "food"
    case fridge = "fridge"
    
    var title: String {
        switch self {
        case .diary: return "Diary"
        case .exercise: return "Exercise"
        case .add: return ""
        case .food: return "Food"
        case .fridge: return "Fridge"
        }
    }
    
    var icon: String {
        switch self {
        case .diary: return "heart.circle"
        case .exercise: return "figure.run"
        case .add: return "plus"
        case .food: return "fork.knife.circle"
        case .fridge: return "refrigerator"
        }
    }
}

// MARK: - Custom Tab Bar (removed duplicate - using Views/Components/CustomTabBar.swift)

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    func apply<V: View>(@ViewBuilder _ transform: (Self) -> V) -> V {
        transform(self)
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Tab Views
// MARK: - Dead HomeTabView system removed - unreachable due to missing .home case in TabItem enum
// This entire 563-line struct was confirmed dead code during forensic audit
//
// struct HomeTabView: View {
//    @State private var animateProgress = false
//    @State private var headerOffset: CGFloat = 0
//    @Binding var showingSettings: Bool
//    @Binding var selectedTab: TabItem
//    
//    var body: some View {
//        NavigationView {
//            ScrollView {
//                LazyVStack(spacing: 16) {
//                    
//                    // Enhanced Header with modern styling
//                    VStack(spacing: 12) {
//                        HStack {
//                            VStack(alignment: .leading, spacing: 4) {
//                                Text("Good morning")
//                                    .font(.system(size: 16, weight: .medium))
//                                    .foregroundColor(.secondary)
//                                
//                                Text("Home")
//                                    .font(.system(size: 32, weight: .bold))
//                                    .foregroundColor(.primary)
//                            }
//                            
//                            Spacer()
//                            
//                            // Enhanced settings button with modern styling
//                            Button(action: {
//                                showingSettings = true
//                            }) {
//                                Image(systemName: "gearshape.fill")
//                                    .font(.system(size: 18, weight: .semibold))
//                                    .foregroundColor(.primary)
//                                    .frame(width: 44, height: 44)
//                                    .background(
//                                        RoundedRectangle(cornerRadius: 14)
//                                            .fill(.ultraThinMaterial)
//                                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
//                                    )
//                            }
//                            .buttonStyle(SpringyButtonStyle())
//                        }
//                        
//                        // Modern date indicator
//                        HStack {
//                            Text(Date(), style: .date)
//                                .font(.system(size: 14, weight: .medium))
//                                .foregroundColor(.secondary)
//                            Spacer()
//                            
//                            // Health status indicator
//                            HStack(spacing: 6) {
//                                Circle()
//                                    .fill(Color.green)
//                                    .frame(width: 8, height: 8)
//                                Text("On track")
//                                    .font(.system(size: 12, weight: .medium))
//                                    .foregroundColor(.green)
//                            }
//                        }
//                    }
//                    .padding(.horizontal, 20)
//                    .padding(.top, 8)
//                    
//                    // Enhanced Main Daily Nutrition Summary
//                    ProfessionalSummaryCard(
//                        dailyNutrition: sampleDailyNutrition,
//                        selectedDate: Date(),
//                        animateProgress: animateProgress
//                    )
//                    .padding(.horizontal, 20)
//                    .scaleEffect(animateProgress ? 1.0 : 0.95)
//                    .opacity(animateProgress ? 1.0 : 0.8)
//                    
//                    // Quick Actions Section
//                    HomeQuickActionsCard(selectedTab: $selectedTab)
//                        .padding(.horizontal, 16)
//                    
//                    // Today's Diary Overview
//                    HomeDiaryOverviewCard()
//                        .padding(.horizontal, 16)
//                    
//                    // Fridge Expiry Alerts
//                    HomeFridgeAlertsCard()
//                        .padding(.horizontal, 16)
//                    
//                    // Food Insights
//                    HomeFoodInsightsCard()
//                        .padding(.horizontal, 16)
//                    
//                    // Health Score Overview
//                    HomeHealthScoreCard()
//                        .padding(.horizontal, 16)
//                    
//                    Rectangle()
//                        .fill(Color.clear)
//                        .frame(height: 100)
//                }
//            }
//            .background(Color(.systemBackground))
//            .navigationBarHidden(true)
//        }
//        .onAppear {
//            withAnimation(.spring(response: 1.2, dampingFraction: 0.8, blendDuration: 0).delay(0.1)) {
//                animateProgress = true
//            }
//        }
//    }

// MARK: - Home Tab Overview Cards

//struct HomeQuickActionsCard: View {
//    @Binding var selectedTab: TabItem
//    @State private var waterCount = UserDefaults.standard.integer(forKey: "dailyWaterCount")
//    @State private var isFasting = UserDefaults.standard.bool(forKey: "isFasting")
//    @State private var fastingStartTime = UserDefaults.standard.object(forKey: "fastingStartTime") as? Date
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text("Quick Actions")
//                .font(.system(size: 18, weight: .semibold))
//                .foregroundColor(.primary)
//            
//            HStack(spacing: 12) {
//                HomeQuickActionButton(
//                    icon: "plus.circle.fill",
//                    title: "Add Food",
//                    color: .blue
//                ) {
//                    selectedTab = .add
//                }
//                
//                HomeQuickActionButton(
//                    icon: "camera.fill",
//                    title: "Scan",
//                    color: .green
//                ) {
//                    selectedTab = .add
//                }
//                
//                HomeQuickActionButton(
//                    icon: "drop.fill",
//                    title: "Water",
//                    color: .cyan
//                ) {
//                    addWater()
//                }
//                
//                HomeQuickActionButton(
//                    icon: isFasting ? "pause.circle.fill" : "play.circle.fill",
//                    title: isFasting ? "Stop Fast" : "Start Fast",
//                    color: isFasting ? .red : .green
//                ) {
//                    toggleFasting()
//                }
//            }
//        }
//        .padding(16)
//        .background(Color(.systemGray6))
//        .cornerRadius(12)
//    }
//    
//    private func addWater() {
//        waterCount += 1
//        UserDefaults.standard.set(waterCount, forKey: "dailyWaterCount")
//        
//        // Add haptic feedback
//        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
//        impactFeedback.impactOccurred()
//    }
//    
//    private func toggleFasting() {
//        if isFasting {
//            // Stop fasting
//            isFasting = false
//            fastingStartTime = nil
//            UserDefaults.standard.set(false, forKey: "isFasting")
//            UserDefaults.standard.removeObject(forKey: "fastingStartTime")
//        } else {
//            // Start fasting
//            isFasting = true
//            fastingStartTime = Date()
//            UserDefaults.standard.set(true, forKey: "isFasting")
//            UserDefaults.standard.set(fastingStartTime, forKey: "fastingStartTime")
//        }
//        
//        // Add haptic feedback
//        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
//        impactFeedback.impactOccurred()
//    }
//}

//struct HomeQuickActionButton: View {
//    let icon: String
//    let title: String
//    let color: Color
//    let action: () -> Void
//    
//    var body: some View {
//        Button(action: action) {
//            VStack(spacing: 6) {
//                Image(systemName: icon)
//                    .font(.system(size: 20))
//                    .foregroundColor(color)
//                
//                Text(title)
//                    .font(.system(size: 12, weight: .medium))
//                    .foregroundColor(.primary)
//            }
//            .frame(maxWidth: .infinity)
//            .padding(.vertical, 12)
//            .background(Color(.systemBackground))
//            .cornerRadius(8)
//        }
//        .buttonStyle(PlainButtonStyle())
//    }
//}

//struct HomeDiaryOverviewCard: View {
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            HStack {
//                Text("Today's Diary")
//                    .font(.system(size: 18, weight: .semibold))
//                    .foregroundColor(.primary)
//                
//                Spacer()
//                
//                Button("View All") {
//                    print("View all diary tapped")
//                }
//                .font(.system(size: 14, weight: .medium))
//                .foregroundColor(.blue)
//            }
//            
//            VStack(spacing: 8) {
//                HomeDiaryMealRow(
//                    mealType: "Breakfast",
//                    calories: 420,
//                    items: 3,
//                    color: .orange
//                )
//                
//                HomeDiaryMealRow(
//                    mealType: "Lunch", 
//                    calories: 0,
//                    items: 0,
//                    color: .green
//                )
//                
//                HomeDiaryMealRow(
//                    mealType: "Dinner",
//                    calories: 0,
//                    items: 0,
//                    color: .purple
//                )
//            }
//        }
//        .padding(16)
//        .background(Color(.systemGray6))
//        .cornerRadius(12)
//    }
//}

//struct HomeDiaryMealRow: View {
//    let mealType: String
//    let calories: Int
//    let items: Int
//    let color: Color
//    
//    var body: some View {
//        HStack {
//            Circle()
//                .fill(color)
//                .frame(width: 8, height: 8)
//            
//            Text(mealType)
//                .font(.system(size: 15, weight: .medium))
//                .foregroundColor(.primary)
//            
//            Spacer()
//            
//            if calories > 0 {
//                Text("\(calories) cal • \(items) items")
//                    .font(.system(size: 13))
//                    .foregroundColor(.secondary)
//            } else {
//                Text("No items")
//                    .font(.system(size: 13))
//                    .foregroundColor(.secondary)
//            }
//        }
//    }
//}

//struct HomeFridgeAlertsCard: View {
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            HStack {
//                Text("Fridge Alerts")
//                    .font(.system(size: 18, weight: .semibold))
//                    .foregroundColor(.primary)
//                
//                Spacer()
//                
//                Button("Manage") {
//                    print("Manage fridge tapped")
//                }
//                .font(.system(size: 14, weight: .medium))
//                .foregroundColor(.blue)
//            }
//            
//            VStack(spacing: 8) {
//                HomeFridgeAlertRow(
//                    item: "Greek Yoghurt",
//                    daysLeft: 2,
//                    urgency: .high
//                )
//                
//                HomeFridgeAlertRow(
//                    item: "Chicken Breast",
//                    daysLeft: 1,
//                    urgency: .critical
//                )
//                
//                HomeFridgeAlertRow(
//                    item: "Spinach",
//                    daysLeft: 4,
//                    urgency: .medium
//                )
//            }
//        }
//        .padding(16)
//        .background(Color(.systemGray6))
//        .cornerRadius(12)
//    }
//}

//struct HomeFridgeAlertRow: View {
//    let item: String
//    let daysLeft: Int
//    let urgency: AlertUrgency
//    
//    enum AlertUrgency {
//        case low, medium, high, critical
//        
//        var color: Color {
//            switch self {
//            case .low: return .green
//            case .medium: return .yellow
//            case .high: return .orange
//            case .critical: return .red
//            }
//        }
//        
//        func text(for days: Int) -> String {
//            switch self {
//            case .critical: return "Expires today"
//            default: return "\(days) days left"
//            }
//        }
//    }
//    
//    var body: some View {
//        HStack {
//            Circle()
//                .fill(urgency.color)
//                .frame(width: 8, height: 8)
//            
//            Text(item)
//                .font(.system(size: 15, weight: .medium))
//                .foregroundColor(.primary)
//            
//            Spacer()
//            
//            Text(urgency.text(for: daysLeft))
//                .font(.system(size: 13))
//                .foregroundColor(.secondary)
//        }
//    }
//}

//struct HomeFoodInsightsCard: View {
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text("Food Insights")
//                .font(.system(size: 18, weight: .semibold))
//                .foregroundColor(.primary)
//            
//            VStack(spacing: 12) {
//                HStack {
//                    VStack(alignment: .leading, spacing: 4) {
//                        Text("Safe Foods")
//                            .font(.system(size: 14, weight: .medium))
//                            .foregroundColor(.primary)
//                        
//                        Text("47 items")
//                            .font(.system(size: 12))
//                            .foregroundColor(.secondary)
//                    }
//                    
//                    Spacer()
//                    
//                    Image(systemName: "checkmark.seal.fill")
//                        .font(.system(size: 20))
//                        .foregroundColor(.green)
//                }
//                .padding(12)
//                .background(Color(.systemBackground))
//                .cornerRadius(8)
//                
//                HStack {
//                    VStack(alignment: .leading, spacing: 4) {
//                        Text("Weekly Pattern")
//                            .font(.system(size: 14, weight: .medium))
//                            .foregroundColor(.primary)
//                        
//                        Text("Improving trends")
//                            .font(.system(size: 12))
//                            .foregroundColor(.secondary)
//                    }
//                    
//                    Spacer()
//                    
//                    Image(systemName: "chart.line.uptrend.xyaxis")
//                        .font(.system(size: 20))
//                        .foregroundColor(.blue)
//                }
//                .padding(12)
//                .background(Color(.systemBackground))
//                .cornerRadius(8)
//            }
//        }
//        .padding(16)
//        .background(Color(.systemGray6))
//        .cornerRadius(12)
//    }
//}

//struct HomeHealthScoreCard: View {
//    @State private var waterCount = UserDefaults.standard.integer(forKey: "dailyWaterCount")
//    @State private var isFasting = UserDefaults.standard.bool(forKey: "isFasting")
//    @State private var fastingStartTime = UserDefaults.standard.object(forKey: "fastingStartTime") as? Date
//    
//    private var hydrationStatus: (text: String, color: Color) {
//        switch waterCount {
//        case 0: return ("Dehydrated", .red)
//        case 1...3: return ("Poor", .orange)
//        case 4...6: return ("Fair", .yellow)
//        case 7...8: return ("Good", .green)
//        case 9...: return ("Excellent", .blue)
//        default: return ("Poor", .orange)
//        }
//    }
//    
//    private var fastingStatus: (text: String, color: Color) {
//        guard isFasting, let startTime = fastingStartTime else {
//            return ("Not Fasting", .gray)
//        }
//        
//        let elapsed = Date().timeIntervalSince(startTime)
//        let hours = elapsed / 3600
//        
//        switch hours {
//        case 0..<12: return ("Early Stage", .orange)
//        case 12..<16: return ("Progressing", .yellow)
//        case 16..<20: return ("Good Progress", .green)
//        case 20...: return ("Extended Fast", .blue)
//        default: return ("Active", .orange)
//        }
//    }
//    
//    private var fastingDuration: String {
//        guard isFasting, let startTime = fastingStartTime else {
//            return "0h 0m"
//        }
//        
//        let elapsed = Date().timeIntervalSince(startTime)
//        let hours = Int(elapsed) / 3600
//        let minutes = (Int(elapsed) % 3600) / 60
//        return "\(hours)h \(minutes)m"
//    }
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text("Health Score")
//                .font(.system(size: 18, weight: .semibold))
//                .foregroundColor(.primary)
//            
//            HStack(spacing: 16) {
//                VStack(spacing: 4) {
//                    Text("84")
//                        .font(.system(size: 32, weight: .bold))
//                        .foregroundColor(.green)
//                    
//                    Text("Today")
//                        .font(.system(size: 12))
//                        .foregroundColor(.secondary)
//                }
//                
//                VStack(alignment: .leading, spacing: 6) {
//                    HStack {
//                        Text("Nutrition:")
//                            .font(.system(size: 13))
//                            .foregroundColor(.secondary)
//                        Text("Good")
//                            .font(.system(size: 13, weight: .medium))
//                            .foregroundColor(.green)
//                    }
//                    
//                    HStack {
//                        Text("Hydration:")
//                            .font(.system(size: 13))
//                            .foregroundColor(.secondary)
//                        Text(hydrationStatus.text)
//                            .font(.system(size: 13, weight: .medium))
//                            .foregroundColor(hydrationStatus.color)
//                        Text("(\(waterCount) glasses)")
//                            .font(.system(size: 12))
//                            .foregroundColor(.secondary)
//                    }
//                    
//                    HStack {
//                        Text("Fasting:")
//                            .font(.system(size: 13))
//                            .foregroundColor(.secondary)
//                        Text(fastingStatus.text)
//                            .font(.system(size: 13, weight: .medium))
//                            .foregroundColor(fastingStatus.color)
//                        if isFasting {
//                            Text("(\(fastingDuration))")
//                                .font(.system(size: 12))
//                                .foregroundColor(.secondary)
//                        }
//                    }
//                }
//                
//                Spacer()
//            }
//        }
//        .padding(16)
//        .background(Color(.systemGray6))
//        .cornerRadius(12)
//        .onAppear {
//            waterCount = UserDefaults.standard.integer(forKey: "dailyWaterCount")
//            isFasting = UserDefaults.standard.bool(forKey: "isFasting")
//            fastingStartTime = UserDefaults.standard.object(forKey: "fastingStartTime") as? Date
//        }
//        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
//            waterCount = UserDefaults.standard.integer(forKey: "dailyWaterCount")
//            isFasting = UserDefaults.standard.bool(forKey: "isFasting")
//            fastingStartTime = UserDefaults.standard.object(forKey: "fastingStartTime") as? Date
//        }
//        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
//            // Update every minute to refresh fasting duration display
//            if isFasting {
//                // Trigger a UI update by re-reading the state (this will cause computed properties to refresh)
//                isFasting = UserDefaults.standard.bool(forKey: "isFasting")
//            }
//        }
//    }
// }

// MARK: - ExerciseTabView moved to separate file
// struct ExerciseTabView: View {
//     @Binding var showingSettings: Bool
//     @Binding var selectedTab: TabItem
//     @State private var selectedDate: Date = Date()
//     @State private var showingDatePicker: Bool = false
//     @State private var selectedExerciseSubTab: ExerciseSubTab = .workout
//     @EnvironmentObject var workoutManager: WorkoutManager
//     
//     enum ExerciseSubTab: String, CaseIterable {
//         case workout = "Workout"
//         case history = "History"
//         case stats = "Stats"
//         
//         var icon: String {
//             switch self {
//             case .workout: return "dumbbell.fill"
//             case .history: return "clock.arrow.circlepath"
//             case .stats: return "chart.bar.fill"
//             }
//         }
//     }
//     
//     var body: some View {
//         NavigationView {
//             VStack(spacing: 0) {
                // Header
//                 VStack(spacing: 16) {
//                     HStack {
//                         Text("Exercise")
//                             .font(.system(size: 32, weight: .bold))
//                             .foregroundColor(.primary)
//                         
//                         Spacer()
//                         
                        // Date display with arrow navigation
//                         HStack(spacing: 12) {
                            // Previous day arrow
//                             Button(action: {
//                                 let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
//                                 selectedDate = previousDay
//                             }) {
//                                 Image(systemName: "chevron.left.circle.fill")
//                                     .font(.system(size: 20, weight: .medium))
//                                     .foregroundColor(.blue)
//                             }
//                             .buttonStyle(PlainButtonStyle())
//                             
                            // Current date display - tappable to open calendar
//                             Button(action: {
//                                 showingDatePicker = true
//                             }) {
//                                 Text(dateDisplayText(selectedDate))
//                                     .font(.system(size: 16, weight: .medium))
//                                     .foregroundColor(.primary)
//                                     .frame(minWidth: 80)
//                             }
//                             .buttonStyle(PlainButtonStyle())
//                             
                            // Next day arrow  
//                             Button(action: {
//                                 let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
//                                 selectedDate = nextDay
//                             }) {
//                                 Image(systemName: "chevron.right.circle.fill")
//                                     .font(.system(size: 20, weight: .medium))
//                                     .foregroundColor(.blue)
//                             }
//                             .buttonStyle(PlainButtonStyle())
//                         }
//                         .padding(.horizontal, 12)
//                         .padding(.vertical, 8)
//                         .background(Color(.systemGray6))
//                         .cornerRadius(8)
//                         
                        // Settings button
//                         Button(action: {
//                             showingSettings = true
//                         }) {
//                             Image(systemName: "gearshape.fill")
//                                 .font(.system(size: 20))
//                                 .foregroundColor(.primary)
//                                 .frame(width: 40, height: 40)
//                                 .background(Color(.systemGray6))
//                                 .clipShape(Circle())
//                         }
//                     }
//                     .padding(.horizontal, 16)
//                     .padding(.top, 16)
//                     
                    // Sub-tab selector
//                     ExerciseSubTabSelector(selectedTab: $selectedExerciseSubTab)
//                         .padding(.horizontal, 16)
//                 }
//                 .background(Color(.systemBackground))
//                 
                // Content based on selected sub-tab
//                 switch selectedExerciseSubTab {
//                 case .workout:
//                     WorkoutMainView(selectedDate: selectedDate)
//                         .environmentObject(workoutManager)
//                         .frame(maxWidth: .infinity, maxHeight: .infinity)
//                 case .history:
//                     ExerciseHistoryView(exerciseName: "")
//                         .frame(maxWidth: .infinity, maxHeight: .infinity)
//                 case .stats:
//                     ExerciseStatsView()
//                         .frame(maxWidth: .infinity, maxHeight: .infinity)
//                 }
//             }
//             .background(Color(.systemBackground))
//             .navigationBarHidden(true)
//             .sheet(isPresented: $showingDatePicker) {
//                 NavigationView {
//                     VStack {
//                         DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
//                             .datePickerStyle(.graphical)
//                             .padding()
//                         
//                         Spacer()
//                     }
//                     .navigationTitle("Select Date")
//                     .navigationBarTitleDisplayMode(.inline)
//                     .toolbar {
//                         ToolbarItem(placement: .navigationBarTrailing) {
//                             Button("Done") {
//                                 showingDatePicker = false
//                             }
//                         }
//                     }
//                 }
//             }
//         }
//     }
//     
    // Helper function for date display
//     private func dateDisplayText(_ date: Date) -> String {
//         let formatter = DateFormatter()
//         let calendar = Calendar.current
//         
//         if calendar.isDateInToday(date) {
//             return "Today"
//         } else if calendar.isDateInYesterday(date) {
//             return "Yesterday"
//         } else if calendar.isDateInTomorrow(date) {
//             return "Tomorrow"
//         } else {
//             formatter.dateFormat = "MMM d"
//             return formatter.string(from: date)
//         }
//     }
// }
// 
// 
// 
// MARK: - Diary Exercise View (with Applied Atomic Constants)
// DiaryExerciseView moved to Views/Exercise/ExerciseSelectionViews.swift
// 
// MARK: - Workout Summary Card
// End of ExerciseTabView - see extracted file for implementation

struct WorkoutSummaryCard: View {
    let workout: WorkoutSessionSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with user info and time
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("akeen90") // TODO: Get actual username
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(timeAgoText)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    // TODO: More options
                }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            
            // Workout title
            Text(workout.name)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            // Workout stats
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("\(workout.duration)min")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Volume")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(String(format: "%.0f kg", workout.totalVolume))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                if let heartRate = workout.averageHeartRate {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                        Text("\(heartRate)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
            }
            
            // Exercise list
            VStack(alignment: .leading, spacing: 8) {
                ForEach(workout.exercises.prefix(3)) { exercise in
                    HStack(spacing: 12) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("\(exercise.sets) sets \(exercise.exerciseType)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
                
                if workout.exercises.count > 3 {
                    Text("+ \(workout.exercises.count - 3) more exercises")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.leading, 36)
                }
            }
            
            // Action buttons
            HStack(spacing: 16) {
                Button(action: {
                    // TODO: Like functionality
                }) {
                    Image(systemName: "hand.thumbsup")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    // TODO: Comment functionality
                }) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    // TODO: Share functionality
                }) {
                    Image(systemName: "arrowshape.turn.up.right")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var timeAgoText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: workout.date, relativeTo: Date())
    }
}

// MARK: - Advanced Workout View (Hevy-style) - EXTRACTED TO MODULAR COMPONENT
// NewWorkoutCreationView moved to Views/Exercise/NewWorkoutCreationView.swift
// MARK: - NewWorkoutCreationView has been extracted to modular component
// This struct has been moved to Views/Exercise/NewWorkoutCreationView.swift
// as part of the ContentView.swift modularization effort.

// MARK: - FunctionalExerciseCard - EXTRACTED TO MODULAR COMPONENT
// The FunctionalExerciseCard struct has been extracted to Components/Exercise/FunctionalExerciseCard.swift
// as part of the ContentView.swift modularization effort to break down the 19,000+ line monolithic file.

// MARK: - Set Row View
// The SetRowView struct has been extracted to Components/Exercise/SetRowViews.swift
// as part of the ContentView.swift modularization effort to break down the 19,600+ line monolithic file.

// MARK: - Cardio Set Row View
// The CardioSetRowView struct has been extracted to Components/Exercise/SetRowViews.swift
// as part of the ContentView.swift modularization effort to break down the 19,600+ line monolithic file.

// MARK: - Helper Functions
func formatRestTime(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let remainingSeconds = seconds % 60
    if minutes > 0 {
        if remainingSeconds > 0 {
            return "\(minutes)m \(remainingSeconds)s"
        } else {
            return "\(minutes)m"
        }
    } else {
        return "\(remainingSeconds)s"
    }
}

// MARK: - Rest Timer Compact View
// The RestTimerCompactView struct has been extracted to Components/Exercise/RestTimerViews.swift
// as part of the ContentView.swift modularization effort to break down the 19,600+ line monolithic file.

// MARK: - Rest Timer Floating View  
// The RestTimerFloatingView struct has been extracted to Components/Exercise/RestTimerViews.swift
// as part of the ContentView.swift modularization effort to break down the 19,600+ line monolithic file.

// MARK: - Workout Header View
// The WorkoutHeaderView struct has been extracted to Components/Exercise/WorkoutHeaderView.swift
// as part of the ContentView.swift modularization effort to break down the 18,953+ line monolithic file.

// MARK: - Quick Actions Bar
// The QuickActionsBar struct has been extracted to Components/Exercise/WorkoutActionComponents.swift
// as part of the ContentView.swift modularization effort to break down the 18,953+ line monolithic file.

// MARK: - Advanced Exercise Card
// The AdvancedExerciseCard struct has been extracted to Components/Exercise/WorkoutActionComponents.swift
// as part of the ContentView.swift modularization effort to break down the 18,953+ line monolithic file.

// MARK: - Advanced Set Row
// The AdvancedSetRow struct has been extracted to Components/Exercise/WorkoutActionComponents.swift
// as part of the ContentView.swift modularization effort to break down the 18,953+ line monolithic file.

// MARK: - Empty Workout View
// EXTRACTED TO: Components/Exercise/ExercisePickerComponents.swift

// MARK: - Advanced Exercise Picker
// EXTRACTED TO: Components/Exercise/ExercisePickerComponents.swift

// MARK: - Exercise Selection Row
// EXTRACTED TO: Components/Exercise/ExercisePickerComponents.swift

// MARK: - Workout Templates View
// EXTRACTED TO: Views/Exercise/WorkoutTemplatesView.swift
// This comprehensive workout template view contains 10 pre-built workout templates
// including Push/Pull/Leg days, Full Body circuits, HIIT cardio, Yoga & mobility,
// Core focus, and Powerlifting basics with complete exercise definitions.

// MARK: - Workout Template Card View
// EXTRACTED TO: Views/Exercise/WorkoutTemplatesView.swift
// Interactive card component for displaying workout template summaries with
// exercise previews, duration info, and context menu actions (start, edit, copy, delete).

// MARK: - Workout Template Detail View
// EXTRACTED TO: Views/Exercise/WorkoutTemplatesView.swift
// Detailed view showing complete workout template information including all exercises
// with primary/secondary muscle groups, equipment requirements, and start workout functionality.

// EXTRACTED: WorkoutHistoryView -> Views/Exercise/ExerciseHistoryViews.swift

// MARK: - Exercise Picker View
// EXTRACTED TO: Components/Exercise/ExerciseUtilityViews.swift

// MARK: - Search Bar Component
// EXTRACTED TO: Components/Exercise/ExercisePickerComponents.swift

// MARK: - Per-Exercise Rest Timer View
// EXTRACTED TO: Components/Exercise/ExerciseUtilityViews.swift

// MARK: - Exercise Tab Selector
// EXTRACTED TO: Components/Exercise/ExerciseUtilityViews.swift

// MARK: - Exercise Home View
// EXTRACTED TO: Components/Exercise/ExerciseUtilityViews.swift

// EXTRACTED: ExerciseWorkoutsView -> Views/Exercise/ExerciseHistoryViews.swift

// EXTRACTED: ExerciseStatsView -> Views/Exercise/ExerciseDetailViews.swift

// EXTRACTED: WorkoutHistoryCard -> Views/Exercise/ExerciseHistoryViews.swift

// EXTRACTED: WorkoutTemplateCard -> Views/Exercise/ExerciseHistoryViews.swift

// EXTRACTED: WorkoutTemplateQuickCard -> Views/Exercise/ExerciseHistoryViews.swift

// EXTRACTED: StatCard -> Views/Exercise/ExerciseDetailViews.swift

// EXTRACTED: ExerciseSummaryView -> Views/Exercise/ExerciseDetailViews.swift

// EXTRACTED: ExerciseHistoryView -> Views/Exercise/ExerciseHistoryViews.swift

// EXTRACTED: ExerciseTemplatesView -> Views/Exercise/ExerciseHistoryViews.swift

// EXTRACTED: WorkoutSummaryRow -> Views/Exercise/ExerciseHistoryViews.swift

// EXTRACTED: ExerciseEntryRow -> Views/Exercise/ExerciseHistoryViews.swift

// MARK: - Workout History Row
struct WorkoutHistoryRow: View {
    let workout: WorkoutSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(DateFormatter.shortDate.string(from: workout.startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Duration: N/A") // TODO: Calculate duration
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Calories: N/A") // TODO: Calculate calories
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}

// MARK: - Working Set Data Structure (Simple inline sets)
struct WorkingSet: Identifiable {
    let id = UUID()
    var weight: String = ""
    var reps: String = ""
    var isCompleted: Bool = false
}

// MARK: - Exercise Workout Card Component
struct ExerciseWorkoutCard: View {
    let exercise: String
    let sets: [WorkoutSet]
    let onAddSet: (WorkoutSet) -> Void
    let onRemoveSet: (Int) -> Void
    let onMove: (Int, Int) -> Void
    let exerciseIndex: Int
    let totalExercises: Int
    
    @EnvironmentObject var restTimerManager: ExerciseRestTimerManager
    @State private var workingSets: [WorkingSet] = []
    @State private var restTime: String = "3:00" // Default 3 minutes for heavy lifting
    @State private var showingRestTimePicker = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Exercise Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise)
                        .font(.headline)
                        .font(.headline.weight(.semibold))
                    
                    if !sets.isEmpty {
                        Text("\(sets.count) sets completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Rest Time Picker
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Rest Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showingRestTimePicker = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.caption)
                            Text(restTime)
                                .font(.caption.weight(.medium).monospacedDigit())
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            
            // Simple Inline Sets
            VStack(spacing: 8) {
                // Sets header
                HStack {
                    Text("Sets")
                        .font(.subheadline.weight(.medium))
                    
                    Spacer()
                }
                
                // Working sets (inline editing)
                ForEach(Array(workingSets.enumerated()), id: \.element.id) { index, workingSet in
                    HStack {
                        // Set number
                        Text("\(index + 1)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 25)
                        
                        // Weight input
                        TextField("kg", text: Binding(
                            get: { workingSets[index].weight },
                            set: { workingSets[index].weight = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .frame(width: 60)
                        
                        Text("kg")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Reps input
                        TextField("reps", text: Binding(
                            get: { workingSets[index].reps },
                            set: { workingSets[index].reps = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .frame(width: 50)
                        
                        Text("reps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Complete button
                        if !workingSet.isCompleted {
                            Button(action: {
                                completeWorkingSet(at: index)
                            }) {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(canCompleteSet(workingSet) ? .green : .gray)
                                    .font(.title3)
                            }
                            .disabled(!canCompleteSet(workingSet))
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Add Set Button (underneath sets)
                Button(action: addEmptySet) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                        Text("Add Set")
                            .foregroundColor(.blue)
                    }
                    .font(.subheadline)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.top, 8)
                
                // Completed Sets Summary (if any)
                if !sets.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Completed: \(sets.count) sets")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal, 20)
        .onAppear {
            // Initialize with one empty set if no working sets exist
            if workingSets.isEmpty {
                workingSets.append(WorkingSet())
            }
        }
        .sheet(isPresented: $showingRestTimePicker) {
            RestTimePickerView(selectedTime: $restTime)
        }
    }
    
    private func addEmptySet() {
        workingSets.append(WorkingSet())
    }
    
    private func canCompleteSet(_ workingSet: WorkingSet) -> Bool {
        !workingSet.weight.isEmpty && !workingSet.reps.isEmpty &&
        Double(workingSet.weight) ?? 0 > 0 && Int(workingSet.reps) ?? 0 > 0
    }
    
    private func completeWorkingSet(at index: Int) {
        guard index < workingSets.count else { return }
        let workingSet = workingSets[index]
        
        guard let weight = Double(workingSet.weight),
              let reps = Int(workingSet.reps),
              weight > 0, reps > 0 else { return }
        
        // Mark as completed
        // workingSets[index].completed = true // TODO: Fix WorkingSet model

        // Create completed WorkoutSet
        let completedSet = WorkoutSet(weight: weight, reps: reps, isCompleted: true)
        onAddSet(completedSet)
        
        // Start rest timer with custom duration for this exercise
        let restDuration = parseRestTime(restTime)
        restTimerManager.startTimer(for: exercise, exerciseName: exercise, duration: restDuration)
    }
    
    // Helper function to parse rest time from "M:SS" format to seconds
    private func parseRestTime(_ timeString: String) -> TimeInterval {
        let components = timeString.split(separator: ":").compactMap { Int($0) }
        if components.count == 2 {
            return TimeInterval(components[0] * 60 + components[1])
        }
        return 180 // Default to 3 minutes if parsing fails
    }
}

// MARK: - Rest Time Picker View
struct RestTimePickerView: View {
    @Binding var selectedTime: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var minutes = 3
    @State private var seconds = 0
    
    private let minuteOptions = Array(0...10) // 0-10 minutes
    private let secondOptions = Array(0...59) // 0-59 seconds
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Set Rest Time")
                    .font(.title2.weight(.semibold))
                    .padding(.top)
                
                Text("How long do you want to rest between sets for this exercise?")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Quick presets
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Presets")
                        .font(.headline.weight(.medium))
                        .padding(.leading, 4)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        RestTimePresetButton(time: "1:00", description: "Light", isSelected: selectedTime == "1:00") {
                            selectedTime = "1:00"
                            dismiss()
                        }
                        RestTimePresetButton(time: "2:00", description: "Medium", isSelected: selectedTime == "2:00") {
                            selectedTime = "2:00"
                            dismiss()
                        }
                        RestTimePresetButton(time: "3:00", description: "Heavy", isSelected: selectedTime == "3:00") {
                            selectedTime = "3:00"
                            dismiss()
                        }
                        RestTimePresetButton(time: "4:00", description: "Max", isSelected: selectedTime == "4:00") {
                            selectedTime = "4:00"
                            dismiss()
                        }
                        RestTimePresetButton(time: "5:00", description: "Power", isSelected: selectedTime == "5:00") {
                            selectedTime = "5:00"
                            dismiss()
                        }
                        RestTimePresetButton(time: "0:30", description: "Circuit", isSelected: selectedTime == "0:30") {
                            selectedTime = "0:30"
                            dismiss()
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Custom time picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Custom Time")
                        .font(.headline.weight(.medium))
                        .padding(.leading, 4)
                    
                    HStack {
                        // Minutes picker
                        Picker("Minutes", selection: $minutes) {
                            ForEach(minuteOptions, id: \.self) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80)
                        
                        Text("min")
                            .font(.body.weight(.medium))
                            .foregroundColor(.secondary)
                        
                        // Seconds picker
                        Picker("Seconds", selection: $seconds) {
                            ForEach(secondOptions, id: \.self) { second in
                                Text(String(format: "%02d", second)).tag(second)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80)
                        
                        Text("sec")
                            .font(.body.weight(.medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Set") {
                        selectedTime = String(format: "%d:%02d", minutes, seconds)
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                }
            }
        }
        .onAppear {
            // Parse current selected time to set initial picker values
            let components = selectedTime.split(separator: ":").compactMap { Int($0) }
            if components.count == 2 {
                minutes = components[0]
                seconds = components[1]
            }
        }
    }
}

struct RestTimePresetButton: View {
    let time: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(time)
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(description)
                    .font(.caption.weight(.medium))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue : Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Comprehensive Workout View (Legacy)

// ComprehensiveWorkoutView moved to Views/Exercise/ExerciseSelectionViews.swift

// MARK: - Exercise Selection View

// ExerciseSelectionView moved to Views/Exercise/ExerciseSelectionViews.swift

// MARK: - Cardio Exercise Models

// CardioExercise and CardioExerciseRow moved to Views/Exercise/ExerciseSelectionViews.swift

// MARK: - Exercise Entry View

struct ExerciseEntryView: View {
    let exerciseType: ExerciseType
    let onAdd: (DiaryExerciseItem) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var exerciseName = ""
    @State private var duration = ""
    @State private var selectedIntensity: ExerciseIntensity = .moderate
    @State private var selectedExercise = ""
    @State private var showingExercisePicker = false
    @State private var showingWeightTraining = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Exercise Details")) {
                    HStack {
                        Text("Type")
                        Spacer()
                        HStack(spacing: 6) {
                            Circle()
                                .fill(exerciseType.color)
                                .frame(width: 12, height: 12)
                            Text(exerciseType.displayName)
                                .foregroundColor(.secondary)
                                .onAppear {
                                    print("🎯 ExerciseEntryView opened with type: \(exerciseType.rawValue)")
                                }
                        }
                    }
                    
                    Button(action: {
                        showingExercisePicker = true
                    }) {
                        HStack {
                            Text("Exercise")
                            Spacer()
                            Text(selectedExercise.isEmpty ? "Select exercise" : selectedExercise)
                                .foregroundColor(selectedExercise.isEmpty ? .secondary : .primary)
                        }
                    }
                    
                    HStack {
                        Text("Duration")
                        Spacer()
                        TextField("Minutes", text: $duration)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker("Intensity", selection: $selectedIntensity) {
                        ForEach(ExerciseIntensity.allCases, id: \.self) { intensity in
                            Text(intensity.rawValue.capitalized).tag(intensity)
                        }
                    }
                }
                
                // Weight training option for strength exercises
                if exerciseType == .resistance {
                    Section(header: Text("Training Mode")) {
                        Button(action: {
                            showingWeightTraining = true
                        }) {
                            HStack {
                                Image(systemName: "dumbbell.fill")
                                    .foregroundColor(.indigo)
                                    .font(.system(size: 16))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Weight Training Mode")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    Text("Track sets, reps, weight & rest time")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                if !selectedExercise.isEmpty && !duration.isEmpty {
                    Section(header: Text("Estimated Calories")) {
                        let estimatedCalories = calculateEstimatedCalories()
                        HStack {
                            Text("Calories Burned")
                            Spacer()
                            Text("\(Int(estimatedCalories))")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(exerciseType.color)
                        }
                    }
                }
            }
            .navigationTitle("Add \(exerciseType.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addExercise()
                    }
                    .disabled(selectedExercise.isEmpty || duration.isEmpty)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExerciseSelectionView(selectedExercises: .constant([selectedExercise]))
            }
            .sheet(isPresented: $showingWeightTraining) {
                WeightTrainingView()
            }
        }
    }
    
    private func calculateEstimatedCalories() -> Double {
        guard let durationMinutes = Double(duration) else { return 0 }
        let userWeight = healthKitManager.userWeight > 0 ? healthKitManager.userWeight : 70.0
        
        return DiaryExerciseItem.calculateCalories(
            exercise: selectedExercise,
            exerciseType: exerciseType,
            duration: Int(durationMinutes),
            intensity: selectedIntensity,
            userWeight: userWeight
        )
    }
    
    private func addExercise() {
        guard let durationMinutes = Int(duration) else { return }
        
        let currentTime = DateFormatter()
        currentTime.dateFormat = "HH:mm"
        let timeString = currentTime.string(from: Date())
        
        let calories = calculateEstimatedCalories()
        
        let exercise = DiaryExerciseItem(
            name: selectedExercise,
            duration: durationMinutes,
            intensity: selectedIntensity,
            calories: calories,
            time: timeString,
            exerciseType: exerciseType
        )
        
        onAdd(exercise)
        dismiss()
    }
}

// WaterEntry moved to DataModels.swift

// MARK: - Diary Components

// MARK: - MacroProgressView moved to separate file
// struct MacroProgressView: View {
//     let name: String
//     let current: Double
//     let goal: Double
//     let unit: String
//     let color: Color
//     
//     private var progress: Double {
//         min(1.0, current / goal)
//     }
//     
//     private var remaining: Double {
//         max(0, goal - current)
//     }
//     
//     var body: some View {
//         VStack(spacing: 4) {
//             HStack {
//                 Text(name)
//                     .font(.system(size: 14, weight: .medium, design: .rounded))
//                     .foregroundColor(.primary)
//                 
//                 Spacer()
//                 
//                 HStack(spacing: 2) {
//                     Text("\(Int(current.rounded()))")
//                         .font(.system(size: 14, weight: .bold, design: .rounded))
//                         .foregroundColor(color)
//                     
//                     Text("/ \(Int(goal))\(unit)")
//                         .font(.system(size: 12, weight: .medium, design: .rounded))
//                         .foregroundColor(.secondary)
//                 }
//             }
//             
//             GeometryReader { geometry in
//                 ZStack(alignment: .leading) {
//                     RoundedRectangle(cornerRadius: 4)
//                         .fill(Color(.systemGray6))
//                         .frame(height: 6)
//                     
//                     RoundedRectangle(cornerRadius: 4)
//                         .fill(
//                             LinearGradient(
//                                 gradient: Gradient(colors: [color.opacity(0.8), color]),
//                                 startPoint: .leading,
//                                 endPoint: .trailing
//                             )
//                         )
//                         .frame(
//                             width: geometry.size.width * progress,
//                             height: 6
//                         )
//                         .animation(.easeInOut(duration: 0.8), value: current)
//                 }
//             }
//             .frame(height: 6)
//             
//             if remaining > 0 {
//                 HStack {
//                     Spacer()
//                     Text("\(Int(remaining.rounded()))\(unit) remaining")
//                         .font(.system(size: 10, weight: .medium, design: .rounded))
//                         .foregroundColor(.secondary)
//                 }
//             }
//         }
//     }
// }
// 
// MARK: - Premium Macro Progress View
//
// End of MacroProgressView - see extracted file for implementation

struct DiaryMacroItem: View {
    let name: String
    let value: Int
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)\(unit)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            Text(name)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MicronutrientFrequencyView: View {
    let breakfast: [DiaryFoodItem]
    let lunch: [DiaryFoodItem]
    let dinner: [DiaryFoodItem]
    let snacks: [DiaryFoodItem]
    
    private var allFoods: [DiaryFoodItem] {
        breakfast + lunch + dinner + snacks
    }
    
    private var micronutrientAnalysis: [MicronutrientStatus] {
        analyzeMicronutrientFrequency()
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(micronutrientAnalysis.prefix(4), id: \.name) { nutrient in
                MicronutrientIndicator(nutrient: nutrient)
            }
        }
    }
    
    private func analyzeMicronutrientFrequency() -> [MicronutrientStatus] {
        let nutrientFoodSources: [String: [String]] = [
            "Vitamin C": ["orange", "lemon", "lime", "strawberry", "strawberries", "kiwi", "bell pepper", "broccoli", "tomato", "potato"],
            "Vitamin D": ["salmon", "tuna", "mackerel", "sardines", "egg", "fortified milk", "fortified cereal"],
            "Iron": ["spinach", "beef", "chicken", "turkey", "lentils", "beans", "quinoa", "tofu"],
            "Calcium": ["milk", "cheese", "yogurt", "yoghurt", "broccoli", "kale", "sardines", "almonds"],
            "Vitamin B12": ["meat", "fish", "dairy", "eggs", "nutritional yeast", "fortified"],
            "Folate": ["leafy greens", "spinach", "asparagus", "avocado", "beans", "lentils", "fortified"],
            "Omega-3": ["salmon", "sardines", "mackerel", "walnuts", "flax", "chia", "hemp"]
        ]
        
        var results: [MicronutrientStatus] = []
        
        for (nutrient, sources) in nutrientFoodSources {
            let hasSource = allFoods.contains { food in
                sources.contains { source in
                    food.name.lowercased().contains(source.lowercased())
                }
            }
            
            let status: NutrientStatus = hasSource ? .good : .needsAttention
            results.append(MicronutrientStatus(name: nutrient, status: status))
        }
        
        // Sort by status (needs attention first)
        return results.sorted { 
            if $0.status == .needsAttention && $1.status == .good { return true }
            if $0.status == .good && $1.status == .needsAttention { return false }
            return $0.name < $1.name
        }
    }
}

struct MicronutrientStatus {
    let name: String
    let status: NutrientStatus
}

enum NutrientStatus {
    case good
    case needsAttention
    
    var color: Color {
        switch self {
        case .good: return .green
        case .needsAttention: return .orange
        }
    }
    
    var symbol: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .needsAttention: return "exclamationmark.triangle.fill"
        }
    }
}

struct MicronutrientIndicator: View {
    let nutrient: MicronutrientStatus
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: nutrient.status.symbol)
                .font(.system(size: 12))
                .foregroundColor(nutrient.status.color)
            
            Text(nutrient.name.replacingOccurrences(of: "Vitamin ", with: "Vit "))
                .font(.system(size: 8))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CompactHydrationRing: View {
    let currentDate: Date
    @State private var waterCount: Int = 0
    @State private var waterGoal: Int = 8
    
    private var fillPercentage: Double {
        min(Double(waterCount) / Double(waterGoal), 1.0)
    }
    
    var body: some View {
        Button(action: addWater) {
            VStack(spacing: 4) {
                // Beautiful glass shape
                ZStack(alignment: .bottom) {
                    // Glass outline
                    GlassShape()
                        .stroke(Color(.systemGray4), lineWidth: 2)
                        .frame(width: 32, height: 50)
                    
                    // Water fill with animation
                    GlassShape()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.cyan.opacity(0.8), location: 0),
                                    .init(color: Color.blue.opacity(0.6), location: 1)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 32, height: 50)
                        .clipShape(
                            Rectangle()
                                .offset(y: 50 * (1 - fillPercentage))
                        )
                        .animation(.easeInOut(duration: 0.8), value: fillPercentage)
                    
                    // Glass highlight effect
                    GlassShape()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear,
                                    Color.white.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 32, height: 50)
                }
                
                // Count display
                Text("\(waterCount)/\(waterGoal)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadHydrationData()
        }
        .onChange(of: currentDate) { _ in
            loadHydrationData()
        }
    }
    
    private func addWater() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            waterCount += 1
        }
        saveHydrationData()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func loadHydrationData() {
        let dateKey = formatDateKey(currentDate)
        let saved = UserDefaults.standard.dictionary(forKey: "hydrationData") as? [String: Int] ?? [:]
        waterCount = saved[dateKey] ?? 0
        waterGoal = UserDefaults.standard.integer(forKey: "dailyWaterGoal") == 0 ? 8 : UserDefaults.standard.integer(forKey: "dailyWaterGoal")
    }
    
    private func saveHydrationData() {
        let dateKey = formatDateKey(currentDate)
        var hydrationData = UserDefaults.standard.dictionary(forKey: "hydrationData") as? [String: Int] ?? [:]
        hydrationData[dateKey] = waterCount
        UserDefaults.standard.set(hydrationData, forKey: "hydrationData")
    }
    
    private func formatDateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Glass Shape for Hydration
struct GlassShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Glass shape - slightly tapered drinking glass
        let topWidth = width * 0.9
        let bottomWidth = width * 0.7
        let topOffset = (width - topWidth) / 2
        let bottomOffset = (width - bottomWidth) / 2
        
        // Start from top left
        path.move(to: CGPoint(x: topOffset, y: 0))
        
        // Top edge
        path.addLine(to: CGPoint(x: width - topOffset, y: 0))
        
        // Right side (tapered)
        path.addLine(to: CGPoint(x: width - bottomOffset, y: height * 0.9))
        
        // Bottom right curve
        path.addQuadCurve(
            to: CGPoint(x: bottomOffset, y: height * 0.9),
            control: CGPoint(x: width / 2, y: height)
        )
        
        // Left side (tapered)
        path.addLine(to: CGPoint(x: topOffset, y: 0))
        
        return path
    }
}

// MARK: - DiaryMealCard moved to separate file

// MARK: - Data Models moved to DataModels.swift
// DiaryFoodItem, WorkoutSessionSummary, ExerciseSummary now in DataModels.swift

// ExerciseSet already defined in DataModels.swift - removed duplicate

// MARK: - Rest Timer
// RestTimer duplicate removed - using the one at line 67

// MARK: - Workout Template
// WorkoutTemplate duplicate removed - already defined in DataModels.swift

// WorkoutStatus enum moved to DataModels.swift

// MARK: - Diary Data Manager moved to DataModels.swift

// MARK: - CompactMacroItem moved to separate file
// struct CompactMacroItem: View {
//     let value: Double
//     let label: String
//     let color: Color
//     
//     var body: some View {
//         VStack(spacing: 2) {
//             Text("\(Int(value))g")
//                 .font(.system(size: 12, weight: .semibold))
//                 .foregroundColor(.primary)
//             
//             Text(label)
//                 .font(.system(size: 10, weight: .medium))
//                 .foregroundColor(color)
//                 .padding(.horizontal, 4)
//                 .padding(.vertical, 1)
//                 .background(
//                     Capsule()
//                         .fill(color.opacity(0.15))
//                 )
//         }
//     }
// }
// End of CompactMacroItem - see extracted file for implementation

// MARK: - DiaryFoodRow moved to separate file

// MARK: - MacroLabel moved to separate file
// struct MacroLabel: View {
//     let value: Double
//     let label: String
//     let color: Color
//     
//     var body: some View {
//         VStack(spacing: 1) {
//             Text(String(format: "%.0f", value))
//                 .font(.system(size: 11, weight: .medium))
//                 .foregroundColor(color)
//             Text(label)
//                 .font(.system(size: 9, weight: .medium))
//                 .foregroundColor(color.opacity(0.7))
//         }
//         .frame(minWidth: 20)
//     }
// }
//
// End of MacroLabel - see extracted file for implementation

struct MacroSummaryLabel: View {
    let value: Double
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text(String(format: "%.0f", value))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(color.opacity(0.8))
        }
    }
}

struct CompactMacroLabel: View {
    let value: Double
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
            Text(String(format: "%.0f", value))
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
        }
        .frame(width: 32, height: 32)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.12))
        )
    }
}

struct ModernMacroItem: View {
    let value: Double
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
            Text(String(format: "%.0f", value))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
        }
        .frame(minWidth: 35)
    }
}

// MARK: - NutritionScoreView moved to separate file
// struct NutritionScoreView: View {
//     let food: DiaryFoodItem
//     @State private var showingScoreDetails = false
//     
//     private var nutritionScore: NutritionProcessingScore {
//         ProcessingScorer.shared.calculateProcessingScore(for: food.name)
//     }
//     
//     var body: some View {
//         Button(action: {
//             showingScoreDetails = true
//         }) {
//             VStack(spacing: 2) {
//                 Text(nutritionScore.grade.rawValue)
//                     .font(.system(size: 14, weight: .bold))
//                     .foregroundColor(.white)
//                     .frame(width: 24, height: 24)
//                     .background(nutritionScore.color)
//                     .clipShape(RoundedRectangle(cornerRadius: 6))
//                 
//                 Text("Grade")
//                     .font(.system(size: 8, weight: .medium))
//                     .foregroundColor(.secondary)
//             }
//         }
//         .buttonStyle(PlainButtonStyle())
//         .sheet(isPresented: $showingScoreDetails) {
//             NutritionScoreDetailView(food: food, score: nutritionScore)
//         }
//     }
// }
//
// End of NutritionScoreView - see extracted file for implementation

// MARK: - ModernNutritionScore moved to separate file
// struct ModernNutritionScore: View {
//     let food: DiaryFoodItem
//     @State private var showingScoreDetails = false
//     
//     private var nutritionScore: NutritionProcessingScore {
//         ProcessingScorer.shared.calculateProcessingScore(for: food.name)
//     }
//     
//     var body: some View {
//         Button(action: {
//             showingScoreDetails = true
//         }) {
//             HStack(spacing: 8) {
                // Grade circle
//                 Text(nutritionScore.grade.rawValue)
//                     .font(.system(size: 14, weight: .bold))
//                     .foregroundColor(.white)
//                     .frame(width: 24, height: 24)
//                     .background(nutritionScore.color)
//                     .clipShape(Circle())
//                 
                // Processing score label
//                 Text("Processing Score")
//                     .font(.system(size: 11, weight: .medium))
//                     .foregroundColor(.secondary)
//                     .multilineTextAlignment(.leading)
//                 
//                 Spacer(minLength: 0)
//             }
//             .padding(.horizontal, 14)
//             .padding(.vertical, 8)
//             .background(
//                 RoundedRectangle(cornerRadius: 10)
//                     .fill(Color(.systemBackground))
//             )
//         }
//         .buttonStyle(PlainButtonStyle())
//         .sheet(isPresented: $showingScoreDetails) {
//             NutritionScoreDetailView(food: food, score: nutritionScore)
//         }
//     }
// }
//
// End of ModernNutritionScore - see extracted file for implementation

// MARK: - NutritionScoreDetailView moved to separate file
// struct NutritionScoreDetailView: View {
//     let food: DiaryFoodItem
//     let score: NutritionProcessingScore
//     @Environment(\.dismiss) private var dismiss
//     
//     var body: some View {
//         NavigationView {
//             ScrollView {
//                 VStack(alignment: .leading, spacing: 20) {
                    // Header with score
//                     VStack(spacing: 12) {
//                         Text(food.name)
//                             .font(.system(size: 24, weight: .bold))
//                             .multilineTextAlignment(.center)
//                         
//                         HStack(spacing: 16) {
                            // Grade circle
//                             Text(score.grade.rawValue)
//                                 .font(.system(size: 32, weight: .bold))
//                                 .foregroundColor(.white)
//                                 .frame(width: 60, height: 60)
//                                 .background(score.color)
//                                 .clipShape(Circle())
//                             
//                             VStack(alignment: .leading, spacing: 4) {
//                                 Text("Processing Score")
//                                     .font(.system(size: 16, weight: .semibold))
//                                     .foregroundColor(.primary)
//                                 
//                                 Text("\(score.score)/100")
//                                     .font(.system(size: 20, weight: .bold))
//                                     .foregroundColor(score.color)
//                                 
//                                 Text(score.processingLevel.rawValue)
//                                     .font(.system(size: 14))
//                                     .foregroundColor(.secondary)
//                             }
//                         }
//                     }
//                     .padding()
//                     .background(Color(.systemGray6))
//                     .cornerRadius(16)
//                     
                    // Explanation
//                     VStack(alignment: .leading, spacing: 8) {
//                         Text("Explanation")
//                             .font(.system(size: 18, weight: .semibold))
//                             .foregroundColor(.primary)
//                         
//                         Text(score.explanation)
//                             .font(.system(size: 15))
//                             .foregroundColor(.secondary)
//                             .lineSpacing(2)
//                     }
//                     .padding()
//                     .background(Color(.systemBackground))
//                     .cornerRadius(12)
//                     
                    // Scoring factors
//                     VStack(alignment: .leading, spacing: 12) {
//                         Text("Scoring Factors")
//                             .font(.system(size: 18, weight: .semibold))
//                             .foregroundColor(.primary)
//                         
//                         ForEach(score.factors, id: \.self) { factor in
//                             HStack {
//                                 Image(systemName: factor.contains("✅") ? "checkmark.circle.fill" : 
//                                                  factor.contains("⚠️") ? "exclamationmark.triangle.fill" : "info.circle")
//                                     .foregroundColor(factor.contains("✅") ? .green : 
//                                                    factor.contains("⚠️") ? .orange : .blue)
//                                     .frame(width: 16)
//                                 
//                                 Text(factor.replacingOccurrences(of: "✅ ", with: "")
//                                           .replacingOccurrences(of: "⚠️ ", with: ""))
//                                     .font(.system(size: 14))
//                                     .foregroundColor(.primary)
//                                 
//                                 Spacer()
//                             }
//                             .padding(.vertical, 4)
//                         }
//                     }
//                     .padding()
//                     .background(Color(.systemBackground))
//                     .cornerRadius(12)
//                     
                    // About the scoring system
//                     VStack(alignment: .leading, spacing: 8) {
//                         Text("About This Score")
//                             .font(.system(size: 18, weight: .semibold))
//                             .foregroundColor(.primary)
//                         
//                         VStack(alignment: .leading, spacing: 8) {
//                             Text("This processing score evaluates how much a food has been altered from its natural state:")
//                                 .font(.system(size: 14))
//                                 .foregroundColor(.secondary)
//                             
//                             VStack(alignment: .leading, spacing: 4) {
//                                 GradeExplanationRow(grade: "A+/A", color: .green, description: "Whole, unprocessed foods")
//                                 GradeExplanationRow(grade: "B", color: .orange, description: "Lightly processed for preservation")
//                                 GradeExplanationRow(grade: "C", color: .yellow, description: "Moderately processed with some additives")
//                                 GradeExplanationRow(grade: "D/F", color: .red, description: "Highly processed with many additives")
//                             }
//                             .padding(.top, 8)
//                         }
//                     }
//                     .padding()
//                     .background(Color(.systemBackground))
//                     .cornerRadius(12)
//                     
//                     Spacer()
//                 }
//                 .padding()
//             }
//             .navigationBarTitleDisplayMode(.inline)
//             .navigationBarItems(trailing: Button("Done") {
//                 dismiss()
//             })
//         }
//     }
// }
//
// End of NutritionScoreDetailView - see extracted file for implementation

// MARK: - GradeExplanationRow moved to separate file
// struct GradeExplanationRow: View {
//     let grade: String
//     let color: Color
//     let description: String
//     
//     var body: some View {
//         HStack(spacing: 12) {
//             Text(grade)
//                 .font(.system(size: 12, weight: .bold))
//                 .foregroundColor(.white)
//                 .frame(width: 32, height: 20)
//                 .background(color)
//                 .cornerRadius(4)
//             
//             Text(description)
//                 .font(.system(size: 14))
//                 .foregroundColor(.secondary)
//             
//             Spacer()
//         }
//     }
// }
//
// End of GradeExplanationRow - see extracted file for implementation

// MARK: - DiaryExerciseSummaryCard moved to separate file

// MARK: - DiaryExerciseStat moved to separate file

// MARK: - DiaryExerciseCard moved to separate file

// MARK: - DiaryExerciseRow moved to separate file

// MARK: - AddTabView moved to separate file
// struct AddTabView: View {
//     @Binding var selectedTab: TabItem
//     
//     var body: some View {
//         AddFoodMainView(selectedTab: $selectedTab)
//     }
// }
// 
// MARK: - Food Tab System moved to Views/Food/FoodTabViews.swift
// The following components were extracted as part of Phase 14 ContentView.swift modularization effort:
// - FoodTabView: Main food hub with sub-tab navigation
// - FoodSubTabSelector: Animated tab selector for food sections
// - FoodReactionsView: Food reaction tracking interface
// - RecipesView: Recipe collections and suggestions
// - FoodReactionSummaryCard: Reaction statistics dashboard
// - FoodReactionListCard: List of recent food reactions
// - FoodReactionRow: Individual reaction display row
// - FoodPatternAnalysisCard: Pattern analysis dashboard
// - PatternRow: Individual pattern trend row
// - RecipeCollectionsCard: Recipe collection grid
// - RecipeCollectionItem: Individual collection item
// - FavouriteRecipesCard: Favourite recipes list
// - SafeRecipeSuggestionsCard: Safe recipe recommendations
// - RecipeRow: Individual recipe display row
// - SpringyButtonStyle: Button animation style
// - sampleReactions: Sample data for food reactions
// Total extracted: 558 lines of comprehensive food tracking functionality
// 
// MARK: - FridgeTabView System moved to Views/Fridge/FridgeTabViews.swift
// The following components were extracted as part of Phase 15 ContentView.swift modularization effort:
// - FridgeTabView: Main fridge interface with sub-tab navigation
// - FridgeSubTabSelector: Sub-tab selector for fridge sections
// - FridgeExpiryView: Food expiry management dashboard
// - FridgeExpiryAlertsCard: Expiry alerts summary
// - FridgeCriticalExpiryCard: Critical expiring items
// - FridgeWeeklyExpiryCard: Weekly expiry schedule
// - FridgeExpiryItemRow: Individual expiry item display
// - FridgeExpiryDayRow: Daily expiry schedule row
// - FridgeQuickAddCard: Quick add item interface
// Total extracted: 385+ lines of comprehensive fridge management functionality
// 
// 
// MARK: - Add Food Main View
//
// End of AddTabView - see extracted file for implementation

struct AddFoodMainView: View {
    @Binding var selectedTab: TabItem
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAddOption: AddOption = .search
    
    enum AddOption: String, CaseIterable {
        case search = "Search"
        case manual = "Manual"
        case barcode = "Barcode"
        case ai = "AI Scanner"
        
        var icon: String {
            switch self {
            case .search: return "magnifyingglass"
            case .manual: return "square.and.pencil"
            case .barcode: return "barcode.viewfinder"
            case .ai: return "camera.viewfinder"
            }
        }
        
        var description: String {
            switch self {
            case .search: return "Search food database"
            case .manual: return "Enter manually"
            case .barcode: return "Scan product barcode"
            case .ai: return "AI-powered food recognition"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Text("Add Food")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // Option selector
                    AddOptionSelector(selectedOption: $selectedAddOption)
                        .padding(.horizontal, 16)
                }
                .background(Color(.systemBackground))
                
                // Content based on selected option
                Group {
                    switch selectedAddOption {
                    case .search:
                        AddFoodSearchView(selectedTab: $selectedTab)
                    case .manual:
                        AddFoodManualView()
                    case .barcode:
                        AddFoodBarcodeView(selectedTab: $selectedTab)
                    case .ai:
                        AddFoodAIView(selectedTab: $selectedTab)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AddOptionSelector: View {
    @Binding var selectedOption: AddFoodMainView.AddOption
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            ForEach(AddFoodMainView.AddOption.allCases, id: \.self) { option in
                Button(action: {
                    selectedOption = option
                }) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(selectedOption == option ? Color.blue : Color(.systemGray5))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: option.icon)
                                .font(.system(size: 24))
                                .foregroundColor(selectedOption == option ? .white : .primary)
                        }
                        
                        VStack(spacing: 4) {
                            Text(option.rawValue)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text(option.description)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedOption == option ? Color.blue : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedOption)
    }
}

// MARK: - Add Food Views

struct AddFoodManualView: View {
    @State private var foodName = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var servingSize = ""
    @State private var servingUnit = "g"
    
    let servingUnits = ["g", "ml", "cup", "tbsp", "tsp", "piece", "slice"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Food Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Food Name")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    TextField("Enter food name...", text: $foodName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Serving Size
                VStack(alignment: .leading, spacing: 8) {
                    Text("Serving Size")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack {
                        TextField("Amount", text: $servingSize)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        
                        Picker("Unit", selection: $servingUnit) {
                            ForEach(servingUnits, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 80)
                    }
                }
                
                // Nutrition Facts
                VStack(alignment: .leading, spacing: 16) {
                    Text("Nutrition Facts (per serving)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        NutritionInputRow(label: "Energy", value: $calories, unit: "kcal")
                        NutritionInputRow(label: "Protein", value: $protein, unit: "g")
                        NutritionInputRow(label: "Carbs", value: $carbs, unit: "g")
                        NutritionInputRow(label: "Fat", value: $fat, unit: "g")
                    }
                }
                
                // Add Button
                Button(action: {
                    addManualFood()
                }) {
                    Text("Add Food")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(foodName.isEmpty || calories.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(foodName.isEmpty || calories.isEmpty)
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }
    
    private func addManualFood() {
        print("Adding manual food: \(foodName)")
        // Implementation for adding manual food
    }
}

// MARK: - Barcode Scanning System has been extracted to Views/Food/BarcodeScanningViews.swift
// This comprehensive barcode scanning system was moved as part of Phase 14 ContentView.swift modularization effort.

// MARK: - AddFoodAIView has been extracted to Views/Food/AddFoodAIView.swift
// This comprehensive AI food scanning system was moved as part of Phase 13 ContentView.swift modularization effort.

// MARK: - NutritionInputRow has been extracted to Views/Food/AddFoodAIView.swift
// This nutrition input component was moved as part of Phase 13 ContentView.swift modularization effort.

// MARK: - FoodSearchResultRow has been extracted to Views/Food/FoodSearchViews.swift
// This component was moved as part of Phase 12A food search system extraction

// MARK: - FoodSearchResultRowEnhanced has been extracted to Views/Food/FoodSearchViews.swift
// This enhanced search result component was moved as part of Phase 12A food search system extraction

// MARK: - NutrientTag has been extracted to Views/Food/FoodSearchViews.swift
// This nutrient display component was moved as part of Phase 12A food search system extraction

// MARK: - FoodSourceType has been extracted to Views/Food/FoodSearchViews.swift
// This enumeration was moved as part of Phase 12A food search system extraction

// MARK: - FoodDetailViewFromSearch has been extracted to modular component
// This massive 2,305-line struct has been moved to Views/Food/FoodDetailViewFromSearch.swift
// as part of the Phase 10 ContentView.swift modularization effort.

// MARK: - Supporting components (VitaminMineralRow, ExpandableSection, VitaminRow, MacroRow, ScrollDismissModifier)
// These components have been extracted to Views/Food/FoodDetailViewFromSearch.swift

// MARK: - AddFoodSearchView has been extracted to Views/Food/FoodSearchViews.swift
// This comprehensive food search interface was moved as part of Phase 12A food search system extraction

// MARK: - Sample search results data has been extracted to Views/Food/FoodSearchViews.swift
// This sample data was moved as part of Phase 12A food search system extraction

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    
                    // Profile Section
                    SettingsSection(title: "Profile") {
                        SettingsRow(icon: "person.fill", title: "Personal Information", action: {})
                        SettingsRow(icon: "target", title: "Goals & Targets", action: {})
                        SettingsRow(icon: "heart.text.square", title: "Health Conditions", action: {})
                        SettingsRow(icon: "exclamationmark.triangle", title: "Allergies & Intolerances", action: {})
                    }
                    
                    // Data & Sync Section
                    SettingsSection(title: "Data & Sync") {
                        SettingsRow(icon: "heart.circle", title: "Apple Health", action: {})
                        SettingsRow(icon: "icloud", title: "Cloud Sync", action: {})
                        SettingsRow(icon: "arrow.up.doc", title: "Export Data", action: {})
                        SettingsRow(icon: "arrow.down.doc", title: "Import Data", action: {})
                    }
                    
                    // Notifications Section
                    SettingsSection(title: "Notifications") {
                        SettingsRow(icon: "bell", title: "Meal Reminders", action: {})
                        SettingsRow(icon: "clock", title: "Water Reminders", action: {})
                        SettingsRow(icon: "refrigerator", title: "Food Expiry Alerts", action: {})
                    }
                    
                    // App Settings Section
                    SettingsSection(title: "App Settings") {
                        SettingsRow(icon: "textformat", title: "Units & Measurements", action: {})
                        SettingsRow(icon: "moon", title: "Dark Mode", action: {})
                        SettingsRow(icon: "lock", title: "Privacy & Security", action: {})
                        SettingsRow(icon: "questionmark.circle", title: "Help & Support", action: {})
                    }
                    
                    // About Section
                    SettingsSection(title: "About") {
                        SettingsRow(icon: "info.circle", title: "Version 1.0.0 (Beta)", action: {})
                        SettingsRow(icon: "doc.text", title: "Terms & Conditions", action: {})
                        SettingsRow(icon: "hand.raised", title: "Privacy Policy", action: {})
                    }
                    
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Professional Summary Card extracted to Views/Diary/ProfessionalSummaryViews.swift
// This comprehensive professional nutrition visualization system was moved as part of Phase 13A extraction:
// - ProfessionalSummaryCard (129 lines) - Advanced nutrition overview with circular progress indicators
// - MacroPieChart (36 lines) - Individual macro pie chart components with animations

// MARK: - MacroPieChart extracted to Views/Diary/ProfessionalSummaryViews.swift
// This macro pie chart component was moved as part of Phase 13A professional summary system extraction

// MARK: - Professional Meal Card extracted to Views/Diary/ProfessionalSummaryViews.swift
// This professional meal display component was moved as part of Phase 13A extraction:
// - ProfessionalMealCard (57 lines) - Advanced meal type display with meal items and totals

// MARK: - Professional Food Item Card extracted to Views/Diary/ProfessionalSummaryViews.swift
// This detailed food item display component was moved as part of Phase 13A extraction:
// - ProfessionalFoodItemCard (55 lines) - Individual food item display with quality indicators and nutrition badges

// MARK: - Nutrition Badge Component extracted to Views/Diary/ProfessionalSummaryViews.swift
// This compact nutrition display component was moved as part of Phase 13A extraction

// MARK: - Professional Empty State extracted to Views/Diary/ProfessionalSummaryViews.swift
// This empty meal state component was moved as part of Phase 13A extraction:
// - ProfessionalEmptyMealState (27 lines) - Clean empty state with contextual add button

// MARK: - MealType Data Model extracted to Views/Diary/ProfessionalSummaryViews.swift
// This meal type enumeration was moved as part of Phase 13A extraction:
// - MealType (32 lines) - Complete meal type definitions with display properties

// MARK: - Color Extension for Hex Colors extracted to Views/Diary/ProfessionalSummaryViews.swift
// This hex color extension was moved as part of Phase 13A extraction:
// - Color+Hex (23 lines) - Hex color string initialization support

// SpringyButtonStyle moved to Views/Food/FoodTabViews.swift

// MARK: - ModernCardStyle extracted to Views/Diary/ProfessionalSummaryViews.swift
// This modern card styling modifier was moved as part of Phase 13A extraction:
// - ModernCardStyle (17 lines) - Professional card styling with material background and shadows

// MARK: - FoodDetailView has been extracted to Views/Food/FoodSearchViews.swift
// This comprehensive food detail view was moved as part of Phase 12A food search system extraction

// MARK: - MacroNutrientRow has been extracted to Views/Food/FoodSearchViews.swift
// This macro nutrient display component was moved as part of Phase 12A food search system extraction

// MARK: - Sample Data
private let sampleDailyNutrition = DailyNutrition(
    calories: NutrientTarget(current: 1450, target: 2000),
    protein: NutrientTarget(current: 95, target: 120),
    carbs: NutrientTarget(current: 180, target: 250),
    fat: NutrientTarget(current: 65, target: 78),
    fiber: NutrientTarget(current: 15, target: 25),
    sodium: NutrientTarget(current: 1200, target: 2300),
    sugar: NutrientTarget(current: 35, target: 50)
)

// MARK: - AI Food Scanning Components have been extracted to Views/Food/AddFoodAIView.swift
// The following components were moved as part of Phase 13 ContentView.swift modularization effort:
// - ImagePicker: UIViewControllerRepresentable for camera functionality
// - AIFoodSelectionView: UI for selecting detected foods from AI recognition
// - AIFoodSelectionRow: Individual food selection row with confidence indicators
// - CombinedMealView: Interface for managing multiple foods from AI scanning
// - CombinedMealFoodRow: Individual food row in combined meal view
// - NutrientSummary: Nutrient display component for meal summaries
// - NutrientPill: Compact nutrient display pills for food rows

struct IngredientCameraView: View {
    let foodName: String
    let onImageCaptured: (UIImage) -> Void
    let onDismiss: () -> Void
    let photoType: PhotoType
    
    enum PhotoType {
        case ingredients, nutrition, barcode
        
        var title: String {
            switch self {
            case .ingredients: return "Ingredient Photo Captured"
            case .nutrition: return "Nutrition Photo Captured" 
            case .barcode: return "Barcode Photo Captured"
            }
        }
        
        var buttonText: String {
            switch self {
            case .ingredients: return "Submit Ingredients"
            case .nutrition: return "Submit Nutrition"
            case .barcode: return "Submit Barcode"
            }
        }
        
        var description: String {
            switch self {
            case .ingredients: return "ingredients list"
            case .nutrition: return "nutrition facts label"
            case .barcode: return "barcode"
            }
        }
    }
    
    @State private var showingImagePicker = false
    @State private var capturedImage: UIImage?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let image = capturedImage {
                    // Show captured image
                    VStack(spacing: 16) {
                        Text(photoType.title)
                            .font(.title2.bold())
                        
                        Text("Please verify this is a clear photo of the \(photoType.description) for \"\(foodName)\"")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                        
                        VStack(spacing: 12) {
                            Button(photoType.buttonText) {
                                onImageCaptured(image)
                                onDismiss()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .font(.headline)
                            .cornerRadius(12)
                            
                            Button("Retake Photo") {
                                capturedImage = nil
                                showingImagePicker = true
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .font(.headline)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                } else {
                    // Initial state - show camera instructions
                    VStack(spacing: 20) {
                        VStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                            
                            Text("Photograph Ingredients")
                                .font(.title.bold())
                            
                            Text("Take a clear photo of the ingredients list for:")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("\"\(foodName)\"")
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("📸 Tips for best results:")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("• Ensure good lighting")
                                Text("• Keep text straight and readable")
                                Text("• Include the complete ingredients list")
                                Text("• Avoid shadows or reflections")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                        
                        Button("Take Photo") {
                            showingImagePicker = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .font(.headline)
                        .cornerRadius(12)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Ingredient Photo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    onDismiss()
                }
            )
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $capturedImage) { image in
                capturedImage = image
            }
        }
    }
}

// Database Building Photo Prompt View
// Pending Verifications View for user submissions
struct PendingVerificationsView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var pendingVerifications: [PendingFoodVerification] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading pending verifications...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if pendingVerifications.isEmpty {
                    VStack {
                        Image(systemName: "hourglass.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Pending Verifications")
                            .font(.title2)
                            .fontWeight(.medium)
                            .padding(.top)
                        Text("Your ingredient submissions will appear here as 'Pending Verification' until approved by our team.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(pendingVerifications) { verification in
                        PendingVerificationRow(verification: verification)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Pending Verifications")
            .task {
                await loadPendingVerifications()
            }
            .refreshable {
                await loadPendingVerifications()
            }
        }
    }
    
    private func loadPendingVerifications() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let verifications = try await firebaseManager.getPendingVerifications()
            await MainActor.run {
                self.pendingVerifications = verifications
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load verifications: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

struct PendingVerificationRow: View {
    let verification: PendingFoodVerification
    @State private var showingCompletionSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(verification.foodName)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                
                // Add completion button for pending verifications that need more photos
                if verification.status == .pending {
                    Button(action: {
                        showingCompletionSheet = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "camera.badge.plus")
                                .font(.caption)
                            Text("Complete")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .sheet(isPresented: $showingCompletionSheet) {
                        DatabasePhotoPromptView(
                            foodName: verification.foodName,
                            brandName: verification.brandName,
                            sourceType: .search,
                            onPhotosCompleted: { ingredients, nutrition, barcode in
                                // Submit additional photos to complete verification
                                Task {
                                    do {
                                        _ = try await IngredientSubmissionService.shared.submitIngredientSubmission(
                                            foodName: verification.foodName,
                                            brandName: verification.brandName,
                                            ingredientsImage: ingredients,
                                            nutritionImage: nutrition,
                                            barcodeImage: barcode
                                        )
                                    } catch {
                                        print("Error completing submission: \(error)")
                                    }
                                }
                            },
                            onSkip: {
                                showingCompletionSheet = false
                            }
                        )
                    }
                }
                
                StatusBadge(status: verification.status)
            }
            
            if let brand = verification.brandName, !brand.isEmpty {
                Text(brand)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let ingredients = verification.ingredients, !ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ingredients:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text(ingredients)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(nil) // Show all ingredients
                        .padding(.leading, 8)
                    
                    // Show immediate intolerance warnings
                    AllergenWarningView(ingredients: ingredients)
                }
            }
            
            Text("Submitted: \(verification.submittedAt, style: .date)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// Immediate Allergen Warning for Pending Ingredients
struct AllergenWarningView: View {
    let ingredients: String
    @State private var detectedAllergens: [Allergen] = []
    @State private var riskLevel: RiskLevel = .safe
    
    enum RiskLevel {
        case safe, caution, danger
        
        var color: Color {
            switch self {
            case .safe: return .green
            case .caution: return .orange
            case .danger: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .safe: return "checkmark.circle.fill"
            case .caution: return "exclamationmark.triangle.fill"
            case .danger: return "xmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        VStack {
            if !detectedAllergens.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: riskLevel.icon)
                            .font(.caption2)
                            .foregroundColor(riskLevel.color)
                        Text("⚠️ Allergen Alert")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(riskLevel.color)
                    }
                    
                    // TODO: Fix when Allergen model is available
                    // ForEach(detectedAllergens.sorted(by: { $0.displayName < $1.displayName }), id: \.rawValue) { allergen in
                    //     HStack(spacing: 4) {
                    //         Circle()
                    //             .fill(riskLevel.color)
                    //             .frame(width: 4, height: 4)
                    //         Text(allergen.displayName)
                    //             .font(.caption2)
                    //             .foregroundColor(.primary)
                    //     }
                    // }
                }
                .padding(8)
                .background(riskLevel.color.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .onAppear {
            analyzeIngredients()
        }
    }
    
    private func analyzeIngredients() {
        // let ingredientsList = ingredients.lowercased()
        // var foundAllergens: [Allergen] = []
        
        // TODO: Implement allergen analysis when Allergen model is available
        detectedAllergens = []
        riskLevel = .safe

        // // Check for common allergens in ingredients
        // for allergen in Allergen.allCases {
        //     for keyword in allergen.keywords {
        //         if ingredientsList.contains(keyword.lowercased()) {
        //             foundAllergens.append(allergen)
        //             break
        //         }
        //     }
        // }
        //
        // detectedAllergens = Array(Set(foundAllergens))
        //
        // // Determine risk level
        // if detectedAllergens.contains(where: { $0.severity == .high }) {
        //     riskLevel = .danger
        // } else if !detectedAllergens.isEmpty {
        //     riskLevel = .caution
        // } else {
        //     riskLevel = .safe
        // }
    }
}

struct StatusBadge: View {
    let status: PendingFoodVerification.VerificationStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.caption2)
            Text(statusText)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.2))
        .foregroundColor(statusColor)
        .cornerRadius(12)
    }
    
    private var statusIcon: String {
        switch status {
        case .pending:
            return "clock"
        case .approved:
            return "checkmark.circle"
        case .rejected:
            return "xmark.circle"
        }
    }
    
    private var statusText: String {
        switch status {
        case .pending:
            return "Pending"
        case .approved:
            return "Approved"
        case .rejected:
            return "Rejected"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .pending:
            return .orange
        case .approved:
            return .green
        case .rejected:
            return .red
        }
    }
}

// MARK: - DatabasePhotoPromptView extracted to Views/Food/FoodManagementViews.swift
// This component was moved as part of Phase 12B food management system extraction

// MARK: - PhotoCaptureSection & EnhancedPhotoCaptureSection extracted to Views/Food/FoodManagementViews.swift
// These components were moved as part of Phase 12B food management system extraction

// MARK: - MacroValue has been extracted to Views/Food/FoodSearchViews.swift
// This compact macro value display component was moved as part of Phase 12A food search system extraction

// MARK: - Additive Analysis System extracted to Views/Food/AdditiveAnalysisViews.swift
// Components moved as part of Phase 12C additive system extraction:
// - AdditiveWatchView (150 lines) - Complete additive detection and analysis interface
// - AdditiveCard (137 lines) - Individual additive display with expandable details  
// - AdditiveCardView (100+ lines) - Detailed additive information display
// - AdditiveDescriptionView (100+ lines) - User-friendly additive descriptions
// - AdditiveSection - Supporting data model
// Total: ~500+ lines extracted

struct FoodActionSheet: View {
    let food: DiaryFoodItem
    let isSelected: Bool
    let selectedCount: Int
    let onViewDetails: () -> Void
    let onEdit: () -> Void
    let onSelect: () -> Void
    let onCopy: () -> Void
    let onMove: () -> Void
    let onStar: () -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Minimal handle
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 3)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            // Clean, minimal actions - TODO: Fix when SlimActionButton is available
            HStack(spacing: 20) {
                Text("Action buttons placeholder")
                    .foregroundColor(.secondary)

                // if selectedCount <= 1 {
                //     SlimActionButton(icon: "info.circle", title: "Details", color: .blue) {
                //         dismiss()
                //         onViewDetails()
                //     }
                //
                //     SlimActionButton(icon: "pencil", title: "Edit", color: .green) {
                //         dismiss()
                //         onEdit()
                //     }
                // }
                //
                // SlimActionButton(icon: "arrow.up.arrow.down", title: "Move", color: .orange) {
                //     dismiss()
                //     onMove()
                // }
                //
                // SlimActionButton(icon: "star", title: "Star", color: .yellow) {
                //     dismiss()
                //     onStar()
                // }
                //
                // SlimActionButton(icon: "trash", title: "Delete", color: .red) {
                //     dismiss()
                //     onDelete()
                // }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
        .modifier(iOS16PresentationModifier())
    }
}

struct iOS16PresentationModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .presentationDetents([.height(120)]) // Much smaller and cleaner
                .presentationDragIndicator(.hidden)
        } else {
            content
        }
    }
}

// MARK: - PersistentBottomMenu moved to separate file
// struct PersistentBottomMenu: View {
//     let selectedCount: Int
//     let onEdit: () -> Void
//     let onMove: () -> Void
//     let onStar: () -> Void
//     let onDelete: () -> Void
//     let onCancel: () -> Void
//     
//     var body: some View {
//         VStack(spacing: 0) {
            // Clean, minimal actions that replace nav area
//             HStack(spacing: 20) {
                // X button to cancel selection
//                 SlimActionButton(icon: "xmark", title: "Cancel", color: .secondary, action: onCancel)
//                 
//                 if selectedCount == 1 {
//                     SlimActionButton(icon: "pencil", title: "Edit", color: .green, action: onEdit)
//                 }
//                 
//                 SlimActionButton(icon: "arrow.up.arrow.down", title: "Move", color: .orange, action: onMove)
//                 SlimActionButton(icon: "star", title: "Star", color: .yellow, action: onStar)
//                 SlimActionButton(icon: "trash", title: "Delete", color: .red, action: onDelete)
//             }
//             .padding(.horizontal, 20)
//             .padding(.top, 20)
//             .padding(.bottom, 34) // Account for tab bar and safe area
//         }
//         .background(Color(.systemBackground))
//         .overlay(
//             Rectangle()
//                 .fill(Color(.systemGray5))
//                 .frame(height: 1),
//             alignment: .top
//         )
//     }
// }
// End of PersistentBottomMenu - see extracted file for implementation


#Preview {
    ContentView()
}