import SwiftUI
import Foundation

// MARK: - Micronutrient Views

struct ImprovedMicronutrientView: View {
    let breakfast: [DiaryFoodItem]
    let lunch: [DiaryFoodItem]
    let dinner: [DiaryFoodItem]
    let snacks: [DiaryFoodItem]
    @State private var showingDetailedInsights = false
    @State private var historicalAnalysis: HistoricalNutrientAnalysis?
    @State private var isLoading = false

    private var allFoods: [DiaryFoodItem] {
        breakfast + lunch + dinner + snacks
    }

    var body: some View {
        Group {
            if allFoods.isEmpty {
                // Initial state - no foods added yet
                Button(action: {
                    showingDetailedInsights = true
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(gradient: Gradient(colors: [.green, .mint]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 32, height: 32)

                            Image(systemName: "leaf.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("View Vitamin & Mineral Insights")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)

                            Text("Track your micronutrients over time")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Show insights button with loading indicator
                Button(action: {
                    loadHistoricalData()
                }) {
                    HStack(spacing: 12) {
                        if isLoading {
                            ProgressView()
                                .frame(width: 32, height: 32)
                        } else {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 32, height: 32)

                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("View Nutritional Insights")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)

                            Text(isLoading ? "Analyzing your nutrition history..." : "See what vitamins & minerals you're missing")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isLoading)
            }
        }
        .sheet(isPresented: $showingDetailedInsights) {
            DetailedMicronutrientInsightsView(
                historicalAnalysis: historicalAnalysis,
                todaysFoods: allFoods
            )
        }
    }

    // MARK: - Private Methods

    private func loadHistoricalData() {
        isLoading = true

        Task {
            do {
                // Load past 30 days of food entries
                let entries = try await FirebaseManager.shared.getFoodEntriesForPeriod(days: 30)

                // Analyze the historical data
                let analysis = analyzeHistoricalNutrition(entries: entries)

                await MainActor.run {
                    self.historicalAnalysis = analysis
                    self.isLoading = false
                    self.showingDetailedInsights = true
                }
            } catch {
                print("Error loading historical data: \(error)")
                await MainActor.run {
                    // Show anyway with limited data
                    self.isLoading = false
                    self.showingDetailedInsights = true
                }
            }
        }
    }

    private func analyzeHistoricalNutrition(entries: [FoodEntry]) -> HistoricalNutrientAnalysis {
        // Group entries by week
        let calendar = Calendar.current
        var weeklyData: [Int: WeeklyNutrientData] = [:]

        for entry in entries {
            let weekOfYear = calendar.component(.weekOfYear, from: entry.date)

            if weeklyData[weekOfYear] == nil {
                weeklyData[weekOfYear] = WeeklyNutrientData()
            }

            weeklyData[weekOfYear]?.addEntry(entry)
        }

        // Calculate average nutrient intake
        let weeks = weeklyData.values
        guard !weeks.isEmpty else {
            return HistoricalNutrientAnalysis(
                totalDaysTracked: 0,
                averageDailyProtein: 0,
                averageDailyFiber: 0,
                averageDailyIron: 0,
                averageDailyCalcium: 0,
                averageDailyVitaminC: 0,
                averageDailyOmega3: 0,
                deficientNutrients: [],
                adequateNutrients: [],
                recommendedFoods: []
            )
        }

        let avgProtein = weeks.map { $0.protein }.reduce(0, +) / Double(weeks.count)
        let avgFiber = weeks.map { $0.fiber }.reduce(0, +) / Double(weeks.count)
        let avgIron = weeks.map { $0.estimatedIron }.reduce(0, +) / Double(weeks.count)
        let avgCalcium = weeks.map { $0.estimatedCalcium }.reduce(0, +) / Double(weeks.count)
        let avgVitaminC = weeks.map { $0.estimatedVitaminC }.reduce(0, +) / Double(weeks.count)
        let avgOmega3 = weeks.map { $0.estimatedOmega3 }.reduce(0, +) / Double(weeks.count)

        // Identify deficiencies (using daily recommended values)
        var deficient: [NutrientDeficiency] = []
        var adequate: [String] = []

        // Protein: RDA ~50g/day
        if avgProtein < 40 {
            deficient.append(NutrientDeficiency(
                name: "Protein",
                currentIntake: avgProtein,
                recommendedIntake: 50,
                severity: avgProtein < 30 ? .high : .moderate,
                foodSources: ["chicken breast", "fish", "eggs", "tofu", "lentils", "Greek yogurt"]
            ))
        } else {
            adequate.append("Protein")
        }

        // Fiber: RDA ~25-30g/day
        if avgFiber < 20 {
            deficient.append(NutrientDeficiency(
                name: "Fiber",
                currentIntake: avgFiber,
                recommendedIntake: 25,
                severity: avgFiber < 15 ? .high : .moderate,
                foodSources: ["oats", "beans", "broccoli", "apples", "whole grain bread", "chia seeds"]
            ))
        } else {
            adequate.append("Fiber")
        }

        // Iron: RDA ~18mg/day
        if avgIron < 14 {
            deficient.append(NutrientDeficiency(
                name: "Iron",
                currentIntake: avgIron,
                recommendedIntake: 18,
                severity: avgIron < 10 ? .high : .moderate,
                foodSources: ["spinach", "red meat", "lentils", "fortified cereals", "dark chocolate"]
            ))
        } else {
            adequate.append("Iron")
        }

        // Calcium: RDA ~1000mg/day
        if avgCalcium < 800 {
            deficient.append(NutrientDeficiency(
                name: "Calcium",
                currentIntake: avgCalcium,
                recommendedIntake: 1000,
                severity: avgCalcium < 600 ? .high : .moderate,
                foodSources: ["milk", "cheese", "yogurt", "fortified plant milk", "sardines", "kale"]
            ))
        } else {
            adequate.append("Calcium")
        }

        // Vitamin C: RDA ~90mg/day
        if avgVitaminC < 70 {
            deficient.append(NutrientDeficiency(
                name: "Vitamin C",
                currentIntake: avgVitaminC,
                recommendedIntake: 90,
                severity: avgVitaminC < 50 ? .high : .moderate,
                foodSources: ["oranges", "strawberries", "bell peppers", "broccoli", "kiwi"]
            ))
        } else {
            adequate.append("Vitamin C")
        }

        // Omega-3: RDA ~1-2g/day
        if avgOmega3 < 1.0 {
            deficient.append(NutrientDeficiency(
                name: "Omega-3 Fatty Acids",
                currentIntake: avgOmega3,
                recommendedIntake: 1.5,
                severity: avgOmega3 < 0.5 ? .high : .moderate,
                foodSources: ["salmon", "sardines", "walnuts", "chia seeds", "flaxseed", "hemp seeds"]
            ))
        } else {
            adequate.append("Omega-3")
        }

        // Generate personalized recommendations
        let recommendations = generateRecommendations(deficiencies: deficient)

        return HistoricalNutrientAnalysis(
            totalDaysTracked: entries.count > 0 ? min(30, entries.count) : 0,
            averageDailyProtein: avgProtein,
            averageDailyFiber: avgFiber,
            averageDailyIron: avgIron,
            averageDailyCalcium: avgCalcium,
            averageDailyVitaminC: avgVitaminC,
            averageDailyOmega3: avgOmega3,
            deficientNutrients: deficient,
            adequateNutrients: adequate,
            recommendedFoods: recommendations
        )
    }

    private func generateRecommendations(deficiencies: [NutrientDeficiency]) -> [String] {
        guard !deficiencies.isEmpty else {
            return ["Keep up the great work! Your nutrition looks balanced."]
        }

        var recommendations: [String] = []

        // Prioritize high-severity deficiencies
        let highPriority = deficiencies.filter { $0.severity == .high }
        let moderatePriority = deficiencies.filter { $0.severity == .moderate }

        if !highPriority.isEmpty {
            let nutrient = highPriority[0]
            recommendations.append("You're averaging \(String(format: "%.1f", nutrient.currentIntake))\(nutrient.unit) of \(nutrient.name) daily, but need \(String(format: "%.1f", nutrient.recommendedIntake))\(nutrient.unit). Try adding \(nutrient.foodSources.prefix(2).joined(separator: " or ")) to your meals.")
        }

        if !moderatePriority.isEmpty {
            let nutrient = moderatePriority[0]
            recommendations.append("Consider increasing your \(nutrient.name) intake by eating more \(nutrient.foodSources.prefix(3).joined(separator: ", ")).")
        }

        return recommendations
    }
}

// MARK: - Data Models

struct HistoricalNutrientAnalysis {
    let totalDaysTracked: Int
    let averageDailyProtein: Double
    let averageDailyFiber: Double
    let averageDailyIron: Double
    let averageDailyCalcium: Double
    let averageDailyVitaminC: Double
    let averageDailyOmega3: Double
    let deficientNutrients: [NutrientDeficiency]
    let adequateNutrients: [String]
    let recommendedFoods: [String]
}

struct NutrientDeficiency: Identifiable {
    let id = UUID()
    let name: String
    let currentIntake: Double
    let recommendedIntake: Double
    let severity: DeficiencySeverity
    let foodSources: [String]

    var unit: String {
        switch name {
        case "Protein", "Fiber": return "g"
        case "Iron", "Calcium", "Vitamin C": return "mg"
        case "Omega-3 Fatty Acids": return "g"
        default: return ""
        }
    }

    var percentageOfTarget: Double {
        guard recommendedIntake > 0 else { return 0 }
        return (currentIntake / recommendedIntake) * 100
    }
}

enum DeficiencySeverity {
    case high
    case moderate
    case low

    var color: Color {
        switch self {
        case .high: return .red
        case .moderate: return .orange
        case .low: return .yellow
        }
    }

    var label: String {
        switch self {
        case .high: return "Significantly Low"
        case .moderate: return "Below Target"
        case .low: return "Slightly Low"
        }
    }
}

class WeeklyNutrientData {
    var protein: Double = 0
    var fiber: Double = 0
    var estimatedIron: Double = 0
    var estimatedCalcium: Double = 0
    var estimatedVitaminC: Double = 0
    var estimatedOmega3: Double = 0
    var entryCount: Int = 0

    func addEntry(_ entry: FoodEntry) {
        protein += entry.protein
        fiber += (entry.fiber ?? 0)

        // Estimate micronutrients based on macros (simplified)
        estimatedIron += entry.protein * 0.5  // ~0.5mg iron per gram of protein
        estimatedCalcium += entry.protein * 4.0  // ~4mg calcium per gram of protein
        estimatedVitaminC += (entry.fiber ?? 0) * 3.0  // ~3mg vitamin C per gram of fiber
        estimatedOmega3 += entry.fat * 0.02  // ~2% of fat could be omega-3

        entryCount += 1
    }
}

// MARK: - Detailed Insights View

struct DetailedMicronutrientInsightsView: View {
    let historicalAnalysis: HistoricalNutrientAnalysis?
    let todaysFoods: [DiaryFoodItem]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Nutritional Insights")
                            .font(.system(size: 28, weight: .bold))

                        if let analysis = historicalAnalysis, analysis.totalDaysTracked > 0 {
                            Text("Based on \(analysis.totalDaysTracked) days of food tracking")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        } else {
                            Text("Start logging food to see personalised insights")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    if let analysis = historicalAnalysis, analysis.totalDaysTracked > 0 {
                        // Deficiencies Section
                        if !analysis.deficientNutrients.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Nutrients to Focus On")
                                    .font(.system(size: 20, weight: .bold))
                                    .padding(.horizontal)

                                ForEach(analysis.deficientNutrients) { deficiency in
                                    DeficiencyCard(deficiency: deficiency)
                                        .padding(.horizontal)
                                }
                            }
                        }

                        // Adequate Nutrients Section
                        if !analysis.adequateNutrients.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("You're Doing Well With")
                                    .font(.system(size: 20, weight: .bold))
                                    .padding(.horizontal)

                                // Simple vertical list instead of flow layout
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(analysis.adequateNutrients, id: \.self) { nutrient in
                                        HStack(spacing: 6) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.green)

                                            Text(nutrient)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.primary)

                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        // Recommendations Section
                        if !analysis.recommendedFoods.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Personalised Recommendations")
                                    .font(.system(size: 20, weight: .bold))
                                    .padding(.horizontal)

                                ForEach(analysis.recommendedFoods, id: \.self) { recommendation in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "lightbulb.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.orange)
                                            .padding(.top, 2)

                                        Text(recommendation)
                                            .font(.system(size: 14))
                                            .foregroundColor(.primary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                }
                            }
                        }
                    } else {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "chart.bar.doc.horizontal")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)

                            Text("No Data Yet")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Text("Log your meals for a few days to get personalised vitamin and mineral insights")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }

                    // Info Footer
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About This Analysis")
                            .font(.system(size: 16, weight: .semibold))

                        Text("This analysis tracks your food intake over the past 30 days to identify patterns in vitamin and mineral consumption. Recommendations are based on standard daily values for adults.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Deficiency Card

struct DeficiencyCard: View {
    let deficiency: NutrientDeficiency

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(deficiency.name)
                        .font(.system(size: 18, weight: .semibold))

                    HStack(spacing: 6) {
                        Circle()
                            .fill(deficiency.severity.color)
                            .frame(width: 8, height: 8)

                        Text(deficiency.severity.label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(deficiency.severity.color)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(String(format: "%.1f", deficiency.currentIntake))\(deficiency.unit)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)

                    Text("of \(String(format: "%.1f", deficiency.recommendedIntake))\(deficiency.unit)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(deficiency.severity.color)
                        .frame(width: geometry.size.width * CGFloat(min(deficiency.percentageOfTarget / 100, 1.0)), height: 8)
                }
            }
            .frame(height: 8)

            // Food sources
            VStack(alignment: .leading, spacing: 4) {
                Text("Good sources:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                Text(deficiency.foodSources.prefix(4).joined(separator: ", "))
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
