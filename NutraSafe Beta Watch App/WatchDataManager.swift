import SwiftUI
import Foundation

class WatchDataManager: ObservableObject {
    @Published var todayEntries: [WatchFoodEntry] = []
    @Published var nutritionSummary: WatchNutritionSummary?
    @Published var healthData: WatchHealthData?
    @Published var quickFoods: [WatchQuickFood] = []
    @Published var isLoading = false
    
    init() {
        loadSampleData()
    }
    
    func updateTodayData(_ entries: [WatchFoodEntry]) {
        DispatchQueue.main.async {
            self.todayEntries = entries
            self.calculateNutritionSummary()
        }
    }
    
    func updateNutritionSummary(_ summary: WatchNutritionSummary) {
        DispatchQueue.main.async {
            self.nutritionSummary = summary
        }
    }
    
    func updateHealthData(_ health: WatchHealthData) {
        DispatchQueue.main.async {
            self.healthData = health
        }
    }
    
    func updateQuickFoods(_ foods: [WatchQuickFood]) {
        DispatchQueue.main.async {
            self.quickFoods = foods
        }
    }
    
    private func calculateNutritionSummary() {
        let totalCalories = todayEntries.reduce(0) { $0 + $1.calories }
        let totalProtein = todayEntries.reduce(0) { $0 + $1.protein }
        let totalCarbs = todayEntries.reduce(0) { $0 + $1.carbs }
        let totalFat = todayEntries.reduce(0) { $0 + $1.fat }
        
        let grades = todayEntries.map { $0.grade }
        let averageGrade = calculateAverageGrade(grades: grades)
        
        nutritionSummary = WatchNutritionSummary(
            totalCalories: totalCalories,
            totalProtein: totalProtein,
            totalCarbs: totalCarbs,
            totalFat: totalFat,
            averageGrade: averageGrade,
            foodCount: todayEntries.count,
            date: Date()
        )
    }
    
    private func calculateAverageGrade(grades: [String]) -> String {
        guard !grades.isEmpty else { return "N/A" }
        
        let gradeValues = grades.compactMap { gradeToNumber($0) }
        guard !gradeValues.isEmpty else { return "N/A" }
        
        let average = gradeValues.reduce(0, +) / Double(gradeValues.count)
        return numberToGrade(average)
    }
    
    private func gradeToNumber(_ grade: String) -> Double? {
        switch grade.uppercased() {
        case "A+": return 4.3
        case "A": return 4.0
        case "B+": return 3.3
        case "B": return 3.0
        case "C+": return 2.3
        case "C": return 2.0
        case "D+": return 1.3
        case "D": return 1.0
        case "F": return 0.0
        default: return nil
        }
    }
    
    private func numberToGrade(_ number: Double) -> String {
        switch number {
        case 4.15...: return "A+"
        case 3.5..<4.15: return "A"
        case 3.15..<3.5: return "B+"
        case 2.5..<3.15: return "B"
        case 2.15..<2.5: return "C+"
        case 1.5..<2.15: return "C"
        case 1.15..<1.5: return "D+"
        case 0.5..<1.15: return "D"
        default: return "F"
        }
    }
    
    private func loadSampleData() {
        quickFoods = [
            WatchQuickFood(id: "1", name: "Apple", calories: 95, grade: "A+"),
            WatchQuickFood(id: "2", name: "Banana", calories: 105, grade: "A"),
            WatchQuickFood(id: "3", name: "Greek Yogurt", calories: 130, grade: "A"),
            WatchQuickFood(id: "4", name: "Almonds (1oz)", calories: 164, grade: "B+"),
            WatchQuickFood(id: "5", name: "Water", calories: 0, grade: "A+")
        ]
    }
}