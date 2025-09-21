import SwiftUI
import Foundation

struct WatchFoodEntry: Identifiable, Codable {
    let id: String
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let grade: String
    let timestamp: Date
    let servingSize: String
    
    var gradeColor: Color {
        switch grade.uppercased() {
        case "A+", "A":
            return .green
        case "B+", "B":
            return .blue
        case "C+", "C":
            return .yellow
        case "D+", "D":
            return .orange
        case "F":
            return .red
        default:
            return .gray
        }
    }
}

struct WatchNutritionSummary: Codable {
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let averageGrade: String
    let foodCount: Int
    let date: Date
    
    var averageGradeColor: Color {
        switch averageGrade.uppercased() {
        case "A+", "A":
            return .green
        case "B+", "B":
            return .blue
        case "C+", "C":
            return .yellow
        case "D+", "D":
            return .orange
        case "F":
            return .red
        default:
            return .gray
        }
    }
}

struct WatchHealthData: Codable {
    let steps: Int
    let exerciseCalories: Double
    let heartRate: Int?
    let date: Date
}

struct WatchQuickFood: Identifiable, Codable {
    let id: String
    let name: String
    let calories: Double
    let grade: String
    
    var gradeColor: Color {
        switch grade.uppercased() {
        case "A+", "A":
            return .green
        case "B+", "B":
            return .blue
        case "C+", "C":
            return .yellow
        case "D+", "D":
            return .orange
        case "F":
            return .red
        default:
            return .gray
        }
    }
}