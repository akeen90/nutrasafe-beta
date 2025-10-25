//
//  ExerciseModels.swift
//  NutraSafe Beta
//
//  Domain models for Exercise
//

import Foundation
import SwiftUI
import FirebaseFirestore

enum ExerciseIntensity: String, Codable, CaseIterable {
    case low = "Low"
    case moderate = "Moderate" 
    case high = "High"
    case veryHigh = "Very High"
    
    var multiplier: Double {
        switch self {
        case .low: return 0.7
        case .moderate: return 1.0
        case .high: return 1.3
        case .veryHigh: return 1.6
        }
    }
    
    var description: String {
        return rawValue
    }
    
    var emoji: String {
        switch self {
        case .low: return "😌"
        case .moderate: return "😊"
        case .high: return "😤"
        case .veryHigh: return "🔥"
        }
    }
}

struct ExerciseEntry: Identifiable {
    let id: UUID
    let userId: String
    let exerciseName: String
    let type: ExerciseType
    let duration: TimeInterval // in seconds
    let caloriesBurned: Int
    let distance: Double? // in km for cardio
    let sets: Int? // for strength training
    let reps: Int? // for strength training
    let weight: Double? // in kg for strength training
    let notes: String?
    let date: Date
    let dateLogged: Date
    
    enum ExerciseType: String, CaseIterable {
        case cardio = "cardio"
        case resistance = "resistance"
        
        var displayName: String {
            switch self {
            case .cardio:
                return "Cardio"
            case .resistance:
                return "Resistance Training"
            }
        }
    }
    
    init(userId: String, exerciseName: String, type: ExerciseType, 
         duration: TimeInterval, caloriesBurned: Int, distance: Double? = nil,
         sets: Int? = nil, reps: Int? = nil, weight: Double? = nil,
         notes: String? = nil, date: Date) {
        self.id = UUID()
        self.userId = userId
        self.exerciseName = exerciseName
        self.type = type
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.distance = distance
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.notes = notes
        self.date = date
        self.dateLogged = Date()
    }
    
    // Initializer for creating from stored data
    init(id: UUID, userId: String, exerciseName: String, type: ExerciseType,
         duration: TimeInterval, caloriesBurned: Int, distance: Double?,
         sets: Int?, reps: Int?, weight: Double?, notes: String?,
         date: Date, dateLogged: Date) {
        self.id = id
        self.userId = userId
        self.exerciseName = exerciseName
        self.type = type
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.distance = distance
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.notes = notes
        self.date = date
        self.dateLogged = dateLogged
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "userId": userId,
            "exerciseName": exerciseName,
            "type": type.rawValue,
            "duration": duration,
            "caloriesBurned": caloriesBurned,
            "distance": distance ?? NSNull(),
            "sets": sets ?? NSNull(),
            "reps": reps ?? NSNull(),
            "weight": weight ?? NSNull(),
            "notes": notes ?? "",
            "date": FirebaseFirestore.Timestamp(date: date),
            "dateLogged": FirebaseFirestore.Timestamp(date: dateLogged)
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> ExerciseEntry? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let userId = data["userId"] as? String,
              let exerciseName = data["exerciseName"] as? String,
              let typeRaw = data["type"] as? String,
              let type = ExerciseEntry.ExerciseType(rawValue: typeRaw),
              let duration = data["duration"] as? TimeInterval,
              let caloriesBurned = data["caloriesBurned"] as? Int,
              let dateTimestamp = data["date"] as? FirebaseFirestore.Timestamp,
              let dateLoggedTimestamp = data["dateLogged"] as? FirebaseFirestore.Timestamp else {
            return nil
        }
        
        let distance = data["distance"] as? Double
        let sets = data["sets"] as? Int
        let reps = data["reps"] as? Int
        let weight = data["weight"] as? Double
        let notes = data["notes"] as? String
        
        let entry = ExerciseEntry(
            id: id,
            userId: userId,
            exerciseName: exerciseName,
            type: type,
            duration: duration,
            caloriesBurned: caloriesBurned,
            distance: distance,
            sets: sets,
            reps: reps,
            weight: weight,
            notes: notes,
            date: dateTimestamp.dateValue(),
            dateLogged: dateLoggedTimestamp.dateValue()
        )
        return entry
    }
}

enum SetType: String, Codable, CaseIterable {
    case normal = "Normal"
    case warmup = "Warm Up"
    case dropset = "Drop Set"
    case failure = "Failure"

    var icon: String {
        switch self {
        case .normal: return "circle"
        case .warmup: return "flame"
        case .dropset: return "arrow.down.circle"
        case .failure: return "exclamationmark.triangle"
        }
    }

    var color: Color {
        switch self {
        case .normal: return .primary
        case .warmup: return .orange
        case .dropset: return .purple
        case .failure: return .red
        }
    }
}

struct WorkoutSet: Identifiable, Codable {
    var id = UUID()
    var weight: Double
    var reps: Int
    var isCompleted: Bool
    var setType: SetType
    var rpe: Int? // Rate of Perceived Exertion (6-10)
    var note: String?
    var restTime: TimeInterval?
    var completedAt: Date

    // Previous performance for comparison
    var previousWeight: Double?
    var previousReps: Int?

    init(weight: Double = 0.0, reps: Int = 0, isCompleted: Bool = false, setType: SetType = .normal, rpe: Int? = nil, note: String? = nil, restTime: TimeInterval? = nil, previousWeight: Double? = nil, previousReps: Int? = nil) {
        self.id = UUID()
        self.weight = weight
        self.reps = reps
        self.isCompleted = isCompleted
        self.setType = setType
        self.rpe = rpe
        self.note = note
        self.restTime = restTime
        self.completedAt = Date()
        self.previousWeight = previousWeight
        self.previousReps = previousReps
    }
}

struct WorkoutExercise: Identifiable, Codable {
    var id = UUID()
    var name: String
    var sets: [WorkoutSet]
    var notes: String?
    let muscleGroups: [String] // e.g., ["Chest", "Shoulders", "Triceps"]
    var supersetId: UUID? // Groups exercises into supersets
    var restTimerSeconds: Int // Default rest between sets
    var previousPerformance: [WorkoutSet]? // Last workout's sets for comparison

    init(name: String, sets: [WorkoutSet] = [], notes: String? = nil, muscleGroups: [String] = [], supersetId: UUID? = nil, restTimerSeconds: Int = 90, previousPerformance: [WorkoutSet]? = nil) {
        self.id = UUID()
        self.name = name
        self.sets = sets
        self.notes = notes
        self.muscleGroups = muscleGroups
        self.supersetId = supersetId
        self.restTimerSeconds = restTimerSeconds
        self.previousPerformance = previousPerformance
    }

    // Calculate total volume (sets × reps × weight)
    var totalVolume: Double {
        return sets.reduce(0) { total, set in
            total + (Double(set.reps) * set.weight)
        }
    }

    // Calculate personal records
    var maxWeight: Double {
        return sets.map { $0.weight }.max() ?? 0
    }

    var maxReps: Int {
        return sets.map { $0.reps }.max() ?? 0
    }

    var best1RM: Double {
        // Epley formula: weight * (1 + reps/30)
        return sets.map { Double($0.weight) * (1.0 + Double($0.reps) / 30.0) }.max() ?? 0
    }
}

struct WorkoutSession: Identifiable, Codable {
    var id = UUID()
    var userId: String
    var name: String // e.g., "Push Day", "Upper Body"
    var exercises: [WorkoutExercise]
    var startTime: Date
    var endTime: Date?
    var notes: String?
    var totalCaloriesBurned: Int
    
    init(userId: String, name: String, exercises: [WorkoutExercise] = [], notes: String? = nil) {
        self.id = UUID()
        self.userId = userId
        self.name = name
        self.exercises = exercises
        self.startTime = Date()
        self.endTime = nil
        self.notes = notes
        self.totalCaloriesBurned = 0
    }
    
    // Calculate workout duration
    var duration: TimeInterval {
        return (endTime ?? Date()).timeIntervalSince(startTime)
    }
    
    // Calculate total volume for the workout
    var totalVolume: Double {
        return exercises.reduce(0) { $0 + $1.totalVolume }
    }
    
    // Get workout date (for streak calculation)
    var workoutDate: Date {
        return startTime
    }
    
    func toDictionary() -> [String: Any] {
        let exerciseData = exercises.map { exercise in
            [
                "name": exercise.name,
                "sets": exercise.sets.map { set in
                    [
                        "reps": set.reps,
                        "weight": set.weight,
                        "restTime": set.restTime ?? NSNull(),
                        "completedAt": FirebaseFirestore.Timestamp(date: set.completedAt)
                    ]
                },
                "notes": exercise.notes ?? "",
                "muscleGroups": exercise.muscleGroups
            ]
        }
        
        return [
            "id": id.uuidString,
            "userId": userId,
            "name": name,
            "exercises": exerciseData,
            "startTime": FirebaseFirestore.Timestamp(date: startTime),
            "endTime": endTime != nil ? FirebaseFirestore.Timestamp(date: endTime!) : NSNull(),
            "notes": notes ?? "",
            "totalCaloriesBurned": totalCaloriesBurned
        ]
    }
}

struct WorkoutProgress: Codable {
    let userId: String
    let currentStreak: Int
    let longestStreak: Int
    let totalWorkouts: Int
    let currentWeekWorkouts: Int
    let lastWorkoutDate: Date?
    let weeklyGoal: Int // workouts per week
    let personalRecords: [String: PersonalRecord] // exercise name -> best performance
    
    init(userId: String, weeklyGoal: Int = 3) {
        self.userId = userId
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalWorkouts = 0
        self.currentWeekWorkouts = 0
        self.lastWorkoutDate = nil
        self.weeklyGoal = weeklyGoal
        self.personalRecords = [:]
    }
    
    // Check if current week streak is active
    var isCurrentStreakActive: Bool {
        guard let lastWorkout = lastWorkoutDate else { return false }
        let calendar = Calendar.current
        let now = Date()
        
        // Check if last workout was this week
        return calendar.isDate(lastWorkout, equalTo: now, toGranularity: .weekOfYear)
    }
    
    // Calculate progress towards weekly goal
    var weeklyProgress: Double {
        return Double(currentWeekWorkouts) / Double(weeklyGoal)
    }
}

struct ExerciseSet: Codable, Identifiable {
    var id = UUID()
    var reps: Int
    var weight: Double // in kg
    var completed: Bool
    
    // Cardio-specific fields
    var duration: TimeInterval? // seconds for cardio exercises
    var distance: Double? // km for cardio exercises
    var intensity: ExerciseIntensity? // intensity level for time-based exercises
    var isCardio: Bool
    
    // Resistance exercise initializer
    init(reps: Int = 0, weight: Double = 0.0, completed: Bool = false) {
        self.reps = reps
        self.weight = weight
        self.completed = completed
        self.duration = nil
        self.distance = nil
        self.intensity = nil
        self.isCardio = false
    }
    
    // Cardio exercise initializer (distance-based)
    init(duration: TimeInterval, distance: Double? = nil, completed: Bool = false) {
        self.reps = 0
        self.weight = 0.0
        self.completed = completed
        self.duration = duration
        self.distance = distance
        self.intensity = nil // Distance-based exercises don't need intensity
        self.isCardio = true
    }
    
    // Cardio exercise initializer (intensity-based)
    init(duration: TimeInterval, intensity: ExerciseIntensity, completed: Bool = false) {
        self.reps = 0
        self.weight = 0.0
        self.completed = completed
        self.duration = duration
        self.distance = nil // Intensity-based exercises don't track distance
        self.intensity = intensity
        self.isCardio = true
    }
    
    // Formatted duration string (MM:SS)
    var formattedDuration: String {
        guard let duration = duration else { return "0:00" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // Formatted distance string
    var formattedDistance: String {
        guard let distance = distance else { return "-" }
        return String(format: "%.1f km", distance)
    }
    
    // Calculate pace (min/km)
    var pace: String {
        guard let duration = duration, 
              let distance = distance, 
              distance > 0 else { return "-" }
        let paceInSeconds = duration / distance
        let minutes = Int(paceInSeconds) / 60
        let seconds = Int(paceInSeconds) % 60
        return String(format: "%d:%02d/km", minutes, seconds)
    }
}

struct WorkoutTemplate: Identifiable, Codable {
    let id: UUID
    let name: String
    let exercises: [ExerciseModel]
    let estimatedDuration: Int // minutes
    let icon: String?
    let category: Category
    let difficulty: Difficulty
    let description: String?
    
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
    
    init(id: UUID = UUID(), name: String, exercises: [ExerciseModel], category: Category, estimatedDuration: Int, difficulty: Difficulty, icon: String? = nil, description: String? = nil) {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.category = category
        self.estimatedDuration = estimatedDuration
        self.difficulty = difficulty
        self.icon = icon
        self.description = description
    }
}

enum ExerciseCategory: String, CaseIterable, Codable {
    case chest = "Chest"
    case back = "Back"  
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case legs = "Legs"
    case glutes = "Glutes"
    case calves = "Calves"
    case core = "Core"
    case cardio = "Cardio"
    case fullBody = "Full Body"
    
    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rowing"
        case .shoulders: return "figure.arm.curls"
        case .biceps: return "figure.arm.curls"
        case .triceps: return "figure.strengthtraining.functional"
        case .legs: return "figure.leg.work"
        case .glutes: return "figure.squat"
        case .calves: return "figure.leg.calf.press"
        case .core: return "figure.core.training"
        case .cardio: return "figure.run"
        case .fullBody: return "figure.mixed.cardio"
        }
    }
}

enum ExerciseMovementType: String, Codable {
    case compound = "Compound"
    case isolation = "Isolation"
    case cardio = "Cardio"
}

struct ExerciseModel: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let name: String
    let category: ExerciseCategory
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let equipment: Equipment
    let movementType: ExerciseMovementType
    let instructions: [String]?
    let isPopular: Bool
    let difficulty: Int // 1-5 scale
    
    init(id: UUID = UUID(), name: String, category: ExerciseCategory, primaryMuscles: [String], secondaryMuscles: [String] = [], equipment: Equipment, movementType: ExerciseMovementType, instructions: [String]? = nil, isPopular: Bool = false, difficulty: Int = 3) {
        self.id = id
        self.name = name
        self.category = category
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.equipment = equipment
        self.movementType = movementType
        self.instructions = instructions
        self.isPopular = isPopular
        self.difficulty = difficulty
    }
}

class ComprehensiveExerciseDatabase {
    static let shared = ComprehensiveExerciseDatabase()
    
    private init() {}
    
    lazy var allExercises: [ExerciseModel] = [
        // CHEST EXERCISES (Alphabetical)
        ExerciseModel(name: "Barbell Bench Press", category: .chest, primaryMuscles: ["Chest", "Front Deltoids"], secondaryMuscles: ["Triceps"], equipment: .barbell, movementType: .compound, isPopular: true, difficulty: 3),
        ExerciseModel(name: "Cable Chest Flyes", category: .chest, primaryMuscles: ["Chest"], equipment: .cable, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Cable Crossover", category: .chest, primaryMuscles: ["Chest"], equipment: .cable, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Cable High-to-Low Flyes", category: .chest, primaryMuscles: ["Lower Chest"], equipment: .cable, movementType: .isolation, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Cable Low-to-High Flyes", category: .chest, primaryMuscles: ["Upper Chest"], equipment: .cable, movementType: .isolation, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Chest Dips", category: .chest, primaryMuscles: ["Lower Chest"], secondaryMuscles: ["Triceps", "Front Deltoids"], equipment: .bodyweight, movementType: .compound, isPopular: true, difficulty: 3),
        ExerciseModel(name: "Chest Press Machine", category: .chest, primaryMuscles: ["Chest"], secondaryMuscles: ["Triceps", "Front Deltoids"], equipment: .machine, movementType: .compound, isPopular: true, difficulty: 1),
        ExerciseModel(name: "Close-Grip Push-ups", category: .chest, primaryMuscles: ["Triceps", "Upper Chest"], secondaryMuscles: ["Front Deltoids"], equipment: .bodyweight, movementType: .compound, isPopular: false, difficulty: 3),
        ExerciseModel(name: "Decline Barbell Bench Press", category: .chest, primaryMuscles: ["Lower Chest"], secondaryMuscles: ["Triceps", "Front Deltoids"], equipment: .barbell, movementType: .compound, isPopular: false, difficulty: 3),
        ExerciseModel(name: "Decline Dumbbell Press", category: .chest, primaryMuscles: ["Lower Chest"], secondaryMuscles: ["Triceps", "Front Deltoids"], equipment: .dumbbell, movementType: .compound, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Decline Push-ups", category: .chest, primaryMuscles: ["Upper Chest"], secondaryMuscles: ["Triceps", "Front Deltoids"], equipment: .bodyweight, movementType: .compound, isPopular: false, difficulty: 3),
        ExerciseModel(name: "Diamond Push-ups", category: .chest, primaryMuscles: ["Triceps", "Upper Chest"], equipment: .bodyweight, movementType: .compound, isPopular: false, difficulty: 4),
        ExerciseModel(name: "Dumbbell Bench Press", category: .chest, primaryMuscles: ["Chest"], secondaryMuscles: ["Triceps", "Front Deltoids"], equipment: .dumbbell, movementType: .compound, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Dumbbell Flyes", category: .chest, primaryMuscles: ["Chest"], equipment: .dumbbell, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Dumbbell Pullover", category: .chest, primaryMuscles: ["Chest", "Lats"], equipment: .dumbbell, movementType: .isolation, isPopular: false, difficulty: 3),
        ExerciseModel(name: "Hammer Strength Chest Press", category: .chest, primaryMuscles: ["Chest"], secondaryMuscles: ["Triceps", "Front Deltoids"], equipment: .machine, movementType: .compound, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Incline Barbell Bench Press", category: .chest, primaryMuscles: ["Upper Chest", "Front Deltoids"], secondaryMuscles: ["Triceps"], equipment: .barbell, movementType: .compound, isPopular: true, difficulty: 3),
        ExerciseModel(name: "Incline Dumbbell Flyes", category: .chest, primaryMuscles: ["Upper Chest"], equipment: .dumbbell, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Incline Dumbbell Press", category: .chest, primaryMuscles: ["Upper Chest"], secondaryMuscles: ["Triceps", "Front Deltoids"], equipment: .dumbbell, movementType: .compound, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Incline Push-ups", category: .chest, primaryMuscles: ["Lower Chest"], secondaryMuscles: ["Triceps"], equipment: .bodyweight, movementType: .compound, isPopular: false, difficulty: 1),
        ExerciseModel(name: "Landmine Press", category: .chest, primaryMuscles: ["Chest", "Front Deltoids"], secondaryMuscles: ["Core", "Triceps"], equipment: .barbell, movementType: .compound, isPopular: false, difficulty: 3),
        ExerciseModel(name: "Machine Flyes", category: .chest, primaryMuscles: ["Chest"], equipment: .machine, movementType: .isolation, isPopular: true, difficulty: 1),
        ExerciseModel(name: "Pec Deck Flyes", category: .chest, primaryMuscles: ["Chest"], equipment: .machine, movementType: .isolation, isPopular: true, difficulty: 1),
        ExerciseModel(name: "Push-ups", category: .chest, primaryMuscles: ["Chest"], secondaryMuscles: ["Triceps", "Front Deltoids", "Core"], equipment: .bodyweight, movementType: .compound, isPopular: true, difficulty: 1),
        ExerciseModel(name: "Svend Press", category: .chest, primaryMuscles: ["Chest"], equipment: .dumbbell, movementType: .isolation, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Wide-Grip Push-ups", category: .chest, primaryMuscles: ["Chest"], secondaryMuscles: ["Front Deltoids"], equipment: .bodyweight, movementType: .compound, isPopular: false, difficulty: 2),
        
        // BACK EXERCISES (Alphabetical)
        ExerciseModel(name: "Assisted Pull-ups", category: .back, primaryMuscles: ["Lats", "Rhomboids"], secondaryMuscles: ["Biceps"], equipment: .machine, movementType: .compound, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Band Pull-aparts", category: .back, primaryMuscles: ["Rhomboids", "Middle Traps"], equipment: .resistance_band, movementType: .isolation, isPopular: false, difficulty: 1),
        ExerciseModel(name: "Barbell Shrugs", category: .back, primaryMuscles: ["Upper Traps"], equipment: .barbell, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Bent-over Barbell Row", category: .back, primaryMuscles: ["Rhomboids", "Lats"], secondaryMuscles: ["Biceps", "Rear Deltoids"], equipment: .barbell, movementType: .compound, isPopular: true, difficulty: 3),
        ExerciseModel(name: "Bent-over Dumbbell Row", category: .back, primaryMuscles: ["Lats", "Rhomboids"], secondaryMuscles: ["Biceps"], equipment: .dumbbell, movementType: .compound, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Cable High Row", category: .back, primaryMuscles: ["Upper Traps", "Rhomboids"], secondaryMuscles: ["Rear Deltoids"], equipment: .cable, movementType: .compound, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Cable Low Row", category: .back, primaryMuscles: ["Lower Lats", "Rhomboids"], secondaryMuscles: ["Biceps"], equipment: .cable, movementType: .compound, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Cable Reverse Flyes", category: .back, primaryMuscles: ["Rear Deltoids", "Rhomboids"], equipment: .cable, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Chest Supported Row", category: .back, primaryMuscles: ["Rhomboids", "Middle Traps"], secondaryMuscles: ["Biceps"], equipment: .machine, movementType: .compound, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Chin-ups", category: .back, primaryMuscles: ["Lats", "Rhomboids"], secondaryMuscles: ["Biceps"], equipment: .bodyweight, movementType: .compound, isPopular: true, difficulty: 4),
        ExerciseModel(name: "Close-Grip Lat Pulldown", category: .back, primaryMuscles: ["Lower Lats"], secondaryMuscles: ["Biceps"], equipment: .cable, movementType: .compound, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Deadlift", category: .back, primaryMuscles: ["Lower Back", "Lats", "Rhomboids"], secondaryMuscles: ["Hamstrings", "Glutes", "Traps"], equipment: .barbell, movementType: .compound, isPopular: true, difficulty: 4),
        ExerciseModel(name: "Dumbbell Shrugs", category: .back, primaryMuscles: ["Upper Traps"], equipment: .dumbbell, movementType: .isolation, isPopular: true, difficulty: 1),
        ExerciseModel(name: "Face Pulls", category: .back, primaryMuscles: ["Rear Deltoids", "Middle Traps"], equipment: .cable, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Hammer Strength Row", category: .back, primaryMuscles: ["Lats", "Rhomboids"], secondaryMuscles: ["Biceps"], equipment: .machine, movementType: .compound, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Hyperextensions", category: .back, primaryMuscles: ["Lower Back"], secondaryMuscles: ["Glutes", "Hamstrings"], equipment: .bodyweight, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Inverted Rows", category: .back, primaryMuscles: ["Rhomboids", "Middle Traps"], secondaryMuscles: ["Biceps"], equipment: .bodyweight, movementType: .compound, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Landmine Row", category: .back, primaryMuscles: ["Lats", "Rhomboids"], secondaryMuscles: ["Core", "Biceps"], equipment: .barbell, movementType: .compound, isPopular: false, difficulty: 3),
        ExerciseModel(name: "Lat Pulldown", category: .back, primaryMuscles: ["Lats"], secondaryMuscles: ["Biceps", "Rhomboids"], equipment: .cable, movementType: .compound, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Machine High Row", category: .back, primaryMuscles: ["Upper Lats", "Rhomboids"], secondaryMuscles: ["Rear Deltoids"], equipment: .machine, movementType: .compound, isPopular: true, difficulty: 1),
        ExerciseModel(name: "Meadows Row", category: .back, primaryMuscles: ["Lats", "Rhomboids"], secondaryMuscles: ["Biceps"], equipment: .barbell, movementType: .compound, isPopular: false, difficulty: 3),
        ExerciseModel(name: "Neutral Grip Pull-ups", category: .back, primaryMuscles: ["Lats", "Rhomboids"], secondaryMuscles: ["Biceps"], equipment: .bodyweight, movementType: .compound, isPopular: false, difficulty: 4),
        ExerciseModel(name: "One-Arm Dumbbell Row", category: .back, primaryMuscles: ["Lats", "Rhomboids"], secondaryMuscles: ["Biceps", "Rear Deltoids"], equipment: .dumbbell, movementType: .compound, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Pendlay Row", category: .back, primaryMuscles: ["Rhomboids", "Middle Traps"], secondaryMuscles: ["Biceps"], equipment: .barbell, movementType: .compound, isPopular: false, difficulty: 4),
        ExerciseModel(name: "Pull-ups", category: .back, primaryMuscles: ["Lats", "Rhomboids"], secondaryMuscles: ["Biceps", "Rear Deltoids"], equipment: .bodyweight, movementType: .compound, isPopular: true, difficulty: 4),
        ExerciseModel(name: "Reverse Flyes", category: .back, primaryMuscles: ["Rear Deltoids", "Rhomboids"], equipment: .dumbbell, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Romanian Deadlift", category: .back, primaryMuscles: ["Lower Back", "Hamstrings"], secondaryMuscles: ["Glutes"], equipment: .barbell, movementType: .compound, isPopular: true, difficulty: 3),
        ExerciseModel(name: "Seated Cable Row", category: .back, primaryMuscles: ["Rhomboids", "Middle Traps"], secondaryMuscles: ["Biceps", "Rear Deltoids"], equipment: .cable, movementType: .compound, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Single-Arm Cable Row", category: .back, primaryMuscles: ["Lats", "Rhomboids"], secondaryMuscles: ["Biceps"], equipment: .cable, movementType: .compound, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Sumo Deadlift", category: .back, primaryMuscles: ["Lower Back", "Glutes"], secondaryMuscles: ["Hamstrings", "Quads"], equipment: .barbell, movementType: .compound, isPopular: false, difficulty: 4),
        ExerciseModel(name: "Superman", category: .back, primaryMuscles: ["Lower Back"], secondaryMuscles: ["Glutes"], equipment: .bodyweight, movementType: .isolation, isPopular: false, difficulty: 1),
        ExerciseModel(name: "T-Bar Row", category: .back, primaryMuscles: ["Rhomboids", "Middle Traps"], secondaryMuscles: ["Biceps", "Rear Deltoids"], equipment: .barbell, movementType: .compound, isPopular: true, difficulty: 3),
        ExerciseModel(name: "Trap Bar Deadlift", category: .back, primaryMuscles: ["Lower Back", "Quads"], secondaryMuscles: ["Hamstrings", "Glutes"], equipment: .barbell, movementType: .compound, isPopular: false, difficulty: 3),
        ExerciseModel(name: "Wide-Grip Lat Pulldown", category: .back, primaryMuscles: ["Upper Lats"], secondaryMuscles: ["Biceps"], equipment: .cable, movementType: .compound, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Wide-Grip Pull-ups", category: .back, primaryMuscles: ["Upper Lats", "Rhomboids"], secondaryMuscles: ["Biceps"], equipment: .bodyweight, movementType: .compound, isPopular: false, difficulty: 4),
        
        // SHOULDER EXERCISES (Alphabetical)
        ExerciseModel(name: "Arnold Press", category: .shoulders, primaryMuscles: ["Front Deltoids", "Middle Deltoids"], secondaryMuscles: ["Triceps"], equipment: .dumbbell, movementType: .compound, isPopular: false, difficulty: 3),
        ExerciseModel(name: "Behind-the-Neck Press", category: .shoulders, primaryMuscles: ["Front Deltoids", "Middle Deltoids"], secondaryMuscles: ["Triceps"], equipment: .barbell, movementType: .compound, isPopular: false, difficulty: 4),
        ExerciseModel(name: "Cable Front Raises", category: .shoulders, primaryMuscles: ["Front Deltoids"], equipment: .cable, movementType: .isolation, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Cable Lateral Raises", category: .shoulders, primaryMuscles: ["Middle Deltoids"], equipment: .cable, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Cable Rear Delt Flyes", category: .shoulders, primaryMuscles: ["Rear Deltoids"], equipment: .cable, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Cuban Press", category: .shoulders, primaryMuscles: ["Rear Deltoids", "Middle Deltoids"], equipment: .dumbbell, movementType: .compound, isPopular: false, difficulty: 3),
        ExerciseModel(name: "Dumbbell Shoulder Press", category: .shoulders, primaryMuscles: ["Front Deltoids", "Middle Deltoids"], secondaryMuscles: ["Triceps"], equipment: .dumbbell, movementType: .compound, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Face Pulls", category: .shoulders, primaryMuscles: ["Rear Deltoids", "Middle Traps"], equipment: .cable, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Front Raises", category: .shoulders, primaryMuscles: ["Front Deltoids"], equipment: .dumbbell, movementType: .isolation, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Handstand Push-ups", category: .shoulders, primaryMuscles: ["Front Deltoids", "Middle Deltoids"], secondaryMuscles: ["Triceps"], equipment: .bodyweight, movementType: .compound, isPopular: false, difficulty: 5),
        ExerciseModel(name: "Lateral Raises", category: .shoulders, primaryMuscles: ["Middle Deltoids"], equipment: .dumbbell, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Machine Shoulder Press", category: .shoulders, primaryMuscles: ["Front Deltoids", "Middle Deltoids"], secondaryMuscles: ["Triceps"], equipment: .machine, movementType: .compound, isPopular: true, difficulty: 1),
        ExerciseModel(name: "Military Press", category: .shoulders, primaryMuscles: ["Front Deltoids", "Middle Deltoids"], secondaryMuscles: ["Triceps", "Core"], equipment: .barbell, movementType: .compound, isPopular: true, difficulty: 3),
        ExerciseModel(name: "Overhead Press", category: .shoulders, primaryMuscles: ["Front Deltoids", "Middle Deltoids"], secondaryMuscles: ["Triceps", "Upper Chest"], equipment: .barbell, movementType: .compound, isPopular: true, difficulty: 3),
        ExerciseModel(name: "Pike Push-ups", category: .shoulders, primaryMuscles: ["Front Deltoids"], secondaryMuscles: ["Triceps"], equipment: .bodyweight, movementType: .compound, isPopular: false, difficulty: 3),
        ExerciseModel(name: "Plate Front Raises", category: .shoulders, primaryMuscles: ["Front Deltoids"], equipment: .other, movementType: .isolation, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Push Press", category: .shoulders, primaryMuscles: ["Front Deltoids", "Middle Deltoids"], secondaryMuscles: ["Triceps", "Legs"], equipment: .barbell, movementType: .compound, isPopular: false, difficulty: 4),
        ExerciseModel(name: "Rear Delt Flyes", category: .shoulders, primaryMuscles: ["Rear Deltoids"], equipment: .dumbbell, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Reverse Pec Deck", category: .shoulders, primaryMuscles: ["Rear Deltoids"], equipment: .machine, movementType: .isolation, isPopular: true, difficulty: 1),
        ExerciseModel(name: "Seated Dumbbell Press", category: .shoulders, primaryMuscles: ["Front Deltoids", "Middle Deltoids"], secondaryMuscles: ["Triceps"], equipment: .dumbbell, movementType: .compound, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Single-Arm Lateral Raise", category: .shoulders, primaryMuscles: ["Middle Deltoids"], equipment: .dumbbell, movementType: .isolation, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Upright Row", category: .shoulders, primaryMuscles: ["Middle Deltoids", "Upper Traps"], secondaryMuscles: ["Biceps"], equipment: .barbell, movementType: .compound, isPopular: true, difficulty: 2),
        
        // BICEPS EXERCISES (Alphabetical)
        ExerciseModel(name: "Barbell Curls", category: .biceps, primaryMuscles: ["Biceps"], equipment: .barbell, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Cable Bicep Curls", category: .biceps, primaryMuscles: ["Biceps"], equipment: .cable, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Cable Hammer Curls", category: .biceps, primaryMuscles: ["Biceps", "Forearms"], equipment: .cable, movementType: .isolation, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Concentration Curls", category: .biceps, primaryMuscles: ["Biceps"], equipment: .dumbbell, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Cross-Body Hammer Curls", category: .biceps, primaryMuscles: ["Biceps", "Forearms"], equipment: .dumbbell, movementType: .isolation, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Dumbbell Bicep Curls", category: .biceps, primaryMuscles: ["Biceps"], equipment: .dumbbell, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "EZ-Bar Curls", category: .biceps, primaryMuscles: ["Biceps"], equipment: .barbell, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Hammer Curls", category: .biceps, primaryMuscles: ["Biceps", "Forearms"], equipment: .dumbbell, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "High Cable Curls", category: .biceps, primaryMuscles: ["Biceps"], equipment: .cable, movementType: .isolation, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Incline Dumbbell Curls", category: .biceps, primaryMuscles: ["Biceps"], equipment: .dumbbell, movementType: .isolation, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Machine Bicep Curls", category: .biceps, primaryMuscles: ["Biceps"], equipment: .machine, movementType: .isolation, isPopular: true, difficulty: 1),
        ExerciseModel(name: "Preacher Curls", category: .biceps, primaryMuscles: ["Biceps"], equipment: .dumbbell, movementType: .isolation, isPopular: false, difficulty: 3),
        ExerciseModel(name: "Reverse Curls", category: .biceps, primaryMuscles: ["Forearms", "Biceps"], equipment: .barbell, movementType: .isolation, isPopular: false, difficulty: 3),
        ExerciseModel(name: "Spider Curls", category: .biceps, primaryMuscles: ["Biceps"], equipment: .barbell, movementType: .isolation, isPopular: false, difficulty: 3),
        ExerciseModel(name: "21s (Bicep Curls)", category: .biceps, primaryMuscles: ["Biceps"], equipment: .barbell, movementType: .isolation, isPopular: false, difficulty: 3),
        
        // TRICEPS EXERCISES (Alphabetical)
        ExerciseModel(name: "Assisted Tricep Dips", category: .triceps, primaryMuscles: ["Triceps"], secondaryMuscles: ["Lower Chest"], equipment: .machine, movementType: .compound, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Cable Overhead Extension", category: .triceps, primaryMuscles: ["Triceps"], equipment: .cable, movementType: .isolation, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Close-Grip Bench Press", category: .triceps, primaryMuscles: ["Triceps"], secondaryMuscles: ["Chest", "Front Deltoids"], equipment: .barbell, movementType: .compound, isPopular: true, difficulty: 3),
        ExerciseModel(name: "Diamond Push-ups", category: .triceps, primaryMuscles: ["Triceps"], secondaryMuscles: ["Chest", "Front Deltoids"], equipment: .bodyweight, movementType: .compound, isPopular: false, difficulty: 3),
        ExerciseModel(name: "Dumbbell Kickbacks", category: .triceps, primaryMuscles: ["Triceps"], equipment: .dumbbell, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "French Press", category: .triceps, primaryMuscles: ["Triceps"], equipment: .barbell, movementType: .isolation, isPopular: false, difficulty: 3),
        ExerciseModel(name: "JM Press", category: .triceps, primaryMuscles: ["Triceps"], secondaryMuscles: ["Chest"], equipment: .barbell, movementType: .compound, isPopular: false, difficulty: 4),
        ExerciseModel(name: "Machine Tricep Dips", category: .triceps, primaryMuscles: ["Triceps"], equipment: .machine, movementType: .compound, isPopular: true, difficulty: 1),
        ExerciseModel(name: "Overhead Tricep Extension", category: .triceps, primaryMuscles: ["Triceps"], equipment: .dumbbell, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Rope Pushdowns", category: .triceps, primaryMuscles: ["Triceps"], equipment: .cable, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Single-Arm Overhead Extension", category: .triceps, primaryMuscles: ["Triceps"], equipment: .dumbbell, movementType: .isolation, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Skull Crushers", category: .triceps, primaryMuscles: ["Triceps"], equipment: .barbell, movementType: .isolation, isPopular: true, difficulty: 3),
        ExerciseModel(name: "Tricep Dips", category: .triceps, primaryMuscles: ["Triceps"], secondaryMuscles: ["Lower Chest", "Front Deltoids"], equipment: .bodyweight, movementType: .compound, isPopular: true, difficulty: 3),
        ExerciseModel(name: "Tricep Pushdowns", category: .triceps, primaryMuscles: ["Triceps"], equipment: .cable, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "V-Bar Pushdowns", category: .triceps, primaryMuscles: ["Triceps"], equipment: .cable, movementType: .isolation, isPopular: true, difficulty: 2),
        
        // LEG EXERCISES (Alphabetical)
        ExerciseModel(name: "Box Squats", category: .legs, primaryMuscles: ["Quadriceps", "Glutes"], secondaryMuscles: ["Hamstrings"], equipment: .barbell, movementType: .compound, isPopular: false, difficulty: 3),
        ExerciseModel(name: "Bulgarian Split Squats", category: .legs, primaryMuscles: ["Quadriceps", "Glutes"], equipment: .dumbbell, movementType: .compound, isPopular: false, difficulty: 3),
        ExerciseModel(name: "Curtsy Lunges", category: .legs, primaryMuscles: ["Glutes", "Quadriceps"], equipment: .dumbbell, movementType: .compound, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Deficit Deadlift", category: .legs, primaryMuscles: ["Hamstrings", "Glutes"], secondaryMuscles: ["Lower Back"], equipment: .barbell, movementType: .compound, isPopular: false, difficulty: 4),
        ExerciseModel(name: "Front Squats", category: .legs, primaryMuscles: ["Quadriceps"], secondaryMuscles: ["Glutes", "Core"], equipment: .barbell, movementType: .compound, isPopular: false, difficulty: 4),
        ExerciseModel(name: "Goblet Squats", category: .legs, primaryMuscles: ["Quadriceps", "Glutes"], secondaryMuscles: ["Core"], equipment: .dumbbell, movementType: .compound, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Good Mornings", category: .legs, primaryMuscles: ["Hamstrings", "Lower Back"], secondaryMuscles: ["Glutes"], equipment: .barbell, movementType: .compound, isPopular: false, difficulty: 3),
        ExerciseModel(name: "Hack Squats", category: .legs, primaryMuscles: ["Quadriceps", "Glutes"], equipment: .machine, movementType: .compound, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Hip Thrusts", category: .legs, primaryMuscles: ["Glutes"], secondaryMuscles: ["Hamstrings"], equipment: .barbell, movementType: .compound, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Jump Squats", category: .legs, primaryMuscles: ["Quadriceps", "Glutes"], secondaryMuscles: ["Calves"], equipment: .bodyweight, movementType: .compound, isPopular: false, difficulty: 3),
        ExerciseModel(name: "Lateral Lunges", category: .legs, primaryMuscles: ["Quadriceps", "Glutes"], secondaryMuscles: ["Adductors"], equipment: .dumbbell, movementType: .compound, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Leg Curls", category: .legs, primaryMuscles: ["Hamstrings"], equipment: .machine, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Leg Extensions", category: .legs, primaryMuscles: ["Quadriceps"], equipment: .machine, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Leg Press", category: .legs, primaryMuscles: ["Quadriceps", "Glutes"], equipment: .machine, movementType: .compound, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Lunges", category: .legs, primaryMuscles: ["Quadriceps", "Glutes"], secondaryMuscles: ["Hamstrings"], equipment: .dumbbell, movementType: .compound, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Nordic Curls", category: .legs, primaryMuscles: ["Hamstrings"], equipment: .bodyweight, movementType: .isolation, isPopular: false, difficulty: 5),
        ExerciseModel(name: "Overhead Squats", category: .legs, primaryMuscles: ["Quadriceps", "Glutes"], secondaryMuscles: ["Shoulders", "Core"], equipment: .barbell, movementType: .compound, isPopular: false, difficulty: 4),
        ExerciseModel(name: "Pause Squats", category: .legs, primaryMuscles: ["Quadriceps", "Glutes"], secondaryMuscles: ["Hamstrings"], equipment: .barbell, movementType: .compound, isPopular: false, difficulty: 3),
        ExerciseModel(name: "Pistol Squats", category: .legs, primaryMuscles: ["Quadriceps", "Glutes"], secondaryMuscles: ["Core"], equipment: .bodyweight, movementType: .compound, isPopular: false, difficulty: 5),
        ExerciseModel(name: "Reverse Lunges", category: .legs, primaryMuscles: ["Quadriceps", "Glutes"], secondaryMuscles: ["Hamstrings"], equipment: .dumbbell, movementType: .compound, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Romanian Deadlift", category: .legs, primaryMuscles: ["Hamstrings", "Glutes"], secondaryMuscles: ["Lower Back"], equipment: .barbell, movementType: .compound, isPopular: true, difficulty: 3),
        ExerciseModel(name: "Single-Leg Deadlift", category: .legs, primaryMuscles: ["Hamstrings", "Glutes"], secondaryMuscles: ["Core"], equipment: .dumbbell, movementType: .compound, isPopular: false, difficulty: 3),
        ExerciseModel(name: "Single-Leg Press", category: .legs, primaryMuscles: ["Quadriceps", "Glutes"], equipment: .machine, movementType: .compound, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Sissy Squats", category: .legs, primaryMuscles: ["Quadriceps"], equipment: .bodyweight, movementType: .isolation, isPopular: false, difficulty: 4),
        ExerciseModel(name: "Squats", category: .legs, primaryMuscles: ["Quadriceps", "Glutes"], secondaryMuscles: ["Hamstrings", "Calves"], equipment: .barbell, movementType: .compound, isPopular: true, difficulty: 3),
        ExerciseModel(name: "Step-ups", category: .legs, primaryMuscles: ["Quadriceps", "Glutes"], equipment: .dumbbell, movementType: .compound, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Stiff-Leg Deadlift", category: .legs, primaryMuscles: ["Hamstrings"], secondaryMuscles: ["Glutes", "Lower Back"], equipment: .dumbbell, movementType: .compound, isPopular: true, difficulty: 3),
        ExerciseModel(name: "Sumo Squats", category: .legs, primaryMuscles: ["Quadriceps", "Glutes", "Adductors"], equipment: .dumbbell, movementType: .compound, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Wall Sits", category: .legs, primaryMuscles: ["Quadriceps", "Glutes"], equipment: .bodyweight, movementType: .isolation, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Walking Lunges", category: .legs, primaryMuscles: ["Quadriceps", "Glutes"], secondaryMuscles: ["Hamstrings"], equipment: .dumbbell, movementType: .compound, isPopular: true, difficulty: 2),
        
        // CALF EXERCISES (Alphabetical)
        ExerciseModel(name: "Calf Press on Leg Press", category: .calves, primaryMuscles: ["Calves"], equipment: .machine, movementType: .isolation, isPopular: false, difficulty: 1),
        ExerciseModel(name: "Calf Raises", category: .calves, primaryMuscles: ["Calves"], equipment: .machine, movementType: .isolation, isPopular: true, difficulty: 1),
        ExerciseModel(name: "Donkey Calf Raises", category: .calves, primaryMuscles: ["Calves"], equipment: .machine, movementType: .isolation, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Seated Calf Raises", category: .calves, primaryMuscles: ["Calves"], equipment: .machine, movementType: .isolation, isPopular: true, difficulty: 1),
        ExerciseModel(name: "Single-Leg Calf Raises", category: .calves, primaryMuscles: ["Calves"], equipment: .bodyweight, movementType: .isolation, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Standing Barbell Calf Raises", category: .calves, primaryMuscles: ["Calves"], equipment: .barbell, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Standing Dumbbell Calf Raises", category: .calves, primaryMuscles: ["Calves"], equipment: .dumbbell, movementType: .isolation, isPopular: true, difficulty: 1),
        
        // CORE EXERCISES (Alphabetical)
        ExerciseModel(name: "Ab Wheel Rollout", category: .core, primaryMuscles: ["Core"], equipment: .other, movementType: .isolation, isPopular: false, difficulty: 4),
        ExerciseModel(name: "Bear Crawl", category: .core, primaryMuscles: ["Core"], secondaryMuscles: ["Shoulders"], equipment: .bodyweight, movementType: .compound, isPopular: false, difficulty: 3),
        ExerciseModel(name: "Bicycle Crunches", category: .core, primaryMuscles: ["Abs", "Obliques"], equipment: .bodyweight, movementType: .isolation, isPopular: true, difficulty: 1),
        ExerciseModel(name: "Cable Crunches", category: .core, primaryMuscles: ["Abs"], equipment: .cable, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Captain's Chair Leg Raises", category: .core, primaryMuscles: ["Lower Abs"], equipment: .machine, movementType: .isolation, isPopular: true, difficulty: 3),
        ExerciseModel(name: "Crunches", category: .core, primaryMuscles: ["Abs"], equipment: .bodyweight, movementType: .isolation, isPopular: true, difficulty: 1),
        ExerciseModel(name: "Dead Bug", category: .core, primaryMuscles: ["Core"], equipment: .bodyweight, movementType: .isolation, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Dragon Flag", category: .core, primaryMuscles: ["Core"], equipment: .bodyweight, movementType: .isolation, isPopular: false, difficulty: 5),
        ExerciseModel(name: "Hanging Knee Raises", category: .core, primaryMuscles: ["Lower Abs"], equipment: .bodyweight, movementType: .isolation, isPopular: true, difficulty: 3),
        ExerciseModel(name: "Hanging Leg Raises", category: .core, primaryMuscles: ["Lower Abs"], equipment: .bodyweight, movementType: .isolation, isPopular: true, difficulty: 4),
        ExerciseModel(name: "Leg Raises", category: .core, primaryMuscles: ["Lower Abs"], equipment: .bodyweight, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Medicine Ball Slams", category: .core, primaryMuscles: ["Core"], secondaryMuscles: ["Shoulders"], equipment: .other, movementType: .compound, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Mountain Climbers", category: .core, primaryMuscles: ["Core"], secondaryMuscles: ["Shoulders", "Legs"], equipment: .bodyweight, movementType: .compound, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Plank", category: .core, primaryMuscles: ["Core"], equipment: .bodyweight, movementType: .isolation, isPopular: true, difficulty: 1),
        ExerciseModel(name: "Plank to Push-up", category: .core, primaryMuscles: ["Core"], secondaryMuscles: ["Chest", "Triceps"], equipment: .bodyweight, movementType: .compound, isPopular: false, difficulty: 3),
        ExerciseModel(name: "Reverse Crunches", category: .core, primaryMuscles: ["Lower Abs"], equipment: .bodyweight, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Russian Twists", category: .core, primaryMuscles: ["Obliques"], equipment: .bodyweight, movementType: .isolation, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Side Plank", category: .core, primaryMuscles: ["Obliques", "Core"], equipment: .bodyweight, movementType: .isolation, isPopular: false, difficulty: 2),
        ExerciseModel(name: "Sit-ups", category: .core, primaryMuscles: ["Abs"], equipment: .bodyweight, movementType: .isolation, isPopular: true, difficulty: 1),
        ExerciseModel(name: "V-Ups", category: .core, primaryMuscles: ["Abs"], equipment: .bodyweight, movementType: .isolation, isPopular: false, difficulty: 3),
        ExerciseModel(name: "Wood Chops", category: .core, primaryMuscles: ["Obliques"], equipment: .cable, movementType: .isolation, isPopular: true, difficulty: 2),
        
        // CARDIO EXERCISES
        ExerciseModel(name: "Treadmill Running", category: .cardio, primaryMuscles: ["Legs", "Cardio System"], equipment: .cardio_machine, movementType: .cardio, isPopular: true, difficulty: 2),
        ExerciseModel(name: "Stationary Bike", category: .cardio, primaryMuscles: ["Legs", "Cardio System"], equipment: .cardio_machine, movementType: .cardio, isPopular: true, difficulty: 1),
        ExerciseModel(name: "Elliptical", category: .cardio, primaryMuscles: ["Full Body", "Cardio System"], equipment: .cardio_machine, movementType: .cardio, isPopular: true, difficulty: 1),
        ExerciseModel(name: "Rowing Machine", category: .cardio, primaryMuscles: ["Back", "Legs", "Cardio System"], equipment: .cardio_machine, movementType: .cardio, isPopular: false, difficulty: 3),
        ExerciseModel(name: "Burpees", category: .cardio, primaryMuscles: ["Full Body"], equipment: .bodyweight, movementType: .cardio, isPopular: false, difficulty: 4),
        
        // FULL BODY
        ExerciseModel(name: "Thrusters", category: .fullBody, primaryMuscles: ["Legs", "Shoulders"], secondaryMuscles: ["Core", "Triceps"], equipment: .dumbbell, movementType: .compound, isPopular: false, difficulty: 4),
        ExerciseModel(name: "Man Makers", category: .fullBody, primaryMuscles: ["Full Body"], equipment: .dumbbell, movementType: .compound, isPopular: false, difficulty: 5)
    ]
    
    // Helper methods for filtering exercises
    func exercises(for category: ExerciseCategory) -> [ExerciseModel] {
        return allExercises.filter { $0.category == category }
    }
    
    func popularExercises() -> [ExerciseModel] {
        return allExercises.filter { $0.isPopular }
    }
    
    func exercises(using equipment: Equipment) -> [ExerciseModel] {
        return allExercises.filter { $0.equipment == equipment }
    }
    
    func exercises(byDifficulty difficulty: Int) -> [ExerciseModel] {
        return allExercises.filter { $0.difficulty == difficulty }
    }
    
    func searchExercises(query: String) -> [ExerciseModel] {
        let lowercaseQuery = query.lowercased()
        return allExercises.filter { 
            $0.name.lowercased().contains(lowercaseQuery) ||
            $0.primaryMuscles.joined(separator: " ").lowercased().contains(lowercaseQuery) ||
            $0.category.rawValue.lowercased().contains(lowercaseQuery)
        }
    }
}

struct WorkoutSessionSummary: Codable, Identifiable {
    var id = UUID()
    let name: String
    let date: Date
    var duration: Int // in minutes
    var totalVolume: Double // in kg
    let averageHeartRate: Int?
    var exercises: [ExerciseSummary]
    let status: WorkoutStatus
}

struct ExerciseSummary: Codable, Identifiable {
    var id = UUID()
    let name: String
    var sets: [ExerciseSet]
    let exerciseType: String // "Triceps Rope Pushdown", "Chest Press (Machine)", etc.
    var restTimerSeconds: Int = 90 // Default rest time in seconds
    
    // Initialize with smart default rest time based on exercise name
    init(name: String, exerciseType: String, sets: [ExerciseSet] = []) {
        self.name = name
        self.exerciseType = exerciseType
        self.sets = sets
        self.restTimerSeconds = Self.getRecommendedRestTime(for: name)
    }
    
    // Smart rest time recommendations based on exercise type
    static func getRecommendedRestTime(for exerciseName: String) -> Int {
        let exercise = exerciseName.lowercased()
        
        // Compound movements - longer rest (3+ minutes)
        if exercise.contains("bench press") || exercise.contains("squat") || 
           exercise.contains("deadlift") || exercise.contains("row") ||
           exercise.contains("pull up") || exercise.contains("chin up") ||
           exercise.contains("overhead press") || exercise.contains("military press") {
            return 180 // 3 minutes
        }
        
        // Heavy isolation or secondary compounds - medium rest (2 minutes)  
        else if exercise.contains("lat pulldown") || exercise.contains("leg press") ||
                exercise.contains("shoulder press") || exercise.contains("dip") ||
                exercise.contains("close grip") || exercise.contains("hip thrust") {
            return 120 // 2 minutes
        }
        
        // Light isolation movements - short rest (60-90 seconds)
        else if exercise.contains("curl") || exercise.contains("extension") ||
                exercise.contains("raise") || exercise.contains("fly") ||
                exercise.contains("calf") || exercise.contains("tricep") {
            return 60 // 1 minute
        }
        
        // Default for unknown exercises
        else {
            return 90 // 1.5 minutes
        }
    }
}

enum WorkoutStatus: String, Codable, CaseIterable {
    case completed = "Completed"
    case inProgress = "In Progress"
    case planned = "Planned"
}

