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

enum Allergen: String, CaseIterable, Identifiable, Codable {
    // UK/EU 14 Allergens
    case gluten = "gluten"
    case dairy = "dairy"
    case eggs = "eggs"
    case fish = "fish"
    case shellfish = "shellfish"
    case treeNuts = "treeNuts"
    case peanuts = "peanuts"
    case wheat = "wheat"
    case soy = "soy"
    case sesame = "sesame"
    case celery = "celery"
    case mustard = "mustard"
    case lupin = "lupin"
    case molluscs = "molluscs"
    case sulfites = "sulfites"

    // Additional common allergens/sensitivities
    case lactose = "lactose"
    case msg = "msg"
    case corn = "corn"
    case nightshades = "nightshades"
    case histamines = "histamines"
    case caffeine = "caffeine"
    case alcohol = "alcohol"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gluten: return "Gluten"
        case .dairy: return "Dairy"
        case .eggs: return "Eggs"
        case .fish: return "Fish"
        case .shellfish: return "Shellfish"
        case .treeNuts: return "Tree Nuts"
        case .peanuts: return "Peanuts"
        case .wheat: return "Wheat"
        case .soy: return "Soy"
        case .sesame: return "Sesame"
        case .celery: return "Celery"
        case .mustard: return "Mustard"
        case .lupin: return "Lupin"
        case .molluscs: return "Molluscs"
        case .sulfites: return "Sulphites"
        case .lactose: return "Lactose"
        case .msg: return "MSG"
        case .corn: return "Corn"
        case .nightshades: return "Nightshades"
        case .histamines: return "Histamines"
        case .caffeine: return "Caffeine"
        case .alcohol: return "Alcohol"
        }
    }

    var icon: String {
        switch self {
        case .gluten: return "🍞"
        case .dairy: return "🥛"
        case .eggs: return "🥚"
        case .fish: return "🐟"
        case .shellfish: return "🦐"
        case .treeNuts: return "🌰"
        case .peanuts: return "🥜"
        case .wheat: return "🌾"
        case .soy: return "🫘"
        case .sesame: return "🫰"
        case .celery: return "🥬"
        case .mustard: return "🟡"
        case .lupin: return "🌼"
        case .molluscs: return "🦪"
        case .sulfites: return "🍷"
        case .lactose: return "🥛"
        case .msg: return "🧂"
        case .corn: return "🌽"
        case .nightshades: return "🍆"
        case .histamines: return "⚠️"
        case .caffeine: return "☕"
        case .alcohol: return "🍺"
        }
    }
    
    // Common ingredient keywords that contain this allergen
    var keywords: [String] {
        switch self {
        case .dairy:
            // Note: Specific cheese names handled by AllergenDetector.containsDairyMilk()
            return ["milk", "cream", "butter", "cheese", "yogurt", "whey", "casein", "lactose", "ghee", "custard", "ice cream"]
        case .eggs:
            return [
                "egg", "albumin", "mayonnaise", "meringue", "ovalbumin", "lecithin", "lysozyme",
                "quiche", "frittata", "omelette", "omelet", "brioche", "challah", "hollandaise",
                "béarnaise", "bearnaise", "aioli", "carbonara", "pavlova", "soufflé", "souffle",
                "custard", "eggnog", "french toast", "scotch egg", "egg fried rice"
            ]
        case .fish:
            return [
                // Generic terms
                "fish", "fish sauce", "worcestershire", "fish finger", "fish cake", "fish pie",
                // Common fish species
                "salmon", "tuna", "cod", "bass", "trout", "anchovy", "sardine", "mackerel",
                "haddock", "plaice", "pollock", "hake", "monkfish", "halibut", "tilapia",
                "bream", "sole", "herring", "kipper", "whitebait", "pilchard", "sprat",
                "swordfish", "snapper", "grouper", "perch", "catfish", "carp", "pike",
                "eel", "skate", "ray", "dover sole", "lemon sole", "sea bass", "sea bream"
            ]
        case .shellfish:
            return [
                // Crustaceans
                "shrimp", "prawn", "crab", "lobster", "crawfish", "crayfish", "langoustine",
                "king prawn", "tiger prawn", "crab stick", "crab cake",
                // Molluscs (bivalves, gastropods, cephalopods)
                "clam", "mussel", "oyster", "scallop", "cockle", "winkle", "whelk",
                "squid", "calamari", "octopus", "cuttlefish", "abalone", "snail", "escargot"
            ]
        case .treeNuts:
            return [
                // Individual nuts
                "almond", "walnut", "cashew", "pistachio", "pecan", "hazelnut", "filbert",
                "brazil nut", "macadamia", "pine nut", "chestnut", "praline", "gianduja",
                // Nut-based products
                "marzipan", "frangipane", "nougat", "nutella", "nut butter", "almond milk",
                "almond flour", "ground almonds", "flaked almonds", "walnut oil", "hazelnut oil"
            ]
        case .peanuts:
            return [
                "peanut", "groundnut", "arachis", "peanut butter", "peanut oil",
                "satay", "monkey nuts", "peanut flour", "beer nuts"
            ]
        case .wheat:
            return [
                "wheat", "flour", "bread", "pasta", "bulgur", "couscous", "farina",
                "graham", "semolina", "spelt", "kamut", "einkorn", "triticale", "durum",
                "orzo", "farro", "freekeh", "matzo", "matzah", "crouton", "breadcrumb",
                "panko", "batter", "seitan", "naan", "pita", "pitta", "chapati", "roti",
                "croissant", "baguette", "ciabatta", "focaccia", "tortilla"
            ]
        case .soy:
            return [
                "soy", "soya", "tofu", "tempeh", "miso", "shoyu", "tamari", "edamame",
                "soy sauce", "soy milk", "soy protein", "soy lecithin", "natto",
                "textured vegetable protein", "tvp", "soy protein isolate", "soybean oil"
            ]
        case .sesame:
            return [
                "sesame", "tahini", "sesame oil", "sesame seed", "sesamum",
                "hummus", "houmous", "halvah", "halva", "za'atar", "zaatar",
                "gomashio", "goma", "benne seed"
            ]
        case .gluten:
            return [
                "gluten", "wheat", "barley", "rye", "malt", "brewer's yeast", "oats",
                "seitan", "vital wheat gluten", "spelt", "kamut", "triticale", "farro",
                "beer", "lager", "ale", "stout"
            ]
        case .lactose:
            return ["lactose", "milk", "dairy", "whey", "cream", "butter", "cheese"]
        case .sulfites:
            return [
                "sulfite", "sulphite", "sulfur dioxide", "sulphur dioxide",
                "e220", "e221", "e222", "e223", "e224", "e225", "e226", "e227", "e228",
                "metabisulfite", "metabisulphite", "wine", "dried fruit",
                // E150b and E150d are made using sulphite process
                "e150b", "e150d", "caustic sulphite caramel", "sulphite ammonia caramel"
            ]
        case .msg:
            return [
                "monosodium glutamate", "msg", "glutamate", "hydrolyzed protein",
                "yeast extract", "autolyzed yeast", "e621"
            ]
        case .corn:
            return [
                "corn", "maize", "corn syrup", "corn starch", "cornstarch", "cornflour",
                "corn flour", "dextrose", "maltodextrin", "polenta", "grits", "hominy",
                "corn oil", "popcorn", "tortilla chip", "corn chip", "nachos"
            ]
        case .celery:
            return [
                "celery", "celeriac", "celery salt", "celery seed", "celery powder",
                "celery juice", "celery extract"
            ]
        case .mustard:
            return [
                "mustard", "mustard seed", "mustard powder", "mustard oil", "dijon",
                "wholegrain mustard", "english mustard", "french mustard", "mustard flour"
            ]
        case .lupin:
            return [
                "lupin", "lupine", "lupini", "lupin flour", "lupin seed", "lupin bean"
            ]
        case .molluscs:
            return [
                "clam", "mussel", "oyster", "scallop", "cockle", "winkle", "whelk",
                "squid", "calamari", "octopus", "cuttlefish", "abalone", "snail", "escargot"
            ]
        case .nightshades:
            return [
                "tomato", "potato", "eggplant", "aubergine", "bell pepper", "capsicum",
                "paprika", "cayenne", "chili", "chilli", "jalapeño", "habanero"
            ]
        case .histamines:
            return [
                "aged cheese", "fermented", "cured meat", "smoked fish", "sauerkraut",
                "kimchi", "miso", "soy sauce", "vinegar", "alcohol", "wine", "beer"
            ]
        case .caffeine:
            return [
                "caffeine", "coffee", "espresso", "tea", "matcha", "guarana", "cola",
                "energy drink", "chocolate", "cocoa", "cacao"
            ]
        case .alcohol:
            return [
                "alcohol", "wine", "beer", "lager", "ale", "spirits", "vodka", "gin",
                "rum", "whisky", "whiskey", "brandy", "liqueur", "cider"
            ]
        }
    }

    var severity: AllergenSeverity {
        switch self {
        // High: Common severe allergies
        case .dairy, .eggs, .fish, .shellfish, .treeNuts, .peanuts, .molluscs:
            return .high
        // Medium: Common but often less severe
        case .wheat, .soy, .gluten, .celery, .mustard, .lupin:
            return .medium
        // Low: Sensitivities and less common allergens
        case .sesame, .lactose, .sulfites, .msg, .corn, .nightshades, .histamines, .caffeine, .alcohol:
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

    private func matchesWord(_ text: String, _ pattern: String) -> Bool {
        let escaped = NSRegularExpression.escapedPattern(for: pattern.lowercased())
        let regexPattern = "(?<![A-Za-z0-9])\(escaped)(?![A-Za-z0-9])"
        guard let regex = try? NSRegularExpression(pattern: regexPattern, options: []) else { return false }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }

    // MARK: - Free-From Pattern Detection

    /// Patterns that indicate an allergen is ABSENT (e.g., "gluten-free", "free from gluten")
    private func getFreeFromPatterns(for allergen: Allergen) -> [String] {
        let name = allergen.displayName.lowercased()
        return [
            "\(name)-free",
            "\(name) free",
            "free from \(name)",
            "free-from \(name)",
            "no \(name)",
            "without \(name)",
            "\(name) not detected",
            "does not contain \(name)",
            "suitable for \(name)-free",
            "suitable for \(name) free"
        ]
    }

    /// Checks if the text indicates the allergen is explicitly absent (free-from)
    private func isAllergenExplicitlyAbsent(_ allergen: Allergen, in text: String) -> Bool {
        let freeFromPatterns = getFreeFromPatterns(for: allergen)
        return freeFromPatterns.contains { text.contains($0) }
    }

    /// Central method to check if an allergen is present in text (handles free-from patterns)
    /// Use this instead of simple keyword matching to avoid false positives
    func isAllergenPresent(_ allergen: Allergen, in text: String) -> Bool {
        let lowercased = text.lowercased()

        // First check if the allergen is explicitly marked as absent
        if isAllergenExplicitlyAbsent(allergen, in: lowercased) {
            return false
        }

        // Use centralized detection for dairy (handles plant milks correctly)
        if allergen == .dairy {
            return containsDairyMilk(in: lowercased)
        }

        // Check keywords with word boundary matching for accuracy
        return allergen.keywords.contains { keyword in
            matchesWord(lowercased, keyword)
        }
    }

    /// Detects allergens and returns which specific ingredients triggered each one
    /// Returns a dictionary mapping each detected allergen to the keywords that matched
    func detectAllergensWithSources(in text: String, userAllergens: [Allergen]) -> [Allergen: [String]] {
        var result: [Allergen: [String]] = [:]
        let lowercased = text.lowercased()

        for allergen in userAllergens {
            // Skip if allergen is explicitly marked as absent (e.g., "gluten-free")
            if isAllergenExplicitlyAbsent(allergen, in: lowercased) {
                continue
            }

            // Special handling for dairy to avoid false positives with plant milks
            if allergen == .dairy {
                if containsDairyMilk(in: lowercased) {
                    // Find which dairy keywords actually matched
                    let dairyKeywords = allergen.keywords.filter { keyword in
                        matchesWord(lowercased, keyword)
                    }
                    if !dairyKeywords.isEmpty {
                        result[allergen] = dairyKeywords
                    } else {
                        // Dairy detected via special logic, use generic source
                        result[allergen] = ["milk products"]
                    }
                }
                continue
            }

            // Standard allergen detection with source tracking
            let matchingKeywords = allergen.keywords.filter { keyword in
                matchesWord(lowercased, keyword)
            }

            if !matchingKeywords.isEmpty {
                result[allergen] = matchingKeywords
            }
        }

        return result
    }

    func detectAllergens(in foodName: String, ingredients: [String] = [], userAllergens: [Allergen]) -> AllergenDetectionResult {
        let searchText = (foodName + " " + ingredients.joined(separator: " ")).lowercased()
        var detectedAllergens: [Allergen] = []
        var confidence = 0.0
        var warnings: [String] = []

        // Check each user allergen against the food
        for allergen in userAllergens {
            // Skip if allergen is explicitly marked as absent (e.g., "gluten-free")
            if isAllergenExplicitlyAbsent(allergen, in: searchText) {
                continue
            }

            let matchingKeywords = allergen.keywords.filter { keyword in
                matchesWord(searchText, keyword)
            }

            if !matchingKeywords.isEmpty {
                detectedAllergens.append(allergen)
                warnings.append("Contains \(allergen.displayName): \(matchingKeywords.joined(separator: ", "))")

                // Increase confidence based on number of matches (slightly lower weight)
                confidence += Double(matchingKeywords.count) * 0.15
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
            confidence = max(confidence, 0.8)
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
            // General dairy terms
            "dairy","cheese","cream","butter","yogurt","yoghurt","whey","casein","lactose",
            "milk powder","skimmed milk powder","condensed milk","evaporated milk",
            "milk solids","milkfat","whole milk","semi skimmed milk","semi-skimmed milk","skimmed milk",
            "cow milk","cow's milk","goat milk","sheep milk","milk chocolate",
            // Specific cheese names (so "parmesan" is detected even without "cheese" in the name)
            "parmesan","parmigiano","cheddar","mozzarella","brie","camembert","feta","gouda",
            "edam","gruyere","gruyère","emmental","ricotta","mascarpone","gorgonzola","roquefort",
            "stilton","halloumi","haloumi","paneer","cottage cheese","cream cheese","quark",
            "burrata","pecorino","manchego","provolone","fontina","taleggio","asiago","colby",
            "monterey jack","swiss cheese","american cheese","processed cheese","cheese spread",
            "red leicester","wensleydale","lancashire","cheshire","double gloucester",
            "fromage frais","crème fraîche","creme fraiche","sour cream","clotted cream",
            "ghee","buttermilk","kefir","lassi","custard","ice cream","gelato"
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

// MARK: - Additive Key Point with Severity
struct AdditiveKeyPoint: Codable, Hashable {
    let text: String
    let severity: String  // "severe", "high", "medium", "info"

    var color: Color {
        switch severity {
        case "severe": return .red
        case "high": return .orange
        case "medium": return .yellow
        case "info": return .green
        default: return .gray
        }
    }
}

struct AdditiveInfo: Codable, Identifiable {
    var id: String {
        // Generate ID from first E-number if not provided in JSON
        return eNumbers.first ?? name
    }
    var eNumber: String {
        // For backward compatibility - return first E-number from array
        return eNumbers.first ?? ""
    }
    let eNumbers: [String]  // Array of all E-numbers for this ingredient (consolidated database)
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

    // COMPREHENSIVE CONSUMER-FOCUSED FIELDS
    let shortSummary: String?  // Quick 1-2 sentence overview for compact views
    let whatItIs: String?  // Detailed engaging description of what it actually is
    let whereItComesFrom: String?  // Honest origin story (e.g., "crushed beetles", "coal tar")
    let whyItsUsed: String?  // Clear explanation of purpose in food
    let whatYouNeedToKnow: [String]?  // Health-focused bullet points (concerns, warnings, research) - LEGACY
    let keyPoints: [AdditiveKeyPoint]?  // NEW: Severity-coded bullet points
    let fullDescription: String?  // Comprehensive scientific background (collapsed by default in UI)

    // LEGACY FIELDS (for backward compatibility with old database)
    let overview: String?
    let typicalUses: String?
    let effectsSummary: String?

    let effectsVerdict: AdditiveVerdict
    let synonyms: [String]
    let insNumber: String?
    let sources: [AdditiveSource]
    let consumerInfo: String?
    let processingPenalty: Int  // Processing penalty score for ultra-processed ingredients
    let novaGroup: Int  // NOVA classification group (1-4)

    init(eNumbers: [String] = [], name: String, group: AdditiveGroup, isPermittedGB: Bool = true, isPermittedNI: Bool = true, isPermittedEU: Bool = true, statusNotes: String? = nil, hasChildWarning: Bool = false, hasPKUWarning: Bool = false, hasPolyolsWarning: Bool = false, hasSulphitesAllergenLabel: Bool = false, category: AdditiveCategory = .other, origin: AdditiveOrigin = .synthetic, shortSummary: String? = nil, whatItIs: String? = nil, whereItComesFrom: String? = nil, whyItsUsed: String? = nil, whatYouNeedToKnow: [String]? = nil, keyPoints: [AdditiveKeyPoint]? = nil, fullDescription: String? = nil, overview: String? = nil, typicalUses: String? = nil, effectsSummary: String? = nil, effectsVerdict: AdditiveVerdict = .neutral, synonyms: [String] = [], insNumber: String? = nil, sources: [AdditiveSource] = [], consumerInfo: String? = nil, processingPenalty: Int = 0, novaGroup: Int = 0) {
        self.eNumbers = eNumbers
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
        self.shortSummary = shortSummary
        self.whatItIs = whatItIs
        self.whereItComesFrom = whereItComesFrom
        self.whyItsUsed = whyItsUsed
        self.whatYouNeedToKnow = whatYouNeedToKnow
        self.keyPoints = keyPoints
        self.fullDescription = fullDescription
        self.overview = overview
        self.typicalUses = typicalUses
        self.effectsSummary = effectsSummary
        self.effectsVerdict = effectsVerdict
        self.synonyms = synonyms
        self.insNumber = insNumber
        self.sources = sources
        self.consumerInfo = consumerInfo
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

    // Custom decoder to handle unrecognized group values
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        // Map American spellings and unrecognized values
        switch rawValue {
        case "flavor_enhancer":  // American spelling
            self = .flavourEnhancer
        case "bulking_agent", "fat", "protein":  // Missing values -> map to other
            self = .other
        default:
            // Try exact match
            if let group = AdditiveGroup(rawValue: rawValue) {
                self = group
            } else {
                // Default to other for any unrecognized value
                self = .other
            }
        }
    }

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
    case sweetener = "sweetener"
    case other = "other"

    // Custom decoder to handle unrecognized category values (antioxidant, emulsifier, etc.)
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        // Try to match existing cases
        if let category = AdditiveCategory(rawValue: rawValue) {
            self = category
        } else {
            // Default to "other" for unrecognized categories
            // (e.g., antioxidant, bulking_agent, emulsifier, fat, flavor_enhancer, protein, thickener)
            self = .other
        }
    }
}

enum AdditiveOrigin: String, Codable {
    case synthetic = "synthetic"
    case plant = "plant"
    case animal = "animal"
    case mineral = "mineral"
    case syntheticPlantMineral = "synthetic/plant/mineral (varies by specification)"
    case unknown = "unknown"  // For empty or unrecognized origin strings

    // Custom decoder to handle empty strings and invalid values
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        // Handle empty string or whitespace-only strings
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            self = .unknown
            return
        }

        // Try to match existing cases
        if let origin = AdditiveOrigin(rawValue: trimmed) {
            self = origin
        } else {
            // Default to unknown for unrecognized values
            self = .unknown
        }
    }

    var displayName: String {
        switch self {
        case .synthetic: return "Synthetic"
        case .plant: return "Plant-based"
        case .animal: return "Animal-based"
        case .mineral: return "Mineral"
        case .syntheticPlantMineral: return "Various sources"
        case .unknown: return "Unknown origin"
        }
    }

    var icon: String {
        switch self {
        case .synthetic: return "⚗️"
        case .plant: return "🌱"
        case .animal: return "🐄"
        case .mineral: return "⛰️"
        case .syntheticPlantMineral: return "🔄"
        case .unknown: return "❓"
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
        // Try to load comprehensive database first, fall back to legacy consolidated database
        let databaseName = Bundle.main.url(forResource: "ingredients_comprehensive", withExtension: "json") != nil
            ? "ingredients_comprehensive"
            : "ingredients_consolidated"

        guard let url = Bundle.main.url(forResource: databaseName, withExtension: "json") else {
            print("❌ No additive database found")
            return
        }

        print("📚 Loading additive database: \(databaseName).json")

        do {
            // NOTE: Synchronous file I/O is acceptable here because:
            // 1. This is called only once during singleton initialization
            // 2. It happens before any UI is displayed (during app launch)
            // 3. The file is in the app bundle (fast local read, not network)
            // 4. Moving to async would require restructuring callers with no benefit
            let data = try Data(contentsOf: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let ingredients = json["ingredients"] as? [[String: Any]] else {
                print("❌ Failed to parse additive database JSON")
                return
            }

            // Convert ingredients to AdditiveInfo format
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

                // Parse comprehensive fields (new format)
                let shortSummary = ingredientDict["shortSummary"] as? String
                let whatItIs = ingredientDict["whatItIs"] as? String
                let whereItComesFrom = ingredientDict["whereItComesFrom"] as? String
                let whyItsUsed = ingredientDict["whyItsUsed"] as? String
                let whatYouNeedToKnow = ingredientDict["whatYouNeedToKnow"] as? [String]
                let fullDescription = ingredientDict["fullDescription"] as? String

                // Parse legacy fields (old format) - fallback if comprehensive fields not present
                let overviewText = ingredientDict["what_it_is"] as? String ?? ingredientDict["overview"] as? String
                let usesText = ingredientDict["why_its_used"] as? String ?? ingredientDict["typicalUses"] as? String
                let concernsText = ingredientDict["concerns"] as? String ?? ingredientDict["effectsSummary"] as? String

                let verdictString = ingredientDict["effectsVerdict"] as? String ?? "neutral"
                let verdict = AdditiveVerdict(rawValue: verdictString) ?? .neutral

                let originString = ingredientDict["origin"] as? String ?? "synthetic"
                let origin = AdditiveOrigin(rawValue: originString) ?? .synthetic
                let group = AdditiveGroup(rawValue: category) ?? .other
                let categ = AdditiveCategory(rawValue: category) ?? .other

                // Create ONE entry per ingredient with all E-numbers in the array
                let additiveInfo = AdditiveInfo(
                    eNumbers: eNumbers,  // Full array of E-numbers
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
                    shortSummary: shortSummary,
                    whatItIs: whatItIs,
                    whereItComesFrom: whereItComesFrom,
                    whyItsUsed: whyItsUsed,
                    whatYouNeedToKnow: whatYouNeedToKnow,
                    fullDescription: fullDescription,
                    overview: overviewText,
                    typicalUses: usesText,
                    effectsSummary: concernsText,
                    effectsVerdict: verdict,
                    sources: sources
                )
                tempDatabase.append(additiveInfo)
            }

            additiveDatabase = tempDatabase
            isLoaded = true
        } catch {
                    }
    }
    
    // Local helpers for fallback matching
    private func normalizeIngredientTextLocal(_ text: String) -> String {
        var lower = text.lowercased()

        // CRITICAL FIX: Convert bare numeric codes to E-numbers BEFORE stripping punctuation
        // Many ingredient lists use "(330, 331)" instead of "(E330, E331)"
        // e.g., "Colours (171, 102, 129)" → "Colours (e171, e102, e129)"
        // e.g., "Food acids (330, 331)" → "Food acids (e330, e331)"
        if let regex = try? NSRegularExpression(pattern: "(?<=[(,\\.\\s])([0-9]{3,4})(?=[),\\.\\s])", options: []) {
            let range = NSRange(lower.startIndex..., in: lower)
            lower = regex.stringByReplacingMatches(in: lower, options: [], range: range, withTemplate: "e$1")
        }

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

        let ingredientsText = ingredients.joined(separator: ", ")

        // Normalize ingredients text for matching (used by both additive and ultra-processed detection)
        let normalized = normalizeIngredientTextLocal(ingredientsText)

        // Use ProcessingScorer's exposed additive analysis method
        let primaryDetected = ProcessingScorer.shared.analyzeAdditives(in: ingredientsText)
        var finalDetected = primaryDetected

                if isLoaded {
            var csvMatches: [AdditiveInfo] = []
            var seenCodes = Set<String>(finalDetected.map { $0.eNumber })
            for additive in additiveDatabase {
                let code = additive.eNumber.lowercased()
                let name = additive.name.lowercased()
                var matched = false

                // Check E-number first (skip if empty to prevent false positives)
                if !code.isEmpty && matchesWithWordBoundaryLocal(text: normalized, pattern: code) {
                    matched = true
                } else if !name.isEmpty && matchesWithWordBoundaryLocal(text: normalized, pattern: name) {
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
            if !csvMatches.isEmpty {
                finalDetected.append(contentsOf: csvMatches)
            }
        }

        // Extract child warnings
        let childWarnings = finalDetected.filter { $0.hasChildWarning }
                let result = AdditiveDetectionResult(
            detectedAdditives: finalDetected,
            childWarnings: childWarnings,
            hasChildConcernAdditives: !childWarnings.isEmpty,
            analysisConfidence: finalDetected.isEmpty ? 0.0 : (primaryDetected.isEmpty ? 0.85 : 0.95),
            processingScore: nil,
            comprehensiveWarnings: nil,
            ultraProcessedIngredients: []  // Empty - using consolidated database only
        )

        DispatchQueue.main.async {
            completion(result)
        }
    }

    // Method to retrieve additive info from CSV database by E-number
    func getAdditiveInfo(eNumber: String) -> AdditiveInfo? {
        return additiveDatabase.first(where: { $0.eNumber == eNumber || $0.id == eNumber })
    }

    // MARK: - Ultra-Processed Ingredients Detection

    // NOTE: Lazy initialization with synchronous file I/O is acceptable here because:
    // 1. This is lazily loaded only when first needed (not at app startup)
    // 2. The file is in the app bundle (fast local read, not network)
    // 3. It happens on the same thread that's already doing additive detection work
    private lazy var ultraProcessedDatabase: [String: UltraProcessedIngredientData] = {
        guard let url = Bundle.main.url(forResource: "ingredients_consolidated", withExtension: "json") else {
                        return [:]
        }

        do {
            let data = try Data(contentsOf: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let ingredients = json["ingredients"] as? [[String: Any]] else {
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

                        return database
        } catch {
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
                    eNumbers: [code],
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

        // Require minimum 16 columns for all required fields (indices 0-15)
        guard components.count >= 16 else {
                        return nil
        }

        // Safety: Verify we can safely access all required indices
        guard components.indices.contains(15) else {
                        return nil
        }

        // Debug logging for E451 specifically
        if components[0] == "E451" {
                        if components.count > 19 {
                            } else {
                            }
        }

        let rawSynonyms = components.count > 16 ? components[16].split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) } : []
        let synonyms = cleanSynonyms(rawSynonyms, eNumber: components[0])

        // Parse sources from column 19 (index 19) if available
        let sources = components.count > 19 ? parseSources(components[19]) : []

        if sources.isEmpty && components.count > 19 {
                    } else if !sources.isEmpty && components[0] == "E451" {
                    }

        return AdditiveInfo(
            eNumbers: [components[0]],
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

                if cleanedJSON.hasPrefix("\"") && cleanedJSON.hasSuffix("\"") {
            cleanedJSON = String(cleanedJSON.dropFirst().dropLast())
        }

        // Replace escaped quotes
        cleanedJSON = cleanedJSON.replacingOccurrences(of: "\"\"", with: "\"")

                guard !cleanedJSON.isEmpty,
              let jsonData = cleanedJSON.data(using: .utf8) else {
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
                                return sources
            } else {
                            }
        } catch {
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
