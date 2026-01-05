//
//  AdditiveAnalysisViews.swift
//  NutraSafe Beta
//
//  Comprehensive Additive Analysis System
//  Components extracted from ContentView.swift to improve code organization
//

import SwiftUI
import Foundation
import UIKit

// MARK: - Shared additive overrides (friendly names/descriptions)

struct AdditiveOverrideData {
    let displayName: String?
    let whatItIs: String?
    let originSummary: String?
    let riskSummary: String?
}

enum AdditiveOverrides {
    // Lookup by lowercase E-number or name
    private static let overrides: [String: AdditiveOverrideData] = [
        // Vitamins / fortification
        "e300": .init(displayName: "Vitamin C (Ascorbic acid)", whatItIs: "Essential vitamin C antioxidant that stops foods turning brown or stale.", originSummary: "Typically synthesised for food use or from fermentation.", riskSummary: "Generally recognised as safe at permitted levels."),
        "ascorbic acid": .init(displayName: "Vitamin C (Ascorbic acid)", whatItIs: "Essential vitamin C antioxidant that stops foods turning brown or stale.", originSummary: "Typically synthesised for food use or from fermentation.", riskSummary: "Generally recognised as safe at permitted levels."),
        "e375": .init(displayName: "Vitamin B3 (Nicotinic acid)", whatItIs: "Essential B vitamin (niacin) added to fortified foods to prevent deficiency.", originSummary: "Usually synthesised for fortification.", riskSummary: "High supplement doses may cause flushing; food levels are safe."),
        "nicotinic acid": .init(displayName: "Vitamin B3 (Nicotinic acid)", whatItIs: "Essential B vitamin (niacin) added to fortified foods to prevent deficiency.", originSummary: "Usually synthesised for fortification.", riskSummary: "High supplement doses may cause flushing; food levels are safe."),
        "e101": .init(displayName: "Vitamin B2 (Riboflavin)", whatItIs: "Vitamin B2 used as a yellow-orange colour and nutrient.", originSummary: "Produced via fermentation or synthetic routes.", riskSummary: "Essential vitamin; generally safe."),
        "riboflavin": .init(displayName: "Vitamin B2 (Riboflavin)", whatItIs: "Vitamin B2 used as a yellow-orange colour and nutrient.", originSummary: "Produced via fermentation or synthetic routes.", riskSummary: "Essential vitamin; generally safe."),
        "e160a": .init(displayName: "Beta-carotene (Provitamin A)", whatItIs: "Natural orange pigment that the body can convert to vitamin A.", originSummary: "Usually from plant sources like carrots or algae; sometimes synthetic.", riskSummary: "Generally safe; very high doses may tint skin."),
        "beta-carotene": .init(displayName: "Beta-carotene (Provitamin A)", whatItIs: "Natural orange pigment that the body can convert to vitamin A.", originSummary: "Usually from plant sources like carrots or algae; sometimes synthetic.", riskSummary: "Generally safe; very high doses may tint skin."),
        "e306": .init(displayName: "Vitamin E (Mixed tocopherols)", whatItIs: "Vitamin E antioxidants that protect fats from going rancid.", originSummary: "Commonly from vegetable oils or produced by purification.", riskSummary: "Generally recognised as safe at food levels."),
        "e307": .init(displayName: "Vitamin E (Alpha-tocopherol)", whatItIs: "Vitamin E antioxidant that protects fats from oxidation.", originSummary: "Usually from vegetable oils or synthetic.", riskSummary: "Generally recognised as safe at food levels."),
        "e308": .init(displayName: "Vitamin E (Gamma-tocopherol)", whatItIs: "Vitamin E antioxidant that protects fats from oxidation.", originSummary: "Usually from vegetable oils or synthetic.", riskSummary: "Generally recognised as safe at food levels."),
        "e309": .init(displayName: "Vitamin E (Delta-tocopherol)", whatItIs: "Vitamin E antioxidant that protects fats from oxidation.", originSummary: "Usually from vegetable oils or synthetic.", riskSummary: "Generally recognised as safe at food levels."),

        // Sweeteners
        "e951": .init(displayName: "Aspartame", whatItIs: "Intense low-calorie sweetener used in drinks and diet foods.", originSummary: "Synthetic.", riskSummary: "Not suitable for people with PKU; otherwise permitted within limits."),
        "e950": .init(displayName: "Acesulfame K", whatItIs: "Intense zero-calorie sweetener often blended with others.", originSummary: "Synthetic.", riskSummary: "Permitted within limits; can leave a bitter aftertaste."),
        "e955": .init(displayName: "Sucralose", whatItIs: "High-intensity sweetener about 600x sweeter than sugar.", originSummary: "Synthetic (modified sucrose).", riskSummary: "Permitted within limits; generally well tolerated."),
        "e954": .init(displayName: "Saccharin", whatItIs: "Zero-calorie sweetener used in diet products.", originSummary: "Synthetic.", riskSummary: "Permitted within limits; can taste metallic at high levels."),
        "e960": .init(displayName: "Steviol glycosides (Stevia)", whatItIs: "Plant-based zero-calorie sweetener from stevia leaves.", originSummary: "Plant-derived then purified.", riskSummary: "Generally well tolerated at permitted levels."),
        "e420": .init(displayName: "Sorbitol", whatItIs: "Sugar alcohol sweetener and humectant.", originSummary: "Typically from glucose hydrogenation (plant origin).", riskSummary: "Excess can cause laxative effects."),
        "e421": .init(displayName: "Mannitol", whatItIs: "Sugar alcohol sweetener and bulking agent.", originSummary: "Typically produced from fructose (plant origin).", riskSummary: "Excess can cause laxative effects."),
        "e965": .init(displayName: "Maltitol", whatItIs: "Sugar alcohol sweetener used in sugar-free confectionery.", originSummary: "Made from maltose (starch).", riskSummary: "Excess can cause laxative effects."),
        "e967": .init(displayName: "Xylitol", whatItIs: "Sugar alcohol sweetener often used in gum.", originSummary: "Usually from birch or corn.", riskSummary: "Excess can cause laxative effects; toxic to dogs."),
        "e968": .init(displayName: "Erythritol", whatItIs: "Low-calorie sugar alcohol sweetener.", originSummary: "Made via fermentation of plant sugars.", riskSummary: "Generally well tolerated; large amounts may cause mild GI upset."),

        // Preservatives / acids
        "e211": .init(displayName: "Sodium benzoate", whatItIs: "Preservative that stops moulds and yeasts.", originSummary: "Synthetic.", riskSummary: "Generally recognised as safe; avoid pairing with vitamin C at high heat to minimise benzene formation."),
        "e202": .init(displayName: "Potassium sorbate", whatItIs: "Preservative that prevents mould and yeast growth.", originSummary: "Synthetic (salt of sorbic acid).", riskSummary: "Generally recognised as safe at permitted levels."),
        "e200": .init(displayName: "Sorbic acid", whatItIs: "Preservative that prevents mould and yeast growth.", originSummary: "Synthetic or from rowan berries originally.", riskSummary: "Generally recognised as safe at permitted levels."),
        "e223": .init(displayName: "Sodium metabisulfite", whatItIs: "Preservative and antioxidant.", originSummary: "Synthetic.", riskSummary: "Can trigger reactions in sulphite-sensitive individuals."),
        "e220": .init(displayName: "Sulphur dioxide", whatItIs: "Preservative and antioxidant.", originSummary: "Synthetic gas used in winemaking and dried fruits.", riskSummary: "Can trigger reactions in sulphite-sensitive individuals."),
        "e250": .init(displayName: "Sodium nitrite", whatItIs: "Curing salt for processed meats; prevents botulism and sets colour.", originSummary: "Synthetic.", riskSummary: "Forms nitrosamines at high heat; eat cured meats in moderation."),
        "e251": .init(displayName: "Sodium nitrate", whatItIs: "Curing salt precursor used in some meats.", originSummary: "Synthetic.", riskSummary: "Converted to nitrite in the body; cured meats best in moderation."),
        "e200-e203": .init(displayName: "Sorbates (preservatives)", whatItIs: "Group of mould/yeast inhibitors used in baked goods and cheese.", originSummary: "Synthetic.", riskSummary: "Generally recognised as safe at permitted levels."),
        "e338": .init(displayName: "Phosphoric acid", whatItIs: "Acidulant for tangy taste and pH control in colas and foods.", originSummary: "Synthetic.", riskSummary: "High intake may affect tooth enamel; acceptable at food levels."),
        "e330": .init(displayName: "Citric acid", whatItIs: "Natural-tasting acid that adds tartness and preserves freshness.", originSummary: "Usually produced via fermentation from sugar sources.", riskSummary: "Generally safe; large amounts can irritate sensitive mouths."),
        "e300-e304": .init(displayName: "Vitamin C antioxidants", whatItIs: "Antioxidants that prevent browning and rancidity.", originSummary: "Typically synthesised for food use or from fermentation.", riskSummary: "Generally recognised as safe at permitted levels."),

        // Colours
        "e102": .init(displayName: "Tartrazine", whatItIs: "Synthetic yellow azo dye used in drinks and snacks.", originSummary: "Synthetic.", riskSummary: "May affect sensitive children; some people avoid it."),
        "e110": .init(displayName: "Sunset Yellow", whatItIs: "Synthetic orange azo dye used in beverages and sweets.", originSummary: "Synthetic.", riskSummary: "May affect sensitive children; some people avoid it."),
        "e129": .init(displayName: "Allura Red", whatItIs: "Synthetic red dye used in drinks and confectionery.", originSummary: "Synthetic.", riskSummary: "May affect sensitive children; some people avoid it."),
        "e133": .init(displayName: "Brilliant Blue", whatItIs: "Synthetic blue dye used in confectionery and drinks.", originSummary: "Synthetic.", riskSummary: "Permitted within limits; may affect sensitive individuals."),
        "e104": .init(displayName: "Quinoline Yellow", whatItIs: "Synthetic yellow dye used in desserts and snacks.", originSummary: "Synthetic.", riskSummary: "May affect sensitive children; some people avoid it."),

        // Emulsifiers / thickeners / gums
        "e322": .init(displayName: "Lecithin", whatItIs: "Emulsifier that helps oil and water stay mixed.", originSummary: "Usually from soy or sunflower; sometimes egg.", riskSummary: "Generally recognised as safe at food levels."),
        "lecithin": .init(displayName: "Lecithin", whatItIs: "Emulsifier that helps oil and water stay mixed.", originSummary: "Usually from soy or sunflower; sometimes egg.", riskSummary: "Generally recognised as safe at food levels."),
        "e466": .init(displayName: "Cellulose gum (CMC)", whatItIs: "Thickener and stabiliser for texture and moisture retention.", originSummary: "Derived from plant cellulose.", riskSummary: "Generally recognised as safe at food levels."),
        "e415": .init(displayName: "Xanthan gum", whatItIs: "Fermentation-derived gum used to thicken and stabilise.", originSummary: "Produced by fermenting sugars.", riskSummary: "Generally safe; large amounts may cause gas in sensitive people."),
        "e412": .init(displayName: "Guar gum", whatItIs: "Plant-based thickener and stabiliser.", originSummary: "From guar bean seeds.", riskSummary: "Generally safe; very high doses can cause bloating."),
        "e407": .init(displayName: "Carrageenan", whatItIs: "Seaweed-derived thickener and stabiliser.", originSummary: "Extracted from red seaweed.", riskSummary: "Food-grade carrageenan is permitted; some people with sensitive guts prefer to limit it."),

        // Flavour enhancers
        "e621": .init(displayName: "MSG (Monosodium glutamate)", whatItIs: "Umami flavour enhancer.", originSummary: "Produced by fermenting plant sugars/starches.", riskSummary: "Considered safe; a small subset reports sensitivity."),
        "monosodium glutamate": .init(displayName: "MSG (Monosodium glutamate)", whatItIs: "Umami flavour enhancer.", originSummary: "Produced by fermenting plant sugars/starches.", riskSummary: "Considered safe; a small subset reports sensitivity."),

        // Antioxidants
        "e320": .init(displayName: "BHA", whatItIs: "Antioxidant that prevents fats from going rancid.", originSummary: "Synthetic.", riskSummary: "Permitted within limits; monitored by regulators."),
        "e321": .init(displayName: "BHT", whatItIs: "Antioxidant that prevents fats from going rancid.", originSummary: "Synthetic.", riskSummary: "Permitted within limits; monitored by regulators."),

        // Misc
        "e570": .init(displayName: "Fatty acids", whatItIs: "Purified fatty acids used as a processing aid or anti-caking agent.", originSummary: "Varied origin (plant or animal fats).", riskSummary: "Generally recognised as safe at permitted food use levels."),
        "fatty acids": .init(displayName: "Fatty acids", whatItIs: "Purified fatty acids used as a processing aid or anti-caking agent.", originSummary: "Varied origin (plant or animal fats).", riskSummary: "Generally recognised as safe at permitted food use levels."),
        "caffeine": .init(displayName: "Caffeine", whatItIs: "Stimulant naturally found in coffee, tea, and added to energy drinks.", originSummary: "Natural or synthetic.", riskSummary: "Can affect sleep and heart rate; limit if sensitive.")
    ]

    static func override(for additive: AdditiveInfo) -> AdditiveOverrideData? {
        for code in additive.eNumbers {
            if let match = overrides[code.lowercased()] {
                return match
            }
        }
        return overrides[additive.name.lowercased()]
    }
}

// MARK: - Additive Analysis Component

struct AdditiveWatchView: View {
    let ingredients: [String]
    @Environment(\.colorScheme) var colorScheme
    @State private var additiveResult: AdditiveDetectionResult?
    @State private var showingSources = false
    @State private var lastAnalyzedHash: Int = 0

    // Check if ingredients contain meaningful data (not just empty strings)
    private var hasMeaningfulIngredients: Bool {
        let clean = ingredients
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return !clean.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Check if ingredients contain meaningful data
            if !hasMeaningfulIngredients {
                emptyIngredientsContent
                    .transition(.opacity)
            } else if let result = additiveResult {
                additiveContent(result: result)
                    .transition(.opacity)
            } else {
                loadingContent
                    .frame(minHeight: 100)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.3), value: additiveResult != nil)
        .sheet(isPresented: $showingSources) {
            SourcesAndCitationsView()
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(.systemBackground))
        }
        .onAppear {
            // Only analyze if we have meaningful ingredients
            if hasMeaningfulIngredients {
                // PERFORMANCE: Only re-analyze if ingredients have changed
                let currentHash = ingredients.hashValue
                if additiveResult == nil || lastAnalyzedHash != currentHash {
                    lastAnalyzedHash = currentHash
                    analyzeAdditives()
                }
            }
        }
    }
    
    private func childWarningBadge(_ count: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10))
            Text("\(count)")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.orange)
        .cornerRadius(8)
    }
    
    private var emptyIngredientsContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))
                Text("No ingredient data available - unable to analyse additives and allergens")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
        }
        .padding(12)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }

    private var loadingContent: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("Analyzing additives...")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
    
    private func additiveContent(result: AdditiveDetectionResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Child warning message if present
            if let warningMessage = result.childWarningMessage {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 14))
                        Text(warningMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.orange)
                            .lineLimit(nil)
                    }

                    // Citation button for child hyperactivity research
                    Button(action: {
                        showingSources = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 11))
                            Text("View Research & Sources")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.orange.opacity(0.15))
                        )
                    }
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Detected additives and ultra-processed ingredients combined
            let totalIssues = result.detectedAdditives.count + result.ultraProcessedIngredients.count

            if totalIssues > 0 {
                VStack(alignment: .leading, spacing: 12) {
                    // Regular additives (E-numbers) — use AdditiveCardView for better UI
                    ForEach(Array(result.detectedAdditives.enumerated()), id: \.element.eNumber) { index, additive in
                        AdditiveCardView(additive: convertToDetailedAdditive(additive))
                    }

                    // Ultra-processed ingredients — collapsed by default
                    ForEach(result.ultraProcessedIngredients) { ingredient in
                        UltraProcessedIngredientCard(ingredient: ingredient, initialExpanded: false)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                        Text("No identifiable additives found")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Text("No additives detected in available data - this does not guarantee the product is additive-free, as additives may be present but not identified.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }

            // Educational footer with citation link
            VStack(alignment: .leading, spacing: 8) {
                Text("This information is provided for educational purposes to help you understand food additives. All listed additives are approved for use in food.")
                    .font(.system(size: 11).italic())
                    .foregroundColor(.secondary)

                Button(action: {
                    showingSources = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 10))
                        Text("View All Sources & Citations")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func analyzeAdditives() {
        #if DEBUG
        print("🧪 [AdditiveWatchView] Starting enhanced additive analysis")
        #endif
        #if DEBUG
        print("🧪 [AdditiveWatchView] Ingredients array count: \(ingredients.count)")
        #endif
        #if DEBUG
        print("🧪 [AdditiveWatchView] Ingredients: \(ingredients)")
        print("🧪 [AdditiveWatchView] FULL INGREDIENTS STRING: '\(ingredients.joined(separator: ", "))'")
        #endif

        // VALIDATION: Check if ingredients look suspicious or incomplete
        let filteredIngredients = ingredients.filter { ingredient in
            let trimmed = ingredient.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            // Skip empty ingredients
            if trimmed.isEmpty {
                return false
            }

            // Skip if ingredient is a common single whole food name (data quality issue)
            let commonWholeFoods = [
                "apple", "apples", "banana", "bananas", "orange", "oranges",
                "carrot", "carrots", "potato", "potatoes", "tomato", "tomatoes",
                "cucumber", "cucumbers", "lettuce", "spinach", "broccoli",
                "chicken", "beef", "pork", "fish", "salmon", "tuna",
                "rice", "water", "milk", "egg", "eggs"
            ]

            if commonWholeFoods.contains(trimmed) {
                #if DEBUG
                print("⚠️ [AdditiveWatchView] Skipping whole food name: '\(ingredient)'")
                #endif
                return false
            }

            return true
        }

        // If no valid ingredients remain after filtering, return empty result
        if filteredIngredients.isEmpty {
            #if DEBUG
            print("⚠️ [AdditiveWatchView] No valid ingredients to analyze after filtering")
            #endif
            self.additiveResult = AdditiveDetectionResult(
                detectedAdditives: [],
                childWarnings: [],
                hasChildConcernAdditives: false,
                analysisConfidence: 1.0,
                processingScore: nil,
                comprehensiveWarnings: nil,
                ultraProcessedIngredients: []
            )
            return
        }

        #if DEBUG
        print("🔍 [AdditiveWatchView] FILTERED INGREDIENTS TO ANALYZE: \(filteredIngredients)")
        print("🔍 [AdditiveWatchView] JOINED FOR ANALYSIS: '\(filteredIngredients.joined(separator: ", "))'")
        #endif

        // Use AdditiveWatchService which now uses local comprehensive database
        AdditiveWatchService.shared.analyzeIngredients(filteredIngredients) { result in
            #if DEBUG
            print("🧪 [AdditiveWatchView] Analysis complete!")
            #endif
            #if DEBUG
            print("🧪 [AdditiveWatchView] Detected additives count: \(result.detectedAdditives.count)")
            #endif
            if !result.detectedAdditives.isEmpty {
                #if DEBUG
                print("🧪 [AdditiveWatchView] Detected additives:")
                #endif
                for additive in result.detectedAdditives {
                    #if DEBUG
                    print("   - \(additive.eNumber): \(additive.name)")
                    #endif
                }
            } else {
                #if DEBUG
                print("🧪 [AdditiveWatchView] ⚠️ NO ADDITIVES DETECTED")
                #endif
            }

            #if DEBUG
            print("🏭 [AdditiveWatchView] Ultra-processed ingredients count: \(result.ultraProcessedIngredients.count)")
            #endif
            if !result.ultraProcessedIngredients.isEmpty {
                #if DEBUG
                print("🏭 [AdditiveWatchView] Detected ultra-processed ingredients:")
                #endif
                for ingredient in result.ultraProcessedIngredients {
                    #if DEBUG
                    print("   - \(ingredient.name) (penalty: \(ingredient.processingPenalty))")
                    #endif
                }
            } else {
                #if DEBUG
                print("🏭 [AdditiveWatchView] ⚠️ NO ULTRA-PROCESSED INGREDIENTS DETECTED")
                #endif
            }

            self.additiveResult = result
        }
    }

    // Convert AdditiveInfo to DetailedAdditive for UI display
    private func convertToDetailedAdditive(_ additive: AdditiveInfo) -> DetailedAdditive {
        // Prefer the human-friendly overview from the consolidated DB; fall back to typical uses or group label
        let overview = additive.overview.trimmingCharacters(in: .whitespacesAndNewlines)
        let uses = additive.typicalUses.trimmingCharacters(in: .whitespacesAndNewlines)
        let whereFrom = (additive.whereItComesFrom ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let effects = additive.effectsSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        let override = AdditiveOverrides.override(for: additive)

        // Show consumer-friendly name for known vitamins/aliases
        let displayName = override?.displayName ?? additive.name

        // Build “What is it?” sentence(s)
        var whatItIs = override?.whatItIs ?? (!overview.isEmpty ? overview : (!uses.isEmpty ? uses : additive.group.rawValue.capitalized))
        if !uses.isEmpty && override?.whatItIs == nil {
            // Avoid awkward “used to ...” phrasing
            let cleanedUses = uses.trimmingCharacters(in: .punctuationCharacters)
            if !whatItIs.lowercased().contains(cleanedUses.lowercased()) {
                whatItIs += (whatItIs.isEmpty ? "" : ". ") + "Commonly used in \(cleanedUses)"
            }
        }
        if !whatItIs.isEmpty && !whatItIs.hasSuffix(".") { whatItIs += "." }

        let originSummary = override?.originSummary ?? (!whereFrom.isEmpty ? whereFrom : describeOrigin(additive.origin.rawValue))

        let riskLevel: String
        switch additive.effectsVerdict {
        case .avoid: riskLevel = "High"
        case .caution: riskLevel = "Moderate"
        default: riskLevel = "Low"
        }

        let riskSummary: String
        if let customRisk = override?.riskSummary {
            riskSummary = customRisk
        } else if !effects.isEmpty {
            riskSummary = effects
        } else if additive.hasChildWarning {
            let guidance: String
            switch riskLevel {
            case "High": guidance = "Best avoided"
            case "Moderate": guidance = "Use in moderation"
            default: guidance = "Generally fine"
            }
            riskSummary = "Some studies suggest this may affect children's behavior. \(guidance)."
        } else {
            switch riskLevel {
            case "High":
                riskSummary = "Some studies have raised questions about this additive for sensitive individuals."
            case "Moderate":
                riskSummary = "This additive has a moderate safety rating in food safety databases."
            default:
                riskSummary = "This additive is generally recognised as safe when used in food."
            }
        }

        return DetailedAdditive(
            name: displayName,
            code: additive.eNumber.isEmpty ? nil : additive.eNumber,
            whatItIs: whatItIs,
            origin: additive.origin.rawValue,
            originSummary: originSummary,
            childWarning: additive.hasChildWarning,
            riskLevel: riskLevel,
            riskSummary: riskSummary,
            sources: additive.sources
        )
    }

    // Simple origin explainer for use before the UI helper functions are in scope
    private func describeOrigin(_ origin: String) -> String {
        let lower = origin.lowercased()
        if lower.contains("plant") { return "Derived from plants - a natural source" }
        if lower.contains("synthetic") { return "Made in a laboratory using chemical processes" }
        if lower.contains("animal") { return "Derived from animals" }
        if lower.contains("mineral") { return "Extracted from minerals or rocks" }
        if lower.contains("ferment") { return "Produced through fermentation - a natural process" }
        if lower.contains("varied") { return "Can come from multiple sources depending on manufacturer" }
        return origin
    }
}

// MARK: - Additive Card Component

struct AdditiveCard: View {
    let additive: AdditiveInfo
    @State private var isExpanded: Bool
    @State private var showingSources = false

    init(additive: AdditiveInfo, initialExpanded: Bool = false) {
        self.additive = additive
        _isExpanded = State(initialValue: initialExpanded)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Additive header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(additive.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)

                            if additive.hasChildWarning {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 10))
                            }
                        }

                        Text(additive.group.displayName)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        // Display only actual E-numbers in purple boxes (E followed by digits)
                        let actualENumbers = additive.eNumbers.filter { eNumber in
                            // Strict check: E followed by digits, optionally with subcategory letters or roman numerals
                            let pattern = "^E[0-9]+(([a-z]+)|([\\(][ivxIVX]+[\\)]))?$"
                            return eNumber.range(of: pattern, options: .regularExpression) != nil
                        }
                        if !actualENumbers.isEmpty {
                            ForEach(actualENumbers, id: \.self) { eNumber in
                                Text(eNumber)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.purple)
                                    .cornerRadius(4)
                            }
                        }

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.purple)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .padding(.vertical, 4)
                    
                    // Overview
                    if !additive.overview.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("What is it?")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.primary)
                            Text(additive.overview)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                    }
                    
                    // Typical uses
                    if !additive.typicalUses.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Typical uses:")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.primary)
                            Text(additive.typicalUses)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                    }
                    
                    // Comprehensive Consumer Information
                    if let consumerInfo = additive.consumerInfo, !consumerInfo.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            // Display consumer guide with markdown formatting
                            Text(LocalizedStringKey(consumerInfo))
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                                .lineLimit(nil)
                        }
                    } else {
                        // Fallback to basic information if consumer info not available
                        VStack(alignment: .leading, spacing: 6) {
                            // Origin
                            HStack(spacing: 6) {
                                Text(originIcon(for: additive.origin.rawValue))
                                    .font(.system(size: 11))
                                Text("Origin: \(originDisplayName(for: additive.origin.rawValue))")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }

                            // Safety message
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: safetyIcon(verdict: additive.effectsVerdict.rawValue))
                                    .foregroundColor(verdictColor(for: additive.effectsVerdict.rawValue))
                                    .font(.system(size: 11))
                                Text(additive.effectsSummary)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .lineLimit(nil)
                            }
                        }
                    }

                    // Sources section
                    if !additive.sources.isEmpty {
                        Divider()
                            .padding(.vertical, 8)

                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showingSources.toggle()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.system(size: 12))
                                        .foregroundColor(.blue)
                                    Text("Sources (\(additive.sources.count))")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: showingSources ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }

                            if showingSources {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(Array(additive.sources.enumerated()), id: \.offset) { index, source in
                                        Button(action: {
                                            if let url = URL(string: source.url) {
                                                UIApplication.shared.open(url)
                                            }
                                        }) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(source.title)
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(.blue)
                                                    .lineLimit(2)

                                                Text(source.url)
                                                    .font(.system(size: 9))
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(8)
                                            .background(Color(.systemGray6))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                            )
                                            .cornerRadius(6)
                                        }
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.purple.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(8)
    }

    private func safetyIndicator(verdict: String) -> some View {
        let color: Color = {
            switch verdict.lowercased() {
            case "avoid": return .red
            case "caution": return .orange
            case "neutral": return .green
            default: return .gray
            }
        }()

        return Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }
    
    private func safetyIcon(verdict: String) -> String {
        switch verdict.lowercased() {
        case "neutral": return "checkmark.circle"
        case "caution": return "exclamationmark.triangle"
        case "avoid": return "xmark.circle"
        default: return "questionmark.circle"
        }
    }

    private func verdictColor(for verdict: String) -> Color {
        switch verdict.lowercased() {
        case "avoid": return .red
        case "caution": return .orange
        case "neutral": return .green
        default: return .gray
        }
    }

    private func originIcon(for origin: String) -> String {
        switch origin.lowercased() {
        case "natural": return "🌿"
        case "plant": return "🌱"
        case "synthetic": return "🧪"
        case "semi-synthetic": return "⚗️"
        default: return "❓"
        }
    }

    private func originDisplayName(for origin: String) -> String {
        return origin.capitalized
    }
}

// MARK: - Detailed Additive Components

struct DetailedAdditive {
    let name: String
    let code: String?
    let whatItIs: String
    let origin: String
    let originSummary: String
    let childWarning: Bool
    let riskLevel: String
    let riskSummary: String
    let sources: [AdditiveSource]
}

struct AdditiveCardView: View {
    let additive: DetailedAdditive
    @Environment(\.colorScheme) var colorScheme
    @State private var isExpanded = false
    @State private var showingSources = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - always visible (tap to expand/collapse)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        // Name and code
                        HStack(spacing: 6) {
                            Text(additive.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)

                            // Only show purple tag for actual E-numbers (E followed by digits)
                            if let code = additive.code {
                                let pattern = "^E[0-9]+(([a-z]+)|([\\(][ivxIVX]+[\\)]))?$"
                                if code.range(of: pattern, options: .regularExpression) != nil {
                                    Text(code)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.purple.opacity(0.7))
                                        .cornerRadius(6)
                                }
                            }
                        }

                        // User-friendly information row
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Image(systemName: getOriginIcon(additive.origin))
                                    .font(.system(size: 10))
                                    .foregroundColor(getOriginColor(additive.origin))
                                Text(getOriginLabel(additive.origin))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }

                            if additive.childWarning {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 9))
                                        .foregroundColor(.orange)
                                    Text("May affect children")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }

                    Spacer()

                    // Chevron indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.purple)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(14)

            // Expanded details - only show when tapped
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .padding(.horizontal, 14)

                    VStack(alignment: .leading, spacing: 12) {
                        // What is it (Purpose)
                        AdditiveInfoRow(icon: "info.circle.fill", title: "What is it?", content: getWhatItIsDescription(additive.whatItIs), color: .blue)

                        // Where is it from
                        AdditiveInfoRow(icon: "leaf.fill", title: "Where is it from?", content: additive.originSummary.isEmpty ? getOriginDescription(additive.origin) : additive.originSummary, color: getOriginColor(additive.origin))

                        // Any risks
                        AdditiveInfoRow(icon: getRiskIcon(), title: "Any risks?", content: getRiskDescription(), color: getUsageColor())
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)

                    // Sources section (collapsible)
                    if !additive.sources.isEmpty {
                        Divider()
                            .padding(.horizontal, 14)

                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showingSources.toggle()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.system(size: 12))
                                        .foregroundColor(.blue)
                                    Text("Sources (\(additive.sources.count))")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: showingSources ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }

                            if showingSources {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(Array(additive.sources.enumerated()), id: \.offset) { _, source in
                                        Button(action: {
                                            if let url = URL(string: source.url) {
                                                UIApplication.shared.open(url)
                                            }
                                        }) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(source.title)
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(.blue)
                                                    .lineLimit(2)

                                                Text(source.url)
                                                    .font(.system(size: 9))
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(8)
                                            .background(Color(.systemGray6))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                            )
                                            .cornerRadius(6)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.bottom, 14)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color.midnightCard.opacity(0.8) : Color.purple.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.purple.opacity(0.25), lineWidth: 1.5)
                )
        )
    }
    
    private func getUsageColor() -> Color {
        switch additive.riskLevel {
        case "High": return .red
        case "Moderate": return .orange
        default: return .green
        }
    }
    
    private func getUsageGuidance(_ level: String) -> String {
        switch level {
        case "High": return "Best avoided"
        case "Moderate": return "Use in moderation"
        case "Low": return "Generally fine"
        default: return "Generally fine"
        }
    }

    private func getRiskFallback(for level: String, childWarning: Bool) -> String {
        if childWarning {
            return "Some studies suggest this may affect children's behavior. \(getUsageGuidance(level))."
        }

        switch level {
        case "High":
            return "Some studies have raised questions about this additive for sensitive individuals."
        case "Moderate":
            return "This additive has a moderate safety rating in food safety databases."
        default:
            return "This additive is generally recognised as safe when used in food."
        }
    }

    private func getOriginLabel(_ origin: String) -> String {
        let lowercased = origin.lowercased()

        // Handle complex origin strings (e.g., "Synthetic/Plant/Mineral (Varies By Specification)")
        if lowercased.contains("varies by specification") || lowercased.contains("syntheticplantmineral") {
            return "Varied origin"
        }

        switch lowercased {
        case "synthetic": return "Synthetic"
        case "natural": return "Natural"
        case "plant": return "Plant-based"
        case "animal": return "Animal-derived"
        case "mineral": return "Mineral"
        case "insect": return "Insect-derived"
        case "fish": return "Fish-derived"
        case "dairy": return "Dairy-derived"
        case "mixed": return "Natural & synthetic"
        case "plant/animal": return "Plant or animal"
        case "natural/synthetic": return "Natural or synthetic"
        case "plant (turmeric)": return "Plant (turmeric)"
        case "synthetic/microbial": return "Synthetic/Microbial"
        default:
            // Clean up long complex strings
            if origin.count > 30 {
                if origin.contains("Synthetic") {
                    return "Synthetic"
                }
                if origin.contains("Plant") {
                    return "Plant-based"
                }
                if origin.contains("Natural") {
                    return "Natural"
                }
                return "Varied origin"
            }
            return origin
        }
    }

    private func getOriginColor(_ origin: String) -> Color {
        let lowercased = origin.lowercased()

        // Handle complex origin strings
        if lowercased.contains("varies") || lowercased.contains("syntheticplantmineral") {
            return .secondary
        }

        switch lowercased {
        case "synthetic": return .orange
        case "natural", "plant": return .green
        case "animal", "insect", "fish", "dairy": return .purple
        case "mineral": return .blue
        case "mixed", "plant/animal", "natural/synthetic": return .secondary
        default:
            // Determine color based on content
            if origin.contains("Synthetic") {
                return .orange
            }
            if origin.contains("Plant") || origin.contains("Natural") {
                return .green
            }
            if origin.contains("Animal") {
                return .purple
            }
            if origin.contains("Mineral") {
                return .blue
            }
            return .secondary
        }
    }

    private func getOriginIcon(_ origin: String) -> String {
        let lowercased = origin.lowercased()

        if lowercased.contains("plant") || lowercased.contains("natural") {
            return "leaf.fill"
        } else if lowercased.contains("synthetic") {
            return "flask.fill"
        } else if lowercased.contains("animal") {
            return "pawprint.fill"
        } else if lowercased.contains("mineral") {
            return "circle.hexagongrid.fill"
        } else {
            return "questionmark.circle.fill"
        }
    }

    private func getWhatItIsDescription(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty else { return trimmed }
        return "Food additive information not available yet."
    }

    private func getOriginDescription(_ origin: String) -> String {
        let lower = origin.lowercased()

        if lower.contains("plant") {
            return "Derived from plants - a natural source"
        } else if lower.contains("synthetic") {
            return "Made in a laboratory using chemical processes"
        } else if lower.contains("animal") {
            return "Derived from animals"
        } else if lower.contains("mineral") {
            return "Extracted from minerals or rocks"
        } else if lower.contains("ferment") {
            return "Produced through fermentation - a natural process"
        } else if lower.contains("varied") {
            return "Can come from multiple sources depending on manufacturer"
        } else {
            return origin
        }
    }

    private func getRiskIcon() -> String {
        switch additive.riskLevel {
        case "High": return "exclamationmark.triangle.fill"
        case "Moderate": return "exclamationmark.circle.fill"
        default: return "checkmark.circle.fill"
        }
    }

    private func getRiskDescription() -> String {
        var summary = additive.riskSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        if summary.isEmpty {
            summary = getRiskFallback(for: additive.riskLevel, childWarning: additive.childWarning)
        }
        return summary
    }
}

// MARK: - Additive Info Row Component

struct AdditiveInfoRow: View {
    let icon: String
    let title: String
    let content: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)

                Text(content)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Additive Description Component

struct AdditiveDescriptionView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Parse and display the consumer guide sections
            ForEach(getParsedSections(), id: \.title) { section in
                if !section.content.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        if !section.title.isEmpty {
                            Text(section.title)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        Text(section.content)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private struct ConsumerGuideSection {
        let title: String
        let content: String
    }

    private func getParsedSections() -> [ConsumerGuideSection] {
        var sections: [ConsumerGuideSection] = []
        let lines = text.components(separatedBy: "\n")
        var currentTitle = ""
        var currentContent = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // Skip empty lines
            if trimmed.isEmpty {
                continue
            }

            // Check if it's a header (e.g., "**What is it?**")
            if trimmed.hasPrefix("**") && trimmed.hasSuffix("**") {
                // Save previous section if we have one
                if !currentTitle.isEmpty || !currentContent.isEmpty {
                    sections.append(ConsumerGuideSection(title: currentTitle, content: currentContent.trimmingCharacters(in: .whitespacesAndNewlines)))
                }
                // Start new section
                currentTitle = trimmed.replacingOccurrences(of: "**", with: "").replacingOccurrences(of: ":", with: "")
                currentContent = ""
            } else {
                // Add content to current section
                if !currentContent.isEmpty {
                    currentContent += " "
                }
                currentContent += trimmed
            }
        }

        // Add the last section
        if !currentTitle.isEmpty || !currentContent.isEmpty {
            sections.append(ConsumerGuideSection(title: currentTitle, content: currentContent.trimmingCharacters(in: .whitespacesAndNewlines)))
        }

        // If no sections were parsed, return the raw text as a single section
        if sections.isEmpty {
            let cleanText = text.replacingOccurrences(of: "**", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            sections.append(ConsumerGuideSection(title: "", content: cleanText))
        }

        return sections
    }
    
    private var parsedSections: [AdditiveSection] {
        // Parse markdown-style **headers** and regular content
        let lines = text.components(separatedBy: "\n")
        var sections: [AdditiveSection] = []
        var currentSection = AdditiveSection(id: UUID(), header: "", content: "")
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.isEmpty {
                continue
            }
            
            // Check if line contains **bold** text
            if trimmedLine.hasPrefix("**") && trimmedLine.contains("**") {
                // Save previous section if it has content
                if !currentSection.header.isEmpty || !currentSection.content.isEmpty {
                    sections.append(currentSection)
                }
                
                // Create new section with header
                let cleanHeader = trimmedLine.replacingOccurrences(of: "**", with: "")
                currentSection = AdditiveSection(id: UUID(), header: cleanHeader, content: "")
            } else {
                // Add to current section content
                if !currentSection.content.isEmpty {
                    currentSection.content += " "
                }
                currentSection.content += trimmedLine
            }
        }
        
        // Add final section
        if !currentSection.header.isEmpty || !currentSection.content.isEmpty {
            sections.append(currentSection)
        }
        
        return sections
    }
}

// MARK: - Supporting Data Models

struct AdditiveSection {
    let id: UUID
    var header: String
    var content: String
}
// MARK: - Ultra-Processed Ingredient Card Component

struct UltraProcessedIngredientCard: View {
    let ingredient: UltraProcessedIngredientDisplay
    @Environment(\.colorScheme) var colorScheme
    @State private var isExpanded: Bool

    init(ingredient: UltraProcessedIngredientDisplay, initialExpanded: Bool = false) {
        self.ingredient = ingredient
        _isExpanded = State(initialValue: initialExpanded)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Ingredient header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ingredient.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)

                        Text(ingredient.category.capitalized)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        // Display only actual E-numbers in purple boxes (E followed by digits)
                        let actualENumbers = ingredient.eNumbers.filter { eNumber in
                            // Strict check: E followed by digits, optionally with subcategory letters or roman numerals
                            let pattern = "^E[0-9]+(([a-z]+)|([\\(][ivxIVX]+[\\)]))?$"
                            return eNumber.range(of: pattern, options: .regularExpression) != nil
                        }
                        if !actualENumbers.isEmpty {
                            ForEach(actualENumbers, id: \.self) { eNumber in
                                Text(eNumber)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.purple)
                                    .cornerRadius(4)
                            }
                        }

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.purple)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()

                    // What it is
                    if let whatItIs = ingredient.whatItIs {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "magnifyingglass.circle")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 12))
                                Text("What it is")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.primary)
                            }

                            Text(whatItIs)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                    }

                    // Why it's used
                    if let whyItsUsed = ingredient.whyItsUsed {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "cube.box")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 12))
                                Text("Why it's used")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.primary)
                            }

                            Text(whyItsUsed)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                    }

                    // Where it comes from
                    if let whereItComesFrom = ingredient.whereItComesFrom {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "leaf")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 12))
                                Text("Where it comes from")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.primary)
                            }

                            Text(whereItComesFrom)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                    }

                    // Concerns section
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .font(.system(size: 12))
                            Text("Why it matters")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.primary)
                        }

                        Text(ingredient.concerns)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                    }

                    // NOVA classification
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 12))
                        Text("NOVA Group \(ingredient.novaGroup)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(novaGroupLabel(ingredient.novaGroup))
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .cornerRadius(4)
                    }

                    // Sources section
                    if !ingredient.sources.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 12))
                                Text("Scientific Sources (\(ingredient.sources.count))")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.primary)
                            }

                            ForEach(ingredient.sources, id: \.url) { source in
                                Button(action: {
                                    if let url = URL(string: source.url) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(source.title)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.blue)
                                            .lineLimit(2)

                                        Text(source.covers)
                                            .font(.system(size: 9))
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                                    .cornerRadius(6)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(colorScheme == .dark ? Color.midnightCard.opacity(0.8) : Color.purple.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(8)
    }

    private func novaGroupLabel(_ group: Int) -> String {
        switch group {
        case 1: return "Unprocessed"
        case 2: return "Minimally Processed"
        case 3: return "Processed"
        case 4: return "Ultra-Processed"
        default: return "Unknown"
        }
    }
}
