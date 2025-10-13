import SwiftUI
import Foundation

// MARK: - Time Period Enum

enum InsightsTimePeriod: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"

    var headerText: String {
        switch self {
        case .day: return "Today's nutrition at a glance"
        case .week: return "Your week of nutrition"
        case .month: return "Month overview"
        }
    }
}

// MARK: - Data Models

struct DailyNutritionStats {
    let date: Date

    // Macros
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double

    // Micros (only calcium is easily available from FoodEntry)
    let calcium: Double

    // Targets
    let proteinTarget: Double
    let carbsTarget: Double
    let fatTarget: Double
    let fiberTarget: Double
    let calciumTarget: Double

    // Calculate % of target
    func proteinPercent() -> Double {
        guard proteinTarget > 0 else { return 0 }
        return (protein / proteinTarget) * 100
    }

    func carbsPercent() -> Double {
        guard carbsTarget > 0 else { return 0 }
        return (carbs / carbsTarget) * 100
    }

    func fatPercent() -> Double {
        guard fatTarget > 0 else { return 0 }
        return (fat / fatTarget) * 100
    }

    func fiberPercent() -> Double {
        guard fiberTarget > 0 else { return 0 }
        return (fiber / fiberTarget) * 100
    }

    func calciumPercent() -> Double {
        guard calciumTarget > 0 else { return 0 }
        return (calcium / calciumTarget) * 100
    }

    // Check if meets goal (≥80%)
    func meetsProteinGoal() -> Bool { proteinPercent() >= 80 }
    func meetsCarbsGoal() -> Bool { carbsPercent() >= 80 }
    func meetsFatGoal() -> Bool { fatPercent() >= 80 }
    func meetsFiberGoal() -> Bool { fiberPercent() >= 80 }
    func meetsCalciumGoal() -> Bool { calciumPercent() >= 80 }
}

struct WeeklyNutritionStats {
    let startDate: Date
    let endDate: Date
    let dailyStats: [DailyNutritionStats]

    var totalDays: Int { dailyStats.count }

    func daysMetProteinGoal() -> Int { dailyStats.filter { $0.meetsProteinGoal() }.count }
    func daysMetCarbsGoal() -> Int { dailyStats.filter { $0.meetsCarbsGoal() }.count }
    func daysMetFatGoal() -> Int { dailyStats.filter { $0.meetsFatGoal() }.count }
    func daysMetFiberGoal() -> Int { dailyStats.filter { $0.meetsFiberGoal() }.count }
    func daysMetCalciumGoal() -> Int { dailyStats.filter { $0.meetsCalciumGoal() }.count }
}

struct MonthlyNutritionStats {
    let month: Int
    let year: Int
    let dailyStats: [DailyNutritionStats]

    var totalDays: Int { dailyStats.count }

    func daysMetProteinGoal() -> Int { dailyStats.filter { $0.meetsProteinGoal() }.count }
    func daysMetCarbsGoal() -> Int { dailyStats.filter { $0.meetsCarbsGoal() }.count }
    func daysMetFatGoal() -> Int { dailyStats.filter { $0.meetsFatGoal() }.count }
    func daysMetFiberGoal() -> Int { dailyStats.filter { $0.meetsFiberGoal() }.count }
    func daysMetCalciumGoal() -> Int { dailyStats.filter { $0.meetsCalciumGoal() }.count }

    func percentDaysMetProteinGoal() -> Double {
        guard !dailyStats.isEmpty else { return 0 }
        return (Double(daysMetProteinGoal()) / Double(totalDays)) * 100
    }

    func percentDaysMetCarbsGoal() -> Double {
        guard !dailyStats.isEmpty else { return 0 }
        return (Double(daysMetCarbsGoal()) / Double(totalDays)) * 100
    }

    func percentDaysMetFatGoal() -> Double {
        guard !dailyStats.isEmpty else { return 0 }
        return (Double(daysMetFatGoal()) / Double(totalDays)) * 100
    }

    func percentDaysMetFiberGoal() -> Double {
        guard !dailyStats.isEmpty else { return 0 }
        return (Double(daysMetFiberGoal()) / Double(totalDays)) * 100
    }

    func percentDaysMetCalciumGoal() -> Double {
        guard !dailyStats.isEmpty else { return 0 }
        return (Double(daysMetCalciumGoal()) / Double(totalDays)) * 100
    }
}

// MARK: - Main View

struct TieredNutritionInsightsView: View {
    @State private var selectedPeriod: InsightsTimePeriod = .month
    @State private var currentDate: Date = Date()
    @State private var dailyStats: DailyNutritionStats?
    @State private var weeklyStats: WeeklyNutritionStats?
    @State private var monthlyStats: MonthlyNutritionStats?
    @State private var isLoading = false
    @EnvironmentObject var firebaseManager: FirebaseManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nutritional Insights")
                            .font(.system(size: 28, weight: .bold))

                        Text(selectedPeriod.headerText)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // Period Selector
                    Picker("Time Period", selection: $selectedPeriod) {
                        ForEach(InsightsTimePeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: selectedPeriod) { _ in
                        loadData()
                    }

                    // Navigation Controls
                    HStack {
                        Button(action: { navigatePrevious() }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Previous")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                        }

                        Spacer()

                        Text(dateRangeText())
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)

                        Spacer()

                        Button(action: { navigateNext() }) {
                            HStack {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(canNavigateNext() ? .blue : .gray)
                        }
                        .disabled(!canNavigateNext())
                    }
                    .padding(.horizontal)

                    // Content
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding()
                            Spacer()
                        }
                    } else {
                        switch selectedPeriod {
                        case .day:
                            if let stats = dailyStats {
                                DayView(stats: stats)
                                    .padding(.horizontal)
                            } else {
                                EmptyDataView()
                            }
                        case .week:
                            if let stats = weeklyStats {
                                WeekView(stats: stats)
                                    .padding(.horizontal)
                            } else {
                                EmptyDataView()
                            }
                        case .month:
                            if let stats = monthlyStats {
                                MonthView(stats: stats)
                                    .padding(.horizontal)
                            } else {
                                EmptyDataView()
                            }
                        }
                    }
                }
                .padding(.bottom)
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
        .onAppear {
            loadData()
        }
    }

    // MARK: - Helper Functions

    private func dateRangeText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"

        switch selectedPeriod {
        case .day:
            return formatter.string(from: currentDate)
        case .week:
            if let weekStart = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate)),
               let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) {
                formatter.dateFormat = "MMM d"
                return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
            }
            return "Week"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: currentDate)
        }
    }

    private func canNavigateNext() -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        switch selectedPeriod {
        case .day:
            return calendar.startOfDay(for: currentDate) < today
        case .week:
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate)) else { return false }
            return weekStart < today
        case .month:
            guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)),
                  let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart) else { return false }
            return nextMonth <= Date()
        }
    }

    private func navigatePrevious() {
        let calendar = Calendar.current

        switch selectedPeriod {
        case .day:
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        case .week:
            currentDate = calendar.date(byAdding: .weekOfYear, value: -1, to: currentDate) ?? currentDate
        case .month:
            currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
        }

        loadData()
    }

    private func navigateNext() {
        guard canNavigateNext() else { return }

        let calendar = Calendar.current

        switch selectedPeriod {
        case .day:
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        case .week:
            currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
        case .month:
            currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
        }

        loadData()
    }

    private func loadData() {
        isLoading = true

        Task {
            do {
                // Load user settings
                let settings = try await firebaseManager.getUserSettings()
                let calorieGoal = Double(settings.caloricGoal ?? 2000)
                let proteinPercent = Double(settings.proteinPercent ?? 30) / 100.0
                let carbsPercent = Double(settings.carbsPercent ?? 40) / 100.0
                let fatPercent = Double(settings.fatPercent ?? 30) / 100.0

                // Macro targets
                let proteinTarget = (calorieGoal * proteinPercent) / 4.0
                let carbsTarget = (calorieGoal * carbsPercent) / 4.0
                let fatTarget = (calorieGoal * fatPercent) / 9.0
                let fiberTarget: Double = 30.0

                // Micro targets (UK RDA)
                let calciumTarget: Double = 700.0  // mg
                let ironTarget: Double = 8.7       // mg
                let vitaminCTarget: Double = 40.0  // mg
                let vitaminDTarget: Double = 10.0  // μg

                switch selectedPeriod {
                case .day:
                    await loadDayData(
                        proteinTarget: proteinTarget,
                        carbsTarget: carbsTarget,
                        fatTarget: fatTarget,
                        fiberTarget: fiberTarget,
                        calciumTarget: calciumTarget,
                        ironTarget: ironTarget,
                        vitaminCTarget: vitaminCTarget,
                        vitaminDTarget: vitaminDTarget
                    )
                case .week:
                    await loadWeekData(
                        proteinTarget: proteinTarget,
                        carbsTarget: carbsTarget,
                        fatTarget: fatTarget,
                        fiberTarget: fiberTarget,
                        calciumTarget: calciumTarget,
                        ironTarget: ironTarget,
                        vitaminCTarget: vitaminCTarget,
                        vitaminDTarget: vitaminDTarget
                    )
                case .month:
                    await loadMonthData(
                        proteinTarget: proteinTarget,
                        carbsTarget: carbsTarget,
                        fatTarget: fatTarget,
                        fiberTarget: fiberTarget,
                        calciumTarget: calciumTarget,
                        ironTarget: ironTarget,
                        vitaminCTarget: vitaminCTarget,
                        vitaminDTarget: vitaminDTarget
                    )
                }

                await MainActor.run {
                    isLoading = false
                }
            } catch {
                print("Error loading nutrition insights: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }

    private func loadDayData(
        proteinTarget: Double,
        carbsTarget: Double,
        fatTarget: Double,
        fiberTarget: Double,
        calciumTarget: Double,
        ironTarget: Double,
        vitaminCTarget: Double,
        vitaminDTarget: Double
    ) async {
        do {
            let entries = try await FirebaseManager.shared.getFoodEntries(for: currentDate)

            let totalProtein = entries.reduce(0.0) { $0 + $1.protein }
            let totalCarbs = entries.reduce(0.0) { $0 + $1.carbohydrates }
            let totalFat = entries.reduce(0.0) { $0 + $1.fat }
            let totalFiber = entries.reduce(0.0) { $0 + ($1.fiber ?? 0) }
            let totalCalcium = entries.reduce(0.0) { $0 + ($1.calcium ?? 0) }
            let totalIron = entries.reduce(0.0) { $0 + ($1.iron ?? 0) }
            let totalVitaminC = entries.reduce(0.0) { $0 + ($1.vitaminC ?? 0) }
            let totalVitaminD = entries.reduce(0.0) { $0 + ($1.vitaminD ?? 0) }

            let stats = DailyNutritionStats(
                date: currentDate,
                protein: totalProtein,
                carbs: totalCarbs,
                fat: totalFat,
                fiber: totalFiber,
                calcium: totalCalcium,
                iron: totalIron,
                vitaminC: totalVitaminC,
                vitaminD: totalVitaminD,
                proteinTarget: proteinTarget,
                carbsTarget: carbsTarget,
                fatTarget: fatTarget,
                fiberTarget: fiberTarget,
                calciumTarget: calciumTarget,
                ironTarget: ironTarget,
                vitaminCTarget: vitaminCTarget,
                vitaminDTarget: vitaminDTarget
            )

            await MainActor.run {
                self.dailyStats = stats
            }
        } catch {
            print("Error loading day data: \(error)")
        }
    }

    private func loadWeekData(
        proteinTarget: Double,
        carbsTarget: Double,
        fatTarget: Double,
        fiberTarget: Double,
        calciumTarget: Double,
        ironTarget: Double,
        vitaminCTarget: Double,
        vitaminDTarget: Double
    ) async {
        do {
            let calendar = Calendar.current

            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate)),
                  let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
                return
            }

            var allDailyStats: [DailyNutritionStats] = []

            for dayOffset in 0...6 {
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }

                let entries = try await FirebaseManager.shared.getFoodEntries(for: day)

                if !entries.isEmpty {
                    let totalProtein = entries.reduce(0.0) { $0 + $1.protein }
                    let totalCarbs = entries.reduce(0.0) { $0 + $1.carbohydrates }
                    let totalFat = entries.reduce(0.0) { $0 + $1.fat }
                    let totalFiber = entries.reduce(0.0) { $0 + ($1.fiber ?? 0) }
                    let totalCalcium = entries.reduce(0.0) { $0 + ($1.calcium ?? 0) }
                    let totalIron = entries.reduce(0.0) { $0 + ($1.iron ?? 0) }
                    let totalVitaminC = entries.reduce(0.0) { $0 + ($1.vitaminC ?? 0) }
                    let totalVitaminD = entries.reduce(0.0) { $0 + ($1.vitaminD ?? 0) }

                    let dayStats = DailyNutritionStats(
                        date: day,
                        protein: totalProtein,
                        carbs: totalCarbs,
                        fat: totalFat,
                        fiber: totalFiber,
                        calcium: totalCalcium,
                        iron: totalIron,
                        vitaminC: totalVitaminC,
                        vitaminD: totalVitaminD,
                        proteinTarget: proteinTarget,
                        carbsTarget: carbsTarget,
                        fatTarget: fatTarget,
                        fiberTarget: fiberTarget,
                        calciumTarget: calciumTarget,
                        ironTarget: ironTarget,
                        vitaminCTarget: vitaminCTarget,
                        vitaminDTarget: vitaminDTarget
                    )

                    allDailyStats.append(dayStats)
                }
            }

            let weekStats = WeeklyNutritionStats(
                startDate: weekStart,
                endDate: weekEnd,
                dailyStats: allDailyStats
            )

            await MainActor.run {
                self.weeklyStats = weekStats
            }
        } catch {
            print("Error loading week data: \(error)")
        }
    }

    private func loadMonthData(
        proteinTarget: Double,
        carbsTarget: Double,
        fatTarget: Double,
        fiberTarget: Double,
        calciumTarget: Double,
        ironTarget: Double,
        vitaminCTarget: Double,
        vitaminDTarget: Double
    ) async {
        do {
            let calendar = Calendar.current

            let components = calendar.dateComponents([.year, .month], from: currentDate)
            guard let monthStart = calendar.date(from: components),
                  let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
                return
            }

            let daysInMonth = calendar.component(.day, from: monthEnd)

            var allDailyStats: [DailyNutritionStats] = []

            for dayOffset in 0..<daysInMonth {
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: monthStart) else { continue }

                let entries = try await FirebaseManager.shared.getFoodEntries(for: day)

                if !entries.isEmpty {
                    let totalProtein = entries.reduce(0.0) { $0 + $1.protein }
                    let totalCarbs = entries.reduce(0.0) { $0 + $1.carbohydrates }
                    let totalFat = entries.reduce(0.0) { $0 + $1.fat }
                    let totalFiber = entries.reduce(0.0) { $0 + ($1.fiber ?? 0) }
                    let totalCalcium = entries.reduce(0.0) { $0 + ($1.calcium ?? 0) }
                    let totalIron = entries.reduce(0.0) { $0 + ($1.iron ?? 0) }
                    let totalVitaminC = entries.reduce(0.0) { $0 + ($1.vitaminC ?? 0) }
                    let totalVitaminD = entries.reduce(0.0) { $0 + ($1.vitaminD ?? 0) }

                    let dayStats = DailyNutritionStats(
                        date: day,
                        protein: totalProtein,
                        carbs: totalCarbs,
                        fat: totalFat,
                        fiber: totalFiber,
                        calcium: totalCalcium,
                        iron: totalIron,
                        vitaminC: totalVitaminC,
                        vitaminD: totalVitaminD,
                        proteinTarget: proteinTarget,
                        carbsTarget: carbsTarget,
                        fatTarget: fatTarget,
                        fiberTarget: fiberTarget,
                        calciumTarget: calciumTarget,
                        ironTarget: ironTarget,
                        vitaminCTarget: vitaminCTarget,
                        vitaminDTarget: vitaminDTarget
                    )

                    allDailyStats.append(dayStats)
                }
            }

            let monthStats = MonthlyNutritionStats(
                month: components.month ?? 1,
                year: components.year ?? 2025,
                dailyStats: allDailyStats
            )

            await MainActor.run {
                self.monthlyStats = monthStats
            }
        } catch {
            print("Error loading month data: \(error)")
        }
    }
}

// MARK: - Day View

struct DayView: View {
    let stats: DailyNutritionStats

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Macros Section
            Text("Macros")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.top, 4)

            VStack(spacing: 12) {
                DayMacroCard(
                    name: "Protein",
                    percent: stats.proteinPercent(),
                    current: stats.protein,
                    target: stats.proteinTarget,
                    unit: "g",
                    color: .blue
                )

                DayMacroCard(
                    name: "Carbs",
                    percent: stats.carbsPercent(),
                    current: stats.carbs,
                    target: stats.carbsTarget,
                    unit: "g",
                    color: .orange
                )

                DayMacroCard(
                    name: "Fat",
                    percent: stats.fatPercent(),
                    current: stats.fat,
                    target: stats.fatTarget,
                    unit: "g",
                    color: .purple
                )

                DayMacroCard(
                    name: "Fiber",
                    percent: stats.fiberPercent(),
                    current: stats.fiber,
                    target: stats.fiberTarget,
                    unit: "g",
                    color: .green
                )
            }

            // Vitamins & Minerals Section
            Text("Vitamins & Minerals")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.top, 8)

            VStack(spacing: 12) {
                DayMicroCard(
                    name: "Calcium",
                    percent: stats.calciumPercent(),
                    current: stats.calcium,
                    target: stats.calciumTarget,
                    unit: "mg"
                )

                DayMicroCard(
                    name: "Iron",
                    percent: stats.ironPercent(),
                    current: stats.iron,
                    target: stats.ironTarget,
                    unit: "mg"
                )

                DayMicroCard(
                    name: "Vitamin C",
                    percent: stats.vitaminCPercent(),
                    current: stats.vitaminC,
                    target: stats.vitaminCTarget,
                    unit: "mg"
                )

                DayMicroCard(
                    name: "Vitamin D",
                    percent: stats.vitaminDPercent(),
                    current: stats.vitaminD,
                    target: stats.vitaminDTarget,
                    unit: "μg"
                )
            }
        }
    }
}

struct DayMacroCard: View {
    let name: String
    let percent: Double
    let current: Double
    let target: Double
    let unit: String
    let color: Color

    var feedbackText: String {
        if percent >= 100 {
            return "Target met"
        } else if percent >= 80 {
            return "Almost there"
        } else if percent >= 60 {
            return "Keep going"
        } else {
            return "Room to improve"
        }
    }

    var displayPercent: Int {
        return min(Int(percent), 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 17, weight: .semibold))

                    Text("\(String(format: "%.0f", current)) / \(String(format: "%.0f", target))\(unit)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(displayPercent)%")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(color)

                    Text(feedbackText)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(min(percent / 100, 1.0)), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DayMicroCard: View {
    let name: String
    let percent: Double
    let current: Double
    let target: Double
    let unit: String

    var feedbackText: String {
        if percent >= 100 {
            return "Daily target met"
        } else if percent >= 70 {
            return "Getting close"
        } else {
            return "Below target"
        }
    }

    var displayPercent: Int {
        return min(Int(percent), 100)
    }

    var statusColor: Color {
        if percent >= 100 {
            return .green
        } else if percent >= 70 {
            return .orange
        } else {
            return .red
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 15, weight: .medium))

                Text("\(String(format: "%.0f", current)) / \(String(format: "%.0f", target))\(unit)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)

                    Text("\(displayPercent)%")
                        .font(.system(size: 16, weight: .semibold))
                }

                Text(feedbackText)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Week View

struct WeekView: View {
    let stats: WeeklyNutritionStats

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Macros Section
            Text("Macros")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.top, 4)

            VStack(spacing: 12) {
                WeekMacroCard(
                    name: "Protein",
                    daysMetGoal: stats.daysMetProteinGoal(),
                    totalDays: stats.totalDays,
                    color: .blue
                )

                WeekMacroCard(
                    name: "Carbs",
                    daysMetGoal: stats.daysMetCarbsGoal(),
                    totalDays: stats.totalDays,
                    color: .orange
                )

                WeekMacroCard(
                    name: "Fat",
                    daysMetGoal: stats.daysMetFatGoal(),
                    totalDays: stats.totalDays,
                    color: .purple
                )

                WeekMacroCard(
                    name: "Fiber",
                    daysMetGoal: stats.daysMetFiberGoal(),
                    totalDays: stats.totalDays,
                    color: .green
                )
            }

            // Vitamins & Minerals Section
            Text("Vitamins & Minerals")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.top, 8)

            VStack(spacing: 12) {
                WeekMicroCard(
                    name: "Calcium",
                    daysMetGoal: stats.daysMetCalciumGoal(),
                    totalDays: stats.totalDays
                )

                WeekMicroCard(
                    name: "Iron",
                    daysMetGoal: stats.daysMetIronGoal(),
                    totalDays: stats.totalDays
                )

                WeekMicroCard(
                    name: "Vitamin C",
                    daysMetGoal: stats.daysMetVitaminCGoal(),
                    totalDays: stats.totalDays
                )

                WeekMicroCard(
                    name: "Vitamin D",
                    daysMetGoal: stats.daysMetVitaminDGoal(),
                    totalDays: stats.totalDays
                )
            }
        }
    }
}

struct WeekMacroCard: View {
    let name: String
    let daysMetGoal: Int
    let totalDays: Int
    let color: Color

    var feedbackText: String {
        if totalDays == 0 { return "No data" }

        let percent = (Double(daysMetGoal) / Double(totalDays)) * 100

        if percent >= 70 {
            return "Great week"
        } else if percent >= 40 {
            return "Making progress"
        } else {
            return "Keep at it"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(name)
                    .font(.system(size: 17, weight: .semibold))

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(daysMetGoal) of \(totalDays) days")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(color)

                    Text(feedbackText)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            // 7-segment bar
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(index < daysMetGoal ? color : Color(.systemGray5))
                        .frame(height: 10)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct WeekMicroCard: View {
    let name: String
    let daysMetGoal: Int
    let totalDays: Int

    var feedbackText: String {
        if totalDays == 0 { return "No data" }

        let percent = (Double(daysMetGoal) / Double(totalDays)) * 100

        if percent >= 70 {
            return "Consistent"
        } else if percent >= 40 {
            return "Improving"
        } else {
            return "Needs attention"
        }
    }

    var statusColor: Color {
        if totalDays == 0 { return .gray }
        let percent = (Double(daysMetGoal) / Double(totalDays)) * 100

        if percent >= 70 {
            return .green
        } else if percent >= 40 {
            return .orange
        } else {
            return .red
        }
    }

    var body: some View {
        HStack {
            Text(name)
                .font(.system(size: 15, weight: .medium))

            Spacer()

            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text("\(daysMetGoal) of \(totalDays) days")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Month View

struct MonthView: View {
    let stats: MonthlyNutritionStats

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Macros Section
            Text("Macros")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.top, 4)

            VStack(spacing: 12) {
                MonthMacroCard(
                    name: "Protein",
                    daysMetGoal: stats.daysMetProteinGoal(),
                    totalDays: stats.totalDays,
                    percent: stats.percentDaysMetProteinGoal(),
                    color: .blue
                )

                MonthMacroCard(
                    name: "Carbs",
                    daysMetGoal: stats.daysMetCarbsGoal(),
                    totalDays: stats.totalDays,
                    percent: stats.percentDaysMetCarbsGoal(),
                    color: .orange
                )

                MonthMacroCard(
                    name: "Fat",
                    daysMetGoal: stats.daysMetFatGoal(),
                    totalDays: stats.totalDays,
                    percent: stats.percentDaysMetFatGoal(),
                    color: .purple
                )

                MonthMacroCard(
                    name: "Fiber",
                    daysMetGoal: stats.daysMetFiberGoal(),
                    totalDays: stats.totalDays,
                    percent: stats.percentDaysMetFiberGoal(),
                    color: .green
                )
            }

            // Vitamins & Minerals Section
            Text("Vitamins & Minerals")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.top, 8)

            VStack(spacing: 12) {
                MonthMicroCard(
                    name: "Calcium",
                    daysMetGoal: stats.daysMetCalciumGoal(),
                    totalDays: stats.totalDays
                )

                MonthMicroCard(
                    name: "Iron",
                    daysMetGoal: stats.daysMetIronGoal(),
                    totalDays: stats.totalDays
                )

                MonthMicroCard(
                    name: "Vitamin C",
                    daysMetGoal: stats.daysMetVitaminCGoal(),
                    totalDays: stats.totalDays
                )

                MonthMicroCard(
                    name: "Vitamin D",
                    daysMetGoal: stats.daysMetVitaminDGoal(),
                    totalDays: stats.totalDays
                )
            }
        }
    }
}

struct MonthMacroCard: View {
    let name: String
    let daysMetGoal: Int
    let totalDays: Int
    let percent: Double
    let color: Color

    var feedbackText: String {
        if totalDays == 0 { return "No data" }

        if percent >= 70 {
            return "Excellent consistency"
        } else if percent >= 40 {
            return "Room to improve"
        } else {
            return "Focus needed"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 17, weight: .semibold))

                    Text("\(daysMetGoal) of \(totalDays) days")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(percent))%")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(color)

                    Text(feedbackText)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(min(percent / 100, 1.0)), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MonthMicroCard: View {
    let name: String
    let daysMetGoal: Int
    let totalDays: Int

    var percentText: String {
        if totalDays == 0 { return "0%" }
        let percent = (Double(daysMetGoal) / Double(totalDays)) * 100
        return "\(Int(percent))%"
    }

    var statusColor: Color {
        if totalDays == 0 { return .gray }
        let percent = (Double(daysMetGoal) / Double(totalDays)) * 100

        if percent >= 70 {
            return .green
        } else if percent >= 40 {
            return .orange
        } else {
            return .red
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 15, weight: .medium))

                Text("\(daysMetGoal) of \(totalDays) days")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text(percentText)
                    .font(.system(size: 16, weight: .semibold))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Empty State

struct EmptyDataView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Data Available")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Log meals to see your insights")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
