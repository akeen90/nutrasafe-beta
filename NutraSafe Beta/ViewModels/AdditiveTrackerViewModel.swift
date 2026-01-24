//
//  AdditiveTrackerViewModel.swift
//  NutraSafe Beta
//
//  Tracks additive consumption over time periods
//

import Foundation
import SwiftUI
import Combine

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

    /// Build "What I need to know" health claim bullets
    var whatYouNeedToKnow: [String] {
        var bullets: [String] = []

        // Child warning (Southampton Six)
        if childWarning {
            bullets.append("May affect children's activity and attention")
        }

        // PKU warning
        if hasPKUWarning {
            bullets.append("Not suitable for people with phenylketonuria (PKU)")
        }

        // Sulphites allergen
        if hasSulphitesAllergenLabel {
            bullets.append("Contains sulphites (allergen)")
        }

        // Polyols warning
        if hasPolyolsWarning {
            bullets.append("May have a laxative effect if consumed in large amounts")
        }

        // Verdict-based claim
        switch effectsVerdict.lowercased() {
        case "avoid":
            bullets.append("Some studies suggest limiting intake")
        case "caution":
            bullets.append("Some people may wish to avoid")
        default:
            if bullets.isEmpty {
                bullets.append("Generally recognized as safe")
            }
        }

        return bullets
    }

    /// Build "Full Facts" scientific background text
    var fullFacts: String {
        var sections: [String] = []

        if let overview = overview, !overview.trimmingCharacters(in: .whitespaces).isEmpty {
            sections.append(overview)
        }

        if let typicalUses = typicalUses, !typicalUses.trimmingCharacters(in: .whitespaces).isEmpty {
            sections.append("**Typical Uses:** \(typicalUses)")
        }

        if let effectsSummary = effectsSummary, !effectsSummary.trimmingCharacters(in: .whitespaces).isEmpty {
            sections.append(effectsSummary)
        }

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

    // MARK: - Cache Management

    func invalidateCache() {
        periodCache.removeAll()
    }

    func invalidateCache(for period: AdditiveTimePeriod) {
        periodCache[period] = nil
    }
}
