//
//  NutritionScoreViews.swift
//  NutraSafe Beta
//
//  Nutrition scoring display components extracted from ContentView.swift
//

import SwiftUI

// MARK: - Nutrition Score View
struct NutritionScoreView: View {
    let grade: String
    let gradientColors: [Color]
    
    var body: some View {
        Text(grade)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 40, height: 40)
            .background(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Circle())
    }
}

// MARK: - Modern Nutrition Score
struct ModernNutritionScore: View {
    let grade: String
    let size: CGFloat
    
    private var gradientColors: [Color] {
        switch grade {
        case "A+", "A": return [Color.green, Color.green.opacity(0.8)]
        case "B": return [Color.blue, Color.blue.opacity(0.8)]
        case "C": return [Color.yellow, Color.orange]
        case "D": return [Color.orange, Color.red.opacity(0.8)]
        case "F": return [Color.red, Color.red.opacity(0.7)]
        default: return [Color.gray, Color.gray.opacity(0.8)]
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            
            Text(grade)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Nutrition Score Detail View
struct NutritionScoreDetailView: View {
    let food: FoodSearchResult
    @Binding var isPresented: Bool
    
    private var nutritionGrade: String {
        calculateNutritionGrade(for: food)
    }
    
    private var gradeColor: Color {
        switch nutritionGrade {
        case "A+", "A": return .green
        case "B": return .blue
        case "C": return .yellow
        case "D": return .orange
        case "F": return .red
        default: return .gray
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Grade Display
                    VStack(spacing: 16) {
                        ModernNutritionScore(grade: nutritionGrade, size: 120)
                        
                        Text("Nutrition Grade")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(gradeExplanation)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Scoring Breakdown
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Scoring Breakdown")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        ForEach(scoringFactors, id: \.title) { factor in
                            GradeExplanationRow(
                                title: factor.title,
                                value: factor.value,
                                status: factor.status,
                                description: factor.description
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Additional Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How We Calculate Your Grade")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Our nutrition grading system evaluates foods based on multiple factors including caloric density, macronutrient balance, sugar content, sodium levels, and fiber content. Foods with better nutritional profiles receive higher grades.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Nutrition Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private var gradeExplanation: String {
        switch nutritionGrade {
        case "A+": return "Excellent nutritional value! This food is highly nutritious."
        case "A": return "Great choice! This food has very good nutritional value."
        case "B": return "Good nutritional value with minor areas for improvement."
        case "C": return "Average nutritional value. Consider in moderation."
        case "D": return "Below average nutritional value. Limit consumption."
        case "F": return "Poor nutritional value. Best avoided or eaten rarely."
        default: return "Nutritional information is being evaluated."
        }
    }
    
    private var scoringFactors: [(title: String, value: String, status: String, description: String)] {
        var factors: [(String, String, String, String)] = []
        
        // Caloric Density
        let caloricDensityStatus = food.calories < 150 ? "good" : food.calories < 300 ? "moderate" : "poor"
        factors.append(("Caloric Density", "\(Int(food.calories)) cal", caloricDensityStatus, "Energy per serving"))
        
        // Sugar Content
        let sugarStatus = food.sugar < 5 ? "good" : food.sugar < 15 ? "moderate" : "poor"
        factors.append(("Sugar Content", String(format: "%.1fg", food.sugar), sugarStatus, "Added and natural sugars"))
        
        // Sodium Level
        let sodiumStatus = food.sodium < 140 ? "good" : food.sodium < 400 ? "moderate" : "poor"
        factors.append(("Sodium Level", String(format: "%.0fmg", food.sodium), sodiumStatus, "Salt content"))
        
        // Fiber Content
        let fiberStatus = food.fiber > 3 ? "good" : food.fiber > 1 ? "moderate" : "poor"
        factors.append(("Fiber Content", String(format: "%.1fg", food.fiber), fiberStatus, "Dietary fiber"))
        
        // Protein Quality
        let proteinStatus = food.protein > 10 ? "good" : food.protein > 3 ? "moderate" : "poor"
        factors.append(("Protein Content", String(format: "%.1fg", food.protein), proteinStatus, "Protein per serving"))
        
        return factors
    }
    
    private func calculateNutritionGrade(for food: FoodSearchResult) -> String {
        var score = 100.0
        
        // Penalize high calories
        if food.calories > 400 { score -= 30 }
        else if food.calories > 250 { score -= 15 }
        
        // Penalize high sugar
        if food.sugar > 20 { score -= 25 }
        else if food.sugar > 10 { score -= 15 }
        
        // Penalize high sodium
        if food.sodium > 500 { score -= 20 }
        else if food.sodium > 250 { score -= 10 }
        
        // Reward fiber
        if food.fiber > 5 { score += 15 }
        else if food.fiber > 2 { score += 5 }
        
        // Reward protein
        if food.protein > 15 { score += 10 }
        else if food.protein > 7 { score += 5 }
        
        // Convert score to grade
        switch score {
        case 90...: return "A+"
        case 80..<90: return "A"
        case 70..<80: return "B"
        case 60..<70: return "C"
        case 50..<60: return "D"
        default: return "F"
        }
    }
}

// MARK: - Grade Explanation Row
struct GradeExplanationRow: View {
    let title: String
    let value: String
    let status: String
    let description: String
    
    private var statusColor: Color {
        switch status {
        case "good": return .green
        case "moderate": return .orange
        case "poor": return .red
        default: return .gray
        }
    }
    
    private var statusIcon: String {
        switch status {
        case "good": return "checkmark.circle.fill"
        case "moderate": return "exclamationmark.circle.fill"
        case "poor": return "xmark.circle.fill"
        default: return "questionmark.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .font(.system(size: 24))
                .foregroundColor(statusColor)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(value)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(statusColor)
                }
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}