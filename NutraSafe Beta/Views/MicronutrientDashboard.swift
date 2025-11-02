//
//  MicronutrientDashboard.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-10-21.
//  Main dashboard for comprehensive micronutrient intelligence
//

import SwiftUI

@available(iOS 16.0, *)
struct MicronutrientDashboard: View {
    @StateObject private var trackingManager = MicronutrientTrackingManager.shared
    @StateObject private var recommendationEngine = NutrientRecommendationEngine.shared
    @StateObject private var diaryDataManager = DiaryDataManager.shared
    @State private var selectedFilter: DashboardFilter = .all
    @State private var selectedNutrient: MicronutrientSummary?
    @State private var showingTimeline = false
    @State private var showingRecommendations = false
    @State private var showingSources = false
    @State private var insights: [String] = []
    @State private var nutrientSummaries: [MicronutrientSummary] = []
    @State private var hasLoadedData = false // Performance: Track if we've already loaded data
    @State private var isLoading = false // Performance: Prevent duplicate loads
    @State private var rhythmDays: [RhythmDay] = []
    @State private var showingGaps: Bool = false

    enum DashboardFilter: String, CaseIterable {
    case all = "All"
    case strong = "Strong"
    case moderate = "Moderate"
    case traceMissing = "Low/Missing"
}

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Health disclaimer banner
                healthDisclaimerBanner

                // Header
                headerSection

                // Nutrient Balance Overview Bar
                if let balance = trackingManager.getTodayBalance() {
                    balanceOverviewBar(balance: balance)
                }

                // Insights
                insightsSection

                // Filter tabs
                filterTabsSection

                // Nutrient list
                nutrientListSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(item: $selectedNutrient) { nutrient in
            NutrientInfoSheet(summary: nutrient)
        }
        .sheet(isPresented: $showingTimeline) {
            MicronutrientTimelineView()
        }
        .sheet(isPresented: $showingRecommendations) {
            SmartRecommendationsView()
        }
        .sheet(isPresented: $showingSources) {
            SourcesAndCitationsView()
        }
        .task {
            // PERFORMANCE: Skip if already loaded - prevents redundant Firebase calls on tab switches
            guard !hasLoadedData, !isLoading else {
        // DEBUG LOG: print("⚡️ MicronutrientDashboard: Skipping load - data already loaded")
                return
            }

            isLoading = true
        // DEBUG LOG: print("📊 MicronutrientDashboard: Loading data...")

            // Process today's foods FIRST to ensure we have fresh data
            await processTodaysFoods()

            // Then load the summaries with the updated data
            nutrientSummaries = await trackingManager.getAllNutrientSummaries()
            insights = await trackingManager.generateTodayInsights()
            await recommendationEngine.generateRecommendations(for: nutrientSummaries)

            // Load rhythm data for last 7 days
            await loadRhythmData()

            hasLoadedData = true
            isLoading = false
            print("✅ MicronutrientDashboard: UI ready with fresh data")
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Micronutrients")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        // Info button for data sources
                        Button(action: {
                            showingSources = true
                        }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                        }
                    }

                    Text("Based on NHS RNI values")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 12) {
                    // Recommendations button
                    Button(action: {
                        showingRecommendations = true
                    }) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.orange)
                            .clipShape(Circle())
                    }

                    // Timeline button
                    Button(action: {
                        showingTimeline = true
                    }) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.purple)
                            .clipShape(Circle())
                    }
                }
            }

            // Dual balance circles: Today and This Week
            HStack(spacing: 16) {
                if let today = trackingManager.getTodayBalance() {
                    premiumSummaryCard(title: "Today", percentage: today.balancePercentage, status: today.balanceStatus)
                } else {
                    premiumSummaryCard(title: "Today", percentage: 0, status: nil)
                }

                let weekStats = weeklyBalanceStats
                premiumSummaryCard(
                    title: "This Week",
                    percentage: weekStats.percentage,
                    status: MicronutrientStatus.from(percentage: weekStats.percentage),
                    footnote: "\(weekStats.daysTracked)/7 days",
                    subtitle: "Average"
                )
            }
        }
        .padding(.top, 8)
    }


    private func premiumSummaryCard(title: String, percentage: Int, status: MicronutrientStatus?, footnote: String? = nil, subtitle: String? = nil) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray6), lineWidth: 12)
                    .frame(width: 92, height: 92)

                Circle()
                    .trim(from: 0, to: CGFloat(percentage) / 100.0)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                (status?.color ?? Color.blue).opacity(0.25),
                                status?.color ?? Color.blue
                            ]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 92, height: 92)
                    .rotationEffect(.degrees(-90))

                Text(status?.emoji ?? "–")
                    .font(.system(size: 30))
            }

            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)

                Text(subtitle ?? status?.label ?? "None")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(status?.color ?? .primary)

                if let footnote {
                    Text(footnote)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }

    // Weekly balance percentage computed from last 7 days of balance history
    private var weeklyBalancePercentage: Int {
        // Deprecated: previously averaged only tracked days which inflated results
        // Kept for compatibility but redirected to the new stats-based computation
        return weeklyBalanceStats.percentage
    }

    // New: Weekly balance stats including coverage across exact 7-day window
    private var weeklyBalanceStats: (percentage: Int, daysTracked: Int) {
        let calendar = Calendar.current
        let today = Date()
        let last7Dates: [Date] = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }

        var sum = 0
        var trackedDays = 0

        for date in last7Dates {
            if let balance = trackingManager.balanceHistory.first(where: { formatDate($0.date) == formatDate(date) }) {
                sum += balance.balancePercentage
                trackedDays += 1
            } else {
                // Missing day contributes 0 to average to avoid early "Strong"
                sum += 0
            }
        }

        let percentage = last7Dates.isEmpty ? 0 : sum / last7Dates.count
        return (percentage, trackedDays)
    }

    // MARK: - Balance Overview Bar

    private func balanceOverviewBar(balance: NutrientBalanceScore) -> some View {
        VStack(spacing: 16) {
            // Main balance indicator
            HStack(spacing: 16) {
                // Circular progress dial without numeric percentage
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 10)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: CGFloat(balance.balancePercentage) / 100.0)
                        .stroke(balance.balanceStatus.color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    Text(balance.balanceStatus.emoji)
                        .font(.system(size: 28))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Today's Balance")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)

                    Text(balance.balanceStatus.label)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(balance.balanceStatus.color)

                    // Labels line e.g. 🟢 27 Strong 🟡 1 Moderate 🟠 0 Trace
                    Text("🟢 \(balance.strongCount) Strong 🟡 \(balance.adequateCount) Moderate 🟠 \(balance.lowCount) Trace")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Breakdown
            HStack(spacing: 12) {
                balanceBreakdownItem(
                    count: balance.strongCount,
                    label: "Strong",
                    color: .green
                )

                balanceBreakdownItem(
                    count: balance.adequateCount,
                    label: "Moderate",
                    color: .yellow
                )

                balanceBreakdownItem(
                    count: balance.lowCount,
                    label: "Low",
                    color: .orange
                )
            }

            // Visual bar
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    let total = max(1, balance.totalNutrientsTracked)
                    let strongWidth = geometry.size.width * CGFloat(balance.strongCount) / CGFloat(total)
                    let adequateWidth = geometry.size.width * CGFloat(balance.adequateCount) / CGFloat(total)
                    let lowWidth = geometry.size.width * CGFloat(balance.lowCount) / CGFloat(total)

                    if balance.strongCount > 0 {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: strongWidth)
                    }

                    if balance.adequateCount > 0 {
                        Rectangle()
                            .fill(Color.yellow)
                            .frame(width: adequateWidth)
                    }

                    if balance.lowCount > 0 {
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: lowWidth)
                    }
                }
                .frame(height: 8)
                .clipShape(Capsule())
            }
            .frame(height: 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    private func balanceBreakdownItem(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text("\(count)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        VStack(spacing: 16) {
            // Nutrient Rhythm Bar (7 days, horizontally scrollable)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(rhythmDays, id: \.date) { day in
                        let isToday = Calendar.current.isDateInToday(day.date)
                        rhythmColumn(day: day, isToday: isToday)
                    }
                }
            }
            .frame(height: 60)

            // Nutrients Needing Attention
            if !insights.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Areas That Need Attention")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)

                    ForEach(insights, id: \.self) { insight in
                        insightCard(text: insight)
                    }
                }
            } else if let adaptiveInsight = generateAdaptiveInsight() {
                insightCard(text: adaptiveInsight)
            }
        }
    }

    private func rhythmColumn(day: RhythmDay, isToday: Bool) -> some View {
        VStack(spacing: 4) {
            // Column
            RoundedRectangle(cornerRadius: 6)
                .fill(day.level.color)
                .frame(width: 16, height: isToday ? 44 : 32)
                .shadow(
                    color: isToday ? day.level.color.opacity(0.5) : .clear,
                    radius: isToday ? 8 : 0,
                    x: 0,
                    y: 0
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                )
                .animation(.easeInOut(duration: 0.25), value: day.level)

            // Date label
            Text(shortDateLabel(day.date))
                .font(.system(size: 9, weight: isToday ? .semibold : .regular))
                .foregroundColor(isToday ? .primary : .secondary)
        }
    }

    private func insightCard(text: String) -> some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.easeInOut(duration: 0.25)) {
                showingGaps = true
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                // Warning icon with prominent colour
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.orange)

                // Insight text with better visibility
                Text(text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.25), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .transition(.opacity.combined(with: .scale(scale: 0.95)).animation(.easeInOut(duration: 0.25)))
    }

    // MARK: - Filter Tabs

    private var filterTabsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DashboardFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = filter
                        }
                    }) {
                        Text(filter.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                            .foregroundColor(selectedFilter == filter ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(selectedFilter == filter ? Color.blue : Color(.systemGray5))
                            )
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Nutrient List

    private var nutrientListSection: some View {
        let filteredSummaries = filterSummaries(nutrientSummaries)

        return VStack(spacing: 12) {
            HStack {
                Text("\(filteredSummaries.count) Nutrients")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()
            }

            VStack(spacing: 1) {
                ForEach(filteredSummaries) { summary in
                    MicronutrientRow(summary: summary)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedNutrient = summary
                        }

                    if summary.id != filteredSummaries.last?.id {
                        Divider()
                            .padding(.leading, 68)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
        }
    }

    private func filterSummaries(_ summaries: [MicronutrientSummary]) -> [MicronutrientSummary] {
        switch selectedFilter {
        case .all:
            return summaries
        case .strong:
            return summaries.filter { $0.todayStatus == .strong }
        case .moderate:
            return summaries.filter { $0.todayStatus == .adequate }
        case .traceMissing:
            return summaries.filter { $0.todayStatus == .low }
        }
    }

    // MARK: - Data Processing

    private func processTodaysFoods() async {
        // DEBUG LOG: print("📊 MicronutrientDashboard: Processing TODAY ONLY (performance fix)")

        // PERFORMANCE FIX: Only process TODAY'S foods, not 30 days
        // The tracking manager will automatically calculate 7-day and 30-day averages from Firebase data
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        do {
            // Only fetch and process today's foods
            let (breakfast, lunch, dinner, snacks) = try await diaryDataManager.getFoodDataAsync(for: today)
            let allFoods = breakfast + lunch + dinner + snacks

        // DEBUG LOG: print("📥 Processing \(allFoods.count) foods from today")

            // Process each food's micronutrients
            for food in allFoods {
                // Process vitamins and minerals from micronutrient profile if available
                if let profile = food.micronutrientProfile {
                    await trackingManager.processNutrientProfile(
                        profile,
                        foodName: food.name,
                        servingSize: food.quantity,
                        date: today
                    )
                } else {
                    // No micronutrient profile - use keyword-based detection instead
                    await trackingManager.processFoodLog(
                        name: food.name,
                        ingredients: food.ingredients ?? [],
                        date: today
                    )
                }
            }

            print("✅ MicronutrientDashboard: Finished processing today's foods")
        } catch {
            print("❌ Error loading today's food entries: \(error)")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // MARK: - Rhythm Bar Data Loading

    private func loadRhythmData() async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var days: [RhythmDay] = []

        // Generate last 7 days
        let dates = (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }.reversed()

        do {
            // Fetch food entries for last 7 days
            let entries = try await FirebaseManager.shared.getFoodEntriesForPeriod(days: 7)
            let grouped = Dictionary(grouping: entries, by: { calendar.startOfDay(for: $0.date) })

            // Build rhythm days
            for date in dates {
                let dayEntries = grouped[date] ?? []
                let level = calculateDominantLevel(for: dayEntries)
                days.append(RhythmDay(date: date, level: level))
            }

            await MainActor.run {
                self.rhythmDays = days
            }
        } catch {
            print("❌ Failed to load rhythm data: \(error)")
        }
    }

    private func calculateDominantLevel(for entries: [FoodEntry]) -> SourceLevel {
        guard !entries.isEmpty else { return .none }

        var strongCount = 0
        var moderateCount = 0
        var traceCount = 0

        // Sample a few key nutrients to determine dominant level
        let keyNutrients = ["vitaminC", "vitaminD", "calcium", "iron", "zinc"]

        for nutrientId in keyNutrients {
            let level = highestLevel(for: nutrientId, entries: entries)
            switch level {
            case .strong: strongCount += 1
            case .moderate: moderateCount += 1
            case .trace: traceCount += 1
            case .none: break
            }
        }

        // Return dominant level
        if strongCount >= moderateCount && strongCount >= traceCount && strongCount > 0 {
            return .strong
        } else if moderateCount >= traceCount && moderateCount > 0 {
            return .moderate
        } else if traceCount > 0 {
            return .trace
        }
        return .none
    }

    private func highestLevel(for nutrientId: String, entries: [FoodEntry]) -> SourceLevel {
        var best: SourceLevel = .none
        for entry in entries {
            if let p = entry.micronutrientProfile {
                if let amt = p.vitamins[nutrientId] ?? p.minerals[nutrientId] {
                    best = max(best, classify(amount: amt, key: nutrientId, profile: p))
                }
            } else {
                let food = DiaryFoodItem.fromFoodEntry(entry)
                let present = NutrientDetector.detectNutrients(in: food).contains(nutrientId)
                best = max(best, present ? .trace : .none)
            }
        }
        return best
    }

    private func classify(amount: Double, key: String, profile: MicronutrientProfile) -> SourceLevel {
        if amount <= 0 { return .none }
        let dvKey = dvKey(for: key)
        if let percent = profile.getDailyValuePercentage(for: dvKey, amount: amount) {
            if percent >= 70 { return .strong }
            if percent >= 30 { return .moderate }
            return .trace
        }
        return .trace
    }

    private func dvKey(for key: String) -> String {
        switch key.lowercased() {
        case "vitaminc": return "vitamin_c"
        case "vitamina": return "vitamin_a"
        case "vitamind": return "vitamin_d"
        case "vitamine": return "vitamin_e"
        case "vitamink": return "vitamin_k"
        default: return key.lowercased()
        }
    }

    func shortDateLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    private func generateAdaptiveInsight() -> String? {
        let totalMeals = calculateTotalMealsLogged()
        let daysWithData = rhythmDays.filter { $0.level != .none }.count

        let hasSufficientData = totalMeals >= 5 && daysWithData >= 3

        if totalMeals == 0 {
            return "As you log more meals, your nutrient trends will start to appear here."
        }

        if !hasSufficientData {
            if totalMeals >= 2 {
                return "Good start — log \(5 - totalMeals) more meals to reveal your full nutrient rhythm."
            } else {
                return "As you log more meals, your nutrient trends will start to appear here."
            }
        }

        // Use existing insights if available
        if !insights.isEmpty {
            return insights.first
        }

        if daysWithData >= 5 {
            return "You're building a solid nutrient rhythm — keep it up this week."
        } else {
            return "Off to a good start — continue logging to strengthen your rhythm."
        }
    }

    private func calculateTotalMealsLogged() -> Int {
        let mealCount = rhythmDays.filter { $0.level != .none }.count
        return min(mealCount * 2, 30) // Rough estimate: assume ~2 meals per logged day
    }

    // MARK: - Health Disclaimer Banner

    private var healthDisclaimerBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text("Informational Only")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                Text("This app is not medical advice. Consult healthcare professionals for dietary guidance.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button(action: {
                showingSources = true
            }) {
                Image(systemName: "doc.text")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Micronutrient Row

struct MicronutrientRow: View {
    let summary: MicronutrientSummary

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    // Today ring
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 4)
                            .frame(width: 36, height: 36)

                        Circle()
                            .trim(from: 0, to: CGFloat(summary.todayPercentage) / 100.0)
                            .stroke(summary.todayStatus.color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 36, height: 36)
                            .rotationEffect(.degrees(-90))

                        Text(summary.todayStatus.emoji)
                            .font(.system(size: 13))
                    }

                    // 7-day ring
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 4)
                            .frame(width: 36, height: 36)

                        Circle()
                            .trim(from: 0, to: CGFloat(summary.sevenDayAverage) / 100.0)
                            .stroke(summary.sevenDayStatus.color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 36, height: 36)
                            .rotationEffect(.degrees(-90))

                        Text(summary.sevenDayStatus.emoji)
                            .font(.system(size: 13))
                    }
                }

                HStack(spacing: 8) {
                    Text("Today")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text("Last 7 days")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 100)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(summary.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    // Intensity label (Strong/Moderate/Trace)
                    Text(summary.todayStatus.label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(summary.todayStatus.color)

                    if summary.trend != .stable {
                        Text(summary.trend.symbol)
                            .font(.system(size: 13))
                            .foregroundColor(summary.trend.color)
                    }
                }

                // Show recent food sources
                if !summary.recentSources.isEmpty {
                    Text("from \(summary.recentSources.prefix(2).joined(separator: ", "))")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Show good food sources recommendations
                if let sources = summary.info?.commonSources {
                    let foodSources = parseArrayString(sources).prefix(3).joined(separator: ", ")
                    if !foodSources.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.green)
                            Text("Good sources: \(foodSources)")
                                .font(.system(size: 11))
                                .foregroundColor(.green.opacity(0.8))
                                .lineLimit(1)
                        }
                    }
                }
            }

            Spacer()

            Image(systemName: "info.circle")
                .font(.system(size: 16))
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    // Helper to parse JSON array strings
    private func parseArrayString(_ jsonString: String?) -> [String] {
        guard let jsonString = jsonString else { return [] }

        // Try to decode JSON array
        if let data = jsonString.data(using: .utf8),
           let array = try? JSONDecoder().decode([String].self, from: data) {
            return array
        }

        // Fallback: split by comma if not valid JSON
        return jsonString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}

// MARK: - Nutrient Info Sheet

struct NutrientInfoSheet: View {
    let summary: MicronutrientSummary
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Status card
                    statusCard

                    // Food sources - MOVED TO TOP for prominence
                    foodSourcesSection

                    // Functions in the body
                    if let benefits = summary.info?.benefits {
                        infoSection(
                            title: "Functions in the Body",
                            icon: "heart.fill",
                            color: .blue,
                            content: benefits
                        )
                    }

                    // Recommended intake
                    if let intake = summary.info?.recommendedDailyIntake {
                        infoSection(
                            title: "Recommended Daily Intake",
                            icon: "chart.bar.fill",
                            color: .purple,
                            content: intake
                        )
                    }

                    // Recent sources
                    if !summary.recentSources.isEmpty {
                        recentSourcesSection
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(summary.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var statusCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's Status")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {


                        VStack(alignment: .leading, spacing: 2) {
                            Text(summary.statusEmoji)
                                .font(.system(size: 20))
                            Text(summary.todayStatus.label)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(summary.todayStatus.color)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Text("7-Day Average")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    Text(summary.sevenDayStatus.label)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(summary.sevenDayStatus.color)

                    if summary.trend != .stable {
                        HStack(spacing: 4) {
                            Text(summary.trend.symbol)
                            Text(summary.trend.label)
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(summary.trend.color)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    private func infoSection(title: String, icon: String, color: Color, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
            }

            // Parse and display the content (handles JSON arrays)
            let items = parseArrayContent(content)

            if items.count > 1 {
                // Multiple items - show as bullet list
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)

                            Text(item)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            } else {
                // Single item or unparseable - show as plain text
                Text(items.first ?? content)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }

    /// Parse JSON array format like ["Item1", "Item2"] into a clean string array
    private func parseArrayContent(_ content: String) -> [String] {
        // Try to decode as JSON array first
        if let data = content.data(using: .utf8),
           let array = try? JSONDecoder().decode([String].self, from: data) {
            return array.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }

        // Fallback: manually parse array format
        let trimmed = content.trimmingCharacters(in: CharacterSet(charactersIn: "[]\""))
        if trimmed.contains(",") {
            return trimmed
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: " \"")) }
                .filter { !$0.isEmpty }
        }

        // Return as single item if not parseable
        return [trimmed]
    }

    private var foodSourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                Text("Good Food Sources")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
            }

            // Load food sources from database
            if let sources = summary.info?.commonSources {
                let items = parseArrayContent(sources)
                let _ = print("🍃 [NutrientInfoSheet] Rendering food sources for \(summary.nutrient): \(items)")
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Text("🍃")
                                .font(.system(size: 14))

                            Text(item)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            } else {
                let _ = print("⚠️ [NutrientInfoSheet] No sources for \(summary.nutrient) - info: \(summary.info != nil), commonSources: \(summary.info?.commonSources ?? "nil")")
                Text("Loading food sources...")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }

    private var recentSourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                Text("Recent Food Sources")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(summary.recentSources.prefix(10), id: \.self) { source in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)

                        Text(source)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)

                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        MicronutrientDashboard()
    }
}
