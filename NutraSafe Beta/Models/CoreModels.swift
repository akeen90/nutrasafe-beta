//
//  CoreModels.swift
//  NutraSafe Beta
//
//  Domain models for Core
//

import Foundation
import SwiftUI

struct BoundingBox: Codable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

// MARK: - Fridge Inventory Models
struct FridgeInventoryItem: Codable, Identifiable {
    let id: String
    let name: String
    let brand: String?
    let quantity: String
    let expiryDate: Date
    let addedDate: Date
    let openedDate: Date?
    let barcode: String?
    let category: String?
    let imageURL: String?

    init(id: String = UUID().uuidString, name: String, brand: String? = nil,
         quantity: String, expiryDate: Date, addedDate: Date,
         openedDate: Date? = nil, barcode: String? = nil, category: String? = nil, imageURL: String? = nil) {
        self.id = id
        self.name = name
        self.brand = brand
        self.quantity = quantity
        self.expiryDate = expiryDate
        self.addedDate = addedDate
        self.openedDate = openedDate
        self.barcode = barcode
        self.category = category
        self.imageURL = imageURL
    }

    var daysUntilExpiry: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expiryDate)
        return components.day ?? 0
    }

    var expiryStatus: ExpiryStatus {
        switch daysUntilExpiry {
        case ...0: return .expired
        case 1: return .expiringToday
        case 2...3: return .expiringSoon
        case 4...7: return .expiringThisWeek
        default: return .fresh
        }
    }
}

enum ExpiryStatus {
    case expired
    case expiringToday
    case expiringSoon
    case expiringThisWeek
    case fresh

    var color: Color {
        switch self {
        case .expired: return .red
        case .expiringToday: return .red
        case .expiringSoon: return .orange
        case .expiringThisWeek: return .yellow
        case .fresh: return .green
        }
    }

    var title: String {
        switch self {
        case .expired: return "Expired"
        case .expiringToday: return "Expires Today"
        case .expiringSoon: return "Expires Soon"
        case .expiringThisWeek: return "This Week"
        case .fresh: return "Fresh"
        }
    }
}

enum ReactionSeverity: String, CaseIterable, Codable {
    case mild = "mild"
    case moderate = "moderate"
    case severe = "severe"
    
    var description: String {
        switch self {
        case .mild:
            return "Mild discomfort"
        case .moderate:
            return "Noticeable reaction"
        case .severe:
            return "Significant reaction"
        }
    }
    
    var color: Color {
        switch self {
        case .mild:
            return .yellow
        case .moderate:
            return .orange
        case .severe:
            return .red
        }
    }
    
    var colorString: String {
        switch self {
        case .mild:
            return "yellow"
        case .moderate:
            return "orange"
        case .severe:
            return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .mild:
            return "exclamationmark.circle"
        case .moderate:
            return "exclamationmark.triangle"
        case .severe:
            return "exclamationmark.octagon"
        }
    }

    var numericValue: Int {
        switch self {
        case .mild:
            return 1
        case .moderate:
            return 2
        case .severe:
            return 3
        }
    }
}

enum ReactionSymptom: String, CaseIterable {
    case nausea = "Nausea"
    case bloating = "Bloating"
    case stomachPain = "Stomach Pain"
    case diarrhea = "Diarrhea"
    case constipation = "Constipation"
    case headache = "Headache"
    case fatigue = "Fatigue"
    case skinRash = "Skin Rash"
    case itching = "Itching"
    case difficulty_breathing = "Difficulty Breathing"
    case heartburn = "Heartburn"
    case dizziness = "Dizziness"
    
    var icon: String {
        switch self {
        case .nausea: return "face.dashed"
        case .bloating: return "circle.fill"
        case .stomachPain: return "hand.point.up.braille"
        case .diarrhea: return "drop.fill"
        case .constipation: return "timer"
        case .headache: return "brain.head.profile"
        case .fatigue: return "bed.double.fill"
        case .skinRash: return "allergens"
        case .itching: return "hand.raised.fingers.spread"
        case .difficulty_breathing: return "lungs.fill"
        case .heartburn: return "heart.fill"
        case .dizziness: return "gyroscope"
        }
    }
}

enum ActivityLevel: String, CaseIterable {
        case sedentary = "sedentary"
        case lightlyActive = "lightlyActive"
        case moderatelyActive = "moderatelyActive"
        case veryActive = "veryActive"
        case extremelyActive = "extremelyActive"
    }

struct DietaryGoals {
        let dailyCalories: Int
        let proteinPercentage: Double
        let carbsPercentage: Double
        let fatPercentage: Double
        let waterIntake: Double // litres
    }

enum ProcessingLevel: String, CaseIterable {
    case unprocessed = "Unprocessed"           // Fresh fruits, vegetables, raw meat, plain water
    case minimally = "Minimally Processed"     // Frozen vegetables, plain yoghurt, tinned beans
    case processed = "Processed"               // Bread, cheese, tinned fruit in syrup
    case ultraProcessed = "Ultra-Processed"    // Ready meals, fizzy drinks, crisps, biscuits
    
    var score: Int {
        switch self {
        case .unprocessed: return 100
        case .minimally: return 80
        case .processed: return 50
        case .ultraProcessed: return 10
        }
    }
}

enum GICategory: String, CaseIterable {
    case low = "Low GI"
    case medium = "Medium GI" 
    case high = "High GI"
    case unknown = "GI Unknown"
    
    var range: String {
        switch self {
        case .low: return "< 55"
        case .medium: return "55-70"
        case .high: return "> 70"
        case .unknown: return "N/A"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .unknown: return .gray
        }
    }
    
    var description: String {
        switch self {
        case .low: return "Slow glucose release - good for blood sugar control"
        case .medium: return "Moderate glucose release - consume mindfully"
        case .high: return "Rapid glucose release - limit portion size"
        case .unknown: return "GI data not available for this food"
        }
    }
}

struct GlycemicIndexData {
    let value: Int?  // nil if unknown
    let category: GICategory
    let servingSize: String
    let carbsPer100g: Double
    let isEstimated: Bool
    
    func calculateGIImpact(servingGrams: Double, carbsInServing: Double) -> Double? {
        guard let giValue = value, carbsInServing > 0 else { return nil }
        
        // Calculate GL (Glycemic Load) = (GI × carbs in serving) / 100
        let glycemicLoad = (Double(giValue) * carbsInServing) / 100.0
        return glycemicLoad
    }
}

class GlycemicIndexDatabase {
    static let shared = GlycemicIndexDatabase()
    
    private init() {}
    
    // Calculate GI based on macronutrient profile - MUCH more accurate and scalable
    func calculateGIFromMacros(carbs: Double, sugar: Double, fiber: Double, protein: Double, fat: Double) -> GlycemicIndexData {
        
        // SCIENTIFIC APPROACH: GI estimation based on macronutrient composition
        
        // Base GI calculation
        var estimatedGI: Int
        
        // 1. If very low carbs (< 5g), GI is effectively zero
        if carbs < 5.0 {
            estimatedGI = 0
        } 
        // 2. High sugar content = higher GI
        else if sugar > (carbs * 0.7) { // >70% of carbs are sugar
            estimatedGI = 75 // High GI (like white bread, candy)
        }
        // 3. High fiber significantly lowers GI
        else if fiber > (carbs * 0.3) { // >30% of carbs are fiber
            estimatedGI = 35 // Low GI (like beans, vegetables)
        }
        // 4. Protein and fat slow absorption
        else if (protein + fat) > carbs {
            estimatedGI = 30 // Low GI (like nuts, meat)
        }
        // 5. Medium sugar with some fiber
        else if sugar > (carbs * 0.4) && fiber > (carbs * 0.1) {
            estimatedGI = 55 // Medium GI (like fruits)
        }
        // 6. Complex carbs with moderate fiber
        else if fiber > (carbs * 0.15) {
            estimatedGI = 50 // Medium GI (like whole grains)
        }
        // 7. Refined carbs with little fiber
        else {
            estimatedGI = 70 // High GI (like white rice, pasta)
        }
        
        let category = calculateGICategory(from: estimatedGI)
        
        return GlycemicIndexData(
            value: estimatedGI,
            category: category,
            servingSize: "per serving",
            carbsPer100g: carbs,
            isEstimated: true // Always mark calculated GI as estimated
        )
    }
    
    // For backward compatibility - now calculates based on macros if available
    func getGIData(for foodName: String, carbs: Double? = nil, sugar: Double? = nil, fiber: Double? = nil, protein: Double? = nil, fat: Double? = nil) -> GlycemicIndexData? {
        
        // If we have macro data, calculate GI scientifically
        if let c = carbs, let s = sugar, let f = fiber, let p = protein, let ft = fat {
            return calculateGIFromMacros(carbs: c, sugar: s, fiber: f, protein: p, fat: ft)
        }
        
        // Fallback: return unknown for foods without macro data
        return GlycemicIndexData(
            value: nil,
            category: .unknown,
            servingSize: "N/A",
            carbsPer100g: 0.0,
            isEstimated: false
        )
    }
    
    func calculateGICategory(from value: Int) -> GICategory {
        switch value {
        case 0..<55:
            return .low
        case 55...70:
            return .medium
        default:
            return .high
        }
    }
}

enum VerificationStatus: String, Codable, CaseIterable {
        case pending = "pending"
        case approved = "approved"
        case rejected = "rejected"
    }

struct ProcessingCategoryBreakdown {
    let count: Int
    let score: Int
    let details: [String]
}

struct PersonalRecord: Codable {
    let exerciseName: String
    let bestWeight: Double
    let bestReps: Int
    let bestVolume: Double
    let achievedDate: Date
    
    init(exerciseName: String, weight: Double, reps: Int, volume: Double) {
        self.exerciseName = exerciseName
        self.bestWeight = weight
        self.bestReps = reps
        self.bestVolume = volume
        self.achievedDate = Date()
    }
}

enum Category: String, CaseIterable, Codable {
        case strength = "strength"
        case cardio = "cardio"
        case flexibility = "flexibility"
        case hiit = "hiit"
        
        var displayName: String {
            switch self {
            case .strength: return "Strength"
            case .cardio: return "Cardio"
            case .flexibility: return "Flexibility"
            case .hiit: return "HIIT"
            }
        }
    }

enum Difficulty: String, CaseIterable, Codable {
        case beginner = "beginner"
        case intermediate = "intermediate"
        case advanced = "advanced"
        
        var displayName: String {
            switch self {
            case .beginner: return "Beginner"
            case .intermediate: return "Intermediate"
            case .advanced: return "Advanced"
            }
        }
    }

enum Equipment: String, CaseIterable, Codable {
    case barbell = "Barbell"
    case dumbbell = "Dumbbell"
    case cable = "Cable"
    case machine = "Machine"
    case bodyweight = "Bodyweight"
    case kettlebell = "Kettlebell"
    case resistance_band = "Resistance Band"
    case cardio_machine = "Cardio Machine"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .barbell: return "barbell"
        case .dumbbell: return "dumbbell"
        case .cable: return "cable.connector"
        case .machine: return "gear"
        case .bodyweight: return "figure.strengthtraining.traditional"
        case .kettlebell: return "figure.strengthtraining.functional"
        case .resistance_band: return "bandage"
        case .cardio_machine: return "figure.run"
        case .other: return "questionmark"
        }
    }
}

struct WaterEntry: Codable, Identifiable {
    let id: UUID
    let amount: Int
    let timestamp: Date

    init(amount: Int, timestamp: Date = Date()) {
        self.id = UUID()
        self.amount = amount
        self.timestamp = timestamp
    }
}

class DiaryDataManager: ObservableObject {
    static let shared = DiaryDataManager()
    
    private init() {}
    
    // Date-based keys for UserDefaults
    private func keyForDate(_ date: Date, type: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(type)_\(formatter.string(from: date))"
    }
    
    // Food data methods - NOW LOADS FROM FIREBASE (source of truth)
    func getFoodData(for date: Date) -> ([DiaryFoodItem], [DiaryFoodItem], [DiaryFoodItem], [DiaryFoodItem]) {
        // Return empty arrays initially - will be populated via async Firebase load
        // The calling view should use Task to call getFoodDataAsync instead
        return ([], [], [], [])
    }

    // New async method that loads from Firebase
    func getFoodDataAsync(for date: Date) async throws -> ([DiaryFoodItem], [DiaryFoodItem], [DiaryFoodItem], [DiaryFoodItem]) {
        // Load from Firebase (single source of truth)
        let foodEntries = try await FirebaseManager.shared.getFoodEntries(for: date)

        print("DiaryDataManager: Loaded \(foodEntries.count) food entries from Firebase for date \(date)")

        // Separate entries by meal type
        var breakfast: [DiaryFoodItem] = []
        var lunch: [DiaryFoodItem] = []
        var dinner: [DiaryFoodItem] = []
        var snacks: [DiaryFoodItem] = []

        for entry in foodEntries {
            let diaryItem = DiaryFoodItem.fromFoodEntry(entry)

            switch entry.mealType {
            case .breakfast:
                breakfast.append(diaryItem)
            case .lunch:
                lunch.append(diaryItem)
            case .dinner:
                dinner.append(diaryItem)
            case .snacks:
                snacks.append(diaryItem)
            }
        }

        print("DiaryDataManager: Separated into - Breakfast: \(breakfast.count), Lunch: \(lunch.count), Dinner: \(dinner.count), Snacks: \(snacks.count)")

        return (breakfast, lunch, dinner, snacks)
    }
    
    func saveFoodData(for date: Date, breakfast: [DiaryFoodItem], lunch: [DiaryFoodItem], dinner: [DiaryFoodItem], snacks: [DiaryFoodItem]) {
        print("DiaryDataManager: Saving food data for date \(date)")
        print("DiaryDataManager: Saving counts - Breakfast: \(breakfast.count), Lunch: \(lunch.count), Dinner: \(dinner.count), Snacks: \(snacks.count)")
        saveFoodItems(key: keyForDate(date, type: "breakfast"), items: breakfast)
        saveFoodItems(key: keyForDate(date, type: "lunch"), items: lunch)
        saveFoodItems(key: keyForDate(date, type: "dinner"), items: dinner)
        saveFoodItems(key: keyForDate(date, type: "snacks"), items: snacks)

        // Notify observers that data has changed
        DispatchQueue.main.async {
            self.objectWillChange.send()
            print("DiaryDataManager: Notified observers of data change")
        }
    }
    
    // Add a single food item to a specific meal
    func addFoodItem(_ item: DiaryFoodItem, to meal: String, for date: Date) {
        print("DiaryDataManager: Adding food item '\(item.name)' to meal '\(meal)' for date \(date)")
        let (breakfast, lunch, dinner, snacks) = getFoodData(for: date)
        print("DiaryDataManager: Current counts - Breakfast: \(breakfast.count), Lunch: \(lunch.count), Dinner: \(dinner.count), Snacks: \(snacks.count)")

        switch meal.lowercased() {
        case "breakfast":
            var updatedBreakfast = breakfast
            updatedBreakfast.append(item)
            print("DiaryDataManager: Adding to breakfast. New count: \(updatedBreakfast.count)")
            saveFoodData(for: date, breakfast: updatedBreakfast, lunch: lunch, dinner: dinner, snacks: snacks)
        case "lunch":
            var updatedLunch = lunch
            updatedLunch.append(item)
            print("DiaryDataManager: Adding to lunch. New count: \(updatedLunch.count)")
            saveFoodData(for: date, breakfast: breakfast, lunch: updatedLunch, dinner: dinner, snacks: snacks)
        case "dinner":
            var updatedDinner = dinner
            updatedDinner.append(item)
            print("DiaryDataManager: Adding to dinner. New count: \(updatedDinner.count)")
            saveFoodData(for: date, breakfast: breakfast, lunch: lunch, dinner: updatedDinner, snacks: snacks)
        case "snacks":
            var updatedSnacks = snacks
            updatedSnacks.append(item)
            print("DiaryDataManager: Adding to snacks. New count: \(updatedSnacks.count)")
            saveFoodData(for: date, breakfast: breakfast, lunch: lunch, dinner: dinner, snacks: updatedSnacks)
        default:
            print("DiaryDataManager: ERROR - Unknown meal type: \(meal)")
        }

        // Add to recent foods for quick access in search
        addToRecentFoods(item)

        // Sync to Firebase immediately
        syncFoodItemToFirebase(item, meal: meal, date: date)
    }

    // MARK: - Firebase Sync

    private func syncFoodItemToFirebase(_ item: DiaryFoodItem, meal: String, date: Date) {
        Task {
            do {
                // Get the current user ID from FirebaseManager
                guard let userId = FirebaseManager.shared.currentUser?.uid else {
                    print("DiaryDataManager: Cannot sync to Firebase - no user logged in")
                    return
                }

                // Convert meal string to MealType enum
                let mealType: MealType
                switch meal.lowercased() {
                case "breakfast": mealType = .breakfast
                case "lunch": mealType = .lunch
                case "dinner": mealType = .dinner
                case "snacks": mealType = .snacks
                default:
                    print("DiaryDataManager: Cannot sync to Firebase - invalid meal type: \(meal)")
                    return
                }

                // Convert DiaryFoodItem to FoodEntry
                let foodEntry = item.toFoodEntry(userId: userId, mealType: mealType, date: date)

                // Save to Firebase
                try await FirebaseManager.shared.saveFoodEntry(foodEntry)

                print("DiaryDataManager: Successfully synced '\(item.name)' to Firebase")
            } catch {
                print("DiaryDataManager: Failed to sync to Firebase: \(error.localizedDescription)")
            }
        }
    }
    
    // Workout data methods
    func getWorkoutData(for date: Date) -> [WorkoutSessionSummary] {
        let key = keyForDate(date, type: "workouts")
        return loadWorkouts(key: key)
    }
    
    func saveWorkoutData(for date: Date, workouts: [WorkoutSessionSummary]) {
        saveWorkouts(key: keyForDate(date, type: "workouts"), workouts: workouts)
    }
    
    // MARK: - Hydration Data Management
    func getHydrationData(for date: Date) -> (count: Int, entries: [WaterEntry]) {
        let countKey = keyForDate(date, type: "waterCount")
        let entriesKey = keyForDate(date, type: "waterEntries")
        
        let count = UserDefaults.standard.integer(forKey: countKey)
        
        guard let data = UserDefaults.standard.data(forKey: entriesKey),
              let entries = try? JSONDecoder().decode([WaterEntry].self, from: data) else {
            return (count, [])
        }
        
        return (count, entries)
    }
    
    func saveHydrationData(for date: Date, count: Int, entries: [WaterEntry]) {
        let countKey = keyForDate(date, type: "waterCount")
        let entriesKey = keyForDate(date, type: "waterEntries")
        
        UserDefaults.standard.set(count, forKey: countKey)
        
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: entriesKey)
        }
    }
    
    // Private helper methods
    private func loadFoodItems(key: String) -> [DiaryFoodItem] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? JSONDecoder().decode([DiaryFoodItem].self, from: data) else {
            return []
        }
        return items
    }
    
    private func saveFoodItems(key: String, items: [DiaryFoodItem]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    private func loadWorkouts(key: String) -> [WorkoutSessionSummary] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let workouts = try? JSONDecoder().decode([WorkoutSessionSummary].self, from: data) else {
            return []
        }
        return workouts
    }
    
    private func saveWorkouts(key: String, workouts: [WorkoutSessionSummary]) {
        if let data = try? JSONEncoder().encode(workouts) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    // MARK: - Recent Foods Tracking
    
    private let recentFoodsKey = "recentFoods"
    private let maxRecentFoods = 20
    
    func addToRecentFoods(_ item: DiaryFoodItem) {
        var recentFoods = getRecentFoods()
        
        // Remove if already exists to avoid duplicates (compare by name for same food)
        recentFoods.removeAll { $0.name.lowercased() == item.name.lowercased() }
        
        // Add to beginning
        recentFoods.insert(item, at: 0)
        
        // Keep only last 20
        if recentFoods.count > maxRecentFoods {
            recentFoods = Array(recentFoods.prefix(maxRecentFoods))
        }
        
        // Save to UserDefaults
        if let data = try? JSONEncoder().encode(recentFoods) {
            UserDefaults.standard.set(data, forKey: recentFoodsKey)
        }
    }
    
    func getRecentFoods() -> [DiaryFoodItem] {
        guard let data = UserDefaults.standard.data(forKey: recentFoodsKey),
              let recentFoods = try? JSONDecoder().decode([DiaryFoodItem].self, from: data) else {
            return []
        }
        return recentFoods
    }
}

enum MicronutrientDataSource: String, Codable {
    case packageLabel = "package_label"     // Direct from product label (rare but highest accuracy)
    case cofid = "cofid"                   // UK McCance & Widdowson CoFID database
    case usda = "usda"                     // USDA FoodData Central
    case openFoodFacts = "off"             // Open Food Facts database
    case recipeEstimate = "recipe_estimate" // Calculated from ingredients using QUID
    case estimated = "estimated"           // General estimation
    case userSubmitted = "user_submitted"   // User-provided data
}

struct RecipeDecomposition: Codable {
    let productName: String
    let ingredients: [IngredientMapping]
    let processingAdjustments: [ProcessingAdjustment]
    let totalMicronutrients: MicronutrientProfile
}

struct ProcessingAdjustment: Codable {
    let processingType: ProcessingType
    let nutrientRetention: [String: Double] // nutrient_name -> retention_factor
    let yieldFactor: Double // How much the food changes in weight
}

enum ProcessingType: String, Codable {
    case raw = "raw"
    case boiled = "boiled" 
    case fried = "fried"
    case baked = "baked"
    case steamed = "steamed"
    case grilled = "grilled"
    case dried = "dried"
    case fermented = "fermented"
    case pasteurized = "pasteurized"
    case canned = "canned"
    case frozen = "frozen"
}

enum MealType: String, CaseIterable, Codable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snacks = "snacks"

    var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snacks: return "Snacks"
        }
    }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "sunset.fill"
        case .snacks: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .indigo
        case .snacks: return .purple
        }
    }
}

