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
    @EnvironmentObject var firebaseManager: FirebaseManager

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
                    .padding(.vertical, AppSpacing.small)
                    .padding(.horizontal, AppSpacing.medium)
                }
                .buttonStyle(SpringyButtonStyle())
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.medium)
                        .fill(AppColors.cardBackgroundElevated)
                )
                .cardShadow()
            } else {
                // Micronutrient insights button with loading indicator
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
                                        .fill(LinearGradient(gradient: Gradient(colors: [.green, .mint]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 32, height: 32)

                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Vitamin & Mineral Insights")
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
                        .padding(.vertical, AppSpacing.small)
                        .padding(.horizontal, AppSpacing.medium)
                    }
                    .buttonStyle(SpringyButtonStyle())
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.medium)
                            .fill(AppColors.cardBackgroundElevated)
                    )
                    .cardShadow()
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

                // Load user settings for macro targets
                let settings = try await firebaseManager.getUserSettings()
                let calorieGoal = Double(settings.caloricGoal ?? 2000)
                let proteinPercent = Double(settings.proteinPercent ?? 30) / 100.0

                // Calculate daily targets from settings
                // Protein: 4 cal/g
                let proteinTarget = (calorieGoal * proteinPercent) / 4.0
                let fiberTarget: Double = 30.0  // Standard recommendation

                // Analyze the historical data with settings-based targets
                let analysis = analyzeHistoricalNutrition(entries: entries, proteinTarget: proteinTarget, fiberTarget: fiberTarget)

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

    // MARK: - Nutrient Food Mapping

    private func getNutrientsInFood(_ foodName: String, entry: FoodEntry) -> [String] {
        let name = foodName.lowercased()
        var nutrients: [String] = []

        // Use real micronutrient data if available, otherwise fall back to keyword matching
        if let micronutrients = entry.micronutrientProfile {
            // Real data from ingredient analysis - check vitamins
            if let vitaminC = micronutrients.vitamins["vitaminC"], vitaminC > 1 {
                nutrients.append("Vitamin C")
            }
            if let vitaminD = micronutrients.vitamins["vitaminD"], vitaminD > 0.5 {
                nutrients.append("Vitamin D")
            }
            // Check for any B vitamins
            let bVitamins = ["thiamine", "riboflavin", "niacin", "pantothenicAcid", "vitaminB6", "biotin", "folate", "vitaminB12"]
            let hasBVitamins = bVitamins.contains { vitaminKey in
                if let amount = micronutrients.vitamins[vitaminKey], amount > 0.1 {
                    return true
                }
                return false
            }
            if hasBVitamins {
                nutrients.append("B Vitamins")
            }

            // Real data from ingredient analysis - check minerals
            if let calcium = micronutrients.minerals["calcium"], calcium > 50 {
                nutrients.append("Calcium")
            }
            if let iron = micronutrients.minerals["iron"], iron > 0.5 {
                nutrients.append("Iron")
            }
            if let magnesium = micronutrients.minerals["magnesium"], magnesium > 20 {
                nutrients.append("Magnesium")
            }
            if let zinc = micronutrients.minerals["zinc"], zinc > 0.5 {
                nutrients.append("Zinc")
            }

            // Omega-3 estimation (still use fat as proxy)
            if entry.fat > 10 || name.contains("salmon") || name.contains("tuna") || name.contains("mackerel") ||
               name.contains("sardine") || name.contains("walnut") || name.contains("chia") ||
               name.contains("flax") || name.contains("hemp") {
                nutrients.append("Omega-3")
            }
        } else {
            // Fallback to keyword-based matching if no micronutrient profile available
            // Calcium - use legacy field if available
            if let calcium = entry.calcium, calcium > 50 {
                nutrients.append("Calcium")
            }

            // Iron - keyword-based
            if entry.protein > 15 || name.contains("beef") || name.contains("steak") || name.contains("liver") ||
               name.contains("spinach") || name.contains("kale") || name.contains("lentil") ||
               name.contains("bean") || name.contains("fortified") || name.contains("cereal") ||
               name.contains("tofu") || name.contains("quinoa") {
                nutrients.append("Iron")
            }

            // Vitamin C - keyword-based
            if name.contains("orange") || name.contains("lemon") || name.contains("lime") ||
               name.contains("strawber") || name.contains("kiwi") || name.contains("mango") ||
               name.contains("pepper") || name.contains("broccoli") || name.contains("tomato") ||
               name.contains("citrus") || name.contains("berry") {
                nutrients.append("Vitamin C")
            }

            // Omega-3 - keyword-based
            if name.contains("salmon") || name.contains("tuna") || name.contains("mackerel") ||
               name.contains("sardine") || name.contains("walnut") || name.contains("chia") ||
               name.contains("flax") || name.contains("hemp") || entry.fat > 10 {
                nutrients.append("Omega-3")
            }

            // Vitamin D - keyword-based
            if name.contains("milk") || name.contains("salmon") || name.contains("tuna") ||
               name.contains("egg") || name.contains("fortified") || name.contains("mushroom") {
                nutrients.append("Vitamin D")
            }

            // B Vitamins - keyword-based
            if name.contains("whole grain") || name.contains("brown rice") || name.contains("oat") ||
               name.contains("chicken") || name.contains("beef") || name.contains("egg") ||
               name.contains("lentil") || name.contains("bean") || name.contains("avocado") {
                nutrients.append("B Vitamins")
            }

            // Magnesium - keyword-based
            if name.contains("almond") || name.contains("cashew") || name.contains("pumpkin seed") ||
               name.contains("spinach") || name.contains("whole grain") || name.contains("black bean") ||
               name.contains("dark chocolate") || name.contains("avocado") {
                nutrients.append("Magnesium")
            }

            // Zinc - keyword-based
            if name.contains("beef") || name.contains("pork") || name.contains("chicken") ||
               name.contains("oyster") || name.contains("crab") || name.contains("cashew") ||
               name.contains("chickpea") || name.contains("lentil") {
                nutrients.append("Zinc")
            }
        }

        return nutrients
    }

    private func analyzeHistoricalNutrition(entries: [FoodEntry], proteinTarget: Double, fiberTarget: Double) -> HistoricalNutrientAnalysis {
        // Count unique days with food entries
        let calendar = Calendar.current
        let uniqueDays = Set(entries.map { calendar.startOfDay(for: $0.date) })
        let totalDaysTracked = uniqueDays.count

        // Debug: Print the dates we found
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        print("🔍 Micronutrient Analysis Debug:")
        print("   Total entries found: \(entries.count)")
        print("   Unique days: \(totalDaysTracked)")
        for date in uniqueDays.sorted() {
            let entriesOnDay = entries.filter { calendar.isDate($0.date, inSameDayAs: date) }
            print("   - \(dateFormatter.string(from: date)): \(entriesOnDay.count) entries")
        }

        guard totalDaysTracked > 0 else {
            return HistoricalNutrientAnalysis(
                totalDaysTracked: 0,
                deficientNutrients: [],
                adequateNutrients: [],
                recommendedFoods: []
            )
        }

        // Track which nutrients appear on which days, with food names
        var nutrientDaysMap: [String: Set<Date>] = [:]
        var nutrientFoodsMap: [String: Set<String>] = [:]

        // Process each entry
        for entry in entries {
            let dayStart = calendar.startOfDay(for: entry.date)
            let nutrients = getNutrientsInFood(entry.foodName, entry: entry)

            for nutrient in nutrients {
                // Track the day (for micros)
                if nutrientDaysMap[nutrient] == nil {
                    nutrientDaysMap[nutrient] = Set()
                }
                nutrientDaysMap[nutrient]?.insert(dayStart)

                // Track the food name
                if nutrientFoodsMap[nutrient] == nil {
                    nutrientFoodsMap[nutrient] = Set()
                }
                nutrientFoodsMap[nutrient]?.insert(entry.foodName)
            }
        }

        // Analyze each nutrient
        var deficient: [NutrientDeficiency] = []
        var adequate: [NutrientInfo] = []

        let allNutrients = ["Iron", "Calcium", "Vitamin C", "Omega-3", "Vitamin D", "B Vitamins", "Magnesium", "Zinc"]

        for nutrient in allNutrients {
            let foodsEaten = Array(nutrientFoodsMap[nutrient] ?? []).prefix(10).map { String($0) }

            // Day-based tracking for micronutrients
            let daysWithNutrient = nutrientDaysMap[nutrient]?.count ?? 0
            let frequency = Double(daysWithNutrient) / Double(totalDaysTracked) * 100

            // Determine threshold based on nutrient type
            let goodThreshold: Double
            let moderateThreshold: Double

            switch nutrient {
            case "Iron", "Calcium", "B Vitamins":
                // Essential micronutrients - need regular intake
                goodThreshold = 70
                moderateThreshold = 50
            case "Vitamin C", "Vitamin D":
                // Important but can be stored
                goodThreshold = 60
                moderateThreshold = 40
            default:
                // Omega-3, Magnesium, Zinc - beneficial but less frequent
                goodThreshold = 50
                moderateThreshold = 30
            }

            if frequency >= goodThreshold {
                // Doing well
                adequate.append(NutrientInfo(
                    name: nutrient,
                    daysWithNutrient: daysWithNutrient,
                    totalDays: totalDaysTracked,
                    foodsEaten: foodsEaten
                ))
            } else {
                // Determine status based on frequency
                let status: NutrientStatus
                if frequency >= 40 {
                    status = .inconsistent
                } else {
                    status = .needsTracking
                }

                deficient.append(NutrientDeficiency(
                    name: nutrient,
                    currentIntake: Double(daysWithNutrient),
                    recommendedIntake: Double(totalDaysTracked),
                    status: status,
                    foodSources: getFoodSources(for: nutrient),
                    foodsEaten: foodsEaten,
                    isFrequencyBased: true,
                    totalDays: totalDaysTracked,
                    trend: nil  // Will add trend calculation later
                ))
            }
        }

        // Generate personalized recommendations
        let recommendations = generateRecommendations(deficiencies: deficient)

        return HistoricalNutrientAnalysis(
            totalDaysTracked: totalDaysTracked,
            deficientNutrients: deficient,
            adequateNutrients: adequate,
            recommendedFoods: recommendations
        )
    }

    private func getFoodSources(for nutrient: String) -> [String] {
        switch nutrient {
        case "Iron":
            return ["spinach", "red meat", "lentils", "fortified cereals", "dark chocolate"]
        case "Calcium":
            return ["milk", "cheese", "yogurt", "fortified plant milk", "sardines", "kale"]
        case "Vitamin C":
            return ["oranges", "strawberries", "bell peppers", "broccoli", "kiwi"]
        case "Omega-3":
            return ["salmon", "sardines", "walnuts", "chia seeds", "flaxseed"]
        case "Vitamin D":
            return ["salmon", "fortified milk", "eggs", "mushrooms", "tuna"]
        case "B Vitamins":
            return ["whole grains", "eggs", "chicken", "beans", "leafy greens"]
        case "Magnesium":
            return ["almonds", "spinach", "black beans", "avocado", "dark chocolate"]
        case "Zinc":
            return ["beef", "chickpeas", "cashews", "pumpkin seeds", "oysters"]
        default:
            return []
        }
    }

    private func generateRecommendations(deficiencies: [NutrientDeficiency]) -> [String] {
        guard !deficiencies.isEmpty else {
            return ["Keep up the great work! Your nutrition looks balanced."]
        }

        var recommendations: [String] = []

        // Prioritize nutrients that need more tracking
        let needsTracking = deficiencies.filter { $0.status == .needsTracking }
        let inconsistent = deficiencies.filter { $0.status == .inconsistent }

        if !needsTracking.isEmpty {
            let nutrient = needsTracking[0]
            let days = Int(nutrient.currentIntake)
            let total = Int(nutrient.recommendedIntake)
            let percent = Int(nutrient.percentageOfTarget)

            if nutrient.isFrequencyBased {
                recommendations.append("You ate \(nutrient.name)-rich foods on \(days) of \(total) days (\(percent)%). Try adding \(nutrient.foodSources.prefix(2).joined(separator: " or ")) to more of your daily meals.")
            } else {
                recommendations.append("You had \(nutrient.name) on \(days) of \(total) days tracked. Aim to include \(nutrient.foodSources.prefix(2).joined(separator: " or ")) in more meals.")
            }
        }

        if !inconsistent.isEmpty {
            let nutrient = inconsistent[0]
            recommendations.append("Consider increasing your \(nutrient.name) intake by eating more \(nutrient.foodSources.prefix(3).joined(separator: ", ")).")
        }

        return recommendations
    }
}

// MARK: - Data Models

struct HistoricalNutrientAnalysis {
    let totalDaysTracked: Int
    let deficientNutrients: [NutrientDeficiency]
    let adequateNutrients: [NutrientInfo]
    let recommendedFoods: [String]
}

struct NutrientInfo: Identifiable {
    let id = UUID()
    let name: String
    let daysWithNutrient: Int
    let totalDays: Int
    let foodsEaten: [String]  // Actual food names eaten containing this nutrient

    var frequency: Double {
        guard totalDays > 0 else { return 0 }
        return Double(daysWithNutrient) / Double(totalDays) * 100
    }
}

struct NutrientDeficiency: Identifiable {
    let id = UUID()
    let name: String
    let currentIntake: Double  // For macros: total grams, For micros: days with nutrient
    let recommendedIntake: Double  // For macros: total grams for period, For micros: total days tracked
    let status: NutrientStatus
    let foodSources: [String]
    let foodsEaten: [String]  // Actual foods user has eaten
    let isFrequencyBased: Bool  // true for vitamins/minerals, false for macros
    let totalDays: Int  // Total days in analysis period
    let trend: TrendDirection?  // Trend compared to previous period

    var unit: String {
        if isFrequencyBased {
            return "days"
        }
        switch name {
        case "Protein", "Fiber": return "g/day"
        default: return ""
        }
    }

    var percentageOfTarget: Double {
        guard recommendedIntake > 0 else { return 0 }
        return (currentIntake / recommendedIntake) * 100
    }

    // Daily average for macros
    var dailyAverage: Double {
        guard totalDays > 0, !isFrequencyBased else { return currentIntake }
        return currentIntake / Double(totalDays)
    }

    var dailyTarget: Double {
        guard totalDays > 0, !isFrequencyBased else { return recommendedIntake }
        return recommendedIntake / Double(totalDays)
    }

    var frequencyText: String {
        if isFrequencyBased {
            let days = Int(currentIntake)
            let total = Int(recommendedIntake)
            let totalDayWord = total == 1 ? "day" : "days"
            return "\(days) of \(total) \(totalDayWord)"
        } else {
            // Show daily averages for macros
            return "\(String(format: "%.1f", dailyAverage))\(unit) of \(String(format: "%.1f", dailyTarget))\(unit)"
        }
    }

    var frequency: Double {
        guard recommendedIntake > 0 else { return 0 }
        return (currentIntake / recommendedIntake) * 100
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

// MARK: - Time Period Selection

enum TimePeriod: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"

    var days: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        }
    }
}

// MARK: - Detailed Insights View

struct DetailedMicronutrientInsightsView: View {
    let historicalAnalysis: HistoricalNutrientAnalysis?
    let todaysFoods: [DiaryFoodItem]
    @Environment(\.dismiss) var dismiss
    @State private var selectedPeriod: TimePeriod = .month
    @State private var periodAnalysis: HistoricalNutrientAnalysis?
    @State private var isLoadingPeriod = false
    @State private var showingCalendarTracker = false
    @EnvironmentObject var firebaseManager: FirebaseManager

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Nutritional Insights")
                            .font(.system(size: 28, weight: .bold))

                        if let analysis = currentAnalysis, analysis.totalDaysTracked > 0 {
                            Text("Based on \(analysis.totalDaysTracked) \(analysis.totalDaysTracked == 1 ? "day" : "days") of food tracking")
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

                    // Time Period Selector
                    HStack(spacing: 12) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Button(action: {
                                selectPeriod(period)
                            }) {
                                Text(period.rawValue)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(selectedPeriod == period ? .white : .primary)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(selectedPeriod == period ? Color.green : Color(.systemGray5))
                                    .cornerRadius(20)
                            }
                        }

                        if isLoadingPeriod {
                            ProgressView()
                                .padding(.leading, 8)
                        }
                    }
                    .padding(.horizontal)

                    // Calendar Tracker Button
                    Button(action: {
                        showingCalendarTracker = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.green)

                            Text("View Nutrient Calendar")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(AppSpacing.medium)
                    }
                    .buttonStyle(SpringyButtonStyle())
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.medium)
                            .fill(AppColors.cardBackgroundElevated)
                    )
                    .cardShadow()
                    .padding(.horizontal)

                    if let analysis = currentAnalysis, analysis.totalDaysTracked > 0 {
                        // Check if we have minimum data threshold
                        if analysis.totalDaysTracked < 3 {
                            // Show "keep tracking" message for insufficient data
                            VStack(spacing: 16) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 48))
                                    .foregroundColor(.green)

                                Text("Keep Tracking")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text("You've tracked \(analysis.totalDaysTracked) \(analysis.totalDaysTracked == 1 ? "day" : "days") so far. Track at least 3 days to see meaningful nutrient patterns.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            // Show full analysis with 3+ days of data
                            // Nutrients that could use more attention
                            if !analysis.deficientNutrients.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Nutrient Patterns")
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

                                // Rich context cards for adequate nutrients
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(analysis.adequateNutrients) { nutrient in
                                        AdequateNutrientCard(nutrient: nutrient)
                                            .padding(.horizontal)
                                    }
                                }
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
                                    .padding(AppSpacing.medium)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppRadius.medium)
                                            .fill(AppColors.cardBackgroundElevated)
                                    )
                                    .cardShadow()
                                    .padding(.horizontal)
                                }
                            }
                        }
                        }  // Close the else block for 3+ days of data
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

                        if let analysis = currentAnalysis, analysis.totalDaysTracked > 0 {
                            Text("This analysis is based on \(analysis.totalDaysTracked) \(analysis.totalDaysTracked == 1 ? "day" : "days") of food tracking. Vitamin and mineral recommendations are based on how frequently you consume foods rich in these nutrients.")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        } else {
                            Text("This analysis tracks your food intake to identify patterns in vitamin and mineral consumption. Start logging foods to see insights about which nutrients you're getting regularly.")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(AppSpacing.medium)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.medium)
                            .fill(AppColors.cardBackgroundElevated)
                    )
                    .cardShadow()
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
        .sheet(isPresented: $showingCalendarTracker) {
            NutrientCalendarTrackerView()
                .environmentObject(firebaseManager)
        }
        .onAppear {
            // Initialize with historicalAnalysis (month view)
            periodAnalysis = historicalAnalysis
        }
    }

    // MARK: - Helper Methods

    private var currentAnalysis: HistoricalNutrientAnalysis? {
        return periodAnalysis ?? historicalAnalysis
    }

    private func selectPeriod(_ period: TimePeriod) {
        guard selectedPeriod != period else { return }
        selectedPeriod = period
        isLoadingPeriod = true

        Task {
            do {
                // Load food entries for the selected period
                let entries = try await FirebaseManager.shared.getFoodEntriesForPeriod(days: period.days)

                // Load user settings for macro targets
                let settings = try await firebaseManager.getUserSettings()
                let calorieGoal = Double(settings.caloricGoal ?? 2000)
                let proteinPercent = Double(settings.proteinPercent ?? 30) / 100.0

                // Calculate daily targets from settings
                let proteinTarget = (calorieGoal * proteinPercent) / 4.0
                let fiberTarget: Double = 30.0

                // Reuse the same analysis function from ImprovedMicronutrientView
                let analysis = analyzeHistoricalNutrition(entries: entries, proteinTarget: proteinTarget, fiberTarget: fiberTarget)

                await MainActor.run {
                    self.periodAnalysis = analysis
                    self.isLoadingPeriod = false
                }
            } catch {
                print("Error loading period data: \(error)")
                await MainActor.run {
                    self.isLoadingPeriod = false
                }
            }
        }
    }

    // MARK: - Analysis Methods (Copied from ImprovedMicronutrientView)

    private func analyzeHistoricalNutrition(entries: [FoodEntry], proteinTarget: Double, fiberTarget: Double) -> HistoricalNutrientAnalysis {
        // Count unique days with food entries
        let calendar = Calendar.current
        let uniqueDays = Set(entries.map { calendar.startOfDay(for: $0.date) })
        let totalDaysTracked = uniqueDays.count

        guard totalDaysTracked > 0 else {
            return HistoricalNutrientAnalysis(
                totalDaysTracked: 0,
                deficientNutrients: [],
                adequateNutrients: [],
                recommendedFoods: []
            )
        }

        // Track which nutrients appear on which days, with food names
        var nutrientDaysMap: [String: Set<Date>] = [:]
        var nutrientFoodsMap: [String: Set<String>] = [:]

        // Process each entry
        for entry in entries {
            let dayStart = calendar.startOfDay(for: entry.date)
            let nutrients = getNutrientsInFood(entry.foodName, entry: entry)

            for nutrient in nutrients {
                // Track the day (for micros)
                if nutrientDaysMap[nutrient] == nil {
                    nutrientDaysMap[nutrient] = Set()
                }
                nutrientDaysMap[nutrient]?.insert(dayStart)

                // Track the food name
                if nutrientFoodsMap[nutrient] == nil {
                    nutrientFoodsMap[nutrient] = Set()
                }
                nutrientFoodsMap[nutrient]?.insert(entry.foodName)
            }
        }

        // Analyze each nutrient
        var deficient: [NutrientDeficiency] = []
        var adequate: [NutrientInfo] = []

        let allNutrients = ["Iron", "Calcium", "Vitamin C", "Omega-3", "Vitamin D", "B Vitamins", "Magnesium", "Zinc"]

        for nutrient in allNutrients {
            let foodsEaten = Array(nutrientFoodsMap[nutrient] ?? []).prefix(10).map { String($0) }

            // Day-based tracking for micronutrients
            let daysWithNutrient = nutrientDaysMap[nutrient]?.count ?? 0
            let frequency = Double(daysWithNutrient) / Double(totalDaysTracked) * 100

            // Determine threshold based on nutrient type
            let goodThreshold: Double
            let moderateThreshold: Double

            switch nutrient {
            case "Iron", "Calcium", "B Vitamins":
                // Essential micronutrients - need regular intake
                goodThreshold = 70
                moderateThreshold = 50
            case "Vitamin C", "Vitamin D":
                // Important but can be stored
                goodThreshold = 60
                moderateThreshold = 40
            default:
                // Omega-3, Magnesium, Zinc - beneficial but less frequent
                goodThreshold = 50
                moderateThreshold = 30
            }

            if frequency >= goodThreshold {
                // Doing well
                adequate.append(NutrientInfo(
                    name: nutrient,
                    daysWithNutrient: daysWithNutrient,
                    totalDays: totalDaysTracked,
                    foodsEaten: foodsEaten
                ))
            } else {
                // Determine status based on frequency
                let status: NutrientStatus
                if frequency >= 40 {
                    status = .inconsistent
                } else {
                    status = .needsTracking
                }

                deficient.append(NutrientDeficiency(
                    name: nutrient,
                    currentIntake: Double(daysWithNutrient),
                    recommendedIntake: Double(totalDaysTracked),
                    status: status,
                    foodSources: getFoodSources(for: nutrient),
                    foodsEaten: foodsEaten,
                    isFrequencyBased: true,
                    totalDays: totalDaysTracked,
                    trend: nil  // Will add trend calculation later
                ))
            }
        }

        // Generate personalized recommendations
        let recommendations = generateRecommendations(deficiencies: deficient)

        return HistoricalNutrientAnalysis(
            totalDaysTracked: totalDaysTracked,
            deficientNutrients: deficient,
            adequateNutrients: adequate,
            recommendedFoods: recommendations
        )
    }

    private func getNutrientsInFood(_ foodName: String, entry: FoodEntry) -> [String] {
        let name = foodName.lowercased()
        var nutrients: [String] = []

        // Use real micronutrient data if available, otherwise fall back to keyword matching
        if let micronutrients = entry.micronutrientProfile {
            // Real data from ingredient analysis - check vitamins
            if let vitaminC = micronutrients.vitamins["vitaminC"], vitaminC > 1 {
                nutrients.append("Vitamin C")
            }
            if let vitaminD = micronutrients.vitamins["vitaminD"], vitaminD > 0.5 {
                nutrients.append("Vitamin D")
            }
            // Check for any B vitamins
            let bVitamins = ["thiamine", "riboflavin", "niacin", "pantothenicAcid", "vitaminB6", "biotin", "folate", "vitaminB12"]
            let hasBVitamins = bVitamins.contains { vitaminKey in
                if let amount = micronutrients.vitamins[vitaminKey], amount > 0.1 {
                    return true
                }
                return false
            }
            if hasBVitamins {
                nutrients.append("B Vitamins")
            }

            // Real data from ingredient analysis - check minerals
            if let calcium = micronutrients.minerals["calcium"], calcium > 50 {
                nutrients.append("Calcium")
            }
            if let iron = micronutrients.minerals["iron"], iron > 0.5 {
                nutrients.append("Iron")
            }
            if let magnesium = micronutrients.minerals["magnesium"], magnesium > 20 {
                nutrients.append("Magnesium")
            }
            if let zinc = micronutrients.minerals["zinc"], zinc > 0.5 {
                nutrients.append("Zinc")
            }

            // Omega-3 estimation (still use fat as proxy)
            if entry.fat > 10 || name.contains("salmon") || name.contains("tuna") || name.contains("mackerel") ||
               name.contains("sardine") || name.contains("walnut") || name.contains("chia") ||
               name.contains("flax") || name.contains("hemp") {
                nutrients.append("Omega-3")
            }
        } else {
            // Fallback to keyword-based matching if no micronutrient profile available
            // Calcium - use legacy field if available
            if let calcium = entry.calcium, calcium > 50 {
                nutrients.append("Calcium")
            }

            // Iron - keyword-based
            if entry.protein > 15 || name.contains("beef") || name.contains("steak") || name.contains("liver") ||
               name.contains("spinach") || name.contains("kale") || name.contains("lentil") ||
               name.contains("bean") || name.contains("fortified") || name.contains("cereal") ||
               name.contains("tofu") || name.contains("quinoa") {
                nutrients.append("Iron")
            }

            // Vitamin C - keyword-based
            if name.contains("orange") || name.contains("lemon") || name.contains("lime") ||
               name.contains("strawber") || name.contains("kiwi") || name.contains("mango") ||
               name.contains("pepper") || name.contains("broccoli") || name.contains("tomato") ||
               name.contains("citrus") || name.contains("berry") {
                nutrients.append("Vitamin C")
            }

            // Omega-3 - keyword-based
            if name.contains("salmon") || name.contains("tuna") || name.contains("mackerel") ||
               name.contains("sardine") || name.contains("walnut") || name.contains("chia") ||
               name.contains("flax") || name.contains("hemp") || entry.fat > 10 {
                nutrients.append("Omega-3")
            }

            // Vitamin D - keyword-based
            if name.contains("milk") || name.contains("salmon") || name.contains("tuna") ||
               name.contains("egg") || name.contains("fortified") || name.contains("mushroom") {
                nutrients.append("Vitamin D")
            }

            // B Vitamins - keyword-based
            if name.contains("whole grain") || name.contains("brown rice") || name.contains("oat") ||
               name.contains("chicken") || name.contains("beef") || name.contains("egg") ||
               name.contains("lentil") || name.contains("bean") || name.contains("avocado") {
                nutrients.append("B Vitamins")
            }

            // Magnesium - keyword-based
            if name.contains("almond") || name.contains("cashew") || name.contains("pumpkin seed") ||
               name.contains("spinach") || name.contains("whole grain") || name.contains("black bean") ||
               name.contains("dark chocolate") || name.contains("avocado") {
                nutrients.append("Magnesium")
            }

            // Zinc - keyword-based
            if name.contains("beef") || name.contains("pork") || name.contains("chicken") ||
               name.contains("oyster") || name.contains("crab") || name.contains("cashew") ||
               name.contains("chickpea") || name.contains("lentil") {
                nutrients.append("Zinc")
            }
        }

        return nutrients
    }

    private func getFoodSources(for nutrient: String) -> [String] {
        switch nutrient {
        case "Iron":
            return ["spinach", "red meat", "lentils", "fortified cereals", "dark chocolate"]
        case "Calcium":
            return ["milk", "cheese", "yogurt", "fortified plant milk", "sardines", "kale"]
        case "Vitamin C":
            return ["oranges", "strawberries", "bell peppers", "broccoli", "kiwi"]
        case "Omega-3":
            return ["salmon", "sardines", "walnuts", "chia seeds", "flaxseed"]
        case "Vitamin D":
            return ["salmon", "fortified milk", "eggs", "mushrooms", "tuna"]
        case "B Vitamins":
            return ["whole grains", "eggs", "chicken", "beans", "leafy greens"]
        case "Magnesium":
            return ["almonds", "spinach", "black beans", "avocado", "dark chocolate"]
        case "Zinc":
            return ["beef", "chickpeas", "cashews", "pumpkin seeds", "oysters"]
        default:
            return []
        }
    }

    private func generateRecommendations(deficiencies: [NutrientDeficiency]) -> [String] {
        guard !deficiencies.isEmpty else {
            return ["Keep up the great work! Your nutrition looks balanced."]
        }

        var recommendations: [String] = []

        // Prioritize nutrients that need more tracking
        let needsTracking = deficiencies.filter { $0.status == .needsTracking }
        let inconsistent = deficiencies.filter { $0.status == .inconsistent }

        if !needsTracking.isEmpty {
            let nutrient = needsTracking[0]
            let days = Int(nutrient.currentIntake)
            let total = Int(nutrient.recommendedIntake)
            let percent = Int(nutrient.percentageOfTarget)

            if nutrient.isFrequencyBased {
                recommendations.append("You ate \(nutrient.name)-rich foods on \(days) of \(total) days (\(percent)%). Try adding \(nutrient.foodSources.prefix(2).joined(separator: " or ")) to more of your daily meals.")
            } else {
                recommendations.append("You had \(nutrient.name) on \(days) of \(total) days tracked. Aim to include \(nutrient.foodSources.prefix(2).joined(separator: " or ")) in more meals.")
            }
        }

        if !inconsistent.isEmpty {
            let nutrient = inconsistent[0]
            recommendations.append("Consider increasing your \(nutrient.name) intake by eating more \(nutrient.foodSources.prefix(3).joined(separator: ", ")).")
        }

        return recommendations
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
                        Text("\(Int(deficiency.frequency))% frequency")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if deficiency.isFrequencyBased {
                        Text("\(Int(deficiency.currentIntake)) \(deficiency.unit)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)

                        Text("of \(Int(deficiency.recommendedIntake)) \(deficiency.unit)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(String(format: "%.1f", deficiency.dailyAverage))\(deficiency.unit)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)

                        Text("of \(String(format: "%.1f", deficiency.dailyTarget))\(deficiency.unit)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(deficiency.status.color)
                        .frame(width: geometry.size.width * CGFloat(min(deficiency.percentageOfTarget / 100, 1.0)), height: 8)
                }
            }
            .frame(height: 8)

            // Foods you've eaten (if any)
            if !deficiency.foodsEaten.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Foods you've eaten:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    Text(deficiency.foodsEaten.prefix(5).joined(separator: ", "))
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }
            }

            // Good sources suggestions
            VStack(alignment: .leading, spacing: 4) {
                Text("Good sources to try:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                Text(deficiency.foodSources.prefix(4).joined(separator: ", "))
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
            }
        }
        .padding(AppSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .fill(AppColors.cardBackgroundElevated)
        )
        .cardShadow()
    }
}

// MARK: - Adequate Nutrient Card

struct AdequateNutrientCard: View {
    let nutrient: NutrientInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with frequency
            HStack(alignment: .top) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 4) {
                    Text(nutrient.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("\(nutrient.daysWithNutrient) of \(nutrient.totalDays) \(nutrient.totalDays == 1 ? "day" : "days") (\(Int(nutrient.frequency))%)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.green)
                }

                Spacer()
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green)
                        .frame(width: geometry.size.width * CGFloat(min(nutrient.frequency / 100, 1.0)), height: 8)
                }
            }
            .frame(height: 8)

            // Foods eaten
            if !nutrient.foodsEaten.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Foods eaten:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    Text(nutrient.foodsEaten.prefix(5).joined(separator: ", "))
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }
            }

            // Encouragement
            Text("Keep up the great work!")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.green)
        }
        .padding(AppSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .fill(Color.green.opacity(0.1))
        )
        .cardShadow()
    }
}

// MARK: - Nutrient Calendar Tracker

struct NutrientCalendarTrackerView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var selectedDate: Date?
    @State private var foodEntries: [FoodEntry] = []
    @State private var nutrientMap: [Date: [String: [String]]] = [:] // Date -> Nutrient -> [Foods]
    @State private var currentMonth: Date = Date()
    @State private var isLoading = true

    private let calendar = Calendar.current
    private let allNutrients = ["Iron", "Calcium", "Vitamin C", "Omega-3", "Vitamin D", "B Vitamins", "Magnesium", "Zinc"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nutrient Calendar")
                            .font(.system(size: 28, weight: .bold))

                        Text("Track your nutrient intake over time")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // Month Navigation
                    HStack {
                        Button(action: {
                            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                            loadMonthData()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                        }

                        Spacer()

                        Text(monthYearString(from: currentMonth))
                            .font(.system(size: 20, weight: .semibold))

                        Spacer()

                        Button(action: {
                            let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                            if nextMonth <= Date() {
                                currentMonth = nextMonth
                                loadMonthData()
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(canGoToNextMonth() ? .primary : .gray.opacity(0.3))
                        }
                        .disabled(!canGoToNextMonth())
                    }
                    .padding(.horizontal)

                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                    } else {
                        // Calendar Grid
                        CalendarGridView(
                            month: currentMonth,
                            nutrientMap: nutrientMap,
                            selectedDate: $selectedDate
                        )
                        .padding(.horizontal)

                        // Selected Day Detail
                        if let selected = selectedDate, let nutrients = nutrientMap[calendar.startOfDay(for: selected)] {
                            DayNutrientDetailView(date: selected, nutrients: nutrients)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Today") {
                        currentMonth = Date()
                        selectedDate = Date()
                        loadMonthData()
                    }
                    .foregroundColor(.green)
                }
            }
        }
        .onAppear {
            loadMonthData()
        }
    }

    private func loadMonthData() {
        isLoading = true

        Task {
            do {
                // Get start and end of month
                let components = calendar.dateComponents([.year, .month], from: currentMonth)
                guard let monthStart = calendar.date(from: components),
                      let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
                    await MainActor.run { isLoading = false }
                    return
                }

                // Load all entries for this month
                let entries = try await FirebaseManager.shared.getFoodEntriesInRange(from: monthStart, to: monthEnd)

                // Process entries to build nutrient map
                var map: [Date: [String: [String]]] = [:]

                for entry in entries {
                    let dayStart = calendar.startOfDay(for: entry.date)
                    let nutrients = getNutrientsInFood(entry.foodName, entry: entry)

                    if map[dayStart] == nil {
                        map[dayStart] = [:]
                    }

                    for nutrient in nutrients {
                        if map[dayStart]?[nutrient] == nil {
                            map[dayStart]?[nutrient] = []
                        }
                        map[dayStart]?[nutrient]?.append(entry.foodName)
                    }
                }

                await MainActor.run {
                    self.foodEntries = entries
                    self.nutrientMap = map
                    self.isLoading = false
                }
            } catch {
                print("Error loading calendar data: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }

    private func getNutrientsInFood(_ foodName: String, entry: FoodEntry) -> [String] {
        let name = foodName.lowercased()
        var nutrients: [String] = []

        // Use same logic as ImprovedMicronutrientView
        if let micronutrients = entry.micronutrientProfile {
            if let vitaminC = micronutrients.vitamins["vitaminC"], vitaminC > 1 {
                nutrients.append("Vitamin C")
            }
            if let vitaminD = micronutrients.vitamins["vitaminD"], vitaminD > 0.5 {
                nutrients.append("Vitamin D")
            }
            let bVitamins = ["thiamine", "riboflavin", "niacin", "pantothenicAcid", "vitaminB6", "biotin", "folate", "vitaminB12"]
            let hasBVitamins = bVitamins.contains { vitaminKey in
                if let amount = micronutrients.vitamins[vitaminKey], amount > 0.1 {
                    return true
                }
                return false
            }
            if hasBVitamins {
                nutrients.append("B Vitamins")
            }

            if let calcium = micronutrients.minerals["calcium"], calcium > 50 {
                nutrients.append("Calcium")
            }
            if let iron = micronutrients.minerals["iron"], iron > 0.5 {
                nutrients.append("Iron")
            }
            if let magnesium = micronutrients.minerals["magnesium"], magnesium > 20 {
                nutrients.append("Magnesium")
            }
            if let zinc = micronutrients.minerals["zinc"], zinc > 0.5 {
                nutrients.append("Zinc")
            }

            if entry.fat > 10 || name.contains("salmon") || name.contains("tuna") || name.contains("mackerel") ||
               name.contains("sardine") || name.contains("walnut") || name.contains("chia") ||
               name.contains("flax") || name.contains("hemp") {
                nutrients.append("Omega-3")
            }
        } else {
            // Fallback keyword matching (simplified for brevity)
            if name.contains("iron") || entry.protein > 15 { nutrients.append("Iron") }
            if name.contains("calcium") || name.contains("milk") { nutrients.append("Calcium") }
            if name.contains("orange") || name.contains("vitamin c") { nutrients.append("Vitamin C") }
            if name.contains("salmon") || name.contains("fish") { nutrients.append("Omega-3") }
        }

        return nutrients
    }

    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func canGoToNextMonth() -> Bool {
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) else {
            return false
        }
        return nextMonth <= Date()
    }
}

// MARK: - Calendar Grid

struct CalendarGridView: View {
    let month: Date
    let nutrientMap: [Date: [String: [String]]]
    @Binding var selectedDate: Date?

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(spacing: 8) {
            // Weekday headers
            HStack(spacing: 4) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar days
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        CalendarDayCell(
                            date: date,
                            nutrients: nutrientMap[calendar.startOfDay(for: date)] ?? [:],
                            isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
                            isToday: calendar.isDateInToday(date)
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(height: 60)
                    }
                }
            }
        }
    }

    private func daysInMonth() -> [Date?] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let monthRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leadingEmptyDays = firstWeekday - 1

        var days: [Date?] = Array(repeating: nil, count: leadingEmptyDays)

        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(date)
            }
        }

        return days
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let nutrients: [String: [String]]
    let isSelected: Bool
    let isToday: Bool

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? .green : .primary)

            // Nutrient indicator dots
            HStack(spacing: 2) {
                ForEach(Array(nutrients.keys.prefix(3)), id: \.self) { nutrient in
                    Circle()
                        .fill(colorForNutrient(nutrient))
                        .frame(width: 4, height: 4)
                }

                if nutrients.count > 3 {
                    Text("+\(nutrients.count - 3)")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 10)
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.green.opacity(0.2) : (nutrients.isEmpty ? Color.clear : Color(.systemGray6)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isSelected ? Color.green : Color.clear, lineWidth: 2)
        )
    }

    private func colorForNutrient(_ nutrient: String) -> Color {
        switch nutrient {
        case "Iron": return .red
        case "Calcium": return .blue
        case "Vitamin C": return .orange
        case "Omega-3": return .teal
        case "Vitamin D": return .yellow
        case "B Vitamins": return .purple
        case "Magnesium": return .green
        case "Zinc": return .gray
        default: return .gray
        }
    }
}

// MARK: - Day Nutrient Detail

struct DayNutrientDetailView: View {
    let date: Date
    let nutrients: [String: [String]]

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(dateString(from: date))
                .font(.system(size: 20, weight: .bold))

            if nutrients.isEmpty {
                Text("No nutrients tracked on this day")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(Array(nutrients.keys.sorted()), id: \.self) { nutrient in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle()
                                .fill(colorForNutrient(nutrient))
                                .frame(width: 12, height: 12)

                            Text(nutrient)
                                .font(.system(size: 16, weight: .semibold))
                        }

                        Text("Foods eaten:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)

                        Text(nutrients[nutrient]?.joined(separator: ", ") ?? "")
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .lineLimit(3)
                    }
                    .padding(AppSpacing.small)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.small)
                            .fill(AppColors.cardBackground)
                    )
                }
            }
        }
        .padding(AppSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.large)
                .fill(AppColors.cardBackgroundElevated)
        )
        .cardShadow()
    }

    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    private func colorForNutrient(_ nutrient: String) -> Color {
        switch nutrient {
        case "Iron": return .red
        case "Calcium": return .blue
        case "Vitamin C": return .orange
        case "Omega-3": return .teal
        case "Vitamin D": return .yellow
        case "B Vitamins": return .purple
        case "Magnesium": return .green
        case "Zinc": return .gray
        default: return .gray
        }
    }
}
