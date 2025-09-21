import SwiftUI

struct NutritionScoreView: View {
    @EnvironmentObject var watchDataManager: WatchDataManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Nutrition Score")
                        .font(.headline)
                        .padding(.top)
                    
                    if let summary = watchDataManager.nutritionSummary {
                        // Main Grade Display
                        VStack(spacing: 8) {
                            Text("Today's Grade")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(summary.averageGrade)
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(summary.averageGradeColor)
                            
                            Text(gradeDescription(summary.averageGrade))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding()
                        .background(summary.averageGradeColor.opacity(0.1))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Grade Breakdown
                        GradeBreakdownView()
                        
                        // Daily Progress
                        DailyProgressView(summary: summary)
                        
                    } else {
                        VStack {
                            ProgressView()
                                .padding()
                            Text("Calculating nutrition score...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }
            }
        }
    }
    
    private func gradeDescription(_ grade: String) -> String {
        switch grade.uppercased() {
        case "A+": return "Exceptional nutrition choices!"
        case "A": return "Excellent nutrition today!"
        case "B+", "B": return "Good nutrition choices"
        case "C+", "C": return "Average nutrition today"
        case "D+", "D": return "Room for improvement"
        case "F": return "Focus on healthier choices"
        default: return "Keep tracking your foods"
        }
    }
}

struct GradeBreakdownView: View {
    @EnvironmentObject var watchDataManager: WatchDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Food Grades Today")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal)
            
            if watchDataManager.todayEntries.isEmpty {
                Text("No foods logged yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                let gradeBreakdown = calculateGradeBreakdown()
                
                LazyVStack(spacing: 4) {
                    ForEach(gradeBreakdown.sorted(by: { $0.key < $1.key }), id: \.key) { grade, count in
                        HStack {
                            Text(grade)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(gradeColor(grade))
                                .frame(width: 24, height: 20)
                                .background(gradeColor(grade).opacity(0.2))
                                .cornerRadius(8)
                            
                            Text("× \(count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            // Progress bar
                            GeometryReader { geometry in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(gradeColor(grade).opacity(0.3))
                                    .frame(height: 4)
                                    .overlay(
                                        HStack {
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(gradeColor(grade))
                                                .frame(width: geometry.size.width * CGFloat(count) / CGFloat(watchDataManager.todayEntries.count), height: 4)
                                            Spacer(minLength: 0)
                                        }
                                    )
                            }
                            .frame(height: 4)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func calculateGradeBreakdown() -> [String: Int] {
        var breakdown: [String: Int] = [:]
        
        for entry in watchDataManager.todayEntries {
            breakdown[entry.grade, default: 0] += 1
        }
        
        return breakdown
    }
    
    private func gradeColor(_ grade: String) -> Color {
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

struct DailyProgressView: View {
    let summary: WatchNutritionSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Progress")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                // Calories progress (assuming 2000 cal target)
                ProgressRow(
                    title: "Calories",
                    current: Int(summary.totalCalories),
                    target: 2000,
                    unit: "cal",
                    color: .blue
                )
                
                // Protein progress (assuming 150g target)
                ProgressRow(
                    title: "Protein",
                    current: Int(summary.totalProtein),
                    target: 150,
                    unit: "g",
                    color: .red
                )
                
                // Foods logged
                HStack {
                    Text("Foods Logged")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(summary.foodCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ProgressRow: View {
    let title: String
    let current: Int
    let target: Int
    let unit: String
    let color: Color
    
    private var progress: Double {
        min(Double(current) / Double(target), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(current) / \(target) \(unit)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(0.3))
                    .frame(height: 4)
                    .overlay(
                        HStack {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(color)
                                .frame(width: geometry.size.width * progress, height: 4)
                            Spacer(minLength: 0)
                        }
                    )
            }
            .frame(height: 4)
        }
        .padding(.horizontal)
    }
}

#Preview {
    NutritionScoreView()
        .environmentObject(WatchDataManager())
}