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

// MARK: - Use By Inventory Models
struct UseByInventoryItem: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let brand: String?
    let quantity: String
    let expiryDate: Date
    let addedDate: Date
    let barcode: String?
    let category: String?
    let imageURL: String?
    let notes: String?

    init(id: String = UUID().uuidString, name: String, brand: String? = nil,
         quantity: String, expiryDate: Date, addedDate: Date,
         barcode: String? = nil, category: String? = nil, imageURL: String? = nil, notes: String? = nil) {
        self.id = id
        self.name = name
        self.brand = brand
        self.quantity = quantity
        self.expiryDate = expiryDate
        self.addedDate = addedDate
        self.barcode = barcode
        self.category = category
        self.imageURL = imageURL
        self.notes = notes
    }

    var daysUntilExpiry: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expiry = calendar.startOfDay(for: expiryDate)
        let components = calendar.dateComponents([.day], from: today, to: expiry)
        return components.day ?? 0
    }

    var expiryStatus: ExpiryStatus {
        switch daysUntilExpiry {
        case ...(-1): return .expired // Past the expiry date
        case 0: return .expiringToday // Expiring today
        case 1...3: return .expiringSoon // Expiring within 3 days
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
        case .expiringToday: return "Last Day"
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
        case .low: return "Slow glucose release (Low GI)"
        case .medium: return "Moderate glucose release (Medium GI)"
        case .high: return "Rapid glucose release (High GI)"
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

    @Published var dataReloadTrigger: UUID = UUID()

    // PERFORMANCE: Static DateFormatter to avoid recreation on every call
    // DateFormatter creation is expensive (~10ms per instance)
    private static let dateKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private init() {}

    // Date-based keys for UserDefaults
    private func keyForDate(_ date: Date, type: String) -> String {
        return "\(type)_\(Self.dateKeyFormatter.string(from: date))"
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
    
    func saveFoodData(for date: Date, breakfast: [DiaryFoodItem], lunch: [DiaryFoodItem], dinner: [DiaryFoodItem], snacks: [DiaryFoodItem], triggerReload: Bool = true) {
        print("DiaryDataManager: Saving food data for date \(date)")
        print("DiaryDataManager: Saving counts - Breakfast: \(breakfast.count), Lunch: \(lunch.count), Dinner: \(dinner.count), Snacks: \(snacks.count)")
        saveFoodItems(key: keyForDate(date, type: "breakfast"), items: breakfast)
        saveFoodItems(key: keyForDate(date, type: "lunch"), items: lunch)
        saveFoodItems(key: keyForDate(date, type: "dinner"), items: dinner)
        saveFoodItems(key: keyForDate(date, type: "snacks"), items: snacks)

        // Notify observers that data has changed and trigger UI reloads
        if triggerReload {
            DispatchQueue.main.async {
                self.objectWillChange.send()
                self.dataReloadTrigger = UUID()
                print("DiaryDataManager: Notified observers and triggered dataReloadTrigger")
            }
        }
    }
    
    // Add a single food item to a specific meal
    func addFoodItem(_ item: DiaryFoodItem, to meal: String, for date: Date) async {
        print("DiaryDataManager: Adding food item '\(item.name)' to meal '\(meal)' for date \(date)")

        // Create item with correct meal time (time property is immutable, so we need a new instance)
        let itemWithCorrectTime = DiaryFoodItem(
            id: item.id,
            name: item.name,
            brand: item.brand,
            calories: item.calories,
            protein: item.protein,
            carbs: item.carbs,
            fat: item.fat,
            fiber: item.fiber,
            sugar: item.sugar,
            sodium: item.sodium,
            calcium: item.calcium,
            servingDescription: item.servingDescription,
            quantity: item.quantity,
            time: meal,  // Set time to match the meal being added to
            processedScore: item.processedScore,
            sugarLevel: item.sugarLevel,
            ingredients: item.ingredients,
            additives: item.additives,
            barcode: item.barcode,
            micronutrientProfile: item.micronutrientProfile,
            isPerUnit: item.isPerUnit
        )

        do {
            // Load current data from Firebase (single source of truth)
            let (breakfast, lunch, dinner, snacks) = try await getFoodDataAsync(for: date)
            print("DiaryDataManager: Loaded current counts from Firebase - Breakfast: \(breakfast.count), Lunch: \(lunch.count), Dinner: \(dinner.count), Snacks: \(snacks.count)")

            // Helper function to check if an item matches (same food)
            func itemMatches(_ existingItem: DiaryFoodItem) -> Bool {
                // Match by barcode first (most reliable)
                if let barcode = itemWithCorrectTime.barcode, !barcode.isEmpty,
                   let existingBarcode = existingItem.barcode, !existingBarcode.isEmpty {
                    return barcode == existingBarcode
                }

                // Otherwise match by name and brand
                let nameMatches = existingItem.name.lowercased() == itemWithCorrectTime.name.lowercased()
                let brandMatches = (existingItem.brand?.lowercased() ?? "") == (itemWithCorrectTime.brand?.lowercased() ?? "")
                return nameMatches && brandMatches
            }

            // Helper function to update or append item
            func updateOrAppend(items: [DiaryFoodItem]) -> [DiaryFoodItem] {
                var updated = items
                if let index = updated.firstIndex(where: itemMatches) {
                    // Food already exists - replace it with fresh data while preserving user-specific fields
                    let updatedItem = DiaryFoodItem(
                        id: updated[index].id,  // Keep the original ID
                        name: itemWithCorrectTime.name,
                        brand: itemWithCorrectTime.brand,
                        calories: itemWithCorrectTime.calories,
                        protein: itemWithCorrectTime.protein,
                        carbs: itemWithCorrectTime.carbs,
                        fat: itemWithCorrectTime.fat,
                        fiber: itemWithCorrectTime.fiber,
                        sugar: itemWithCorrectTime.sugar,
                        sodium: itemWithCorrectTime.sodium,
                        calcium: itemWithCorrectTime.calcium,
                        servingDescription: itemWithCorrectTime.servingDescription,
                        quantity: itemWithCorrectTime.quantity,
                        time: itemWithCorrectTime.time,
                        processedScore: itemWithCorrectTime.processedScore,
                        sugarLevel: itemWithCorrectTime.sugarLevel,
                        ingredients: itemWithCorrectTime.ingredients,
                        additives: itemWithCorrectTime.additives,
                        barcode: itemWithCorrectTime.barcode,
                        micronutrientProfile: itemWithCorrectTime.micronutrientProfile,
                        isPerUnit: itemWithCorrectTime.isPerUnit
                    )
                    updated[index] = updatedItem
                    print("DiaryDataManager: ✨ Updated existing food '\(itemWithCorrectTime.name)' with fresh data (ID: \(updatedItem.id))")
                    return updated
                } else {
                    // New food - append it
                    updated.append(itemWithCorrectTime)
                    print("DiaryDataManager: ➕ Added new food '\(itemWithCorrectTime.name)' to meal")
                    return updated
                }
            }

            // Update or append item to appropriate meal
            switch meal.lowercased() {
            case "breakfast":
                let updatedBreakfast = updateOrAppend(items: breakfast)
                print("DiaryDataManager: Breakfast count: \(updatedBreakfast.count)")
                saveFoodData(for: date, breakfast: updatedBreakfast, lunch: lunch, dinner: dinner, snacks: snacks, triggerReload: false)
            case "lunch":
                let updatedLunch = updateOrAppend(items: lunch)
                print("DiaryDataManager: Lunch count: \(updatedLunch.count)")
                saveFoodData(for: date, breakfast: breakfast, lunch: updatedLunch, dinner: dinner, snacks: snacks, triggerReload: false)
            case "dinner":
                let updatedDinner = updateOrAppend(items: dinner)
                print("DiaryDataManager: Dinner count: \(updatedDinner.count)")
                saveFoodData(for: date, breakfast: breakfast, lunch: lunch, dinner: updatedDinner, snacks: snacks, triggerReload: false)
            case "snacks":
                let updatedSnacks = updateOrAppend(items: snacks)
                print("DiaryDataManager: Snacks count: \(updatedSnacks.count)")
                saveFoodData(for: date, breakfast: breakfast, lunch: lunch, dinner: dinner, snacks: updatedSnacks, triggerReload: false)
            default:
                print("DiaryDataManager: ERROR - Unknown meal type: \(meal)")
            }

            // Add to recent foods for quick access in search
            await MainActor.run {
                addToRecentFoods(item)
            }

            // Sync to Firebase and wait for it to complete
            await syncFoodItemToFirebase(item, meal: meal, date: date)

            // Process micronutrients for this food item
            await processMicronutrientsForFood(item, date: date)

            // Notify observers that data changed (triggers DiaryTabView to refresh)
            await MainActor.run {
                self.objectWillChange.send()
                self.dataReloadTrigger = UUID() // Trigger DiaryTabView to reload from Firebase
            }

        } catch {
            print("DiaryDataManager: Error loading current data from Firebase: \(error.localizedDescription)")
            // Fallback: just sync to Firebase
            await syncFoodItemToFirebase(item, meal: meal, date: date)
            await MainActor.run {
                addToRecentFoods(item)
                self.objectWillChange.send()
                self.dataReloadTrigger = UUID()
            }
        }
    }

    // Replace an existing food item in the diary (used when enhancing from diary)
    func replaceFoodItem(_ item: DiaryFoodItem, to meal: String, for date: Date) async throws {
        print("DiaryDataManager: Replacing food item '\(item.name)' (ID: \(item.id)) in meal '\(meal)' for date \(date)")

        // Load current data from Firebase (single source of truth)
        let (breakfast, lunch, dinner, snacks) = try await getFoodDataAsync(for: date)
        print("DiaryDataManager: Loaded current counts from Firebase - Breakfast: \(breakfast.count), Lunch: \(lunch.count), Dinner: \(dinner.count), Snacks: \(snacks.count)")

        // Replace existing item in appropriate meal
        var updatedBreakfast = breakfast
        var updatedLunch = lunch
        var updatedDinner = dinner
        var updatedSnacks = snacks

        switch meal.lowercased() {
        case "breakfast":
            if let index = updatedBreakfast.firstIndex(where: { $0.id == item.id }) {
                updatedBreakfast[index] = item
                print("DiaryDataManager: Replaced in breakfast at index \(index)")
            } else {
                print("DiaryDataManager: WARNING - Item not found in breakfast, appending instead")
                updatedBreakfast.append(item)
            }
        case "lunch":
            if let index = updatedLunch.firstIndex(where: { $0.id == item.id }) {
                updatedLunch[index] = item
                print("DiaryDataManager: Replaced in lunch at index \(index)")
            } else {
                print("DiaryDataManager: WARNING - Item not found in lunch, appending instead")
                updatedLunch.append(item)
            }
        case "dinner":
            if let index = updatedDinner.firstIndex(where: { $0.id == item.id }) {
                updatedDinner[index] = item
                print("DiaryDataManager: Replaced in dinner at index \(index)")
            } else {
                print("DiaryDataManager: WARNING - Item not found in dinner, appending instead")
                updatedDinner.append(item)
            }
        case "snacks":
            if let index = updatedSnacks.firstIndex(where: { $0.id == item.id }) {
                updatedSnacks[index] = item
                print("DiaryDataManager: Replaced in snacks at index \(index)")
            } else {
                print("DiaryDataManager: WARNING - Item not found in snacks, appending instead")
                updatedSnacks.append(item)
            }
        default:
            print("DiaryDataManager: ERROR - Unknown meal type: \(meal)")
        }

        // Save locally (don't trigger reload yet - wait for Firebase first)
        saveFoodData(for: date, breakfast: updatedBreakfast, lunch: updatedLunch, dinner: updatedDinner, snacks: updatedSnacks, triggerReload: false)

        // Add to recent foods for quick access in search
        await MainActor.run {
            addToRecentFoods(item)
        }

        // FIX: Sync to Firebase and WAIT for it to complete before triggering reload
        // This ensures loadFoodData() will fetch the updated data from Firebase
        await syncFoodItemToFirebase(item, meal: meal, date: date)

        // Process micronutrients for this food item
        await processMicronutrientsForFood(item, date: date)

        // NOW trigger the reload - Firebase has the updated data
        await MainActor.run {
            self.objectWillChange.send()
            self.dataReloadTrigger = UUID()
        }

        print("DiaryDataManager: Successfully completed replacing '\(item.name)'")
    }

    // Move an existing food item from one meal to another for a given date
    func moveFoodItem(_ item: DiaryFoodItem, from originalMeal: String, to newMeal: String, for date: Date) async throws {
        print("DiaryDataManager: Moving food item '\(item.name)' (ID: \(item.id)) from '\(originalMeal)' to '\(newMeal)' for date \(date)")

        // Load current data from Firebase (single source of truth)
        let (breakfast, lunch, dinner, snacks) = try await getFoodDataAsync(for: date)
        print("DiaryDataManager: Loaded current counts from Firebase - Breakfast: \(breakfast.count), Lunch: \(lunch.count), Dinner: \(dinner.count), Snacks: \(snacks.count)")

        // Remove from original meal
        var updatedBreakfast = breakfast
        var updatedLunch = lunch
        var updatedDinner = dinner
        var updatedSnacks = snacks

        switch originalMeal.lowercased() {
        case "breakfast":
            updatedBreakfast.removeAll { $0.id == item.id }
            print("DiaryDataManager: Removed from breakfast if present")
        case "lunch":
            updatedLunch.removeAll { $0.id == item.id }
            print("DiaryDataManager: Removed from lunch if present")
        case "dinner":
            updatedDinner.removeAll { $0.id == item.id }
            print("DiaryDataManager: Removed from dinner if present")
        case "snacks":
            updatedSnacks.removeAll { $0.id == item.id }
            print("DiaryDataManager: Removed from snacks if present")
        default:
            print("DiaryDataManager: WARNING - Unknown original meal type: \(originalMeal)")
        }

        // Create updated item with new meal time
        let updatedItem = DiaryFoodItem(
            id: item.id,
            name: item.name,
            brand: item.brand,
            calories: item.calories,
            protein: item.protein,
            carbs: item.carbs,
            fat: item.fat,
            fiber: item.fiber,
            sugar: item.sugar,
            sodium: item.sodium,
            calcium: item.calcium,
            servingDescription: item.servingDescription,
            quantity: item.quantity,
            time: newMeal,  // Update time to reflect new meal
            processedScore: item.processedScore,
            sugarLevel: item.sugarLevel,
            ingredients: item.ingredients,
            additives: item.additives,
            barcode: item.barcode,
            micronutrientProfile: item.micronutrientProfile,
            isPerUnit: item.isPerUnit
        )

        // Add to new meal (replace if same id already exists, otherwise append)
        switch newMeal.lowercased() {
        case "breakfast":
            if let index = updatedBreakfast.firstIndex(where: { $0.id == item.id }) {
                updatedBreakfast[index] = updatedItem
                print("DiaryDataManager: Replaced in breakfast at index \(index)")
            } else {
                updatedBreakfast.append(updatedItem)
                print("DiaryDataManager: Appended to breakfast. New count: \(updatedBreakfast.count)")
            }
        case "lunch":
            if let index = updatedLunch.firstIndex(where: { $0.id == item.id }) {
                updatedLunch[index] = updatedItem
                print("DiaryDataManager: Replaced in lunch at index \(index)")
            } else {
                updatedLunch.append(updatedItem)
                print("DiaryDataManager: Appended to lunch. New count: \(updatedLunch.count)")
            }
        case "dinner":
            if let index = updatedDinner.firstIndex(where: { $0.id == item.id }) {
                updatedDinner[index] = updatedItem
                print("DiaryDataManager: Replaced in dinner at index \(index)")
            } else {
                updatedDinner.append(updatedItem)
                print("DiaryDataManager: Appended to dinner. New count: \(updatedDinner.count)")
            }
        case "snacks":
            if let index = updatedSnacks.firstIndex(where: { $0.id == item.id }) {
                updatedSnacks[index] = updatedItem
                print("DiaryDataManager: Replaced in snacks at index \(index)")
            } else {
                updatedSnacks.append(updatedItem)
                print("DiaryDataManager: Appended to snacks. New count: \(updatedSnacks.count)")
            }
        default:
            print("DiaryDataManager: ERROR - Unknown new meal type: \(newMeal)")
        }

        // Save locally (don't trigger reload yet - wait for Firebase first)
        saveFoodData(for: date, breakfast: updatedBreakfast, lunch: updatedLunch, dinner: updatedDinner, snacks: updatedSnacks, triggerReload: false)

        // Add to recent foods for quick access in search
        await MainActor.run {
            addToRecentFoods(item)
        }

        // FIX: Sync to Firebase and WAIT for it to complete before triggering reload
        // This ensures loadFoodData() will fetch the updated data from Firebase
        await syncFoodItemToFirebase(item, meal: newMeal, date: date)

        // Process micronutrients for this food item
        await processMicronutrientsForFood(item, date: date)

        // NOW trigger the reload - Firebase has the updated data
        await MainActor.run {
            self.objectWillChange.send()
            self.dataReloadTrigger = UUID()
        }

        print("DiaryDataManager: Successfully completed moving '\(item.name)' to \(newMeal)")
    }

    // Delete food items from both local storage and Firebase
    // Uses batch delete for atomic operations and better performance
    func deleteFoodItems(_ items: [DiaryFoodItem], for date: Date) {
        Task {
            print("DiaryDataManager: Deleting \(items.count) food items from Firebase")

            // Collect all entry IDs for batch delete
            let entryIds = items.map { $0.id.uuidString }

            do {
                // Use batch delete for atomic operation and better performance
                try await FirebaseManager.shared.deleteFoodEntries(entryIds: entryIds)
                print("DiaryDataManager: Successfully deleted \(items.count) items from Firebase")
            } catch {
                print("DiaryDataManager: Error batch deleting items from Firebase: \(error.localizedDescription)")
                // Fallback: try deleting one by one
                for item in items {
                    do {
                        try await FirebaseManager.shared.deleteFoodEntry(entryId: item.id.uuidString)
                        print("DiaryDataManager: Deleted item '\(item.name)' from Firebase")
                    } catch {
                        print("DiaryDataManager: Error deleting item '\(item.name)' from Firebase: \(error.localizedDescription)")
                    }
                }
            }

            // Trigger reload after deletion
            await MainActor.run {
                self.dataReloadTrigger = UUID()
            }
        }
    }

    // MARK: - Firebase Sync

    private func syncFoodItemToFirebase(_ item: DiaryFoodItem, meal: String, date: Date) async {
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

    // MARK: - Micronutrient Processing

    private func processMicronutrientsForFood(_ item: DiaryFoodItem, date: Date) async {

        // Check if the food has a micronutrient profile with actual data
        if let profile = item.micronutrientProfile {
            print("  📊 Found micronutrient profile with \(profile.vitamins.count) vitamins and \(profile.minerals.count) minerals")

            // Process actual nutrient data
            Task { @MainActor in
                await MicronutrientTrackingManager.shared.processNutrientProfile(
                    profile,
                    foodName: item.name,
                    servingSize: item.quantity,
                    date: date
                )
            }
        } else {
            // Fallback: Extract ingredients and use keyword-based detection
            print("  ⚠️ No micronutrient profile found, falling back to ingredient analysis")
            let ingredients = item.ingredients ?? []

            Task { @MainActor in
                await MicronutrientTrackingManager.shared.processFoodLog(
                    name: item.name,
                    ingredients: ingredients,
                    date: date
                )
            }
        }

        print("✅ Micronutrient processing queued for: \(item.name)")
    }

    // MARK: - Reaction Log Support

    /// Fetches all meals (as FoodEntry objects) within a specific time range for reaction analysis
    /// - Parameters:
    ///   - from: Start of time range
    ///   - to: End of time range
    /// - Returns: Array of FoodEntry objects that fall within the time range
    func getMealsInTimeRange(from startDate: Date, to endDate: Date) async throws -> [FoodEntry] {
        guard let userId = FirebaseManager.shared.currentUser?.uid else {
            throw NSError(domain: "DiaryDataManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }

        print("DiaryDataManager: Fetching meals from \(startDate) to \(endDate)")

        // Use Firebase to query food entries within the date range
        let entries = try await FirebaseManager.shared.getFoodEntriesInRange(userId: userId, startDate: startDate, endDate: endDate)

        print("DiaryDataManager: Found \(entries.count) food entries in time range")

        return entries
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

// MARK: - Weekly Summary Models

struct WeeklySummary {
    let weekStartDate: Date  // Monday of the week
    let weekEndDate: Date    // Sunday of the week
    let totalCalories: Int
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let dailyBreakdowns: [DailyBreakdown]

    var averageCalories: Int {
        let daysLogged = dailyBreakdowns.filter { $0.isLogged }.count
        return daysLogged > 0 ? totalCalories / daysLogged : 0
    }

    var daysLogged: Int {
        dailyBreakdowns.filter { $0.isLogged }.count
    }
}

struct DailyBreakdown: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let isLogged: Bool

    var dayName: String {
        // PERFORMANCE: Use cached static formatter instead of creating new one
        DateHelper.fullDayOfWeekFormatter.string(from: date)
    }

    var shortDateString: String {
        // PERFORMANCE: Use cached static formatter instead of creating new one
        DateHelper.monthDayFormatter.string(from: date)
    }
}

// MARK: - Macro Management Models

enum MacroType: String, CaseIterable, Codable {
    case protein = "protein"
    case carbs = "carbs"
    case fat = "fat"
    case fiber = "fiber"
    case sugar = "sugar"
    case salt = "salt"
    case saturatedFat = "saturatedFat"

    var displayName: String {
        switch self {
        case .protein: return "Protein"
        case .carbs: return "Carbs"
        case .fat: return "Fat"
        case .fiber: return "Fibre"
        case .sugar: return "Sugar"
        case .salt: return "Salt"
        case .saturatedFat: return "Saturated Fat"
        }
    }

    var unit: String {
        return "g" // All macros in grams now
    }

    var color: Color {
        switch self {
        case .protein: return Color(.systemRed)
        case .carbs: return Color(.systemOrange)
        case .fat: return Color(.systemYellow)
        case .fiber: return Color(.systemGreen)
        case .sugar: return Color(.systemPink)
        case .salt: return Color(.systemBlue)
        case .saturatedFat: return Color(.systemPurple)
        }
    }

    var caloriesPerGram: Double {
        switch self {
        case .protein: return 4.0
        case .carbs: return 4.0
        case .fat: return 9.0
        case .saturatedFat: return 9.0
        case .fiber, .sugar, .salt: return 0.0 // Non-caloric macros
        }
    }

    var isCaloric: Bool {
        return caloriesPerGram > 0
    }

    var isCoreMacro: Bool {
        return self == .protein || self == .carbs || self == .fat
    }

    // Get value from DiaryFoodItem
    func getValue(from item: DiaryFoodItem) -> Double {
        switch self {
        case .protein: return item.protein
        case .carbs: return item.carbs
        case .fat: return item.fat
        case .fiber: return item.fiber
        case .sugar: return item.sugar
        case .salt: return item.sodium / 1000.0 // Convert mg to g
        case .saturatedFat: return 0.0 // Not currently tracked in DiaryFoodItem
        }
    }

    // Available extra macros (user picks one of these)
    static var extraMacros: [MacroType] {
        return [.fiber, .sugar, .salt]
    }
}

struct MacroGoal: Codable, Identifiable {
    var id: String { macroType.rawValue }
    let macroType: MacroType
    let percentage: Int?       // For core macros (P/C/F) - percentage of calories
    let directTarget: Double?  // For extra macro - direct gram target

    // Init for core macros (percentage-based)
    init(macroType: MacroType, percentage: Int) {
        self.macroType = macroType
        self.percentage = percentage
        self.directTarget = nil
    }

    // Init for extra macro (direct target in grams)
    init(macroType: MacroType, directTarget: Double) {
        self.macroType = macroType
        self.percentage = nil
        self.directTarget = directTarget
    }

    // Calculate gram goal based on calorie goal
    func calculateGramGoal(from calorieGoal: Double) -> Double {
        // Core macros (P/C/F): calculate from percentage of calories
        if let percentage = percentage, macroType.isCoreMacro {
            let caloriesForMacro = calorieGoal * (Double(percentage) / 100.0)
            return caloriesForMacro / macroType.caloriesPerGram
        }

        // Extra macro: return direct target
        if let directTarget = directTarget {
            return directTarget
        }

        // Fallback (shouldn't reach here)
        return 0
    }
}

// Default macro configuration (protein/carbs/fat + fiber)
extension MacroGoal {
    static let defaultMacros: [MacroGoal] = [
        MacroGoal(macroType: .protein, percentage: 30),
        MacroGoal(macroType: .carbs, percentage: 40),
        MacroGoal(macroType: .fat, percentage: 30),
        MacroGoal(macroType: .fiber, directTarget: 30.0) // UK recommended daily fiber intake
    ]
}

// MARK: - Use By Data Manager
class UseByDataManager: ObservableObject {
    static let shared = UseByDataManager()

    @Published var items: [UseByInventoryItem] = []
    @Published var isLoading: Bool = false
    private var hasLoadedOnce: Bool = false

    var isLoaded: Bool { hasLoadedOnce }

    private init() {}

    func loadItems() async {
        // PERFORMANCE: Skip if already loaded
        guard !hasLoadedOnce else {
            print("⚡️ UseByDataManager: Skipping load - data already cached (count: \(items.count))")
            return
        }

        await MainActor.run { self.isLoading = true }

        do {
            let loadedItems: [UseByInventoryItem] = try await FirebaseManager.shared.getUseByItems()
            await MainActor.run {
                self.items = loadedItems
                self.hasLoadedOnce = true
                self.isLoading = false
                print("✅ UseByDataManager: Loaded \(loadedItems.count) items from Firebase")
            }
        } catch {
            await MainActor.run {
                self.items = []
                self.isLoading = false
                print("❌ UseByDataManager: Error loading items: \(error)")
            }
        }
    }

    func forceReload() async {
        hasLoadedOnce = false
        await loadItems()
    }
}
