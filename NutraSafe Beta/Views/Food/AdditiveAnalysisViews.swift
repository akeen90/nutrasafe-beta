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
    let whatItIs: String?
    let originSummary: String?
    let riskSummary: String?
    let riskLevel: AdditiveRiskLevel?
}

enum AdditiveOverrides {
    // Lookup by lowercase E-number or name
    private static let overrides: [String: AdditiveOverrideData] = [
        // Vitamins / fortification - NO RISK (natural/beneficial)
        "e300": .init(displayName: "Vitamin C (Ascorbic acid)", whatItIs: "Essential vitamin C - a powerful antioxidant that prevents browning and extends freshness. Your body needs it daily for immune function and collagen production.", originSummary: "Naturally found in citrus fruits; commercially produced via fermentation of glucose.", riskSummary: "Safe and beneficial. This is the same vitamin C found in oranges and lemons.", riskLevel: .noRisk),
        "ascorbic acid": .init(displayName: "Vitamin C (Ascorbic acid)", whatItIs: "Essential vitamin C - a powerful antioxidant that prevents browning and extends freshness. Your body needs it daily for immune function and collagen production.", originSummary: "Naturally found in citrus fruits; commercially produced via fermentation of glucose.", riskSummary: "Safe and beneficial. This is the same vitamin C found in oranges and lemons.", riskLevel: .noRisk),
        "e375": .init(displayName: "Vitamin B3 (Niacin)", whatItIs: "Essential B vitamin that helps convert food into energy. Added to cereals and bread to prevent deficiency diseases.", originSummary: "Found naturally in meat, fish, and nuts; commercially synthesised.", riskSummary: "Essential nutrient. The amounts in food are well within safe limits.", riskLevel: .noRisk),
        "nicotinic acid": .init(displayName: "Vitamin B3 (Niacin)", whatItIs: "Essential B vitamin that helps convert food into energy. Added to cereals and bread to prevent deficiency diseases.", originSummary: "Found naturally in meat, fish, and nuts; commercially synthesised.", riskSummary: "Essential nutrient. The amounts in food are well within safe limits.", riskLevel: .noRisk),
        "e101": .init(displayName: "Vitamin B2 (Riboflavin)", whatItIs: "Essential B vitamin that gives foods a yellow-orange colour. Important for energy metabolism and healthy skin.", originSummary: "Found in eggs, dairy, and leafy greens; produced via bacterial fermentation.", riskSummary: "Completely safe. This is the same vitamin B2 found naturally in dairy and eggs.", riskLevel: .noRisk),
        "riboflavin": .init(displayName: "Vitamin B2 (Riboflavin)", whatItIs: "Essential B vitamin that gives foods a yellow-orange colour. Important for energy metabolism and healthy skin.", originSummary: "Found in eggs, dairy, and leafy greens; produced via bacterial fermentation.", riskSummary: "Completely safe. This is the same vitamin B2 found naturally in dairy and eggs.", riskLevel: .noRisk),
        "e160a": .init(displayName: "Beta-carotene", whatItIs: "Natural orange pigment from carrots and sweet potatoes. Your body converts it to vitamin A for healthy eyes and immune function.", originSummary: "Extracted from carrots, palm oil, or algae; sometimes synthetic.", riskSummary: "Safe and beneficial. Provides vitamin A activity without toxicity risk.", riskLevel: .noRisk),
        "beta-carotene": .init(displayName: "Beta-carotene", whatItIs: "Natural orange pigment from carrots and sweet potatoes. Your body converts it to vitamin A for healthy eyes and immune function.", originSummary: "Extracted from carrots, palm oil, or algae; sometimes synthetic.", riskSummary: "Safe and beneficial. Provides vitamin A activity without toxicity risk.", riskLevel: .noRisk),
        "e306": .init(displayName: "Vitamin E (Tocopherols)", whatItIs: "Natural antioxidant that protects fats from going rancid and protects your cells from damage.", originSummary: "Extracted from vegetable oils like sunflower and wheat germ.", riskSummary: "Safe and beneficial. A natural preservative with health benefits.", riskLevel: .noRisk),
        "e307": .init(displayName: "Vitamin E (Alpha-tocopherol)", whatItIs: "The most active form of vitamin E - protects cell membranes and keeps oils fresh.", originSummary: "From vegetable oils or synthetic.", riskSummary: "Safe and beneficial.", riskLevel: .noRisk),
        "e308": .init(displayName: "Vitamin E (Gamma-tocopherol)", whatItIs: "A form of vitamin E with antioxidant properties.", originSummary: "From vegetable oils.", riskSummary: "Safe and beneficial.", riskLevel: .noRisk),
        "e309": .init(displayName: "Vitamin E (Delta-tocopherol)", whatItIs: "A form of vitamin E with antioxidant properties.", originSummary: "From vegetable oils.", riskSummary: "Safe and beneficial.", riskLevel: .noRisk),

        // Natural ingredients - NO RISK
        "e330": .init(displayName: "Citric acid", whatItIs: "The same natural acid found in lemons and oranges. Gives foods a tangy taste and helps preserve them.", originSummary: "Originally from citrus; now produced by fermenting sugar with a harmless mould.", riskSummary: "Completely safe. Identical to the citric acid in citrus fruits.", riskLevel: .noRisk),
        "e322": .init(displayName: "Lecithin", whatItIs: "Natural emulsifier found in egg yolks and soybeans. Helps oil and water mix smoothly in chocolate, margarine, and baked goods.", originSummary: "Usually from soybeans or sunflower seeds; occasionally from eggs.", riskSummary: "Safe and natural. An important nutrient for brain health.", riskLevel: .noRisk),
        "lecithin": .init(displayName: "Lecithin", whatItIs: "Natural emulsifier found in egg yolks and soybeans. Helps oil and water mix smoothly in chocolate, margarine, and baked goods.", originSummary: "Usually from soybeans or sunflower seeds; occasionally from eggs.", riskSummary: "Safe and natural. An important nutrient for brain health.", riskLevel: .noRisk),

        // Low risk - plant-derived gums and thickeners
        "e415": .init(displayName: "Xanthan gum", whatItIs: "Natural thickener that gives foods a smooth, creamy texture. Used in salad dressings, sauces, and gluten-free baking.", originSummary: "Made by fermenting sugar with a natural bacterium.", riskSummary: "Generally safe. Very high amounts may cause mild digestive effects in sensitive people.", riskLevel: .lowRisk),
        "e412": .init(displayName: "Guar gum", whatItIs: "Plant-based thickener from guar beans. Creates smooth texture in ice cream, sauces, and gluten-free products.", originSummary: "Ground from the seeds of the guar plant, grown mainly in India.", riskSummary: "Generally safe. May cause mild bloating if consumed in very large amounts.", riskLevel: .lowRisk),
        "e407": .init(displayName: "Carrageenan", whatItIs: "Seaweed extract used to thicken and stabilise dairy products, plant milks, and desserts.", originSummary: "Extracted from red seaweed (Irish moss).", riskSummary: "Food-grade carrageenan is approved as safe. Some people with digestive sensitivity may prefer to limit it.", riskLevel: .lowRisk),
        "e466": .init(displayName: "Cellulose gum", whatItIs: "Plant fibre derivative that thickens and stabilises foods. Also helps ice cream stay smooth.", originSummary: "Made from plant cellulose (wood pulp or cotton).", riskSummary: "Safe. Passes through the body undigested like dietary fibre.", riskLevel: .lowRisk),

        // Sweeteners - LOW to MODERATE risk
        "e960": .init(displayName: "Stevia (Steviol glycosides)", whatItIs: "Natural zero-calorie sweetener from the stevia plant. About 200-300x sweeter than sugar.", originSummary: "Extracted and purified from stevia leaves, a plant native to South America.", riskSummary: "Safe plant-based alternative to sugar. No known health concerns at normal consumption.", riskLevel: .lowRisk),
        "e968": .init(displayName: "Erythritol", whatItIs: "Sugar alcohol with almost zero calories. Tastes like sugar but doesn't spike blood sugar or harm teeth.", originSummary: "Made by fermenting glucose, often from corn.", riskSummary: "Well tolerated. Very large amounts may cause mild digestive upset.", riskLevel: .lowRisk),
        "e420": .init(displayName: "Sorbitol", whatItIs: "Sugar alcohol used in sugar-free sweets and chewing gum. Provides sweetness with fewer calories.", originSummary: "Made from glucose, originally from mountain ash berries.", riskSummary: "Can cause laxative effects if consumed in excess (>20g). Products must carry a warning.", riskLevel: .moderateRisk),
        "e421": .init(displayName: "Mannitol", whatItIs: "Sugar alcohol used in sugar-free confectionery. Provides sweetness without affecting blood sugar.", originSummary: "Made from fructose or extracted from seaweed.", riskSummary: "Can cause laxative effects if consumed in excess. Products must carry a warning.", riskLevel: .moderateRisk),
        "e965": .init(displayName: "Maltitol", whatItIs: "Sugar alcohol commonly used in sugar-free chocolate and biscuits.", originSummary: "Made from maltose (malt sugar) derived from starch.", riskSummary: "Can cause significant digestive issues in some people. Limit intake to avoid discomfort.", riskLevel: .moderateRisk),
        "e967": .init(displayName: "Xylitol", whatItIs: "Sugar alcohol that's actually good for teeth - used in sugar-free gum and dental products.", originSummary: "Usually made from birch bark or corn cobs.", riskSummary: "Safe for humans. Can cause digestive issues in excess. TOXIC TO DOGS - keep away from pets.", riskLevel: .moderateRisk),
        "e951": .init(displayName: "Aspartame", whatItIs: "Artificial sweetener about 200x sweeter than sugar. Used in diet drinks and sugar-free foods.", originSummary: "Synthetic. Made from two amino acids.", riskSummary: "Safe for most people at normal consumption. NOT suitable for people with PKU (phenylketonuria).", riskLevel: .moderateRisk),
        "e950": .init(displayName: "Acesulfame K", whatItIs: "Artificial sweetener often combined with aspartame for a more sugar-like taste.", originSummary: "Synthetic.", riskSummary: "Approved as safe. Can have a bitter aftertaste at high concentrations.", riskLevel: .moderateRisk),
        "e955": .init(displayName: "Sucralose", whatItIs: "Artificial sweetener made from sugar, about 600x sweeter. Stable for cooking.", originSummary: "Synthetic - modified sucrose molecule.", riskSummary: "Well tolerated. Some concerns about long-term effects, but approved as safe.", riskLevel: .moderateRisk),
        "e954": .init(displayName: "Saccharin", whatItIs: "The oldest artificial sweetener, about 300x sweeter than sugar.", originSummary: "Synthetic. Discovered in 1879.", riskSummary: "Previous cancer concerns were disproved. Can have a metallic aftertaste.", riskLevel: .moderateRisk),

        // Preservatives - varied risk
        "e202": .init(displayName: "Potassium sorbate", whatItIs: "Effective preservative that prevents mould and yeast growth in cheese, wine, and baked goods.", originSummary: "Synthetic salt of sorbic acid, which occurs naturally in some berries.", riskSummary: "Very safe. One of the most studied and well-tolerated preservatives.", riskLevel: .lowRisk),
        "e200": .init(displayName: "Sorbic acid", whatItIs: "Natural preservative that prevents mould and yeast growth.", originSummary: "Originally from rowan berries; now mostly synthetic.", riskSummary: "Very safe. Well tolerated with no known adverse effects.", riskLevel: .lowRisk),
        "e211": .init(displayName: "Sodium benzoate", whatItIs: "Preservative that prevents bacterial growth in acidic foods like soft drinks, pickles, and sauces.", originSummary: "Synthetic. Related to benzoic acid found naturally in berries.", riskSummary: "Safe at permitted levels. Avoid combining with vitamin C in acidic conditions at high temperatures (rare in normal use).", riskLevel: .lowRisk),
        "e220": .init(displayName: "Sulphur dioxide", whatItIs: "Preservative and antioxidant used in wine, dried fruits, and some juices.", originSummary: "Synthetic gas.", riskSummary: "Can trigger asthma or allergic reactions in sensitive individuals. Must be declared on labels.", riskLevel: .moderateRisk),
        "e223": .init(displayName: "Sodium metabisulphite", whatItIs: "Preservative and antioxidant used in wine, dried fruits, and processed foods.", originSummary: "Synthetic.", riskSummary: "Can trigger reactions in sulphite-sensitive people (especially asthmatics). Must be declared on labels.", riskLevel: .moderateRisk),
        "e250": .init(displayName: "Sodium nitrite", whatItIs: "Curing salt used in bacon, ham, and processed meats. Prevents deadly botulism bacteria and gives meat its pink colour.", originSummary: "Synthetic.", riskSummary: "Essential for meat safety but can form nitrosamines when cooked at high heat. Limit processed meat intake.", riskLevel: .highRisk),
        "e251": .init(displayName: "Sodium nitrate", whatItIs: "Curing agent used in some cured meats. Converts to nitrite during curing.", originSummary: "Synthetic or from mineral sources.", riskSummary: "Similar concerns to nitrite. Limit intake of processed meats.", riskLevel: .highRisk),

        // Colours - varied risk (synthetic colours higher risk)
        "e160b": .init(displayName: "Annatto", whatItIs: "Natural orange-red colour from the achiote tree. Used in cheese, butter, and snacks.", originSummary: "Extracted from the seeds of the tropical achiote tree.", riskSummary: "Natural colour. Generally safe, though rare sensitivity has been reported.", riskLevel: .lowRisk),
        "e162": .init(displayName: "Beetroot red", whatItIs: "Natural red colour extracted from beetroot.", originSummary: "From beetroot juice.", riskSummary: "Completely safe and natural.", riskLevel: .noRisk),
        "e140": .init(displayName: "Chlorophyll", whatItIs: "Natural green colour - the same pigment that makes plants green.", originSummary: "Extracted from nettles, grass, or alfalfa.", riskSummary: "Completely safe and natural.", riskLevel: .noRisk),
        "e102": .init(displayName: "Tartrazine (Yellow 5)", whatItIs: "Synthetic lemon-yellow dye used in drinks, sweets, and snacks.", originSummary: "Synthetic azo dye made from petroleum.", riskSummary: "May affect activity and attention in some children. Products must carry a warning in the UK/EU.", riskLevel: .highRisk),
        "e110": .init(displayName: "Sunset Yellow", whatItIs: "Synthetic orange-yellow dye used in soft drinks and confectionery.", originSummary: "Synthetic azo dye.", riskSummary: "May affect activity and attention in some children. Requires warning label.", riskLevel: .highRisk),
        "e129": .init(displayName: "Allura Red", whatItIs: "Synthetic red dye widely used in soft drinks, sweets, and sauces.", originSummary: "Synthetic azo dye.", riskSummary: "May affect activity and attention in some children. Requires warning label.", riskLevel: .highRisk),
        "e104": .init(displayName: "Quinoline Yellow", whatItIs: "Synthetic greenish-yellow dye used in desserts and ice lollies.", originSummary: "Synthetic.", riskSummary: "May affect activity and attention in some children. Requires warning label.", riskLevel: .highRisk),
        "e122": .init(displayName: "Carmoisine (Azorubine)", whatItIs: "Synthetic red dye used in jams, jellies, and confectionery.", originSummary: "Synthetic azo dye.", riskSummary: "May affect activity and attention in some children. Requires warning label.", riskLevel: .highRisk),
        "e124": .init(displayName: "Ponceau 4R", whatItIs: "Synthetic red dye used in desserts and meat products.", originSummary: "Synthetic azo dye.", riskSummary: "May affect activity and attention in some children. Requires warning label.", riskLevel: .highRisk),
        "e133": .init(displayName: "Brilliant Blue", whatItIs: "Synthetic blue dye used in confectionery and drinks.", originSummary: "Synthetic.", riskSummary: "Generally considered safer than azo dyes. Permitted within limits.", riskLevel: .moderateRisk),
        "e150a": .init(displayName: "Plain caramel", whatItIs: "Brown colour made by heating sugar - the same process as making caramel at home.", originSummary: "Made from heated sugar.", riskSummary: "Safe and natural.", riskLevel: .noRisk),
        "e150d": .init(displayName: "Sulphite ammonia caramel", whatItIs: "Brown colour used in cola drinks and soy sauce.", originSummary: "Made from sugar treated with ammonia and sulphites.", riskSummary: "Contains 4-MEI as a byproduct. Approved as safe within limits.", riskLevel: .moderateRisk),

        // Flavour enhancers
        "e621": .init(displayName: "MSG (Monosodium glutamate)", whatItIs: "Umami flavour enhancer that makes savoury foods taste richer and more satisfying.", originSummary: "Made by fermenting starches - the same glutamate found naturally in tomatoes and parmesan.", riskSummary: "Safe for most people. 'Chinese Restaurant Syndrome' was never scientifically proven. Some sensitive individuals may react.", riskLevel: .lowRisk),
        "monosodium glutamate": .init(displayName: "MSG (Monosodium glutamate)", whatItIs: "Umami flavour enhancer that makes savoury foods taste richer and more satisfying.", originSummary: "Made by fermenting starches - the same glutamate found naturally in tomatoes and parmesan.", riskSummary: "Safe for most people. 'Chinese Restaurant Syndrome' was never scientifically proven. Some sensitive individuals may react.", riskLevel: .lowRisk),

        // Antioxidants
        "e320": .init(displayName: "BHA (Butylated hydroxyanisole)", whatItIs: "Synthetic antioxidant that prevents fats and oils from going rancid.", originSummary: "Synthetic.", riskSummary: "Some studies raised concerns. Strictly limited in foods. Being phased out in favour of natural alternatives.", riskLevel: .highRisk),
        "e321": .init(displayName: "BHT (Butylated hydroxytoluene)", whatItIs: "Synthetic antioxidant that prevents fats and oils from going rancid.", originSummary: "Synthetic.", riskSummary: "Some studies raised concerns. Strictly limited in foods. Being phased out in favour of natural alternatives.", riskLevel: .highRisk),

        // Phosphates
        "e338": .init(displayName: "Phosphoric acid", whatItIs: "Gives cola drinks their sharp, tangy taste. Also used as an acidifier in processed foods.", originSummary: "Synthetic.", riskSummary: "Safe at food levels. High cola consumption may affect bone and tooth health.", riskLevel: .moderateRisk),
        "e450": .init(displayName: "Diphosphates", whatItIs: "Emulsifier and stabiliser used in processed cheese, meat, and baking powder.", originSummary: "Synthetic.", riskSummary: "Safe within limits. High phosphate intake from all sources may affect kidney patients.", riskLevel: .moderateRisk),

        // Misc
        "e570": .init(displayName: "Fatty acids", whatItIs: "Natural fats used as anti-caking agents and in food processing.", originSummary: "From plant or animal fats.", riskSummary: "Safe and natural.", riskLevel: .noRisk),
        "fatty acids": .init(displayName: "Fatty acids", whatItIs: "Natural fats used as anti-caking agents and in food processing.", originSummary: "From plant or animal fats.", riskSummary: "Safe and natural.", riskLevel: .noRisk),
        "caffeine": .init(displayName: "Caffeine", whatItIs: "Natural stimulant found in coffee, tea, and chocolate. Added to energy drinks and some soft drinks.", originSummary: "From coffee beans, tea leaves, or synthetic.", riskSummary: "Safe for most adults in moderation. Limit intake if sensitive to stimulants, pregnant, or for children.", riskLevel: .moderateRisk),
        "e471": .init(displayName: "Mono- and diglycerides", whatItIs: "Emulsifiers that help oil and water mix. Used in bread, ice cream, and margarine.", originSummary: "From vegetable or animal fats.", riskSummary: "Safe and well tolerated. One of the most common emulsifiers.", riskLevel: .lowRisk),

        // More common additives with proper descriptions
        "e441": .init(displayName: "Gelatin", whatItIs: "A gelling agent derived from animal collagen. Creates the wobbly texture in jellies, marshmallows, and gummy sweets.", originSummary: "Made from animal bones, skin, and connective tissue - typically from pigs or cows.", riskSummary: "Safe to consume. Not suitable for vegetarians, vegans, or those avoiding pork/beef for religious reasons.", riskLevel: .lowRisk),
        "gelatin": .init(displayName: "Gelatin", whatItIs: "A gelling agent derived from animal collagen. Creates the wobbly texture in jellies, marshmallows, and gummy sweets.", originSummary: "Made from animal bones, skin, and connective tissue - typically from pigs or cows.", riskSummary: "Safe to consume. Not suitable for vegetarians, vegans, or those avoiding pork/beef for religious reasons.", riskLevel: .lowRisk),
        "gelatine": .init(displayName: "Gelatin", whatItIs: "A gelling agent derived from animal collagen. Creates the wobbly texture in jellies, marshmallows, and gummy sweets.", originSummary: "Made from animal bones, skin, and connective tissue - typically from pigs or cows.", riskSummary: "Safe to consume. Not suitable for vegetarians, vegans, or those avoiding pork/beef for religious reasons.", riskLevel: .lowRisk),

        "e418": .init(displayName: "Gellan gum", whatItIs: "A plant-based gelling agent used as a vegan alternative to gelatin. Creates firm, clear gels.", originSummary: "Produced by bacterial fermentation.", riskSummary: "Safe and vegan-friendly. A good alternative to animal-derived gelatin.", riskLevel: .noRisk),

        "e440": .init(displayName: "Pectin", whatItIs: "Natural plant fibre that makes jams and jellies set. Also used in fruit drinks and dairy desserts.", originSummary: "Extracted from apple pomace or citrus peel.", riskSummary: "Completely safe and natural. Actually a beneficial dietary fibre.", riskLevel: .noRisk),
        "pectin": .init(displayName: "Pectin", whatItIs: "Natural plant fibre that makes jams and jellies set. Also used in fruit drinks and dairy desserts.", originSummary: "Extracted from apple pomace or citrus peel.", riskSummary: "Completely safe and natural. Actually a beneficial dietary fibre.", riskLevel: .noRisk),

        "e500": .init(displayName: "Sodium bicarbonate (Baking soda)", whatItIs: "A raising agent that makes cakes and bread rise. Also neutralises acidity.", originSummary: "Mineral-based, can be mined or produced industrially.", riskSummary: "Completely safe. The same baking soda used in home cooking.", riskLevel: .noRisk),
        "sodium bicarbonate": .init(displayName: "Sodium bicarbonate (Baking soda)", whatItIs: "A raising agent that makes cakes and bread rise. Also neutralises acidity.", originSummary: "Mineral-based, can be mined or produced industrially.", riskSummary: "Completely safe. The same baking soda used in home cooking.", riskLevel: .noRisk),
        "bicarbonate of soda": .init(displayName: "Sodium bicarbonate (Baking soda)", whatItIs: "A raising agent that makes cakes and bread rise. Also neutralises acidity.", originSummary: "Mineral-based, can be mined or produced industrially.", riskSummary: "Completely safe. The same baking soda used in home cooking.", riskLevel: .noRisk),

        "e503": .init(displayName: "Ammonium carbonate", whatItIs: "A raising agent used in flat baked goods like crackers and cookies. Evaporates during baking.", originSummary: "Synthetic.", riskSummary: "Safe. Completely dissipates during baking leaving no residue.", riskLevel: .noRisk),

        "e170": .init(displayName: "Calcium carbonate (Chalk)", whatItIs: "Used as a white colour, anti-caking agent, and calcium fortification. Also neutralises acidity.", originSummary: "Natural mineral - the same compound found in limestone, chalk, and eggshells.", riskSummary: "Completely safe. Provides dietary calcium.", riskLevel: .noRisk),

        "e270": .init(displayName: "Lactic acid", whatItIs: "A natural acid that adds tartness and acts as a preservative. Found naturally in yogurt and fermented foods.", originSummary: "Produced by fermenting sugars - the same process that makes yogurt tangy.", riskSummary: "Completely safe and natural.", riskLevel: .noRisk),
        "lactic acid": .init(displayName: "Lactic acid", whatItIs: "A natural acid that adds tartness and acts as a preservative. Found naturally in yogurt and fermented foods.", originSummary: "Produced by fermenting sugars - the same process that makes yogurt tangy.", riskSummary: "Completely safe and natural.", riskLevel: .noRisk),

        "e296": .init(displayName: "Malic acid", whatItIs: "A natural acid that gives green apples their sour taste. Used to add tartness to sweets and drinks.", originSummary: "Found naturally in apples and many fruits; commercially produced.", riskSummary: "Completely safe and natural.", riskLevel: .noRisk),
        "malic acid": .init(displayName: "Malic acid", whatItIs: "A natural acid that gives green apples their sour taste. Used to add tartness to sweets and drinks.", originSummary: "Found naturally in apples and many fruits; commercially produced.", riskSummary: "Completely safe and natural.", riskLevel: .noRisk),

        "e334": .init(displayName: "Tartaric acid", whatItIs: "A natural acid found in grapes. Used in wine-making and to add tartness to foods.", originSummary: "Extracted from grapes or produced during wine-making.", riskSummary: "Completely safe and natural.", riskLevel: .noRisk),

        "e262": .init(displayName: "Sodium acetate", whatItIs: "Salt of acetic acid (vinegar). Used to add a vinegary flavour and as a preservative.", originSummary: "Derived from vinegar.", riskSummary: "Safe. Essentially the salt form of vinegar.", riskLevel: .noRisk),

        "e150c": .init(displayName: "Ammonia caramel", whatItIs: "Brown colour used in beer, soy sauce, and dark breads.", originSummary: "Made from sugar treated with ammonia.", riskSummary: "Safe within permitted limits. Contains 4-MEI as a byproduct but at safe levels.", riskLevel: .lowRisk),

        "e171": .init(displayName: "Titanium dioxide", whatItIs: "Bright white colour used in confectionery, icing, and some medications.", originSummary: "Mineral-based, derived from titanium ore.", riskSummary: "Banned in EU since 2022 due to concerns about nanoparticles. Still permitted in some countries.", riskLevel: .highRisk),

        "e172": .init(displayName: "Iron oxides", whatItIs: "Natural mineral colours ranging from yellow to red to black. Used in confectionery and cake decorations.", originSummary: "Mineral-based, the same compounds that give rust its colour.", riskSummary: "Safe and natural mineral pigments.", riskLevel: .noRisk),

        "e163": .init(displayName: "Anthocyanins", whatItIs: "Natural purple-red colours from berries, grapes, and red cabbage.", originSummary: "Extracted from purple/red fruits and vegetables.", riskSummary: "Completely safe and natural. These are the same pigments in blueberries.", riskLevel: .noRisk),

        "e160c": .init(displayName: "Paprika extract", whatItIs: "Natural orange-red colour from paprika peppers.", originSummary: "Extracted from paprika peppers.", riskSummary: "Completely safe and natural.", riskLevel: .noRisk),

        "e100": .init(displayName: "Curcumin (Turmeric)", whatItIs: "Natural yellow colour from turmeric root. The same spice used in curry.", originSummary: "Extracted from turmeric root.", riskSummary: "Completely safe and natural. Turmeric has been used in cooking for thousands of years.", riskLevel: .noRisk),
        "curcumin": .init(displayName: "Curcumin (Turmeric)", whatItIs: "Natural yellow colour from turmeric root. The same spice used in curry.", originSummary: "Extracted from turmeric root.", riskSummary: "Completely safe and natural. Turmeric has been used in cooking for thousands of years.", riskLevel: .noRisk),

        "e120": .init(displayName: "Cochineal (Carmine)", whatItIs: "Natural red colour used in drinks, sweets, and cosmetics.", originSummary: "Derived from crushed cochineal insects.", riskSummary: "Safe but not suitable for vegetarians or vegans. Rare allergic reactions reported.", riskLevel: .lowRisk),
        "carmine": .init(displayName: "Cochineal (Carmine)", whatItIs: "Natural red colour used in drinks, sweets, and cosmetics.", originSummary: "Derived from crushed cochineal insects.", riskSummary: "Safe but not suitable for vegetarians or vegans. Rare allergic reactions reported.", riskLevel: .lowRisk),

        "e410": .init(displayName: "Locust bean gum", whatItIs: "Natural thickener that creates a smooth, creamy texture in ice cream and dairy products.", originSummary: "Ground from the seeds of the carob tree.", riskSummary: "Safe and natural. Also known as carob gum.", riskLevel: .noRisk),
        "locust bean gum": .init(displayName: "Locust bean gum", whatItIs: "Natural thickener that creates a smooth, creamy texture in ice cream and dairy products.", originSummary: "Ground from the seeds of the carob tree.", riskSummary: "Safe and natural. Also known as carob gum.", riskLevel: .noRisk),

        "e414": .init(displayName: "Gum arabic (Acacia gum)", whatItIs: "Natural gum used to stabilise soft drinks, glazes, and confectionery.", originSummary: "Natural sap from acacia trees, harvested in Africa.", riskSummary: "Completely safe and natural. Used for thousands of years.", riskLevel: .noRisk),
        "gum arabic": .init(displayName: "Gum arabic (Acacia gum)", whatItIs: "Natural gum used to stabilise soft drinks, glazes, and confectionery.", originSummary: "Natural sap from acacia trees, harvested in Africa.", riskSummary: "Completely safe and natural. Used for thousands of years.", riskLevel: .noRisk),

        "e401": .init(displayName: "Sodium alginate", whatItIs: "Natural thickener from seaweed. Creates gel-like textures and is used in molecular gastronomy.", originSummary: "Extracted from brown seaweed.", riskSummary: "Safe and natural. Popular in modern cooking for creating 'spherification'.", riskLevel: .noRisk),

        "e509": .init(displayName: "Calcium chloride", whatItIs: "Mineral salt that firms up canned vegetables and helps cheese set.", originSummary: "Mineral-based, produced from limestone.", riskSummary: "Safe within food use limits.", riskLevel: .lowRisk),

        "e516": .init(displayName: "Calcium sulphate", whatItIs: "Mineral used to make tofu and as a dough conditioner in bread.", originSummary: "Mineral-based, also known as gypsum.", riskSummary: "Safe. Used in tofu-making for centuries.", riskLevel: .noRisk),

        "e460": .init(displayName: "Cellulose", whatItIs: "Plant fibre used as a bulking agent and anti-caking agent in grated cheese.", originSummary: "From plant cell walls - wood pulp or cotton.", riskSummary: "Safe. Passes through the body as indigestible fibre.", riskLevel: .noRisk),
        "cellulose": .init(displayName: "Cellulose", whatItIs: "Plant fibre used as a bulking agent and anti-caking agent in grated cheese.", originSummary: "From plant cell walls - wood pulp or cotton.", riskSummary: "Safe. Passes through the body as indigestible fibre.", riskLevel: .noRisk),

        "e551": .init(displayName: "Silicon dioxide", whatItIs: "Anti-caking agent that keeps powders flowing freely.", originSummary: "Mineral-based - the same compound as sand and quartz.", riskSummary: "Safe. Used in tiny amounts to prevent clumping.", riskLevel: .noRisk),

        "e1200": .init(displayName: "Polydextrose", whatItIs: "Synthetic fibre used as a low-calorie bulking agent in reduced-sugar foods.", originSummary: "Synthetic, made from glucose and sorbitol.", riskSummary: "Safe. Can cause digestive issues if consumed in very large amounts.", riskLevel: .lowRisk),

        "e1520": .init(displayName: "Propylene glycol", whatItIs: "Humectant that keeps food moist. Also used to carry flavours.", originSummary: "Synthetic.", riskSummary: "Safe within permitted limits. Different from antifreeze (ethylene glycol).", riskLevel: .lowRisk),

        "e422": .init(displayName: "Glycerol (Glycerine)", whatItIs: "Sweet-tasting humectant that keeps food moist. Used in cakes, confectionery, and vaping liquids.", originSummary: "From vegetable oils or as a byproduct of soap-making.", riskSummary: "Safe and widely used.", riskLevel: .noRisk),
        "glycerol": .init(displayName: "Glycerol (Glycerine)", whatItIs: "Sweet-tasting humectant that keeps food moist. Used in cakes, confectionery, and vaping liquids.", originSummary: "From vegetable oils or as a byproduct of soap-making.", riskSummary: "Safe and widely used.", riskLevel: .noRisk),
        "glycerine": .init(displayName: "Glycerol (Glycerine)", whatItIs: "Sweet-tasting humectant that keeps food moist. Used in cakes, confectionery, and vaping liquids.", originSummary: "From vegetable oils or as a byproduct of soap-making.", riskSummary: "Safe and widely used.", riskLevel: .noRisk),

        "e901": .init(displayName: "Beeswax", whatItIs: "Natural wax used to coat sweets and fresh produce for a shiny finish.", originSummary: "From honeybee hives.", riskSummary: "Safe and natural. Not suitable for strict vegans.", riskLevel: .noRisk),
        "beeswax": .init(displayName: "Beeswax", whatItIs: "Natural wax used to coat sweets and fresh produce for a shiny finish.", originSummary: "From honeybee hives.", riskSummary: "Safe and natural. Not suitable for strict vegans.", riskLevel: .noRisk),

        "e903": .init(displayName: "Carnauba wax", whatItIs: "Natural plant wax that gives confectionery and pills a glossy coating.", originSummary: "From the leaves of the Brazilian carnauba palm.", riskSummary: "Safe and vegan-friendly.", riskLevel: .noRisk),
        "carnauba wax": .init(displayName: "Carnauba wax", whatItIs: "Natural plant wax that gives confectionery and pills a glossy coating.", originSummary: "From the leaves of the Brazilian carnauba palm.", riskSummary: "Safe and vegan-friendly.", riskLevel: .noRisk),

        "e904": .init(displayName: "Shellac", whatItIs: "Natural resin used to coat sweets, pills, and citrus fruits for shine.", originSummary: "Secreted by the lac insect on trees in India and Thailand.", riskSummary: "Safe but not suitable for vegetarians or vegans.", riskLevel: .noRisk),
        "shellac": .init(displayName: "Shellac", whatItIs: "Natural resin used to coat sweets, pills, and citrus fruits for shine.", originSummary: "Secreted by the lac insect on trees in India and Thailand.", riskSummary: "Safe but not suitable for vegetarians or vegans.", riskLevel: .noRisk),

        "e476": .init(displayName: "Polyglycerol polyricinoleate (PGPR)", whatItIs: "Emulsifier that reduces the amount of cocoa butter needed in chocolate.", originSummary: "Made from castor oil and glycerol.", riskSummary: "Safe. Allows chocolate makers to use less cocoa butter.", riskLevel: .lowRisk),

        "e473": .init(displayName: "Sucrose esters", whatItIs: "Emulsifiers made from sugar and fats. Used in baked goods and ice cream.", originSummary: "Made from sucrose (sugar) and fatty acids.", riskSummary: "Safe and well tolerated.", riskLevel: .lowRisk),

        "e627": .init(displayName: "Disodium guanylate", whatItIs: "Flavour enhancer that works with MSG to create umami taste.", originSummary: "Usually from yeast extract or fish.", riskSummary: "Safe. Not suitable for gout sufferers due to purine content.", riskLevel: .lowRisk),

        "e631": .init(displayName: "Disodium inosinate", whatItIs: "Flavour enhancer that works with MSG to create umami taste.", originSummary: "Usually from meat or fish extracts.", riskSummary: "Safe. Not suitable for gout sufferers due to purine content.", riskLevel: .lowRisk),

        "e635": .init(displayName: "Disodium 5'-ribonucleotides", whatItIs: "Combination flavour enhancer containing E627 and E631. Boosts umami flavour.", originSummary: "From yeast, meat, or fish extracts.", riskSummary: "Safe. Not suitable for gout sufferers due to purine content.", riskLevel: .lowRisk)
    ]

    static func override(for additive: AdditiveInfo) -> AdditiveOverrideData? {
        for code in additive.eNumbers {
            if let match = overrides[code.lowercased()] {
                return match
            }
        }
        return overrides[additive.name.lowercased()]
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
