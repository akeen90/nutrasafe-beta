//
//  FoodSafetyModels.swift
//  NutraSafe Beta
//
//  Domain models for FoodSafety
//

import Foundation
import SwiftUI
import FirebaseFirestore

// MARK: - Placeholder Types for Build Compatibility

struct SuspiciousFood {
    let id = UUID()
    let name: String
    let reason: String
    let flagged: Bool
}

struct Ingredient {
    let id = UUID()
    let name: String
    let category: IngredientCategory
    let allergens: [Allergen]
    let micronutrients: [Micronutrient]
    let additives: [FoodAdditive]
    let riskLevel: IngredientRiskLevel

    init(name: String, category: IngredientCategory, allergens: [Allergen] = [], micronutrients: [Micronutrient] = [], additives: [FoodAdditive] = [], riskLevel: IngredientRiskLevel = .unknown) {
        self.name = name
        self.category = category
        self.allergens = allergens
        self.micronutrients = micronutrients
        self.additives = additives
        self.riskLevel = riskLevel
    }
}

enum MicronutrientType: String, CaseIterable {
    case vitamin = "vitamin"
    case mineral = "mineral"
    case other = "other"
}

struct Micronutrient {
    let id = UUID()
    let name: String
    let type: MicronutrientType
    let amount: Double
    let unit: String
    let dailyValuePercentage: Double?
    let benefits: [String]
    let deficiencyRisks: [String]

    init(name: String, type: MicronutrientType, amount: Double, unit: String, dailyValuePercentage: Double? = nil, benefits: [String] = [], deficiencyRisks: [String] = []) {
        self.name = name
        self.type = type
        self.amount = amount
        self.unit = unit
        self.dailyValuePercentage = dailyValuePercentage
        self.benefits = benefits
        self.deficiencyRisks = deficiencyRisks
    }
}

struct FoodAdditive {
    let id = UUID()
    let name: String
    let code: String
    let purpose: AdditivePurpose
    let safetyRating: AdditiveRating
    let commonNames: [String]
    let potentialEffects: [String]

    init(name: String, code: String, purpose: AdditivePurpose, safetyRating: AdditiveRating, commonNames: [String] = [], potentialEffects: [String] = []) {
        self.name = name
        self.code = code
        self.purpose = purpose
        self.safetyRating = safetyRating
        self.commonNames = commonNames
        self.potentialEffects = potentialEffects
    }
}

enum Allergen: String, CaseIterable, Identifiable {
    case dairy = "dairy"
    case eggs = "eggs"  
    case fish = "fish"
    case shellfish = "shellfish"
    case treeNuts = "treeNuts"
    case peanuts = "peanuts"
    case wheat = "wheat"
    case soy = "soy"
    case sesame = "sesame"
    case gluten = "gluten"
    case lactose = "lactose"
    case sulfites = "sulfites"
    case msg = "msg"
    case corn = "corn"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .dairy: return "Dairy"
        case .eggs: return "Eggs"
        case .fish: return "Fish"
        case .shellfish: return "Shellfish"
        case .treeNuts: return "Tree Nuts"
        case .peanuts: return "Peanuts"
        case .wheat: return "Wheat"
        case .soy: return "Soy"
        case .sesame: return "Sesame"
        case .gluten: return "Gluten"
        case .lactose: return "Lactose"
        case .sulfites: return "Sulfites"
        case .msg: return "MSG"
        case .corn: return "Corn"
        }
    }
    
    var icon: String {
        switch self {
        case .dairy: return "🥛"
        case .eggs: return "🥚"
        case .fish: return "🐟"
        case .shellfish: return "🦐"
        case .treeNuts: return "🌰"
        case .peanuts: return "🥜"
        case .wheat: return "🌾"
        case .soy: return "🫘"
        case .sesame: return "🫰"
        case .gluten: return "🍞"
        case .lactose: return "🥛"
        case .sulfites: return "🍷"
        case .msg: return "🧂"
        case .corn: return "🌽"
        }
    }
    
    // Common ingredient keywords that contain this allergen
    var keywords: [String] {
        switch self {
        case .dairy:
            return ["milk", "cream", "butter", "cheese", "yogurt", "whey", "casein", "lactose", "ghee", "custard", "ice cream"]
        case .eggs:
            return ["egg", "albumin", "mayonnaise", "meringue", "ovalbumin", "lecithin"]
        case .fish:
            return ["salmon", "tuna", "cod", "bass", "trout", "anchovy", "sardine", "mackerel", "fish sauce", "worcestershire"]
        case .shellfish:
            return ["shrimp", "crab", "lobster", "clam", "mussel", "oyster", "scallop", "crawfish", "crayfish"]
        case .treeNuts:
            return ["almond", "walnut", "cashew", "pistachio", "pecan", "hazelnut", "brazil nut", "macadamia", "pine nut"]
        case .peanuts:
            return ["peanut", "groundnut", "arachis oil", "peanut butter", "peanut oil"]
        case .wheat:
            return ["wheat", "flour", "bread", "pasta", "bulgur", "couscous", "farina", "graham", "semolina", "spelt"]
        case .soy:
            return ["soy", "soya", "tofu", "tempeh", "miso", "shoyu", "tamari", "edamame", "soy sauce"]
        case .sesame:
            return ["sesame", "tahini", "sesame oil", "sesame seed", "sesamum"]
        case .gluten:
            return ["gluten", "wheat", "barley", "rye", "malt", "brewer's yeast", "oats"]
        case .lactose:
            return ["lactose", "milk", "dairy", "whey", "cream", "butter", "cheese"]
        case .sulfites:
            return ["sulfite", "sulfur dioxide", "wine", "dried fruit", "preservative"]
        case .msg:
            return ["monosodium glutamate", "msg", "glutamate", "hydrolyzed protein", "yeast extract"]
        case .corn:
            return ["corn", "maize", "corn syrup", "corn starch", "dextrose", "glucose", "fructose"]
        }
    }
    
    var severity: AllergenSeverity {
        switch self {
        case .dairy, .eggs, .fish, .shellfish, .treeNuts, .peanuts:
            return .high
        case .wheat, .soy, .gluten:
            return .medium
        case .sesame, .lactose, .sulfites, .msg, .corn:
            return .low
        }
    }
}

enum AllergenSeverity: String {
    case low = "low"
    case medium = "medium"
    case high = "high"

    var color: String {
        switch self {
        case .low: return "yellow"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
}

// Ingredient typing used across NutritionModels and FoodSafetyModels
enum IngredientCategory: String, Codable, CaseIterable {
    case core        // core ingredient, e.g., flour, sugar
    case additive    // additive like emulsifier, stabilizer
    case allergen    // known allergen source
    case micronutrient // fortified micronutrient source
    case flavoring   // natural or artificial flavors/spices
    case other
}

enum IngredientRiskLevel: String, Codable, CaseIterable {
    case unknown
    case low
    case medium
    case high
}

struct AllergenDetectionResult {
    let detectedAllergens: [Allergen]
    let confidence: Double // 0.0 to 1.0
    let riskLevel: AllergenSeverity
    let warnings: [String]

    /// True if allergens were detected in the food
    var hasAllergens: Bool {
        return !detectedAllergens.isEmpty
    }
}

class AllergenDetector {
    static let shared = AllergenDetector()
    
    private init() {}
    
    func detectAllergens(in foodName: String, ingredients: [String] = [], userAllergens: [Allergen]) -> AllergenDetectionResult {
        let searchText = (foodName + " " + ingredients.joined(separator: " ")).lowercased()
        var detectedAllergens: [Allergen] = []
        var confidence = 0.0
        var warnings: [String] = []
        
        // Check each user allergen against the food
        for allergen in userAllergens {
            let matchingKeywords = allergen.keywords.filter { keyword in
                searchText.contains(keyword.lowercased())
            }
            
            if !matchingKeywords.isEmpty {
                detectedAllergens.append(allergen)
                warnings.append("Contains \(allergen.displayName): \(matchingKeywords.joined(separator: ", "))")
                
                // Increase confidence based on number of matches
                confidence += Double(matchingKeywords.count) * 0.2
            }
        }
        
        // Cap confidence at 1.0
        confidence = min(confidence, 1.0)
        
        // Determine risk level
        let riskLevel: AllergenSeverity
        if detectedAllergens.contains(where: { $0.severity == .high }) {
            riskLevel = .high
        } else if detectedAllergens.contains(where: { $0.severity == .medium }) {
            riskLevel = .medium
        } else if !detectedAllergens.isEmpty {
            riskLevel = .low
        } else {
            riskLevel = .low
            confidence = max(confidence, 0.8) // High confidence if no allergens detected
        }
        
        return AllergenDetectionResult(
            detectedAllergens: detectedAllergens,
            confidence: confidence,
            riskLevel: riskLevel,
            warnings: warnings
        )
    }

    // Refined dairy detection: flags animal dairy terms and excludes plant milks
    func containsDairyMilk(in rawText: String) -> Bool {
        let text = rawText.lowercased()
        let explicitDairyTerms = [
            "dairy","cheese","cream","butter","yogurt","yoghurt","whey","casein","lactose",
            "milk powder","skimmed milk powder","condensed milk","evaporated milk",
            "milk solids","milkfat","whole milk","semi skimmed milk","semi-skimmed milk","skimmed milk",
            "cow milk","cow's milk","goat milk","sheep milk","milk chocolate"
        ]
        if explicitDairyTerms.contains(where: { text.contains($0) }) {
            return true
        }
        guard text.contains("milk") else { return false }
        let plantMilkPhrases = [
            "coconut milk","almond milk","soy milk","soya milk","oat milk","rice milk",
            "cashew milk","hazelnut milk","pea milk","plant milk","non-dairy milk",
            "non dairy milk","dairy-free milk","dairy free milk"
        ]
        var scrubbed = text
        for phrase in plantMilkPhrases {
            scrubbed = scrubbed.replacingOccurrences(of: phrase, with: "")
        }
        // If any 'milk' remains after removing plant-milk phrases, treat as dairy
        return scrubbed.contains("milk")
    }
}

struct AdditiveInfo: Codable, Identifiable {
    let id: String
    let eNumber: String
    let name: String
    let group: AdditiveGroup
    let isPermittedGB: Bool
    let isPermittedNI: Bool
    let isPermittedEU: Bool
    let statusNotes: String?
    let hasChildWarning: Bool
    let hasPKUWarning: Bool
    let hasPolyolsWarning: Bool
    let hasSulphitesAllergenLabel: Bool
    let category: AdditiveCategory
    let origin: AdditiveOrigin
    let overview: String
    let typicalUses: String
    let effectsSummary: String
    let effectsVerdict: AdditiveVerdict
    let synonyms: [String]
    let insNumber: String?
    let sources: [AdditiveSource]
    let consumerInfo: String?
    let eNumbers: [String]  // Array of all E-numbers for this ingredient (consolidated database)
    let whereItComesFrom: String?  // Descriptive origin text for ultra-processed ingredients
    let processingPenalty: Int  // Processing penalty score for ultra-processed ingredients
    let novaGroup: Int  // NOVA classification group (1-4)

    init(id: String, eNumber: String, name: String, group: AdditiveGroup, isPermittedGB: Bool = true, isPermittedNI: Bool = true, isPermittedEU: Bool = true, statusNotes: String? = nil, hasChildWarning: Bool = false, hasPKUWarning: Bool = false, hasPolyolsWarning: Bool = false, hasSulphitesAllergenLabel: Bool = false, category: AdditiveCategory = .other, origin: AdditiveOrigin = .synthetic, overview: String = "", typicalUses: String = "", effectsSummary: String = "", effectsVerdict: AdditiveVerdict = .neutral, synonyms: [String] = [], insNumber: String? = nil, sources: [AdditiveSource] = [], consumerInfo: String? = nil, eNumbers: [String] = [], whereItComesFrom: String? = nil, processingPenalty: Int = 0, novaGroup: Int = 0) {
        self.id = id
        self.eNumber = eNumber
        self.name = name
        self.group = group
        self.isPermittedGB = isPermittedGB
        self.isPermittedNI = isPermittedNI
        self.isPermittedEU = isPermittedEU
        self.statusNotes = statusNotes
        self.hasChildWarning = hasChildWarning
        self.hasPKUWarning = hasPKUWarning
        self.hasPolyolsWarning = hasPolyolsWarning
        self.hasSulphitesAllergenLabel = hasSulphitesAllergenLabel
        self.category = category
        self.origin = origin
        self.overview = overview
        self.typicalUses = typicalUses
        self.effectsSummary = effectsSummary
        self.effectsVerdict = effectsVerdict
        self.synonyms = synonyms
        self.insNumber = insNumber
        self.sources = sources
        self.consumerInfo = consumerInfo
        self.eNumbers = eNumbers
        self.whereItComesFrom = whereItComesFrom
        self.processingPenalty = processingPenalty
        self.novaGroup = novaGroup
    }
}

struct AdditiveAnalysis {
    let eNumbers: [String]
    let additives: [String]
    let preservatives: [String]
    let goodAdditives: [String]
    let comprehensiveAdditives: [AdditiveInfo]
    let totalHealthScore: Int
    let worstVerdict: String
    let hasChildWarnings: Bool
    let hasAllergenWarnings: Bool
}

enum AdditiveGroup: String, Codable, CaseIterable {
    case colour = "colour"
    case preservative = "preservative"
    case antioxidant = "antioxidant"
    case emulsifier = "emulsifier"
    case stabilizer = "stabilizer"
    case thickener = "thickener"
    case sweetener = "sweetener"
    case flavourEnhancer = "flavour_enhancer"
    case acidRegulator = "acid_regulator"
    case anticaking = "anticaking"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .colour: return "Colour"
        case .preservative: return "Preservative"
        case .antioxidant: return "Antioxidant"
        case .emulsifier: return "Emulsifier"
        case .stabilizer: return "Stabilizer"
        case .thickener: return "Thickener"
        case .sweetener: return "Sweetener"
        case .flavourEnhancer: return "Flavour Enhancer"
        case .acidRegulator: return "Acid Regulator"
        case .anticaking: return "Anti-Caking Agent"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .colour: return "🎨"
        case .preservative: return "🛡️"
        case .antioxidant: return "⚗️"
        case .emulsifier: return "🫧"
        case .stabilizer: return "⚖️"
        case .thickener: return "🥄"
        case .sweetener: return "🍯"
        case .flavourEnhancer: return "✨"
        case .acidRegulator: return "🧪"
        case .anticaking: return "🧂"
        case .other: return "📦"
        }
    }
}

enum AdditiveCategory: String, Codable {
    case colour = "colour"
    case preservative = "preservative"
    case other = "other"
}

enum AdditiveOrigin: String, Codable {
    case synthetic = "synthetic"
    case plant = "plant"
    case animal = "animal"
    case mineral = "mineral"
    case syntheticPlantMineral = "synthetic/plant/mineral (varies by specification)"
    
    var displayName: String {
        switch self {
        case .synthetic: return "Synthetic"
        case .plant: return "Plant-based"
        case .animal: return "Animal-based"
        case .mineral: return "Mineral"
        case .syntheticPlantMineral: return "Various sources"
        }
    }
    
    var icon: String {
        switch self {
        case .synthetic: return "⚗️"
        case .plant: return "🌱"
        case .animal: return "🐄"
        case .mineral: return "⛰️"
        case .syntheticPlantMineral: return "🔄"
        }
    }
}

enum AdditiveVerdict: String, Codable {
    case neutral = "neutral"
    case caution = "caution"
    case avoid = "avoid"
    
    var color: Color {
        switch self {
        case .neutral: return .green
        case .caution: return .orange
        case .avoid: return .red
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .neutral: return .green.opacity(0.1)
        case .caution: return .orange.opacity(0.1)
        case .avoid: return .red.opacity(0.1)
        }
    }
}

struct AdditiveSource: Codable {
    let title: String
    let url: String
    let covers: String?  // Optional field from CSV sources
}

struct AdditiveDetectionResult {
    let detectedAdditives: [AdditiveInfo]
    let childWarnings: [AdditiveInfo]
    let hasChildConcernAdditives: Bool
    let analysisConfidence: Double
    let processingScore: ProcessingAnalysisResult?
    let comprehensiveWarnings: AdditiveWarningsResult?
    let ultraProcessedIngredients: [UltraProcessedIngredientDisplay]  // NEW

    var childWarningMessage: String? {
        if hasChildConcernAdditives {
            let count = childWarnings.count
            let names = childWarnings.map { $0.name }.joined(separator: ", ")
            return "Contains \(count) additive\(count == 1 ? "" : "s") that may affect children's activity and attention: \(names)"
        }
        return nil
    }
}

// NEW: Source citation model for ingredients
struct IngredientSource: Codable {
    let title: String
    let url: String
    let covers: String
}

// NEW: Display model for ultra-processed ingredients
struct UltraProcessedIngredientDisplay: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let concerns: String
    let processingPenalty: Int
    let novaGroup: Int
    let sources: [IngredientSource]  // RESTORED: Sources for citations
    let whatItIs: String?
    let whyItsUsed: String?
    let whereItComesFrom: String?
    let eNumbers: [String]  // NEW: For E-number display (supports multiple E-numbers)
}

// NEW: Internal data model for ultra-processed ingredients
struct UltraProcessedIngredientData {
    let name: String
    let synonyms: [String]
    let eNumbers: [String]  // E-numbers array from consolidated database
    let processingPenalty: Int
    let category: String
    let concerns: String
    let novaGroup: Int
    let sources: [IngredientSource]  // RESTORED: Sources for citations
    let what_it_is: String?
    let why_its_used: String?
    let where_it_comes_from: String?
}

struct ProcessingAnalysisResult {
    let score: Int
    let grade: String
    let label: String
    let breakdown: [String: ProcessingCategoryBreakdown]
}

struct AdditiveWarningsResult {
    let childWarnings: [String]
    let pkuWarnings: [String] 
    let sulphiteWarnings: [String]
    let polyolWarnings: [String]
    let regulatoryWarnings: [String]
    let hasRedFlags: Bool
    let overallRisk: String
    let riskExplanation: String
    
    var hasAnyWarnings: Bool {
        return !childWarnings.isEmpty || !pkuWarnings.isEmpty || 
               !sulphiteWarnings.isEmpty || !polyolWarnings.isEmpty || 
               !regulatoryWarnings.isEmpty || hasRedFlags
    }
    
    var totalWarningCount: Int {
        return childWarnings.count + pkuWarnings.count + sulphiteWarnings.count +
               polyolWarnings.count + regulatoryWarnings.count + (hasRedFlags ? 1 : 0)
    }
}

// MARK: - Unified Additive Database Models

struct UnifiedAdditiveDatabase: Codable {
    let metadata: DatabaseMetadata
    let additives: [AdditiveInfo]
}

struct ConsolidatedIngredientsDatabase: Codable {
    let metadata: DatabaseMetadata
    let ingredients: [AdditiveInfo]
}

struct DatabaseMetadata: Codable {
    let version: String
    let total_additives: Int?  // Optional for backward compatibility
    let total_ingredients: Int?  // New field for consolidated database
    let last_updated: String
    let description: String
    let source: String?  // Optional as consolidated DB uses "sources" array
    let sources: [String]?  // Array of source files for consolidated database

    var totalCount: Int {
        return total_ingredients ?? total_additives ?? 0
    }
}

class AdditiveWatchService {
    static let shared = AdditiveWatchService()
    private var additiveDatabase: [AdditiveInfo] = []
    private var isLoaded = false
    
    private init() {
        loadAdditiveDatabase()
    }
    
    private func loadAdditiveDatabase() {
        guard let url = Bundle.main.url(forResource: "ingredients_consolidated", withExtension: "json") else {
            print("❌ Could not find ingredients_consolidated.json")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let ingredients = json["ingredients"] as? [[String: Any]] else {
                print("❌ Could not parse ingredients_consolidated.json")
                return
            }

            // Convert consolidated ingredients to AdditiveInfo format
            // For ingredients with multiple E-numbers, create separate AdditiveInfo entries
            var tempDatabase: [AdditiveInfo] = []

            for ingredientDict in ingredients {
                guard let name = ingredientDict["name"] as? String,
                      let category = ingredientDict["category"] as? String else { continue }

                let eNumbers = ingredientDict["eNumbers"] as? [String] ?? []
                let sourcesArray = ingredientDict["sources"] as? [[String: String]] ?? []
                var sources: [AdditiveSource] = []
                for sourceDict in sourcesArray {
                    if let title = sourceDict["title"],
                       let url = sourceDict["url"],
                       let covers = sourceDict["covers"] {
                        sources.append(AdditiveSource(title: title, url: url, covers: covers))
                    }
                }

                // Extract other fields
                let permittedGB = ingredientDict["isPermittedGB"] as? Bool ?? true
                let permittedNI = ingredientDict["isPermittedNI"] as? Bool ?? true
                let permittedEU = ingredientDict["isPermittedEU"] as? Bool ?? true
                let childWarning = ingredientDict["hasChildWarning"] as? Bool ?? false
                let pkuWarning = ingredientDict["hasPKUWarning"] as? Bool ?? false
                let polyolsWarning = ingredientDict["hasPolyolsWarning"] as? Bool ?? false
                let sulphitesLabel = ingredientDict["hasSulphitesAllergenLabel"] as? Bool ?? false

                let overviewText = ingredientDict["what_it_is"] as? String ?? ingredientDict["overview"] as? String ?? ""
                let usesText = ingredientDict["why_its_used"] as? String ?? ingredientDict["typicalUses"] as? String ?? ""
                let concernsText = ingredientDict["concerns"] as? String ?? ingredientDict["effectsSummary"] as? String ?? ""
                let verdictString = ingredientDict["effectsVerdict"] as? String ?? "neutral"
                let verdict = AdditiveVerdict(rawValue: verdictString) ?? .neutral

                let originString = ingredientDict["origin"] as? String ?? "synthetic"
                let origin = AdditiveOrigin(rawValue: originString) ?? .synthetic
                let group = AdditiveGroup(rawValue: category) ?? .other
                let categ = AdditiveCategory(rawValue: category) ?? .other
                let whereFrom = ingredientDict["where_it_comes_from"] as? String

                // Create ONE entry per ingredient with all E-numbers in the array
                let primaryENumber = eNumbers.first ?? name  // Use first E-number or name as ID
                let additiveInfo = AdditiveInfo(
                    id: primaryENumber,
                    eNumber: primaryENumber,
                    name: name,
                    group: group,
                    isPermittedGB: permittedGB,
                    isPermittedNI: permittedNI,
                    isPermittedEU: permittedEU,
                    statusNotes: nil,
                    hasChildWarning: childWarning,
                    hasPKUWarning: pkuWarning,
                    hasPolyolsWarning: polyolsWarning,
                    hasSulphitesAllergenLabel: sulphitesLabel,
                    category: categ,
                    origin: origin,
                    overview: overviewText,
                    typicalUses: usesText,
                    effectsSummary: concernsText,
                    effectsVerdict: verdict,
                    sources: sources,
                    eNumbers: eNumbers,  // Full array of E-numbers
                    whereItComesFrom: whereFrom
                )
                tempDatabase.append(additiveInfo)
            }

            additiveDatabase = tempDatabase
            isLoaded = true

            print("✅✅✅ CONSOLIDATED INGREDIENTS DATABASE LOADED: \(additiveDatabase.count) additive entries ✅✅✅")

            // Count additives with sources
            let withSources = additiveDatabase.filter { !$0.sources.isEmpty }.count
            let totalSources = additiveDatabase.reduce(0) { $0 + $1.sources.count }
            print("📚 Additives with sources: \(withSources)")
            print("📖 Total source citations: \(totalSources)")

            // Print first few additives for verification
            for (i, additive) in additiveDatabase.prefix(3).enumerated() {
                print("  \(i+1). \(additive.eNumber) - \(additive.name) (\(additive.sources.count) sources)")
            }
        } catch {
            print("❌❌❌ ERROR LOADING CONSOLIDATED INGREDIENTS DATABASE: \(error) ❌❌❌")
        }
    }
    
    // Local helpers for fallback matching
    private func normalizeIngredientTextLocal(_ text: String) -> String {
        let lower = text.lowercased()
        let cleaned = lower.replacingOccurrences(of: "[\\n\\r\\t]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "[\\(\\)\\[\\]\\{\\};:\\\\|/\\\\\\\\]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "[,\\.\\u{00B7}]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\u{00A0}", with: " ")
        return cleaned.replacingOccurrences(of: " +", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func matchesWithWordBoundaryLocal(text: String, pattern: String) -> Bool {
        let escaped = NSRegularExpression.escapedPattern(for: pattern)
        let regexPattern = "(?<![A-Za-z0-9])\(escaped)(?![A-Za-z0-9])"
        guard let regex = try? NSRegularExpression(pattern: regexPattern, options: []) else { return false }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }
    
    func analyzeIngredients(_ ingredients: [String], completion: @escaping (AdditiveDetectionResult) -> Void) {
        // DEBUG LOG: print("🔬 [AdditiveWatchService] Starting local comprehensive additive analysis")
        // DEBUG LOG: print("🔬 [AdditiveWatchService] Input ingredients array: \(ingredients)")
        // DEBUG LOG: print("🔬 [AdditiveWatchService] Ingredients count: \(ingredients.count)")

        let ingredientsText = ingredients.joined(separator: ", ")
        // DEBUG LOG: print("🔬 [AdditiveWatchService] Joined ingredients text: '\(ingredientsText)'")

        // Normalize ingredients text for matching (used by both additive and ultra-processed detection)
        let normalized = normalizeIngredientTextLocal(ingredientsText)

        // Use ProcessingScorer's exposed additive analysis method
        let primaryDetected = ProcessingScorer.shared.analyzeAdditives(in: ingredientsText)
        var finalDetected = primaryDetected

        print("✅ [AdditiveWatchService] Primary analysis complete!")
        print("✅ [AdditiveWatchService] Total additives detected: \(primaryDetected.count)")

        // Fallback: scan CSV database with boundary-aware matching if primary found nothing
        if primaryDetected.isEmpty && isLoaded {
            print("🔁 [AdditiveWatchService] Performing CSV fallback scan")
            var csvMatches: [AdditiveInfo] = []
            var seenCodes = Set<String>()
            for additive in additiveDatabase {
                let code = additive.eNumber.lowercased()
                let name = additive.name.lowercased()
                var matched = false
                if matchesWithWordBoundaryLocal(text: normalized, pattern: code) || matchesWithWordBoundaryLocal(text: normalized, pattern: name) {
                    matched = true
                } else {
                    for syn in additive.synonyms {
                        let term = syn.lowercased()
                        if term.isEmpty { continue }
                        if matchesWithWordBoundaryLocal(text: normalized, pattern: term) {
                            matched = true
                            break
                        }
                    }
                }
                if matched && !seenCodes.contains(additive.eNumber) {
                    csvMatches.append(additive)
                    seenCodes.insert(additive.eNumber)
                }
            }
            print("🔁 [AdditiveWatchService] CSV fallback matches: \(csvMatches.count)")
            finalDetected = csvMatches
        }

        // Extract child warnings
        let childWarnings = finalDetected.filter { $0.hasChildWarning }
        print("✅ [AdditiveWatchService] Child warnings: \(childWarnings.count)")

        // Build result (ultraProcessedIngredients removed - all ingredients now in detectedAdditives)
        let result = AdditiveDetectionResult(
            detectedAdditives: finalDetected,
            childWarnings: childWarnings,
            hasChildConcernAdditives: !childWarnings.isEmpty,
            analysisConfidence: finalDetected.isEmpty ? 0.0 : (primaryDetected.isEmpty ? 0.85 : 0.95),
            processingScore: nil,
            comprehensiveWarnings: nil,
            ultraProcessedIngredients: []  // Empty - using consolidated database only
        )

        // Log detected additives for debugging
        if !finalDetected.isEmpty {
            print("✅ [AdditiveWatchService] Detected additives:")
            for additive in finalDetected {
                print("   - \(additive.eNumber): \(additive.name)")
            }
        } else {
            print("⚠️ [AdditiveWatchService] NO ADDITIVES DETECTED IN SERVICE!")
        }

        DispatchQueue.main.async {
            completion(result)
        }
    }

    // Method to retrieve additive info from CSV database by E-number
    func getAdditiveInfo(eNumber: String) -> AdditiveInfo? {
        return additiveDatabase.first(where: { $0.eNumber == eNumber || $0.id == eNumber })
    }

    // MARK: - Ultra-Processed Ingredients Detection

    private lazy var ultraProcessedDatabase: [String: UltraProcessedIngredientData] = {
        guard let url = Bundle.main.url(forResource: "ingredients_consolidated", withExtension: "json") else {
            print("⚠️ Could not find ingredients_consolidated.json")
            return [:]
        }

        do {
            let data = try Data(contentsOf: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let ingredients = json["ingredients"] as? [[String: Any]] else {
                print("❌ Could not parse ingredients_consolidated.json")
                return [:]
            }

            var database: [String: UltraProcessedIngredientData] = [:]

            // Parse flat list of ingredients
            for ingredientDict in ingredients {
                guard let name = ingredientDict["name"] as? String,
                      let synonyms = ingredientDict["synonyms"] as? [String],
                      let category = ingredientDict["category"] as? String,
                      let concerns = ingredientDict["concerns"] as? String else { continue }

                let sources = (ingredientDict["sources"] as? [[String: String]] ?? []).compactMap { sourceDict -> IngredientSource? in
                    guard let title = sourceDict["title"],
                          let url = sourceDict["url"],
                          let covers = sourceDict["covers"] else { return nil }
                    return IngredientSource(title: title, url: url, covers: covers)
                }

                let eNumbers = ingredientDict["eNumbers"] as? [String] ?? []

                let ingredient = UltraProcessedIngredientData(
                    name: name,
                    synonyms: synonyms,
                    eNumbers: eNumbers,
                    processingPenalty: ingredientDict["processingPenalty"] as? Int ?? 0,
                    category: category,
                    concerns: concerns,
                    novaGroup: ingredientDict["novaGroup"] as? Int ?? 0,
                    sources: sources,
                    what_it_is: ingredientDict["what_it_is"] as? String,
                    why_its_used: ingredientDict["why_its_used"] as? String,
                    where_it_comes_from: ingredientDict["where_it_comes_from"] as? String
                )

                // Store by name
                database[name.lowercased()] = ingredient

                // Store by all synonyms
                for synonym in synonyms {
                    database[synonym.lowercased()] = ingredient
                }
            }

            print("✅ Loaded consolidated ingredients database: \(database.count) entries")
            return database
        } catch {
            print("❌ Error loading consolidated ingredients: \(error)")
            return [:]
        }
    }()

    private func detectUltraProcessedIngredients(from ingredientsText: String, normalized: String) -> [UltraProcessedIngredientDisplay] {
        // Use a dictionary to consolidate duplicates by ingredient name
        var consolidatedIngredients: [String: (ingredient: UltraProcessedIngredientData, eNumbers: Set<String>)] = [:]

        // First pass: detect all matching ingredients and collect their E-numbers
        for (key, ingredient) in ultraProcessedDatabase {
            if matchesWithWordBoundaryLocal(text: normalized, pattern: key) {
                // Extract all E-numbers from synonyms
                let eNumbers = ingredient.synonyms.filter { $0.hasPrefix("E") && $0.count <= 5 }

                if let existing = consolidatedIngredients[ingredient.name] {
                    // Merge E-numbers if we've already seen this ingredient
                    consolidatedIngredients[ingredient.name] = (
                        ingredient: existing.ingredient,
                        eNumbers: existing.eNumbers.union(eNumbers)
                    )
                } else {
                    // First time seeing this ingredient
                    consolidatedIngredients[ingredient.name] = (
                        ingredient: ingredient,
                        eNumbers: Set(eNumbers)
                    )
                }
            }
        }

        // Second pass: create display models with consolidated data
        let detected = consolidatedIngredients.map { (name, data) in
            UltraProcessedIngredientDisplay(
                name: data.ingredient.name,
                category: data.ingredient.category,
                concerns: data.ingredient.concerns,
                processingPenalty: data.ingredient.processingPenalty,
                novaGroup: data.ingredient.novaGroup,
                sources: data.ingredient.sources,
                whatItIs: data.ingredient.what_it_is,
                whyItsUsed: data.ingredient.why_its_used,
                whereItComesFrom: data.ingredient.where_it_comes_from,
                eNumbers: Array(data.eNumbers).sorted()  // Sort E-numbers for consistent display
            )
        }

        return detected
    }

    private func parseProcessingScore(_ processing: [String: Any]?) -> ProcessingAnalysisResult? {
        guard let processing = processing,
              let score = processing["score"] as? Int,
              let grade = processing["grade"] as? String,
              let label = processing["label"] as? String,
              let breakdownData = processing["breakdown"] as? [String: [String: Any]] else {
            return nil
        }
        
        var breakdown: [String: ProcessingCategoryBreakdown] = [:]
        for (category, data) in breakdownData {
            if let count = data["count"] as? Int,
               let score = data["score"] as? Int,
               let details = data["details"] as? [String] {
                breakdown[category] = ProcessingCategoryBreakdown(count: count, score: score, details: details)
            }
        }
        
        return ProcessingAnalysisResult(score: score, grade: grade, label: label, breakdown: breakdown)
    }
    
    private func parseWarnings(_ warnings: [String: Any]?) -> AdditiveWarningsResult? {
        guard let warnings = warnings else { return nil }
        
        return AdditiveWarningsResult(
            childWarnings: warnings["children"] as? [String] ?? [],
            pkuWarnings: warnings["pku"] as? [String] ?? [],
            sulphiteWarnings: warnings["sulphites"] as? [String] ?? [],
            polyolWarnings: warnings["polyols"] as? [String] ?? [],
            regulatoryWarnings: warnings["regulatory"] as? [String] ?? [],
            hasRedFlags: warnings["hasRedFlags"] as? Bool ?? false,
            overallRisk: warnings["overallRisk"] as? String ?? "LOW",
            riskExplanation: warnings["riskExplanation"] as? String ?? ""
        )
    }
    
    private func parseEnhancedAdditives(_ additivesData: [[String: Any]]?) -> [AdditiveInfo] {
        guard let additivesData = additivesData else { return [] }
        
        var additives: [AdditiveInfo] = []
        for data in additivesData {
            if let code = data["code"] as? String,
                let name = data["name"] as? String {
                let effectsVerdictString = data["effectsVerdict"] as? String ?? "neutral"
                let verdict: AdditiveVerdict = effectsVerdictString == "avoid" ? .avoid : (effectsVerdictString == "caution" ? .caution : .neutral)
                let groupString = data["group"] as? String ?? "other"
                let group = AdditiveGroup(rawValue: groupString) ?? .other
                let originString = data["origin"] as? String ?? "synthetic"
                let origin = AdditiveOrigin(rawValue: originString) ?? .synthetic
                let synonyms = data["synonyms"] as? [String] ?? []
                let consumerInfo = data["consumerInfo"] as? String
                let typicalUses = data["typicalUses"] as? String ?? ""
                let overview = data["overview"] as? String ?? ""
                let effectsSummary = data["effectsSummary"] as? String ?? ""
                let hasChildWarning = data["hasChildWarning"] as? Bool ?? false
                let insNumber = data["insNumber"] as? String
                let statusNotes = data["statusNotes"] as? String
                let isPermittedGB = data["isPermittedGB"] as? Bool ?? true
                let isPermittedNI = data["isPermittedNI"] as? Bool ?? true
                let isPermittedEU = data["isPermittedEU"] as? Bool ?? true
                
                let additive = AdditiveInfo(
                    id: code,
                    eNumber: code,
                    name: name,
                    group: group,
                    isPermittedGB: isPermittedGB,
                    isPermittedNI: isPermittedNI,
                    isPermittedEU: isPermittedEU,
                    statusNotes: statusNotes,
                    hasChildWarning: hasChildWarning,
                    hasPKUWarning: false,
                    hasPolyolsWarning: false,
                    hasSulphitesAllergenLabel: false,
                    category: .other,
                    origin: origin,
                    overview: overview,
                    typicalUses: typicalUses,
                    effectsSummary: effectsSummary,
                    effectsVerdict: verdict,
                    synonyms: synonyms,
                    insNumber: insNumber,
                    sources: [],
                    consumerInfo: consumerInfo
                )
                additives.append(additive)
            }
        }
        
        return additives
    }
    
    private func parseCSV(_ content: String) -> [AdditiveInfo] {
        let lines = content.components(separatedBy: .newlines)
        guard lines.count > 2 else { return [] }
        // Skip table name row and header row
        let dataLines = Array(lines[2...]).filter { !$0.isEmpty }
        var additives: [AdditiveInfo] = []
        for line in dataLines {
            if let additive = parseCSVLine(line) {
                additives.append(additive)
            }
        }
        return additives
    }
    
    private func parseCSVLine(_ line: String) -> AdditiveInfo? {
        let components = parseCSVComponents(line)
        guard components.count >= 16 else {
            print("❌ CSV line has \(components.count) components, need at least 16. Line: \(line.prefix(100))")
            return nil
        }

        // Debug logging for E451 specifically
        if components[0] == "E451" {
            print("🔍 [CSV Parser] E451 has \(components.count) components")
            if components.count > 19 {
                print("🔍 [CSV Parser] Component 19 (sources field): \(components[19].prefix(200))")
            } else {
                print("❌ [CSV Parser] E451 doesn't have component 19! Only \(components.count) components")
            }
        }

        let rawSynonyms = components.count > 16 ? components[16].split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) } : []
        let synonyms = cleanSynonyms(rawSynonyms, eNumber: components[0])

        // Parse sources from column 19 (index 19) if available
        let sources = components.count > 19 ? parseSources(components[19]) : []

        if sources.isEmpty && components.count > 19 {
            print("⚠️ [AdditiveDB] No sources found for \(components[0]) - \(components[1])")
        } else if !sources.isEmpty && components[0] == "E451" {
            print("✅ [CSV Parser] E451 parsed \(sources.count) sources successfully!")
        }

        return AdditiveInfo(
            id: components[0],
            eNumber: components[0],
            name: components[1],
            group: AdditiveGroup(rawValue: components[2].lowercased()) ?? .other,
            isPermittedGB: components[3] == "TRUE",
            isPermittedNI: components[4] == "TRUE",
            isPermittedEU: components[5] == "TRUE",
            statusNotes: components[6].isEmpty ? nil : components[6],
            hasChildWarning: components[7] == "TRUE",
            hasPKUWarning: components[8] == "TRUE",
            hasPolyolsWarning: components[9] == "TRUE",
            hasSulphitesAllergenLabel: components[10] == "TRUE",
            category: AdditiveCategory(rawValue: components[2].lowercased()) ?? .other,
            origin: AdditiveOrigin(rawValue: components[11].lowercased()) ?? .synthetic,
            overview: components[12],
            typicalUses: components[13],
            effectsSummary: components[14],
            effectsVerdict: AdditiveVerdict(rawValue: components[15].lowercased()) ?? .neutral,
            synonyms: synonyms,
            insNumber: components.count > 18 && !components[18].isEmpty ? components[18] : nil,
            sources: sources,
            consumerInfo: nil
        )
    }

    private func parseSources(_ jsonString: String) -> [AdditiveSource] {
        // Remove surrounding quotes and unescape if needed
        var cleanedJSON = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)

        print("🔍 [AdditiveDB] Parsing sources from: \(jsonString.prefix(100))")

        if cleanedJSON.hasPrefix("\"") && cleanedJSON.hasSuffix("\"") {
            cleanedJSON = String(cleanedJSON.dropFirst().dropLast())
        }

        // Replace escaped quotes
        cleanedJSON = cleanedJSON.replacingOccurrences(of: "\"\"", with: "\"")

        print("🔍 [AdditiveDB] Cleaned JSON: \(cleanedJSON.prefix(100))")

        guard !cleanedJSON.isEmpty,
              let jsonData = cleanedJSON.data(using: .utf8) else {
            print("⚠️ [AdditiveDB] Empty or invalid JSON string")
            return []
        }

        do {
            // Parse as array of dictionaries
            if let sourcesArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: String]] {
                let sources = sourcesArray.compactMap { (dict: [String: String]) -> AdditiveSource? in
                    guard let title = dict["title"], let url = dict["url"] else { return nil }
                    let covers = dict["covers"]  // Optional covers field
                    return AdditiveSource(title: title, url: url, covers: covers)
                }
                print("✅ [AdditiveDB] Parsed \(sources.count) sources successfully")
                return sources
            } else {
                print("⚠️ [AdditiveDB] JSON is not an array of dictionaries")
            }
        } catch {
            print("❌ [AdditiveDB] JSON parsing error: \(error.localizedDescription)")
        }

        return []
    }
    
    private func cleanSynonyms(_ rawSynonyms: [String], eNumber: String) -> [String] {
        let blacklist = ["red","yellow","blue","green","orange","white","black","brown","pink","purple","color","colour","dye"]
        return rawSynonyms.filter { synonym in
            let lower = synonym.lowercased()
            if lower.starts(with: "e") || lower.starts(with: "ins") { return true }
            if lower.contains(" ") { return true }
            if blacklist.contains(lower) {
                print("🧹 Filtered out generic synonym '\(synonym)' for \(eNumber)")
                return false
            }
            return true
        }
    }
    
    private func parseOrigin(_ originString: String) -> AdditiveOrigin {
        switch originString.lowercased() {
        case "synthetic": return .synthetic
        case "plant": return .plant
        case "animal": return .animal
        case "mineral": return .mineral
        default: return .syntheticPlantMineral
        }
    }
    
    private func parseCSVComponents(_ line: String) -> [String] {
        var components: [String] = []
        var current = ""
        var inQuotes = false
        var i = line.startIndex

        while i < line.endIndex {
            let char = line[i]

            if inQuotes {
                // We're inside a quoted field
                if char == "\"" {
                    // Check if next char is also a quote (escaped quote)
                    let nextIndex = line.index(after: i)
                    if nextIndex < line.endIndex && line[nextIndex] == "\"" {
                        // This is an escaped quote (""), add one quote to current
                        current.append("\"")
                        i = nextIndex // Skip the second quote
                    } else {
                        // This is the closing quote of the field
                        inQuotes = false
                    }
                } else {
                    // Regular character inside quoted field
                    current.append(char)
                }
            } else {
                // We're outside a quoted field
                if char == "\"" {
                    // Start of a quoted field
                    inQuotes = true
                } else if char == "," {
                    // Field separator
                    components.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                    current = ""
                } else {
                    // Regular character
                    current.append(char)
                }
            }

            i = line.index(after: i)
        }

        // Add the last field
        components.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        return components
    }
}


struct ReferenceFood: Codable {
    let id: String
    let name: String
    let category: String
    let nutritionalInfo: [String: Double]?
}

struct IngredientMapping: Codable {
    let ingredientName: String
    let quidPercentage: Double? // QUID percentage if available
    let estimatedWeight: Double // Weight per 100g of final product
    let matchedReferenceFood: ReferenceFood
    let matchConfidence: Double // 0.0 to 1.0
}


// MARK: - Core Food Models needed by FirebaseManager

struct PendingFoodVerification: Identifiable, Codable {
    enum VerificationStatus: String, Codable {
        case pending
        case approved
        case rejected
    }

    let id: String
    let foodName: String
    let brandName: String?
    let ingredients: String?
    let submittedAt: Date
    let status: VerificationStatus
    let userId: String
}

struct SafeFood: Identifiable, Codable {
    let id: UUID
    let foodName: String
    let brandName: String?
    let ingredients: [String]?
    let addedAt: Date

    init(id: UUID = UUID(), foodName: String, brandName: String? = nil, ingredients: [String]? = nil, addedAt: Date = Date()) {
        self.id = id
        self.foodName = foodName
        self.brandName = brandName
        self.ingredients = ingredients
        self.addedAt = addedAt
    }

    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "foodName": foodName,
            "brandName": brandName ?? "",
            "ingredients": (ingredients ?? []).joined(separator: ", "),
            "addedAt": FirebaseFirestore.Timestamp(date: addedAt)
        ]
    }
}


// Additive purpose and rating enums used by FoodAdditive
enum AdditivePurpose: String, Codable, CaseIterable {
    case colour
    case preservative
    case antioxidant
    case emulsifier
    case stabilizer
    case thickener
    case sweetener
    case flavourEnhancer
    case acidRegulator
    case anticaking
    case other
}

enum AdditiveRating: String, Codable, CaseIterable {
    case safe
    case caution
    case avoid
}

