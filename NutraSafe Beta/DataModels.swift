import Foundation
import Firebase

// MARK: - User Profile
struct UserProfile {
    let userId: String
    let name: String
    let email: String?
    let dateOfBirth: Date?
    let height: Double? // cm
    let weight: Double? // kg
    let activityLevel: ActivityLevel
    let dietaryGoals: DietaryGoals
    let allergies: [String]
    let medicalConditions: [String]
    let dateCreated: Date
    let lastUpdated: Date
    
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
    
    func toDictionary() -> [String: Any] {
        return [
            "userId": userId,
            "name": name,
            "email": email ?? "",
            "dateOfBirth": dateOfBirth != nil ? Timestamp(date: dateOfBirth!) : NSNull(),
            "height": height ?? NSNull(),
            "weight": weight ?? NSNull(),
            "activityLevel": activityLevel.rawValue,
            "dietaryGoals": [
                "dailyCalories": dietaryGoals.dailyCalories,
                "proteinPercentage": dietaryGoals.proteinPercentage,
                "carbsPercentage": dietaryGoals.carbsPercentage,
                "fatPercentage": dietaryGoals.fatPercentage,
                "waterIntake": dietaryGoals.waterIntake
            ],
            "allergies": allergies,
            "medicalConditions": medicalConditions,
            "dateCreated": Timestamp(date: dateCreated),
            "lastUpdated": Timestamp(date: lastUpdated)
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> UserProfile? {
        guard let userId = data["userId"] as? String,
              let name = data["name"] as? String,
              let activityLevelRaw = data["activityLevel"] as? String,
              let activityLevel = ActivityLevel(rawValue: activityLevelRaw),
              let goalsData = data["dietaryGoals"] as? [String: Any],
              let dailyCalories = goalsData["dailyCalories"] as? Int,
              let proteinPercentage = goalsData["proteinPercentage"] as? Double,
              let carbsPercentage = goalsData["carbsPercentage"] as? Double,
              let fatPercentage = goalsData["fatPercentage"] as? Double,
              let waterIntake = goalsData["waterIntake"] as? Double,
              let allergies = data["allergies"] as? [String],
              let medicalConditions = data["medicalConditions"] as? [String],
              let dateCreatedTimestamp = data["dateCreated"] as? Timestamp,
              let lastUpdatedTimestamp = data["lastUpdated"] as? Timestamp else {
            return nil
        }
        
        let email = data["email"] as? String
        let height = data["height"] as? Double
        let weight = data["weight"] as? Double
        let dateOfBirth = (data["dateOfBirth"] as? Timestamp)?.dateValue()
        
        let dietaryGoals = DietaryGoals(
            dailyCalories: dailyCalories,
            proteinPercentage: proteinPercentage,
            carbsPercentage: carbsPercentage,
            fatPercentage: fatPercentage,
            waterIntake: waterIntake
        )
        
        return UserProfile(
            userId: userId,
            name: name,
            email: email,
            dateOfBirth: dateOfBirth,
            height: height,
            weight: weight,
            activityLevel: activityLevel,
            dietaryGoals: dietaryGoals,
            allergies: allergies,
            medicalConditions: medicalConditions,
            dateCreated: dateCreatedTimestamp.dateValue(),
            lastUpdated: lastUpdatedTimestamp.dateValue()
        )
    }
}

// MARK: - Food Entry
struct FoodEntry {
    let id: String
    let userId: String
    let foodName: String
    let brandName: String?
    let servingSize: Double
    let servingUnit: String
    let calories: Double
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let fiber: Double?
    let sugar: Double?
    let sodium: Double?
    let mealType: MealType
    let date: Date
    let dateLogged: Date
    
    enum MealType: String, CaseIterable {
        case breakfast = "breakfast"
        case lunch = "lunch"
        case dinner = "dinner"
        case snacks = "snacks"
    }
    
    init(userId: String, foodName: String, brandName: String? = nil, 
         servingSize: Double, servingUnit: String, calories: Double, 
         protein: Double, carbohydrates: Double, fat: Double, 
         fiber: Double? = nil, sugar: Double? = nil, sodium: Double? = nil,
         mealType: MealType, date: Date) {
        self.id = UUID().uuidString
        self.userId = userId
        self.foodName = foodName
        self.brandName = brandName
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.mealType = mealType
        self.date = date
        self.dateLogged = Date()
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "foodName": foodName,
            "brandName": brandName ?? "",
            "servingSize": servingSize,
            "servingUnit": servingUnit,
            "calories": calories,
            "protein": protein,
            "carbohydrates": carbohydrates,
            "fat": fat,
            "fiber": fiber ?? NSNull(),
            "sugar": sugar ?? NSNull(),
            "sodium": sodium ?? NSNull(),
            "mealType": mealType.rawValue,
            "date": Timestamp(date: date),
            "dateLogged": Timestamp(date: dateLogged)
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> FoodEntry? {
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let foodName = data["foodName"] as? String,
              let servingSize = data["servingSize"] as? Double,
              let servingUnit = data["servingUnit"] as? String,
              let calories = data["calories"] as? Double,
              let protein = data["protein"] as? Double,
              let carbohydrates = data["carbohydrates"] as? Double,
              let fat = data["fat"] as? Double,
              let mealTypeRaw = data["mealType"] as? String,
              let mealType = MealType(rawValue: mealTypeRaw),
              let dateTimestamp = data["date"] as? Timestamp,
              let dateLoggedTimestamp = data["dateLogged"] as? Timestamp else {
            return nil
        }
        
        let brandName = data["brandName"] as? String
        let fiber = data["fiber"] as? Double
        let sugar = data["sugar"] as? Double
        let sodium = data["sodium"] as? Double
        
        var entry = FoodEntry(
            userId: userId,
            foodName: foodName,
            brandName: brandName,
            servingSize: servingSize,
            servingUnit: servingUnit,
            calories: calories,
            protein: protein,
            carbohydrates: carbohydrates,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            mealType: mealType,
            date: dateTimestamp.dateValue()
        )
        
        // Override the generated values with stored ones
        return FoodEntry(
            id: id,
            userId: userId,
            foodName: foodName,
            brandName: brandName,
            servingSize: servingSize,
            servingUnit: servingUnit,
            calories: calories,
            protein: protein,
            carbohydrates: carbohydrates,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            mealType: mealType,
            date: dateTimestamp.dateValue(),
            dateLogged: dateLoggedTimestamp.dateValue()
        )
    }
}

extension FoodEntry {
    init(id: String, userId: String, foodName: String, brandName: String?, 
         servingSize: Double, servingUnit: String, calories: Double, 
         protein: Double, carbohydrates: Double, fat: Double, 
         fiber: Double?, sugar: Double?, sodium: Double?,
         mealType: MealType, date: Date, dateLogged: Date) {
        self.id = id
        self.userId = userId
        self.foodName = foodName
        self.brandName = brandName
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.mealType = mealType
        self.date = date
        self.dateLogged = dateLogged
    }
}

// MARK: - Food Reaction (Updated)
struct FoodReaction {
    let id: UUID
    let userId: String
    let food: String
    let symptoms: String
    let severity: Severity
    let date: Date
    let notes: String?
    
    enum Severity: String, CaseIterable {
        case mild = "mild"
        case moderate = "moderate"
        case severe = "severe"
        
        var color: String {
            switch self {
            case .mild: return "yellow"
            case .moderate: return "orange"
            case .severe: return "red"
            }
        }
    }
    
    init(userId: String, food: String, symptoms: String, severity: Severity, date: Date, notes: String? = nil) {
        self.id = UUID()
        self.userId = userId
        self.food = food
        self.symptoms = symptoms
        self.severity = severity
        self.date = date
        self.notes = notes
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "userId": userId,
            "food": food,
            "symptoms": symptoms,
            "severity": severity.rawValue,
            "date": Timestamp(date: date),
            "notes": notes ?? ""
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> FoodReaction? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let userId = data["userId"] as? String,
              let food = data["food"] as? String,
              let symptoms = data["symptoms"] as? String,
              let severityRaw = data["severity"] as? String,
              let severity = Severity(rawValue: severityRaw),
              let dateTimestamp = data["date"] as? Timestamp else {
            return nil
        }
        
        let notes = data["notes"] as? String
        
        return FoodReaction(
            userId: userId,
            food: food,
            symptoms: symptoms,
            severity: severity,
            date: dateTimestamp.dateValue(),
            notes: notes
        )
    }
}

// MARK: - Safe Food
struct SafeFood {
    let id: UUID
    let userId: String
    let name: String
    let category: String
    let dateAdded: Date
    let notes: String?
    let verified: Bool
    
    init(userId: String, name: String, category: String, notes: String? = nil, verified: Bool = false) {
        self.id = UUID()
        self.userId = userId
        self.name = name
        self.category = category
        self.dateAdded = Date()
        self.notes = notes
        self.verified = verified
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "userId": userId,
            "name": name,
            "category": category,
            "dateAdded": Timestamp(date: dateAdded),
            "notes": notes ?? "",
            "verified": verified
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> SafeFood? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let userId = data["userId"] as? String,
              let name = data["name"] as? String,
              let category = data["category"] as? String,
              let dateAddedTimestamp = data["dateAdded"] as? Timestamp,
              let verified = data["verified"] as? Bool else {
            return nil
        }
        
        let notes = data["notes"] as? String
        
        var safeFood = SafeFood(userId: userId, name: name, category: category, notes: notes, verified: verified)
        // Override the generated values
        return SafeFood(
            id: id,
            userId: userId,
            name: name,
            category: category,
            dateAdded: dateAddedTimestamp.dateValue(),
            notes: notes,
            verified: verified
        )
    }
}

extension SafeFood {
    init(id: UUID, userId: String, name: String, category: String, dateAdded: Date, notes: String?, verified: Bool) {
        self.id = id
        self.userId = userId
        self.name = name
        self.category = category
        self.dateAdded = dateAdded
        self.notes = notes
        self.verified = verified
    }
}

// MARK: - Kitchen Item
struct KitchenItem {
    let id: UUID
    let userId: String
    let name: String
    let category: String
    let location: StorageLocation
    let quantity: Double
    let unit: String
    let purchaseDate: Date
    let expiryDate: Date
    let estimatedValue: Double?
    let barcode: String?
    let dateAdded: Date
    
    enum StorageLocation: String, CaseIterable {
        case fridge = "fridge"
        case freezer = "freezer"
        case pantry = "pantry"
        case cupboard = "cupboard"
        
        var displayName: String {
            switch self {
            case .fridge: return "Fridge"
            case .freezer: return "Freezer"
            case .pantry: return "Pantry"
            case .cupboard: return "Cupboard"
            }
        }
    }
    
    init(userId: String, name: String, category: String, location: StorageLocation, 
         quantity: Double, unit: String, purchaseDate: Date, expiryDate: Date, 
         estimatedValue: Double? = nil, barcode: String? = nil) {
        self.id = UUID()
        self.userId = userId
        self.name = name
        self.category = category
        self.location = location
        self.quantity = quantity
        self.unit = unit
        self.purchaseDate = purchaseDate
        self.expiryDate = expiryDate
        self.estimatedValue = estimatedValue
        self.barcode = barcode
        self.dateAdded = Date()
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "userId": userId,
            "name": name,
            "category": category,
            "location": location.rawValue,
            "quantity": quantity,
            "unit": unit,
            "purchaseDate": Timestamp(date: purchaseDate),
            "expiryDate": Timestamp(date: expiryDate),
            "estimatedValue": estimatedValue ?? NSNull(),
            "barcode": barcode ?? "",
            "dateAdded": Timestamp(date: dateAdded)
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> KitchenItem? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let userId = data["userId"] as? String,
              let name = data["name"] as? String,
              let category = data["category"] as? String,
              let locationRaw = data["location"] as? String,
              let location = StorageLocation(rawValue: locationRaw),
              let quantity = data["quantity"] as? Double,
              let unit = data["unit"] as? String,
              let purchaseDateTimestamp = data["purchaseDate"] as? Timestamp,
              let expiryDateTimestamp = data["expiryDate"] as? Timestamp,
              let dateAddedTimestamp = data["dateAdded"] as? Timestamp else {
            return nil
        }
        
        let estimatedValue = data["estimatedValue"] as? Double
        let barcode = data["barcode"] as? String
        
        return KitchenItem(
            id: id,
            userId: userId,
            name: name,
            category: category,
            location: location,
            quantity: quantity,
            unit: unit,
            purchaseDate: purchaseDateTimestamp.dateValue(),
            expiryDate: expiryDateTimestamp.dateValue(),
            estimatedValue: estimatedValue,
            barcode: barcode,
            dateAdded: dateAddedTimestamp.dateValue()
        )
    }
}

extension KitchenItem {
    init(id: UUID, userId: String, name: String, category: String, location: StorageLocation, 
         quantity: Double, unit: String, purchaseDate: Date, expiryDate: Date, 
         estimatedValue: Double?, barcode: String?, dateAdded: Date) {
        self.id = id
        self.userId = userId
        self.name = name
        self.category = category
        self.location = location
        self.quantity = quantity
        self.unit = unit
        self.purchaseDate = purchaseDate
        self.expiryDate = expiryDate
        self.estimatedValue = estimatedValue
        self.barcode = barcode
        self.dateAdded = dateAdded
    }
}

// MARK: - Shopping List
struct ShoppingList {
    let id: UUID
    let userId: String
    let name: String
    let items: [ShoppingItem]
    let dateCreated: Date
    let lastUpdated: Date
    let isCompleted: Bool
    
    struct ShoppingItem {
        let id: UUID
        let name: String
        let category: String
        let quantity: Double?
        let unit: String?
        let isCompleted: Bool
        let dateAdded: Date
        
        init(name: String, category: String, quantity: Double? = nil, unit: String? = nil) {
            self.id = UUID()
            self.name = name
            self.category = category
            self.quantity = quantity
            self.unit = unit
            self.isCompleted = false
            self.dateAdded = Date()
        }
        
        func toDictionary() -> [String: Any] {
            return [
                "id": id.uuidString,
                "name": name,
                "category": category,
                "quantity": quantity ?? NSNull(),
                "unit": unit ?? "",
                "isCompleted": isCompleted,
                "dateAdded": Timestamp(date: dateAdded)
            ]
        }
        
        static func fromDictionary(_ data: [String: Any]) -> ShoppingItem? {
            guard let idString = data["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let name = data["name"] as? String,
                  let category = data["category"] as? String,
                  let isCompleted = data["isCompleted"] as? Bool,
                  let dateAddedTimestamp = data["dateAdded"] as? Timestamp else {
                return nil
            }
            
            let quantity = data["quantity"] as? Double
            let unit = data["unit"] as? String
            
            return ShoppingItem(
                id: id,
                name: name,
                category: category,
                quantity: quantity,
                unit: unit,
                isCompleted: isCompleted,
                dateAdded: dateAddedTimestamp.dateValue()
            )
        }
    }
    
    init(userId: String, name: String, items: [ShoppingItem] = []) {
        self.id = UUID()
        self.userId = userId
        self.name = name
        self.items = items
        self.dateCreated = Date()
        self.lastUpdated = Date()
        self.isCompleted = false
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "userId": userId,
            "name": name,
            "items": items.map { $0.toDictionary() },
            "dateCreated": Timestamp(date: dateCreated),
            "lastUpdated": Timestamp(date: lastUpdated),
            "isCompleted": isCompleted
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> ShoppingList? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let userId = data["userId"] as? String,
              let name = data["name"] as? String,
              let itemsData = data["items"] as? [[String: Any]],
              let dateCreatedTimestamp = data["dateCreated"] as? Timestamp,
              let lastUpdatedTimestamp = data["lastUpdated"] as? Timestamp,
              let isCompleted = data["isCompleted"] as? Bool else {
            return nil
        }
        
        let items = itemsData.compactMap { ShoppingItem.fromDictionary($0) }
        
        return ShoppingList(
            id: id,
            userId: userId,
            name: name,
            items: items,
            dateCreated: dateCreatedTimestamp.dateValue(),
            lastUpdated: lastUpdatedTimestamp.dateValue(),
            isCompleted: isCompleted
        )
    }
}

extension ShoppingList {
    init(id: UUID, userId: String, name: String, items: [ShoppingItem], 
         dateCreated: Date, lastUpdated: Date, isCompleted: Bool) {
        self.id = id
        self.userId = userId
        self.name = name
        self.items = items
        self.dateCreated = dateCreated
        self.lastUpdated = lastUpdated
        self.isCompleted = isCompleted
    }
}

extension ShoppingList.ShoppingItem {
    init(id: UUID, name: String, category: String, quantity: Double?, unit: String?, 
         isCompleted: Bool, dateAdded: Date) {
        self.id = id
        self.name = name
        self.category = category
        self.quantity = quantity
        self.unit = unit
        self.isCompleted = isCompleted
        self.dateAdded = dateAdded
    }
}

// MARK: - Exercise Entry
struct ExerciseEntry {
    let id: UUID
    let userId: String
    let exerciseName: String
    let category: ExerciseCategory
    let duration: Int // minutes
    let caloriesBurned: Double
    let intensity: Intensity
    let date: Date
    let notes: String?
    let dateLogged: Date
    
    enum ExerciseCategory: String, CaseIterable {
        case cardio = "cardio"
        case strength = "strength"
        case flexibility = "flexibility"
        case sports = "sports"
        case other = "other"
    }
    
    enum Intensity: String, CaseIterable {
        case low = "low"
        case moderate = "moderate"
        case high = "high"
        case veryHigh = "veryHigh"
    }
    
    init(userId: String, exerciseName: String, category: ExerciseCategory, 
         duration: Int, caloriesBurned: Double, intensity: Intensity, 
         date: Date, notes: String? = nil) {
        self.id = UUID()
        self.userId = userId
        self.exerciseName = exerciseName
        self.category = category
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.intensity = intensity
        self.date = date
        self.notes = notes
        self.dateLogged = Date()
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "userId": userId,
            "exerciseName": exerciseName,
            "category": category.rawValue,
            "duration": duration,
            "caloriesBurned": caloriesBurned,
            "intensity": intensity.rawValue,
            "date": Timestamp(date: date),
            "notes": notes ?? "",
            "dateLogged": Timestamp(date: dateLogged)
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> ExerciseEntry? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let userId = data["userId"] as? String,
              let exerciseName = data["exerciseName"] as? String,
              let categoryRaw = data["category"] as? String,
              let category = ExerciseCategory(rawValue: categoryRaw),
              let duration = data["duration"] as? Int,
              let caloriesBurned = data["caloriesBurned"] as? Double,
              let intensityRaw = data["intensity"] as? String,
              let intensity = Intensity(rawValue: intensityRaw),
              let dateTimestamp = data["date"] as? Timestamp,
              let dateLoggedTimestamp = data["dateLogged"] as? Timestamp else {
            return nil
        }
        
        let notes = data["notes"] as? String
        
        return ExerciseEntry(
            id: id,
            userId: userId,
            exerciseName: exerciseName,
            category: category,
            duration: duration,
            caloriesBurned: caloriesBurned,
            intensity: intensity,
            date: dateTimestamp.dateValue(),
            notes: notes,
            dateLogged: dateLoggedTimestamp.dateValue()
        )
    }
}

extension ExerciseEntry {
    init(id: UUID, userId: String, exerciseName: String, category: ExerciseCategory, 
         duration: Int, caloriesBurned: Double, intensity: Intensity, 
         date: Date, notes: String?, dateLogged: Date) {
        self.id = id
        self.userId = userId
        self.exerciseName = exerciseName
        self.category = category
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.intensity = intensity
        self.date = date
        self.notes = notes
        self.dateLogged = dateLogged
    }
}