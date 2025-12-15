import SwiftUI
import Foundation
import HealthKit
import Vision
import UserNotifications
import ActivityKit
import UIKit

// Import the extracted view components
// Note: These would typically be handled by proper module imports
// For now, ensure all View files are included in your Xcode target

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
                #if DEBUG
                print("✅ Saved exercise entry: \(exerciseSummary.name) - \(Int(estimatedCalories)) calories")
                #endif
            } catch {
                #if DEBUG
                print("❌ Error saving exercise entry for \(exerciseSummary.name): \(error)")
                #endif
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
            #if DEBUG
            print("Live Activities are not enabled")
            #endif
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
            #if DEBUG
            print("Started Live Activity for rest timer: \(activity.id)")
            #endif
        } catch {
            #if DEBUG
            print("Error starting Live Activity: \(error)")
            #endif
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
            #if DEBUG
            print("Ended Live Activity for rest timer")
            #endif
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
            id: UUID().uuidString,
            foodName: foodName,
            brandName: brandName,
            ingredients: extractedIngredients.isEmpty ? "Processing ingredient image..." : extractedIngredients,
            submittedAt: Date(),
            status: .pending,
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
            #if DEBUG
            print("No user ID available for submission")
            #endif
            return
        }

        let urlString = "\(functionsBaseURL)/submitFoodVerification"
        guard let url = URL(string: urlString) else {
            #if DEBUG
            print("❌ Invalid URL for food verification: \(urlString)")
            #endif
            throw NSError(domain: "ContentView", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid submission URL"])
        }
        
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
            #if DEBUG
            print("Backend processing failed, but local pending verification was saved")
            #endif
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
        #if DEBUG
        print("🔎 FatSecretService.searchFoods called with query: '\(query)'")
        #endif
        let results = try await performFatSecretSearch(query: query)
        #if DEBUG
        print("🔎 FatSecretService.searchFoods returning \(results.count) results")
        #endif
        return results
    }
    
    private func performFatSecretSearch(query: String) async throws -> [FoodSearchResult] {
        let urlString = "\(functionsBaseURL)/searchFoods"
        guard let url = URL(string: urlString) else {
            #if DEBUG
            print("❌ Invalid URL for food search: \(urlString)")
            #endif
            throw NSError(domain: "FatSecretService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid search URL"])
        }
        
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
                
                struct AdditiveSource: Codable {
                    let name: String
                    let url: String?
                }
            }
        }
        
        // Debug: Print raw JSON response (commented out for production)
        // if let jsonString = String(data: data, encoding: .utf8) {
        //     print("🔍 Raw API response: \(jsonString.prefix(500))")
        // }
        
        let searchResponse: FirebaseFoodSearchResponse
        do {
            searchResponse = try JSONDecoder().decode(FirebaseFoodSearchResponse.self, from: data)
            #if DEBUG
            print("✅ Successfully decoded \(searchResponse.foods.count) foods")
            #endif
        } catch {
            #if DEBUG
            print("❌ JSON decoding error: \(error)")
            #endif
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    #if DEBUG
                    print("Key not found: \(key), context: \(context)")
                    #endif
                case .typeMismatch(let type, let context):
                    #if DEBUG
                    print("Type mismatch: \(type), context: \(context)")
                    #endif
                case .valueNotFound(let type, let context):
                    #if DEBUG
                    print("Value not found: \(type), context: \(context)")
                    #endif
                case .dataCorrupted(let context):
                    #if DEBUG
                    print("Data corrupted: \(context)")
                    #endif
                @unknown default:
                    #if DEBUG
                    print("Unknown decoding error")
                    #endif
                }
            }
            throw error
        }
        
        return searchResponse.foods.map { food in
            // Debug logging for ingredients
            if let rawIngredients = food.ingredients {
                #if DEBUG
                print("🧪 Raw ingredients for \(food.name): '\(rawIngredients)'")
                #endif
                let splitIngredients = rawIngredients.components(separatedBy: ", ")
                #if DEBUG
                print("🧪 Split into \(splitIngredients.count) parts: \(splitIngredients)")
                #endif
            } else {
                #if DEBUG
                print("🧪 No ingredients for \(food.name)")
                #endif
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
        let urlString = "\(functionsBaseURL)/getFoodDetails"
        guard let url = URL(string: urlString) else {
            #if DEBUG
            print("❌ Invalid URL for food details: \(urlString)")
            #endif
            throw NSError(domain: "FatSecretService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid details URL"])
        }
        
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

struct DiaryExerciseItem: Identifiable, Codable, Equatable {
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

    // MARK: - Equatable conformance for SwiftUI's .onChange() modifier
    static func == (lhs: DiaryExerciseItem, rhs: DiaryExerciseItem) -> Bool {
        lhs.id == rhs.id
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
    
    @ViewBuilder
    private func navigationContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if #available(iOS 16.0, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
                .navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
    var body: some View {
        navigationContainer {
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
    @State private var copyTrigger = false
    @State private var deleteTrigger = false
    @StateObject private var workoutManager = WorkoutManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var showOnboarding = !OnboardingManager.shared.hasCompletedOnboarding
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var showingPaywall = false
    @State private var showingAddMenu = false
    @State private var showingDiaryAdd = false
    @State private var showingUseByAdd = false
    @State private var showingReactionLog = false
    @State private var showingWeightAdd = false
    @State private var useBySelectedFood: FoodSearchResult? = nil
    @State private var previousTabBeforeAdd: TabItem = .diary

    // Weight tracking state for AddWeightView
    @State private var currentWeight: Double = 0
    @State private var weightHistory: [WeightEntry] = []
    @State private var userHeight: Double = 0

    // Track notification-triggered navigation to bypass subscription gate
    @State private var isNavigatingFromNotification = false

    // MARK: - Persistent Tab Views (Performance Fix)
    // Keep tabs alive to preserve state and prevent redundant loading
    // Only the selected tab is visible, but all maintain their loaded data
    @State private var visitedTabs: Set<TabItem> = [.diary] // Diary pre-loaded

    // PERFORMANCE: Pre-render all tabs in background for instant switching
    private func preloadAllTabsInBackground() {
        // Wait 1.5 seconds after app launch to avoid impacting startup
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)

            await MainActor.run {
                let tabsToPreload = TabItem.allCases.filter { $0 != .add }
                // Pre-load all tabs except .add (modal)
                visitedTabs = Set(tabsToPreload)
            }
        }
    }

    private var persistentTabViews: some View {
        ZStack {
            ForEach(TabItem.allCases, id: \.self) { tab in
                if visitedTabs.contains(tab) {
                    // PERFORMANCE: Use .id() to stabilize view identity and prevent re-creation
                    // This ensures that once a tab is created, it stays alive and isn't recreated
                    // on every state change, reducing excessive re-rendering
                    tabContent(for: tab)
                        .id(tab) // Stable identity prevents view re-creation
                        .opacity(selectedTab == tab ? 1 : 0)
                        .allowsHitTesting(selectedTab == tab)
                        .accessibilityHidden(selectedTab != tab)
                }
            }
        }
    }

    // Keep each tab alive once visited so data/models are not re-created on every switch
    @ViewBuilder
    private func tabContent(for tab: TabItem) -> some View {
        switch tab {
        case .diary:
            DiaryTabView(
                selectedFoodItems: $selectedFoodItems,
                showingSettings: $showingSettings,
                selectedTab: $selectedTab,
                editTrigger: $editTrigger,
                moveTrigger: $moveTrigger,
                copyTrigger: $copyTrigger,
                deleteTrigger: $deleteTrigger,
                onEditFood: editSelectedFood,
                onDeleteFoods: deleteSelectedFoods,
                onBlockedNutrientsAttempt: { showingPaywall = true }
            )
            .environmentObject(diaryDataManager)
            .environmentObject(healthKitManager)

        case .weight:
            WeightTrackingView(showingSettings: $showingSettings)
                .environmentObject(healthKitManager)

        case .food:
            FoodTabView(showingSettings: $showingSettings, selectedTab: $selectedTab)

        case .useBy:
            UseByTabView(showingSettings: $showingSettings, selectedTab: $selectedTab)

        case .add:
            AddTabView(
                selectedTab: $selectedTab,
                isPresented: Binding(
                    get: { selectedTab == .add },
                    set: { if !$0 { selectedTab = previousTabBeforeAdd } }
                )
            )
            .environmentObject(diaryDataManager)
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private func navigationContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if #available(iOS 16.0, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
                .navigationViewStyle(StackNavigationViewStyle())
        }
    }

    var body: some View {
        navigationContainer {
            ZStack {
                // Midnight blue background for entire app
                Color.adaptiveBackground
                    .ignoresSafeArea()

                // Main Content with padding for tab bar and potential workout progress bar
                VStack {
                    persistentTabViews
                        .animation(nil, value: selectedTab)
                        .transaction { $0.disablesAnimations = true }
                        .onAppear {
                            visitedTabs.insert(selectedTab)
                            // PERFORMANCE: Pre-load all tabs in background for instant switching
                            preloadAllTabsInBackground()
                        }
                        .onChange(of: selectedTab) { oldTab, newTab in
                            visitedTabs.insert(newTab)
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar positioned at bottom - hidden when in workout view
            if !workoutManager.isInWorkoutView {
                VStack {
                    Spacer()
                    CustomTabBar(selectedTab: $selectedTab, workoutManager: workoutManager, onBlockedTabAttempt: { showingPaywall = true }, showingAddMenu: $showingAddMenu)
                        .offset(y: 34) // Lower the tab bar to bottom edge
                }
            }

            // Add Action Menu - always rendered but controls its own visibility
            AddActionMenu(
                isPresented: $showingAddMenu,
                onSelectDiary: {
                    previousTabBeforeAdd = selectedTab
                    showingDiaryAdd = true
                },
                onSelectUseBy: {
                    previousTabBeforeAdd = selectedTab
                    showingUseByAdd = true
                },
                onSelectReaction: {
                    previousTabBeforeAdd = selectedTab
                    showingReactionLog = true
                },
                onSelectWeighIn: {
                    previousTabBeforeAdd = selectedTab
                    showingWeightAdd = true
                }
            )
            .zIndex(1000)
            
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
                        onCopy: {
                            copyTrigger = true
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
        // REMOVED: .onTapGesture that was consuming ALL taps and blocking buttons
        // Keyboard dismissal now handled by:
        // - scrollDismissesKeyboard on ScrollViews
        // - Return key on TextFields
        // - Individual view dismiss actions
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView()
                .environmentObject(subscriptionManager)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(onComplete: { emailMarketingConsent in
                OnboardingManager.shared.completeOnboarding()

                // Save email consent to Firestore
                Task {
                    do {
                        try await firebaseManager.updateEmailMarketingConsent(hasConsented: emailMarketingConsent)
                        #if DEBUG
                        print("✅ Email marketing consent saved to Firestore: \(emailMarketingConsent)")
                        #endif
                    } catch {
                        #if DEBUG
                        print("❌ Failed to save email consent: \(error)")
                        #endif
                        // Save to UserDefaults as fallback
                        UserDefaults.standard.set(emailMarketingConsent, forKey: "emailMarketingConsent")
                        if emailMarketingConsent {
                            UserDefaults.standard.set(Date(), forKey: "emailMarketingConsentDate")
                        }
                    }
                }

                showOnboarding = false
                // Only show paywall if not already subscribed
                if !(subscriptionManager.isSubscribed || subscriptionManager.isInTrial || subscriptionManager.isPremiumOverride) {
                    showingPaywall = true
                }
            })
        }
        .fullScreenCover(isPresented: $showingDiaryAdd) {
            AddFoodMainView(
                selectedTab: $selectedTab,
                isPresented: $showingDiaryAdd,
                onDismiss: {
                    showingDiaryAdd = false
                },
                onComplete: { tab in
                    // Dismiss keyboard before closing fullscreen and switching tabs
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    showingDiaryAdd = false
                    selectedTab = tab
                }
            )
            .environmentObject(diaryDataManager)
        }
        .fullScreenCover(isPresented: $showingUseByAdd) {
            AddUseByItemSheet(onComplete: {
                showingUseByAdd = false
                selectedTab = .useBy
            })
            .onDisappear {
                showingUseByAdd = false
            }
        }
        .fullScreenCover(isPresented: $showingReactionLog) {
            NavigationView {
                LogReactionView(reactionManager: ReactionManager.shared, selectedTab: $selectedTab)
            }
            .onDisappear {
                // Clean up when sheet is dismissed
                showingReactionLog = false
            }
        }
        .sheet(isPresented: $showingWeightAdd) {
            AddWeightView(currentWeight: $currentWeight, weightHistory: $weightHistory, userHeight: $userHeight)
                .environmentObject(FirebaseManager.shared)
                .onDisappear {
                    showingWeightAdd = false
                    // Switch to weight tab after adding weight
                    selectedTab = .weight
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToUseBy)) { _ in
            #if DEBUG
            print("[Nav] Received navigateToUseBy")
            #endif
            isNavigatingFromNotification = true
            selectedTab = .useBy
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToFasting)) { _ in
            #if DEBUG
            print("[Nav] Received navigateToFasting -> switching to Food tab")
            #endif
            isNavigatingFromNotification = true
            selectedTab = .food
        }
        .onReceive(NotificationCenter.default.publisher(for: .restartOnboarding)) { _ in
            // First dismiss Settings if it's showing
            showingSettings = false
            // Wait for Settings dismiss animation to complete, then show onboarding
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showOnboarding = true
            }
        }
        
        .onChange(of: selectedTab) { newTab in
            // Track the last non-add tab for proper return behavior when dismissing
            if newTab != .add {
                previousTabBeforeAdd = newTab
            }

            // Enforce subscription gating for programmatic tab changes
            // BUT allow notification-triggered navigation to proceed
            if !(subscriptionManager.isSubscribed || subscriptionManager.isInTrial || subscriptionManager.isPremiumOverride) {
                if !(newTab == .diary || newTab == .add) && !isNavigatingFromNotification {
                    // Revert and show paywall
                    selectedTab = .diary
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.warning)
                    showingPaywall = true
                }
            }

            // Reset the notification flag after navigation is handled
            if isNavigatingFromNotification {
                isNavigatingFromNotification = false
                #if DEBUG
                print("[Nav] Reset notification flag after navigation")
                #endif
            }
        }
        .onAppear {
            // PERFORMANCE OPTIMIZATION: Parallel preloading for instant app responsiveness

            // PRIORITY 1: Load critical Diary tab data IMMEDIATELY (user-facing)
            Task(priority: .userInitiated) {
                let today = Date()
                _ = diaryDataManager.getFoodData(for: today)
                #if DEBUG
                print("✅ Diary data loaded - app responsive in <300ms")
                #endif
            }

            // PRIORITY 2: Background preload other tabs IN PARALLEL (non-blocking)
            Task(priority: .utility) {
                // Load user height for weight tracking
                do {
                    let settings = try await FirebaseManager.shared.getUserSettings()
                    if let height = settings.height {
                        await MainActor.run {
                            userHeight = height
                        }
                    }
                } catch {
                    #if DEBUG
                    print("⚠️ Error loading user height: \(error.localizedDescription)")
                    #endif
                }

                // All requests run in parallel using async let
                async let weightsTask = FirebaseManager.shared.getWeightHistory()
                async let useByTask: [UseByInventoryItem] = FirebaseManager.shared.getUseByItems()
                async let reactionsTask = FirebaseManager.shared.getReactions()
                async let settingsTask = FirebaseManager.shared.getUserSettings()
                async let nutrientsTask = MicronutrientTrackingManager.shared.getAllNutrientSummaries()

                // Wait for all to complete (runs in ~1.2s instead of 3.4s sequential)
                do {
                    let weights = try await weightsTask
                    let useByItems = try await useByTask
                    let reactions = try await reactionsTask
                    let settings = try await settingsTask
                    let _ = await nutrientsTask
                    await MainActor.run {
                        if let uid = FirebaseManager.shared.currentUser?.uid {
                            ReactionManager.shared.preload(reactions, for: uid)
                            // Start nutrient tracking with user-scoped caching
                            NutrientTrackingManager.shared.startTracking(for: uid)
                        }
                        FirebaseManager.shared.preloadWeightData(history: weights, height: settings.height, goalWeight: settings.goalWeight)
                    }
                    #if DEBUG
                    print("✅ Background preload complete - all tabs ready (weights: \(weights.count), useBy: \(useByItems.count), reactions: \(reactions.count))")
                    #endif
                } catch {
                    #if DEBUG
                    print("⚠️ Some preload tasks failed: \(error)")
                    #endif
                }
            }
        }

        }
    }
    
    private func editSelectedFood() {
        guard selectedTab == .diary && !selectedFoodItems.isEmpty else { return }
        editTrigger.toggle()
    }
    
    private func deleteSelectedFoods() {
        guard selectedTab == .diary && !selectedFoodItems.isEmpty else { return }
        deleteTrigger = true
    }
}

// MARK: - Tab Items
enum TabItem: String, CaseIterable {
    case diary = "diary"
    case weight = "progress"
    case add = "add"
    case food = "food"
    case useBy = "fridge"

    var title: String {
        switch self {
        case .diary: return "Diary"
        case .weight: return "Progress"
        case .add: return ""
        case .food: return "Health"
        case .useBy: return "Use By"
        }
    }

    var icon: String {
        switch self {
        case .diary: return "fork.knife.circle"
        case .weight: return "figure.run.treadmill.circle"
        case .add: return "plus"
        case .food: return "heart.circle"
        case .useBy: return "calendar.circle"
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


// MARK: - Weight Tracking View
struct WeightTrackingView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var showingSettings: Bool
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var firebaseManager: FirebaseManager
    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric

    @State private var currentWeight: Double = 0
    @State private var goalWeight: Double = 0
    @State private var userHeight: Double = 0 // 0 means not set
    @State private var showingAddWeight = false
    @State private var weightHistory: [WeightEntry] = []
    @State private var showingHeightSetup = false
    @State private var isLoadingData = false
    @State private var hasCheckedHeight = false
    @State private var hasLoadedOnce = false // PERFORMANCE: Guard flag to prevent redundant loads

    // Entry management
    @State private var editingEntry: WeightEntry?  // Changed from selectedEntry to editingEntry for clarity
    @State private var entryToDelete: WeightEntry?
    @State private var showingDeleteConfirmation = false
    @State private var showAllWeightEntries = false

    private var needsHeightSetup: Bool {
        userHeight == 0 && hasCheckedHeight // Only prompt if height is truly not set
    }

    private var currentBMI: Double {
        guard currentWeight > 0, userHeight > 0 else { return 0 }
        let heightInMeters = userHeight / 100
        return currentWeight / (heightInMeters * heightInMeters)
    }

    private var bmiCategory: (String, Color) {
        let bmi = currentBMI
        if bmi < 18.5 {
            return ("Underweight", .orange)
        } else if bmi < 25 {
            return ("Healthy", .green)
        } else if bmi < 30 {
            return ("Overweight", .orange)
        } else {
            return ("Obese", .red)
        }
    }

    private var totalProgress: Double {
        guard goalWeight > 0, let firstEntry = weightHistory.last else { return 0 }
        let startWeight = firstEntry.weight
        let totalToLose = startWeight - goalWeight
        let lostSoFar = startWeight - currentWeight
        return totalToLose != 0 ? (lostSoFar / totalToLose) * 100 : 0
    }

    // Helper methods for unit conversion
    private func formatWeight(_ kg: Double) -> String {
        switch unitSystem {
        case .metric:
            return String(format: "%.1f", kg)
        case .imperial:
            let lbs = kg * 2.20462
            return String(format: "%.1f", lbs)
        }
    }

    private var weightUnit: String {
        switch unitSystem {
        case .metric:
            return "kg"
        case .imperial:
            return "lbs"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
                // Fixed Header
                HStack(spacing: 16) {
                    Text("Progress")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .frame(height: 44, alignment: .center)
                        .foregroundColor(.primary)

                    Spacer()

                    Button(action: { showingSettings = true }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primary)
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(Color.adaptiveBackground)

                // Loading overlay
                if isLoadingData {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))

                        Text("Loading your progress...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {

                        // Stats Grid - NOW AT TOP
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Summary")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)

                        HStack(spacing: 12) {
                            // Current Weight
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(formatWeight(currentWeight))
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.3, green: 0.5, blue: 1.0),
                                                    Color(red: 0.5, green: 0.3, blue: 0.9)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    Text(weightUnit)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(colorScheme == .dark ? Color.midnightCard : Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
                            )

                            // Goal Weight
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Goal")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(goalWeight > 0 ? formatWeight(goalWeight) : "--")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.green)
                                    Text(weightUnit)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(colorScheme == .dark ? Color.midnightCard : Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
                            )
                        }
                        .padding(.horizontal, 16)

                        HStack(spacing: 12) {
                            // Progress
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Progress")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                                let startWeight = weightHistory.last?.weight ?? currentWeight
                                let lost = max(startWeight - currentWeight, 0)
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(formatWeight(lost))
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.green)
                                    Text(weightUnit)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(colorScheme == .dark ? Color.midnightCard : Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
                            )

                            // Remaining
                            VStack(alignment: .leading, spacing: 8) {
                                Text("To Go")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                                let remaining = goalWeight > 0 ? max(currentWeight - goalWeight, 0) : 0
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(formatWeight(remaining))
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.orange)
                                    Text(weightUnit)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(colorScheme == .dark ? Color.midnightCard : Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
                            )
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 12)

                    // Update Weight button - STAYS IN MIDDLE
                    Button(action: { showingAddWeight = true }) {
                        HStack {
                            Text("Update Weight")
                                .font(.system(size: 20, weight: .semibold))
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.7, blue: 0.5),
                                    Color(red: 1.0, green: 0.6, blue: 0.7),
                                    Color(red: 0.7, green: 0.6, blue: 1.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(30)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)

                    // Weight History or Empty State - NOW AT BOTTOM
                    if !weightHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("History")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.primary)

                                    Text("\(weightHistory.count) entries")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                // Mini trend indicator
                                if weightHistory.count > 1 {
                                    let latest = weightHistory.first?.weight ?? currentWeight
                                    let previous = weightHistory[safe: 1]?.weight ?? latest
                                    let change = latest - previous

                                    HStack(spacing: 4) {
                                        Image(systemName: change < 0 ? "arrow.down.right" : change > 0 ? "arrow.up.right" : "arrow.right")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text("\(formatWeight(abs(change))) \(weightUnit)")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(change < 0 ? .green : change > 0 ? .red : .secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill((change < 0 ? Color.green : change > 0 ? Color.red : Color.secondary).opacity(0.1))
                                    )
                                }
                            }
                            .padding(.horizontal, 20)

                            // Weight entries list
                            List {
                                ForEach(Array(weightHistory.prefix(showAllWeightEntries ? weightHistory.count : 5).enumerated()), id: \.element.id) { index, entry in
                                    WeightEntryRow(
                                        entry: entry,
                                        previousEntry: weightHistory[safe: index + 1],
                                        isLatest: index == 0
                                    )
                                    .onTapGesture {
                                        #if DEBUG
                                        print("📍 Tapped entry: \(entry.date)")
                                        #endif
                                        editingEntry = entry
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            entryToDelete = entry
                                            showingDeleteConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .contextMenu {
                                        Button {
                                            editingEntry = entry
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }

                                        Button(role: .destructive) {
                                            entryToDelete = entry
                                            showingDeleteConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .listRowInsets(EdgeInsets())
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                }

                                if weightHistory.count > 5 {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showAllWeightEntries.toggle()
                                        }
                                    }) {
                                        Text(showAllWeightEntries ? "Show less" : "View all \(weightHistory.count) entries")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.blue)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                    }
                                    .listRowInsets(EdgeInsets())
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                }
                            }
                            .listStyle(.plain)
                            .frame(height: CGFloat((showAllWeightEntries ? weightHistory.count : min(weightHistory.count, 5)) * 85 + (weightHistory.count > 5 ? 50 : 0)))
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 12)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(colorScheme == .dark ? Color.midnightCard : Color(.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        )
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
                            .padding(.horizontal, 0)
                    } else {
                        // Empty State
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.3, green: 0.5, blue: 1.0).opacity(0.1),
                                                Color(red: 0.5, green: 0.3, blue: 0.9).opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)

                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 48, weight: .light))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.3, green: 0.5, blue: 1.0),
                                                Color(red: 0.5, green: 0.3, blue: 0.9)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            .padding(.top, 20)

                            VStack(spacing: 8) {
                                Text("Track Your Weight Journey")
                                    .font(.system(size: 20, weight: .semibold))
                                    .multilineTextAlignment(.center)

                                Text("Tap 'Update Weight' above to log your first entry and see your progress over time")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 40)
                        }
                        .frame(height: 280)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.35), Color.white.opacity(0.15)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    }

                    }
                    .padding(.bottom, 100)
                }
                } // End of loading else block
            }
            .background(Color.adaptiveBackground)
        .sheet(isPresented: $showingAddWeight) {
            AddWeightView(currentWeight: $currentWeight, weightHistory: $weightHistory, userHeight: $userHeight)
                .environmentObject(firebaseManager)
        }
        .sheet(isPresented: $showingHeightSetup) {
            HeightSetupView(userHeight: $userHeight)
                .environmentObject(firebaseManager)
        }
        .sheet(item: $editingEntry) { entry in
            EditWeightView(
                entry: entry,
                currentWeight: $currentWeight,
                weightHistory: $weightHistory,
                userHeight: $userHeight,
                onSave: { loadWeightHistory() }
            )
            .environmentObject(firebaseManager)
        }
        .alert("Delete Weight Entry?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                entryToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let entry = entryToDelete {
                    deleteWeightEntry(entry)
                }
            }
        } message: {
            if let entry = entryToDelete {
                Text("Are you sure you want to delete the weight entry from \(entry.date, style: .date)?")
            }
        }
        .onAppear {
            guard !hasLoadedOnce else { return }
            if !(firebaseManager.cachedWeightHistory.isEmpty && firebaseManager.cachedUserHeight == nil && firebaseManager.cachedGoalWeight == nil) {
                currentWeight = firebaseManager.cachedWeightHistory.first?.weight ?? currentWeight
                weightHistory = firebaseManager.cachedWeightHistory
                if let h = firebaseManager.cachedUserHeight { userHeight = h }
                if let g = firebaseManager.cachedGoalWeight { goalWeight = g }
                hasCheckedHeight = true
                hasLoadedOnce = true
                loadWeightHistory(silent: true)
            } else {
                hasLoadedOnce = true
                loadWeightHistory()
            }
            if needsHeightSetup {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingHeightSetup = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .goalWeightUpdated)) { notification in
            if let gw = notification.userInfo?["goalWeight"] as? Double {
                goalWeight = gw
            } else {
                Task {
                    do {
                        let settings = try await firebaseManager.getUserSettings()
                        await MainActor.run { goalWeight = settings.goalWeight ?? 0 }
                    } catch {
                        // Ignore errors; UI will refresh on next load
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .weightHistoryUpdated)) { notification in
            // Optimistically reflect the saved entry if provided; otherwise reload
            if let entry = notification.userInfo?["entry"] as? WeightEntry {
                // Check if entry already exists (editing existing entry)
                if let existingIndex = weightHistory.firstIndex(where: { $0.id == entry.id }) {
                    // Update existing entry
                    weightHistory[existingIndex] = entry
                } else {
                    // Insert new entry at beginning
                    weightHistory.insert(entry, at: 0)
                }
                // Update current weight and re-sort by date
                weightHistory.sort { $0.date > $1.date }
                currentWeight = entry.weight
            } else {
                loadWeightHistory()
            }
        }
    }

    // MARK: - Peach Background Gradient
    private var progressGlassBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.92, green: 0.96, blue: 1.0),
                    Color(red: 0.93, green: 0.88, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [Color.blue.opacity(0.10), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 300
            )
            RadialGradient(
                colors: [Color.purple.opacity(0.08), Color.clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 280
            )
        }
        .ignoresSafeArea()
    }

    private func loadWeightHistory(silent: Bool = false) {
        if !silent { isLoadingData = true }
        Task {
            do {
                // OPTIMIZATION: Load weight history and settings in parallel
                async let historyTask = firebaseManager.getWeightHistory()
                async let settingsTask = firebaseManager.getUserSettings()

                let (history, settings) = try await (historyTask, settingsTask)

                await MainActor.run {
                    weightHistory = history

                    // Set current weight from most recent entry
                    if let latest = history.first {
                        currentWeight = latest.weight
                    }

                    // Load height and goal weight from settings
                    if let height = settings.height {
                        userHeight = height
                    }
                    if let goal = settings.goalWeight {
                        goalWeight = goal
                    }

                    hasCheckedHeight = true
                    if !silent { isLoadingData = false }
                }
            } catch {
                #if DEBUG
                print("Error loading weight data from Firebase: \(error)")
                #endif
                await MainActor.run {
                    hasCheckedHeight = true
                    if !silent { isLoadingData = false }
                }
            }
        }
    }

    private func deleteWeightEntry(_ entry: WeightEntry) {
        Task {
            do {
                try await firebaseManager.deleteWeightEntry(id: entry.id)
                await MainActor.run {
                    weightHistory.removeAll { $0.id == entry.id }
                    // Update current weight if we deleted the most recent entry
                    if let latest = weightHistory.first {
                        currentWeight = latest.weight
                    } else {
                        currentWeight = 0
                    }
                    entryToDelete = nil
                }
                #if DEBUG
                print("✅ Weight entry deleted successfully")
                #endif
            } catch {
                #if DEBUG
                print("❌ Error deleting weight entry: \(error)")
                #endif
                await MainActor.run {
                    entryToDelete = nil
                }
            }
        }
    }
}

// MARK: - Array Extension for Safe Access
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Weight Entry Row
struct WeightEntryRow: View {
    let entry: WeightEntry
    let previousEntry: WeightEntry?
    let isLatest: Bool
    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric

    private var weightChange: Double? {
        guard let previous = previousEntry else { return nil }
        return entry.weight - previous.weight
    }

    private func formatWeight(_ kg: Double) -> String {
        switch unitSystem {
        case .metric:
            return String(format: "%.1f", kg)
        case .imperial:
            let lbs = kg * 2.20462
            return String(format: "%.1f", lbs)
        }
    }

    private var weightUnit: String {
        switch unitSystem {
        case .metric:
            return "kg"
        case .imperial:
            return "lbs"
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter.string(from: entry.date)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Date
            VStack(alignment: .leading, spacing: 2) {
                Text(formattedDate)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                Text(entry.date, style: .time)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .frame(width: 90, alignment: .leading)

            // Weight
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formatWeight(entry.weight))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    Text(weightUnit)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }

                if let bmi = entry.bmi {
                    Text("BMI: \(String(format: "%.1f", bmi))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Change indicator
            if let change = weightChange {
                HStack(spacing: 4) {
                    Image(systemName: change < 0 ? "arrow.down" : "arrow.up")
                        .font(.system(size: 12, weight: .bold))
                    Text("\(formatWeight(abs(change))) \(weightUnit)")
                        .font(.system(size: 14, weight: .bold))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .foregroundColor(change < 0 ? .green : .red)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill((change < 0 ? Color.green : Color.red).opacity(0.15))
                )
            } else if isLatest {
                Text("Latest")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.15))
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .padding(.bottom, 8)
    }
}

// MARK: - Progress Tab Weight Entry Detail View
struct ProgressWeightEntryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseManager: FirebaseManager
    let entry: WeightEntry
    @State private var photoImage: UIImage?
    @State private var isLoadingPhoto = false
    let onEdit: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Photo section
                    if entry.photoURL != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Progress Photo")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)

                            if let image = photoImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            } else if isLoadingPhoto {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Weight & BMI section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Measurements")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)

                        HStack(spacing: 32) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Weight")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f kg", entry.weight))
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.blue)
                            }

                            if let bmi = entry.bmi {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("BMI")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.1f", bmi))
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // Additional measurements
                    if entry.waistSize != nil || entry.dressSize != nil {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Additional Measurements")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)

                            if let waist = entry.waistSize {
                                HStack {
                                    Text("Waist Size")
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(String(format: "%.1f cm", waist))
                                        .font(.system(size: 15, weight: .semibold))
                                }
                            }

                            if let dress = entry.dressSize {
                                HStack {
                                    Text("Dress Size")
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(dress)
                                        .font(.system(size: 15, weight: .semibold))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Date section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Date")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)

                        Text(entry.date, style: .date)
                            .font(.system(size: 15))
                        Text(entry.date, style: .time)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)

                    // Note section
                    if let note = entry.note, !note.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Note")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)

                            Text(note)
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 16)
                    }

                    // Edit button
                    Button(action: {
                        // First dismiss this sheet
                        dismiss()
                        // Then trigger the edit action after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onEdit()
                        }
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit Entry")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("Weight Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Load photo if available
                if let photoURL = entry.photoURL {
                    isLoadingPhoto = true
                    Task {
                        do {
                            let image = try await firebaseManager.downloadWeightPhoto(from: photoURL)
                            await MainActor.run {
                                photoImage = image
                                isLoadingPhoto = false
                            }
                        } catch {
                            #if DEBUG
                            print("❌ Error loading photo: \(error.localizedDescription)")
                            #endif
                            await MainActor.run {
                                isLoadingPhoto = false
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Weight Unit System
enum WeightUnit: String, CaseIterable, Codable {
    case kg = "Kilograms (kg)"
    case lbs = "Pounds (lbs)"
    case stones = "Stones & lbs"

    var shortName: String {
        switch self {
        case .kg: return "kg"
        case .lbs: return "lbs"
        case .stones: return "st"
        }
    }

    // Convert from kg (storage format) to display format
    func fromKg(_ kg: Double) -> (primary: Double, secondary: Double?) {
        switch self {
        case .kg:
            return (kg, nil)
        case .lbs:
            return (kg * 2.20462, nil)
        case .stones:
            let totalPounds = kg * 2.20462
            let stones = floor(totalPounds / 14)
            let pounds = totalPounds.truncatingRemainder(dividingBy: 14)
            return (stones, pounds)
        }
    }

    // Convert from display format to kg (storage format)
    func toKg(primary: Double, secondary: Double? = nil) -> Double {
        switch self {
        case .kg:
            return primary
        case .lbs:
            return primary / 2.20462
        case .stones:
            let totalPounds = (primary * 14) + (secondary ?? 0)
            return totalPounds / 2.20462
        }
    }
}

// MARK: - Height Unit System
enum HeightUnit: String, CaseIterable, Codable {
    case cm = "Centimeters (cm)"
    case ftIn = "Feet & Inches (ft/in)"

    var shortName: String {
        switch self {
        case .cm: return "cm"
        case .ftIn: return "ft"
        }
    }

    // Convert from cm (storage format) to display format
    func fromCm(_ cm: Double) -> (primary: Double, secondary: Double?) {
        switch self {
        case .cm:
            return (cm, nil)
        case .ftIn:
            let totalInches = cm / 2.54
            let feet = floor(totalInches / 12)
            let inches = totalInches.truncatingRemainder(dividingBy: 12)
            return (feet, inches)
        }
    }

    // Convert from display format to cm (storage format)
    func toCm(primary: Double, secondary: Double? = nil) -> Double {
        switch self {
        case .cm:
            return primary
        case .ftIn:
            let totalInches = (primary * 12) + (secondary ?? 0)
            return totalInches * 2.54
        }
    }
}

// MARK: - Weight Entry Model
struct WeightEntry: Identifiable, Codable {
    let id: UUID
    let weight: Double // Always stored in kg
    let date: Date
    let bmi: Double?
    let note: String?
    let photoURL: String? // Firebase Storage path (legacy - for backward compatibility)
    let photoURLs: [String]? // Multiple photo URLs
    let waistSize: Double? // Waist measurement in cm
    let dressSize: String? // Dress size (UK/US format)

    init(id: UUID = UUID(), weight: Double, date: Date = Date(), bmi: Double? = nil, note: String? = nil, photoURL: String? = nil, photoURLs: [String]? = nil, waistSize: Double? = nil, dressSize: String? = nil) {
        self.id = id
        self.weight = weight
        self.date = date
        self.bmi = bmi
        self.note = note
        self.photoURL = photoURL
        self.photoURLs = photoURLs
        self.waistSize = waistSize
        self.dressSize = dressSize
    }
}

// MARK: - History Row
struct WeightHistoryRow: View {
    let entry: WeightEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1f kg", entry.weight))
                        .font(.system(size: 17, weight: .semibold))

                    Text(entry.date, style: .date)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let bmi = entry.bmi {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("BMI")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", bmi))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                }
            }

            if let note = entry.note, !note.isEmpty {
                Text(note)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal, 16)
    }
}

// MARK: - Simple Chart
struct SimpleWeightChart: View {
    let entries: [WeightEntry]
    let goalWeight: Double

    private var sortedEntries: [WeightEntry] {
        entries.sorted { $0.date < $1.date }
    }

    private var maxWeight: Double {
        max(sortedEntries.map { $0.weight }.max() ?? 0, goalWeight)
    }

    private var minWeight: Double {
        min(sortedEntries.map { $0.weight }.min() ?? 0, goalWeight)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Goal line
                if goalWeight > 0 {
                    let goalY = (1 - (goalWeight - minWeight) / (maxWeight - minWeight)) * geometry.size.height

                    Path { path in
                        path.move(to: CGPoint(x: 0, y: goalY))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: goalY))
                    }
                    .stroke(Color.green.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }

                // Weight line
                if sortedEntries.count > 1 {
                    Path { path in
                        for (index, entry) in sortedEntries.enumerated() {
                            let x = (CGFloat(index) / CGFloat(sortedEntries.count - 1)) * geometry.size.width
                            let y = (1 - (entry.weight - minWeight) / (maxWeight - minWeight)) * geometry.size.height

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.blue, lineWidth: 3)
                }

                // Data points
                ForEach(sortedEntries.indices, id: \.self) { index in
                    let entry = sortedEntries[index]
                    let x = (CGFloat(index) / CGFloat(max(sortedEntries.count - 1, 1))) * geometry.size.width
                    let y = (1 - (entry.weight - minWeight) / max(maxWeight - minWeight, 1)) * geometry.size.height

                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }
            }
        }
        .padding(.vertical, 20)
        .background(Color(.systemGray6).opacity(0.3))
        .cornerRadius(12)
    }
}

// MARK: - Weight Line Chart
struct WeightLineChart: View {
    let entries: [WeightEntry]
    let goalWeight: Double
    let startWeight: Double

    var body: some View {
        GeometryReader { geometry in
            let maxWeight = max(entries.map { $0.weight }.max() ?? 0, goalWeight, startWeight) + 1
            let minWeight = min(entries.map { $0.weight }.min() ?? 0, goalWeight) - 1
            let range = maxWeight - minWeight

            ZStack {
                // Background card
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)

                VStack(spacing: 0) {
                    // Subtle gridlines
                    ForEach(0..<4) { i in
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .frame(height: 0.5)
                            .padding(.horizontal, 20)

                        if i < 3 {
                            Spacer()
                        }
                    }
                }
                .frame(height: geometry.size.height - 40)
                .padding(.top, 20)

                // Line and area
                if entries.count > 1 {
                    // Gradient area under line
                    Path { path in
                        let points = entries.enumerated().map { index, entry -> CGPoint in
                            let x = CGFloat(index) / CGFloat(max(entries.count - 1, 1)) * (geometry.size.width - 40) + 20
                            let y = (1 - (entry.weight - minWeight) / range) * (geometry.size.height - 40) + 20
                            return CGPoint(x: x, y: y)
                        }

                        if let first = points.first {
                            path.move(to: CGPoint(x: first.x, y: geometry.size.height))
                            path.addLine(to: first)

                            for point in points.dropFirst() {
                                path.addLine(to: point)
                            }

                            if let last = points.last {
                                path.addLine(to: CGPoint(x: last.x, y: geometry.size.height))
                            }
                            path.closeSubpath()
                        }
                    }
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.3, green: 0.5, blue: 1.0).opacity(0.2),
                                Color(red: 0.3, green: 0.5, blue: 1.0).opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Line
                    Path { path in
                        let points = entries.enumerated().map { index, entry -> CGPoint in
                            let x = CGFloat(index) / CGFloat(max(entries.count - 1, 1)) * (geometry.size.width - 40) + 20
                            let y = (1 - (entry.weight - minWeight) / range) * (geometry.size.height - 40) + 20
                            return CGPoint(x: x, y: y)
                        }

                        if let first = points.first {
                            path.move(to: first)
                            for point in points.dropFirst() {
                                path.addLine(to: point)
                            }
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.3, green: 0.5, blue: 1.0),
                                Color(red: 0.5, green: 0.3, blue: 0.9)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )

                    // Data points
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        let x = CGFloat(index) / CGFloat(max(entries.count - 1, 1)) * (geometry.size.width - 40) + 20
                        let y = (1 - (entry.weight - minWeight) / range) * (geometry.size.height - 40) + 20

                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.3, green: 0.5, blue: 1.0),
                                                Color(red: 0.5, green: 0.3, blue: 0.9)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 3
                                    )
                            )
                            .position(x: x, y: y)
                    }
                }

                // Goal line
                if goalWeight > 0 && goalWeight >= minWeight && goalWeight <= maxWeight {
                    let goalY = (1 - (goalWeight - minWeight) / range) * (geometry.size.height - 40) + 20

                    ZStack {
                        Path { path in
                            path.move(to: CGPoint(x: 20, y: goalY))
                            path.addLine(to: CGPoint(x: geometry.size.width - 20, y: goalY))
                        }
                        .stroke(Color.green.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))

                        HStack {
                            Spacer()
                            Text("Goal")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .cornerRadius(6)
                                .offset(y: goalY - 32)
                                .padding(.trailing, 24)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Picker Type Enum
enum PhotoPickerType: Identifiable {
    case camera
    case photoLibrary

    var id: String {
        switch self {
        case .camera: return "camera"
        case .photoLibrary: return "photoLibrary"
        }
    }

    var sourceType: UIImagePickerController.SourceType {
        switch self {
        case .camera: return .camera
        case .photoLibrary: return .photoLibrary
        }
    }
}

// MARK: - Identifiable Image Wrapper
struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
    let url: String? // URL if this is an existing photo from server
}

// MARK: - Weighing Scale Icon
struct WeighingScaleIcon: View {
    var size: CGFloat = 24
    var color: Color = .blue

    var body: some View {
        ZStack {
            // Platform base (rectangular with rounded corners)
            RoundedRectangle(cornerRadius: size * 0.15)
                .stroke(color, lineWidth: size * 0.08)
                .frame(width: size * 0.95, height: size * 0.7)
                .offset(y: size * 0.1)

            // Analog gauge dial (semi-circle at top)
            Circle()
                .trim(from: 0.25, to: 0.75)
                .stroke(color, lineWidth: size * 0.08)
                .frame(width: size * 0.5, height: size * 0.5)
                .rotationEffect(.degrees(180))
                .offset(y: -size * 0.1)

            // Needle
            Rectangle()
                .fill(color)
                .frame(width: size * 0.04, height: size * 0.2)
                .offset(y: -size * 0.1)
                .rotationEffect(.degrees(30))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Add Weight View
struct AddWeightView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseManager: FirebaseManager
    @Binding var currentWeight: Double
    @Binding var weightHistory: [WeightEntry]
    @Binding var userHeight: Double

    var existingEntry: WeightEntry? = nil // For editing existing entries

    @AppStorage("weightUnit") private var selectedUnit: WeightUnit = .kg
    @AppStorage("heightUnit") private var selectedHeightUnit: HeightUnit = .cm
    @AppStorage("userGender") private var userGender: Gender = .other
    @State private var primaryWeight: String = "" // kg, lbs, or stones
    @State private var secondaryWeight: String = "" // pounds (for stones only)
    @State private var primaryHeight: String = "" // cm or feet
    @State private var secondaryHeight: String = "" // inches (for ft/in only)
    @State private var note: String = ""
    @State private var date = Date()

    // Photo picker
    @State private var selectedPhotos: [IdentifiableImage] = []
    @State private var isLoadingPhotos = false
    @State private var activePickerType: PhotoPickerType? = nil
    @State private var showingPhotoOptions = false
    @State private var isUploading = false
    @State private var selectedPhotoForViewing: IdentifiableImage? = nil
    @State private var showingMultiImagePicker = false

    // Measurements
    @State private var waistSize: String = ""
    @State private var dressSize: String = ""

    private var weightInKg: Double? {
        guard let primary = Double(primaryWeight) else { return nil }
        let secondary = selectedUnit == .stones ? Double(secondaryWeight) : nil
        return selectedUnit.toKg(primary: primary, secondary: secondary)
    }

    private var heightInCm: Double? {
        guard let primary = Double(primaryHeight) else { return nil }
        let secondary = selectedHeightUnit == .ftIn ? Double(secondaryHeight) : nil
        return selectedHeightUnit.toCm(primary: primary, secondary: secondary)
    }

    private var calculatedBMI: Double? {
        guard let weightKg = weightInKg else { return nil }
        guard let heightCm = heightInCm, heightCm > 0 else { return nil }
        let heightInMeters = heightCm / 100
        return weightKg / (heightInMeters * heightInMeters)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Height")) {
                    Picker("Height Unit", selection: $selectedHeightUnit) {
                        ForEach(HeightUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)

                    if selectedHeightUnit == .ftIn {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Feet", text: $primaryHeight)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 20, weight: .semibold))
                                Text("ft").foregroundColor(.secondary).font(.caption)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Inches", text: $secondaryHeight)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 20, weight: .semibold))
                                Text("in").foregroundColor(.secondary).font(.caption)
                            }
                        }
                    } else {
                        HStack {
                            TextField("Height", text: $primaryHeight)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 20, weight: .semibold))

                            Text(selectedHeightUnit.shortName)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text("Weight")) {
                    Picker("Weight Unit", selection: $selectedUnit) {
                        ForEach(WeightUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)

                    if selectedUnit == .stones {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Stones", text: $primaryWeight)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 20, weight: .semibold))
                                Text("st").foregroundColor(.secondary).font(.caption)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Pounds", text: $secondaryWeight)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 20, weight: .semibold))
                                Text("lbs").foregroundColor(.secondary).font(.caption)
                            }
                        }
                    } else {
                        HStack {
                            TextField("Weight", text: $primaryWeight)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 20, weight: .semibold))

                            Text(selectedUnit.shortName)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let bmi = calculatedBMI {
                        HStack {
                            Text("BMI")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f", bmi))
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                }

                Section(header: Text("Date")) {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                // Photo Section
                Section(header: Text("Progress Photos (Optional - up to 3)")) {
                    // Show selected photos in a grid
                    if !selectedPhotos.isEmpty {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(selectedPhotos) { identifiableImage in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: identifiableImage.image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                        .onTapGesture {
                                            selectedPhotoForViewing = identifiableImage
                                        }

                                    // Delete button
                                    Button(action: {
        // DEBUG LOG: print("🗑️ Deleting photo with ID: \(identifiableImage.id)")
                                        #if DEBUG
                                        print("   Current photo count: \(selectedPhotos.count)")
                                        #endif
                                        selectedPhotos.removeAll { $0.id == identifiableImage.id }
                                        #if DEBUG
                                        print("   After deletion count: \(selectedPhotos.count)")
                                        #endif
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                            .background(Circle().fill(Color.red))
                                    }
                                    .buttonStyle(.plain)
                                    .padding(4)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    // Show add photo buttons if less than 3 photos
                    if selectedPhotos.count < 3 {
                        Button(action: {
                            #if DEBUG
                            print("📷 Take Photo button tapped")
                            #endif
                            activePickerType = .camera
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Take Photo")
                                if !selectedPhotos.isEmpty {
                                    Spacer()
                                    Text("(\(selectedPhotos.count)/3)")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        Button(action: {
        // DEBUG LOG: print("📚 Choose from Library button tapped")
                            showingMultiImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo.fill")
                                Text("Choose from Library")
                            }
                        }
                    } else {
                        Text("Maximum 3 photos added")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.vertical, 8)
                    }
                }

                // Measurements Section (conditional based on gender)
                if userGender == .female {
                    Section(header: Text("Measurements (Optional)")) {
                        TextField("Dress Size (e.g., UK 12)", text: $dressSize)
                            .keyboardType(.default)
                    }
                } else {
                    Section(header: Text("Measurements (Optional)")) {
                        TextField("Waist Size (cm)", text: $waistSize)
                            .keyboardType(.decimalPad)
                    }
                }

                Section(header: Text("Note (Optional)")) {
                    TextField("Add a note", text: $note)
                }
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWeight()
                    }
                    .disabled(primaryWeight.isEmpty || weightInKg == nil || isUploading)
                }
            }
            .overlay {
                if isUploading {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text(selectedPhotos.isEmpty ? "Saving weight..." : "Uploading photos...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(Color(.systemGray5))
                        .cornerRadius(16)
                    }
                }
            }
            .onAppear {
                // Pre-populate height fields from userHeight
                if userHeight > 0 {
                    let converted = selectedHeightUnit.fromCm(userHeight)
                    primaryHeight = String(format: converted.secondary != nil ? "%.0f" : "%.1f", converted.primary)
                    if let secondary = converted.secondary {
                        secondaryHeight = String(format: "%.1f", secondary)
                    }
                }
            }
            .fullScreenCover(item: $activePickerType) { pickerType in
                // Only use this for camera - library uses MultiImagePicker
                if pickerType == .camera {
                    ImagePicker(selectedImage: nil, sourceType: .camera) { image in
                        activePickerType = nil // Dismiss picker
                        if let image = image, selectedPhotos.count < 3 {
                            #if DEBUG
                            print("✅ AddWeightView: Photo from camera, adding to array (current count: \(selectedPhotos.count))")
                            #endif
                            selectedPhotos.append(IdentifiableImage(image: image, url: nil))
                        }
                    }
                }
            }
            .sheet(isPresented: $showingMultiImagePicker) {
                MultiImagePicker(maxSelection: 3 - selectedPhotos.count) { images in
        // DEBUG LOG: print("🎯 AddWeightView: Received \(images.count) images from MultiImagePicker")
                    #if DEBUG
                    print("   Current photo count before adding: \(selectedPhotos.count)")

                    // Add photos up to the limit of 3
                    #endif
                    let availableSlots = 3 - selectedPhotos.count
                    let photosToAdd = min(images.count, availableSlots)

                    for i in 0..<photosToAdd {
                        selectedPhotos.append(IdentifiableImage(image: images[i], url: nil))
                        #if DEBUG
                        print("   ✅ Added photo \(i + 1)/\(photosToAdd), new count: \(selectedPhotos.count)")
                        #endif
                    }

                    if images.count > photosToAdd {
                        #if DEBUG
                        print("   ⚠️ Ignored \(images.count - photosToAdd) photos (limit reached)")
                        #endif
                    }
                }
            }
            .confirmationDialog("Choose Photo Source", isPresented: $showingPhotoOptions) {
                Button("Take Photo") {
                    #if DEBUG
                    print("📷 Dialog: Take Photo selected")
                    #endif
                    activePickerType = .camera
                }
                Button("Choose from Library") {
        // DEBUG LOG: print("📚 Dialog: Choose from Library selected")
                    activePickerType = .photoLibrary
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    private func saveWeight() {
        guard let weightKg = weightInKg else { return }

        isUploading = true

        // Save to Firebase
        Task {
            do {
                // Generate ID for new entry
                let entryId = UUID()

                // Extract images from selected photos
                let images = selectedPhotos.map { $0.image }

                // Save images to local cache first
                var photoURLs: [String] = []
                if !images.isEmpty {
                    // Save all images locally
                    do {
                        try ImageCacheManager.shared.saveWeightImages(images, for: entryId.uuidString)
                        #if DEBUG
                        print("✅ Saved \(images.count) weight images to local cache for entry: \(entryId)")
                        #endif
                    } catch {
                        #if DEBUG
                        print("⚠️ Failed to cache weight images locally: \(error)")
                        #endif
                    }

                    // Upload to Firebase for backup/sync
                    do {
                        photoURLs = try await firebaseManager.uploadWeightPhotos(images)
                        #if DEBUG
                        print("☁️ Uploaded \(photoURLs.count) weight images to Firebase")
                        #endif
                    } catch {
                        #if DEBUG
                        print("⚠️ Firebase upload failed (using local cache): \(error)")
                        #endif
                    }
                }

                // Parse measurements
                let waist = waistSize.isEmpty ? nil : Double(waistSize)
                let dress = dressSize.isEmpty ? nil : dressSize

                // Create entry with all fields
                let entry = WeightEntry(
                    id: entryId,
                    weight: weightKg,
                    date: date,
                    bmi: calculatedBMI,
                    note: note.isEmpty ? nil : note,
                    photoURL: photoURLs.first, // For backward compatibility
                    photoURLs: photoURLs.isEmpty ? nil : photoURLs,
                    waistSize: waist,
                    dressSize: dress
                )

                try await firebaseManager.saveWeightEntry(entry)

                // Save height changes if user modified it
                if let heightCm = heightInCm, heightCm != userHeight {
                    try await firebaseManager.saveUserSettings(height: heightCm, goalWeight: nil)
                }

                await MainActor.run {
                    // FIX: Don't insert locally - NotificationCenter listener handles it
                    // This prevents duplicate entries
                    currentWeight = weightKg

                    // Update height if changed
                    if let heightCm = heightInCm, heightCm != userHeight {
                        userHeight = heightCm
                    }

                    isUploading = false
                    dismiss()
                }
            } catch {
                #if DEBUG
                print("Error saving weight entry: \(error)")
                #endif
                await MainActor.run {
                    isUploading = false
                }
                // TODO: Show error alert to user
            }
        }
    }
}

// MARK: - Edit Weight View
struct EditWeightView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseManager: FirebaseManager
    let entry: WeightEntry
    @Binding var currentWeight: Double
    @Binding var weightHistory: [WeightEntry]
    @Binding var userHeight: Double  // Changed from let to @Binding
    let onSave: () -> Void

    @AppStorage("weightUnit") private var selectedUnit: WeightUnit = .kg
    @AppStorage("heightUnit") private var selectedHeightUnit: HeightUnit = .cm  // NEW
    @AppStorage("userGender") private var userGender: Gender = .other
    @State private var primaryWeight: String = ""
    @State private var secondaryWeight: String = ""
    @State private var primaryHeight: String = ""  // NEW
    @State private var secondaryHeight: String = ""  // NEW
    @State private var note: String = ""
    @State private var date = Date()
    @State private var previousUnit: WeightUnit = .kg  // Track previous unit for conversions
    @State private var previousHeightUnit: HeightUnit = .cm  // Track previous height unit

    // Photo picker
    @State private var selectedPhotos: [IdentifiableImage] = []
    @State private var isLoadingPhotos = false
    @State private var activePickerType: PhotoPickerType? = nil
    @State private var showingPhotoOptions = false
    @State private var isUploading = false
    @State private var selectedPhotoForViewing: IdentifiableImage? = nil
    @State private var showingMultiImagePicker = false

    // Measurements
    @State private var waistSize: String = ""
    @State private var dressSize: String = ""

    private var weightInKg: Double? {
        guard let primary = Double(primaryWeight) else { return nil }
        let secondary = selectedUnit == .stones ? Double(secondaryWeight) : nil
        return selectedUnit.toKg(primary: primary, secondary: secondary)
    }

    private var heightInCm: Double? {  // NEW
        guard let primary = Double(primaryHeight) else { return nil }
        let secondary = selectedHeightUnit == .ftIn ? Double(secondaryHeight) : nil
        return selectedHeightUnit.toCm(primary: primary, secondary: secondary)
    }

    private var calculatedBMI: Double? {
        guard let weightKg = weightInKg else { return nil }
        guard let heightCm = heightInCm, heightCm > 0 else { return nil }  // Updated to use heightInCm
        let heightInMeters = heightCm / 100
        return weightKg / (heightInMeters * heightInMeters)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Height")) {
                    Picker("Height Unit", selection: $selectedHeightUnit) {
                        ForEach(HeightUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)

                    if selectedHeightUnit == .ftIn {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Feet", text: $primaryHeight)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 20, weight: .semibold))
                                Text("ft").foregroundColor(.secondary).font(.caption)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Inches", text: $secondaryHeight)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 20, weight: .semibold))
                                Text("in").foregroundColor(.secondary).font(.caption)
                            }
                        }
                    } else {
                        HStack {
                            TextField("Height", text: $primaryHeight)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 20, weight: .semibold))

                            Text(selectedHeightUnit.shortName)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text("Weight")) {
                    Picker("Weight Unit", selection: $selectedUnit) {
                        ForEach(WeightUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)

                    if selectedUnit == .stones {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Stones", text: $primaryWeight)
                                     .keyboardType(.decimalPad)
                                    .font(.system(size: 20, weight: .semibold))

                                Text("st")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Pounds", text: $secondaryWeight)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 20, weight: .semibold))

                                Text("lbs")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    } else {
                        HStack {
                            TextField("Weight", text: $primaryWeight)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 20, weight: .semibold))

                            Text(selectedUnit.shortName)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let bmi = calculatedBMI {
                        HStack {
                            Text("BMI")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f", bmi))
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                }

                Section(header: Text("Date")) {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                // Photo Section
                Section(header: Text("Progress Photos (Optional - up to 3)")) {
                    // Show loading indicator while photos are being downloaded
                    if isLoadingPhotos {
                        HStack {
                            Spacer()
                            ProgressView("Loading photos...")
                                .padding(.vertical, 20)
                            Spacer()
                        }
                    }

                    // Show selected photos in a grid
                    if !selectedPhotos.isEmpty {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(selectedPhotos) { identifiableImage in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: identifiableImage.image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                        .onTapGesture {
                                            selectedPhotoForViewing = identifiableImage
                                        }

                                    // Delete button
                                    Button(action: {
        // DEBUG LOG: print("🗑️ Deleting photo with ID: \(identifiableImage.id)")
                                        #if DEBUG
                                        print("   Current photo count: \(selectedPhotos.count)")
                                        #endif
                                        selectedPhotos.removeAll { $0.id == identifiableImage.id }
                                        #if DEBUG
                                        print("   After deletion count: \(selectedPhotos.count)")
                                        #endif
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                            .background(Circle().fill(Color.red))
                                    }
                                    .buttonStyle(.plain)
                                    .padding(4)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    // Show add photo buttons if less than 3 photos
                    if selectedPhotos.count < 3 && !isLoadingPhotos {
                        Button(action: {
                            activePickerType = .camera
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Take Photo")
                                if !selectedPhotos.isEmpty {
                                    Spacer()
                                    Text("(\(selectedPhotos.count)/3)")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        Button(action: {
                            showingMultiImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo.fill")
                                Text("Choose from Library")
                            }
                        }
                    } else if selectedPhotos.count >= 3 {
                        Text("Maximum 3 photos added")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.vertical, 8)
                    }
                }

                if userGender == .female {
                    Section(header: Text("Measurements (Optional)")) {
                        TextField("Dress Size (e.g., UK 12)", text: $dressSize)
                            .keyboardType(.default)
                    }
                } else {
                    Section(header: Text("Measurements (Optional)")) {
                        TextField("Waist Size (cm)", text: $waistSize)
                            .keyboardType(.decimalPad)
                    }
                }

                Section(header: Text("Note (Optional)")) {
                    TextField("Add a note", text: $note)
                }
            }
            .navigationTitle("Edit Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWeight()
                    }
                    .disabled(weightInKg == nil || isUploading)
                }
            }
            .overlay {
                if isUploading {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text(selectedPhotos.isEmpty ? "Saving weight..." : "Uploading photos...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(Color(.systemGray5))
                        .cornerRadius(16)
                    }
                }
            }
            .onChange(of: selectedUnit) { newUnit in
                convertWeight(from: previousUnit, to: newUnit)
                previousUnit = newUnit  // Update after conversion
            }
            .onChange(of: selectedHeightUnit) { newUnit in
                convertHeight(from: previousHeightUnit, to: newUnit)
                previousHeightUnit = newUnit  // Update after conversion
            }
            .onAppear {
                // Initialize previous units to current units
                previousUnit = selectedUnit
                previousHeightUnit = selectedHeightUnit

                // Pre-populate with existing entry data (convert from kg to selected unit)
                let converted = selectedUnit.fromKg(entry.weight)
                primaryWeight = String(format: "%.1f", converted.primary)
                if let secondary = converted.secondary {
                    secondaryWeight = String(format: "%.1f", secondary)
                }

                // Pre-populate height fields from userHeight
                if userHeight > 0 {
                    let convertedHeight = selectedHeightUnit.fromCm(userHeight)
                    primaryHeight = String(format: convertedHeight.secondary != nil ? "%.0f" : "%.0f", convertedHeight.primary)
                    if let secondary = convertedHeight.secondary {
                        secondaryHeight = String(format: "%.0f", secondary)
                    }
                }

                date = entry.date
                note = entry.note ?? ""

                // Pre-populate measurement fields
                if let waist = entry.waistSize {
                    waistSize = String(format: "%.1f", waist)
                }
                if let dress = entry.dressSize {
                    dressSize = dress
                }

                // Load existing photos
                loadExistingPhotos()
            }
            .fullScreenCover(item: $activePickerType) { pickerType in
                // Only use this for camera - library uses MultiImagePicker
                if pickerType == .camera {
                    ImagePicker(selectedImage: nil, sourceType: .camera) { image in
                        activePickerType = nil // Dismiss picker
                        if let image = image, selectedPhotos.count < 3 {
                            #if DEBUG
                            print("✅ EditWeightView: Photo from camera, adding to array (current count: \(selectedPhotos.count))")
                            #endif
                            selectedPhotos.append(IdentifiableImage(image: image, url: nil))
                        }
                    }
                }
            }
            .confirmationDialog("Choose Photo Source", isPresented: $showingPhotoOptions) {
                Button("Take Photo") {
                    #if DEBUG
                    print("📷 Take Photo button tapped")
                    #endif
                    activePickerType = .camera
                }
                Button("Choose from Library") {
        // DEBUG LOG: print("📚 Choose from Library button tapped")
                    showingMultiImagePicker = true
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showingMultiImagePicker) {
                MultiImagePicker(maxSelection: 3 - selectedPhotos.count) { images in
        // DEBUG LOG: print("🎯 Received \(images.count) images from MultiImagePicker")
                    #if DEBUG
                    print("   Current photo count before adding: \(selectedPhotos.count)")

                    // Add photos up to the limit of 3
                    #endif
                    let availableSlots = 3 - selectedPhotos.count
                    let photosToAdd = min(images.count, availableSlots)

                    for i in 0..<photosToAdd {
                        selectedPhotos.append(IdentifiableImage(image: images[i], url: nil))
                        #if DEBUG
                        print("   ✅ Added photo \(i + 1)/\(photosToAdd), new count: \(selectedPhotos.count)")
                        #endif
                    }

                    if images.count > photosToAdd {
                        #if DEBUG
                        print("   ⚠️ Ignored \(images.count - photosToAdd) photos (limit reached)")
                        #endif
                    }
                }
            }
            .fullScreenCover(item: $selectedPhotoForViewing) { photo in
                ZStack {
                    Color.black.ignoresSafeArea()

                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                selectedPhotoForViewing = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .padding()
                            }
                        }

                        Spacer()

                        Image(uiImage: photo.image)
                            .resizable()
                            .scaledToFit()

                        Spacer()
                    }
                }
            }
        }
    }

    private func convertWeight(from oldUnit: WeightUnit, to newUnit: WeightUnit) {
        // DEBUG LOG: print("🔄 EditWeightView: Converting weight from \(oldUnit.rawValue) to \(newUnit.rawValue)")
        #if DEBUG
        print("   Current primaryWeight: '\(primaryWeight)', secondaryWeight: '\(secondaryWeight)'")

        #endif
        withAnimation(.easeInOut(duration: 0.2)) {
            // First, get current weight in kg for conversion
            guard let primary = Double(primaryWeight), primary > 0 else { return }
            let secondary = !secondaryWeight.isEmpty ? Double(secondaryWeight) : nil

            // Convert from old unit to kg
            let kg = oldUnit.toKg(primary: primary, secondary: secondary)
            #if DEBUG
            print("   Intermediate kg value: \(kg) kg")

            #endif
            if newUnit == .kg {
                // Converting TO kg
                self.primaryWeight = String(format: "%.1f", kg)
                #if DEBUG
                print("   ✅ Converted to \(self.primaryWeight) kg")

                // Clear secondary field after delay
                #endif
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.secondaryWeight = ""
                }
            } else if newUnit == .stones {
                // Converting TO stones/lbs
                let converted = WeightUnit.stones.fromKg(kg)

                // Update stones/lbs fields FIRST
                self.primaryWeight = String(format: "%.0f", converted.primary)
                self.secondaryWeight = String(format: "%.1f", converted.secondary ?? 0)
                #if DEBUG
                print("   ✅ Converted to \(self.primaryWeight) st \(self.secondaryWeight) lbs")
                #endif
            } else if newUnit == .lbs {
                // Converting TO lbs
                let converted = WeightUnit.lbs.fromKg(kg)
                self.primaryWeight = String(format: "%.1f", converted.primary)
                #if DEBUG
                print("   ✅ Converted to \(self.primaryWeight) lbs")

                // Clear secondary field after delay
                #endif
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.secondaryWeight = ""
                }
            }
        }
    }

    private func convertHeight(from oldUnit: HeightUnit, to newUnit: HeightUnit) {
        // DEBUG LOG: print("🔄 EditWeightView: Converting height from \(oldUnit.rawValue) to \(newUnit.rawValue)")
        #if DEBUG
        print("   Current primaryHeight: '\(primaryHeight)', secondaryHeight: '\(secondaryHeight)'")

        #endif
        withAnimation(.easeInOut(duration: 0.2)) {
            guard let primary = Double(primaryHeight), primary > 0 else { return }
            let secondary = !secondaryHeight.isEmpty ? Double(secondaryHeight) : nil

            // Convert from old unit to cm
            let cm = oldUnit.toCm(primary: primary, secondary: secondary)
            #if DEBUG
            print("   Intermediate cm value: \(cm) cm")

            #endif
            if newUnit == .cm {
                // Converting TO cm
                self.primaryHeight = String(format: "%.0f", cm)
                #if DEBUG
                print("   ✅ Converted to \(self.primaryHeight) cm")

                // Clear secondary field after delay
                #endif
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.secondaryHeight = ""
                }
            } else if newUnit == .ftIn {
                // Converting TO feet/inches
                let converted = HeightUnit.ftIn.fromCm(cm)

                // Update ft/in fields FIRST
                self.primaryHeight = String(format: "%.0f", converted.primary)
                self.secondaryHeight = String(format: "%.0f", converted.secondary ?? 0)
                #if DEBUG
                print("   ✅ Converted to \(self.primaryHeight) ft \(self.secondaryHeight) in")
                #endif
            }
        }
    }

    private func loadExistingPhotos() {
        // Check for photos in photoURLs array (new format) or photoURL (legacy)
        var urls: [String] = []
        if let photoURLs = entry.photoURLs {
            urls = photoURLs
        } else if let photoURL = entry.photoURL {
            urls = [photoURL]
        }

        guard !urls.isEmpty else { return }

        isLoadingPhotos = true
        Task {
            var loadedImages: [IdentifiableImage] = []

            // Try loading from local cache first
            let cachedImages = await ImageCacheManager.shared.loadWeightImagesAsync(for: entry.id.uuidString, count: urls.count)

            if !cachedImages.isEmpty && cachedImages.count == urls.count {
                // All images found in cache
                for (index, image) in cachedImages.enumerated() {
                    loadedImages.append(IdentifiableImage(image: image, url: urls[index]))
                }
                #if DEBUG
                print("⚡️ Loaded \(cachedImages.count) weight images from local cache")
                #endif
            } else {
                // Load from Firebase and cache locally
                for (index, url) in urls.enumerated() {
                    do {
                        let image = try await firebaseManager.downloadWeightPhoto(from: url)
                        loadedImages.append(IdentifiableImage(image: image, url: url))

                        // Cache the downloaded image locally for next time
                        let imageId = "\(entry.id.uuidString)_\(index)"
                        do {
                            try await ImageCacheManager.shared.saveWeightImageAsync(image, for: imageId)
                            #if DEBUG
                            print("💾 Cached downloaded weight image: \(imageId)")
                            #endif
                        } catch {
                            #if DEBUG
                            print("⚠️ Failed to cache downloaded image: \(error)")
                            #endif
                        }
                    } catch {
                        #if DEBUG
                        print("Error loading photo from \(url): \(error)")
                        #endif
                    }
                }
                #if DEBUG
                print("📸 Loaded \(loadedImages.count) weight images from Firebase")
                #endif
            }

            await MainActor.run {
                selectedPhotos = loadedImages
                isLoadingPhotos = false
            }
        }
    }

    private func saveWeight() {
        guard let weightKg = weightInKg else { return }  // Convert to kg

        isUploading = true

        // Save to Firebase
        Task {
            do {
                // Separate existing photos (have URLs) from new photos (need upload)
                var photoURLs: [String] = []
                var newPhotosToUpload: [UIImage] = []

                for photo in selectedPhotos {
                    if let url = photo.url {
                        // Existing photo - keep the URL
                        photoURLs.append(url)
                    } else {
                        // New photo - needs upload
                        newPhotosToUpload.append(photo.image)
                    }
                }

                // Save new photos to local cache
                if !newPhotosToUpload.isEmpty {
                    do {
                        // Save all new images locally
                        let currentPhotoCount = selectedPhotos.count - newPhotosToUpload.count
                        for (index, image) in newPhotosToUpload.enumerated() {
                            let imageId = "\(entry.id.uuidString)_\(currentPhotoCount + index)"
                            try await ImageCacheManager.shared.saveWeightImageAsync(image, for: imageId)
                        }
                        #if DEBUG
                        print("✅ Saved \(newPhotosToUpload.count) new weight images to local cache")
                        #endif
                    } catch {
                        #if DEBUG
                        print("⚠️ Failed to cache new weight images locally: \(error)")
                        #endif
                    }

                    // Upload new photos to Firebase for backup/sync
                    do {
                        let newURLs = try await firebaseManager.uploadWeightPhotos(newPhotosToUpload)
                        photoURLs.append(contentsOf: newURLs)
                        #if DEBUG
                        print("☁️ Uploaded \(newURLs.count) new weight images to Firebase")
                        #endif
                    } catch {
                        #if DEBUG
                        print("⚠️ Firebase upload failed (using local cache): \(error)")
                        #endif
                    }
                }

                // Parse measurements
                let waist = waistSize.isEmpty ? nil : Double(waistSize)
                let dress = dressSize.isEmpty ? nil : dressSize

                // Create updated entry with same ID
                let updatedEntry = WeightEntry(
                    id: entry.id,
                    weight: weightKg,  // Store in kg
                    date: date,
                    bmi: calculatedBMI,
                    note: note.isEmpty ? nil : note,
                    photoURL: photoURLs.first, // For backward compatibility
                    photoURLs: photoURLs.isEmpty ? nil : photoURLs,
                    waistSize: waist,
                    dressSize: dress
                )

                try await firebaseManager.saveWeightEntry(updatedEntry)

                // Save height changes if user modified it
                if let heightCm = heightInCm, heightCm != userHeight {
                    try await firebaseManager.saveUserSettings(height: heightCm, goalWeight: nil)
                }

                await MainActor.run {
                    // Update local state
                    if let index = weightHistory.firstIndex(where: { $0.id == entry.id }) {
                        weightHistory[index] = updatedEntry
                        weightHistory.sort { $0.date > $1.date }
                    }

                    // Update current weight if this was the most recent entry
                    if let latest = weightHistory.first {
                        currentWeight = latest.weight
                    }

                    // Update height if changed
                    if let heightCm = heightInCm, heightCm != userHeight {
                        userHeight = heightCm
                    }

                    isUploading = false
                    onSave()
                    dismiss()
                }
            } catch {
                #if DEBUG
                print("Error updating weight entry: \(error)")
                #endif
                await MainActor.run {
                    isUploading = false
                }
                // TODO: Show error alert to user
            }
        }
    }
}

// MARK: - Height Setup View
struct HeightSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseManager: FirebaseManager
    @Binding var userHeight: Double

    @State private var heightCm: String = ""
    @State private var heightFeet: String = ""
    @State private var heightInches: String = ""
    @State private var useMetric: Bool = true

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("What's your height?")
                        .font(.system(size: 28, weight: .bold))

                    Text("We need this to calculate your BMI")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                Picker("Unit", selection: $useMetric) {
                    Text("Metric (cm)").tag(true)
                    Text("Imperial (ft/in)").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 40)

                if useMetric {
                    HStack(spacing: 12) {
                        TextField("170", text: $heightCm)
                            .keyboardType(.numberPad)
                            .font(.system(size: 48, weight: .light, design: .rounded))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 200)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                        Text("cm")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack(spacing: 16) {
                        VStack(spacing: 8) {
                            TextField("5", text: $heightFeet)
                                .keyboardType(.numberPad)
                                .font(.system(size: 36, weight: .light, design: .rounded))
                                .multilineTextAlignment(.center)
                                .frame(width: 100)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)

                            Text("feet")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }

                        VStack(spacing: 8) {
                            TextField("9", text: $heightInches)
                                .keyboardType(.numberPad)
                                .font(.system(size: 36, weight: .light, design: .rounded))
                                .multilineTextAlignment(.center)
                                .frame(width: 100)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)

                            Text("inches")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Button(action: saveHeight) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isValid ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isValid)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(true)
    }

    private var isValid: Bool {
        if useMetric {
            return Double(heightCm) ?? 0 > 0
        } else {
            return (Double(heightFeet) ?? 0) > 0 || (Double(heightInches) ?? 0) > 0
        }
    }

    private func saveHeight() {
        var heightInCm: Double = 0

        if useMetric {
            heightInCm = Double(heightCm) ?? 0
        } else {
            let feet = Double(heightFeet) ?? 0
            let inches = Double(heightInches) ?? 0
            heightInCm = (feet * 12 + inches) * 2.54
        }

        // Save to Firebase
        Task {
            do {
                try await firebaseManager.saveUserSettings(height: heightInCm, goalWeight: nil)
                await MainActor.run {
                    userHeight = heightInCm
                    dismiss()
                }
            } catch {
                #if DEBUG
                print("Error saving height: \(error)")
                // TODO: Show error alert to user
                #endif
            }
        }
    }
}



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
//                    HomeUseByAlertsCard()
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

//struct HomeUseByAlertsCard: View {
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
//                    print("Manage Use By tapped")
//                }
//                .font(.system(size: 14, weight: .medium))
//                .foregroundColor(.blue)
//            }
//            
//            VStack(spacing: 8) {
//                HomeUseByAlertRow(
//                    item: "Greek Yoghurt",
//                    daysLeft: 2,
//                    urgency: .high
//                )
//                
//                HomeUseByAlertRow(
//                    item: "Chicken Breast",
//                    daysLeft: 1,
//                    urgency: .critical
//                )
//                
//                HomeUseByAlertRow(
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

//struct HomeUseByAlertRow: View {
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
                        
                        Text("\(exercise.sets.count) sets \(exercise.exerciseType)")
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

// MARK: - Exercise Workout Card Component
struct ExerciseWorkoutCard: View {
    let exercise: String
    @Binding var sets: [WorkoutSet]
    let onAddSet: (WorkoutSet) -> Void
    let onRemoveSet: (Int) -> Void
    var onCompleteSet: ((Int) -> Void)? = nil
    let onMove: (Int, Int) -> Void
    let exerciseIndex: Int
    let totalExercises: Int

    @State private var showingSetTypeMenu: Int? = nil
    @State private var showingNotes = false
    @State private var exerciseNotes: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // HEVY STYLE: Exercise Header
            HStack {
                Text(exercise)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                Menu {
                    Button(action: { showingNotes = true }) {
                        Label("Notes", systemImage: "note.text")
                    }
                    Button(role: .destructive, action: {
                        // Delete handled via onRemoveSet callback
                    }) {
                        Label("Delete Exercise", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
            }

            // HEVY STYLE: Column Headers
            HStack(spacing: 8) {
                Text("SET")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .center)

                Text("PREVIOUS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 70, alignment: .center)

                Text("KG")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)

                Text("REPS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)

                Spacer()
                    .frame(width: 40)
            }
            .padding(.horizontal, 4)

            // HEVY STYLE: Sets List
            ForEach(Array(sets.enumerated()), id: \.offset) { index, set in
                HStack(spacing: 8) {
                    // Set Number Circle with Type Indicator
                    Button(action: {
                        showingSetTypeMenu = index
                    }) {
                        ZStack {
                            Circle()
                                .fill(set.setType == .normal ? Color(.systemGray5) : set.setType.color.opacity(0.2))
                                .frame(width: 32, height: 32)

                            if set.setType != .normal {
                                Image(systemName: set.setType.icon)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(set.setType.color)
                            } else {
                                Text("\(index + 1)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .frame(width: 40)
                    .confirmationDialog("Set Type", isPresented: Binding(
                        get: { showingSetTypeMenu == index },
                        set: { if !$0 { showingSetTypeMenu = nil } }
                    )) {
                        ForEach(SetType.allCases, id: \.self) { type in
                            Button(type.rawValue) {
                                sets[index].setType = type
                                showingSetTypeMenu = nil
                            }
                        }
                    }

                    // Previous Performance
                    Text("-")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(width: 70, alignment: .center)

                    // Weight Input
                    TextField("0", value: $sets[index].weight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 15, weight: .medium))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity)

                    // Reps Input
                    TextField("0", value: $sets[index].reps, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 15, weight: .medium))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity)

                    // Complete Set Checkbox
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()

                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            sets[index].isCompleted.toggle()
                        }

                        if sets[index].isCompleted {
                            onCompleteSet?(index)
                        }
                    }) {
                        ZStack {
                            Circle()
                                .stroke(set.isCompleted ? Color.blue : Color(.systemGray4), lineWidth: 2)
                                .frame(width: 28, height: 28)

                            if set.isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .frame(width: 40)
                }
                .padding(.vertical, 4)
            }

            // HEVY STYLE: Add Set Button
            Button(action: {
                let newSet = WorkoutSet(
                    weight: sets.last?.weight ?? 0,
                    reps: sets.last?.reps ?? 0
                )
                onAddSet(newSet)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                    Text("Add Set")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
        .sheet(isPresented: $showingNotes) {
            NavigationView {
                VStack {
                    TextEditor(text: $exerciseNotes)
                        .padding()

                    Spacer()
                }
                .navigationTitle("Exercise Notes")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showingNotes = false
                        }
                    }
                }
            }
        }
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
        // DEBUG LOG: print("🎯 ExerciseEntryView opened with type: \(exerciseType.rawValue)")
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
                            Text(intensity.description).tag(intensity)
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
            // Exercise selection sheets removed - feature deprecated
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
    
    private var micronutrientAnalysis: [LegacyMicronutrientStatus] {
        analyzeMicronutrientFrequency()
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(micronutrientAnalysis.prefix(4), id: \.name) { nutrient in
                MicronutrientIndicator(nutrient: nutrient)
            }
        }
    }
    
    private func analyzeMicronutrientFrequency() -> [LegacyMicronutrientStatus] {
        let nutrientFoodSources: [String: [String]] = [
            "Vitamin C": ["orange", "lemon", "lime", "strawberry", "strawberries", "kiwi", "bell pepper", "broccoli", "tomato", "potato"],
            "Vitamin D": ["salmon", "tuna", "mackerel", "sardines", "egg", "fortified milk", "fortified cereal"],
            "Iron": ["spinach", "beef", "chicken", "turkey", "lentils", "beans", "quinoa", "tofu"],
            "Calcium": ["milk", "cheese", "yogurt", "yoghurt", "broccoli", "kale", "sardines", "almonds"],
            "Vitamin B12": ["meat", "fish", "dairy", "eggs", "nutritional yeast", "fortified"],
            "Folate": ["leafy greens", "spinach", "asparagus", "avocado", "beans", "lentils", "fortified"],
            "Omega-3": ["salmon", "sardines", "mackerel", "walnuts", "flax", "chia", "hemp"]
        ]
        
        var results: [LegacyMicronutrientStatus] = []
        
        for (nutrient, sources) in nutrientFoodSources {
            let hasSource = allFoods.contains { food in
                sources.contains { source in
                    food.name.lowercased().contains(source.lowercased())
                }
            }
            
            let status: LegacyNutrientStatus = hasSource ? .good : .needsAttention
            results.append(LegacyMicronutrientStatus(name: nutrient, status: status))
        }
        
        // Sort by status (needs attention first)
        return results.sorted { 
            if $0.status == .needsAttention && $1.status == .good { return true }
            if $0.status == .good && $1.status == .needsAttention { return false }
            return $0.name < $1.name
        }
    }
}

struct LegacyMicronutrientStatus {
    let name: String
    let status: LegacyNutrientStatus
}

enum LegacyNutrientStatus {
    case good              // Getting regularly (70%+)
    case inconsistent      // Getting sometimes (40-69%)
    case needsTracking     // Rarely getting (<40%)
    case needsAttention    // Legacy case for compatibility

    var color: Color {
        switch self {
        case .good: return .green
        case .inconsistent: return .orange
        case .needsTracking: return .gray
        case .needsAttention: return .orange
        }
    }

    var symbol: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .inconsistent: return "exclamationmark.triangle"
        case .needsTracking: return "circle.dotted"
        case .needsAttention: return "exclamationmark.triangle.fill"
        }
    }

    var label: String {
        switch self {
        case .good: return "Getting regularly"
        case .inconsistent: return "Track more often"
        case .needsTracking: return "Rarely tracked"
        case .needsAttention: return "Needs attention"
        }
    }
}

struct MicronutrientIndicator: View {
    let nutrient: LegacyMicronutrientStatus
    
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
// MARK: - UseByTabView System moved to Views/Use By/UseByTabViews.swift
// The following components were extracted as part of Phase 15 ContentView.swift modularization effort:
// - UseByTabView: Main fridge interface with sub-tab navigation
// - UseBySubTabSelector: Sub-tab selector for fridge sections
// - UseByExpiryView: Food expiry management dashboard
// - UseByExpiryAlertsCard: Expiry alerts summary
// - UseByCriticalExpiryCard: Critical expiring items
// - UseByWeeklyExpiryCard: Weekly expiry schedule
// - UseByExpiryItemRow: Individual expiry item display
// - UseByExpiryDayRow: Daily expiry schedule row
// - UseByQuickAddCard: Quick add item interface
// Total extracted: 385+ lines of comprehensive Use By management functionality
// 
// 
// MARK: - Add Food Main View
//
// End of AddTabView - see extracted file for implementation

struct AddFoodMainView: View {
    @Binding var selectedTab: TabItem
    @State private var selectedAddOption: AddOption = .search
    @State private var prefilledBarcode: String? = nil // Barcode from scanner to prefill manual entry
    @Binding var isPresented: Bool // Direct binding to presentation state
    var onDismiss: (() -> Void)?
    var onComplete: ((TabItem) -> Void)?
    @State private var keyboardVisible = false

    init(selectedTab: Binding<TabItem>, isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil, onComplete: ((TabItem) -> Void)? = nil) {
        self._selectedTab = selectedTab
        self._isPresented = isPresented
        self.onDismiss = onDismiss
        self.onComplete = onComplete
    }

    enum AddOption: String, CaseIterable {
        case search = "Search"
        case manual = "Manual"
        case barcode = "Barcode"

        var icon: String {
            switch self {
            case .search: return "magnifyingglass"
            case .manual: return "square.and.pencil"
            case .barcode: return "barcode.viewfinder"
            }
        }

        var description: String {
            switch self {
            case .search: return "Search food database"
            case .manual: return "Enter manually"
            case .barcode: return "Scan product barcode"
            }
        }
    }

    // Lightweight button component to simplify option selector and reduce type-checking complexity
    private struct OptionSelectorButton: View {
        @Environment(\.colorScheme) var colorScheme
        let title: String
        let icon: String
        let isSelected: Bool
        let onTap: () -> Void

        var body: some View {
            Button(action: { onTap() }) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? (colorScheme == .dark ? Color.midnightBackground : Color.blue) : Color(.systemGray6))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                    // Option selector
                    HStack(spacing: 0) {
                        OptionSelectorButton(title: "Search", icon: "magnifyingglass", isSelected: selectedAddOption == .search) {
                            selectedAddOption = .search
                        }
                        OptionSelectorButton(title: "AI/Manual", icon: "square.and.pencil", isSelected: selectedAddOption == .manual) {
                            selectedAddOption = .manual
                        }
                        OptionSelectorButton(title: "Barcode", icon: "barcode.viewfinder", isSelected: selectedAddOption == .barcode) {
                            selectedAddOption = .barcode
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .background(Color.green.opacity(0.001)) // Ultra-transparent hit test helper
                }
                .background(Color.adaptiveBackground)
                .zIndex(999)
                .allowsHitTesting(true)

                // Content based on selected option
                Group {
                    switch selectedAddOption {
                    case .search:
                        AnyView(
                            AddFoodSearchView(
                                selectedTab: $selectedTab,
                                onComplete: onComplete,
                                onSwitchToManual: {
                                    selectedAddOption = .manual
                                }
                            )
                        )
                    case .manual:
                        AnyView(
                            AddFoodManualView(selectedTab: $selectedTab, prefilledBarcode: prefilledBarcode, onComplete: onComplete)
                        )
                    case .barcode:
                        AnyView(
                            AddFoodBarcodeView(selectedTab: $selectedTab, onSwitchToManual: { barcode in
                                prefilledBarcode = barcode
                                selectedAddOption = .manual
                            })
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(0)
                }
                .background(Color.adaptiveBackground)
                .navigationTitle("Diary")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isPresented = false
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        .zIndex(1000)
                        .allowsHitTesting(true)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            // Monitor keyboard
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
                keyboardVisible = true
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                keyboardVisible = false
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
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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

// MARK: - AddFoodManualView has been extracted to Views/Food/AddFoodManualViews.swift
// This comprehensive manual food entry system was moved as part of manual add enhancement:
// - AddFoodManualView: Main manual add view with navigation to detail entry
// - ManualFoodDetailEntryView: Full food entry form with all FoodSearchResult fields
// - Support for both diary and useBy destinations with appropriate fields
// - UseByItem models for expiry tracking and location management
// Total extracted: 450+ lines of comprehensive manual entry functionality

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

// MARK: - Settings View extracted to Views/Settings/SettingsView.swift
// The comprehensive settings interface was extracted as part of settings implementation:
// - SettingsView: Main settings interface with account management, nutrition goals, and preferences
// - AccountSection: User account management with sign out, password reset, and account deletion
// - SettingsSection: Reusable section container component
// - SettingsRow: Individual settings row with icon and action
// - AboutSection: App version, terms, privacy policy, and health disclaimer
// Total extracted: 120+ lines of settings functionality
//
// PHASE 1 (Completed): Account section with functional sign out button
// PHASE 2-5: To be implemented in future iterations

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
            ImagePicker(selectedImage: $capturedImage, sourceType: .camera) { image in
                showingImagePicker = false // Dismiss picker
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
                                        #if DEBUG
                                        print("Error completing submission: \(error)")
                                        #endif
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
