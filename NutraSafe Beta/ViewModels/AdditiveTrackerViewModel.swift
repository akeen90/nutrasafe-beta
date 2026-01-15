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

    var verdictColor: Color {
        switch effectsVerdict.lowercased() {
        case "avoid": return .red
        case "caution": return .orange
        default: return .green
        }
    }

    /// Fun, human-friendly description of what this additive is
    var whatIsIt: String {
        // Check for specific additives with fun descriptions
        let codeLower = code.lowercased()
        let nameLower = name.lowercased()

        // Colours from bugs
        if codeLower == "e120" || nameLower.contains("carmine") || nameLower.contains("cochineal") {
            return "A bright red dye made from crushed cochineal beetles. Yes, actual bugs! About 70,000 beetles are needed to make just one pound of dye. Vegetarians and vegans, look away!"
        }

        // Shellac (also from bugs)
        if codeLower == "e904" || nameLower.contains("shellac") {
            return "A shiny coating secreted by lac bugs. It's the same stuff used to make furniture polish shine! Also found on apples and sweets to give them that glossy look."
        }

        // Gelatin
        if nameLower.contains("gelatin") || nameLower.contains("gelatine") {
            return "Made by boiling animal bones, skin, and connective tissue. It's what makes jelly wobble and gummy bears chewy. Not one for the vegans!"
        }

        // Carrageenan (seaweed)
        if codeLower == "e407" || nameLower.contains("carrageenan") {
            return "Extracted from red seaweed harvested from the ocean. It's been used in Irish cooking for centuries - nature's thickener!"
        }

        // MSG
        if codeLower == "e621" || nameLower.contains("monosodium glutamate") || nameLower.contains("msg") {
            return "The famous 'umami' flavour enhancer. Despite its bad reputation, it's just a salt of glutamic acid - an amino acid found naturally in tomatoes, parmesan, and your own body!"
        }

        // Aspartame
        if codeLower == "e951" || nameLower.contains("aspartame") {
            return "An artificial sweetener about 200 times sweeter than sugar. Made from two amino acids, it's in most diet drinks. One of the most studied food additives ever!"
        }

        // Xanthan gum
        if codeLower == "e415" || nameLower.contains("xanthan") {
            return "A slimy substance produced by bacteria during fermentation. Sounds gross, but it's brilliant at making sauces smooth and gluten-free baking possible!"
        }

        // Lecithin
        if codeLower == "e322" || nameLower.contains("lecithin") {
            return "Usually extracted from soy or egg yolks. It's an emulsifier that stops oil and water from separating - the unsung hero of chocolate bars everywhere!"
        }

        // Tartrazine (yellow)
        if codeLower == "e102" || nameLower.contains("tartrazine") {
            return "A bright yellow synthetic dye also known as 'Yellow 5'. It's what gives custard and fizzy drinks that sunny colour. Some people are sensitive to it."
        }

        // Sodium benzoate
        if codeLower == "e211" || nameLower.contains("sodium benzoate") {
            return "A preservative that stops bacteria and fungi from growing. Naturally found in cranberries and prunes, but usually made synthetically."
        }

        // Generic based on category
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
        guard let origin = origin else {
            return "Origin unknown - probably cooked up in a lab somewhere!"
        }

        let originLower = origin.lowercased()
        let codeLower = code.lowercased()

        // Special cases
        if codeLower == "e120" || name.lowercased().contains("carmine") {
            return "🐛 Crushed beetles from South America and Mexico. The female cochineal bugs are harvested, dried, and crushed. It takes about 70,000 bugs to make 450g of dye!"
        }

        if codeLower == "e904" || name.lowercased().contains("shellac") {
            return "🐛 Secreted by lac bugs in India and Thailand. The bugs coat tree branches with this resinous substance, which is then scraped off and processed."
        }

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
            self?.invalidateCache()
            self?.loadData()
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

            #if DEBUG
            print("🧪 AdditiveTracker: Fetched \(entries.count) entries for \(period.days) days")
            var entriesWithAdditives = 0
            for entry in entries {
                if let additives = entry.additives, !additives.isEmpty {
                    entriesWithAdditives += 1
                    print("   - \(entry.foodName): \(additives.count) additives")
                }
            }
            print("🧪 AdditiveTracker: \(entriesWithAdditives) entries have additives")
            #endif

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

            // Convert to aggregates
            let aggregates = additiveMap.map { key, value in
                AdditiveAggregate(
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
                    consumerGuide: value.info.consumerGuide
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
            #if DEBUG
            print("❌ AdditiveTracker: Failed to load entries: \(error)")
            #endif
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
