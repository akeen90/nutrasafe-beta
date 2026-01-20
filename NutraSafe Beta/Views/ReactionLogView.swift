//
//  ReactionLogView.swift
//  NutraSafe Beta
//
//  Reaction Log Mode - Track reactions and analyze possible food triggers
//

import SwiftUI
import FirebaseFirestore

struct ReactionLogView: View {
    @StateObject private var manager = ReactionLogManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingLogSheet = false
    @State private var selectedEntry: ReactionLogEntry?
    @State private var selectedDayRange: DayRange = .threeDays
    @State private var selectedTab: AnalysisTab = .potentialTriggers
    @State private var showingPDFExportSheet = false
    @State private var isLoadingData = false
    @State private var userAllergens: Set<Allergen> = []
    @State private var selectedSymptomFilter: String? = nil  // nil = All Symptoms
    @State private var allergenLoadFailed = false  // Track allergen load failures for user feedback
    @State private var allergenLoadRetryCount = 0  // Retry counter for exponential backoff

    // MARK: - Cached Computed Values (Performance Optimization)
    // These are expensive to compute and don't need to recalculate on every view redraw
    @State private var cachedUniqueSymptoms: [String] = []
    @State private var cachedCommonFoods: [(name: String, frequency: Int, percentage: Double)] = []
    @State private var cachedCommonIngredients: [(name: String, frequency: Int, percentage: Double, isPrimarilyEstimated: Bool)] = []
    @State private var cachedMostCommonSymptom: (symptom: String, percentage: Int)?
    @State private var cachedPeakTiming: String?
    @State private var cachedTopTrigger: (name: String, percentage: Int)?
    @State private var cachedWeeklyTrend: (thisWeek: Int, lastWeek: Int, trend: String)?
    @State private var lastCacheUpdateLogCount: Int = -1  // Track when cache was last updated

    enum DayRange: Int, CaseIterable {
        case threeDays = 3
        case fiveDays = 5
        case sevenDays = 7

        var displayText: String {
            "\(rawValue) days"
        }
    }

    enum AnalysisTab: String, CaseIterable {
        case potentialTriggers = "Potential Triggers"
        case reactionTimeline = "Reaction Timeline"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Allergen load failure warning (safety-critical)
                if allergenLoadFailed {
                    allergenWarningBanner
                }

                // Log Reaction Button
                logReactionButton

                // Export PDF Button (only show if there are reactions)
                if !manager.reactionLogs.isEmpty {
                    exportPDFButton
                }

                // Loading state or content
                if isLoadingData {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .progressViewStyle(.circular)
                        Text("Loading reaction history...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    // Analysis Tabs
                    analysisTabPicker

                    // Tab Content
                    tabContent
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color.adaptiveBackground)
        .fullScreenCover(isPresented: $showingLogSheet) {
            LogReactionSheet(selectedDayRange: selectedDayRange)
        }
        .fullScreenCover(item: $selectedEntry) { entry in
            ReactionLogDetailView(entry: entry, selectedDayRange: selectedDayRange)
        }
        .fullScreenCover(isPresented: $showingPDFExportSheet) {
            MultiReactionPDFExportSheet()
        }
        .task {
            isLoadingData = true
            async let logsTask: () = manager.loadReactionLogs()
            async let allergensTask: () = loadUserAllergens()
            await logsTask
            await allergensTask
            updateCachedValues()
            isLoadingData = false
            print("📊 [ReactionLogView] Initial load complete. reactionLogs count: \(manager.reactionLogs.count)")
        }
        .onChange(of: showingLogSheet) { _, isShowing in
            if !isShowing {
                // Refresh when log sheet closes - force reload to ensure we have latest data
                print("📊 [ReactionLogView] Log sheet dismissed. Current reactionLogs count: \(manager.reactionLogs.count)")
                // Force refresh from Firebase to ensure consistency
                Task {
                    print("📊 [ReactionLogView] Reloading reaction logs after sheet dismissed...")
                    await manager.loadReactionLogs()
                    updateCachedValues()
                    print("📊 [ReactionLogView] Reload complete. New count: \(manager.reactionLogs.count)")
                }
            }
        }
        .onChange(of: manager.reactionLogs.count) {
            // Update cache when reaction logs change
            updateCachedValues()
        }
        .trackScreen("Reaction Log")
    }

    // MARK: - Cache Update (Performance Optimization)

    /// Updates all cached computed values. Called once when data changes rather than on every view redraw.
    private func updateCachedValues() {
        let logs = manager.reactionLogs

        // Only update if data actually changed
        guard logs.count != lastCacheUpdateLogCount else { return }
        lastCacheUpdateLogCount = logs.count

        // Calculate unique symptoms (sorted by frequency) - O(n) single pass
        let symptomCounts = logs.reduce(into: [String: Int]()) { counts, log in
            counts[log.reactionType, default: 0] += 1
        }
        cachedUniqueSymptoms = symptomCounts.keys.sorted {
            (symptomCounts[$0] ?? 0) > (symptomCounts[$1] ?? 0)
        }

        // Calculate most common symptom (reuse symptomCounts - no extra iteration)
        if let (symptom, count) = symptomCounts.max(by: { $0.value < $1.value }) {
            let percentage = Int((Double(count) / Double(logs.count)) * 100)
            cachedMostCommonSymptom = (symptom, percentage)
        } else {
            cachedMostCommonSymptom = nil
        }

        // Calculate peak timing
        if !logs.isEmpty {
            let calendar = Calendar.current
            var timingCounts: [String: Int] = ["Morning": 0, "Afternoon": 0, "Evening": 0, "Night": 0]

            for entry in logs {
                let hour = calendar.component(.hour, from: entry.reactionDate)
                switch hour {
                case 5..<12: timingCounts["Morning", default: 0] += 1
                case 12..<17: timingCounts["Afternoon", default: 0] += 1
                case 17..<21: timingCounts["Evening", default: 0] += 1
                default: timingCounts["Night", default: 0] += 1
                }
            }
            cachedPeakTiming = timingCounts.max(by: { $0.value < $1.value })?.key
        } else {
            cachedPeakTiming = nil
        }

        // Calculate weekly trend - single pass instead of two filters
        let calendar = Calendar.current
        let now = Date()
        if let startOfThisWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
           let startOfLastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: startOfThisWeek) {
            var thisWeekCount = 0
            var lastWeekCount = 0
            for log in logs {
                if log.reactionDate >= startOfThisWeek {
                    thisWeekCount += 1
                } else if log.reactionDate >= startOfLastWeek {
                    lastWeekCount += 1
                }
            }

            let trend: String
            if thisWeekCount < lastWeekCount {
                trend = "down"
            } else if thisWeekCount > lastWeekCount {
                trend = "up"
            } else {
                trend = "same"
            }
            cachedWeeklyTrend = (thisWeekCount, lastWeekCount, trend)
        } else {
            cachedWeeklyTrend = nil
        }

        // Calculate top trigger
        var ingredientScores: [String: Double] = [:]
        for entry in logs {
            guard let analysis = entry.triggerAnalysis else { continue }
            for ingredient in analysis.topIngredients.prefix(3) {
                ingredientScores[ingredient.ingredientName, default: 0] += ingredient.crossReactionFrequency
            }
        }
        if let (name, score) = ingredientScores.max(by: { $0.value < $1.value }), score > 0 {
            let percentage = Int(score / Double(max(1, logs.filter { $0.triggerAnalysis != nil }.count)))
            cachedTopTrigger = (name, min(percentage, 100))
        } else {
            cachedTopTrigger = nil
        }

        // Calculate common foods
        var foodCounts: [String: (count: Int, displayName: String)] = [:]
        for entry in logs {
            guard let analysis = entry.triggerAnalysis else { continue }
            for food in analysis.topFoods {
                let normalizedName = food.foodName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                if foodCounts[normalizedName] == nil {
                    foodCounts[normalizedName] = (count: 1, displayName: food.foodName)
                } else {
                    foodCounts[normalizedName]?.count += 1
                }
            }
        }
        let totalReactions = logs.count
        cachedCommonFoods = foodCounts
            .filter { $0.value.count >= 2 }
            .map { (name: $0.value.displayName, frequency: $0.value.count, percentage: (Double($0.value.count) / Double(max(1, totalReactions))) * 100.0) }
            .sorted { $0.frequency > $1.frequency }

        // Calculate common ingredients
        var ingredientCounts: [String: (count: Int, displayName: String, exactCount: Int, estimatedCount: Int)] = [:]
        for entry in logs {
            guard let analysis = entry.triggerAnalysis else { continue }
            for ingredient in analysis.topIngredients {
                let normalizedName = ingredient.ingredientName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                if ingredientCounts[normalizedName] == nil {
                    ingredientCounts[normalizedName] = (
                        count: 1,
                        displayName: ingredient.ingredientName,
                        exactCount: ingredient.exactExposureCount,
                        estimatedCount: ingredient.estimatedExposureCount
                    )
                } else {
                    ingredientCounts[normalizedName]?.count += 1
                    ingredientCounts[normalizedName]?.exactCount += ingredient.exactExposureCount
                    ingredientCounts[normalizedName]?.estimatedCount += ingredient.estimatedExposureCount
                }
            }
        }
        cachedCommonIngredients = ingredientCounts
            .filter { $0.value.count >= 2 }
            .map {
                let isPrimarilyEstimated = $0.value.estimatedCount > $0.value.exactCount
                return (
                    name: $0.value.displayName,
                    frequency: $0.value.count,
                    percentage: (Double($0.value.count) / Double(max(1, totalReactions))) * 100.0,
                    isPrimarilyEstimated: isPrimarilyEstimated
                )
            }
            .sorted { $0.frequency > $1.frequency }
    }

    // MARK: - Load User Allergens

    private func loadUserAllergens() async {
        // Try to load from cache first (UserDefaults) for instant display
        if let cachedAllergens = loadCachedAllergens() {
            await MainActor.run {
                userAllergens = cachedAllergens
            }
        }

        // Then fetch fresh data from server
        do {
            let settings = try await FirebaseManager.shared.getUserSettings()
            let allergens = Set(settings.allergens ?? [])
            await MainActor.run {
                userAllergens = allergens
                allergenLoadFailed = false
                allergenLoadRetryCount = 0
            }
            // Cache for offline access
            cacheAllergens(allergens)
        } catch {
            // CRITICAL: Allergen loading is safety-critical for a food reaction tracking app
            // Log error and show subtle indicator, but don't crash
            print("⚠️ [ReactionLogView] Failed to load allergens: \(error.localizedDescription)")

            // Retry with exponential backoff (max 3 retries)
            if allergenLoadRetryCount < 3 {
                await MainActor.run {
                    allergenLoadRetryCount += 1
                }
                let delay = UInt64(pow(2.0, Double(allergenLoadRetryCount))) * 1_000_000_000 // 2, 4, 8 seconds
                try? await Task.sleep(nanoseconds: delay)
                await loadUserAllergens() // Recursive retry
            } else {
                // Max retries reached - show warning if no cached data
                await MainActor.run {
                    if userAllergens.isEmpty {
                        allergenLoadFailed = true
                    }
                }
            }
        }
    }

    // MARK: - Allergen Cache (for offline safety)

    private func loadCachedAllergens() -> Set<Allergen>? {
        guard let data = UserDefaults.standard.data(forKey: "cachedUserAllergens"),
              let allergenIds = try? JSONDecoder().decode([String].self, from: data) else {
            return nil
        }
        // Convert IDs back to Allergen enum values
        let allergens = allergenIds.compactMap { id in
            Allergen.allCases.first { $0.rawValue == id }
        }
        return Set(allergens)
    }

    private func cacheAllergens(_ allergens: Set<Allergen>) {
        let allergenIds = allergens.map { $0.rawValue }
        if let data = try? JSONEncoder().encode(allergenIds) {
            UserDefaults.standard.set(data, forKey: "cachedUserAllergens")
        }
    }

    /// Check if an ingredient matches user's saved allergens
    private func isUserAllergenIngredient(_ ingredient: String) -> Bool {
        let lower = ingredient.lowercased()

        for allergen in userAllergens {
            // Check against allergen keywords
            for keyword in allergen.keywords {
                if lower.contains(keyword.lowercased()) {
                    return true
                }
            }
        }
        return false
    }

    // MARK: - Allergen Warning Banner (shown when allergens fail to load)
    private var allergenWarningBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Allergen data unavailable")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                Text("Your saved allergens couldn't be loaded. Tap to retry.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                allergenLoadFailed = false
                allergenLoadRetryCount = 0
                Task {
                    await loadUserAllergens()
                }
            }) {
                Text("Retry")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .cornerRadius(8)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Log Reaction Button (Onboarding Design Language)
    private var logReactionButton: some View {
        Button(action: { showingLogSheet = true }) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)

                Text("Log Reaction")
                    .font(AppTypography.button)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.20, green: 0.45, blue: 0.50),
                        Color(red: 0.15, green: 0.35, blue: 0.42)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(AppRadius.large)
            .accentShadow(Color(red: 0.20, green: 0.45, blue: 0.50))
        }
    }

    // MARK: - Export PDF Button (Onboarding Design Language)
    private var exportPDFButton: some View {
        Button(action: { showingPDFExportSheet = true }) {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.textSecondary)

                Text("Export PDF Report")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.large)
                    .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.large)
                    .stroke(Color.textTertiary.opacity(0.3), lineWidth: 1)
            )
            .cardShadow()
        }
    }

    // MARK: - Analysis Tab Picker (Onboarding Design Language)
    private var analysisTabPicker: some View {
        HStack(spacing: 0) {
            ForEach(AnalysisTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    Text(tab.rawValue)
                        .font(.system(size: 15, weight: selectedTab == tab ? .semibold : .medium))
                        .foregroundColor(selectedTab == tab ? .white : Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedTab == tab ?
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.20, green: 0.45, blue: 0.50),
                                        Color(red: 0.15, green: 0.35, blue: 0.42)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [Color.clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                        .cornerRadius(AppRadius.medium)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.large)
                .fill(colorScheme == .dark ? Color.midnightCard : Color(.systemGray6))
        )
    }

    // MARK: - Tab Content
    // Both views are kept in the hierarchy but only one is visible.
    // This prevents SwiftUI from rebuilding views on tab switch for instant transitions.
    private var tabContent: some View {
        ZStack {
            potentialTriggersView
                .opacity(selectedTab == .potentialTriggers ? 1 : 0)
                .allowsHitTesting(selectedTab == .potentialTriggers)

            reactionTimelineView
                .opacity(selectedTab == .reactionTimeline ? 1 : 0)
                .allowsHitTesting(selectedTab == .reactionTimeline)
        }
    }

    // MARK: - Potential Triggers View
    private var potentialTriggersView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if manager.reactionLogs.isEmpty {
                emptyStateView(
                    icon: "chart.bar.doc.horizontal",
                    title: "No reactions logged yet",
                    message: "Log your first reaction to start identifying potential food triggers"
                )
            } else if manager.reactionLogs.count < 2 {
                emptyStateView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Building your pattern analysis",
                    message: "Log at least 2 reactions to identify potential triggers and patterns"
                )
            } else {
                // Flagged foods patterns
                commonFoodsView

                // Common ingredients patterns
                commonIngredientsView
            }
        }
    }

    // MARK: - Reaction Timeline View
    private var reactionTimelineView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if manager.reactionLogs.isEmpty {
                emptyStateView(
                    icon: "clock.badge.questionmark",
                    title: "No reactions logged yet",
                    message: "Start logging reactions to see your timeline and meal history"
                )
            } else {
                // Smart insights card (shown with 3+ reactions)
                reactionInsightsCard

                // Symptom filter picker
                symptomFilterPicker

                // Filtered reaction history list
                let filteredLogs = filteredReactionLogs

                if filteredLogs.isEmpty {
                    // No reactions for selected symptom
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No \(selectedSymptomFilter ?? "reactions") logged")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    // Show count
                    Text("\(filteredLogs.count) \(filteredLogs.count == 1 ? "reaction" : "reactions")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    ForEach(filteredLogs) { entry in
                        Button(action: {
                            selectedEntry = entry
                        }) {
                            ReactionLogCard(entry: entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Symptom Filter Picker
    private var symptomFilterPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Filter by Symptom")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // All Symptoms option
                    symptomFilterChip(symptom: nil, label: "All", icon: "list.bullet")

                    // Get unique symptoms from logged reactions (using cached values)
                    ForEach(cachedUniqueSymptoms, id: \.self) { symptom in
                        let reactionType = ReactionType.allCases.first { $0.rawValue == symptom }
                        symptomFilterChip(
                            symptom: symptom,
                            label: symptom,
                            icon: reactionType?.icon ?? "circle.fill"
                        )
                    }
                }
                .padding(.horizontal, 1)
            }
        }
        .padding(.bottom, 8)
    }

    private func symptomFilterChip(symptom: String?, label: String, icon: String) -> some View {
        let isSelected = selectedSymptomFilter == symptom

        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSymptomFilter = symptom
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.blue : Color(.systemGray5))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Filtered Reaction Logs
    private var filteredReactionLogs: [ReactionLogEntry] {
        guard let symptom = selectedSymptomFilter else {
            return manager.reactionLogs
        }
        return manager.reactionLogs.filter { $0.reactionType == symptom }
    }

    // NOTE: Computed insight properties have been replaced with cached @State properties
    // (cachedUniqueSymptoms, cachedMostCommonSymptom, cachedPeakTiming, cachedWeeklyTrend, cachedTopTrigger)
    // which are updated via updateCachedValues() when data changes, rather than on every view redraw.
    // This eliminates expensive O(n×m) recalculations during tab switching.

    // MARK: - Reaction Insights Card
    @ViewBuilder
    private var reactionInsightsCard: some View {
        // Only show if we have enough data (3+ reactions)
        if manager.reactionLogs.count >= 3 {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text("Your Reaction Insights")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                }

                // Insights rows (using cached values for performance)
                VStack(spacing: 10) {
                    // Most common symptom
                    if let insight = cachedMostCommonSymptom {
                        insightRow(
                            icon: "chart.bar.fill",
                            iconColor: .blue,
                            label: "Most common",
                            value: "\(insight.symptom) (\(insight.percentage)%)"
                        )
                    }

                    // Peak timing
                    if let timing = cachedPeakTiming {
                        insightRow(
                            icon: "clock.fill",
                            iconColor: .orange,
                            label: "Peak timing",
                            value: timing
                        )
                    }

                    // Weekly trend
                    if let trend = cachedWeeklyTrend {
                        let trendColor: Color = trend.trend == "down" ? .green : (trend.trend == "up" ? .red : .secondary)
                        let trendText = trend.trend == "down" ? "↓ from \(trend.lastWeek)" : (trend.trend == "up" ? "↑ from \(trend.lastWeek)" : "same as last week")

                        insightRow(
                            icon: "calendar",
                            iconColor: .purple,
                            label: "This week",
                            value: "\(trend.thisWeek) \(trend.thisWeek == 1 ? "reaction" : "reactions")",
                            badge: trendText,
                            badgeColor: trendColor
                        )
                    }

                    // Top trigger
                    if let trigger = cachedTopTrigger {
                        insightRow(
                            icon: "target",
                            iconColor: .red,
                            label: "Watch for",
                            value: trigger.name,
                            badge: "\(trigger.percentage)% correlation",
                            badgeColor: .secondary
                        )
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .padding(.bottom, 8)
        }
    }

    private func insightRow(icon: String, iconColor: Color, label: String, value: String, badge: String? = nil, badgeColor: Color = .secondary) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(iconColor)
                .frame(width: 20)

            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)

            if let badge = badge {
                Text(badge)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(badgeColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(badgeColor.opacity(0.15))
                    .cornerRadius(4)
            }
        }
    }

    // MARK: - Empty State (Onboarding Design Language)
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: AppSpacing.large) {
            // Abstract icon - light weight, subtle
            Image(systemName: icon)
                .font(.system(size: 60, weight: .light))
                .foregroundColor(Color.textTertiary.opacity(0.4))
                .padding(.top, AppSpacing.large)

            VStack(spacing: AppSpacing.small) {
                Text(title)
                    .font(AppTypography.sectionTitle(20))
                    .foregroundColor(Color.textSecondary)

                Text(message)
                    .font(AppTypography.body)
                    .foregroundColor(Color.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(AppSpacing.lineSpacing)
            }

            // Helpful tip using onboarding InfoCard pattern
            NSInfoCard(
                icon: "lightbulb.fill",
                text: "Track reactions to help identify patterns and potential food sensitivities over time",
                iconColor: .orange
            )
            .padding(.horizontal, AppSpacing.large)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.section)
    }

    // MARK: - Common Foods View (Flagged Foods)
    private var commonFoodsView: some View {
        // Using cached values for performance (no recalculation on tab switch)
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(spacing: AppSpacing.small) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.orange)
                Text("Flagged Foods")
                    .font(AppTypography.sectionTitle(18))
                    .foregroundColor(Color.textPrimary)
            }

            Text("These specific foods appear frequently before your reactions. Track these items to identify patterns.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 4)

            if cachedCommonFoods.isEmpty {
                Text("Not enough observations yet to identify food patterns")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(cachedCommonFoods.prefix(10), id: \.name) { food in
                    CommonFoodRow(
                        name: food.name,
                        frequency: food.frequency,
                        percentage: food.percentage
                    )
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }

    // MARK: - Common Ingredients View
    private var commonIngredientsView: some View {
        // Using cached values for performance (no recalculation on tab switch)
        let matchedAllergens = cachedCommonIngredients.filter { isUserAllergenIngredient($0.name) }

        return VStack(alignment: .leading, spacing: 16) {
            Text("Ingredient Patterns")
                .font(.headline)
                .foregroundColor(.primary)

            Text("These ingredients appear frequently in foods consumed before your reactions. This information may help you spot potential connections to discuss with your healthcare provider.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 4)

            // User allergen warning banner
            if !matchedAllergens.isEmpty && !userAllergens.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(matchedAllergens.count) of your allergens detected")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)

                        Text("These match allergens you've saved in your profile")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.9))
                    }

                    Spacer()
                }
                .padding(14)
                .background(
                    LinearGradient(
                        colors: [Color.red, Color.orange.opacity(0.9)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: .red.opacity(0.3), radius: 6, x: 0, y: 3)
            }

            if cachedCommonIngredients.isEmpty {
                Text("Not enough observations yet to identify ingredient patterns")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                // Disclaimer about estimated ingredients (AI-Inferred Meal Analysis)
                if cachedCommonIngredients.contains(where: { $0.isPrimarilyEstimated }) {
                    Text("Patterns may include both exact ingredients and estimated exposures from meals without ingredient labels.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                }

                ForEach(cachedCommonIngredients.prefix(10), id: \.name) { ingredient in
                    CommonIngredientRow(
                        name: ingredient.name,
                        frequency: ingredient.frequency,
                        percentage: ingredient.percentage,
                        isUserAllergen: isUserAllergenIngredient(ingredient.name),
                        isPrimarilyEstimated: ingredient.isPrimarilyEstimated
                    )
                }
            }
        }
    }

    // NOTE: calculateCommonIngredients() and calculateCommonFoods() have been moved into
    // updateCachedValues() to compute once when data changes rather than on every view render.
}

// MARK: - Stat Card
struct StatCard: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Text("\(count)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Common Ingredient Row
struct CommonIngredientRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let name: String
    let frequency: Int
    let percentage: Double
    var isUserAllergen: Bool = false
    var isPrimarilyEstimated: Bool = false  // AI-Inferred Meal Analysis: true if most exposures are from estimated sources

    var body: some View {
        HStack(spacing: 12) {
            // User allergen warning badge
            if isUserAllergen {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(6)
                    .background(
                        LinearGradient(
                            colors: [Color.red, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: .red.opacity(0.4), radius: 3, x: 0, y: 2)
            } else {
                Circle()
                    .fill(frequencyColor)
                    .frame(width: 10, height: 10)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isUserAllergen ? .red : .primary)

                    if isUserAllergen {
                        Text("YOUR ALLERGEN")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(4)
                    }

                    // AI-Inferred Meal Analysis: Show "Estimated" badge for ingredients primarily from inferred sources
                    if isPrimarilyEstimated {
                        Text("Estimated")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.8))
                            .cornerRadius(4)
                    }
                }

                Text("Appears in \(frequency) reaction\(frequency == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(percentage))%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(frequencyColor)

                Text("frequency")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            isUserAllergen
                ? Color.red.opacity(0.1)
                : (colorScheme == .dark ? Color.midnightCard : Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isUserAllergen ? Color.red.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .cornerRadius(10)
        .shadow(color: isUserAllergen ? .red.opacity(0.2) : .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }

    private var frequencyColor: Color {
        if percentage >= 80 {
            return .red
        } else if percentage >= 50 {
            return .orange
        } else {
            return .yellow
        }
    }
}

// MARK: - Common Food Row (Flagged Foods)
struct CommonFoodRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let name: String
    let frequency: Int
    let percentage: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "flag.fill")
                .font(.system(size: 12))
                .foregroundColor(frequencyColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text("Before \(frequency) reaction\(frequency == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(percentage))%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(frequencyColor)

                Text("correlation")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(colorScheme == .dark ? Color.midnightCard : Color(.secondarySystemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }

    private var frequencyColor: Color {
        if percentage >= 80 {
            return .red
        } else if percentage >= 50 {
            return .orange
        } else {
            return .yellow
        }
    }
}

// MARK: - Reaction Log Card

struct ReactionLogCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: ReactionLogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Reaction type icon
                Image(systemName: reactionIcon)
                    .font(.title3)
                    .foregroundColor(.orange)
                    .frame(width: 32, height: 32)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.reactionType)
                        .font(.headline)

                    Text(entry.reactionDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    +
                    Text(" at ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    +
                    Text(entry.reactionDate, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            if let notes = entry.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            if let analysis = entry.triggerAnalysis {
                HStack(spacing: 16) {
                    Label("\(analysis.mealCount) meals analyzed", systemImage: "fork.knife")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label("\(analysis.topFoods.count) foods identified", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(12)
        .background(colorScheme == .dark ? Color.midnightCard : Color(.secondarySystemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }

    private var reactionIcon: String {
        if let type = ReactionType(rawValue: entry.reactionType) {
            return type.icon
        }
        return "exclamationmark.circle"
    }
}

// MARK: - Log Reaction Sheet (Modern Redesign)

struct LogReactionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var manager = ReactionLogManager.shared

    let selectedDayRange: ReactionLogView.DayRange

    // Core state - supports multiple symptom selection
    @State private var selectedTypes: Set<ReactionType> = []
    @State private var customType: String = ""
    @State private var reactionDate: Date = Date()
    @State private var selectedSeverity: ReactionSeverity = .moderate
    @State private var notes: String = ""
    @State private var dayRange: ReactionLogView.DayRange

    // Food source state - 4 options as requested
    @State private var foodSource: FoodSource = .diary
    @State private var recentMeals: [FoodEntry] = []
    @State private var isLoadingMeals = false
    @State private var showMealSelection = false
    @State private var showDatabaseSearch = false

    // Multiple foods support - stores all selected foods
    @State private var selectedFoods: [SelectedFood] = []

    // Temporary state for adding a new food (cleared after adding)
    @State private var tempSelectedFoodId: String? = nil
    @State private var tempManualFoodName: String = ""
    @State private var tempSelectedSearchFood: FoodSearchResult? = nil

    // Inline database search state
    @State private var databaseSearchText: String = ""
    @State private var databaseSearchResults: [FoodSearchResult] = []
    @State private var isDatabaseSearching = false
    @State private var databaseSearchTask: Task<Void, Never>?
    @FocusState private var isDatabaseSearchFocused: Bool
    @StateObject private var searchDebouncer = Debouncer(milliseconds: 300)

    // Barcode scanning state
    @State private var showingBarcodeScanner = false
    @State private var isBarcodeSearching = false

    // Editable ingredients list
    @State private var editableIngredients: [String] = []
    @State private var newIngredientText: String = ""

    // AI Ingredient Estimation state
    @State private var showingInferredIngredientsSheet = false
    @State private var inferredIngredients: [InferredIngredient] = []

    // UI state
    @State private var isSaving: Bool = false
    @State private var showSuccess: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    // Food source options: Diary, Database Search, AI Estimate, Manual
    enum FoodSource: String, CaseIterable {
        case diary = "Diary"
        case database = "Search"
        case ai = "AI"
        case manual = "Manual"

        var icon: String {
            switch self {
            case .diary: return "book.fill"
            case .database: return "magnifyingglass"
            case .ai: return "sparkles"
            case .manual: return "pencil"
            }
        }
    }

    // Represents a food item selected for the reaction
    struct SelectedFood: Identifiable, Equatable {
        let id = UUID()
        let name: String
        let source: FoodSource
        var ingredients: [String]
        let diaryEntryId: String? // For diary entries
        let searchResult: FoodSearchResult? // For database searches

        static func == (lhs: SelectedFood, rhs: SelectedFood) -> Bool {
            lhs.id == rhs.id
        }
    }

    init(selectedDayRange: ReactionLogView.DayRange) {
        self.selectedDayRange = selectedDayRange
        self._dayRange = State(initialValue: selectedDayRange)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Reaction Type Section
                    reactionTypeSection

                    // Severity Section
                    severitySection

                    // Date & Time Section
                    dateTimeSection

                    // Food Connection Section
                    foodConnectionSection

                    // Notes Section
                    notesSection

                    // Save Button
                    saveButton
                }
                .padding(20)
            }
            .background(Color.adaptiveBackground)
            .navigationTitle("Log Reaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isSaving {
                    savingOverlay
                } else if showSuccess {
                    successOverlay
                }
            }
        }
        .fullScreenCover(isPresented: $showMealSelection) {
            mealSelectionSheet
        }
        .sheet(isPresented: $showingInferredIngredientsSheet) {
            InferredIngredientsSheet(
                foodName: tempManualFoodName.isEmpty ? "Food" : tempManualFoodName,
                inferredIngredients: $inferredIngredients
            )
        }
        .fullScreenCover(isPresented: $showingBarcodeScanner) {
            ReactionBarcodeScannerSheet(
                onFoodFound: { food in
                    showingBarcodeScanner = false
                    selectDatabaseFood(food)
                },
                onCancel: {
                    showingBarcodeScanner = false
                }
            )
        }
        .onAppear {
            loadRecentMeals()
        }
        .onChange(of: inferredIngredients) { _, _ in
            // When AI inference completes, populate editable ingredients
            populateIngredientsFromAI()
        }
        .onDisappear {
            // Cancel any pending search tasks when the sheet is dismissed
            databaseSearchTask?.cancel()
        }
    }

    // MARK: - Reaction Type Section

    private var reactionTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(title: "What happened?", icon: "exclamationmark.triangle.fill", color: .orange)
                Spacer()
                if !selectedTypes.isEmpty {
                    Text("\(selectedTypes.count) selected")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            Text("Select all that apply")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .padding(.bottom, 4)

            // Reaction type grid (2 columns)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(ReactionType.allCases.filter { $0 != .custom }, id: \.self) { type in
                    reactionTypeButton(type)
                }
            }

            // Custom/Other option
            reactionTypeButton(.custom)
                .frame(maxWidth: .infinity)

            if selectedTypes.contains(.custom) {
                TextField("Describe your reaction...", text: $customType)
                    .textFieldStyle(.plain)
                    .padding(14)
                    .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(16)
    }

    private func reactionTypeButton(_ type: ReactionType) -> some View {
        let isSelected = selectedTypes.contains(type)
        return Button(action: {
            // Toggle selection
            if isSelected {
                selectedTypes.remove(type)
            } else {
                selectedTypes.insert(type)
            }
        }) {
            HStack(spacing: 8) {
                // Checkmark for selected items
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                } else {
                    Image(systemName: type.icon)
                        .font(.system(size: 16))
                }
                Text(type.rawValue)
                    .font(.system(size: 14, weight: .medium))
                Spacer()
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(
                isSelected ?
                LinearGradient(colors: [.orange, .red.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                LinearGradient(colors: [colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Severity Section

    private var severitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "How severe?", icon: "speedometer", color: .red)

            HStack(spacing: 10) {
                ForEach(ReactionSeverity.allCases, id: \.self) { severity in
                    Button(action: { selectedSeverity = severity }) {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(severityColor(severity).opacity(selectedSeverity == severity ? 0.2 : 0.1))
                                    .frame(width: 44, height: 44)
                                Circle()
                                    .fill(severityColor(severity))
                                    .frame(width: selectedSeverity == severity ? 20 : 12, height: selectedSeverity == severity ? 20 : 12)
                            }
                            Text(severityLabel(severity))
                                .font(.system(size: 13, weight: selectedSeverity == severity ? .bold : .medium))
                                .foregroundColor(selectedSeverity == severity ? severityColor(severity) : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedSeverity == severity ? severityColor(severity).opacity(0.1) : (colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedSeverity == severity ? severityColor(severity).opacity(0.5) : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(16)
    }

    private func severityColor(_ severity: ReactionSeverity) -> Color {
        switch severity {
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        }
    }

    private func severityLabel(_ severity: ReactionSeverity) -> String {
        switch severity {
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        }
    }

    // MARK: - Date & Time Section

    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "When did it happen?", icon: "clock.fill", color: .blue)

            DatePicker("", selection: $reactionDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                .cornerRadius(12)
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Food Connection Section

    private var foodConnectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                sectionHeader(title: "Suspected foods", icon: "fork.knife", color: .green)
                Spacer()
                if selectedFoods.isEmpty {
                    Text("Required")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                } else {
                    Text("\(selectedFoods.count) added")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(6)
                }
            }

            // Food source picker - 4 compact buttons
            HStack(spacing: 6) {
                ForEach(FoodSource.allCases, id: \.self) { source in
                    Button(action: {
                        foodSource = source
                        // Reset temporary state when switching modes
                        tempSelectedFoodId = nil
                        tempManualFoodName = ""
                        editableIngredients = []
                        inferredIngredients = []
                        databaseSearchText = ""
                        databaseSearchResults = []
                        if source == .diary {
                            loadRecentMeals()
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: source.icon)
                                .font(.system(size: 16))
                            Text(source.rawValue)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(foodSource == source ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            foodSource == source ?
                            Color.blue : (colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                        )
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Selected foods list
            if !selectedFoods.isEmpty {
                selectedFoodsSection
            }

            // Food selection content based on mode
            foodSelectionContent

            // Info text
            Text("Add all foods you think might be related to this reaction.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Selected Foods Section
    private var selectedFoodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Added foods:")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)

            VStack(spacing: 10) {
                ForEach(selectedFoods) { food in
                    selectedFoodCard(food)
                }
            }
        }
    }

    private func selectedFoodCard(_ food: SelectedFood) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Food name header with remove button
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: food.source.icon)
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                    Text(food.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedFoods.removeAll { $0.id == food.id }
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
            }

            // Ingredients list
            if !food.ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ingredients:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    FlowLayout(spacing: 4) {
                        ForEach(food.ingredients.prefix(10), id: \.self) { ingredient in
                            Text(ingredient)
                                .font(.system(size: 11))
                                .foregroundColor(.primary.opacity(0.8))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                                .cornerRadius(4)
                        }
                        if food.ingredients.count > 10 {
                            Text("+\(food.ingredients.count - 10) more")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                        }
                    }
                }
            } else {
                Text("No ingredients listed")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.7))
                    .italic()
            }
        }
        .padding(12)
        .background(Color.green.opacity(0.08))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var foodSelectionContent: some View {
        switch foodSource {
        case .diary:
            // Diary meal selection
            diaryFoodContent

        case .database:
            // Search database for foods
            databaseSearchContent

        case .ai:
            // AI estimate ingredients
            aiEstimateContent

        case .manual:
            // Manual entry with ingredients
            manualEntryContent
        }
    }

    // MARK: - Diary Food Content
    @ViewBuilder
    private var diaryFoodContent: some View {
        if isLoadingMeals {
            HStack(spacing: 10) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Loading recent meals...")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
            .cornerRadius(12)
        } else if recentMeals.isEmpty {
            Text("No meals found in your diary")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                .cornerRadius(12)
        } else {
            VStack(spacing: 12) {
                Button(action: { showMealSelection = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                        Text("Add from recent meals")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.blue)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(14)
                    .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Database Search Content
    private var databaseSearchContent: some View {
        VStack(spacing: 12) {
            // Inline search field
            HStack(spacing: 10) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search foods...", text: $databaseSearchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .focused($isDatabaseSearchFocused)
                        .onChange(of: databaseSearchText) { _, newValue in
                            // Debounce search to avoid excessive API calls
                            searchDebouncer.debounce {
                                await performDatabaseSearch(query: newValue)
                            }
                        }

                    if !databaseSearchText.isEmpty {
                        Button(action: {
                            databaseSearchText = ""
                            databaseSearchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(14)
                .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                .cornerRadius(12)

                // Barcode scan button
                Button(action: {
                    showingBarcodeScanner = true
                }) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(width: 48, height: 48)
                        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                        .cornerRadius(12)
                }
            }

            // Search results dropdown
            if isDatabaseSearching {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Searching...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            } else if !databaseSearchResults.isEmpty {
                VStack(spacing: 8) {
                    ForEach(databaseSearchResults.prefix(5), id: \.id) { food in
                        Button(action: {
                            selectDatabaseFood(food)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(food.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)

                                    if let brand = food.brand, !brand.isEmpty {
                                        Text(brand)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }

                                    if let ingredients = food.ingredients, !ingredients.isEmpty {
                                        let displayText = ingredients.prefix(3).joined(separator: ", ")
                                        Text(displayText + (ingredients.count > 3 ? "..." : ""))
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary.opacity(0.8))
                                            .lineLimit(1)
                                    }
                                }

                                Spacer()

                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                            }
                            .padding(12)
                            .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }

                    if databaseSearchResults.count > 5 {
                        Text("\(databaseSearchResults.count - 5) more results...")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                    }
                }
            } else if !databaseSearchText.isEmpty && databaseSearchText.count >= 2 {
                // No results message
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No foods found")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text("Try different keywords")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }

        }
    }

    // MARK: - Database Search Helpers

    private func performDatabaseSearch(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count >= 2 else {
            await MainActor.run {
                databaseSearchResults = []
                isDatabaseSearching = false
            }
            return
        }

        await MainActor.run {
            isDatabaseSearching = true
        }

        do {
            let results = try await FirebaseManager.shared.searchFoods(query: trimmed)
            await MainActor.run {
                databaseSearchResults = results
                isDatabaseSearching = false
            }
        } catch {
            await MainActor.run {
                databaseSearchResults = []
                isDatabaseSearching = false
            }
            print("Database search error: \(error)")
        }
    }

    private func selectDatabaseFood(_ food: FoodSearchResult) {
        // Parse ingredients from the selected food
        var ingredients: [String] = []
        if let foodIngredients = food.ingredients, !foodIngredients.isEmpty {
            // Check if ingredients came as a single comma-separated string
            if foodIngredients.count == 1, let first = foodIngredients.first, first.contains(",") {
                ingredients = first.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            } else {
                ingredients = foodIngredients
            }
        }

        // Add to selected foods list
        let newFood = SelectedFood(
            name: food.name,
            source: .database,
            ingredients: ingredients,
            diaryEntryId: nil,
            searchResult: food
        )

        withAnimation(.easeInOut(duration: 0.2)) {
            selectedFoods.append(newFood)
        }

        // Clear search state
        databaseSearchText = ""
        databaseSearchResults = []
        isDatabaseSearchFocused = false
    }

    // MARK: - AI Estimate Content
    private var aiEstimateContent: some View {
        VStack(spacing: 12) {
            TextField("Food name (e.g., chippy sausage, doner kebab)", text: $tempManualFoodName)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.words)
                .padding(14)
                .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                .cornerRadius(12)

            if !tempManualFoodName.isEmpty {
                Button(action: { showingInferredIngredientsSheet = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                        Text("Estimate Ingredients with AI")
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                        if !inferredIngredients.isEmpty {
                            Text("\(inferredIngredients.count) found")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white)
                    .padding(14)
                    .background(
                        LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)

                // Show inferred ingredients as editable chips after AI estimation
                if !inferredIngredients.isEmpty {
                    ingredientsEditorSection

                    // Add food button
                    addFoodButton(source: .ai)
                } else {
                    Text("AI estimates likely ingredients for generic foods like takeaways")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Manual Entry Content
    private var manualEntryContent: some View {
        VStack(spacing: 12) {
            TextField("Food name", text: $tempManualFoodName)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.words)
                .padding(14)
                .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                .cornerRadius(12)

            // Always show ingredients editor for manual entry
            if !tempManualFoodName.isEmpty {
                ingredientsEditorSection

                // Add food button
                addFoodButton(source: .manual)
            }
        }
    }

    // MARK: - Add Food Button
    private func addFoodButton(source: FoodSource) -> some View {
        Button(action: {
            addCurrentFoodToList(source: source)
        }) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                Text("Add to suspected foods")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .disabled(tempManualFoodName.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    private func addCurrentFoodToList(source: FoodSource) {
        let name = tempManualFoodName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let ingredients = source == .ai ? inferredIngredients.map { $0.name } : editableIngredients

        let newFood = SelectedFood(
            name: name,
            source: source,
            ingredients: ingredients,
            diaryEntryId: nil,
            searchResult: nil
        )

        withAnimation(.easeInOut(duration: 0.2)) {
            selectedFoods.append(newFood)
        }

        // Clear temporary state
        tempManualFoodName = ""
        editableIngredients = []
        inferredIngredients = []
    }

    // MARK: - Ingredients Editor Section

    private var ingredientsEditorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 14))
                Text("Ingredients")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Text("\(editableIngredients.count)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            // Display existing ingredients as chips
            if !editableIngredients.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(editableIngredients, id: \.self) { ingredient in
                        ingredientChip(ingredient)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Add new ingredient field
            HStack(spacing: 8) {
                TextField("Add ingredient...", text: $newIngredientText)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.words)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5).opacity(0.5))
                    .cornerRadius(8)
                    .onSubmit {
                        addNewIngredient()
                    }

                Button(action: addNewIngredient) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
                .disabled(newIngredientText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(12)
        .background(colorScheme == .dark ? Color(.systemGray5).opacity(0.5) : Color(.systemGray6).opacity(0.5))
        .cornerRadius(10)
    }

    private func ingredientChip(_ ingredient: String) -> some View {
        HStack(spacing: 4) {
            Text(ingredient)
                .font(.system(size: 13))
                .foregroundColor(.primary)
            Button(action: {
                withAnimation {
                    editableIngredients.removeAll { $0 == ingredient }
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(colorScheme == .dark ? Color(.systemGray4) : Color(.systemGray5))
        .cornerRadius(16)
    }

    private func addNewIngredient() {
        let trimmed = newIngredientText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        if !editableIngredients.contains(where: { $0.lowercased() == trimmed.lowercased() }) {
            withAnimation {
                editableIngredients.append(trimmed)
            }
        }
        newIngredientText = ""
    }

    // MARK: - Analysis Window Section

    private var analysisWindowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Analysis period", icon: "calendar", color: .purple)

            Picker("", selection: $dayRange) {
                ForEach(ReactionLogView.DayRange.allCases, id: \.self) { range in
                    Text(range.displayText).tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Notes (optional)", icon: "note.text", color: .gray)

            TextEditor(text: $notes)
                .frame(height: 80)
                .padding(10)
                .scrollContentBackground(.hidden)
                .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                .cornerRadius(12)
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        VStack(spacing: 8) {
            // Show validation hints if not valid
            if !isValid && !isSaving {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.orange)
                    Text(validationHint)
                        .font(.system(size: 13))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            Button(action: {
                Task { await saveReaction() }
            }) {
                HStack(spacing: 10) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                    }
                    Text(isSaving ? "Saving..." : "Log Reaction")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: isValid ? [Color(red: 0.3, green: 0.5, blue: 1.0), Color(red: 0.5, green: 0.3, blue: 0.9)] : [.gray.opacity(0.6), .gray.opacity(0.4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: isValid ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
            }
            .disabled(isSaving || !isValid)
        }
        .padding(.top, 8)
    }

    private var validationHint: String {
        if selectedTypes.isEmpty {
            return "Select at least one reaction type"
        }
        if selectedTypes.contains(.custom) && selectedTypes.count == 1 && customType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Describe your custom reaction"
        }
        if selectedFoods.isEmpty {
            return "Add at least one suspected food"
        }
        return ""
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
        }
    }

    private var cardBackground: some View {
        colorScheme == .dark ? Color(.systemGray6).opacity(0.5) : Color.white
    }

    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))

                Text("Saving reaction...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)

                Text("Analyzing your food history")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(40)
            .background(Color(.systemGray6).opacity(0.95))
            .cornerRadius(20)
            .shadow(radius: 20)
        }
    }

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 100, height: 100)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                }

                Text("Reaction Logged")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)

                Text("\(selectedFoods.count) food\(selectedFoods.count == 1 ? "" : "s") recorded")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 50)
            .padding(.vertical, 40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
        }
        .transition(.opacity)
    }

    private var mealSelectionSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header showing count of added foods
                if !selectedFoods.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(selectedFoods.count) food\(selectedFoods.count == 1 ? "" : "s") added")
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.green.opacity(0.1))
                }

                List {
                    Section(header: Text("Tap to add meals from the past 7 days")) {
                        if recentMeals.isEmpty {
                            Text("No meals found in your diary")
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(recentMeals) { meal in
                                mealSelectionRow(meal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Meals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showMealSelection = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func mealSelectionRow(_ meal: FoodEntry) -> some View {
        let isAlreadyAdded = selectedFoods.contains { $0.diaryEntryId == meal.id }

        // Get ingredients preview
        let ingredientsPreview: String = {
            if let ingredients = meal.ingredients, !ingredients.isEmpty {
                if ingredients.count == 1, let first = ingredients.first, first.contains(",") {
                    let parsed = first.components(separatedBy: ",").prefix(3).map { $0.trimmingCharacters(in: .whitespaces) }
                    return parsed.joined(separator: ", ")
                } else {
                    return ingredients.prefix(3).joined(separator: ", ")
                }
            } else if let inferred = meal.inferredIngredients, !inferred.isEmpty {
                return inferred.prefix(3).map { $0.name }.joined(separator: ", ")
            }
            return ""
        }()

        return Button(action: {
            if !isAlreadyAdded {
                addDiaryMealToList(meal)
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.foodName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isAlreadyAdded ? .secondary : .primary)

                    HStack(spacing: 4) {
                        Text(meal.date, style: .date)
                        Text("•")
                        Text(meal.date, style: .time)
                    }
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                    if !ingredientsPreview.isEmpty {
                        Text(ingredientsPreview + "...")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                Spacer()
                if isAlreadyAdded {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Added")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    }
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isAlreadyAdded)
        .opacity(isAlreadyAdded ? 0.6 : 1.0)
    }

    private func addDiaryMealToList(_ meal: FoodEntry) {
        // Get ingredients from the meal
        var ingredients: [String] = []
        if let mealIngredients = meal.ingredients, !mealIngredients.isEmpty {
            if mealIngredients.count == 1, let first = mealIngredients.first, first.contains(",") {
                ingredients = first.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            } else {
                ingredients = mealIngredients
            }
        } else if let inferred = meal.inferredIngredients, !inferred.isEmpty {
            ingredients = inferred.map { $0.name }
        }

        let newFood = SelectedFood(
            name: meal.foodName,
            source: .diary,
            ingredients: ingredients,
            diaryEntryId: meal.id,
            searchResult: nil
        )

        withAnimation(.easeInOut(duration: 0.2)) {
            selectedFoods.append(newFood)
        }
    }

    private func loadRecentMeals() {
        isLoadingMeals = true
        Task {
            let endDate = reactionDate
            let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate

            do {
                let meals = try await DiaryDataManager.shared.getMealsInTimeRange(from: startDate, to: endDate)
                await MainActor.run {
                    self.recentMeals = meals.sorted { $0.date > $1.date }
                    self.isLoadingMeals = false
                }
            } catch {
                await MainActor.run {
                    self.recentMeals = []
                    self.isLoadingMeals = false
                }
            }
        }
    }

    private var isValid: Bool {
        // Must have at least one symptom selected
        guard !selectedTypes.isEmpty else { return false }

        // Must have at least one food selected
        guard !selectedFoods.isEmpty else { return false }

        // If "Other" is selected, must have custom text
        if selectedTypes.contains(.custom) {
            // If ONLY custom is selected, require custom text
            if selectedTypes.count == 1 {
                return !customType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            // If custom is selected along with others, custom text is optional
        }
        return true
    }

    private func saveReaction() async {
        isSaving = true

        print("🔵 [LogReactionSheet] saveReaction started")
        print("🔵 [LogReactionSheet] Manager reactionLogs count BEFORE: \(manager.reactionLogs.count)")
        print("🔵 [LogReactionSheet] Selected foods count: \(selectedFoods.count)")

        do {
            // Build array of selected symptom types
            var symptomStrings: [String] = selectedTypes.filter { $0 != .custom }.map { $0.rawValue }
            if selectedTypes.contains(.custom) && !customType.isEmpty {
                symptomStrings.append(customType)
            }

            // Use first symptom as primary reaction type for backward compatibility
            let reactionType = symptomStrings.first ?? "Unknown"
            let notesText = notes.trimmingCharacters(in: .whitespacesAndNewlines)

            print("🔵 [LogReactionSheet] Reaction type: \(reactionType)")
            print("🔵 [LogReactionSheet] Reaction date: \(reactionDate)")

            // Combine all food names
            let foodNames = selectedFoods.map { $0.name }
            let combinedFoodName = foodNames.joined(separator: ", ")

            // Combine all ingredients from selected foods
            let allIngredients = selectedFoods.flatMap { $0.ingredients }
            let uniqueIngredients = Array(Set(allIngredients))

            print("🔵 [LogReactionSheet] Foods: \(combinedFoodName)")
            print("🔵 [LogReactionSheet] Ingredients count: \(uniqueIngredients.count)")

            print("🔵 [LogReactionSheet] Calling manager.saveReactionLog...")
            let savedEntry = try await manager.saveReactionLog(
                reactionType: reactionType,
                reactionDate: reactionDate,
                notes: notesText.isEmpty ? nil : notesText,
                dayRange: dayRange.rawValue
            )

            print("✅ [LogReactionSheet] Save successful! Entry ID: \(savedEntry.id ?? "no-id")")
            print("✅ [LogReactionSheet] Manager reactionLogs count AFTER: \(manager.reactionLogs.count)")

            // Also update the FoodReactionsView's ReactionManager so Health tab shows the reaction
            // Create a FoodReaction from the saved entry data with ALL selected symptoms
            let foodReaction = FoodReaction(
                foodName: combinedFoodName,
                foodId: nil,
                foodBrand: nil,
                timestamp: FirebaseFirestore.Timestamp(date: reactionDate),
                severity: selectedSeverity,
                symptoms: symptomStrings,
                suspectedIngredients: uniqueIngredients,
                notes: notesText.isEmpty ? nil : notesText
            )
            await ReactionManager.shared.addReaction(foodReaction)
            print("✅ [LogReactionSheet] Also added to ReactionManager for Health tab with \(symptomStrings.count) symptoms")

            // Show success state before dismissing
            await MainActor.run {
                isSaving = false
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSuccess = true
                }
            }

            // Wait a moment so user sees the success confirmation
            try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds

            // Dismiss
            await MainActor.run {
                dismiss()
            }
        } catch {
            print("❌ [LogReactionSheet] Save FAILED: \(error.localizedDescription)")
            await MainActor.run {
                isSaving = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    // Populate editable ingredients from AI inference
    private func populateIngredientsFromAI() {
        guard !inferredIngredients.isEmpty else { return }
        editableIngredients = inferredIngredients.map { $0.name }
    }
}

// MARK: - Reaction Detail View

struct ReactionLogDetailView: View {
    let entry: ReactionLogEntry
    let selectedDayRange: ReactionLogView.DayRange

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingExportSheet = false
    @State private var showOtherIngredients = false
    @State private var selectedFood: WeightedFoodScore?
    @State private var selectedIngredient: WeightedIngredientScore?
    @State private var selectedAllergenCategory: String?
    @State private var userAllergens: Set<Allergen> = []
    @State private var isLoadingAllergens = true

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    reactionHeader

                    if let analysis = entry.triggerAnalysis {
                        // Analysis Summary
                        analysisOverview(analysis: analysis)

                        // Top Trigger Foods
                        if !analysis.topFoods.isEmpty {
                            topFoodsSection(foods: analysis.topFoods)
                        }

                        // Top Trigger Ingredients
                        if !analysis.topIngredients.isEmpty {
                            topIngredientsSection(ingredients: analysis.topIngredients)
                        }
                    } else {
                        Text("No analysis available")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Reaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingExportSheet = true }) {
                        Label("Export PDF", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .fullScreenCover(isPresented: $showingExportSheet) {
                PDFExportSheet(entry: entry)
            }
            .fullScreenCover(item: $selectedFood) { food in
                FoodHistoryDetailView(food: food, reactionDate: entry.reactionDate)
            }
            .fullScreenCover(item: $selectedIngredient) { ingredient in
                IngredientHistoryDetailView(ingredient: ingredient, reactionDate: entry.reactionDate)
            }
            .fullScreenCover(item: $selectedAllergenCategory) { category in
                AllergenCategoryDetailView(category: category, entry: entry)
            }
            .task {
                await loadUserAllergens()
            }
        }
    }

    // MARK: - Load User Allergens

    private func loadUserAllergens() async {
        do {
            let settings = try await FirebaseManager.shared.getUserSettings()
            await MainActor.run {
                userAllergens = Set(settings.allergens ?? [])
                isLoadingAllergens = false
            }
        } catch {
            await MainActor.run {
                isLoadingAllergens = false
            }
        }
    }

    /// Check if an allergen category matches user's saved allergens
    private func isUserAllergen(_ category: String) -> Bool {
        let categoryLower = category.lowercased()

        for allergen in userAllergens {
            switch allergen {
            case .dairy, .lactose:
                if categoryLower == "milk" || categoryLower == "dairy" || categoryLower == "lactose" {
                    return true
                }
            case .eggs:
                if categoryLower == "eggs" { return true }
            case .fish:
                if categoryLower == "fish" { return true }
            case .shellfish:
                if categoryLower == "shellfish" { return true }
            case .treeNuts:
                if categoryLower == "tree nuts" { return true }
            case .peanuts:
                if categoryLower == "peanuts" { return true }
            case .wheat, .gluten:
                if categoryLower == "gluten" || categoryLower == "wheat" { return true }
            case .soy:
                if categoryLower == "soya" || categoryLower == "soy" { return true }
            case .sesame:
                if categoryLower == "sesame" { return true }
            case .sulfites:
                if categoryLower == "sulphites" || categoryLower == "sulfites" { return true }
            case .msg:
                if categoryLower == "msg" { return true }
            case .corn:
                if categoryLower == "corn" { return true }
            }
        }
        return false
    }

    private var reactionHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: reactionIcon)
                    .font(.title)
                    .foregroundColor(.orange)

                Text(entry.reactionType)
                    .font(.title2)
                    .fontWeight(.bold)
            }

            HStack(spacing: 16) {
                Label(entry.reactionDate.formatted(date: .long, time: .omitted), systemImage: "calendar")
                Label(entry.reactionDate.formatted(date: .omitted, time: .shortened), systemImage: "clock")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            if let notes = entry.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .padding(.top, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func analysisOverview(analysis: TriggerAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis Summary")
                .font(.headline)

            HStack(spacing: 20) {
                StatBox(value: "\(analysis.mealCount)", label: "Meals Analyzed", icon: "fork.knife")
                StatBox(value: "\(analysis.totalFoodsAnalyzed)", label: "Foods Reviewed", icon: "list.bullet")
            }

            Text("\(analysis.dayRange)-Day Window")
                .font(.caption)
                .foregroundColor(.secondary)
            +
            Text(" • ")
                .font(.caption)
                .foregroundColor(.secondary)
            +
            Text("\(analysis.timeRangeStart.formatted(date: .abbreviated, time: .shortened)) to \(analysis.timeRangeEnd.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorScheme == .dark ? Color.midnightCard : Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private func topFoodsSection(foods: [WeightedFoodScore]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Foods Appearing Alongside Reactions")
                .font(.headline)

            Text("These foods were consumed in the days before this reaction. Patterns may help you identify connections.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)

            ForEach(foods.prefix(10)) { food in
                Button(action: {
                    selectedFood = food
                }) {
                    FoodScoreRow(score: food)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorScheme == .dark ? Color.midnightCard : Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private func topIngredientsSection(ingredients: [WeightedIngredientScore]) -> some View {
        let ingredientData = categorizeIngredients(ingredients)

        return VStack(alignment: .leading, spacing: 20) {
            // Recognised Allergens Section
            if !ingredientData.allergenGroups.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Recognised Allergens")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.bottom, 20)

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(ingredientData.allergenGroups, id: \.category) { group in
                            ReactionAllergenGroup(
                                allergenCategory: group.category,
                                categoryScore: group.maxScore,
                                ingredients: group.ingredients,
                                isUserAllergen: isUserAllergen(group.category),
                                onIngredientTap: { ingredient in
                                    selectedIngredient = ingredient
                                },
                                onCategoryTap: {
                                    selectedAllergenCategory = group.category
                                }
                            )
                        }
                    }
                }
                .padding()
                .background(colorScheme == .dark ? Color.midnightCard : Color(.secondarySystemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
            }

            // Other Ingredients Section (Expandable)
            if !ingredientData.otherIngredients.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showOtherIngredients.toggle()
                        }
                    }) {
                        HStack(alignment: .center, spacing: 12) {
                            Text("Other Ingredients")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: showOtherIngredients ? "chevron.up" : "chevron.down")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 20)
                    }
                    .buttonStyle(.plain)

                    if showOtherIngredients {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(ingredientData.otherIngredients) { ingredient in
                                Button(action: {
                                    selectedIngredient = ingredient
                                }) {
                                    IngredientScoreRow(score: ingredient)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
                .background(colorScheme == .dark ? Color.midnightCard : Color(.secondarySystemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
            }
        }
    }

    private func categorizeIngredients(_ ingredients: [WeightedIngredientScore]) -> (allergenGroups: [(category: String, maxScore: Int, ingredients: [WeightedIngredientScore])], otherIngredients: [WeightedIngredientScore]) {
        var allergenDict: [String: [WeightedIngredientScore]] = [:]
        var otherIngredients: [WeightedIngredientScore] = []

        for ingredient in ingredients.prefix(10) {
            if let allergenCategory = getBaseAllergen(for: ingredient.ingredientName) {
                allergenDict[allergenCategory, default: []].append(ingredient)
            } else {
                otherIngredients.append(ingredient)
            }
        }

        let allergenGroups = allergenDict.map { (category, ingredients) -> (category: String, maxScore: Int, ingredients: [WeightedIngredientScore]) in
            // Use maximum cross-reaction frequency for the category
            let maxScore = ingredients.map { Int($0.crossReactionFrequency) }.max() ?? 0
            return (category, maxScore, ingredients.sorted { $0.crossReactionFrequency > $1.crossReactionFrequency })
        }.sorted { $0.maxScore > $1.maxScore }

        return (allergenGroups, otherIngredients.sorted { $0.totalScore > $1.totalScore })
    }

    private func getBaseAllergen(for ingredient: String) -> String? {
        let lower = ingredient.lowercased()

        // Milk and dairy (uses comprehensive cheese/dairy detection)
        if AllergenDetector.shared.containsDairyMilk(in: lower) {
            return "Milk"
        }

        // Eggs (comprehensive)
        let eggKeywords = ["egg", "albumin", "mayonnaise", "meringue", "ovalbumin", "lecithin", "lysozyme",
                           "quiche", "frittata", "omelette", "omelet", "brioche", "challah", "hollandaise",
                           "béarnaise", "bearnaise", "aioli", "carbonara", "pavlova", "soufflé", "souffle",
                           "custard", "eggnog", "scotch egg"]
        if eggKeywords.contains(where: { lower.contains($0) }) {
            return "Eggs"
        }

        // Peanuts
        let peanutKeywords = ["peanut", "groundnut", "arachis", "peanut butter", "peanut oil", "satay", "monkey nuts"]
        if peanutKeywords.contains(where: { lower.contains($0) }) {
            return "Peanuts"
        }

        // Tree nuts (comprehensive)
        let treeNutKeywords = ["almond", "hazelnut", "walnut", "cashew", "pistachio", "pecan", "filbert",
                               "brazil nut", "macadamia", "pine nut", "chestnut", "praline", "gianduja",
                               "marzipan", "frangipane", "nougat", "nutella", "nut butter", "almond flour",
                               "ground almonds", "flaked almonds", "walnut oil", "hazelnut oil"]
        if treeNutKeywords.contains(where: { lower.contains($0) }) {
            return "Tree Nuts"
        }

        // Gluten (comprehensive)
        let glutenKeywords = ["wheat", "gluten", "barley", "rye", "oats", "spelt", "kamut", "einkorn",
                              "triticale", "durum", "farro", "freekeh", "seitan", "malt", "brewer's yeast",
                              "semolina", "bulgur", "couscous", "flour", "bread", "pasta", "beer", "lager", "ale", "stout"]
        if glutenKeywords.contains(where: { lower.contains($0) }) {
            return "Gluten"
        }

        // Soya (comprehensive)
        let soyKeywords = ["soy", "soya", "soybean", "tofu", "tempeh", "miso", "shoyu", "tamari",
                           "edamame", "soy sauce", "soy milk", "soy protein", "soy lecithin", "natto", "tvp"]
        if soyKeywords.contains(where: { lower.contains($0) }) {
            return "Soya"
        }

        // Fish (comprehensive)
        let fishKeywords = ["fish", "fish sauce", "worcestershire", "fish finger", "fish cake", "fish pie",
                            "salmon", "tuna", "cod", "bass", "trout", "anchovy", "sardine", "mackerel",
                            "haddock", "plaice", "pollock", "hake", "monkfish", "halibut", "tilapia",
                            "bream", "sole", "herring", "kipper", "whitebait", "pilchard", "sprat",
                            "swordfish", "snapper", "grouper", "perch", "catfish", "carp", "pike", "eel"]
        if fishKeywords.contains(where: { lower.contains($0) }) {
            return "Fish"
        }

        // Shellfish (crustaceans and molluscs combined)
        let shellfishKeywords = ["shellfish", "shrimp", "prawn", "crab", "lobster", "crawfish", "crayfish", "langoustine",
                                 "king prawn", "tiger prawn", "crab stick", "mollusc", "clam", "mussel", "oyster",
                                 "scallop", "cockle", "winkle", "whelk", "squid", "calamari", "octopus",
                                 "cuttlefish", "abalone", "snail", "escargot"]
        if shellfishKeywords.contains(where: { lower.contains($0) }) {
            return "Shellfish"
        }

        // Sesame (comprehensive)
        let sesameKeywords = ["sesame", "tahini", "sesame oil", "sesame seed", "hummus", "houmous",
                              "halvah", "halva", "za'atar", "zaatar", "gomashio", "benne seed"]
        if sesameKeywords.contains(where: { lower.contains($0) }) {
            return "Sesame"
        }

        // Celery
        let celeryKeywords = ["celery", "celeriac", "celery salt", "celery extract"]
        if celeryKeywords.contains(where: { lower.contains($0) }) {
            return "Celery"
        }

        // Mustard
        let mustardKeywords = ["mustard", "mustard seed", "dijon", "wholegrain mustard"]
        if mustardKeywords.contains(where: { lower.contains($0) }) {
            return "Mustard"
        }

        // Lupin
        let lupinKeywords = ["lupin", "lupine", "lupin flour"]
        if lupinKeywords.contains(where: { lower.contains($0) }) {
            return "Lupin"
        }

        // Sulphites (comprehensive)
        let sulphiteKeywords = ["sulphite", "sulfite", "sulphur dioxide", "sulfur dioxide",
                                "e220", "e221", "e222", "e223", "e224", "e225", "e226", "e227", "e228",
                                "metabisulphite", "metabisulfite"]
        if sulphiteKeywords.contains(where: { lower.contains($0) }) {
            return "Sulphites"
        }

        return nil
    }

    private var reactionIcon: String {
        if let type = ReactionType(rawValue: entry.reactionType) {
            return type.icon
        }
        return "exclamationmark.circle"
    }
}

// MARK: - Helper Views

struct StatBox: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct FoodScoreRow: View {
    let score: WeightedFoodScore

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Frequency indicator (only show if we have cross-reaction data)
            if score.crossReactionFrequency > 0 {
                Circle()
                    .fill(frequencyColor)
                    .frame(width: 10, height: 10)
                    .padding(.top, 6)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(score.foodName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    Label("\(score.occurrences)×", systemImage: "repeat")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if score.occurrencesWithin24h > 0 {
                        Text("\(score.occurrencesWithin24h)× <24h")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Text("Last seen \(Int(score.lastSeenHoursBeforeReaction))h before reaction")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Only show cross-reaction percentage if there are 2+ reactions (crossReactionFrequency > 0)
            if score.crossReactionFrequency > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(score.crossReactionFrequency))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(frequencyColor)
                    Text("of reactions")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var frequencyColor: Color {
        let percentage = Int(score.crossReactionFrequency)
        if percentage >= 80 {
            return .red
        } else if percentage >= 40 {
            return .orange
        } else {
            return .yellow
        }
    }
}

struct IngredientScoreRow: View {
    let score: WeightedIngredientScore

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Frequency indicator (only show if we have cross-reaction data)
            if score.crossReactionFrequency > 0 {
                Circle()
                    .fill(frequencyColor)
                    .frame(width: 10, height: 10)
                    .padding(.top, 6)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(score.ingredientName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    Label("\(score.occurrences)×", systemImage: "repeat")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if score.symptomAssociationScore > 0 {
                        Label("Pattern detected", systemImage: "waveform.path.ecg")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Text("Found in: \(score.contributingFoodNames.prefix(3).joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Only show cross-reaction percentage if there are 2+ reactions (crossReactionFrequency > 0)
            if score.crossReactionFrequency > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(score.crossReactionFrequency))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(frequencyColor)
                    Text("of reactions")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var frequencyColor: Color {
        let percentage = Int(score.crossReactionFrequency)
        if percentage >= 80 {
            return .red
        } else if percentage >= 40 {
            return .orange
        } else {
            return .yellow
        }
    }
}

// MARK: - Reaction Allergen Group Component

struct ReactionAllergenGroup: View {
    let allergenCategory: String
    let categoryScore: Int
    let ingredients: [WeightedIngredientScore]
    var isUserAllergen: Bool = false
    let onIngredientTap: (WeightedIngredientScore) -> Void
    let onCategoryTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Category header with score badge - clickable
            Button(action: {
                onCategoryTap()
            }) {
                HStack(alignment: .center, spacing: 12) {
                    // User allergen warning badge
                    if isUserAllergen {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Text("YOUR ALLERGEN")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            LinearGradient(
                                colors: [Color.red, Color.orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                        .shadow(color: .red.opacity(0.4), radius: 4, x: 0, y: 2)
                    }

                    Text(allergenCategory)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(isUserAllergen ? .red : .primary)

                    Spacer()

                    // Frequency badge (only show if there's cross-reaction data)
                    if categoryScore > 0 {
                        VStack(spacing: 2) {
                            Text("\(categoryScore)%")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.red, Color.red.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            Text("of reactions")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.red.opacity(0.7))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.red.opacity(0.12))
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
                            }
                        )
                        .shadow(color: Color.red.opacity(0.15), radius: 3, x: 0, y: 2)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.bottom, 14)

            // Ingredient list
            VStack(alignment: .leading, spacing: 10) {
                ForEach(ingredients) { ingredient in
                    Button(action: {
                        onIngredientTap(ingredient)
                    }) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 4, height: 4)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(ingredient.ingredientName)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)

                                HStack(spacing: 12) {
                                    Label("\(ingredient.occurrences)×", systemImage: "repeat")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    if ingredient.symptomAssociationScore > 0 {
                                        Label("Pattern detected", systemImage: "waveform.path.ecg")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }

                                Text("Found in: \(ingredient.contributingFoodNames.prefix(3).joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text("\(Int(ingredient.totalScore))")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(scoreColor(for: ingredient.totalScore))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.bottom, 28)
    }

    private func scoreColor(for score: Double) -> Color {
        if score >= 100 {
            return .red
        } else if score >= 50 {
            return .orange
        } else {
            return .yellow
        }
    }
}

// MARK: - PDF Export Sheet

struct PDFExportSheet: View {
    let entry: ReactionLogEntry
    @Environment(\.dismiss) private var dismiss
    @State private var isGenerating = false
    @State private var pdfURL: URL?
    @State private var showShareSheet = false
    @State private var errorMessage: String?
    @State private var selectedDayRange: Int = 7

    let dayRangeOptions = [3, 7, 14, 30]

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if isGenerating {
                    ProgressView("Generating PDF...")
                        .font(.headline)
                        .padding()
                } else if let error = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)

                        Text("Export Failed")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("Try Again") {
                            errorMessage = nil
                            generatePDF()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Close") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                } else if pdfURL != nil {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)

                        Text("PDF Ready")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Your observation report has been generated and is ready to share with your nutritionist or healthcare provider.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: {
                            showShareSheet = true
                        }) {
                            Label("Share Report", systemImage: "square.and.arrow.up")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()

                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)

                            Text("Export Observation Report")
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text("Create a detailed PDF report of your food patterns and reactions to share with your nutritionist or healthcare provider.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            // Date Range Selector
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Select Time Period")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                HStack(spacing: 12) {
                                    ForEach(dayRangeOptions, id: \.self) { days in
                                        Button(action: {
                                            selectedDayRange = days
                                        }) {
                                            VStack(spacing: 4) {
                                                Text("\(days)")
                                                    .font(.title3)
                                                    .fontWeight(.bold)
                                                Text("days")
                                                    .font(.caption2)
                                            }
                                            .foregroundColor(selectedDayRange == days ? .white : .blue)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                selectedDayRange == days ?
                                                    LinearGradient(
                                                        colors: [
                                                            Color(red: 0.3, green: 0.5, blue: 1.0),
                                                            Color(red: 0.5, green: 0.3, blue: 0.9)
                                                        ],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                    : LinearGradient(
                                                        colors: [Color.blue.opacity(0.1)],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                            )
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(selectedDayRange == days ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }

                                Text("Report will include all reactions and food patterns from the last \(selectedDayRange) days")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Report Includes")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                VStack(alignment: .leading, spacing: 10) {
                                    Label("Reaction details and timeline", systemImage: "info.circle")
                                    Label("Foods appearing alongside reactions", systemImage: "fork.knife")
                                    Label("Ingredient frequency patterns", systemImage: "chart.bar")
                                    Label("Common allergen observations", systemImage: "list.bullet")
                                    Label("Meal timing context", systemImage: "clock")
                                    Label("7-day meal history with ingredients", systemImage: "calendar.badge.clock")
                                }
                                .font(.callout)
                                .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                            Text("This report is for informational purposes only and represents your personal food observations. Please share with a qualified healthcare provider or nutritionist for professional guidance.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            Button(action: {
                                generatePDF()
                            }) {
                                Label("Generate PDF Report", systemImage: "doc.badge.plus")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.horizontal)

                            Button("Cancel") {
                                dismiss()
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                    }
                }
            }
            .padding()
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showShareSheet) {
                if let url = pdfURL {
                    ShareSheet(items: [url])
                }
            }
        }
        .onDisappear {
            // Clean up temporary file when sheet is dismissed
            if let url = pdfURL {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    private func generatePDF() {
        isGenerating = true
        errorMessage = nil

        Task {
            do {
                // Calculate date range for meal history (7 days prior to reaction)
                let reactionDate = entry.reactionDate
                let startDate = reactionDate.addingTimeInterval(-7 * 24 * 3600)  // 7 days before

                // Fetch meals in the 7-day period
                var meals = try await DiaryDataManager.shared.getMealsInTimeRange(from: startDate, to: reactionDate)

                // Fetch food reactions in the same 7-day period
                let allFoodReactions = try await FirebaseManager.shared.getReactions()
                let reactionDates = allFoodReactions.filter { reaction in
                    let date = reaction.timestamp.dateValue()
                    return date >= startDate && date <= reactionDate
                }

                // Convert FoodReactions to FoodEntry format
                let reactionEntries = reactionDates.compactMap { reaction -> FoodEntry? in
                    guard let userId = FirebaseManager.shared.currentUser?.uid else { return nil }
                    let date = reaction.timestamp.dateValue()

                    return FoodEntry(
                        id: reaction.id.uuidString,
                        userId: userId,
                        foodName: reaction.foodName,
                        brandName: reaction.foodBrand,
                        servingSize: 100,
                        servingUnit: "g",
                        calories: 0,
                        protein: 0,
                        carbohydrates: 0,
                        fat: 0,
                        ingredients: reaction.suspectedIngredients,
                        mealType: .snacks,
                        date: date,
                        dateLogged: date
                    )
                }

                // Merge reaction entries with diary meals, deduplicating by food name + same day
                for reactionEntry in reactionEntries {
                    let calendar = Calendar.current
                    let reactionDay = calendar.startOfDay(for: reactionEntry.date)

                    // Check if this food (by name) is already in diary for the same day
                    let alreadyExists = meals.contains { meal in
                        let mealDay = calendar.startOfDay(for: meal.date)
                        return mealDay == reactionDay && meal.foodName.lowercased() == reactionEntry.foodName.lowercased()
                    }

                    // Only add if not already in diary
                    if !alreadyExists {
                        meals.append(reactionEntry)
                    }
                }

                // Sort meals by date
                meals.sort { $0.date < $1.date }

                // Get all reactions for cross-reaction analysis
                let allReactions = ReactionLogManager.shared.reactionLogs

                // Generate PDF on background thread
                let url = await Task.detached(priority: .userInitiated) {
                    return ReactionPDFExporter.exportReactionReport(entry: entry, mealHistory: meals, allReactions: allReactions)
                }.value

                if let url = url {
                    await MainActor.run {
                        self.pdfURL = url
                        self.isGenerating = false
                    }
                } else {
                    await MainActor.run {
                        self.errorMessage = "Failed to generate PDF. Please try again."
                        self.isGenerating = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to fetch meal history: \(error.localizedDescription)"
                    self.isGenerating = false
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - History Detail Views (Placeholders)

struct FoodHistoryDetailView: View {
    let food: WeightedFoodScore
    let reactionDate: Date
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var foodEntry: FoodEntry?
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(food.foodName)
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack(spacing: 16) {
                            Label("\(food.occurrences)× consumed", systemImage: "repeat")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Label("Last: \(Int(food.lastSeenHoursBeforeReaction))h before", systemImage: "clock")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        // Cross-reaction frequency
                        if food.crossReactionFrequency > 0 {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(frequencyColor)
                                    .frame(width: 10, height: 10)

                                Text("Appears in \(Int(food.crossReactionFrequency))% of reactions")
                                    .font(.caption)
                                    .foregroundColor(frequencyColor)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Ingredients Section
                    if isLoading {
                        ProgressView("Loading ingredients...")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else if let ingredients = foodEntry?.ingredients, !ingredients.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Ingredients")
                                .font(.headline)

                            ingredientsBreakdownView(ingredients: ingredients)
                        }
                        .padding()
                        .background(colorScheme == .dark ? Color.midnightCard : Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 3)
                    } else {
                        Text("No ingredient information available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    }

                    // Time Window Breakdown
                    timeWindowBreakdown
                }
                .padding()
            }
            .navigationTitle("Food Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadFoodEntry()
            }
        }
    }

    private var frequencyColor: Color {
        let percentage = Int(food.crossReactionFrequency)
        if percentage >= 80 {
            return .red
        } else if percentage >= 40 {
            return .orange
        } else {
            return .yellow
        }
    }

    private var timeWindowBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Window Breakdown")
                .font(.headline)

            VStack(spacing: 8) {
                TimeWindowRow(label: "Within 24 hours", count: food.occurrencesWithin24h, color: .red)
                TimeWindowRow(label: "24-48 hours before", count: food.occurrencesBetween24_48h, color: .orange)
                TimeWindowRow(label: "48-72 hours before", count: food.occurrencesBetween48_72h, color: .yellow)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color.midnightCard : Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3)
    }

    private func ingredientsBreakdownView(ingredients: [String]) -> some View {
        let categorized = categorizeIngredients(ingredients)

        return VStack(alignment: .leading, spacing: 20) {
            // Recognised Allergens
            if !categorized.allergenGroups.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recognised Allergens")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)

                    ForEach(categorized.allergenGroups, id: \.category) { group in
                        AllergenCategoryCard(category: group.category, ingredients: group.ingredients)
                    }
                }
            }

            // Other Ingredients
            if !categorized.otherIngredients.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Other Ingredients")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    ForEach(categorized.otherIngredients, id: \.self) { ingredient in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 4, height: 4)

                            Text(ingredient)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
    }

    private func categorizeIngredients(_ ingredients: [String]) -> (allergenGroups: [(category: String, ingredients: [String])], otherIngredients: [String]) {
        var allergenDict: [String: [String]] = [:]
        var otherIngredients: [String] = []

        for ingredient in ingredients {
            if let allergenCategory = getBaseAllergen(for: ingredient) {
                allergenDict[allergenCategory, default: []].append(ingredient)
            } else {
                otherIngredients.append(ingredient)
            }
        }

        let allergenGroups = allergenDict.map { (category: $0.key, ingredients: $0.value) }
            .sorted { $0.category < $1.category }

        return (allergenGroups, otherIngredients)
    }

    private func getBaseAllergen(for ingredient: String) -> String? {
        let lower = ingredient.lowercased()

        if lower.contains("milk") || lower.contains("dairy") || lower.contains("cream") ||
           lower.contains("cheese") || lower.contains("butter") || lower.contains("yogurt") ||
           lower.contains("whey") || lower.contains("casein") || lower.contains("lactose") {
            return "Milk"
        }
        if lower.contains("egg") || lower.contains("albumin") || lower.contains("mayonnaise") {
            return "Eggs"
        }
        if lower.contains("peanut") || lower.contains("groundnut") {
            return "Peanuts"
        }
        if lower.contains("almond") || lower.contains("hazelnut") || lower.contains("walnut") ||
           lower.contains("cashew") || lower.contains("pistachio") || lower.contains("pecan") ||
           lower.contains("brazil nut") || lower.contains("macadamia") || lower.contains("nut") {
            return "Tree Nuts"
        }
        if lower.contains("wheat") || lower.contains("gluten") || lower.contains("barley") ||
           lower.contains("rye") || lower.contains("oats") || lower.contains("spelt") ||
           lower.contains("kamut") {
            return "Gluten"
        }
        if lower.contains("soy") || lower.contains("soya") || lower.contains("soybean") ||
           lower.contains("tofu") || lower.contains("edamame") {
            return "Soya"
        }
        if lower.contains("fish") || lower.contains("salmon") || lower.contains("tuna") ||
           lower.contains("cod") || lower.contains("haddock") || lower.contains("trout") {
            return "Fish"
        }
        if lower.contains("shellfish") || lower.contains("shrimp") || lower.contains("prawn") ||
           lower.contains("crab") || lower.contains("lobster") || lower.contains("mussel") ||
           lower.contains("oyster") || lower.contains("clam") {
            return "Shellfish"
        }
        if lower.contains("sesame") || lower.contains("tahini") {
            return "Sesame"
        }
        if lower.contains("celery") || lower.contains("celeriac") {
            return "Celery"
        }
        if lower.contains("mustard") {
            return "Mustard"
        }
        if lower.contains("sulphite") || lower.contains("sulfite") {
            return "Sulphites"
        }

        return nil
    }

    private func loadFoodEntry() async {
        isLoading = true
        defer { isLoading = false }

        // Try to fetch the food entry from the reaction date
        // We'll fetch all meals around the reaction time to find this specific food
        let startTime = reactionDate.addingTimeInterval(-7 * 24 * 3600) // 7 days before
        let endTime = reactionDate

        do {
            let meals = try await DiaryDataManager.shared.getMealsInTimeRange(from: startTime, to: endTime)

            // Find the food entry that matches our meal ID
            if let firstMealId = food.contributingMealIds.first {
                foodEntry = meals.first { $0.id == firstMealId }
            }
        } catch {
                    }
    }
}

// MARK: - Time Window Row
struct TimeWindowRow: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text("\(count)×")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Allergen Category Card
struct AllergenCategoryCard: View {
    let category: String
    let ingredients: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.red)

            ForEach(ingredients, id: \.self) { ingredient in
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 4, height: 4)

                    Text(ingredient)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(12)
        .background(Color.red.opacity(0.05))
        .cornerRadius(8)
    }
}

struct IngredientHistoryDetailView: View {
    let ingredient: WeightedIngredientScore
    let reactionDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("History for \(ingredient.ingredientName)")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Occurrence history and pattern analysis will be displayed here, showing all times this ingredient appeared before reactions.")
                        .foregroundColor(.secondary)

                    Text("Score: \(Int(ingredient.totalScore))")
                    Text("Occurrences: \(ingredient.occurrences)")
                    Text("Found in foods: \(ingredient.contributingFoodNames.joined(separator: ", "))")

                    if ingredient.symptomAssociationScore > 0 {
                        Text("Pattern detected: This ingredient has appeared before \(ingredient.appearedInSameSymptomCount) similar reactions")
                            .foregroundColor(.red)
                    }
                }
                .padding()
            }
            .navigationTitle("Ingredient History")
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

struct AllergenCategoryDetailView: View {
    let category: String
    let entry: ReactionLogEntry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("\(category) History")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Complete history of all \(category.lowercased())-containing foods consumed before reactions will be displayed here.")
                        .foregroundColor(.secondary)

                    Text("This view will show:")
                        .font(.headline)
                        .padding(.top)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Timeline of \(category.lowercased()) consumption")
                        Text("• Specific ingredients within this category")
                        Text("• Cross-reaction patterns")
                        Text("• Severity trends over time")
                    }
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("\(category) Analysis")
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

// MARK: - Recent Meals List View

struct RecentMealsListView: View {
    @State private var mealsByDay: [(date: Date, meals: [FoodEntry])] = []
    @State private var isLoading = true
    @State private var allIngredients: [String] = []
    @State private var allergens: [String: [String]] = [:]
    @State private var otherIngredients: [String] = []
    @State private var mealFrequencies: [(name: String, count: Int)] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isLoading {
                ProgressView("Loading recent meals...")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if mealsByDay.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))

                    Text("No meals logged recently")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(alignment: .leading, spacing: 24) {
                    // Meals by Day
                    ForEach(mealsByDay, id: \.date) { dayData in
                        DayMealsSection(date: dayData.date, meals: dayData.meals)
                    }

                    Divider()
                        .padding(.vertical, 8)

                    // Pattern Frequencies
                    if !mealFrequencies.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Meal Pattern Frequencies")
                                .font(.headline)
                                .foregroundColor(.primary)

                            ForEach(mealFrequencies.prefix(10), id: \.name) { item in
                                HStack {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 8, height: 8)

                                    Text(item.name)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    Text("\(item.count)×")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.bottom, 8)
                    }

                    // Recognised Allergens
                    if !allergens.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recognised Allergens")
                                .font(.headline)
                                .foregroundColor(.red)

                            ForEach(allergens.sorted(by: { $0.key < $1.key }), id: \.key) { category, ingredients in
                                AllergenCategoryCard(category: category, ingredients: ingredients)
                            }
                        }
                        .padding(.bottom, 8)
                    }

                    // Other Ingredients
                    if !otherIngredients.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Other Ingredients")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            ForEach(otherIngredients.prefix(20), id: \.self) { ingredient in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.secondary.opacity(0.3))
                                        .frame(width: 4, height: 4)

                                    Text(ingredient)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .task {
            await loadRecentMeals()
        }
    }

    private func loadRecentMeals() async {
        isLoading = true
        defer { isLoading = false }

        // Fetch meals from the last 7 days
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!

        do {
            let meals = try await DiaryDataManager.shared.getMealsInTimeRange(from: startDate, to: endDate)

            // Group by day (reverse chronological)
            let calendar = Calendar.current
            var grouped: [Date: [FoodEntry]] = [:]

            for meal in meals {
                let dayStart = calendar.startOfDay(for: meal.date)
                grouped[dayStart, default: []].append(meal)
            }

            // Sort by date (most recent first)
            mealsByDay = grouped.map { (date: $0.key, meals: $0.value) }
                .sorted { $0.date > $1.date }

            // Calculate meal frequencies
            var foodCounts: [String: Int] = [:]
            for meal in meals {
                let normalizedName = meal.foodName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                foodCounts[normalizedName, default: 0] += 1
            }
            mealFrequencies = foodCounts
                .map { (name: $0.key.capitalized, count: $0.value) }
                .sorted { $0.count > $1.count }

            // Extract all ingredients
            var allIngredientsList: [String] = []
            for meal in meals {
                if let ingredients = meal.ingredients {
                    allIngredientsList.append(contentsOf: ingredients)
                }
            }

            // Categorize ingredients
            categorizeIngredients(allIngredientsList)

        } catch {
                    }
    }

    private func categorizeIngredients(_ ingredients: [String]) {
        var allergenDict: [String: Set<String>] = [:]
        var otherSet: Set<String> = []

        for ingredient in ingredients {
            if let allergenCategory = getBaseAllergen(for: ingredient) {
                allergenDict[allergenCategory, default: []].insert(ingredient)
            } else {
                otherSet.insert(ingredient)
            }
        }

        allergens = allergenDict.mapValues { Array($0).sorted() }
        otherIngredients = Array(otherSet).sorted()
    }

    private func getBaseAllergen(for ingredient: String) -> String? {
        let lower = ingredient.lowercased()

        if lower.contains("milk") || lower.contains("dairy") || lower.contains("cream") ||
           lower.contains("cheese") || lower.contains("butter") || lower.contains("yogurt") ||
           lower.contains("whey") || lower.contains("casein") || lower.contains("lactose") {
            return "Milk"
        }
        if lower.contains("egg") || lower.contains("albumin") || lower.contains("mayonnaise") {
            return "Eggs"
        }
        if lower.contains("peanut") || lower.contains("groundnut") {
            return "Peanuts"
        }
        if lower.contains("almond") || lower.contains("hazelnut") || lower.contains("walnut") ||
           lower.contains("cashew") || lower.contains("pistachio") || lower.contains("pecan") ||
           lower.contains("brazil nut") || lower.contains("macadamia") || lower.contains("nut") {
            return "Tree Nuts"
        }
        if lower.contains("wheat") || lower.contains("gluten") || lower.contains("barley") ||
           lower.contains("rye") || lower.contains("oats") || lower.contains("spelt") ||
           lower.contains("kamut") {
            return "Gluten"
        }
        if lower.contains("soy") || lower.contains("soya") || lower.contains("soybean") ||
           lower.contains("tofu") || lower.contains("edamame") {
            return "Soya"
        }
        if lower.contains("fish") || lower.contains("salmon") || lower.contains("tuna") ||
           lower.contains("cod") || lower.contains("haddock") || lower.contains("trout") {
            return "Fish"
        }
        if lower.contains("shellfish") || lower.contains("shrimp") || lower.contains("prawn") ||
           lower.contains("crab") || lower.contains("lobster") || lower.contains("mussel") ||
           lower.contains("oyster") || lower.contains("clam") {
            return "Shellfish"
        }
        if lower.contains("sesame") || lower.contains("tahini") {
            return "Sesame"
        }
        if lower.contains("celery") || lower.contains("celeriac") {
            return "Celery"
        }
        if lower.contains("mustard") {
            return "Mustard"
        }
        if lower.contains("sulphite") || lower.contains("sulfite") {
            return "Sulphites"
        }

        return nil
    }
}

// MARK: - Day Meals Section

struct DayMealsSection: View {
    let date: Date
    let meals: [FoodEntry]

    private var dayName: String {
        // PERFORMANCE: Use cached static formatter
        DateHelper.fullDayOfWeekFormatter.string(from: date)
    }

    private var dateText: String {
        // PERFORMANCE: Use cached static formatter
        DateHelper.mediumDateFormatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Day header
            VStack(alignment: .leading, spacing: 4) {
                Text(dayName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                Text(dateText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Meals for this day
            VStack(alignment: .leading, spacing: 8) {
                ForEach(meals) { meal in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(mealTypeColor(meal.mealType))
                            .frame(width: 8, height: 8)

                        Text(meal.foodName)
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        Spacer()

                        Text(mealTypeLabel(meal.mealType))
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(mealTypeColor(meal.mealType).opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.leading, 8)
        }
        .padding(12)
        .background(Color.adaptiveCard)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }

    private func mealTypeColor(_ mealType: MealType) -> Color {
        switch mealType {
        case .breakfast: return .orange
        case .lunch: return .blue
        case .dinner: return .purple
        case .snacks: return .green
        }
    }

    private func mealTypeLabel(_ mealType: MealType) -> String {
        switch mealType {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snacks: return "Snack"
        }
    }
}

// MARK: - Multi-Reaction PDF Export Sheet

struct MultiReactionPDFExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = ReactionLogManager.shared
    @State private var isGenerating = false
    @State private var pdfURL: URL?
    @State private var showShareSheet = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if isGenerating {
                    ProgressView("Generating PDF...")
                        .font(.headline)
                        .padding()
                } else if let error = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)

                        Text("Export Failed")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("Try Again") {
                            errorMessage = nil
                            generatePDF()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Close") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                } else if pdfURL != nil {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)

                        Text("PDF Ready")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Your comprehensive reaction report is ready to share.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: {
                            showShareSheet = true
                        }) {
                            Label("Share Report", systemImage: "square.and.arrow.up")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()

                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)

                            Text("Export Comprehensive Report")
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text("Generate a PDF report of your last \(min(manager.reactionLogs.count, 5)) reactions with complete pattern analysis.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Report Includes")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                VStack(alignment: .leading, spacing: 10) {
                                    Label("Most recent reaction details", systemImage: "info.circle")
                                    Label("7-day meal history", systemImage: "calendar.badge.clock")
                                    Label("Previous reactions timeline", systemImage: "list.bullet")
                                    Label("Pattern analysis for allergens", systemImage: "chart.bar")
                                    Label("Other ingredient patterns", systemImage: "list.bullet")
                                }
                                .font(.callout)
                                .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                            Text("This report is for informational purposes only. Please share with a qualified healthcare provider or nutritionist for professional guidance.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            Button(action: {
                                generatePDF()
                            }) {
                                Label("Generate PDF Report", systemImage: "doc.badge.plus")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.horizontal)

                            Button("Cancel") {
                                dismiss()
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                    }
                }
            }
            .padding()
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showShareSheet) {
                if let url = pdfURL {
                    ShareSheet(items: [url])
                }
            }
        }
        .onDisappear {
            // Clean up temporary file when sheet is dismissed
            if let url = pdfURL {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    private func generatePDF() {
        isGenerating = true
        errorMessage = nil

        Task {
            do {
                // Get last 5 reactions (or fewer if less than 5 exist)
                let reactions = Array(manager.reactionLogs.prefix(5))

                guard !reactions.isEmpty else {
                    await MainActor.run {
                        self.errorMessage = "No reactions found to export."
                        self.isGenerating = false
                    }
                    return
                }

                // Get the most recent reaction for meal history
                let mostRecentReaction = reactions[0]
                let reactionDate = mostRecentReaction.reactionDate
                let startDate = reactionDate.addingTimeInterval(-7 * 24 * 3600)  // 7 days before

                // Fetch meals in the 7-day period
                var meals = try await DiaryDataManager.shared.getMealsInTimeRange(from: startDate, to: reactionDate)

                // Fetch food reactions in the same 7-day period and merge
                let allFoodReactions = try await FirebaseManager.shared.getReactions()
                let reactionDates = allFoodReactions.filter { reaction in
                    let date = reaction.timestamp.dateValue()
                    return date >= startDate && date <= reactionDate
                }

                // Convert FoodReactions to FoodEntry format
                let reactionEntries = reactionDates.compactMap { reaction -> FoodEntry? in
                    guard let userId = FirebaseManager.shared.currentUser?.uid else { return nil }
                    let date = reaction.timestamp.dateValue()

                    return FoodEntry(
                        id: reaction.id.uuidString,
                        userId: userId,
                        foodName: reaction.foodName,
                        brandName: reaction.foodBrand,
                        servingSize: 100,
                        servingUnit: "g",
                        calories: 0,
                        protein: 0,
                        carbohydrates: 0,
                        fat: 0,
                        ingredients: reaction.suspectedIngredients,
                        mealType: .snacks,
                        date: date,
                        dateLogged: date
                    )
                }

                // Merge reaction entries with diary meals (deduplicate)
                for reactionEntry in reactionEntries {
                    let calendar = Calendar.current
                    let reactionDay = calendar.startOfDay(for: reactionEntry.date)

                    let alreadyExists = meals.contains { meal in
                        let mealDay = calendar.startOfDay(for: meal.date)
                        return mealDay == reactionDay && meal.foodName.lowercased() == reactionEntry.foodName.lowercased()
                    }

                    if !alreadyExists {
                        meals.append(reactionEntry)
                    }
                }

                // Sort meals by date
                meals.sort { $0.date < $1.date }

                // Get all reactions for pattern analysis
                let allReactions = manager.reactionLogs

                // Generate PDF on background thread
                let url = await Task.detached(priority: .userInitiated) {
                    return ReactionPDFExporter.exportMultipleReactionsReport(
                        reactions: reactions,
                        mealHistory: meals,
                        allReactions: allReactions
                    )
                }.value

                if let url = url {
                    await MainActor.run {
                        self.pdfURL = url
                        self.isGenerating = false
                    }
                } else {
                    await MainActor.run {
                        self.errorMessage = "Failed to generate PDF. Please try again."
                        self.isGenerating = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to fetch data: \(error.localizedDescription)"
                    self.isGenerating = false
                }
            }
        }
    }
}

// MARK: - String Identifiable Extension
// Note: Required for .sheet(item:) modifier with String? types (line 767)
// @retroactive suppresses warning about conforming String to Identifiable
extension String: @retroactive Identifiable {
    public var id: String { self }
}

// MARK: - Reaction Barcode Scanner Sheet

struct ReactionBarcodeScannerSheet: View {
    let onFoodFound: (FoodSearchResult) -> Void
    let onCancel: () -> Void

    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var showError = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            ZStack {
                // Camera scanner
                BarcodeScannerViewControllerRepresentable { barcode in
                    handleBarcodeScanned(barcode)
                }
                .edgesIgnoringSafeArea(.all)

                // Overlay UI
                VStack {
                    Spacer()

                    // Bottom instruction text
                    if !isSearching {
                        VStack(spacing: 8) {
                            Text("Position barcode within frame")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            Text("Scan a product to link with your reaction")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(Color.black.opacity(0.7))
                    }
                }

                // Searching overlay
                if isSearching {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Looking up product...")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(16)
                }
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
            .alert("Product Not Found", isPresented: $showError) {
                Button("Try Again") {
                    errorMessage = nil
                }
                Button("Cancel", role: .cancel) {
                    onCancel()
                }
            } message: {
                Text(errorMessage ?? "This product wasn't found in our database.")
            }
        }
    }

    // MARK: - Barcode Handling

    private func handleBarcodeScanned(_ barcode: String) {
        guard !isSearching else { return }

        isSearching = true
        errorMessage = nil

        Task {
            // Normalize barcode for format variations
            let variations = normalizeBarcode(barcode)

            // Try Algolia search first
            var foundProduct: FoodSearchResult?
            for variation in variations {
                do {
                    if let hit = try await AlgoliaSearchManager.shared.searchByBarcode(variation) {
                        foundProduct = hit
                        break
                    }
                } catch {
                    continue
                }
            }

            if let product = foundProduct {
                await MainActor.run {
                    isSearching = false
                    onFoodFound(product)
                }
                return
            }

            // Fallback to Firebase cloud function
            await searchProductCloud(barcode: barcode)
        }
    }

    private func searchProductCloud(barcode: String) async {
        guard let url = URL(string: "https://us-central1-nutrasafe-705c7.cloudfunctions.net/searchFoodByBarcode") else {
            await MainActor.run {
                isSearching = false
                errorMessage = "Unable to search. Please try again."
                showError = true
            }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["barcode": barcode])

        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool, success,
               let foodData = json["food"] as? [String: Any] {

                // Parse the food result
                let product = FoodSearchResult(
                    id: foodData["id"] as? String ?? UUID().uuidString,
                    name: foodData["name"] as? String ?? "Unknown",
                    brand: foodData["brand"] as? String,
                    calories: foodData["calories"] as? Double ?? 0,
                    protein: foodData["protein"] as? Double ?? 0,
                    carbs: foodData["carbs"] as? Double ?? 0,
                    fat: foodData["fat"] as? Double ?? 0,
                    saturatedFat: foodData["saturatedFat"] as? Double,
                    fiber: foodData["fiber"] as? Double ?? 0,
                    sugar: foodData["sugar"] as? Double ?? 0,
                    sodium: foodData["sodium"] as? Double ?? 0,
                    ingredients: foodData["ingredients"] as? [String],
                    barcode: foodData["barcode"] as? String ?? barcode
                )

                await MainActor.run {
                    isSearching = false
                    onFoodFound(product)
                }
            } else {
                await MainActor.run {
                    isSearching = false
                    errorMessage = "This product wasn't found in our database."
                    showError = true
                }
            }
        } catch {
            await MainActor.run {
                isSearching = false
                errorMessage = "Unable to search. Please try again."
                showError = true
            }
        }
    }

    private func normalizeBarcode(_ barcode: String) -> [String] {
        var variations = [barcode]

        // EAN-13 to UPC-A
        if barcode.count == 13 && barcode.hasPrefix("0") {
            variations.append(String(barcode.dropFirst()))
        }

        // UPC-A to EAN-13
        if barcode.count == 12 {
            variations.append("0" + barcode)
        }

        return variations
    }
}
