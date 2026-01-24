//
//  AdditiveTrackerViewModel.swift
//  NutraSafe Beta
//
//  Tracks additive consumption over time periods
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

// MARK: - Time Period Enum

enum AdditiveTimePeriod: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case ninetyDays = "90 Days"

    var days: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        case .ninetyDays: return 90
        }
    }

    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        let endOfToday = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
        let startDate = calendar.date(byAdding: .day, value: -days + 1, to: calendar.startOfDay(for: now)) ?? now
        return (startDate, endOfToday)
    }
}

// MARK: - Additive Aggregate Model
// Note: ResearchStrength enum is defined in AdditiveResearchDatabase.swift

struct AdditiveAggregate: Identifiable {
    let id: String  // E-number code
    let code: String
    let name: String
    let category: String
    let healthScore: Int
    let effectsVerdict: String
    let childWarning: Bool
    let occurrenceCount: Int
    let foodItems: [String]
    let origin: String?
    let consumerGuide: String?

    // NEW: Full database fields for unified display
    let overview: String?           // Scientific explanation
    let typicalUses: String?        // Usage information
    let effectsSummary: String?     // Health effects details
    let hasPKUWarning: Bool
    let hasPolyolsWarning: Bool
    let hasSulphitesAllergenLabel: Bool

    var verdictColor: Color {
        switch effectsVerdict.lowercased() {
        case "avoid": return .red
        case "caution": return .orange
        default: return .green
        }
    }

    // MARK: - NEW 5-Section Template Structure

    /// SECTION 1: "What it is & why it's used" - Proper description from research database
    var whatItIsAndWhyItsUsed: String {
        // FIRST: Check the research database for a proper description
        if let databaseDescription = AdditiveResearchDatabase.shared.getWhatItIs(for: code), !databaseDescription.isEmpty {
            return databaseDescription
        }

        // SECOND: Try to use the overview field if available
        if let overview = overview, !overview.trimmingCharacters(in: .whitespaces).isEmpty {
            return overview
        }

        // THIRD: Fallback to category-based short description
        switch category.lowercased() {
        case "colour", "colours", "color", "colors":
            return "A food colouring that makes products more visually appealing."
        case "preservative", "preservatives":
            return "Helps keep food fresh by preventing bacterial growth."
        case "sweetener", "sweeteners":
            return "Provides sweetness without the calories of sugar."
        case "emulsifier", "emulsifiers":
            return "Keeps oil and water mixed for smooth textures."
        case "flavour enhancer", "flavour enhancers":
            return "Intensifies the natural flavour of foods."
        case "thickener", "thickeners":
            return "Gives food a thicker, more satisfying texture."
        case "antioxidant", "antioxidants":
            return "Prevents fats and oils from going rancid."
        case "stabiliser", "stabilisers":
            return "Keeps ingredients evenly mixed throughout the product."
        default:
            return "A food additive used to enhance or preserve food."
        }
    }

    /// SECTION 2: "Where it's found" - Common foods from research database + user's logged foods
    var whereItsFound: [String] {
        var foods: [String] = []

        // First check the research database for comprehensive food list
        let databaseFoods = AdditiveResearchDatabase.shared.getCommonFoods(for: code)
        if !databaseFoods.isEmpty {
            foods.append(contentsOf: databaseFoods)
        } else if let typicalUses = typicalUses, !typicalUses.trimmingCharacters(in: .whitespaces).isEmpty {
            // Fallback: parse typicalUses into individual food items
            let parsed = typicalUses
                .replacingOccurrences(of: " and ", with: ", ")
                .replacingOccurrences(of: "; ", with: ", ")
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && $0.count > 2 }
            foods.append(contentsOf: parsed)
        }

        // Add user's logged foods (if any, mark them distinctly)
        if !foodItems.isEmpty {
            foods.append(contentsOf: foodItems.prefix(3).map { "Your log: \($0)" })
        }

        return foods
    }

    /// SECTION 3: "Known reactions" - Specific health reactions from research database
    var knownReactions: [String] {
        // First check the research database for comprehensive reactions
        let databaseReactions = AdditiveResearchDatabase.shared.getKnownReactions(for: code)
        if !databaseReactions.isEmpty {
            return databaseReactions
        }

        // Fallback to boolean-based reactions
        var reactions: [String] = []

        if childWarning {
            reactions.append("Hyperactivity and attention issues in children")
        }
        if hasPKUWarning {
            reactions.append("Brain damage in people with phenylketonuria (PKU)")
        }
        if hasSulphitesAllergenLabel {
            reactions.append("Asthma attacks and allergic reactions")
        }
        if hasPolyolsWarning {
            reactions.append("Bloating, gas, and laxative effects")
        }

        return reactions
    }

    /// SECTION 4: "What research says" - Evidence-based summary from research database
    var whatResearchSays: (summary: String, strength: ResearchStrength) {
        // First check the research database for comprehensive research summary
        if let databaseResearch = AdditiveResearchDatabase.shared.getResearchSummary(for: code) {
            return databaseResearch
        }

        // Fallback to computed research summary
        let strength: ResearchStrength = {
            if childWarning || hasPKUWarning {
                return .strong
            } else if hasSulphitesAllergenLabel || hasPolyolsWarning {
                return .moderate
            } else if effectsVerdict.lowercased() == "avoid" {
                return .moderate
            } else if effectsVerdict.lowercased() == "caution" {
                return .emerging
            } else {
                return .limited
            }
        }()

        var summary = ""

        if childWarning {
            summary = "The Southampton Six study (2007) found this additive linked to increased hyperactivity in children. The FSA recommends parents of children showing signs of hyperactivity consider avoiding these additives."
        } else if hasPKUWarning {
            summary = "Medical research shows this substance causes brain damage in people with phenylketonuria (PKU), a genetic condition. Products must carry warnings for PKU sufferers."
        } else if hasSulphitesAllergenLabel {
            summary = "Clinical studies show sulphites can trigger asthma attacks and allergic reactions in sensitive individuals. The FSA requires sulphite content to be declared as an allergen."
        } else if hasPolyolsWarning {
            summary = "Research indicates that polyols (sugar alcohols) can cause digestive discomfort including bloating and laxative effects when consumed in large amounts."
        } else {
            switch effectsVerdict.lowercased() {
            case "avoid":
                summary = "Some research links this additive to potential health concerns. Regulatory bodies recommend avoiding or limiting intake."
            case "caution":
                summary = "Some studies suggest this additive may cause sensitivity in certain individuals. Consuming in moderation is advised."
            default:
                summary = "Regulatory bodies including the FSA and EFSA consider this additive safe at permitted use levels based on current evidence."
            }
        }

        return (summary, strength)
    }

    /// SECTION 5: "Full description" - The FUN engaging description (collapsed by default)
    var fullDescription: String {
        var sections: [String] = []

        // The fun "what is it" description
        sections.append(whatIsIt)

        // The fun "where is it from" description
        sections.append(whereIsItFrom)

        return sections.joined(separator: "\n\n")
    }

    /// Fun, human-friendly description of what this additive is
    var whatIsIt: String {
        // First try to get description from AdditiveOverrides (single source of truth)
        // This ensures consistency between food detail view and insights tracker

        // Try lookup by E-number or name using the helper method
        if let whatItIs = AdditiveOverrides.getWhatItIs(code: code, name: name), !whatItIs.isEmpty {
            return whatItIs
        }

        // Fallback to consumer guide or generic based on category
        switch category.lowercased() {
        case "colour", "colours", "color", "colors":
            return consumerGuide ?? "A food colouring used to make products more visually appealing. Because apparently we eat with our eyes first!"
        case "preservative", "preservatives":
            return consumerGuide ?? "Helps keep food fresh longer by preventing bacteria, mould, and other nasties from setting up camp."
        case "sweetener", "sweeteners":
            return consumerGuide ?? "Provides sweetness without the calories of sugar. Your taste buds won't know the difference (mostly)."
        case "emulsifier", "emulsifiers":
            return consumerGuide ?? "Keeps oil and water from having a falling out. Essential for creamy textures and smooth sauces."
        case "flavour enhancer", "flavour enhancers", "flavor enhancer", "flavor enhancers":
            return consumerGuide ?? "Makes food taste more like itself. The culinary equivalent of turning up the volume."
        case "thickener", "thickeners":
            return consumerGuide ?? "Gives food that satisfying thick, gloopy texture. Without it, your sauce would be water."
        case "antioxidant", "antioxidants":
            return consumerGuide ?? "Prevents fats and oils from going rancid. Keeps your crisps tasting fresh, not like old cardboard."
        case "stabiliser", "stabilisers", "stabilizer", "stabilizers":
            return consumerGuide ?? "Keeps everything mixed together nicely. The peacekeeper of the food world."
        default:
            return consumerGuide ?? "A food additive used to enhance, preserve, or modify food properties."
        }
    }

    /// Fun description of where this additive comes from
    var whereIsItFrom: String {
        // First try to get description from AdditiveOverrides (single source of truth)

        // Try lookup by E-number or name using the helper method
        if let originSummary = AdditiveOverrides.getOriginSummary(code: code, name: name), !originSummary.isEmpty {
            return originSummary
        }

        // Fallback to generic origin descriptions
        guard let origin = origin else {
            return "Origin unknown - probably cooked up in a lab somewhere!"
        }

        let originLower = origin.lowercased()

        switch originLower {
        case "synthetic":
            return "🧪 Made in a laboratory from chemical compounds. Science at its finest (or scariest, depending on your view)!"
        case "plant":
            return "🌱 Derived from plants - could be anything from seaweed to tree bark to corn. Mother Nature's chemistry set!"
        case "animal":
            return "🐄 Sourced from animals. This might include bones, skin, or other bits you probably don't want to think about while eating."
        case "mineral":
            return "🪨 Mined from the earth or extracted from rocks and minerals. Literally eating rocks, but in a safe way!"
        case "synthetic/plant/mineral (varies by specification)":
            return "🔄 Can come from various sources depending on the manufacturer. Like a lucky dip, but for food additives!"
        default:
            return "📍 \(origin.capitalized)"
        }
    }
}

// MARK: - Category Summary Model

struct AdditiveCategorySummary: Identifiable {
    let id: String
    let category: String
    let icon: String
    let count: Int
    let percentage: Double

    static func iconFor(category: String) -> String {
        switch category.lowercased() {
        case "colour", "colours", "color", "colors":
            return "paintpalette.fill"
        case "preservative", "preservatives":
            return "shield.fill"
        case "sweetener", "sweeteners":
            return "drop.fill"
        case "emulsifier", "emulsifiers":
            return "circle.lefthalf.filled"
        case "flavour enhancer", "flavour enhancers", "flavor enhancer", "flavor enhancers":
            return "sparkles"
        case "thickener", "thickeners", "stabiliser", "stabilisers", "stabilizer", "stabilizers":
            return "square.stack.fill"
        case "antioxidant", "antioxidants":
            return "leaf.fill"
        case "acid regulator", "acid regulators", "acidity regulator", "acidity regulators":
            return "flask.fill"
        case "anti-caking agent", "anti-caking agents", "anticaking agent", "anticaking agents":
            return "square.grid.3x3.fill"
        case "glazing agent", "glazing agents":
            return "sparkle"
        case "raising agent", "raising agents":
            return "arrow.up.circle.fill"
        case "humectant", "humectants":
            return "humidity.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
}

// MARK: - Pattern-Based Scoring Models

/// Frequency of concerning additive consumption
enum AdditiveFrequencyLevel: String {
    case rare = "Rare"           // < 2/week
    case occasional = "Occasional" // 2-4/week
    case frequent = "Frequent"    // 5-10/week
    case daily = "Daily"          // > 10/week

    static func from(concerningCount: Int, days: Int) -> AdditiveFrequencyLevel {
        let weeklyAverage = Double(concerningCount) / (Double(days) / 7.0)

        if weeklyAverage < 2 { return .rare }
        if weeklyAverage < 4 { return .occasional }
        if weeklyAverage < 10 { return .frequent }
        return .daily
    }

    var color: Color {
        switch self {
        case .rare: return SemanticColors.positive
        case .occasional: return .yellow
        case .frequent: return .orange
        case .daily: return .red
        }
    }
}

/// Trend direction for additive consumption
enum AdditiveTrendDirection: String {
    case improving = "↗️ Improving"
    case stable = "→ Stable"
    case declining = "↘️ Declining"

    var color: Color {
        switch self {
        case .improving: return SemanticColors.positive
        case .stable: return .yellow
        case .declining: return .red
        }
    }
}

/// Pattern-based grade that considers recency and frequency
enum AdditivePatternGrade: String {
    case clean = "Clean"           // 70-100: No concerning additives recently
    case moderate = "Moderate"     // 40-69: Some concerns, mostly safe
    case concerning = "Concerning" // 0-39: Frequent concerning additives

    static func from(score: Int) -> AdditivePatternGrade {
        if score >= 70 { return .clean }
        if score >= 40 { return .moderate }
        return .concerning
    }

    var color: Color {
        switch self {
        case .clean: return SemanticColors.positive
        case .moderate: return .yellow
        case .concerning: return .red
        }
    }

    var icon: String {
        switch self {
        case .clean: return "checkmark.circle.fill"
        case .moderate: return "exclamationmark.triangle.fill"
        case .concerning: return "xmark.octagon.fill"
        }
    }
}

/// Complete pattern analysis result
struct AdditivePatternScore {
    let overallScore: Int // 0-100
    let grade: AdditivePatternGrade
    let message: String
    let cleanStreakDays: Int
    let lastConcerningDate: Date?
    let lastConcerningAdditive: AdditiveAggregate?
    let frequency: AdditiveFrequencyLevel
    let trend: AdditiveTrendDirection

    // Recent vs. earlier comparison (for "now vs then" visualization)
    let recentScore: Int  // Last 7 days
    let earlierScore: Int // Days 8-30

    // Daily breakdown for sparkline visualization
    let dailyBreakdown: [DailyAdditiveData]
}

/// Daily additive data point for visualization
struct DailyAdditiveData: Identifiable {
    let id = UUID()
    let date: Date
    let avoidCount: Int
    let cautionCount: Int
    let neutralCount: Int

    var totalConcerning: Int {
        avoidCount + cautionCount
    }

    var severity: AdditiveSeverity {
        if avoidCount > 0 { return .avoid }
        if cautionCount > 0 { return .caution }
        return .neutral
    }
}

enum AdditiveSeverity {
    case avoid, caution, neutral

    var color: Color {
        switch self {
        case .avoid: return .red
        case .caution: return .orange
        case .neutral: return SemanticColors.positive
        }
    }
}

// MARK: - ViewModel

@MainActor
class AdditiveTrackerViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var selectedPeriod: AdditiveTimePeriod = .week
    @Published var additiveAggregates: [AdditiveAggregate] = []
    @Published var categorySummaries: [AdditiveCategorySummary] = []
    @Published var totalAdditiveCount: Int = 0
    @Published var foodItemCount: Int = 0
    @Published var isLoading = false
    @Published var hasData = false

    // MARK: - Private Properties

    private let firebaseManager: FirebaseManager
    private var loadTask: Task<Void, Never>?
    private var foodEntryObserver: NSObjectProtocol?

    // Cache for each period
    private var periodCache: [AdditiveTimePeriod: (aggregates: [AdditiveAggregate], categories: [AdditiveCategorySummary], total: Int, foods: Int, timestamp: Date)] = [:]
    private let cacheExpiration: TimeInterval = 300 // 5 minutes

    // MARK: - Init

    init(firebaseManager: FirebaseManager = .shared) {
        self.firebaseManager = firebaseManager

        // Listen for food entries being added to refresh cache
        foodEntryObserver = NotificationCenter.default.addObserver(
            forName: .foodEntryAdded,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.invalidateCache()
                self?.loadData()
            }
        }
    }

    deinit {
        if let observer = foodEntryObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Public Methods

    func loadData() {
        loadTask?.cancel()
        loadTask = Task {
            await loadAdditivesForPeriod(selectedPeriod)
        }
    }

    func refreshData() {
        // Clear cache for current period and reload
        periodCache[selectedPeriod] = nil
        loadData()
    }

    func selectPeriod(_ period: AdditiveTimePeriod) {
        if period == selectedPeriod {
            // Tapping same period forces refresh (clears cache)
            refreshData()
            return
        }
        selectedPeriod = period
        loadData()
    }

    // MARK: - Private Methods

    private func loadAdditivesForPeriod(_ period: AdditiveTimePeriod) async {
        // Check cache first
        if let cached = periodCache[period],
           Date().timeIntervalSince(cached.timestamp) < cacheExpiration {
            self.additiveAggregates = cached.aggregates
            self.categorySummaries = cached.categories
            self.totalAdditiveCount = cached.total
            self.foodItemCount = cached.foods
            self.hasData = !cached.aggregates.isEmpty
            return
        }

        isLoading = true

        do {
            // Use fromDictionary-based fetch for proper additives decoding
            let entries = try await firebaseManager.getFoodEntriesWithAdditivesForPeriod(days: period.days)

            guard !Task.isCancelled else { return }

            // Aggregate additives from all entries
            var additiveMap: [String: (info: NutritionAdditiveInfo, count: Int, foods: Set<String>)] = [:]
            var foodsWithAdditives = Set<String>()

            for entry in entries {
                guard let additives = entry.additives, !additives.isEmpty else { continue }

                let foodName = entry.foodName
                foodsWithAdditives.insert(entry.id)

                for additive in additives {
                    let key = additive.code.isEmpty ? additive.name.lowercased() : additive.code.lowercased()
                    if var existing = additiveMap[key] {
                        existing.count += 1
                        existing.foods.insert(foodName)
                        additiveMap[key] = existing
                    } else {
                        additiveMap[key] = (additive, 1, [foodName])
                    }
                }
            }

            guard !Task.isCancelled else { return }

            // Convert to aggregates - look up full additive info for each
            let aggregates = additiveMap.map { key, value in
                // Try to get full additive info from database
                let fullAdditive = AdditiveWatchService.shared.getAdditiveInfo(eNumber: value.info.code)

                return AdditiveAggregate(
                    id: key,
                    code: value.info.code,
                    name: value.info.name,
                    category: value.info.category,
                    healthScore: value.info.healthScore,
                    effectsVerdict: value.info.effectsVerdict,
                    childWarning: value.info.childWarning,
                    occurrenceCount: value.count,
                    foodItems: Array(value.foods),
                    origin: value.info.origin,
                    consumerGuide: value.info.consumerGuide,
                    // NEW: Full database fields
                    overview: fullAdditive?.overview,
                    typicalUses: fullAdditive?.typicalUses,
                    effectsSummary: fullAdditive?.effectsSummary,
                    hasPKUWarning: fullAdditive?.hasPKUWarning ?? false,
                    hasPolyolsWarning: fullAdditive?.hasPolyolsWarning ?? false,
                    hasSulphitesAllergenLabel: fullAdditive?.hasSulphitesAllergenLabel ?? false
                )
            }.sorted { $0.occurrenceCount > $1.occurrenceCount }

            // Calculate category summaries
            var categoryMap: [String: Int] = [:]
            for aggregate in aggregates {
                let category = normalizeCategory(aggregate.category)
                categoryMap[category, default: 0] += aggregate.occurrenceCount
            }

            let totalCount = categoryMap.values.reduce(0, +)
            let categories = categoryMap.map { category, count in
                AdditiveCategorySummary(
                    id: category,
                    category: category,
                    icon: AdditiveCategorySummary.iconFor(category: category),
                    count: count,
                    percentage: totalCount > 0 ? Double(count) / Double(totalCount) * 100 : 0
                )
            }.sorted { $0.count > $1.count }

            guard !Task.isCancelled else { return }

            // Update state
            self.additiveAggregates = aggregates
            self.categorySummaries = categories
            self.totalAdditiveCount = aggregates.reduce(0) { $0 + $1.occurrenceCount }
            self.foodItemCount = foodsWithAdditives.count
            self.hasData = !aggregates.isEmpty
            self.isLoading = false

            // Cache results
            periodCache[period] = (aggregates, categories, totalAdditiveCount, foodItemCount, Date())

        } catch {
            guard !Task.isCancelled else { return }
                        self.isLoading = false
        }
    }

    private func normalizeCategory(_ category: String) -> String {
        let lowercased = category.lowercased().trimmingCharacters(in: .whitespaces)

        // Normalize plural/singular and spelling variants
        switch lowercased {
        case "colour", "colors", "color":
            return "Colours"
        case "preservative":
            return "Preservatives"
        case "sweetener":
            return "Sweeteners"
        case "emulsifier":
            return "Emulsifiers"
        case "flavour enhancer", "flavor enhancer", "flavor enhancers":
            return "Flavour Enhancers"
        case "thickener", "thickeners":
            return "Thickeners"
        case "stabiliser", "stabilizer", "stabilizers":
            return "Stabilisers"
        case "antioxidant":
            return "Antioxidants"
        case "acid regulator", "acidity regulator", "acidity regulators":
            return "Acid Regulators"
        case "anti-caking agent", "anticaking agent", "anticaking agents":
            return "Anti-Caking Agents"
        case "glazing agent":
            return "Glazing Agents"
        case "raising agent":
            return "Raising Agents"
        case "humectant":
            return "Humectants"
        default:
            // Capitalize first letter of each word
            return category.capitalized
        }
    }

    // MARK: - Pattern Analysis (Time-Decay Scoring)

    /// Calculate time-weighted pattern score based on recency and frequency
    func analyzeAdditivePattern() async -> AdditivePatternScore {
        // Get all food entries from last 30 days
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let allEntries = await fetchAdditiveEntriesWithDates(since: thirtyDaysAgo)

        // Calculate clean streak
        let cleanStreak = calculateCleanStreak(entries: allEntries)

        // Find last concerning additive
        let concerningEntries = allEntries.filter { $0.verdict == "avoid" || $0.verdict == "caution" }
        let lastConcerning = concerningEntries.sorted { $0.date > $1.date }.first

        // Calculate frequency
        let frequency = AdditiveFrequencyLevel.from(concerningCount: concerningEntries.count, days: 30)

        // Calculate time-weighted score
        var score = 100
        for entry in allEntries {
            let daysAgo = Calendar.current.dateComponents([.day], from: entry.date, to: Date()).day ?? 0
            let weight = calculateTimeWeight(daysAgo: daysAgo)
            let severity = entry.verdict == "avoid" ? 20 : (entry.verdict == "caution" ? 10 : 2)
            score -= Int(Double(severity) * weight)
        }
        score = max(0, min(100, score))

        // Calculate recent vs. earlier scores for trend
        let recentEntries = allEntries.filter {
            Calendar.current.dateComponents([.day], from: $0.date, to: Date()).day ?? 0 < 7
        }
        let earlierEntries = allEntries.filter {
            let days = Calendar.current.dateComponents([.day], from: $0.date, to: Date()).day ?? 0
            return days >= 7 && days < 30
        }

        let recentScore = calculateScore(for: recentEntries, days: 7)
        let earlierScore = calculateScore(for: earlierEntries, days: 23)

        // Determine trend
        let trend: AdditiveTrendDirection
        if recentScore > earlierScore + 15 {
            trend = .improving
        } else if recentScore < earlierScore - 15 {
            trend = .declining
        } else {
            trend = .stable
        }

        // Generate grade and message
        let grade = AdditivePatternGrade.from(score: score)
        let message = generateEmotionalMessage(grade: grade, streak: cleanStreak, frequency: frequency, trend: trend)

        // Generate daily breakdown for visualization
        let dailyBreakdown = generateDailyBreakdown(entries: allEntries)

        return AdditivePatternScore(
            overallScore: score,
            grade: grade,
            message: message,
            cleanStreakDays: cleanStreak,
            lastConcerningDate: lastConcerning?.date,
            lastConcerningAdditive: lastConcerning != nil ? createAggregate(from: lastConcerning!) : nil,
            frequency: frequency,
            trend: trend,
            recentScore: recentScore,
            earlierScore: earlierScore,
            dailyBreakdown: dailyBreakdown
        )
    }

    /// Time-decay weight function: exponential decay with 7-day half-life
    private func calculateTimeWeight(daysAgo: Int) -> Double {
        let decayConstant = 7.0
        return exp(-Double(daysAgo) / decayConstant)
    }

    /// Calculate score for a set of entries over a period
    private func calculateScore(for entries: [AdditiveEntry], days: Int) -> Int {
        var score = 100
        for entry in entries {
            let severity = entry.verdict == "avoid" ? 20 : (entry.verdict == "caution" ? 10 : 2)
            score -= severity
        }
        return max(0, min(100, score))
    }

    /// Calculate clean streak (days since last concerning additive)
    private func calculateCleanStreak(entries: [AdditiveEntry]) -> Int {
        let concerningEntries = entries.filter { $0.verdict == "avoid" || $0.verdict == "caution" }
        guard let lastConcerning = concerningEntries.sorted(by: { $0.date > $1.date }).first else {
            // No concerning additives ever? Count all 30 days
            return 30
        }

        let daysSince = Calendar.current.dateComponents([.day], from: lastConcerning.date, to: Date()).day ?? 0
        return max(0, daysSince)
    }

    /// Generate emotion-first message based on pattern analysis
    private func generateEmotionalMessage(grade: AdditivePatternGrade, streak: Int, frequency: AdditiveFrequencyLevel, trend: AdditiveTrendDirection) -> String {
        switch grade {
        case .clean:
            if streak >= 14 {
                return "Clean streak: \(streak) days. You're thriving!"
            } else if streak >= 7 {
                return "Building good habits"
            } else {
                return "Your choices look good"
            }

        case .moderate:
            if trend == .improving {
                return "Making cleaner choices"
            } else if frequency == .rare {
                return "Worth noting what's in your food"
            } else {
                return "Some patterns emerging"
            }

        case .concerning:
            if frequency == .daily {
                return "Daily patterns worth exploring"
            } else {
                return "Patterns worth noting"
            }
        }
    }

    /// Generate daily breakdown for sparkline visualization
    private func generateDailyBreakdown(entries: [AdditiveEntry]) -> [DailyAdditiveData] {
        let calendar = Calendar.current
        var dailyData: [Date: (avoid: Int, caution: Int, neutral: Int)] = [:]

        // Group by day
        for entry in entries {
            let dayStart = calendar.startOfDay(for: entry.date)
            var existing = dailyData[dayStart] ?? (0, 0, 0)

            switch entry.verdict {
            case "avoid":
                existing.avoid += 1
            case "caution":
                existing.caution += 1
            default:
                existing.neutral += 1
            }

            dailyData[dayStart] = existing
        }

        // Convert to array sorted by date
        return dailyData.map { date, counts in
            DailyAdditiveData(
                date: date,
                avoidCount: counts.avoid,
                cautionCount: counts.caution,
                neutralCount: counts.neutral
            )
        }.sorted { $0.date < $1.date }
    }

    /// Helper struct for pattern analysis
    private struct AdditiveEntry {
        let date: Date
        let code: String
        let name: String
        let verdict: String
        let category: String
    }

    /// Fetch additive entries with timestamps from Firebase using existing infrastructure
    private func fetchAdditiveEntriesWithDates(since startDate: Date) async -> [AdditiveEntry] {
        do {
            // Use existing FirebaseManager method to get food entries with date filter
            let endDate = Date()

            guard let userId = firebaseManager.currentUser?.uid else { return [] }

            // Get food entries in range
            let foodEntries = try await firebaseManager.getFoodEntriesInRange(
                userId: userId,
                startDate: startDate,
                endDate: endDate
            )

            var entries: [AdditiveEntry] = []

            // Extract additives from each food entry
            for foodEntry in foodEntries {
                guard let additives = foodEntry.additives, !additives.isEmpty else { continue }

                let entryDate = foodEntry.date

                for additive in additives {
                    guard !additive.code.isEmpty else { continue }

                    entries.append(AdditiveEntry(
                        date: entryDate,
                        code: additive.code,
                        name: additive.name,
                        verdict: additive.effectsVerdict,
                        category: additive.category
                    ))
                }
            }

            return entries
        } catch {
            print("Error fetching additive entries: \(error)")
            return []
        }
    }

    /// Create aggregate from single entry (for "last concerning" display)
    private func createAggregate(from entry: AdditiveEntry) -> AdditiveAggregate {
        // This is a simplified version - in real use we'd fetch full data
        return AdditiveAggregate(
            id: entry.code.isEmpty ? entry.name.lowercased() : entry.code.lowercased(),
            code: entry.code,
            name: entry.name,
            category: entry.category,
            healthScore: 50,
            effectsVerdict: entry.verdict,
            childWarning: false,
            occurrenceCount: 1,
            foodItems: [],
            origin: nil,
            consumerGuide: nil,
            overview: nil,
            typicalUses: nil,
            effectsSummary: nil,
            hasPKUWarning: false,
            hasPolyolsWarning: false,
            hasSulphitesAllergenLabel: false
        )
    }

    // MARK: - Cache Management

    func invalidateCache() {
        periodCache.removeAll()
    }

    func invalidateCache(for period: AdditiveTimePeriod) {
        periodCache[period] = nil
    }
}
