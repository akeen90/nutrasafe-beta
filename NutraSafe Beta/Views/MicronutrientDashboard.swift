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
    @State private var insights: [String] = []
    @State private var nutrientSummaries: [MicronutrientSummary] = []
    @State private var hasLoadedData = false // Performance: Track if we've already loaded data
    @State private var isLoading = false // Performance: Prevent duplicate loads

    enum DashboardFilter: String, CaseIterable {
        case all = "All"
        case strong = "Strong Sources"
        case moderate = "Moderate Sources"
        case traceMissing = "Trace / Missing"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
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
        .task {
            // Performance: Only load data once, not every time view appears
            guard !hasLoadedData && !isLoading else {
                print("⚡️ Skipping reload - data already loaded")
                return
            }

            isLoading = true
            print("📊 MicronutrientDashboard: Fast initial load starting...")

            // PERFORMANCE OPTIMIZATION: Load Firebase data first, then show UI IMMEDIATELY
            // This allows the user to see the UI without waiting for today's food processing
            nutrientSummaries = await trackingManager.getAllNutrientSummaries()
            insights = await trackingManager.generateTodayInsights()

            hasLoadedData = true
            isLoading = false
            print("✅ MicronutrientDashboard: UI ready with Firebase data")

            // Background: Process today's foods asynchronously (doesn't block UI)
            Task.detached(priority: .utility) {
                await self.processTodaysFoods()

                // Refresh summaries and insights after processing
                await MainActor.run {
                    Task {
                        self.nutrientSummaries = await trackingManager.getAllNutrientSummaries()
                        self.insights = await trackingManager.generateTodayInsights()
                        await recommendationEngine.generateRecommendations(for: self.nutrientSummaries)
                        print("🔄 Background refresh complete")
                    }
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Micronutrients")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("Comprehensive nutrient tracking")
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
        }
        .padding(.top, 8)
    }

    // MARK: - Balance Overview Bar

    private func balanceOverviewBar(balance: NutrientBalanceScore) -> some View {
        VStack(spacing: 16) {
            // Main balance indicator
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's Balance")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        Text("\(balance.balancePercentage)%")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(balance.balanceStatus.color)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(balance.balanceStatus.emoji)
                                .font(.system(size: 24))
                            Text(balance.balanceStatus.label)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(balance.balanceStatus.color)
                        }
                    }
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
                    label: "Trace",
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
                            .fill(Color.red)
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
        VStack(alignment: .leading, spacing: 12) {
            if !insights.isEmpty {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.orange)
                    Text("Today's Insights")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(insights, id: \.self) { insight in
                        HStack(alignment: .top, spacing: 12) {
                            Text("•")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.secondary)

                            Text(insight)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer()
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
    }

    // MARK: - Filter Tabs

    private var filterTabsSection: some View {
        HStack(spacing: 12) {
            ForEach(DashboardFilter.allCases, id: \.self) { filter in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedFilter = filter
                    }
                }) {
                    Text(filter.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selectedFilter == filter ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedFilter == filter ? Color.blue : Color(.systemGray5))
                        )
                }
            }

            Spacer()
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
        print("📊 MicronutrientDashboard: Processing TODAY ONLY (performance fix)")

        // PERFORMANCE FIX: Only process TODAY'S foods, not 30 days
        // The tracking manager will automatically calculate 7-day and 30-day averages from Firebase data
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        do {
            // Only fetch and process today's foods
            let (breakfast, lunch, dinner, snacks) = try await diaryDataManager.getFoodDataAsync(for: today)
            let allFoods = breakfast + lunch + dinner + snacks

            print("📥 Processing \(allFoods.count) foods from today")

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
}

// MARK: - Micronutrient Row

struct MicronutrientRow: View {
    let summary: MicronutrientSummary

    var body: some View {
        HStack(spacing: 12) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 4)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: CGFloat(summary.todayPercentage) / 100.0)
                    .stroke(summary.todayStatus.color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))

                Text(summary.statusEmoji)
                    .font(.system(size: 16))
            }

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

                    Text("(\(summary.todayPercentage)%)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)

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

                    // Benefits
                    if let benefits = summary.info?.benefits {
                        infoSection(
                            title: "Benefits",
                            icon: "heart.fill",
                            color: .green,
                            content: benefits
                        )
                    }

                    // Deficiency signs
                    if let deficiency = summary.info?.deficiencySigns {
                        infoSection(
                            title: "Deficiency Signs",
                            icon: "exclamationmark.triangle.fill",
                            color: .orange,
                            content: deficiency
                        )
                    }

                    // Food sources
                    if let sources = summary.info?.commonSources {
                        infoSection(
                            title: "Common Food Sources",
                            icon: "leaf.fill",
                            color: .blue,
                            content: sources
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
                        Text("\(summary.todayPercentage)%")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(summary.todayStatus.color)

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

                    Text("\(Int(summary.sevenDayAverage))%")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
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
