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

// MARK: - Additive Risk Level (Traffic Light System)

/// Risk levels for additives - neutral wording as individual reactions may vary
enum AdditiveRiskLevel: Int, Comparable, CaseIterable {
    case noRisk = 0       // Green - vitamins, natural ingredients
    case lowRisk = 1      // Light green - common additives, few concerns
    case moderateRisk = 2 // Yellow/Orange - some people may want to limit
    case highRisk = 3     // Red - often limited or avoided

    static func < (lhs: AdditiveRiskLevel, rhs: AdditiveRiskLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var color: Color {
        switch self {
        case .noRisk: return Color(red: 0.2, green: 0.7, blue: 0.3)      // Bright green
        case .lowRisk: return Color(red: 0.5, green: 0.75, blue: 0.3)    // Yellow-green
        case .moderateRisk: return Color(red: 0.95, green: 0.6, blue: 0.1) // Orange
        case .highRisk: return Color(red: 0.9, green: 0.25, blue: 0.2)   // Red
        }
    }

    var label: String {
        switch self {
        case .noRisk: return "Minimal"
        case .lowRisk: return "Limited"
        case .moderateRisk: return "Moderate"
        case .highRisk: return "Notable"
        }
    }

    var icon: String {
        switch self {
        case .noRisk: return "checkmark.circle.fill"
        case .lowRisk: return "checkmark.circle"
        case .moderateRisk: return "exclamationmark.circle.fill"
        case .highRisk: return "xmark.circle.fill"
        }
    }

    var shortDescription: String {
        switch self {
        case .noRisk: return "Commonly accepted"
        case .lowRisk: return "Few concerns raised"
        case .moderateRisk: return "Some choose to limit"
        case .highRisk: return "Often avoided"
        }
    }
}

// MARK: - Additive Score Summary

/// Overall additive score for a food product (0-100, like Yuka)
struct AdditiveScoreSummary {
    let score: Int                    // 0-100 score (100 = no additives/all safe)
    let overallRisk: AdditiveRiskLevel
    let totalAdditives: Int
    let riskBreakdown: [AdditiveRiskLevel: Int]  // Count per risk level
    let hasChildWarnings: Bool
    let hasSulphiteWarnings: Bool

    var gradeLabel: String {
        // Show "No Additives" when there are genuinely none detected
        if totalAdditives == 0 {
            return "No Additives"
        }
        switch score {
        case 80...100: return "Few Additives"
        case 60..<80: return "Some Additives"
        case 40..<60: return "Several Additives"
        case 20..<40: return "Many Additives"
        default: return "High Additive Count"
        }
    }

    var gradeColor: Color {
        switch score {
        case 80...100: return Color(red: 0.2, green: 0.7, blue: 0.3)
        case 60..<80: return Color(red: 0.5, green: 0.75, blue: 0.3)
        case 40..<60: return Color(red: 0.95, green: 0.6, blue: 0.1)
        case 20..<40: return Color(red: 0.9, green: 0.5, blue: 0.2)
        default: return Color(red: 0.9, green: 0.25, blue: 0.2)
        }
    }
}

// MARK: - Shared additive overrides (friendly names/descriptions)

struct AdditiveOverrideData {
    let displayName: String?
    let shortSummary: String?  // 1-2 sentence quick summary for compact views
    let whatItIs: String?       // Full engaging description (3-5+ sentences)
    let originSummary: String?
    let riskSummary: String?
    let riskLevel: AdditiveRiskLevel?
}

enum AdditiveOverrides {
    // Lookup by lowercase E-number or name
    private static let overrides: [String: AdditiveOverrideData] = [
        // Vitamins / fortification - NO RISK (natural/beneficial)
        "e300": .init(displayName: "Vitamin C (Ascorbic acid)", shortSummary: "Essential vitamin C - antioxidant and immune booster found in citrus fruits.", whatItIs: "Essential vitamin C - a powerful antioxidant that prevents browning and extends freshness. Your body needs it daily for immune function and collagen production.", originSummary: "Naturally found in citrus fruits; commercially produced via fermentation of glucose.", riskSummary: "Safe and beneficial. This is the same vitamin C found in oranges and lemons.", riskLevel: .noRisk),
        "ascorbic acid": .init(displayName: "Vitamin C (Ascorbic acid)", shortSummary: "Essential vitamin C - antioxidant and immune booster found in citrus fruits.", whatItIs: "Essential vitamin C - a powerful antioxidant that prevents browning and extends freshness. Your body needs it daily for immune function and collagen production.", originSummary: "Naturally found in citrus fruits; commercially produced via fermentation of glucose.", riskSummary: "Safe and beneficial. This is the same vitamin C found in oranges and lemons.", riskLevel: .noRisk),
        "e375": .init(displayName: "Vitamin B3 (Niacin)", shortSummary: "Essential B vitamin for energy metabolism, found in meat and nuts.", whatItIs: "Essential B vitamin that helps convert food into energy. Added to cereals and bread to prevent deficiency diseases.", originSummary: "Found naturally in meat, fish, and nuts; commercially synthesised.", riskSummary: "Essential nutrient. The amounts in food are well within safe limits.", riskLevel: .noRisk),
        "nicotinic acid": .init(displayName: "Vitamin B3 (Niacin)", shortSummary: "Essential B vitamin for energy metabolism, found in meat and nuts.", whatItIs: "Essential B vitamin that helps convert food into energy. Added to cereals and bread to prevent deficiency diseases.", originSummary: "Found naturally in meat, fish, and nuts; commercially synthesised.", riskSummary: "Essential nutrient. The amounts in food are well within safe limits.", riskLevel: .noRisk),
        "e101": .init(displayName: "Vitamin B2 (Riboflavin)", shortSummary: "Essential B vitamin giving foods yellow colour, important for energy and skin health.", whatItIs: "Essential B vitamin that gives foods a yellow-orange colour. Important for energy metabolism and healthy skin.", originSummary: "Found in eggs, dairy, and leafy greens; produced via bacterial fermentation.", riskSummary: "Completely safe. This is the same vitamin B2 found naturally in dairy and eggs.", riskLevel: .noRisk),
        "riboflavin": .init(displayName: "Vitamin B2 (Riboflavin)", shortSummary: "Essential B vitamin giving foods yellow colour, important for energy and skin health.", whatItIs: "Essential B vitamin that gives foods a yellow-orange colour. Important for energy metabolism and healthy skin.", originSummary: "Found in eggs, dairy, and leafy greens; produced via bacterial fermentation.", riskSummary: "Completely safe. This is the same vitamin B2 found naturally in dairy and eggs.", riskLevel: .noRisk),
        "e160a": .init(displayName: "Beta-carotene", shortSummary: "Orange pigment from carrots that your body converts to vitamin A.", whatItIs: "Natural orange pigment from carrots and sweet potatoes. Your body converts it to vitamin A for healthy eyes and immune function.", originSummary: "Extracted from carrots, palm oil, or algae; sometimes synthetic.", riskSummary: "Safe and beneficial. Provides vitamin A activity without toxicity risk.", riskLevel: .noRisk),
        "beta-carotene": .init(displayName: "Beta-carotene", shortSummary: "Orange pigment from carrots that your body converts to vitamin A.", whatItIs: "Natural orange pigment from carrots and sweet potatoes. Your body converts it to vitamin A for healthy eyes and immune function.", originSummary: "Extracted from carrots, palm oil, or algae; sometimes synthetic.", riskSummary: "Safe and beneficial. Provides vitamin A activity without toxicity risk.", riskLevel: .noRisk),
        "e306": .init(displayName: "Vitamin E (Tocopherols)", shortSummary: "Natural antioxidant from vegetable oils that protects fats and cells.", whatItIs: "Natural antioxidant that protects fats from going rancid and protects your cells from damage.", originSummary: "Extracted from vegetable oils like sunflower and wheat germ.", riskSummary: "Safe and beneficial. A natural preservative with health benefits.", riskLevel: .noRisk),
        "e307": .init(displayName: "Vitamin E (Alpha-tocopherol)", shortSummary: "The most active form of vitamin E - cell protector and oil preserver.", whatItIs: "The most active form of vitamin E - protects cell membranes and keeps oils fresh.", originSummary: "From vegetable oils or synthetic.", riskSummary: "Safe and beneficial.", riskLevel: .noRisk),
        "e308": .init(displayName: "Vitamin E (Gamma-tocopherol)", shortSummary: "A form of vitamin E with antioxidant properties from vegetable oils.", whatItIs: "A form of vitamin E with antioxidant properties.", originSummary: "From vegetable oils.", riskSummary: "Safe and beneficial.", riskLevel: .noRisk),
        "e309": .init(displayName: "Vitamin E (Delta-tocopherol)", shortSummary: "A form of vitamin E with antioxidant properties from vegetable oils.", whatItIs: "A form of vitamin E with antioxidant properties.", originSummary: "From vegetable oils.", riskSummary: "Safe and beneficial.", riskLevel: .noRisk),

        // Natural ingredients - NO RISK
        "e330": .init(displayName: "Citric acid", shortSummary: "The tangy acid from lemons and oranges - your body makes it naturally too!", whatItIs: "The tangy punch behind lemons, limes, and oranges - when life gives you lemons, you're tasting citric acid! For a century, it was painstakingly extracted from actual citrus fruits, but then a clever scientist discovered you could ferment sugars with a harmless mould (Aspergillus niger - sounds scary but it's perfectly safe) to produce tons of it. Now it's one of the most widely used food additives on Earth. Besides adding tartness to soft drinks, sweets, and jams, it's a brilliant preservative that stops food from going brown and extends shelf life. Your own body produces citric acid constantly as part of the Krebs cycle (the energy factory in your cells), so you're already full of the stuff!", originSummary: "🍋 Originally extracted from citrus fruits; now produced industrially by fermenting sugar or molasses with Aspergillus niger mould. Your body makes it naturally too!", riskSummary: "Completely safe and identical to the citric acid in lemons and oranges. Your body produces and metabolizes it constantly. One of the safest and most natural-feeling additives.", riskLevel: .noRisk),
        "e322": .init(displayName: "Lecithin", shortSummary: "Natural emulsifier from soybeans or eggs - 30% of your brain is lecithin!", whatItIs: "The molecular peacekeeper that stops oil and water from having a divorce! Usually extracted from soybeans (though egg yolks work too), lecithin is what makes chocolate bars smooth instead of grainy, stops salad dressing from separating, and keeps margarine emulsified. It's actually an essential nutrient your brain and liver need - about 30% of your brain's dry weight is lecithin! Food scientists love it because it works magic at tiny concentrations. The soy version revolutionized food manufacturing when it was discovered in the 1930s. Fun fact: the name comes from the Greek word 'lekithos' meaning egg yolk, where it was first discovered in 1845.", originSummary: "🫘🥚 Usually from soybeans or sunflower seeds (pressed, refined, and extracted). Occasionally from egg yolks. Natural and minimally processed.", riskSummary: "Completely safe and natural. An important nutrient for brain and liver health. Your body uses lecithin to build cell membranes. One of the friendliest emulsifiers.", riskLevel: .noRisk),
        "lecithin": .init(displayName: "Lecithin", shortSummary: "Natural emulsifier from soybeans or eggs - 30% of your brain is lecithin!", whatItIs: "The molecular peacekeeper that stops oil and water from having a divorce! Usually extracted from soybeans (though egg yolks work too), lecithin is what makes chocolate bars smooth instead of grainy, stops salad dressing from separating, and keeps margarine emulsified. It's actually an essential nutrient your brain and liver need - about 30% of your brain's dry weight is lecithin! Food scientists love it because it works magic at tiny concentrations. The soy version revolutionized food manufacturing when it was discovered in the 1930s. Fun fact: the name comes from the Greek word 'lekithos' meaning egg yolk, where it was first discovered in 1845.", originSummary: "🫘🥚 Usually from soybeans or sunflower seeds (pressed, refined, and extracted). Occasionally from egg yolks. Natural and minimally processed.", riskSummary: "Completely safe and natural. An important nutrient for brain and liver health. Your body uses lecithin to build cell membranes. One of the friendliest emulsifiers.", riskLevel: .noRisk),

        // Low risk - plant-derived gums and thickeners
        "e415": .init(displayName: "Xanthan gum", shortSummary: "Bacterial thickener that makes sauces smooth and gluten-free baking possible.", whatItIs: "A slimy substance produced by bacteria during fermentation - sounds absolutely revolting, doesn't it? But hear this: it's brilliant at making sauces silky smooth and gluten-free baking actually possible! Discovered in the 1960s by USDA scientists studying bacteria, xanthan gum is made when Xanthomonas campestris bacteria feast on sugar and produce this gooey polysaccharide as a byproduct (basically bacterial slime). But don't let that put you off - it's completely safe and incredibly useful. Just a tiny pinch transforms liquids into smooth, stable gels. It's the secret behind every commercial salad dressing that doesn't separate, and it's a game-changer for gluten-free bakers who need something to replace gluten's binding power.", originSummary: "🧫 Made by fermenting sugar (usually corn or soy-derived) with Xanthomonas campestris bacteria. The bacteria produce it naturally as they digest the sugar.", riskSummary: "Generally safe and approved globally. Very high amounts may cause mild digestive effects in sensitive people, but typical food amounts are completely fine. Revolutionized gluten-free cooking!", riskLevel: .lowRisk),
        "xanthan gum": .init(displayName: "Xanthan gum", shortSummary: "Bacterial thickener that makes sauces smooth and gluten-free baking possible.", whatItIs: "A slimy substance produced by bacteria during fermentation - sounds absolutely revolting, doesn't it? But hear this: it's brilliant at making sauces silky smooth and gluten-free baking actually possible! Discovered in the 1960s by USDA scientists studying bacteria, xanthan gum is made when Xanthomonas campestris bacteria feast on sugar and produce this gooey polysaccharide as a byproduct (basically bacterial slime). But don't let that put you off - it's completely safe and incredibly useful. Just a tiny pinch transforms liquids into smooth, stable gels. It's the secret behind every commercial salad dressing that doesn't separate, and it's a game-changer for gluten-free bakers who need something to replace gluten's binding power.", originSummary: "🧫 Made by fermenting sugar (usually corn or soy-derived) with Xanthomonas campestris bacteria. The bacteria produce it naturally as they digest the sugar.", riskSummary: "Generally safe and approved globally. Very high amounts may cause mild digestive effects in sensitive people, but typical food amounts are completely fine. Revolutionized gluten-free cooking!", riskLevel: .lowRisk),
        "xanthan": .init(displayName: "Xanthan gum", shortSummary: "Bacterial thickener that makes sauces smooth and gluten-free baking possible.", whatItIs: "A slimy substance produced by bacteria during fermentation - sounds absolutely revolting, doesn't it? But hear this: it's brilliant at making sauces silky smooth and gluten-free baking actually possible! Discovered in the 1960s by USDA scientists studying bacteria, xanthan gum is made when Xanthomonas campestris bacteria feast on sugar and produce this gooey polysaccharide as a byproduct (basically bacterial slime). But don't let that put you off - it's completely safe and incredibly useful. Just a tiny pinch transforms liquids into smooth, stable gels. It's the secret behind every commercial salad dressing that doesn't separate, and it's a game-changer for gluten-free bakers who need something to replace gluten's binding power.", originSummary: "🧫 Made by fermenting sugar (usually corn or soy-derived) with Xanthomonas campestris bacteria. The bacteria produce it naturally as they digest the sugar.", riskSummary: "Generally safe and approved globally. Very high amounts may cause mild digestive effects in sensitive people, but typical food amounts are completely fine. Revolutionized gluten-free cooking!", riskLevel: .lowRisk),
        "e412": .init(displayName: "Guar gum", shortSummary: "Plant thickener from guar beans - 8x stronger than cornstarch and acts as prebiotic fiber.", whatItIs: "Plant-based thickener from guar beans that grow in India and Pakistan. These legume pods produce seeds that, when ground up, create an incredibly powerful thickening agent - it's about 8 times more effective than cornstarch! Food manufacturers love it for ice cream (keeps it smooth and prevents ice crystals), sauces (stops them from going watery), and gluten-free products (provides structure without gluten). It's also brilliant for stabilizing dairy products and keeping ingredients suspended in drinks. Your gut bacteria can partially ferment it, which means it acts as a prebiotic fiber feeding your good gut bugs. The guar plant has been cultivated for thousands of years, and 80% of the world's supply still comes from India.", originSummary: "🫘 Ground from the endosperm of guar bean seeds (Cyamopsis tetragonoloba), a legume grown mainly in India and Pakistan. The seeds are dehusked, milled, and sifted into fine powder.", riskSummary: "Generally safe and well-tolerated as a natural plant fiber. May cause mild bloating or gas if consumed in very large amounts. Acts as prebiotic fiber benefiting gut health.", riskLevel: .lowRisk),
        "e407": .init(displayName: "Carrageenan", shortSummary: "Seaweed thickener from Irish moss - used since the 1400s for milk puddings.", whatItIs: "Extracted from red seaweed (Irish moss) that washes up on rocky Atlantic coastlines - it's been used in Irish and Scottish cooking since the 1400s as a traditional way to thicken milk puddings! When you simmer this seaweed in milk, it releases carrageenans which gel everything together beautifully. Modern food manufacturers extract and purify it to use as a thickener in everything from ice cream to chocolate milk to vegan cheese. It comes in different types (kappa, iota, lambda) that gel or thicken in different ways, giving food scientists precise control over texture. There's been some controversy about degraded carrageenan (poligeenan) which isn't used in food, but food-grade carrageenan is a completely different molecule and extensively tested for safety.", originSummary: "🌊🌱 Extracted from red seaweed species (mainly Chondrus crispus - Irish moss, and Eucheuma) harvested from cold Atlantic waters. The seaweed is washed, alkali-treated to extract carrageenan, then filtered and dried.", riskSummary: "Food-grade carrageenan is approved as safe by major regulatory bodies worldwide. Some people with digestive sensitivity may prefer to limit it. Different from degraded carrageenan (poligeenan) which isn't used in food.", riskLevel: .lowRisk),
        "carrageenan": .init(displayName: "Carrageenan", shortSummary: "Seaweed thickener from Irish moss - used since the 1400s for milk puddings.", whatItIs: "Extracted from red seaweed (Irish moss) that washes up on rocky Atlantic coastlines - it's been used in Irish and Scottish cooking since the 1400s as a traditional way to thicken milk puddings! When you simmer this seaweed in milk, it releases carrageenans which gel everything together beautifully. Modern food manufacturers extract and purify it to use as a thickener in everything from ice cream to chocolate milk to vegan cheese. It comes in different types (kappa, iota, lambda) that gel or thicken in different ways, giving food scientists precise control over texture. There's been some controversy about degraded carrageenan (poligeenan) which isn't used in food, but food-grade carrageenan is a completely different molecule and extensively tested for safety.", originSummary: "🌊🌱 Extracted from red seaweed species (mainly Chondrus crispus - Irish moss, and Eucheuma) harvested from cold Atlantic waters. The seaweed is washed, alkali-treated to extract carrageenan, then filtered and dried.", riskSummary: "Food-grade carrageenan is approved as safe by major regulatory bodies worldwide. Some people with digestive sensitivity may prefer to limit it. Different from degraded carrageenan (poligeenan) which isn't used in food.", riskLevel: .lowRisk),
        "e466": .init(displayName: "Cellulose gum", shortSummary: "Modified plant fiber from wood pulp - can't digest your spoon, but this dissolves!", whatItIs: "Chemically modified plant fiber (cellulose gum or CMC) that's brilliant at thickening, stabilizing, and keeping things smooth. Made by treating regular cellulose (from wood pulp or cotton) with chemicals to make it dissolve in water - regular cellulose won't dissolve which is why you can't drink your wooden spoon! Food manufacturers use it to prevent ice cream from getting icy, stop sauces from separating, and give reduced-fat products a creamier mouthfeel. It's also in toothpaste (makes it the right consistency), and pharmaceutical tablets (binds ingredients together). Your body can't digest it at all - it passes straight through as dietary fiber, actually helping with digestion. Despite being 'modified', it's considered very safe since it's just restructured plant fiber.", originSummary: "🌳🧪 Made from plant cellulose (wood pulp or cotton) that's chemically modified with sodium chloroacetate to make it water-soluble. Natural origin but chemically processed.", riskSummary: "Safe and passes through the body undigested like dietary fiber. Approved globally with no safety concerns. Acts as beneficial fiber promoting gut health.", riskLevel: .lowRisk),

        // Sweeteners - LOW to MODERATE risk
        "e960": .init(displayName: "Stevia (Steviol glycosides)", shortSummary: "Natural zero-calorie sweetener from stevia plant - 200-300x sweeter than sugar.", whatItIs: "Natural zero-calorie sweetener from the stevia plant. About 200-300x sweeter than sugar.", originSummary: "Extracted and purified from stevia leaves, a plant native to South America.", riskSummary: "Safe plant-based alternative to sugar. No known health concerns at normal consumption.", riskLevel: .lowRisk),
        "e968": .init(displayName: "Erythritol", shortSummary: "Sugar alcohol with almost zero calories - doesn't spike blood sugar or harm teeth.", whatItIs: "Sugar alcohol with almost zero calories. Tastes like sugar but doesn't spike blood sugar or harm teeth.", originSummary: "Made by fermenting glucose, often from corn.", riskSummary: "Well tolerated. Very large amounts may cause mild digestive upset.", riskLevel: .lowRisk),
        "e420": .init(displayName: "Sorbitol", shortSummary: "Sugar alcohol in sugar-free sweets - can cause laxative effects in excess.", whatItIs: "Sugar alcohol used in sugar-free sweets and chewing gum. Provides sweetness with fewer calories.", originSummary: "Made from glucose, originally from mountain ash berries.", riskSummary: "Can cause laxative effects if consumed in excess (>20g). Products must carry a warning.", riskLevel: .moderateRisk),
        "e421": .init(displayName: "Mannitol", shortSummary: "Sugar alcohol in sugar-free sweets - watch for laxative effects.", whatItIs: "Sugar alcohol used in sugar-free confectionery. Provides sweetness without affecting blood sugar.", originSummary: "Made from fructose or extracted from seaweed.", riskSummary: "Can cause laxative effects if consumed in excess. Products must carry a warning.", riskLevel: .moderateRisk),
        "e965": .init(displayName: "Maltitol", shortSummary: "Sugar alcohol in sugar-free chocolate - can cause digestive issues in some people.", whatItIs: "Sugar alcohol commonly used in sugar-free chocolate and biscuits.", originSummary: "Made from maltose (malt sugar) derived from starch.", riskSummary: "Can cause significant digestive issues in some people. Limit intake to avoid discomfort.", riskLevel: .moderateRisk),
        "e967": .init(displayName: "Xylitol", shortSummary: "Sugar alcohol that's good for teeth - used in gum. TOXIC TO DOGS!", whatItIs: "Sugar alcohol that's actually good for teeth - used in sugar-free gum and dental products.", originSummary: "Usually made from birch bark or corn cobs.", riskSummary: "Safe for humans. Can cause digestive issues in excess. TOXIC TO DOGS - keep away from pets.", riskLevel: .moderateRisk),
        "e951": .init(displayName: "Aspartame", shortSummary: "Artificial sweetener 200x sweeter than sugar - not for people with PKU.", whatItIs: "An artificial sweetener about 200 times sweeter than sugar. Made from two amino acids, it's in most diet drinks. One of the most studied food additives ever!", originSummary: "🧪 Synthetic. Made from two amino acids.", riskSummary: "Safe for most people at normal consumption. NOT suitable for people with PKU (phenylketonuria).", riskLevel: .moderateRisk),
        "aspartame": .init(displayName: "Aspartame", shortSummary: "Artificial sweetener 200x sweeter than sugar - not for people with PKU.", whatItIs: "An artificial sweetener about 200 times sweeter than sugar. Made from two amino acids, it's in most diet drinks. One of the most studied food additives ever!", originSummary: "🧪 Synthetic. Made from two amino acids.", riskSummary: "Safe for most people at normal consumption. NOT suitable for people with PKU (phenylketonuria).", riskLevel: .moderateRisk),
        "e950": .init(displayName: "Acesulfame K", shortSummary: "Artificial sweetener often mixed with aspartame - can taste bitter.", whatItIs: "Artificial sweetener often combined with aspartame for a more sugar-like taste.", originSummary: "Synthetic.", riskSummary: "Approved as safe. Can have a bitter aftertaste at high concentrations.", riskLevel: .moderateRisk),
        "e955": .init(displayName: "Sucralose", shortSummary: "Artificial sweetener made from sugar - 600x sweeter and stable for cooking.", whatItIs: "Artificial sweetener made from sugar, about 600x sweeter. Stable for cooking.", originSummary: "Synthetic - modified sucrose molecule.", riskSummary: "Well tolerated. Some concerns about long-term effects, but approved as safe.", riskLevel: .moderateRisk),
        "e954": .init(displayName: "Saccharin", shortSummary: "Oldest artificial sweetener (1879) - 300x sweeter with metallic aftertaste.", whatItIs: "The oldest artificial sweetener, about 300x sweeter than sugar.", originSummary: "Synthetic. Discovered in 1879.", riskSummary: "Previous cancer concerns were disproved. Can have a metallic aftertaste.", riskLevel: .moderateRisk),

        // Preservatives - varied risk
        "e202": .init(displayName: "Potassium sorbate", shortSummary: "Effective mould and yeast preventer in cheese and wine - very safe.", whatItIs: "Effective preservative that prevents mould and yeast growth in cheese, wine, and baked goods.", originSummary: "Synthetic salt of sorbic acid, which occurs naturally in some berries.", riskSummary: "Very safe. One of the most studied and well-tolerated preservatives.", riskLevel: .lowRisk),
        "e200": .init(displayName: "Sorbic acid", shortSummary: "Natural preservative from rowan berries - prevents mould and yeast.", whatItIs: "Natural preservative that prevents mould and yeast growth.", originSummary: "Originally from rowan berries; now mostly synthetic.", riskSummary: "Very safe. Well tolerated with no known adverse effects.", riskLevel: .lowRisk),
        "e211": .init(displayName: "Sodium benzoate", shortSummary: "Preservative found in cranberries - stops bacteria and fungi growth.", whatItIs: "A preservative that stops bacteria and fungi from growing. Naturally found in cranberries and prunes, but usually made synthetically.", originSummary: "🧪 Synthetic. Related to benzoic acid found naturally in berries.", riskSummary: "Safe at permitted levels. Avoid combining with vitamin C in acidic conditions at high temperatures (rare in normal use).", riskLevel: .lowRisk),
        "sodium benzoate": .init(displayName: "Sodium benzoate", shortSummary: "Preservative found in cranberries - stops bacteria and fungi growth.", whatItIs: "A preservative that stops bacteria and fungi from growing. Naturally found in cranberries and prunes, but usually made synthetically.", originSummary: "🧪 Synthetic. Related to benzoic acid found naturally in berries.", riskSummary: "Safe at permitted levels. Avoid combining with vitamin C in acidic conditions at high temperatures (rare in normal use).", riskLevel: .lowRisk),
        "e220": .init(displayName: "Sulphur dioxide", shortSummary: "Preservative in wine and dried fruits - can trigger asthma in sensitive people.", whatItIs: "Preservative and antioxidant used in wine, dried fruits, and some juices.", originSummary: "Synthetic gas.", riskSummary: "Can trigger asthma or allergic reactions in sensitive individuals. Must be declared on labels.", riskLevel: .moderateRisk),
        "e223": .init(displayName: "Sodium metabisulphite", shortSummary: "Preservative in wine and dried fruits - watch if asthmatic or sulphite-sensitive.", whatItIs: "Preservative and antioxidant used in wine, dried fruits, and processed foods.", originSummary: "Synthetic.", riskSummary: "Can trigger reactions in sulphite-sensitive people (especially asthmatics). Must be declared on labels.", riskLevel: .moderateRisk),
        "e250": .init(displayName: "Sodium nitrite", shortSummary: "Curing salt in bacon and ham - prevents botulism but limit processed meat intake.", whatItIs: "Curing salt used in bacon, ham, and processed meats. Prevents deadly botulism bacteria and gives meat its pink colour.", originSummary: "Synthetic.", riskSummary: "Essential for meat safety but can form nitrosamines when cooked at high heat. Limit processed meat intake.", riskLevel: .highRisk),
        "e251": .init(displayName: "Sodium nitrate", shortSummary: "Curing agent in processed meats - converts to nitrite. Limit intake.", whatItIs: "Curing agent used in some cured meats. Converts to nitrite during curing.", originSummary: "Synthetic or from mineral sources.", riskSummary: "Similar concerns to nitrite. Limit intake of processed meats.", riskLevel: .highRisk),

        // Colours - varied risk (synthetic colours higher risk)
        "e160b": .init(displayName: "Annatto", shortSummary: "Natural orange colour from achiote tree seeds - used for thousands of years as body paint and food dye.", whatItIs: "A vibrant natural colouring extracted from the spiky red seed pods of the achiote tree, native to Central and South America. Indigenous peoples have used it for thousands of years - not just as food coloring but also as body paint, fabric dye, and even sun protection! The seeds are covered in a waxy red-orange coating packed with carotenoid pigments (the same beneficial compounds in carrots). Today it's what makes Cheddar cheese that appealing orange-yellow color (fun fact: cheese is naturally pale!), gives Red Leicester its distinctive hue, and adds warm tones to butter, snacks, and processed foods. Unlike synthetic dyes, annatto comes with bonus antioxidants. It's also called 'achiote' in Latin American cooking where the seeds flavor rice dishes and marinades.", originSummary: "🌳🌶️ Extracted from the waxy red coating on seeds of the achiote tree (Bixa orellana) grown in tropical regions. The seeds are harvested, ground, and extracted with oil or water to concentrate the color compounds.", riskSummary: "Natural colour generally recognized as safe. Contains beneficial carotenoids (same antioxidants as in carrots). Rare sensitivity has been reported in some individuals, but vastly safer than synthetic dyes.", riskLevel: .lowRisk),
        "e162": .init(displayName: "Beetroot red", shortSummary: "Natural red colour extracted from beetroot - completely safe.", whatItIs: "Natural red colour extracted from beetroot.", originSummary: "From beetroot juice.", riskSummary: "Completely safe and natural.", riskLevel: .noRisk),
        "e140": .init(displayName: "Chlorophyll", shortSummary: "Natural green pigment from plants - the same stuff that makes leaves green.", whatItIs: "Natural green colour - the same pigment that makes plants green.", originSummary: "Extracted from nettles, grass, or alfalfa.", riskSummary: "Completely safe and natural.", riskLevel: .noRisk),
        "e102": .init(displayName: "Tartrazine (Yellow 5)", shortSummary: "Synthetic yellow dye - may affect activity in children. Requires warning label.", whatItIs: "A bright yellow synthetic dye also known as 'Yellow 5'. It's what gives custard and fizzy drinks that sunny colour. Some people are sensitive to it.", originSummary: "🧪 Synthetic azo dye made from petroleum.", riskSummary: "May affect activity and attention in some children. Products must carry a warning in the UK/EU.", riskLevel: .highRisk),
        "tartrazine": .init(displayName: "Tartrazine (Yellow 5)", shortSummary: "Synthetic yellow dye - may affect activity in children. Requires warning label.", whatItIs: "A bright yellow synthetic dye also known as 'Yellow 5'. It's what gives custard and fizzy drinks that sunny colour. Some people are sensitive to it.", originSummary: "🧪 Synthetic azo dye made from petroleum.", riskSummary: "May affect activity and attention in some children. Products must carry a warning in the UK/EU.", riskLevel: .highRisk),
        "e110": .init(displayName: "Sunset Yellow", shortSummary: "Synthetic orange-yellow dye - may affect children. Requires warning label.", whatItIs: "Synthetic orange-yellow dye used in soft drinks and confectionery.", originSummary: "Synthetic azo dye.", riskSummary: "May affect activity and attention in some children. Requires warning label.", riskLevel: .highRisk),
        "e129": .init(displayName: "Allura Red", shortSummary: "Synthetic red dye in sweets and drinks - may affect children. Requires warning.", whatItIs: "Synthetic red dye widely used in soft drinks, sweets, and sauces.", originSummary: "Synthetic azo dye.", riskSummary: "May affect activity and attention in some children. Requires warning label.", riskLevel: .highRisk),
        "e104": .init(displayName: "Quinoline Yellow", shortSummary: "Synthetic greenish-yellow dye - may affect children. Requires warning label.", whatItIs: "Synthetic greenish-yellow dye used in desserts and ice lollies.", originSummary: "Synthetic.", riskSummary: "May affect activity and attention in some children. Requires warning label.", riskLevel: .highRisk),
        "e122": .init(displayName: "Carmoisine (Azorubine)", shortSummary: "Synthetic red dye in jams and sweets - may affect children. Requires warning.", whatItIs: "Synthetic red dye used in jams, jellies, and confectionery.", originSummary: "Synthetic azo dye.", riskSummary: "May affect activity and attention in some children. Requires warning label.", riskLevel: .highRisk),
        "e124": .init(displayName: "Ponceau 4R", shortSummary: "Synthetic red dye - may affect children. Requires warning label.", whatItIs: "Synthetic red dye used in desserts and meat products.", originSummary: "Synthetic azo dye.", riskSummary: "May affect activity and attention in some children. Requires warning label.", riskLevel: .highRisk),
        "e133": .init(displayName: "Brilliant Blue", shortSummary: "Synthetic blue dye in sweets - safer than azo dyes but still synthetic.", whatItIs: "Synthetic blue dye used in confectionery and drinks.", originSummary: "Synthetic.", riskSummary: "Generally considered safer than azo dyes. Permitted within limits.", riskLevel: .moderateRisk),
        "e150a": .init(displayName: "Plain caramel", shortSummary: "Brown colour from heated sugar - same as homemade caramel. Safe and natural.", whatItIs: "Brown colour made by heating sugar - the same process as making caramel at home.", originSummary: "Made from heated sugar.", riskSummary: "Safe and natural.", riskLevel: .noRisk),
        "e150d": .init(displayName: "Sulphite ammonia caramel", shortSummary: "Brown colour in cola - made from sugar treated with ammonia and sulphites.", whatItIs: "Brown colour used in cola drinks and soy sauce.", originSummary: "Made from sugar treated with ammonia and sulphites.", riskSummary: "Contains 4-MEI as a byproduct. Approved as safe within limits.", riskLevel: .moderateRisk),

        // Flavour enhancers
        "e621": .init(displayName: "MSG (Monosodium glutamate)", shortSummary: "Umami flavour enhancer found naturally in tomatoes and parmesan - safe despite bad reputation.", whatItIs: "The famous 'umami' flavour enhancer. Despite its bad reputation, it's just a salt of glutamic acid - an amino acid found naturally in tomatoes, parmesan, and your own body!", originSummary: "Made by fermenting starches - the same glutamate found naturally in tomatoes and parmesan.", riskSummary: "Safe for most people. 'Chinese Restaurant Syndrome' was never scientifically proven. Some sensitive individuals may react.", riskLevel: .lowRisk),
        "monosodium glutamate": .init(displayName: "MSG (Monosodium glutamate)", shortSummary: "Umami flavour enhancer found naturally in tomatoes and parmesan - safe despite bad reputation.", whatItIs: "The famous 'umami' flavour enhancer. Despite its bad reputation, it's just a salt of glutamic acid - an amino acid found naturally in tomatoes, parmesan, and your own body!", originSummary: "Made by fermenting starches - the same glutamate found naturally in tomatoes and parmesan.", riskSummary: "Safe for most people. 'Chinese Restaurant Syndrome' was never scientifically proven. Some sensitive individuals may react.", riskLevel: .lowRisk),
        "msg": .init(displayName: "MSG (Monosodium glutamate)", shortSummary: "Umami flavour enhancer found naturally in tomatoes and parmesan - safe despite bad reputation.", whatItIs: "The famous 'umami' flavour enhancer. Despite its bad reputation, it's just a salt of glutamic acid - an amino acid found naturally in tomatoes, parmesan, and your own body!", originSummary: "Made by fermenting starches - the same glutamate found naturally in tomatoes and parmesan.", riskSummary: "Safe for most people. 'Chinese Restaurant Syndrome' was never scientifically proven. Some sensitive individuals may react.", riskLevel: .lowRisk),

        // Antioxidants
        "e320": .init(displayName: "BHA (Butylated hydroxyanisole)", shortSummary: "Synthetic antioxidant preventing rancidity - studies raised concerns, being phased out.", whatItIs: "Synthetic antioxidant that prevents fats and oils from going rancid.", originSummary: "Synthetic.", riskSummary: "Some studies raised concerns. Strictly limited in foods. Being phased out in favour of natural alternatives.", riskLevel: .highRisk),
        "e321": .init(displayName: "BHT (Butylated hydroxytoluene)", shortSummary: "Synthetic antioxidant preventing rancidity - studies raised concerns, being phased out.", whatItIs: "Synthetic antioxidant that prevents fats and oils from going rancid.", originSummary: "Synthetic.", riskSummary: "Some studies raised concerns. Strictly limited in foods. Being phased out in favour of natural alternatives.", riskLevel: .highRisk),

        // Phosphates
        "e338": .init(displayName: "Phosphoric acid", shortSummary: "The acid that gives cola its bite - safe in moderation but erodes teeth and may affect bones with excessive intake.", whatItIs: "The tangy, sharp acid that gives Coca-Cola and other colas their distinctive bite - without it, cola would taste sickeningly sweet! It's a strong acid (pH around 2.8, similar to stomach acid) that provides acidity regulation in processed foods. Food manufacturers also use it to prevent discoloration in potatoes and to clarify sugar. Here's the thing though: while it's safe in moderate amounts, regular high consumption from fizzy drinks can affect your teeth (the acid erodes enamel) and potentially interfere with calcium absorption, which is why excessive cola drinking has been linked to weaker bones. The phosphoric acid in one cola isn't a problem - it's drinking multiple cans daily for years that adds up.", originSummary: "🧪 Synthesized industrially from phosphate rock treated with sulfuric acid. Clear, colorless liquid when diluted for food use.", riskSummary: "Safe at typical food levels. High cola consumption may contribute to tooth enamel erosion and potentially affect bone health over time due to phosphate-calcium balance. Moderate consumption is fine.", riskLevel: .moderateRisk),
        "e450": .init(displayName: "Diphosphates", shortSummary: "Swiss Army knife of food chemistry - keeps cheese smooth and ham moist. High intake from processed foods may stress kidneys.", whatItIs: "A family of synthetic phosphate salts that do multiple jobs in processed foods - they're the Swiss Army knife of food chemistry! In processed cheese, they stop the fat from separating and create that smooth, melty texture. In processed meats like ham and sausages, they help retain moisture and improve texture (that's why cheap ham looks so pink and uniform). They're also in baking powder where they provide the 'double-acting' effect - bubbles when mixed AND when heated. Your body needs phosphorus (it's in your bones and DNA), but the concern is that Western diets already contain loads of phosphates from processed foods. While safe within limits, very high intake from eating mostly processed food could potentially stress kidneys over time, especially in people with existing kidney problems.", originSummary: "🧪 Synthesized from phosphoric acid and various minerals (sodium, potassium, calcium). A family of related compounds (E450i through E450vii) with slightly different properties.", riskSummary: "Safe within permitted limits. Generally well-tolerated. Very high phosphate intake from eating mostly processed foods may be a concern for kidney health in susceptible individuals. Moderate consumption from varied diet is fine.", riskLevel: .moderateRisk),
        "e451": .init(displayName: "Triphosphates", shortSummary: "Phosphate compounds preventing puddles in defrosted prawns - help seafood and meat retain water.", whatItIs: "Close chemical cousins to diphosphates (E450), these synthetic phosphate compounds serve similar purposes - improving texture in processed meats, helping baked goods rise, and preventing processed cheese from turning into an oily mess. Food processors inject them into chicken, fish, and seafood to help retain water (which also increases the weight you're paying for!). They're particularly common in frozen seafood where they prevent 'drip loss' when thawed - that puddle of water in your defrosted prawns would be much bigger without triphosphates. Like all phosphates, they're safe in moderation but contribute to overall dietary phosphate load, which nutritionists suggest we should moderate by eating more whole foods and fewer ultra-processed products.", originSummary: "🧪 Synthesized from phosphoric acid, similar to diphosphates but with three phosphate groups. Sodium and potassium forms are most common in food.", riskSummary: "Safe within permitted limits. Concerns are similar to other phosphates - very high intake from processed foods may affect mineral balance and kidney function in susceptible people. Choose fresh over processed when possible.", riskLevel: .moderateRisk),

        // Misc
        "e570": .init(displayName: "Fatty acids", shortSummary: "Natural fats from plants or animals - used as anti-caking agents.", whatItIs: "Natural fats used as anti-caking agents and in food processing.", originSummary: "From plant or animal fats.", riskSummary: "Safe and natural.", riskLevel: .noRisk),
        "fatty acids": .init(displayName: "Fatty acids", shortSummary: "Natural fats from plants or animals - used as anti-caking agents.", whatItIs: "Natural fats used as anti-caking agents and in food processing.", originSummary: "From plant or animal fats.", riskSummary: "Safe and natural.", riskLevel: .noRisk),
        "caffeine": .init(displayName: "Caffeine", shortSummary: "Natural stimulant from coffee and tea - safe for most adults in moderation.", whatItIs: "Natural stimulant found in coffee, tea, and chocolate. Added to energy drinks and some soft drinks.", originSummary: "From coffee beans, tea leaves, or synthetic.", riskSummary: "Safe for most adults in moderation. Limit intake if sensitive to stimulants, pregnant, or for children.", riskLevel: .moderateRisk),
        "e471": .init(displayName: "Mono- and diglycerides", shortSummary: "Emulsifiers helping oil and water mix - in bread, ice cream, margarine. Very safe.", whatItIs: "Emulsifiers that help oil and water mix. Used in bread, ice cream, and margarine.", originSummary: "From vegetable or animal fats.", riskSummary: "Safe and well tolerated. One of the most common emulsifiers.", riskLevel: .lowRisk),

        // More common additives with proper descriptions
        "e441": .init(displayName: "Gelatin", shortSummary: "Boiled animal bones and skin - makes jelly wobble. Not for vegans!", whatItIs: "Made by boiling animal bones, skin, and connective tissue. It's what makes jelly wobble and gummy bears chewy. Not one for the vegans!", originSummary: "🐄 Sourced from animals - bones, skin, and connective tissue from pigs or cows.", riskSummary: "Safe to consume. Not suitable for vegetarians, vegans, or those avoiding pork/beef for religious reasons.", riskLevel: .lowRisk),
        "gelatin": .init(displayName: "Gelatin", shortSummary: "Boiled animal bones and skin - makes jelly wobble. Not for vegans!", whatItIs: "Made by boiling animal bones, skin, and connective tissue. It's what makes jelly wobble and gummy bears chewy. Not one for the vegans!", originSummary: "🐄 Sourced from animals - bones, skin, and connective tissue from pigs or cows.", riskSummary: "Safe to consume. Not suitable for vegetarians, vegans, or those avoiding pork/beef for religious reasons.", riskLevel: .lowRisk),
        "gelatine": .init(displayName: "Gelatin", shortSummary: "Liquified animal collagen from bones and skin - makes jelly wobble and gummy bears chewy.", whatItIs: "Made by boiling animal bones, skin, and connective tissue for hours until they break down into collagen. It's what makes jelly wobble, gummy bears chewy, and marshmallows fluffy. Your grandmother's aspic? That's gelatin. The pharmaceutical industry uses tons of it for pill capsules. It's essentially liquified animal parts that solidify when cold - which sounds horrifying but has been used in cooking for centuries. Not one for the vegans! Fun fact: high-quality gelatin comes from fish bones in some Asian cuisines, giving it a clearer appearance.", originSummary: "🐄 Sourced from animals - bones, skin, and connective tissue from pigs or cows. Boiled for hours to extract collagen, then dried into powder or sheets.", riskSummary: "Safe to consume and actually beneficial for joints and skin due to collagen content. Not suitable for vegetarians, vegans, or those avoiding pork/beef for religious reasons.", riskLevel: .lowRisk),

        "e418": .init(displayName: "Gellan gum", shortSummary: "Vegan gelling agent from bacteria - creates firm, heat-stable gels for plant-based foods.", whatItIs: "A plant-based gelling agent discovered by scientists at Kelco in the 1970s while studying microorganisms. It's now the vegan go-to for creating those satisfying firm gels in plant-based desserts and alt-dairy products. Creates incredibly clear, firm gels that don't melt easily - much more heat-stable than gelatin. Food scientists love it because a tiny amount goes a long way, and it works brilliantly in both hot and cold applications. You'll find it holding together vegan jellies, plant milks, and even some meal replacement drinks.", originSummary: "🧫 Produced by bacterial fermentation using Sphingomonas elodea bacteria. The bacteria produce the gum as they digest sugar - similar to how yogurt bacteria make lactic acid.", riskSummary: "Safe and vegan-friendly. A brilliant alternative to animal-derived gelatin with no known side effects. Nature meets food science!", riskLevel: .noRisk),

        "e440": .init(displayName: "Pectin", shortSummary: "Natural plant fiber from apple cores and orange peel - makes jam set beautifully.", whatItIs: "Natural plant fibre that makes jams and jellies set - it's why your homemade strawberry jam turns from liquid to spreadable. Found naturally in the cell walls of fruits, particularly in apple cores and orange peel (the bits you normally throw away!). When you heat fruit with sugar and pectin, the pectin molecules form a network that traps water, creating that perfect jammy texture. Commercial pectin lets you make jam with less sugar than traditional recipes required. It's also added to fruit drinks to give body, and to dairy desserts for a smooth, stable texture. Your body can't digest it, so it passes through as beneficial dietary fibre.", originSummary: "🍎🍊 Extracted from apple pomace (the leftover pulp from cider-making) or citrus peel. These are usually waste products from juice production, making pectin a sustainable ingredient!", riskSummary: "Completely safe and natural. Actually a beneficial dietary fibre that can help with digestive health and cholesterol management. One of the healthiest additives around.", riskLevel: .noRisk),
        "pectin": .init(displayName: "Pectin", shortSummary: "Natural plant fiber from apple cores and orange peel - makes jam set beautifully.", whatItIs: "Natural plant fibre that makes jams and jellies set - it's why your homemade strawberry jam turns from liquid to spreadable. Found naturally in the cell walls of fruits, particularly in apple cores and orange peel (the bits you normally throw away!). When you heat fruit with sugar and pectin, the pectin molecules form a network that traps water, creating that perfect jammy texture. Commercial pectin lets you make jam with less sugar than traditional recipes required. It's also added to fruit drinks to give body, and to dairy desserts for a smooth, stable texture. Your body can't digest it, so it passes through as beneficial dietary fibre.", originSummary: "🍎🍊 Extracted from apple pomace (the leftover pulp from cider-making) or citrus peel. These are usually waste products from juice production, making pectin a sustainable ingredient!", riskSummary: "Completely safe and natural. Actually a beneficial dietary fibre that can help with digestive health and cholesterol management. One of the healthiest additives around.", riskLevel: .noRisk),

        "e500": .init(displayName: "Sodium bicarbonate (Baking soda)", shortSummary: "Good old baking soda from your cupboard - makes cakes rise. Used since ancient Egypt!", whatItIs: "Good old baking soda! The exact same stuff you have in your kitchen cupboard for baking cakes. When it heats up, it releases carbon dioxide bubbles that make your bread fluffy and your cakes rise. It's been used in cooking since ancient Egypt - they found it in natron deposits along the Nile. In processed foods, it serves the same job: makes things rise, neutralizes acidity, and keeps foods tender. One of the few additives that's genuinely just what it says on the tin.", originSummary: "🪨 Mineral-based sodium compound. Can be mined from natural deposits or produced industrially from salt and limestone. The same stuff in your baking cupboard.", riskSummary: "Completely safe. This is literally the same baking soda you use at home for cooking and cleaning. As natural as additives get.", riskLevel: .noRisk),
        "sodium bicarbonate": .init(displayName: "Sodium bicarbonate (Baking soda)", shortSummary: "Good old baking soda from your cupboard - makes cakes rise. Used since ancient Egypt!", whatItIs: "Good old baking soda! The exact same stuff you have in your kitchen cupboard for baking cakes. When it heats up, it releases carbon dioxide bubbles that make your bread fluffy and your cakes rise. It's been used in cooking since ancient Egypt - they found it in natron deposits along the Nile. In processed foods, it serves the same job: makes things rise, neutralizes acidity, and keeps foods tender. One of the few additives that's genuinely just what it says on the tin.", originSummary: "🪨 Mineral-based sodium compound. Can be mined from natural deposits or produced industrially from salt and limestone. The same stuff in your baking cupboard.", riskSummary: "Completely safe. This is literally the same baking soda you use at home for cooking and cleaning. As natural as additives get.", riskLevel: .noRisk),
        "bicarbonate of soda": .init(displayName: "Sodium bicarbonate (Baking soda)", shortSummary: "Good old baking soda from your cupboard - makes cakes rise. Used since ancient Egypt!", whatItIs: "Good old baking soda! The exact same stuff you have in your kitchen cupboard for baking cakes. When it heats up, it releases carbon dioxide bubbles that make your bread fluffy and your cakes rise. It's been used in cooking since ancient Egypt - they found it in natron deposits along the Nile. In processed foods, it serves the same job: makes things rise, neutralizes acidity, and keeps foods tender. One of the few additives that's genuinely just what it says on the tin.", originSummary: "🪨 Mineral-based sodium compound. Can be mined from natural deposits or produced industrially from salt and limestone. The same stuff in your baking cupboard.", riskSummary: "Completely safe. This is literally the same baking soda you use at home for cooking and cleaning. As natural as additives get.", riskLevel: .noRisk),

        "e503": .init(displayName: "Ammonium carbonate", shortSummary: "Baker's ammonia from medieval times - evaporates completely during baking leaving crispy texture.", whatItIs: "An old-school raising agent that's been used in baking since your great-great-grandmother's time - also called 'baker's ammonia' or hartshorn. When heated in the oven, it completely breaks down into ammonia gas, carbon dioxide, and water vapor, which all evaporate away leaving absolutely no residue in your food. This magical disappearing act makes it perfect for flat, crispy baked goods like crackers, cookies, and Swedish dream cookies where you want crunch without any baking powder aftertaste. Professional bakers love it because it creates incredibly light, airy textures. The ammonia smell during baking can be strong (like walking past a stable!) but vanishes completely once baked.", originSummary: "🪨 Synthetic ammonia-based mineral salt. Also known as baker's ammonia. Used in baking since medieval times when it was extracted from deer antlers (hence 'hartshorn').", riskSummary: "Completely safe. 100% dissipates during baking leaving zero residue in the finished product. Any lingering smell disappears as the baked goods cool.", riskLevel: .noRisk),

        "e170": .init(displayName: "Calcium carbonate (Chalk)", shortSummary: "Ground-up chalk, limestone, or seashells - adds white colour and fortifies with calcium.", whatItIs: "Literally ground-up chalk, limestone, or marble - the same compound that forms seashells, coral reefs, and the White Cliffs of Dover! In food, it serves triple duty: adds brilliant white colour, stops powders from clumping, and fortifies foods with calcium. You'll find it in flour (to boost calcium), chewing gum (for texture), and as an antacid in your medicine cabinet. It also neutralizes acidity in some foods and wines. Fun fact: it's what makes cave formations - stalactites and stalagmites are pure calcium carbonate deposited over thousands of years by dripping water. Your body uses calcium carbonate to build bones and teeth, so this is one of the few additives that's actually nutritious!", originSummary: "🪨⚪ Natural mineral - the exact same compound found in limestone quarries, chalk cliffs, seashells, and marble. Ground into fine white powder for food use.", riskSummary: "Completely safe and provides dietary calcium. Your body needs this stuff! It's literally rock-ground minerals from the earth.", riskLevel: .noRisk),

        "e270": .init(displayName: "Lactic acid", shortSummary: "The tangy acid from yogurt and sauerkraut - your muscles make it during exercise too!", whatItIs: "The tangy acid that gives yogurt, sourdough, and sauerkraut their distinctive sour kick. It's created by friendly bacteria during fermentation - the same process humans have used for thousands of years to preserve food. When bacteria munch on sugars or starches, they produce lactic acid as a byproduct, which lowers the pH and prevents nasty bacteria from growing. In processed foods, it adds tartness and extends shelf life naturally. Your own muscles produce lactic acid during intense exercise (that burning feeling!). Food manufacturers love it because it's gentle, natural, and super effective. It's also used in cosmetics and as a natural preservative in everything from pickles to candy.", originSummary: "🥛🧫 Produced by fermenting sugars using Lactobacillus bacteria - the exact same process that transforms milk into yogurt and cabbage into sauerkraut. Can also be extracted from fermented milk products.", riskSummary: "Completely safe and natural. Your body produces and processes lactic acid every day. One of the oldest food preservation methods known to humanity.", riskLevel: .noRisk),
        "lactic acid": .init(displayName: "Lactic acid", shortSummary: "The tangy acid from yogurt and sauerkraut - your muscles make it during exercise too!", whatItIs: "The tangy acid that gives yogurt, sourdough, and sauerkraut their distinctive sour kick. It's created by friendly bacteria during fermentation - the same process humans have used for thousands of years to preserve food. When bacteria munch on sugars or starches, they produce lactic acid as a byproduct, which lowers the pH and prevents nasty bacteria from growing. In processed foods, it adds tartness and extends shelf life naturally. Your own muscles produce lactic acid during intense exercise (that burning feeling!). Food manufacturers love it because it's gentle, natural, and super effective. It's also used in cosmetics and as a natural preservative in everything from pickles to candy.", originSummary: "🥛🧫 Produced by fermenting sugars using Lactobacillus bacteria - the exact same process that transforms milk into yogurt and cabbage into sauerkraut. Can also be extracted from fermented milk products.", riskSummary: "Completely safe and natural. Your body produces and processes lactic acid every day. One of the oldest food preservation methods known to humanity.", riskLevel: .noRisk),

        "e296": .init(displayName: "Malic acid", shortSummary: "Mouth-puckering acid from green apples - makes Sour Patch Kids and Warheads sour!", whatItIs: "The mouth-puckering acid that gives green apples (especially Granny Smiths) their signature sour punch! Bite into an unripe apple and that zing you feel? That's malic acid at work. It's found naturally in almost all fruits but especially apples, cherries, and grapes. Food manufacturers add it to sweets and drinks to create that addictive sour flavour in things like Warheads, Sour Patch Kids, and fizzy drinks. It enhances fruit flavours and makes them taste 'brighter' and more refreshing. Your body also produces small amounts of malic acid as part of the Krebs cycle (the process that generates energy in your cells). Fun fact: wine enthusiasts talk about malic acid levels because it affects wine flavour - high malic acid means sharper, greener taste.", originSummary: "🍏 Found naturally in apples (especially green ones!), cherries, grapes, and many other fruits. Commercially produced by fermenting starches or synthesized from petroleum derivatives (though chemically identical).", riskSummary: "Completely safe and natural. Your body produces and metabolizes malic acid daily as part of normal energy production. Been safely used in food for decades.", riskLevel: .noRisk),
        "malic acid": .init(displayName: "Malic acid", shortSummary: "Mouth-puckering acid from green apples - makes Sour Patch Kids and Warheads sour!", whatItIs: "The mouth-puckering acid that gives green apples (especially Granny Smiths) their signature sour punch! Bite into an unripe apple and that zing you feel? That's malic acid at work. It's found naturally in almost all fruits but especially apples, cherries, and grapes. Food manufacturers add it to sweets and drinks to create that addictive sour flavour in things like Warheads, Sour Patch Kids, and fizzy drinks. It enhances fruit flavours and makes them taste 'brighter' and more refreshing. Your body also produces small amounts of malic acid as part of the Krebs cycle (the process that generates energy in your cells). Fun fact: wine enthusiasts talk about malic acid levels because it affects wine flavour - high malic acid means sharper, greener taste.", originSummary: "🍏 Found naturally in apples (especially green ones!), cherries, grapes, and many other fruits. Commercially produced by fermenting starches or synthesized from petroleum derivatives (though chemically identical).", riskSummary: "Completely safe and natural. Your body produces and metabolizes malic acid daily as part of normal energy production. Been safely used in food for decades.", riskLevel: .noRisk),

        "e334": .init(displayName: "Tartaric acid", shortSummary: "Wine crystals ('wine diamonds') from grapes - makes cream of tartar for meringues.", whatItIs: "A natural acid discovered in wine-making - those sparkly crystals that sometimes form in wine bottles or at the bottom of wine barrels? That's crystallized tartaric acid (called 'wine diamonds')! Grapes are loaded with it, which is why it's been central to wine-making for thousands of years. In food, it adds a pleasantly sharp, fruity sourness to sweets, fizzy drinks, and baking powder. Bakers combine it with baking soda to create cream of tartar, which stabilizes whipped egg whites for perfect meringues and soufflés. It's less harsh than citric acid, giving a smoother, more sophisticated tartness. Fun fact: the name comes from 'tartar', the crusty sediment left in wine casks after fermentation.", originSummary: "🍇 Extracted from grapes or produced as a byproduct during wine fermentation. Those crystals in your wine bottle? That's tartaric acid! Can also be synthesized for commercial use.", riskSummary: "Completely safe and natural. Wine-makers have been working with it for millennia. One of the gentlest food acids.", riskLevel: .noRisk),

        "e262": .init(displayName: "Sodium acetate", shortSummary: "Salt form of vinegar - adds mild tang to salt-and-vinegar crisps without dripping acidity.", whatItIs: "The salt form of acetic acid (the stuff that makes vinegar taste like vinegar). When you neutralize vinegar with sodium bicarbonate (baking soda), you get sodium acetate and that satisfying fizz! It adds a mild vinegary tang to salt-and-vinegar crisps, pickles, and savoury snacks without making them drippingly acidic. It also acts as a preservative by lowering pH just enough to discourage bacterial growth. Interestingly, sodium acetate is also used in those reusable hand warmers - when you flex the metal disc, it triggers crystallization which releases heat. But in food, it's perfectly safe and just adds gentle acidity and preservation.", originSummary: "🧪 Derived from vinegar (acetic acid) reacted with sodium carbonate or sodium hydroxide. Essentially vinegar's less acidic cousin.", riskSummary: "Completely safe. It's essentially the salt form of vinegar, one of humanity's oldest preservatives. Your body metabolizes it just like regular vinegar.", riskLevel: .noRisk),

        "e150c": .init(displayName: "Ammonia caramel", shortSummary: "Dark brown colour in cola made from sugar + ammonia - more stable than plain caramel.", whatItIs: "Dark brown colouring made by heating sugar with ammonia compounds - basically caramel with a chemistry twist. This is what gives cola drinks their distinctive deep brown colour, plus soy sauce, brown bread, and dark beers their rich hues. Unlike plain caramel (E150a) which you could make at home, this version involves industrial processing with ammonia to create colours that won't fade and work in acidic conditions like soft drinks. The process creates a byproduct called 4-methylimidazole (4-MEI) which sounds scary but is present in such tiny amounts it's considered safe. Food scientists prefer it over plain caramel because it's more stable and consistent batch-to-batch.", originSummary: "🧪🍬 Made from sugar (usually glucose or sucrose) heated with ammonia and sulphites under controlled industrial conditions. More complex chemistry than your stovetop caramel!", riskSummary: "Safe within permitted limits. Contains traces of 4-MEI as a byproduct, but studies show the amounts in food are far below any level of concern. Extensively tested and approved.", riskLevel: .lowRisk),

        "e171": .init(displayName: "Titanium dioxide", shortSummary: "Bright white powder in icing and sweets - same as white paint! Banned in EU 2022.", whatItIs: "An intensely bright white powder used to make foods brilliantly white - think icing sugar, white chocolate, and those suspiciously white sweets. It's the same titanium compound used in white paint, sunscreen, and toothpaste! The food industry loves it because just a tiny amount creates that perfect, pure white colour that makes products look 'premium'. However, here's the plot twist: the EU banned it in 2022 over concerns about nanoparticles potentially accumulating in the body, though the evidence wasn't conclusive. It's still legal in the US, UK (post-Brexit), and many other countries. The debate continues in the scientific community - some say it's perfectly safe, others prefer the precautionary approach.", originSummary: "⚪🪨 Mineral-based pigment derived from titanium ore (ilmenite or rutile). Ground into extremely fine particles to maximize whiteness and opacity.", riskSummary: "Banned in the EU since August 2022 due to concerns about nanoparticles. Still permitted in the UK, US, and many other countries. The science is ongoing - no definitive proof of harm, but uncertainty led to EU's ban.", riskLevel: .highRisk),

        "e172": .init(displayName: "Iron oxides", shortSummary: "Natural rust and earth pigments from cave painting times - provides trace iron!", whatItIs: "Natural earth pigments that have coloured pottery, cave paintings, and food for thousands of years. These are the exact same iron compounds that make rust orange-red, give red clay its colour, and create those stunning rust-red landscapes in places like Arizona. Food-grade iron oxides range from yellow (like ochre) through red (like terracotta) to brown and black, giving confectioners an artist's palette of natural earth tones. You'll find them decorating cakes, tinting pasta (yes, some 'tomato' pasta uses iron oxide!), and colouring sweets. They're completely inert - your digestive system can't break them down, so they pass straight through unchanged. Bonus: they actually provide a tiny bit of dietary iron!", originSummary: "🪨🎨 Natural mineral compounds - literally rust and earth pigments. The same iron oxides found in red clay, ochre, and the rust on old iron gates. Purified for food use.", riskSummary: "Completely safe and natural. Humans have been using these pigments since prehistoric cave paintings. Chemically inert and even provides trace amounts of iron.", riskLevel: .noRisk),

        "e163": .init(displayName: "Anthocyanins", shortSummary: "Purple/red pigments from blueberries and strawberries - powerful antioxidants with health benefits!", whatItIs: "The gorgeous purple and red pigments that make blueberries blue and strawberries red. These are powerful antioxidants that give berries their health benefits. When you eat foods with anthocyanins, you're getting the same beneficial compounds found in superfoods.", originSummary: "🫐 Extracted from purple and red fruits like berries, grapes, and red cabbage. Nature's own food coloring!", riskSummary: "Completely safe and natural. These are the same pigments in blueberries with actual health benefits.", riskLevel: .noRisk),
        "anthocyanins": .init(displayName: "Anthocyanins", shortSummary: "Purple/red pigments from blueberries and strawberries - powerful antioxidants with health benefits!", whatItIs: "The gorgeous purple and red pigments that make blueberries blue and strawberries red. These are powerful antioxidants that give berries their health benefits. When you eat foods with anthocyanins, you're getting the same beneficial compounds found in superfoods.", originSummary: "🫐 Extracted from purple and red fruits like berries, grapes, and red cabbage. Nature's own food coloring!", riskSummary: "Completely safe and natural. These are the same pigments in blueberries with actual health benefits.", riskLevel: .noRisk),

        "e160c": .init(displayName: "Paprika extract", shortSummary: "Natural orange-red colour from sweet red peppers - with bonus antioxidants!", whatItIs: "A vibrant natural colouring extracted from sweet red peppers - the same paprika you sprinkle on devilled eggs or Hungarian goulash! It provides beautiful orange-red hues without adding any spicy heat (food companies use mild, sweet pepper varieties). Unlike synthetic dyes, paprika extract comes with bonus antioxidants called carotenoids, which are actually good for you. Food manufacturers love it for colouring cheese, crisps, sauces, and processed meats because it creates that appealing warm orange-red glow consumers associate with quality and flavour. Fun fact: Spanish paprika gets its colour intensity from the amount of time the peppers spend drying in the sun - the longer they dry, the deeper the red!", originSummary: "🌶️ Extracted from sweet red paprika peppers (Capsicum annuum). The peppers are dried, ground, and then extracted with solvents to concentrate the colour compounds.", riskSummary: "Completely safe and natural. Contains beneficial carotenoids (the same antioxidants in carrots). One of the healthiest colour additives available.", riskLevel: .noRisk),

        "e100": .init(displayName: "Curcumin (Turmeric)", shortSummary: "Golden-yellow turmeric pigment from 4,000 years of Indian cooking - stains clothes forever!", whatItIs: "The vivid golden-yellow pigment from turmeric root - the same spice that makes curry powder yellow and stains your clothes permanently if you spill it! Turmeric has been used in Indian cooking for over 4,000 years, and curcumin is the compound responsible for its colour and many of its health benefits. Food manufacturers extract and concentrate it to create natural yellow colouring for mustard, cheese, butter, cakes, and curry sauces. It's having a moment in wellness circles due to its anti-inflammatory properties, though you'd need to eat unrealistic amounts for significant health effects. Fun fact: Buddhist monks' robes are traditionally dyed with turmeric, giving them that distinctive saffron-yellow colour!", originSummary: "🌿✨ Extracted from turmeric root (Curcuma longa), a ginger family plant grown primarily in India and Southeast Asia. The roots are boiled, dried, ground, and extracted to concentrate the bright yellow curcumin.", riskSummary: "Completely safe and natural. Turmeric has been used in cooking and traditional medicine for over 4,000 years. Actually contains compounds with anti-inflammatory properties. One of the safest colourings available.", riskLevel: .noRisk),
        "curcumin": .init(displayName: "Curcumin (Turmeric)", shortSummary: "Golden-yellow turmeric pigment from 4,000 years of Indian cooking - stains clothes forever!", whatItIs: "The vivid golden-yellow pigment from turmeric root - the same spice that makes curry powder yellow and stains your clothes permanently if you spill it! Turmeric has been used in Indian cooking for over 4,000 years, and curcumin is the compound responsible for its colour and many of its health benefits. Food manufacturers extract and concentrate it to create natural yellow colouring for mustard, cheese, butter, cakes, and curry sauces. It's having a moment in wellness circles due to its anti-inflammatory properties, though you'd need to eat unrealistic amounts for significant health effects. Fun fact: Buddhist monks' robes are traditionally dyed with turmeric, giving them that distinctive saffron-yellow colour!", originSummary: "🌿✨ Extracted from turmeric root (Curcuma longa), a ginger family plant grown primarily in India and Southeast Asia. The roots are boiled, dried, ground, and extracted to concentrate the bright yellow curcumin.", riskSummary: "Completely safe and natural. Turmeric has been used in cooking and traditional medicine for over 4,000 years. Actually contains compounds with anti-inflammatory properties. One of the safest colourings available.", riskLevel: .noRisk),

        "e120": .init(displayName: "Cochineal (Carmine)", shortSummary: "Bright red dye from 70,000 crushed beetles - actual bugs! Not for vegans.", whatItIs: "A bright red dye made from crushed cochineal beetles. Yes, actual bugs! About 70,000 beetles are needed to make just one pound of dye. Vegetarians and vegans, look away!", originSummary: "🐛 Crushed beetles from South America and Mexico. The female cochineal bugs are harvested, dried, and crushed.", riskSummary: "Safe but not suitable for vegetarians or vegans. Rare allergic reactions reported.", riskLevel: .lowRisk),
        "carmine": .init(displayName: "Cochineal (Carmine)", shortSummary: "Bright red dye from 70,000 crushed beetles - actual bugs! Not for vegans.", whatItIs: "A bright red dye made from crushed cochineal beetles. Yes, actual bugs! About 70,000 beetles are needed to make just one pound of dye. Vegetarians and vegans, look away!", originSummary: "🐛 Crushed beetles from South America and Mexico. The female cochineal bugs are harvested, dried, and crushed.", riskSummary: "Safe but not suitable for vegetarians or vegans. Rare allergic reactions reported.", riskLevel: .lowRisk),
        "cochineal": .init(displayName: "Cochineal (Carmine)", shortSummary: "Bright red dye from 70,000 crushed beetles - actual bugs! Not for vegans.", whatItIs: "A bright red dye made from crushed cochineal beetles. Yes, actual bugs! About 70,000 beetles are needed to make just one pound of dye. Vegetarians and vegans, look away!", originSummary: "🐛 Crushed beetles from South America and Mexico. The female cochineal bugs are harvested, dried, and crushed.", riskSummary: "Safe but not suitable for vegetarians or vegans. Rare allergic reactions reported.", riskLevel: .lowRisk),

        "e410": .init(displayName: "Locust bean gum", shortSummary: "Natural carob tree seed thickener (no actual locusts!) - makes ice cream scoopable when frozen.", whatItIs: "A natural thickening gum from carob tree seeds - and despite the alarming name, no actual locusts are involved! The 'locust' part comes from the carob pods' resemblance to locust swarms. Carob trees grow around the Mediterranean, and their seeds have been used since ancient Egypt. When ground into powder, they create a smooth, creamy texture that makes ice cream stay soft and scoopable even when frozen solid, prevents ice crystals from forming, and gives dairy products that luxurious mouthfeel. It works brilliantly with other gums (especially xanthan) to create even better textures. Fun fact: those chocolate-looking carob bars in health food shops? Made from the same tree's pods! The seeds make the gum, the pods make chocolate substitutes.", originSummary: "🌳 Ground from the seeds of the carob tree (Ceratonia siliqua) which grows in Mediterranean regions. The pods are harvested, split open, and the seeds are separated, dried, and milled into powder.", riskSummary: "Completely safe and natural. Also known as carob gum. Been used in food for centuries with no known safety concerns. Actually considered a beneficial dietary fibre.", riskLevel: .noRisk),
        "locust bean gum": .init(displayName: "Locust bean gum", shortSummary: "Natural carob tree seed thickener (no actual locusts!) - makes ice cream scoopable when frozen.", whatItIs: "A natural thickening gum from carob tree seeds - and despite the alarming name, no actual locusts are involved! The 'locust' part comes from the carob pods' resemblance to locust swarms. Carob trees grow around the Mediterranean, and their seeds have been used since ancient Egypt. When ground into powder, they create a smooth, creamy texture that makes ice cream stay soft and scoopable even when frozen solid, prevents ice crystals from forming, and gives dairy products that luxurious mouthfeel. It works brilliantly with other gums (especially xanthan) to create even better textures. Fun fact: those chocolate-looking carob bars in health food shops? Made from the same tree's pods! The seeds make the gum, the pods make chocolate substitutes.", originSummary: "🌳 Ground from the seeds of the carob tree (Ceratonia siliqua) which grows in Mediterranean regions. The pods are harvested, split open, and the seeds are separated, dried, and milled into powder.", riskSummary: "Completely safe and natural. Also known as carob gum. Been used in food for centuries with no known safety concerns. Actually considered a beneficial dietary fibre.", riskLevel: .noRisk),

        "e414": .init(displayName: "Gum arabic (Acacia gum)", shortSummary: "4,000-year-old acacia tree sap - makes M&Ms glossy and keeps fizz dissolved in drinks.", whatItIs: "Tree sap from acacia trees that grows wild across the African Sahel region - it's been traded for over 4,000 years! When acacia trees get stressed (by heat, drought, or damage), they ooze this golden-amber sap that hardens into natural 'tears' which are then collected, cleaned, and ground into powder. Ancient Egyptians used it in mummification and ink-making. In modern food, it keeps the fizz dissolved in your soft drinks, creates the glossy shell on M&Ms, holds the sugar crystals on wine gums, and emulsifies the essential oils in fizzy drinks so they don't separate. It's also used by artists for watercolour paints! The majority of the world's supply still comes from Sudan, supporting thousands of small-scale farmers.", originSummary: "🌳 Natural sap harvested from acacia trees (primarily Acacia senegal and Acacia seyal) in the Sahel region of Africa. The trees naturally exude the gum, which is hand-collected from the bark.", riskSummary: "Completely safe and natural. Used for over 4,000 years in food, medicine, and art. One of the oldest food additives known. Actually provides prebiotic fibre benefits for gut health!", riskLevel: .noRisk),
        "gum arabic": .init(displayName: "Gum arabic (Acacia gum)", shortSummary: "4,000-year-old acacia tree sap - makes M&Ms glossy and keeps fizz dissolved in drinks.", whatItIs: "Tree sap from acacia trees that grows wild across the African Sahel region - it's been traded for over 4,000 years! When acacia trees get stressed (by heat, drought, or damage), they ooze this golden-amber sap that hardens into natural 'tears' which are then collected, cleaned, and ground into powder. Ancient Egyptians used it in mummification and ink-making. In modern food, it keeps the fizz dissolved in your soft drinks, creates the glossy shell on M&Ms, holds the sugar crystals on wine gums, and emulsifies the essential oils in fizzy drinks so they don't separate. It's also used by artists for watercolour paints! The majority of the world's supply still comes from Sudan, supporting thousands of small-scale farmers.", originSummary: "🌳 Natural sap harvested from acacia trees (primarily Acacia senegal and Acacia seyal) in the Sahel region of Africa. The trees naturally exude the gum, which is hand-collected from the bark.", riskSummary: "Completely safe and natural. Used for over 4,000 years in food, medicine, and art. One of the oldest food additives known. Actually provides prebiotic fibre benefits for gut health!", riskLevel: .noRisk),

        "e401": .init(displayName: "Sodium alginate", shortSummary: "Seaweed extract creating molecular gastronomy 'caviar' pearls - also in your dental impressions!", whatItIs: "Seaweed extract that creates those trendy 'caviar' pearls in molecular gastronomy restaurants! When sodium alginate meets calcium chloride, it instantly forms a gel membrane, allowing chefs to create liquid-filled spheres that burst in your mouth. Brown seaweed (kelp) naturally produces alginates as part of their cell walls - it's what makes seaweed slimy and flexible underwater. Food scientists use it in ice cream to prevent ice crystals, in beer to maintain foam head, and in restructured foods (like those weird crab sticks) to bind everything together. Dentists use the same stuff to make impressions of your teeth! It's been commercially produced since the 1880s when a Scottish chemist figured out how to extract it.", originSummary: "🌊 Extracted from brown seaweed (kelp) harvested from cold ocean waters. The seaweed is washed, treated with alkali to extract the alginate, then processed into powder form.", riskSummary: "Completely safe and natural. Your body can't digest it, so it passes through as dietary fibre. Widely used in molecular gastronomy and dental impressions. No known adverse effects.", riskLevel: .noRisk),

        "e509": .init(displayName: "Calcium chloride", shortSummary: "Mineral salt keeping pickles crispy and forming cheese curds - also de-ices roads!", whatItIs: "A mineral salt with multiple food uses - it firms up canned vegetables and pickles (preventing that mushy texture), helps cheese curds form during cheese-making, and even extends the shelf life of cut fruit. When you bite into a crisp pickle spear, calcium chloride helped maintain that crunch through the canning process by strengthening the pectin in plant cell walls. Home brewers add it to water to adjust mineral content. It's also the stuff used for de-icing roads in winter and keeping dust down on gravel roads! But food-grade calcium chloride is purified and safe. Fun fact: those moisture-absorbing packets in electronics packaging? Often calcium chloride - it sucks water out of the air like a sponge.", originSummary: "🪨 Mineral salt produced from limestone (calcium carbonate) reacted with hydrochloric acid. Can also be purified from natural brine deposits or as a byproduct of the Solvay process (soda ash production).", riskSummary: "Safe within food use limits. Provides dietary calcium. Been used in food preservation and cheese-making for over a century with no safety concerns at approved levels.", riskLevel: .lowRisk),

        "e341": .init(displayName: "Calcium phosphates", shortSummary: "Ground chalk's cousin fortifying foods with calcium - your bones need this!", whatItIs: "Mineral salts that do everything from fortifying foods with calcium to preventing powders from clumping. Used as anti-caking agents in powdered foods, raising agents in baking, and to add calcium to fortified products like plant milks and cereals. They're essentially chalk (calcium carbonate's cousin) ground up and added to food - which sounds weird but is perfectly safe. Your body actually needs calcium phosphate for strong bones and teeth!", originSummary: "🪨 Mineral compounds produced from calcium salts and phosphoric acid. Also found naturally in milk and bones.", riskSummary: "Safe and provides dietary calcium. One of the few additives that actually adds nutritional value.", riskLevel: .noRisk),
        "calcium phosphates": .init(displayName: "Calcium phosphates", shortSummary: "Ground chalk's cousin fortifying foods with calcium - your bones need this!", whatItIs: "Mineral salts that do everything from fortifying foods with calcium to preventing powders from clumping. Used as anti-caking agents in powdered foods, raising agents in baking, and to add calcium to fortified products like plant milks and cereals. They're essentially chalk (calcium carbonate's cousin) ground up and added to food - which sounds weird but is perfectly safe. Your body actually needs calcium phosphate for strong bones and teeth!", originSummary: "🪨 Mineral compounds produced from calcium salts and phosphoric acid. Also found naturally in milk and bones.", riskSummary: "Safe and provides dietary calcium. One of the few additives that actually adds nutritional value.", riskLevel: .noRisk),

        "e501": .init(displayName: "Potassium carbonates", shortSummary: "Baking soda's potassium cousin - controls pH without adding more sodium.", whatItIs: "Alkaline mineral salts used as acidity regulators and stabilizers. They help control pH levels in foods and drinks, prevent crystallization in jams, and act as raising agents in baking. Think of them as baking soda's more sophisticated mineral cousin - doing similar jobs but with potassium instead of sodium. Food chemists use them when they want the alkalinity benefits without adding more sodium to products.", originSummary: "🪨 Mineral-based potassium compounds, similar to baking soda but with potassium. Produced industrially or from mineral deposits.", riskSummary: "Safe and well-tolerated. Actually provides dietary potassium, an essential mineral most people don't get enough of.", riskLevel: .noRisk),
        "potassium carbonates": .init(displayName: "Potassium carbonates", shortSummary: "Baking soda's potassium cousin - controls pH without adding more sodium.", whatItIs: "Alkaline mineral salts used as acidity regulators and stabilizers. They help control pH levels in foods and drinks, prevent crystallization in jams, and act as raising agents in baking. Think of them as baking soda's more sophisticated mineral cousin - doing similar jobs but with potassium instead of sodium. Food chemists use them when they want the alkalinity benefits without adding more sodium to products.", originSummary: "🪨 Mineral-based potassium compounds, similar to baking soda but with potassium. Produced industrially or from mineral deposits.", riskSummary: "Safe and well-tolerated. Actually provides dietary potassium, an essential mineral most people don't get enough of.", riskLevel: .noRisk),

        "e218": .init(displayName: "Methyl p-hydroxybenzoate", shortSummary: "Paraben preservative (controversial in cosmetics) - food amounts tiny compared to lotions.", whatItIs: "A synthetic preservative from the paraben family. Parabens are controversial in cosmetics, but in food they're used in tiny amounts to prevent mold and bacteria growth. They mimic natural preservatives found in blueberries and other fruits, but the synthetic versions last longer on the shelf. Food manufacturers love them because they work in acidic and non-acidic foods, unlike most preservatives which are picky. The amounts in food are tiny compared to cosmetics, but some people prefer to avoid them on principle.", originSummary: "🧪 Synthetic preservative from the paraben family. Chemically similar to compounds found naturally in blueberries, but made in a lab.", riskSummary: "Approved as safe in food at low levels. Some people prefer to avoid parabens due to their use in cosmetics, though food amounts are much smaller.", riskLevel: .moderateRisk),
        "methyl p-hydroxybenzoate": .init(displayName: "Methyl p-hydroxybenzoate", shortSummary: "Paraben preservative (controversial in cosmetics) - food amounts tiny compared to lotions.", whatItIs: "A synthetic preservative from the paraben family. Parabens are controversial in cosmetics, but in food they're used in tiny amounts to prevent mold and bacteria growth. They mimic natural preservatives found in blueberries and other fruits, but the synthetic versions last longer on the shelf. Food manufacturers love them because they work in acidic and non-acidic foods, unlike most preservatives which are picky. The amounts in food are tiny compared to cosmetics, but some people prefer to avoid them on principle.", originSummary: "🧪 Synthetic preservative from the paraben family. Chemically similar to compounds found naturally in blueberries, but made in a lab.", riskSummary: "Approved as safe in food at low levels. Some people prefer to avoid parabens due to their use in cosmetics, though food amounts are much smaller.", riskLevel: .moderateRisk),

        "e492": .init(displayName: "Sorbitan tristearate", shortSummary: "Emulsifier making oil and water hold hands - breaks down into natural sorbitol and fats.", whatItIs: "An emulsifier that helps oil and water play nicely together in processed foods. It's made by combining sorbitol (a sugar alcohol) with stearic acid (a fatty acid found in cocoa butter and animal fats). This creates a molecule with one end that loves water and another that loves fat - perfect for keeping salad dressings from separating and making chocolate coatings smooth. It's the industrial chemistry equivalent of getting two feuding friends to hold hands.", originSummary: "🧪 Synthetic emulsifier made from sorbitol (from corn or wheat) and stearic acid (from palm or animal fats). Chemistry lab meets food factory.", riskSummary: "Safe and well-tolerated. Your body breaks it down into sorbitol and fatty acids, both of which occur naturally in foods.", riskLevel: .lowRisk),
        "sorbitan tristearate": .init(displayName: "Sorbitan tristearate", shortSummary: "Emulsifier making oil and water hold hands - breaks down into natural sorbitol and fats.", whatItIs: "An emulsifier that helps oil and water play nicely together in processed foods. It's made by combining sorbitol (a sugar alcohol) with stearic acid (a fatty acid found in cocoa butter and animal fats). This creates a molecule with one end that loves water and another that loves fat - perfect for keeping salad dressings from separating and making chocolate coatings smooth. It's the industrial chemistry equivalent of getting two feuding friends to hold hands.", originSummary: "🧪 Synthetic emulsifier made from sorbitol (from corn or wheat) and stearic acid (from palm or animal fats). Chemistry lab meets food factory.", riskSummary: "Safe and well-tolerated. Your body breaks it down into sorbitol and fatty acids, both of which occur naturally in foods.", riskLevel: .lowRisk),

        "e516": .init(displayName: "Calcium sulphate", shortSummary: "Gypsum/plaster of Paris making tofu for 2,000 years - same calcium your body needs!", whatItIs: "A mineral salt better known as gypsum or plaster of Paris - yes, the same stuff used in building materials! But don't worry, food-grade calcium sulphate has been used in Asian cuisine for over 2,000 years to coagulate soy milk into tofu. When you add it to soy milk, the calcium ions bind to proteins, causing them to clump together and form those firm tofu curds. In bread-making, it conditions the dough and provides calcium fortification. It also shows up as a firming agent in canned vegetables and as a nutrient supplement. The Chinese discovered its tofu-making properties during the Han Dynasty (around 164 BC) and it's been essential to Asian cuisine ever since. Your body needs calcium sulphate - it's the same calcium found in milk!", originSummary: "🪨 Mineral-based calcium salt, also known as gypsum. Found naturally in mineral deposits or produced from limestone. Purified to food grade for culinary use.", riskSummary: "Completely safe and provides dietary calcium and sulphur. Used in traditional tofu-making for over 2,000 years. One of the safest mineral additives.", riskLevel: .noRisk),

        "e460": .init(displayName: "Cellulose", shortSummary: "Pure plant scaffolding from wood pulp - treats like eating lettuce. Most abundant organic compound on Earth!", whatItIs: "Pure plant fibre - literally the structural scaffolding that makes plants stand upright! It's what gives lettuce its crunch, paper its strength, and cotton its durability. Your body can't digest cellulose at all (only cows and termites can, thanks to special gut bacteria), so it passes straight through as dietary fibre. Food manufacturers add powdered cellulose to grated cheese to prevent clumping, to reduce-calorie foods as a bulking agent (adds volume without calories!), and to ice cream for smoother texture. It's usually sourced from wood pulp or cotton - which sounds weird but is perfectly safe since it's just pure plant matter. Fun fact: cellulose is the most abundant organic compound on Earth!", originSummary: "🌳 From plant cell walls - typically wood pulp or cotton fibres. Purified and ground into fine powder. It's literally the same stuff that makes up tree trunks and cotton t-shirts!", riskSummary: "Completely safe. Passes through your digestive system as indigestible fibre, actually helping with digestion. Your body treats it exactly like eating lettuce or celery. Zero nutritional value but beneficial for gut health.", riskLevel: .noRisk),
        "cellulose": .init(displayName: "Cellulose", shortSummary: "Pure plant scaffolding from wood pulp - treats like eating lettuce. Most abundant organic compound on Earth!", whatItIs: "Pure plant fibre - literally the structural scaffolding that makes plants stand upright! It's what gives lettuce its crunch, paper its strength, and cotton its durability. Your body can't digest cellulose at all (only cows and termites can, thanks to special gut bacteria), so it passes straight through as dietary fibre. Food manufacturers add powdered cellulose to grated cheese to prevent clumping, to reduce-calorie foods as a bulking agent (adds volume without calories!), and to ice cream for smoother texture. It's usually sourced from wood pulp or cotton - which sounds weird but is perfectly safe since it's just pure plant matter. Fun fact: cellulose is the most abundant organic compound on Earth!", originSummary: "🌳 From plant cell walls - typically wood pulp or cotton fibres. Purified and ground into fine powder. It's literally the same stuff that makes up tree trunks and cotton t-shirts!", riskSummary: "Completely safe. Passes through your digestive system as indigestible fibre, actually helping with digestion. Your body treats it exactly like eating lettuce or celery. Zero nutritional value but beneficial for gut health.", riskLevel: .noRisk),

        "e551": .init(displayName: "Silicon dioxide", shortSummary: "Purified sand/quartz preventing clumping - passes through unchanged. Not toxic like those DO NOT EAT packets suggest!", whatItIs: "Ground-up quartz crystal - literally sand, but purified to food-grade! It's the same compound that makes up beach sand, quartz crystals, and those silica gel packets that say 'DO NOT EAT' (those aren't toxic, they're just a choking hazard). In powdered foods, tiny amounts prevent clumping by absorbing moisture and creating space between particles. Ever notice how salt stops flowing in humid weather? That's moisture clumping. Silicon dioxide prevents that in everything from dried spices to powdered sugar to instant coffee. It's chemically inert - your body can't break it down or absorb it, so it passes straight through unchanged. Fun fact: silicon dioxide is the second most abundant compound in Earth's crust after water!", originSummary: "🪨⚪ Mineral-based - the exact same compound as sand, quartz crystals, and glass. Purified, then ground into ultra-fine powder for food use (much finer than beach sand!).", riskSummary: "Completely safe. Used in tiny amounts (typically 2% or less). Chemically inert and passes through your body unchanged. Approved by all major food safety authorities worldwide.", riskLevel: .noRisk),

        "e1200": .init(displayName: "Polydextrose", shortSummary: "1960s synthetic fibre for diet products - 1 calorie vs 4 in sugar. Can cause gas if overdone.", whatItIs: "A synthetic soluble fibre created by food scientists in the 1960s as a low-calorie bulking agent for 'diet' and 'sugar-free' products. Made by heating glucose (sugar) with sorbitol and citric acid until they randomly bond into complex branched molecules your body can't digest properly. It provides bulk and texture in reduced-sugar foods without the calories - you absorb only about 1 calorie per gram compared to 4 for regular sugar. Found in sugar-free sweets, diet ice cream, and fibre-fortified products. Your gut bacteria can ferment some of it, which provides prebiotic benefits but can also cause gas and bloating if you eat too much. Food manufacturers love it because it mimics sugar's bulk and mouthfeel in diet products.", originSummary: "🧪 Synthetic fibre made by heating glucose with sorbitol and citric acid. The random polymerization creates branched molecules too complex for your digestive enzymes to break down efficiently.", riskSummary: "Generally safe and approved for use. Acts as a dietary fibre with prebiotic effects. Can cause digestive discomfort (gas, bloating, loose stools) if consumed in large amounts (usually over 50g). Start small if you're sensitive.", riskLevel: .lowRisk),

        "e1520": .init(displayName: "Propylene glycol", shortSummary: "Pet-safe antifreeze ingredient - your body converts it to yogurt's lactic acid. Not the toxic kind!", whatItIs: "A syrupy liquid that keeps foods moist and helps dissolve flavours and colours evenly throughout products. Yes, it's used in some antifreeze formulations - but that's because it's SAFER than the old toxic antifreeze (ethylene glycol), not because it's dangerous! In fact, propylene glycol antifreeze is marketed as 'pet-safe' precisely because it's non-toxic. In food, it appears in cake mixes, salad dressings, soft drinks, and food colourings as a carrier solvent. It's also in your toothpaste, mouthwash, and e-cigarettes. Your body metabolizes it into lactic acid (the same stuff in yogurt), so it's actually quite safe. The 'antifreeze ingredient' reputation is misleading - table salt is used to de-ice roads too, but that doesn't make it unsafe!", originSummary: "🧪 Synthetic compound made from petroleum or plant sources (corn, soy). Clear, slightly sweet-tasting viscous liquid. Used in pharmaceuticals, cosmetics, and food.", riskSummary: "Safe within permitted food limits. Extensively studied and approved by all major food safety authorities. Your body converts it to lactic acid and eliminates it quickly. Different from toxic ethylene glycol antifreeze.", riskLevel: .lowRisk),

        "e422": .init(displayName: "Glycerol (Glycerine)", shortSummary: "Sweet-tasting moisture keeper from vegetable oils - in cakes and vapes.", whatItIs: "Sweet-tasting humectant that keeps food moist. Used in cakes, confectionery, and vaping liquids.", originSummary: "From vegetable oils or as a byproduct of soap-making.", riskSummary: "Safe and widely used.", riskLevel: .noRisk),
        "glycerol": .init(displayName: "Glycerol (Glycerine)", shortSummary: "Sweet-tasting moisture keeper from vegetable oils - in cakes and vapes.", whatItIs: "Sweet-tasting humectant that keeps food moist. Used in cakes, confectionery, and vaping liquids.", originSummary: "From vegetable oils or as a byproduct of soap-making.", riskSummary: "Safe and widely used.", riskLevel: .noRisk),
        "glycerine": .init(displayName: "Glycerol (Glycerine)", shortSummary: "Sweet-tasting moisture keeper from vegetable oils - in cakes and vapes.", whatItIs: "Sweet-tasting humectant that keeps food moist. Used in cakes, confectionery, and vaping liquids.", originSummary: "From vegetable oils or as a byproduct of soap-making.", riskSummary: "Safe and widely used.", riskLevel: .noRisk),

        "e901": .init(displayName: "Beeswax", shortSummary: "Natural wax from bee hives coating sweets and apples. Not for vegans.", whatItIs: "Natural wax used to coat sweets and fresh produce for a shiny finish.", originSummary: "From honeybee hives.", riskSummary: "Safe and natural. Not suitable for strict vegans.", riskLevel: .noRisk),
        "beeswax": .init(displayName: "Beeswax", shortSummary: "Natural wax from bee hives coating sweets and apples. Not for vegans.", whatItIs: "Natural wax used to coat sweets and fresh produce for a shiny finish.", originSummary: "From honeybee hives.", riskSummary: "Safe and natural. Not suitable for strict vegans.", riskLevel: .noRisk),

        "e903": .init(displayName: "Carnauba wax", shortSummary: "Brazilian palm leaf wax giving pills and sweets glossy coating. Vegan-friendly.", whatItIs: "Natural plant wax that gives confectionery and pills a glossy coating.", originSummary: "From the leaves of the Brazilian carnauba palm.", riskSummary: "Safe and vegan-friendly.", riskLevel: .noRisk),
        "carnauba wax": .init(displayName: "Carnauba wax", shortSummary: "Brazilian palm leaf wax giving pills and sweets glossy coating. Vegan-friendly.", whatItIs: "Natural plant wax that gives confectionery and pills a glossy coating.", originSummary: "From the leaves of the Brazilian carnauba palm.", riskSummary: "Safe and vegan-friendly.", riskLevel: .noRisk),

        "e904": .init(displayName: "Shellac", shortSummary: "Lac bug secretions making furniture and apples shiny. Not for vegans!", whatItIs: "A shiny coating secreted by lac bugs. It's the same stuff used to make furniture polish shine! Also found on apples and sweets to give them that glossy look.", originSummary: "🐛 Secreted by lac bugs in India and Thailand. The bugs coat tree branches with this resinous substance, which is then scraped off and processed.", riskSummary: "Safe but not suitable for vegetarians or vegans.", riskLevel: .noRisk),
        "shellac": .init(displayName: "Shellac", shortSummary: "Lac bug secretions making furniture and apples shiny. Not for vegans!", whatItIs: "A shiny coating secreted by lac bugs. It's the same stuff used to make furniture polish shine! Also found on apples and sweets to give them that glossy look.", originSummary: "🐛 Secreted by lac bugs in India and Thailand. The bugs coat tree branches with this resinous substance, which is then scraped off and processed.", riskSummary: "Safe but not suitable for vegetarians or vegans.", riskLevel: .noRisk),

        "e476": .init(displayName: "Polyglycerol polyricinoleate (PGPR)", shortSummary: "Emulsifier from castor oil reducing cocoa butter needs in chocolate.", whatItIs: "Emulsifier that reduces the amount of cocoa butter needed in chocolate.", originSummary: "Made from castor oil and glycerol.", riskSummary: "Safe. Allows chocolate makers to use less cocoa butter.", riskLevel: .lowRisk),

        "e473": .init(displayName: "Sucrose esters", shortSummary: "Sugar + fat emulsifiers in baked goods and ice cream. Safe.", whatItIs: "Emulsifiers made from sugar and fats. Used in baked goods and ice cream.", originSummary: "Made from sucrose (sugar) and fatty acids.", riskSummary: "Safe and well tolerated.", riskLevel: .lowRisk),

        "e627": .init(displayName: "Disodium guanylate", shortSummary: "Umami enhancer working with MSG from yeast/fish. Avoid if gout sufferer.", whatItIs: "Flavour enhancer that works with MSG to create umami taste.", originSummary: "Usually from yeast extract or fish.", riskSummary: "Safe. Not suitable for gout sufferers due to purine content.", riskLevel: .lowRisk),

        "e631": .init(displayName: "Disodium inosinate", shortSummary: "Umami enhancer working with MSG from meat/fish. Avoid if gout sufferer.", whatItIs: "Flavour enhancer that works with MSG to create umami taste.", originSummary: "Usually from meat or fish extracts.", riskSummary: "Safe. Not suitable for gout sufferers due to purine content.", riskLevel: .lowRisk),

        "e635": .init(displayName: "Disodium 5'-ribonucleotides", shortSummary: "E627 + E631 combo umami booster from yeast/meat/fish. Avoid if gout sufferer.", whatItIs: "Combination flavour enhancer containing E627 and E631. Boosts umami flavour.", originSummary: "From yeast, meat, or fish extracts.", riskSummary: "Safe. Not suitable for gout sufferers due to purine content.", riskLevel: .lowRisk),

        // Ultra-processed ingredients (no E-numbers but commonly flagged)
        "palm kernel oil": .init(displayName: "Palm kernel oil", shortSummary: "Heavily refined cheap oil from palm kernels - high saturated fat, deforestation concerns.", whatItIs: "Highly refined oil from palm kernels. Cheap and stable at high temperatures, which is why it's everywhere in processed foods. The refining process strips away most nutrients.", originSummary: "🌴 Extracted from the kernel (seed) of oil palms, then heavily refined.", riskSummary: "High in saturated fat. Environmental concerns about palm plantation deforestation.", riskLevel: .moderateRisk),
        "palm oil": .init(displayName: "Palm oil", shortSummary: "World's most popular cheap oil in half of packaged foods - deforestation driver.", whatItIs: "The world's most popular cheap oil, found in about half of packaged foods. Refining it at high heat can create compounds linked to health concerns.", originSummary: "🌴 Pressed from the fruit of oil palms. Often heavily refined for shelf stability.", riskSummary: "High in saturated fat. Major driver of deforestation in Southeast Asia.", riskLevel: .moderateRisk),
        "rapeseed oil": .init(displayName: "Rapeseed oil", shortSummary: "Canola oil heavily processed and chemically extracted - look for cold-pressed.", whatItIs: "Better known as 'canola oil' in some countries. Usually heavily processed and chemically extracted, unlike the traditional cold-pressed version.", originSummary: "🌻 From rapeseed (canola) plants. Most commercial versions are refined and sometimes partially hydrogenated.", riskSummary: "Generally safe but refining reduces nutritional value. Check for 'cold-pressed' for better quality.", riskLevel: .lowRisk),
        "vegetable oil": .init(displayName: "Vegetable oil", shortSummary: "Mystery blend - whatever's cheapest that day! Could be soy, sunflower, or palm.", whatItIs: "A mysterious term that could mean soybean, sunflower, rapeseed, or a blend. Usually the cheapest oil the manufacturer could find that day!", originSummary: "🌻 Could be from various plants - soy, sunflower, rapeseed, palm. The vague name hides the true source.", riskSummary: "Quality varies wildly. Often highly processed. Look for specific oil names for better transparency.", riskLevel: .lowRisk),
        "modified starch": .init(displayName: "Modified starch", shortSummary: "Chemically altered starch thickening sauces and preventing ice cream crystals.", whatItIs: "Regular starch that's been chemically altered to thicken, stabilize, or gel foods. Makes sauces smooth and prevents ice crystals in ice cream.", originSummary: "🧪 Chemically modified from corn, potato, or tapioca starch.", riskSummary: "Generally safe. Heavily processed but serves a functional purpose in food manufacturing.", riskLevel: .lowRisk),
        "glucose syrup": .init(displayName: "Glucose syrup", shortSummary: "Concentrated liquid sugar from broken-down starch - spikes blood sugar, zero nutrients.", whatItIs: "Super-concentrated liquid sugar made by breaking down starch with enzymes or acids. It's sweeter than regular sugar, never crystallizes, and is much cheaper - which is why food manufacturers absolutely love it. You'll find it in everything from sweets to 'healthy' cereal bars. Made by enzymatically breaking down cornstarch into pure glucose, giving you all the sugar hit with none of the fiber or nutrients that would normally come with whole grains.", originSummary: "🌽🧪 Made by enzymatically or chemically breaking down corn or wheat starch into pure glucose. Industrial food science at its finest.", riskSummary: "Pure liquid sugar with zero nutritional value. Spikes blood sugar rapidly and contributes to insulin resistance when consumed regularly.", riskLevel: .moderateRisk),
        "fructose syrup": .init(displayName: "Fructose syrup", shortSummary: "Sweeter than glucose syrup - liver works harder to process, fatty liver risk.", whatItIs: "Even sweeter than glucose syrup. Your liver has to work harder to process fructose compared to glucose.", originSummary: "🧪 Enzymatically converted from glucose syrup to be sweeter.", riskSummary: "High fructose intake linked to fatty liver and metabolic issues when consumed in excess.", riskLevel: .moderateRisk),
        "corn syrup": .init(displayName: "Corn syrup", shortSummary: "America's liquid sweetener from cornstarch - highly processed, zero nutrition.", whatItIs: "America's favourite liquid sweetener. Made by breaking down cornstarch into simpler sugars. Adds sweetness and prevents crystallization.", originSummary: "🌽 From cornstarch converted to syrup through enzymatic processing.", riskSummary: "Highly processed sugar with zero nutritional value.", riskLevel: .moderateRisk),
        "maltodextrin": .init(displayName: "Maltodextrin", shortSummary: "Spikes blood sugar FASTER than pure glucose (105-130 GI) without tasting sweet - sneaky!", whatItIs: "A super-processed starch powder that dissolves instantly in your mouth. Here's the kicker: it has a glycemic index of 105-130, which means it spikes your blood sugar FASTER than pure glucose (100) despite barely tasting sweet! Food manufacturers use it as cheap filler in protein powders, 'healthy' snack bars, and diet products. It adds bulk and texture without adding noticeable sweetness, so you don't realize you're basically eating refined carbs. Made by taking starch and breaking it down with enzymes and acids until it's barely more complex than pure sugar.", originSummary: "🌽🧪 Made by enzymatically and chemically breaking down corn, rice, or potato starch into short-chain carbohydrates. One step away from being pure sugar.", riskSummary: "Spikes blood sugar faster than table sugar despite not tasting sweet. Pure empty calories with zero nutritional value. Particularly misleading in 'health' products.", riskLevel: .moderateRisk),
        "dextrose": .init(displayName: "Dextrose", shortSummary: "Pure glucose powder in your bloodstream and IV drips - instant spike then crash in 20-30 mins.", whatItIs: "Pure glucose in crystalline powdered form - literally the exact same sugar molecule that's coursing through your bloodstream right now! It's what your brain runs on, what athletes use for instant energy, and what hospitals give in IV drips. Made by completely breaking down cornstarch with enzymes and acid until nothing but pure glucose remains, it's about 70-75% as sweet as table sugar. Your body absorbs it instantly without any digestion needed - straight from tongue to bloodstream in minutes. Sounds great for energy, right? The catch is you get a rapid spike followed by a crash 20-30 minutes later as insulin kicks in hard. It's in sports drinks, energy gels, glucose tablets for diabetics, and loads of processed foods. Fun fact: 'dextrose' and 'glucose' are the same molecule - the name just comes from how it rotates polarized light (dextro = right-turning).", originSummary: "🌽 Refined from cornstarch through enzymatic and chemical hydrolysis. The starch is completely broken down into individual glucose molecules, then crystallized into white powder.", riskSummary: "Pure, rapid-acting sugar. Causes immediate blood sugar spike followed by crash. Useful for athletes or diabetics managing low blood sugar, but not ideal for everyday consumption. Use in moderation.", riskLevel: .lowRisk),
        "invert sugar": .init(displayName: "Invert sugar", shortSummary: "Sugar broken apart with acid/enzymes - sweeter, prevents candy crystallization.", whatItIs: "Regular sugar that's been 'inverted' by breaking it apart with acid or enzymes. Sweeter and prevents crystallization in candy and baked goods.", originSummary: "🧪 Made by treating sucrose with acid or enzymes to split it into glucose and fructose.", riskSummary: "Just another form of processed sugar.", riskLevel: .moderateRisk),
        "natural flavouring": .init(displayName: "Natural flavouring", shortSummary: "Weasel words hiding anything from vanilla to beaver anal glands (seriously!). Trade secret.", whatItIs: "The food industry's favourite weasel words. Could be anything from real vanilla to beaver anal glands (seriously - castoreum is 'natural'). Manufacturers never tell you what it actually is.", originSummary: "🔍 Derived from natural sources but often heavily processed. The exact ingredients are trade secrets.", riskSummary: "'Natural' doesn't mean healthy or unprocessed. Just means it started from something that was once alive.", riskLevel: .lowRisk),
        "natural flavour": .init(displayName: "Natural flavour", shortSummary: "Weasel words hiding anything from vanilla to beaver anal glands (seriously!). Trade secret.", whatItIs: "The food industry's favourite weasel words. Could be anything from real vanilla to beaver anal glands (seriously - castoreum is 'natural'). Manufacturers never tell you what it actually is.", originSummary: "🔍 Derived from natural sources but often heavily processed. The exact ingredients are trade secrets.", riskSummary: "'Natural' doesn't mean healthy or unprocessed. Just means it started from something that was once alive.", riskLevel: .lowRisk),
        "artificial flavour": .init(displayName: "Artificial flavour", shortSummary: "Lab-created chemicals mimicking natural flavours - safer than 'natural' sometimes!", whatItIs: "Lab-created chemicals designed to mimic natural flavours. Sometimes safer than natural flavourings because at least we know what's in them!", originSummary: "🧪 Synthesized in laboratories from various chemical compounds.", riskSummary: "Extensively tested for safety. No nutritional value but adds flavour without calories.", riskLevel: .lowRisk),
        "artificial flavouring": .init(displayName: "Artificial flavouring", shortSummary: "Lab-created chemicals mimicking natural flavours - safer than 'natural' sometimes!", whatItIs: "Lab-created chemicals designed to mimic natural flavours. Sometimes safer than natural flavourings because at least we know what's in them!", originSummary: "🧪 Synthesized in laboratories from various chemical compounds.", riskSummary: "Extensively tested for safety. No nutritional value but adds flavour without calories.", riskLevel: .lowRisk)
    ]

    static func override(for additive: AdditiveInfo) -> AdditiveOverrideData? {
        for code in additive.eNumbers {
            if let match = overrides[code.lowercased()] {
                return match
            }
        }
        return overrides[additive.name.lowercased()]
    }

    /// Helper methods for insights tracker lookup (allows lookup without creating full AdditiveInfo)
    static func getWhatItIs(code: String, name: String) -> String? {
        // Try code first
        if let override = overrides[code.lowercased()], let whatItIs = override.whatItIs {
            return whatItIs
        }
        // Try name
        if let override = overrides[name.lowercased()], let whatItIs = override.whatItIs {
            return whatItIs
        }
        return nil
    }

    static func getOriginSummary(code: String, name: String) -> String? {
        // Try code first
        if let override = overrides[code.lowercased()], let originSummary = override.originSummary {
            return originSummary
        }
        // Try name
        if let override = overrides[name.lowercased()], let originSummary = override.originSummary {
            return originSummary
        }
        return nil
    }

    static func getShortSummary(code: String, name: String) -> String? {
        // Try code first
        if let override = overrides[code.lowercased()], let shortSummary = override.shortSummary {
            return shortSummary
        }
        // Try name
        if let override = overrides[name.lowercased()], let shortSummary = override.shortSummary {
            return shortSummary
        }
        return nil
    }

    /// Get risk level for an additive
    static func getRiskLevel(for additive: AdditiveInfo) -> AdditiveRiskLevel {
        // First check if we have an override with explicit risk level
        if let override = AdditiveOverrides.override(for: additive), let level = override.riskLevel {
            return level
        }

        // Fall back to verdict-based risk assessment
        switch additive.effectsVerdict {
        case .avoid:
            return .highRisk
        case .caution:
            return additive.hasChildWarning ? .highRisk : .moderateRisk
        case .neutral:
            // Check origin for natural vs synthetic
            let originLower = additive.origin.rawValue.lowercased()
            if originLower.contains("plant") || originLower.contains("natural") {
                return .noRisk
            } else if originLower.contains("synthetic") {
                return .lowRisk
            }
            return .lowRisk
        }
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

    // Count of detected issues for the collapsed header
    private var issueCount: Int {
        guard let result = additiveResult else { return 0 }
        return result.detectedAdditives.count + result.ultraProcessedIngredients.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Traffic light explanation - subtle
            Text("Traffic light system: green = safe, amber = moderate, red = best limited")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            // Content shown directly (no dropdown)
            if !hasMeaningfulIngredients {
                emptyIngredientsContent
            } else if let result = additiveResult {
                additiveContent(result: result)
            } else {
                loadingContent
                    .frame(minHeight: 60)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.3), value: additiveResult != nil)
        .fullScreenCover(isPresented: $showingSources) {
            SourcesAndCitationsView()
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
    
    /// Check if an additive is a fortification (vitamin/mineral) that shouldn't be penalized
    private func isFortificationAdditive(name: String, eNumber: String) -> Bool {
        let nameLower = name.lowercased()
        let eNumberLower = eNumber.lowercased()

        // Vitamin E-numbers (E300 series are mostly vitamins/antioxidants)
        let vitaminENumbers = [
            "e300", "e301", "e302", "e303", "e304",  // Vitamin C (ascorbic acid)
            "e306", "e307", "e308", "e309",          // Vitamin E (tocopherols)
            "e101",                                   // Vitamin B2 (riboflavin)
            "e160a",                                  // Beta-carotene (pro-vitamin A)
            "e375",                                   // Niacin (Vitamin B3)
        ]

        // Mineral E-numbers
        let mineralENumbers = [
            "e341", "e342", "e343",  // Calcium phosphates
            "e170",                   // Calcium carbonate
            "e574", "e575", "e576", "e577",  // Gluconates (calcium, iron, etc.)
        ]

        // Check E-number match
        for vitaminE in vitaminENumbers {
            if eNumberLower == vitaminE || eNumberLower.contains(vitaminE) {
                return true
            }
        }
        for mineralE in mineralENumbers {
            if eNumberLower == mineralE || eNumberLower.contains(mineralE) {
                return true
            }
        }

        // Check name for vitamin/mineral keywords
        let fortificationKeywords = [
            "vitamin", "ascorbic acid", "riboflavin", "thiamin", "niacin",
            "folic acid", "folate", "pyridoxine", "cobalamin", "biotin",
            "tocopherol", "beta-carotene", "beta carotene", "retinol",
            "calcium carbonate", "calcium phosphate", "iron", "zinc",
            "iodine", "selenium", "magnesium", "potassium"
        ]

        for keyword in fortificationKeywords {
            if nameLower.contains(keyword) {
                return true
            }
        }

        return false
    }

    /// Calculate the additive score summary for the traffic light display
    private func calculateScoreSummary(result: AdditiveDetectionResult) -> AdditiveScoreSummary {
        var riskBreakdown: [AdditiveRiskLevel: Int] = [
            .noRisk: 0, .lowRisk: 0, .moderateRisk: 0, .highRisk: 0
        ]

        // Track what we've already counted to avoid double-counting
        var countedNames = Set<String>()
        var countedENumbers = Set<String>()

        // Track fortification additives separately (vitamins/minerals don't penalize)
        var fortificationCount = 0

        // Count additives by risk level
        for additive in result.detectedAdditives {
            // Check if this is a fortification additive (vitamin/mineral)
            if isFortificationAdditive(name: additive.name, eNumber: additive.eNumber) {
                fortificationCount += 1
                countedNames.insert(additive.name.lowercased())
                if !additive.eNumber.isEmpty {
                    countedENumbers.insert(additive.eNumber.lowercased())
                }
                continue  // Don't add to risk breakdown - fortifications are free
            }

            let level = AdditiveOverrides.getRiskLevel(for: additive)
            riskBreakdown[level, default: 0] += 1
            countedNames.insert(additive.name.lowercased())
            if !additive.eNumber.isEmpty {
                countedENumbers.insert(additive.eNumber.lowercased())
            }
        }

        // Ultra-processed ingredients - ONLY count if not already counted in detectedAdditives
        // This prevents double-counting things like lecithin (E322), glucose syrup, etc.
        for ingredient in result.ultraProcessedIngredients {
            let nameLower = ingredient.name.lowercased()

            // Check if already counted
            let isAlreadyCounted = countedNames.contains(nameLower) ||
                countedNames.contains(where: { $0.contains(nameLower) || nameLower.contains($0) }) ||
                countedENumbers.contains(where: { nameLower.contains($0) })

            if !isAlreadyCounted {
                // Assign risk level based on NOVA group and processing penalty
                if ingredient.novaGroup >= 4 {
                    riskBreakdown[.highRisk, default: 0] += 1
                } else if ingredient.processingPenalty >= 10 {
                    riskBreakdown[.moderateRisk, default: 0] += 1
                } else {
                    riskBreakdown[.lowRisk, default: 0] += 1
                }
                countedNames.insert(nameLower)
            }
        }

        // Total non-fortification additives (these affect the score)
        let penalizedAdditives = riskBreakdown.values.reduce(0, +)
        // Total including fortifications (for display purposes)
        let totalAdditives = penalizedAdditives + fortificationCount

        // Calculate score (100 = perfect, 0 = many high-risk additives)
        // STRICT SCORING: 5+ non-fortification additives can't be "Good" (60+)
        let score: Int
        if penalizedAdditives == 0 {
            score = 100
        } else {
            // Weighted scoring: high risk costs more points
            let highRiskPenalty = (riskBreakdown[.highRisk] ?? 0) * 25   // Very harsh for high risk
            let moderatePenalty = (riskBreakdown[.moderateRisk] ?? 0) * 12
            let lowRiskPenalty = (riskBreakdown[.lowRisk] ?? 0) * 6
            let noRiskPenalty = (riskBreakdown[.noRisk] ?? 0) * 2

            // Stricter base penalty - 5+ additives pushes below "Good" threshold (60)
            // With 5 low-risk additives: 100 - (5*6) - 15 = 55 = "Mediocre" ✓
            let basePenalty = min(penalizedAdditives * 3, 25)

            score = max(0, 100 - highRiskPenalty - moderatePenalty - lowRiskPenalty - noRiskPenalty - basePenalty)
        }

        // Determine overall risk level
        let overallRisk: AdditiveRiskLevel
        if (riskBreakdown[.highRisk] ?? 0) > 0 {
            overallRisk = .highRisk
        } else if (riskBreakdown[.moderateRisk] ?? 0) > 0 {
            overallRisk = .moderateRisk
        } else if (riskBreakdown[.lowRisk] ?? 0) > 0 {
            overallRisk = .lowRisk
        } else {
            overallRisk = .noRisk
        }

        return AdditiveScoreSummary(
            score: score,
            overallRisk: overallRisk,
            totalAdditives: totalAdditives,
            riskBreakdown: riskBreakdown,
            hasChildWarnings: result.hasChildConcernAdditives,
            hasSulphiteWarnings: result.detectedAdditives.contains { $0.hasSulphitesAllergenLabel }
        )
    }

    private func additiveContent(result: AdditiveDetectionResult) -> some View {
        let summary = calculateScoreSummary(result: result)

        return VStack(alignment: .leading, spacing: 16) {
            // TRAFFIC LIGHT SCORE HEADER
            AdditiveScoreHeader(summary: summary)

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

            // Detected additives and ultra-processed ingredients
            let totalIssues = result.detectedAdditives.count + result.ultraProcessedIngredients.count

            if totalIssues > 0 {
                // Group additives by risk level for better organization
                let groupedAdditives = groupAdditivesByRisk(result.detectedAdditives)

                VStack(alignment: .leading, spacing: 16) {
                    // Show high risk first (if any)
                    if let highRisk = groupedAdditives[.highRisk], !highRisk.isEmpty {
                        AdditiveRiskSection(
                            riskLevel: .highRisk,
                            additives: highRisk,
                            convertToDetailedAdditive: convertToDetailedAdditive
                        )
                    }

                    // Then moderate risk
                    if let moderateRisk = groupedAdditives[.moderateRisk], !moderateRisk.isEmpty {
                        AdditiveRiskSection(
                            riskLevel: .moderateRisk,
                            additives: moderateRisk,
                            convertToDetailedAdditive: convertToDetailedAdditive
                        )
                    }

                    // Then low risk
                    if let lowRisk = groupedAdditives[.lowRisk], !lowRisk.isEmpty {
                        AdditiveRiskSection(
                            riskLevel: .lowRisk,
                            additives: lowRisk,
                            convertToDetailedAdditive: convertToDetailedAdditive
                        )
                    }

                    // Then no risk (vitamins, etc.)
                    if let noRisk = groupedAdditives[.noRisk], !noRisk.isEmpty {
                        AdditiveRiskSection(
                            riskLevel: .noRisk,
                            additives: noRisk,
                            convertToDetailedAdditive: convertToDetailedAdditive
                        )
                    }

                    // Ultra-processed ingredients section
                    if !result.ultraProcessedIngredients.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "cube.box.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.purple)
                                Text("Ultra-Processed Ingredients")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text("(\(result.ultraProcessedIngredients.count))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            ForEach(result.ultraProcessedIngredients) { ingredient in
                                UltraProcessedIngredientCard(ingredient: ingredient, initialExpanded: false)
                            }
                        }
                    }
                }
            } else {
                // No additives found - show positive message
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AdditiveRiskLevel.noRisk.color)
                            .font(.system(size: 18))
                        Text("No additives detected")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                    }

                    Text("This product appears to have no identifiable additives in the available ingredient data.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AdditiveRiskLevel.noRisk.color.opacity(0.1))
                .cornerRadius(12)
            }

            // Educational footer with citation link
            VStack(alignment: .leading, spacing: 8) {
                Text("This information is provided for educational purposes. All listed additives are approved for use in food within regulatory limits.")
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
                    .foregroundColor(AppPalette.standard.accent)
                }
            }
        }
    }

    /// Group additives by their risk level
    private func groupAdditivesByRisk(_ additives: [AdditiveInfo]) -> [AdditiveRiskLevel: [AdditiveInfo]] {
        var grouped: [AdditiveRiskLevel: [AdditiveInfo]] = [:]
        for additive in additives {
            let level = AdditiveOverrides.getRiskLevel(for: additive)
            grouped[level, default: []].append(additive)
        }
        return grouped
    }
    
    private func analyzeAdditives() {
                        
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
                                return false
            }

            return true
        }

        // If no valid ingredients remain after filtering, return empty result
        if filteredIngredients.isEmpty {
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

        
        // Use AdditiveWatchService which now uses local comprehensive database
        AdditiveWatchService.shared.analyzeIngredients(filteredIngredients) { result in
            self.additiveResult = result
        }
    }

    // MARK: - Helper Functions for Description Generation

    /// Checks if a string looks like a list of products rather than a proper description
    private func looksLikeProductList(_ text: String) -> Bool {
        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Empty or very short strings aren't useful descriptions
        if lower.count < 10 { return true }

        // Product-like patterns: comma-separated items without verbs
        let productPatterns = [
            "candy", "candies", "sweets", "cakes", "biscuits", "cookies",
            "desserts", "drinks", "beverages", "sauces", "soups",
            "ice cream", "yogurt", "yoghurt", "jams", "jellies",
            "meats", "sausages", "processed foods", "snacks",
            "confectionery", "bakery", "dairy products", "soft drinks",
            "marshmallows", "gummy", "chocolate", "cereals"
        ]

        var productMatchCount = 0
        for pattern in productPatterns {
            if lower.contains(pattern) {
                productMatchCount += 1
            }
        }

        // If text has multiple product words and no descriptive verbs, it's likely a product list
        let descriptiveWords = ["is a", "is an", "are ", "used to", "helps", "prevents", "made from", "derived from", "produced", "natural", "synthetic", "chemical"]
        let hasDescriptiveContent = descriptiveWords.contains { lower.contains($0) }

        // More than 2 product words without descriptive content = product list
        if productMatchCount >= 2 && !hasDescriptiveContent {
            return true
        }

        // Check for comma-separated short words (typical of product lists)
        let commaCount = text.filter { $0 == "," }.count
        let wordCount = text.split(separator: " ").count
        if commaCount >= 2 && wordCount < 15 && !hasDescriptiveContent {
            return true
        }

        return false
    }

    /// Generates a sensible description based on the additive's group/category
    private func generateGroupDescription(for additive: AdditiveInfo) -> String {
        let group = additive.group.rawValue.lowercased()

        // Color-related groups
        if group.contains("colour") || group.contains("color") {
            if additive.origin.rawValue.lowercased().contains("synthetic") {
                return "A synthetic food colouring used to give foods an attractive appearance"
            } else if additive.origin.rawValue.lowercased().contains("plant") {
                return "A natural food colouring derived from plants"
            } else if additive.origin.rawValue.lowercased().contains("animal") {
                return "A food colouring derived from animal sources"
            }
            return "A food colouring used to give foods an attractive appearance"
        }

        // Preservatives
        if group.contains("preserv") {
            return "A preservative that helps extend shelf life by preventing spoilage"
        }

        // Emulsifiers
        if group.contains("emulsif") {
            return "An emulsifier that helps blend ingredients that normally don't mix, like oil and water"
        }

        // Stabilisers
        if group.contains("stabilis") || group.contains("stabiliz") {
            return "A stabiliser that helps maintain the texture and consistency of food"
        }

        // Thickeners
        if group.contains("thicken") {
            return "A thickening agent used to give foods a thicker, more appealing texture"
        }

        // Gelling agents
        if group.contains("gel") {
            return "A gelling agent that helps foods set into a solid or semi-solid texture"
        }

        // Antioxidants
        if group.contains("antioxid") {
            return "An antioxidant that helps prevent food from going rancid or changing colour"
        }

        // Acidity regulators
        if group.contains("acid") && group.contains("regul") {
            return "An acidity regulator that controls the pH level of food"
        }

        // Flavour enhancers
        if group.contains("flavour") || group.contains("flavor") {
            return "A flavour enhancer that intensifies the taste of food"
        }

        // Sweeteners
        if group.contains("sweeten") {
            return "A sweetener used as an alternative to sugar"
        }

        // Raising agents
        if group.contains("raising") || group.contains("leavening") {
            return "A raising agent that helps baked goods rise and become light and fluffy"
        }

        // Humectants
        if group.contains("humect") {
            return "A humectant that helps food retain moisture and stay fresh"
        }

        // Glazing agents
        if group.contains("glaz") {
            return "A glazing agent that gives foods a shiny, protective coating"
        }

        // Anti-caking agents
        if group.contains("anti-cak") || group.contains("anticak") {
            return "An anti-caking agent that prevents powders from clumping together"
        }

        // Bulking agents
        if group.contains("bulk") {
            return "A bulking agent that adds volume to food without significantly increasing calories"
        }

        // Firming agents
        if group.contains("firm") {
            return "A firming agent that helps maintain the texture and crispness of food"
        }

        // Carrier/carrier solvents
        if group.contains("carrier") || group.contains("solvent") {
            return "A carrier substance used to deliver other additives evenly throughout food"
        }

        // Sequestrants
        if group.contains("sequest") {
            return "A sequestrant that binds to metal ions to prevent food discolouration"
        }

        // Vitamins and minerals
        if group.contains("vitamin") || group.contains("mineral") || group.contains("nutrient") {
            return "A vitamin or mineral added to improve nutritional value"
        }

        // Default fallback using the group name
        if !group.isEmpty && group != "unknown" {
            return "A food additive classified as \(additive.group.rawValue.lowercased())"
        }

        // Last resort
        return "A food additive used in food processing"
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

        // Build "What is it?" sentence(s)
        var whatItIs: String
        if let overrideWhatItIs = override?.whatItIs {
            whatItIs = overrideWhatItIs
        } else if !overview.isEmpty && !looksLikeProductList(overview) {
            whatItIs = overview
        } else {
            // Generate a sensible description based on the additive group
            whatItIs = generateGroupDescription(for: additive)
        }

        // Add typical uses if we have them and they're not already mentioned
        if !uses.isEmpty && override?.whatItIs == nil && !looksLikeProductList(whatItIs) {
            let cleanedUses = uses.trimmingCharacters(in: .punctuationCharacters)
            if !whatItIs.lowercased().contains(cleanedUses.lowercased()) {
                whatItIs += (whatItIs.isEmpty ? "" : " ") + "Commonly found in \(cleanedUses)."
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
                                        .foregroundColor(AppPalette.standard.accent)
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
                                                    .foregroundColor(AppPalette.standard.accent)
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
                                                    .stroke(AppPalette.standard.accent.opacity(0.3), lineWidth: 1)
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
                                        .foregroundColor(AppPalette.standard.accent)
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
                                                    .foregroundColor(AppPalette.standard.accent)
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
                                                    .stroke(AppPalette.standard.accent.opacity(0.3), lineWidth: 1)
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
// MARK: - Ultra-Processed Ingredient Card Component (Redesigned - Sheet Modal)

struct UltraProcessedIngredientCard: View {
    let ingredient: UltraProcessedIngredientDisplay
    @Environment(\.colorScheme) var colorScheme
    @State private var showingDetail = false

    init(ingredient: UltraProcessedIngredientDisplay, initialExpanded: Bool = false) {
        self.ingredient = ingredient
    }

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        Button(action: { showingDetail = true }) {
            HStack(alignment: .center, spacing: 10) {
                // Soft indicator line (purple for ultra-processed)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.purple.opacity(0.6))
                    .frame(width: 3, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(ingredient.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(palette.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        // Display only actual E-numbers in purple capsule
                        let actualENumbers = ingredient.eNumbers.filter { eNumber in
                            let pattern = "^E[0-9]+(([a-z]+)|([\\(][ivxIVX]+[\\)]))?$"
                            return eNumber.range(of: pattern, options: .regularExpression) != nil
                        }
                        if let firstENumber = actualENumbers.first {
                            Text(firstENumber.uppercased())
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.purple)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.purple.opacity(0.12))
                                )
                        }

                        Text(ingredient.category.capitalized)
                            .font(.system(size: 11))
                            .foregroundColor(palette.textTertiary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(palette.textTertiary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.midnightCard.opacity(0.5) : palette.tertiary.opacity(0.06))
        )
        .sheet(isPresented: $showingDetail) {
            UltraProcessedDetailSheet(ingredient: ingredient)
        }
    }
}

// MARK: - Ultra-Processed Detail Sheet

struct UltraProcessedDetailSheet: View {
    let ingredient: UltraProcessedIngredientDisplay
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        // E-numbers in capsules
                        let actualENumbers = ingredient.eNumbers.filter { eNumber in
                            let pattern = "^E[0-9]+(([a-z]+)|([\\(][ivxIVX]+[\\)]))?$"
                            return eNumber.range(of: pattern, options: .regularExpression) != nil
                        }
                        if !actualENumbers.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(actualENumbers, id: \.self) { eNumber in
                                    Text(eNumber.uppercased())
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.purple)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color.purple.opacity(0.12))
                                        )
                                }
                            }
                        }

                        Text(ingredient.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(palette.textPrimary)

                        HStack(spacing: 8) {
                            Text(ingredient.category.capitalized)
                                .font(.system(size: 14))
                                .foregroundColor(palette.textSecondary)

                            Text("•")
                                .foregroundColor(palette.textTertiary)

                            Text("NOVA \(ingredient.novaGroup)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.purple)
                        }
                    }

                    // What it is
                    if let whatItIs = ingredient.whatItIs {
                        infoSection(title: "What it is", icon: "info.circle.fill", color: palette.accent) {
                            Text(whatItIs)
                                .font(.system(size: 15))
                                .foregroundColor(palette.textPrimary)
                        }
                    }

                    // Why it's used
                    if let whyItsUsed = ingredient.whyItsUsed {
                        infoSection(title: "Why it's used", icon: "cube.box.fill", color: .purple) {
                            Text(whyItsUsed)
                                .font(.system(size: 15))
                                .foregroundColor(palette.textPrimary)
                        }
                    }

                    // Where it comes from
                    if let whereItComesFrom = ingredient.whereItComesFrom {
                        infoSection(title: "Origin", icon: "leaf.fill", color: SemanticColors.nutrient) {
                            Text(whereItComesFrom)
                                .font(.system(size: 15))
                                .foregroundColor(palette.textPrimary)
                        }
                    }

                    // Why it matters
                    infoSection(title: "Why it matters", icon: "lightbulb.fill", color: SemanticColors.neutral) {
                        Text(ingredient.concerns)
                            .font(.system(size: 15))
                            .foregroundColor(palette.textPrimary)
                    }

                    // Scientific sources
                    if !ingredient.sources.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Scientific Sources")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(palette.textSecondary)

                            ForEach(ingredient.sources, id: \.url) { source in
                                Button(action: {
                                    if let url = URL(string: source.url) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(source.title)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(palette.accent)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.leading)

                                            Text(source.covers)
                                                .font(.system(size: 11))
                                                .foregroundColor(palette.textTertiary)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 10))
                                            .foregroundColor(palette.textTertiary)
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(colorScheme == .dark ? Color.midnightCard : Color(.systemGray6))
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(colorScheme == .dark ? Color.midnightBackground : Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func infoSection<Content: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(palette.textSecondary)
            }

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(colorScheme == .dark ? Color.midnightCard : Color(.systemGray6))
        )
    }
}

// MARK: - Additive Score Header (Redesigned - Calm & Premium)

/// Clean, calm additive summary matching onboarding design
struct AdditiveScoreHeader: View {
    let summary: AdditiveScoreSummary
    @Environment(\.colorScheme) var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Simple summary row
            HStack(spacing: 12) {
                // Soft colored indicator
                Circle()
                    .fill(summary.gradeColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(gradeInitial)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(summary.gradeColor)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.gradeLabel)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(palette.textPrimary)

                    Text(scoreDescription)
                        .font(.system(size: 13))
                        .foregroundColor(palette.textSecondary)
                }

                Spacer()

                // Count badge
                if summary.totalAdditives > 0 {
                    Text("\(summary.totalAdditives)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(palette.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(palette.tertiary.opacity(0.12))
                        )
                }
            }

            // Simple breakdown pills (if any additives)
            if summary.totalAdditives > 0 {
                HStack(spacing: 8) {
                    ForEach(AdditiveRiskLevel.allCases, id: \.self) { level in
                        if let count = summary.riskBreakdown[level], count > 0 {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(level.color)
                                    .frame(width: 6, height: 6)
                                Text("\(count) \(level.label.lowercased())")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(palette.textSecondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(summary.gradeColor.opacity(0.06))
        )
    }

    private var gradeInitial: String {
        if summary.totalAdditives == 0 { return "✓" }
        switch summary.score {
        case 80...100: return "A"
        case 60..<80: return "B"
        case 40..<60: return "C"
        default: return "D"
        }
    }

    private var scoreDescription: String {
        switch summary.score {
        case 90...100:
            return summary.totalAdditives == 0 ? "No additives detected" : "Mostly natural additives"
        case 70..<90:
            return "A few common additives"
        case 50..<70:
            return "Some additives present"
        case 30..<50:
            return "Several additives"
        default:
            return "Contains many additives"
        }
    }
}

// MARK: - Additive Risk Section (Redesigned - No Dropdown)

/// Clean additive grouping without dropdown - always visible
struct AdditiveRiskSection: View {
    let riskLevel: AdditiveRiskLevel
    let additives: [AdditiveInfo]
    let convertToDetailedAdditive: (AdditiveInfo) -> DetailedAdditive
    @Environment(\.colorScheme) var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Simple section label
            HStack(spacing: 6) {
                Circle()
                    .fill(riskLevel.color)
                    .frame(width: 8, height: 8)
                Text("\(riskLevel.label) (\(additives.count))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(palette.textSecondary)
                Spacer()
            }

            // Additive cards - always visible, no dropdown
            VStack(spacing: 6) {
                ForEach(additives, id: \.id) { additive in
                    EnhancedAdditiveCard(
                        additive: additive,
                        detailedAdditive: convertToDetailedAdditive(additive),
                        riskLevel: AdditiveOverrides.getRiskLevel(for: additive)
                    )
                }
            }
        }
    }
}

// MARK: - Enhanced Additive Card (Redesigned - Simple & Clean)

/// Clean additive card - simple row design matching onboarding aesthetic
struct EnhancedAdditiveCard: View {
    let additive: AdditiveInfo
    let detailedAdditive: DetailedAdditive
    let riskLevel: AdditiveRiskLevel
    @State private var isExpanded = false
    @State private var showingSources = false
    @Environment(\.colorScheme) var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row - always visible
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(alignment: .center, spacing: 10) {
                    // Soft risk indicator line
                    RoundedRectangle(cornerRadius: 2)
                        .fill(riskLevel.color)
                        .frame(width: 3, height: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(detailedAdditive.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(palette.textPrimary)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            if let code = detailedAdditive.code, !code.isEmpty {
                                Text(code.uppercased())
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(riskLevel.color)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(riskLevel.color.opacity(0.12))
                                    )
                            }

                            Text(additive.group.displayName)
                                .font(.system(size: 11))
                                .foregroundColor(palette.textTertiary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(palette.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .padding(.horizontal, 12)

                    // Consumer info (detailed human-friendly guide) - show if available
                    if let consumerInfo = additive.consumerInfo, !consumerInfo.isEmpty {
                        Text(LocalizedStringKey(consumerInfo))
                            .font(.system(size: 13))
                            .foregroundColor(palette.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 12)
                    } else {
                        // Fallback to structured info if no consumer guide
                        // What it is
                        if !detailedAdditive.whatItIs.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("What it is")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(palette.textSecondary)
                                Text(detailedAdditive.whatItIs)
                                    .font(.system(size: 13))
                                    .foregroundColor(palette.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 12)
                        }

                        // Origin - use whereItComesFrom if available for more interesting descriptions
                        if let whereFrom = additive.whereItComesFrom, !whereFrom.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Where it comes from")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(palette.textSecondary)
                                Text(whereFrom)
                                    .font(.system(size: 13))
                                    .foregroundColor(palette.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 12)
                        } else if !detailedAdditive.originSummary.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Origin")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(palette.textSecondary)
                                Text(detailedAdditive.originSummary)
                                    .font(.system(size: 13))
                                    .foregroundColor(palette.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 12)
                        }

                        // Effects/Safety - use effectsSummary for more detail
                        if !additive.effectsSummary.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("What to know")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(palette.textSecondary)
                                Text(additive.effectsSummary)
                                    .font(.system(size: 13))
                                    .foregroundColor(palette.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 12)
                        } else if !detailedAdditive.riskSummary.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Safety")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(palette.textSecondary)
                                Text(detailedAdditive.riskSummary)
                                    .font(.system(size: 13))
                                    .foregroundColor(palette.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 12)
                        }
                    }

                    // Child warning if applicable
                    if additive.hasChildWarning {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(SemanticColors.neutral)
                            Text("Heads up: This one's flagged for potentially affecting attention in kids. UK/EU products carry a warning label.")
                                .font(.system(size: 12))
                                .foregroundColor(palette.textSecondary)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(SemanticColors.neutral.opacity(0.08))
                        )
                        .padding(.horizontal, 12)
                    }

                    // Sources link if available - now tappable
                    if !additive.sources.isEmpty {
                        Button(action: { showingSources = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 10))
                                Text("\(additive.sources.count) source\(additive.sources.count == 1 ? "" : "s")")
                                    .font(.system(size: 11))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 8, weight: .semibold))
                            }
                            .foregroundColor(palette.accent)
                            .padding(.horizontal, 12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.bottom, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.midnightCard.opacity(0.5) : palette.tertiary.opacity(0.06))
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showingSources) {
            AdditiveSourcesSheet(additiveName: detailedAdditive.name, sources: additive.sources)
        }
    }
}

// MARK: - Additive Sources Sheet
struct AdditiveSourcesSheet: View {
    let additiveName: String
    let sources: [AdditiveSource]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Sources for information about \(additiveName)")
                        .font(.system(size: 14))
                        .foregroundColor(palette.textSecondary)
                        .padding(.horizontal)

                    ForEach(Array(sources.enumerated()), id: \.offset) { index, source in
                        Button(action: {
                            if let url = URL(string: source.url) {
                                openURL(url)
                            }
                        }) {
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(palette.accent.opacity(0.1))
                                        .frame(width: 32, height: 32)
                                    Text("\(index + 1)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(palette.accent)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(source.title)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(palette.textPrimary)
                                        .multilineTextAlignment(.leading)

                                    if let covers = source.covers, !covers.isEmpty {
                                        Text(covers)
                                            .font(.system(size: 12))
                                            .foregroundColor(palette.textSecondary)
                                    }

                                    Text(source.url)
                                        .font(.system(size: 11))
                                        .foregroundColor(palette.accent)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(palette.textTertiary)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(colorScheme == .dark ? Color.midnightBackground : palette.background)
            .navigationTitle("Sources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(palette.accent)
                }
            }
        }
    }
}

// MARK: - Additive Detail Sheet (Modal)

struct AdditiveDetailSheet: View {
    let additive: AdditiveInfo
    let detailedAdditive: DetailedAdditive
    let riskLevel: AdditiveRiskLevel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        if let code = detailedAdditive.code, !code.isEmpty {
                            Text(code.uppercased())
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(riskLevel.color)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(riskLevel.color.opacity(0.12))
                                )
                        }

                        Text(detailedAdditive.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(palette.textPrimary)

                        Text(additive.group.displayName)
                            .font(.system(size: 14))
                            .foregroundColor(palette.textSecondary)
                    }

                    // What it is
                    infoSection(title: "What it is", icon: "info.circle.fill", color: palette.accent) {
                        Text(detailedAdditive.whatItIs)
                            .font(.system(size: 15))
                            .foregroundColor(palette.textPrimary)
                    }

                    // Origin
                    infoSection(title: "Origin", icon: "leaf.fill", color: SemanticColors.nutrient) {
                        Text(detailedAdditive.originSummary)
                            .font(.system(size: 15))
                            .foregroundColor(palette.textPrimary)
                    }

                    // Safety
                    infoSection(title: "Safety", icon: "shield.fill", color: riskLevel.color) {
                        Text(detailedAdditive.riskSummary)
                            .font(.system(size: 15))
                            .foregroundColor(palette.textPrimary)
                    }

                    // Child warning if applicable
                    if additive.hasChildWarning {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(SemanticColors.neutral)
                            Text("May affect activity and attention in some children. Products in the UK/EU carry a warning label.")
                                .font(.system(size: 13))
                                .foregroundColor(palette.textSecondary)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(SemanticColors.neutral.opacity(0.08))
                        )
                    }
                }
                .padding(20)
            }
            .background(colorScheme == .dark ? Color.midnightBackground : palette.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(palette.accent)
                }
            }
        }
    }

    @ViewBuilder
    private func infoSection(title: String, icon: String, color: Color, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(palette.textSecondary)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
        )
    }
}
